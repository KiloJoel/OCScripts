robot = require("robot")
component = require("component")
computer = require("computer")
sides = require("sides")
inventory = component.inventory_controller


tolerance = 5

parentName = ""
parentStats = {growth=0,gain=0,resistance=31}
parent = nil
state = 1 --1 breeding for stat, 2 propogating, 3 ending


function safeMove(move)
  response = move()
  while not response do
    os.sleep(0.5)
    response = move()
  end
end

function safeForward()
  safeMove(robot.forward)
end

function safeBack()
  safeMove(robot.back)
end

function useItem(slotNum, sneaky)
  robot.select(slotNum)
  inventory.equip()
  robot.useDown(nil, sneaky)
  inventory.equip()
end

function useItemInSlot(slotNum)
  useItem(slotNum, false)
end

function useItemInSlotWithSneak(slotNum)
  useItem(slotNum, true)
end

function checkInitialParent()
  parent = component.geolyzer.analyze(sides.down)
  if (calculateCropValue(parent) == 62) then
    state = 2
  end
end

function calculateCropValue(scan)
  return scan["crop:growth"] + scan["crop:gain"] - scan["crop:resistance"]
end

function getCropName(scan)
  return scan["crop:name"]
end

function isWeed(scan)
  return getCropName(scan) == "weed"
end

function clearAndReplaceStick()
  robot.useDown()
  useItemInSlot(1)
end

function checkCropStick()
  scan = component.geolyzer.analyze(sides.down)

  if (scan.name ~= "IC2:blockCrop") then
    state = 3
    return nil
  end
  if (getCropName(scan) == nil) then
    return nil
  end
  if (isWeed(scan)) then
    clearAndReplaceStick()
    return nil
  end

  return scan
end

function tryToReplaceParent(name, value)
  if name == getCropName(parent) and value > calculateCropValue(parent) then
    if newCropValue == 62 then --objective achieved
      state = 2;
    end
    parent = scan
    useItemInSlotWithSneak(2)
    safeBack()
    robot.swingDown()
    useItemInSlot(2)
    safeForward()
    useItemInSlot(1)
    useItemInSlot(1)
    return true
  else
    clearAndReplaceStick()
    return false
  end
end

function tryToGrowCrop(name, value)
  if (name == getCropName(parent) and value + tolerance >= 62) then
    useItemInSlotWithSneak(2)
    safeForward()
    safeForward()

    growing = component.geolyzer.analyze(sides.down)
    while (growing["crop:size"] ~= growing["crop:maxSize"]) do
      os.sleep(2)
      growing = component.geolyzer.analyze(sides.down)
    end

    robot.swingDown()
    useItemInSlot(2)
    safeBack()
    safeBack()
    useItemInSlot(1)
    useItemInSlot(1)
  else
    clearAndReplaceStick()
  end
end

function checkForNewCrop()
  scan = checkCropStick()
  if scan == nil then
    return
  end

  newCropValue = calculateCropValue(scan)
  newCropName = getCropName(scan)

  success = false
  if (state == 1) then
    success = tryToReplaceParent(newCropName, newCropValue)
  end
  if not success then
    tryToGrowCrop(newCropName, newCropValue)
  end
end

function checkForInvClear()
  stack = inventory.getStackInInternalSlot(12)
  if stack ~= nil then
    clearInventory(3)
  end
end

function clearInventory(minSlot)
  for i = minSlot, 16 do
    robot.select(i)
    robot.dropUp()
  end
end

function checkSticks()
  count = robot.count(1)
  if count < 32 then
    robot.select(1)
    robot.turnLeft()
    robot.suck(64-count)
    robot.turnRight()
    if robot.count() ~= 64 then --stop program if out of cropsticks
      state = 3
    end
  end
end

function singlePass()
  checkForNewCrop()
  checkForInvClear()
  checkSticks()
end


robot.back()
checkInitialParent()
safeForward()
checkSticks()
useItemInSlot(1) --place crossing sticks
useItemInSlot(1)

while state < 3 do
  singlePass()
  os.sleep(2)
end

robot.swingDown() --remove sticks to prevent weeds
