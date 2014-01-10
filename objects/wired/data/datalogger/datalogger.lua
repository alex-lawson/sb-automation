function init(virtual)
  if not virtual then
    if storage.enabled == nil then
      storage.enabled = true
    end

    -- what do?
    self.flipStr = ""
    if entity.direction() == -1 then
      self.flipStr = "flipped."
    end

    updateAnimationState()

    datawire.init()
  end
end

-- Done
function onInteraction(args)
  storage.enabled ==  not storage.enabled
end

function onInboundNodeChange(args)
  
  output()
  updateAnimationState()
end


function updateAnimationState()
  if storage.enabled then
    -- set the animation state to glowing
  else
    -- set the animation state to dark
  end
end

-- Done
function validateData(data, dataType, nodeId)
  --only receive data on node 0
  return nodeId == 0
end

-- Done
function onValidDataReceived(data, dataType, nodeId)
  if storage.enabled then
    logInfo(data .. dataType)
  end
end

-- Done
function logInfo(stringToLog)
  world.logInfo(stringToLog)
end

-- Done
function main()
  datawire.update()
end