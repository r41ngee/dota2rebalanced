pudge_eject_lua = class({})
function pudge_eject_lua:Spawn()
    if not IsServer() then return end

    self:SetActivated(false)
end

function pudge_eject_lua:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local caster_mod = caster:FindModifierByName("modifier_pudge_consume_holder")
    local target = caster_mod:GetInjected()
    local target_mod = target:FindModifierByName("modifier_pudge_consume_held")

    if target_mod and caster_mod then
        target_mod:Destroy()
        caster_mod:Destroy()
    end
end