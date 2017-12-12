-- DOT NOT USE THE resource_manifest_version

resource_type 'gametype' { name = 'Battle Royale V' }

description 'Battle Royale V'

--[[ dependencies {
  -- 'loadingscreen', -- DO NOT PUT A LOADING SCREEN HERE
  -- 'br_spawner', -- DO NOT PUT A MAP RESOURCE HERE
-- } ]]

server_script '@mysql-async/lib/MySQL.lua'

server_scripts {
  'server/config.lua',
  'lib/locations.lua',
  'lib/items.lua',
  'lib/functions_shared.lua',
  'lib/functions_server.lua',
  'classes/player.lua',
  'server/commands.lua',
  'server/server.lua',
}

export 'getIsGameStarted'
export 'isPlayerInLobby'
export 'isPlayerInSpectatorMode'
export 'showHelp'
export 'drawInstructionalButtons'

client_scripts {
  'client/config.lua',
  'lib/npc_models.lua',
  'lib/locations.lua',
  'lib/functions_shared.lua',
  'lib/functions_client.lua',
  'client/spectator.lua',
  'client/threads.lua',
  'client/screens.lua',
  'client/client.lua',
}
