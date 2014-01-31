function init(args)
    if not self.initialized and not args then
        energy.init()
        self.initialized = true
        if storage.state == nil then
           storage.state = true
        end
        entity.setInteractive(not entity.isInboundNodeConnected(0))
        updateAnimationState()
    end
end

function onInteraction(args)
   if not entity.isInboundNodeConnected(0) then
      storage.state = not storage.state
      updateAnimationState()
   end
end

function main()
   energy.update()
   local lightLevel = world.lightLevel(entity.position())
   if lightLevel >= entity.configParameter("lightLevelThreshold") then
      local generatedEnergy = lightLevel*entity.configParameter("energyGenerationRate")
      if energy.addEnergy(generatedEnergy) then
         updateAnimationState()
      end
   end
end

function updateAnimationState()
   if storage.state then
      entity.setAnimationState("solarState", "on")
   else
      entity.setAnimationState("solarState", "off")
   end
end

function onNodeConnectionChange()
   checkNodes()
end

function onInboundNodeChange()
   checkNodes()
end

function checkNodes()
   local isWired = entity.isInboundNodeConnected(0)
   if isWired then
      storage.state = entity.getInboundNodeLevel(0)
      updateAnimationState()
   end
   entity.setInteractive(not isWired)
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
