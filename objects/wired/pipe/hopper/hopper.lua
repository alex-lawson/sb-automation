function init(virtual)
  if not virtual then
    pipes.init({itemPipe})
  end
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())

  local itemDropList = findItemDrops()
  if #itemDropList > 0 then
    world.logInfo(itemDropList)
    local itemList = {}
    for i, itemId in ipairs(itemDropList) do
      itemList[i] = world.takeItemDrop(itemId)
    end
    world.logInfo(itemList)

    if #itemList > 0 then
      local result = pushItem(1, itemList)
      world.logInfo(result)
    end
  end
end

function findItemDrops()
  local pos = entity.position()
  return world.itemDropQuery(pos, {pos[1] + 2, pos[2] + 1})
end