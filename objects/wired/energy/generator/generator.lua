function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
  end
end

function main()
  -- yes, it really is that easy. uses the energyGenerationRate config parameter
  energy.generateEnergy()

  energy.update()
  datawire.update()
end