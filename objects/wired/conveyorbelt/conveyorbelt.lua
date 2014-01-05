function init(v)
  if storage.active == nil then storage.active = false end
  entity.setInteractive(true)
  self.workSound = entity.configParameter("workSound")
  self.moveSpeed = entity.configParameter("moveSpeed")
  self.st = 0
end

function onInteraction(args)
  storage.active = not storage.active
  if storage.active then entity.setAnimationState("workState", "work")
  else entity.setAnimationState("workState", "idle") end
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

function process(ox, oy)
  local f = entity.direction()
  local eids = world.entityQuery(entity.toAbsolutePosition({ f * ox + 0.5, oy }), 2, { notAnObject = true, order = "nearest" })
  eids = filterEntities(eids)
  for i,id in ipairs(eids) do
    local e = entityProxy.create(id)
    local v = e.velocity()
    if v ~= nil then
      v[1] = v[1] + self.workSpeed * f
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
    for x=-1,1 do
      for y=0,2 do
        process(x, y)
      end
    end
  end
end