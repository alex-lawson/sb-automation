function init(virtual)
  if not virtual then
    energy.init()
  end
end

function die()
  energy.die()
end

function main()
  energy.update()
end