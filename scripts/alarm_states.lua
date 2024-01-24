local simdefs = include("sim/simdefs")
local alarm_states = include("sim/alarm_states")
local spawnGuards = alarm_states.guards

local function changePatrols(sim)
    -- shift guard patrols
    local idle = sim:getNPC():getIdleSituation()
    local guards = sim:getNPC():getUnits()

    for i, guard in ipairs(guards) do
        if guard:getBrain() and guard:getBrain():getSituation().ClassType == simdefs.SITUATION_IDLE then
            idle:generatePatrolPath(guard)
            if guard:getTraits().patrolPath and #guard:getTraits().patrolPath > 1 then
                local firstPoint = guard:getTraits().patrolPath[1]
                guard:getBrain():getSenses():addInterest(
                        firstPoint.x, firstPoint.y, simdefs.SENSE_RADIO,
                        simdefs.REASON_PATROLCHANGED, guard)
            end
        end
    end
    sim:processReactions()
end

local oldExecuteSpawnGuards = spawnGuards.executeAlarm
function spawnGuards:executeAlarm(sim, stage)
    local opts = sim:getParams().difficultyOptions
    if config.QED_FORCE_VIG == 2 or opts.qed_vigNoCM and not sim:getTags().noCountermeasures then
        sim:getTags().noCountermeasures = true
    end

    oldExecuteSpawnGuards(self, sim, stage)

    if not sim:getTags().qed_vig and not sim:getTags().qed_noVig and
            (config.QED_FORCE_VIG == 2 or opts.qed_vigMode == 2) and sim:getParams().missionEvents and
            sim:getParams().missionEvents.advancedAlarm then
        sim:getTags().qed_vig = true
        sim:getNPC():addMainframeAbility(sim, "qed_vigilance_alarm", nil, 0)
        changePatrols(sim)
    end
end
