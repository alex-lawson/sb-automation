function init(args)
  if args == false then
    self.state = stateMachine.create({
      "offState",
      "rotationState",
      "laserState"
    })
    pipes.init({liquidPipe, itemPipe})
    energy.init()
    
    entity.setInteractive(true)

    entity.scaleGroup("beam", {0, 1})


    self.rotations = {0, math.pi * 0.5, math.pi, math.pi * 1.5}
    self.directions = { {1,0}, {0, 1}, {-1, 0}, {0, -1}}
    storage.curDir = storage.curDir or 1

    --Map of the minimum length to be outside the object
    self.minLengths = { 0, 0, 1, 1}

    --This is the offset of tile 2, add to tile 1 pos
    self.blockOffsets = { {0, -1}, {-1, 0}, {0, -1}, {-1, 0} } 

    self.dps = entity.configParameter("damagePerSecond", 1)
    self.maxLength = entity.configParameter("maxLength", 50)

    self.state.pickState()
  end
end

function die()
  energy.die()
end

function onInteraction(args)
  toggleDir()
  self.state.endState();
  self.state.pickState("rotate");
end

function curDir()
  return self.directions[storage.curDir]
end

function trimRadians(radians)
  return radians % (math.pi * 2)
end

function toggleDir()
  storage.curDir = storage.curDir + 1
  if storage.curDir > #self.directions then storage.curDir = 1 end
end

function main(args)
  pipes.update(entity.dt())
  energy.update()
  self.state.update(entity.dt())
end

--------------------------------------------------------------
offState = {}

function offState.enter()
  return {state = "off"}
end

function offState.enterWith(action)
  if action ~= "rotate" and action ~= "laser" then
    return {state = "off"}
  end
end

function offState.enteringState(stateData)
end

function offState.update(dt, stateData)
  if entity.getInboundNodeLevel(0) then
    stateData.state = "laser"
    return true
  end
  return false
end

function offState.leavingState(stateData)
  self.state.pickState(stateData.state)
end

--------------------------------------------------------------------------------
rotationState = {}

function rotationState.enterWith(action)
  if action == "rotate" then
    return {}
  end
end

function rotationState.enteringState(stateData)
end

function rotationState.update(dt, stateData)
  entity.rotateGroup("laser", self.rotations[storage.curDir])

  local rotationDifference = trimRadians(entity.currentRotationAngle("laser")) - self.rotations[storage.curDir]
  if math.abs(rotationDifference) < 0.01 then
    return true
  else
    return false
  end
end

function rotationState.leavingState(stateData)
  self.state.pickState()
end
--------------------------------------------------------------------------------
laserState = {}

function laserState.enterWith(action)
  if action == "laser" then
    return {length = 0, minLength = self.minLengths[storage.curDir], tileOffset = self.blockOffsets[storage.curDir], direction = self.directions[storage.curDir], curLength = 0}
  end
end

function laserState.enteringState(stateData)
  entity.setAnimationState("laser", "work")
  laserState.dig(stateData)
end

function laserState.update(dt, stateData)
  
  laserState.dig(stateData)

  if entity.getInboundNodeLevel(0) then
    return false
  end
  return true
end

function laserState.dig(stateData, damage)

  --Find tiles
  local tiles = laserState.findTilesByDamage(stateData)
  stateData.curLength = tiles[1]

  --Damage tiles
  if stateData.curLength < self.maxLength then
    local damaged = world.damageTiles(tiles[2], "foreground", entity.position(), "blockish", self.dps * entity.dt())
  end

  laserState.setLength(stateData.curLength)
end

function laserState.findTilesByDamage(stateData)
  local length = -1

  local firstLine = {}
  local secondLine = {}
  local firstFound = false
  local secondFound = false

  while firstFound == false and secondFound == false and length < self.maxLength do
    length = length + 1

    firstLine = laserState.getBeamLine(stateData, length)
    secondLine = laserState.addBeamOffset(firstLine, stateData.tileOffset)

    firstFound = world.damageTiles({firstLine[2]}, "foreground", entity.position(), "blockish", 0)
    secondFound = world.damageTiles({secondLine[2]}, "foreground", entity.position(), "blockish", 0)
  end

  local tiles = {}
  if firstFound then tiles[#tiles+1] = firstLine[2] end
  if secondFound then tiles[#tiles+1] = secondLine[2] end

  return {length, tiles}
end

function laserState.getBeamLine(stateData, length) 
  if length == nil then length = self.maxLength end

  local firstLineStart = entity.toAbsolutePosition({stateData.direction[1] + stateData.minLength * stateData.direction[1], stateData.direction[2] + stateData.minLength * stateData.direction[2]})
  local firstLineEnd = {firstLineStart[1] + length * stateData.direction[1], firstLineStart[2] + length * stateData.direction[2]}

  return {firstLineStart, firstLineEnd}
end

function laserState.addBeamOffset(firstBeam, offset)
  local secondLineStart = {firstBeam[1][1] +  offset[1], firstBeam[1][2] + offset[2]}
  local secondLineEnd = {firstBeam[2][1] + offset[1], firstBeam[2][2] + offset[2]}

  return {secondLineStart, secondLineEnd}
end

function laserState.leavingState(stateData)
  entity.setAnimationState("laser", "off")
  laserState.setLength(0);
  self.state.pickState()
end

--length in blocks
function laserState.setLength(length)
  entity.scaleGroup("beam", {8 * length, 1}) 
end