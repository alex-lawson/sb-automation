function init(v)
  entity.setInteractive(true)
  if not v then
    pipes.init({itemPipe})
    local initInv = entity.configParameter("initialInventory")
    if initInv and (storage.sApi == nil) then
      storage.sApi = initInv
    end
    storageApi.init({ mode = 3, capacity = 10, ondeath = 1, merge = true })
    self.pushRate = entity.configParameter("itemPushRate")
    self.pushTimer = 0
    self.spawnTimer = 10
  end
end

function die()
  storageApi.die()
end

function droneRegister(eId)
  if (self.droneId == nil) or (self.droneId == eId) or not world.entityExists(self.droneId) then
    self.droneId = eId
    return true
  end
  return false
end

function droneDeath(eId)
  if self.droneId == eId then
    self.droneId = nil
  end
end

function droneLand(eId)
  if self.droneId == eId then
    local inv = world.callScriptedEntity(eId, "onLanding")
    if inv then
      self.droneId = nil
      entity.setAnimationState("droneState", "show")
      storage.spawned = false
    end
  end
end

function launchDrone()
  if self.droneId == nil then
    self.droneId = world.spawnMonster("itemdrone", entity.position(), { stationPos = entity.position() })
    entity.setAnimationState("droneState", "hide")
    storage.spawned = true
  end
end

function onInboundNodeChange(args)
  -- TODO: Toggle the drone state
end

function onInteraction(args)
  -- TODO: Toggle all
end

function main()
  pipes.update(entity.dt())
  if self.pushTimer > self.pushRate then
    for i,item in storageApi.getIterator() do
      local result = pushItem(1, item)
      if result == true then storageApi.returnItem(i) end
      if result and result ~= true then item.count = item.count - result end
      if result then break end
    end
    self.pushTimer = 0
  end
  self.pushTimer = self.pushTimer + entity.dt()
end