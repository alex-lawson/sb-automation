function init(args)
  entity.setInteractive(true)
  
  if args == false then
    pipes.init({itemPipe})
    
    local initInv = entity.configParameter("initialInventory")
    if initInv and storage.sApi == nil then
      storage.sApi = initInv
    end
    
    storageApi.init(3, 16, true)
    
    entity.scaleGroup("invbar", {2, 0})
    
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

function onInboundNodeChange(args)
  if args.level then
    for i,item in storageApi.getIterator() do
      pushItem(2, storageApi.returnItem(i))
      break
    end
    self.pushTimer = 0
  end
end

function onInteraction(args)
  local count = storageApi.getCount()
  local capacity = storageApi.getCapacity()
  local itemList = ""
  
  for _,item in storageApi.getIterator() do
    itemList = itemList .. "^green;" .. item[1] .. "^white; x " .. item[2] .. ", "
  end
  
  return { "ShowPopup", { message = "^white;Holding ^green;" .. count ..
									"^white; / ^green;" .. capacity ..
                  "^white; stacks of items." ..
                  "\n\nStorage: " ..
                  itemList
									}}
end

function main(args)
  pipes.update(entity.dt())
  
  --Scale inventory bar
  local relStorage = storageApi.getCount() / storageApi.getCapacity()
  entity.scaleGroup("invbar", {2, relStorage})
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
        local result = pushItem(2, item)
        if result == true then storageApi.returnItem(i) end --Whole stack was accepted
        if result and result ~= true then item[2] = item[2] - result end --Only part of the stack was accepted
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

function beforeItemPut(item, nodeId)
  if item then
    return not storageApi.isFull() --TODO: Make this use the future function for fitting in a stack of items
  end
  return false
end

function onItemGet(filter, nodeId)
  if filter then
    for i,item in storageApi.getIterator() do
      for filterString,amount  in pairs(filter) do
        if item[1] == filterString and item[2] >= amount[1] then
          if item[2] <= amount[2] then
            return storageApi.returnItem(i)
          else
            item[2] = item[2] - amount[2]
            return {item[1], amount[2], item[3]}
          end
        end
      end
    end
  else
    for i,item in storageApi.getIterator() do
      return storageApi.returnItem(i)
    end
  end
  return false
end

function beforeItemGet(filter, nodeId)
  if filter then
    for i,item in storageApi.getIterator() do
      for filterString,amount  in ipairs(filter) do
        if item[1] == filterString and item[2] >= amount[1] then
          return true 
        end
      end
    end
  else
    for i,item in storageApi.getIterator() do
      return true
    end
  end
  return false
end