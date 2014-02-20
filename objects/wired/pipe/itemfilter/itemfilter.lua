function init(virtual)
  if not virtual then
    pipes.init({liquidPipe,itemPipe})

    entity.setInteractive(true)

    self.connectionMap = {}
    self.connectionMap[1] = 2
    self.connectionMap[2] = 1
    self.connectionMap[3] = 4
    self.connectionMap[4] = 3

    buildFilter()
  end
end

--------------------------------------------------------------------------------

-- function onInteraction(args)
--   local itemName = world.entityHandItem(args.sourceId, "primary")
--   if itemName == nil then
--     if storage.itemName == nil then
--       return { "ShowPopup", { message = "Filtered item : " .. "none" }}
--     else
--       return { "ShowPopup", { message = "Filtered item : " .. storage.itemName }}
--     end
--   else
--     storage.itemName = itemName
--     entity.setAnimationState("filterState", "on")
--   end
-- end

--------------------------------------------------------------------------------
function main(args)
  buildFilter()
  pipes.update(entity.dt())
end

function showPass()
  entity.setAnimationState("filterState", "pass")
end

function showFail()
  entity.setAnimationState("filterState", "fail")
end

function beforeLiquidGet(filter, nodeId)
  --world.logInfo("passing liquid peek get from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPullLiquid(self.connectionMap[nodeId], filter)
end

function onLiquidGet(filter, nodeId)
  --world.logInfo("passing liquid get from %s to %s", nodeId, self.connectionMap[nodeId])
  return pullLiquid(self.connectionMap[nodeId], filter)
end

function beforeLiquidPut(liquid, nodeId)
  --world.logInfo("passing liquid peek from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPushLiquid(self.connectionMap[nodeId], liquid)
end

function onLiquidPut(liquid, nodeId)
  --world.logInfo("passing liquid from %s to %s", nodeId, self.connectionMap[nodeId])
  return pushLiquid(self.connectionMap[nodeId], liquid)
end

function beforeItemPut(item, nodeId)
  --world.logInfo("Testing to put item %s with filter %s", item.name, storage.itemName)
  if self.filterCount > 0 then
    if self.filter[item.name] then
      --world.logInfo("passing item peek from %s to %s", nodeId, self.connectionMap[nodeId])
      return peekPushItem(self.connectionMap[nodeId], item)
    end
  end

  return false
end

function onItemPut(item, nodeId)
  local pushResult = false

  --world.logInfo("Trying to put item %s with filter %s", item.name, storage.itemName)
  if self.filterCount > 0 then
    if self.filter[item.name] then
      --world.logInfo("passing item from %s to %s", nodeId, self.connectionMap[nodeId])
      pushResult = pushItem(self.connectionMap[nodeId], item)
    end
  end

  if pushResult then
    showPass()
  else
    showFail()
  end
  return pushResult
end

function beforeItemGet(filter, nodeId)
  if self.filterCount > 0 then
    for filterString, amount in pairs(filter) do
      local pullFilter = {}
      if self.filter[filterString] then
        pullFilter[filterString] = amount        
      end
    end

    return peekPullItem(self.connectionMap[nodeId], pullFilter)
  end

  return false
end

function onItemGet(filter, nodeId)
  local pullResult = false

  if self.filterCount > 0 then
    for filterString, amount in pairs(filter) do
      local pullFilter = {}
      if self.filter[filterString] then
        pullFilter[filterString] = amount
      end
    end

    pullResult = pullItem(self.connectionMap[nodeId], pullFilter)
  end

  if pullResult then
    showPass()
  else
    showFail()
  end

  return pullResult
end

function buildFilter()
  self.filter = {}
  self.filterCount = 0
  local contents = world.containerItems(entity.id())
  if contents then
    for key, item in pairs(contents) do
      if self.filter[item.name] then
        self.filter[item.name] = math.min(self.filter[item.name], item.count)
      else
        self.filter[item.name] = item.count
        self.filterCount = self.filterCount + 1
      end
    end
  end

  if self.filterCount > 0 then
    entity.setAnimationState("filterState", "on")
  else
    entity.setAnimationState("filterState", "off")
  end

end