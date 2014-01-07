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

-- Analyze an item from storage
function storageApi.peekItem(index)
  return storageApi.storage[index]
end

-- Take an item from storage
function storageApi.returnItem(index)
  if (storageApi.beforeItemTaken ~= nil) and storageApi.beforeItemTaken(index) then return nil end
  local ret = storageApi.storage[index]
  storageApi.storage[index] = nil
  if (storageApi.afterItemTaken ~= nil) then storageApi.afterItemTaken(ret[1], ret[2], ret[3]) end
  return ret
end

-- Take all items from storage
function storageApi.returnContents()
  local ret = storageApi.storage
  storageApi.storage = {}
  if (storageApi.afterAllItemsTaken ~= nil) then storageApi.afterAllItemsTaken() end
  return ret
end

-- Put an item in storage, returns true if successfully
function storageApi.storeItem(itemname, count, properties)
  if (storageApi.beforeItemStored ~= nil) and storageApi.beforeItemStored(itemname, count, properties) then return end
  if storageApi.isFull() then return false end
  if storageApi.isMerging() then
    for i,stack in ipairs(storageApi.storage) do
      if (stack[1] == itemname) and compareTables(properties, stack[3]) then
        storageApi.storage[i][2] = stack[2] + count
        if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(i, true) end
        return true
      end
    end
  end
  storage[#storageApi.storage + 1] = { itemname, count, properties }
  if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(#storageApi.storage, false) end
  return true
end

-------------------------------------------------
-- Hook functions

-- Called when an item is about to be taken from storage
-- index - the requested item index
-- If this returns true, the item is not taken and the returned item is null
----- function storageApi.beforeItemTaken(index) end

-- Called when an item has been taken from storage
-- itemname, count, parameters - item data that was taken
----- function storageApi.afterItemTaken(itemname, count, properties) end

-- Called when an item is about to be stored in storage
-- itemname, count, parameters - item data requested to be stored
-- If this returns true, the item is not stored and the parent method returns false
----- function storageApi.beforeItemStored(itemname, count, properties) end

-- Called when an item has been stored in storage
-- index - the index assigned to the item
-- merged - tells whenever the item stack was merged into another, or not
----- function storageApi.afterItemStored(index, merged) end

-- Called when all items have been taken from storage
----- function storageApi.afterAllItemsTaken() end