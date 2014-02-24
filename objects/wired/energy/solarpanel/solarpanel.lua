function init(virtual)
    if not virtual then
        energy.init({energySendFreq = 2})

        if storage.state == nil then
           storage.state = true
        end

        updateAnimationState()
    end
end

function main()
   energy.update()
   local lightLevel = onShip() and 1.0 or world.lightLevel(entity.position())
   if lightLevel >= entity.configParameter("lightLevelThreshold") and checkSolar() then
      local generatedEnergy = lightLevel*entity.configParameter("energyGenerationRate")*entity.dt()
      energy.addEnergy(generatedEnergy)
      updateAnimationState()
   end
end

function updateAnimationState()
   if storage.state then
      entity.setAnimationState("solarState", "on")
   else
      entity.setAnimationState("solarState", "off")
   end
end

function onShip()
  local worldInfo = world.info()
  return not worldInfo or worldInfo.id == "null"
end

-- Check requirements for solar generation
function checkSolar()
  return (onShip() or (world.timeOfDay() <= 0.5 and not world.underground(entity.position()))) and clearSkiesAbove()
end

function clearSkiesAbove()
  local ll = entity.toAbsolutePosition({ -2.0, 1.0 })
  local tr = entity.toAbsolutePosition({ 2.0, 16.0 })
  
  local bounds = {0, 0, 0, 0}
  bounds[1] = ll[1]
  bounds[2] = ll[2]
  bounds[3] = tr[1]
  bounds[4] = tr[2]
  
  return not world.rectCollision(bounds, true)
end

--- Energy
function onEnergySendCheck()
   if storage.state then
      return energy.getEnergy()
   else
      return 0
   end
end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
   energyNeeds[tostring(entity.id())] = 0
   return energyNeeds
end
