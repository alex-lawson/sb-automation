function init(virtual)
  if not virtual then
    entity.setInteractive(true)

    if not storage.data1 then
      storage.data1 = 0
    end

    if not storage.data2 then
      storage.data2 = 0
    end

    if not storage.nodeStates then
      storage.nodeStates = {}
    end

    if storage.state == nil then
      storage.state = false
    end

    self.modes = { "gt", "lt", "eq" }
    if storage.currentMode == nil then
      storage.currentMode = self.modes[1]
    end

    self.flipStr = ""
    if entity.direction() == -1 then
      self.flipStr = "flipped."
    end

    updateAnimationState()

    datawire.init()
  end
end

function onInteraction()
  cycleMode()
end

function cycleMode()
  for i, mode in ipairs(self.modes) do
    if mode == storage.currentMode then
      storage.currentMode = self.modes[(i % #self.modes) + 1]
      compare()
      return
    end
  end

  --previous mode invalid, default to mode 1
  storage.currentMode = self.modes[1]
  compare()
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function validateData(data, dataType, nodeId, sourceEntityId)
  return dataType == "number"
end

function onValidDataReceived(data, dataType, nodeId, sourceEntityId)
  if nodeId == 0 then
    storage.data1 = data
  else
    storage.data2 = data
  end
end

function compare()
  if entity.isInboundNodeConnected(0) and entity.isInboundNodeConnected(1) then
    if storage.currentMode == "gt" then
      storage.state = storage.data1 > storage.data2
    elseif storage.currentMode == "lt" then
      storage.state = storage.data1 < storage.data2
    elseif storage.currentMode == "eq" then
      storage.state = storage.data1 == storage.data2
    end

    entity.setOutboundNodeLevel(0, storage.state)
    
    if (storage.state) then
      datawire.sendData(storage.data1, "number", "all")
    elseif storage.currentMode == "eq" then
      datawire.sendData(0, "number", "all")
    else
      datawire.sendData(storage.data2, "number", "all")
    end
  end

  updateAnimationState()
end

function updateAnimationState()
  entity.setAnimationState("modeState", self.flipStr..storage.currentMode)

  if storage.state then
    entity.setAnimationState("comparatorState", self.flipStr.."on")
  else
    entity.setAnimationState("comparatorState", self.flipStr.."off")
  end
end

function main()
  datawire.update()
  compare()
end