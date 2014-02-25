function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
    pipes.init({itemPipe})
    
    if storage.ore == nil then storage.ore = {} end
    if storage.state == nil then storage.state = false end

    self.conversions = entity.configParameter("smeltRecipes")
    
    self.smeltRate = entity.configParameter("smeltRate")
    self.smeltTimer = 0
    
    entity.setInteractive(not entity.isInboundNodeConnected(0))
  end
end

function die()
  energy.die()
  ejectOre() --Temporary
end

function onNodeConnectionChange()
  checkNodes()
  datawire.onNodeConnectionChange()
end

function onInboundNodeChange(args)
  checkNodes()
end

function checkNodes()
  local isWired = entity.isInboundNodeConnected(0)
  if isWired then
    storage.state = entity.getInboundNodeLevel(0)
  end
  entity.setInteractive(not isWired)
end

function onInteraction(args)
  if entity.isInboundNodeConnected(0) == false then
    storage.state = not storage.state
  end
end

function main()
  energy.update()
  datawire.update()
  pipes.update(entity.dt())

  if storage.state and (storage.ore.name == nil or storage.ore.count <= 0) then
    pullOre()
  end
  
  if storage.ore.name and storage.state and energy.consumeEnergy() then
    local oreConversion = self.conversions[storage.ore.name]
    local bar = {name = oreConversion[3], count = oreConversion[2], data = {}}
    
    if peekPushItem(2, bar) then 
      entity.setAnimationState("smelting", "smelt") 
    else
      entity.setAnimationState("smelting", "error")
    end
    
    if self.smeltTimer > self.smeltRate then
      if oreConversion and oreConversion[1] <= storage.ore.count and pushItem(2, bar) then
        storage.ore = {}
      end
      self.smeltTimer = 0
    end
    self.smeltTimer = self.smeltTimer + entity.dt()
  else
    if storage.state then
      entity.setAnimationState("smelting", "error")
    else
      entity.setAnimationState("smelting", "idle")
    end
  end
  
end

function pullOre() 
  storage.ore = {}
  local pullFilter = {}
  for matitem,conversion in pairs(self.conversions) do
    pullFilter[matitem] = {conversion[1], conversion[1]}
  end
  local pulledItem = pullItem(1, pullFilter)
  if pulledItem then
    storage.ore = pulledItem
  end
end

function onItemPut(item, nodeId) 
  if item and nodeId == 1 and storage.ore.name == nil then
    if self.conversions[item.name] then
      local conversion = self.conversions[item.name]
      if item.count < conversion[1] then
        return false
      elseif item.count == conversion[1] then
        storage.ore = item
        return true --used whole stack
      else
        item.count = conversion[1]
        storage.ore = item
        return conversion[1] --return amount used
      end
    end
  end
  return false
end

function beforeItemPut(item, nodeId)
  if item and nodeId == 1 and storage.ore.name == nil then
    local pullFilter = {}
    for ore,_ in pairs(self.conversions) do
      if ore == item.name then return true end
    end
  end
  return false
end

--Temporary function until itempipes api is changed to allow amount filters and returns
function ejectOre()
  local position = entity.position()
  if storage.ore.name and next(storage.ore.data) == nil then
    world.spawnItem(storage.ore.name, {position[1] + 1.5, position[2] + 1}, storage.ore.count)
  elseif storage.ore.name then
    world.spawnItem(storage.ore.name, {position[1] + 1.5, position[2] + 1}, storage.ore.count, storage.ore.data)
  end
  storage.ore = {}
end