function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
  end
end

function onEnergyReceive(amount, visited)
  --world.logInfo("Relaying energy: %s Visited: %s", amount, visited)
  datawire.sendData(amount, "number", "all")
  return energy.sendEnergy(amount, visited)
end

function main()
  energy.update()
  datawire.update()
end