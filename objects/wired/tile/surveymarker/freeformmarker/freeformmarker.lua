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

    self.triggerDistance = entity.configParameter("triggerDistance")
    if self.triggerDistance == nil then
      self.triggerDistance = 5
    end

    self.smashed = false

    datawire.init()
  end
end

function onInteraction(args)
  startScan()
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function onTrigger()
  storage.timer = self.cooldown
  storage.triggered = true
end

function triggerConnectedMarkers(scriptName, scriptArgs)
  local entityIds = world.objectQuery(entity.position(), self.triggerDistance, {
          callScript = scriptName, callScriptArgs = scriptArgs
        })
  return entityIds
end

function startScan()
  local scanInProgress = storage.timer > 0
  if not scanInProgress and datawire.isOutboundNodeConnected(0) then
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
  --world.logInfo("received positions from %d markers: %s", #storage.scanTable, storage.scanTable)
  
  local transmitSuccess = datawire.sendData(storage.scanTable, "area", "all")
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
  datawire.update()
  
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