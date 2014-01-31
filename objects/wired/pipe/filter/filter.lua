function init(virtual)
  if not virtual then
    entity.setInteractive(true)

    entity.setAnimationState("switchState", "off")

    if storage.block == nil then storage.block = {} end
    if storage.placedBlock == nil then storage.placedBlock = {} end

    self.connectionMap = {}
    self.connectionMap[1] = 2
    self.connectionMap[2] = 1
    self.connectionMap[3] = 4
    self.connectionMap[4] = 3
  
    pipes.init({liquidPipe,itemPipe})
  end
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function beforeLiquidGet(liquid, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing liquid peek get from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return peekPullLiquid(self.connectionMap[nodeId], liquid)
  -- else
    return false
  -- end
end

function onLiquidGet(liquid, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing liquid get from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return pullLiquid(self.connectionMap[nodeId], liquid)
  -- else
    return false
  -- end
end

function beforeLiquidPut(liquid, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing liquid peek from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return peekPushLiquid(self.connectionMap[nodeId], liquid)
  -- else
    return false
  -- end
end

function onLiquidPut(liquid, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing liquid from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return pushLiquid(self.connectionMap[nodeId], liquid)
  -- else
    return false
  -- end
end

function beforeItemPut(item, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing item peek from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return peekPushItem(self.connectionMap[nodeId], item)
  -- else
    return false
  -- end
end

function onItemPut(item, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing item from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return pushItem(self.connectionMap[nodeId], item)
  -- else
    return false
  -- end
end

function beforeItemGet(filter, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing item peek get from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return peekPullItem(self.connectionMap[nodeId], filter)
  -- else
    return false
  -- end
end

function onItemGet(filter, nodeId)
  -- if storage.state then
  --   --world.logInfo("passing item get from %s to %s", nodeId, self.connectionMap[nodeId])
  --   return pullItem(self.connectionMap[nodeId], filter)
  -- else
    return false
  -- end
end