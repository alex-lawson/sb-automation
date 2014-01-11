function init(virtual)
  if not virtual then
    pipes.init({itemPipe})

    self.dropPoint = {entity.position()[1] + 0.5, entity.position()[2] - 0.75}
  end
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function beforeItemPut(item)
  return true
end

function onItemPut(item, nodeId)
  world.logInfo(item)
  world.logInfo(nodeId)
  if item then
    local position = entity.position()
    world.logInfo("Putting item %s", item[1])
    if next(item[3]) == nil then 
      world.spawnItem(item[1], self.dropPoint, item[2])
    else
      world.spawnItem(item[1], self.dropPoint, item[2], item[3])
    end
    return true
  end
  
  return false
end