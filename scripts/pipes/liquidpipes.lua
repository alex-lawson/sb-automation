liquidPipe = {
  pipeName = "liquid",
  nodesConfigParameter = "liquidNodes",
  tiles = {"sewerpipe", "cleanpipe"},
  hooks = {
    put = "onLiquidPut",  --Should take whatever argument get returns
    get = "onLiquidGet", --Should return whatever argument you want to plug into the put hook, can take whatever argument you want like a filter or something
    peekPut = "beforeLiquidPut", --Should return true if object will put the item
    peekGet = "beforeLiquidGet" --Should return true if object will get the item
  }
}

liquidConversions =  { 
  {5, 3}, 
  {2, 1} 
}

--- Pushes liquid
-- @param nodeId the node to push from
-- @param liquid the liquid to push, specified as array {liquidId, amount}
-- @returns true if successful, false if unsuccessful
function pushLiquid(nodeId, liquid)
  if not liquid then return false end

  local pushResult = pipes.push("liquid", nodeId, liquid)


  if not pushResult and next(pipes.virtualNodes["liquid"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["liquid"][nodeId]) do
      local liquidPos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      local curLiquid = world.liquidAt(liquidPos)
      if not curLiquid or curLiquid[1] == liquid[1] then
        if curLiquid then liquid[2] = liquid[2] + curLiquid[2] end
        world.spawnLiquid(liquidPos, liquid[1], liquid[2])
        pushResult = true
        break
      end
    end
  end
  return pushResult
end

--- Pulls liquid
-- @param nodeId the node to push from
-- @param filter array of filters of liquids {liquidId = {minAmount,maxAmount}, otherLiquidId = {minAmount,maxAmount}}
-- @returns liquid if successful, false if unsuccessful
function pullLiquid(nodeId, filter)
  local pullResult = pipes.pull("liquid", nodeId, filter)

  if not pullResult and next(pipes.virtualNodes["liquid"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["liquid"][nodeId]) do
      local liquidPos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      local getLiquid = canGetLiquid(filter, liquidPos)
      if pullResult == false or getLiquid[1] == pullResult[1] then
        local destroyed = world.destroyLiquid(liquidPos)
        if destroyed[2] > getLiquid[2] then
          world.spawnLiquid(liquidPos, destroyed[1], destroyed[2] - getLiquid[2])
        end
        pullResult = convertEndlessLiquid(getLiquid)
        break
      end
    end
  end
  return pullResult
end

--- Peeks a liquid push, does not go through with the transfer
-- @param nodeId the node to push from
-- @param liquid the liquid to push, specified as array {liquidId, amount}
-- @returns true if successful, false if unsuccessful
function peekPushLiquid(nodeId, liquid)
  if not liquid then return false end

  local pushResult = pipes.peekPush("liquid", nodeId, liquid)

  if not pushResult and next(pipes.virtualNodes["liquid"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["liquid"][nodeId]) do
      local liquidPos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      local curLiquid = world.liquidAt(liquidPos)
      if not curLiquid or curLiquid[1] == liquid[1] then
        pushResult = true
      end
    end
  end
  return pushResult
end

--- Peeks a liquid pull, does not go through with the transfer
-- @param nodeId the node to push from
-- @param filter array of filters of liquids {liquidId = {minAmount,maxAmount}, otherLiquidId = {minAmount,maxAmount}}
-- @returns liquid if successful, false if unsuccessful
function peekPullLiquid(nodeId, filter)
  local pullResult = pipes.peekPull("liquid", nodeId, filter)

  if not pullResult and next(pipes.virtualNodes["liquid"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["liquid"][nodeId]) do
      local liquidPos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      local getLiquid = canGetLiquid(filter, liquidPos)

      if getLiquid then
        pullResult = getLiquid
        break
      end
    end
  end
  --world.logInfo("%s", pullResult)
  return pullResult
end

function canGetLiquid(filter, position)
  local availableLiquid = world.liquidAt(position)
  if availableLiquid then
    local liquid = convertEndlessLiquid(availableLiquid)

    local returnLiquid = filterLiquids(filter, {liquid})
    --world.logInfo("(canGetLiquid) filter result: %s", returnLiquid)
    
    if returnLiquid then
      return returnLiquid
    end
  end
  return false
end

function convertEndlessLiquid(liquid)
  for _,liquidTo in ipairs(liquidConversions) do
    if liquid[1] == liquidTo[1] then
      liquid[1] = liquidTo[2]
      break
    end
  end
  return liquid
end

function isLiquidNodeConnected(nodeId)
  if pipes.nodeEntities["liquid"] == nil or pipes.nodeEntities["liquid"][nodeId] == nil then return false end
  if #pipes.nodeEntities["liquid"][nodeId] > 0 then
    return pipes.nodeEntities["liquid"][nodeId]
  else
    return false
  end
end

function filterLiquids(filter, liquids)
  if filter then
    for i,liquid in ipairs(liquids) do
      local liquidId = tostring(liquid[1])
      if filter[liquidId] and liquid[2] >= filter[liquidId][1]then
        if liquid[2] <= filter[liquidId][2] then
          return liquid, i
        else
          return {liquid[1], filter[liquidId][2]}, i
        end
      end
    end
  else
    return liquids[1], 1
  end
end