function init(virtual)
  if not virtual then
    storage.state = storage.state or false
    self.nodeMap = { "top", "right", "bottom", "left" }
    checkNodes()
  end
end

function onNodeConnectionChange()
  checkNodes()
end

function onInboundNodeChange(args)
  checkNodes()
end

function checkNodes()
  if entity.getInboundNodeLevel(0) ~= storage.state then
    storage.state = entity.getInboundNodeLevel(0)
    entity.setAllOutboundNodes(false)
    if storage.state then
      local choice = math.random(0, 3)
      entity.setOutboundNodeLevel(choice, true)
      entity.setAnimationState("randState", self.nodeMap[choice + 1])
    else
      entity.setAnimationState("randState", "off")
    end
  end
end