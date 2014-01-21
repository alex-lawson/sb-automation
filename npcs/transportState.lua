transportState = {}

function transportState.enter()
  if storageApi.isInit() then
    storageApi.init(entity.configParameter("storageapi.mode"), entity.configParameter("storageapi.capacity"), entity.configParameter("storageapi.merge"))
  end
  if not storageApi.isFull() then return nil end
  local objs = world.objectQuery(entity.position(), entity.configParameter("transport.scanRadius"), { order = "nearest" })
  local oid = nil
  for i,id in pairs(objs) do
    local l = world.callScriptedEntity(id, "storageApi.isInput")
    if l then oid = id end
  end
  if oid == nil then return nil end
  return { objId = oid }
end

function transportState.update(dt, stateData)
  local pos = world.entityPosition(stateData.objId)
  if pos == nil then return true end
  moveTo(pos, dt)
  local epos = entity.position()
  if (math.abs(epos[1] - pos[1])) < 3 and (world.magnitude(entity.position(), pos) < 6) then
    local ids = storageApi.getStorageIndices()
    for i,ix in pairs(ids) do
      local item = storageApi.returnItem(ix)
      local r = world.callScriptedEntity(stateData.objId, "storageApi.storeItemFit", item[1], item[2], item[3])
      if r < item[2] then
        storageApi.storeItem(item[1], item[2] - r, item[3])
      end
    end
  end
  local ids = world.itemDropQuery(entity.position(), 3)
  for i,id in pairs(ids) do
    if storageApi.isFull() then break end
    local item = world.takeItemDrop(id, entity.id())
    storageApi.storeItem(item[1], item[2], item[3])
  end
  return not storageApi.isFull()
end
