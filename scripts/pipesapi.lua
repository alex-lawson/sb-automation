--Global helper functions
function acceptPipeRequestAt(pipeName, position, pipeDirection)
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

function isValueInArray(value, table)
  for _,val in ipairs(table) do
    if value == val then return true end
  end
  return false
end

--Pipes object with internal functions
pipes = {}

pipes.directions = {}
pipes.directions["horz"] = {{1,0}, {-1, 0}}
pipes.directions["vert"] = {{0, 1}, {0, -1}}
pipes.directions["b1"] = {{1,0}, {0,1}}
pipes.directions["b2"] = {{1, 0}, {0, -1}}
pipes.directions["b3"] = {{-1,0}, {0, -1}}
pipes.directions["b4"] = {{-1, 0}, {0, 1}}
pipes.directions["plus"] = {{1,0}, {-1, 0}, {0, -1}, {0, 1}}

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
end

function pipes.push(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.put, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.pull(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.get, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.peekPush(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.peekPut, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.peekPull(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName][nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName][nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.peekGet, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.pipesConnect(firstDirection, secondDirections)
  for _,secondDirection in ipairs(secondDirections) do
    if firstDirection[1] == -secondDirection[1] and firstDirection[2] == -secondDirection[2] then
      return true
    end
  end
  return false
end

function pipes.tileDirections(pipeName, position, layer)
  local foregroundTile = world.material(position, layer)
  for orientation,directions in pairs(pipes.directions) do
    if foregroundTile == pipes.types[pipeName].tiles .. orientation then
      return directions
    end
  end
  return false
end

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

function pipes.validEntity(pipeName, entityId, position, direction)
  return world.callScriptedEntity(entityId, "acceptPipeRequestAt", pipeName, position, direction)
end

function pipes.walkPipes(pipeName, startOffset, startDir)
  local validEntities = {}
  local visitedTiles = {}
  local tilesToVisit = {{pos = {startOffset[1] + startDir[1], startOffset[2] + startDir[2]}, layer = "foreground", dir = startDir, path = {}}}
  local layerMode = nil
  
  while #tilesToVisit > 0 do
    --Get connecting pipes, ignoring previous one
    local tile = tilesToVisit[1]
    local pipeDirections, layerMode = pipes.getPipeTileData(pipeName, entity.toAbsolutePosition(tile.pos), tile.layer, tile.dir)
    
    --If a tile, add connected spaces to the visit list
    if pipeDirections then
      tile.path[#tile.path+1] = tile.pos --Add tile to the path
      visitedTiles[tile.pos[1].."."..tile.pos[2]] = true --Add to global visited
      world.logInfo("Walking from object %s through tile %s", entity.id(), tile.pos[1].."."..tile.pos[2])
      for _,dir in ipairs(pipeDirections) do
        local newPos = {tile.pos[1] + dir[1], tile.pos[2] + dir[2]}
        if not pipes.pipesConnect(dir, {tile.dir}) and visitedTiles[newPos[1].."."..newPos[2]] == nil then --Don't check the tile we just came from
          local newTile = {pos = newPos, layer = layerMode, dir = dir, path = tile.path}
          table.insert(tilesToVisit, 2, newTile)
        end
      end
    --If not a tile, check for objects that might connect
    elseif not pipeDirections then
      world.logInfo("No tile at %s, checking for objects.", tile.pos[1].."."..tile.pos[2])
      local connectedObjects = world.objectQuery(entity.toAbsolutePosition(tile.pos), 1)
      if connectedObjects then
        world.logInfo("Found %s objects", #connectedObjects) 
        for key,objectId in ipairs(connectedObjects) do
          world.logInfo("Found object %s", objectId)
          local entNode = pipes.validEntity(pipeName, objectId, entity.toAbsolutePosition(tile.pos), tile.dir)
          if objectId ~= entity.id() and entNode and isValueInArray(objectId, validEntities) == false then
            validEntities[#validEntities+1] = {id = objectId, nodeId = entNode, path = tile.path}
          end
        end
      end
    end
    table.remove(tilesToVisit, 1)
  end
  table.sort(validEntities, function(a,b) return #a.path < #b.path end)
  world.logInfo("%s", validEntities)
  return validEntities
end
