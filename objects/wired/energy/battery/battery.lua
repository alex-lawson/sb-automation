function init(virtual)
  if not virtual then
    energy.init()
    entity.setParticleEmitterActive("charging", false)
    updateAnimationState()
  end
end

function die()
  energy.die()
end

function isBattery()
  return true
end

function getBatteryStatus()
  return {
    id=entity.id(),
    capacity=energy.getCapacity(),
    energy=energy.getEnergy(),
    unusedCapacity=energy.getUnusedCapacity()
  }
end

function onEnergyChange(newAmount)
  updateAnimationState()
end

function updateAnimationState()
  local chargeAmt = energy.getEnergy() / energy.getCapacity()
  entity.scaleGroup("chargebar", {1, chargeAmt})
end

function main()
  energy.update()
end