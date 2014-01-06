function init(args)
  pipes.init()
  entity.setInteractive(true)
end

function onInteraction(args)
  local getLiquid = pullLiquid(1)
  if getLiquid then
    pushLiquid(1, getLiquid[1], getLiquid[2])
  end
  local getItems = pullItem(1)
  if getItems then
    pushItem(1, getItems)
  end
end

function main(args)
  pipes.update(entity.dt())
end