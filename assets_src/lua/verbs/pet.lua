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
    Wargroove.playPositionlessSound("caesar/caesarShoutExcited")
    --Wargroove.playPositionlessSound("caesar/caesarSoldierHeartFoley")

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

return Pet
