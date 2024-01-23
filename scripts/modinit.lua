local serverdefs = include("modules/serverdefs")

local function earlyInit(modApi)
    modApi.requirements = {
        -- "Function Library",
    }
end

local function init(modApi)
    local scriptPath = modApi:getScriptPath()
    -- Store script path for cross-file includes
    -- rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})
    -- SCRIPT_PATHS.qed_vig = scriptPath

    local STR = STRINGS.QED_VIG.OPTIONS

    modApi:addGenerationOption(
            "mode", STR.MODE, STR.MODE_TIP, {
                noUpdate = true,
                values = {false, 1}, -- 2, 3},
                value = 1,
                strings = STR.MODE_OPTS,
                masks = {{mask = "mask_qed_vig_always", requirement = 1}},
            })
    modApi:addGenerationOption(
            "startDay", STR.START_DAY, STR.START_DAY_TIP, {
                noUpdate = true,
                values = {1, 2, 3, 4, 5},
                value = 1,
                requirements = {{mask = "mask_qed_vig_always", requirement = true}},
            })

    local dataPath = modApi:getDataPath()
    KLEIResourceMgr.MountPackage(dataPath .. "/gui.kwad", "data")

    include(scriptPath .. "/engine")
end

local function lateInit(modApi)
end

local function earlyUnload(modApi)
end

local function earlyLoad(modApi, options, params)
    earlyUnload(modApi)
end

local function load(modApi, options, params)
    local scriptPath = modApi:getScriptPath()

    local npc_abilities = include(scriptPath .. "/npc_abilities")
    for name, ability in pairs(npc_abilities) do
        modApi:addDaemonAbility(name, ability)
    end
    modApi:addTooltipDef(include(scriptPath .. "/commondefs"))

    if params then
        local mode = options["mode"] and options["mode"].value
        if mode == 1 then
            params.qed_vigMode = 1
            params.qed_vigStart = options["startDay"] and options["startDay"].value or 1
        elseif mode == 2 then
            params.qed_vigMode = 2
        elseif mode == 3 then
            params.qed_vigMode = 3
        end
    end
end

local function unload(modApi)
    if (config.QED_FORCE_VIG) then
        load(modApi, {})
    end
end

local function lateLoad(modApi, options, params)
end

local function initStrings(modApi)
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()

    modApi:addStrings(dataPath, "QED_VIG", include(scriptPath .. "/strings"))
end

return {
    earlyInit = earlyInit,
    init = init,
    -- lateInit = lateInit,
    -- earlyLoad = earlyLoad,
    -- earlyUnload = earlyUnload,
    load = load,
    unload = unload,
    -- lateLoad = lateLoad,
    initStrings = initStrings,
}
