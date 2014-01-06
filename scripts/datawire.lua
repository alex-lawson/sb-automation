--- WHEN YOU OVERWRITE THIS FUNCTION IN A LATER SCRIPT, INCLUDE THIS CODE!
function init(virtual)
  if not virtual then
    datawire.init()
  end
end

--- WHEN YOU OVERWRITE THIS FUNCTION IN A LATER SCRIPT, INCLUDE THIS CODE!
function onNodeConnectionChange()
  datawire.createConnectionTable()
end

datawire = {}

--- this should be called by the implementing object in its own init()
function datawire.init()
  self.initialized = false
end

--- this will be called internally, to build connection tables once the world has fully loaded
function datawire.initAfterLoading()
  datawire.createConnectionTable()
  self.initialized = true
end

--- Creates connection tables for inbound and outbound nodes
function datawire.createConnectionTable()
  storage.outboundConnections = {}
  local i = 0
  while i < entity.outboundNodeCount() do
    storage.outboundConnections[i] = entity.getOutboundNodeIds(i)
    i = i + 1
  end

  storage.inboundConnections = {}
  local entityIds
  i = 0
  while i < entity.inboundNodeCount() do
    entityIds = entity.getInboundNodeIds(i)
    for j, entityId in ipairs(entityIds) do
      storage.inboundConnections[entityId] = i
    end
    i = i + 1
  end

  --world.logInfo(string.format("%s (id %d) created connection tables for %d outbound and %d inbound nodes", entity.configParameter("objectName"), entity.id(), entity.outboundNodeCount(), entity.inboundNodeCount()))
  --world.logInfo(storage.outboundConnections)
  --world.logInfo(storage.inboundConnections)
end

--- determine whether there is a valid recipient on the specified outbound node
-- @param nodeId the node to be queried
-- @returns true if there is a recipient connected to the node
function datawire.isOutboundNodeConnected(nodeId)
  return storage.outboundConnections and storage.outboundConnections[nodeId] and #storage.outboundConnections[nodeId] > 0
end

--- Sends data to another datawire object
-- @param data the data to be sent
-- @param dataType the data type to be sent ("boolean", "number", "string", "area", etc.)
-- @param nodeId the outbound node id to send to, or "all" for all outbound nodes
-- @returns true if at least one object successfully received the data
function datawire.sendData(data, dataType, nodeId)
  -- don't transmit if connection tables haven't been built
  if not self.initialized then
    return false
  end

  local transmitSuccess = false

  if nodeId == "all" then
    for k, v in pairs(storage.outboundConnections) do
      transmitSuccess = datawire.sendData(data, dataType, k) or transmitSuccess
    end
  else
    if storage.outboundConnections[nodeId] and #storage.outboundConnections[nodeId] > 0 then 
      for i, entityId in ipairs(storage.outboundConnections[nodeId]) do
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

  --convert entityId to nodeId
  local nodeId = storage.inboundConnections[sourceEntityId]

  if nodeId == nil then
    world.logInfo(string.format("DataWire: %s received data of type %s from UNRECOGNIZED ENTITY %d, not in table:", entity.configParameter("objectName"), dataType, sourceEntityId))
    world.logInfo(storage.inboundConnections)

    return false
  elseif validateData(data, dataType, nodeId) then
    onValidDataReceived(data, dataType, nodeId)

    --world.logInfo(string.format("DataWire: %s received data of type %s from %d", entity.configParameter("objectName"), dataType, sourceEntityId))
    --world.logInfo(data)

    return true
  else
    world.logInfo(string.format("DataWire: %s received INVALID data of type %s from entity %d", entity.configParameter("objectName"), dataType, sourceEntityId))
    world.logInfo(data)
    
    return false
  end
end

--- Validates data received from another datawire object
-- @param data the data to be validated
-- @param dataType the data type to be validated ("boolean", "number", "string", "area", etc.)
-- @param nodeId the inbound node id on which data was received
-- @returns true if the data is valid
function validateData(data, dataType, nodeId)
  return true
end

--- Hook for datawire objects to use received data
-- @param data the data
-- @param dataType the data type ("boolean", "number", "string", "area", etc.)
-- @param nodeId the inbound node id on which data was received
function onValidDataReceived(data, dataType, nodeId) end

--- any datawire operations that need to be run in main()
function datawire.update()
  if self.initialized then
    -- nothing for now
  else
    datawire.initAfterLoading()
    initAfterLoading()
  end
end

--- hook for implementing scripts to add their own initialization code in main()
function initAfterLoading() end

--- WHEN YOU OVERWRITE THIS FUNCTION IN A LATER SCRIPT, INCLUDE THIS CODE!
function main()
  datawire.update()
end