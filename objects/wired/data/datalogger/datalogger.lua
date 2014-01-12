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
  end
end

function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

function onValidDataReceived(data, dataType, nodeId)
  if storage.state then
    logInfo("DataLogger: " .. dataType .. ": " .. data)
  end
end

function logInfo(stringToLog)
  world.logInfo(stringToLog)
end

function main()
  datawire.update()
end