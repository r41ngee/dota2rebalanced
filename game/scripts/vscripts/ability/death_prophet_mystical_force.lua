death_prophet_mystical_force = class({})

function death_prophet_mystical_force:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function death_prophet_mystical_force:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    print(caster:GetAbsOrigin())
    print(target:GetAbsOrigin())

    local projectile_name = "particles/neutral_fx/dark_troll_ensnare_proj.vpcf"
    local projectile_speed = 1500

    ProjectileManager:CreateTrackingProjectile(
        {
            EffectName = projectile_name,
            Ability = self,
            Source = caster,
            bProvidesVision = false,
            Target = target,
            iMoveSpeed = projectile_speed,
            bDodgeable = false
        }
    )
end

function death_prophet_mystical_force:OnProjectileHit(target, location)
    if not IsServer() then return end

    local caster = self:GetCaster()
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

    for _,i in ipairs(secondary) do
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
end

modifier_mystical_force_root = class({})
function modifier_mystical_force_root:IsHidden()
    return false
end
function modifier_mystical_force_root:IsDebuff() return true end

function modifier_mystical_force_root:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true
    }
end

function modifier_mystical_force_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mystical_force_root:GetEffectName()
    return "particles/neutral_fx/dark_troll_ensnare.vpcf"
end

function modifier_mystical_force_root:GetPriority() return 3 end

LinkLuaModifier("modifier_mystical_force_root", "Ability/death_prophet_mystical_force.lua", LUA_MODIFIER_MOTION_NONE)