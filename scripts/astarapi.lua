astarApi = {}

--- Internal Node class
local Node = {}
setmetatable(Node, { __call = function(self, ...) return self:new(...) end })
Node.__index = Node

--- Comparison of positions
function Node.__eq (a, b)
  return (a.x == b.x) and (a.y == b.y)
end

--- Node constructor
function Node:new(x, y, G, H, F, parent)
  local node = {x = x, y = y, F = F or 0, G = G or 0, H = H or 0, parent = parent or {}}
  return setmetatable(node, Node)
end

--- Computes the distance from self node to another node using custom heuristic
function Node:getDistanceTo(node)
  return 10 * (1 + math.abs(self.x - node.x)) + 10 * (1 + math.abs(self.y - node.y))
end

--- Computes the self node G, H, F costs
function Node:computeHeuristicsTo(node, final)
  local cost = 10  
  if (self.x ~= node.x and self.y ~= node.y) then 
    cost = 15
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

--- Internal function which checks new nodes to study around self node.
function astarApi.addNode()
  local lowerCostNode = astarApi.currentNode
  for y = astarApi.currentNode.y - 1, astarApi.currentNode.y + 1, 1 do
    for x = astarApi.currentNode.x - 1, astarApi.currentNode.x + 1, 1 do
      local left, right = false, false
      if not astarApi.diagonalMove then
        left = (y == astarApi.currentNode.y - 1) and ((x == astarApi.currentNode.x - 1) or (x == astarApi.currentNode.x + 1))
        right = (y == astarApi.currentNode.y + 1) and ((x == astarApi.currentNode.x - 1) or (x == astarApi.currentNode.x + 1))
      end
      if not left and not right then
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then
          tmpNode:computeHeuristicsTo(astarApi.currentNode, astarApi.finalNode)
          if not astarApi.isListed(astarApi.cList,tmpNode) then
            local opened, pos = astarApi.isListed(astarApi.oList, tmpNode)
            if opened then
              if (tmpNode.G < astarApi.oList[pos].G) then
                astarApi.oList[pos] = tmpNode
              end
            else
              if tmpNode.G <= lowerCostNode.G  then
                lowerCostNode = tmpNode   
                table.insert(astarApi.oList, 1, tmpNode)
              else
                table.insert(astarApi.oList, tmpNode)
              end
            end
          end
        end
      end
    end
  end
end

--- Looks for a new walkable destination in the search area around a node
-- @param node (Node) A node
function astarApi.getNewFreeNode(node)
  local depth = 0
  repeat
    depth = depth + 1
    local x, y
    y = node.y - depth
      for x = node.x - depth, node.x + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end
    y = node.y + depth
      for x = node.x - depth, node.x + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end
    x = node.x - depth
      for y = node.y - depth, node.y + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end
    x = node.x + depth
      for y = node.y - depth, node.y + depth do
        local tmpNode = Node(x, y)
        if astarApi.isWalkable(tmpNode) then return tmpNode end
      end  
  until (depth >= astarApi.searchDepth)
  return nil
end

--- Pick a nearest walkable node around specified position
-- @return (Node) A walkable node or nil
function astarApi.getWalkableNode(x, y)
  local node = Node(x, y)
  if not astarApi.isWalkable(node) then
    if astarApi.searchDepth > 0 then
      return astarApi.getNewFreeNode(node)
    else return nil end
  else return node end
end

--- Checks if a node is walkable
-- @param node (Node) A node
function astarApi.isWalkable(node)
  return not world.rectCollision({ astarApi.trect[1] + node.x, astarApi.trect[2] + node.y, astarApi.trect[3] + node.x, astarApi.trect[4] + node.y }, true)
end

--- Returns the reordered path from the starting node to the final node
-- @param from (vec2f) The starting position
-- @param to (vec2f) The destination
-- @param rect (rect4f) A rectangle to be used for collision testing
-- @return (table) A list of nodes
function astarApi.getPath(from, to, rect)
  astarApi.trect = rect
  astarApi.diagonalMove = true
  astarApi.searchDepth = 2
  astarApi.tries = 0
  astarApi.initialNode = astarApi.getWalkableNode(from[1], from[2])
  astarApi.finalNode = astarApi.getWalkableNode(to[1], to[2])
  astarApi.path = {}
  astarApi.currentNode = Node(astarApi.initialNode.x, astarApi.initialNode.y, 0, 0, 0, Node(astarApi.initialNode.x, astarApi.initialNode.y))
  astarApi.cList = {}
  astarApi.oList = {}
  table.insert(astarApi.cList,astarApi.currentNode)
  if astarApi.finalNode == astarApi.initialNode then
    astarApi.path = astarApi.cList
    return
  end
  repeat
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
    if astarApi.tries > 3000 then return true, nil end
    if astarApi.tries % 100 == 0 then
      coroutine.yield(false)
    end
  until (astarApi.currentNode == astarApi.finalNode)
  astarApi.path = astarApi.cList
  if astarApi.path and (#astarApi.path > 0) then
    local way = {}
    local nxt = Node(astarApi.finalNode.x, astarApi.finalNode.y)
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
    local _, res, path = coroutine.resume(astarApi.pth, astarApi.floorVec(entity.position()), dest, rect)
    if not res then
      astarApi.pdone = false
      entity.fly({ 0, 0 })
      return true
    else
      astarApi.pdone = true
      astarApi.flyp = path
      astarApi.pnode = 1
    end
  end
  if astarApi.flyp == nil then return false end
  local p = entity.position()
  if astarApi.pnode >= #astarApi.flyp then
    entity.flyTo(fdest, true)
  else
    local n = astarApi.flyp[astarApi.pnode]
    entity.fly(astarApi.dirVec({ n.x - p[1] + 0.5, n.y - p[2] + 0.5 }, 4))
    if world.magnitude(entity.position(), astarApi.n2v(astarApi.flyp[astarApi.pnode])) < 1.25 then
      astarApi.pnode = astarApi.pnode + 1
    end
  end
  return true
end

function astarApi.dirVec(v, spd)
  local l = math.sqrt(v[1] * v[1] + v[2] * v[2])
  return { v[1] * spd / l, v[2] * spd / l }
end

--- Vector the node!
-- @param node (Node) A node
-- @return (vec2f) A vector
function astarApi.n2v(node)
  return { node.x, node.y }
end

--- Floor the vector!
-- @param vec (vec2f) A vector
-- @return (vec2i) A rounded vector
function astarApi.floorVec(vec)
  return { math.floor(vec[1] + 0.5), math.floor(vec[2] + 0.5) }
end