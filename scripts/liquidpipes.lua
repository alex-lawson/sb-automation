--Global helper functions
function hasLiquidInbound()
  if pipes.liquidInboundNodes ~= nil then
    return #pipes.liquidInboundNodes
  end
  return nil
end

function hasLiquidOutbound()
  if pipes.liquidOutboundNodes ~= nil then
    return #pipes.liquidOutboundNodes
  end
  return nil
end

function acceptLiquidRequestAt(position, lookingFor)
  local entityPos = entity.position()
  local nodeTable = {}
  if lookingFor == "liquidInbound" then
    nodeTable = pipes.liquidInboundNodes
  elseif lookingFor == "liquidOutbound" then
    nodeTable = pipes.liquidOutboundNodes
  end
  
  for i,node in ipairs(nodeTable) do
    local absNodePos = {entityPos[1] + node.offset[1], entityPos[2] + node.offset[2]}
    if position[1] == absNodePos[1] and position[2] == absNodePos[2] and node.acceptLiquid then
      return true
    end
  end
  return false
end

function acceptItemRequestAt(position, lookingFor)
  local entityPos = entity.position()
  local nodeTable = {}
  if lookingFor == "itemInbound" then
    nodeTable = pipes.itemInboundNodes
  elseif lookingFor == "itemOutbound" then
    nodeTable = pipes.itemOutboundNodes
  end
  
  for i,node in ipairs(nodeTable) do
    local absNodePos = {entityPos[1] + node.offset[1], entityPos[2] + node.offset[2]}
    if position[1] == absNodePos[1] and position[2] == absNodePos[2] and node.acceptItems then
      return true
    end
  end
  return false
end

function pushLiquid(node, liquidType, amount)
  if #pipes.liquidOutboundEntityIds[node] > 0 then
    for i,entityId in ipairs(pipes.liquidOutboundEntityIds[node]) do
      if world.callScriptedEntity(entityId, "hasLiquidInbound") then
        return world.callScriptedEntity(entityId, "putLiquid", liquidType, amount)
      end
    end
  end
  return false
end

function pullLiquid(node)
  if #pipes.liquidInboundEntityIds[node] > 0 then
    for i,entityId in ipairs(pipes.liquidInboundEntityIds[node]) do
      if world.callScriptedEntity(entityId, "hasLiquidOutbound") then
        return world.callScriptedEntity(entityId, "getLiquid", liquidType, amount)
      end
    end
  end
  return false
end

function pushItem(node, itemList)
  if #pipes.itemOutboundEntityIds[node] > 0 then
    for i,entityId in ipairs(pipes.itemOutboundEntityIds[node]) do
      if world.callScriptedEntity(entityId, "hasLiquidInbound") then
        return world.callScriptedEntity(entityId, "putItem", itemList)
      end
    end
  end
  return false
end

function pullItem(node)
  if #pipes.itemInboundEntityIds[node] > 0 then
    for i,entityId in ipairs(pipes.itemInboundEntityIds[node]) do
      if world.callScriptedEntity(entityId, "hasLiquidOutbound") then
        return world.callScriptedEntity(entityId, "getItem")
      end
    end
  end
  return false
end

--Pipes object with internal functions
pipes = {}

function pipes.init(args)

  pipes.updateTimer = 0
  pipes.updateInterval = 1
  
  pipes.liquidInboundNodes = entity.configParameter("pipeInboundNodes")
  pipes.liquidOutboundNodes = entity.configParameter("pipeOutboundNodes")
  pipes.itemInboundNodes = entity.configParameter("itemInboundNodes")
  pipes.itemOutboundNodes = entity.configParameter("itemOutboundNodes")
  
  if init == false then
    pipes.liquidInboundEntityIds = pipes.getLiquidInboundEntities()
    pipes.liquidOutboundEntityIds = pipes.getLiquidOutboundEntities()
    pipes.itemInboundEntityIds = pipes.getItemInboundEntities()
    pipes.itemOutboundEntityIds = pipes.getItemOutboundEntities()
  end
end

function pipes.getLiquidInboundEntities()
  local position = entity.position()
  local nodeEntities = {}
    for i,pipeNode in ipairs(pipes.liquidInboundNodes) do
      nodeEntities[i] = pipes.walkPipes({position[1] + pipeNode.offset[1], position[2] + pipeNode.offset[2]}, 20, "liquidOutbound")
    end
  return nodeEntities
end

function pipes.getLiquidOutboundEntities()
  local position = entity.position()
  local nodeEntities = {}
    for i,pipeNode in ipairs(pipes.liquidOutboundNodes) do
      nodeEntities[i] = pipes.walkPipes({position[1] + pipeNode.offset[1], position[2] + pipeNode.offset[2]}, 20, "liquidInbound")
    end
  return nodeEntities
end

function pipes.getItemInboundEntities()
  local position = entity.position()
  local nodeEntities = {}
    for i,pipeNode in ipairs(pipes.itemInboundNodes) do
      nodeEntities[i] = pipes.walkPipes({position[1] + pipeNode.offset[1], position[2] + pipeNode.offset[2]}, 20, "itemOutbound")
    end
  return nodeEntities
end

function pipes.getItemOutboundEntities()
  local position = entity.position()
  local nodeEntities = {}
    for i,pipeNode in ipairs(pipes.itemOutboundNodes) do
      nodeEntities[i] = pipes.walkPipes({position[1] + pipeNode.offset[1], position[2] + pipeNode.offset[2]}, 20, "itemInbound")
    end
  return nodeEntities
end

function pipes.update(dt)
  local position = entity.position()
  pipes.updateTimer = pipes.updateTimer + dt
  
  if pipes.updateTimer >= pipes.updateInterval then
    pipes.liquidInboundEntityIds = pipes.getLiquidInboundEntities()
    pipes.liquidOutboundEntityIds = pipes.getLiquidOutboundEntities()
    pipes.itemInboundEntityIds = pipes.getItemInboundEntities()
    pipes.itemOutboundEntityIds = pipes.getItemOutboundEntities()
    
    pipes.updateTimer = 0
  end
end

function pipes.validEntity(entityId, position, lookingFor)
  if lookingFor == "liquidOutbound" or lookingFor == "liquidInbound" then
    return world.callScriptedEntity(entityId, "acceptLiquidRequestAt", position, lookingFor) and entityId ~= entity.id()
  elseif lookingFor == "itemOutbound" or lookingFor == "itemInbound" then
    return world.callScriptedEntity(entityId, "acceptItemRequestAt", position, lookingFor) and entityId ~= entity.id()
  end
end
  
function pipes.walkPipes(startPos, length, lookingFor)
  local validEntities = {}
  
  local visitedTiles = {}
  local tilesToVisit = {{startPos[1], startPos[2]}}
  
  while #tilesToVisit > 0 do
    local newVisitTiles = {}
    for i,tile in ipairs(tilesToVisit) do
      if world.material({tile[1], tile[2]}, "foreground") == "metalpipe" then
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
          if world.material({nearTile[1], nearTile[2]}, "foreground") == "metalpipe" and (visitedTiles[nearTile[1]] == nil or visitedTiles[nearTile[1]][nearTile[2]] == nil) then
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
              
              if pipes.validEntity(objectId, tile, lookingFor) and notAdded then
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





