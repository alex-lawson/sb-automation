--Global helper functions
function hasLiquidInbound()
  if self.pipes.inboundLiquidNodes ~= nil then
    return #self.pipes.inboundLiquidNodes
  end
  return nil
end

function hasLiquidOutbound()
  if self.pipes.outboundLiquidNodes ~= nil then
    return #self.pipes.outboundLiquidNodes
  end
  return nil
end

function pushLiquid(node, liquidType, amount)
  if #self.pipes.outboundEntityIds[node] > 0 then
    for i,entityId in ipairs(self.pipes.outboundEntityIds[node]) do
      if world.callScriptedEntity(entityId, "hasLiquidInbound", liquidType, amount) then
        return world.callScriptedEntity(entityId, "putLiquid", liquidType, amount)
      end
    end
  end
  return false
end

function pullLiquid(node)
  if #self.pipes.inboundEntityIds[node] > 0 then
    for i,entityId in ipairs(self.pipes.inboundEntityIds[node]) do
      if world.callScriptedEntity(entityId, "hasLiquidOutbound", liquidType, amount) then
        return world.callScriptedEntity(entityId, "getLiquid", liquidType, amount)
      end
    end
  end
  return false
end

--Pipes object with internal functions
liquidPipes = {}

function liquidPipes.create()
  local self = {}
  
  self.updateTimer = 0
  self.updateInterval = 1
  
  self.inboundLiquidNodes = entity.configParameter("liquidInboundNodes")
  self.outboundLiquidNodes = entity.configParameter("liquidOutboundNodes")
  
  --Will temporarily use wire nodes
  function self.getInboundEntities()
    local nodeEntities = {}
    for i,nodeId in ipairs(self.inboundLiquidNodes) do
      nodeEntities[i] = entity.getInboundNodeIds(nodeId)
    end
    return nodeEntities
  end
  
  --Will temporarily use wire nodes
  function self.getOutboundEntities()
    local nodeEntities = {}
    for i,nodeId in ipairs(self.outboundLiquidNodes) do
      nodeEntities[i] = entity.getOutboundNodeIds(nodeId)
    end
    return nodeEntities
  end
  
  function self.update(dt)
    self.updateTimer = self.updateTimer + dt
    
    if self.updateTimer >= self.updateInterval then
      self.inboundEntityIds = self.getInboundEntities()
      self.outboundEntityIds = self.getOutboundEntities()
      self.updateTimer = 0
    end
  end
  
  self.inboundEntityIds = self.getInboundEntities()
  self.outboundEntityIds = self.getOutboundEntities()
  
  return self
end





