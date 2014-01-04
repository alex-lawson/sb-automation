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

    self.initialized = false
  end
end

function initInWorld()
  --world.logInfo(string.format("%s initializing in world", entity.configParameter("objectName")))

  self.flipStr = ""
  if entity.direction() == -1 then
    self.flipStr = "flipped."
  end
  
  queryNodes()
  self.initialized = true
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

function validateData(data, nodeId)
  return type(data) == "number"
end

function onValidDataReceived(data, nodeId)
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

  sendData(storage.result, "all")
  updateAnimationState()
end

function updateAnimationState()
  entity.setAnimationState("operatorState", self.flipStr..storage.currentMode)
end

function main(args)
  if not self.initialized then
    initInWorld()
  end

  operate()
end