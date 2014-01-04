function init(virtual)
  if not virtual then
    self.detectThresholdHigh = entity.configParameter("detectThresholdHigh")
    self.detectThresholdLow = entity.configParameter("detectThresholdLow")
    self.initialized = false
  end
end

function initInWorld()
  --world.logInfo(string.format("%s initializing in world", entity.configParameter("objectName")))
  queryNodes()
  self.initialized = true
end

function getSample()
  --to be implemented by sensor
  return false
end

function main(args)
  if not self.initialized then
    initInWorld()
  end

  local sample = getSample()
  sendData(sample, "all")

  if sample >= self.detectThresholdLow then
    entity.setOutboundNodeLevel(0, true)
    entity.setAnimationState("sensorState", "med")
  else
    entity.setOutboundNodeLevel(0, false)
    entity.setAnimationState("sensorState", "min")
  end

  if sample >= self.detectThresholdHigh then
    entity.setOutboundNodeLevel(1, true)
    entity.setAnimationState("sensorState", "max")
  else
    entity.setOutboundNodeLevel(1, false)
  end
end