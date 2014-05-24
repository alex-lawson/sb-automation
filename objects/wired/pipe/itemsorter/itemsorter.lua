function init(virtual)
  if not virtual then
    pipes.init({liquidPipe,itemPipe})

    self.connectionMap = {}
    self.connectionMap[1] = {2, 3, 4}
    self.connectionMap[2] = {1, 3, 4}
    self.connectionMap[3] = {1, 2, 4}
    self.connectionMap[4] = {1, 2, 3}

    self.filtermap = {3, 2, 2, 1,
                      3, 2, 2, 1,
                      3, 4, 4, 1,
                      3, 4, 4, 1}

    filter = {}
    filter[1] = {}
    filter[2] = {}
    filter[3] = {}
    filter[4] = {}

    self.stateMap = {"right", "up", "left", "down"}

    self.filterCount = {}

    buildFilter()
  end
end

--------------------------------------------------------------------------------
function main(args)
  buildFilter()
  pipes.update(entity.dt())
end

function showPass(direction)
  entity.setAnimationState("filterState", "pass." .. direction)
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
  for _,node in ipairs(self.connectionMap[nodeId]) do
    if self.filterCount[node] > 0 then
      if self.filter[node][item.name] then
        return peekPushItem(self.connectionMap[nodeId], item)
      end
    end
  end
  return false
end

function onItemPut(item, nodeId)
  local pushResult = false
  local resultNode = 1

  for _,node in ipairs(self.connectionMap[nodeId]) do
    if self.filterCount[node] > 0 then
      if self.filter[node][item.name] then
        pushResult = pushItem(node, item)
        if pushResult then resultNode = node end
      end
    end
  end

  if pushResult then
    showPass(self.stateMap[resultNode])
  else
    showFail()
  end

  return pushResult
end

function beforeItemGet(filter, nodeId)
  for _,node in ipairs(self.connectionMap[nodeId]) do
    if self.filterCount[node] > 0 then
      local pullFilter = {}
      local filterMatch = false
      for filterString, amount in pairs(filter) do
        if self.filter[node][filterString] then
          pullFilter[filterString] = amount
          filterMatch = true
        end
      end

      if filterMatch then
        return peekPullItem(self.connectionMap[nodeId], pullFilter)
      end
    end
  end

  return false
end

function onItemGet(filter, nodeId)
  local pullResult = false
  local resultNode = 1

  for _,node in ipairs(self.connectionMap[nodeId]) do
  if self.filterCount[node] > 0 then
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
      if pullResult then resultNode = node end
    end
  end
  end

  if pullResult then
    showPass(self.stateMap[resultNode])
  else
    showFail()
  end

  return pullResult
end

function buildFilter()
  self.filter = {{}, {}, {}, {}}
  self.filterCount = {0, 0, 0, 0}
  local totalCount = 0

  local contents = world.containerItems(entity.id())
  if contents then
    for key, item in pairs(contents) do
      if self.filter[self.filtermap[key]][item.name] then
        self.filter[self.filtermap[key]][item.name] = math.min(self.filter[self.filtermap[key]][item.name], item.count)
      else
        self.filter[self.filtermap[key]][item.name] = item.count
        self.filterCount[self.filtermap[key]] = self.filterCount[self.filtermap[key]] + 1
        totalCount = totalCount + 1
      end
    end
  end

  if totalCount > 0 and entity.animationState("filterState") == "off" then
    entity.setAnimationState("filterState", "on")
  elseif totalCount <= 0 then
    entity.setAnimationState("filterState", "off")
  end
end