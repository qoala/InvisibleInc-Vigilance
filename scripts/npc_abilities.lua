local util = include("client_util")
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
    return not unit:getTraits().alerted and unit:getPlayerOwner():isNPC() and
                   not (unit:getTraits().pacifist and not unit:getTraits().isDrone)
    -- and not unit:getTraits().hasVigTarget
end

SENSE_REASONS = {
    [simdefs.SENSE_PERIPHERAL] = {
        [simdefs.REASON_DOOR] = true,
        [simdefs.REASON_SENSEDTARGET] = true, -- Static peripheral vision.
        [simdefs.REASON_NOTICED] = true, -- Noticed by peeking.
    },
    [simdefs.SENSE_SIGHT] = {[simdefs.REASON_DOOR] = true},
    [simdefs.SENSE_HEARING] = {[simdefs.REASON_NOISE] = true},
}
local function isValidInterest(sim, interest)
    if interest.sourceUnit and simquery.isEnemyAgent(sim:getNPC(), interest.sourceUnit, true) then
        local reasons = SENSE_REASONS[interest.sense]
        return reasons and reasons[interest.reason]
    end
end

-- Skip vigilance notification for peek-noticed agents that are still the guard's interest.
-- Such interests are otherwise just a retargeting of vigilance protocol rather than a primary source.
local function alreadyNoticed(brain, target)
    local i = brain:getInterest()
    local x, y = target:getLocation()
    return i and i.x == x and i.y == y and
                   ((i.sense == simdefs.SENSE_PERIPHERAL and i.reason == simdefs.REASON_NOTICED) or
                           i.reason == simdefs.REASON_SCANNED)
end

-- function cleanupVigTarget(target)
--     if target and target.isVigTarget and target.isVigTarget > 0 then
--         target.isVigTarget = target.isVigTarget - 1
--         if target.isVigTarget == 0 then
--             target.isVigTarget = nil
--         end
--     end
-- end

--

local vigBase = util.extend(createDaemon(STRINGS.QED_VIG.DAEMONS.VIGILANCE)) {
    icon = "gui/icons/daemon_icons/vigilance.png",

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

function vigBase:onSpawnAbility(sim, player)
    sim:addTrigger(simdefs.TRG_START_TURN, self)
    sim:addTrigger(simdefs.TRG_UNIT_NEWINTEREST, self)
    -- sim:addTrigger(simdefs.TRG_UNIT_NEWTARGET, self)
end
function vigBase:onDespawnAbility(sim)
    sim:removeTrigger(simdefs.TRG_START_TURN, self)
    sim:removeTrigger(simdefs.TRG_UNIT_NEWINTEREST, self)
    -- sim:removeTrigger(simdefs.TRG_UNIT_NEWTARGET, self)
end

function vigBase:onTooltip(hud, sim, player)
    local tooltip = util.tooltip(hud._screen)
    local section = tooltip:addSection()
    -- Vanilla lines
    section:addLine(self.name)
    section:addAbility(
            self.shortdesc, self.desc,
            "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png")
    -- Additional line.
    section:addAbility(
            STRINGS.QED_VIG.DAEMONS.VIGILANCE.SCOPE, STRINGS.QED_VIG.DAEMONS.VIGILANCE.SCOPE_DESC,
            "gui/icons/arrow_small.png")
    -- Vanilla footer
    if self.dlcFooter then
        section:addFooter(self.dlcFooter[1], self.dlcFooter[2])
    end

    return tooltip
end

function vigBase:onTrigger(sim, evType, evData)
    if evType == simdefs.TRG_START_TURN and evData:isPC() then
        self:onStartTurn(sim)
    elseif evType == simdefs.TRG_UNIT_NEWINTEREST and isValidGuard(evData.unit) and
            isValidInterest(sim, evData.interest) then
        self:onNotice(sim, evData.unit, evData.interest.sourceUnit)
    end
    -- elseif evType == simdefs.TRG_UNIT_NEWTARGET then
    --     self:onNotice(sim, evData.unit, evData.target)
end
function vigBase:onStartTurn(sim)
    for _, unit in pairs(sim:getAllUnits()) do
        if unit:getTraits().hasVigTarget then
            local target = sim:getUnit(unit:getTraits().hasVigTarget)
            local brain = target and not unit:getTraits().alerted and isBrainy(unit)
            if brain and isOK(target) and not alreadyNoticed(brain, target) then
                local x, y = target:getLocation()
                local x0, y0 = unit:getLocation()
                sim:dispatchEvent(
                        simdefs.EV_UNIT_FLOAT_TXT, {
                            txt = STRINGS.QED_VIG.UI.VIGILANCE,
                            x = x,
                            y = y,
                            color = {r = 101 / 255, g = 232 / 255, b = 248 / 255, a = 1},
                        })
                brain:getSenses():addInterest(
                        x, y, simdefs.SENSE_SIGHT, simdefs.REASON_SCANNED, target, true)
            end

            -- Cleanup.
            unit:getTraits().hasVigTarget = nil
            -- cleanupVigTarget(target)
        end
    end
end
function vigBase:onNotice(sim, unit, target)
    if unit:getTraits().hasVigTarget == target:getID() then
        return -- Already tracking.
    end
    -- if unit:getTraits().hasVigTarget then
    --     cleanupVigTarget(sim:getUnit(unit:getTraits().hasVigTarget))
    -- end
    unit:getTraits().hasVigTarget = target:getID()
    -- target:getTraits().isVigTarget = (target:getTraits().isVigTarget or 0) + 1

    local x0, y0 = target:getLocation()
    sim:dispatchEvent(simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_wisp_reveal")
    sim:dispatchEvent(
            simdefs.EV_UNIT_FLOAT_TXT, {
                txt = STRINGS.QED_VIG.UI.VIGILANCE,
                x = x0,
                y = y0,
                color = {r = 101 / 255, g = 232 / 255, b = 248 / 255, a = 1},
            })
end

local qed_vigilance_mission = util.extend(vigBase) {}

local qed_vigilance_alarm = util.extend(vigBase) {
    activedesc = STRINGS.QED_VIG.DAEMONS.VIGILANCE.ALARM_ACTIVE_DESC,
}
function qed_vigilance_alarm:onSpawnAbility(sim, player)
    sim:dispatchEvent(
            simdefs.EV_SHOW_DAEMON, {name = self.name, icon = self.icon, txt = self.activedesc})

    vigBase.onSpawnAbility(self, sim, player)
end

return { --
    qed_vigilance_mission = qed_vigilance_mission,
    qed_vigilance_alarm = qed_vigilance_alarm,
}
