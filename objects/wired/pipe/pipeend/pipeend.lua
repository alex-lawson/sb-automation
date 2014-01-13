function init(virtual)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe})
  
  self.usedNode = 0
end

--------------------------------------------------------------------------------

function onInteraction(args)

end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
  
  local position = entity.position()
  local checkDirs = {}
  checkDirs[0] = {-1, 0}
  checkDirs[1] = {0, -1}
  checkDirs[2] = {1, 0}
  checkDirs[3] = {0, 1}
  
  for i=0,3 do 
    local angle = (math.pi / 2) * i
    local tilePos = {position[1] + checkDirs[i][1], position[2] + checkDirs[i][2]}
    local pipeDirections = pipes.getPipeDirections("liquid", tilePos)
    if pipeDirections and pipes.pipesConnect(checkDirs[i], pipeDirections) then
      entity.rotateGroup("pipe", angle)
      self.usedNode = i + 1
    end
  end
  
  
end

function canGetLiquid(liquid, nodeId)
  if nodeId ~= self.usedNode then return false end
  --Only get liquid if the pipe is emerged in liquid
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local liquid = world.liquidAt(liquidPos)
  
  if liquid then
    return liquid
  end
  return false
end

function canPutLiquid(liquid, nodeId)
  if nodeId ~= self.usedNode then return false end
  
  return true
end

function onLiquidGet(liquid, nodeId)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  local getLiquid = canGetLiquid(liquid, nodeId)
  if getLiquid then
    world.spawnProjectile("destroyliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100})
    return getLiquid
  end
  return false
end

function onLiquidPut(liquid, nodeId)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  if canPutLiquid(liquid, nodeId) then
    world.spawnProjectile("createliquid", liquidPos, entity.id(), {0, -1}, false, {speed = 100, actionOnReap = { {action = "liquid", quantity = liquid[2], liquidId = liquid[1]}}})
    return true
  else
    return false
  end
end

function beforeLiquidGet(liquid, nodeId)
  return canGetLiquid(liquid, nodeId)
end

function beforeLiquidPut(liquid, nodeId)
  return canPutLiquid(liquid, nodeId)
end
