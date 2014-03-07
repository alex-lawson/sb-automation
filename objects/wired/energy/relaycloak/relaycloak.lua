function init(virtual)
  if not virtual then
    entity.setInteractive(true)

    self.range = 70

    self.modes = { "default", "subtle", "hidden" }
    storage.currentMode = storage.currentMode or self.modes[1]

    updateRelays(storage.currentMode)
  end
end

function onInteraction(args)
  cycleMode()
end

function main()
  --updateRelays(storage.currentMode)
end

function cycleMode()
  for i, mode in ipairs(self.modes) do
    if mode == storage.currentMode then
      storage.currentMode = self.modes[(i % #self.modes) + 1]
      updateRelays(storage.currentMode)
      return
    end
  end

  --previous mode invalid, default to mode 1
  storage.currentMode = self.modes[1]
  updateRelays(storage.currentMode)
end

function updateRelays(variant)
  local relays = world.objectQuery(entity.toAbsolutePosition({-self.range, -self.range}), entity.toAbsolutePosition({self.range, self.range}), {callScript = "setRelayVariant", callScriptArgs = {variant}})
  --world.logInfo("successfully updated %d relays: %s", #relays, relays)

  updateAnimationState()
end

function updateAnimationState()
  entity.setAnimationState("cloakState", storage.currentMode)
end