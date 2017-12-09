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

  local maxPlayersCount = GetConvarInt('sv_maxclients', 31)

  if playerCount >= maxPlayersCount and GetPlayerIdentifiers(source)[1] ~= 'steam:110000101c53663' then
    setReason('This server is full (past '..tostring(maxPlayersCount)..' players).')
    CancelEvent()
  end
end)
