lina_overheat_nw = class({})

modifier_lina_overheat_nw = class({})
function modifier_lina_overheat_nw:IsHidden() return false end
function modifier_lina_overheat_nw:IsPurgable() return false end
function modifier_lina_overheat_nw:IsDebuff() return false end

modifier_lina_overheat_nw_stack = class({})
function modifier_lina_overheat_nw_stack:IsHidden() return false end
function modifier_lina_overheat_nw_stack:IsPurgable() return true end
function modifier_lina_overheat_nw_stack:IsDebuff() return true end

function lina_overheat_nw:GetIntrinsicModifierName() return "modifier_lina_overheat_nw" end

function modifier_lina_overheat_nw:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_lina_overheat_nw:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    if parent:PassivesDisabled() then return end

    if parent ~= event.attacker then return end

    -- Add safety checks for nil values
    if not parent or not ability then return end

    local victim = event.target
    if not victim then return end

    if parent:GetTeamNumber() == victim:GetTeamNumber() then return end
    if parent:IsIllusion() then return end
    if victim:IsBuilding() then return end

    local mark_modifier = victim:FindModifierByName("modifier_lina_overheat_nw_stack")

    if mark_modifier then
        if mark_modifier:GetStackCount() >= ability:GetSpecialValueFor("required_stacks") then
            ApplyDamage({
                victim = victim,
                attacker = parent,
                damage = ability:GetSpecialValueFor("damage"),
                damage_type = ability:GetAbilityDamageType(),
                ability = ability
            })
            SendOverheadEventMessage(victim, 4, victim, ability:GetSpecialValueFor("damage"), nil)
            mark_modifier:Destroy()
        else
            mark_modifier:IncrementStackCount()
        end
    else
        local new_modifier = victim:AddNewModifier(parent, ability, "modifier_lina_overheat_nw_stack", {
            duration = ability:GetSpecialValueFor("duration")
        })
        if new_modifier then
            new_modifier:SetStackCount(1)
        end
    end
end

LinkLuaModifier("modifier_lina_overheat_nw", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_overheat_nw_stack", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)