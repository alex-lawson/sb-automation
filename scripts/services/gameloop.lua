gameloop = gameloop or {}

function gameloop.init()
  storage.gameloop = {}
  storage.gameloop.listeners = {}
  storage.gameloop.initialized = true
end

function gameloop.globalInit()
  if (math.starfoundry and
      math.starfoundry.gameloop and
      math.starfoundry.gameloop.initialized) then
    return
  end
    
  math.starfoundry = math.starfoundry or {}
  math.starfoundry.gameloop = math.starfoundry.gameloop or {}
  math.starfoundry.gameloop.objects = math.starfoundry.gameloop.objects or {}
  
  math.starfoundry.gameloop.objects.last = -1
  math.starfoundry.gameloop.objects.lastUpdated = math.huge
  math.starfoundry.gameloop.listeners = { }
  
  math.starfoundry.gameloop.initialized = true
end


function gameloop.update()
  gameloop.globalInit()
    
  local id = entity.id()
  local index
  if (not math.starfoundry.gameloop.objects[id]) then
    local newIndex = math.starfoundry.gameloop.objects.last + 1
    math.starfoundry.gameloop.objects.last = newIndex
    math.starfoundry.gameloop.objects[id] = newIndex
   
    --printf("mark: object %s (%d) registred at index %d",
    --  entity.configParameter("objectName"), entity.id(),
    --  math.starfoundry.gameloop.objects.last)
    index = newIndex
  else
    index = math.starfoundry.gameloop.objects[id]
  end
 
  if (index <= math.starfoundry.gameloop.objects.lastUpdated) then
    --printf("%s: mark: new frame", getLocationName())
    gameloop.notifyListeners()
  end
 
  math.starfoundry.gameloop.objects.lastUpdated = index
end

function gameloop.notifyListeners()
  for i, listenerName in ipairs(storage.gameloop.listeners) do
    if (_ENV[listenerName].gameloopUpdate) then _ENV[listenerName].gameloopUpdate() end
  end
end

function gameloop.registerListener(listenerName)
  print("registerListener ", listenerName)
  table.insert(storage.gameloop.listeners, listenerName)
end