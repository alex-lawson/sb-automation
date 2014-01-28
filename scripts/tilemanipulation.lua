--- Converts a list of absolute tile locations to a list of relative tile locations
-- @param tileArea the list of [x, y] positions to be converted
-- @returns a converted list of [x, y] positions
function absTileAreaToRel(tileArea)
  local ePos = entity.position()
  local newTileArea = {}
  for i, pos in ipairs(tileArea) do
    newTileArea[i] = { pos[1] - ePos[1], pos[2] - ePos[2] }
  end
  return newTileArea
end

--- Converts a list of relative tile locations to a list of absolute tile locations
-- @param tileArea the list of [x, y] positions to be converted
-- @returns a converted list of [x, y] positions
function relTileAreaToAbs(tileArea)
  local ePos = entity.position()
  local newTileArea = {}
  for i, pos in ipairs(tileArea) do
    newTileArea[i] = { pos[1] + ePos[1], pos[2] + ePos[2] }
  end
  return newTileArea
end

--- Scans the placed tiles in an area of the world
-- @param tileArea list of absolute tile positions to be scanned
-- @param targetLayer layer to be scanned ("foreground" or "background")
-- @returns list of tile values, will be a material name string if found or false if the tile is empty
function scanLayer(tileArea, targetLayer)
  --world.logInfo("in scanLayer ("..targetLayer..")")
  --world.logInfo(tileArea)
  local scanData = {}
  for i, pos in ipairs(tileArea) do
    local sample = world.material(pos, targetLayer)
    if sample and sample ~= "invisitile" then
      scanData[i] = sample
    else
      scanData[i] = false
    end
  end

  return scanData
end

--- Destroys the placed tiles in an area of the world
-- @param tileArea list of absolute tile positions to be destroyed
-- @param targetLayer layer to be destroyed ("foreground" or "background")
-- @param dropItems if true, the material items will be dropped, otherwise they will be destroyed
function breakLayer(tileArea, targetLayer, dropItems)
  --world.logInfo("in breakLayer ("..targetLayer..")")
  if dropItems then
    world.damageTiles(tileArea, targetLayer, entity.position(), "blockish", 9999)
  else
    world.damageTiles(tileArea, targetLayer, entity.position(), "crushing", 9999)
  end
end

--- Places a list of tiles in an area of the world
-- @param tileArea list of absolute tile positions where the materials will be placed
-- @param targetLayer layer for the materials to be placed ("foreground" or "background")
-- @param tileData list of material names (or false for blank tiles). indexes in this list should correspond to indexes in the tileArea list
-- @param conserveMaterial if true, blocks that can't be placed will be dropped as items
function placeLayer(tileArea, targetLayer, tileData, conserveMaterial)
  if conserveMaterial == nil then
    conserveMaterial = false
  end

  --world.logInfo("in placeLayer ("..targetLayer..")")
  --world.logInfo(tileData)

  --track failure counts for recursive placement
  if not self.previousFailureCount then
    self.previousFailureCount = { foreground = 0, background = 0 }
  end
  local failureCount = 0
  local nextTileData = {}

  --world.logInfo(string.format("attempting to place blocks in %s with data:", targetLayer))
  --world.logInfo(tileData)

  for i, pos in ipairs(tileArea) do
    nextTileData[i] = false
    if tileData[i] then
      local success = world.placeMaterial(pos, targetLayer, tileData[i], nil, true)
      if success then
        --world.logInfo(string.format("successfully placed %s in %s", tileData[i], targetLayer))
      else
        if world.material(pos, targetLayer) == tileData[i] then
          --didn't really fail; correct tile is already here
        else
          --world.logInfo("failed to place block in "..targetLayer)
          failureCount = failureCount + 1

          --add to table to be retried
          nextTileData[i] = tileData[i]
        end
      end
    elseif targetLayer == "background" then
      local success = world.placeMaterial(pos, targetLayer, "invisitile", nil, true)
      if not success then
        --world.logInfo("failed to place invisible tile in "..targetLayer)
      end
    end
  end

  --world.logInfo(string.format("finished placement with %d failures (%d last run)", failureCount, self.previousFailureCount[targetLayer]))

  --keep calling recursively as long as placement improves with each call
  if failureCount > 0 then
    if failureCount ~= self.previousFailureCount[targetLayer] then
      --still improving placements
      self.previousFailureCount[targetLayer] = failureCount
      placeLayer(tileArea, targetLayer, nextTileData, conserveMaterial)
    else
      --placements are stuck; give up and drop items
      if conserveMaterial then
        dropMatItems(tileArea, nextTileData)
      end

      self.previousFailureCount = nil
    end
  else

    self.previousFailureCount = nil
  end
end

--- Determines the name of the item drop from a given material name
-- @param matName the name of the material
-- @returns the name of the proper material item to drop (or false if item can't be found)
function getMatItemName(matName)
  local success = pcall(function () world.itemType(matName) end)
  if not success then
    success = pcall(function () world.itemType(matName.."material") end)
    if not success then
      world.logInfo("unable to get item name for %s", matName)
      return false
    else
      return matName.."material"
    end
  else
    return matName
  end
end

--- Drops the material items for any materials in the tileData
-- @param tileArea list of absolute tile positions where the items will be dropped
-- @param tileData list of material names to be dropped (or false for no drop). indexes in this list should correspond to indexes in the tileArea list
function dropMatItems(tileArea, tileData)
  for i, pos in ipairs(tileArea) do
    if tileData[i] then
      local itemName = getMatItemName(tileData[i])
      if itemName then
        world.spawnItem(itemName, pos, 1)
      end
    end
  end
end

--- Destroys any background "invisitiles" (used to aid in block placement)
-- @param tileArea list of absolute tile positions where invisitile cleanup will be performed
function cleanupInvisitiles(tileArea)
  for i, pos in ipairs(tileArea) do
    if world.material(pos, "background") == "invisitile" then
      world.damageTiles({pos}, "background", entity.position(), "crushing", 9999)
    end
  end
end

--- Removes 'invisitiles' or other helper tiles/objects after a transition
-- THIS MUST BE CALLED AFTER A BACKGROUND placeLayer CALL
-- @param tileArea list of absolute tile positions where cleanup will be performed
function cleanupTransition(tileArea)
  cleanupInvisitiles(tileArea)
end