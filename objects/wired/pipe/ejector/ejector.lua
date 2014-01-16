function init(virtual)
  if not virtual then
    pipes.init({itemPipe})

    self.dropPoint = {entity.position()[1] + 0.5, entity.position()[2] - 0.75}
  end
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
  
  --Pull items
  local pulledItem = pullItem(1)
  if pulledItem then
    if next(pulledItem[3]) == nil then 
      world.spawnItem(pulledItem[1], self.dropPoint, pulledItem[2])
    else
      world.spawnItem(pulledItem[1], self.dropPoint, pulledItem[2], pulledItem[3])
    end
  end
  
end

function beforeItemPut(item, nodeId)
  return true
end

function onItemPut(item, nodeId)
  --world.logInfo(item)
  --world.logInfo(nodeId)
  if item then
    local position = entity.position()
    --world.logInfo("Putting item %s", item[1])
    if next(item[3]) == nil then 
      world.spawnItem(item[1], self.dropPoint, item[2])
    else
      world.spawnItem(item[1], self.dropPoint, item[2], item[3])
    end
    return true
  end
  
  return false
end