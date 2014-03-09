function init(virtual)
  if not virtual then
    energy.init()

    -- tile mods to pull
    self.pullTypes = entity.configParameter("pullTypes") or {}

    -- tile mods not worth replacing
    self.trashTypes = entity.configParameter("trashTypes") or {}

    self.cleanupLocs = {}
    self.nullMod = "grass"

    self.pullInterval = 1
    self.pullTimer = self.pullInterval

    self.findInterval = 10
    self.findTimer = self.findInterval

    self.range = 100
    findOres()

    self.energyCost = 100

    self.needleMinPos = math.pi / 2.1
    self.needleRange = math.pi / 1.16

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

  cleanupMods()

  if self.findTimer > 0 then
    self.findTimer = self.findTimer - entity.dt()
  elseif storage.state then
    findOres()
    self.findTimer = self.findInterval
  end

  if self.pullTimer > 0 then
    self.pullTimer = self.pullTimer - entity.dt()
  elseif storage.state and energy.consumeEnergy(self.energyCost) then
    pullOres()
    self.pullTimer = self.pullInterval
  end

  updateAnimationState()
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
  if entity.animationState("magnetState") ~= "pulse" then
    if storage.state then
      if energy.getEnergy() < energy.getCapacity() then
        entity.setAnimationState("magnetState", "charge")
      else
        entity.setAnimationState("magnetState", "on")
      end
    else
      entity.setAnimationState("magnetState", "off")
    end
  end
  setNeedlePos()
end

function setNeedlePos()
  local angle = self.needleMinPos - self.needleRange * ((energy.getEnergy() / energy.getCapacity()) + (math.random() * 0.04))
  entity.rotateGroup("needle", angle)
end

function findOres()
  local pos1 = entity.toAbsolutePosition({-self.range, -self.range})
  local pos2 = entity.toAbsolutePosition({self.range, 5})

  -- world.logInfo("finding ores in area from %s to %s", pos1, pos2)

  self.oreLocs = {}

  for x=pos1[1], pos2[1] do
    for y=pos1[2], pos2[2] do
      local mod = world.mod({x, y}, "foreground")
      if mod and self.pullTypes[mod] then
        --world.logInfo("found %s at %d, %d", mod, x, y)
        self.oreLocs[#self.oreLocs + 1] = {position={x, y}, mod=mod, active=true}
      end
    end
  end

  table.sort(self.oreLocs, compareDistance)
end

function compareDistance(a, b)
  return world.magnitude(entity.position(), a.position) < world.magnitude(entity.position(), b.position)
end

function math.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function pullOres()
  entity.setAnimationState("magnetState", "pulse")

  for i, ore in ipairs(self.oreLocs) do
    if ore.active then
      if world.mod(ore.position, "foreground") == ore.mod then
        local relPos = {ore.position[1] - entity.position()[1], ore.position[2] - entity.position()[2]}
        local magnitude = math.sqrt((relPos[1] ^ 2) + (relPos[2] ^ 2)) * 1.2
        local jitter  = {math.random() * 0.8 - 0.4, math.random() * 0.8 - 0.4}
        local newPos = {math.round(ore.position[1] - (relPos[1] / magnitude) + jitter[1]), math.round(ore.position[2] - (relPos[2] / magnitude) + jitter[2])}
        local prevMod = world.mod(newPos, "foreground")

        if newPos ~= ore.position and world.material(newPos, "foreground") and not self.pullTypes[prevMod] then
          if world.placeMod(newPos, "foreground", ore.mod) then
            if prevMod and not self.trashTypes[prevMod] then
              world.placeMod(ore.position, "foreground", prevMod)
            else
              markForCleanup(ore.position)
            end
            ore.position = newPos
          end
        end
      else
        ore.active = false
      end
    end
  end
end

function markForCleanup(pos)
  world.placeMod(pos, "foreground", self.nullMod)
  self.cleanupLocs[#self.cleanupLocs + 1] = pos
end

function cleanupMods()
  if #self.cleanupLocs > 0 then
    local finalLocs = {}
    -- world.logInfo("cleaning up null mods at %s", self.cleanupLocs)
    for i, pos in ipairs(self.cleanupLocs) do
      if world.mod(pos, "foreground") == self.nullMod then
        finalLocs[#finalLocs + 1] = pos
      end
    end
    self.cleanupLocs = {}
    if #finalLocs > 0 then
      world.damageTiles(finalLocs, "foreground", entity.position(), "plantish", 0.01)
    end
  end
end