function getSample()
  local sample = world.windLevel(entity.position())
  --world.logInfo(string.format("Wind reading: %f", sample))
  return math.floor(math.abs(sample))
end