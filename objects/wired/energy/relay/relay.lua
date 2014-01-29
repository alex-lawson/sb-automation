function init(virtual)
  if not virtual then
    energy.init()
  end
end

function die()
  energy.die()
end

function energy.isRelay()
  return true
end

function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = -1 -- -1 is just a hack to mark relays for ordering
  return energy.energyNeedsQuery(energyNeeds)
end

function main()
  energy.update()
end