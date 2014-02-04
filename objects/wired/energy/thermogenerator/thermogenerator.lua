function init(virtual)
  if not virtual then
    energy.init()

    self.lavaCapacity = 2000
    storage.lavaLevel = storage.lavaLevel or self.lavaCapacity
    self.lavaConsumptionRate = 5 --this is per tile, so multiply by 6 to get max energyGenerationRate
    self.energyPerLava = 0.2
    self.waterPerLava = 4

    self.energyPerExchange = 1

    local pos = entity.position()
    --self.checkArea = {{pos[1] - 1, pos[2] -2}, {pos[1] + 1, pos[2] -2}, {pos[1] - 1, pos[2] - 1}, {pos[1] + 1, pos[2] - 1}, {pos[1] - 1, pos[2]}, {pos[1] + 1, pos[2]}}
    self.checkArea = {{pos[1], pos[2] -2}, {pos[1], pos[2] - 1}, {pos[1], pos[2]}}

    -- entity.setParticleEmitterActive("steam1", true)
    -- entity.setParticleEmitterActive("steam2", true)
    -- entity.setParticleEmitterActive("steam3", true)

    updateAnimationState()
  end
end

function die()
  energy.die()
end

function updateAnimationState()
  if storage.lavaLevel > 0 then
    entity.setAnimationState("lavaState", "on")
  else
    entity.setAnimationState("lavaState", "off")
  end
end

function onLiquidPut(liquid, nodeId)
  if storage.lavaLevel < self.lavaCapacity and liquid and liquid[1] == 3 then
    return true
  end
end

function pullLava()

end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = 0
  return energyNeeds
end

function generate()
  local lavaPerTile = self.lavaConsumptionRate * entity.dt()
  for i, pos in ipairs(self.checkArea) do
    --break out of this if no lava is left
    if storage.lavaLevel <= 0 then
      return
    end

    --check liquid at the given tile
    local liquidSample = world.liquidAt(pos)
    if liquidSample and liquidSample[1] == 1 and liquidSample[2] >= 700 then
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
  end
end

function main()
  pullLava()
  generate()
  updateAnimationState()

  energy.update()
end