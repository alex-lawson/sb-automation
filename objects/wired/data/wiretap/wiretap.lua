function init(virtual)
  if not virtual then
    if storage.fingerpint == nil then
      -- First Initialization
      storage.fingerprint = entity.position()[1] .. "." ..entity.position()[2]
      storage.name = storage.fingerprint
      output(false)
    else
      -- Re-Initialization
      output(storage.state)
    end

    -- Every Initialization
    datawire.init()
    entity.setInteractive(true)
  end
end

function main(args)
  datawire.update()
end

function onInteraction(args)
  output(not storage.state)
end

function output(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      entity.setAnimationState("tapState", "on")
      logInfo("--- Enabling Logging ---")
    else
      entity.setAnimationState("tapState", "off")
      logInfo("--- Disabling Logging ---")
    end
  end
end

function logInfo(stringToLog)
  world.logInfo("Wiretap " .. storage.name .. ": " .. stringToLog)
end

function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

function onValidDataReceived(data, dataType, nodeId)
  if storage.state then
    logInfo(dataType .. ": " .. data)
  end
  datawire.sendData(data, dataType, 0)
end

function name(newName)
  storage.name = newName
end