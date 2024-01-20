local util = include("modules/util")

-- function onAgentTooltip(tooltip, unit)
--     if unit:getTraits().isVigTarget and unit:getTraits().isVigTarget > 0 then
--         tooltip:addAbility(
--                 STRINGS.QED_VIG.TOOLTIPS.VIGILANCE, STRINGS.QED_VIG.TOOLTIPS.VIGILANCE_TARGET_DESC,
--                 "gui/icons/skills_icons/skills_icon_small/icon-item_overwatch_small.png")
--     end
-- end
function onGuardTooltip(tooltip, unit)
    if unit:getTraits().hasVigTarget then
        local target = unit:getSim():getUnit(unit:getTraits().hasVigTarget)
        if target then
            local desc = util.sformat(
                    STRINGS.QED_VIG.TOOLTIPS.VIGILANCE_GUARD_DESC, target:getName())
            tooltip:addAbility(
                    STRINGS.QED_VIG.TOOLTIPS.VIGILANCE, desc,
                    "gui/icons/skills_icons/skills_icon_small/icon-item_overwatch_small.png")
        end
    end
end

return { --
    -- onAgentTooltip = onAgentTooltip,
    onGuardTooltip = onGuardTooltip,
}
