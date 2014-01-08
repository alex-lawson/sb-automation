-- Holds top level storage location for saved data
local energy = storage.energy


--[[
-- Initializes the energy module.
-- Energy modules must have the following script config in "energy" array
-- 
-- battery (boolean): Determines whether or not this object acts as a battery
--		and whether or not it is able to send out energy to other objects
--		if false, then this object is a consumer
-- maxEnergy (integer): How much energy can the object hold. Please note that
--		consumers may also have an internal storage even if they are not a 
--		battery.
--]]
function initEnergy()
	if not energy then
		storage.energy = {
			batteries = {}, -- Table for each entry is: {ID (K)= location (V)}
			objects = {}, -- Table for each entry is: {ID (K)= location (V)}
			power = 0,
			maxEnergy = entity.configParameter("energy.maxEnergy")
			isBattery = entity.configParameter("energy.battery"),
			}
	end
	updateBatteries()
	updateObjects()
	scanForBatteries()
end

-- Returns how much energy the object currently holds
function getEnergy()
	return energy.power
end

-- Gets all attached objects that this object is providing energy for
function getObjects()
	return energy.objects
end

-- Adds the specified amount of energy
function addEnergy( amount )
	local power = getEnergy() -- Good practice, but tiny bit slower.
	power = math.max(0, math.min(power + amount, maxEnergy))
end

-- Attempts to initiate a link with the specified object
function initiateLink(id)
	local object = world.callScriptedEntity(id, "linkObject" , {id = entity.id, location = entity.location, batter = energy.isBattery})
	
	--if object then
		--It worked. Fancy a debug statement here?
	--end
end

-- Link this object with the other object. Will automatically put it in the Batteries or Objects table
-- depending on its type. Should not call this function directly. Use initiateLink(id) instead.
function linkObject(object)
	if not world.entityExists(object.id) then return end
	
	
	if object.battery and (not energy.battery) then -- Only link if THEY are battery and WE are consumer
		-- Are we missing our battery
		if not energy.batteries[object.id] then
			energy.batteries[object.id] = object.location
			
			-- Call the script back on the original object that called this one to complete the link
			world.callScriptedEntity(object.id, "linkObject" , {id = entity.id, location = entity.location, batter = energy.isBattery})
		end
	elseif (not object.battery) and energy.battery then -- Only link if THEY are consumer and WE are battery
		-- Are we missing our consumer?
		if not energy.objects[object.id] then
			energy.objects[object.id] = object.location
			
			-- Call the script back on the original object that called this one to complete the link
			world.callScriptedEntity(object.id, "linkObject" , {id = entity.id, location = entity.location, batter = energy.isBattery})
		end
	end
end

--Used to determine if it uses the energy system.
function isEnergyMod()
	return true
end

-- Consumes the specified energy from internal storage first. If
-- amount is more than held, will search for energy in its linked
-- batteries
function consumeEnergy(amount)
	--TODO: Set battery level animation?
	
	if energy.power <= amount then
		amount = amount - energy.power
		energy.power = 0
		
		if amount > 0 and not isBattery() then
			for k, v in pairs(getBatteries()) do
				-- If we no longer need any, return 0
				if amount <= 0 then return 0 end
				
				-- Set amount to amount that is now left to consume
				amount = world.callScriptedEntity(k, "consumeEnergy", amount)
			end
		end
		
	else
		energy.power = energy.power - amount
	end
	
	return amount
end

-- Takes an amount of energy from the specified battery and transfers it to this object's storage.
-- It will not take more than it can hold.
function takeEnergy(batteryID, amount)
	amount = math.min( amount, energy.maxAmount) -- First limit amount to the max storage.
	
	-- Make sure the other object is a battery
	if world.callScriptedEntity(batteryID, "isBattery") then
		-- Take some energy, and then add in the amount returned from the call.
		amount = world.callScriptedEntity(batteryID, "consumeEnergy", amount)
		
		if amount then -- Prevent possible Nil>0 compare error from bad ID?
			addEnergy(amount)
		end
	end
end

-- Returns true if the object has atleast the specified amount of energy in its storage
function hasEnergy(amount)
	return getEnergy() >= amount
end

-- Returns true if the object is a battery, false if it is a consumer
function isBattery()
	return energy.isBattery
end

-- Returns a list of all the batteries currently linked to this object
function getBatteries()
	return energy.batteries
end

-- Attempts to find and add batteries.
function scanForBatteries()
	if not isBattery() then return end
	
	-- I dont know how this is going to function yet. Holding off till then.
	-- Can manually link entities by using initiateLink(id)
end

--Update that battteries that this consumer uses
function updateBatteries()
	if not isBattery() then return end
	
	local batteries = getBatteries()
	for k, v in pairs(batteries) do
		if not world.entityExists(k) then
			local possibleObjs = world.objectQuery(v, 2, {order = "nearest"})
			if possibleObjs and world.callScriptedEntity(possibleObjects[1], "isBattery") then
				batteries[k] = nil -- Get rid of old ID data
				initiateLink(k)
			end
		else
			-- Did we HAPPEN to get an ID saved that was reloaded and coincidentally matches up with a non energy object?
			if not world.callScriptedEntity(k, "isBattery") then
				batteries[k] = nil
			end
		end
	end
end


-- Update the consumers that use this battery
function updateObjects()
	if not isBattery() then return end
	
	local objects = getObjects()
	for k, v in pairs(objects) do
		if not world.entityExists(k) then
			local possibleObjs = world.objectQuery(v, 2, {order = "nearest"})
			if possibleObjs and not world.callScriptedEntity(possibleObjects[1], "isBattery") then
				objects[k] = nil -- Get rid of old ID data
				initiateLink(k)
			end
		else
			-- Did we HAPPEN to get an ID saved that was reloaded and coincidentally matches up with a non energy object?
			if world.callScriptedEntity(k, "isBattery") then
				objects[k] = nil
			end
		end
	end
end
