--[[
-- Kui_Nameplates_Absorbs
-- By Kesava at curse.com
-- All rights reserved
-- Absorb watcher module for Kui_Nameplates.
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local kui = LibStub('Kui-1.0')
local mod = addon:NewModule('Absorbs', 'AceEvent-3.0')

-- combat log events to listen to for damage
local damageEvents = {
    ['SPELL_PERIODIC_DAMAGE'] = true,
    ['SPELL_DAMAGE'] = true,
    ['SWING_DAMAGE'] = true,
    ['RANGE_DAMAGE'] = true,
}
-- and misses (which includes absorbs)
local missEvents = {
    ['SPELL_PERIODIC_MISSED'] = true,
    ['SPELL_MISSED'] = true,
    ['SWING_MISSED'] = true,
    ['RANGE_MISSED'] = true,
}

function mod:UpdateAbsorbAmount(frame, amount)
    if amount > 0 then
        frame.absorb:SetMinMaxValues(0,1)
        frame.absorb:SetValue(amount / frame.health.max)
        frame.absorb:Show()
    else
        frame.absorb:Hide()
    end
end

----------------------------------------------------------------------- Hooks --
function mod:Create(msg, frame)
    frame.absorb = CreateFrame('StatusBar', nil, frame.health)
    frame.absorb:SetAllPoints(frame.health)
    frame.absorb:Hide()

    frame.absorb:SetStatusBarTexture(addon.bartexture)
    frame.absorb:SetStatusBarColor(0, 0, 0)
    frame.absorb:SetAlpha(.7)

    frame.absorb.spark =frame.absorb:CreateTexture(nil, 'ARTWORK')
    frame.absorb.spark:SetDrawLayer('ARTWORK', 7)
    frame.absorb.spark:SetVertexColor(1,1,.8)
    frame.absorb.spark:SetTexture('Interface\\AddOns\\Kui_Media\\t\\spark')

    local bar = frame.absorb:GetRegions()
    frame.absorb.spark:SetPoint('CENTER', bar, 'RIGHT', 0, 0)
    frame.absorb.spark:SetSize(6,16)
end

function mod:Hide(msg, frame)
    frame.absorb:Hide()
end

-------------------------------------------------------------- event handlers --
function mod:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local _,event = ...
    local targetGUID = select(8, ...)
    if not targetGUID then return end
    if not damageEvents[event] and not missEvents[event] then return end
    if targetGUID == UnitGUID('player') then return end

    -- fetch the subject's nameplate
    local f = addon:GetNameplate(targetGUID, nil)
    if not f or not f.absorb or not f.absorb:IsShown() then return end

    if missEvents[event] then
        local missType,_,_,amount = select(15, ...)
        if missType ~= 'ABSORB' then return end

        -- subtract amount absorbed from absorb frame
        local absorb = f.absorb:GetValue() - amount
        self:UpdateAbsorbAmount(f, absorb)
    else
        -- received damage; hide the absorb frame
        self:UpdateAbsorbAmount(f, 0)
    end
end

function mod:PLAYER_TARGET_CHANGED()
    self:UNIT_ABSORB_AMOUNT_CHANGED(nil, 'target')
end
function mod:UPDATE_MOUSEOVER_UNIT()
    self:UNIT_ABSORB_AMOUNT_CHANGED(nil, 'mouseover')
end

function mod:UNIT_ABSORB_AMOUNT_CHANGED(event, unit, frame)
    frame = frame or addon:GetUnitPlate(unit)
    if not frame or not frame.absorb then return end

    local absorbs = UnitGetTotalAbsorbs(unit)

    self:UpdateAbsorbAmount(frame, absorbs)
end

function mod:GUIDStored(msg, f, unit)
    self:UNIT_ABSORB_AMOUNT_CHANGED(nil, unit, f)
end

---------------------------------------------------- Post db change functions --
mod.configChangedFuncs = { runOnce = {} }
mod.configChangedFuncs.runOnce.enabled = function(val)
    mod:SetEnabledState(val)
end

---------------------------------------------------- initialisation functions --
function mod:GetOptions()
    return {
        enabled = {
            name = 'Show total absorbs',
            desc = 'Display total absorbs over the target\'s health bar',
            type = 'toggle',
            width = 'full',
            order = 10,
            disabled = false
        },
    }
end

function mod:OnInitialize()
    self.db = addon.db:RegisterNamespace(self.moduleName, {
        profile = {
            enabled = true,
        }
    })

    addon:InitModuleOptions(self)
    mod:SetEnabledState(self.db.profile.enabled)
end

function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostCreate', 'Create')
    self:RegisterMessage('KuiNameplates_PostHide', 'Hide')

    self:RegisterMessage('KuiNameplates_GUIDStored', 'GUIDStored')

    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED')
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')

    local _, frame
    for _, frame in pairs(addon.frameList) do
        if not frame.absorb then
            self:Create(nil, frame.kui)
        end
    end
end

function mod:OnDisable()
    self:UnregisterMessage('KuiNameplates_GUIDStored', 'GUIDStored')

    self:UnregisterEvent('PLAYER_TARGET_CHANGED')
    self:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED')
    self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    self:UnregisterEvent('UPDATE_MOUSEOVER_UNIT')

    local _, frame
    for _, frame in pairs(addon.frameList) do
        self:Hide(nil, frame.kui)
    end
end
