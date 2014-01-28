function init(virtual)
  if not virtual then
    if storage.fingerpint == nil then
      -- First Initialization
      storage.fingerprint = entity.position()[1] .. "." ..entity.position()[2]
      storage.name = storage.fingerprint
      storage.logStack = {}
      entity.setAnimationState("tapState", "on")
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
  showPopup()
end

function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

function onValidDataReceived(data, dataType, nodeId)
  logInfo(dataType .. " : " .. data)
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

function name(newName)
  storage.name = newName
end