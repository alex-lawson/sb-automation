function init(virtual)
  if not virtual then
    pipes.init({liquidPipe,itemPipe})

    self.connectionMap = {}
    self.connectionMap[1] = 2
    self.connectionMap[2] = 1
    self.connectionMap[3] = 4
    self.connectionMap[4] = 3

    buildFilter()
  end
end

--------------------------------------------------------------------------------
function main(args)
  buildFilter()
  pipes.update(entity.dt())
end

function showPass()
  entity.setAnimationState("filterState", "pass")
end

function showFail()
  entity.setAnimationState("filterState", "fail")
end

function beforeLiquidGet(filter, nodeId)
  --world.logInfo("passing liquid peek get from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPullLiquid(self.connectionMap[nodeId], filter)
end

function onLiquidGet(filter, nodeId)
  --world.logInfo("passing liquid get from %s to %s", nodeId, self.connectionMap[nodeId])
  return pullLiquid(self.connectionMap[nodeId], filter)
end

function beforeLiquidPut(liquid, nodeId)
  --world.logInfo("passing liquid peek from %s to %s", nodeId, self.connectionMap[nodeId])
  return peekPushLiquid(self.connectionMap[nodeId], liquid)
end

function onLiquidPut(liquid, nodeId)
  --world.logInfo("passing liquid from %s to %s", nodeId, self.connectionMap[nodeId])
  return pushLiquid(self.connectionMap[nodeId], liquid)
end

function beforeItemPut(item, nodeId)
  if self.filterCount > 0 then
    if self.filter[item.name] then
      return peekPushItem(self.connectionMap[nodeId], item)
    end
  end

  return false
end

function onItemPut(item, nodeId)
  local pushResult = false

  if self.filterCount > 0 then
    if self.filter[item.name] then
      pushResult = pushItem(self.connectionMap[nodeId], item)
    end
  end

  if pushResult then
    showPass()
  else
    showFail()
  end

  return pushResult
end

function beforeItemGet(filter, nodeId)
  if self.filterCount > 0 then
    local pullFilter = {}
    local filterMatch = false
    for filterString, amount in pairs(filter) do
      if self.filter[filterString] then
        pullFilter[filterString] = amount
        filterMatch = true
      end
    end

    if filterMatch then
      return peekPullItem(self.connectionMap[nodeId], pullFilter)
    end
  end

  return false
end

function onItemGet(filter, nodeId)
  local pullResult = false

  if self.filterCount > 0 then
    local pullFilter = {}
    local filterMatch = false
    for filterString, amount in pairs(filter) do
      if self.filter[filterString] then
        pullFilter[filterString] = amount
        filterMatch = true
      end
    end

    if filterMatch then
      pullResult = pullItem(self.connectionMap[nodeId], pullFilter)
    end
  end

  if pullResult then
    showPass()
  else
    showFail()
  end

  return pullResult
end

function buildFilter()
  self.filter = {}
  self.filterCount = 0
  local contents = world.containerItems(entity.id())
  if contents then
    for key, item in pairs(contents) do
      if self.filter[item.name] then
        self.filter[item.name] = math.min(self.filter[item.name], item.count)
      else
        self.filter[item.name] = item.count
        self.filterCount = self.filterCount + 1
      end
    end
  end

  if self.filterCount > 0 and entity.animationState("filterState") == "off" then
    entity.setAnimationState("filterState", "on")
  elseif self.filterCount <= 0 then
    entity.setAnimationState("filterState", "off")
  end
end