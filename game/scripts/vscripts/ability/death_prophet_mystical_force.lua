death_prophet_mystical_force = class({})

function death_prophet_mystical_force:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function death_prophet_mystical_force:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local projectile_name = "particles/units/heroes/hero_siren/siren_net_projectile.vpcf"
    local projectile_speed = 1500

    local secondary = FindUnitsInRadius(
        target:GetTeamNumber(),
        target:GetAbsOrigin(),
        nil,
        self:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        0,
        false
    )

    for _, i in ipairs(secondary) do
        ProjectileManager:CreateTrackingProjectile(
            {
                EffectName = projectile_name,
                Ability = self,
                Source = caster,
                bProvidesVision = true,
                iVisionRadius = 300,
                iVisionTeamNumber = caster:GetTeamNumber(),
                Target = i,
                iMoveSpeed = projectile_speed,
                bDodgeable = false
            }
        )
    end
end

function death_prophet_mystical_force:OnProjectileHit(i, location)
    if not IsServer() then return end
    
    local caster = self:GetCaster()

    if i:IsIllusion() then
        i:Kill(self, caster)
    end

    i:AddNewModifier(
        caster,
        self,
        "modifier_mystical_force_root",
        {
            duration = self:GetSpecialValueFor("duration")
        }
    )

    ApplyDamage({
        victim = i,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = self:GetAbilityDamageType(),
        ability = self
    })
end

modifier_mystical_force_root = class({})
function modifier_mystical_force_root:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    parent:MakeVisibleToTeam(self:GetCaster():GetTeamNumber(), 0.12)
    self:StartIntervalThink(0.1)
end
function modifier_mystical_force_root:OnIntervalThink()
    if not IsServer() then return end
    
    local parent = self:GetParent()
    parent:MakeVisibleToTeam(self:GetCaster():GetTeamNumber(), 0.12)
end

function modifier_mystical_force_root:IsHidden()
    return false
end
function modifier_mystical_force_root:IsDebuff() return true end

function modifier_mystical_force_root:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
        -- [MODIFIER_STATE_PROVIDES_VISION] = true
    }
end

function modifier_mystical_force_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mystical_force_root:GetEffectName()
    return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_mystical_force_root:GetPriority() return 3 end

LinkLuaModifier("modifier_mystical_force_root", "Ability/death_prophet_mystical_force.lua", LUA_MODIFIER_MOTION_NONE)