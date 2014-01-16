function init(args)
  if not args then
    energy.init()
    storage.magnetOnAnim = (entity.configParameter("chargeStrengthOn") == 0) and "neutral" or entity.configParameter("chargeStrengthOn") > 0 and "positive" or "negative"
    storage.magnetOffAnim = (entity.configParameter("chargeStrengthOff") == 0) and "neutral" or entity.configParameter("chargeStrengthOff") > 0 and "positive" or "negative"
  
    storage.magnetDataOn = clamp(entity.configParameter("chargeStrengthOn"), -magnets.limit, magnets.limit)
    storage.magnetDataOff = clamp(entity.configParameter("chargeStrengthOff"), -magnets.limit, magnets.limit)
	
    storage.charge = 0
    
    killData()
	
    entity.setInteractive(true)
    if storage.state == nil then
      output(true)
    else
      output(storage.state)
    end
  end
end

function die()
  energy.die()
  killData()
end

function killData()
  if storage.dataID ~= nil then
    world.callScriptedEntity(storage.dataID, "kill")
    storage.dataID = nil
  end
end

function onInteraction(args)
  output(not storage.state)
end

function onInboundNodeChange(args)
  output(not storage.state)
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    entity.setAllOutboundNodes(state)
	
    updateMagnetData()
	
    if state then
      entity.setAnimationState("magnetState", storage.magnetOnAnim)
      entity.playSound("onSounds")
    else
      entity.setAnimationState("magnetState", storage.magnetOffAnim)
      entity.playSound("offSounds")
    end
  end
end

function main()
  energy.update()
  if (storage.dataID == nil or (storage.dataID ~= nil and not world.entityExists(storage.dataID))) then
    updateMagnetData()
  end
  
  local charge = storage.charge
  if storage.state then -- Magnet is active
    if not energy.consumeEnergy() then
      output(false)
      return
    end
    
    -- Push monsters/npcs
    local radius = magnets.radius
    local pos = entity.position()
    local ents = world.entityQuery(pos, radius, { withoutEntityId = storage.dataID, notAnObject = true })
    for key,value in pairs(ents) do
      if magnets.shouldEffect(value) then
        local ent = entityProxy.create(value)
        magnets.applyForce(ent, magnets.vecSum(pos, { 0.5, 0.5 }), charge)
      end
    end
  end
end

function updateMagnetData()
  killData()
  
  -- 13/9 Is the level the monster needs for the health to scale by 1
  local charge = storage.charge
  if storage.state then
    charge = storage.magnetDataOn
  else
    charge = storage.magnetDataOff
  end
  if charge ~= 0 then
    local pos = entity.position()
    pos = magnets.vecSum(pos, { 0.5, 0.5 })
    -- This dummy monster is needed for the magnetize tech to interact with magnets
    storage.dataID = world.spawnMonster("ptmagnetdata", pos, { level = (13/9), statusParameters = { baseMaxHealth = charge }})
    entity.setColliding(true)
  else
    storage.dataID = nil
    entity.setColliding(false)
  end
  storage.charge = charge
  
  entity.setGlobalTag("charge", roundCharge(charge))
end

function roundCharge(charge)
  charge = charge / 10
  if charge >= 0 then
    charge = math.ceil(charge)
  else
    charge = math.floor(charge)
  end
  return charge * 10
end

function clamp(num, minimum, maximum)
  if num < minimum then
    return minimum
  elseif num > maximum then
    return maximum
  else
    return num
  end
end