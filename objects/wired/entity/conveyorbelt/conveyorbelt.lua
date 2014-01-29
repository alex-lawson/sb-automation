function init(v)
  energy.init()
  if storage.active == nil then storage.active = false end
  setActive(storage.active)
  self.workSound = entity.configParameter("workSound")
  self.moveSpeed = entity.configParameter("moveSpeed")
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
    local x,y = unpack(entity.position())
    entity.setForceRegion({x,y+1,x+4,y+1},{self.moveSpeed*entity.direction(),0})
  end
end
