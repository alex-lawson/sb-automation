function init(args)
  pipes.init()
  entity.setInteractive(true)
end

function onInteraction(args)
  local getLiquid = pullLiquid(1)
  if getLiquid then
    pushLiquid(1, getLiquid[1], getLiquid[2])
  end
end

function main(args)
  pipes.update(entity.dt())
end