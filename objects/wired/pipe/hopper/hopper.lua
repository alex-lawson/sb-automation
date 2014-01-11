function init(virtual)
  if not virtual then
    pipes.init({itemPipe})
  end
  
  self.timer = 0
  self.pickupCooldown = 1
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
  
  if self.timer > self.pickupCooldown and (isItemOutboundConnected(1) or isItemOutboundConnected(2)) then
    local itemDropList = findItemDrops()
    if #itemDropList > 0 then
      --world.logInfo(itemDropList)
      
      for i, itemId in ipairs(itemDropList) do
        local item = world.takeItemDrop(itemId)

        if item then
          -- try to push to node 1
          local result = pushItem(1, item)

          -- try to push to node 2
          if not result then
            result = pushItem(2, item)
          end

          -- failed to push item
          if not result then
            ejectItem(item)
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

function ejectItem(item)
  world.logInfo("Something went wrong! This item is lost forever:")
  world.logInfo(item)
  --TODO: actually eject item (though this should be rare/impossible)
end