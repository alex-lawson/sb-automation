function init(virtual)
  pipes.init({itemPipe})
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function beforeItemPut(item)
  return true
end

function onItemPut(item)
  if item then
    local position = entity.position()
    world.logInfo("Putting item %s", item[1])
    if next(item[3]) == nil then 
      world.spawnItem(item[1], {position[1] + 0.5, position[2] - 0.5}, item[2])
    else
      world.spawnItem(item[1], {position[1] + 0.5, position[2] - 0.5}, item[2], item[3])
    end
    return true
  end
  
  return false
end