--------------------- SAMPLE MINIMAL IMPLEMENTATION --------------------

--- TODO: documents args

function init(virtual)
  if not virtual then
    storage.init(args)
  end
end

function die()
  storage.die()
end

--------------------- HOOKS --------------------

-- Called when an item is about to be taken from storage
-- index - the requested item index
-- count - amount of the item to take
-- If this returns true, the item is not taken and the returned item is null
function beforeItemTaken(index, count) end

-- Called when an item has been taken from storage
-- itemname, count, parameters - item data that was taken
function afterItemTaken(itemname, count, properties) end

-- Called when an item is about to be stored in storage
-- itemname, count, parameters - item data requested to be stored
-- If this returns true, the item is not stored and the parent method returns false
function beforeItemStored(itemname, count, properties) end

-- Called when an item has been stored in storage
-- index - the index assigned to the item
-- merged - tells whenever the item stack was merged into another, or not
function afterItemStored(index, merged) end

-- Called when all items have been taken from storage
function afterAllItemsTaken() end
