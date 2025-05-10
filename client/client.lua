local QBCore = exports['qb-core']:GetCoreObject()
local chatInputActive = false
local registeredCommandData = {}


local baseCommandInfo = {
    ['me'] = { name = '/me', help = 'Karakter eylemini belirtir.', params = {{name="eylem", help="Yapılan eylem"}} },
    ['do'] = { name = '/do', help = 'Çevresel durumu belirtir.', params = {{name="durum", help="Betimlenen durum"}} },
    ['ooc'] = { name = '/ooc', help = 'Oyun dışı mesaj gönderir.', params = {{name="mesaj", help="Oyun dışı mesajınız"}} },
    ['pdc'] = { name = '/pdc', help = 'Polis Departman Kanalı.', params = {{name="mesaj", help="Polis kanalına mesajınız"}} },
    ['emsc'] = { name = '/emsc', help = 'EMS Departman Kanalı.', params = {{name="mesaj", help="EMS kanalına mesajınız"}} }, 
    ['clear'] = { name = '/clear', help = 'Sohbet ekranını temizler.', params = nil },
    ['car'] = { name = '/car', help = 'Belirtilen aracı spawnlar.', params = {{name="araç_modeli"}} },
    ['dv'] = { name = '/dv', help = 'Yakındaki aracı siler.', params = nil },
    ['setjob'] = { name = '/setjob', help = 'Oyuncuya iş ve rütbe verir.', params = {{name="id"}, {name="iş"}, {name="rütbe"}} },
    ['giveitem'] = { name = '/giveitem', help = 'Oyuncuya eşya verir.', params = {{name="id"}, {name="eşya"}, {name="adet"}} },
    ['twt'] = { name = '/twt', help = 'Tweet atar.', params = {{name="mesaj"}} },
    ['announce'] = { name = '/announce', help = 'Duyuru yapar.', params = {{name="mesaj"}} },
    ['skin'] = { name = '/skin', help = 'Karakter görünüm menüsü.', params = nil },
    ['money'] = { name = '/money', help = 'Paranızı gösterir.', params = nil }
}


local baseCommands = {
    ['me'] = true, ['do'] = true, ['ooc'] = true, ['pdc'] = true, ['clear'] = true, ['emsc'] = true,
    ['car'] = true, ['dv'] = true, ['setjob'] = true, ['giveitem'] = true, ['twt'] = false,
    ['announce'] = true, ['skin'] = true, ['money'] = true
}


local function GetCommandName(fullCmd) if not fullCmd then return '' end; local cmd = fullCmd:gsub("^%s*(.-)%s*$", "%1"):lower(); if cmd:sub(1, 1) == '/' then return cmd:sub(2) end; return cmd end

local function RefreshCommandInfo()
    registeredCommandData = {}; for cmdName, data in pairs(baseCommandInfo) do registeredCommandData[cmdName] = data end
    if GetRegisteredCommands then local commands = GetRegisteredCommands(); for _, cmdData in ipairs(commands) do if cmdData and cmdData.name then local cmdName = GetCommandName(cmdData.name); if cmdName ~= "" and not baseCommandInfo[cmdName] then registeredCommandData[cmdName] = { name = '/' .. cmdName, help = '', params = nil } end end end
    else print("[bs-chat] WARNING: GetRegisteredCommands native not available!") end
    SendNUIMessage({ type = 'updateCommandData', commands = registeredCommandData })
end


AddEventHandler('chat:addSuggestion', function(name, help, params) local cmdName = GetCommandName(name); if cmdName ~= '' and not baseCommands[cmdName] then baseCommands[cmdName] = true end end)

local function SetChatFocus(hasFocus, hasCursor) if chatInputActive == hasFocus then return end; chatInputActive = hasFocus; if type(SetNuiFocus) == 'function' then SetNuiFocus(hasFocus, hasCursor); SendNUIMessage({ type = hasFocus and 'showChatInput' or 'hideChatInput' }) else print("bs-chat ERROR: SetNuiFocus native not found!"); SendNUIMessage({ type = hasFocus and 'showChatInput' or 'hideChatInput' }) end; if not hasFocus then SendNUIMessage({ type = 'showCommandInfo', show = false, info = nil }) end end

Citizen.CreateThread(function() while true do Citizen.Wait(1); if IsControlJustPressed(0, Config.OpenChatControl) and not chatInputActive then SetChatFocus(true, true) end; if IsControlJustPressed(0, Config.CloseChatControl) then if NuiHasFocus() then SetChatFocus(false, false) end end end end)

local function AddClientMessage(messageData) TriggerEvent('bs-chat:addMessage', messageData) end


RegisterNUICallback('sendMessage', function(data, cb)
    local rawMessage = data.message or ''; local messageToSend = rawMessage:gsub("^%s*(.-)%s*$", "%1")
    SetChatFocus(false, false); cb('ok')
    if messageToSend == '' then return end
    local isPotentiallyCommand = false; local command = ''; local argsString = ''; local executeInput = messageToSend
    local startsWithSlash = messageToSend:sub(1, 1) == '/'
    local firstWord = ""

    if startsWithSlash then isPotentiallyCommand = true; local spacePos = messageToSend:find(' '); if spacePos then command = messageToSend:sub(2, spacePos - 1):lower(); argsString = messageToSend:sub(spacePos + 1) else command = messageToSend:sub(2):lower(); argsString = '' end; executeInput = messageToSend:sub(2)
    else local spacePos = messageToSend:find(' '); if spacePos then firstWord = messageToSend:sub(1, spacePos - 1):lower(); argsString = messageToSend:sub(spacePos + 1) else firstWord = messageToSend:lower(); argsString = '' end
        if baseCommands[firstWord] then 
            isPotentiallyCommand = true; command = firstWord; executeInput = messageToSend
        else
            return 
        end
    end

  
    if command == 'me' or command == 'do' or command == 'ooc' or command == 'pdc' or command == 'emsc' then
        if argsString ~= "" or (command == 'me' or command == 'do') then
            TriggerServerEvent('bs-chat:sendMessage', argsString, command) 
        else
            AddClientMessage({ authorType=Config.MessageTypes['error'], authorName='HATA', message='/'..command .. ' komutu için mesaj girmelisiniz.'})
        end
    elseif command == 'clear' then
        SendNUIMessage({ type = 'clearMessages' })
    else
       
        ExecuteCommand(executeInput)
    end
end)

RegisterNUICallback('hideChat', function(data, cb) SetChatFocus(false, false); cb('ok') end)
RegisterNetEvent('bs-chat:addMessage', function(messageData) SendNUIMessage({ type = 'addMessage', messageData = messageData }) end)

AddEventHandler('onClientResourceStart', function(resourceName) if resourceName == GetCurrentResourceName() then Citizen.Wait(1500); RefreshCommandInfo(); SendNUIMessage({ type = 'updateSettings', settings = { maxMessages = Config.MaxMessages, fadeOutTime = Config.FadeOutTime, visibilityDuration = Config.ChatVisibilityDuration, showTimestamps = Config.ShowTimestamps, showPlayerId = Config.ShowPlayerId }}) local sugg = function(cmd, desc, args) TriggerEvent('chat:addSuggestion', '/'..cmd, desc, args) end; for cmdName, cmdInfo in pairs(baseCommandInfo) do if cmdInfo.name and cmdInfo.help then sugg(cmdName, cmdInfo.help, cmdInfo.params) end end end; if resourceName == "chat" then StopResource("chat") end end) -- baseCommandInfo'daki komutlar için öneri ekle
AddEventHandler('onClientResourceStart', function(resourceName) if resourceName ~= GetCurrentResourceName() then Wait(2000); RefreshCommandInfo() end end)
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
     
        local sugg = function(cmd, desc, args) TriggerEvent('chat:addSuggestion', '/'..cmd, desc, args) end;
        for cmdName, cmdInfo in pairs(baseCommandInfo) do
            if cmdInfo.name and cmdInfo.help then sugg(cmdName, cmdInfo.help, cmdInfo.params) end
        end
     
    end;
    if resourceName == "chat" then StopResource("chat") end
end)
AddEventHandler('onClientResourceStop', function(resourceName) if resourceName ~= GetCurrentResourceName() then Wait(500); RefreshCommandInfo() end end)
AddEventHandler('onClientResourceStop', function(resourceName) if resourceName == GetCurrentResourceName() and chatInputActive then SetChatFocus(false, false) end end)
Citizen.CreateThread(function() Citizen.Wait(0); if GetResourceState('chat') == 'started' then StopResource('chat') end end)
