LinkLuaModifier("modifier_pudge_consume_held", "ability/pudge_consume.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_pudge_consume_holder", "ability/pudge_consume.lua", LUA_MODIFIER_MOTION_NONE)

pudge_consume_lua = class({})
function pudge_consume_lua:CastFilterResultTarget(target)
    if self:GetCaster() == target then
        return UF_FAIL_CUSTOM
    end
end

function pudge_consume_lua:GetCustomCastErrorTarget(target)
    if self:GetCaster() == target then
        return "#dota_hud_error_cant_cast_on_self"
    end
end

function pudge_consume_lua:IsStealable()
    return false
end

function pudge_consume_lua:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    target:AddNewModifier(
        caster,
        self,
        "modifier_pudge_consume_held",
        { }
    )

    caster:AddNewModifier(
        caster,
        self,
        "modifier_pudge_consume_holder",
        { injected = target:GetEntityIndex() }
    )
end

modifier_pudge_consume_held = class({})
function modifier_pudge_consume_held:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_pudge_consume_held:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
    }
end

function modifier_pudge_consume_held:GetModifierConstantHealthRegen()
    return self:GetParent():GetMaxHealth() * self:GetAbility():GetSpecialValueFor("regen_pct") / 100
end

function modifier_pudge_consume_held:OnOrder(params)
    local type = params.order_type
    if type > 0 and (type <= 10 or type == 28 or type == 29) and self:GetParent() == params.unit then
        self:Destroy()
    end
end

function modifier_pudge_consume_held:GetMotionControllerPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_pudge_consume_held:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    parent:AddNoDraw()
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end
end

function modifier_pudge_consume_held:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
    parent:RemoveNoDraw()

    local caster = self:GetCaster()
    caster:RemoveModifierByName("modifier_pudge_consume_holder")

    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle(
        "particles/units/heroes/hero_pudge/pudge_swallow_release.vpcf",
        PATTACH_ABSORIGIN,
        caster
    ))
end

function modifier_pudge_consume_held:UpdateHorizontalMotion(me, dt)
    if not IsServer() then return end

    me:SetAbsOrigin(self:GetCaster():GetAbsOrigin())
end

modifier_pudge_consume_holder = class({})
function modifier_pudge_consume_holder:OnCreated(kv)
    if not IsServer() then return end

    self.injected = EntIndexToHScript(kv.injected)
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    caster:FindAbilityByName("pudge_eject_lua"):SetActivated(true)
    ability:SetFrozenCooldown(true)
    ability:SetActivated(false)
end

function modifier_pudge_consume_holder:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    caster:FindAbilityByName("pudge_eject_lua"):SetActivated(false)
    ability:SetActivated(true)
    ability:SetFrozenCooldown(false)
end

function modifier_pudge_consume_holder:GetInjected()
    return self.injected
end

function modifier_pudge_consume_holder:GetEffectName()
    return "particles/units/heroes/hero_pudge/pudge_swallow_overhead.vpcf"
end

function modifier_pudge_consume_holder:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end