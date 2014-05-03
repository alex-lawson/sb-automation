datawire = datawire or {}

function inspectInternal(key, value, prefix) 
  local out = prefix and prefix..".%s" or "%s" 
  if type(value) == "table" then 
    for k, v in pairs(value) do
      inspectInternal(k, v, prefix.."."..key)
    end
  else 
    out = type(value) == "function" and out.."()" or out.." = %s" 
    world.logInfo(out:format(key, tostring(value))) 
  end 
end

function inspect(table, prefix)
  world.logInfo("inspecting %@:", prefix)
  local name = prefix
  for k, v in pairs(table) do
    inspectInternal(k, v, prefix);
  end
end 

function print(...)
  local arg={...}

  local printResult = ""
  for i,v in ipairs(arg) do
    printResult = printResult .. tostring(v)
  end

  world.logInfo("%s", printResult)
end

function printf(frmt, ...)
  world.logInfo(frmt, ...)
end

function getLocationName()
  if ((world.info() ~= nil) and (world.info().name ~= "")) then
    return world.info().name
  else
    return "Ship"
  end
 
end

---------------------------------------------------------------------

--- this should be called by the implementing object in its own init()
function datawire.init()
  datawire.inboundConnections = {}
  datawire.outboundConnections = {}

  datawire.initialized = false
  end

function datawire.globalInit()

end

--- this should be called by the implementing object in its own onNodeConnectionChange()
function datawire.onNodeConnectionChange()
  datawire.createConnectionTable()
end



function datawire.test()
  
  local location = getLocationName()
  
  world.logInfo("%s: %s (%d) has index %d", location, entity.configParameter("objectName"), entity.id(), math.starfoundry.frameUpdateSim.objects[entity.id()])
end


--- any datawire operations that need to be run when main() is first called
function datawire.update()
  if datawire.initialized then
    -- nothing for now
  else
    datawire.initAfterLoading()
    if initAfterLoading then initAfterLoading() end
  end
  
  local id = entity.id()
  local index
  if (not math.starfoundry.frameUpdateSim.objects[id]) then
    local newIndex = math.starfoundry.frameUpdateSim.objects.last + 1
    math.starfoundry.frameUpdateSim.objects.last = newIndex
    math.starfoundry.frameUpdateSim.objects[id] = newIndex
   
    --printf("mark: object %s (%d) registred at index %d",
    --  entity.configParameter("objectName"), entity.id(),
    --  math.starfoundry.frameUpdateSim.objects.last)
    index = newIndex
  else
    index = math.starfoundry.frameUpdateSim.objects[id]
  end
 
  if (index <= math.starfoundry.frameUpdateSim.objects.lastUpdated) then
    printf("%s: mark: new frame", getLocationName())
    datawire.updateReceivers()
  end
 
  math.starfoundry.frameUpdateSim.objects.lastUpdated = index
end

-------------------------------------------

--- this will be called internally, to build connection tables once the world has fully loaded
function datawire.initAfterLoading()
  --datawire.globalInit()
  storage.wiredata = {};
  storage.wiredata.nextState = {};
  datawire.createConnectionTable()
  datawire.initialized = true
  
  datawire.globalInit()
end

function datawire.globalInit()
  if (math.starfoundry and
      math.starfoundry.datawire and 
      math.starfoundry.datawire.initialized) then -- I hate chain nil tests
    return
  end
    
  math.starfoundry = math.starfoundry or {}
  math.starfoundry.frameUpdateSim = math.starfoundry.frameUpdateSim or {}
  math.starfoundry.frameUpdateSim.objects = math.starfoundry.frameUpdateSim.objects or {}
  
  math.starfoundry.frameUpdateSim.objects.last = -1
  math.starfoundry.frameUpdateSim.objects.lastUpdated = math.huge
  
  math.starfoundry.datawire = {}
  math.starfoundry.datawire.initialized = true
  math.starfoundry.datawire.receivers =  {}
end

--- Creates connection tables for inbound and outbound nodes
function datawire.createConnectionTable()
  datawire.outboundConnections = {}
  local i = 0
  while i < entity.outboundNodeCount() do
    local connInfo = entity.getOutboundNodeIds(i)
    local entityIds = {}
    for k, v in pairs(connInfo) do
      entityIds[#entityIds + 1] = v[1]
    end
    datawire.outboundConnections[i] = entityIds
    i = i + 1
  end

  datawire.inboundConnections = {}
  local connInfos
  i = 0
  while i < entity.inboundNodeCount() do
    connInfos = entity.getInboundNodeIds(i)
    for j, connInfo in ipairs(connInfos) do
      datawire.inboundConnections[connInfo[1]] = i
    end
    i = i + 1
  end

  --world.logInfo(string.format("%s (id %d) created connection tables for %d outbound and %d inbound nodes", entity.configParameter("objectName"), entity.id(), entity.outboundNodeCount(), entity.inboundNodeCount()))
  --world.logInfo("outbound: %s", datawire.outboundConnections)
  --world.logInfo("inbound: %s", datawire.inboundConnections)
end

--- determine whether there is a valid recipient on the specified outbound node
-- @param nodeId the node to be queried
-- @returns true if there is a recipient connected to the node
function datawire.isOutboundNodeConnected(nodeId)
  return datawire.outboundConnections and datawire.outboundConnections[nodeId] and #datawire.outboundConnections[nodeId] > 0
end

--- Sends data to another datawire object
-- @param data the data to be sent
-- @param dataType the data type to be sent ("boolean", "number", "string", "area", etc.)
-- @param nodeId the outbound node id to send to, or "all" for all outbound nodes
-- @returns true if at least one object successfully received the data
function datawire.sendData(data, dataType, nodeId)
  -- don't transmit if connection tables haven't been built
  if not datawire.initialized then
    return false
  end

  local transmitSuccess = false

  if nodeId == "all" then
    for k, v in pairs(datawire.outboundConnections) do
      transmitSuccess = datawire.sendData(data, dataType, k) or transmitSuccess
    end
  else
    if datawire.outboundConnections[nodeId] and #datawire.outboundConnections[nodeId] > 0 then 
      for i, entityId in ipairs(datawire.outboundConnections[nodeId]) do
        if entityId ~= entity.id() then
          transmitSuccess = world.callScriptedEntity(entityId, "datawire.receiveData", { data, dataType, entity.id() }) or transmitSuccess
        end
      end
    end
  end

  -- if not transmitSuccess then
  --   world.logInfo(string.format("DataWire: %s (id %d) FAILED to send data of type %s", entity.configParameter("objectName"), entity.id(), dataType))
  --   world.logInfo(data)
  -- end

  return transmitSuccess
end

function datawire.updateReceivers()
  local toRemove = {}
  
  for receiverid, dummy in pairs(math.starfoundry.datawire.receivers) do
    local result = world.callScriptedEntity(receiverid, "datawire.flushData", { })
  end
 
  math.starfoundry.datawire.receivers = {}
end

function datawire.flushData()
  for nodeId, dataItem in pairs(storage.wiredata.nextState) do
    for dataType, data in pairs(dataItem) do
      onValidDataReceived(data, dataType, nodeId, nil) -- todo: fix regression
    end
  end
  storage.wiredata.nextState = {}
  return true
end

--- Receives data from another datawire object
-- @param data (args[1]) the data received
-- @param dataType (args[2]) the data type received ("boolean", "number", "string", "area", etc.)
-- @param sourceEntityId (args[3]) the id of the sending entity, which can be use for an imperfect node association
-- @returns true if valid data was received
function datawire.receiveData(args)
  --unpack args
  local data = args[1]
  local dataType = args[2]
  local sourceEntityId = args[3]

  -- world.logInfo("%s %d sent me this %s %s", world.callScriptedEntity(sourceEntityId, "entity.configParameter", "objectName"), sourceEntityId, dataType, data)

  --convert entityId to nodeId
  local nodeId = datawire.inboundConnections[sourceEntityId]

  if nodeId == nil then
    -- if datawire.initialized then
    --   world.logInfo("DataWire: %s received data of type %s from UNRECOGNIZED %s %d, not in table:", entity.configParameter("objectName"), dataType, world.callScriptedEntity(sourceEntityId, "entity.configParameter", "objectName"), sourceEntityId)
    --   world.logInfo("%s", datawire.inboundConnections)
    -- end

    return false
  elseif validateData and validateData(data, dataType, nodeId, sourceEntityId) then
    if onValidDataReceived then
      
      -- initial state of stored data is nil 
      storage.wiredata.nextState[nodeId] = storage.wiredata.nextState[nodeId] or {}

      if (dataType == "number") then
        storage.wiredata.nextState[nodeId][dataType] = storage.wiredata.nextState[nodeId][dataType] or 0
        storage.wiredata.nextState[nodeId][dataType] = storage.wiredata.nextState[nodeId][dataType] + data
      elseif (dataType == "boolean") then
        storage.wiredata.nextState[nodeId][dataType] = storage.wiredata.nextState[nodeId][dataType] or false
        storage.wiredata.nextState[nodeId][dataType] = storage.wiredata.nextState[nodeId][dataType] or data
      elseif (dataType == "string") then
        storage.wiredata.nextState[nodeId][dataType] = storage.wiredata.nextState[nodeId][dataType] or "" -- todo: Проверить ли, нужна ли эта строка
        storage.wiredata.nextState[nodeId][dataType] = storage.wiredata.nextState[nodeId][dataType] .. data
      else
        -- todo: Проверить список допустимых типов
        storage.wiredata.nextState[nodeId][dataType] = data
      end
          
       math.starfoundry.datawire.receivers[entity.id()] = entity.id();
      --onValidDataReceived(data, dataType, nodeId, sourceEntityId)
    end
     
    -- world.logInfo(string.format("DataWire: %s received data of type %s from %d", entity.configParameter("objectName"), dataType, sourceEntityId))

    return true
  else
    -- world.logInfo("DataWire: %s received INVALID data of type %s from entity %d: %s", entity.configParameter("objectName"), dataType, sourceEntityId, data)
    
    return false
  end
end