-- RED LIGHT DISTRICT
-- (for hooks... get it?)

--- hook to request a custom amount of energy (defaults to current unused capacity)
-- should return energyNeeds, with energyNeeds[tostring(entity.id())] equal to the requested energy
-- if energy requested > 0, then energyNeeds["total"] should be incremented appropriately
-- onEnergyNeedsCheck(energyNeeds)

--- return the amount of energy available to send (defaults to current energy)
-- onEnergySendCheck()

--- called when energy amount changes
-- onEnergyChange(newAmount)

--- called when energy is sent to the object
-- should return amount of energy accepted
-- onEnergyReceived(amount)

-------------------------------------------------------------------------------------

energy = {}

-- Initializes the energy module (MUST BE CALLED IN OBJECT init() FUNCTION)
function energy.init()
  --energy per unit of fuel for automated conversions
  energy.fuelEnergyConversion = 100

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

  --amount of energy consumed per second when active
  energy.consumptionRate = entity.configParameter("energyConsumptionRate")
  if energy.consumptionRate == nil then
    energy.consumptionRate = 0
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
  energy.connectCheckFreq = 0.5

  --timer variable that tracks cooldown until next connection LoS check
  energy.connectCheckTimer = energy.connectCheckFreq

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
        local energyToSend = math.min(energy.getAvailableEnergy(), energy.sendRate * energy.sendFreq)
        if energyToSend > 0 then
          energy.sendEnergy(energyToSend)
        end
        energy.sendTimer = energy.sendTimer + energy.sendFreq
      end
    end

    --periodic connection checks
    energy.connectCheckTimer = energy.connectCheckTimer - entity.dt()
    if energy.connectCheckTimer <= 0 then
      energy.checkConnections()
      energy.connectCheckTimer = energy.connectCheckTimer + energy.connectCheckFreq
    end
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
    if onEnergyChange then
      onEnergyChange(amount)
    end
  end
end

-- gets the available energy to send
function energy.getAvailableEnergy()
  if onEnergySendCheck then
    return onEnergySendCheck()
  else
    return energy.getEnergy()
  end
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
function energy.getEnergyNeeds(energyNeeds)
  if onEnergyNeedsCheck then
    return onEnergyNeedsCheck(energyNeeds)
  else
    energyNeeds["total"] = energyNeeds["total"] + energy.getUnusedCapacity()
    energyNeeds[tostring(entity.id())] = energy.getUnusedCapacity()
    return energyNeeds
  end
end

-- comparator function for table sorting
function energy.compareNeeds(a, b)
  if a == -1 then
    return false -- used to move relays to the end of the list
  else
    return a[2] < b[2]
  end
end

-- traverse the tree and build a list of receivers requesting energy
function energy.energyNeedsQuery(energyNeeds)
  -- check energy needs for all connected entities
  for entityId, config in pairs(energy.connections) do
    if not energyNeeds[tostring(entityId)] and not config.blocked then
      local prevTotal = energyNeeds["total"]
      energyNeeds = world.callScriptedEntity(entityId, "energy.getEnergyNeeds", energyNeeds)
      if energyNeeds[tostring(entityId)] == nil then
        world.logInfo("%s %d failed to add itself to energyNeeds table", world.callScriptedEntity(entityId, "entity.configParameter", "objectName"), entityId)
      end
      if energyNeeds["total"] > prevTotal then
        energy.showTransferEffect(entityId)
      end
    end
  end

  return energyNeeds
end

-- callback for receiving incoming energy pulses
function energy.receiveEnergy(amount)
  --world.logInfo("%s %d receiving %d energy...", entity.configParameter("objectName"), entity.id(), amount)
  if onEnergyReceived then
    return onEnergyReceived(amount)
  else
    return energy.addEnergy(amount)
  end
end

-- pushes energy to connected entities. amount is divided "fairly" between the valid receivers
function energy.sendEnergy(amount)
  --if entity.configParameter("objectName") ~= "relay" then
    --world.logInfo("%s %d sending %f energy...", entity.configParameter("objectName"), entity.id(), amount)
  --end

  -- get the network's energy needs
  local energyNeeds = {total=0}
  energyNeeds[tostring(entity.id())] = 0
  energyNeeds = energy.energyNeedsQuery(energyNeeds)
  energyNeeds["total"] = nil

  -- world.logInfo("initial energyNeeds")
  -- world.logInfo(energyNeeds)

  -- build and sort a table from least to most energy requested
  local sortedEnergyNeeds = {}
  for entityId, thisNeed in pairs(energyNeeds) do
    sortedEnergyNeeds[#sortedEnergyNeeds + 1] = {entityId, thisNeed}
  end
  table.sort(sortedEnergyNeeds, energy.compareNeeds)

  -- world.logInfo("sorted energyNeeds")
  -- world.logInfo(sortedEnergyNeeds)

  -- process list and distribute remainder evenly at each step
  local totalEnergyToSend = amount
  local remainingEnergyToSend = totalEnergyToSend
  while #sortedEnergyNeeds > 0 do
    if sortedEnergyNeeds[1][2] > 0 then
      local sendAmt = remainingEnergyToSend / #sortedEnergyNeeds
      local acceptedEnergy = world.callScriptedEntity(sortedEnergyNeeds[1][1], "energy.receiveEnergy", sendAmt)
      if acceptedEnergy > 0 then
        remainingEnergyToSend = remainingEnergyToSend - acceptedEnergy
      end
    end
    table.remove(sortedEnergyNeeds, 1)
  end

  --remove the total amount of energy sent
  local totalSent = totalEnergyToSend - remainingEnergyToSend
  energy.removeEnergy(totalSent)

  -- world.logInfo("%s %d successfully sent %d energy", entity.configParameter("objectName"), entity.id(), totalSent)
end

-- display a visual indicator of the energy transfer
function energy.showTransferEffect(entityId)
  local config = energy.connections[entityId]
  world.spawnProjectile("energytransfer", config.srcPos, entity.id(), config.aimVector, false, { speed=config.speed })
end