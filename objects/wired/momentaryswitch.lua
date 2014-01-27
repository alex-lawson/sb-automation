function init(args)
  entity.setInteractive(true)
  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
  if storage.timer == nil then
    storage.timer = 0
  end
  self.interval = entity.configParameter("interval")
end

function onInteraction(args)
  if storage.state == false then
    output(true)
  end

  entity.playSound("onSounds");
  storage.timer = self.interval
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    entity.setAllOutboundNodes(state)
    if state then
      entity.setAnimationState("switchState", "on")
      entity.playSound("onSounds");
    else
      entity.setAnimationState("switchState", "off")
      entity.playSound("offSounds");
    end
  else
  end
end

function main()
  if storage.timer > 0 then
    storage.timer = storage.timer - 1

    if storage.timer == 0 then
      output(false)
    end
  end
end
