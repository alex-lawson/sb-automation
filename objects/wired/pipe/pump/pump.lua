function init(args)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe,itemPipe})
end

function onInteraction(args)

  --pump liquid
  local getLiquidList = pullLiquid(1)
  for entityId, getLiquid in pairs(getLiquidList) do
    getLiquid[2] = 1400
    
    if getLiquid and peekLiquid("put", 1, getLiquid) then
      pushLiquid(1, getLiquid)
    end
  end
  
  --Pump items
  local getItemList = pullItem(1)
  
  for entityId, getItems in pairs(getItemList) do
    if getItems and peekItem("put", 1, getItems) then
      pushItem(1, getItems)
    end
  end
end

function main(args)
  pipes.update(entity.dt())
end