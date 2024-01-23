local simengine = include("sim/engine")

local oldInit = simengine.init
function simengine:init(...)
    oldInit(self, ...)

    local opts = self:getParams().difficultyOptions
    if config.QED_FORCE_VIG == 1 or
            (opts.qed_vigMode == 1 and (opts.qed_vigStart or 1) >= self:getParams().difficulty) then
        self:getNPC():addMainframeAbility(self, "qed_vigilance", nil, 0)
    end
end
