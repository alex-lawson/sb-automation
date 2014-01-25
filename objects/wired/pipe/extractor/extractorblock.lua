function init(virtual)
  if virtual == false then
    entity.setInteractive(false)
    self.maxHealth = entity.configParameter("health")
    if storage.health == nil then storage.health = self.maxHealth end
    local initState = entity.configParameter("initState")
    if initState then entity.setAnimationState("blocktype", initState) end
  end
end

function setBlockState(state)
  world.logInfo("Block state: %s", state)
  
end

function damageBlock(amount)
  storage.health = storage.health - amount
  local damage = self.maxHealth - storage.health
  local damageState = tostring(math.min(math.ceil((damage / self.maxHealth) * 5), 5))
  entity.setAnimationState("damage", damageState)
  
  if storage.health <= 0 then
    entity.smash()
  end
end
