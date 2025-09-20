templar_assassin_refraction_new = class({})

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
function templar_assassin_refraction_new:Precache(context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_templar_assassin.vsndevts", context)
    PrecacheResource("particle", "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf", context)
end

--------------------------------------------------------------------------------
-- Ability Cast
--------------------------------------------------------------------------------
function templar_assassin_refraction_new:OnSpellStart()
    if not IsServer() then return end
    
    local caster = self:GetCaster()
    
    -- Get values
    local duration = self:GetSpecialValueFor("duration")
    local instances = self:GetSpecialValueFor("instances")
    local bonus_damage = self:GetSpecialValueFor("bonus_damage")
    local shield_per_instance = self:GetSpecialValueFor("shield_per_instance")
    
    -- Remove existing modifiers if any
    local existing_shield = caster:FindModifierByName("modifier_templar_assassin_refraction_shield")
    local existing_damage = caster:FindModifierByName("modifier_templar_assassin_refraction_damage")
    if existing_shield then existing_shield:Destroy() end
    if existing_damage then existing_damage:Destroy() end
    
    -- Apply shield modifier
    caster:AddNewModifier(
        caster,
        self,
        "modifier_templar_assassin_refraction_shield",
        {
            duration = duration,
            instances = instances,
            shield_per_instance = shield_per_instance
        }
    )
    
    -- Apply damage modifier
    caster:AddNewModifier(
        caster,
        self,
        "modifier_templar_assassin_refraction_damage",
        {
            duration = duration,
            instances = instances,
            bonus_damage = bonus_damage
        }
    )
    
    -- Apply visual effect modifier
    caster:AddNewModifier(
        caster,
        self,
        "modifier_templar_assassin_refraction_visual",
        { duration = 3.0 }
    )
    
    -- Play sound
    EmitSoundOn("Hero_TemplarAssassin.Refraction", caster)
    
    -- Create particle effect
    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)
end

--------------------------------------------------------------------------------
-- Ability Considerations
--------------------------------------------------------------------------------
function templar_assassin_refraction_new:GetAbilityTextureName()
    return "templar_assassin_refraction"
end

function templar_assassin_refraction_new:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end

function templar_assassin_refraction_new:GetCooldown(level)
    local base_cd = self:GetSpecialValueFor("ability_cooldown")
    return base_cd
end

function templar_assassin_refraction_new:GetManaCost(level)
    local mana_cost = self:GetSpecialValueFor("ability_mana_cost")
    return mana_cost
end

function templar_assassin_refraction_new:CastFilterResult()
    local cast_while_disabled = self:GetSpecialValueFor("cast_while_disabled")
    
    -- Можно кастовать в дизейблах если есть талант
    if cast_while_disabled > 0 then
        return UF_SUCCESS
    end
    
    -- Обычная проверка на дизейблы
    if self:GetCaster():IsStunned() or 
       self:GetCaster():IsHexed() or 
       self:GetCaster():IsSilenced() or 
       self:GetCaster():IsCommandRestricted() then
        return UF_FAIL_CUSTOM
    end
    
    return UF_SUCCESS
end

function templar_assassin_refraction_new:GetCustomCastError()
    return "#dota_hud_error_ability_disabled"
end

-- Остальные модификаторы остаются без изменений...

-- Регистрация модификаторов в конце файла
LinkLuaModifier("modifier_templar_assassin_refraction_shield", "templar_assassin_refraction_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_damage", "templar_assassin_refraction_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_visual", "templar_assassin_refraction_new", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
-- Modifier: Shield
--------------------------------------------------------------------------------
modifier_templar_assassin_refraction_shield = class({})

function modifier_templar_assassin_refraction_shield:IsHidden()
    return false
end

function modifier_templar_assassin_refraction_shield:IsPurgable()
    return true
end

function modifier_templar_assassin_refraction_shield:IsDebuff()
    return false
end

function modifier_templar_assassin_refraction_shield:OnCreated(kv)
    if not IsServer() then return end
    
    self.instances = kv.instances or self:GetAbility():GetSpecialValueFor("instances")
    self.shield_per_instance = kv.shield_per_instance or self:GetAbility():GetSpecialValueFor("shield_per_instance")
    
    -- Инициализируем с защитой от nil
    self.remaining_instances = self.instances or 0
    self.total_shield_health = (self.remaining_instances or 0) * (self.shield_per_instance or 0)
    self.current_shield_health = self.total_shield_health or 0
    
    self:StartIntervalThink(0.1)
    self:SetStackCount(self.remaining_instances)
end

function modifier_templar_assassin_refraction_shield:OnRefresh(kv)
    self:OnCreated(kv)
end

function modifier_templar_assassin_refraction_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_templar_assassin_refraction_shield:GetModifierIncomingDamageConstant(keys)
    if not self.remaining_instances or not self.current_shield_health then
        return 0
    end
    
    if self.remaining_instances <= 0 or self.current_shield_health <= 0 then
        return 0
    end
    
    -- Полное поглощение урона пока есть щит
    return -keys.damage
end

function modifier_templar_assassin_refraction_shield:OnIntervalThink()
    if not IsServer() then return end
    if self.remaining_instances then
        self:SetStackCount(self.remaining_instances)
    end
end

function modifier_templar_assassin_refraction_shield:OnTakeDamage(keys)
    if not IsServer() then return end
    
    -- Защита от nil значений
    if not self.remaining_instances or not self.current_shield_health then
        return
    end
    
    local unit = keys.unit
    local attacker = keys.attacker
    local damage = keys.damage

    if unit ~= self:GetParent() then return end
    if self.remaining_instances <= 0 then return end
    if unit == attacker or (attacker and unit:GetTeam() == attacker:GetTeam()) then return end
    if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
        return
    end

    -- Уменьшаем здоровье щита
    self.current_shield_health = self.current_shield_health - damage
    
    -- Если щит сломан
    if self.current_shield_health <= 0 then
        self.remaining_instances = self.remaining_instances - 1
        
        if self.remaining_instances > 0 then
            -- Создаем новый щит
            self.current_shield_health = self.shield_per_instance or 0
            self.total_shield_health = (self.remaining_instances or 0) * (self.shield_per_instance or 0)
        else
            self.current_shield_health = 0
            self.total_shield_health = 0
        end
        
        self:SetStackCount(self.remaining_instances)

        -- Эффект блокировки (используем основную частицу)
        local particle = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            unit
        )
        ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle)

        EmitSoundOn("Hero_TemplarAssassin.Refraction", unit)

        if self.remaining_instances <= 0 then
            self:Destroy()
        end
    end
end

function modifier_templar_assassin_refraction_shield:OnTooltip()
    return self.remaining_instances or 0
end

function modifier_templar_assassin_refraction_shield:GetEffectName()
    return "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf"
end

function modifier_templar_assassin_refraction_shield:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------
-- Modifier: Damage
--------------------------------------------------------------------------------
modifier_templar_assassin_refraction_damage = class({})

function modifier_templar_assassin_refraction_damage:IsHidden()
    return false
end

function modifier_templar_assassin_refraction_damage:IsPurgable()
    return true
end

function modifier_templar_assassin_refraction_damage:IsDebuff()
    return false
end

function modifier_templar_assassin_refraction_damage:OnCreated(kv)
    if not IsServer() then return end
    
    self.instances = kv.instances or self:GetAbility():GetSpecialValueFor("instances")
    self.bonus_damage = kv.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
    
    self.remaining_instances = self.instances
    self:SetStackCount(self.remaining_instances)
end

function modifier_templar_assassin_refraction_damage:OnRefresh(kv)
    self:OnCreated(kv)
end

function modifier_templar_assassin_refraction_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_templar_assassin_refraction_damage:GetModifierPreAttack_BonusDamage()
    -- Даем бонусный урон только если есть charges урона
    if self.remaining_instances > 0 then
        return self.bonus_damage
    end
    return 0
end

function modifier_templar_assassin_refraction_damage:OnTooltip()
    return self.remaining_instances
end

--------------------------------------------------------------------------------
-- Modifier: Visual Effect
--------------------------------------------------------------------------------
modifier_templar_assassin_refraction_visual = class({})

function modifier_templar_assassin_refraction_visual:IsHidden()
    return true
end

function modifier_templar_assassin_refraction_visual:IsPurgable()
    return true
end

function modifier_templar_assassin_refraction_visual:IsDebuff()
    return false
end

function modifier_templar_assassin_refraction_visual:GetEffectName()
    return "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf"
end

function modifier_templar_assassin_refraction_visual:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

LinkLuaModifier("modifier_templar_assassin_refraction_shield", "templar_assassin_refraction_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_damage", "templar_assassin_refraction_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_visual", "templar_assassin_refraction_new", LUA_MODIFIER_MOTION_NONE)