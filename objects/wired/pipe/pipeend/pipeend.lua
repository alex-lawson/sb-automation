function init(virtual) 
  pipes.init({liquidPipe})
  
  self.usedNode = 0
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
    local pipeDirections = pipes.getPipeTileData("liquid", tilePos, "foreground", checkDirs[i])
    if pipeDirections then
      entity.rotateGroup("pipe", angle)
      self.usedNode = i + 1
    end
  end
  
  self.convertLiquid = entity.configParameter("liquidConversions")
end

function convertEndlessLiquid(liquid)
  for _,liquidTo in ipairs(self.convertLiquid) do
    if liquid[1] == liquidTo[1] then
      liquid[1] = liquidTo[2]
      break
    end
  end
  return liquid
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
    getLiquid = world.destroyLiquid(liquidPos)
    getLiquid = convertEndlessLiquid(getLiquid)
    return getLiquid
  end
  return false
end

function onLiquidPut(liquid, nodeId)
  local position = entity.position()
  local liquidPos = {position[1] + 0.5, position[2] + 0.5}
  if canPutLiquid(liquid, nodeId) then
    local curLiquid = world.liquidAt(liquidPos)
    if curLiquid then liquid[2] = liquid[2] + curLiquid[2] end
    world.spawnLiquid(liquidPos, liquid[1], liquid[2])
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
