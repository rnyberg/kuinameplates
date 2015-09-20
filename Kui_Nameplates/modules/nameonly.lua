--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved.
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('NameOnly', addon.Prototype, 'AceEvent-3.0')
mod.uiName = "Name-only display"

local len = string.len
local utf8sub = LibStub('Kui-1.0').utf8sub
local orig_SetName
local hooked

-- mod functions ###############################################################
-- toggle nameonly mode on
local function SwitchOn(f)
    if f.nameonly then return end
    f.nameonly = true

    if not f.player then
        -- color NPC names
        if f.friend then
            f.name:SetTextColor(.6,1,.6)
        else
            f.name:SetTextColor(1,.6,.6)
        end
    end

    if mod.db.profile.display.hidecastbars then
        addon.Castbar:IgnoreFrame(f)
    end

    f:CreateFontString(f.name, {
        reset = true,
        size = f.trivial and 'nameonlytrivial' or 'nameonly',
        shadow = true
    })
    f.name:SetParent(f)
    f.name:ClearAllPoints()

    -- same as create.lua, UpdateName
    -- prevents font string jitter for some reason
    local swidth = f.name:GetStringWidth()
    swidth = swidth - abs(swidth)
    offset = (swidth > .7 or swidth < .2) and .5 or 0

    f.name:SetPoint('CENTER',offset,.5)
    --f.name:SetPoint('CENTER')

    f.health:Hide()
    f.overlay:Hide()
    f.bg:Hide()
end
-- toggle nameonly mode off
local function SwitchOff(f)
    if not f.nameonly then return end
    f.nameonly = nil

    if not f.player then
        f.name:SetTextColor(1,1,1)
    end

    if mod.db.profile.display.hidecastbars then
        addon.Castbar:UnignoreFrame(f)
    end

    f:CreateFontString(f.name, {
        reset = true, size = 'name'
    })
    f.name:SetParent(f.overlay)
    f.name:ClearAllPoints()

    f.health:Show()
    f.overlay:Show()
    f.bg:Show()

    -- reposition name
    addon:UpdateName(f,f.trivial)

    -- reset name text
    f:SetName()
end
-- SetName hook, to set name's colour based on health
local function nameonly_SetName(f)
    orig_SetName(f)

    if not f.health.curr or not f.nameonly then return end

    local health_length = len(f.name.text) * (f.health.curr / f.health.max)
    f.name:SetText(
        utf8sub(f.name.text, 0, health_length)..
        '|cff555555'..utf8sub(f.name.text, health_length+1)
    )
end
local function HookSetName(f)
    orig_SetName = f.SetName
    f.SetName = nameonly_SetName
end
-- toggle name-only display mode
local function UpdateNameOnly(f)
    if not mod.db.profile.enabled then return end

    if f.kuiParent then
        -- resolve frame for oldHealth hook
        f = f.kuiParent.kui
    end

    if (f.target or not f.friend) or
       (not mod.db.profile.display.ondamaged and f.health.curr < f.health.max)
    then
        SwitchOff(f)
    else
        SwitchOn(f)
        f:SetName()
    end
end
-- message listeners ###########################################################
function mod:PostShow(msg,f)
    UpdateNameOnly(f)
end
function mod:PostHide(msg,f)
    SwitchOff(f)
end
function mod:PostCreate(msg,f)
    f.oldHealth:HookScript('OnValueChanged',UpdateNameOnly)
    f.nameonly_hooked = true

    if self.db.profile.display.ondamaged then
        HookSetName(f)
    end
end
function mod:PostTarget(msg,f)
    UpdateNameOnly(f)
end
-- post db change functions ####################################################
local function UpdateFontSize()
    addon:RegisterFontSize('nameonly',tonumber(mod.db.profile.display.fontsize))
    addon:RegisterFontSize('nameonlytrivial',tonumber(mod.db.profile.display.fontsizetrivial))
end
local function UpdateDisplay(f)
    if not f.nameonly then return end
    f:CreateFontString(f.name, {
        reset = true,
        size = f.trivial and 'nameonlytrivial' or 'nameonly',
        shadow = true
    })
end

mod:AddConfigChanged('enabled',
    function(v)
        mod:SetEnabledState(v)
    end,
    function(f,v)
        if v then
            if not f.nameonly_hooked then
                mod:PostCreate(nil,f)
            end

            if mod.db.profile.display.ondamaged and f.SetName ~= nameonly_SetName then
                HookSetName(f)
            end

            UpdateNameOnly(f)
        else
            SwitchOff(f)
        end
    end
)
mod:AddConfigChanged({'display','ondamaged'}, nil,
    function(f)
        if not mod.db.profile.enabled then return end
        mod.configChangedFuncs.enabled.pf(f,true)
    end
)
mod:AddConfigChanged({{'display','fontsize'},{'display','fontsizetrivial'}},
    UpdateFontSize,
    UpdateDisplay
)
-- initialise ##################################################################
function mod:GetOptions()
    return {
        enabled = {
            name = 'Only show name of friendly units',
            desc = 'Change the layout of friendly nameplates so as to only show their names.',
            type = 'toggle',
            width = 'full',
            order = 0
        },
        display = {
            name = 'Display',
            type = 'group',
            inline = true,
            disabled = function()
                return not mod.db.profile.enabled
            end,
            args = {
                ondamaged = {
                    name = 'Even when damaged',
                    desc = 'Only show the name of damaged nameplates, too. Their name will be coloured as a percentage of health remaining.',
                    type = 'toggle',
                    order = 10,
                },
                hidecastbars = {
                    name = 'Hide castbars',
                    desc = 'Hide castbars when in name-only display.',
                    type = 'toggle',
                    order = 20,
                },
                fontsize = {
                    name = 'Font size',
                    desc = 'Font size used when in name-only display. This is affected by the standard "Font scale" option under "Fonts".',
                    type = 'range',
                    order = 30,
                    step = 1,
                    min = 1,
                    softMin = 1,
                    softMax = 30
                },
                fontsizetrivial = {
                    name = 'Trivial font size',
                    type = 'range',
                    order = 40,
                    step = 1,
                    min = 1,
                    softMin = 1,
                    softMax = 30
                }
            }
        }
    }
end
function mod:OnInitialize()
    self:SetEnabledState(true)

    self.db = addon.db:RegisterNamespace(self.moduleName, {
        profile = {
            enabled = true,
            display = {
                ondamaged = false,
                hidecastbars = true,
                fontsize = 11,
                fontsizetrivial = 9,
            }
        }
    })

    addon:InitModuleOptions(self)
    self:SetEnabledState(self.db.profile.enabled)
end
function mod:OnEnable()
    UpdateFontSize()

    self:RegisterMessage('KuiNameplates_PostHide','PostHide')
    self:RegisterMessage('KuiNameplates_PostShow','PostShow')
    self:RegisterMessage('KuiNameplates_PostTarget','PostTarget')
    self:RegisterMessage('KuiNameplates_PostCreate','PostCreate')
end
function mod:OnDisable()
    self:UnregisterMessage('KuiNameplates_PostHide','PostHide')
    self:UnregisterMessage('KuiNameplates_PostShow','PostShow')
    self:UnregisterMessage('KuiNameplates_PostTarget','PostTarget')
    self:UnregisterMessage('KuiNameplates_PostCreate','PostCreate')
end
