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

    self.modes = { "add", "subtract", "multiply", "divide" }
    if storage.currentMode == nil then
      storage.currentMode = self.modes[1]
    end

    if not storage.result then
      storage.result = 0
    end

    self.flipStr = ""
    if entity.direction() == -1 then
      self.flipStr = "flipped."
    end

    datawire.init()
  end
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function onInteraction()
  cycleMode()
end

function cycleMode()
  for i, mode in ipairs(self.modes) do
    if mode == storage.currentMode then
      storage.currentMode = self.modes[(i % #self.modes) + 1]
      operate()
      return
    end
  end

  --previous mode invalid, default to mode 1
  storage.currentMode = self.modes[1]
  operate()
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

function operate()
  if storage.currentMode == "add" then
    storage.result = storage.data1 + storage.data2
  elseif storage.currentMode == "subtract" then
    storage.result = storage.data1 - storage.data2
  elseif storage.currentMode == "multiply" then
    storage.result = storage.data1 * storage.data2
  elseif storage.currentMode == "divide" then
    storage.result = storage.data1 / storage.data2
  end

  datawire.sendData(storage.result, "number", "all")
  updateAnimationState()
end

function updateAnimationState()
  entity.setAnimationState("operatorState", self.flipStr..storage.currentMode)
end

function main()
  datawire.update()
  operate()
end