function init(args)
   if not self.initialized and not args then
      self.initialized = true
      entity.setInteractive(true)
      if storage.mode == nil then
          storage.mode = "all"
      end
      entity.setAllOutboundNodes(false)

      entity.setGlobalTag("modePart", storage.mode)
      self.countdown = 0
   end
end

function on()
   entity.setAllOutboundNodes(true)
   entity.setAnimationState("detectorState", "on")
   self.countdown = entity.configParameter("detectTickDuration")
end

function off()
   entity.setAllOutboundNodes(false)
   entity.setAnimationState("detectorState", "off")
end

function onInteraction(args)
   off()
   storage.owner = world.entityName(args["sourceId"])
   local modes = entity.configParameter("modes")
   for k, mode in ipairs(modes) do
      if mode == storage.mode then
         storage.mode = modes[k+1] or "all"
         break
      end
   end
   entity.setGlobalTag("modePart", storage.mode)
end

function main()
   if self.countdown == 0 then
      local radius, entityIds, pos = entity.configParameter("detectRadius"), {}, entity.toAbsolutePosition({1,1})
      if storage.mode == "all" then
         entityIds = world.entityQuery(pos, radius, { notAnObject = true })
      elseif storage.mode == "owner" then
         for _, entityId in pairs(world.playerQuery(pos, radius, { notAnObject = true })) do
            if world.entityName(entityId) == storage.owner then
               entityIds[1] = "test"
               break
            end
         end
      elseif storage.mode == "player" then
         entityIds = world.playerQuery(pos, radius, { notAnObject = true })
      elseif storage.mode == "monster" then
         entityIds = world.monsterQuery(pos, radius, { notAnObject = true })
      elseif storage.mode == "item" then
         entityIds = world.itemDropQuery(pos, radius, { notAnObject = true })
      elseif storage.mode == "npc" then
         entityIds = world.npcQuery(pos, radius, { notAnObject = true })
      elseif storage.mode == "solar" then
         if world.lightLevel(pos) >= entity.configParameter("lightLevel") then
            entityIds[1] = "test"
         end
      end

      if #entityIds > 0 then
         on()
      else
         off()
      end
   else
      self.countdown = self.countdown - 1
   end
end