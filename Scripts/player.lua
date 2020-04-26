-- Wait for depending scripts to load
function onCreated()
  game:setTimeout(5, "onTimeoutDependents")
end

-- Triggered when dependent scripts have loaded
-- e.g can't add the player until the world has loaded
function onCreatedDependents()
  script:clear(script:thisName()) 
  script:triggerFunction("removeGrids", "Scripts/world.lua") -- In case this script was updated

  self:removeKey("gridPos")

  -- The player is the node we are controlling
  player = CreateImage("Players/player.png", 0, 0, 32, 32); player:setScaled(getWorld():getScaled()); player:center(); player:setClipped(false); player:setProperty("isPlayer", "1")
  playerSpeed = 4; maxPlayerSpeed = playerSpeed*3
  getWorld():setPosition(0,0)
  local topLayer = script:getValue("topLayer", "Scripts/world.lua")
  topLayer:addElement(player)
  playerPos = { x = player:getX(), y = player:getY() }

  playerMoving = {}; moveTimeout = nil

  nodes = {}
  
  fullOnGrid = {}
  lastOnGrid = nil
  updateGridPosition()

  sendPlayer()
end

-- Gets the element's top-most parent. e.g a tile's absolute parent is the world (rather than the layer)
function getAbsoluteParent(elem)
  if elem == nil then return; end

  while elem ~= elem:getParent() do
    elem = elem:getParent()
  end
  return elem
end

function getWorld()
  return script:getValue("parent", "Scripts/world.lua")
end

function onKeyDown(key)
  -- Move the player if we aren't clicked on a button, editbox, etc.
  if game:getFocusedElement() == nil or getAbsoluteParent(game:getFocusedElement()) == getWorld() or getAbsoluteParent(game:getFocusedElement()) == player then
    key = key == "W" and "UP" or key == "S" and "DOWN" or key == "A" and "LEFT" or key == "D" and "RIGHT" or key

    if playerMoving[key] == nil and (key == "LEFT" or key == "RIGHT" or key == "UP" or key == "DOWN") then
      if playerIsMoving() == false then startWalk = true; end -- Start with walking animation

      -- Can't move left & right at the same time. Same for up/down.
      playerMoving[key == "LEFT" and "RIGHT" or key == "RIGHT" and "LEFT" or key == "UP" and "DOWN" or "UP"] = nil
      
      playerMoving[key] = true
      movePlayer(playerSpeed)
    end
  end
end

function onKeyUp(key)
  key = key == "W" and "UP" or key == "S" and "DOWN" or key == "A" and "LEFT" or key == "D" and "RIGHT" or key
  if playerMoving[key] ~= nil then
    playerMoving[key] = nil
  end
end

-- Get which grid we're on
function getOnGrid()
  local gridSq = script:getValue("gridSq", "Scripts/world.lua")
  return { math.floor(playerPos.x/gridSq.w), math.floor(playerPos.y/gridSq.h), gridSq.horiz, gridSq.vert }
end

-- Send to all clients who have a grid we're standing on
function sendPlayer(obj)
  obj = obj or player
  lastOnGrid = getOnGrid()
  local posStr = tostring(lastOnGrid[1]) .. "," .. tostring(lastOnGrid[2])
  obj:sendToClients(true, "gridPos", posStr)
end

function playerIsMoving()
  return playerMoving["LEFT"] ~= nil or playerMoving["RIGHT"] ~= nil or playerMoving["UP"] ~= nil or playerMoving["DOWN"] ~= nil
end

function movePlayer(speed)
  if speed > maxPlayerSpeed then speed = maxPlayerSpeed; end -- Max speed due to lag
  
  -- Get our changed X/Y position based on the key pressed
  local difX = playerMoving["LEFT"] and speed*(-1) or playerMoving["RIGHT"] and speed or 0
  local difY = playerMoving["UP"] and speed*(-1) or playerMoving["DOWN"] and speed or 0

  --[[
  -- TODO - To move the player instead (rather than the world, e.g. when reaching the end of a level)
  -- don't change playerPos or getWorld() positions. Instead, add to player position directly.
  --]]
  getWorld():setPosition(getWorld():getX() - difX, getWorld():getY() - difY)
  player:setPosition(player:getX() + difX, player:getY() + difY) -- Since the player is an element of the world, need to move him with it
  playerPos.x = player:getX()
  playerPos.y = player:getY()

  if moveTimeout == nil and playerIsMoving() then
    game:setTimeout(5, "onTimeoutMovePlayer"); moveTimeout = true
  end

  updateGridPosition()
  sendPlayer()
end

-- Compare two grids
function compareGrids(t1, t2)
  local newT = {}
  for i,tbl1 in pairs(t1) do
    local found = nil
    for n,tbl2 in pairs(t2) do
      if tbl1[1] == tbl2[1] and tbl1[2] == tbl2[2] then
        found = n; break
      end
    end
    if found == nil then
      table.insert(newT, tbl1)
    end
  end
  return newT
end

-- Print for testing
function printGrid(tbl)
  for i,t in pairs(tbl) do
    print("  " .. tostring(t[1]) .. ", " .. tostring(t[2]))
  end
end

-- Update our grid position. doAnyways allows recalculation even if the grid is the same (e.g. for if a script is changed).
function updateGridPosition(doAnyways)
  local onGrid = getOnGrid()
  
  if doAnyways == true or lastOnGrid == nil or onGrid[1] ~= lastOnGrid[1] or onGrid[2] ~= lastOnGrid[2] then
    local newFullOnGrid = {}
    --[[ Create new grid, determined in the world script by window size --]]
    for i=math.ceil(onGrid[3]/2)*(-1), math.ceil(onGrid[3]/2) do
      for n=math.ceil(onGrid[4]/2)*(-1), math.ceil(onGrid[4]/2) do
        table.insert(newFullOnGrid, { onGrid[1]+i, onGrid[2]+n } )
      end
    end

    local remKeys = compareGrids(fullOnGrid, newFullOnGrid)
    local addKeys = compareGrids(newFullOnGrid, fullOnGrid)

    --  If we remove all keys, simply clear them. Otherwise remove individual keys.
    -- We don't do an else-if so that we can remove all before adding, or add before removing certain keys (prevents "flickering" when a key is removed).
    if #remKeys == #fullOnGrid then
      self:removeKey("gridPos")
      script:triggerFunction("removeGrids", "Scripts/world.lua")
      -- print("Removing all keys")
    end

    --  Add keys
    for i,tbl in pairs(addKeys) do
      self:addKey("gridPos", tostring(tbl[1]) .. "," .. tostring(tbl[2]))
      script:triggerFunction("loadGrid", "Scripts/world.lua", tbl[1], tbl[2])
      -- print("Adding key: " .. tostring(tbl[1]) .. ", " .. tostring(tbl[2]))
    end

    -- Read above (removing all keys) for why this isn't in an else-statement.
    if #remKeys ~= #fullOnGrid then
      for i,tbl in pairs(remKeys) do
        self:removeKey("gridPos", tostring(tbl[1]) .. "," .. tostring(tbl[2]))
        script:triggerFunction("removeGrid", "Scripts/world.lua", tbl[1], tbl[2])
        -- print("Removing key: " .. tostring(tbl[1]) .. ", " .. tostring(tbl[2]))
      end
    end
    --[[
      print("Old (" .. tostring(lastOnGrid[1]) .. ", " .. tostring(lastOnGrid[2]) .. "):"); printGrid(fullOnGrid)
      print("Adding:"); printGrid(addKeys)
      print("Removing:"); printGrid(remKeys)
      print("New (" .. tostring(onGrid[1]) .. ", " .. tostring(onGrid[2]) .. "):"); printGrid(newFullOnGrid)
    --]]

    fullOnGrid = newFullOnGrid

    lastOnGrid = onGrid
  end
end

-- Wait for depending scripts to load, then finish loading this script
function onTimeoutDependents(time, realTime)
  if game:getScript("Scripts/world.lua") ~= nil then
    onCreatedDependents()
  else
    game:setTimeout(time, script:thisFunction())
  end
end

-- Move our player relative to time that passed
function onTimeoutMovePlayer(time, realTime)
  moveTimeout = nil; movePlayer(realTime/time*playerSpeed)
end

-- Make sure that online players are associated with the world's position
function onCommand(cmd, cmdStr)
  local elem = server:getObjectFromCommand(cmd)
  if elem == nil and cmd:find("Elem") == 1 and cmdStr == "remove" then
    local ID = operations:removeQuotes(cmd:sub(5))
    if nodes[ID] ~= nil then nodes[ID] = nil; end
  elseif elem ~= nil and cmdStr:find("isPlayer") ~= nil and elem:getProperty("isPlayer") == "1" then
    getWorld():addElement(elem)
    elem:bringToFront()
    nodes[elem:getID()] = elem
  end
end

-- Called every loop
function main()
  -- Draw a line from our node to other nodes, then each node to each other node
  if nodes ~= nil then
    for ID,node in pairs(nodes) do
     game:draw2DLine(player:getX(true)+getWorld():getX()+16, player:getY(true)+getWorld():getY()+16, node:getX(true)+getWorld():getX()+16, node:getY(true)+getWorld():getY()+16, 0, 0, 0, 255);
     for ID2,node2 in pairs(nodes) do
       if ID ~= ID2 then game:draw2DLine(node:getX(true)+getWorld():getX()+16, node:getY(true)+getWorld():getY()+16, node2:getX(true)+getWorld():getX()+16, node2:getY(true)+getWorld():getY()+16, 0, 0, 0, 255); end
     end
    end
  end
end