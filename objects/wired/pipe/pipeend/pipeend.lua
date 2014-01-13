function init(virtual)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe})
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end

function canGetLiquid(liquid)
  --Only get liquid if the pipe is emerged in liquid
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local liquid = world.liquidAt(liquidPos)
  
  if liquid then
    return liquid
  end
  return false
end

function canPutLiquid(liquid)
  --Always put liquid. ALWAYS.
  return true
end

function onLiquidGet(liquid)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local liquid = world.liquidAt(liquidPos)
  if liquid then
    world.spawnProjectile("destroyliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100})
    return liquid
  end
  return false
end

function onLiquidPut(liquid)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  if canPutLiquid(liquid) then
    world.spawnProjectile("createliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100, actionOnReap = { {action = "liquid", quantity = liquid[2], liquidId = liquid[1]}}})
    return true
  else
    return false
  end
end

function beforeLiquidGet(liquid)
  return canGetLiquid(liquid)
end

function beforeLiquidPut(liquid)
  return canPutLiquid(liquid)
end
