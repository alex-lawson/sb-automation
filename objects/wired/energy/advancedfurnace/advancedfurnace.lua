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

  for _,recipe in ipairs(self.conversions) do
    if recipe[1] == oreItem.name and oreItem.count >= recipe[2] then
      return {name = recipe[4], count = recipe[3], data = {}}, {name = recipe[1], count = oreItem.count - recipe[2], data = {}}
    end
  end
  return false
end