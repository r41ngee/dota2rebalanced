lina_overheat_nw = lina_overheat_nw or class({})
print("lina_overheat script loaded")

-- Сначала объявляем ВСЕ классы модификаторов
modifier_lina_overheat_mark_nw = class({})
function modifier_lina_overheat_mark_nw:IsHidden() return false end
function modifier_lina_overheat_mark_nw:IsPurgable() return true end
function modifier_lina_overheat_mark_nw:IsDebuff() return true end

function modifier_lina_overheat_mark_nw:OnCreated()
    if not IsServer() then return end
    self:SetStackCount(1)
    print("Mark created with 1 stack")
end

function modifier_lina_overheat_mark_nw:OnDestroy()
    if not IsServer() then return end
    print("Overheat mark destroyed with", self:GetStackCount(), "stacks")
end

-- Модификатор true strike
modifier_lina_overheat_true_strike_nw = class({})
function modifier_lina_overheat_true_strike_nw:IsHidden() return true end
function modifier_lina_overheat_true_strike_nw:IsPurgable() return false end
function modifier_lina_overheat_true_strike_nw:IsDebuff() return false end

function modifier_lina_overheat_true_strike_nw:DeclareFunctions()
    return { MODIFIER_PROPERTY_CANNOT_MISS }
end

function modifier_lina_overheat_true_strike_nw:GetModifierCannotMiss()
    return 1
end

-- Основной модификатор способности
modifier_lina_overheat_nw = class({})

function modifier_lina_overheat_nw:IsHidden() return true end
function modifier_lina_overheat_nw:IsPurgable() return false end
function modifier_lina_overheat_nw:IsDebuff() return false end

function modifier_lina_overheat_nw:OnCreated()
    if not IsServer() then return end
    self.attackRecords = {}
    self.processedCrits = {}  -- Для отслеживания уже обработанных критов
    self:UpdateValues()
end

function modifier_lina_overheat_nw:OnRefresh()
    print("modifier_lina_overheat:OnRefresh() called - ability leveled up!")
    if not IsServer() then return end
    self:UpdateValues()
end

function modifier_lina_overheat_nw:UpdateValues()
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        local level = ability:GetLevel() - 1
        if level < 0 then level = 0 end
        
        self.required_stacks = ability:GetLevelSpecialValueFor("required_stacks", level)
        self.bonus_damage = ability:GetLevelSpecialValueFor("damage", level)
        self.stack_duration = ability:GetLevelSpecialValueFor("duration", level)
        self.building_damage_pct = ability:GetLevelSpecialValueFor("building_damage", level)
        
        print("Overheat values - stacks:", self.required_stacks, "damage:", self.bonus_damage, "duration:", self.stack_duration, "building pct:", self.building_damage_pct)
    else
        self.required_stacks = 5
        self.bonus_damage = 50
        self.stack_duration = 6
        self.building_damage_pct = 20
    end
end

function modifier_lina_overheat_nw:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_RECORD,
        MODIFIER_EVENT_ON_ATTACK_FAIL
    }
end

function modifier_lina_overheat_nw:OnAttackLanded(event)
    if not IsServer() then return end
    local parent = self:GetParent()
    
    if parent:IsIllusion() then return end
    if event.attacker ~= parent then return end
    
    local target = event.target
    if not target or target:IsNull() or not target:IsAlive() then return end
    if target:GetTeamNumber() == parent:GetTeamNumber() then return end

    if not self.stack_duration then self:UpdateValues() end

    -- ВАЖНО: Проверяем, есть ли запись об этой атаке как о крите
    if self.attackRecords[event.record] then
        print("Overheat proc detected for record:", event.record)
        
        local actual_damage = self.bonus_damage
        if target:IsBuilding() then
            actual_damage = actual_damage * (self.building_damage_pct / 100)
        end
        
        ApplyDamage({
            victim = target,
            attacker = parent,
            damage = actual_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
        
        self:CreateJavelinStyleDamageNumber(target, actual_damage)

        -- СБРАСЫВАЕМ СТАКИ И ОЧИЩАЕМ ЗАПИСЬ
        local debuff = target:FindModifierByNameAndCaster("modifier_lina_overheat_mark_nw", parent)
        if debuff then
            debuff:Destroy()
        end

        parent:RemoveModifierByName("modifier_lina_overheat_true_strike_nw")
        self.attackRecords[event.record] = nil  -- ОЧИЩАЕМ ЗАПИСЬ СРАЗУ!
        
    else
        -- ОБЫЧНАЯ АТАКА - проверяем, не была ли эта атака уже обработана как крит
        if self.processedCrits[event.record] then
            print("Skipping stack - this attack was already a crit:", event.record)
            return
        end
        
        -- Добавляем стак
        local debuff = target:FindModifierByNameAndCaster("modifier_lina_overheat_mark_nw", parent)
        if not debuff then
            debuff = target:AddNewModifier(parent, self:GetAbility(), "modifier_lina_overheat_mark_nw", {duration = self.stack_duration})
            debuff:SetStackCount(1)
        else
            if debuff:GetStackCount() < self.required_stacks then
                debuff:SetStackCount(debuff:GetStackCount() + 1)
                debuff:SetDuration(self.stack_duration, true)
            end
        end
    end
end

function modifier_lina_overheat_nw:CreateJavelinStyleDamageNumber(target, damage)
    -- Просто используем встроенную систему сообщений
    SendOverheadEventMessage(
        nil, 
        OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, -- Для магического урона
        target, 
        damage, 
        nil
    )
    
    -- -- Или для критического стиля:
    -- SendOverheadEventMessage(
    --     nil, 
    --     OVERHEAD_ALERT_CRITICAL, -- Для критического урона  
    --     target,
    --     damage,
    --     nil
    -- )
    
    EmitSoundOn("DOTA_Item.MKB.Hit", target)
end

function modifier_lina_overheat_nw:OnAttackRecord(event)
    if not IsServer() then return end
    local parent = self:GetParent()
    
    if parent:IsIllusion() then return end
    if event.attacker ~= parent then return end
    
    local target = event.target
    if not target or target:IsNull() or target:GetTeamNumber() == parent:GetTeamNumber() then return end

    if not self.required_stacks then self:UpdateValues() end

    local debuff = target:FindModifierByNameAndCaster("modifier_lina_overheat_mark_nw", parent)
    if debuff and debuff:GetStackCount() >= self.required_stacks then
        self.attackRecords[event.record] = true
        self.processedCrits[event.record] = true  -- Помечаем как крит
        parent:AddNewModifier(parent, self:GetAbility(), "modifier_lina_overheat_true_strike_nw", {duration = 1.0})
    end
end

function modifier_lina_overheat_nw:OnDestroy()
    if not IsServer() then return end
    self.attackRecords = {}
    print("Modifier destroyed, attack records cleared")
end

function modifier_lina_overheat_nw:OnAttackFail(event)
    if not IsServer() then return end
    if event.attacker == self:GetParent() then
        self.attackRecords[event.record] = nil
        self:GetParent():RemoveModifierByName("modifier_lina_overheat_true_strike_nw")
        print("Attack failed, cleaning up")
    end
end

-- Линкуем все модификаторы (ПОСЛЕ объявления всех классов)
LinkLuaModifier("modifier_lina_overheat_nw", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_overheat_mark_nw", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_overheat_true_strike_nw", "ability/lina_overheat.lua", LUA_MODIFIER_MOTION_NONE)

function lina_overheat_nw:GetIntrinsicModifierName()
    print("lina_overheat:GetIntrinsicModifierName() called")
    return "modifier_lina_overheat_nw"
end

function lina_overheat_nw:GetAbilityDamageType()
    return DAMAGE_TYPE_MAGICAL
end

print("lina_overheat script fully loaded")