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
    peek = "onItemPeek" --Should return true if item accepts the request
  }
}
function pushItem(nodeId, itemList)
  return pipes.push("item", nodeId, itemList)
end
function pullItem(nodeId, itemFilter)
  return pipes.pull("item", nodeId, itemFilter)
end
function peekItem(nodeId, pipeFunction, itemArgs)
  return pipes.peek("item", pipeFunction, nodeId, itemArgs)
end