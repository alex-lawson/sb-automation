function init(virtual)
  if not virtual then
    energy.init()

    self.tempToEnergyConversion = 1
    self.waterConsumptionRate = 20

    local pos = entity.position()
    self.checkAreaLeft = {{pos[1] - 1, pos[2] - 1}, {pos[1] - 1, pos[2]}, {pos[1] - 1, pos[2] + 1}}
    self.checkAreaRight = {{pos[1] + 1, pos[2] - 1}, {pos[1] + 1, pos[2]}, {pos[1] + 1, pos[2] + 1}}

    checkTemps()
  end
end

function die()
  energy.die()
end

function checkTemps()
  self.tempLeft = getPlateTemp(self.checkAreaLeft)
  self.tempRight = getPlateTemp(self.checkAreaRight)
  updateAnimationState()
  world.logInfo("left plate temp: %d, right plate temp: %d", self.tempLeft, self.tempRight)
end

function getPlateTemp(checkArea)
  local temp = 0
  for i, pos in ipairs(checkArea) do
    local sample = world.liquidAt(pos)
    if sample then
      if sample[1] == 1 or sample[1] == 2 then
        temp = temp - 1
      elseif sample[1] == 3 or sample[1] == 5 then
        temp = temp + 1
      end
    end
  end
  return temp
end

function updateAnimationState()
  if self.tempLeft > 0 then
    entity.setAnimationState("leftState", "hot")
  elseif self.tempLeft < 0 then
    entity.setAnimationState("leftState", "cold")
  else
    entity.setAnimationState("leftState", "off")
  end

  if self.tempRight > 0 then
    entity.setAnimationState("rightState", "hot")
  elseif self.tempRight < 0 then
    entity.setAnimationState("rightState", "cold")
  else
    entity.setAnimationState("rightState", "off")
  end
end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
  energyNeeds[tostring(entity.id())] = 0
  return energyNeeds
end

function generate()
  if self.tempRight < 0 and self.tempLeft > 0 then
    if consumeWater(self.waterConsumptionRate * entity.dt(), self.checkAreaRight) then
      local output = (math.abs(self.tempRight) + self.tempLeft) * self.tempToEnergyConversion * entity.dt()
      world.logInfo("generated %f energy", output)
      energy.addEnergy(output)
    end
  elseif self.tempRight > 0 and self.tempLeft < 0 then
    if consumeWater(self.waterConsumptionRate * entity.dt(), self.checkAreaLeft) then
      local output = (math.abs(self.tempLeft) + self.tempRight) * self.tempToEnergyConversion * entity.dt()
      world.logInfo("generated %f energy", output)
      energy.addEnergy(output)
    end
  end
end

function consumeWater(amount, locations)
  for i, pos in ipairs(locations) do
    local destroyed = world.destroyLiquid(pos)
    if destroyed then
      if destroyed[2] >= amount then
        world.spawnLiquid(pos, 1, destroyed[2] - amount)
        return true
      else
        amount = amount - destroyed[2]
      end
    end
  end
  return false
end

function main()
  checkTemps()
  generate()

  energy.update()
end