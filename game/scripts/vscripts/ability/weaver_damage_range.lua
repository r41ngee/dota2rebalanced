weaver_damage_range = class({})

function weaver_damage_range:GetIntrinsicModifierName() 
    return "modifier_weaver_damage_range" 
end

modifier_weaver_damage_range = class({})

function modifier_weaver_damage_range:IsHidden() 
    return false 
end

function modifier_weaver_damage_range:IsPurgable() 
    return false 
end

function modifier_weaver_damage_range:IsDebuff() 
    return false 
end

function modifier_weaver_damage_range:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
    }
end

function modifier_weaver_damage_range:GetModifierAttackRangeBonus()
    local parent = self:GetParent()
    local baseattack_damage = (parent:GetDamageMax() + parent:GetDamageMin()) / 2

    return baseattack_damage * self:GetAbility():GetSpecialValueFor("bonus_range_pct") / 100
end

LinkLuaModifier("modifier_weaver_damage_range", "ability/weaver_damage_range.lua", LUA_MODIFIER_MOTION_NONE)