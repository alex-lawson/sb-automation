function init(v)
  entity.setInteractive(true)
  
  if not v then
    pipes.init({itemPipe})
    
    local initInv = entity.configParameter("initialInventory")
    if initInv and (storage.sApi == nil) then
      storage.sApi = initInv
    end

    storageApi.init({ mode = 3, capacity = 16, ondeath = 1, merge = true })
    
    self.pushRate = entity.configParameter("itemPushRate")
    self.pushTimer = 0
  end
end

function die()
  storageApi.die()
end

function droneRegister(eId)
  if (self.droneId) == nil or (self.droneId == eId) then
    self.droneId = eId
    return true
  end
  return false
end

function droneDeath(eId)
  if self.droneId == eId then
    self.droneId = nil
  end
end

function onInboundNodeChange(args)
  if args.level then
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
  end
end

function onInteraction(args)
  
end

function main(args)
  pipes.update(entity.dt())
  
  if self.pushTimer > self.pushRate then
    for node=0,1 do
      if entity.getInboundNodeLevel(node) then
        for i,item in storageApi.getIterator() do
          local result = pushItem(node + 1, item)
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