liquidPipe = {
  pipeName = "liquid",
  configParameters = {
    inbound = "liquidInboundNodes",
    outbound = "liquidOutboundNodes"
  },
  tiles = "metalpipe",
  hooks = {
    put = "onLiquidPut",  --Should take whatever argument get returns
    get = "onLiquidGet", --Should return whatever argument you want to plug into the put hook, can take whatever argument you want like a filter or something
    peek = "onLiquidPeek" --Should return true if item accepts the request
  }
}
function pushLiquid(nodeId, liquid)
  return pipes.push("liquid", nodeId, liquid)
end
function pullLiquid(nodeId, liquid)
  return pipes.pull("liquid", nodeId, liquid)
end
function peekLiquid(pipeFunction, nodeId, liquid)
  return pipes.peek("liquid", pipeFunction, nodeId, liquid)
end