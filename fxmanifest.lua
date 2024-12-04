fx_version "cerulean"
game "gta5"
lua54 "yes"

name "echo_smugglerheist"
author "akaLucifer"
version "1.0.0"
description "A cargo plane smuggling heist trial for EchoRP"

ui_page "html/ui.html"

files {
    "config/client.lua",
    "config/shared.lua",
    "client/dui.lua",
    "client/mission.lua",
	'html/*.*'
}

shared_scripts {
    "@ox_lib/init.lua",
	"@qbx_core/modules/lib.lua",
    "shared/*.lua",
	"config/config.lua"
}

client_scripts {
    "@qbx_core/modules/playerdata.lua", -- Remove this if not using Qbox
    "config/client.lua",
    "client/*.lua"
}

server_scripts {
    "config/server.lua",
    "server/*.lua"
}

dependencies {
    "/onesync",
    "ox_lib"
}

use_experimental_fxv2_oal "yes"