function init(virtual)
  if not virtual then
    energy.init()

    entity.setParticleEmitterActive("charging", false)
    updateAnimationState()
  end
end

function die()
  local position = entity.position()
  if energy.getEnergy() == 0 then
    world.spawnItem("battery", {position[1] + 0.5, position[2] + 1}, 1)
  else
    world.spawnItem("battery", {position[1] + 0.5, position[2] + 1}, 1, {savedEnergy=energy.getEnergy()})
  end

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
    unusedCapacity=energy.getUnusedCapacity(),
    position=entity.position()
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