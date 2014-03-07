function init(v)
  entity.setInteractive(true)
  if not v then
    energy.init()
    pipes.init({ itemPipe })
    if storageApi.isInit() then
      storageApi.init({ mode = 2, capacity = 9, ondeath = 1, merge = true })
    end
    self.pushRate = entity.configParameter("itemPushRate")
    self.pushTimer = 0
    if storage.power == nil then storage.power = 0 end
    if storage.active == nil then setActive(true)
    else setActive(storage.active) end
    if (storage.state == nil) or (storage.state == 1) then setStatus(2)
    else setStatus(storage.state) end
  end
end

function die()
  storageApi.die()
  energy.die()
  
end

function getLandingPos()
  return entity.toAbsolutePosition({ 0.5, 3 })
end

function setActive(f)
  storage.active = f
  if f then entity.setAnimationState("workState", "on")
  else entity.setAnimationState("workState", "off") end
  if self.droneId ~= nil then
    world.callScriptedEntity(self.droneId, "setActive", f)
  end
end

function setStatus(i)
  storage.state = i
  if i > 0 then
    entity.setAnimationState("droneState", "hide")
    if i > 1 then
      self.droneId = nil
      self.spawnTimer = 5
    end
  else
    self.droneId = nil
    entity.setAnimationState("droneState", "show")
  end
end

function droneRegister(eId)
  if (self.droneId == nil) or (self.droneId == eId) or not world.entityExists(self.droneId) then
    self.droneId = eId
    setStatus(1)
    return true
  end
  return false
end

function droneDeath(eId)
  if self.droneId == eId then setStatus(2) end
end

function droneLand(eId)
  if self.droneId == eId then
    local fuel = world.callScriptedEntity(eId, "onLanding")
    storage.power = math.max(0, storage.power + fuel)
    setStatus(0)
  end
end

function launchDrone()
  if self.droneId == nil then
    if (storage.power < 50) and energy.consumeEnergy(50 - storage.power) then
      storage.power = 50
    end
    if storage.power >= 50 then
      storage.power = storage.power - 50
      self.droneId = world.spawnMonster("itemdrone", getLandingPos(), { stationPos = entity.position() })
      setStatus(1)
    end
  end
end

function onInboundNodeChange(args)
  onNodeConnectionChange()
end

function onNodeConnectionChange()
  entity.setInteractive(not entity.isInboundNodeConnected(0))
  setActive(entity.getInboundNodeLevel(0))
end

function onInteraction(args)
  setActive(not storage.active)
end

function main()
  local dt = entity.dt()
  pipes.update(dt)
  energy.update()
  if self.pushTimer > self.pushRate then
    for i,item in storageApi.getIterator() do
      local result = pushItem(1, item)
      if result == true then storageApi.returnItem(i) end
      if result and result ~= true then item.count = item.count - result end
      if result then break end
    end
    self.pushTimer = 0
  end
  self.pushTimer = self.pushTimer + dt
  if (self.droneId ~= nil) and not world.entityExists(self.droneId) then setStatus(2) end
  if storage.active and (storage.state < 1) and not storageApi.isFull() then
    local drops = world.itemDropQuery(getLandingPos(), 20)
    if #drops > 0 then launchDrone() end
  elseif storage.state > 1 then
    if self.spawnTimer < 0 then
      setStatus(0)
    else self.spawnTimer = self.spawnTimer - dt end
  end
end