collectState = {}

function collectState.enter()
  if storageApi.isInit() then
    storageApi.init()
  end
  if storageApi.isFull() then return nil end
  local drops = world.itemDropQuery(storage.stationPos, entity.configParameter("collect.scanRadius") or 25, { order = "nearest" })
  if #drops < 1 then return nil end
  return { drops = drops }
end

function collectState.update(dt, stateData)
  local pos
  for i,id in pairs(stateData.drops) do
    pos = world.entityPosition(id)
    if pos == nil then stateData.drops[i] = nil
    else break end
  end
  if pos == nil then return true end
  moveTo(pos, dt)
  local ids = world.itemDropQuery(entity.position(), 3)
  for i,id in pairs(ids) do
    if storageApi.isFull() then break end
    local item = world.takeItemDrop(id, entity.id())
    if item ~= nil then
      storageApi.storeItem(item.name, item.count, item.data)
    end
  end
  return storageApi.isFull() or (#stateData.drops < 1)
end
