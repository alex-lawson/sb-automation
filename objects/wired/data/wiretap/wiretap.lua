function init(virtual)
  if not virtual then
    if storage.fingerpint == nil then
      -- First Initialization
      storage.fingerprint = entity.position()[1] .. "." ..entity.position()[2]
      storage.name = storage.fingerprint
      storage.logStack = {}
      storage.state = false
      entity.setAnimationState("tapState", "off")
    else
      -- Re-Initialization
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
  if storage.state then
    storage.state = false
    entity.setAnimationState("tapState", "off")
    showPopup()
  else
    storage.logStack = {}
    storage.state = true
    entity.setAnimationState("tapState", "on")
end

function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

function onValidDataReceived(data, dataType, nodeId)
  if storage.state then
    logInfo(dataType .. " : " .. data)
  end
  datawire.sendData(data, dataType, 0)
end

-- I'm using some dirty 'features' of # here
-- while the full, list will have keys 0-10,  # will still return 10
-- This is just a poor-man's stack, with a max of 10 entries.
function logInfo(logString)
  if #storage.logStack >= 10
    for i = 1, 10, 1 do
      storage.logStack[i - 1] = storage.logStack[i]
    end
    storage.logStack[10] = logString
  else
    storage.logStack[#storage.logStack + 1] = logString
  end
end

function showPopup()
  popupString = ""
  for i = 1, #storage.logStack, 1 do
    popupString = popupString .. "\n^green;" .. i .. ") ^white;" .. storage.logStack[i]
  end
  return { "ShowPopup", { message = popupString }
end

function output(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      entity.setAnimationState("tapState", "on")
      world.logInfo("Wiretap " .. storage.name .. "--- Enabling Logging ---")
    else
      entity.setAnimationState("tapState", "off")
      world.logInfo("Wiretap " .. storage.name .. "--- Disabling Logging ---")
    end
  end
end

function name(newName)
  storage.name = newName
end