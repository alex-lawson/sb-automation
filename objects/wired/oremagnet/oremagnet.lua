function init(virtual)
  if not virtual then
    energy.init()

    self.oreTypes = {
      copper = true,
      iron = true,
      silver = true,
      gold = true,
      titanium = true,
      lead = true,
      metal = true,
      rubium = true,
      uranium = true,
      solarium = true,
      plutonium = true,
      cerulium = true,
      platinum = true,
      aegisalt = true
    }

    local range = 100
    local bl = entity.toAbsolutePosition({-range, -range})
    local tr = entity.toAbsolutePosition({range, range})
    self.oreLocs = findOres(bl, tr)
    table.sort(self.oreLocs, compareDistance)

    world.logInfo("registered %d ores: %s", #self.oreLocs, self.oreLocs)

    entity.setInteractive(not entity.isInboundNodeConnected(0))

    storage.state = storage.state or false
    checkNodes()
  end
end

function die()
  energy.die()
end

function onInteraction(args)
  if not entity.isInboundNodeConnected(0) then
    storage.state = not storage.state
    updateAnimationState()
  end
end

function main()
  energy.update()

  if storage.state then
    pullOres()
  end
end

function onInboundNodeChange(args) 
  checkNodes()
end
 
function onNodeConnectionChange()
  checkNodes()
end

function checkNodes()
  entity.setInteractive(not entity.isInboundNodeConnected(0))
  if entity.isInboundNodeConnected(0) then
    storage.state = entity.getInboundNodeLevel(0)
  end
  updateAnimationState()
end

function updateAnimationState()
  if storage.state then
    entity.setAnimationState("magnetState", "on")
  else
    entity.setAnimationState("magnetState", "off")
  end
end

function findOres(pos1, pos2)
  world.logInfo("finding ores in area from %s to %s", pos1, pos2)

  local oreLocs = {}

  for x=pos1[1], pos2[1] do
    for y=pos1[2], pos2[2] do
      local mod = world.mod({x, y}, "foreground")
      if mod and self.oreTypes[mod] then
        world.logInfo("found %s at %d, %d", mod, x, y)
        oreLocs[#oreLocs + 1] = {position={x, y}, mod=mod, active=true}
      end
    end
  end

  return oreLocs
end

function compareDistance(a, b)
  return world.magnitude(entity.position(), a.position) < world.magnitude(entity.position(), b.position)
end

function math.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function pullOres()
  for i, ore in ipairs(self.oreLocs) do
    if ore.active then
      if world.mod(ore.position, "foreground") == ore.mod then
        -- find closer space
        local relPos = {ore.position[1] - entity.position()[1], ore.position[2] - entity.position()[2]}
        local magnitude = math.sqrt((relPos[1] ^ 2) + (relPos[2] ^ 2)) * 1.2
        local jitter  = {math.random() * 0.5 - 0.25, math.random() * 0.5 - 0.25}
        local newPos = {math.round(ore.position[1] - (relPos[1] / magnitude) + jitter[1]), math.round(ore.position[2] - (relPos[2] / magnitude) + jitter[2])}

        -- check suitability (foreground material, existing mods)
        --world.logInfo("checking suitability to move %s from %s to %s", ore.mod, ore.position, newPos)

        if world.material(newPos, "foreground") then
          local prevMod = world.mod(newPos, "foreground")
          if not prevMod then
            prevMod = "sand"
          end
          if not self.oreTypes[prevMod] then
            if world.placeMod(newPos, "foreground", ore.mod) then
              world.placeMod(ore.position, "foreground", prevMod)
              ore.position = newPos
            end
          end
        end
      else
        ore.active = false
      end
    end
  end
end