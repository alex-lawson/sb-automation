function init(args)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe,itemPipe})
end

function onInteraction(args)
  local getLiquid = pullLiquid(1)
  if getLiquid then
    getLiquid[2] = 1400
    pushLiquid(1, getLiquid)
  end
  local getItems = pullItem(1)
  if getItems then
    pushItem(1, getItems)
  end
end

function main(args)
  pipes.update(entity.dt())
end