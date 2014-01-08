function init(virtual)
  if not virtual then
    self.lampColor = entity.configParameter("lampColor")
    if self.lampColor == nil then
      self.lampColor = "white"
    end

    entity.setGlobalTag("color", self.lampColor)

    self.projectileLocation = {entity.position()[1], entity.position()[2] + 1}

    checkNodes()
  end
end

function onNodeConnectionChange()
  checkNodes()
end

function onInboundNodeChange(args)
  checkNodes()
end

function checkNodes()
  storage.state = entity.getInboundNodeLevel(0)
end

function main()
  if storage.state then
    world.spawnProjectile("wirelamp"..self.lampColor, self.projectileLocation, entity.id(), {0, 0}, false, {})
  end
end