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
  
  if self.timer > self.pickupCooldown then
    local itemDropList = findItemDrops()
    if #itemDropList > 0 then
      world.logInfo(itemDropList)
      
      for i, itemId in ipairs(itemDropList) do
        item = world.takeItemDrop(itemId)
        local result = pushItem(1, item)
        world.logInfo(result)
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