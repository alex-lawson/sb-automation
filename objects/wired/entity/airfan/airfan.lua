function init(v)
  energy.init()

  if storage.active == nil then storage.active = false end
  setActive(storage.active)
  self.affectWidth = entity.configParameter("affectWidth")
  self.blowSound = entity.configParameter("blowSound")
  self.fanPower = entity.configParameter("fanPower")
  self.timer = 0
  self.st = 0
  onNodeConnectionChange(nil)
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
  storage.active = flag
  entity.setParticleEmitterActive("fanwind", flag)
  if flag then entity.setAnimationState("fanState", "work")
  else
    entity.setAnimationState("fanState", "slow")
    self.timer = 20
  end
end

function filterEntities(eids)
  local valid = { "monster", "npc" }
  local ret = { }
  for i, id in pairs(eids) do
    if self.aet[id] == nil then
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
  if energy.consumeEnergy(1) == false then
    setActive(false)
  end
  if storage.active then
    self.aet = {}
    self.st = self.st + 1
    if self.st > 6 then self.st = 0
    elseif self.st == 3 then entity.playImmediateSound(self.blowSound) end
    for x=1,self.affectWidth do
      for y=-2,1 do
        process(x, y)
      end
    end
  elseif self.timer > 0 then
    if self.timer % 12 == 4 then entity.playImmediateSound(self.blowSound) end
    self.timer = self.timer - 1
    if self.timer == 1 then entity.setAnimationState("fanState", "idle") end
  end
end