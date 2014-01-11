--Global helper functions
function acceptPipeRequestAt(pipeName, position, pipeDirection, lookingFor)
  if pipes == nil or pipes.nodes[pipeName] == nil then
    return false 
  end
  
  local entityPos = entity.position()
  local nodeTable = {}
  if lookingFor == "inbound" then
    nodeTable = pipes.nodes[pipeName].inbound
  elseif lookingFor == "outbound" then
    nodeTable = pipes.nodes[pipeName].outbound
  end
  
  if nodeTable == nil then 
    return false 
  end
  
  for i,node in ipairs(nodeTable) do
    local absNodePos = {entityPos[1] + node.offset[1], entityPos[2] + node.offset[2]}
    if position[1] == absNodePos[1] and position[2] == absNodePos[2] and pipes.pipesConnect(node.dir, {pipeDirection}) then
      return i
    end
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
    pipes.nodes[pipeName] = {
      inbound = entity.configParameter(pipeType.configParameters.inbound), 
      outbound = entity.configParameter(pipeType.configParameters.outbound)
    }
    pipes.nodeEntities[pipeName] = {
      inbound = {}, 
      outbound = {}
    }
  end
end

function pipes.push(pipeName, nodeId, args)
  local returnTable = {}
  if #pipes.nodeEntities[pipeName].outbound[nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName].outbound[nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.put, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.pull(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName].inbound[nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName].inbound[nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.get, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.peekPush(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName].outbound[nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName].outbound[nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.peekPut, pipeFunction, args, entity.nodeId)
      if entityReturn then return entityReturn end
    end
  end
  return false
end

function pipes.peekPull(pipeName, nodeId, args)
  if #pipes.nodeEntities[pipeName].inbound[nodeId] > 0 then
    for i,entity in ipairs(pipes.nodeEntities[pipeName].inbound[nodeId]) do
      local entityReturn = world.callScriptedEntity(entity.id, pipes.types[pipeName].hooks.peekGet, pipeFunction, args, entity.nodeId)
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

function pipes.getPipeDirections(pipeName, position)
  local backgroundTile = world.material(position, "background")
  for orientation,directions in pairs(pipes.directions) do
    if backgroundTile == pipes.types[pipeName].tiles .. orientation then
      return directions
    end
  end
  
  local foregroundTile = world.material(position, "foreground")
  for orientation,directions in pairs(pipes.directions) do
    if foregroundTile == pipes.types[pipeName].tiles .. orientation then
      return directions
    end
  end
  
  return false
end

function pipes.getNodeEntities(pipeName, direction)
  local position = entity.position()
  local nodeEntities = {}
  local nodesTable = {}
  local lookingFor = ""
  
  if direction == "inbound" then
    nodesTable = pipes.nodes[pipeName].inbound
    lookingFor = "outbound"
  elseif direction == "outbound" then
    nodesTable = pipes.nodes[pipeName].outbound
    lookingFor = "inbound"
  end
  
  if nodesTable == nil then return {} end
  for i,pipeNode in ipairs(nodesTable) do
    local pipePos = {position[1] + pipeNode.offset[1], position[2] + pipeNode.offset[2]}
    nodeEntities[i] = pipes.walkPipes(pipeName, pipePos, pipeNode.dir, lookingFor)
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
      pipes.nodeEntities[pipeName].inbound = pipes.getNodeEntities(pipeName, "inbound")
      --Get outbound
      pipes.nodeEntities[pipeName].outbound = pipes.getNodeEntities(pipeName, "outbound")
    end
    
    pipes.updateTimer = 0
  end
end

function pipes.validEntity(pipeName, entityId, position, direction, lookingFor)
  return world.callScriptedEntity(entityId, "acceptPipeRequestAt", pipeName, position, direction, lookingFor)
end

function pipes.checkTile(position, tileName)
  return (world.material(position, "foreground") == tileName or world.material(position, "background") == tileName)
end

function pipes.walkPipes(pipeName, startPos, startDir, lookingFor)
  local validEntities = {}
  
  local visitedTiles = {}
  local tilesToVisit = {{startPos[1], startPos[2]}}
  
  
  while #tilesToVisit > 0 do
    local newVisitTiles = {}
    for i,tile in ipairs(tilesToVisit) do
      local tileName = pipes.types[pipeName].tiles
      local pipeDirections = pipes.getPipeDirections(pipeName, {tile[1], tile[2]})
      if startDir then
        pipeDirections = {startDir}
        startDir = false
      end
      
      
      if pipeDirections ~= false then
        if visitedTiles[tile[1]] == nil then visitedTiles[tile[1]] = {} end
        visitedTiles[tile[1]][tile[2]] = true
        
        --Get tiles that the current pipe might connect to
        for i,direction in ipairs(pipeDirections) do
          nearTile = {tile[1] + direction[1], tile[2] + direction[2]}
          nearPipeDirections = pipes.getPipeDirections(pipeName, nearTile)
          
          --Add them to the list of tiles to visit if they do connect
          if nearPipeDirections ~= false and pipes.pipesConnect(direction, nearPipeDirections) and (visitedTiles[nearTile[1]] == nil or visitedTiles[nearTile[1]][nearTile[2]] == nil) then
            newVisitTiles[#newVisitTiles+1] = {nearTile[1], nearTile[2]}
          end
          
          --Add valid entities to the entity list
          local connectedObjects = world.entityLineQuery({nearTile[1] + 0.4, nearTile[2] + 0.4}, {nearTile[1] + 0.6, nearTile[2] + 0.6}, {notAnObject = false})
          if connectedObjects then
            for key,objectId in ipairs(connectedObjects) do
              if objectId ~= entity.id() then
                local notAdded = true
                
                for i,id in ipairs(validEntities) do
                  if objectId == id then notAdded = false end
                end
                local validEntity = pipes.validEntity(pipeName, objectId, nearTile, direction, lookingFor)
                if validEntity and notAdded then
                  validEntities[#validEntities+1] = {id = objectId, nodeId = validEntity}
                end
              end
            end
          end
        end
      end
    end
    tilesToVisit = newVisitTiles
  end
  return validEntities
end