lina_overheat_nw = class({})
function lina_overheat_nw:GetBehavior()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function lina_overheat_nw:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(
        caster,
        self,
        "modifier_lina_overheat_nw_building",
        {
            duration = self:GetSpecialValueFor("building_damage_duration")
        }
    )
end

modifier_lina_overheat_nw = class({})
function modifier_lina_overheat_nw:IsHidden() return true end
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

    local damage_multiplier = 1
    if victim:IsBuilding() then
        if parent:HasModifier("modifier_lina_overheat_nw_building") then
            damage_multiplier = ability:GetSpecialValueFor("building_damage") / 100
        else
            return
        end
    end

    local mark_modifier = victim:FindModifierByName("modifier_lina_overheat_nw_stack")

    if mark_modifier then
        if mark_modifier:GetStackCount() >= ability:GetSpecialValueFor("required_stacks") then
            local final_damage = ability:GetSpecialValueFor("damage") * damage_multiplier
            ApplyDamage({
                victim = victim,
                attacker = parent,
                damage = final_damage,
                damage_type = ability:GetAbilityDamageType(),
                ability = ability
            })
            SendOverheadEventMessage(victim, 4, victim, final_damage, nil)
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

modifier_lina_overheat_nw_building = class({})
function modifier_lina_overheat_nw_building:IsHidden() return false end
function modifier_lina_overheat_nw_building:IsPurgable() return false end
function modifier_lina_overheat_nw_building:IsDebuff() return false end

LinkLuaModifier("modifier_lina_overheat_nw", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_overheat_nw_stack", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_overheat_nw_building", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)