morphling_bubble = class({})
function morphling_bubble:GetIntrinsicModifierName()
    return "modifier_morphling_bubble"
end

modifier_morphling_bubble = class({})
function modifier_morphling_bubble:OnCreated()
    if not IsServer() then return end

    -- str = 0
    -- agi = 1
    -- int = 2
    -- universal = 3
    -- max? = 4
    self:GetParent():SetPrimaryAttribute(2)
end

function modifier_morphling_bubble:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_morphling_bubble:GetModifierMoveSpeedBonus_Percentage()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    return math.min(math.max(0, (parent:GetAgility() - parent:GetStrength()) * ability:GetSpecialValueFor("ms_pct_agi")), ability:GetSpecialValueFor("max_ms_pct"))
end

function modifier_morphling_bubble:GetModifierBaseAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_base_attack")
end

function modifier_morphling_bubble:OnAbilityFullyCast()
    self:OnCreated()
end

LinkLuaModifier("modifier_morphling_bubble", "ability/morphling_bubble.lua", LUA_MODIFIER_MOTION_NONE)