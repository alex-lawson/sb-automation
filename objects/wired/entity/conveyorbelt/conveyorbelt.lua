function init(v)
  energy.init()
  if storage.active == nil then storage.active = false end
  setActive(storage.active)
  self.workSound = entity.configParameter("workSound")
  self.moveSpeed = entity.configParameter("moveSpeed")
  self.st = 0
  onNodeConnectionChange(nil)
end

function die()
  energy.die()
end

function onNodeConnectionChange(args)
  if entity.isInboundNodeConnected(0) then
    entity.setInteractive(false)
  else
    entity.setInteractive(true)
  end
  onInboundNodeChange(args)
end

function onInboundNodeChange(args)
  if entity.isInboundNodeConnected(0) then
    setActive(entity.getInboundNodeLevel(0))
  end
end

function onInteraction(args)
  setActive(not storage.active)
end

function setActive(flag)
  storage.active = flag
  if flag then entity.setAnimationState("workState", "work")
  else entity.setAnimationState("workState", "idle") end
end

function main()
  energy.update()
  if storage.active then
    if not energy.consumeEnergy() then
      setActive(false)
      return
    end

    self.st = self.st + 1
    if self.st > 6 then 
      self.st = 0
    elseif self.st == 3 then
      entity.playImmediateSound(self.workSound)
    end
    local x1,y1 = unpack(entity.toAbsolutePosition({-2, 1}))
    local x2,y2 = unpack(entity.toAbsolutePosition({2, 1}))
    entity.setForceRegion({x1,y1,x2,y2},{self.moveSpeed*entity.direction(),0})
  end
  
end
