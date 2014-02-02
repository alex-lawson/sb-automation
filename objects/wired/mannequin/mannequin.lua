function init(args)
    if not self.initialized and not args then
        self.initialized, self.revive = true, 7
        entity.setInteractive(false)
        entity.setColliding(false)
        if storage.slots == nil then
            storage.slots = {}
        end
        if storage.mannequin == nil then
            storage.mannequin = {}
            self.revive = 1
        end
    end
end

function main()
    if self.revive then
        if self.revive == 5 then
            -- Look for mannequin after 2 scriptDeltas
            local objectIds = world.npcQuery(entity.toAbsolutePosition({0.5, 1.8}), 1, {callScript = "isMannequin"})

            for _, objectId in pairs(objectIds) do
                storage.mannequin.id = objectId
                storage.slots = world.callScriptedEntity(storage.mannequin.id, "getSlots", entity.id())
                self.revive = false
                break
            end
        elseif self.revive == 1 then
            checkForMannequin()
            self.revive = false
        else
            self.revive = self.revive - 1
        end
    end
end

function checkForMannequin()
    if storage.mannequin.id and world.entityExists(storage.mannequin.id) then
        return true
    else
        spawnMannequin()
    end
end

function spawnMannequin()
    if not storage.mannequin.id then
        storage.mannequin.npcSpecies = entity.randomizeParameter("mannequin.npcSpeciesOptions")
        storage.mannequin.npcParameter = entity.configParameter("mannequin.npcParameter")
        storage.mannequin.npcParameter.levelVariance = {1,1}

        storage.mannequin.direction = entity.direction()
        storage.mannequin.objectId = entity.id()
    end
    storage.mannequin.id = world.spawnNpc(entity.toAbsolutePosition({0.5, 1.8}), storage.mannequin.npcSpecies, "mannequin", 1, 0, storage.mannequin.npcParameter)
    if storage.mannequin.id then
        world.callScriptedEntity(storage.mannequin.id, "initialize", storage.mannequin, storage.slots)
    end
end

function revive(slots)
    storage.slots = slots
    self.revive = 2
end

function die()
    if storage.mannequin.id then
       local pos = world.entityPosition(storage.mannequin.id)
       if pos then
           local id = entity.id()
           local playerIds = world.playerQuery(pos, 5, { order = "nearest" })
           for _, playerId in pairs(playerIds) do
               id = playerId
               break
           end
           world.spawnProjectile("damage", pos, id, { 0, 1 }, false, {power = 28, speed = 0.1 })
       end
    end
end