function init(args)
    entity.setInteractive(true)
end

function initialize(attr, slots)
    storage.objectId = attr.objectId
    storage.direction = attr.direction
    storage.slots = slots
    entity.setFacingDirection(storage.direction)
    equip(slots)
end

function equip(slots)
    slots = slots or storage.slots
    if slots then
        for slot, item in pairs(slots) do
            entity.setItemSlot(slot, item)
        end
    end
end

function interact(args)
    if args.sourceId then
        local primaryItem = world.entityHandItem(args.sourceId,"primary")
        local altItem = world.entityHandItem(args.sourceId,"alt")

        if primaryItem then
            checkItem(primaryItem, "primary")
        end
        if altItem then
            checkItem(altItem, "primary")
        end
    end
    entity.setFacingDirection(storage.direction)
end

function checkItem(item, handSlot)
    primary = primary or false
    local itemType = world.itemType(item)
    if type(item) == "string" then
        item = {item, 1, {level = 2}}
    end
    local allowedHand = {sword = 1, shield = 1, gun = 1, instrument = 1, beamminingtool = 1, wiretool = 1, flashlight = 1, miningtool = 1, harvestingtool = 1, paintingbeamtool = 1 , tillingtool = 1}
    if itemType then
        if allowedHand[itemType] then
            setSlot(handSlot, item)
        elseif itemType == "headarmor" then
            setSlot("head", item)
        elseif itemType == "chestarmor" then
            setSlot("chest", item)
        elseif itemType == "legsarmor" then
            setSlot("legs", item)
        elseif itemType == "backarmor" then
            setSlot("back", item)
        end
    end
end

function isMannequin()
    return true
end

function getSlots(id)
    storage.objectId = id
    return storage.slots
end

function setSlot(slot, item)
    storage.slots[slot] = item
    entity.setItemSlot(slot, item)
end

function die()
    local call = world.callScriptedEntity(storage.objectId, "revive", storage.slots)
    return false
end