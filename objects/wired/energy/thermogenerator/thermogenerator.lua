function init(virtual)
  if not virtual then
    energy.init()
    pipes.init({liquidPipe})

    self.lavaCapacity = 2000
    storage.lavaLevel = storage.lavaLevel or 0
    self.lavaConsumptionRate = 10 --this is per tile, so multiply by 3 to get maximum total consumption
    self.energyPerLava = 0.2
    self.waterPerLava = 4

    setOrientation()

    updateAnimationState()
  end
end

function die()
  energy.die()
end

function setOrientation()
  local orientation = entity.configParameter("orientation")
  local pos = entity.position()
  if orientation == "down" then
    self.checkArea = {{pos[1], pos[2] - 2}, {pos[1], pos[2] - 1}, {pos[1], pos[2]}}
  else
    self.checkArea = {{pos[1], pos[2]}, {pos[1], pos[2] + 1}, {pos[1], pos[2] + 2}}
  end
  entity.setAnimationState("orientState", orientation)
end

function updateAnimationState()
  if storage.lavaLevel > 0 then
    entity.setAnimationState("lavaState", "on")
  else
    entity.setAnimationState("lavaState", "off")
  end
end

function beforeLiquidPut(liquid, nodeId)
  return storage.lavaLevel < 10 and liquid and liquid[1] == 3
end

function onLiquidPut(liquid, nodeId)
  if storage.lavaLevel < 10 and liquid and liquid[1] == 3 then
    storage.lavaLevel = math.min(storage.lavaLevel + liquid[2], self.lavaCapacity)
    return true
  end
end

function pullLava()
  local unusedCapacity = self.lavaCapacity - storage.lavaLevel
  if unusedCapacity > 0 then
    local filter = {}
    filter["3"] = {1, unusedCapacity}

    local liquid = pullLiquid(1, filter) or pullLiquid(2, filter)
    if liquid then
      storage.lavaLevel = storage.lavaLevel + liquid[2]
    end
  end
end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = 0
  return energyNeeds
end

function generate()
  local lavaPerTile = self.lavaConsumptionRate * entity.dt()
  for i, pos in ipairs(self.checkArea) do
    if storage.lavaLevel > 0 then
      --check liquid at the given tile
      local liquidSample = world.liquidAt(pos)
      if liquidSample and liquidSample[1] == 1 and liquidSample[2] >= 300 then
        --destroy water in the tile
        local destroyed = world.destroyLiquid(pos)
        
        --evaporate some water
        local consumeLava = math.min(lavaPerTile, storage.lavaLevel)
        local consumeWater = consumeLava * self.waterPerLava
        if destroyed[2] > consumeWater then
          world.spawnLiquid(pos, 1, destroyed[2] - consumeWater)
        else
          consumeLava = destroyed[2] / self.waterPerLava
        end

        --convert lava to energy
        storage.lavaLevel = storage.lavaLevel - consumeLava
        energy.addEnergy(self.energyPerLava * consumeLava)

        entity.setParticleEmitterActive("steam"..i, true)
      else
        entity.setParticleEmitterActive("steam"..i, false)
      end
    else
      entity.setParticleEmitterActive("steam"..i, false)
    end
  end
end

function main()
  pipes.update(entity.dt())

  pullLava()
  generate()
  updateAnimationState()

  energy.update()
end