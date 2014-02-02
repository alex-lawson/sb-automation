function init(virtual)
  -- self.displayCharSet = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-"}
  -- self.linkStates = {"none", "left", "right", "both"}

  if not virtual then
    self.dataFormat = entity.configParameter("dataFormat")
    if self.dataFormat == nil then
      self.dataFormat = "%d"
    end

    self.displaySize = entity.configParameter("displaySize")
    if self.displaySize == nil then
      --maybe no point to setting a default since this will totally break if it's wrong
      self.displaySize = 1
    end

    datawire.init()
  end
end

function initAfterLoading()
  findAdjacentSegments()
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function die()
  if storage.connectedRight then
    world.callScriptedEntity(storage.connectedRight, "disconnectLeft")
  end

  if storage.connectedLeft then
    world.callScriptedEntity(storage.connectedLeft, "disconnectRight")
  end
end

function disconnectLeft()
  storage.connectedLeft = nil
  updateLinkAnimationState()
end

function disconnectRight()
  storage.connectedRight = nil
  updateLinkAnimationState()
end

function findAdjacentSegments()
  pingLeft()
  pingRight()

  updateLinkAnimationState()

  if storage.data == nil then
    if storage.connectedLeft then
      storage.data = world.callScriptedEntity(storage.connectedLeft, "getData", {})
    end
  end
end

function pingRight()
  local entityIds = world.entityQuery({entity.position()[1] + self.displaySize, entity.position()[2]}, 1,
     { callScript = "isLinkedDisplayToRight", callScriptArgs = { {math.floor(entity.position()[1] + self.displaySize), math.floor(entity.position()[2])}, self.displaySize, entity.id() }, withoutEntityId = entity.id()})

  if #entityIds == 1 then
    storage.connectedRight = entityIds[1]
  else
    storage.connectedRight = false
  end
end

function pingLeft()
  local entityIds = world.entityQuery({entity.position()[1] - self.displaySize, entity.position()[2]}, 1,
      { callScript = "isLinkedDisplayToLeft", callScriptArgs = { {math.floor(entity.position()[1] - self.displaySize), math.floor(entity.position()[2])}, self.displaySize, entity.id() }, withoutEntityId = entity.id()})

  if #entityIds == 1 then
    storage.connectedLeft = entityIds[1]
  else
    storage.connectedLeft = false
  end
end

function isLinkedDisplayToRight(pos, displaySize, entityId)
  if pos[1] == math.floor(entity.position()[1]) and pos[2] == math.floor(entity.position()[2]) and displaySize == self.displaySize then
    storage.connectedLeft = entityId
    updateLinkAnimationState()
    return true
  else
    return false
  end
end

function isLinkedDisplayToLeft(pos, displaySize, entityId)
  if pos[1] == math.floor(entity.position()[1]) and pos[2] == math.floor(entity.position()[2]) and displaySize == self.displaySize then
    storage.connectedRight = entityId
    updateLinkAnimationState()
    return true
  else
    return false
  end
end

function validateData(data, dataType, nodeId, sourceEntityId)
  return dataType == "number"
end

function onValidDataReceived(data, dataType, nodeId, sourceEntityId)
  setData(data)
end

function getData()
  return storage.data
end

function setData(data)
  storage.data = data

  if storage.connectedRight then
    world.callScriptedEntity(storage.connectedRight, "setData", data)
  end

  return true
end

function takeOneAndPassToYourLeft(args)
  --abort if not initialized
  if not datawire.initialized then return end

  storage.data = args.data

  --take one
  local newDisplayData
  if #args.dataString >= 1 then
    newDisplayData = args.dataString:sub(#args.dataString, #args.dataString)
  end
  updateDisplay(newDisplayData)

  --pass to your left
  if storage.connectedLeft then
    world.callScriptedEntity(storage.connectedLeft, "takeOneAndPassToYourLeft", {data = args.data, dataString = args.dataString:sub(1, #args.dataString - 1)})
  end
end

function updateLinkAnimationState()
  if storage.connectedRight and storage.connectedLeft then
    entity.setAnimationState("linkState", "both")
  elseif not storage.connectedRight and storage.connectedLeft then
    if entity.direction() == 1 then
      entity.setAnimationState("linkState", "left")
    else
      entity.setAnimationState("linkState", "right")
    end
  elseif storage.connectedRight and not storage.connectedLeft then
    if entity.direction() == 1 then
      entity.setAnimationState("linkState", "right")
    else
      entity.setAnimationState("linkState", "left")
    end
  else
    entity.setAnimationState("linkState", "none")
  end
end

function updateDisplay(newDisplayData)
  if newDisplayData and newDisplayData ~= "" then
    if entity.direction() == 1 then
      entity.setAnimationState("dataState", newDisplayData)
    else
      entity.setAnimationState("dataState", "flipped."..newDisplayData)
    end
  else
    entity.setAnimationState("dataState", "off")
  end

  storage.currentDisplayData = newDisplayData
end

function main()
  datawire.update()

  if storage.data then
    if not storage.connectedRight then
      dataStr = string.format(self.dataFormat, storage.data)
      takeOneAndPassToYourLeft({data = storage.data, dataString = dataStr:sub(1, #dataStr)})
    end
  end
end