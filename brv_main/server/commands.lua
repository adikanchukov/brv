--------------------------------------------------------------------------------
--                               BATTLE ROYALE                                --
--                               Chat commands                                --
--------------------------------------------------------------------------------
local commands = {}

-- List of all interiors
local interiors = {
  { x = 261.4586, y = -998.8196, z = -99.00863 },
  { x = -35.31277, y = -580.4199, z = 88.71221 },
  { x = -1477.14, y = -538.7499, z = 55.5264 },
  { x = -18.07856, y = -583.6725, z = 79.46569 },
  { x = -1468.14, y = -541.815, z = 73.4442 },
  { x = -915.811, y = -379.432, z = 113.6748 },
  { x = -614.86, y = 40.6783, z = 97.60007 },
  { x = -773.407, y = 341.766, z = 211.397 },
  { x = -169.286, y = 486.4938, z = 137.4436 },
  { x = 340.9412, y = 437.1798, z = 149.3925 },
  { x = 373.023, y = 416.105, z = 145.7006 },
  { x = -676.127, y = 588.612, z = 145.1698 },
  { x = -763.107, y = 615.906, z = 144.1401 },
  { x = -857.798, y = 682.563, z = 152.6529 },
  { x = 120.5, y = 549.952, z = 184.097 },
  { x = -1288.055, y = 440.748, z = 97.69459 }, -- 16
  { x = 229.9559, y = -981.7928, z = -99.66071 }, -- 17
}

-- Declares a new command
function addCommand(name, callback)
  commands[name] = callback
end

-- Calls a command callback with player and args
function callCommand(name, player, args)
  if commands[name] ~= nil then
    return commands[name](player, args)
  end
  return false
end

-- /kick playerId
-- Kicks a player out of the server
-- ADMIN ONLY
addCommand('kick', function(player, args)
  if GetPlayerName(args[1]) and player:isAdmin() then
    if args[1] == player.source then
      sendSystemMessage(player.source, 'You can\'t kick yourself !')
    else
      local message = ''
      if args[2] == nil then
        message = 'You have been kicked'
      else
        message = args[2]
      end
      DropPlayer(args[1], message)
    end
    return true
  end

  return false
end)

-- /ban playerId
-- Disable the player and kicks him out of the server
-- ADMIN ONLY
addCommand('ban', function(player, args)
  if GetPlayerName(args[1]) and player:isAdmin() then
    if args[1] == player.source then
      sendSystemMessage(player.source, 'You can\'t ban yourself !')
    else
      args[2] = 'You have been banned'
      MySQL.Async.execute('UPDATE players SET status=@status WHERE id=@id', {['@status'] = 0, ['@id'] = args[1]}, function()
        callCommand('kick', player, args)
      end)
    end
    return true
  end

  return false
end)

-- /skin
-- Change the skin, if the game has not already started
addCommand('skin', function(player, args)
  if getIsGameStarted() then
    sendSystemMessage(player.source, 'You can\'t change your skin during the match')
  else
    TriggerClientEvent('brv:changeSkin', player.source)
  end
  return true
end)

-- /saveskin
-- Saves the current player skin
addCommand('saveskin', function(player, args)
  if getIsGameStarted() then
    sendSystemMessage(player.source, 'You can\'t save your skin during the match')
  else
    TriggerEvent('brv:saveSkin', player.source)
  end
  return true
end)

-- /vote
-- Vote for the game to start
addCommand('vote', function(player, args)
  if getIsGameStarted() then
    sendSystemMessage(player.source, 'You can\'t vote during the match')
  else
    TriggerEvent('brv:voteServer', player.source)
  end
  return true
end)

-- /name
-- Change the player's name
addCommand('name', function(player, args)
  if getIsGameStarted() then
    sendSystemMessage(player.source, 'You can\'t change your name during the match')
  else
    if #args == 0 then
      sendSystemMessage(player.source, 'Invalid name')
    else
      local newName = table.concat(args, ' ')
      if string.find(newName, '%^') then
        sendSystemMessage(player.source, 'Invalid name')
      else
        player.name = newName
        MySQL.Async.execute('UPDATE players SET name=@name WHERE id=@id', {['@name'] = newName, ['@id'] = player.id})
        TriggerClientEvent('brv:changeName', player.source, player.name)
        sendMessage(player.source, 'SYSTEM', {255, 255, 255}, 'Name changed to ^4' .. newName)
      end
    end
  end
  return true
end)

-- /911
-- Send a message to the admins
addCommand('911', function(player, args)
  local players = getPlayers()

  for k, v in pairs(players) do
    if v:isAdmin() then
      sendSystemMessage(v.source, '^1911^9 : ' .. player.name .. ' (^4' .. player.source .. '^9)' .. ' : ' .. table.concat(args, ' '))
    end
  end
  return true
end)

-- /list
-- List all connected players
-- ADMIN ONLY
addCommand('list', function(player, args)
  if player:isAdmin() then
    local message = ''
    local players = getPlayers()

    for k, v in pairs(players) do
      if v:isAdmin() then
        message = '%d - %s ^4[admin]^2'
      else
        message = '%d - %s'
      end
      message = message .. ' (' .. GetPlayerPing(v.source) .. ')'
      sendSystemMessage(player.source, string.format(message, v.source, v.name))
    end
    return true
  end

  return false
end)

-- /coords
-- Saves the current coords to the database
-- ADMIN ONLY
addCommand('coords', function(player, args)
  if player:isAdmin() then
    TriggerClientEvent('brv:saveCoords', player.source)
    return true
  end
  return false
end)

-- /tpi interiorIndex
-- Teleports into one of the interiors (see list above)
-- ADMIN ONLY
addCommand('tpi', function(player, args)
  if args[1] and player:isAdmin() then
    local index = tonumber(args[1])
    local coords = interiors[index]
    TriggerClientEvent('brv:playerTeleportation', player.source, coords)
    sendSystemMessage(player.source, 'Teleported to interior n°^4' .. index)
    return true
  end
  return false
end)

-- /tpto playerId
-- Teleports next to a player
-- ADMIN ONLY
addCommand('tpto', function(player, args)
  if args[1] and player:isAdmin() then
    local target = args[1]
    if target == 'marker' then
      TriggerClientEvent('brv:playerTeleportationToMarker', player.source)
      sendSystemMessage(player.source, 'Teleported to ^4marker')
    else
      target = tonumber(target)
      if target == player.source then
        sendSystemMessage(player.source, 'You can\'t TP on yourself')
      else
        TriggerClientEvent('brv:playerTeleportationToPlayer', player.source, target)
        sendSystemMessage(player.source, 'Teleported to ^4' .. getPlayerName(target))
      end
    end
    return true
  end
  return false
end)

-- /tpfrom playerId
-- Teleports a player next to you
-- ADMIN ONLY
addCommand('tpfrom', function(player, args)
  if args[1] and player:isAdmin() then
    local source = tonumber(args[1])
    if source == player.source then
      sendSystemMessage(player.source, 'You can\'t TP on yourself')
    else
      TriggerClientEvent('brv:playerTeleportationToPlayer', source, player.source)
      sendSystemMessage(player.source, 'Teleported ^4' .. getPlayerName(source) .. '^2 to you')
      sendSystemMessage(source, 'Teleported by ^4' .. player.name)
    end
    return true
  end
  return false
end)

-- /help
-- Displays a welcome message
addCommand('help', function(player, args)
  sendSystemMessage(player.source, "^2Welcome to ^8Battle Royale V Reborn^2 ^4ALPHA^2 !")
  sendSystemMessage(player.source, "^2Available commands :")
  sendSystemMessage(player.source, "^4/help^2 : Show this message")
  sendSystemMessage(player.source, "^4/skin^2 : Select new random skin")
  sendSystemMessage(player.source, "^4/saveskin^2 : Save current skin")
  sendSystemMessage(player.source, "^4/name NEWNAME^2 : Change name to NEWNAME")
  sendSystemMessage(player.source, "^4/vote^2 : Vote to start the game immediately")
  sendSystemMessage(player.source, "^2Key controls :")
  sendSystemMessage(player.source, "^4\"ARROW UP (HOLD)\"^2 : Display Scoreboard")
  sendSystemMessage(player.source, "^4\"F\"^2 : Enable Spectator Mode near TV in lobby")
  sendSystemMessage(player.source, "^4\"Z\"^2 : Toggle Extended Radar")
  sendSystemMessage(player.source, "^2Join our Discord and thanks for playing !")
  return true
end)

-- /start
-- Start the Battle !
-- ADMIN ONLY
addCommand('start', function(player, args)
  if player:isAdmin() then
    TriggerEvent('brv:startGame')
    return true
  end
  return false
end)

-- /stop [1]
-- Stop the Battle !
-- ADMIN ONLY
addCommand('stop', function(player, args)
  if player:isAdmin() then
    local restart = true
    if args[1] ~= nil and args[1] == 1 then restart = false end
    TriggerEvent('brv:stopGame', restart, true)
    return true
  end
  return false
end)

-- /health
-- Sets player health, for debug purposes
-- ADMIN ONLY
addCommand('health', function(player, args)
  if args[1] and player:isAdmin() then
    TriggerClientEvent('brv:setHealth', player.source, args[1])
    return true
  end
  return false
end)

-- Parse every chat message to detect if a command was entered
AddEventHandler('chatMessage', function(source, name, message)
  if string.len(message) > 1 and string.sub(message, 1, 1) == '/' then
    local args = explode(message, ' ')

    local cmd = string.sub(table.remove(args, 1), 2)
    local player = getPlayer(source)

    if callCommand(cmd, player, args) then
      print(string.format("Command '%s' found, called by '%s'.", cmd, name))
      CancelEvent()
    end
  end
end)
