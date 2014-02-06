function init()
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "flying")
  if storageApi.isInit() then
    storageApi.init({ mode = 1, capacity = 9, join = true, ondeath = 1 })
  end
  local states = stateMachine.scanScripts(entity.configParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)
  if storage.stationPos == nil then
    storage.stationPos = entity.configParameter("stationPos")
  end
  if storage.active == nil then storage.active = true end
  if (self.stationId == nil) or not world.entityExists(self.stationId) then
    local ids = world.objectQuery(storage.stationPos, 1, { name = "dronestation", callScript = "droneRegister", callScriptArgs = { entity.id() } })
    for _,v in ids do
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
  self.dead = true
  return storageApi.returnContents()
end

function shouldDie()
  return dead or not world.entityExists(self.stationId or -1)
end

function moveTo(pos, dt)
  entity.flyTo(pos, true)
end

function main()
  local dt = entity.dt()
  self.state.update(dt)
end