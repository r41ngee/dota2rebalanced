pugna_life_drain_lua = class({})

function pugna_life_drain_lua:CastFilterResultTarget(target)
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

    self.isAlly = self.caster:GetTeamNumber() == self.target:GetTeamNumber()
end

function pugna_life_drain_lua:GetChannelTime()
    return self:GetSpecialValueFor("AbilityChannelTime")
end

function pugna_life_drain_lua:OnChannelThink(dt)
    if not self.isAlly then
        local heal = ApplyDamage({
            victim = self.target,
            attacker = self:GetCaster(),
            damage = self:GetSpecialValueFor("health_drain") * dt,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })

        self:GetCaster():Heal(heal, self)
    else
        local heal = self:GetSpecialValueFor("ally_healing") * dt
        self.target:Heal(heal, self)

        local self_resist = self.caster:Script_GetMagicalArmorValue(false, self)
        print(self_resist)
        ApplyDamage({
            victim = self.caster,
            attacker = self.caster,
            damage = heal * (1 - self_resist),
            damage_type = DAMAGE_TYPE_PURE,
            damage_flags = 0,
            ability = self
        })
    end
end