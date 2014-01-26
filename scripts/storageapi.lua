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
-- @param mode Should other entities access this storage: 0 not, 1 store, 2 take, 3 both
-- @param space Maximum amount of item stacks, up to 999
-- @param join Should the storage merge stacks if possible?
function storageApi.init(mode, space, join)
  if storage.sApi == nil then storage.sApi = {} end
  storageApi.isin = mode % 2 == 1
  storageApi.isout = mode % 4 >= 2
  storageApi.capacity = math.min(999, space)
  storageApi.isjoin = join
end

--- Should the storage be initialized?
function storageApi.isInit()
  return storageApi.capacity == nil
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
  for _ in storageApi.getIterator() do ret = ret + 1 end
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
-- @param count (Optional) Amount of the item to take from the stack
function storageApi.returnItem(index, count)
  if (storageApi.beforeItemTaken ~= nil) and storageApi.beforeItemTaken(index, count) then return nil end
  local ret = storage.sApi[index]
  if (count == nil) or (ret[2] >= count) then
    storage.sApi[index] = nil
  else
    storage.sApi[index][2] = ret[2] - count
    ret[2] = count
  end
  if (storageApi.afterItemTaken ~= nil) then storageApi.afterItemTaken(ret[1], ret[2], ret[3]) end
  return ret
end

--- Get maximum stack size for an item type
function storageApi.getMaxStackSize(itemname)
  if itemname == "climbingrope" then return 1000
  elseif itemname == "money" then return 25000 end
  local t = world.itemType(itemname)
  if (t == "generic") or (t == "coin") or (t == "material") or (t == "consumable") or (t == "thrownitem") or (t == "object") then return 1000
  else return 1 end
end

--- Checks if the item can be fit inside storage
function storageApi.canFitItem(itemname, count, properties)
  local max = storageApi.getMaxStackSize(itemname)
  local spacecnt = (storageApi.getCapacity() - storageApi.getCount()) * max
  if spacecnt >= count then return true
  elseif max > 1 then return false end
  for i,v in storageApi.getIterator() do
    if (itemname == v[1]) and compareTables(properties, v[3]) then
      spacecnt = spacecnt + max - v[2]
    end
    if spacecnt >= count then return true end
  end
  return false
end

--- Take a specific type of item from storage
-- @param itemname The name of item to get
-- @param count The amount of item to get
-- @param properties (Optional) The properties table of the item
function storageApi.returnItemByName(itemname, count, properties)
  if (storageApi.beforeReturnByName ~= nil) and storageApi.beforeReturnByName(itemname, count, properties) then return { itemname, count, properties } end
  if properties == nil then
    for i,v in storageApi.getIterator() do
      if v[1] == itemname then
        properties = v[3]
        break
      end
    end
  end
  if properties == nil then return { itemname, 0, { } } end
  local retcnt = 0
  for i,v in storageApi.getIterator() do
    if retcnt >= count then break end
    if (v[1] == itemname) and compareTables(properties, v[3]) then
      retcnt = retcnt + storageApi.returnItem(i, count - retcnt)[2]
    end
  end
  return { itemname, retcnt, properties }
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
  if not storageApi.canFitItem(itemname, count, properties) then return false end
  if (storageApi.beforeItemStored ~= nil) and storageApi.beforeItemStored(itemname, count, properties) then return false end
  if storageApi.isMerging() then
    local max = storageApi.getMaxStackSize(itemname)
    for i,stack in storageApi.getIterator() do
      if (stack[1] == itemname) and (stack[2] < max) and compareTables(properties, stack[3]) then
        if (stack[2] + count > max) then
          local i = storageApi.getFirstEmptyIndex()
          storage.sApi[i] = { itemname, stack[2] + count - max, properties }
          if (storageApi.afterItemStored ~= nil) then storageApi.afterItemStored(i, false) end
          count = max - stack[2] - count
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

--- Put as much items as possible in storage, handles oversized stacks
-- @return The amount of item that was stored
function storageApi.storeItemFit(itemname, count, properties)
  local ret = 0
  local max = storageApi.getMaxStackSize(itemname)
  while (count > max) and not storageApi.isFull() do
    storageApi.storeItem(itemname, max, properties)
    ret = ret + max
    count = count - max
  end
  for i,v in storageApi.getIterator() do
    if count < 1 then break end
    if (v[1] == itemname) and (v[2] < max) and compareTables(properties, v[3]) then
      local amo = math.min(max, v[2] + count)
      storage.sApi[i][2] = amo
      count = count + v[2] - amo
    end
  end
  return ret
end

-------------------------------------------------
-- Event functions
-------------------------------------------------

-- Called before the API searches for the item to return in storage
-- itemname, count, parameters - the requested item data
-- If this returns true, item is returned instantly without searching through the storage
----- function storageApi.beforeReturnByName(itemname, count, properties)

-- Called when an item is about to be taken from storage
-- index - the requested item index
-- count - amount of the item to take
-- If this returns true, the item is not taken and the returned item is null
----- function storageApi.beforeItemTaken(index, count) end

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
