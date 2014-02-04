
function validateData(data, dataType, nodeId, sourceEntityId)
  return dataType == "number"
end

function onValidDataReceived(data, dataType, nodeId, sourceEntityId)
  storage.charge = clamp(data * 10, -magnets.limit, magnets.limit)
  storage.magnetOnAnim = storage.charge == 0 and "positiveOn" or (storage.charge > 0 and "positiveOn" or "negativeOn")
  storage.magnetOffAnim = storage.charge == 0 and "positiveOff" or (storage.charge > 0 and "positiveOff" or "negativeOff")
  if storage.state then
    entity.setAnimationState("magnetState", storage.magnetOnAnim)
    updateMagnetData()
  else
    entity.setAnimationState("magnetState", storage.magnetOffAnim)
  end
end

function getEnergyUsage()
  return (math.abs(storage.charge) / 100) * 5 * entity.dt()
end

function energy.getProjectileSourcePosition()
  return {entity.position()[1] + 1, entity.position()[2] + 1}
end