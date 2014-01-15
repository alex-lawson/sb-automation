function init(args)

  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
end

function output(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      entity.setAnimationState("debugState", "on")
    else
      entity.setAnimationState("debugState", "off")
    end
  end
end

function main(args)
  if entity.getInboundNodeLevel(0) then
    output(true)
  else
    output(false)
  end
end