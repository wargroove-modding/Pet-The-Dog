local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Pet = Verb:new()

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
    return targetUnit ~= nil and (targetUnit.unitClass.id == "dog" or targetUnit.unitClass.id == "commander_tolstoy" or targetUnit.unitClass.id == "commander_caesar")
end

function Pet:execute(unit, targetPos, strParam, path)
    local amountToMove = 0.25
    local xMove = (targetPos.x > unit.pos.x and amountToMove) or (targetPos.x < unit.pos.x and -amountToMove) or 0
    local yMove = (targetPos.y > unit.pos.y and amountToMove) or (targetPos.y < unit.pos.y and -amountToMove) or 0

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

    Wargroove.waitTime(0.5)

    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0, 0, 10)
    while (Wargroove.isLuaMoving(unit.id)) do
        coroutine.yield()
    end

    Wargroove.waitTime(0.5)

    Wargroove.unsetFacingOverride(unit.id)
end

-- function Pet:generateOrders(unitId, canMove)
--     return {}
-- end


-- function Pet:getScore(unitId, order)        
--     return {score = 0, introspection = introspection}
-- end

return Pet
