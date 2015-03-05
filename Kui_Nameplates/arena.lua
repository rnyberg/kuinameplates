
--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
--
-- Modifications for plates while in an arena
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('Arena', 'AceEvent-3.0')

mod.uiName = "Arena modifications"
mod.in_arena = nil

function mod:IsArenaPlate(frame)
    -- TODO we should cache this after the event runs telling us it's available
    -- rather than every time a plate becomes visible
    for i = 1, GetNumArenaOpponents() do
        print('check arena'..i)
        if frame.name.text == GetUnitName('arena'..i) or
           frame.name.text == GetUnitName('arenapet'..i)
        then
            print(frame.name.text..' is '..i)
            frame.level:SetText('arena '..i)
        end
    end
end

function mod:PLAYER_ENTERING_WORLD()
    in_instance, instance_type = IsInInstance()
    if in_instance and instance_type == 'arena' then
        self.in_arena = true
        print('in arena')
    end
end

function mod:PostShow(msg, frame)
    if self.in_arena then
        self:IsArenaPlate(frame)
    end
end

function mod:OnInitialize()
    self:SetEnabledState(true)
end

function mod:OnEnable()
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterMessage('KuiNameplates_PostShow', 'PostShow')
end
