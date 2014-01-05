function init(v)
  if storage.active == nil then storage.active = false
  else entity.setParticleEmitterActive("fanwind", storage.active) end
  entity.setInteractive(true)
  self.affectWidth = entity.configParameter("affectWidth")
  self.blowSound = entity.configParameter("blowSound")
  self.fanPower = entity.configParameter("fanPower")
  self.timer = 0
  self.st = 0
end

function onInteraction(args)
  storage.active = not storage.active
  entity.setParticleEmitterActive("fanwind", storage.active)
  if storage.active then entity.setAnimationState("fanState", "work")
  else
    entity.setAnimationState("fanState", "slow")
    self.timer = 20
  end
end

function filterEntities(eids)
  local valid = { "monster", "npc" }
  local ret = { }
  for i, id in ipairs(eids) do
    if self.aet[id] == nil then
      local et = world.entityType(id)
      for j, vt in ipairs(valid) do
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

function process(ox, oy, mult)
  local f = entity.direction()
  local eids = world.entityQuery(entity.toAbsolutePosition({ f * ox, oy }), 2, { notAnObject = true, order = "nearest" })
  eids = filterEntities(eids)
  for i,id in ipairs(eids) do
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
  if storage.active then
    self.aet = {}
    self.st = self.st + 1
    if self.st > 6 then self.st = 0
    elseif self.st == 3 then entity.playImmediateSound(self.blowSound) end
    for x=1,self.affectWidth do
      for y=-1,1 do
        process(x, y)
      end
    end
  elseif self.timer > 0 then
    if self.timer % 12 == 4 then entity.playImmediateSound(self.blowSound) end
    self.timer = self.timer - 1
    if self.timer == 0 then entity.setAnimationState("fanState", "idle") end
  end
end