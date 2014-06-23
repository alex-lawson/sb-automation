function init(virtual)
  if not virtual then
    energy.init()

    entity.setAnimationState("smelting", "off")

    self.conversions = entity.configParameter("smeltRecipes")
    self.smeltRate = entity.configParameter("smeltRate")
    self.smeltTimer = 0
    self.smelting = true

    entity.setInteractive(true)
  end
end

function die()
  energy.die()
end

function main()
  energy.update()

  local oreItem = world.containerItemAt(entity.id(), 0)
  local smeltedItem, newOreItem = getOreOutput(oreItem)

  if smeltedItem and world.containerItemsCanFit(entity.id(), smeltedItem) and energy.consumeEnergy() then
    if not self.smelting then
      self.smelting = true
      entity.setAnimationState("smelting", "smelt")
    end

    self.smeltTimer = self.smeltTimer + entity.dt()

    if self.smeltTimer > self.smeltRate then

      world.containerTakeAt(entity.id(), 0)
      world.containerPutItemsAt(entity.id(), newOreItem, 0)
      world.containerPutItemsAt(entity.id(), smeltedItem, 1)
      self.smeltTimer = 0
    end
  else
    self.smelting = false
    entity.setAnimationState("smelting", "on")
  end
end

function getOreOutput(oreItem)
  if not oreItem then return false end

  local recipe = getOreRecipe(oreItem)

  if recipe then
    if recipe[1] == oreItem.name and oreItem.count >= recipe[2] then
      return {name = recipe[4], count = recipe[3], data = {}}, {name = recipe[1], count = oreItem.count - recipe[2], data = {}}
    end
  end
  return false
end

function getOreRecipe(oreItem)
  if not oreItem then return false end

  for _,recipe in ipairs(self.conversions) do
    if recipe[1] == oreItem.name then return recipe end
  end
  return false
end

function beforeAdaptorGet(filter, adaptorId)
  local resultItem = world.containerItemAt(entity.id(), 1)
  if resultItem then
    if filter then
      for itemName, amount in pairs(filter) do
        if resultItem.name == itemName and resultItem.count > amount[1] then
          return true
        end
      end
    else
      return true
    end
  end
  return false
end

function adaptorGet(filter, adaptorId)
  local resultItem = world.containerItemAt(entity.id(), 1)
  if resultItem then
    if filter then
      for itemName, amount in pairs(filter) do
        if resultItem.name == itemName and resultItem.count > amount[1] then
          local consumeAmount = math.min(resultItem.count, amount[2])
          return {resultItem.name, }
        end
      end
    else
      return world.containerTakeAt(entity.id(), 1)
    end
  end
  return false
end

function adaptorGetAll(filter, adaptorId)
  local resultItem = world.containerItemAt(entity.id(), 1)
  if resultItem then
    return {resultItem}
  else 
    return {}
  end
end

function beforeAdaptorPut(item, adaptorId)
  local canFit = world.containerItemsFitWhere(entity.id(), item)
  if recipe then
    local oreItem = world.containerItemAt(entity.id(), 0)
    if oreItem and oreItem.name ~= item.name then return false end

    local amount = item.count;
    if oreItem then amount = amount + oreItem.amount end

    if amount > recipe[2] then return true end
  end
  return false
end

function adaptorPut(item, adaptorId)
  local recipe = getOreRecipe(item)
  if recipe then
    local oreItem = world.containerItemAt(entity.id(), 0)
    if oreItem and oreItem.name ~= item.name then return false end

    local amount = item.count;
    if oreItem then amount = amount + oreItem.count end

    local overflow = amount % recipe[2]
    world.logInfo("Overflow: %s", overflow)
    item.count = item.count - overflow

    local putResult = world.containerPutItemsAt(entity.id(), item, 0)
    world.logInfo("putResult: %s", putResult)


    if putResult or overflow then
      if putResult then item.count = item.count - putResult.count end
      return item.count
    else
      return true
    end
  end
  return false
end