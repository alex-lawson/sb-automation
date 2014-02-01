function init(v)
  energy.init()
  self.jumpt = 0
  self.boostPower = entity.configParameter("boostPower")
  self.jumpSound = entity.configParameter("jumpSound")
  self.energyPerJump = entity.configParameter("energyPerJump")
end

function die()
  energy.die()
end

function firstValidEntity(eids)
  local invalid = { "object", "projectile", "plant", "effect" }
  for i, id in pairs(eids) do
    if not world.callScriptedEntity(id, "entity.configParameter", "isStatic", false) then
      local et = world.entityType(id)
      local f = true
      for j, vt in pairs(invalid) do
        if et == vt then 
          f = false
          break
        end
      end
      if f then return id end
    end
  end
  return nil
end

function main()
  energy.update()
  if self.jumpt > 0 then 
    self.jumpt = self.jumpt - 1
  else
    local p = entity.toAbsolutePosition({ -1.3, 1 })
    local eids = world.entityQuery(p, { p[1] + 2.6, p[2] }, { notAnObject = true, order = "nearest" })
    if firstValidEntity(eids) ~= nil then
      if energy.consumeEnergy(self.energyPerJump) then
        entity.setForceRegion({ p[1], p[2], p[1] + 2.6, p[2] }, { 0, self.boostPower })
        self.jumpt = 7
      end
    end
  end
  local state = entity.animationState("jumpState")
  if state == "idle" and self.jumpt > 0 then
    entity.setAnimationState("jumpState", "jump")
    entity.playImmediateSound(self.jumpSound)
  elseif state == "jump" and self.jumpt < 1 then
    entity.setAnimationState("jumpState", "idle") 
  end
end