
function validateData(data, dataType, nodeId)
  return dataType == "number"
end

function onValidDataReceived(data, dataType, nodeId)
  storage.charge = clamp(data * 10, -magnets.limit, magnets.limit)
  storage.magnetOnAnim = storage.charge == 0 and "neutral" or (storage.charge > 0 and "positive" or "negative")
  if storage.state then
    entity.setAnimationState("magnetState", storage.magnetOnAnim)
    updateMagnetData()
  end
end

function getEnergyUsage()
  return (math.abs(storage.charge) / 100) * 5 * entity.dt()
end