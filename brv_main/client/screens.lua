-- WASTED SCREEN
AddEventHandler('brv:wastedScreen', function(rank, kills)
  Citizen.CreateThread(function()
    local locksound = false
    while IsEntityDead(PlayerPedId()) do
      StartScreenEffect("DeathFailOut", 0, 0)
      if not locksound then
        PlaySoundFrontend(-1, "Bed", "WastedSounds", 1)
        locksound = true
      end
      ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 1.0)

      local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")

      if HasScaleformMovieLoaded(scaleform) then

        PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
        BeginTextComponent("STRING")
        AddTextComponentString("~r~wasted")
        EndTextComponent()
        BeginTextComponent("STRING")
        AddTextComponentString('Rank ~g~~h~#' .. rank .. '~s~ | Kills ~r~~h~#' .. kills .. '~s~~n~Returning to Lobby...')
        EndTextComponent()
        PopScaleformMovieFunctionVoid()

        Citizen.Wait(500)

        PlaySoundFrontend(-1, "TextHit", "WastedSounds", 1)
        while IsEntityDead(PlayerPedId()) do
          DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
          Wait(0)
        end

        StopScreenEffect("DeathFailOut")
        locksound = false
      end
      Wait(0)
    end
  end)
end)

-- WINNER SCREEN
AddEventHandler('brv:winnerScreen', function(rank, kills, restart)
  setGameStarted(false) -- forces stop for winner
  Citizen.CreateThread(function()
    local timeDiff = 0
    local wonAt
    local locksound = false

    while timeDiff < 10000 do
      if not wonAt then
        wonAt = GetGameTimer()
      end

      StartScreenEffect("DeathFailOut", 0, 0)
      if not locksound then
        PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
        locksound = true
      end
      ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 1.0)

      local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")

      if HasScaleformMovieLoaded(scaleform) then

        PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
        BeginTextComponent("STRING")
        AddTextComponentString("~g~winner")
        EndTextComponent()
        BeginTextComponent("STRING")
        AddTextComponentString('Rank ~g~~h~#' .. rank .. '~s~ | Kills ~r~~h~#' .. kills .. '~s~~n~Returning to Lobby...')
        EndTextComponent()
        PopScaleformMovieFunctionVoid()

        Citizen.Wait(500)

        PlaySoundFrontend(-1, "TextHit", "WastedSounds", 1)
        while timeDiff < 10000 do
          timeDiff = GetTimeDifference(GetGameTimer(), wonAt)
          DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
          Wait(0)
        end

        StopScreenEffect("DeathFailOut")
        locksound = false
      end
      Wait(0)
    end
    TriggerServerEvent('brv:stopGameClients', getLocalPlayer().name, restart)
  end)
end)
