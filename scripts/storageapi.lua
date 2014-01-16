-------------------------------------------------
-- Helper functions
-------------------------------------------------

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
-------------------------------------------------

storageApi = {}

-------------------------------------------------
-- API functions
-------------------------------------------------

--- Initializes the storage
-- @param mode should other entities access this storage: 0 not, 1 store, 2 take, 3 both
-- @param space capacity of item stacks, max 999
-- @param join should the storage merge stacks if possible?
function storageApi.init(mode, space, join)
  if storage.sApi == nil then storage.sApi = {} end
  storageApi.isin = mode % 2 == 1
  storageApi.isout = mode % 4 >= 2
  storageApi.capacity = math.min(999, space)
  storageApi.isjoin = join
end

--- Sets storage contents and returns previous contents
-- @param itemArray an array of item structures (name, count, params)
function storageApi.setContents(itemArray)
  local ret = storage.sApi
  storage.sApi = itemArray
  return ret
end

--- Should we take items from storage from outside the object?
function storageApi.isOutput()
  return storageApi.isout
end

--- Should we put items in storage from outside the object?
function storageApi.isInput()
  return storageApi.isin
end

--- Is this storage merging stacks?
function storageApi.isMerging()
  return storageApi.isjoin
end

--- Is this storage full?
function storageApi.isFull()
  return storageApi.getCount() >= storageApi.getCapacity()
end

--- How many item stacks can be stored?
function storageApi.getCapacity()
  return storageApi.capacity
end

--- How many item stacks are stored?
function storageApi.getCount()
  local ret = 0
  for _ in pairs(storage.sApi) do ret = ret + 1 end
  return ret
end

--- Analyze an item from storage
function storageApi.peekItem(index)
  return storage.sApi[index]
end

--- Returns an iterator for the whole storage 
function storageApi.getIterator()
  return pairs(storage.sApi)
end

--- Take an item from storage
function storageApi.returnItem(index)
  if (storageApi.beforeItemTaken ~= nil) and storageApi.beforeItemTaken(index) then return nil end
  local ret = storage.sApi[index]
  storage.sApi[index] = nil
  if (storageApi.afterItemTaken ~= nil) then storageApi.afterItemTaken(ret[1], ret[2], ret[3]) end
  return ret
end

--- Take all items from storage
function storageApi.returnContents()
  local ret = storage.sApi
  storage.sApi = {}
  if (storageApi.afterAllItemsTaken ~= nil) then storageApi.afterAllItemsTaken() end
  return ret
end

--- Get first empty key in storage table
function storageApi.getFirstEmptyIndex()
  for i=1,999 do
    if storage.sApi[i] == nil then return i end
  end
  return 1000
end

--- Put an item in storage, returns true if successfully
function storageApi.storeItem(itemname, count, properties)
  if (storageApi.beforeItemStored ~= nil) and storageApi.beforeItemStored(itemname, count, properties) then return end
  if storageApi.isFull() then return false end
  if storageApi.isMerging() then
    for i,stack in pairs(storage.sApi) do
      if (stack[1] == itemname) and (stack[2] < 1000) and compareTables(properties, stack[3]) then
        if (stack[2] + count > 1000) then
          local i = storageApi.getFirstEmptyIndex()
          storage.sApi[i] = { itemname, stack[2] + count - 1000, properties }
          if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(i, false) end
          count = 1000 - stack[2] - count
        end
        storage.sApi[i][2] = stack[2] + count
        if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(i, true) end
        return true
      end
    end
  end
  local i = storageApi.getFirstEmptyIndex()
  storage.sApi[i] = { itemname, count, properties }
  if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(i, false) end
  return true
end

-------------------------------------------------
-- Event functions
-------------------------------------------------

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