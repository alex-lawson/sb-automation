--------------------- SAMPLE MINIMAL IMPLEMENTATION --------------------

--- TODO: documents args

function init(virtual)
  if not virtual then
    local pipeTypes = ({liquidPipe, itemPipe}) --only use the types you need
    pipes.init(pipeTypes)
  end
end

function main()
  pipes.update() --Required
  
  --Pushing and pulling liquids, simple usage
  local getLiquid = pullLiquid(1) --Returns false/nil if no liquid was pulled, {liquidId, amount} if successful
  
  pushLiquid(1, getLiquid) --Returns true if successful
  
  --Pushing and pulling items, simple usage
  local filter = {"snow", "slush"}
  local getItem = pullItem(1, filter) --Pulls a stack of snow or slush, returns item if successful, false/nil if unsuccessful
  getItem = pullItem(1) --Pulls the first item it encounters
  
  pushItem(1, getItem) --Returns true (whole stack was tacken) / number (the number of items that were taken) / false/nil (nothing was taken)
  
  
  --Peeking, advanced usage
  --peek functions allow you to check if the operation is possible before going through with it
  local liquid = peekPullLiquid(1)
  if liquid and peekPushLiquid(1, liquid) then --Both check if there is liquid to pull, and somewhere to output it, before trying to pull liquid. This avoids destroying liquid.
    liquid = pullLiquid(1)
    pushLiquid(1, liquid)
  end
  
  local item = peekPullItem(1)
  if item and peekPushItem(1, item) then
    item = pullItem(1)
    pushItem(1, item)
  end
end

--------------------- HOOKS --------------------

-- TODO: document filter format

--LIQUIDS

--Should return true if the object can receive the liquid, false if it can't, but do nothing with the liquid value
function beforeLiquidPut(liquid, nodeId)
  return true
end

--Should return true if the object received the liquid, false if it didn't, and perform the receive action
function onLiquidPut(liquid, nodeId)
  self.liquid = liquid
  return true
end

--Should return the liquid it would send, or false if no liquid, but not remove any liquid
function beforeLiquidGet(filter, nodeId)
  if filter == nil then
    return world.liquidAt(entity.position()) or false
  else
    local liquid = world.liquidAt(entity.position())
    if filter[1] == liquid[1] then return liquid end
  end
  return false
end

--Should return the liquid, or false if there is none, and perform the send action
function onLiquidGet(filter, nodeId)
  if filter == nil then
    return world.liquidAt(entity.position()) or false
  else
    local liquid = world.liquidAt(entity.position())
    if filter[1] == liquid[1] then return world.destroyLiquiod(entity.position()) end
  end
  return false
end

--ITEMS

--Return true if item can be used, amount used if only part can be used, or false if it cannot be used
function beforeItemPut(item, nodeId)
  return true
end

--Return same as beforeItemPut, and perform the receive action
function onItemPut(item, nodeId)
  storage.item = item
  return true
end

--Return item if item can be sent, false if cannot
function beforeItemGet(filter, nodeId)
  if filter == nil then
    return storage.item
  else
    if filterContains(filter, storage.item.name) then return storage.item end
  end
  return false
end

--Return item if item can be sent, false if cannot, and perform the send action
function onItemGet(filter, nodeId)
  if filter == nil then
    return storage.item
  else
    if filterContains(filter, storage.item.name) then 
      local item = storage.item
      storage.item = nil
      return item
    end
  end
  return false
end