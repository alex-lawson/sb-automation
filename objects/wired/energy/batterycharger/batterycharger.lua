function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
  end
end

function die()
  energy.die()
end

function main()
  energy.update()
  datawire.update()
end