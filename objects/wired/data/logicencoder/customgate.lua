function init(args)
  entity.setInteractive(false)
  if storage.state == nil then
    output(false)
  else
    entity.setAllOutboundNodes(storage.state)
    if storage.state then
      entity.setAnimationState("switchState", "on")
    else
      entity.setAnimationState("switchState", "off")
    end
  end
  self.gates = entity.configParameter("gates")
  self.truthtable = entity.configParameter("truthtable")
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    entity.setAllOutboundNodes(state)
    if state then
      entity.setAnimationState("switchState", "on")
    else
      entity.setAnimationState("switchState", "off")
    end
  end
end

function toIndex(truth)
  if truth then
    return 2
  else
    return 1
  end
end

function main()
  if self.gates == 1 then
    output(self.truthtable[toIndex(entity.getInboundNodeLevel(0))])
  elseif self.gates == 2 then
    output(self.truthtable[toIndex(entity.getInboundNodeLevel(0))][toIndex(entity.getInboundNodeLevel(1))])
  elseif self.gates == 3 then
    output(self.truthtable[toIndex(entity.getInboundNodeLevel(0))][toIndex(entity.getInboundNodeLevel(1))][toIndex(entity.getInboundNodeLevel(2))])
  end
end
