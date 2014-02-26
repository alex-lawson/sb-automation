function init()
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "start")
  if storageApi.isInit() then
    storageApi.init({ mode = 1, capacity = 4, merge = true, ondeath = 1 })
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
  self.start = 2
  storage.fuel = 50
end

function setActive(flag)
  storage.active = flag
end

function die()
  world.callScriptedEntity(self.stationId or -1, "droneDeath", entity.id())
  storageApi.die()
end

function onLanding()
  entity.setAnimationState("movement", "start")
  entity.setDeathParticleBurst(nil)
  self.dead = true
  return storage.fuel
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
    else if self.start > 0 then
      self.start = self.start - entity.dt()
      if self.start <= 0 then
        entity.setAnimationState("movement", "fly")
      end
    else
      local dt = entity.dt()
      storage.fuel = storage.fuel - dt * 2.5
      self.state.update(dt)
    end
  end
end