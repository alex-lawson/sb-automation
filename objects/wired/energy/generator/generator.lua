function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
  end
end

function die()
  energy.die()
end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = 0
  return energyNeeds
end

function main()
  -- yes, it really is that easy. uses the energyGenerationRate config parameter
  energy.generateEnergy()

  energy.update()
  datawire.update()
end