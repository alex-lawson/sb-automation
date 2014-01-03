function absTileAreaToRel(tileArea)
  local ePos = entity.position()
  local newTileArea = {}
  for i, pos in ipairs(tileArea) do
    newTileArea[i] = { pos[1] - ePos[1], pos[2] - ePos[2] }
  end
  return newTileArea
end

function relTileAreaToAbs(tileArea)
  local ePos = entity.position()
  local newTileArea = {}
  for i, pos in ipairs(tileArea) do
    newTileArea[i] = { pos[1] + ePos[1], pos[2] + ePos[2] }
  end
  return newTileArea
end

function scanLayer(targetLayer)
  --world.logInfo("in scanLayer ("..targetLayer..")")
  --world.logInfo(storage.tileArea)
  local scanData = {}
  for i, pos in ipairs(storage.tileArea) do
    local sample = world.material(pos, targetLayer)
    if sample and sample ~= "invisitile" then
      scanData[i] = sample
    else
      scanData[i] = false
    end
  end

  return scanData
end

function breakLayer(targetLayer, dropItems)
  --world.logInfo("in breakLayer ("..targetLayer..")")
  if dropItems then
    world.damageTiles(storage.tileArea, targetLayer, entity.position(), "blockish", 9999)
  else
    world.damageTiles(storage.tileArea, targetLayer, entity.position(), "crushing", 9999)
  end
end

function placeLayer(targetLayer, blockData, conserveMaterial)
  if conserveMaterial == nil then
    conserveMaterial = false
  end
  --world.logInfo("in placeLayer ("..targetLayer..")")
  --world.logInfo(blockData)

  --track failures and retry while failuresLastRun < failuresRunBeforeLast
  local failureCount = 0
  local nextBlockData = {}

  --world.logInfo(string.format("attempting to place blocks in %s with data:", targetLayer))
  --world.logInfo(blockData)

  for i, pos in ipairs(storage.tileArea) do
    nextBlockData[i] = false
    if blockData[i] then
      local success = world.placeMaterial(pos, targetLayer, blockData[i])
      if success then
        --world.logInfo(string.format("successfully placed %s in %s", blockData[i], targetLayer))
      else
        if world.material(pos, targetLayer) == blockData[i] then
          --didn't really fail; correct tile is already here
        else
          --world.logInfo("failed to place block in "..targetLayer)
          failureCount = failureCount + 1

          --add to table to be retried
          nextBlockData[i] = blockData[i]
        end
      end
    elseif targetLayer == "background" then
      local success = world.placeMaterial(pos, targetLayer, "invisitile")
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
      placeLayer(targetLayer, nextBlockData, conserveMaterial)
    else
      --placements are stuck; give up and drop items
      if conserveMaterial then
        dropUnplacedItems(nextBlockData)
      end
      cleanupInvisitiles()
    end
  else
    cleanupInvisitiles()
  end
end

function getMatItemName(matName)
  local success = pcall(function () world.itemType(matName) end)
  if not success then
    success = pcall(function () world.itemType(matName.."material") end)
    if not success then
      world.logInfo(string.format("unable to get item name for %s", matName))
      return false
    else
      return matName.."material"
    end
  else
    return matName
  end
end

function dropUnplacedItems(blockData)
  for i, pos in ipairs(storage.tileArea) do
    if blockData[i] then
      local itemName = getMatItemName(blockData[i])
      if itemName then
        world.spawnItem(itemName, pos, 1)
      end
    end
  end
end

function cleanupInvisitiles()
  for i, pos in ipairs(storage.tileArea) do
    if world.material(pos, "background") == "invisitile" then
      world.damageTiles({pos}, "background", entity.position(), "crushing", 9999)
    end
  end
end