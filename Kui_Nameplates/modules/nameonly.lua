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
        reset = true, size = f.trivial and 'small' or 'name', shadow = true
    })
    f.name:SetParent(f)
    f.name:ClearAllPoints()
    f.name:SetPoint('CENTER')

    if f.friend and not f.player then
        f.name:SetTextColor(.6,1,.6)
    end

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

    if f.friend and not f.player then
        f.name:SetTextColor(1,1,1)
    end

    f.health:Show()
    f.overlay:Show()
    f.bg:Show()

    -- reposition name
    addon:UpdateName(f,f.trivial)
end

local function OnHealthValueChanged(oldHealth)
    local f = oldHealth.kuiParent.kui

    if not f.friend then
        if f.nameonly then
            SwitchOff(f)
        end
        return
    end

    local _,max = oldHealth:GetMinMaxValues()
    local cur = oldHealth:GetValue()

    if cur == max then
        SwitchOn(f)
    else
        SwitchOff(f)
    end
end

function mod:PostShow(msg,f)
    OnHealthValueChanged(f.oldHealth)
end
function mod:PostHide(msg,f)
    SwitchOff(f)
end
function mod:PostCreate(msg,f)
    f.oldHealth:HookScript('OnValueChanged',OnHealthValueChanged)
end
function mod:PostTarget(msg,f,is_target)
    if is_target then
        -- never nameonly the target
        SwitchOff(f)
    else
        OnHealthValueChanged(f.oldHealth)
    end
end

function mod:OnInitialize()
    self:SetEnabledState(true)
end
function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostHide','PostHide')
    self:RegisterMessage('KuiNameplates_PostShow','PostShow')
    self:RegisterMessage('KuiNameplates_PostCreate','PostCreate')
    self:RegisterMessage('KuiNameplates_PostTarget','PostTarget')
end
