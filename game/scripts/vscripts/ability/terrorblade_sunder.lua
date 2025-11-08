terrorblade_sunder = class({})

-- function terrorblade_sunder:CastFilterResultTarget(target)
--     if target:IsRealHero() then
--         return UF_SUCCESS
--     end
-- end

SUNDER_EFFECT_NAME = "particles/units/heroes/hero_terrorblade/terrorblade_sunder.vpcf"

function terrorblade_sunder:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local caster_pct = caster:GetHealth() / caster:GetMaxHealth()
    local target_pct = math.max(target:GetHealth() / target:GetMaxHealth(), self:GetSpecialValueFor("hit_point_minimum_pct") / 100)

    local isAlly = caster:GetTeamNumber() == target:GetTeamNumber()
    local no_limit = self:GetSpecialValueFor("ignore_minimum_pct_for_enemies") > 0

    if not (no_limit and not isAlly) then
        caster_pct = math.max(caster_pct, self:GetSpecialValueFor("hit_point_minimum_pct") / 100)
    end

    caster:ModifyHealth(target_pct * caster:GetMaxHealth(), self, false, DOTA_DAMAGE_FLAG_HPLOSS)
    if not (target:IsDebuffImmune() and isAlly) then
        target:ModifyHealth(caster_pct * target:GetMaxHealth(), self, false, DOTA_DAMAGE_FLAG_HPLOSS)
    end

    local effect = ParticleManager:CreateParticle(
        SUNDER_EFFECT_NAME,
        PATTACH_CENTER_FOLLOW,
        caster
    )
    ParticleManager:SetParticleControlEnt(
        effect,
        1,
        target,
        PATTACH_CENTER_FOLLOW,
        "attach_hitloc",
        Vector(0, 0, 0),
        false
    )
end