function init(args)
  entity.setInteractive(true)

  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end

  if storage.triggered == nil then
    storage.triggered = false
  end
end

function onInteraction(args)
  output(not storage.state)
end

function onInboundNodeChange(args)
  checkInboundNodes()
end

function onNodeConnectionChange(args)
  checkInboundNodes()
end

function checkInboundNodes()
  if entity.inboundNodeCount() > 0 and entity.getInboundNodeLevel(0) then
    output(not storage.state)
  end
end

function output(state)
  storage.state = state
  if state then
    entity.setAnimationState("switchState", "on")
    entity.playSound("onSounds");
    entity.setAllOutboundNodes(true)
  else
    entity.setAnimationState("switchState", "off")
    entity.playSound("offSounds");
    entity.setAllOutboundNodes(false)
  end
end