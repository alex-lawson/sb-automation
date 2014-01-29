collectState = {}

function collectState.enter()
  if storageApi.isInit() then
    storageApi.init(entity.configParameter("storageapi.mode"), entity.configParameter("storageapi.capacity"), entity.configParameter("storageapi.merge"))
  end
  if storageApi.isFull() then return nil end
  local drops = world.itemDropQuery(entity.position(), entity.configParameter("collect.scanRadius"), { order = "nearest" })
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
      storageApi.storeItem(item[1], item[2], item[3])
    end
  end
  return storageApi.isFull() or (#stateData.drops < 1)
end
