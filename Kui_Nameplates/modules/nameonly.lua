--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved.
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('NameOnly', 'AceEvent-3.0')

-- toggle nameonly mode on
local function SwitchOn(f)
    if f.nameonly then return end
    f.nameonly = true

    f:CreateFontString(f.name, {
        reset = true, size = f.trivial and 'small' or 'large', shadow = true
    })
    f.name:SetParent(f)
    f.name:ClearAllPoints()
    f.name:SetPoint('CENTER')

    f.health:Hide()
    f.overlay:Hide()
    f.bg:Hide()
end
-- toggle nameonly mode off
local function SwitchOff(f)
    if not f.nameonly then return end
    f.nameonly = nil

    f:CreateFontString(f.name, {
        reset = true, size = 'name'
    })
    f.name:SetParent(f.overlay)
    f.name:ClearAllPoints()

    f.health:Show()
    f.overlay:Show()
    f.bg:Show()

    addon:UpdateName(f,f.trivial)
end

local function OnHealthValueChanged(oldHealth)
    local f = oldHealth.kuiParent.kui
    if f.nameonly_ignore then return end

    local _,max = oldHealth:GetMinMaxValues()
    local cur = oldHealth:GetValue()

    if cur == max then
        SwitchOn(f)
    else
        SwitchOff(f)
    end
end

function mod:PostShow(msg,f)
    if not f.friend then
        f.nameonly_ignore = true
    else
        f.nameonly_ignore = nil
        OnHealthValueChanged(f.oldHealth)
    end
end
function mod:PostHide(msg,f)
    SwitchOff(f)
end
function mod:PostCreate(msg,f)
    f.oldHealth:HookScript('OnValueChanged',OnHealthValueChanged)
end

function mod:OnInitialize()
    self:SetEnabledState(true)
end
function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostHide','PostHide')
    self:RegisterMessage('KuiNameplates_PostShow','PostShow')
    self:RegisterMessage('KuiNameplates_PostCreate','PostCreate')
end
