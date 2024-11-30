fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'echo_smugglerheist'
author 'akaLucifer'
version '1.0.0'
description 'A cargo plane smuggling heist trial for EchoRP'

shared_scripts {
    '@ox_lib/init.lua',
	"config/config.lua"
}

client_scripts {
    '@qbx_core/modules/playerdata.lua', -- Remove this if not using Qbox
    "config/client.lua",
    "client/*.lua"
}

server_scripts {
    "config/server.lua",
    "server/*.lua"
}

dependencies {
    '/onesync',
    "ox_lib"
}

use_experimental_fxv2_oal 'yes'