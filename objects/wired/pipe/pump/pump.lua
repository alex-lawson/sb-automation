function init(args)
  entity.setInteractive(true)
  
  pipes.init({liquidPipe})
end

function onInteraction(args)
  --pump liquid
  local canGetLiquid = peekPullLiquid(1)
  local canPutLiquid = peekPushLiquid(1, canGetLiquid)
  world.logInfo("%s %s", canGetLiquid, canPutLiquid)
  
  if canGetLiquid and canPutLiquid then
    local liquid = pullLiquid(1)
    liquid[2] = 1400 --Set amount to 1400 because reasons
    pushLiquid(1, liquid)
  end
end

function main(args)
  pipes.update(entity.dt())
end