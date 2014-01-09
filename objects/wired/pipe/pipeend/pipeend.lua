function init(virtual)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe,itemPipe})
  
  self.acceptAmount = 1400
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function onLiquidGet(liquid)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local liquid = world.liquidAt(liquidPos)
  
  if liquid then
    world.spawnProjectile("destroyliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100})
  end
  return liquid
end

function onLiquidPut(liquid)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2]}
  world.spawnProjectile("createliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100, actionOnReap = { {action = "liquid", quantity = liquid[2], liquidId = liquid[1]}}})
end

function onLiquidPeek(pipeFunction, liquid)
  if pipeFunction == "put" then
  
    return true
    
  elseif pipeFunction == "get" then
  
    local position = entity.position()
    local liquidPos = {position[1] + 0.5, position[2] + 0.5}
    local liquid = world.liquidAt(liquidPos)
    
    if liquid then
      return liquid
    end
    
  end
  
  return false
end

function onItemGet(filter)
  local position = entity.position()
  local nearbyDroppedItems = world.itemDropQuery({position[1] + 0.5, position[2] - 0.5}, 2)
  local itemList = {}
  for i, entityId in ipairs(nearbyDroppedItems) do
    if world.entityExists(entityId) then
      local itemDescription = world.takeItemDrop(entityId)
      if itemDescription then
        world.logInfo("Taking item %s", itemDescription[3])
        itemList[#itemList+1] = itemDescription
      end
    end
  end
  return itemList
end

function onItemPut(itemList)
  local position = entity.position()
  for _, item in pairs(itemList) do
    world.logInfo("Putting item %s", item[3])
    if next(item[3]) == nil then 
      world.spawnItem(item[1], {position[1] + 0.5, position[2] - 0.5}, item[2])
    else
      world.spawnItem(item[1], {position[1] + 0.5, position[2] - 0.5}, item[2], item[3])
    end
  end
  return true
end

function onItemPeek(pipeFunction, args)
  if pipeFunction == "put" then
  
    return true
    
  elseif pipeFunction == "get" then
  
    local position = entity.position()
    local nearbyDroppedItems = world.itemDropQuery({position[1] + 0.5, position[2] - 0.5}, 2)
    return nearbyDroppedItems
    
  end
  return false
end