
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
local cache = {}

function mod:IsArenaPlate(frame)
    if cache[frame.name.text] then
        frame.level:SetText(cache[frame.name.text])
    else
        frame.level:SetText('?')
    end
end

function mod:PLAYER_ENTERING_WORLD()
    in_instance, instance_type = IsInInstance()
    if in_instance and instance_type == 'arena' then
        print('in arena')
        in_arena = true
        self:RegisterEvent('ARENA_OPPONENT_UPDATE')
    else
        in_arena = nil
        self:UnregisterEvent('ARENA_OPPONENT_UPDATE')
        wipe(cache)
    end
end

function mod:ARENA_OPPONENT_UPDATE(event, unit, message)
    print('opponent update fired for '..unit)

    -- cache opponent names as they become available
    -- TODO not sure if this fires for pets
    if not unit then return end
    local id = tonumber(strsub(unit, -1))
    local name = GetUnitName(unit)
    if not id or not name then return end

    print(id..' = '..name)

    cache[name] = id
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
    self:RegisterMessage('KuiNameplates_PostShow', 'PostShow')
end
