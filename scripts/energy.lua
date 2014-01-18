-- HOOKS

-- called when energy needs are queried, should return the quantity of energy this object requests
-- function onEnergyNeedsCheck() end

-- called when energy is sent to the object, should return 
--    { totalEnergyAccepted, visited }
-- (no need to manually add entity.id() to visited)
-- function onEnergyReceived(amount, visited) end

energy = {}

-- Initializes the energy module (MUST BE CALLED IN OBJECT init() FUNCTION)
function energy.init()
  --can be used to disallow direct connection (e.g. for batteries)
  energy.allowConnection = entity.configParameter("energyAllowConnection")
  if energy.allowConnection == nil then
    energy.allowConnection = true
  end

  --capacity of internal energy storage
  energy.capacity = entity.configParameter("energyCapacity")
  if energy.capacity == nil then
    energy.capacity = 0
  end

  --amount of energy generated per second when active
  energy.generationRate = entity.configParameter("energyGenerationRate")
  if energy.generationRate == nil then
    energy.generationRate = 0
  end

  if storage.energyGenerationState == nil then
    storage.energyGenerationState = false
  end

  --amount of energy consumed per second when active
  energy.consumptionRate = entity.configParameter("energyConsumptionRate")
  if energy.consumptionRate == nil then
    energy.consumptionRate = 0
  end

  if storage.energyConsumptionState == nil then
    storage.energyConsumptionState = false
  end

  --current energy storage
  if storage.curEnergy == nil then
    storage.curEnergy = 0
  end

  --maximum amount of energy transmitted per second
  energy.sendRate = entity.configParameter("energySendRate")
  if energy.sendRate == nil then
    energy.sendRate = 0
  end

  --frequency (in seconds) to push energy (maybe make this hard coded)
  energy.sendFreq = entity.configParameter("energySendFreq")
  if energy.sendFreq == nil then
    energy.sendFreq = 0.5
  end

  --timer variable that tracks the cooldown until next transmission pulse
  energy.sendTimer = energy.sendFreq

  --maximum range (in blocks) that this device will search for entities to connect to
  --NOTE: we may not want to make this configurable, since it will result in strange behavior if asymmetrical
  energy.linkRange = entity.configParameter("energyLinkRange")
  if energy.linkRange == nil then
    energy.linkRange = 10
  end

  --determines how much power the device can transfer (without storing)
  energy.relayMax = entity.configParameter("energyRelayMax")

  --frequency (in seconds) to perform LoS checks on connected entities
  --energy.connectCheckFreq = 1

  --timer variable that tracks cooldown until next connection LoS check
  --energy.connectCheckTimer = energy.connectCheckFreq

  --table to hold id's of connected entities (no point storing this since id's change on reload)
  --  keys are entity id's, values are tables of connection parameters
  energy.connections = {}

  --flag used to run more initialization the first time main() is called (in energy.update())
  self.energyInitialized = false
end

-- performs any unloading necessary when the object is removed (MUST BE CALLED IN OBJECT die() FUNCTION)
function energy.die()
  for entityId, v in pairs(energy.connections) do
    energy.disconnect(entityId)
  end
end

-- Performs per-tick updates for energy module (MUST BE CALLED IN OBJECT main() FUNCTION)
function energy.update()
  if self.energyInitialized then
    --periodic energy transmission pulses
    if energy.sendRate > 0 then
      energy.sendTimer = energy.sendTimer - entity.dt()
      if energy.sendTimer <= 0 then
        if energy.getEnergy() >= 1 then --no nickels or dimes please
          local pulseEnergy = math.min(energy.getEnergy(), energy.sendRate * energy.sendFreq)
          --world.logInfo("initiating pulse with %f energy", pulseEnergy)
          local visited = {}
          visited[entity.id()] = true
          local result = energy.sendEnergy(pulseEnergy, visited)
          energy.removeEnergy(result[1])
        end
        energy.sendTimer = energy.sendTimer + energy.sendFreq
      end
    end

    --periodic connection checks
    -- DOING THESE ON EVERY PULSE FOR NOW
    -- energy.connectCheckTimer = energy.connectCheckTimer - entity.dt()
    -- if energy.connectCheckTimer <= 0 then
    --   energy.checkConnections()
    --   energy.connectCheckTimer = energy.connectCheckTimer + energy.connectCheckFreq
    -- end
  else
    if energy.allowConnection then
      energy.findConnections()
      energy.checkConnections()
    end
    self.energyInitialized = true
  end
end

-------------------------------------------------

-- Returns how much energy the object currently holds
function energy.getEnergy()
  return storage.curEnergy
end

-- sets the current energy pool (and provides a place to update animations, etc.)
function energy.setEnergy(amount)
  if amount ~= energy.getEnergy() then
    storage.curEnergy = amount
    onEnergyChange(amount)
  end
end

-- object hook called when energy amount is changed
if not onEnergyChange then
  function onEnergyChange(newAmount) end
end

-- returns the total amount of space in the object's energy storage
function energy.getCapacity()
  return energy.capacity
end

-- returns the amount of free space in the object's energy storage
function energy.getUnusedCapacity()
  return energy.capacity - energy.getEnergy()
end

-- adds the appropriate periodic energy generation based on energyGenerationRate and scriptDelta
-- @returns amount of energy generated
function energy.generateEnergy()
  local amount = energy.generationRate * entity.dt()
  --world.logInfo("generating %f energy", amount)
  return energy.addEnergy(amount)
end

-- Adds the specified amount of energy to the storage pool, to a maximum of <energy.capacity> 
-- @returns the amount added
function energy.addEnergy(amount)
  local newEnergy = energy.getEnergy() + amount
  if newEnergy <= energy.getCapacity() then
    energy.setEnergy(newEnergy)
    return amount
  else
    local addedEnergy = energy.getUnusedCapacity()
    energy.setEnergy(energy.getCapacity())
    return addedEnergy
  end
end

-- callback for receiving incoming energy pulses
function energy.receiveEnergy(amount, visited)
  --world.logInfo("%s %d receiving %d energy...", entity.configParameter("objectName"), entity.id(), amount)
  visited[entity.id()] = true
  if onEnergyReceived == nil then
    local acceptedEnergy = energy.addEnergy(amount)
    return {acceptedEnergy, visited}
  else
    return onEnergyReceived(amount, visited)
  end
end

-- reduces the current energy pool by the specified amount, to a minimum of 0
-- @returns the amount of energy removed
function energy.removeEnergy(amount, entityId)
  local newEnergy = energy.getEnergy() - amount
  if newEnergy <= 0 then
    energy.setEnergy(0)
    return amount + newEnergy
  else
    energy.setEnergy(newEnergy)
    return amount
  end
end

-- attempt to remove the specified amount of energy
-- if no amount is provided, will attempt to consume the periodic amount
--     as determined by energyConsumptionRate and scriptDelta
-- @returns false if there is insufficient energy stored (and does not remove energy)
function energy.consumeEnergy(amount)
  if amount == nil then
    amount = energy.consumptionRate * entity.dt()
  end
  --world.logInfo("consuming %f energy", amount)
  if amount <= energy.getEnergy() then
    energy.removeEnergy(amount)
    return true
  else
    return false
  end
end

-------------------------------------------------

--Used to determine if device can connect directly to other nodes
function energy.canConnect()
  return energy.allowConnection
end

-- returns true if object is a valid energy receiver
function energy.canReceiveEnergy()
  return energy.getUnusedCapacity() > 0
end

-- compute all the configuration stuff for the connection and projectile effect
function energy.makeConnectionConfig(entityId)
  local config = {}
  local srcPos = energy.getProjectileSourcePosition()
  local tarPos = world.entityPosition(entityId)
  tarPos = {tarPos[1] + 0.5, tarPos[2] + 0.5}
  config.aimVector = {tarPos[1] - srcPos[1], tarPos[2] - srcPos[2]}
  config.srcPos = srcPos
  config.tarPos = tarPos
  local distToTarget = world.magnitude(srcPos, tarPos)
  config.speed = (distToTarget / 1.2) -- denominator must == projectile's timeToLive
  config.blocked = world.lineCollision(srcPos, tarPos)
  return config
end

-- get the source position for the visual effect (replace with something better)
function energy.getProjectileSourcePosition()
  return {entity.position()[1] + 0.5, entity.position()[2] + 0.5}
end

-- connects to the specified entity id
function energy.connect(entityId)
  energy.connections[entityId] = energy.makeConnectionConfig(entityId)
  world.callScriptedEntity(entityId, "energy.onConnect", entity.id())
end

-- callback for energy.connect
function energy.onConnect(entityId)
  energy.connections[entityId] = energy.makeConnectionConfig(entityId)
end

-- disconnects from the specified entity id
function energy.disconnect(entityId)
  world.callScriptedEntity(entityId, "energy.onDisconnect", entity.id())
  energy.connections[entityId] = nil
end

-- callback for energy.disconnect
function energy.onDisconnect(entityId)
  energy.connections[entityId] = nil
end

-- Returns a list of connected entity id's
function energy.getConnections()
  return self.energyConnections
end

-- finds and connects to entities within <energy.linkRange> blocks
function energy.findConnections()
  energy.connections = {}

  --find nearby energy devices within LoS
  local entityIds = world.objectQuery(entity.position(), energy.linkRange, { 
      withoutEntityId = entity.id(),
      callScript = "energy.canConnect"
    })

  --world.logInfo("%s %d found %d entities within range:", entity.configParameter("objectName"), entity.id(), #entityIds)
  --world.logInfo(entityIds)

  --connect
  for i, entityId in ipairs(entityIds) do
    energy.connect(entityId)
  end
end

-- performs periodic LoS checks on connected entities
function energy.checkConnections()
  for entityId, pConfig in pairs(energy.connections) do
    energy.connections[entityId].blocked = world.lineCollision(pConfig.srcPos, pConfig.tarPos)
  end
end

-- returns the empty capacity (for consumers) or a Very Large Number TM for relays
function energy.getEnergyNeeds()
  if onEnergyNeedsCheck then
    return onEnergyNeedsCheck()
  elseif energy.relayMax then
    return energy.relayMax
  else
    return energy.getUnusedCapacity()
  end
end

-- comparator function for table sorting
function energy.compareNeeds(a, b)
  return a[2] < b[2]
end

-- pushes energy to connected entities. amount is divided between # of valid receivers
function energy.sendEnergy(amount, visited)
  --if entity.configParameter("objectName") ~= "relay" then
    --world.logInfo("%s %d sending %f energy...", entity.configParameter("objectName"), entity.id(), amount)
  --end

  energy.checkConnections()

  local energyNeeds = {}
  -- check energy needs for all connected entities
  for entityId, config in pairs(energy.connections) do
    if not visited[tostring(entityId)] and not config.blocked then 
      local thisEnergyNeed = world.callScriptedEntity(entityId, "energy.getEnergyNeeds")
      if thisEnergyNeed and thisEnergyNeed > 0 then
        energyNeeds[#energyNeeds + 1] = {entityId, thisEnergyNeed}
      end
    end
  end

  -- sort table of energy needs
  table.sort(energyNeeds, energy.compareNeeds)
  --world.logInfo(energyNeeds)

  -- process list and distribute remainder evenly at each step
  local totalEnergyToSend = amount
  local remainingEnergyToSend = totalEnergyToSend
  while #energyNeeds > 0 do
    if energyNeeds[1][2] > 0 then
      local sendAmt = remainingEnergyToSend / #energyNeeds
      local energyReturn = world.callScriptedEntity(energyNeeds[1][1], "energy.receiveEnergy", sendAmt, visited)
      if energyReturn then
        visited = energyReturn[2]
        remainingEnergyToSend = remainingEnergyToSend - energyReturn[1]
        if energyReturn[1] > 0 then
          energy.showTransferEffect(energyNeeds[1][1])
        end
      else
        --world.logInfo("%s %d failed to get energy return from %d", entity.configParameter("objectName"), entity.id(), entityId)
      end
    end
    table.remove(energyNeeds, 1)
  end

  --remove the total amount of energy sent
  local totalSent = totalEnergyToSend - remainingEnergyToSend
  --world.logInfo("%s %d successfully sent %d energy", entity.configParameter("objectName"), entity.id(), totalSent)

  return {totalSent, visited}
end

-- display a visual indicator of the energy transfer
function energy.showTransferEffect(entityId)
  local config = energy.connections[entityId]
  world.spawnProjectile("energytransfer", config.srcPos, entity.id(), config.aimVector, false, { speed=config.speed })
end