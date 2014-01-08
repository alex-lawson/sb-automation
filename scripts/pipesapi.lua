--Global helper functions
function acceptPipeRequestAt(pipeName, position, lookingFor)
  if pipes == nil or pipes.nodes[pipeName] == nil then return false end
  
  local entityPos = entity.position()
  local nodeTable = {}
  if lookingFor == "inbound" then
    nodeTable = pipes.nodes[pipeName].inbound
  elseif lookingFor == "outbound" then
    nodeTable = pipes.nodes[pipeName].outbound
  end
  
  if nodeTable == nil then return false end
  
  for i,node in ipairs(nodeTable) do
    local absNodePos = {entityPos[1] + node.offset[1], entityPos[2] + node.offset[2]}
    if position[1] == absNodePos[1] and position[2] == absNodePos[2] and node.acceptRequest then
      return true
    end
  end
  return false
end

--Pipes object with internal functions
pipes = {}
function pipes.init(pipeTypes)

  pipes.updateTimer = 1
  pipes.updateInterval = 1
  
  pipes.types = {}
  pipes.nodes = {} 
  pipes.nodeEntityIds = {}
  
  for _,pipeType in ipairs(pipeTypes) do
  pipes.types[pipeType.pipeName] = pipeType
  end
  
  for pipeName,pipeType in pairs(pipes.types) do
    pipes.nodes[pipeName] = {
      inbound = entity.configParameter(pipeType.configParameters.inbound), 
      outbound = entity.configParameter(pipeType.configParameters.outbound)
    }
    pipes.nodeEntityIds[pipeName] = {
      inbound = {}, 
      outbound = {}
    }
  end
end

function pipes.push(pipeName, nodeId, args)
  if #pipes.nodeEntityIds[pipeName].outbound[nodeId] > 0 then
    for i,entityId in ipairs(pipes.nodeEntityIds[pipeName].outbound[nodeId]) do
      return world.callScriptedEntity(entityId, pipes.types[pipeName].hooks.put, args)
    end
  end
  return false
end

function pipes.pull(pipeName, nodeId, args)
  if #pipes.nodeEntityIds[pipeName].inbound[nodeId] > 0 then
    for i,entityId in ipairs(pipes.nodeEntityIds[pipeName].inbound[nodeId]) do
      return world.callScriptedEntity(entityId, pipes.types[pipeName].hooks.get, args)
    end
  end
  return false
end

function pipes.peek(pipeName, pipeFunction, nodeId, args)
  local nodesTable = {}
  if pipeFunction == "get" then
    nodesTable = pipes.nodeEntityIds[pipeName].inbound[nodeId]
  elseif pipeFunction == "put" then 
    nodesTable = pipes.nodeEntityIds[pipeName].outbound[nodeId]
  end
  if #nodesTable > 0 then
    for i,entityId in ipairs(nodesTable) do
      return world.callScriptedEntity(entityId, pipes.types[pipeName].hooks.peek, pipeFunction, args)
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
    nodeEntities[i] = pipes.walkPipes(pipeName, pipePos, 20, lookingFor)
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
      pipes.nodeEntityIds[pipeName].inbound = pipes.getNodeEntities(pipeName, "inbound")
      --Get outbound
      pipes.nodeEntityIds[pipeName].outbound = pipes.getNodeEntities(pipeName, "outbound")
    end
    
    pipes.updateTimer = 0
  end
end

function pipes.validEntity(pipeName, entityId, position, lookingFor)
  return world.callScriptedEntity(entityId, "acceptPipeRequestAt", pipeName, position, lookingFor) and entityId ~= entity.id()
end

function pipes.checkTile(position, tileName)
  return (world.material(position, "foreground") == tileName or world.material(position, "background") == tileName)
end

function pipes.walkPipes(pipeName, startPos, length, lookingFor)
  local validEntities = {}
  
  local visitedTiles = {}
  local tilesToVisit = {{startPos[1], startPos[2]}}
  
  while #tilesToVisit > 0 do
    local newVisitTiles = {}
    for i,tile in ipairs(tilesToVisit) do
      local tileName = pipes.types[pipeName].tiles
      if pipes.checkTile({tile[1], tile[2]}, tileName) then
        if visitedTiles[tile[1]] == nil then visitedTiles[tile[1]] = {} end
        visitedTiles[tile[1]][tile[2]] = true
        
        --Inspect bordering tiles (no diagonals for now)
        local nearTiles = {}
        nearTiles[1] = {tile[1] + 1, tile[2]}
        nearTiles[2] = {tile[1], tile[2] - 1}
        nearTiles[3] = {tile[1] - 1, tile[2]}
        nearTiles[4] = {tile[1], tile[2] + 1}
        
        for i,nearTile in ipairs(nearTiles) do
          --Add them to visited
          if pipes.checkTile({nearTile[1], nearTile[2]}, tileName) and (visitedTiles[nearTile[1]] == nil or visitedTiles[nearTile[1]][nearTile[2]] == nil) then
            newVisitTiles[#newVisitTiles+1] = {nearTile[1], nearTile[2]}
          end
          
          --Add valid entities to the entity list
          local connectedObjects = world.entityLineQuery({nearTile[1] + 0.4, nearTile[2] + 0.4}, {nearTile[1] + 0.6, nearTile[2] + 0.6}, {notAnObject = false})
          if connectedObjects then
            for key,objectId in ipairs(connectedObjects) do
              local notAdded = true
              
              for i,id in ipairs(validEntities) do
                if objectId == id then notAdded = false end
              end
              if pipes.validEntity(pipeName, objectId, tile, lookingFor) and notAdded then
                validEntities[#validEntities+1] = objectId
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