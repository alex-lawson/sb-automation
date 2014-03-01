function init(virtual)
  if not virtual then
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

function math.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function setTargetPosition()
  entity.rotateGroup("target", self.zeroAngle + storage.targetAngle)
  local pos = entity.position()
  local tarX = math.round(math.cos(storage.targetAngle) * 2) + pos[1] + 0.5
  local tarY = math.round(math.sin(storage.targetAngle) * 2) + pos[2] + 0.5
  self.clickPos = {tarX, tarY}
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

    local eIds = world.entityLineQuery(self.clickPos, self.clickPos, { withoutEntityId = entity.id() })

    for i, eId in ipairs(eIds) do
      if world.entityType(eId) == "object" then
        --world.logInfo("clicking %d the %s", eId, world.entityName(eId))
        world.callScriptedEntity(eId, "onInteraction", interactArgs)
      end
    end
  end
end