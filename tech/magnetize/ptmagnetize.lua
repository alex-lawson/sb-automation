function init()
  data.active = false
  tech.setVisible(true)
  
  data.dataStart = "ptmagnetblock"
  data.dataStartLen = string.len(data.dataStart)
  data.magnetConstant = magnetUtil.constant
  data.positive = true
end

function uninit()
  if data.active then
    tech.setAnimationState("magnetball", "off")
    tech.translate({0, -tech.parameter("ballTransformHeightChange")})
    tech.setParentAppearance("normal")
    data.active = false
  end
end

function input(args)
  local move = nil
  if args.moves["special"] == 1 and not data.specialLast then
    if data.active then
      return "magnetizeDeactivate"
    else
      return "magnetizeActivate"
    end
  end
  
  if args.moves["special"] == 2 and not data.specialLast2 then
    if data.active then
      return "magnetizeReverse"
    end
  end

  data.specialLast = args.moves["special"] == 1
  data.specialLast2 = args.moves["special"] == 2

  return move
end

function update(args)
  local radius = magnetUtil.radius

  if not data.active and args.actions["magnetizeActivate"] then
    tech.setAnimationState("magnetball", (data.positive and "pos" or "neg"))
    tech.translate({0, tech.parameter("ballTransformHeightChange")})
    tech.setParentAppearance("hidden")
    data.active = true
  elseif data.active and (args.actions["magnetizeDeactivate"]) then
    local ballDeactivateCollisionTest = tech.parameter("ballDeactivateCollisionTest")
    local yChange = ballDeactivateCollisionTest[2] + ballDeactivateCollisionTest[4] + 0.01
    ballDeactivateCollisionTest[1] = ballDeactivateCollisionTest[1] + tech.position()[1]
    ballDeactivateCollisionTest[2] = ballDeactivateCollisionTest[2] + tech.position()[2]
    ballDeactivateCollisionTest[3] = ballDeactivateCollisionTest[3] + tech.position()[1]
    ballDeactivateCollisionTest[4] = ballDeactivateCollisionTest[4] + tech.position()[2]
    if not world.rectCollision(ballDeactivateCollisionTest) then
      tech.setAnimationState("magnetball", "off")
      tech.translate({0, -tech.parameter("ballTransformHeightChange")})
      tech.setParentAppearance("normal")
      data.active = false
    else
      -- Try going down instead of up
      ballDeactivateCollisionTest[2] = ballDeactivateCollisionTest[2] - yChange
      ballDeactivateCollisionTest[4] = ballDeactivateCollisionTest[4] - yChange
      if not world.rectCollision(ballDeactivateCollisionTest) then
        tech.setAnimationState("magnetball", "off")
        tech.translate({0, -tech.parameter("ballTransformHeightChange") - yChange})
        tech.setParentAppearance("normal")
        data.active = false
      end
    end
  elseif data.active and (args.actions["magnetizeReverse"]) then
    data.positive = not data.positive
    if data.positive then
      tech.setAnimationState("magnetball", "pos")
    else
      tech.setAnimationState("magnetball", "neg")
    end
  end

  if data.active then
    tech.applyMovementParameters(tech.parameter("ballCustomMovementParameters"))
	
    local dv = {0, 0}
	local objects = world.objectQuery(tech.position(), radius)
	
	for key,value in pairs(objects) do
	  if isMagnet(value) then
	    local objPos = world.entityPosition(value)
      local magnetPos = magnetUtil.magnetCenter(objPos)
	    local monsters = world.monsterQuery(magnetPos, 0)
      if #monsters > 0 then
        local magnetDataID = monsters[1]
        local magnetCharge = world.entityHealth(magnetDataID)[2]
      
        -- Advanced magnets are twice the normal size
        if world.entityName(value) == "ptmagnetblockadvanced" then
          magnetPos = {magnetPos[1] + 0.5, magnetPos[2] + 0.5}
        end
        
        local posDif = world.distance(playerCenter(), magnetPos)
        local qQ = magnetCharge * data.magnetConstant * (data.positive and 1 or -1)
        local forceMag = qQ / magnetUtil.lengthSquared(posDif)
        local theta = math.atan2(posDif[2], posDif[1])
      
        dv[1] = dv[1] + (forceMag * math.cos(theta))
        dv[2] = dv[2] + (forceMag * math.sin(theta))
      end
	  end
	end
	
	local v = tech.velocity()
	tech.setVelocity({v[1] + (dv[1] * args.dt), v[2] + (dv[2] * args.dt)})
  end

  return 0
end

function playerCenter()
  local pos = tech.position()
  pos[2] = pos[2] - 0.75
  return pos
end

function isMagnet(id)
  return string.sub(world.entityName(id), 1, data.dataStartLen) == data.dataStart
end

magnetUtil = {
  constant = 40,
  radius = 50,
  minDist = 1
}

function magnetUtil.magnetCenter(objPos)
  return { objPos[1] + 0.5, objPos[2] + 0.5}
end

function magnetUtil.lengthSquared(vec)
  local out = (vec[1] * vec[1]) + (vec[2] * vec[2])
  if out < magnetUtil.minDist then
    out = 2 * magnetUtil.minDist - out
  end
  return out
end