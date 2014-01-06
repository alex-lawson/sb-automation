function getSample()
  return world.liquidAt(entity.position())
end

function main()
  datawire.update()

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
end