local util = include("modules/util")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local actions = include("sim/btree/actions")

local VIG_RADIUS = 5
local HIDDEN_WEIGHT = 20

local REASONS = {
    [simdefs.REASON_NOISE] = true,
    [simdefs.REASON_DOOR] = true,
    [simdefs.REASON_NOTICED] = true,
    [simdefs.REASON_SENSEDTARGET] = true,
    [simdefs.REASON_LOSTTARGET] = true, -- Not a PE sight/sound interest, but makes sense here.
}
local SENSES = {
    [simdefs.SENSE_HEARING] = REASONS,
    [simdefs.SENSE_SIGHT] = REASONS,
    [simdefs.SENSE_PERIPHERAL] = REASONS,
}

local function canVigilance(sim, unit)
    -- if unit:getTraits().vigilant then
    local interest = unit:getBrain():getInterest()
    if interest and interest.sourceUnit ~= unit then
        local reasons = SENSES[interest.sense]
        return reasons and reasons[interest.reason]
    end
    -- end
end

local function isCellHidden(sim, x0, y0, x1, y1)
    -- -- Cannot see at all.
    -- local raycastX, raycastY = sim:getLOS():raycast(x0, y0, x1, y1)
    -- if raycastX ~= x1 or raycastY ~= y1 then
    --     return true
    -- end
    -- In cover.
    return simquery.checkCellCover(sim, x0, y0, x1, y1)
end

local function findNewVigilantInterest(sim, unit)
    local x0, y0 = unit:getLocation()
    local c0 = x0 and sim:getCell(x0, y0)
    if not c0 then
        return
    end

    local cells = simquery.floodFill(sim, unit, c0, VIG_RADIUS, nil, simquery.canSoftPath, nil, sim)

    local tooClose = {}
    for x = x0 - 1, x0 + 1 do
        for y = y0 - 1, y0 + 1 do
            tooClose[simquery.toCellID(x, y)] = true
        end
    end

    local wt = util.weighted_list()
    for _, cell in ipairs(cells) do
        if not tooClose[cell.id] then
            -- Higher weight for cells in cover
            local w = isCellHidden(sim, x0, y0, cell.x, cell.y) and HIDDEN_WEIGHT or 1
            wt:addChoice(cell, w)
        end
    end
    if wt:getTotalWeight() == 0 then
        simlog("QDBG VIGILANCE %d %d,%d #wt=0", unit:getID(), x0, y0)
        return
    end
    local cell = wt:getChoice(sim:nextRand(1, wt:getTotalWeight()))
    simlog(
            "QDBG VIGILANCE %d %d,%d->%d,%d #=%d hidden=%d", unit:getID(), x0, y0, cell.x, cell.y,
            wt:getCount(), (wt:getTotalWeight() - wt:getCount()) / (HIDDEN_WEIGHT - 1))
    return cell
end

local oldRemoveInterest = actions.RemoveInterest
function actions.RemoveInterest(sim, unit)
    local shouldVig = canVigilance(sim, unit)

    local res = oldRemoveInterest(sim, unit)

    if res == simdefs.BSTATE_COMPLETE and shouldVig then
        local cell = findNewVigilantInterest(sim, unit)
        local interest = cell and unit:getBrain():getSenses():addInterest(
                cell.x, cell.y, simdefs.SENSE_RADIO, simdefs.REASON_NOTICED, unit)
        if interest then
            interest.vigilance = true
        end
    end

    return res
end

local function hasVigilantInterest(unit)
    for _, interest in ipairs(unit:getBrain():getSenses().interests) do
        if interest.vigilance then
            return interest
        end
    end
end

local oldRequestNewHuntTarget = actions.RequestNewHuntTarget
function actions.RequestNewHuntTarget(sim, unit)
    if unit:getBrain():getSituation().ClassType == simdefs.SITUATION_HUNT then
        local interest = hasVigilantInterest(unit)
        if interest then
            -- simlog("QDBG ending on vigilant interest")
            unit:getBrain():getSituation():overrideHuntTarget(unit, interest)
            return simdefs.BSTATE_COMPLETE
        end
    end

    return oldRequestNewHuntTarget(sim, unit)
end

local oldFinishSearch = actions.FinishSearch
function actions.FinishSearch(sim, unit)
    if hasVigilantInterest(unit) then
        -- simlog("QDBG ending on vigilant interest")
        return simdefs.BSTATE_COMPLETE
    end

    return oldFinishSearch(sim, unit)
end
