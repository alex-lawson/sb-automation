function init(virtual)
  if not virtual then
    energy.init()
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

function main()
  energy.update()
end