robot = require("robot")
component = require("component")
computer = require("computer")
sides = require("sides")
inventory = component.inventory_controller


parentName = "reed"
parentStats = {growth=0,gain=0,resistance=31}


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
    parentStats.gain = scan["crop:growth"]
    parentStats.resistance = scan["crop:resistance"]
end

function checkAndRecharge()
    if computer.energy() < computer.maxEnergy() * 0.5 then
        safeBack()
        safeBack()
        while computer.energy() < computer.maxEnergy() * 0.98 do
            os.sleep(1)
        end
        safeForward()
        safeForward()
    end
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
        parentStats = newStats
        useItemInSlot(2)
        safeBack()
        robot.breakDown()
        useItemInSlot(2)
        safeForward()
        useItemInSlot(1)
        useItemInSlot(1)
    else
        robot.useDown()
        useItemInSlot(1)
    end
end

function singlePass()
  checkForNewCrop()
  checkAndRecharge()
end


checkInitialParent()
safeForward()

while true do
  singlePass()
  os.sleep(2)
end