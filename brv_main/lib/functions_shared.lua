function round(num, precision)
  return string.format("%." .. (precision or 0) .. "f", num)
end

function explode(str, sep)
  if sep == '' then return false end

  local pos,arr = 0,{}

  -- for each divider found
  for st,sp in function() return string.find(str, sep, pos, true) end do
    table.insert(arr, string.sub(str, pos, st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end

  table.insert(arr, string.sub(str, pos)) -- Attach chars right of last divider
  return arr
end

function table_reverse(t)
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

function count(array)
  if type(array) ~= 'table' then return false end

  local count = 0
  for k, v in pairs(array) do
    count = count + 1
  end
  return count
end
