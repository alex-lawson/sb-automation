function init(virtual)
  if not virtual then
    pipes.init({itemPipe})

    self.timer = 0
    self.pickupCooldown = 0.2

    self.ignoreIds = {}
    self.dropPoint = {entity.position()[1] + 1, entity.position()[2] + 1.5}
  end
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
  
  if self.timer > self.pickupCooldown and (isItemNodeConnected(1) or isItemNodeConnected(2)) then

    --Try to push from inventory first
    local result = false;
    local items = world.containerItems(entity.id())
    for key, item in pairs(items) do
      result = pushItem(1, item) or pushItem(2, item)
      if result then
        if result ~= true then
          item.count = result --amount accepted
        end
        world.containerConsume(entity.id(), item)

        break
      end
    end

    --If inventory fails
    if not result then
      local itemDropList = findItemDrops()
      if #itemDropList > 0 then
        for i, itemId in ipairs(itemDropList) do
          if not self.ignoreIds[itemId] then
            local item = world.takeItemDrop(itemId, entity.id())
            if item then
              outputItem(item)
            end
          end
        end
      end
    end
    self.timer = 0
  end
  self.timer = self.timer + entity.dt()
end

function findItemDrops()
  local pos = entity.position()
  return world.itemDropQuery(pos, {pos[1] + 2, pos[2] + 1})
end

-- function canPushItem(item)
--   return peekPushItem(1, item) or peekPushItem(2, item)
-- end

function outputItem(item)
  -- try to push to both nodes (in a dangerous and confusing way!)
  local result = pushItem(1, item) or pushItem(2, item)
  
  -- pushed only some of the item
  if result and result ~= true then
    item.count = item.count - result
    ejectItem(item)
  end
  
  -- failed to push item
  if not result then
    ejectItem(item)
  end
end

function ejectItem(item)
  local itemDropId
  if next(item.data) == nil then
    itemDropId = world.spawnItem(item.name, self.dropPoint, item.count)
  else
    itemDropId = world.spawnItem(item.name, self.dropPoint, item.count, item.data)
  end
  self.ignoreIds[itemDropId] = true

  -- world.logInfo("ejected item with id %s", itemDropId)
  -- world.logInfo(item)
end