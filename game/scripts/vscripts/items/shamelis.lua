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

        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
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
    if attacker ~= self:GetParent() then return end
    
    local ability = self:GetAbility()
    local target = event.target
    
    if attacker:GetTeamNumber() == target:GetTeamNumber() then return end

    self.last_attack_target = target
    self.last_attack_crit = RandomInt(0, 100) < ability:GetSpecialValueFor("crit_chance_pct")
    
    if self.last_attack_crit then
        return ability:GetSpecialValueFor("crit_damage_pct")
    end
end

function modifier_item_shamelis:OnAttackLanded(event)
    if not IsServer() then return end
    
    local attacker = event.attacker
    local target = event.target
    
    if attacker ~= self:GetParent() then return end
    if attacker:GetTeamNumber() == target:GetTeamNumber() then return end
    
    if target == self.last_attack_target and self.last_attack_crit then
        local ability = self:GetAbility()
        
        target:AddNewModifier(
            attacker,
            ability,
            "modifier_item_shamelis_bash",
            {
                duration = ability:GetSpecialValueFor("crit_bash_duration")
            }
        )
    end
    
    -- Сбрасываем
    self.last_attack_target = nil
    self.last_attack_crit = false
end

modifier_item_shamelis_bash = class({})

function modifier_item_shamelis_bash:IsHidden() return false end
function modifier_item_shamelis_bash:IsDebuff() return true end
function modifier_item_shamelis_bash:IsPurgable() return true end

function modifier_item_shamelis_bash:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_item_shamelis_bash:GetEffectName()
    return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_item_shamelis_bash:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_item_shamelis_bash:OnCreated()
    if IsServer() then
        EmitSoundOn("DOTA_Item.AbyssalBlade.Target", self:GetParent())
    end
end

LinkLuaModifier("modifier_item_shamelis", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shamelis_bash", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)