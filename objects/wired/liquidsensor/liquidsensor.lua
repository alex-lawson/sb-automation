function init(virtual)
  if not virtual then
    self.initialized = false
  end
end

function initInWorld()
  --world.logInfo(string.format("%s initializing in world", entity.configParameter("objectName")))
  datawire.init()
  self.initialized = true
end

function getSample()
  local sample = world.liquidAt(entity.position())

  return sample
end

function main(args)
  if self.initialized then
    local sample = getSample()
    if sample then
      datawire.sendData(sample[1], "number", "all")
    else
      datawire.sendData(0, "number", "all")
    end

    if not sample then
      entity.setOutboundNodeLevel(0, false)
      entity.setAnimationState("sensorState", "off")
    elseif sample[1] == 1 or sample[1] == 2 then
      entity.setOutboundNodeLevel(0, true)
      entity.setAnimationState("sensorState", "water")
    elseif sample[1] == 4 then
      entity.setOutboundNodeLevel(0, true)
      entity.setAnimationState("sensorState", "poison")
    elseif sample[1] == 3 or sample[1] == 5 then
      entity.setOutboundNodeLevel(0, true)
      entity.setAnimationState("sensorState", "lava")
    else
      entity.setOutboundNodeLevel(0, true)
      entity.setAnimationState("sensorState", "other")
    end
  else
    initInWorld()
  end
end