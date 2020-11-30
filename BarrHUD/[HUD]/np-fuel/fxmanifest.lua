fx_version 'bodacious'
games { 'gta5' }

client_script "@errorlog/client/cl_errorlog.lua"


author 'InZidiuZ'
description 'Legacy Fuel'
version '1.3'

-- What to run
client_scripts {
	'config.lua',
	'functions/functions_client.lua',
	'source/fuel_client.lua'
}

server_scripts {
	'config.lua',
	'source/fuel_server.lua'
}

exports {
	'GetFuel',
	'SetFuel'
}

--Fuck YM Leakssss - NewLeaks Are The Best!!!
--Barr#0725   RoFoS#4444

