profilerApi = {}

--- Initializes the Profiler and hooks all functions
function profilerApi.init()
  if profilerApi.isInit then return end
  profilerApi.hooks = {}
  if entity ~= nil then
    for k,v in pairs(entity) do
      if type(v) == "function" then
        profilerApi.hook(entity, "entity.", v, k)
      end
    end
  end
  if world ~= nil then
    for k,v in pairs(world) do
      if type(v) == "function" then
        profilerApi.hook(world, "world.", v, k)
      end
    end
  end
  if tech ~= nil then
    for k,v in pairs(tech) do
      if type(v) == "function" then
        profilerApi.hook(tech, "tech.", v, k)
      end
    end
  end
  profilerApi.hookAll("", _ENV)
  profilerApi.isInit = true
end

--- Prints all collected data into the log ordered by total time descending
function profilerApi.logData()
  local arr = {}
  for k in pairs(t) do table.insert(arr, t) end
  table.sort(arr, profilerApi.sortHelp)
  for k in ipairs(arr) do
    local hook = profilerApi.hooks[k]
    if hook.c > 0 then
      world.logInfo(k .. ": total " .. hook.t .. ", count " .. hook.c .. ", avg " .. hook.a .. ", last " .. hook.e)
    end
  end
end

function profilerApi.sortHelp(e1, e2)
  return profilerApi.hooks[e1].t > profilerApi.hooks[e2].t
end

function profilerApi.hookAll(tn, to)
  if (tn == "entity.") or (tn == "world.") or (tn == "tech.") then return end
  if tn == "profilerApi." then return end
  for k,v in pairs(to) do
    if type(v) == "function" then
      profilerApi.hook(to, tn, v, k)
    elseif type(v) == "table" then
      profilerApi.hookAll(tn .. k .. ".", v)
    end
  end
end

function profilerApi.getTime()
  return os.time()
end

function profilerApi.hook(to, tn, fo, fn)
  local full = tn .. fn
  profilerApi.hooks[full] = { s = -1, f = fo, e = -1, t = 0, a = 0, c = 0 }
  to[fn] = function(...) profilerApi.hooked(full, ...) end
end

function profilerApi.hooked(n, ...)
  local hook = profilerApi.hooks[n]
  hook.s = profilerApi.getTime()
  hook.f(...)
  hook.e = profilerApi.getTime() - hook.s
  hook.t = hook.t + hook.e
  hook.a = hook.a * hook.c + hook.e
  hook.c = hook.c + 1
  hook.a = hook.a / hook.c
end