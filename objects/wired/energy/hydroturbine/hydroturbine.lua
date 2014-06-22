function init(virtual)
    if not virtual then
        energy.init()

        if storage.state == nil then
           storage.state = true
        end

		-- cached value, avoids multiple world.liquidAt()
		self.liquidAtInput = {}
		self.liquidState = false
		if self.liquidConsumed == nil then
			self.liquidConsumed = {}
			for i = 1, 7 do
				self.liquidConsumed[i] = 0
			end
		end

		setOrientation()

		entity.setInteractive(not entity.isInboundNodeConnected(0))
		
        updateAnimationState()
    end
end

function setOrientation()
	local pos = entity.position()
	if entity.direction() then
		self.liquidInArea = {{pos[1] - 4, pos[2]}, {pos[1] - 4, pos[2] + 1}, {pos[1] - 4, pos[2] + 2}, {pos[1] - 4, pos[2] + 3}}
	else
		self.liquidInArea = {{pos[1] + 4, pos[2]}, {pos[1] + 4, pos[2] + 1}, {pos[1] + 4, pos[2] + 2}, {pos[1] + 4, pos[2] + 3}}
	end
	self.liquidOutArea = {pos[1], pos[2] - 1}
end

function checkLiquidIn()
	-- needs all 4 spots filled with liquid,
	-- but should be able to generate power through different liquids excepts lava...
	-- they flow anyway...
	-- ok:
	--   1 - Water
    --   2 - Endless Water (Ocean)
    --   4 - Acid/Poison
    --   6 - Tentacle Juice
    --   7 - Tar
	-- nope:
    --   3 - Lava
    --   5 - Endless Lava
	for i, pos in ipairs(self.liquidInArea) do
		local liquidSample = world.liquidAt(pos)
		self.liquidAtInput[i] = liquidSample
		if not (liquidSample and
		        (liquidSample[1] == 1 or liquidSample[1] == 2 or liquidSample[1] == 4 or liquidSample[1] == 6 or liquidSample[1] == 7) and
		        liquidSample[2] > 0) then
			--[[
			world.logInfo("hydroturbine: checkLiquidIn(): return false.")
			world.logInfo("hydroturbine: checkLiquidIn(): because " .. (
				liquidSample 
				and ("liquid type is " .. liquidSample[1] .. ", amount " .. liquidSample[2])
				or "liquidSample is nil"
			))
			]]--
			return false
		end
	end
	world.logInfo("hydroturbine: checkLiquidIn(): return true")
	return true
end

function checkLiquidOut()
	-- output area needs to be clear
	if world.material(self.liquidOutArea, "foreground") or world.liquidAt(self.liquidOutArea) then
		--world.logInfo("hydroturbine: checkLiquidOut(): return false")
		return false
	end
	--world.logInfo("hydroturbine: checkLiquidOut(): return true")
	return true
end

function onNodeConnectionChange()
  world.logInfo("hydroturbine: onNodeConnectionChange(): checkpoint 1")
  checkNodes()
end

function onInboundNodeChange(args)
  world.logInfo("hydroturbine: onInboundNodeChange(): checkpoint 1")
  checkNodes()
end

function onInteraction(args)
  if entity.isInboundNodeConnected(0) == false then
    storage.state = not storage.state
	updateAnimationState()
  end
end

function checkNodes()
  world.logInfo("hydroturbine: checkNodes(): checkpoint 1")
  local isWired = entity.isInboundNodeConnected(0)
  if isWired then
    storage.state = entity.getInboundNodeLevel(0)
    updateAnimationState()
  end
  world.logInfo("hydroturbine: checkNodes(): checkpoint 2")
  entity.setInteractive(not isWired)
  world.logInfo("hydroturbine: checkNodes(): checkpoint 3")
end

function generate()
	--world.logInfo("hydroturbine: generate(): storage.state = " .. (storage.state and "true" or "false"))
	if storage.state then
		if checkLiquidIn() and checkLiquidOut() then
			local liquidConsumed = 0
			local consumptionRate = entity.configParameter("liquidConsumptionRate") -- I dunno if Lua does CSE or not, so cache the value here.
			for i = 1, 3 do
				local destroyed = world.destroyLiquid(self.liquidInArea[i])
				--world.logInfo("hydroturbine: generate(): destroyed " .. destroyed[2] .. " of liquid type " .. destroyed[1] .. " at [" .. pos[1] .. ", " .. pos[2] .. "]")
				-- consumes only entity.configParameter("liquidConsumptionRate") liquid per round
				if (destroyed[2] >= consumptionRate) then
					world.spawnLiquid(self.liquidInArea[i], destroyed[1], destroyed[2] - consumptionRate)
					self.liquidConsumed[destroyed[1]] = self.liquidConsumed[destroyed[1]] + consumptionRate
					liquidConsumed = liquidConsumed + consumptionRate
				else
					self.liquidConsumed[destroyed[1]] = self.liquidConsumed[destroyed[1]] + destroyed[2]
					liquidConsumed = liquidConsumed + destroyed[2]
				end
			end
			
			-- we can't just spawn liquid, because if we do so they just vanish.
			-- i think the world doesn't handle too little liquid like the amount of 
			-- entity.configParameter("liquidConsumptionRate")...
			-- so we stack it up till it hits entity.configParameter("liquidOutputThreshold").
			for i = 1, 7 do
				if self.liquidConsumed[i] >= entity.configParameter("liquidOutputThreshold") then
					world.spawnLiquid(self.liquidOutArea, i, self.liquidConsumed[i])
					self.liquidConsumed[i] = 0
				end
			end
			
			local generatedEnergy = liquidConsumed * entity.configParameter("energyGenerationPerLiquid") * entity.dt()
			energy.addEnergy(generatedEnergy)
			
			self.liquidState = true
		else
			self.liquidState = false
		end
	end
end

function main()
	energy.update()
	generate()
    updateAnimationState()
end

function updateAnimationState()
	if storage.state then
		if self.liquidState then
			entity.setAnimationState("turbineState", "on")
		else
			entity.setAnimationState("turbineState", "error")
		end
	else
		entity.setAnimationState("turbineState", "off")
	end
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
