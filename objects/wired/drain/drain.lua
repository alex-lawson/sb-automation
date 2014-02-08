function init(args)
  if not virtual then
    storage.pos = {entity.position(), {entity.position()[1] + 1, entity.position()[2]}, {entity.position()[1] - 1, entity.position()[2]}}
    if storage.state == nil then
      output(false)
    else
      output(storage.state)
    end
  end
end

-- Change Animation
function output(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      entity.setAnimationState("drainState", "on")
    else
      entity.setAnimationState("drainState", "off")
    end
  end
end

-- Removes Liquids at current position
function drain()
  if world.liquidAt(storage.pos[1])then
    world.destroyLiquid(storage.pos[1])
  end
end

function main()
  if not entity.isInboundNodeConnected(0) or entity.getInboundNodeLevel(0) then
    output(true)
    drain()
  else
    output(false)
  end
end