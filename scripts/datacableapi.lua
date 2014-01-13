--- Data Cables API
-- storage.cApi.c(in/out) is the persistent memory for connected object positions
-- cableApi.c(in/out) is the temporary memory that needs to be restored every world load

cableApi = {}

--------------------------------------------------
--- CONCEPT OBJECT REQUIREMENTS TO USE THE API ---
--------------------------------------------------

--- The list:
--  * at least one input node for input devices
--  * at least one output node for output devices
--  * 'incable#' rotation and scaling groups for each IN slot
--  * 'outcable#' rotation and scaling groups for each OUT slot

--------------------------------------------------
--- HOOK STUFF -- TO BE DECLARED IN OBJ SCRIPT ---
--------------------------------------------------

--- Used to read data sent trough the cables
-- @param data the data sent
--> function cableApi.receiveInData(data, entityId) end

--- Called when a connection is established
-- @param _cableApi the remote object's cableApi proxy
-- @param cableno the IN cable's number
--> function cableApi.onConnected(_cableApi, cableno)

--- Called when a connection is severed
-- @param cableno the IN cable's number
--> function cableApi.onDisconnected(cableno)

--------------------------------------------------
--- PUBLIC API STUFF -- MEANT FOR EVERYDAY USE ---
--------------------------------------------------

--- Initializes the cables
-- @param inType type of the input cables
-- @param inCount amount of input cables
-- @param outType type of the output cables
-- @param outCount amount of output cables
function cableApi.init(inType, inCount, outType, outCount)
  if cableApi.oriNodeChange == nil then
    cableApi.oriNodeChange = onNodeConnectionChange
    onNodeConnectionChange = cableApi.hookNodeChange
  end
  if cableApi.oriDie == nil then
    cableApi.oriDie = die
    die = cableApi.hookDie
  end
  if storage.cApi == nil then storage.cApi = {} end
  if storage.cApi.cin == nil then storage.cApi.cin = { type = inType, count = inCount } end
  if storage.cApi.cout == nil then storage.cApi.cout = { type = outType, count = outCount } end
  if cableApi.cin == nil then cableApi.cin = {} end
  if cableApi.cout == nil then cableApi.cout = {} end
  if cableApi.prevNodes == nil then cableApi.prevNodes = { nin = {}, nout = {} } end
  cableApi.updateNodeTable()
  cableApi.restoreConnections()
  cableApi.updateConnections()
end

--- Sends data trough the cables
-- @param data the data to send
function cableApi.sendOutData(data)
  for i=1,cableApi.getOutCount() do
    if (cableApi.cout[i] == nil) and (cableApi.cout[i].receiveInData ~= nil) then
      cableApi.cout[i].receiveInData(data, entity.id())
    end
  end
  return true
end

--- Updates the node connection lookup table
function cableApi.updateNodeTable()
  for i=0,entity.inboundNodeCount() - 1 do
    cableApi.prevNodes.nin[i] = entity.isInboundNodeConnected(i)
  end
end

--- Updates positions of visual cables
function cableApi.updateConnections()
  local pos = cableApi.getInPosition()
  for i=1,cableApi.getInCount() do
    local e = cableApi.cin[i]
    if e == nil then entity.scaleGroup("incable" .. i, { 0.001, 1 })
    else
      e = e.getOutPosition()
      entity.rotateGroup("incable" .. i, math.atan2(e[2] - pos[2], e[1] - pos[1]))
      entity.scaleGroup("incable" .. i, { world.magnitude(pos, e) * 2, 1 })
    end
  end
  pos = cableApi.getOutPosition()
  for i=1,cableApi.getOutCount() do
    local e = cableApi.cout[i]
    if e == nil then entity.scaleGroup("outcable" .. i, { 0.001, 1 })
    else
      e = e.getInPosition()
      entity.rotateGroup("outcable" .. i, math.atan2(e[2] - pos[2], e[1] - pos[1]))
      entity.scaleGroup("outcable" .. i, { world.magnitude(pos, e) * 2, 1 })
    end
  end
end

--- Returns absolute inbound node position
function cableApi.getInPosition()
  return entity.toAbsolutePosition(entity.configParameter("inboundNodes")[1])
end

--- Returns absolute outbound node position
function cableApi.getOutPosition()
  return entity.toAbsolutePosition(entity.configParameter("outboundNodes")[1])
end

--- Returns absolute entity position
function cableApi.getEntityPosition()
  return entity.position()
end

--- Returns entity's ID
function cableApi.getEntityId()
  return entity.id()
end

--- Returns IN cables type
function cableApi.getInType()
  return storage.cApi.cin.type
end

--- Returns OUT cables type
function cableApi.getOutType()
  return storage.cApi.cout.type
end

--- Returns IN cables count
function cableApi.getInCount()
  return storage.cApi.cin.count
end

--- Returns OUT cables count
function cableApi.getOutCount()
  return storage.cApi.cout.count
end

--- Set a new incoming cable connection
-- @param _cableApi another object's cableApi proxy
function cableApi.connectIn(_cableApi)
  if _cableApi.getOutType() ~= cableApi.getInType() then return false end
  local lin = cableApi.getEmptyInIndex()
  if lin == nil then return false end
  if not _cableApi.setOutConnection(entity.id()) then return false end
  storage.cApi.cin[lin] = _cableApi.getEntityPosition()
  cableApi.cin[lin] = _cableApi
  if cableApi.onConnected ~= nil then cableApi.onConnected(_cableApi, lin) end
  cableApi.updateConnections()
  _cableApi.updateConnections()
  return true
end

--- Get an empty IN cable slot
function cableApi.getEmptyInIndex()
  for i=1,cableApi.getInCount() do
    if cableApi.cin[i] == nil then return i end
  end
  return nil
end

--- Get an empty OUT cable slot
function cableApi.getEmptyOutIndex()
  for i=1,cableApi.getOutCount() do
    if cableApi.cout[i] == nil then return i end
  end
  return nil
end

--- Used to check if the object implements Cable API
function cableApi.hasCableApi()
  return true
end

--- Severs an IN connection
function cableApi.severInConnection(slot)
  if cableApi.cin[slot] ~= nil then
    cableApi.cin[slot].chainOutSever(cableApi.getEntityId())
    cableApi.cin[slot] = nil
    storage.cApi.cin[slot] = nil
    cableApi.updateConnections()
  end
end

--- Severs an OUT connection
function cableApi.severOutConnection(slot)
  if cableApi.cout[slot] ~= nil then
    cableApi.cout[slot].chainInSever(cableApi.getEntityId())
    cableApi.cout[slot] = nil
    storage.cApi.cout[slot] = nil
    cableApi.updateConnections()
  end
end

--------------------------------------------------
--- HELP FUNCTIONS -- NOT MEANT FOR PUBLIC USE ---
--------------------------------------------------

--- Returns first value in table
function firstVal(table)
  for i,v in pairs(table) do return v end
  return nil
end

--------------------------------------------------
--- INTERNAL STUFF -- NOT MEANT FOR PUBLIC USE ---
--------------------------------------------------

--- Internal use only!
function cableApi.chainInSever(entityId)
  for i=1,cableApi.getInCount() do
    if cableApi.cin[i].getEntityId() == entityId then
      cableApi.cin[i] = nil
      storage.cApi.cin[i] = nil
      cableApi.updateConnections()
    end
  end
end

--- Internal use only!
function cableApi.chainOutSever(entityId)
  for i=1,cableApi.getOutCount() do
    if cableApi.cout[i].getEntityId() == entityId then
      cableApi.cout[i] = nil
      storage.cApi.cout[i] = nil
      cableApi.updateConnections()
    end
  end
end

--- Internal use only!
function cableApi.restoreConnections()
  local x = 1
  for i,v in pairs(cableApi.cin) do
    local id = firstVal(world.objectQuery(v, 1))
    if (id ~= nil) and world.callScriptedEntity(id, "cableApi.hasCableApi") then
      cableApi.cin[x] = cableApi.createProxy(id)
      x = x + 1
    end
  end
end

--- Internal use only!
function cableApi.setOutConnection(eId)
  local lout = cableApi.getEmptyOutIndex()
  if lout == nil then return false end
  local _cableApi = cableApi.createProxy(eId)
  storage.cApi.cout[lout] = _cableApi.getEntityPosition()
  cableApi.cout[lout] = _cableApi
  return true
end

--- Internal use only!
function cableApi.hookNodeChange()
  if cableApi.oriNodeChange ~= nil then cableApi.oriNodeChange() end
  for i,v in pairs(cableApi.prevNodes.nin) do
    if not v and entity.isInboundNodeConnected(i) then
      local id = firstVal(entity.getInboundNodeIds(i))
      if world.callScriptedEntity(id, "cableApi.hasCableApi") then
        cableApi.connectIn(cableApi.createProxy(id))
      end
    end
  end
  cableApi.updateNodeTable()
end

--- Internal use only!
function cableApi.hookDie()
  if cableApi.oriDie ~= nil then cableApi.oriDie() end
  for i=1,cableApi.getInCount() do cableApi.severInConnection(i) end
  for i=1,cableApi.getOutCount() do cableApi.severOutConnection(i) end
end

--- Internal use only!
function cableApi.createProxy(entityId)
  local wrappers = {}
  local proxyMetatable = {
    __index = function(t, functionName)
      local wrapper = wrappers[functionName]
      if wrapper == nil then
        wrapper = function(...)
          return world.callScriptedEntity(entityId, "cableApi." .. functionName, ...)
        end
        wrappers[functionName] = wrapper
      end
      return wrapper
    end,
    __newindex = function(t, key, val) end
  }
  local proxy = {}
  setmetatable(proxy, proxyMetatable)
  return proxy
end