RegisterNetEvent('brv:showScoreboard')

local listOn = false

Citizen.CreateThread(function()
  listOn = false
  while true do
    Wait(0)

    if IsControlPressed(0, 27)--[[ INPUT_PHONE ]] then
      if not listOn then
        TriggerServerEvent('brv:showScoreboard')

        listOn = true
      end
    end
  end
end)

AddEventHandler('brv:showScoreboard', function(data)
  Citizen.CreateThread(function()
    listOn = false
    local players = data.players
    local global = data.global
    if IsControlPressed(0, 27)--[[ INPUT_PHONE ]] then
      if not listOn then
        local ptable = {}
        local i = 1
        for k, player in spairs(players, function(t,a,b) return t[b].kills < t[a].kills end) do
          if i > 20 then break end
          if player.kills == nil then player.kills = 'N/A' end
          if player.rank == nil then player.rank = 'N/A' end
          table.insert(ptable,
            '<tr class=""><td>' .. player.source .. '</td><td>' .. player.name .. '</td><td>' .. player.kills .. '</td><td>' .. player.rank .. '</td></tr>'
          )
          i = i + 1
      end

      local gtable = {}
      i = 1
      for k, player in pairs(global) do
        if i > 10 then break end
        table.insert(gtable,
          '<tr class=""><td>' .. player.name .. '</td><td>' .. player.games .. '</td><td>' .. player.wins .. '</td><td>' .. player.kills .. '</td></tr>'
        )
        i = i + 1
      end

      SendNUIMessage({ text = table.concat(ptable), global = table.concat(gtable) })

      listOn = true
      while listOn do
        Wait(0)
        if(IsControlPressed(0, 27) == false) then
          listOn = false
          SendNUIMessage({
            meta = 'close'
          })
          break
        end
      end
    end
  end
end)
end)

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
