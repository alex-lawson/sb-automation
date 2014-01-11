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
    peekPut = "beforeLiquidPut", --Should return true if object will put the item
    peekGet = "beforeLiquidGet" --Should return true if object will get the item
  }
}
function pushLiquid(nodeId, liquid)
  return pipes.push("liquid", nodeId, liquid)
end
function pullLiquid(nodeId, liquid)
  return pipes.pull("liquid", nodeId, liquid)
end
function peekPushLiquid(nodeId, liquid)
  return pipes.peekPush("liquid", nodeId, liquid)
end
function peekPullLiquid(nodeId, liquid)
  return pipes.peekPull("liquid", nodeId, liquid)
end

function isLiquidOutboundConnected(nodeId)
  if pipes.nodeEntityIds["liquid"] == nil then return false end
  if #pipes.nodeEntityIds["liquid"].outbound[nodeId] > 0 then
    return pipes.nodeEntityIds["liquid"].outbound[nodeId]
  else
    return false
  end
end
function isLiquidInboundConnected(nodeId)
  if pipes.nodeEntityIds["liquid"] == nil then return false end
  if #pipes.nodeEntityIds["liquid"].inbound[nodeId] > 0 then
    return pipes.nodeEntityIds["liquid"].inbound[nodeId]
  else
    return false
  end
end