------------------------------------
-- simulation of missed lua api

function print(...)
  local arg={...}

  local printResult = ""
  for i,v in ipairs(arg) do
    printResult = printResult .. tostring(v)
  end

  world.logInfo("%s", printResult)
end

------------------------------------
-- lua tools

function printf(frmt, ...)
  world.logInfo(frmt, ...)
end

function inspectInternal(key, value, prefix) 
  local out = prefix and prefix..".%s" or "%s" 
  if type(value) == "table" then 
    for k, v in pairs(value) do
      inspectInternal(k, v, prefix.."."..key)
    end
  else 
    out = type(value) == "function" and out.."()" or out.." = %s" 
    print(out:format(key, tostring(value))) 
  end 
end

function inspect(table, prefix)
  world.logInfo("inspecting %@:", prefix)
  local name = prefix
  for k, v in pairs(table) do
    inspectInternal(k, v, prefix);
  end
end 

------------------------------------
-- game tools

function getLocationName()
  if ((world.info() ~= nil) and (world.info().name ~= "")) then
    return world.info().name
  else
    return "Ship"
  end
 
end
