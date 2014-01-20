function init(args)
  pipes.init({liquidPipe, itemPipe})
  energy.init()
  
  if entity.direction() < 0 then
    pipes.nodes["liquid"] = entity.configParameter("flippedLiquidNodes")
  end
  
  entity.setInteractive(true)
  
  self.conversions = {}
  --Water
  self.conversions["snow"] = {liquid = 1, material = "snow", input = 20, output = 200}
  self.conversions["slush"] = {liquid = 1, material = "slush", input = 20, output = 200}
  self.conversions["ice"] = {liquid = 1, material = "ice", input = 20, output = 200}
  self.conversions["mud"] = {liquid = 1, material = "mud", input = 20, output = 200}
  self.conversions["wetdirt"] = {liquid = 1, material = "wetdirt", input = 20, output = 200}
  --Lava
  self.conversions["magmarock"] = {liquid = 3, material = "magmarock", input = 20, output = 800}
  self.conversions["obsidian"] = {liquid = 3, material = "obsidian", input = 20, output = 800}
  --Poison
  self.conversions["sewage"] = {liquid = 4, material = "sewage", input = 20, output = 400}
  self.conversions["slime"] = {liquid = 4, material = "slime", input = 20, output = 400}
  --Tar
  self.conversions["tar"] = {liquid = 7, material = "tar", input = 20, output = 400}
  
  
  self.damageRate = entity.configParameter("damageRate")
  self.damageAmount = entity.configParameter("damageAmount")
  self.blockOffset = entity.configParameter("blockOffset")
  
  self.damageTimer = 0
  
  if storage.block == nil then storage.block = {} end
  if storage.placedBlock == nil then storage.placedBlock = {} end
  if storage.state == nil then storage.state = false end
end

function die()
  energy.die()
  ejectOre() --Temporary
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
  if storage.block[1] then
    local position = entity.position()
    if next(storage.block[3]) == nil then
      world.spawnItem(storage.block[1], {position[1] + 1.5, position[2] + 1.5}, storage.block[2])
    else
      world.spawnItem(storage.block[1], {position[1] + 1.5, position[2] + 1.5}, storage.block[2], storage.block[3])
    end
  end
end

function beforeItemPut(item, nodeId)
  if storage.block[1] == nil or storage.block[2] <= 0 then
    local acceptItem = false
    local pullFilter = {}
    for matitem,_ in pairs(self.conversions) do
      if item[1] == matitem then return true end
    end
  end
  return false
end

function onItemPut(item, nodeId)
  if storage.block[1] == nil or storage.block[2] <= 0 then
    local acceptItem = false
    local pullFilter = {}
    for matitem,conversion in pairs(self.conversions) do
      if item[1] == matitem then
        if item[2] <= conversion.input then
          storage.block = item
          return true --used whole stack
        else
          item[2] = conversion.input
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
    if storage.block[1] == nil or storage.block[2] <= 0 then
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
    
    if self.damageTimer > self.damageRate then
      if storage.placedBlock[1] == nil then
        placeBlock()
      else
        if energy.consumeEnergy() then
          local blockConversion = self.conversions[storage.placedBlock[1]]
          local liquidOut = {blockConversion.liquid, storage.placedBlock[3]}
          
          if canOutputLiquid(liquidOut) then
            if checkBlock() then
              local placePosition = blockPosition()
              world.damageTiles({placePosition}, "foreground", placePosition, "crushing", self.damageAmount)
            else
              outputLiquid(liquidOut)
              storage.block[2] = storage.block[2] - storage.placedBlock[2]
              storage.placedBlock = {}
            end
          end
        end
      end
      self.damageTimer = 0
    end
    self.damageTimer = self.damageTimer + entity.dt()
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
  if storage.block[1] then
    local blockConversion = self.conversions[storage.block[1]]
    if blockConversion then
      local placePosition = blockPosition()
      if world.placeMaterial(placePosition, "foreground", blockConversion.material) then
        local placedBlock = {}
        placedBlock[1] = storage.block[1]
        placedBlock[2] = blockConversion.input
        placedBlock[3] = blockConversion.output
        if placedBlock[2] > storage.block[2] then
          placedBlock[3] = blockConversion.output * (storage.block[2] / placedBlock[2])
          placedBlock[2] = storage.block[2]
        end
        storage.placedBlock = placedBlock
        return true
      end
    end
  end
  return false
end

function checkBlock()
  if storage.placedBlock[1] then
    local blockConversion = self.conversions[storage.placedBlock[1]]
    local placePosition = blockPosition()
    local material = world.material(placePosition, "foreground")
    if material and material == blockConversion.material then return true end
  end
  return false
end