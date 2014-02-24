function init()
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "fly")
  if storageApi.isInit() then
    storageApi.init({ mode = 1, capacity = 4, join = true, ondeath = 1 })
  end
  local states = stateMachine.scanScripts(entity.configParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)
  if storage.stationPos == nil then
    storage.stationPos = entity.configParameter("stationPos")
  end
  if storage.active == nil then storage.active = true end
  if (self.stationId == nil) or not world.entityExists(self.stationId) then
    local ids = world.objectQuery(storage.stationPos, 1, { name = "dronestation", callScript = "droneRegister", callScriptArgs = { entity.id() } })
    for _,v in pairs(ids) do
      self.stationId = v
      break
    end
  end
end

function setActive(flag)
  storage.active = flag
end

function die()
  world.callScriptedEntity(self.stationId or -1, "droneDeath", entity.id())
  storageApi.die()
end

function onLanding()
  entity.setDeathParticleBurst(nil)
  self.dead = true
end

function shouldDie()
  return self.dead or not world.entityExists(self.stationId or -1)
end

function moveTo(pos, dt)
  entity.flyTo(pos, true)
end

function main()
  if not self.dead then
    if not world.entityExists(self.stationId or -1) then self.dead = true
    else self.state.update(entity.dt()) end
  end
end