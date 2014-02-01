function init(virtual)
  if not virtual then
    if not storage.data then
      storage.data = 0
    end

    if not storage.nodeStates then
      storage.nodeStates = {}
    end

    if entity.direction() == -1 then
      entity.setAnimationState("counterState", "flipped.off")
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
  local nodeIndex = 0
  while nodeIndex < entity.inboundNodeCount() do
    local newLevel = entity.getInboundNodeLevel(nodeIndex)
    if newLevel ~= storage.nodeStates[nodeIndex] then
      storage.nodeStates[nodeIndex] = newLevel
      if newLevel then
        if nodeIndex == 0 then
          increment()
        elseif nodeIndex == 1 then
          decrement()
        elseif nodeIndex == 2 then
          reset()
        end
      end
    end 
    nodeIndex = nodeIndex + 1
  end
end

function increment()
  storage.data = storage.data + 1
end

function decrement()
  storage.data = storage.data - 1
end

function reset()
  storage.data = 0
end

function validateData(data, dataType, nodeId, sourceEntityId)
  return dataType == "number"
end

function onValidDataReceived(data, dataType, nodeId, sourceEntityId)
  storage.data = data
end

function output()
  datawire.sendData(storage.data, "number", 0)
end

function main()
  datawire.update()
  output()
end