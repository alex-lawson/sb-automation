--HOOKS

--- Hook used for determining if an object connects to a specified position
-- @param pipeName string - name of the pipe type to push through
-- @param position vec2 - world position to compare node positions to
-- @param pipeDirection vec2 - direction of the pipe to see if the object connects
-- @returns node ID if successful, false if unsuccessful
function entityConnectsAt(pipeName, position, pipeDirection)
  if pipes == nil or pipes.nodes[pipeName] == nil then
    return false 
  end
  local entityPos = entity.position()
  
  for i,node in ipairs(pipes.nodes[pipeName]) do
    local absNodePos = entity.toAbsolutePosition(node.offset)
    local distance = world.distance(position, absNodePos)
    if distance[1] == 0 and distance[2] == 0 and pipes.pipesConnect(node.dir, {pipeDirection}) then
      return i
    end
  end
  return false
end

--HELPERS

--- Checks if a table (array only) contains a value
-- @param table table - table to check
-- @param value (w/e) - value to compare
-- @returns true if table contains it, false if not
function table.contains(table, value)
  for _,val in ipairs(table) do
    if value == val then return true end
  end
  return false
end

--- Copies a table (not recursive)
-- @param table table - table to copy
-- @returns copied table
function table.copy(table)
  local newTable = {}
  for i,v in pairs(table) do
    newTable[i] = v
  end
  return newTable
end

--PIPES
pipes = {}

pipes.directions = {
  horz = {{1,0}, {-1, 0}},
  vert = {{0, 1}, {0, -1}},
  b1 = {{1,0}, {0,1}},
  b2 = {{1, 0}, {0, -1}},
  b3 = {{-1,0}, {0, -1}},
  b4 = {{-1, 0}, {0, 1}},
  plus = {{1,0}, {-1, 0}, {0, -1}, {0, 1}},
  horizontal = {{1,0}, {-1, 0}},
  vertical = {{0, 1}, {0, -1}},
  NE = {{1,0}, {0,1}},
  SE = {{1, 0}, {0, -1}},
  SW = {{-1,0}, {0, -1}},
  NW = {{-1, 0}, {0, 1}},
  middle = {{1,0}, {-1, 0}, {0, -1}, {0, 1}}
}

--- Initialize, always run this in init (when init args == false)
-- @param pipeTypes an array of pipe types (defined in itempipes.lua and liquidpipes.lua)
-- @returns nil
function pipes.init(pipeTypes)

  pipes.updateTimer = 1 --Should be set to the same as updateInterval so it gets entities on the first update
  pipes.updateInterval = 1
  
  pipes.types = {}
  pipes.nodes = {} 
  pipes.nodeEntities = {}
  
  for _,pipeType in ipairs(pipeTypes) do
    pipes.types[pipeType.pipeName] = pipeType
  end
  
  for pipeName,pipeType in pairs(pipes.types) do
    pipes.nodes[pipeName] = entity.configParameter(pipeType.nodesConfigParameter)
    pipes.nodeEntities[pipeName] = {}
  end

  pipes.rejectNode = {}
end

--- Push, calls the put hook on the closest connected object that returns true
-- @param pipeName string - name of the pipe type to push through
-- @param nodeId number - ID of the node to push through
-- @param args - The arguments to send to the put hook
-- @returns Hook return if successful, false if unsuccessful
function pipes.push(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 and not pipes.rejectNode[nodeId] then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      pipes.rejectNode[nodeId] = true
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.put, args, entity.nodeId)
      pipes.rejectNode[nodeId] = false
      if entityReturn then return entityReturn end
    end
  end
  return false
end

--- Pull, calls the get hook on the closest connected object that returns true
-- @param pipeName string - name of the pipe type to pull through
-- @param nodeId number - ID of the node to pull through
-- @param args - The arguments to send to the hook
-- @returns Hook return if successful, false if unsuccessful
function pipes.pull(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 and not pipes.rejectNode[nodeId] then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      pipes.rejectNode[nodeId] = true
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.get, args, entity.nodeId)
      pipes.rejectNode[nodeId] = false
      if entityReturn then return entityReturn end
    end
  end
  return false
end

--- Peek push, calls the peekPut hook on the closest connected object that returns true
-- @param pipeName string - name of the pipe type to peek through
-- @param nodeId number - ID of the node to peek through
-- @param args - The arguments to send to the hook
-- @returns Hook return if successful, false if unsuccessful
function pipes.peekPush(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 and not pipes.rejectNode[nodeId] then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      pipes.rejectNode[nodeId] = true
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.peekPut, args, entity.nodeId)
      pipes.rejectNode[nodeId] = false
      if entityReturn then return entityReturn end
    end
  end
  return false
end

--- Peek pull, calls the peekPull hook on the closest connected object that returns true
-- @param pipeName string - name of the pipe type to peek through
-- @param nodeId number - ID of the node to peek through
-- @param args - The arguments to send to the hook
-- @returns Hook return if successful, false if unsuccessful
function pipes.peekPull(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 and not pipes.rejectNode[nodeId] then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      pipes.rejectNode[nodeId] = true
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.peekGet, args, entity.nodeId)
      pipes.rejectNode[nodeId] = false
      if entityReturn then return entityReturn end
    end
  end
  return false
end

--- Checks if two pipes connect up, direction-wise
-- @param firstDirection vec2 - vector2 of direction to match
-- @param secondDirections array of vec2s - List of directions to match against
-- @returns true if the secondDirections can connect to the firstDirection
function pipes.pipesConnect(firstDirection, secondDirections)
  for _,secondDirection in ipairs(secondDirections) do
    if firstDirection[1] == -secondDirection[1] and firstDirection[2] == -secondDirection[2] then
      return true
    end
  end
  return false
end

--- Gets the directions of a tile based on tile name
-- @param pipeName string - name of the pipe type to use
-- @param position vec2 - world position to check
-- @param layer - layer to check ("foreground" or "background")
-- @returns Hook return if successful, false if unsuccessful
function pipes.tileDirections(pipeName, position, layer)
  local checkedTile = world.material(position, layer)
  for _,tileType in ipairs(pipes.types[pipeName].tiles) do
    for orientation,directions in pairs(pipes.directions) do
      if checkedTile == tileType .. orientation then
        return directions
      end
    end
  end
  return false
end

--- Gets the directions + layer for a connecting pipe, prioritises the layer specified in layerMode
-- @param pipeName string - name of the pipe type to use
-- @param position vec2 - world position to check
-- @param layerMode - layer to prioritise
-- @param direction (optional) - direction to compare to, if specified it will return false if the pipe does not connect
-- @returns Hook return if successful, false if unsuccessful
function pipes.getPipeTileData(pipeName, position, layerMode, direction)
  local layerSwitch = {foreground = "background", background = "foreground"}
  
  layerMode = layerMode or "foreground"
  
  local firstCheck = pipes.tileDirections(pipeName, position, layerMode)
  local secondCheck = pipes.tileDirections(pipeName, position, layerSwitch[layerMode])
  
  --Return relevant values
  if firstCheck and (direction == nil or pipes.pipesConnect(direction, firstCheck)) then
    return firstCheck, layerMode
  elseif secondCheck and (direction == nil or pipes.pipesConnect(direction, secondCheck)) then
    return secondCheck, layerSwitch[layerMode]
  end
  return false
end

--- Gets all the connected entities for a pipe type
-- @param pipeName string - name of the pipe type to use
-- @returns list of connected entities with format {nodeId = {{id = 1, nodeId = 1, path = {{1,0},{2,0}}}}
function pipes.getNodeEntities(pipeName)
  local position = entity.position()
  local nodeEntities = {}
  local nodesTable = {}
  
  if pipes.nodes[pipeName] == nil then return {} end
  for i,pipeNode in ipairs(pipes.nodes[pipeName]) do
    nodeEntities[i] = pipes.walkPipes(pipeName, pipeNode.offset, pipeNode.dir)
  end
  return nodeEntities
  
end

--- Should be run in main
-- @param dt number - delta time
-- @returns nil
function pipes.update(dt)
  local position = entity.position()
  pipes.updateTimer = pipes.updateTimer + dt
  
  if pipes.updateTimer >= pipes.updateInterval then
  
    --Get connected entities
    for pipeName,pipeType in pairs(pipes.types) do
      --Get inbound
      pipes.nodeEntities[pipeName] = pipes.getNodeEntities(pipeName)
    end
    
    pipes.updateTimer = 0
  end
end

--- Calls a hook on the entity to see if it connects to the specified pipe
-- @param pipeName string - name of pipe type to use
-- @param entityId number - ID of entity to check against
-- @param position vec2 - position of the pipe tile
-- @param direction vec2 - direction of the pipe tile
-- @returns nil
function pipes.validEntity(pipeName, entityId, position, direction)
  return world.callScriptedEntity(entityId, "entityConnectsAt", pipeName, position, direction)
end

--- Walks through placed pipe tiles to find connected entities
-- @param pipeName string - name of pipe type to use
-- @param startOffset vec2 - Position *relative to the object* to start looking, should be set to a node's position
-- @param startDir vec2 - Direction to start looking in, should be set to a node's direction
-- @returns List of connected entities with ID, remote Node ID, and path info, sorted by nearest-first
function pipes.walkPipes(pipeName, startOffset, startDir)
  local validEntities = {}
  local visitedTiles = {}
  local tilesToVisit = {{pos = {startOffset[1] + startDir[1], startOffset[2] + startDir[2]}, layer = "foreground", dir = startDir, path = {}}}
  local layerMode = nil
  
  while #tilesToVisit > 0 do
    local tile = tilesToVisit[1]
    local pipeDirections, layerMode = pipes.getPipeTileData(pipeName, entity.toAbsolutePosition(tile.pos), tile.layer, tile.dir)
    
    --If a tile, add connected spaces to the visit list
    if pipeDirections then
      tile.path[#tile.path+1] = tile.pos --Add tile to the path
      visitedTiles[tile.pos[1].."."..tile.pos[2]] = true --Add to global visited
      for _,dir in ipairs(pipeDirections) do
        local newPos = {tile.pos[1] + dir[1], tile.pos[2] + dir[2]}
        if not pipes.pipesConnect(dir, {tile.dir}) and visitedTiles[newPos[1].."."..newPos[2]] == nil then --Don't check the tile we just came from, and don't check already visited ones
          local newTile = {pos = newPos, layer = layerMode, dir = dir, path = table.copy(tile.path)}
          table.insert(tilesToVisit, 2, newTile)
        end
      end
    --If not a tile, check for objects that might connect
    elseif not pipeDirections then
      --local connectedObjects = world.objectQuery(entity.toAbsolutePosition(tile.pos), 2)
      local absTilePos = entity.toAbsolutePosition(tile.pos)
      local connectedObjects = world.entityLineQuery(absTilePos, {absTilePos[1] + 1, absTilePos[2] + 2})
      if connectedObjects then
        for key,objectId in ipairs(connectedObjects) do
          local entNode = pipes.validEntity(pipeName, objectId, entity.toAbsolutePosition(tile.pos), tile.dir)
          if objectId ~= entity.id() and entNode and table.contains(validEntities, objectId) == false then
            validEntities[#validEntities+1] = {id = objectId, nodeId = entNode, path = table.copy(tile.path)}
          end
        end
      end
    end
    table.remove(tilesToVisit, 1)
  end

  table.sort(validEntities, function(a,b) return #a.path < #b.path end)
  return validEntities
end
