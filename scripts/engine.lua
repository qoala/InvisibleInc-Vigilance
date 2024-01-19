local simengine = include("sim/engine")

local oldInit = simengine.init
function simengine:init(...)
    oldInit(self, ...)
    self:getNPC():addMainframeAbility(self, "qed_vigilance", nil, 0)
end
