function main()
  sortItems()
end

function sortItems()
  local contents = world.containerTakeAll(entity.id())
  local sortItems = {}
  for key, item in pairs(contents) do
    item.sortString = world.itemType(item.name)..item.name
    sortItems[#sortItems + 1] = item
  end
  if #sortItems > 0 then
    table.sort(sortItems, compareItems)
    for i, item in ipairs(sortItems) do
      world.containerAddItems(entity.id(), item)
    end
  end
end

function compareItems(a, b)
  return a.sortString < b.sortString
end