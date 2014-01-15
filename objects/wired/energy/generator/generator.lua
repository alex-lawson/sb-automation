function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
  end
end

function main()
  energy.setEnergy(100) --unlimited generation for testing
  energy.update()
  datawire.update()
  energy.setEnergy(100) --unlimited generation for testing
end