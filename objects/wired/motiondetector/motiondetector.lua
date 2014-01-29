function init(args)
  self.detectArea = entity.configParameter("detectArea")
  self.detectAreaOffset = entity.configParameter("detectAreaOffset")

  --compute the origin or bottom left corner for detection
  if type(self.detectAreaOffset) == "table" then
    self.detectOrigin = {entity.position()[1] + self.detectAreaOffset[1], entity.position()[2] + self.detectAreaOffset[2]}
  else
    self.detectOrigin = entity.position()
  end

  --compute top right corner for detection (if area rectangular)
  if type(self.detectArea) == "table" then
    
    if type(self.detectAreaOffset) == "table" then
      self.detectArea = {entity.position()[1] + self.detectArea[1] + self.detectAreaOffset[1], entity.position()[2] + self.detectArea[2] + self.detectAreaOffset[2]}
    else
      self.detectArea = {entity.position()[1] + self.detectArea[1], entity.position()[2] + self.detectArea[2]}
    end
  end

  --allow triggering through manual interaction if specified
  entity.setInteractive(entity.configParameter("manualTrigger") ~= nil and entity.configParameter("manualTrigger"))

  --define valid entity types (defaults to player, monster and npc)
  self.detectEntityTypes = entity.configParameter("detectEntityTypes")
  if self.detectEntityTypes == nil then
    self.detectEntityTypes = {"player", "monster", "npc"}
  end

  --define time to stay active after detecting
  self.timeout = entity.configParameter("timeout")
  if self.timeout == nil then
    self.timeout = 0.1
  end

  entity.setAllOutboundNodes(false)
  entity.setAnimationState("switchState", "off")
  self.cooldown = 0
end

function trigger()
  entity.setAllOutboundNodes(true)
  entity.setAnimationState("switchState", "on")
  self.cooldown = self.timeout
end

function onInteraction(args)
  trigger()
end

function onEntityDetected(entityId, entityType)
  --hook for derivative scripts (e.g. target.lua)
end

function onTick()
  --hook for derivative scripts (e.g. target.lua)
end

function validateEntities(entityIds)
  for i, entityId in ipairs(entityIds) do
    local entityType = world.entityType(entityId)
    for j, detectEntityType in ipairs(self.detectEntityTypes) do
      if entityType == detectEntityType then
        onEntityDetected(entityId, entityType)
        return true
      end
    end
  end
  
  return false
end

function main() 
  if self.cooldown > 0 then
    self.cooldown = self.cooldown - entity.dt()
  else
    if self.cooldown <= 0 then
      local entityIds = world.entityQuery(self.detectOrigin, self.detectArea, { notAnObject = true, order = "nearest" })
      if #entityIds > 0 and validateEntities(entityIds) then
        trigger()
      else
        entity.setAllOutboundNodes(false)
        entity.setAnimationState("switchState", "off")
      end
    end
  end

  onTick()
end