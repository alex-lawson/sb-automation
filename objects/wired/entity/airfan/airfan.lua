function init(v)
  energy.init()

  if storage.active == nil then storage.active = false end

  self.flipStr = ""
  if entity.direction() == -1 then
    self.flipStr = "flip"
  end
  entity.setParticleEmitterActive("fanwind", false)
  entity.setParticleEmitterActive("fanwindflip", false)

  setActive(storage.active)
  self.affectWidth = entity.configParameter("affectWidth")
  self.blowSound = entity.configParameter("blowSound")
  self.fanPower = entity.configParameter("fanPower")
  self.timer = 0
  self.st = 0
  onNodeConnectionChange(nil)
end

function die()
  energy.die()
end

function onNodeConnectionChange(args)
  if entity.isInboundNodeConnected(0) then
    entity.setInteractive(false)
  else
    entity.setInteractive(true)
  end
  onInboundNodeChange(args)
end

function onInboundNodeChange(args)
  if entity.isInboundNodeConnected(0) then
    setActive(entity.getInboundNodeLevel(0))
  end
end

function onInteraction(args)
  setActive(not storage.active)
end

function setActive(isActive)
  entity.setParticleEmitterActive("fanwind"..self.flipStr, isActive)
  if isActive then
    entity.setAnimationState("fanState", "work")
  elseif storage.active then
    entity.setAnimationState("fanState", "slow")
    self.timer = 20
  else
    entity.setAnimationState("fanState", "idle")
  end
  storage.active = isActive
end

function filterEntities(eids)
  local valid = { "monster", "npc" }
  local ret = { }
  for i, id in pairs(eids) do
    if self.aet[id] == nil and (not world.callScriptedEntity(id, "entity.configParameter", "isStatic", false)) then
      local et = world.entityType(id)
      for j, vt in pairs(valid) do
        if et == vt then
          ret[#ret + 1] = id
          break
        end
      end
    end
  end
  return ret
end

function rand()
  return (math.random() + 1) * 2 / 3
end

function process(ox, oy)
  local f = entity.direction()
  local eids = world.entityQuery(entity.toAbsolutePosition({ f * ox + 0.5, oy + 0.5 }), 2, { notAnObject = true, order = "nearest" })
  eids = filterEntities(eids)
  for i,id in pairs(eids) do
    local e = entityProxy.create(id)
    local v = e.velocity()
    if v ~= nil then
      v[1] = v[1] + self.fanPower * f * (self.affectWidth - ox) * rand() / self.affectWidth
      e.setVelocity(v)
      self.aet[id] = true
    end
  end
end

function main()
  energy.update()
  if storage.active then
    if not energy.consumeEnergy() then
      setActive(false)
    end

    --world.logInfo("air fan has %d energy", energy.getEnergy())

    self.aet = {}
    self.st = self.st + 1
    if self.st > 6 then 
      self.st = 0
    elseif self.st == 3 then 
      entity.playImmediateSound(self.blowSound)
    end
    for x=1,self.affectWidth do
      for y=-2,1 do
        process(x, y)
      end
    end
  elseif self.timer > 0 then
    if self.timer % 12 == 4 then 
      entity.playImmediateSound(self.blowSound) 
    end
    self.timer = self.timer - 1
    if self.timer == 1 then 
      entity.setAnimationState("fanState", "idle") 
    end
  end
end