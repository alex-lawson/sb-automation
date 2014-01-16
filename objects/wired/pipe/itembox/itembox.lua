function init(args)
  entity.setInteractive(true)
  
  if args == false then
    pipes.init({itemPipe})
    storageApi.init(3, 16, true)
    entity.scaleGroup("invbar", {1, 1})
    
    if entity.direction() < 0 then
      entity.setAnimationState("flipped", "left")
    end
    
    local initInv = entity.configParameter("initialInventory")
    if initInv then
      storage.sApi = initInv
    end
  end
end

function die()
  local position = entity.position()
  world.spawnItem("itembox", {position[1] + 1.5, position[2] + 1}, 1, {initialInventory = storage.sApi})
end

function main(args)
  pipes.update(entity.dt())
  
  --Scale inventory bar
  local relStorage = storageApi.getCount() / storageApi.getCapacity()
  entity.scaleGroup("invbar", {1, relStorage})
  if relStorage < 0.5 then 
    entity.setAnimationState("invbar", "low")
  elseif relStorage < 1 then
    entity.setAnimationState("invbar", "medium")
  else
    entity.setAnimationState("invbar", "full")
  end
end

function onItemPut(item, nodeId)
  if item then
    return storageApi.storeItem(item[1], item[2], item[3])
  end
  
  return false
end

function onItemGet(filter, nodeId)
  world.logInfo("filter: %s", filter)
  if filter then
    for i,item in storageApi.getIterator() do
      for _, filterString in ipairs(filter) do
        if storageApi.peekItem(i)[1] == filterString then return storageApi.returnItem(i) end
      end
    end
  else
    for i,item in storageApi.getIterator() do
      world.logInfo(i)
      return storageApi.returnItem(i)
    end
  end
  return false
end


--Generator
function main(args)
  local remainingEnergy = energyapi.currentEnergy
  for _, node in ipairs(nodes)
    local visited = {entity.id()}
    remainingEnergy = pushEnergy(node, remainingEnergy, visited) --Gives energy to the node if specified, and calls onRecieveEnergy
  end
end

--Node
function onRecieveEnergy(energy, visited)
  local remainingEnergy = energy
  for _, node in ipairs(nodes)
    visited[#visited+1] = entity.id()
    local willSend = true
    for _,visitedId in ipairs(visited) do
      if node == visitedId then willSend = false end
    end
    if willSend then
      remainingEnergy = pushEnergy(node, remainingEnergy, visited) --Gives energy to the node if specified, and calls onRecieveEnergy
    end
  end
end

--Machine using energy (this can be done internally)
function energyapi.recieveEnergy(energy, visited)
  if energy < energyapi.maxEnergy - energyapi.curEnergy then
    energyapi.curEnergy = energyapi.curEnergy + energy
  else
    energyapi.curEnergy = energyApi.
  end


end