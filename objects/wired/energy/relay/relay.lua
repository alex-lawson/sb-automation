function init(virtual)
  if not virtual then
    energy.init()
  end
end

function die()
  energy.die()
end

function onEnergyReceive(amount, visited)
  --world.logInfo("Relaying energy: %s Visited: %s", amount, visited)
  return energy.sendEnergy(amount, visited)
end

function main()
  energy.update()
end