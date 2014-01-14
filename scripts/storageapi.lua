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
  return #storage.sApi
end

--- Analyze an item from storage
function storageApi.peekItem(index)
  return storage.sApi[index]
end

--- Retrieve a list of indices in storage for iteration
function storageApi.getStorageIndices()
  local ret = {}
  for i,k in pairs(storage.sApi) do
    ret[#ret+1] = i
  end
  return ret
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

--- Put an item in storage, returns true if successfully
function storageApi.storeItem(itemname, count, properties)
  if storageApi.beforeItemStored ~= nil and storageApi.beforeItemStored(itemname, count, properties) == false then return end
  if storageApi.isFull() then return false end
  if storageApi.isMerging() then
    local stackIndex = #storage.sApi+1
    local stackCount = count
    for i,stack in pairs(storage.sApi) do
      if (stack[1] == itemname) and compareTables(properties, stack[3]) then
        stackIndex = i
        stackCount = stack[2] + count
        if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(i, true) end
      end
    end
    storage.sApi[stackIndex] = {itemname, stackCount, properties}
    return true 
  end
  storage[#storage.sApi + 1] = { itemname, count, properties }
  if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(#storage.sApi, false) end
  return true
end

-------------------------------------------------
-- Hook functions
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