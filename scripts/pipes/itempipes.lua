itemPipe = {
  pipeName = "item",
  nodesConfigParameter = "itemNodes",
  tiles = {"sewerpipe", "cleanpipe"},
  hooks = {
    put = "onItemPut", --Should take whatever argument get returns
    get = "onItemGet", --Should return whatever argument you want to plug into the put hook, can take whatever argument you want like a filter or something
    peekPut = "beforeItemPut", --Should return true if object will put the item
    peekGet = "beforeItemGet" --Should return true if object will get the item
  }
}

--- Pushes item to another object
-- @param nodeId the node to push from
-- @param item the item to push, specified as map {name = "itemname", count = 1, data = {}}
-- @returns true if whole stack was pushed, number amount of items taken if stack was partly taken, false/nil if fail
function pushItem(nodeId, item)
  local pushResult = pipes.push("item", nodeId, item)
  if pushResult ~= true and next(pipes.virtualNodes["item"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["item"][nodeId]) do
      local nodePos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      if world.spawnItem(item.name, nodePos, item.count, item.data.__content) then 
        pushResult = true
        break 
      end
    end
  end
  return pushResult
end

--- Pulls item from another object
-- @param nodeId the node to pull to
-- @param filter an array of filters to specify what items to return and how many {itemname = {minAmount,maxAmount}, otherItem = {minAmount,maxAmount}}
-- @returns item if successful, false/nil if unsuccessful
function pullItem(nodeId, filter)
  local pullResult =  pipes.pull("item", nodeId, filter)


  --If pull from entities failed, use vnodes
  if not pullResult and next(pipes.virtualNodes["item"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["item"][nodeId]) do
      local nodePos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      local itemDropList = world.itemDropQuery(nodePos, 1)

      for i, itemId in ipairs(itemDropList) do
        local itemName = world.entityName(itemId)

        if filter and filter[itemName] then
          local item = world.takeItemDrop(itemId)
          local returnCount = item.count - filter[itemName][2]

          if item.count >= filter[itemName][1] then
            if returnCount > 0 then
              item.count = filter[itemName][2]
              returnItem(nodePos, item, returnCount)
            end

            return item
          else
              returnItem(nodePos, item, item.count)
          end
        elseif not filter then
          local item = world.takeItemDrop(itemId)
          if item then return item end
        end
      end
    end
  end
end

--- Peeks an item push, does not perform the push
-- @param nodeId the node to push from to
-- @param item the item to push, specified as map {name = "itemname", count = 1, data = {}}
-- @returns true if the item can be pushed, false if item cannot be pushed
function peekPushItem(nodeId, item)
  local pushResult =  pipes.peekPush("item", nodeId, item)
  if pushResult ~= true and next(pipes.virtualNodes["item"][nodeId]) then pushResult = true end
  return pushResult;
end

--- Peeks an item pull, does not perform the pull
-- @param nodeId the node to pull to
-- @param filter an array of filters to specify what items to return and how many {{itemname = {minAmount,maxAmount}}, {otherItem = {minAmount,maxAmount}}}
-- @returns item if successful, false/nil if unsuccessful
function peekPullItem(nodeId, filter)
  local pullResult = pipes.peekPull("item", nodeId, filter)

  --If pull from entities failed, use vnodes
  if not pullResult and next(pipes.virtualNodes["item"][nodeId]) then
    for _,vNode in ipairs(pipes.virtualNodes["item"][nodeId]) do
      local nodePos = {vNode.pos[1] + 0.5, vNode.pos[2] + 0.5}
      local itemDropList = world.itemDropQuery(nodePos, 1)

      for i, itemId in ipairs(itemDropList) do
        local itemName = world.entityName(itemId)

        if filter and filter[itemName] then
          local item = world.takeItemDrop(itemId)
          local returnCount = item.count - filter[itemName][2]

          if item.count >= filter[itemName][1] then
            if returnCount > 0 then
              returnItem(nodePos, item, item.count)
              item.count = filter[itemName][2]
            end

            return item
          else
              returnItem(nodePos, item, item.count)
          end
        elseif not filter then
          local item = world.takeItemDrop(itemId)
          if item then
            returnItem(nodePos, item, item.count)
            return item 
          end
        end
      end
    end
  end
end

function returnItem(pos, item, returnCount)
  world.spawnItem(item.name, pos, returnCount, item.data.__content)
end

function isItemNodeConnected(nodeId)
  if pipes.nodeEntities["item"] == nil or pipes.nodeEntities["item"][nodeId] == nil then return false end
  if next(pipes.nodeEntities["item"][nodeId]) then
    return pipes.nodeEntities["item"][nodeId]
  else
    if next(pipes.virtualNodes["item"][nodeId]) then
      return pipes.virtualNodes["item"][nodeId]
    end
    return false
  end
end

function filterItems(filter, items)
  if filter then
    for i,item in ipairs(items) do
      if filter[item.name] and item.count >= filter[item.name][1]then
        if item.count <= filter[item.name][2] then
          return item, i
        else
          return {name = item.name, count = filter[item.name][2], data = item.data}, i
        end
      end
    end
  else
    return items[1], 1
  end
end