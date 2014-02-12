function init(args)
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "flying")
  
  local states = stateMachine.scanScripts(entity.configParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)
end

function die()

end

function main()
  local dt = entity.dt()
  self.state.update(dt)

  local masterId, minionIndex, minionTimer = findMaster()
  if masterId ~= 0 then
    self.hadMaster = true

    local angle = ((minionIndex - 1) * math.pi / 2.0) + minionTimer
    local target = vec2.add(world.entityPosition(masterId), {
      20.0 * math.cos(angle),
      8.0 * math.sin(angle)
    })

    entity.flyTo(target, true)
  else
    self.hadMaster = false

    entity.fly({0,0}, true)
  end

  util.trackTarget(30.0, 10.0)

  if self.targetPosition ~= nil then
    entity.setFireDirection({0,0}, world.distance(self.targetPosition, entity.position()))
    entity.startFiring("plasmabullet")
  else
    entity.stopFiring()
  end
end

function hasCapability(capability)
  if capability == 'spawnedBy' then
    return true
  end
  return false
end