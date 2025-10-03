lion_mana_sacrifice = class({})
function lion_mana_sacrifice:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_necrolyte/necrolyte_pulse_friend.vpcf", context)
end


function lion_mana_sacrifice:OnSpellStart()
    local target = self:GetCursorTarget()

    local projectile_name = "particles/units/heroes/hero_necrolyte/necrolyte_pulse_friend.vpcf"
    local projectile_speed = self:GetSpecialValueFor("projectile_speed")
    local projectile_vision = 300

    local projectile_data = {
        Target = target,
        Source = self:GetCaster(),
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bProvidesVision = true,
        iVisionRadius = projectile_vision,
        bVisibleToEnemies = true,
        bDodgeable = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
        Ability = self
    }

    ProjectileManager:CreateTrackingProjectile(projectile_data)
end
function lion_mana_sacrifice:OnProjectileHit(target, location)
    target:AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_mana_sacrifice",
        {
            duration = self:GetSpecialValueFor("duration")
        }
    )
end

modifier_mana_sacrifice = class({})
function modifier_mana_sacrifice:IsPurgable() return true end

function modifier_mana_sacrifice:DeclareFunctions()
    return  {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_mana_sacrifice:OnCreated()
    self:StartIntervalThink(1 / self:GetAbility():GetSpecialValueFor("tick_rate"))
end

function modifier_mana_sacrifice:OnIntervalThink()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local tickrate = ability:GetSpecialValueFor("tick_rate")

    local mana_burn_pct = ability:GetSpecialValueFor("mana_burn_per_second_pct") / tickrate / 100
    local hp_regen_pct = ability:GetSpecialValueFor("hp_regen_per_second_pct") / tickrate / 100

    local current_heal = parent:GetMaxHealth() * hp_regen_pct
    local current_manab = parent:GetMaxMana() * mana_burn_pct


    if parent:GetHealth() == parent:GetMaxHealth() or parent:GetMana() < current_manab then
        self:Destroy()
        return
    end

    local parent = self:GetParent()

    parent:Heal(current_heal, ability)
    parent:SpendMana(current_manab, ability)
end

function modifier_mana_sacrifice:OnTakeDamage(event)
    if event.unit == self:GetParent() and event.attacker and event.attacker:IsHero() and event.attacker:GetTeamNumber() == event.unit:GetTeamNumber() then
        self:Destroy()
    end
end

LinkLuaModifier("modifier_mana_sacrifice", "ability/lion_mana_sacrifice.lua", LUA_MODIFIER_MOTION_NONE)