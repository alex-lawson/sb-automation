function init(args)  
  entity.setInteractive(true)
  if args == false then
    pipes.init({liquidPipe})
    local initInv = entity.configParameter("initialInventory")
    if initInv and storage.liquid == nil then
      storage.liquid = initInv
    end
    
    entity.scaleGroup("liquid", {1, 0})
    self.liquidMap = {}
    self.liquidMap[1] = "water"
    self.liquidMap[3] = "lava"
    self.liquidMap[4] = "poison"
    self.liquidMap[6] = "juice"
    self.liquidMap[7] = "tar"
    
    self.capacity = entity.configParameter("liquidCapacity")
    self.pushAmount = entity.configParameter("liquidPushAmount")
    self.pushRate = entity.configParameter("liquidPushRate")
    
    if storage.liquid == nil then storage.liquid = {} end
    
    self.pushTimer = 0
  end
end

function die()
  local position = entity.position()
  if storage.liquid[1] ~= nil then
    world.spawnItem("liquidtank", {position[1] + 1.5, position[2] + 1}, 1, {initialInventory = storage.liquid})
  else
    world.spawnItem("liquidtank", {position[1] + 1.5, position[2] + 1}, 1)
  end
end


function onInteraction(args)
  local liquid = self.liquidMap[storage.liquid[1]]
  local count = storage.liquid[2]
  local capacity = self.capacity
  local itemList = ""
  
  if liquid == nil then liquid = "other" end
  if count ~= nil then 
    return { "ShowPopup", { message = "^white;Holding ^green;" .. count ..
      "^white; / ^green;" .. capacity ..
      "^white; units of liquid ^green;" .. liquid
    }}
  else
    return { "ShowPopup", { message = "Tank is empty."}}
  end
end

function main(args)
  pipes.update(entity.dt())
  
  local liquidState = self.liquidMap[storage.liquid[1]]
  if liquidState then
    entity.setAnimationState("liquid", liquidState)
  else
    entity.setAnimationState("liquid", "other")
  end
  
  if storage.liquid[2] then
    local liquidScale = storage.liquid[2] / self.capacity
    entity.scaleGroup("liquid", {1, liquidScale})
  else
    entity.scaleGroup("liquid", {1, 0})
  end
  
  if self.pushTimer > self.pushRate and storage.liquid[2] ~= nil then
    local pushedLiquid = {storage.liquid[1], storage.liquid[2]}
    if storage.liquid[2] > self.pushAmount then pushedLiquid[2] = self.pushAmount end
    for i=1,2 do
      if entity.getInboundNodeLevel(i-1) and pushLiquid(i, pushedLiquid) then
        storage.liquid[2] = storage.liquid[2] - pushedLiquid[2]
        break;
      end
    end
    self.pushTimer = 0
  end
  self.pushTimer = self.pushTimer + entity.dt()
  
  clearLiquid()
end

function clearLiquid()
  if storage.liquid[2] ~= nil and storage.liquid[2] == 0 then
    storage.liquid = {}
  end
end

function onLiquidPut(liquid, nodeId)
  if storage.liquid[1] == nil then
    storage.liquid = liquid
    return true
  elseif liquid[1] == storage.liquid[1] then
    local excess = 0
    local newLiquid = {liquid[1], storage.liquid[2] + liquid[2]}
    
    if newLiquid[2] > self.capacity then 
      excess = newLiquid[2] - self.capacity
      newLiquid[2] = self.capacity
    end
    storage.liquid = newLiquid
    
    --Try to push excess liquid
    if excess > 0 then return pushLiquid(2, {newLiquid[1], excess}) end
    return true
  end
  return false
end

function beforeLiquidPut(liquid, nodeId)
  if storage.liquid[1] == nil then
    return true
  elseif liquid[1] == storage.liquid[1] then
    local excess = 0
    local newLiquid = {liquid[1], storage.liquid[2] + liquid[2]}
    
    if newLiquid[2] > self.capacity then 
      excess = newLiquid[2] - self.capacity
    end
    
    if excess == liquid[2] then return peekPushLiquid(2, {newLiquid[1], excess}) end
    return true
  end
  return false
end

function onLiquidGet(liquid, nodeId)
  if storage.liquid[1] ~= nil and (liquid == nil or liquid[1] == storage.liquid[1]) then
    local returnLiquid = {storage.liquid[1], self.pushAmount}
    if returnLiquid[2] > storage.liquid[2] then returnLiquid[2] = storage.liquid[2] end
    if liquid ~= nil and returnLiquid[2] > liquid[2] then returnLiquid[2] = liquid[2] end
    
    storage.liquid[2] = storage.liquid[2] - returnLiquid[2]
    return returnLiquid
  end
  return false
end

function beforeLiquidGet(liquid, nodeId)
  if storage.liquid[1] ~= nil and (liquid == nil or liquid[1] == storage.liquid[1]) then
    local returnLiquid = {storage.liquid[1], self.pushAmount}
    if returnLiquid[2] > storage.liquid[2] then returnLiquid[2] = storage.liquid[2] end
    if liquid ~= nil and returnLiquid[2] > liquid[2] then returnLiquid[2] = liquid[2] end
    return returnLiquid
  end
  return false
end
