function init(v)
  if storage.active == nil then storage.active = false end
  entity.setInteractive(true)
  self.levitationHeight = entity.configParameter("levitationHeight")
  self.workSound = entity.configParameter("workSound")
  self.st = 0
  self.laet = {}
  self.raet = {}
end

function onInteraction(args)
  storage.active = not storage.active
  if storage.active then entity.setAnimationState("jumpState", "jump")
  else entity.setAnimationState("jumpState", "idle") end
end

function filterEntities(eids)
  local valid = { "monster", "npc" }
  local ret = { }
  for i, id in ipairs(eids) do
    if (self.aet[id] == nil) and (self.laet[id] == nil) and (self.raet[id] == nil) then
      local et = world.entityType(id)
      for j, vt in ipairs(valid) do
        if (et == vt) then
          ret[#ret + 1] = id
          break
        end
      end
    end
  end
  return ret
end

function rand()
  return math.random() / 5 + 0.9
end

function process(ox, oy)
  local eids = world.entityQuery(entity.toAbsolutePosition({ ox + 0.5, oy }), 2, { notAnObject = true, order = "nearest" })
  eids = filterEntities(eids)
  for i,id in ipairs(eids) do
    local e = entityProxy.create(id)
    local v = e.velocity()
    if (v ~= nil) and (v[2] < self.levitationHeight - oy) then
      v[2] = v[2] + (self.levitationHeight - oy + 1) * rand()
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
    elseif self.st == 3 then entity.playImmediateSound(self.workSound) end
    for y=1,self.levitationHeight-1 do
      process(-1, y)
      process(0, y)
      process(1, y)
    end
    local q = world.objectQuery(entity.toAbsolutePosition({ 4, 0 }), 2, { name = "levitationpad" })
    for i,id in ipairs(q) do
      world.callScriptedEntity(id, "setraet", self.aet)
    end
    q = world.objectQuery(entity.toAbsolutePosition({ -4, 0 }), 2, { name = "levitationpad" })
    for i,id in ipairs(q) do
      world.callScriptedEntity(id, "setlaet", self.aet)
    end
  end
end