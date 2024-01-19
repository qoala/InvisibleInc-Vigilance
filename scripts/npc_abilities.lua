local util = include("modules/util")
local mainframe_common = include("sim/abilities/mainframe_common")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include("client_defs")

local createDaemon = mainframe_common.createDaemon

--

local function isOK(unit)
    return unit and unit:getLocation() and unit:isValid() and not unit:isDown()
end

local function isBrainy(unit)
    return isOK(unit) and unit:getPlayerOwner():isNPC() and unit:getBrain()
end

local function isValidGuard(unit)
    return not unit:getTraits().alerted and unit:getPlayerOwner():isNPC()
    -- and not unit:getTraits().hasVigTarget
end

SENSE_REASONS = {
    [simdefs.SENSE_PERIPHERAL] = {
        [simdefs.REASON_DOOR] = true,
        [simdefs.REASON_SENSEDTARGET] = true,
    },
    [simdefs.SENSE_SIGHT] = {
        [simdefs.REASON_DOOR] = true,
    },
    [simdefs.SENSE_HEARING] = {
        [simdefs.REASON_NOISE] = true,
    },
}
local function isValidInterest(sim, interest)
    if interest.sourceUnit and simquery.isEnemyAgent(sim:getNPC(), interest.sourceUnit, true) then
        local reasons = SENSE_REASONS[interest.sense]
        return reasons and reasons[interest.reason]
    end
end

--

local qed_vigilance = util.extend(createDaemon(STRINGS.QED_VIG.DAEMONS.VIGILANCE)) {
    icon = "gui/icons/daemon_icons/Daemons0004.png",

    standardDaemon = false,
    reverseDaemon = false,
    permanent = true,
    noDaemonReversal = true,

    ENDLESS_DAEMONS = false,
    PROGRAM_LIST = false,
    OMNI_PROGRAM_LIST_EASY = false,
    OMNI_PROGRAM_LIST = false,
    REVERSE_DAEMONS = false,
}

function qed_vigilance:onSpawnAbility(sim, player)
    sim:addTrigger(simdefs.TRG_START_TURN, self)
    sim:addTrigger(simdefs.TRG_UNIT_NEWINTEREST, self)
    -- sim:addTrigger(simdefs.TRG_UNIT_NEWTARGET, self)
end
function qed_vigilance:onDespawnAbility(sim)
    sim:removeTrigger(simdefs.TRG_START_TURN, self)
    sim:removeTrigger(simdefs.TRG_UNIT_NEWINTEREST, self)
    -- sim:removeTrigger(simdefs.TRG_UNIT_NEWTARGET, self)
end

function qed_vigilance:onTrigger(sim, evType, evData)
    if evType == simdefs.TRG_START_TURN and evData:isPC() then
        self:onStartTurn(sim)
    elseif evType == simdefs.TRG_UNIT_NEWINTEREST and isValidGuard(evData.unit) and
            isValidInterest(sim, evData.interest) then
        self:onNotice(sim, evData.unit, evData.interest.sourceUnit)
    end
    if evType == simdefs.TRG_UNIT_NEWINTEREST then
        simlog("QDBG: vig trg %s", tostring(evData.unit))
        util.tlog(util.tkeys(evData or {}))
        util.tlog(util.tkeys(evData.unit or {}))
    end
    -- elseif evType == simdefs.TRG_UNIT_NEWTARGET then
    --     self:onNotice(sim, evData.unit, evData.target)
end
function qed_vigilance:onStartTurn(sim)
    for _, unit in pairs(sim:getAllUnits()) do
        if unit:getTraits().hasVigTarget then
            local target = sim:getUnit(unit:getTraits().hasVigTarget)
            local brain = target and isBrainy(unit)
            if brain and isOK(target) then
                local x, y = target:getLocation()
                local x0, y0 = unit:getLocation()
                sim:dispatchEvent(
                        simdefs.EV_UNIT_FLOAT_TXT, {
                            txt = STRINGS.QED_VIG.UI.VIGILANCE,
                            x = x,
                            y = y,
                            color = {r = 101 / 255, g = 232 / 255, b = 248 / 255, a = 1},
                        })
                -- sim:dispatchEvent(simdefs.EV_UNIT_WIRELESS_SCAN, {unitID = target:getID()})
                brain:getSenses():addInterest(
                        x, y, simdefs.SENSE_SIGHT, simdefs.REASON_SCANNED, target, true)
            end

            -- Cleanup.
            unit:getTraits().hasVigTarget = nil
        end
    end
end
function qed_vigilance:onNotice(sim, unit, target)
    unit:getTraits().hasVigTarget = target:getID()

    local x0, y0 = target:getLocation()
    sim:dispatchEvent(simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_wisp_reveal")
    sim:dispatchEvent(
            simdefs.EV_UNIT_FLOAT_TXT, {
                txt = STRINGS.QED_VIG.UI.VIGILANCE,
                x = x0,
                y = y0,
                color = {r = 101 / 255, g = 232 / 255, b = 248 / 255, a = 1},
            })
    -- sim:dispatchEvent(
    --         simdefs.EV_UNIT_ADD_FX, {
    --             unit = target,
    --             kanim = "fx/firewall_buff_fx_2",
    --             symbol = "character",
    --             anim = "in",
    --             above = true,
    --             params = {
    --                 color = {
    --                     {symbol = "wall", r = 101 / 255, g = 232 / 255, b = 248 / 255, a = 1},
    --                     {
    --                         symbol = "outline_side",
    --                         r = 101 / 255,
    --                         g = 232 / 255,
    --                         b = 248 / 255,
    --                         a = 0.75,
    --                     },
    --                 },
    --             },
    --         })
end

return {qed_vigilance = qed_vigilance}
