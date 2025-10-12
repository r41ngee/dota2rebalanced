item_shamelis = class({})
function item_shamelis:GetIntrinsicModifierName()
    return "modifier_item_shamelis"
end

modifier_item_shamelis = class({})
function modifier_item_shamelis:IsHidden()
    return true
end
function modifier_item_shamelis:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,

        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,

        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
    }
end

function modifier_item_shamelis:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
function modifier_item_shamelis:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end
function modifier_item_shamelis:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end
function modifier_item_shamelis:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end
function modifier_item_shamelis:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_ats")
end
function modifier_item_shamelis:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_hpregen")
end
function modifier_item_shamelis:GetModifierConstantManaRegen() return self:GetAbility():GetSpecialValueFor("bonus_manaregen") end


function modifier_item_shamelis:GetModifierPreAttack_CriticalStrike(event)
    local attacker = event.attacker
    if attacker ~= self:GetParent() then
        return
    end
    local target = event.target

    local ability = self:GetAbility()

    if attacker:GetTeamNumber() == target:GetTeamNumber() then
        return
    end

    if RandomInt(0, 100) < ability:GetSpecialValueFor("crit_chance_pct") then
        target:AddNewModifier(
            attacker,
            ability,
            "modifier_item_shamelis_bash",
            {
                duration = ability:GetSpecialValueFor("crit_bash_duration")
            }
        )
        return ability:GetSpecialValueFor("crit_damage_pct")
    end
end

modifier_item_shamelis_bash = class({})
function modifier_item_shamelis_bash:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

LinkLuaModifier("modifier_item_shamelis", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shamelis_bash", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)