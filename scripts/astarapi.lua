astarApi = {}

--- Internal Node class
local Node = {}
setmetatable(Node, { __call = function(self, ...) return self:new(...) end })
Node.__index = Node

--- Comparison of positions
function Node.__eq (a, b)
  return (a[1] == b[1]) and (a[2] == b[2])
end

--- Node constructor
function Node:new(x, y, G, H, F, parent)
  local node = { x, y, F = F or 0, G = G or 0, H = H or 0, parent = parent or {}}
  return setmetatable(node, Node)
end

--[[ Possible distance formulas
 Manhattan:
   H          = 2 * (math.Abs(mNewLocationX - end.X) + math.abs(mNewLocationY - end.Y))
 MaxDXDY:
   H          = 2 * (math.max(math.abs(mNewLocationX - end.X), math.abs(mNewLocationY - end.Y)))
 DiagonalShortCut:
   diagonal   = math.min(math.abs(mNewLocationX - end.X), math.abs(mNewLocationY - end.Y))
   straight   = (math.abs(mNewLocationX - end.X) + math.abs(mNewLocationY - end.Y))
   H          = 4 * diagonal + 2 * (straight - 2 * diagonal)
 Euclidean:
   H          = 2 * math.sqrt(math.pow((mNewLocationY - end.X) , 2) + math.pow((mNewLocationY - end.Y), 2))
 EuclideanNoSQR:
   H          = 2 * (math.pow((mNewLocationX - end.X) , 2) + math.pow((mNewLocationY - end.Y), 2))
 Custom:
   dxy        = Node(math.abs(end.X - mNewLocationX), math.abs(end.Y - mNewLocationY))
   Orthogonal = math.abs(dxy.X - dxy.Y)
   Diagonal   = math.abs(((dxy.X + dxy.Y) - Orthogonal) / 2)
   H          = 2 * (Diagonal + Orthogonal + dxy.X + dxy.Y)
]]--

--- Computes the distance from self node to another node
function Node:getDistanceTo(node)
  local x, y = self[1] - node[1], self[2] - node[2]
  return 2 * (x * x + y * y)
end

--- Computes the self node G, H, F costs
function Node:computeHeuristicsTo(node, final)
  local cost = 1  
  if (self[1] ~= node[1] and self[2] ~= node[2]) then 
    cost = 2--1.41
  end
  self.G = cost + node.G
  self.H = self:getDistanceTo(final)
  self.F = self.G + self.H
  self.parent = node
end

--- Checks whenever an object is already on a list
-- @return (bool, int) If the list contains the object, return true and the object's index
function astarApi.isListed(list, obj)
  for k, v in pairs(list) do
    if v == obj then return true, k end
  end
  return false,nil
end

--- Divide and Conquer the open list!
-- @param F (float) A F node value to find a position for
-- @return (int) Suitable position in the open list for the node
function astarApi.findPos(F)
  local imid = next(astarApi.oList)
  if imid == nil or astarApi.oList[imid].F >= F then return 1 end
  local imin, imax = 1, #astarApi.oList - 1
  while (imax >= imin) do
    imid = math.floor((imin + imax) / 2)
    if astarApi.oList[imid].F == F then return imid
    elseif (astarApi.oList[imid + 1].F > F) and (astarApi.oList[imid].F <= F) then return imid + 1
    elseif astarApi.oList[imid].F < F then imin = imid + 1
    else imax = imid - 1 end
  end
  return #astarApi.oList + 1
end

--- Internal function which checks new nodes to study around self node
function astarApi.addNode()
  for y = astarApi.currentNode[2] - 1, astarApi.currentNode[2] + 1, 1 do
    for x = astarApi.currentNode[1] - 1, astarApi.currentNode[1] + 1, 1 do
      local left, right = false, false
      if not astarApi.diagonal then
        left = (y == astarApi.currentNode[2] - 1) and ((x == astarApi.currentNode[1] - 1) or (x == astarApi.currentNode[1] + 1))
        right = (y == astarApi.currentNode[2] + 1) and ((x == astarApi.currentNode[1] - 1) or (x == astarApi.currentNode[1] + 1))
      end
      if not left and not right then
        local tmpNode = Node(x, y)
        local fd = math.abs(astarApi.finalNode[1] - tmpNode[1]) < astarApi.maxDist and math.abs(astarApi.finalNode[2] - tmpNode[2]) < astarApi.maxDist
        if fd and astarApi.isWalkable(tmpNode) then
          -- DEBUG
          --world.placeMaterial(n2v(tmpNode), "background", "ice")
          -- DEBUG
          tmpNode:computeHeuristicsTo(astarApi.currentNode, astarApi.finalNode)
          if not astarApi.isListed(astarApi.cList, tmpNode) then
            local opened, pos = astarApi.isListed(astarApi.oList, tmpNode)
            if not opened or (tmpNode.G < astarApi.oList[pos].G) then
              if opened then table.remove(astarApi.oList, pos) end
              table.insert(astarApi.oList, astarApi.findPos(tmpNode.F), tmpNode)
            end
          end
        -- DEBUG
        --else world.placeMaterial(n2v(tmpNode), "background", "iceblock")
        -- DEBUG
        end
      end
    end
  end
end

--- Looks for a new walkable destination in the search area around a node
-- @param node (vec2f) Position to look around from
-- @return (Node) A walkable node or nil
function astarApi.getNewFreeNode(node)
  local depth = 0
  repeat
    depth = depth + 1
    local x, y
    y = node[2] - depth
      for x = node[1] - depth, node[1] + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end
    y = node[2] + depth
      for x = node[1] - depth, node[1] + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end
    x = node[1] - depth
      for y = node[2] - depth, node[2] + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end
    x = node[1] + depth
      for y = node[2] - depth, node[2] + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end  
  until (depth >= astarApi.searchDepth)
  return nil
end

--- Pick a nearest walkable node around specified position
-- @param vec (vec2f) Position to look around from
-- @return (Node) A walkable node or nil
function astarApi.getWalkableNode(vec)
  local node = Node(vec[1], vec[2])
  if not astarApi.isWalkable(node) then
    if astarApi.searchDepth > 0 then
      return astarApi.getNewFreeNode(node)
    else return nil end
  else return node end
end

--- Returns the reordered path from the starting node to the final node
-- @param from (vec2f) The starting position
-- @param to (vec2f) The destination
-- @param rect (rect4f) A rectangle to be used for collision testing
-- @return (table) A list of nodes
function astarApi.getPath(from, to)
  if not astarApi.init then return true, nil end
  astarApi.tries = 0
  astarApi.initialNode = astarApi.getWalkableNode(from)
  astarApi.finalNode = astarApi.getWalkableNode(to)
  if not astarApi.initialNode or not astarApi.finalNode then return false end
  astarApi.path = {}
  astarApi.currentNode = Node(astarApi.initialNode[1], astarApi.initialNode[2], 0, 0, 0, Node(astarApi.initialNode[1], astarApi.initialNode[2]))
  astarApi.cList = {}
  astarApi.oList = {}
  table.insert(astarApi.cList, astarApi.currentNode)
  while (not (astarApi.finalNode == astarApi.currentNode)) do
    astarApi.addNode()
    local bestPos = next(astarApi.oList)
    if bestPos then
      astarApi.currentNode = astarApi.oList[bestPos]
      table.remove(astarApi.oList, bestPos)
      table.insert(astarApi.cList, astarApi.currentNode)
    else
      astarApi.cList = nil
      break
    end
    astarApi.tries = astarApi.tries + 1
    if astarApi.tries > astarApi.tlimit then return true, nil end
    if astarApi.tries % astarApi.tpt == 0 then
      coroutine.yield(false)
    end
  end
  astarApi.path = astarApi.cList
  if astarApi.path and (#astarApi.path > 0) then
    local way = {}
    local nxt = Node(astarApi.finalNode[1], astarApi.finalNode[2])
    table.insert(way, 1, nxt)
    nxt = astarApi.path[#astarApi.path].parent
    table.insert(way, 1, nxt)
    repeat
      local bool, pos = astarApi.isListed(astarApi.path, nxt)
      if bool then
        if nxt == astarApi.initialNode then break end
        nxt = astarApi.path[pos].parent
        table.insert(way, 1, nxt)
      end
    until (nxt == astarApi.initialNode)
    table.remove(way, 1)
    return true, way
  else return true, nil end
end

--- Required to call before using path functions
-- @param args (table) [optional] A table containing possible configuration keys:
--  - walkFunc (func{Node}) Function to be used for node passability checking
--  - moveSpeed (float) Speed multiplier used in integrated move functions
--  - triesLimit (int) Node search limit
--  - triesPerTick (int) Maximum amount of node checks per tick
--  - maxDistance (int) Distance after which all nodes are considered impassable
--  - searchDepth (int) Maximum tolerated distance from destination
--  - diagonal (bool) Allow diagonal movement along the path
--  - collisionRect (rect4f) Collision rectangle to use by the default passability function
function astarApi.setConfig(args)
  astarApi.init = true
  astarApi.trect = args.collisionRect or { -1, -1, 1, 1 }
  astarApi.diagonal = args.diagonal or false
  astarApi.searchDepth = args.searchDepth or 2
  astarApi.maxDist = args.maxDistance or 50
  astarApi.tpt = args.triesPerTick or 100
  astarApi.tlimit = args.triesLimit or 3000
  astarApi.spd = args.moveSpeed or 4
  astarApi.isWalkable = args.walkFunc or function(node) return not world.rectCollision({ astarApi.trect[1] + node[1], astarApi.trect[2] + node[2], astarApi.trect[3] + node[1], astarApi.trect[4] + node[2] }, true) end
end

--- Just an usage example, if you mind
-- @param dest (vec2f) Desired destination
-- @param rect (rect4f) A rectangle to be used for collision testing
-- @return (bool) A flag indicating whenever the path could be found
function astarApi.flyTo(fdest, rect)
  local dest = astarApi.floorVec(fdest)
  local f = (astarApi.pdest == nil) or (dest[1] ~= astarApi.pdest[1]) or (dest[2] ~= astarApi.pdest[2])
  if not astarApi.pdone or f then
    if f or (astarApi.pth == nil) then astarApi.pth = coroutine.create(astarApi.getPath) end
    astarApi.pdest = dest
    local res = { coroutine.resume(astarApi.pth, astarApi.floorVec(entity.position()), dest, rect) }
    if not res[1] then world.logInfo("%s", res)
    elseif not res[2] then
      astarApi.pdone = false
      entity.fly({ 0, 0 })
      return true
    else
      astarApi.pdone = true
      astarApi.flyp = res[3]
      astarApi.pnode = 1
    end
  end
  if astarApi.flyp == nil then return false end
  local p = entity.position()
  if astarApi.pnode >= #astarApi.flyp then
    entity.flyTo(fdest, true)
  else
    local n = astarApi.flyp[astarApi.pnode]
    entity.fly(astarApi.dirVec({ n[1] - p[1] + 0.5, n[2] - p[2] + 0.5 }, astarApi.spd))
    if world.magnitude(entity.position(), n2v(astarApi.flyp[astarApi.pnode])) < 1.25 then
      astarApi.pnode = astarApi.pnode + 1
    end
  end
  return true
end

--- Vector the node!
-- @param n (Node) A node
-- @return (vec2f) A vector
function n2v(n)
  return { n[1], n[2] }
end

--- Normalizes a vector and multiplies it by speed
-- @param v (vec2f) Vector to process
-- @param spd (float) Speed multiplier to apply
function astarApi.dirVec(v, spd)
  local l = math.sqrt(v[1] * v[1] + v[2] * v[2])
  return { v[1] * spd / l, v[2] * spd / l }
end

--- Floor the vector!
-- @param vec (vec2f) A vector
-- @return (vec2i) A rounded vector
function astarApi.floorVec(vec)
  return { math.floor(vec[1] + 0.5), math.floor(vec[2] + 0.5) }
end