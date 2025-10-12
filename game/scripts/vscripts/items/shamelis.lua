item_shamelis = class({})
function item_shamelis:GetIntrinsicModifierName()
    return "modifier_item_shamelis"
end

function item_shamelis:OnSpellStart()
    local target = self:GetCursorTarget()
    local caster = self:GetCaster()

    if target:TriggerSpellAbsorb(self) or target:TriggerSpellReflect(self) then
        return
    end

    target:AddNewModifier(
        caster,
        self,
        "modifier_item_shamelis_bash",
        {
            duration = self:GetSpecialValueFor("active_bash_duration")
        }
    )

    target:AddNewModifier(
        caster,
        self,
        "modifier_item_shamelis_silence",
        {
            duration = self:GetSpecialValueFor("active_silence_duration")
        }
    )
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

function modifier_item_shamelis:OnCreated()
    self.prd_attack_counter = 0
end

function modifier_item_shamelis:GetModifierPreAttack_CriticalStrike(event)
    local attacker = event.attacker
    if attacker ~= self:GetParent() then return end
    
    local ability = self:GetAbility()
    local target = event.target
    
    if attacker:GetTeamNumber() == target:GetTeamNumber() then return end

    self.last_attack_target = target
    self.last_attack_crit = PRDCalc_Pct(ability:GetSpecialValueFor("crit_chance_pct"), self.prd_attack_counter)
    
    if self.last_attack_crit then
        self.prd_attack_counter = 0
        return ability:GetSpecialValueFor("crit_damage_pct")
    else
        self.prd_attack_counter = self.prd_attack_counter + 1
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
function modifier_item_shamelis_bash:IsPurgable() return false end
function modifier_item_shamelis_bash:IsPurgeException() return true end

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

modifier_item_shamelis_silence = class({})
function modifier_item_shamelis_silence:IsHidden() return false end
function modifier_item_shamelis_silence:IsDebuff() return true end
function modifier_item_shamelis_silence:IsPurgable() return true end

function modifier_item_shamelis_silence:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_item_shamelis_silence:OnCreated()
    self.start_hp = self:GetParent():GetHealth()
end

function modifier_item_shamelis_silence:OnDestroy()
    if not IsServer() then return end

    if self:GetRemainingTime() <= 0 then
        local current_hp = self:GetParent():GetHealth()
        if self.start_hp > current_hp then
            ApplyDamage({
                victim = self:GetParent(),
                attacker = self:GetCaster(),
                damage = (self.start_hp - current_hp) * (self:GetAbility():GetSpecialValueFor("silence_afterburn_pct") / 100),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_item_shamelis_silence:GetEffectName()
    return "particles/items2_fx/orchid.vpcf"
end

function modifier_item_shamelis_silence:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

LinkLuaModifier("modifier_item_shamelis", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shamelis_bash", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shamelis_silence", "items/shamelis.lua", LUA_MODIFIER_MOTION_NONE)