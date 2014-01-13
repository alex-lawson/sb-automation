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
  
  if self.timer > self.pickupCooldown and (isItemOutboundConnected(1) or isItemOutboundConnected(2)) then
    local itemDropList = findItemDrops()
    if #itemDropList > 0 then
      --world.logInfo(itemDropList)
      
      for i, itemId in ipairs(itemDropList) do
        if not self.ignoreIds[itemId] then
          local item = world.takeItemDrop(itemId)

          if item then
            outputItem(item)
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

  -- failed to push item
  if not result then
    ejectItem(item)
  end
end

function ejectItem(item)
  local itemDropId
  if next(item[3]) == nil then
    itemDropId = world.spawnItem(item[1], self.dropPoint, item[2])
  else
    itemDropId = world.spawnItem(item[1], self.dropPoint, item[2], item[3])
  end
  self.ignoreIds[itemDropId] = true

  -- world.logInfo("ejected item with id %s", itemDropId)
  -- world.logInfo(item)
end