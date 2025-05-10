document.addEventListener('DOMContentLoaded', () => {
    const messageContainer = document.getElementById('message-list');
    const chatInput = document.getElementById('chat-input');
    const inputArea = document.getElementById('input-area');
    const sendButton = document.getElementById('send-button');
    const chatWrapper = document.getElementById('chat-wrapper');
    const settingsButton = document.getElementById('settings-button');
    const settingsMenu = document.getElementById('settings-menu');
    const toggleThemeButton = document.getElementById('toggle-theme');
    const togglePositionButton = document.getElementById('toggle-position');
    const commandInfoBox = document.getElementById('command-info');

    let settings = { maxMessages: 15, fadeOutTime: 400, visibilityDuration: 10000, showTimestamps: true, showPlayerId: true };
    let chatVisible = false; let inputActive = false; let visibilityTimer = null;
    let commandData = {};
    let sentMessagesHistory = []; let historyIndex = -1; const MAX_HISTORY = 50;
    let currentTheme = localStorage.getItem('chatTheme') || 'light';
    let currentPosition = localStorage.getItem('chatPosition') || 'left';

    function escapeHtml(unsafe) { if (!unsafe) return ''; return unsafe.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;"); }
    function getCurrentTime() { return new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }); }

    function addMessage(data) {
        if (!messageContainer) return;
        const messageDiv = document.createElement('div'); messageDiv.classList.add('message'); const authorType = data.authorType || 'oyuncu'; messageDiv.classList.add(authorType);
        const namesDiv = document.createElement('div'); namesDiv.classList.add('isimler');
        const authorTypeSpan = document.createElement('span'); authorTypeSpan.className = authorType;
        let prefixText = ''; if (authorType === 'me' || authorType === 'do') prefixText = `${authorType.toUpperCase()}`; else if (authorType === 'police') prefixText = 'PDC'; else if (authorType === 'ems') prefixText = 'EMSC'; else if (authorType === 'emergency') prefixText = `${data.authorName || 'ACIL'}`; else if (authorType === 'system') prefixText = `SISTEM`; else if (authorType === 'server') prefixText = `SUNUCU`; else if (authorType === 'ooc') prefixText = 'OOC'; else if (authorType === 'error') prefixText = 'HATA';
        if (prefixText !== '') { authorTypeSpan.textContent = prefixText; namesDiv.appendChild(authorTypeSpan); }
        if (data.authorName && data.authorName !== '' && !['system', 'server', 'error', 'sistem'].includes(authorType)) {
            const playerNameSpan = document.createElement('span');
            playerNameSpan.classList.add('oyuncu');
            playerNameSpan.textContent = escapeHtml(data.authorName);
            namesDiv.appendChild(playerNameSpan);
       }
       if ((authorType === 'police' || authorType === 'ems') && data.rankLabel && data.rankLabel !== '') {
        const rankSpan = document.createElement('span');
        rankSpan.classList.add('rank');
        rankSpan.textContent = `(${escapeHtml(data.rankLabel)})`;
        namesDiv.appendChild(rankSpan);
    }
    if (settings.showPlayerId && data.playerId && data.playerId !== 0 && !['system', 'server', 'error', 'sistem'].includes(authorType)) {
        const playerIdSpan = document.createElement('span');
        playerIdSpan.classList.add('oyuncu');
        playerIdSpan.textContent = `(${data.playerId})`; 
        playerIdSpan.style.opacity = '0.7';
        playerIdSpan.style.fontSize = '0.8rem';
        playerIdSpan.style.marginLeft = '4px';
        namesDiv.appendChild(playerIdSpan);
    }
        messageDiv.appendChild(namesDiv);
        const messageContentSpan = document.createElement('span'); messageContentSpan.className = (authorType === 'error') ? 'hataaciklama' : 'aciklama'; messageContentSpan.innerHTML = colorizeText(escapeHtml(data.message || '')); messageDiv.appendChild(messageContentSpan);
        if (settings.showTimestamps) { const timeSpan = document.createElement('span'); timeSpan.classList.add('saat'); timeSpan.textContent = getCurrentTime(); messageDiv.appendChild(timeSpan); }
        messageContainer.insertBefore(messageDiv, messageContainer.firstChild); while (messageContainer.children.length > settings.maxMessages) { messageContainer.removeChild(messageContainer.lastChild); }
        showChatTemporarily();
    }

    function colorizeText(text) { return text.replace(/\^([0-9])/g, (match, colorCode) => { const colorMap = {'1': '#F44336', '2': '#4CAF50', '3': '#FFEB3B', '4': '#2196F3', '5': '#00BCD4', '6': '#9C27B0', '7': '#F0F0F0', '8': '#FF5722', '9': '#607D8B', '0': '#FFFFFF'}; return `</span><span style="color: ${colorMap[colorCode] || '#FFFFFF'}">`; }).replace(/\^r/g, '</span>'); }
    function showChatTemporarily() { clearTimeout(visibilityTimer); const hasMessages = messageContainer.children.length > 0; if (inputActive || hasMessages) { if (!chatVisible) { chatWrapper.style.opacity = '1'; chatVisible = true; } } else { chatWrapper.style.opacity = '0'; chatVisible = false; return; } if (!inputActive && hasMessages) { visibilityTimer = setTimeout(() => { chatWrapper.style.opacity = '0'; chatVisible = false; displayCommandInfo(null);}, settings.visibilityDuration); } }

    function displayCommandInfo(matchingCommands) {
        if (inputActive && matchingCommands && matchingCommands.length > 0) {
            let infoHTML = ''; const maxSuggestionsToShow = 5;
            for (let i = 0; i < Math.min(matchingCommands.length, maxSuggestionsToShow); i++) { const info = matchingCommands[i]; let paramsHTML = ''; if (info.params && info.params.length > 0) { paramsHTML = info.params.map(p => `<span class="cmd-param-name">[${escapeHtml(p.name || '?')}]</span>`).join(' '); } infoHTML += `<div class="cmd-entry"><span class="cmd-name">${escapeHtml(info.name)}</span> <span class="cmd-params">${paramsHTML}</span> <span class="cmd-desc">- ${escapeHtml(info.help || 'Açıklama yok')}</span></div>`; }
            commandInfoBox.innerHTML = infoHTML;
            try { const chatRect = chatWrapper.getBoundingClientRect(); commandInfoBox.style.top = `${chatRect.bottom + 8}px`; if (chatWrapper.classList.contains('chat-pos-right')) { commandInfoBox.style.left = 'auto'; commandInfoBox.style.right = `${window.innerWidth - chatRect.right}px`; } else { commandInfoBox.style.right = 'auto'; commandInfoBox.style.left = `${chatRect.left}px`; } commandInfoBox.style.width = `${chatRect.width}px`; commandInfoBox.style.display = 'block'; } catch(e) { commandInfoBox.style.display = 'none'; }
        } else { commandInfoBox.style.display = 'none'; commandInfoBox.innerHTML = ''; }
    }

    function setInputActiveState(active) { inputActive = active; inputArea.style.display = active ? 'block' : 'none'; settingsMenu.style.display = 'none'; if (active) { clearTimeout(visibilityTimer); if (!chatVisible) { showChatTemporarily(); } setTimeout(() => { try { chatInput.focus(); } catch(e){} }, 50); historyIndex = -1; handleInputChange(); } else { chatInput.value = ''; sendButton.disabled = true; displayCommandInfo(null); showChatTemporarily(); } }

    function applyTheme() {
        if (currentTheme === 'dark') {
            chatWrapper.classList.add('chat-theme-dark');
            commandInfoBox.classList.add('chat-theme-dark');
        } else {
            chatWrapper.classList.remove('chat-theme-dark');
            commandInfoBox.classList.remove('chat-theme-dark');
        }
    }

    function applyPosition() { if (currentPosition === 'right') { chatWrapper.classList.add('chat-pos-right'); commandInfoBox.classList.add('chat-pos-right'); } else { chatWrapper.classList.remove('chat-pos-right'); commandInfoBox.classList.remove('chat-pos-right'); } handleInputChange(); }
    if (toggleThemeButton) { toggleThemeButton.addEventListener('click', () => { currentTheme = (currentTheme === 'light') ? 'dark' : 'light'; localStorage.setItem('chatTheme', currentTheme); applyTheme(); settingsMenu.style.display = 'none'; }); }
    if (togglePositionButton) { togglePositionButton.addEventListener('click', () => { currentPosition = (currentPosition === 'left') ? 'right' : 'left'; localStorage.setItem('chatPosition', currentPosition); applyPosition(); settingsMenu.style.display = 'none'; }); }
    if (settingsButton) { settingsButton.addEventListener('click', (event) => { event.stopPropagation(); settingsMenu.style.display = (settingsMenu.style.display === 'block') ? 'none' : 'block'; }); }
    document.addEventListener('click', (event) => { if (settingsMenu.style.display === 'block' && !settingsMenu.contains(event.target) && event.target !== settingsButton && !settingsButton.contains(event.target)) { settingsMenu.style.display = 'none'; } });

    window.addEventListener('message', (event) => { const data = event.data; if (!data || !data.type) return; switch (data.type) { case 'addMessage': addMessage(data.messageData); break; case 'showChatInput': setInputActiveState(true); break; case 'hideChatInput': setInputActiveState(false); break; case 'clearMessages': messageContainer.innerHTML = ''; showChatTemporarily(); break; case 'setInputText': chatInput.value = data.text || ''; sendButton.disabled = chatInput.value.trim() === ''; handleInputChange(); break; case 'clearInput': chatInput.value = ''; sendButton.disabled = true; handleInputChange(); break; case 'updateSettings': if (data.settings) { settings = { ...settings, ...data.settings }; chatWrapper.style.transitionDuration = `${settings.fadeOutTime / 1000}s`; } break; case 'updateCommandData': if (data.commands) { commandData = data.commands; handleInputChange(); } break; } });

    function handleInputChange() { const value = chatInput.value; let infoToShow = null; let potentialCmd = ''; let matchingCommands = []; if (value.trim() === '') { displayCommandInfo(null); return; } if (value.startsWith('/')) { const spacePos = value.indexOf(' '); potentialCmd = (spacePos === -1) ? value.substring(1).toLowerCase() : value.substring(1, spacePos).toLowerCase(); } else if (value.length > 0) { const spacePos = value.indexOf(' '); potentialCmd = (spacePos === -1) ? value.toLowerCase() : value.substring(0, spacePos).toLowerCase(); } if (potentialCmd.length > 0 && commandData) { matchingCommands = Object.keys(commandData).filter(cmdName => cmdName.startsWith(potentialCmd)).map(cmdName => commandData[cmdName]).sort((a, b) => a.name.localeCompare(b.name)); } displayCommandInfo(matchingCommands); }
    chatInput.addEventListener('input', handleInputChange); chatInput.addEventListener('focus', handleInputChange);
    chatInput.addEventListener('blur', () => { if (inputActive) { setTimeout(() => { try { if (inputActive && document.activeElement !== chatInput) { chatInput.focus(); } } catch (e) {} }, 10); } setTimeout(() => { if(document.activeElement !== chatInput) { displayCommandInfo(null);} }, 100); });
    function sendMessage() { const message = chatInput.value.trim(); if (message) { if (sentMessagesHistory[0] !== message) { sentMessagesHistory.unshift(message); if (sentMessagesHistory.length > MAX_HISTORY) { sentMessagesHistory.pop(); } } historyIndex = -1; fetch(`https://${GetParentResourceName()}/sendMessage`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify({ message: message }) }).catch(console.error); } }
    if(sendButton) { sendButton.addEventListener('click', sendMessage); }
    chatInput.addEventListener('keyup', (event) => { if (event.key === 'Enter' || event.keyCode === 13) { sendMessage(); } else if (event.key === 'Escape' || event.keyCode === 27) { fetch(`https://${GetParentResourceName()}/hideChat`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify({}) }).catch(console.error); } else if (event.key === 'ArrowUp' || event.keyCode === 38) { event.preventDefault(); if (sentMessagesHistory.length > 0 && historyIndex < sentMessagesHistory.length - 1) { historyIndex++; chatInput.value = sentMessagesHistory[historyIndex]; chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length); sendButton.disabled = false; handleInputChange(); } } else if (event.key === 'ArrowDown' || event.keyCode === 40) { event.preventDefault(); if (historyIndex > -1) { historyIndex--; if (historyIndex === -1) { chatInput.value = ''; } else { chatInput.value = sentMessagesHistory[historyIndex]; } chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length); sendButton.disabled = chatInput.value.trim() === ''; handleInputChange(); } } });

    chatWrapper.style.transitionDuration = `${settings.fadeOutTime / 1000}s`; inputArea.style.display = 'none'; chatWrapper.style.opacity = '0'; applyTheme(); applyPosition();
});
