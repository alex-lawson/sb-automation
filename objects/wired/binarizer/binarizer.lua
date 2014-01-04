function init(virtual)
  if not virtual then
    
    -- if storage.state == nil then
    --   storage.state = false
    -- end
    throughput()

    updateAnimationState()
  end
end

function onInboundNodeChange(args)
  throughput()
end

function onNodeConnectionChange()
  throughput()
end

function throughput()
  storage.state = entity.getInboundNodeLevel(0)
  entity.setOutboundNodeLevel(0, storage.state)
end

function updateAnimationState()
  if entity.direction() == 1 then
    entity.setAnimationState("flipState", "default")
  else
    entity.setAnimationState("flipState", "flipped")
  end
end