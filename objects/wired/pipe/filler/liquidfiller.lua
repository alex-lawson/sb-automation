function init(args)
  if args == false then
    pipes.init({liquidPipe, itemPipe})
    energy.init()
    
    if entity.direction() < 0 then
      pipes.nodes["liquid"] = entity.configParameter("flippedLiquidNodes")
      pipes.nodes["item"] = entity.configParameter("flippedItemNodes")
    end
    
    entity.setInteractive(true)
    
    self.conversions = entity.configParameter("liquidConversions")
    self.energyRate = entity.configParameter("energyConsumptionRate")

    self.fillInterval = entity.configParameter("fillInterval")
    self.fillTimer = 0
    
    if storage.state == nil then storage.state = false end
  end
end

function die()
  energy.die()
end

function onInboundNodeChange(args)
  storage.state = args.level
  if storage.state then entity.setAnimationState("fillstate", "on") end
end

function onNodeConnectionChange()
  storage.state = entity.getInboundNodeLevel(0)
  if storage.state then entity.setAnimationState("fillstate", "on") end
end

function onInteraction(args)
  --pump liquid
  if entity.isInboundNodeConnected(0) == false then
    storage.state = not storage.state
  if storage.state then entity.setAnimationState("fillstate", "on") end
  end
end

function beforeItemPut(item, nodeId)
  if storage.block.name == nil or storage.block.count <= 0 then
    local acceptItem = false
    local pullFilter = {}
    for matitem,_ in pairs(self.conversions) do
      if item.name == matitem then return true end
    end
  end
  return false
end

function onItemPut(item, nodeId)
  if storage.block.name == nil or storage.block.count <= 0 then
    local acceptItem = false
    local pullFilter = {}
    for matitem,conversion in pairs(self.conversions) do
      if item.name == matitem then
        if item.count <= conversion.input then
          storage.block = item
          return true --used whole stack
        else
          item.count = conversion.input
          storage.block = item
          return conversion.input --return amount used
        end
      end
    end
  end
  return false
end

function main(args)
  pipes.update(entity.dt())
  energy.update()
  
  if storage.state then
    --Pull item if we don't have any
    if self.fillTimer > self.fillInterval then

      local pullFilter = {}
      for liquidId,conversion in pairs(self.conversions) do
        pullFilter[tostring(liquidId)] = {conversion[2], conversion[2]}
      end
      local pulledLiquid = peekPullLiquid(1, pullFilter)
      if pulledLiquid then
        local newCapsule = fillCapsule(pulledLiquid)
        if newCapsule and  energy.consumeEnergy(10) then
          pullLiquid(1, pullFilter)
          pushItem(1, newCapsule)
          entity.setAnimationState("fillstate", "work")
        else
          entity.setAnimationState("fillstate", "on")
        end
      else
        entity.setAnimationState("fillstate", "on")
      end
      self.fillTimer = 0
    end
    self.fillTimer = self.fillTimer + entity.dt()
  else
    entity.setAnimationState("fillstate", "off")
  end
end

function fillCapsule(liquid)
  if self.conversions[liquid[1]] and liquid[2] == self.conversions[liquid[1]][2] then
    local capsule = {name = self.conversions[liquid[1]][1], count = 1, data = {}}
    if peekPushItem(1, capsule) == true then return capsule end
  end
  return false
end