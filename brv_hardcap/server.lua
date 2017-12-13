local maxPlayersCount = GetConvarInt('sv_maxclients', 32)
local adminId = GetConvar('sv_adminId', '')

local playerCount = 0
local list = {}


RegisterServerEvent('hardcap:playerActivated')
AddEventHandler('hardcap:playerActivated', function()
  if not list[source] then
    playerCount = playerCount + 1
    list[source] = true
  end
end)


AddEventHandler('playerDropped', function()
  if list[source] then
    playerCount = playerCount - 1
    list[source] = nil
  end
end)


AddEventHandler('playerConnecting', function(name, setReason)
  print(name..' is connecting...')

  if playerCount >= maxPlayersCount and GetPlayerIdentifiers(source)[1] ~= adminId then
    setReason('Sorry, the server is full.')
    CancelEvent()
  end
end)
