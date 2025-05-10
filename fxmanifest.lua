fx_version 'cerulean'
game 'gta5'

author 'Busiriss'
description 'bs-chat'
version '1.0.0' 

shared_scripts {
    'config.lua',
}

server_scripts {
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core'
}