itemPipe = {
  pipeName = "item",
  nodesConfigParameter = "itemNodes",
  tiles = {"metalpipe", "sewerpipe", "cleanpipe"},
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
  return pipes.push("item", nodeId, item)
end

--- Pulls item from another object
-- @param nodeId the node to pull to
-- @param filter an array of filters to specify what items to return and how many {itemname = {minAmount,maxAmount}, otherItem = {minAmount,maxAmount}}
-- @returns item if successful, false/nil if unsuccessful
function pullItem(nodeId, filter)
  return pipes.pull("item", nodeId, filter)
end

--- Peeks an item push, does not perform the push
-- @param nodeId the node to push from to
-- @param item the item to push, specified as map {name = "itemname", count = 1, data = {}}
-- @returns true if the item can be pushed, false if item cannot be pushed
function peekPushItem(nodeId, item)
  return pipes.peekPush("item", nodeId, item)
end

--- Peeks an item pull, does not perform the pull
-- @param nodeId the node to pull to
-- @param filter an array of filters to specify what items to return and how many {{itemname = {minAmount,maxAmount}}, {otherItem = {minAmount,maxAmount}}}
-- @returns item if successful, false/nil if unsuccessful
function peekPullItem(nodeId, filter)
  return pipes.peekPull("item", nodeId, filter)
end

function isItemNodeConnected(nodeId)
  if pipes.nodeEntities["item"] == nil or pipes.nodeEntities["item"][nodeId] == nil then return false end
  if #pipes.nodeEntities["item"][nodeId] > 0 then
    return pipes.nodeEntities["item"][nodeId]
  else
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