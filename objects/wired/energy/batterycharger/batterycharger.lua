function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()

    entity.setInteractive(true)

    --table of batteries in the charger
    self.batteries = {}

    -- will be updated when batteries are checked
    self.batteryUnusedCapacity = 0

    --maximum energy to request for batteries from a single pulse
    self.batteryChargeAmount = 5

    --flag to allow/disallow energy output
    if storage.discharging == nil then
      storage.discharging = true
    end

    --frequency (in seconds) to check for batteries present
    self.batteryCheckFreq = 1
    self.batteryCheckTimer = self.batteryCheckFreq

    --store this so that we don't have to compute it repeatedly
    local pos = entity.position()
    self.batteryCheckArea = {
      {pos[1], pos[2] - 1},
      1.5
    }

    updateAnimationState()
  end
end

-- this hook is called by the first datawire.update()
function initAfterLoading()
  checkBatteries()
end

function die()
  energy.die()
end

function onInteraction(args)
  storage.discharging = not storage.discharging
  updateAnimationState()
end

function battCompare(a, b)
  return a.position[1] < b.position[1]
end

function checkBatteries()
  self.batteries = {}
  self.batteryUnusedCapacity = 0

  local entityIds = world.objectQuery(self.batteryCheckArea[1], self.batteryCheckArea[2], { withoutEntityId = entity.id(), callScript = "isBattery" })
  for i, entityId in ipairs(entityIds) do
    local batteryStatus = world.callScriptedEntity(entityId, "getBatteryStatus")
    self.batteries[#self.batteries + 1] = batteryStatus
    self.batteryUnusedCapacity = self.batteryUnusedCapacity + batteryStatus.unusedCapacity
  end

  --world.logInfo("found %d batteries with %f total unused capacity", #entityIds, self.batteryUnusedCapacity)
  --world.logInfo(self.batteries)

  --order batteries left -> right
  table.sort(self.batteries, battCompare)

  updateAnimationState()
  self.batteryCheckTimer = self.batteryCheckFreq --reset this here so we don't perform periodic checks right after a pulse

  --world.logInfo(self.batteries)
end

function updateAnimationState()
  if not self.batteries then
    entity.setAnimationState("chargeState", "error")
  elseif #self.batteries == 0 then
    entity.setAnimationState("chargeState", "off")
  elseif storage.discharging then
    entity.setAnimationState("chargeState", "on")
  else
    entity.setAnimationState("chargeState", "charge")
  end
end

function onEnergyNeedsCheck(energyNeeds)
  local thisNeed = math.min(self.batteryChargeAmount, self.batteryUnusedCapacity)
  energyNeeds["total"] = energyNeeds["total"] + thisNeed
  energyNeeds[tostring(entity.id())] = thisNeed
  return energyNeeds
end

--only send energy while discharging (even if it's in the pool... could try revamping this later)
function onEnergySendCheck()
  if storage.discharging then
    return energy.getEnergy()
  else
    return 0
  end
end

function onEnergyReceived(amount)
  checkBatteries()
  local acceptedEnergy = chargeBatteries(amount)

  return acceptedEnergy
end

function chargeBatteries(amount)
  local amountRemaining = amount
  for i, bStatus in ipairs(self.batteries) do
    local amountAccepted = world.callScriptedEntity(bStatus.id, "energy.addEnergy", amountRemaining)
    if amountAccepted then --this check probably isn't necessary, but just in case a battery explodes or somethin
      if amountAccepted > 0 then
        world.callScriptedEntity(bStatus.id, "entity.burstParticleEmitter", "charging")
      end
      amountRemaining = amountRemaining - amountAccepted
    end
  end

  return amount - amountRemaining
end

--fills the charger's energy pool from the contained batteries
function dischargeBatteries()
  local sourceBatt = #self.batteries
  local energyNeeded = energy.getUnusedCapacity()
  --world.logInfo("discharging batteries starting with %f energy", energy.getEnergy())
  while sourceBatt >= 1 and energyNeeded > 0 do
    
    local discharge = world.callScriptedEntity(self.batteries[sourceBatt].id, "energy.removeEnergy", energyNeeded)
    if discharge and discharge > 0 then
      energy.addEnergy(discharge)
      energyNeeded = energyNeeded - discharge
    end
    sourceBatt = sourceBatt - 1
  end
  --world.logInfo("ended up with %f energy", energy.getEnergy())
end

function main()
  self.batteryCheckTimer = self.batteryCheckTimer - entity.dt()
  if self.batteryCheckTimer <= 0 then
    checkBatteries()
  end

  if storage.discharging then
    dischargeBatteries()
  end

  datawire.update()
  energy.update()
end