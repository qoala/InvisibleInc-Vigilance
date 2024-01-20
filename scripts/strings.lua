local s = {
    DAEMONS = {
        VIGILANCE = {
            NAME = "VIGILANCE",
            DESC = "Pinpoint agent location at the start of the next turn after being noticed or heard by non-alerted guards.",
            SHORT_DESC = "Guides non-alerted guards",
            ACTIVE_DESC = "",
        },
    },
    TOOLTIPS = {
        VIGILANCE = "VIGILANCE PROTOCOL",
        VIGILANCE_GUARD_DESC = "Next turn, this guard will receive the location of: {1}",
        VIGILANCE_TARGET_DESC = "This agent has been marked. Next turn, this agent's position will be relayed to security.",
    },
    UI = { --
        VIGILANCE = "VIGILANCE",
    },
}

return s
