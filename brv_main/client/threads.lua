Citizen.CreateThread(function()
  local isRadarExtended = false
  while true do
    Wait(0)

    -- Infinite stamina
    RestorePlayerStamina(PlayerId(), 1.0)

    -- Disable health regeneration
    SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)

    -- Extended minimap
    if IsControlJustPressed(0, 20) then
      if not isRadarExtended then
        SetRadarBigmapEnabled(true, false)
        isRadarExtended = true
      else
        SetRadarBigmapEnabled(false, false)
        isRadarExtended = false
      end
    end

    -- Drawing pickup markers
    for i,v in pairs(getPickups()) do
      if isPlayerNearCoords(v.coords, 100.0) then
        DrawMarker(1, v.coords.x, v.coords.y, v.coords.z-1, 0, 0, 0, 0, 0, 0, 0.5001, 0.5001, 2.0001, 245, 233, 76, 100, 0, 0, 0, 0)
      end
    end
  end
end)

-- Auto restart
Citizen.CreateThread(function()
  local countdown = 0
  local gameEndedAt = nil
  local timeDiff = 0

  while true do
    Wait(0)
    if getIsGameEnded() then
      if not gameEndedAt then gameEndedAt = GetGameTimer() end

      timeDiff = GetTimeDifference(GetGameTimer(), gameEndedAt)
      countdown = conf.autostartTimer - tonumber(round(timeDiff / 1000))

      showText('THE NEXT BATTLE IS STARTING IN ' .. countdown .. 's', 0.425, 0.135, conf.color.red)

      if countdown < 0 then
        setGameEnded(false)
        gameEndedAt = nil
        TriggerServerEvent('brv:startGame')
      end
    else
      gameEndedAt = nil
    end
  end
end)

-- Print a clock top left and number of players remaining
Citizen.CreateThread(function()
  local message = ''

  while true do
    Wait(0)

    local h = GetClockHours()
    local m = GetClockMinutes()
    if m < 10 then
      m = '0' .. m
    end
    if h < 10 then
      h = '0' .. h
    end
    showText(h .. 'H' .. m, 0.005, 0.05)
    showText(conf.discordUrl, 0.45, 0.015, conf.color.green, 4)

    if getIsGameStarted() then
      message = 'Players remaining : ' .. getPlayersRemaining()
    else
      if getIsGameEnded() then
        message = 'The battle will start soon...'
      else
        message = 'Waiting for more players to start the battle...'
      end
    end

    showText(message, 0.005, 0.075, {r = 255, g = 255, b = 255})

    if isPlayerInLobby() and not isPlayerInSpectatorMode() then
      if getIsGameStarted() then
        showText('A BATTLE IS CURRENTLY GOING', 0.43, 0.105, conf.color.red)
        showText('You can spectate at the TV and wait for a new battle to begin', 0.38, 0.14, conf.color.red)
      else
        showText('You are in the lobby, it is safe and comfortable', 0.4, 0.105, conf.color.green)
      end
    end
  end
end)

-- Check pickup collection
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(50)

    if getIsGameStarted() then
      if NetworkIsPlayerActive(PlayerId()) then
        for i,v in pairs(pickups) do
          if HasPickupBeenCollected(v.id) then
            -- Remove local pickup
            TriggerEvent('brv:removePickup', i)
            -- Sends event to the server for the other players
            TriggerServerEvent('brv:pickupCollected', i)
          end
        end
      end
    end
  end
end)

-- Auto respawning after 10 seconds
local diedAt
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)

    local playerPed = GetPlayerPed(-1)

    if playerPed and playerPed ~= -1 then
      if NetworkIsPlayerActive(PlayerId()) then
        if (diedAt and (GetTimeDifference(GetGameTimer(), diedAt) > 10000)) then
          exports.spawnmanager:spawnPlayer(false, function()
            getLocalPlayer().skin = changeSkin(getLocalPlayer().skin)
          end)
        end
      end

      if IsEntityDead(playerPed) then
        if not diedAt then
          diedAt = GetGameTimer()
        end
      else
        diedAt = nil
      end
    end
  end
end)
