
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

local in_arena

function mod:IsArenaPlate(frame)
    -- strip different-realm indicator
    local name = gsub(frame.name.text, ' %(%*%)$', '')

    for i = 1, GetNumArenaOpponents() do
        if name == UnitName('arena'..i) and
           frame.health.max == UnitHealthMax('arena'..i)
        then
            frame.level:SetText(i)
            return
        elseif name == UnitName('arenapet'..i) and
               frame.health.max == UnitHealthMax('arenapet'..i)
        then
            frame.level:SetText(i..'*')
            return
        end
    end

    -- unhandled name
    frame.level:SetText('?')
end

function mod:PLAYER_ENTERING_WORLD()
    in_instance, instance_type = IsInInstance()
    if in_instance and instance_type == 'arena' then
        in_arena = true
        self:RegisterMessage('KuiNameplates_PostShow', 'PostShow')
    else
        in_arena = nil
        self:UnregisterMessage('KuiNameplates_PostShow', 'PostShow')
    end
end

function mod:PostShow(msg, frame)
    if in_arena then
        self:IsArenaPlate(frame)
    end
end

function mod:OnInitialize()
    self:SetEnabledState(true)
end

function mod:OnEnable()
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

