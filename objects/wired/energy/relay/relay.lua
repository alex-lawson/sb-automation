function init(virtual)
  if not virtual then
    energy.init()
  end
end

function die()
  energy.die()
end

function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = 0
  return energy.energyNeedsQuery(energyNeeds)
end

function main()
  energy.update()
end