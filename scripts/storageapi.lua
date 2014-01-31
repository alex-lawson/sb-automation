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
-- @param args (optional) Change starting parameters
--      -mode: (int) Should other entities access this storage: 0 not, 1 store, 2 take, 3 both
--      -space: (int) Maximum amount of item stacks, up to 999
--      -join: (boolean) Should the storage merge stacks if possible?
--      -content: (table) table of items to prefill the object
--      -dropPosition: {x,y} position to drop items
--      -ondeath: (int) Should object 0 do nothing, 1 drop items or 2 store items on death
function storageApi.init(args)
    if storage.sApi == nil then
        storage.sApi = {}
        local content = args.content or entity.configParameter("storageapi.content")
        if content then
            storage.sApi = content
        end
    end
    storageApi.mode = args.mode or entity.configParameter("storageapi.mode") or 0
    storageApi.isin = storageApi.mode % 2 == 1
    storageApi.isout = storageApi.mode % 4 >= 2
    storageApi.capacity = math.min(999, args.capacity or entity.configParameter("storageapi.capacity") or 1)
    storageApi.isjoin = args.merge or entity.configParameter("storageapi.merge")
    storageApi.dropPosition = args.dropPosition or entity.configParameter("storageapi.dropPosition") or entity.position()
    storageApi.ondeath = args.ondeath or entity.configParameter("storageapi.ondeath") or 0
    storageApi.ignoreDropIds = {}
end

--- Should the storage be initialized?
-- @returns True if storage should be initialized
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
-- @returns True if storage is full
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
-- @param index (int) index of item
-- @returns (table) of item descriptor
function storageApi.peekItem(index)
    return storage.sApi[index]
end

--- Returns an iterator for the whole storage
-- @returns (table) of item descriptors
function storageApi.getIterator()
    return pairs(storage.sApi)
end

--- Take an item from storage
-- @param index (int) index of item
-- @param count (Optional) Amount of the item to take from the stack
-- @returns (table) of item descriptor or nil
function storageApi.returnItem(index, count)
    if (beforeiTemTaken ~= nil) and beforeiTemTaken(index, count) then return nil end
    local ret = storage.sApi[index]
    if (count == nil) or (ret.count >= count) then
        storage.sApi[index] = nil
    else
        storage.sApi[index].count = ret.count - count
        ret.count = count
    end
    if (afteritEmtaken ~= nil) then afteritEmtaken(ret.name, ret.count, ret.data) end
    return ret
end

--- Get maximum stack size for an item type
-- @param itemname (string) The name of item to get
-- @returns (int) max stack size
function storageApi.getMaxStackSize(itemname)
    if itemname == "climbingrope" then return 1000
    elseif itemname == "money" then return 25000 end
    local t = world.itemType(itemname)
    if (t == "generic") or (t == "coin") or (t == "material") or (t == "consumable") or (t == "thrownitem") or (t == "object") then return 1000
    else return 1 end
end

--- Checks if the item can be fit inside storage
-- @param itemname (string) The name of item to get
-- @param count (int) The amount of item to get
-- @param properties (optional) The properties table of the item
-- @returns True if item fits in storage or false
function storageApi.canFitItem(itemname, count, properties)
    local max = storageApi.getMaxStackSize(itemname)
    local spacecnt = (storageApi.getCapacity() - storageApi.getCount()) * max
    if spacecnt >= count then return true
    elseif max > 1 then return false end
    for i,v in storageApi.getIterator() do
        if (itemname == v.name) and compareTables(properties, v.data) then
            spacecnt = spacecnt + max - v.count
        end
        if spacecnt >= count then return true end
    end
    return false
end

--- Take a specific type of item from storage
-- @param itemname (string) The name of item to get
-- @param count (int) The amount of item to get
-- @param properties (optional) The properties table of the item
-- @returns (table) descriptor of the item taken
-- function storageApi.returnItemByName(itemname, count, properties)
--     if (storageApi.beforeReturnByName ~= nil) and storageApi.beforeReturnByName(itemname, count, properties) then return { itemname, count, properties } end
--     --TODO: Change it so hook defines return?
--     if properties == nil then
--         for i,v in storageApi.getIterator() do
--             if v.name == itemname then
--                 properties = v.data
--                 break
--             end
--         end
--     end
--     if properties == nil then return { itemname, 0, { } } end
--     local retcnt = 0
--     for i,v in storageApi.getIterator() do
--         if retcnt >= count then break end
--         if (v.name == itemname) and compareTables(properties, v.data) then
--             retcnt = retcnt + storageApi.returnItem(i, count - retcnt).count
--         end
--     end
--     return { itemname, retcnt, properties }
-- end

--- Take all items from storage
-- @return (table) of taken iems
function storageApi.returnContents()
    local ret = storage.sApi
    storage.sApi = {}
    if (afterAllItemsTaken ~= nil) then afterAllItemsTaken() end
    return ret
end

--- Get first empty key in storage table
-- @return (int) first empty key
function storageApi.getFirstEmptyIndex()
    for i=1,999 do
        if storage.sApi[i] == nil then return i end
    end
    return 1000
end

--- Put an item in storage, returns true if successfully
-- @param itemname (string) The name of item to get
-- @param count (int) The amount of item to get
-- @param properties (optional) The properties table of the item
-- @return True if item could be stored
function storageApi.storeItem(itemname, count, properties)
    if not storageApi.canFitItem(itemname, count, properties) then return false end
    if (beforeItemStored ~= nil) and beforeItemStored(itemname, count, properties) then return false end
    --TODO: Change it so hook defines return?
    if storageApi.isMerging() then
        local max = storageApi.getMaxStackSize(itemname)
        for i,stack in storageApi.getIterator() do
            if (stack.name == itemname) and (stack.count < max) and compareTables(properties, stack.data) then
                if (stack.count + count > max) then
                    local newIndex = storageApi.getFirstEmptyIndex()
                    storage.sApi[newIndex] = { name = itemname, count = (stack.count + count) - max, data = properties }
                    if (afterItemStored ~= nil) then afterItemStored(newIndex, false) end
                    count = max - stack.count
                end
                storage.sApi[i].count = stack.count + count
                if afterItemStored then afterItemStored(i, true) end
                return true
            end
        end
    end
    local i = storageApi.getFirstEmptyIndex()
    storage.sApi[i] = { name = itemname, count = count, data = properties }
    if afterItemStored then afterItemStored(i, false) end
    return true
end

--- Put as much items as possible in storage, handles oversized stacks
-- @param itemname (string) The name of item to get
-- @param count (int) The amount of item to get
-- @param properties (optional) The properties table of the item
-- @return The amount of item that got stored
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
        if (v.name == itemname) and (v.count < max) and compareTables(properties, v.data) then
            local amo = math.min(max, v.count + count)
            storage.sApi[i].count = amo
            count = count + v.count - amo
        end
    end
    return ret
end

--- Drops one item
-- @param index (int) index of item
-- @param amount (optional) If provided will only drop certain amount of item
-- @param pos (optional) { x, y } position to drop item
-- @returns Id of dropped item entity or false
function storageApi.drop(index, amount, pos)
    pos = pos or storageApi.dropPosition
    local item, drop = storage.sApi[index], false
    if item then
        world.logInfo("Drop item %s", item)

        if not amount then amount = item.count or 0 end
        if amount > 0 then
            if not item.data or next(item.data) == nil then
                drop = world.spawnItem(item.name, pos, amount)
            else
                drop = world.spawnItem(item.name, pos, amount, item.data)
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

--- Drops all item
-- @param pos (optional) { x, y } position to drop item
-- @returns True if it could drop all items
function storageApi.dropAll(pos)
    pos = pos or storageApi.dropPosition
    for i,stack in storageApi.getIterator() do
        storageApi.drop(i, stack.count)
    end
    if storageApi.getCount() == 0 then
        return true
    end
    return false
end

--- Checks if item was recently dropped by
-- @param entityId (int) id of dropped item entity
-- @param cooldown (optional) how long to let the item stay
-- @param time (optional) current os.time time
-- @returns True if item was not just dropped
function storageApi.notJustDropped(entityId, cooldown, time)
    cooldown = cooldown or 20
    time = time or os.time()
    if storageApi.ignoreDropIds[entityId] == nil or storageApi.ignoreDropIds[entityId]+cooldown < time then
        storageApi.ignoreDropIds[entityId] = nil
        return true
    end
    return false
end

--- Try to take item drop
-- @param pos (optional) { x, y } position to drop item
-- @param radius (int) radius
-- @param takenBy (int) entity id to animate item drop to
-- @returns Amount of found items or false
function storageApi.take(pos, radius, takenBy)
    pos = pos or storageApi.dropPosition
    radius = radius or 1
    local itemIds, time, ret = world.itemDropQuery(pos, radius), os.time(), false
    for _, itemId in ipairs(itemIds) do
        if storageApi.notJustDropped(itemId, 10, time) then
            local item = world.takeItemDrop(itemId, takenBy)
            if item then
                ret = (ret or 0) + 1
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
    elseif storageApi.ondeath == 2 then
        world.spawnItem(entity.configParameter("objectName"), storageApi.dropPosition, 1, { content = storage.sApi()} )
    end
end

