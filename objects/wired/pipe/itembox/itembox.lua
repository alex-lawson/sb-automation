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
    for node=0,1 do
      if entity.getInboundNodeLevel(node) then
        for i,item in storageApi.getIterator() do
          world.logInfo("%s", args.node)
          local result = pushItem(node+1, item)
          if result == true then storageApi.returnItem(i) end --Whole stack was accepted
          if result and result ~= true then item.count = item.count - result end --Only part of the stack was accepted
          if result then break end
        end
      end
    end
  end
end

function onInteraction(args)
  local count = storageApi.getCount()
  local capacity = storageApi.getCapacity()
  local itemList = ""
  
  for _,item in storageApi.getIterator() do
    itemList = itemList .. "^green;" .. item.name .. "^white; x " .. item.count .. ", "
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
  if self.pushTimer > self.pushRate then
    for node=0,1 do
      if entity.getInboundNodeLevel(node) then
        for i,item in storageApi.getIterator() do
          local result = pushItem(node+1, item)
          if result == true then storageApi.returnItem(i) end --Whole stack was accepted
          if result and result ~= true then item.count = item.count - result end --Only part of the stack was accepted
          if result then break end
        end
      end
    end
    self.pushTimer = 0
  end
  self.pushTimer = self.pushTimer + entity.dt()
end

function onItemPut(item, nodeId)
  if item then
    return storageApi.storeItem(item.name, item.count, item.data)
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
        if item.name == filterString and item.count >= amount[1] then
          if item.count <= amount[2] then
            return storageApi.returnItem(i)
          else
            item.count = item.count - amount[2]
            return {name = item.name, count = amount[2], data = item.data}
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
        if item.name == filterString and item.count >= amount[1] then
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