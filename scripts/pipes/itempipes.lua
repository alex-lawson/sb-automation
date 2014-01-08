itemPipe = {
  pipeName = "item",
  configParameters = {
    inbound = "itemInboundNodes",
    outbound = "itemOutboundNodes"
  },
  tiles = "metalpipe",
  hooks = {
    put = "putItem", --Should take whatever argument get returns
    get = "getItem", --Should return whatever argument you want to plug into the put hook, can take whatever argument you want like a filter or something
    peek = "peekItem" --Should return true if item accepts the request
  }
}
function pushItem(nodeId, itemList)
  return pipes.push("item", nodeId, itemList)
end
function pullItem(nodeId, itemFilter)
  return pipes.pull("item", nodeId, itemFilter)
end