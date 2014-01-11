function init(virtual)
  pipes.init({itemPipe})
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
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