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
    self.minLengths = { 1, 1, -2, -2}

    --This is the offset of tile 2, add to tile 1 pos
    self.blockOffsets = { {0, -1}, {-1, 0}, {0, -1}, {-1, 0} } 

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
  world.logInfo("Entering state: offState")
end

function offState.update(dt, stateData)
  if entity.getInboundNodeLevel(0) then
    stateData.state = "laser"
    return true
  end
  world.logInfo("Wire level: %s", entity.getInboundNodeLevel(0))
  return false
end

function offState.leavingState(stateData)
  world.logInfo("Leaving state: offState for %s", stateData.state)
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
  world.logInfo("Entering state: rotationState")
end

function rotationState.update(dt, stateData)
  entity.rotateGroup("laser", self.rotations[storage.curDir])

  local rotationDifference = trimRadians(entity.currentRotationAngle("laser")) - self.rotations[storage.curDir]
  if math.abs(rotationDifference) < 0.01 then
    return true
  else
    world.logInfo("Rotation difference: %s", rotationDifference)
    return false
  end
end

function rotationState.leavingState(stateData)
  world.logInfo("Leaving state: rotationState")
  self.state.pickState()
end
--------------------------------------------------------------------------------
laserState = {}

function laserState.enterWith(action)
  if action == "laser" then
    return {length = 0, minLength = self.minLengths[storage.curDir], tileOffset = self.blockOffsets[storage.curDir]}
  end
end

function laserState.enteringState(stateData)
  world.logInfo("Entering state: laserState")
  entity.setAnimationState("laser", "work")
  laserState.setLength(4);
end

function laserState.update(dt, stateData)
  if entity.getInboundNodeLevel(0) then
    return false
  end

  return true
end

function laserState.leavingState(stateData)
  world.logInfo("Leaving state: laserState")
  entity.setAnimationState("laser", "off")
  laserState.setLength(0);
  self.state.pickState()
end

--length in blocks
function laserState.setLength(length)
  entity.scaleGroup("beam", {8 * length, 1}) 
end