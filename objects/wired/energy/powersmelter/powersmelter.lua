function init(virtual)
  if not virtual then
    energy.init()
    datawire.init()
    pipes.init({itemPipe})
    --TODO: set up storage api
  end
end

function die()
  energy.die()
  --TODO: cleanup storage api
end

function onInteraction(args)
  storage.state = not storage.state
end

function main()
  if storage.state and energy.consumeEnergy() then
    -- smelt stuff
  end
  energy.update()
  datawire.update()
  pipes.update(entity.dt())
end