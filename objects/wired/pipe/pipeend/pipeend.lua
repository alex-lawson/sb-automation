function init(args)
  pipes.init()
  entity.setInteractive(true)
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function getLiquid()
  local position = entity.position()
  
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local liquid = world.liquidAt(liquidPos)
  
  if liquid then
    world.spawnProjectile("destroyliquid", liquidPos, entity.id(), {0, 1}, false, {speed = 0.01})
  end
  return liquid
end

function putLiquid(liquidId, quantity)
  world.logInfo("Putting liquid")
  quantity = 1400
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2]}
  world.spawnProjectile("createliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100, actionOnReap = { {action = "liquid", quantity = quantity, liquidId = liquidId}}})
end

function getItem()
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

function putItem(itemList)
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