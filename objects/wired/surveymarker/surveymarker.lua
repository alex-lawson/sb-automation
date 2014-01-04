function init(virtual)
  if not virtual then
    entity.setInteractive(true)

    if storage.timer == nil then
      storage.timer = 0
    end

    self.cooldown = 5

    if storage.triggered == nil then
      storage.triggered = false
    end

    if not storage.triggered then
      storage.isOrigin = false
    end

    self.markerType = entity.configParameter("markerType")
    if self.markerType == nil then
      self.markerType = "freeform"
    end

    self.smashed = false

    self.initialized = false
  end
end

function initInWorld()
  --world.logInfo(string.format("%s initializing in world", entity.configParameter("objectName")))

  queryNodes()
  self.initialized = true
end

function onInteraction(args)
  startScan()
end

function onTrigger()
  storage.timer = self.cooldown
  storage.triggered = true
end

function triggerConnectedMarkers(scriptName, scriptArgs)
  local entityIds = {}

  if self.markerType == "freeform" then
    local triggerDistance = 2
    entityIds = world.objectQuery(entity.position(), triggerDistance, {
          callScript = scriptName, callScriptArgs = scriptArgs
        })
  elseif self.markerType == "rect" then
    --TODO
  end

  return entityIds
end

function startScan()
  local scanInProgress = storage.timer > 0
  if not scanInProgress then
    onTrigger()
    storage.isOrigin = true

    storage.scanTable = {}
    addScanCoords(entity.position())

    triggerConnectedMarkers("receiveSurveyTrigger", { self.markerType, entity.id() })
  end
end

function addScanCoords(pos)
  storage.scanTable[#storage.scanTable + 1] = pos
end

function receiveSurveyTrigger(markerType, originId)
  if not storage.triggered and markerType == self.markerType then
    onTrigger()
    sendSurveyResult(originId)
    local entityIds = triggerConnectedMarkers("receiveSurveyTrigger", { self.markerType, originId })
    --world.logInfo(entityIds)

    return true
  end

  return false
end

function sendSurveyResult(originId)
  world.callScriptedEntity(originId, "receiveSurveyResult", entity.position())
end

function receiveSurveyResult(pos)
  addScanCoords(pos)
end

function finalizeSurvey()
  world.logInfo(string.format("received positions from %d markers", #storage.scanTable))
  world.logInfo(storage.scanTable)
  
  local transmitSuccess = sendData(storage.scanTable, "all")
  if transmitSuccess then
    smashConnectedMarkers(entity.id())
  else
    storage.triggered = false
    storage.isOrigin = false
  end
end

function smashConnectedMarkers(originId)
  if not self.smashed then
    world.spawnItem(entity.configParameter("objectName"), world.entityPosition(originId), 1)
    entity.smash()
    self.smashed = true
    triggerConnectedMarkers("smashConnectedMarkers", { originId })
  end
end

function main()
  if not self.initialized then
    initInWorld()
  end

  if storage.timer > 0 then
    storage.timer = storage.timer - 1

    if storage.timer <= 0 then
      if storage.isOrigin then
        finalizeSurvey()
      else
        storage.triggered = false
      end
    end
  end
end