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
  local searchPos = {pos[1] + 0.5, pos[2] + 0.1}
  local entityIds = world.objectLineQuery(searchPos, searchPos, { withoutEntityId = entity.id(), order = "nearest" })
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
        return true
      else
        return item.count - canFit.leftover
      end
    end
  end
  return false
end

function onItemPut(item, nodeId)
  if item and self.chest then
    local returnedItem = world.containerAddItems(self.chest, item)
    if returnedItem then
      local returnCount = item.count - returnedItem.count
      if returnCount > 0 then
        return returnCount
      else
        return false
      end
    else
      return true
    end
  end
  return false
end

function beforeItemGet(filter, nodeId)
  if self.chest then
    if filter then
      for itemName, amount in pairs(filter) do
        local filterItem = {name=itemName, count=amount[1], data={}}
        local available = world.containerAvailable(self.chest, filterItem)
        if available >= 1 then return true end
      end
    else
      for key, item in pairs(world.containerItems(self.chest)) do
        return true
      end
    end
  end
  return false
end

function onItemGet(filter, nodeId)
  if self.chest then
    if filter then
      for itemName, amount in pairs(filter) do
        local filterItem = {name=itemName, count=amount[1], data={}}
        local availableAmount = world.containerAvailable(self.chest, filterItem)
        if availableAmount >= 1 then
          filterItem.count = math.min(availableAmount * amount[1], amount[2])
          world.containerConsume(self.chest, filterItem)
          return filterItem
        end
      end
    else
      for key, item in pairs(world.containerItems(self.chest)) do
        return item
      end
    end
  end
  return false
end