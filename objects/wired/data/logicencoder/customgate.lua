function init(virtual)
  if not virtual then
    storage.state = storage.state or false
    entity.setAllOutboundNodes(storage.state)
  end
end

function updateAnimationState()
  if storage.state then
    entity.setAnimationState("switchState", "on")
  else
    entity.setAnimationState("switchState", "off")
  end
end

-- function output(state)
--   if storage.state ~= state then
--     storage.state = state
--     entity.setAllOutboundNodes(state)
--     updateAnimationState()
--   end
-- end

-- function toIndex(truth)
--   if truth then
--     return 2
--   else
--     return 1
--   end
-- end

function main()
  -- if self.gates == 1 then
  --   output(self.truthtable[toIndex(entity.getInboundNodeLevel(0))])
  -- elseif self.gates == 2 then
  --   output(self.truthtable[toIndex(entity.getInboundNodeLevel(0))][toIndex(entity.getInboundNodeLevel(1))])
  -- elseif self.gates == 3 then
  --   output(self.truthtable[toIndex(entity.getInboundNodeLevel(0))][toIndex(entity.getInboundNodeLevel(1))][toIndex(entity.getInboundNodeLevel(2))])
  -- end
end
