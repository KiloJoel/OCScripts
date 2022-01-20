robot = require("robot")
component = require("component")
computer = require("computer")
sides = require("sides")
inventory = component.inventory_controller


parentName = "reed"
parentStats = {growth=0,gain=0,resistance=31}
keepRunning = true

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

function useItemInSlot(slotNum)
  robot.select(slotNum)
  inventory.equip()
  robot.useDown()
  inventory.equip()
end

function checkInitialParent()
  scan = component.geolyzer.analyze(sides.down)
  parentName = scan["crop:name"]
  parentStats.growth = scan["crop:growth"]
  parentStats.gain = scan["crop:gain"]
  parentStats.resistance = scan["crop:resistance"]
end

function checkForNewCrop()
  scan = component.geolyzer.analyze(sides.down)

  name = scan["crop:name"]

  if name == nil then
      return
  end
  if name == "weed" then
    robot.useDown()
    useItemInSlot(1)
    return
  end

  newStats = {growth=scan["crop:growth"],gain=scan["crop:gain"],resistance=scan["crop:resistance"]}
  relativeValue = newStats.growth - parentStats.growth
  relativeValue = relativeValue + newStats.gain - parentStats.gain
  relativeValue = relativeValue - newStats.resistance + parentStats.resistance


  if name == parentName and relativeValue > 0 then --replace with new superior parent
    if newStats == {31,31,0} then --objective achieved
      keepRunning = false;
    end
    parentStats = newStats
    useItemInSlot(2)
    safeBack()
    robot.swingDown()
    useItemInSlot(2)
    safeForward()
    useItemInSlot(1)
    useItemInSlot(1)
  else
    robot.useDown()
    useItemInSlot(1)
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
      keepRunning = false
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

while keepRunning do
  singlePass()
  os.sleep(2)
end

robot.swingDown() --remove sticks to prevent weeds
