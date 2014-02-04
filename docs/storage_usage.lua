--------------------- SAMPLE MINIMAL IMPLEMENTATION --------------------

--- TODO: documents args

function init(virtual)
  if not virtual then
    storageApi.init(args)
  end
end

function die()
  storageApi.die()
end

--------------------- HOOKS --------------------

--- Called when an item is about to be taken from storage
-- @param index (int) The requested item index
-- @param count (int) The amount of item requested
-- @return (bool) If this returns true, the item is not taken and the returned item is null
function beforeItemTaken(index, count) end

--- Called when an item has been taken from storage
-- @param itemname, count, parameters - item data that was taken
function afterItemTaken(itemname, count, properties) end

--- Called when an item is about to be stored in storage
-- @param itemname, count, parameters - item data requested to be stored
-- @return (bool) If this returns true, the item is not stored and the parent method returns false
function beforeItemStored(itemname, count, properties) end

--- Called when an item has been stored in storage
-- @param index (int) The index assigned to the item
-- @param merged (bool) Whenever the item stack was merged into another, or not
function afterItemStored(index, merged) end

--- Called when all items have been taken from storage
function afterAllItemsTaken() end
