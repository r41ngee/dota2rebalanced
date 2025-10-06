sniper_accurate_shooting = class({})

function sniper_accurate_shooting:GetIntrinsicModifierName()
    return "modifier_sniper_accurate_shooting"
end

modifier_sniper_accurate_shooting = class({})
function modifier_sniper_accurate_shooting:IsHidden() return false end
function modifier_sniper_accurate_shooting:IsPurgable() return false end

function modifier_sniper_accurate_shooting:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("stack_regen_time"))
end

function modifier_sniper_accurate_shooting:OnIntervalThink()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    if self:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
        self:IncrementStackCount()
    end
end

function modifier_sniper_accurate_shooting:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
    }
end

function modifier_sniper_accurate_shooting:GetModifierAttackRangeBonus()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if parent:HasModifier("modifier_sniper_accurate_shooting_cd") or self:GetStackCount() <= 0 then
        return 0
    else
        local per_stack = ability:GetSpecialValueFor("range_per_stack")
        local stacks = self:GetStackCount()

        return per_stack * stacks
    end
end

function modifier_sniper_accurate_shooting:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    if parent ~= event.unit then return end

    local ability = self:GetAbility()
    local cooldown = ability:GetSpecialValueFor("AbilityCooldown")
    ability:StartCooldown(cooldown)

   
    parent:AddNewModifier(
        parent,
        ability,
        "modifier_sniper_accurate_shooting_cd",
        {
            duration = cooldown
        }
    )
end

modifier_sniper_accurate_shooting_cd = class({})
function modifier_sniper_accurate_shooting_cd:IsHidden() return true end
function modifier_sniper_accurate_shooting_cd:IsPurgable() return false end
function modifier_sniper_accurate_shooting_cd:IsDebuff() return true end

function modifier_sniper_accurate_shooting_cd:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    print(parent)
    local buff_mod = parent:FindModifierByName("modifier_sniper_accurate_shooting")

    buff_mod:SetStackCount(0)
    buff_mod:StartIntervalThink(-1)
end

function modifier_sniper_accurate_shooting_cd:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    print(parent)
    local buff_mod = parent:FindModifierByName("modifier_sniper_accurate_shooting")

    buff_mod:StartIntervalThink(buff_mod:GetAbility():GetSpecialValueFor("stack_regen_time"))
end

LinkLuaModifier("modifier_sniper_accurate_shooting", "ability/sniper_accurate_shooting.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_accurate_shooting_cd", "ability/sniper_accurate_shooting.lua", LUA_MODIFIER_MOTION_NONE)