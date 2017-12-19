Citizen.CreateThread(function()
  SetRandomSeed(GetNetworkTime())

  -- Disable money displaying
  DisplayCash(true)

  -- Disable health regeneration
  SetPlayerHealthRechargeMultiplier(PlayerId(), 0)

  -- Draw Discord in menu
  Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), 'FE_THDR_GTAO', 'Battle Royale V Reborn | '..conf.discordUrl)

  local player = PlayerId()

  -- Disable cops
  SetPoliceIgnorePlayer(player, true)
  SetDispatchCopsForPlayer(player, false)
  SetMaxWantedLevel(0)

  local isRadarExtended = false

  while true do
    Citizen.Wait(0)

    -- Extended Radar
    if IsControlJustReleased(0, 20) then
      isRadarExtended = not isRadarExtended
      Citizen.InvokeNative(0x231C8F89D0539D8F, isRadarExtended, false)
    end

    -- Infinite stamina
    ResetPlayerStamina(player)
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

      showHelp('Match starts in ' .. countdown .. '...')

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

-- Set weather and time
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(33)

    NetworkOverrideClockTime(conf.time.hours, conf.time.minutes, conf.time.seconds)

    SetWeatherTypePersist(conf.weather)
    SetWeatherTypeNowPersist(conf.weather)
    SetWeatherTypeNow(conf.weather)
    SetOverrideWeather(conf.weather)
  end
end)


Citizen.CreateThread(function()
  local message

  while true do
    Wait(0)

    message = nil

    if getIsGameStarted() then
      message = 'Alive players:  ~o~' .. getPlayersRemaining()
    elseif not getIsGameEnded() then
      message = getPlayersRemainingToAutostart()..' player(s) left to autostart the match.'
    end

    if message then
      showHelp(message)
    end

    DisplayRadar(not isPlayerInSpectatorMode() and not isPlayerInLobby())
  end
end)

-- Check pickup collection
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(50)

    if getIsGameStarted() then
      if NetworkIsPlayerActive(PlayerId()) then
        for i, pickup in pairs(getPickups()) do
          if HasPickupBeenCollected(pickup.id) then
            showNotification('Picked up '..pickup.name..'.')

            SetBlipAlpha(getPickupBlips()[i], 128)

            TriggerEvent('brv:removePickup', i)
          end
        end
      end
    end
  end
end)

-- Displaying gamer tags in Spectator Mode
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)

    if isPlayerInSpectatorMode() then
      for _, player in ipairs(getAlivePlayers()) do
        local playerId = GetPlayerFromServerId(player.source)
        local gamerTag = CreateMpGamerTag(GetPlayerPed(playerId), player.name, false, false, "", 0)

        local color = 0
        if getSpectatingPlayer() == playerId then
          color = 4
        end

        -- https://runtime.fivem.net/doc/reference.html#_0x63BB75ABEDC1F6A0
        SetMpGamerTagName(gamerTag, player.name)
        SetMpGamerTagColour(gamerTag, 0, color)
        SetMpGamerTagHealthBarColour(gamerTag, color)
        SetMpGamerTagAlpha(gamerTag, 0, 255)
        SetMpGamerTagAlpha(gamerTag, 2, 255)

        SetMpGamerTagVisibility(gamerTag, 0, true) -- GAMER_NAME
        SetMpGamerTagVisibility(gamerTag, 2, true) -- HEALTH/ARMOR
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
