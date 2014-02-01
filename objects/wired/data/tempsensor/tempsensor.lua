function getSample()
  local sample = world.temperature(entity.position())
  -- world.logInfo(string.format("Temperature reading: %f", sample))
  return math.floor(sample)
end