pugna_life_drain_lua = class({})

function pugna_life_drain_lua:CastFilterResultTarget(target)
    self.totemTarget = false
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") and target:GetUnitName() == "npc_dota_pugna_nether_ward" then
        self.totemTarget = true
        return UF_SUCCESS
    end
    if self:GetCaster() == target then
        return UF_FAIL_CUSTOM
    end
end

function pugna_life_drain_lua:GetCustomCastErrorTarget(target)
    if target == self:GetCaster() then
        return "#dota_hud_error_cant_cast_on_self" -- стандартная ошибка
    end
    return ""
end


function pugna_life_drain_lua:OnSpellStart()
    self.target = self:GetCursorTarget()
    self.caster = self:GetCaster()

    if self.target:TriggerSpellAbsorb(self) then
        self.caster:Interrupt()
        return
    end

    self.isAlly = self.caster:GetTeamNumber() == self.target:GetTeamNumber()

    if self.isAlly then
        self.target:AddNewModifier(
            self.caster,
            self,
            "modifier_pugna_life_drain_ally",
            {
            }
        )
    else
        self.target:AddNewModifier(
            self.caster,
            self,
            "modifier_pugna_life_drain_enemy",
            {
            }
        )
    end
end

function pugna_life_drain_lua:GetChannelTime()
    return self:GetSpecialValueFor("AbilityChannelTime")
end

function pugna_life_drain_lua:OnChannelFinish()
    if self.isAlly then
        self.target:RemoveModifierByName("modifier_pugna_life_drain_ally")
    else
        self.target:RemoveModifierByName("modifier_pugna_life_drain_enemy")
    end
end

modifier_pugna_life_drain_enemy = class({})

function modifier_pugna_life_drain_enemy:OnCreated(kv)
    self.tickrate = self:GetAbility():GetSpecialValueFor("tick_rate")
    self:StartIntervalThink(self.tickrate)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(self.particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_head", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end

function modifier_pugna_life_drain_enemy:OnIntervalThink()
    if not IsServer() then return end
    local ability = self:GetAbility()
    local caster = ability:GetCaster()
    local target = self:GetParent()

    if (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() >= ability:GetSpecialValueFor("AbilityCastRange") + ability:GetSpecialValueFor("drain_buffer") then
        caster:Interrupt()
    end

    local heal = ApplyDamage({
        victim = target,
        attacker = caster,
        damage = ability:GetSpecialValueFor("health_drain") * self.tickrate,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    })

    caster:Heal(heal, ability)
end

function modifier_pugna_life_drain_enemy:OnDestroy()
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
end

modifier_pugna_life_drain_ally = class({})
function modifier_pugna_life_drain_ally:OnCreated(kv)
    self.tickrate = self:GetAbility():GetSpecialValueFor("tick_rate")
    self:StartIntervalThink(self.tickrate)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_life_give.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(self.particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_head", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end

function modifier_pugna_life_drain_ally:OnIntervalThink()
    if not IsServer() then return end
    local ability = self:GetAbility()
    local caster = ability:GetCaster()
    local target = self:GetParent()

    local heal = ability:GetSpecialValueFor("ally_healing") * self.tickrate

    target:Heal(heal, ability)
    local current_health = caster:GetHealth()
    if heal >= current_health then
        caster:Kill(ability, caster)
    end
    caster:ModifyHealth(current_health - heal, ability, true, 0)
end

function modifier_pugna_life_drain_ally:OnDestroy()
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
end

function modifier_pugna_life_drain_ally:IsPurgable() return false end
function modifier_pugna_life_drain_enemy:IsPurgable() return false end

LinkLuaModifier("modifier_pugna_life_drain_enemy", "ability/pugna_life_drain.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pugna_life_drain_ally", "ability/pugna_life_drain.lua", LUA_MODIFIER_MOTION_NONE)