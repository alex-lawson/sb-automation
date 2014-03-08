function init(virtual)
  if not virtual then
    energy.init()

    self.particleCooldown = 0.2
    self.particleTimer = 0

    self.acceptCharge = entity.configParameter("acceptCharge") or true

    entity.setParticleEmitterActive("charging", false)
    updateAnimationState()
  end
end

function die()
  local position = entity.position()
  if energy.getEnergy() == 0 then
    world.spawnItem("battery", {position[1] + 0.5, position[2] + 1}, 1)
  elseif energy.getUnusedCapacity() == 0 then
    world.spawnItem("fullbattery", {position[1] + 0.5, position[2] + 1}, 1, {savedEnergy=energy.getEnergy()})
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
    position=entity.position(),
    acceptCharge=self.acceptCharge
  }
end

function onEnergyChange(newAmount)
  updateAnimationState()
end

function showChargeEffect()
  entity.setParticleEmitterActive("charging", true)
  self.particleTimer = self.particleCooldown
end

function updateAnimationState()
  local chargeAmt = energy.getEnergy() / energy.getCapacity()
  entity.scaleGroup("chargebar", {1, chargeAmt})
end

function main()
  if self.particleTimer > 0 then
    self.particleTimer = self.particleTimer - entity.dt()
    if self.particleTimer <= 0 then
      entity.setParticleEmitterActive("charging", false)
    end
  end

  energy.update()
end