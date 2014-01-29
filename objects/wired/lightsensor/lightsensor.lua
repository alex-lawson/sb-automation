function getSample()
  local sample = world.lightLevel(entity.position())
  return math.floor(sample * 1000) * 0.1
end