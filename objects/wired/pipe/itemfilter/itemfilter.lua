function init(virtual)
  if not virtual then
    pipes.init({liquidPipe,itemPipe})

    entity.setInteractive(true)

    self.connectionMap = {}
    self.connectionMap[1] = 2
    self.connectionMap[2] = 1
    self.connectionMap[3] = 4
    self.connectionMap[4] = 3

    if storage.itemName then
      entity.setAnimationState("filterState", "on")
    else
      entity.setAnimationState("filterState", "off")
    end
  end
end

--------------------------------------------------------------------------------

function onInteraction(args)
  local itemName = world.entityHandItem(args.sourceId, "primary")
  if itemName == nil then
    if storage.itemName == nil then
      return { "ShowPopup", { message = "Filtered item : " .. "none" }}
    else
      return { "ShowPopup", { message = "Filtered item : " .. storage.itemName }}
    end
  else
    storage.itemName = itemName
    entity.setAnimationState("filterState", "on")
  end
end

--------------------------------------------------------------------------------
function main(args)
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
  if storage.itemName ~= nil then
    if item.name == storage.itemName then
      --world.logInfo("passing item peek from %s to %s", nodeId, self.connectionMap[nodeId])
      showPass()
      return peekPushItem(self.connectionMap[nodeId], item)
    else
      showFail()
    end
  end

  return false
end

function onItemPut(item, nodeId)
  --world.logInfo("Trying to put item %s with filter %s", item.name, storage.itemName)
  if storage.itemName ~= nil then
    if item.name == storage.itemName then
      --world.logInfo("passing item from %s to %s", nodeId, self.connectionMap[nodeId])
      showPass()
      return pushItem(self.connectionMap[nodeId], item)
    else
      showFail()
    end
  end

  return false
end

function beforeItemGet(filter, nodeId)
  if storage.itemName ~= nil then
    for filterString, amount  in pairs(filter) do
      local pullFilter = {}
      if filterString == storage.itemName then
        pullFilter[filterString] = amount
        --world.logInfo("passing item peek get from %s to %s", nodeId, self.connectionMap[nodeId])
        showPass()
        return peekPullItem(self.connectionMap[nodeId], pullFilter)
      else
        showFail()
      end
    end
  end

  return false
end

function onItemGet(filter, nodeId)
  if storage.itemName ~= nil then
    for filterString, amount in pairs(filter) do
      local pullFilter = {}
      if filterString == storage.itemName then
        pullFilter[filterString] = amount
        --world.logInfo("passing item get from %s to %s", nodeId, self.connectionMap[nodeId])
        showPass()
        return pullItem(self.connectionMap[nodeId], pullFilter)
      else
        showFail()
      end
    end
  end

  return false
end