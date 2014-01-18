function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()

    entity.setInteractive(true)
    updateAnimationState()
  end
end

function die()
  energy.die()
end

function onInteraction(args)
  storage.state = not storage.state
  updateAnimationState()
end

function updateAnimationState()
  if storage.state then
    entity.setAnimationState("generatorState", "on")
  else
    entity.setAnimationState("generatorState", "off")
  end
end

--never accept energy from elsewhere
function onEnergyNeedsCheck()
  return 0
end

function main()
  if storage.state then
    -- yes, it really is that easy. uses the energyGenerationRate config parameter
    energy.generateEnergy()
  end

  energy.update()
  datawire.update()
end