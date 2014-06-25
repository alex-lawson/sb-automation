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

function receiveBroadcastedEntities(pipeName, nodeId, entities, virtualNodes, fromEntity, fromNode)
  local position = entity.position()
  world.debugLine({position[1] + 1, position[2]}, {position[1] + 1, position[2] + 3}, "green")

  local newEntities = {}
  local pathToSource = {}
  local localNode = 0
  local appliedOffset = {0, 0}

  --Get path to source entity
  for _,connection in ipairs(entities) do
    if connection.id == entity.id() then
      pathToSource = reversePath(connection.path)
      localNode = connection.nodeId
      local offset = pathToSource[1] --This is the offset from the source entity
      if #pathToSource == 0 then offset = {0,0} end
      appliedOffset = {-offset[1] + pipes.nodes[pipeName][nodeId].dir[1], -offset[2] + pipes.nodes[pipeName][nodeId].dir[2]} --The offset to apply to all path nodes to make them relative to this object
    end
  end

  --Add source entity
  newEntities[1] = {id = fromEntity, nodeId = fromNode, path = offsetPath(pathToSource, appliedOffset)}

  --Add the other entities
  for _,connection in ipairs(entities) do
    if connection.id ~= entity.id() then
      local reroutedPath = reroutePath(pathToSource, connection.path)
      newEntities[#newEntities+1] = {id = connection.id, nodeId = connection.nodeId, path = offsetPath(reroutedPath, appliedOffset)}
    end
  end

  --Add virtual nodes
  local newNodes = {}
  for _,vNode in ipairs(virtualNodes) do
    local reroutedPath = reroutePath(pathToSource, vNode.path)
    newNodes[#newNodes+1] = {pos = vNode.pos, path = offsetPath(reroutedPath, appliedOffset)}
  end

  if pipes.nodeEntities == nil then pipes.nodeEntities = {} end
  if pipes.nodeEntities[pipeName] == nil then pipes.nodeEntities[pipeName] = {} end
  if pipes.virtualNodes == nil then pipes.virtualNodes = {} end
  if pipes.virtualNodes[pipeName] == nil then pipes.virtualNodes[pipeName] = {} end

  table.sort(newEntities, function(a,b) return #a.path < #b.path end)
  table.sort(newNodes, function(a,b) return #a.path < #b.path end)

  pipes.nodeEntities[pipeName][nodeId] = newEntities;
  pipes.virtualNodes[pipeName][nodeId] = newNodes;

  pipes.updateTimers[pipeName][nodeId] = -0.5;
end

function reversePath(path)
  local newPath = {}
  for i = #path, 1, -1 do
    newPath[#newPath+1] = {path[i][1], path[i][2]}
  end
  return newPath
end

function offsetPath(path, offset)
  local newPath = {}
  for i,pos in ipairs(path) do
    newPath[i] = {pos[1] + offset[1], pos[2] + offset[2]}
  end
  return newPath
end

function pathIntersection(firstPath, secondPath)
  for firstIndex,pos in ipairs(firstPath) do
    local secondIndex = table.containsVector2(secondPath, pos)
    if secondIndex then
      return firstIndex, secondIndex
    end
  end
  return false
end

function reroutePath(firstPath, secondPath)
  local newPath = {}

  local firstIndex, secondIndex = pathIntersection(firstPath, secondPath)

  --Add segment from this object to intersection
  for i = 1, firstIndex do
    newPath[#newPath+1] = {firstPath[i][1], firstPath[i][2]}
  end

  --Add segment from intersection to end object
  for i = secondIndex, #secondPath do
    newPath[#newPath+1] = {secondPath[i][1], secondPath[i][2]}
  end

  return newPath;
end

--HELPERS

--- Checks if a table (array only) contains a value (not recursive)
-- @param table table - table to check
-- @param value (w/e) - value to compare
-- @returns true if table contains it, false if not
function table.contains(table, value)
  for _,val in ipairs(table) do
    if value == val then return true end
  end
  return false
end

function table.containsVector2(table, value)
  for i,val in ipairs(table) do
    if val[1] == value[1] and val[2] == value[2] then return i end
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

function compareVectors(firstVector, secondVector)
  return firstVector[1] == secondVector[1] and firstVector[2] == secondVector[2]
end

--PIPES
pipes = {}

--Directions

pipes.directions = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
pipes.otherDirections = {{-1, 0}, {0, -1}, {1, 0}, {0, 1}}
pipes.reverseDir = {}
pipes.reverseDir["1.0"] = {-1, 0}
pipes.reverseDir["0.1"] = {0, -1}
pipes.reverseDir["-1.0"] = {1, 0}
pipes.reverseDir["0.-1"] = {0, 1}

--Varieties. Order is important. Middle, hrz, vert, ne, nw, sw, se
pipes.varieties = {}

pipes.varieties["sewerpipe"] = {
  "sewerpipehorizontal",
  "sewerpipevertical",
  "sewerpipeNE",
  "sewerpipeNW",
  "sewerpipeSW",
  "sewerpipeSE",
  "sewerpipemiddle"
}

pipes.varieties["cleanpipe"] = {
  "cleanpipehorizontal",
  "cleanpipevertical",
  "cleanpipeNE",
  "cleanpipeNW",
  "cleanpipeSW",
  "cleanpipeSE",
  "cleanpipemiddle"
}

--- Initialize, always run this in init (when init args == false)
-- @param pipeTypes an array of pipe types (defined in itempipes.lua and liquidpipes.lua)
-- @returns nil
function pipes.init(pipeTypes)

  pipes.updateTimers = {}
  pipes.updateInterval = 1
  
  pipes.types = {}
  pipes.nodes = {} 
  pipes.nodeEntities = {}
  pipes.virtualNodes = {}
  
  for _,pipeType in ipairs(pipeTypes) do
    pipes.types[pipeType.pipeName] = pipeType
  end
  
  for pipeName,pipeType in pairs(pipes.types) do
    pipes.nodes[pipeName] = entity.configParameter(pipeType.nodesConfigParameter)
    pipes.nodeEntities[pipeName] = {}
    pipes.virtualNodes[pipeName] = {}
    pipes.updateTimers[pipeName] = {}
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

--- Matches pipe against a pipe type and layer
-- @param pipeName string - name of the pipe type to use
-- @param position vec2 - world position to check
-- @param layer - layer to check ("foreground" or "background")
-- @param pipeType - type of pipe to check for, if nil it will return whatever it finds
-- @returns Hook return if successful, false if unsuccessful
function pipes.pipeMatches(pipeName, position, layer, pipeType)
  local checkedTile = world.material(position, layer)
  for type,varieties in pairs(pipes.varieties) do
    if type == pipeType or pipeType == nil then
      if table.contains(varieties, checkedTile) then 
        return type
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
function pipes.getPipeTileData(pipeName, position, layerMode, typeMode)
  local checkBothLayers = false
  if layerMode == nil then checkBothLayers = true end

  local layerSwitch = {foreground = "background", background = "foreground"}
  
  layerMode = layerMode or "foreground"
  
  local firstCheck = pipes.pipeMatches(pipeName, position, layerMode, typeMode)
  local secondCheck = nil
  if checkBothLayers then secondCheck = pipes.pipeMatches(pipeName, position, layerSwitch[layerMode], typeMode) end

  --Return relevant values
  if firstCheck then
    if typeMode == nil then typeMode = firstCheck end
    return layerMode, typeMode
  elseif checkBothLayers and secondCheck then
    if typeMode == nil then typeMode = secondCheck end
    return layerSwitch[layerMode], secondCheck
  end
  return false, false
end

--- Gets all the connected entities for a pipe type
-- @param pipeName string - name of the pipe type to use
-- @returns list of connected entities with format {nodeId = {{id = 1, nodeId = 1, path = {{1,0},{2,0}}}}
function pipes.getNodeEntities(pipeName, pipeNode, nodeIndex)
  local position = entity.position()
  local nodeEntities = {}
  local virtualNodes = {}
  local nodesTable = {}
  
  if pipes.nodes[pipeName] == nil then return {} end
  nodeEntities, virtualNodes = pipes.walkPipes(pipeName, pipeNode.offset, pipeNode.dir, nodeIndex)
  return nodeEntities, virtualNodes
end

--- Should be run in main
-- @param dt number - delta time
-- @returns nil
function pipes.update(dt)
  local position = entity.position()
  pipes.processPlacementQueue()

  --Get connected entities
  for pipeName,pipeType in pairs(pipes.types) do
    if pipes.updateTimers[pipeName] == nil then pipes.updateTimers[pipeName] = {} end

    for i,pipeNode in ipairs(pipes.nodes[pipeName]) do
      if pipes.updateTimers[pipeName][i] == nil then pipes.updateTimers[pipeName][i] = pipes.updateInterval end

      if pipes.updateTimers[pipeName][i] >= pipes.updateInterval then
        pipes.nodeEntities[pipeName][i], pipes.virtualNodes[pipeName][i] = pipes.getNodeEntities(pipeName, pipeNode, i)
        pipes.updateTimers[pipeName][i] = pipes.updateTimers[pipeName][i] - pipes.updateInterval;
      end

      pipes.updateTimers[pipeName][i] = pipes.updateTimers[pipeName][i] + dt
    end
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

--NEEDS TO BE REWRITTEN FOR ENDPOINTS
--- Walks through placed pipe tiles to find connected entities
-- @param pipeName string - name of pipe type to use
-- @param startOffset vec2 - Position *relative to the object* to start looking, should be set to a node's position
-- @param startDir vec2 - Direction to start looking in, should be set to a node's direction
-- @returns List of connected entities with ID, remote Node ID, and path info, sorted by nearest-first
function pipes.walkPipes(pipeName, startOffset, startDir, nodeId)
  local position = entity.position();
  world.debugLine(position, {position[1], position[2] + 3}, "red")


  local validEntities = {}
  local visitedTiles = {}
  local tilesToVisit = {}
  local typeMode = nil

  tilesToVisit[1] =  {pos = {startOffset[1] + startDir[1], startOffset[2] + startDir[2]}, layer = nil, dir = startDir, path = {}, neighbors = {pipes.reverseDir[startDir[1].."."..startDir[2]]} } 

  while #tilesToVisit > 0 do
    local tile = tilesToVisit[1]
    local layer, type = pipes.getPipeTileData(pipeName, entity.toAbsolutePosition(tile.pos), tile.layer, typeMode)

    --If a tile, add connected spaces to the visit list
    if layer then
      tile.layer = layer
      typeMode = type
      tile.path[#tile.path+1] = tile.pos --Add tile to the path

      visitedTiles[tile.pos[1].."."..tile.pos[2]] = tile --Add to global visited
      for index,dir in ipairs(pipes.directions) do
        local newPos = {tile.pos[1] + dir[1], tile.pos[2] + dir[2]}
        if visitedTiles[newPos[1].."."..newPos[2]] == nil then --Don't check the tile we just came from, and don't check already visited ones
          local newTile = {pos = newPos, prev = tile.pos[1].."."..tile.pos[2], layer = tile.layer, neighbors = {}, dir = dir, path = table.copy(tile.path)}
          table.insert(tilesToVisit, 2, newTile)
        else
          --If it is visited we should add this tile to its neighbors
          table.insert(visitedTiles[newPos[1].."."..newPos[2]].neighbors, 1, pipes.otherDirections[index])
          table.insert(tile.neighbors, 1, {dir[1], dir[2]})
        end
      end
    --If not a tile, check for objects that might connect
    elseif not layer then
      local absTilePos = entity.toAbsolutePosition(tile.pos)
      local connectedObjects = world.entityLineQuery(absTilePos, {absTilePos[1] + 1, absTilePos[2] + 2})

      if connectedObjects then
        for key,objectId in ipairs(connectedObjects) do
          local entNode = pipes.validEntity(pipeName, objectId, entity.toAbsolutePosition(tile.pos), tile.dir)
          if entNode and tile.prev then table.insert(visitedTiles[tile.prev].neighbors, 1, tile.dir) end
          if (objectId ~= entity.id() or entNode ~= nodeId) and entNode then
            validEntities[#validEntities+1] = {id = objectId, nodeId = entNode, path = table.copy(tile.path)}
          end
        end
      end
    end
    table.remove(tilesToVisit, 1)
  end

  if next(visitedTiles) then 
    pipes.replacePipes(visitedTiles, typeMode)
  end

  local virtualNodes = pipes.getVirtualNodes(visitedTiles)

  table.sort(validEntities, function(a,b) return #a.path < #b.path end)
  table.sort(virtualNodes, function(a,b) return #a.path < #b.path end)

  if next(validEntities) then
    pipes.broadcastEntities(validEntities, virtualNodes, pipeName, nodeId)
  end

  return validEntities, virtualNodes
end


function pipes.getVirtualNodes(tiles)
  local vNodes = {}
  for _,tile in pairs(tiles) do
    if #tile.neighbors == 1 then
      local nodePos = entity.toAbsolutePosition(tile.pos)
      nodePos[1] = nodePos[1] + tile.dir[1]
      nodePos[2] = nodePos[2] + tile.dir[2]
      table.insert(vNodes, {pos = nodePos, path = tile.path})
    end
  end
  table.sort(vNodes, function(a,b) return #a.path < #b.path end)
  return vNodes
end

------BROADCASTING ENTITIES

function pipes.broadcastEntities(entities, virtualNodes, pipeName, pipeNode)
  for _,connectedEntity in ipairs(entities) do
    world.callScriptedEntity(connectedEntity.id, 'receiveBroadcastedEntities', pipeName, connectedEntity.nodeId, entities, virtualNodes, entity.id(), pipeNode)
  end
end

------REPLACING TILES WITH THE RIGHT ones
pipes.placeQueue = {}

pipes.tileMatchMap = {
  {match = {"e", false, "e", false}, min = 3},
  {match = {false, "e", false, "e"}, min = 3},
  {match = {true, true, false, false}, min = 4},
  {match = {false, true, true, false}, min = 4},
  {match = {false, false, true, true}, min = 4},
  {match = {true, false, false, true}, min = 4},
  {match = {"e", "e", "e", "e"}, min = 0}
}

function pipes.tileContainsNeighbor(tile, direction)
  for _,dir in ipairs(tile.neighbors) do
    if compareVectors(dir, direction) then return true end
  end
  return false
end

function pipes.buildTileConnectionMap(tile)
  local neighborMap = {}
  for i=1, 4 do
    neighborMap[i] = pipes.tileContainsNeighbor(tile, pipes.directions[i])
  end
  return neighborMap
end

function pipes.matchNeighbors(tile, matchKey)
  local matches = 0
  local connectionMap = pipes.buildTileConnectionMap(tile)
  for i=1, 4 do
    if matchKey.match[i] == "e" then
      if connectionMap[i] == true then matches = matches + 1 end
    elseif matchKey.match[i] == connectionMap[i] then
      matches = matches + 1
    else
      return false
    end
  end

  if matches >= matchKey.min then return true end
  return false
end

function pipes.suggestTileName(tile, type)
  for i,matchKey in ipairs(pipes.tileMatchMap) do
    if pipes.matchNeighbors(tile, matchKey) then
      return pipes.varieties[type][i]
    end
  end
  return false
end

function pipes.replacePipes(tiles, type)
  for key,tile in pairs(tiles) do
    local worldPos = entity.toAbsolutePosition(tile.pos)
    local tileName = world.material(worldPos, tile.layer)
    local suggestedName = pipes.suggestTileName(tile, type)
    if tileName ~= suggestedName then
        world.damageTiles({worldPos}, tile.layer, entity.position(), "crushing", 1000)
        table.insert(pipes.placeQueue, {pos = worldPos, layer = tile.layer, material = suggestedName})
    end
  end
end

function pipes.processPlacementQueue()
  for i=#pipes.placeQueue, 1, -1 do
    local tile = pipes.placeQueue[i]
    if world.material(tile.pos, tile.layer) or world.placeMaterial(tile.pos, tile.layer, tile.material) then
      
      table.remove(pipes.placeQueue, i)
    end
  end
end