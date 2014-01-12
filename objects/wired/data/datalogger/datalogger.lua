function init(virtual)
  if not virtual then
    if storage.state == nil then
      storage.state = false
    end

    output(storage.state)
    datawire.init()
  end
end

function onInteraction(args)
<<<<<<< HEAD
  storage.state =  not storage.state
  output(storage.state)
end

function output(state)
  if state ~= storage.state then
    if state then
        entity.setAnimationState("alarmState", "on")
        logInfo("DataLogger: --- Enabling Logging ---")
      else
        entity.setAnimationState("alarmState", "off")
        logInfo("DataLogger: --- Disabling Logging ---")
    end
=======
  storage.enabled =  not storage.enabled
  if storage.enabled then
    entity.setAnimationState("loggerState", "enabled")
    logInfo("DataLogger: Enabling Logging")
  else
    entity.setAnimationState("loggerState", "disabled")
    logInfo("DataLogger: Disabling Logging")
<<<<<<< HEAD
>>>>>>> ee3db06bdfcfdfcc8737abc805b55dcf630d8511
=======
>>>>>>> ee3db06bdfcfdfcc8737abc805b55dcf630d8511
  end
end

function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

function onValidDataReceived(data, dataType, nodeId)
<<<<<<< HEAD
  if storage.state then
=======
  if storage.enabled then
<<<<<<< HEAD
>>>>>>> ee3db06bdfcfdfcc8737abc805b55dcf630d8511
=======
>>>>>>> ee3db06bdfcfdfcc8737abc805b55dcf630d8511
    logInfo("DataLogger: " .. dataType .. ": " .. data)
  end
end

function logInfo(stringToLog)
  world.logInfo(stringToLog)
end

function main()
  datawire.update()
end