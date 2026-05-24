fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MadebyAzure.com'
description 'AChat - multi-framework FiveM chat replacement'
version '1.2.0'

ui_page 'html/index.html'

shared_script 'config.lua'

client_scripts {
    'bridge/client.lua',
    'client/main.lua'
}

server_scripts {
    'server_config.lua',
    'bridge/server.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/logo.svg'
}
