function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
    pipes.init({itemPipe})
    --TODO: set up storage api

    entity.setInteractive(true)

    self.turbineAngle = 0
    self.turbineSpeed = 0.2
  end
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function die()
  energy.die()
  --TODO: cleanup storage api
end

function onInteraction(args)
  storage.state = not storage.state
end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = 0
  return energyNeeds
end

function rotateTurbine()
  self.turbineAngle = (self.turbineAngle + self.turbineSpeed) % (2 * math.pi)
  entity.rotateGroup("turbine", self.turbineAngle)
end

function main()
  if storage.state then
    -- yes, it really is that easy. uses the energyGenerationRate config parameter
    energy.generateEnergy()
    rotateTurbine()
  end
  energy.update()
  datawire.update()
  pipes.update(entity.dt())
end