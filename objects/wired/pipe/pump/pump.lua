function init(virtual)
  if virtual == false then
    entity.setInteractive(true)
    pipes.init({liquidPipe})
    energy.init()

    if entity.direction() < 0 then
      pipes.nodes["liquid"] = entity.configParameter("flippedLiquidNodes")
    end

    entity.setAnimationState("pumping", "off")
    
    self.pumping = false
    self.pumpRate = entity.configParameter("pumpRate")
    self.energyConsumption = entity.configParameter("energyConsumptionRate") * self.pumpRate;
    self.pumpTimer = 0

    buildFilter()
    
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
  
  if storage.state and energy.consumeEnergy(self.energyConsumption, true) then
    if self.pumpTimer > self.pumpRate then
      entity.setAnimationState("pumping", "powered")
      local canGetLiquid = peekPullLiquid(1, self.filter)
      local canPutLiquid = peekPushLiquid(2, canGetLiquid)

      if canGetLiquid and canPutLiquid and energy.consumeEnergy(self.energyConsumption) then
        entity.setAnimationState("pumping", "pump")
        entity.setAllOutboundNodes(true)
        
        local liquid = pullLiquid(1, self.filter)
        pushLiquid(2, liquid)
      else
        entity.setAllOutboundNodes(false)
        if canGetLiquid then
          entity.setAnimationState("pumping", "error")
        end
      end
      self.pumpTimer = self.pumpTimer - self.pumpRate
    end
    self.pumpTimer = self.pumpTimer + entity.dt()
  else
    entity.setAllOutboundNodes(false)
    if not storage.state then
      entity.setAnimationState("pumping", "off")
    elseif not energy.consumeEnergy(self.energyConsumption, true) then
      entity.setAnimationState("pumping", "unpowered")
    end
  end
end

function buildFilter()
  local pullAmount = entity.configParameter("pumpAmount")
  self.filter = {}
  for i = 0, 20 do
    self.filter[tostring(i)] = {1, pullAmount}
  end
end