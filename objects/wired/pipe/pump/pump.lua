function init(virtual)
  if virtual == false then
    entity.setInteractive(true)
    
    pipes.init({liquidPipe})
    energy.init()
    
    entity.setAnimationState("pumping", "idle")
    
    self.pumping = false
    self.pumpRate = entity.configParameter("pumpRate")
    self.pumpTimer = 0
    
    if storage.state == nil then storage.state = false end
  end
end

function onInboundNodeChange(args)
  storage.state = args.level
end

function onNodeConnectionChange()
  storage.state = entity.getInboundNodeLevel(0)
end

function onInteraction(args)
  --pump liquid
  if entity.isInboundNodeConnected(0) == false then
    storage.state = not storage.state
  end
end

function die()
  energy.die()
end

function main(args)
  pipes.update(entity.dt())
  energy.update()
  
  if storage.state then
    local srcNode
    local tarNode
    if entity.direction() == 1 then
      srcNode = 1
      tarNode = 2
    else
      srcNode = 2
      tarNode = 1
    end
    
    if self.pumpTimer > self.pumpRate then
      local canGetLiquid = peekPullLiquid(srcNode)
      local canPutLiquid = peekPushLiquid(tarNode, canGetLiquid)

      if canGetLiquid and canPutLiquid and energy.consumeEnergy() then
        entity.setAnimationState("pumping", "pump")
        entity.setAllOutboundNodes(true)
        
        local liquid = pullLiquid(srcNode)
        pushLiquid(tarNode, liquid)
      else
        entity.setAllOutboundNodes(false)
        entity.setAnimationState("pumping", "error")
      end
      self.pumpTimer = 0
    end
    self.pumpTimer = self.pumpTimer + entity.dt()
  else
    entity.setAnimationState("pumping", "idle")
    entity.setAllOutboundNodes(false)
  end
  
  
  
end