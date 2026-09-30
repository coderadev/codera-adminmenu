fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'codera-adminmenu'
author 'Codera'
description 'Admin Menu Nopixel V Inspired System'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'bridge/client.lua',
    'client/client.lua'
}

server_scripts {
    'bridge/server.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
