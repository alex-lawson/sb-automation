function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
    pipes.init({itemPipe})
    
    self.conversions = {}
    self.conversions["copperore"] = {2, 1, "copperbar"}
    self.conversions["ironore"] = {2, 1, "ironbar"}
    self.conversions["silverore"] = {2, 1, "silverbar"}
    self.conversions["goldore"] = {2, 1, "goldbar"}
    self.conversions["diamondore"] = {4, 1, "diamond"}
    self.conversions["platinumore"] = {2, 1, "platinumbar"}
    self.conversions["titaniumore"] = {2, 1, "titaniumbar"}
    self.conversions["aegisaltore"] = {2, 1, "aegisaltbar"}
    self.conversions["Rubiumore"] = {2, 1, "Rubiumbar"}
    self.conversions["Ceruliumore"] = {2, 1, "Ceruliumbar"}
    
    if storage.ore == nil then storage.ore = {} end
    if storage.state == nil then storage.state = false end
    
    self.smeltRate = entity.configParameter("smeltRate")
    self.smeltTimer = 0
    
    entity.setInteractive(not entity.isInboundNodeConnected(0))
  end
end

function die()
  energy.die()
  ejectOre() --Temporary
end

function onNodeConnectionChange()
  checkNodes()
end

function onInboundNodeChange(args)
  checkNodes()
end

function checkNodes()
  local isWired = entity.isInboundNodeConnected(0)
  if isWired then
    storage.state = entity.getInboundNodeLevel(0)
  end
  entity.setInteractive(not isWired)
end

function onInteraction(args)
  if entity.isInboundNodeConnected(0) == false then
    storage.state = not storage.state
  end
end

function main()
  energy.update()
  datawire.update()
  pipes.update(entity.dt())

  if storage.ore[1] == nil or storage.ore[2] <= 0 then
    pullOre()
  end
  
  if storage.ore[1] and storage.state and  energy.consumeEnergy() then
    if self.smeltTimer > self.smeltRate then
      local oreConversion = self.conversions[storage.ore[1]]
      if oreConversion and oreConversion[1] <= storage.ore[2] then
        local bar = {oreConversion[3], oreConversion[2], {}}
        if peekPushItem(2, bar) then
          entity.setAnimationState("smelting", "smelt")
          if pushItem(2, bar) then
            storage.ore[2] = storage.ore[2] - oreConversion[1]
          end
        else
          entity.setAnimationState("smelting", "error")
        end
      end
      --This won't be needed when the smelter only accepts the ore it needs to smelt a bar
      if oreConversion[1] > storage.ore[2] then
        ejectOre() 
      end
      self.smeltTimer = 0
    end
    self.smeltTimer = self.smeltTimer + entity.dt()
  else
    entity.setAnimationState("smelting", "idle")
  end
  
end

--TODO: Change this to only grab the ore it needs
function pullOre() 
  storage.ore = {}
  local pullFilter = {}
  for matitem,conversion in pairs(self.conversions) do
    pullFilter[matitem] = {conversion[1], conversion[1]}
  end
  local pulledItem = pullItem(1, pullFilter)
  if pulledItem then
    storage.ore = pulledItem
  end
end

--TODO: Change this to only accept the ore it needs
function onItemPut(item, nodeId) 
  if item and nodeId == 1 and storage.ore[1] == nil then
    for ore,conversion in pairs(self.conversions) do
      if ore == item[1] then
        if item[2] <= conversion[1] then
          storage.ore = item
          return true --used whole stack
        else
          item[2] = conversion[1]
          storage.ore = item
          return conversion[1] --return amount used
        end
      end
    end
  end
  return false
end

function beforeItemPut(item, nodeId)
  if item and nodeId == 1 and storage.ore[1] == nil then
    local pullFilter = {}
    for ore,_ in pairs(self.conversions) do
      if ore == item[1] then return true end
    end
  end
  return false
end

--Temporary function until itempipes api is changed to allow amount filters and returns
function ejectOre()
  local position = entity.position()
  if next(storage.ore[3]) == nil then
    world.spawnItem(storage.ore[1], {position[1] + 1.5, position[2] + 1}, storage.ore[2])
  else
    world.spawnItem(storage.ore[1], {position[1] + 1.5, position[2] + 1}, storage.ore[2], storage.ore[3])
  end
  storage.ore = {}
end