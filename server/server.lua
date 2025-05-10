local QBCore = exports['qb-core']:GetCoreObject()

local function SendClientMessage(targetId, messageData) TriggerClientEvent('bs-chat:addMessage', targetId, messageData) end

RegisterNetEvent('bs-chat:sendMessage', function(message, messageType)
    local src = source; local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
    if not message or message == "" then if messageType == 'me' or messageType == 'do' or messageType == 'ooc' or messageType == 'pdc' or messageType == 'emsc' then SendClientMessage(src, { authorType=Config.MessageTypes['error'], authorName='HATA', message='/'..messageType .. ' komutu için mesaj girmelisiniz.'}) end; return end

    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname; local playerId = src
    local typeToSend = messageType or 'default'; local cssType = Config.MessageTypes[typeToSend] or 'oyuncu'
    local targetClients = {}; local isProximityBased = (typeToSend == 'me' or typeToSend == 'do')
    local rankLabel = nil

    if isProximityBased and Config.MeDoCommandDistance > 0 then local sourceCoords = GetEntityCoords(GetPlayerPed(src)); local players = QBCore.Functions.GetPlayers() for _, targetPlayerId in ipairs(players) do local targetPed = GetPlayerPed(targetPlayerId) if targetPed and targetPed ~= 0 then if #(sourceCoords - GetEntityCoords(targetPed)) <= Config.MeDoCommandDistance then table.insert(targetClients, targetPlayerId) end end end
    elseif typeToSend == 'emsc' then 
        local senderJob = Player.PlayerData.job
        cssType = Config.MessageTypes['emschat'] or 'ems'
        if Config.EmsJobs[senderJob.name:lower()] then
            rankLabel = senderJob.grade.label or senderJob.grade.name or ''
            local players = QBCore.Functions.GetPlayers()
            for _, targetPlayerId in ipairs(players) do
                local TargetPlayer = QBCore.Functions.GetPlayer(targetPlayerId)
                if TargetPlayer and Config.EmsJobs[TargetPlayer.PlayerData.job.name:lower()] then
                    table.insert(targetClients, targetPlayerId)
                end
            end
            if #targetClients == 0 then table.insert(targetClients, src) end
        else
            SendClientMessage(src, { authorType=Config.MessageTypes['error'], authorName='HATA', message='EMS sohbetini kullanma yetkiniz yok.'})
            return
        end
        local messageData = { authorType = cssType, authorName = playerName, playerId = playerId, message = message, showPlayerId = Config.ShowPlayerId, rankLabel = rankLabel }
        for _, targetId in ipairs(targetClients) do SendClientMessage(targetId, messageData) end
        return
    elseif typeToSend == 'pdc' then
        local senderJob = Player.PlayerData.job; cssType = Config.MessageTypes['pdc'] or 'police'
        if Config.PoliceJobs[senderJob.name:lower()] then rankLabel = senderJob.grade.label or senderJob.grade.name or ''; local players = QBCore.Functions.GetPlayers() for _, targetPlayerId in ipairs(players) do local TargetPlayer = QBCore.Functions.GetPlayer(targetPlayerId) if TargetPlayer and Config.PoliceJobs[TargetPlayer.PlayerData.job.name:lower()] then table.insert(targetClients, targetPlayerId) end end; if #targetClients == 0 then table.insert(targetClients, src) end
        else SendClientMessage(src, { authorType=Config.MessageTypes['error'], authorName='HATA', message='Polis sohbetini kullanma yetkiniz yok.'}); return end
        local messageData = { authorType = cssType, authorName = playerName, playerId = playerId, message = message, showPlayerId = Config.ShowPlayerId, rankLabel = rankLabel }
        for _, targetId in ipairs(targetClients) do SendClientMessage(targetId, messageData) end
        return
    elseif typeToSend == 'ooc' then
        cssType = Config.MessageTypes['ooc'] or 'ooc'; targetClients = {-1}
    elseif typeToSend == 'me' or typeToSend == 'do' then
        cssType = Config.MessageTypes[typeToSend] or 'oyuncu'
        if Config.MeDoCommandDistance <= 0 then targetClients = {-1} end
    else return
    end

    local messageData = { authorType = cssType, authorName = playerName, playerId = playerId, message = message, showPlayerId = Config.ShowPlayerId }
    if rankLabel then messageData.rankLabel = rankLabel end
    for _, targetId in ipairs(targetClients) do SendClientMessage(targetId, messageData) end
end)
function SendServerMessage(message) SendClientMessage(-1, { authorType = Config.MessageTypes['server'] or 'system', authorName='Sunucu', playerId=0, message = message, showPlayerId = false }) end; exports('SendServerMessage', SendServerMessage)
function SendSystemMessage(message) SendClientMessage(-1, { authorType = Config.MessageTypes['system'] or 'system', authorName='Sistem', playerId=0, message = message, showPlayerId = false }) end; exports('SendSystemMessage', SendSystemMessage)
