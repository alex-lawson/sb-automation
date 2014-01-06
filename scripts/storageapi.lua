-------------------------------------------------
-- Helper functions
function compareTables(firstTable, secondTable)
  if (next(firstTable) == nil) and (next(secondTable) == nil) then 
    return true
  end
  for key,value in pairs(firstTable) do
    if firstTable[key] ~= secondTable[key] then 
      return false 
    end
  end
  for key,value in pairs(secondTable) do
    if firstTable[key] ~= secondTable[key] then 
      return false 
    end
  end
  return true
end

-------------------------------------------------
-- Definitions
storageApi = { storage = {} }

-------------------------------------------------
-- API functions

-- mode: 0 none, 1 in, 2 out, 3 both
-- space: capacity of item stacks, max 999
-- join: should the storage merge stacks if possible?
function storageApi.init(mode, space, join)
  storageApi.isout = bit.band(mode, 1) == 1
  storageApi.isin = bit.band(mode, 2) == 1
  storageApi.capacity = math.min(999, space)
  storageApi.isjoin = join
end

-- Should we take items from storage from outside the object?
function storageApi.isOutput()
  return storageApi.isout
end

-- Should we put items in storage from outside the object?
function storageApi.isInput()
  return storageApi.isin
end

-- Is this storage merging stacks?
function storageApi.isMerging()
  return storageApi.isjoin
end

-- Is this storage full?
function storageApi.isFull()
  return storageApi.getCount() >= storageApi.getCapacity()
end

-- How many item stacks can be stored?
function storageApi.getCapacity()
  return storageApi.capacity
end

-- How many item stacks are stored?
function storageApi.getCount()
  return #storageApi.storage
end

-- Analyze storage contents
function storageApi.peekItem(index)
  return storageApi.storage[index]
end

-- Take an item from storage
function storageApi.returnItem(index)
  local ret = storageApi.storage[index]
  storage[index] = nil
  return ret
end

-- Put an item in storage
function storageApi.storeItem(itemname, count, properties)
  if storageApi.isMerging() then
    for i,stack in ipairs(storageApi.storage) do
      if (stack[1] == itemname) and compareTables(properties, stack[3]) then
        storageApi.storage[i][2] = stack[2] + count
        return true
      end
    end
  end
  storage[#storageApi.storage + 1] = { itemname, count, properties }
  return false
end