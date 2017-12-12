--------------------------------------------------------------------------------
--                               BATTLE ROYALE V                              --
--                              Main client file                              --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                 Variables                                  --
--------------------------------------------------------------------------------
local firstSpawn = true -- Used to trigger a first spawn event to the server and loads the player from DB
local nbPlayersRemaining = 0 -- Printed top left
local alivePlayers = {} -- A table with all alive players, during a game
local isGameStarted = false -- Is game started ?
local gameEnded = false -- True during restart
local playerInLobby = true -- Is the player in the lobby ?
local player = {} -- Local player data
local pickups = {} -- Local pickups data
local pickupBlips = {} -- All pickup blips

local safeZones = {} -- All safezones
local safeZonesBlips = {} -- All safezones blips
local currentSafeZone = 1; -- Current safe zone

local safeZoneTimer -- Global safe zone timer, default value is in the config file
local safeZoneTimerDec -- Step of the timer

--------------------------------------------------------------------------------
--                                  Events                                    --
--------------------------------------------------------------------------------
RegisterNetEvent('brv:playerLoaded') -- Player loaded from the server
RegisterNetEvent('brv:playerTeleportation') -- Teleportation to coordinates
RegisterNetEvent('brv:playerTeleportationToPlayer') -- Teleportation to another player
RegisterNetEvent('brv:playerTeleportationToMarker') -- Teleportation to the marker - NOT WORKING
RegisterNetEvent('brv:updateAlivePlayers') -- Track the remaining players in battle
RegisterNetEvent('brv:showNotification') -- Shows a basic notification
RegisterNetEvent('brv:showNotificationDetails') -- Shows an advanced notification
RegisterNetEvent('brv:setHealth') -- DEBUG : sets the current health (admin only)
RegisterNetEvent('brv:changeSkin') -- Change the current skin
RegisterNetEvent('brv:changeName') -- Change the current name
RegisterNetEvent('brv:nextSafeZone') -- Triggers the next safe zone, recursive event
RegisterNetEvent('brv:createPickups') -- Generates all the pickups
RegisterNetEvent('brv:addPickup') -- Add one pickup, without blip
RegisterNetEvent('brv:removePickup') -- Remove a pickup
RegisterNetEvent('brv:wastedScreen') -- WASTED
RegisterNetEvent('brv:winnerScreen') -- WINNER
RegisterNetEvent('brv:setGameStarted') -- For players joining during battle
RegisterNetEvent('brv:startGame') -- Starts a battle
RegisterNetEvent('brv:stopGame') -- Stops a battle
RegisterNetEvent('brv:restartGame') -- Enable restart
RegisterNetEvent('brv:saveCoords') -- DEBUG : saves current coords (admin only)

--------------------------------------------------------------------------------
--                                 Functions                                  --
--------------------------------------------------------------------------------
function getIsGameStarted()
  return isGameStarted
end

function setGameStarted(gameStarted)
  isGameStarted = gameStarted
end

function getLocalPlayer()
  return player
end

function getPickups()
  return pickups
end

function deletePickup(i)
  pickups[i] = nil
end

function getPlayersRemaining()
  return nbPlayersRemaining
end

function getAlivePlayers()
  return alivePlayers
end

function getCurrentSafeZone()
  return currentSafeZone
end

function isPlayerInLobby()
  return playerInLobby
end

function getIsGameEnded()
  return gameEnded
end

function setGameEnded(enable)
  gameEnded = enable
end
--------------------------------------------------------------------------------
--                              Event handlers                                --
--------------------------------------------------------------------------------
AddEventHandler('onClientMapStart', function()
  exports.spawnmanager:setAutoSpawn(false)
  exports.spawnmanager:spawnPlayer()
  SetClockTime(24, 0, 0)
  PauseClock(true)

  -- Voice proximity
  NetworkSetTalkerProximity(0.0)
  NetworkSetVoiceActive(false)
end)

AddEventHandler('playerSpawned', function()
  local playerId = PlayerId()
  local ped = GetPlayerPed(playerId)

  -- Disable PVP
  SetCanAttackFriendly(ped, false, false)
  NetworkSetFriendlyFireOption(false)
  -- SetEntityCanBeDamaged(ped, false)

  if firstSpawn then
    firstSpawn = false
    TriggerServerEvent('brv:playerFirstSpawned')
  end

  playerInLobby = true
end)

-- Updates the current number of alive (remaining) players
AddEventHandler('brv:updateAlivePlayers', function(players)
  nbPlayersRemaining = #players
  alivePlayers = players
end)

-- Teleports the player to coords
AddEventHandler('brv:playerTeleportation', function(coords)
  teleport(coords)
end)

-- Teleports the player to another player
AddEventHandler('brv:playerTeleportationToPlayer', function(target)
  local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target)))
  teleport(coords)
end)

-- Teleports the player to the marker
-- UNSTABLE
AddEventHandler('brv:playerTeleportationToMarker', function()
  local blip = GetFirstBlipInfoId(8)
  if not DoesBlipExist(blip) then
    return
  end
  local vector = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())
  local coords = {
    x = vector.x,
    y = vector.y,
    z = 0.0,
  }
  teleport(coords)
end)

-- Show a notification
AddEventHandler('brv:showNotification', function(message)
  showNotification(message)
end)

-- Show a notification with details
AddEventHandler('brv:showNotificationDetails', function(pic, title, subtitle, message)
  showNotificationDetails(pic, title, subtitle, message)
end)

-- Sets current player health
AddEventHandler('brv:setHealth', function(health)
  SetEntityHealth(GetPlayerPed(-1), tonumber(health) + 100)
end)

AddEventHandler('brv:playerLoaded', function(playerData)
  player = playerData

  if not player.skin then
    TriggerEvent('brv:changeSkin')
    TriggerServerEvent('brv:saveSkin', player.source)
  else
    player.skin = changeSkin(player.skin)
  end
end)

-- Change player name
AddEventHandler('brv:changeName', function(newName)
  player.name = newName
end)

-- Change player skin
AddEventHandler('brv:changeSkin', function()
  player.skin = changeSkin()
  TriggerServerEvent('brv:skinChanged', player.skin)
end)

-- Sets the game as started, when the player join the server during a battle
AddEventHandler('brv:setGameStarted', function()
  isGameStarted = true
end)

-- Start the battle !
AddEventHandler('brv:startGame', function(nbAlivePlayers, svSafeZonesCoords)
  gameEnded = false
  safeZoneTimer = conf.safeZoneTimer
  safeZoneTimerDec = safeZoneTimer / 5
  currentSafeZone = 1

  nbPlayersRemaining = nbAlivePlayers

  player.spawn = getRandomLocation()
  player.spawn.z = 1200.0 -- Get high !

  local ped = GetPlayerPed(-1)
  local parachute = GetHashKey('gadget_parachute')
  local weapModel = getRandomMeleeWeapon()
  local weapon = GetHashKey(weapModel)

  -- Remove all previously given weapons
  RemoveAllPedWeapons(ped, true)

  -- Give a parachute and a random melee weapon
  GiveWeaponToPed(ped, parachute, 1, false, false)
  GiveWeaponToPed(ped, weapon, 1, false, true)

  -- If player is dead, resurrect him on target
  if IsPedDeadOrDying(ped, true) then
    NetworkResurrectLocalPlayer(player.spawn.x, player.spawn.y, player.spawn.z, 1, true, true, false)
  else
    -- Else teleports player
    teleport(player.spawn)
  end

  playerInLobby = false

  -- Enable PVP
  SetCanAttackFriendly(ped, true, false)
  NetworkSetFriendlyFireOption(true)
  -- SetEntityCanBeDamaged(ped, true)

  -- Enable drop weapon after death
  SetPedDropsWeaponsWhenDead(ped, true)

  -- Sets all safezones
  safeZones = svSafeZonesCoords

  -- Generate pickup blips
  for i, location in pairs(locations) do
    if location.x ~= player.spawn.x and location.y ~= player.spawn.y then
      pickupBlips[i] = addPickupBlip(location)
    end
  end

  -- Set game state as started
  isGameStarted = true

  -- Triggers the first one
  TriggerEvent('brv:nextSafeZone')
  TriggerServerEvent('brv:clientGameStarted', {
    spawn = player.spawn,
    weapon = weapModel,
  })
end)

AddEventHandler('brv:createPickups', function(seed)
  -- Generates pickups based on server seed
  Citizen.CreateThread(function()
    local index = 0
    local rand = math.random() * 50000 -- Saves a client sided rand
    if count(pickups) > 0 then
      for i, v in pairs(pickups) do
        RemovePickup(v.id)
      end
      pickups = { }
    end

    math.randomseed(seed * 50000)

    for i, location in pairs(locations) do
      if location.x ~= player.spawn.x and location.y ~= player.spawn.y then
        local pickupItem = getRandomPickup()
        index = tonumber(round(math.random())+1)
        pickups[i] = {
          id = CreatePickup(GetHashKey(pickupItem.id), location.x, location.y, location.z),
          coords = location
        }
      end
    end
    math.randomseed(rand)
  end)
end)

AddEventHandler('brv:addPickup', function(pickupHash, location)
  if not IsEntityDead(GetPlayerPed(-1)) then
    local pickup = CreatePickup(pickupHash, location.x, location.y, location.z)
    table.insert(pickups, { id = pickup, coords = location })
  end
end)

AddEventHandler('brv:restartGame', function()
  if not isGameStarted then
    gameEnded = true
  end
end)

AddEventHandler('brv:stopGame', function(winnerName, restart)
  isGameStarted = false
  currentSafeZone = 1

  -- Disable spectator mode
  if isPlayerInSpectatorMode() then
    setPlayerInSpectatorMode(false)
  end

  showNotification('And the winner is ~r~' .. winnerName)

  exports.spawnmanager:spawnPlayer(false, function()
    player.skin = changeSkin(player.skin)
  end)

  for _,safeZoneBlip in pairs(safeZonesBlips) do
    RemoveBlip(safeZoneBlip)
  end

  for _, pickupBlip in pairs(pickupBlips) do
    RemoveBlip(pickupBlip)
  end

  if restart then
    gameEnded = true
  else
    gameEnded = false
  end
end)

-- Triggers the next Safe zone
AddEventHandler('brv:nextSafeZone', function()
  -- Draw zone on the map
  if currentSafeZone <= #safeZones  then
    if conf.debug and currentSafeZone == 1 then
      for i, v in ipairs(safeZones) do
        safeZonesBlips[i] = setSafeZone(nil, v, i, false)
      end
    end
    if not conf.debug then
      safeZonesBlips[currentSafeZone] = setSafeZone(safeZonesBlips[currentSafeZone - 2], safeZones[currentSafeZone], currentSafeZone, true)
      -- Sets counter
      showCountdown(safeZoneTimer, 1 , function() -- 1 + step ?
        currentSafeZone = currentSafeZone + 1
        safeZoneTimer = safeZoneTimer - safeZoneTimerDec
        -- Rince, repeat
        TriggerEvent('brv:nextSafeZone')
      end)
    end
  end
end)

-- Removes a pickup
AddEventHandler('brv:removePickup', function(index)
  if pickups[index] ~= nil then
    RemovePickup(pickups[index].id)
    pickups[index] = nil
  end
end)

-- Saves current player's coordinates
AddEventHandler('brv:saveCoords', function()
  Citizen.CreateThread(function()
    local coords = GetEntityCoords(GetPlayerPed(-1))
    TriggerServerEvent('brv:saveCoords', {x = coords.x, y = coords.y, z = coords.z})
  end)
end)

-- Instant Death when out of zone
Citizen.CreateThread(function()
  local countdown = 0
  local playerOutOfZone = false
  local playerOOZAt = nil
  local timeDiff = 0
  local prevCount = conf.outOfZoneTimer
  local lastZoneAt = nil
  local instantDeathCountdown = 0
  local timeDiffLastZone = 0

  while true do
    Wait(0)
    if isGameStarted and not playerInLobby and not IsEntityDead(PlayerPedId()) then
      if safeZones[currentSafeZone - 1] ~= nil then
        playerOutOfZone = isPlayerOutOfZone(safeZones[currentSafeZone - 1])
        if playerOutOfZone then
          if not playerOOZAt then playerOOZAt = GetGameTimer() end

          timeDiff = GetTimeDifference(GetGameTimer(), playerOOZAt)
          countdown = conf.outOfZoneTimer - tonumber(round(timeDiff / 1000))

          if countdown ~= prevCount then
            if countdown == 9 then
              PlaySoundFrontend(-1, 'Timer_10s', 'DLC_HALLOWEEN_FVJ_Sounds')
            else
              if countdown > 9 then
                PlaySoundFrontend(-1, 'TIMER', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
              end
            end
            prevCount = countdown
          end

          showText('GET IN THE SAFE ZONE : ' .. countdown .. '', 0.45, 0.125, conf.color.red, 2)
          if countdown < 0  then
            SetEntityHealth(GetPlayerPed(-1), 0)
            playerOOZAt = nil
          end
        end
        if currentSafeZone == (#safeZones+1) then
          if not lastZoneAt then lastZoneAt = GetGameTimer() end
          timeDiffLastZone = GetTimeDifference(GetGameTimer(), lastZoneAt)
          instantDeathCountdown = conf.instantDeathTimer - tonumber(round(timeDiffLastZone / 1000))
          showText('ONLY ONE CAN SURVIVE : ' .. instantDeathCountdown .. '', 0.45, 0.1, conf.color.red, 2)
          if instantDeathCountdown < 0  then
            SetEntityHealth(GetPlayerPed(-1), 0)
            lastZoneAt = nil
            timeDiffLastZone = 0
            TriggerServerEvent('brv:stopGame', true, true)
          end
        else
          lastZoneAt = nil
          timeDiffLastZone = 0
        end
      else
        playerOOZAt = nil
        timeDiff = 0
      end
      playerOutOfZone = isPlayerOutOfZone(safeZones[currentSafeZone])
      if playerOutOfZone then
        showText('GO TO THE SAFE ZONE', 0.894, 0.05, conf.color.red, 2)
      else
        showText('YOU ARE IN THE SAFE ZONE', 0.87, 0.05, conf.color.green, 2)
      end
    end
  end
end)
