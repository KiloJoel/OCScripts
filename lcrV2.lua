transposer = component.proxy(component.list("transposer")())
redstone = component.proxy(component.list("redstone")())

function checkOutputSide(sideNumber)
  local inventorySize = transposer.getInventorySize(sideNumber)
  if inventorySize and inventorySize > 15 then
    cellOutputSides[#cellOutputSides+1]=sideNumber
    numberOutputSides = numberOutputSides + 1
  end
end

function determineSides()
  stagingSide = 1
  cellOutputSides = {}
  numberOutputSides = 0
  checkOutputSide(0)
  checkOutputSide(1)

  addCellsSide = 4
  fluidInHatchesSide = 5
  for i = 2, 5 do
    name = transposer.getInventoryName(i)
    if name == "gt.blockmachines" then
      hatchSide = i
    end
  end
  -- Ugly code incoming
  if hatchSide == 2 then
    inputSide = 3
    checkOutputSide(4)
    checkOutputSide(5)
  elseif hatchSide == 3 then
    inputSide = 2
    checkOutputSide(4)
    checkOutputSide(5)
  elseif hatchSide == 4 then
    inputSide = 5
    checkOutputSide(2)
    checkOutputSide(3)
  else
    inputSide = 4
    checkOutputSide(2)
    checkOutputSide(3)
  end
end

function waitForInput()
  found = false
  while not found do
    stack = transposer.getStackInSlot(inputSide, 1)
    if stack and stack.name == "minecraft:redstone_torch" then
      found = true
    end
  end
end

function insertItems()
  stagingSlot = 1
  hatchSlot = 1
  size = transposer.getInventorySize(inputSide)
  cellOutputsTable = {}
  cellOutputSidesIndex = 1
  for i = 2, size do
    stack = transposer.getStackInSlot(inputSide, i)
    if stack then
      if stack.name == "IC2:itemCellEmpty" then
        --Empty cell
        transposer.transferItem(inputSide, cellOutputSides[1], 64, i, i)
      elseif stack.fluid_name or stack.name:match("^miscutils:itemCell") then
        --Fluid cell
        if cellOutputsTable[stack.label] == nil then
          if (cellOutputSidesIndex <= numberOutputSides) then
            cellOutputsTable[stack.label] = cellOutputSides[cellOutputSidesIndex]
            cellOutputSidesIndex = cellOutputSidesIndex + 1
          else
            error("Too many fluid types (" .. #cellOutputSides .. " max)")
          end
        end
        transposer.transferItem(inputSide, cellOutputsTable[stack.label], 64, i, i)
      else
        --Circuit or item
        transposer.transferItem(inputSide, hatchSide, 64, i, i)
      end
    end
  end

  redstone.setOutput(addCellsSide, 15)
end

function waitForEmptyInventory(side)
  done = false
  while not done do
    done = isInventoryEmpty(side, false)
  end
end

function isInventoryEmpty(side, ignoreCircuits)
  size = transposer.getInventorySize(side)
  for i = 1, size do
    stack = transposer.getStackInSlot(side, i)
    if stack and (stack.name ~= "gregtech:gt.integrated_circuit" or not ignoreCircuits) then
      return false
    end
  end
  return true
end

function fluidHatchesEmpty()
  isEmpty = true
  for i = 1, 3 do
    computer.pullSignal(0.5)

    for i = 0, 5 do
      input = redstone.getInput(i)
      if input ~= 0 then
        isEmpty = false;
      end
    end
  end
  return isEmpty
end

function waitForLCR()
  done = false
  while not done do
    done = isInventoryEmpty(hatchSide, true) and fluidHatchesEmpty()
  end
end

function finishUp()
  redstone.setOutput(addCellsSide, 0)
  transposer.transferItem(hatchSide, stagingSide, 1, 1, 1)
  transposer.transferItem(inputSide, stagingSide, 1, 1, 2)
  waitForEmptyInventory(stagingSide, false)
end

function main()
  determineSides()
  while true do
    waitForInput()
    insertItems()
    waitForLCR()
    finishUp()
  end
end

main()
