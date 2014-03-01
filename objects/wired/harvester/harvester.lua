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
        world.logInfo("(harvester) harvesting crop #%d  name: %s  type: %s  configName: %s", eId, world.entityName(eId), world.entityType(eId), world.callScriptedEntity(eId, "entity.configParameter", "objectName"))
        harvestCrop(eId)
      elseif world.entityType(eId) == "plant" then
        world.logInfo("(harvester) chopping plant #%d  name: %s  type: %s  configName: %s", eId, world.entityName(eId), world.entityType(eId), world.callScriptedEntity(eId, "entity.configParameter", "objectName"))
        world.damageTiles({world.entityPosition(eId)}, "foreground", entity.position(), "plantish", 100)
      else
        world.logInfo("(harvester) ignoring entity #%d  name: %s  type: %s  configName: %s", eId, world.entityName(eId), world.entityType(eId), world.callScriptedEntity(eId, "entity.configParameter", "objectName"))
      end
    end
  end
end

function harvestCrop(entityId)
  local interactions = world.callScriptedEntity(entityId, "entity.configParameter", "interactionTransition")
  if interactions then
    for key, interaction in pairs(interactions) do
      local drops = interaction.dropOptions
      if drops then
        local i = 2
        local odds = drops[1]
        while drops[i] do
          if drops[i + 1] == nil or math.random() < odds then
            local j = 1
            while drops[i][j] do
              world.spawnItem(drops[i][j].name, world.callScriptedEntity(entityId, "entity.toAbsolutePosition", { 0.0, 1.0 }), drops[i][j].count)
              j = j + 1
            end
            break
          end
          i = i + 1
        end
        break
      end
    end
    world.callScriptedEntity(entityId, "entity.break")
  end
end