function init(args)
  if args == false then
    self.state = stateMachine.create({
      "deadState",
      "attackState",
      "scanState"
    })
    pipes.init({liquidPipe, itemPipe})
    energy.init()
    
    entity.setInteractive(true)

    entity.scaleGroup("beam", {0, 1})


    self.rotations = {0, math.pi * 0.5, math.pi, math.pi * 1.5}
    self.directions = { {1,0}, {0, 1}, {-1, 0}, {0, -1}}
    self.curDir = 1

    if storage.state == nil then storage.state = false end
  end
end

function die()
  energy.die()
end

function onInteraction(args)
  toggleDir()
end

function onInboundNodeChange(args)
  storage.state = args.level
end

function onNodeConnectionChange()
  storage.state = entity.getInboundNodeLevel(0)
end

function curDir()
  return self.directions[self.curDir]
end

function toggleDir()
  self.curDir = self.curDir + 1
  if self.curDir > #self.directions then self.curDir = 1 end
end

function main(args)
  pipes.update(entity.dt())
  energy.update()

  entity.rotateGroup("laser", self.rotations[self.curDir])

end