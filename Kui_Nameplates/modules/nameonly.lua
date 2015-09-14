--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved.
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('NameOnly', 'AceEvent-3.0')

local len = string.len
local utf8sub = LibStub('Kui-1.0').utf8sub
local orig_SetName

-- toggle nameonly mode on
local function SwitchOn(f)
    if f.friend and not f.player then
        -- color NPC names
        f.name:SetTextColor(.6,1,.6)
    end

    if f.nameonly then return end
    f.nameonly = true

    f:CreateFontString(f.name, {
        reset = true, size = f.trivial and 'small' or 'name', shadow = true
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

    if f.friend and not f.player then
        f.name:SetTextColor(1,1,1)
    end

    f.health:Show()
    f.overlay:Show()
    f.bg:Show()

    -- reposition name
    addon:UpdateName(f,f.trivial)
end

local function nameonly_SetName(f)
    orig_SetName(f)

    if not f.health.curr or not f.nameonly then return end

    local health_length = len(f.name.text) * (f.health.curr / f.health.max)
    f.name:SetText(
        utf8sub(f.name.text, 0, health_length)..
        '|cff555555'..utf8sub(f.name.text, health_length+1)
    )
end

local function OnHealthValueChanged(oldHealth)
    local f = oldHealth.kuiParent.kui
    if f.target or not f.friend then
        SwitchOff(f)
    else
        SwitchOn(f)
    end

    f:SetName()
end

function mod:PostShow(msg,f)
    OnHealthValueChanged(f.oldHealth)
end
function mod:PostHide(msg,f)
    SwitchOff(f)
end
function mod:PostCreate(msg,f)
    f.oldHealth:HookScript('OnValueChanged',OnHealthValueChanged)

    orig_SetName = f.SetName
    f.SetName = nameonly_SetName
end
function mod:PostTarget(msg,f)
    OnHealthValueChanged(f.oldHealth)
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
