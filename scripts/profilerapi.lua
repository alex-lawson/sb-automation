profilerApi = {}

--- Initializes the Profiler and hooks all functions
function profilerApi.init()
  if profilerApi.isInit then return end
  profilerApi.hooks = {}
  profilerApi.hookAll("", _ENV)
  profilerApi.isInit = true
end

--- Prints all collected data into the log ordered by total time descending
function profilerApi.logData()
  local arr = {}
  local len, cnt = 0, 0
  for k in pairs(profilerApi.hooks) do
    table.insert(arr, k)
    local l = string.len(k)
    if l > len then len = l end
    l = profilerApi.hooks[k].c
    if l > cnt then cnt = l end
  end
  table.sort(arr, profilerApi.sortHelp)
  for i,k in ipairs(arr) do
    local hook = profilerApi.hooks[k]
    if hook.t > 0 then
      world.logInfo(string.format("%" .. len .. "s: total %.15f, cnt %" .. cnt .. "i, avg %.15f, last %.15f", k, hook.t, hook.c, hook.a, hook.e))
    end
  end
end

function profilerApi.sortHelp(e1, e2)
  return profilerApi.hooks[e1].t > profilerApi.hooks[e2].t
end

function profilerApi.canHook(fn)
  local un = { "pairs", "ipairs", "type", "next", "assert", "error", "print", "setmetatable", "select", "rawset", "rawlen", "pcall" }
  for i,v in ipairs(un) do
    if v == fn then return false end
  end
  return true
end

function profilerApi.hookAll(tn, to)
  if (tn == "profilerApi.") or (tn == "table.") or (tn == "coroutine.") or (tn == "os.") then return end
  for k,v in pairs(to) do
    if type(v) == "function" then
      if (tn ~= "") or profilerApi.canHook(k) then
        profilerApi.hook(to, tn, v, k)
      end
    elseif type(v) == "table" then
      profilerApi.hookAll(tn .. k .. ".", v)
    end
  end
end

function profilerApi.getTime()
  return os.clock()
end

function profilerApi.hook(to, tn, fo, fn)
  local full = tn .. fn
  profilerApi.hooks[full] = { s = -1, f = fo, e = -1, t = 0, a = 0, c = 0 }
  to[fn] = function(...) return profilerApi.hooked(full, ...) end
end

function profilerApi.hooked(n, ...)
  local hook = profilerApi.hooks[n]
  hook.s = profilerApi.getTime()
  local ret = hook.f(...)
  hook.e = profilerApi.getTime() - hook.s
  hook.t = hook.t + hook.e
  hook.a = hook.a * hook.c + hook.e
  hook.c = hook.c + 1
  hook.a = hook.a / hook.c
  return ret
end