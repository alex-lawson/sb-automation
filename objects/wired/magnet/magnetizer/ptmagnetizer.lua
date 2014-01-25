function init(virtual)
  if not virtual then
    energy.init()
    entity.setInteractive(true)
    
    storage.magnetized = {}
    storage.magnetizeDuration = entity.configParameter("magnetizeDuration", 5)
    storage.energyPerMonster = entity.configParameter("energyPerMonster", 10)
    
    if math.magnetizers == nil then
      math.magnetizers = { }
    end
    
    if storage.state == nil then
      output(false)
    else
      output(storage.state)
    end

    local pos = entity.position()
    self.aoe = {pos, {pos[1] + 1, pos[2] + 5}}
  end
end

-- Remove self from global magnetizer list on death
function die()
  energy.die()
  if math.magnetizers ~= nil then
    math.magnetizers[entity.id()] = nil
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
  energy.update()

  -- Ensure that this magnetizer is still in the global table
  if not math.magnetizers[entity.id()] then
    math.magnetizers[entity.id()] = true
  end

  -- Update all entities magnetized by this magnetizer
  for key,value in pairs(storage.magnetized) do
    if (not world.entityExists(key)) or (value <= 0) then
      -- If the entity no longer exists, remove it from the magnetized list
      storage.magnetized[key] = nil
    else
      -- Play the magnetized effect
      world.spawnProjectile("magnetEffect", world.entityPosition(key), key, {0, 0}, true)
      -- Update magnetize duration
      storage.magnetized[key] = value - entity.dt()
    end
  end

  if storage.state then
    -- Magnetize entities
    local ents = world.entityQuery(self.aoe[1], self.aoe[2], { withoutEntityId = storage.dataID, notAnObject = true })
    for key,value in pairs(ents) do
      if magnets.isValidTarget(value) then
        local magnetized = magnets.isMagnetized(value)
        if magnetized ~= nil and magnetized ~= -1 then
          local durationLeft = world.callScriptedEntity(magnetized, "getMagnetizedDuration", value)
          local energyToConsume = storage.energyPerMonster * (1 - (durationLeft / storage.magnetizeDuration))
          if energy.consumeEnergy(energyToConsume) then
            entity.setAnimationState("magnetizerState", "activate")
            world.callScriptedEntity(magnetized, "refreshMagnetize", value, storage.magnetizeDuration)
          end
        else
          if energy.consumeEnergy(storage.energyPerMonster) then
            entity.setAnimationState("magnetizerState", "activate")
            storage.magnetized[value] = storage.magnetizeDuration
          end
        end
      end
    end
  end
end

function getMagnetized()
  return storage.magnetized
end

function isMagnetized(entID)
  return storage.magnetized[entID] ~= nil
end

function refreshMagnetize(entID, duration)
  storage.magnetized[entID] = duration
end

function getMagnetizedDuration(entID)
  return storage.magnetized[entID]
end