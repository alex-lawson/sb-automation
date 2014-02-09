function init(args)
  if not args then
    storage.zeroAngle = math.pi / 2
  end
end

function main()
  local timeOfDay = world.timeOfDay()
  local theta = storage.zeroAngle - (math.pi * 2 * timeOfDay)
  entity.rotateGroup("hand", theta)
  entity.setOutboundNodeLevel(0, (timeOfDay <= 0.5))
end