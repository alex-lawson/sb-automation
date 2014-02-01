--------------------- SAMPLE MINIMAL IMPLEMENTATION --------------------

--- Supported args for energy.init:
-- energyAllowConnection boolean can suppress an object's ability to connect (e.g. batteries)
-- energyCapacity number defines the size of the object's energy storage pool
-- energyGenerationRate number defines the rate (in energy/sec) for energy.generateEnergy()
-- energyConsumptionRate number defines the rate (in energy/sec) for energy.consumeEnergy()
-- energySendRate number defines the maximum energy transmission rate (in energy/sec)
-- energySendFreq number defines the interval (in sec) between energy transmission pulses
-- energyLinkRange number defines the maximum distance to connect to other devices/relays

function init(virtual)
  if not virtual then
    energy.init(args)
  end
end

function main()
  energy.update()
end

function die()
  energy.die()
end

--------------------- HOOKS --------------------

--- hook to request a custom amount of energy (defaults to current unused capacity)
-- should return energyNeeds, with energyNeeds[tostring(entity.id())] equal to the requested energy
-- if energy requested > 0, then energyNeeds["total"] should be incremented appropriately
function onEnergyNeedsCheck(energyNeeds) end

--- return the amount of energy available to send (defaults to current energy)
function onEnergySendCheck() end

--- called when energy amount changes
function onEnergyChange(newAmount) end

--- called when energy is sent from the object
-- @param totalSent total amount of energy sent
function onEnergySend(totalSent) end

--- called when energy is sent to the object
-- @returns amount of energy accepted
function onEnergyReceived(amount) end