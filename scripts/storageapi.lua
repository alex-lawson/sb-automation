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
-- @param args [optional] (table) Override config parameters
--      -mode: (int) Should other entities access this storage: 0 not, 1 store in, 2 take from, 3 both
--      -capacity: (int) Maximum amount of item stacks, up to 999
--      -merge: (boolean) Should the storage merge stacks if possible?
--      -content: (table) table of items to prefill the object
--      -dropPosition: (vec2f) position to drop items
--      -ondeath: (int) Should object 0 do nothing, 1 drop items or 2 store items on death
function storageApi.init(args)
    if storage.sApi == nil then
        storage.sApi = args.content or entity.configParameter("storageapi.content") or { }
    end
    storageApi.mode = args.mode or entity.configParameter("storageapi.mode") or 0
    storageApi.isin = storageApi.mode % 2 == 1
    storageApi.isout = storageApi.mode % 4 >= 2
    storageApi.capacity = math.min(999, args.capacity or entity.configParameter("storageapi.capacity") or 1)
    storageApi.isjoin = args.merge or entity.configParameter("storageapi.merge")
    storageApi.dropPosition = args.dropPosition or entity.configParameter("storageapi.dropPosition")
    storageApi.ondeath = args.ondeath or entity.configParameter("storageapi.ondeath") or 0
    storageApi.ignoreDropIds = {}
end

--- Should the storage be initialized?
-- @return (bool) True if storage should be initialized
function storageApi.isInit()
    return storageApi.capacity == nil
end

--- Sets storage contents and returns previous contents
-- @param itemArray (table) An array of item structures (name, count, params)
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
-- @param index (int) Index in storage
-- @return (table) An item descriptor
function storageApi.peekItem(index)
    return storage.sApi[index]
end

--- Returns an iterator for the whole storage
-- @return (explist) The iterator
function storageApi.getIterator()
    return pairs(storage.sApi)
end

--- Take an item from storage
-- @param index (int) Index in storage
-- @param count [optional] (int) Amount of the item to take from the stack
-- @return (table) An item descriptor or nil
function storageApi.returnItem(index, count)
    if beforeItemTaken and beforeItemTaken(index, count) then return nil end
    local ret = storage.sApi[index]
    if (count == nil) or (ret.count >= count) then
        storage.sApi[index] = nil
    else
        storage.sApi[index].count = ret.count - count
        ret.count = count
    end
    if afterItemTaken then afterItemTaken(ret.name, ret.count, ret.data) end
    return ret
end

--- Get maximum stack size for an item type
-- @param itemname (string) The name of item to check
-- @return (int) The estimated max stack size
function storageApi.getMaxStackSize(itemname)
    if itemname == "climbingrope" then return 1000
    elseif itemname == "money" then return 25000 end
    local t = world.itemType(itemname)
    if (t == "generic") or (t == "coin") or (t == "material") or (t == "consumable") or (t == "thrownitem") or (t == "object") then return 1000
    else return 1 end
end

--- Checks if the item can be fit inside storage
-- @param itemname (string) The item name
-- @param count (int) The amount of item
-- @param data [optional] (table) The properties table of the item
function storageApi.canFitItem(itemname, count, data)
    local max = storageApi.getMaxStackSize(itemname)
    local spacecnt = (storageApi.getCapacity() - storageApi.getCount()) * max
    if spacecnt >= count then return true
    elseif max > 1 then return false end
    for i,v in storageApi.getIterator() do
        if (itemname == v.name) and compareTables(data, v.data) then
            spacecnt = spacecnt + max - v.count
        end
        if spacecnt >= count then return true end
    end
    return false
end

--- Take a specific type of item from storage
-- @param itemname (string) The name of item to get
-- @param count (int) The amount of item to get
-- @param data [optional] (table) The properties table of the item
-- @return (table) Descriptor of the item taken
function storageApi.returnItemByName(itemname, count, data)
    if (storageApi.beforeReturnByName ~= nil) and storageApi.beforeReturnByName(itemname, count, data) then return { name = itemname, count = count, data = data } end
    if data == nil then
        for i,v in storageApi.getIterator() do
            if v.name == itemname then
                data = v.data
                break
            end
        end
    end
    if data == nil then return { name = itemname, count = 0, data = { } } end
    local retcnt = 0
    for i,v in storageApi.getIterator() do
        if retcnt >= count then break end
        if (v.name == itemname) and compareTables(properties, v.data) then
            retcnt = retcnt + storageApi.returnItem(i, count - retcnt).count
        end
    end
    return { name = itemname, count = retcnt, data = data }
end

--- Take all items from storage
-- @return (table) An item descriptor table of items
function storageApi.returnContents()
    local ret = storage.sApi
    storage.sApi = {}
    if (afterAllItemsTaken ~= nil) then afterAllItemsTaken() end
    return ret
end

--- Get first empty key in storage table
-- @return (int) First empty storage index found
function storageApi.getFirstEmptyIndex()
    local c = storageApi.getCapacity()
    for i=1,c do
        if storage.sApi[i] == nil then return i end
    end
    return c + 1
end

--- Puts an item in storage
-- @param itemname (string) The item name
-- @param count (int) The amount of item to store
-- @param data [optional] (table) The properties table of the item
-- @return (bool) True if item was stored
function storageApi.storeItem(itemname, count, data)
    if not storageApi.canFitItem(itemname, count, data) then return false end
    if beforeItemStored and beforeItemStored(itemname, count, data) then return false end
    if storageApi.isMerging() then
        local max = storageApi.getMaxStackSize(itemname)
        for i,stack in storageApi.getIterator() do
            if (stack.name == itemname) and (stack.count < max) and compareTables(data, stack.data) then
                if (stack.count + count > max) then
                    local newIndex = storageApi.getFirstEmptyIndex()
                    storage.sApi[newIndex] = { name = itemname, count = (stack.count + count) - max, data = data }
                    if afterItemStored then afterItemStored(newIndex, false) end
                    count = max - stack.count
                end
                storage.sApi[i].count = stack.count + count
                if afterItemStored then afterItemStored(i, true) end
                return true
            end
        end
    end
    local i = storageApi.getFirstEmptyIndex()
    storage.sApi[i] = { name = itemname, count = count, data = data }
    if afterItemStored then afterItemStored(i, false) end
    return true
end

--- Puts as much of an item as possible in storage, handles oversized stacks
-- @param itemname (string) The item name
-- @param count (int) The amount of item to store
-- @param properties [optional] (table) The properties table of the item
-- @return (int) The amount of item that was left
function storageApi.storeItemFit(itemname, count, data)
    local max = storageApi.getMaxStackSize(itemname)
    while (count > max) and not storageApi.isFull() do
        storageApi.storeItem(itemname, max, data)
        count = count - max
    end
    for i,v in storageApi.getIterator() do
        if count < 1 then break end
        if (v.name == itemname) and (v.count < max) and compareTables(data, v.data) then
            local amo = math.min(max, v.count + count)
            storage.sApi[i].count = amo
            count = count + v.count - amo
        end
    end
    if (count > 0) and storageApi.storeItem(itemname, count, data) then return 0 end
    return count
end

--- Drops an item from storage
-- @param index (int) Index in storage
-- @param amount [optional] (int) If provided will only drop certain amount of item
-- @param pos [optional] (vec2f) A position to drop item at
-- @return (int) ID of dropped item entity or nil
function storageApi.drop(index, amount, pos)
    pos = pos or storageApi.dropPosition or entity.position()
    local item, drop = storage.sApi[index], nil
    if item then
        if not amount then amount = item.count or 0 end
        if amount > 0 then
            if not item.data or next(item.data) == nil then
                drop = world.spawnItem(item.name, pos, amount)
            else
                drop = world.spawnItem(item.name, pos, amount, item.data.__content)
            end
            if drop then
                storage.sApi[index].count = item.count - amount
                if storage.sApi[index].count < 1 then
                    storage.sApi[index] = nil
                end
                storageApi.ignoreDropIds[drop] = os.time()
            end
        end
    end
    return drop
end

--- Drops all items from storage
-- @param pos [optional] (vec2f) A position to drop items at
-- @return (bool) True if all items were dropped successfully
function storageApi.dropAll(pos)
    pos = pos or storageApi.dropPosition or entity.position()
    for i in storageApi.getIterator() do
        storageApi.drop(i)
    end
    return storageApi.getCount() == 0
end

--- Checks if a specified item was recently dropped 
-- @param entityId (int) ID of an item drop entity
-- @param cooldown [optional] (int) Time after an item drop is not considered recent
-- @return (bool) True if the item drop is old enough
function storageApi.notJustDropped(entityId, cooldown)
    cooldown = cooldown or 20
    if storageApi.ignoreDropIds[entityId] == nil or storageApi.ignoreDropIds[entityId] + cooldown < os.time() then
        storageApi.ignoreDropIds[entityId] = nil
        return true
    end
    return false
end

--- Take item drops around a position
-- @param pos [optional] (vec2f) A position to take items from
-- @param radius (int) Scan radius
-- @param takenBy (int) Entity ID to animate item drop to
-- @return (int) Amount of found items
function storageApi.take(pos, radius, takenBy)
    pos = pos or storageApi.dropPosition or entity.position()
    radius = radius or 1
    local itemIds, time, ret = world.itemDropQuery(pos, radius), os.time(), 0
    for _, itemId in ipairs(itemIds) do
        if storageApi.notJustDropped(itemId, 10, time) then
            local item = world.takeItemDrop(itemId, takenBy)
            if item then
                ret = ret + 1
                if not storageApi.storeItem(item.name, item.count, item.data) then
                    storageApi.ignoreDropIds[itemId] = time - 5
                end
            end
        end
    end
    return ret
end

--- Call this in entities die() function if you use the "ondeath" arg in init
function storageApi.die()
    if storageApi.ondeath == 1 then
        storageApi.dropAll()
    elseif (storageApi.ondeath == 2) and (world.entityType(entity.id()) == "object") then
        world.spawnItem(entity.configParameter("objectName"), storageApi.dropPosition, 1, { content = storage.sApi()} )
    end
end

