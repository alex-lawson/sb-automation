function init(args)
  if args == false then
    pipes.init({liquidPipe, itemPipe})
    energy.init()
    
    if entity.direction() < 0 then
      pipes.nodes["liquid"] = entity.configParameter("flippedLiquidNodes")
    end
    
    entity.setInteractive(true)
    
    self.conversions = {}
    --Water
    self.conversions["snow"] = {liquid = 1, material = "snow", input = 20, output = 1400}
    self.conversions["slush"] = {liquid = 1, material = "slush", input = 20, output = 1400}
    self.conversions["ice"] = {liquid = 1, material = "ice", input = 20, output = 1400}
    self.conversions["mud"] = {liquid = 1, material = "mud", input = 20, output = 1400}
    self.conversions["wetdirt"] = {liquid = 1, material = "wetdirt", input = 20, output = 1400}
    --Lava
    self.conversions["magmarock"] = {liquid = 3, material = "magmarock", input = 20, output = 1400}
    self.conversions["obsidian"] = {liquid = 3, material = "obsidian", input = 20, output = 1400}
    --Poison
    self.conversions["sewage"] = {liquid = 4, material = "sewage", input = 20, output = 1400}
    self.conversions["slime"] = {liquid = 4, material = "slime", input = 20, output = 1400}
    --Tar
    self.conversions["tar"] = {liquid = 7, material = "tar", input = 20, output = 1400}
    
    
    self.damageRate = entity.configParameter("damageRate")
    self.damageAmount = entity.configParameter("damageAmount")
    self.blockOffset = entity.configParameter("blockOffset")
    
    self.energyRate = entity.configParameter("energyConsumptionRate")
    
    self.damageTimer = 0
    
    if storage.block == nil then storage.block = {} end
    if storage.placedBlock == nil then storage.placedBlock = {} end
    if storage.state == nil then storage.state = false end
  end
end

function die()
  energy.die()
  
  local placePosition = blockPosition()
  local extractorBlock = world.objectQuery(placePosition, 1, {name = "extractorblock"})
  if extractorBlock and #extractorBlock > 0 then
    world.logInfo("%s", extractorBlock)
    world.callScriptedEntity(extractorBlock[1], "damageBlock", 999999) --Really Big Number
  end
  
  if storage.block[1] then
    local position = entity.position()
    if next(storage.block[3]) == nil then
      world.spawnItem(storage.block[1], {position[1] + 1.5, position[2] + 1.5}, storage.block[2])
    else
      world.spawnItem(storage.block[1], {position[1] + 1.5, position[2] + 1.5}, storage.block[2], storage.block[3])
    end
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
    if storage.block.name == nil or storage.block.count <= 0 then
      storage.block = {}
      local pullFilter = {}
      for matitem,conversion in pairs(self.conversions) do
        pullFilter[matitem] = {1, conversion.input}
      end
      local pulledItem = pullItem(1, pullFilter)
      if pulledItem then
        storage.block = pulledItem
      end
    end
    
    if storage.block.name == nil then turnOff() end
    
    
    if self.damageTimer > self.damageRate then
      if storage.placedBlock[1] == nil then
        if placeBlock() then
          entity.setAnimationState("extractState", "open")
        end
      else
        local blockConversion = self.conversions[storage.placedBlock[1]]
        local liquidOut = {blockConversion.liquid, storage.placedBlock[3]}
        
        if canOutputLiquid(liquidOut) and energy.consumeEnergy(self.energyRate * self.damageRate) then
          entity.setAnimationState("extractState", "work")
          if checkBlock() then
            local placePosition = blockPosition()
            world.callScriptedEntity(storage.blockId, "damageBlock", self.damageAmount)
          else
            outputLiquid(liquidOut)
            storage.block.count = storage.block.count - storage.placedBlock[2]
            storage.placedBlock = {}
          end
        else
          turnOff()
        end
      end
      self.damageTimer = 0
    end
    self.damageTimer = self.damageTimer + entity.dt()
  else
    turnOff()
  end
end

function turnOff()
  if checkBlock() then
    entity.setAnimationState("extractState", "error")
  else
    entity.setAnimationState("extractState", "off")
  end
end

function canOutputLiquid(liquid)
  return peekPushLiquid(1, liquid)
end

function outputLiquid(liquid)
  return pushLiquid(1, liquid)
end

function blockPosition()
  local position = entity.position()
  return {position[1] + self.blockOffset[1], position[2] + self.blockOffset[2]}
end


function placeBlock()
  if storage.block.name then
    local blockConversion = self.conversions[storage.block.name]
    if blockConversion then
      local placePosition = blockPosition()
      local placedObject = world.placeObject("extractorblock", placePosition, 1, {initState = storage.block.name})
      if placedObject then
        local placedBlock = {}
        placedBlock[1] = storage.block.name
        placedBlock[2] = blockConversion.input
        placedBlock[3] = blockConversion.output
        if placedBlock[2] > storage.block.count then
          placedBlock[3] = blockConversion.output * (storage.block.count / placedBlock[2])
          placedBlock[2] = storage.block.count
        end
        storage.placedBlock = placedBlock
        
        storage.blockId = placedObject
        return true
      end
    end
  end
  return false
end

function checkBlock()
  if storage.placedBlock[1] then
    local placePosition = blockPosition()
    local extractorBlock = world.objectQuery(placePosition, 1, {name = "extractorblock"})
    if extractorBlock and #extractorBlock == 1 then
      storage.blockId = extractorBlock[1]
      return storage.blockId
    end
  end
  storage.blockId = nil
  return false
end