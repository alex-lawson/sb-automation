function init(args)
  entity.setInteractive(true)
  
  storage.nodeEntities = {inbound = {}, outbound = {}}
end

function getNodeIds()
  storage.nodeEntities.outbound = entity.getOutboundNodeIds(0)
  storage.nodeEntities.inbound = entity.getInboundNodeIds(0)
end

--------------------------------------------------------------------------------

function onInteraction(args)
  getNodeIds()

  if #storage.nodeEntities.outbound > 0 and #storage.nodeEntities.inbound > 0 then
    local liquid = nil
    for key,entityId in ipairs(storage.nodeEntities.inbound) do
      liquid = world.callScriptedEntity(entityId, "getLiquid")
    end
    for key,entityId in ipairs(storage.nodeEntities.outbound) do
      world.callScriptedEntity(entityId, "putLiquid", liquid)
    end
  end
end

function transferLiquidIn()
  return entity.getLiquid()
end

function transferLiquidOut(liquid)
  return entity.putLiquid(liquid)
end

--------------------------------------------------------------------------------
function main(args)

end