fx_version 'bodacious'
game 'gta5'

--> Copyright to InZidiuZ @Reworked by Super.Cool.Ninja.

client_scripts {
	'config.lua',
	'source/fuel_client.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	'source/fuel_server.lua'
}

ui_page "html/index.html"
files {
    "html/index.html",
    "html/script.js",
    "html/style.css"
}