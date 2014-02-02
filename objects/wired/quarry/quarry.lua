function init(args)
    if not self.initialized and not args then
        energy.init()
        storageApi.init({mode = 2, capacity = 16, merge = true, join = true, ondeath = 1})
        pipes.init({itemPipe})
        entity.setInteractive(true)
        self.state = stateMachine.create({
            "prepareState", "runState", "returnState"
        })
        self.state.leavingState = function(stateName) end
        if storage.quarry == nil then
            storage.quarry = { build = false, curX = 0, curY = 0, dig = false }
        end
        self.state.pickState({})
        if storage.quarry.homePos then
            updateAnimationState()
        end
        self.ishome, self.stuck, self.range, self.initialized = true, 0, 25, true
    end
end

function main()
    local dt = entity.dt()
    self.state.update(dt)
    pipes.update(dt)
    energy.update()
    if self.ishome then
        sendItem()
    end
end

function onInteraction(args, active)
    if self.ishome and storageApi.getCount() > 0 then
        storageApi.dropAll()
    else
        self.changeDirection = true
        storage.quarry.build, storage.quarry.active = true, active or not storage.quarry.active
        if not self.state.hasState() then
            self.state.pickState({})
            if not self.state.hasState() then
                self.state.pickState({})
            end
        end
    end
    updateAnimationState()
end

-------------------

prepareState = {}

function prepareState.enterWith(args)
    if args.returnPosition or args.run then return nil end
    return {}
end

function prepareState.update(dt, data)
    if storage.quarry.build then
        if storage.quarry.fakePos == nil then
            if not prepareState.findMarker() then
                return true, 2
            end
        elseif storage.quarry.fakeId == nil then
            if not prepareState.placeStand() then
                return true, 2
            end
        elseif not storage.quarry.holders then
            if not quarryHolders() then
                return true, 2
            end
        else
            if not storage.quarry.id then
                spawnQuarry()
            else
                if not world.entityExists(storage.quarry.id) then
                    storage.quarry.id = false
                end
                if storage.quarry.id and storage.quarry.active then
                    self.ishome = false
                    local pos = false
                    if storage.quarry.returnPosition then
                        pos = storage.quarry.returnPosition
                    else
                        pos = toAbsolutePosition(storage.quarry.homePos, {
                            storage.quarry.curX*storage.quarry.dir, storage.quarry.curY
                        })
                    end
                    if  not inPosition(world.distance(pos, world.entityPosition(storage.quarry.id))) then
                        if storage.curEnergy < 1 or self.stuck > 5 then
                            storage.quarry.active = false
                            storage.quarry.returnPosition, storage.quarry.returnDirection, storage.quarry.run = storage.quarry.homePos, 1,nil
                        else
                            storage.quarry.returnPosition, storage.quarry.returnDirection, storage.quarry.run = pos,-1,nil
                        end
                        self.state.pickState( storage.quarry )
                    else
                        storage.quarry.returnDirection, storage.quarry.returnPosition, storage.quarry.run = nil, nil, 1
                        self.state.pickState(storage.quarry)
                    end
                end
            end
        end
    end
    return false
end

function prepareState.findMarker()
    local quarryPos, markerId, dir = entity.toAbsolutePosition({0,-1}), false, entity.direction()
    for i = 2, self.range, 1 do
        local pos = toAbsolutePosition(quarryPos, {dir*i,0})
        local entityIds = world.entityQuery(pos, 0, {name = "quarry_marker"})
        if #entityIds > 0 and world.entityName(entityIds[1]) == "quarry_marker" then
            markerId = { entityIds[1], pos}
        end
    end
    if markerId then
        local pos, dir, collisionPos = markerId[2], entity.direction(), {}
        if dir < 0 then
            collisionPos = { pos[1] - dir*2, pos[2], quarryPos[1] + dir*2, quarryPos[2] + 1 }
        else
            collisionPos = { quarryPos[1] + dir*2, quarryPos[2], pos[1] - dir*2, pos[2] + 1 }
        end
        if not world.rectCollision(collisionPos) then
            if world.damageTiles({pos}, "foreground", pos, "blockish", 1000) then
                storage.quarry.pos, storage.quarry.fakePos = quarryPos, toAbsolutePosition(pos, {0,1})
                storage.quarry.width = math.ceil(math.abs(world.distance(pos, quarryPos)[1]))-3
                return true
            end
        else
            for _, h in ipairs({0,1}) do
                for i = 2, math.abs(pos[1]-quarryPos[1]), 1 do
                    local pos = toAbsolutePosition(quarryPos, {dir*i,h+0.5})
                    if not world.pointCollision(pos) then
                        world.spawnProjectile("beam", pos, entity.id(), {0,0}, false, {})
                    end
                end
            end
            storage.quarry.active = false
        end
    end
    return false
end

function prepareState.placeStand()
    local fakeQuarryId = world.placeObject("quarry_fake", storage.quarry.fakePos, -entity.direction() )
    if fakeQuarryId then
        storage.quarry.fakeId = fakeQuarryId
        return quarryHolders()
    end
    return false
end

function quarryHolders(destroy)
    if not storage.quarry.holders or destroy then
        local i, dir, pos = 1, entity.direction(), {0, storage.quarry.fakePos[2]}
        while i <= storage.quarry.width+1 do
            pos[1] = i*-dir+storage.quarry.fakePos[1]
            if destroy then
                world.damageTiles({pos}, "foreground", storage.quarry.fakePos, "blockish", 2200)
            else
                world.placeObject("quarry_holder", pos, dir )
            end
            i = i + 1
        end
        storage.quarry.holders = not destroy
        if not destroy then
            entity.setAnimationState("quarryState", "idle")
            local spawnPos = entity.toAbsolutePosition({dir, 0})
            if dir > 0 then
                spawnPos[1] = spawnPos[1] + 1
            end
            storage.quarry.pos, storage.quarry.homePos = spawnPos, spawnPos
            storage.quarry.dir, storage.quarry.curDir = dir, dir
        end
        return true
    end
    return false
end

----------------------

runState = {}

function runState.enterWith(args)
    if not args.run or not storage.quarry.id or energy.getEnergy() < 1 then return nil end
    self.stuck = 0
    entity.setAnimationState("quarryState", "run")
    return storage.quarry
end

function runState.update(dt, data)
    storage.quarry = data
    local quarryPos = world.entityPosition(storage.quarry.id)
    if storage.quarry.active and energy.consumeEnergy() and not storageApi.isFull() then
        if quarryPos then
            -- Check for stuck
            if inPosition({data.pos[1]-quarryPos[1],data.pos[2]-quarryPos[2]},0.01) then
                self.stuck = self.stuck + 1
                if self.stuck > 4 then
                    data.curX, data.curY = 0, data.curY + 2
                    if data.curY > 0 then data.curY = 0 end
                    return true
                end
            end
            data.pos = quarryPos
            local desiredPos = toAbsolutePosition(data.homePos, {data.curX*data.dir, data.curY})
            local distance = world.distance(desiredPos, quarryPos)
            if self.justspawned then
                data.dig, self.justspawned = runState.dig(data, desiredPos), nil
            end
            if data.dig then
                local colCheck = world.collisionBlocksAlongLine(data.dig[1],data.dig[2], true, 2)
                if data.dig[3] and #colCheck == 0 then
                    local colCheck2 = world.collisionBlocksAlongLine(data.dig[3],data.dig[4], true, 2)
                    for _, v in ipairs(colCheck2) do
                        colCheck[#colCheck+1] = v
                    end
                end
                if #colCheck > 0 then
                    world.damageTiles(data.dig, "foreground", quarryPos, "blockish", 2500)
                    return false
                end
                data.dig = false
                storageApi.take(toAbsolutePosition(quarryPos, {0,-2}), 3, data.id)
            end
            if moveQuarry(distance) then
                return false
            end
            -- didn't had to move so it's not stuck (as it could move before..)
            self.stuck = 0
            if not data.dig then
                local digged = false
                data.dig, digged = runState.dig(data,desiredPos)
                if digged then
                    world.callScriptedEntity(data.id, "dig")
                end
            end
            
            if (data.curDir == data.dir and data.curX < data.width) or (data.curX > 0 and data.curDir ~= data.dir) then
                if data.curDir == data.dir then
                    data.curX = data.curX + 2
                else
                    data.curX = data.curX - 2
                end
                data.curX = math.max(math.min(data.curX, data.width), 0)
                self.justdid = false
            else
                --See how many rows down we can go
                local row = 0
                local collisions1 = {}
                local collisions2 = {}
                repeat
                    row = row - 2
                    collisions1 = world.collisionBlocksAlongLine(toAbsolutePosition(data.homePos, {-0.5, data.curY + row - 1.5}), toAbsolutePosition(data.homePos, {data.width * data.dir + 0.5, data.curY + row - 1.5}))
                    collisions2 = world.collisionBlocksAlongLine(toAbsolutePosition(data.homePos, {-0.5, data.curY + row - 2.5}), toAbsolutePosition(data.homePos, {data.width * data.dir + 0.5, data.curY + row - 2.5}))
                    world.logInfo("Quarry sez coll1: %s coll2: %s", collisions1, collisions2)
                until #collisions1 > 0 or #collisions2 > 0

                data.curY, data.curDir = data.curY + row, -data.curDir
            end


            return false
        else
            if not self.justspawned then
                if storage.quarry.id then
                    world.callScriptedEntity(storage.quarry.id, "damage")
                end
                data.id, self.justspawned = spawnQuarry(), true
                return false
            end
            return true
        end
    end
    return true
end

function runState.dig(data, desiredPos)
    data.dig = {
        toAbsolutePosition(desiredPos, {-0.5, -1.5 }), toAbsolutePosition(desiredPos, {-0.5, -2.5 }),
        toAbsolutePosition(desiredPos, { 0.5, -1.5 }), toAbsolutePosition(desiredPos, { 0.5, -2.5 })
    }
    --Exception if width is uneven
    if data.curX == data.width and data.width%2 ~= 0 and not self.justdid then
        self.justdid = true
        if data.curDir > 0 then
            table.remove(data.dig, 2)
            table.remove(data.dig, 1)
        else
            table.remove(data.dig, 4)
            table.remove(data.dig, 3)
        end
    end
    if world.damageTiles(data.dig, "foreground", desiredPos, "blockish", 2500) then
        return data.dig, true
    end
    return data.dig, false
end

function runState.leavingState(data)
    data.returnPosition, data.returnDirection, data.run = data.homePos, 1, nil
    if data.id then
       world.callScriptedEntity(data.id, "collide")
    end
    self.state.pickState(data)
end

------------------

returnState = {}

function returnState.enterWith(args)
    if not args.returnPosition then return nil end
    storage.quarry = args
    updateAnimationState()
    self.done, self.stuck, self.changeDirection = false, 0, false
    return args
end

function returnState.update(dt, data)
    storage.quarry = data
    local quarryPos = world.entityPosition(storage.quarry.id)
    if quarryPos and not self.changeDirection then
        if inPosition({data.pos[1]-quarryPos[1],data.pos[2]-quarryPos[2]},0.01) then
            self.stuck = self.stuck + 1
            if self.stuck > 5 then
                if data.returnDirection > 0 then
                    data.run, data.active, data.curX, data.curY, data.id, self.done = nil, false, 0, 0, respawnQuarry(data.homePos), true
                    return true
                end
                data.run, data.curX, data.curY = false, 0, math.min(-math.ceil(world.distance(data.homePos, quarryPos)[2])+3,0)
                return true
            end
        end
        data.pos = quarryPos
        local distance = world.distance(data.returnPosition, quarryPos)
        if moveQuarry(distance) then
            return false
        end
        self.done = true
        return true
    end
    return true
end

function returnState.leavingState(data)
    if data.returnDirection > 0 and self.done then
        cameHome()
        data.run, data.active = nil, false
    elseif data.returnDirection < 0 and self.stuck < 6 then
        data.run = 1
    end
    data.returnPosition, data.returnDirection, self.done, self.changeDirection = nil, nil, false, false
    storage.quarry = data

    if data.id then world.callScriptedEntity(data.id, "collide") end
    updateAnimationState()
    self.state.pickState(data)
end

-------------------------------------

function spawnQuarry(pos)
    pos = pos or storage.quarry.pos
    if pos then
        local quarryId = world.spawnMonster("squarry", pos)
        if quarryId then
            storage.quarry.id = quarryId
        end
    end
    return storage.quarry.id
end

function respawnQuarry(pos)
    killQuarry()
    return spawnQuarry(pos)
end

function killQuarry()
    if storage.quarry.id then
        world.callScriptedEntity(storage.quarry.id, "damage")
        storage.quarry.id = nil
    end
end

function moveQuarry(distance)
    if not inPosition(distance, 0.04) then
        local chainlength = (storage.quarry.homePos[2] - storage.quarry.pos[2])*8+2
        local push, max = entity.configParameter("push"), entity.configParameter("maxSpeed")
        if distance[1] > 0.04 then
            distance[1] = math.min(distance[1]+push[1], max[1])
        elseif distance[1] < -0.04 then
            distance[1] = math.max(distance[1]-push[1], -max[1])
        end
        if distance[2] > 0.04 then
            chainlength = chainlength -2
            distance[2] = math.min(distance[2]+push[2], max[2])
        elseif distance[2] < -0.04 then
            distance[2] = math.max(distance[2]-push[2], -max[2])
        end
        world.callScriptedEntity(storage.quarry.id, "move", {velocity = distance, chain = chainlength})
        return true
    end
    return false
end

function cameHome()
    self.ishome = true
    updateAnimationState()
end

function sendItem()
    if next(pipes.nodeEntities) ~= nil and storageApi.getCount() > 0 then
        for i,item in storageApi.getIterator() do
            local tarNode = 1
            if entity.direction() == -1 then
                tarNode = 2
            end
            local result = pushItem(tarNode, item)
            if result == true then storageApi.returnItem(i) end --Whole stack was accepted
            if result and result ~= true then item.count = item.count - result end --Only part of the stack was accepted
            if result then
                if storageApi.getCount() == 0 then
                    updateAnimationState()
                end
            end
        end
    end
end

function updateAnimationState()
    if energy.getEnergy() > 1 then
        if storage.quarry.run then
            entity.setAnimationState("quarryState", "run")
        elseif storage.quarry.returnPosition then
            if storage.quarry.returnDirection > 0 then
                entity.setAnimationState("quarryState", "return")
            else
                entity.setAnimationState("quarryState", "run")
            end
        elseif storageApi.getCount() > 0 then
            entity.setAnimationState("quarryState", "items")
        else
            entity.setAnimationState("quarryState", "idle")
        end
    else
        entity.setAnimationState("quarryState", "energy")
    end
end

function toAbsolutePosition(pos, vec)
    return {vec[1] + pos[1], vec[2] + pos[2]}
end

function inPosition(distance, marge)
    marge = marge or 0.01
    if math.abs(distance[1]) > marge or math.abs(distance[2]) > marge then
        return false
    end
    return true
end

function onNodeConnectionChange(args)
    updateAnimationState()
end

function onInboundNodeChange(args)
    onInteraction({}, args.level)
end

function isActive()
    return storage.quarry.active and storage.quarry.run and not storage.quarry.returnPosition
end

function die()
    energy.die()
    storageApi.dropAll()
    killQuarry()
    quarryHolders(true)
    if storage.quarry.fakePos then
        world.damageTiles({storage.quarry.fakePos}, "foreground", storage.quarry.fakePos, "blockish", 2200)
    end
end