function init()
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "flying")
  if storageApi.isInit() then
    storageApi.init({ mode = 1, space = 9, join = true, ondeath = 1 })
  end
  local states = stateMachine.scanScripts(entity.configParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)
  if storage.stationPos == nil then
    storage.stationPos = entity.configParameter("stationPos")
  end
  if (self.stationId == nil) or not world.entityExists(self.stationId) then
    local ids = world.objectQuery(storage.stationPos, 5, { order = "nearest", name = "dronestation", callScript = "droneRegister", callScriptArgs = { entity.id() } })
    for _,v in ids do
      self.stationId = v
      break
    end
  end
end

function die()
  world.callScriptedEntity(self.stationId or -1, "droneDeath", entity.id())
  storageApi.die()
end

function setDead()
  self.dead = true
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