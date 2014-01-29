itemPipe = {
  pipeName = "item",
  nodesConfigParameter = "itemNodes",
  tiles = "metalpipe",
  hooks = {
    put = "onItemPut", --Should take whatever argument get returns
    get = "onItemGet", --Should return whatever argument you want to plug into the put hook, can take whatever argument you want like a filter or something
    peekPut = "beforeItemPut", --Should return true if object will put the item
    peekGet = "beforeItemGet" --Should return true if object will get the item
  }
}
function pushItem(nodeId, item)
  return pipes.push("item", nodeId, item)
end
function pullItem(nodeId, filter)
  return pipes.pull("item", nodeId, filter)
end
function peekPushItem(nodeId, item)
  return pipes.peekPush("item", nodeId, item)
end
function peekPullItem(nodeId, filter)
  return pipes.peekPull("item", nodeId, filter)
end

function isItemNodeConnected(nodeId)
  if pipes.nodeEntities["item"] == nil then return false end
  if #pipes.nodeEntities["item"] > 0 then
    return pipes.nodeEntities["item"]
  else
    return false
  end
end