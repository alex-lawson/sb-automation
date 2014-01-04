function init(args)
  entity.setInteractive(true)
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)

end

function getLiquid()
  local position = entity.position()
  local liquid = world.liquidAt(position)
  
  if liquid then
    world.spawnProjectile("destroyliquid", {entity.position()[1] + 0.5, entity.position()[2] - 0.5}, entity.id(), {0, 0}, false, {})
  end
  return liquid
end

function putLiquid(liquidBlock)
  local position = entity.position()
  position[2] = position[2] - 1
  world.spawnProjectile("createliquid", {entity.position()[1] + 0.5, entity.position()[2] - 0.5}, entity.id(), {0, 1}, false, {})
end