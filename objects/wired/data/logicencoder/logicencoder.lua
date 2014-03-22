function init(virtual)
  if not virtual then
    self.inventory = {}
    self.gateSlot = 0
    self.trashSlot = 3
    self.actSymSlots = {8, 9, 10, 11, 12, 13, 14, 15}
    self.srcSymSlots = {16, 17, 18, 19, 20, 21, 22, 23}
    self.srcSymPalette = {
      {name="sym_a",count=1,data={}},
      {name="sym_b",count=1,data={}},
      {name="sym_not",count=1,data={}},
      {name="sym_and",count=1,data={}},
      {name="sym_or",count=1,data={}},
      {name="sym_xor",count=1,data={}}
    }
    self.dropPoint = entity.toAbsolutePosition({0, 1})
  end
end

function main()
  -- check current inventory
  self.inventory = world.containerItems(entity.id())
  -- world.logInfo("items this tick: %s", self.inventory)

  -- eject illegal items

  -- sync gate < - > active symbols
  buildGate()

  -- replenish source symbols
  fillSourceSymbols()

  -- take out the garbage
  emptyTrash()
end

function die()
  -- don't drop all those messy symbols and things
  world.containerTakeAt(entity.id(), self.gateSlot)
  for i, slotId in ipairs(self.actSymSlots) do
    world.containerTakeAt(entity.id(), slotId)
  end
  for i, slotId in ipairs(self.srcSymSlots) do
    world.containerTakeAt(entity.id(), slotId)
  end
end

-- builds a custom logic gate object from the current active symbol set
function buildGate()
  -- empty the current contents of the gate slot
  if self.inventory[self.gateSlot + 1] then
    local oldStack = self.inventory[self.gateSlot + 1]
    if oldStack.name == "customgate" then
      world.containerConsumeAt(entity.id(), self.gateSlot, oldStack.count)
    else
      local ejectStack = world.containerTakeAt(entity.id(), self.gateSlot)
      eject(ejectStack)
    end
  end

  -- interpret the current symbols
  local symbols = {}
  for i, slotId in ipairs(self.actSymSlots) do
    if self.inventory[slotId + 1] then
      symbols[#symbols + 1] = self.inventory[slotId + 1].name:sub(5)
    end
  end

  -- world.logInfo("current active symbol set: %s", symbols)

  -- create a new gate
  local newGate = {name="customgate",count=1,data={
      color="green"
    }}
  world.containerPutItemsAt(entity.id(), newGate, self.gateSlot)
end

-- replenishes the symbol palette
function fillSourceSymbols()
  for i, slotId in ipairs(self.srcSymSlots) do
    if self.srcSymPalette[i] then
      local palStack = self.srcSymPalette[i]
      local slotStack = self.inventory[slotId + 1]
      if slotStack then
        -- world.logInfo("comparing slot contents %s to palette %s", slotStack, palStack)
        if slotStack.name == palStack.name then
          if slotStack.count == palStack.count then
            -- world.logInfo("That'll do, slot %d, that'll do.", slotId)
            -- perfect, do nothing!
          elseif slotStack.count > palStack.count then
            world.logInfo("removing some items in slot %d", slotId)
            -- right item, but too many, so remove some
            world.containerConsumeAt(entity.id(), slotId, slotStack.count - palStack.count)
          else
            world.logInfo("adding some items in slot %d", slotId)
            -- right item, but too few, so add some
            local putStack = {name=palStack.name,count=palStack.count-slotStack.count,data=palStack.data}
            world.containerPutItemsAt(entity.id(), putStack, slotId)
          end
        else
          world.logInfo("replacing some items in slot %d", slotId)
          -- different item, throw it out!
          if slotStack.name:sub(1, 4) == "sym_" then
            -- don't bother ejecting symbols
            world.containerConsumeAt(entity.id(), slotId, slotStack.count)
          else
            -- ...but do eject potentially important items
            local ejectStack = world.containerTakeAt(entity.id(), slotId)
            eject(ejectStack)
          end

          -- now, fill it with the correct item from the palette
          world.containerPutItemsAt(entity.id(), palStack, slotId)
        end
      else
        world.logInfo("refilling empty slot %d", slotId)
        -- empty slot, just fill it up
        world.containerPutItemsAt(entity.id(), palStack, slotId)
      end
    end
  end
end

-- spawn the specified item stack at the object's location
function eject(item)
  if item then
    if next(item.data) == nil then 
      world.spawnItem(item.name, self.dropPoint, item.count)
    else
      world.spawnItem(item.name, self.dropPoint, item.count, item.data)
    end
  end
end

-- delete the item in the trash slot
function emptyTrash()
  world.containerTakeAt(entity.id(), self.trashSlot)
end