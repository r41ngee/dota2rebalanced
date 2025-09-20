phantom_assassin_crit_new = phantom_assassin_crit_new or class({})

modifier_phantom_crit_new = class({})
function modifier_phantom_crit_new:IsHidden() return true end
function modifier_phantom_crit_new:IsPurgable() return false end
function modifier_phantom_crit_new:IsBreakable() return true end
function modifier_phantom_crit_new:IsDebuff() return false end

modifier_phantom_crit_new_focus = class({})
function modifier_phantom_crit_new_focus:IsHidden() return false end
function modifier_phantom_crit_new_focus:IsPurgable() return false end
function modifier_phantom_crit_new_focus:IsDebuff() return false end

modifier_phantom_crit_new_active = class({})
function modifier_phantom_crit_new_active:IsHidden() return false end  -- Теперь видимый в статус баре
function modifier_phantom_crit_new_active:IsPurgable() return false end
function modifier_phantom_crit_new_active:IsDebuff() return false end
function modifier_phantom_crit_new_active:GetTexture() return "phantom_assassin_coup_de_grace" end

-- Функции способности
function phantom_assassin_crit_new:OnSpellStart()
    local parent = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    
    -- Добавляем модификатор активного крита
    parent:AddNewModifier(parent, self, "modifier_phantom_crit_new_active", {duration = duration})
    
    -- Звуковой эффект активации
    parent:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
    
    -- Визуальный эффект на герое
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_shard_fan_of_knives.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:ReleaseParticleIndex(particle)
end

function phantom_assassin_crit_new:GetIntrinsicModifierName()
    return "modifier_phantom_crit_new"
end

-- Функции модификаторов
function modifier_phantom_crit_new:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_phantom_crit_new_focus:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_phantom_crit_new_focus:OnCreated()
    if not IsServer() then return end
    
    -- Создаем эффект над головой
    local parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_mark_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
    self:AddParticle(self.particle, false, false, -1, false, false)
end

function modifier_phantom_crit_new:OnCreated()
    if not IsServer() then return end
    self:UpdateValues()
end

function modifier_phantom_crit_new:OnRefresh()
    if not IsServer() then return end
    self:UpdateValues()
end

function modifier_phantom_crit_new:UpdateValues()
    if not IsServer() then return end

    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        -- Сохраняем значения из способности
        self.passive_crit = ability:GetSpecialValueFor("passive_crit_damage")
        self.active_crit = ability:GetSpecialValueFor("active_crit_damage")
        self.crit_chance = ability:GetSpecialValueFor("crit_chance")
        self.focus_duration = ability:GetSpecialValueFor("focus_duration")
    end
end

function modifier_phantom_crit_new:OnAttackLanded(event)
    if not IsServer() then return end
    
    local parent = self:GetParent()
    if parent ~= event.attacker then return end
    
    local target = event.target
    if target:GetTeamNumber() == parent:GetTeamNumber() then return end
    if target:IsBuilding() then return end

    -- Проверяем, нет ли уже модификатора фокуса
    if not parent:FindModifierByNameAndCaster("modifier_phantom_crit_new_focus", parent) then
        -- Шанс активации крита
        if RandomFloat(0, 1) < self.crit_chance / 100 then
            parent:AddNewModifier(parent, self:GetAbility(), "modifier_phantom_crit_new_focus", {duration = self.focus_duration})
        end
    end
end

function modifier_phantom_crit_new_focus:OnAttackLanded(event)
    if not IsServer() then return end
    
    local parent = self:GetParent()
    if parent ~= event.attacker then return end
    
    local target = event.target
    if target:IsBuilding() then return end
    local ability = self:GetAbility()
    
    local crit_multiplier
    -- Проверяем, активен ли бафф ульты
    if parent:FindModifierByNameAndCaster("modifier_phantom_crit_new_active", parent) then
        crit_multiplier = ability:GetSpecialValueFor("active_crit_damage") / 100
    else
        crit_multiplier = ability:GetSpecialValueFor("passive_crit_damage") / 100
    end
    
    -- Вычисляем дополнительный урон крита
    local base_damage = event.damage
    local bonus_damage = base_damage * crit_multiplier
    local total_damage = base_damage + bonus_damage

    -- Применяем полный урон (базовый + крит)
    ApplyDamage({
        victim = target,
        attacker = parent,
        damage = bonus_damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = ability,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
    })

    -- Показываем общий урон крита
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_CRITICAL,
        target,
        total_damage,
        parent
    )

    -- Звуковой эффект крита
    parent:EmitSound("Hero_PhantomAssassin.CoupDeGrace.Impact")
    
    -- Эффект крови
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    -- Убираем модификатор фокуса после крита
    self:Destroy()
end

-- Регистрируем модификаторы
LinkLuaModifier("modifier_phantom_crit_new", "ability/phantom_crit_new.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phantom_crit_new_focus", "ability/phantom_crit_new.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phantom_crit_new_active", "ability/phantom_crit_new.lua", LUA_MODIFIER_MOTION_NONE)