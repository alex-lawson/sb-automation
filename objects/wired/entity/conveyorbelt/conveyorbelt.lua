function init(v)
  energy.init()
  
  if storage.active == nil then storage.active = false end
  setActive(storage.active)
  self.workSound = entity.configParameter("workSound")
  self.moveSpeed = entity.configParameter("moveSpeed")
  self.st = 0
  self.laet = {}
  self.raet = {}
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
  storage.active = flag
  if flag then entity.setAnimationState("workState", "work")
  else entity.setAnimationState("workState", "idle") end
end

function filterEntities(eids)
  local valid = { "monster", "npc" }
  local ret = { }
  for i, id in pairs(eids) do
    if (self.aet[id] == nil) and (self.laet[id] == nil) and (self.raet[id] == nil) and (not world.callScriptedEntity(id, "entity.configParameter", "isStatic", false)) then
      local et = world.entityType(id)
      for j, vt in pairs(valid) do
        if (et == vt) and world.callScriptedEntity(id, "entity.onGround") then
          ret[#ret + 1] = id
          break
        end
      end
    end
  end
  return ret
end

function process(ox, oy)
  local f = entity.direction()
  local eids = world.entityQuery(entity.toAbsolutePosition({ f * ox, oy }), 2, { notAnObject = true, order = "nearest" })
  eids = filterEntities(eids)
  for i,id in pairs(eids) do
    local e = entityProxy.create(id)
    local v = e.velocity()
    if v ~= nil then
      v[1] = v[1] + self.moveSpeed * f
      e.setVelocity(v)
      self.aet[id] = true
    end
  end
end

function setlaet(data)
  self.laet = data
end

function setraet(data)
  self.raet = data
end

function main()
  energy.update()
  if storage.active then
    if not energy.consumeEnergy() then
      setActive(false)
    end
    
    self.aet = {}
    self.st = self.st + 1
    if self.st > 6 then self.st = 0
    elseif self.st == 3 then entity.playImmediateSound(self.workSound) end
    for x=-1,1 do
      process(x, 1.5)
      process(x, 2.5)
    end
    local q = world.objectQuery(entity.toAbsolutePosition({ 4, 0 }), 2, { name = "conveyorbelt" })
    for i,id in pairs(q) do
      world.callScriptedEntity(id, "setraet", self.aet)
    end
    q = world.objectQuery(entity.toAbsolutePosition({ -4, 0 }), 2, { name = "conveyorbelt" })
    for i,id in pairs(q) do
      world.callScriptedEntity(id, "setlaet", self.aet)
    end
  end
end