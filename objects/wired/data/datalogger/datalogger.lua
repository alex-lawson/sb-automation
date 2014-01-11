function init(virtual)
  if not virtual then
    if storage.enabled == nil then
      storage.enabled = true
    end

    entity.setAnimationState("loggerState", "disabled")
    datawire.init()
  end
end

function onInteraction(args)
  storage.enabled =  not storage.enabled
  if storage.enabled then
    entity.setAnimationState("loggerState", "enabled")
    logInfo("DataLogger: Enabling Logging")
  else
    entity.setAnimationState("loggerState", "disabled")
    logInfo("DataLogger: Disabling Logging")
  end
end

function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

function onValidDataReceived(data, dataType, nodeId)
  if storage.enabled then
    logInfo("DataLogger: " .. dataType .. ": " .. data)
  end
end

function logInfo(stringToLog)
  world.logInfo(stringToLog)
end

function main()
  datawire.update()
end