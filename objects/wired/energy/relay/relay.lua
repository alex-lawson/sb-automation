function init(virtual)
  if not virtual then
    energy.init()
  end
end

function onEnergyReceive(amount, visited)
  --world.logInfo("Relaying energy: %s Visited: %s", amount, visited)
  return energy.sendEnergy(amount, visited)
end

function main()
  energy.update()
end