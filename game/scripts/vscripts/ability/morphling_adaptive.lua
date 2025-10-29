-- Привязка модификаторов
LinkLuaModifier("modifier_morphling_adaptive_knockback", "ability/morphling_adaptive.lua", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_morphling_adaptive_stun", "ability/morphling_adaptive.lua", LUA_MODIFIER_MOTION_NONE)

morphling_adaptive_strike_agi = class({})

function morphling_adaptive_strike_agi:CastFilterResultTarget(target)
    
    local caster = self:GetCaster()

    if caster == target then return UF_FAIL_CUSTOM end
    if target:IsBuilding() then return UF_FAIL_BUILDING end

    if self:GetSpecialValueFor("ally_cast") > 0 then
        return 0
    else

        local caster_team = caster:GetTeamNumber()
        local target_team = target:GetTeamNumber()

        if caster_team ==
        target_team then
            return UF_FAIL_FRIENDLY
        else
            return 0
        end
    end
end


function morphling_adaptive_strike_agi:GetCustomCastErrorTarget(target)
    if target == self:GetCaster() then
        return "#dota_hud_error_cant_cast_on_self" -- стандартная ошибка
    end
    return ""
end

--------------------------------------------------------------------------------
-- Основная логика способности
--------------------------------------------------------------------------------

function morphling_adaptive_strike_agi:OnAbilityPhaseStart()
    self:GetHealthCost()
end

function morphling_adaptive_strike_agi:OnSpellStart()
	if not IsServer() then return end
    self.effect_impact = false

	self.caster = self:GetCaster()
	self.target = self:GetCursorTarget()

	-- Параметры из AbilityValues
	local projectile_speed  = self:GetSpecialValueFor("projectile_speed")

    
    if self.target:TriggerSpellAbsorb(self) or self.target:TriggerSpellReflect(self) then return end

    -- Атрибуты
    self.agi = self.caster:GetAgility()
    self.str = self.caster:GetStrength()

	-- выбираем тип снаряда и поведение
    local isAlly = self.caster:GetTeamNumber() == self.target:GetTeamNumber()

	local projectile_name
	if self.agi >= self.str or isAlly then
		projectile_name = "particles/units/heroes/hero_morphling/morphling_adaptive_strike_agi_proj.vpcf"
		self.effect_impact = true -- только AGI версия создаёт эффект импакта при попадании
	else
		projectile_name = "particles/units/heroes/hero_morphling/morphling_adaptive_strike_str_proj.vpcf"
		self.effect_impact = false -- STR версия имеет встроенный эффект
	end

    if not isAlly then
        self:RefundHealthCost()
	end

    ProjectileManager:CreateTrackingProjectile({
        EffectName = projectile_name,
        Ability = self,
        Source = self.caster,
        Target = self.target,
        iMoveSpeed = projectile_speed,
        bDodgeable = not self.target:GetTeamNumber() == self.caster:GetTeamNumber(),
    })
end

function morphling_adaptive_strike_agi:GetHealthCost()
    self.caster = self:GetCaster()
    if self.caster:HasModifier("modifier_morphling_bubble") then
        self.heal = self.caster:GetMaxHealth() * self:GetSpecialValueFor("heal_pct") / 100
        return self.heal * self:GetSpecialValueFor("health_cost_multiplier")
    end
    return 0
end

function morphling_adaptive_strike_agi:OnProjectileHit()
    
    if self.target:GetTeamNumber() ~= self.caster:GetTeamNumber() then

        -- Рассчитываем соотношение
        local agi_to_str_ratio = self.agi / math.max(self.str, 1)

        -- При AGI на 50% выше STR — максимум урона
        -- При STR на 50% выше AGI — максимум контроля
        local agi_threshold = 1.5
        local str_threshold = 1 / agi_threshold

        local agi_factor = 0
        if agi_to_str_ratio >= agi_threshold then
            agi_factor = 1
        elseif agi_to_str_ratio <= str_threshold then
            agi_factor = 0
        else
            agi_factor = (agi_to_str_ratio - str_threshold) / (agi_threshold - str_threshold)
        end

        local str_factor = 1 - agi_factor

        -- Интерполяция параметров
        local damage_mult = self.agi * self:GetSpecialValueFor("damage_agi")
        local stun_duration = self:GetSpecialValueFor("stun_min") + (self:GetSpecialValueFor("stun_max") - self:GetSpecialValueFor("stun_min")) * (1 / agi_to_str_ratio)
        local knockback_distance = self:GetSpecialValueFor("knockback_min") + (self:GetSpecialValueFor("knockback_max") - self:GetSpecialValueFor("knockback_min")) * str_factor

        -- Наносим урон
        print("mult="..damage_mult)
        
        local damage = self:GetSpecialValueFor("damage_base") + damage_mult
        print("damage="..damage)
        ApplyDamage({
            victim = self.target,
            attacker = self.caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self,
        })

        -- Отбрасывание
        self.target:RemoveModifierByName("modifier_morphling_adaptive_knockback")
        self.target:AddNewModifier(self.caster, self, "modifier_morphling_adaptive_knockback", {
            duration = self:GetSpecialValueFor("knockback_duration"),
            distance = knockback_distance,
            stun = stun_duration > 0 and 1 or 0,
            stun_duration = stun_duration,
        })
    else
        self.effect_impact = true

        self.target:Heal(self.heal, self)
        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_HEAL,
            self.target,
            self.heal,
            nil
        )
    end

	-- Эффекты
    if self.effect_impact then
        local particle_name = "particles/units/heroes/hero_morphling/morphling_adaptive_strike.vpcf"
        
        -- берём позицию цели и проецируем на землю
        local origin = self.target:GetAbsOrigin()
        origin.z = GetGroundHeight(origin, self.target)
    
        local impact_fx = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(impact_fx, 1, origin)
        ParticleManager:SetParticleControl(impact_fx, 0, self.caster:GetAbsOrigin()) -- направление
        ParticleManager:ReleaseParticleIndex(impact_fx)
    end

	self.target:EmitSound("Hero_Morphling.AdaptiveStrike")
end

--------------------------------------------------------------------------------
-- Модификатор отбрасывания
--------------------------------------------------------------------------------
modifier_morphling_adaptive_knockback = class({})

function modifier_morphling_adaptive_knockback:IsHidden() return true end
function modifier_morphling_adaptive_knockback:IsDebuff() return true end
function modifier_morphling_adaptive_knockback:IsPurgable() return false end
function modifier_morphling_adaptive_knockback:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_morphling_adaptive_knockback:OnCreated(kv)
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.distance = kv.distance or 0
	self.duration = kv.duration or 0.5
	self.stun = kv.stun == 1
	self.stun_duration = kv.stun_duration or 0

	-- направление от кастера к цели
	self.direction = (self.parent:GetAbsOrigin() - self.caster:GetAbsOrigin()):Normalized()
	self.speed = self.distance / self.duration
	self.traveled = 0

	if self.stun then
		self.parent:AddNewModifier(self.caster, self.ability, "modifier_morphling_adaptive_stun", { duration = self.stun_duration })
	end

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
	end
end

function modifier_morphling_adaptive_knockback:UpdateHorizontalMotion(me, dt)
	if not IsServer() then return end

	local move = self.direction * self.speed * dt
	self.traveled = self.traveled + self.speed * dt

	if self.traveled >= self.distance then
		self:Destroy()
		return
	end

	local new_pos = me:GetAbsOrigin() + move
	me:SetAbsOrigin(new_pos)
end

function modifier_morphling_adaptive_knockback:OnHorizontalMotionInterrupted()
	if not IsServer() then return end
	self:Destroy()
end

function modifier_morphling_adaptive_knockback:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	parent:RemoveHorizontalMotionController(self)
	FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
end

--------------------------------------------------------------------------------
-- Модификатор оглушения
--------------------------------------------------------------------------------
modifier_morphling_adaptive_stun = class({})

function modifier_morphling_adaptive_stun:IsHidden() return false end
function modifier_morphling_adaptive_stun:IsDebuff() return true end
function modifier_morphling_adaptive_stun:IsStunDebuff() return true end
function modifier_morphling_adaptive_stun:IsPurgable() return true end

function modifier_morphling_adaptive_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_morphling_adaptive_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_morphling_adaptive_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
