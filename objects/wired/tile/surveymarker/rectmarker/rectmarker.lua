function init(virtual)
  if not virtual then
    entity.setInteractive(true)

    if storage.timer == nil then
      storage.timer = 0
    end

    self.cooldown = 5

    if storage.triggered == nil then
      storage.triggered = false
    end

    if not storage.triggered then
      storage.isOrigin = false
    end

    self.triggerDistance = entity.configParameter("triggerDistance")
    if self.triggerDistance == nil then
      self.triggerDistance = 50
    end

    self.smashed = false

    datawire.init()
  end
end

function onInteraction(args)
  doScan()
end

function doScan()
  local entityIds = world.objectQuery(entity.position(), self.triggerDistance, { name = "rectmarker", order = "nearest", withoutEntityId = entity.id() })
  if #entityIds > 0 then
    local corner1 = floorPos(entity.position())
    local corner2 = floorPos(world.entityPosition(entityIds[1]))
    local tileArea = getTileAreaFromRect(corner1, corner2)
    local success = datawire.sendData(tileArea, "area", "all")
    if success then
      world.spawnItem(entity.configParameter("objectName"), corner1, 2)
      world.callScriptedEntity(entityIds[1], "entity.smash")
      entity.smash()
    else
      world.logInfo("Unable to send area data; make sure a valid receiver object is connected.")
    end
  else
    world.logInfo("No valid markers found within range!")
  end
end

function floorPos(position)
  return {math.floor(position[1]), math.floor(position[2])}
end

function getTileAreaFromRect(corner1, corner2)
  if corner1[1] > corner2[1] then
    local tempx = corner1[1]
    corner1[1] = corner2[1]
    corner2[1] = tempx
  end

  if corner1[2] > corner2[2] then
    local tempy = corner1[2]
    corner1[2] = corner2[2]
    corner2[2] = tempy
  end

  local x = corner1[1]
  local locations = {}
  while x <= corner2[1] do
    local y = corner1[2]
    while y <= corner2[2] do
      locations[#locations + 1] = {x, y}
      y = y + 1
    end
    x = x + 1
  end

  return locations
end

function main()
  datawire.update()
end