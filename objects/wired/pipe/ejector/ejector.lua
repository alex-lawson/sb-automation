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

function beforeItemPut(item, nodeId)
  return true
end

function onItemPut(item, nodeId)
  --world.logInfo(item)
  --world.logInfo(nodeId)
  if item then
    local position = entity.position()
    --world.logInfo("Putting item %s", item[1])
    if next(item.data) == nil then 
      world.spawnItem(item.name, self.dropPoint, item.count)
    else
      world.spawnItem(item.name, self.dropPoint, item.count, item.data)
    end
    return true
  end
  
  return false
end