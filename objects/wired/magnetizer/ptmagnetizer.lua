function init(args)
  if not args then
    entity.setInteractive(true)
    
    storage.magnetized = {}
    
    if math.magnetizers == nil then
      math.magnetizers = { }
    end
    
    if storage.state == nil then
      output(false)
    else
      output(storage.state)
    end
  end
end

-- Remove self from global magnetizer list on death
function die()
  if math.magnetizers ~= nil then
    math.magnetizers[entity.id()] = nil
  end
end

function onInteraction(args)
  output(not storage.state)

  entity.playSound("onSounds");
end

function onInboundNodeChange(args)
  output(not storage.state)
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    entity.setAllOutboundNodes(state)
	
    if state then
      entity.setAnimationState("magnetizerState", "on")
      entity.playSound("onSounds")
    else
      entity.setAnimationState("magnetizerState", "off")
      entity.playSound("offSounds")
    end
  end
end

function main()
  -- Ensure that this magnetizer is still in the global table
  if not math.magnetizers[entity.id()] then
    math.magnetizers[entity.id()] = true
  end

  -- Update all entities magnetized by this magnetizer
  for key,value in pairs(storage.magnetized) do
    if not world.entityExists(key) then
      -- If the entity no longer exists, remove it from the magnetized list
      storage.magnetized[key] = nil
    else
      -- Else play the magnetized effect
      world.spawnProjectile("magnetEffect", world.entityPosition(key), key, {0, 0}, true)
    end
  end

  if storage.state then
    -- Magnetize entities
    local radius = 10
    local pos = entity.position()
    local ents = world.entityQuery(pos, radius, { withoutEntityId = storage.dataID, notAnObject = true })
    for key,value in pairs(ents) do
      if magnets.isValidTarget(value) then
        storage.magnetized[value] = true
      end
    end
  end
end

function getMagnetized()
  return storage.magnetized
end

function isMagnetized(entID)
  return storage.magnetized[entID] == true
end