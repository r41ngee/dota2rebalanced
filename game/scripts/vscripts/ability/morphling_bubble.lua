morphling_bubble = class({})
function morphling_bubble:GetIntrinsicModifierName()
    return "modifier_morphling_bubble"
end

modifier_morphling_bubble = class({})
function modifier_morphling_bubble:OnCreated()
    -- str = 0
    -- agi = 1
    -- int = 2
    -- universal = 3
    -- max? = 4
    self:GetParent():SetPrimaryAttribute(2)
end

LinkLuaModifier("modifier_morphling_bubble", "ability/morphling_bubble.lua", LUA_MODIFIER_MOTION_NONE)