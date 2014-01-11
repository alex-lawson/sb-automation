function init(virtual)
  if not virtual then
    entity.setInteractive(true)

    if storage.state == nil then
      storage.state = true
    end
    updateAnimationState()

    self.connectionMap = {}
    self.connectionMap[1] = 2
    self.connectionMap[2] = 1
    self.connectionMap[3] = 4
    self.connectionMap[4] = 3
    world.logInfo(self.connectionMap)
  
    pipes.init({liquidPipe,itemPipe})
  end
end

--------------------------------------------------------------------------------

function onInteraction(args)
  if not entity.isInboundNodeConnected(0) then
    storage.state = not storage.state
    updateAnimationState()
  end
end

function onInboundNodeChange(args)
  checkInboundNodes()
end

function onNodeConnectionChange()
  checkInboundNodes()
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function checkInboundNodes()
  if entity.isInboundNodeConnected(0) then
    entity.setInteractive(false)
    storage.state = entity.getInboundNodeLevel(0)
    updateAnimationState()
  else
    entity.setInteractive(true)
  end
end

function updateAnimationState()
  if storage.state then
    entity.setAnimationState("switchState", "on")
  else
    entity.setAnimationState("switchState", "off")
  end
end

-- function beforeLiquidGet(liquid, nodeId)
--   return false
-- end

-- function beforeLiquidPut(liquid, nodeId)
--   return storage.state and isLiquidOutboundConnected(self.connectionMap[nodeId])
-- end

-- function onLiquidPut(liquid)
--   return false
-- end

-- function beforeItemGet(item, nodeId)
--   return false
-- end

-- function beforeItemPut(item, nodeId)
--   local canPutItem = storage.state and isItemOutboundConnected(self.connectionMap[nodeId])
--   if canPutItem then
--     world.logInfo("can put item from %s to %s", nodeId, self.connectionMap[nodeId])
--   else
--     world.logInfo("CANT PUT DA ITEM FRUM %s TO %s", nodeId, self.connectionMap[nodeId])
--   end
--   return canPutItem
-- end

function onItemPut(item, nodeId)
  if storage.state then
    world.logInfo("passing item from %s to %s", nodeId, self.connectionMap[nodeId])
    return pushItem(self.connectionMap[nodeId], item)
  else
    return false
  end
end