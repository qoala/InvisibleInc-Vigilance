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

local function unload(modApi)
    local scriptPath = modApi:getScriptPath()

    local npc_abilities = include(scriptPath .. "/npc_abilities")
    for name, ability in pairs(npc_abilities) do
        modApi:addDaemonAbility(name, ability)
    end

    modApi:addTooltipDef(include(scriptPath .. "/commondefs"))
end
local function load(modApi, options, params)
    unload(modApi)
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
