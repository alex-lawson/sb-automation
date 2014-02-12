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

function setActive(flag)
  if not flag or energy.consumeEnergy(nil, true) then
    entity.setParticleEmitterActive("fanwind" .. self.flipStr, flag)
    if flag then
      entity.setAnimationState("fanState", "work")
    elseif storage.active then
      entity.setAnimationState("fanState", "slow")
      self.timer = 20
    else
      entity.setAnimationState("fanState", "idle")
    end
    storage.active = flag
  end
end


function main()
  energy.update()
  if storage.active then
    if not energy.consumeEnergy() then
      setActive(false)
      return
    end
    self.st = self.st + 1
    if self.st > 6 then 
      self.st = 0
    elseif self.st == 3 then 
      entity.playImmediateSound(self.blowSound)
    end
    local d = entity.direction();
    local p = entity.position();
    local region;
    if d == 1 then
      region = { p[1], p[2] - 1, p[1] + d * self.affectWidth, p[2] + 1 }
    else
      region = { p[1] + d * self.affectWidth, p[2] - 1, p[1], p[2] + 1 }
    end
    entity.setForceRegion(region, { self.fanPower * d, 0 })
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
