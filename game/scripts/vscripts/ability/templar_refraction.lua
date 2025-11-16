templar_assassin_refraction_lua = class({})
function templar_assassin_refraction_lua:GetBehavior()
    return self:GetSpecialValueFor("cast_while_disabled")
        and DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
        or  DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function templar_assassin_refraction_lua:OnSpellStart()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()

    caster:AddNewModifier(
        caster,
        self,
        "modifier_templar_refraction_lua",
        {
            duration = self:GetSpecialValueFor("duration")
        }
    )

    if self:GetSpecialValueFor("dispels") > 0 then
        caster:Purge(
            false,
            true,
            false,
            false,
            false
        )
    end
end

modifier_templar_refraction_lua = class({})
function modifier_templar_refraction_lua:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
    }
end

function modifier_templar_refraction_lua:OnCreated()
    if IsClient() then return end
    local ability = self:GetAbility()
    local parent = self:GetParent()
    parent:AddNewModifier(
        parent,
        ability,
        "modifier_templar_refraction_lua_damage",
        {
            duration = ability:GetSpecialValueFor("duration")
        }
    )

    self.barrier_max = ability:GetSpecialValueFor("stack_health")
    self.barrier_hp = self.barrier_max

    self:SetStackCount(ability:GetSpecialValueFor("stacks"))

    self:SetHasCustomTransmitterData(true)
end

function modifier_templar_refraction_lua:AddCustomTransmitterData()
    return {
        barrier_max = self.barrier_max,
        barrier_hp = self.barrier_hp
    }
end

function modifier_templar_refraction_lua:HandleCustomTransmitterData(data)
    self.barrier_max = data.barrier_max
    self.barrier_hp = data.barrier_hp
end

function modifier_templar_refraction_lua:GetModifierIncomingDamageConstant(event)
    if IsClient() then
        if event.report_max then
            return self.barrier_max
        else
            return self.barrier_hp
        end
    end

    local damage = event.damage
    if damage > self.barrier_hp then
        if self:GetStackCount() > 1 then
            self:DecrementStackCount()
            self.barrier_hp = self.barrier_max
        else
            self:Destroy()
        end

        local ability = self:GetAbility()
        if ability:GetSpecialValueFor("refresh_damage_on_break") then
            local parent = self:GetParent()
            if parent:HasModifier("modifier_templar_refraction_lua_damage") then
                parent:FindModifierByName("modifier_templar_refraction_lua_damage"):SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
            end
        end
    else
        self.barrier_hp = self.barrier_hp - damage
    end
    self:SendBuffRefreshToClients()
    return -damage
end

modifier_templar_refraction_lua_damage = class({})
function modifier_templar_refraction_lua_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_templar_refraction_lua_damage:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage")
end

function modifier_templar_refraction_lua_damage:GetTexture()
    return "templar_assassin_refraction_damage"
end

LinkLuaModifier("modifier_templar_refraction_lua", "ability/templar_refraction.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_refraction_lua_damage", "ability/templar_refraction.lua", LUA_MODIFIER_MOTION_NONE)
