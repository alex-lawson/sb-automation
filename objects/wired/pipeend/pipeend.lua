function init(args)
  self.pipes = liquidPipes.create()
  entity.setInteractive(true)
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)
  if self.pipes ~= nil then
    self.pipes.update(entity.dt())
  end
end

function getLiquid()
  local position = entity.position()
  
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local liquid = world.liquidAt(liquidPos)
  
  if liquid then
    world.spawnProjectile("destroyliquid", liquidPos, entity.id(), {0, 1}, false, {speed = 0.01})
  end
  return liquid
end

function putLiquid(liquidId, quantity)
  world.logInfo("Putting liquid")
  quantity = 1400
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2]}
  world.spawnProjectile("createliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100, actionOnReap = { {action = "liquid", quantity = quantity, liquidId = liquidId}}})
end