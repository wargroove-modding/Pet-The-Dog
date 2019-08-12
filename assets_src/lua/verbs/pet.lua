local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Pet = Verb:new()
local healAmount = 15
local dogHealAmount = 5

function Pet:getMaximumRange(unit, endPos)
    return 1
end

function Pet:getTargetType()
    return "unit"
end

function Pet:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    return targetUnit ~= nil and Wargroove.areAllies(unit.playerId, targetUnit.playerId) and (targetUnit.unitClass.id == "dog" or targetUnit.unitClass.id == "turtle" or targetUnit.unitClass.id == "commander_caesar")
end

function Pet:execute(unit, targetPos, strParam, path)
    local amountToMove = 0.25
    local xMove = (targetPos.x > unit.pos.x and amountToMove) or (targetPos.x < unit.pos.x and -amountToMove) or 0
    local yMove = (targetPos.y > unit.pos.y and amountToMove) or (targetPos.y < unit.pos.y and -amountToMove) or 0
    local targetUnit = Wargroove.getUnitAt(targetPos)

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)

    Wargroove.moveUnitToOverride(unit.id, unit.pos, xMove, yMove, 10)
    while (Wargroove.isLuaMoving(unit.id)) do
        coroutine.yield()
    end
    
    Wargroove.waitTime(0.3)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/heal_unit")
    --Wargroove.playPositionlessSound("sfx/caesar/caesarShoutExcited")
    Wargroove.playPositionlessSound("sfx/caesar/caesarSoldierHeartFoley")

    unit:setHealth(unit.health + healAmount, unit.id)
    targetUnit:setHealth(targetUnit.health + dogHealAmount, unit.id)
    Wargroove.updateUnit(targetUnit)

    Wargroove.waitTime(0.5)

    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0, 0, 10)
    while (Wargroove.isLuaMoving(unit.id)) do
        coroutine.yield()
    end

    Wargroove.waitTime(0.5)

    Wargroove.unsetFacingOverride(unit.id)
end

function Pet:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        Wargroove.pushUnitPos(unit, pos)
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in ipairs(targets) do
            if canExecuteWithTarget(unit, pos, targetPos, "") and unit.health ~= 100 then
                table.insert(orders, { targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos })
            end
        end
        Wargroove.popUnitPos()
    end

    return orders
end

function Pet:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targetUnit = Wargroove.getUnitAt(order.targetPosition)

    -- Calculate self-heal amount and score
    local selfHealAmount = math.min(healAmount, 100 - unit.health)
    local unitValue = math.sqrt(unit.unitClass.cost / 100)
    local healScore = unitValue * selfHealAmount/healAmount

    -- Calculate value of healing the dog
    local healingAmount = 0
    if targetUnit ~= nil then
        local targetClass = targetUnit.unitClass
        if Wargroove.areAllies(targetUnit.playerId, unit.playerId) and (not targetClass.isStructure) then
            healingAmount = math.min(dogHealAmount, 100 - u.health)
            local unitValue = math.sqrt(targetClass.cost / 100)
            if targetClass.isCommander then
                unitValue = 10
            end
            healScore = healScore + (healingAmount / 100) * unitValue
        end
    end

    return { score = healScore, healthDelta = selfHealAmount, introspection = {
        { key = "healScore", value = healScore },
        { key = "selfHealAmount", value = selfHealAmount },
        { key = "dogHealAmount", value = healingAmount }}}
end

return Pet
