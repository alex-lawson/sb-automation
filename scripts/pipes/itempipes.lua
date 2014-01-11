itemPipe = {
  pipeName = "item",
  configParameters = {
    inbound = "itemInboundNodes",
    outbound = "itemOutboundNodes"
  },
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
function pullItem(nodeId, itemFilter)
  return pipes.pull("item", nodeId, filter)
end
function peekPushItem(nodeId, item)
  return pipes.peekPush("item", nodeId, item)
end
function peekPullItem(nodeId, filter)
  return pipes.peekPull("item", nodeId, filter)
end

function isItemOutboundConnected(nodeId)
  if pipes.nodeEntityIds["item"] == nil then return false end
  if #pipes.nodeEntityIds["item"].outbound[nodeId] > 0 then
    return pipes.nodeEntityIds["item"].outbound[nodeId]
  else
    return false
  end
end
function isItemInboundConnected(nodeId)
  if pipes.nodeEntityIds["item"] == nil then return false end
  if #pipes.nodeEntityIds["item"].inbound[nodeId] > 0 then
    return pipes.nodeEntityIds["item"].inbound[nodeId]
  else
    return false
  end
end