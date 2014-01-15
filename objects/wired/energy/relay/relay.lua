function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
  end
end

function onEnergyChange(newAmount)
  world.logInfo("%s %d energy changed to %.2f", entity.configParameter("objectName"), entity.id(), newAmount)
  datawire.sendData(newAmount, "number", "all")
  updateAnimationState()
end

function updateAnimationState()
  if storage.curEnergy == 0 then
    entity.setAnimationState("relayState", "min")
  elseif storage.curEnergy == energy.getCapacity() then
    entity.setAnimationState("relayState", "max")
  else
    entity.setAnimationState("relayState", "med")
  end
end

function main()
  energy.update()
  datawire.update()
end