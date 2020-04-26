function onCreated()
  script:triggerFunction("onCreated", "Scripts/player.lua") -- Reset player if this script was updated

  -- Create parent. Holds part of grid
  parent = CreateListBox(0,0,0,0); parent:setScaled(false)
  
  -- Parent holds grids
  grids = {}
  -- Grids hold layers
  layers = {}
  -- Layers hold tiles
  tiles = {}
  --[[ NOTE:
       Layers and Tiles not yet necessary. Added so that future code could allow for adding extra visualization features.
  --]]
  topLayer = CreateListBox(0,0,0,0); topLayer:setScaled(parent:getScaled()); parent:addElement(topLayer) -- Used for displaying above everything, such as clouds or a tile placer
  
  gridSq = { w = 30*16, h = 30*16, horiz = 2, vert = 2 }
  onWindowResize()
end

-- Creates necessary lists if they don't exists
function checkCreateLists(gridX, gridY, layer)
  if grids[tostring(gridX)] == nil then grids[tostring(gridX)] = {}; end
  if layers[tostring(gridX)] == nil then layers[tostring(gridX)] = {}; end
  if layers[tostring(gridX)][tostring(gridY)] == nil then layers[tostring(gridX)][tostring(gridY)] = {}; end
  if tiles[tostring(gridX)] == nil then tiles[tostring(gridX)] = {}; end
  if tiles[tostring(gridX)][tostring(gridY)] == nil then tiles[tostring(gridX)][tostring(gridY)] = {}; end
  if tiles[tostring(gridX)][tostring(gridY)][tostring(layer)] == nil then tiles[tostring(gridX)][tostring(gridY)][tostring(layer)] = {}; end

  -- Create part of grid. Holds layers
  local grid = grids[tostring(gridX)][tostring(gridY)]
  if grid == nil then
    grid = CreateListBox(gridX*gridSq.w, gridY*gridSq.h, gridSq.w, gridSq.h); grid:setScaled(parent:getScaled())
    grids[tostring(gridX)][tostring(gridY)] = grid
    parent:addElement(grid)
  end
  
  -- Create layer. Holds tiles
  if layers[tostring(gridX)][tostring(gridY)][tostring(layer)] == nil then
    local layerLB = CreateListBox(0,0,0,0); layerLB:setScaled(parent:getScaled())
    layers[tostring(gridX)][tostring(gridY)][tostring(layer)] = layerLB
    grid:addElement(layerLB)
    reorderLayers(gridX, gridY)
  end
end

-- E.g if layers 1 and 4 already exist but 3 was just created, layer 3 will be above layer 4.
-- This way, we can move them around as necessary. 
function reorderLayers(gridX, gridY)
  local lyrs = layers[tostring(gridX)][tostring(gridY)]
  local lyrNums = {}
  
  -- Turn each layer into a number (from a string) and sort
  for num,k in pairs(lyrs) do table.insert(lyrNums, num+0); end
  table.sort(lyrNums)
  
  -- bringToFront starting at first layer in sorted numbers
  for i,num in pairs(lyrNums) do lyrs[tostring(num)]:bringToFront(); end
  topLayer:bringToFront()
end

-- Load a grid at a position
function loadGrid(gridX, gridY)
  checkCreateLists(gridX, gridY, 1)
  local begX = operations:arraySize(tiles[tostring(gridX)][tostring(gridY)]["1"])
  local begY = tiles[tostring(gridX)][tostring(gridY)]["1"] and tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(begX)] and operations:arraySize(tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(begX)]) or 0
  if begY > 0 then begX = begX-1; end

  local tile = CreateImage("Tilesets/tileset2.png", begX, begY); tile:setClipped(false); tile:setScaled(parent:getScaled())
  layers[tostring(gridX)][tostring(gridY)]["1"]:addElement(tile)
  if tiles[tostring(gridX)][tostring(gridY)]["1"]["0"] == nil then tiles[tostring(gridX)][tostring(gridY)]["1"]["0"] = {}; end
  if tiles[tostring(gridX)][tostring(gridY)]["1"]["0"]["0"] == nil then tiles[tostring(gridX)][tostring(gridY)]["1"]["0"]["0"] = {}; end
  tiles[tostring(gridX)][tostring(gridY)]["1"]["0"]["0"] = tile
  
  topLayer:bringToFront()
end

-- Remove a grid at a position
function removeGrid(gridX, gridY)
  if grids[tostring(gridX)] == nil or grids[tostring(gridX)][tostring(gridY)] == nil then return; end
  
  local grid = grids[tostring(gridX)][tostring(gridY)]
  grid:remove()
  grids[tostring(gridX)][tostring(gridY)] = nil
  tiles[tostring(gridX)][tostring(gridY)] = nil
  layers[tostring(gridX)][tostring(gridY)] = nil
end

-- Remove all grids (e.g. if a script is updated).
function removeGrids()
  for x,tbl in pairs(grids) do
    for y,grid in pairs(tbl) do
      removeGrid(x, y)
    end
  end
end

function onWindowResize(lX, lY, lW, lH)
  if parent:getScaled() then return; end

  -- Always keep the world centered
  if lX ~= nil then
    local w, h = game:getWindowWidth(), game:getWindowHeight()
    parent:setPosition(parent:getX()+(w-lW)/2, parent:getY()+(h-lH)/2)
  end
  
  -- Load enough grids to fill the screen. Commented out so that we can see a maximum of 3 grids, for visualization.
  -- gridSq.horiz = math.ceil(game:getWindowWidth()/gridSq.w)
  -- gridSq.vert = math.ceil(game:getWindowHeight()/gridSq.h)
  script:triggerFunction("updateGridPosition", "Scripts/player.lua", true) -- Reset grids, we now have different grids
end

function main()
  parent:bringToBack()
end