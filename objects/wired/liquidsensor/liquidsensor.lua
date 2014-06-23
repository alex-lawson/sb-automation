function init(virtual)
  if not virtual then
    datawire.init()
  end
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function getSample()
  return world.liquidAt(entity.position())
end

function main()
  datawire.update()

  local sample = getSample()
  if sample then
    datawire.sendData(sample[1], "number", 0)
    datawire.sendData(sample[2], "number", 1)
  else
    datawire.sendData(0, "number", 0)
    datawire.sendData(0, "number", 1)
  end

  if not sample then
    entity.setOutboundNodeLevel(0, false)
    entity.setOutboundNodeLevel(1, false)
    entity.setAnimationState("sensorState", "off")
  elseif sample[1] == 1 or sample[1] == 2 then
    entity.setOutboundNodeLevel(0, true)
    entity.setOutboundNodeLevel(1, true)
    entity.setAnimationState("sensorState", "water")
  elseif sample[1] == 4 then
    entity.setOutboundNodeLevel(0, true)
    entity.setOutboundNodeLevel(1, true)
    entity.setAnimationState("sensorState", "poison")
  elseif sample[1] == 3 or sample[1] == 5 then
    entity.setOutboundNodeLevel(0, true)
    entity.setOutboundNodeLevel(1, true)
    entity.setAnimationState("sensorState", "lava")
  else
    entity.setOutboundNodeLevel(0, true)
    entity.setOutboundNodeLevel(1, true)
    entity.setAnimationState("sensorState", "other")
  end
end