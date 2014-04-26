function init(virtual)
  if not virtual then
    pipes.init({liquidPipe,itemPipe})
    entity.setInteractive(true)

    self.connectionMap = {}
    self.connectionMap[1] = 3
    self.connectionMap[2] = 4
    self.connectionMap[3] = 1
    self.connectionMap[4] = 2

    self.rotations = {0, math.pi * 0.5, math.pi, math.pi * 1.5}
    storage.curDir = storage.curDir or 1
  
  end
end

--------------------------------------------------------------------------------

function onInteraction(args)
  toggleDir()
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())

  entity.rotateGroup("pipe", self.rotations[storage.curDir])
end

function toggleDir()
  storage.curDir = storage.curDir + 1
  if storage.curDir > 4 then storage.curDir = 1 end
end

function updateAnimationState()
  entity.setAnimationState("active", "on")
end

function beforeLiquidGet(filter, nodeId)
  if nodeId == storage.curDir then
    --world.logInfo("passing liquid peek get from %s to %s", nodeId, self.connectionMap[nodeId])
    return peekPullLiquid(self.connectionMap[nodeId], filter)
  else
    return false
  end
end

function onLiquidGet(filter, nodeId)
  if nodeId == storage.curDir then
    --world.logInfo("passing liquid get from %s to %s", nodeId, self.connectionMap[nodeId])
    local result = pullLiquid(self.connectionMap[nodeId], filter)
    if result then updateAnimationState() end
    return result
  else
    return false
  end
end

function beforeLiquidPut(liquid, nodeId)
  if nodeId == self.connectionMap[storage.curDir] then
    --world.logInfo("passing liquid peek from %s to %s", nodeId, self.connectionMap[nodeId])
    return peekPushLiquid(self.connectionMap[nodeId], liquid)
  else
    return false
  end
end

function onLiquidPut(liquid, nodeId)
  if nodeId == self.connectionMap[storage.curDir] then
    --world.logInfo("passing liquid from %s to %s", nodeId, self.connectionMap[nodeId])
    local result =  pushLiquid(self.connectionMap[nodeId], liquid)
    if result then updateAnimationState() end
    return result
  else
    return false
  end
end

function beforeItemPut(item, nodeId)
  if nodeId == self.connectionMap[storage.curDir] then
    --world.logInfo("passing item peek from %s to %s", nodeId, self.connectionMap[nodeId])
    return peekPushItem(self.connectionMap[nodeId], item)
  else
    return false
  end
end

function onItemPut(item, nodeId)
  if nodeId == self.connectionMap[storage.curDir] then
    --world.logInfo("passing item from %s to %s", nodeId, self.connectionMap[nodeId])
    local result =  pushItem(self.connectionMap[nodeId], item)
    if result then updateAnimationState() end
    return result
  else
    return false
  end
end

function beforeItemGet(filter, nodeId)
  if nodeId == storage.curDir then
    --world.logInfo("passing item peek get from %s to %s", nodeId, self.connectionMap[nodeId])
    return peekPullItem(self.connectionMap[nodeId], filter)
  else
    return false
  end
end

function onItemGet(filter, nodeId)
  if nodeId == storage.curDir then
    --world.logInfo("passing item get from %s to %s", nodeId, self.connectionMap[nodeId])
    local result = pullItem(self.connectionMap[nodeId], filter)
    if result then updateAnimationState() end
    return result
  else
    return false
  end
end