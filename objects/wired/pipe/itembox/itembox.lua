function init(args)
  entity.setInteractive(true)
  
  if args == false then
    pipes.init({itemPipe})
    
    local initInv = entity.configParameter("initialInventory")
    if initInv and storage.sApi == nil then
      storage.sApi = initInv
    end
    
    storageApi.init(3, 16, true)
    
    entity.scaleGroup("invbar", {1, 0})
    
    if entity.direction() < 0 then
      entity.setAnimationState("flipped", "left")
    end
    
    self.pushRate = entity.configParameter("itemPushRate")
    self.pushTimer = 0
  end
end

function die()
  local position = entity.position()
  if storageApi.getCount() == 0 then
    world.spawnItem("itembox", {position[1] + 1.5, position[2] + 1}, 1)
  else
    world.spawnItem("itembox", {position[1] + 1.5, position[2] + 1}, 1, {initialInventory = storage.sApi})
  end
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
  
  --Push out items if switched on
  if entity.getInboundNodeLevel(0) then
    if self.pushTimer > self.pushRate then
      for i,item in storageApi.getIterator() do
        pushItem(2, storageApi.returnItem(i))
        break
      end
      self.pushTimer = 0
    end
    self.pushTimer = self.pushTimer + entity.dt()
  end
end

function onItemPut(item, nodeId)
  if item then
    return storageApi.storeItem(item[1], item[2], item[3])
  end
  
  return false
end

function onItemGet(filter, nodeId)
  --world.logInfo("filter: %s", filter)
  if filter then
    for i,item in storageApi.getIterator() do
      for _, filterString in ipairs(filter) do
        if storageApi.peekItem(i)[1] == filterString then return storageApi.returnItem(i) end
      end
    end
  else
    for i,item in storageApi.getIterator() do
      --world.logInfo(i)
      return storageApi.returnItem(i)
    end
  end
  return false
end