function init(virtual)
  if not virtual then
    -- local pos = entity.position()
    -- self.clickArea = {{pos[1] + 2, pos[2] - 0.5}, 1.75}

    self.zeroAngle = -math.pi / 2
    storage.targetAngle = (storage.targetAngle and storage.targetAngle % (2 * math.pi)) or 0
    setTargetPosition()

    entity.setInteractive(true)
  end
end

function onInteraction(args)
  cycleTarget()
end

function cycleTarget()
  storage.targetAngle = storage.targetAngle - (math.pi / 2)
  setTargetPosition()
end

function setTargetPosition()
  entity.rotateGroup("target", self.zeroAngle + storage.targetAngle)
  local pos = entity.position()
  local tarX = math.floor(math.cos(storage.targetAngle) * 2) + pos[1] + 0.5
  local tarY = math.floor(math.sin(storage.targetAngle) * 2) + pos[2] + 0.5
  -- self.clickArea = {{tarX, tarY}, 1.5}
  self.clickArea = {{tarX - 0.3, tarY - 0.3}, {tarX + 0.5, tarY + 0.5}}
  world.logInfo("target area changed to %s", self.clickArea)
end

function onNodeConnectionChange()
  checkNodes()
end

function onInboundNodeChange(args)
  checkNodes()
end

function checkNodes()
  if entity.getInboundNodeLevel(0) and not storage.state then
    click()
  end
  storage.state = entity.getInboundNodeLevel(0)
end

function click()
  if entity.animationState("clickState") ~= "on" then
    entity.setAnimationState("clickState", "on")
    local interactArgs = { source = entity.position(), sourceId = entity.id() }
    local eIds = world.entityQuery(self.clickArea[1], self.clickArea[2], { withoutEntityId = entity.id() })
    
    for i, eId in ipairs(eIds) do
      if world.entityType(eId) == "object" then
        world.logInfo("clicking %d the %s", eId, world.entityName(eId))
        world.callScriptedEntity(eId, "onInteraction", interactArgs)
      end
    end
  end
end