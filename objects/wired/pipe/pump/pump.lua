function init(args)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe})
  
  entity.setAnimationState("pumping", "idle")
  
  self.pumping = false
  self.pumpRate = 0.5
  self.pumpTimer = 0
end

function onInteraction(args)
  --pump liquid
end

function main(args)
  pipes.update(entity.dt())
  
  
  if entity.getInboundNodeLevel(0) then
    self.pumping = true
  else
    self.pumping = false
  end
  
  if self.pumping == false then
    entity.setAnimationState("pumping", "idle")
    entity.setAllOutboundNodes(false)
  else
    
    
    if self.pumpTimer > self.pumpRate then

      local canGetLiquid = peekPullLiquid(1)
      local canPutLiquid = peekPushLiquid(1, canGetLiquid)
      
      if canGetLiquid and canPutLiquid then
      
        entity.setAnimationState("pumping", "pump")
        entity.setAllOutboundNodes(true)
        
        local liquid = pullLiquid(1)
        liquid[2] = 1400 --Set amount to 1400 because reasons
        pushLiquid(1, liquid)
      else
        
        entity.setAllOutboundNodes(false)
        entity.setAnimationState("pumping", "error")
      end
      self.pumpTimer = 0
    end
    self.pumpTimer = self.pumpTimer + entity.dt()
  end
  
  
  
end