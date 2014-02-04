function init(virtual)
  if not virtual then
    if storage.state == nil then
      storage.state = false
    end

    if storage.timer == nil then
      storage.timer = 0
    end

    self.detectCooldown = entity.configParameter("detectCooldown")

    updateAnimationState()

    self.connectionMap = {}
    self.connectionMap[1] = 2
    self.connectionMap[2] = 1
    self.connectionMap[3] = 4
    self.connectionMap[4] = 3
  
    pipes.init({liquidPipe,itemPipe})
    datawire.init()
  end
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

--------------------------------------------------------------------------------
function main(args)
  datawire.update()
  pipes.update(entity.dt())

  if storage.timer > 0 then
    storage.timer = storage.timer - entity.dt()

    if storage.timer <= 0 then
      deactivate()
    end
  end
end

function updateAnimationState()
  if storage.state then
    entity.setAnimationState("switchState", "on")
  else
    entity.setAnimationState("switchState", "off")
  end
end

function activate()
  storage.timer = self.detectCooldown
  storage.state = true
  entity.setAllOutboundNodes(true)
  updateAnimationState()
end

function deactivate()
  storage.state = false
  updateAnimationState()
  entity.setAllOutboundNodes(false)
end

function output(item)
  if item.count then
    datawire.sendData(item.count, "number", "all")
  end
end

function beforeLiquidGet(liquid, nodeId)
  --world.logInfo("passing liquid peek get from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPullLiquid(self.connectionMap[nodeId], liquid)
end

function onLiquidGet(liquid, nodeId)
  --world.logInfo("passing liquid get from %s to %s", nodeId, self.connectionMap[nodeId])
  return pullLiquid(self.connectionMap[nodeId], liquid)
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
  --world.logInfo("passing item peek from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPushItem(self.connectionMap[nodeId], item)
end

function onItemPut(item, nodeId)
  --world.logInfo("passing item from %s to %s", nodeId, self.connectionMap[nodeId])
  local result = pushItem(self.connectionMap[nodeId], item)
  if result then
    activate()
    output(item)
  end
  return result
end

function beforeItemGet(filter, nodeId)
  --world.logInfo("passing item peek get from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPullItem(self.connectionMap[nodeId], filter)
end

function onItemGet(filter, nodeId)
  --world.logInfo("passing item get from %s to %s", nodeId, self.connectionMap[nodeId])
  local result = pullItem(self.connectionMap[nodeId], filter)
  if result then
    activate()
    output(result)
  end
  return result
end