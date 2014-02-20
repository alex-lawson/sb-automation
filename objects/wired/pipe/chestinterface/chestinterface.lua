function init(virtual)
  if not virtual then
    pipes.init({itemPipe})

    if entity.direction() < 0 then
      pipes.nodes["liquid"] = entity.configParameter("flippedLiquidNodes")
      pipes.nodes["item"] = entity.configParameter("flippedItemNodes")
    end

    connectChest()
  end
end

function main(args)
  pipes.update(entity.dt())

  connectChest()
  
  --Push out items if switched on
  if self.chest and entity.getInboundNodeLevel(0) then
    pushItems()
  end
end

function connectChest()
  self.chest = false
  local pos = entity.toAbsolutePosition({entity.direction(), 1})
  local entityIds = world.objectQuery({pos[1] - 0.2, pos[2] - 0.2}, {pos[1] + 0.2, pos[2] + 0.2}, { withoutEntityId = entity.id(), order = "nearest" })
  --world.logInfo("searched for chests, found entities %s", entityIds)
  for i, entityId in ipairs(entityIds) do
    if world.containerSize(entityId) then
      self.chest = entityId
      --world.logInfo("connected successfully to %s %d", world.entityName(entityId), entityId)
      break
    end
  end
end

function pushItems()
  local items = world.containerItems(self.chest)
  world.logInfo("attempting to push items %s", items)
  for key, item in pairs(items) do
    local result = pushItem(1, item)
    if result then
      if result ~= true then
        item.count = result --amount accepted
      end
      world.containerConsume(self.chest, item)

      break
    end
  end
end

function beforeItemPut(item, nodeId)
  if item and self.chest then
    local canFit = world.containerItemsFitWhere(self.chest, item)
    if canFit then
      if canFit.leftover == 0 then
        world.logInfo("(peek) accepted whole stack %s", item)
        return true
      else
        world.logInfo("(peek) accepted partial stack %s", item)
        return item.count - canFit.leftover
      end
    end
  end
  world.logInfo("(peek) didn't accept item %s", item)
  return false
end

function onItemPut(item, nodeId)
  if item and self.chest then
    local returnedItem = world.containerAddItems(self.chest, item)
    if returnedItem then
      world.logInfo("(put) didn't accept full stack, returned %s", returnedItem)
      local returnCount = item.count - returnedItem.count
      if returnCount > 0 then
        return returnCount
      else
        return false
      end
    else
      world.logInfo("(put) accepted whole stack %s", item)
      return true
    end
  end
  world.logInfo("(put) failed for item %s", item)
  return false
end

-- function beforeItemGet(filter, nodeId)
--   if filter then
--     for i,item in storageApi.getIterator() do
--       for filterString,amount  in ipairs(filter) do
--         if item.name == filterString and item.count >= amount[1] then
--           return true 
--         end
--       end
--     end
--   else
--     for i,item in storageApi.getIterator() do
--       return true
--     end
--   end
--   return false
-- end

-- function onItemGet(filter, nodeId)
--   if filter then
--     for i,item in storageApi.getIterator() do
--       for filterString,amount  in pairs(filter) do
--         if item.name == filterString and item.count >= amount[1] then
--           if item.count <= amount[2] then
--             return storageApi.returnItem(i)
--           else
--             item.count = item.count - amount[2]
--             return {name = item.name, count = amount[2], data = item.data}
--           end
--         end
--       end
--     end
--   else
--     for i,item in storageApi.getIterator() do
--       return storageApi.returnItem(i)
--     end
--   end
--   return false
-- end