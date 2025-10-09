item_shamelis = class({})
function item_shamelis:GetIntrinsicModifierName()
    return "modifier_item_shamelis"
end

modifier_item_shamelis = class({})
function modifier_item_shamelis:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
    }
end

function modifier_item_shamelis:GetModifierPreAttack_CriticalStrike()
    if RandomFloat(0, 1) < self:GetAbility():GetSpecialValueFor("crit_chance_pct") / 100 then
        return self:GetAbility():GetSpecialValueFor("crit_damage_pct")
    end
    return 0
end

function modifier_item_shamelis:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
function modifier_item_shamelis:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end
function modifier_item_shamelis:GetModifierConstantManaRegen() return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end

LinkLuaModifier("modifier_item_shamelis", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)