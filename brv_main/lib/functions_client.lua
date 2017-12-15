--------------------------------------------------------------------------------
--                               BATTLE ROYALE V                              --
--                            Client functions file                           --
--------------------------------------------------------------------------------

local itemBlips = {
    ["PICKUP_WEAPON_APPISTOL"] = 156,
    ["PICKUP_WEAPON_ASSAULTSHOTGUN"] = 158,
    ["PICKUP_WEAPON_ASSAULTSMG"] = 159,
    ["PICKUP_WEAPON_AUTOSHOTGUN"] = 158,
    ["PICKUP_WEAPON_BULLPUPSHOTGUN"] = 158,
    ["PICKUP_WEAPON_COMBATMG"] = 159,
    ["PICKUP_WEAPON_COMBATPDW"] = 159,
    ["PICKUP_WEAPON_COMBATPISTOL"] = 156,
    ["PICKUP_WEAPON_FLAREGUN"] = 156,
    ["PICKUP_WEAPON_DBSHOTGUN"] = 158,
    ["PICKUP_WEAPON_GRENADE"] = 152,
    ["PICKUP_WEAPON_GUSENBERG"] = 159,
    ["PICKUP_WEAPON_HEAVYPISTOL"] = 156,
    ["PICKUP_WEAPON_HEAVYSHOTGUN"] = 158,
    ["PICKUP_WEAPON_MACHINEPISTOL"] = 159,
    ["PICKUP_WEAPON_MARKSMANPISTOL"] = 156,
    ["PICKUP_WEAPON_MG"] = 159,
    ["PICKUP_WEAPON_MICROSMG"] = 159,
    ["PICKUP_WEAPON_MINISMG"] = 159,
    ["PICKUP_WEAPON_MOLOTOV"] = 155,
    ["PICKUP_WEAPON_PIPEBOMB"] = 152,
    ["PICKUP_WEAPON_PISTOL"] = 156,
    ["PICKUP_WEAPON_PISTOL50"] = 156,
    ["PICKUP_WEAPON_PROXMINE"] = 152,
    ["PICKUP_WEAPON_PUMPSHOTGUN"] = 158,
    ["PICKUP_WEAPON_REVOLVER"] = 156,
    ["PICKUP_WEAPON_RPG"] = 157,
    ["PICKUP_WEAPON_HOMINGLAUNCHER"] = 157,
    ["PICKUP_WEAPON_SAWNOFFSHOTGUN"] = 158,
    ["PICKUP_WEAPON_MUSKET"] = 158,
    ["PICKUP_WEAPON_SMG"] = 159,
    ["PICKUP_WEAPON_SMOKEGRENADE"] = 152,
    ["PICKUP_WEAPON_SNSPISTOL"] = 156,
    ["PICKUP_WEAPON_STICKYBOMB"] = 152,
    ["PICKUP_WEAPON_VINTAGEPISTOL"] = 156,
    ["PICKUP_WEAPON_ADVANCEDRIFLE"] = 150,
    ["PICKUP_WEAPON_ASSAULTRIFLE"] = 150,
    ["PICKUP_WEAPON_BULLPUPRIFLE"] = 150,
    ["PICKUP_WEAPON_CARBINERIFLE"] = 150,
    ["PICKUP_WEAPON_COMPACTLAUNCHER"] = 174,
    ["PICKUP_WEAPON_COMPACTRIFLE"] = 150,
    ["PICKUP_WEAPON_GRENADELAUNCHER"] = 174,
    ["PICKUP_WEAPON_HEAVYSNIPER"] = 160,
    ["PICKUP_WEAPON_MARKSMANRIFLE"] = 160,
    ["PICKUP_WEAPON_SNIPERRIFLE"] = 160,
    ["PICKUP_WEAPON_MINIGUN"] = 173,
    ["PICKUP_WEAPON_SPECIALCARBINE"] = 150,
    ["PICKUP_ARMOUR_STANDARD"] = 175,
    ["PICKUP_HEALTH_SNACK"] = 153,
    ["PICKUP_HEALTH_STANDARD"] = 153,
}

-- Prints help text (top left)
function showHelp(str)
  SetTextComponentFormat("STRING")
  AddTextComponentString(str)
  DisplayHelpTextFromStringLabel(0, 0, 0, -1)
end

-- Print notification (bottom left)
function showNotification(text)
  SetNotificationTextEntry("STRING")
  AddTextComponentString(text)
  DrawNotification(true, false)
end

-- Print a text at coords
function showText(text, x, y, color, font)
  if color == nil then
    color = conf.color.grey
  end
  if font == nil then
    font = 4
  end
  SetTextFont(font)
  SetTextProportional(1)
  SetTextScale(0.0, 0.5)
  SetTextColour(color.r, color.g, color.b, 255)
  -- SetTextDropshadow(0, 0, 0, 0, 255)
  -- SetTextEdge(1, 0, 0, 0, 255)
  -- SetTextDropShadow()
  SetTextOutline()
  SetTextEntry("STRING")
  AddTextComponentString(text)
  DrawText(x, y)
end

function getGroundZ(x, y, z)
  local result, groundZ = GetGroundZFor_3dCoord(x+0.0, y+0.0, z+0.0, Citizen.ReturnResultAnyway())
  return groundZ
end

-- Teleports current player to coords
function teleport(coords)
  Citizen.CreateThread(function()
    local playerPed = GetPlayerPed(-1)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    while not HasCollisionLoadedAroundEntity(playerPed) do
      RequestCollisionAtCoord(coords.x, coords.y, coords.z)
      Wait(0)
    end
    ClearPedTasksImmediately(playerPed)

    local groundZ = coords.z
    if groundZ == 0.0 then
      groundZ = getGroundZ(coords.x, coords.y, 1000.0)
    end
    SetEntityCoords(playerPed, coords.x, coords.y, groundZ)
  end)
end

-- Change the skin of the player, from a predefined list
function changeSkin(skin)
  local model = (skin ~= '' and skin or getRandomNPCModel())
  Citizen.CreateThread(function()
    -- Get model hash.
    local modelhashed = GetHashKey(model)

    -- Request the model, and wait further triggering untill fully loaded.
    RequestModel(modelhashed)
    while not HasModelLoaded(modelhashed) do
      RequestModel(modelhashed)
      Wait(0)
    end
    -- Set playermodel.
    SetPlayerModel(PlayerId(), modelhashed)
    -- Set model no longer needed.
    SetModelAsNoLongerNeeded(modelhashed)
  end)
  return model
end

-- Sets a countdown
-- duration (integer) : Duration of the countdown (seconds)
-- step (integer) : Step of the countdown (seconds)
function showCountdown(duration, step, callback)
  Citizen.CreateThread(function()
      local startedAt = GetGameTimer()
      local time = duration
      local run = true
      local loop = 0
      local color = nil
      local countdown = 0

      while run do
        Wait(0)
        timeDiff = GetTimeDifference(GetGameTimer(), startedAt)
        countdown = duration - tonumber(round(timeDiff / (step * 1000)))

        local color = conf.color.white
        if countdown < (duration / 10) then
          color = conf.color.red
        end

        showText(tonumber(round(countdown)) .. 's remaining', 0.93, 0.08, color)

        if countdown <= 0 then
          run = false
        end
        if not getIsGameStarted() then return end
      end
      callback()
  end)
end

-- Returns a random npc model from a predefined list
function getRandomNPCModel()
  return npc_models[GetRandomIntInRange(1, count(npc_models) + 1)]
end

-- Return a random melee starting weapon
function getRandomMeleeWeapon()
  return meleeWeapons[GetRandomIntInRange(1, count(meleeWeapons) + 1)]
end

-- Returns a random location from a predefined list
function getRandomLocation()
  return locations[GetRandomIntInRange(1, count(locations) + 1)]
end

function getRandomSpawn()
  local startingSafeZone = getStartingSafeZone()

  local angle = GetRandomFloatInRange(0.0, 1.0) * math.pi * 2
  local radius = math.sqrt(GetRandomFloatInRange(0.0, 1.0)) * startingSafeZone.radius

  return { x = startingSafeZone.x + radius * math.cos(angle), y = startingSafeZone.y + radius * math.sin(angle), z = 1200.0 }
end

-- Sets the current safe zone and draws it on the map
-- safeZoneBlip (integer)
-- safeZoneCoords (x, y, z)
-- safeZoneRadius (float)
-- removeBlip (boolean) : If true, removes the previous drawed safe zone if it exists
-- step (integer)
function setSafeZone(safeZoneBlip, safeZone, step, removeBlip)
  if removeBlip and safeZoneBlip ~= nil then
    RemoveBlip(safeZoneBlip)
  end

  local color = 5 --yellow

  if step == 5 then color = 1 end --red

  safeZoneBlip = AddBlipForRadius(safeZone.x, safeZone.y, safeZone.z, safeZone.radius * 1.0)
  SetBlipColour(safeZoneBlip, color)
  SetBlipHighDetail(safeZoneBlip, true)
  SetBlipAlpha(safeZoneBlip, 80)

  return safeZoneBlip
end

function setBlipName(blip, name)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(tostring(name))
  EndTextCommandSetBlipName(blip)
end

-- https://marekkraus.sk/gtav/blips/list.html
function addPickupBlip(id, coords, color)
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

  SetBlipSprite(blip, itemBlips[id])
  SetBlipHighDetail(blip, true)
  SetBlipAsShortRange(blip, true)

  if color then SetBlipColour(blip, color) end

  return blip
end

-- Returns true if the player is out of the zone, false otherwise
function isPlayerOutOfZone(safeZone)
  if safeZone == nil then return false end

  local playerPos = GetEntityCoords(GetPlayerPed(PlayerId()))
  local distance = math.abs(GetDistanceBetweenCoords(playerPos.x, playerPos.y, playerPos.z, safeZone.x, safeZone.y, safeZone.z, false))

  return distance > safeZone.radius
end

-- Returns true if the player is near coords
function isPlayerNearCoords(coords, min)
  if min == nil then min = 100.0 end

  if coords == nil then return false end

  local playerPos = GetEntityCoords(GetPlayerPed(PlayerId()))
  local distance = math.abs(GetDistanceBetweenCoords(playerPos.x, playerPos.y, playerPos.z, coords.x, coords.y, coords.z, true))

  return distance <= min
end

function drawInstructionalButtons(buttons)
  Citizen.CreateThread(function()
    local scaleform = RequestScaleformMovie('instructional_buttons')
    while not HasScaleformMovieLoaded(scaleform) do
      Wait(0)
    end

    PushScaleformMovieFunction(scaleform, 'CLEAR_ALL')
    PushScaleformMovieFunction(scaleform, 'TOGGLE_MOUSE_BUTTONS')
    PushScaleformMovieFunctionParameterBool(0)
    PopScaleformMovieFunctionVoid()

    for i,v in ipairs(buttons) do
      PushScaleformMovieFunction(scaleform, 'SET_DATA_SLOT')
      PushScaleformMovieFunctionParameterInt(i-1)
      Citizen.InvokeNative(0xE83A3E3557A56640, v.button)
      PushScaleformMovieFunctionParameterString(v.label)
      PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(scaleform, 'DRAW_INSTRUCTIONAL_BUTTONS')
    PushScaleformMovieFunctionParameterInt(-1)
    PopScaleformMovieFunctionVoid()
    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
  end)
end
