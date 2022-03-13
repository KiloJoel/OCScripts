transposer = component.proxy(component.list("transposer")())
redstone = component.proxy(component.list("redstone")())

function determineSides()
  stagingSide = 1
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
  elseif hatchSide == 3 then
    inputSide = 2
  elseif hatchSide == 4 then
    inputSide = 5
  else
    inputSide = 4
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
  for i = 2, size do
    stack = transposer.getStackInSlot(inputSide, i)
    if stack then
      if stack.name == "IC2:itemCellEmpty" or stack.fluid_name or stack.name:match("^miscutils:itemCell") then
        transposer.transferItem(inputSide, stagingSide, 64, i, stagingSlot)
        stagingSlot = stagingSlot + 1
      else
        transposer.transferItem(inputSide, hatchSide, 64, i, hatchSlot)
        hatchSlot = hatchSlot + 1
      end
    end
  end

  waitForEmptyInventory(stagingSide)
  redstone.setOutput(addCellsSide, 15)
end

function waitForEmptyInventory(side)
  done = false
  while not done do
    done = inventoryEmpty(side, false)
  end
end

function inventoryEmpty(side, ignoreCircuits)
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
    input = redstone.getInput(fluidInHatchesSide)
    isEmpty = isEmpty and input == 0
  end
  return isEmpty
end

function waitForLCR()
  done = false
  while not done do
    done = inventoryEmpty(hatchSide, true) and fluidHatchesEmpty()
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
