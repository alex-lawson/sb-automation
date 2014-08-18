function init(virtual)
  if not virtual then
    if not storage.data then
      storage.data = 0
    end

    if not storage.nodeStates then
      storage.nodeStates = {}
    end

    if entity.direction() == -1 then
      entity.setAnimationState("advancedrandomizerState", "flipped.off")
    end

    datawire.init()
  end
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function onInboundNodeChange(args)
  checkInboundNodes()
end

function checkInboundNodes()
  local newLevel = entity.getInboundNodeLevel(2) -- Check if we request a new random number
  if newLevel ~= storage.nodeStates[2] then
    storage.nodeStates[2] = newLevel
	if newLevel then
      randomize()
	end
  end 
end

function randomize()
  local rMin = storage.nodeStates[1]
  local rMax = storage.nodeStates[0]
  if not rMax then
	rMax = 1
  end
  if rMin <= rMax then
    -- storage.data = math.random(rMin, rMax)
    storage.data = math.random(rMin, rMax)
  end
end

function validateData(data, dataType, nodeId, sourceEntityId)
  return (nodeId ~= 2 and dataType == "number") or (nodeId == 2 and dataType == "boolean")
end

function onValidDataReceived(data, dataType, nodeId, sourceEntityId)
  if nodeId == 2 and data and storage.nodeStates[nodeId] ~= data then -- currently, no object send boolean data with starfoundry wire api, but I handle this for the future
    randomize()
  end
  storage.nodeStates[nodeId] = data
end

function output()
  datawire.sendData(storage.data, "number", 0)
end

function main()
  datawire.update()
  output()
end