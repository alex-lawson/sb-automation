stationState = {}

function stationState.enter()
  if world.entityExists(self.stationId or -1) == nil then return nil end
  return { pos = world.callScriptedEntity(self.stationId, "getLandingPos") }
end

function stationState.update(dt, sd)
  moveTo(sd.pos, dt)
  local pos = entity.position()
  if world.magnitude(pos, sd.pos) < 0.5 then
    for i,v in storageApi.getIterator() do
      local item = storageApi.returnItem(i)
      local res = world.callScriptedEntity(self.stationId, "storeItemFit", item.name, item.count, item.data)
      if res < item.count then
        storageApi.storeItem(item.name, item.count - res, item.data) 
      end
      storageApi.dropAll()
      world.callScriptedEntity(self.stationId, "droneLand")
    end
    return true
  end
  return false
end
