
magnets = {
  constant = 20,
  radius = 50,
  limit = 100
}

------------------------------------------------------------------------------------------
-- Applies a force to the specified entity, from the specified source position.
-- @param ent The entity table generated from entityProxy.
-- @param sourcePos The source position of the force, a table with an x and y value.
-- @param force The force to apply.
-- @return The new velocity of the entity, or nil if the force was unable to be applied.
------------------------------------------------------------------------------------------
function magnets.applyForce(ent, sourcePos, force)
  local vel = ent.velocity()
  if vel then
    local targetPos = ent.position()
    local posDif = world.distance(targetPos, sourcePos)
    local qQ = force * magnets.constant
    local forceMag = qQ * magnets.distanceScale(posDif)
    local theta = math.atan2(posDif[2], posDif[1])
  
    vel[1] = vel[1] + (forceMag * math.cos(theta) * entity.dt())
    vel[2] = vel[2] + (forceMag * math.sin(theta) * entity.dt())
    
    ent.setVelocity(vel)
    return vel
  else
    return nil
  end
end

----------------------------------------------------------------
-- Get the number to scale the force by with distance.
-- Override to scale force differently with distance.
-- Default scale by square inverse of distance (F = kqQ/r^2).
-- @param distance A table with 2 values, the x and y distance.
-- @return The number with which to scale the force by
----------------------------------------------------------------
function magnets.distanceScale(distance)
  return 1/magnets.lengthSquared(distance)
end

-------------------------------------------------------------------------
-- Adds two vectors.
-- @param u First vector in the form of { x1 , y1 }.
-- @param v Second vector in the form of { x2 , y2 }.
-- @return The sum of the two vectors in the form { x1 + x2 , y1 + y2 }.
-------------------------------------------------------------------------
function magnets.vecSum(u, v)
  return { u[1] + v[1], u[2] + v[2]}
end

-----------------------------------------------
-- Gets the square length of a vector.
-- @param vec The vector to get the length of.
-- @return The square length of the vector.
-----------------------------------------------
function magnets.lengthSquared(vec)
  return (vec[1] * vec[1]) + (vec[2] * vec[2])
end

------------------------------------------------------------------
-- Checks whether or not the entity should be effected by magnets
-- @param entID The ID of the entity
-- @return Whether or not the entity should be pushed by magnets
------------------------------------------------------------------
function magnets.shouldEffect(entID)
  -- Make sure the entity has been magnetized
  if math.magnetizers ~= nil and magnets.isValidTarget(entID) then
    for key,value in pairs(math.magnetizers) do
      if world.entityExists(key) then
        if world.callScriptedEntity(key, "isMagnetized", entID) then
          return true
        end
      else
        math.magnetizers[key] = nil
      end
    end
  end
  return false
end

------------------------------------------------------------------
-- Checks if the entity is a valid target of magnets
-- @param entID The ID of the entity
-- @return Whether or not the entity can be magnetized
------------------------------------------------------------------
function magnets.isValidTarget(entID)
  local entType = world.entityType(entID)
  return (entType == "monster" or entType == "npc") and (not world.callScriptedEntity(entID, "entity.configParameter", "isMagnetData", false)) 
end
