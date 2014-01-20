function init(args)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe})
  energy.init()
  
  entity.setAnimationState("pumping", "idle")
  
  self.pumping = false
  self.pumpRate = 0.5
  self.pumpTimer = 0
end

function onInteraction(args)
  --pump liquid
end

function die()
  energy.die()
end

function main(args)
  pipes.update(entity.dt())
  energy.update()
  
  
  if entity.getInboundNodeLevel(0) then
    self.pumping = true
  else
    self.pumping = false
  end
  
  if self.pumping == false then
    entity.setAnimationState("pumping", "idle")
    entity.setAllOutboundNodes(false)
  else
    
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
        liquid[2] = 1400 --Set amount to 1400 because reasons
        pushLiquid(tarNode, liquid)
      else
        
        entity.setAllOutboundNodes(false)
        entity.setAnimationState("pumping", "error")
      end
      self.pumpTimer = 0
    end
    self.pumpTimer = self.pumpTimer + entity.dt()
  end
  
  
  
end