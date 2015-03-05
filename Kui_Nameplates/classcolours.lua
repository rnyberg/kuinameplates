--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
--
-- Provides class colours for friendly targets
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('ClassColours', 'AceEvent-3.0')

local cc_table
local cache = {}
local cache_index = {}

mod.uiName = "Class colours"

function mod:SetClassColour(frame, cc)
    frame.name.class_coloured = true
    frame.name:SetTextColor(cc.r,cc.g,cc.b)
end

function mod:GUIDStored(msg, f, unit)
    -- get colour from unit definition and override cache
    if not UnitIsPlayer(unit) then return end
    if UnitIsFriend('player',unit) then
        local class = select(2,UnitClass(unit))
        self:SetClassColour(f, cc_table[class])

        tinsert(cache_index, f.name.text)
        cache[f.name.text] = class

        -- purge index over 100
        if #cache_index > 100 then
            cache[tremove(cache_index, 1)] = nil
        end

        print(#cache_index)
    end
end

function mod:PostShow(msg, f)
    -- restore colour from cache
    if cache[f.name.text] then
        self:SetClassColour(f, cc_table[cache[f.name.text]])
    elseif f.friend and f.player then
        -- a friendly player with no class information
        -- make their name slightly gray
        f.name:SetTextColor(.7,.7,.7)
    end
end

function mod:PostHide(msg, f)
    f.name.class_coloured = nil
    f.name:SetTextColor(1,1,1,1)
end

function mod:OnInitialize()
    cc_table = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    self:SetEnabledState(true)
end

function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_GUIDStored', 'GUIDStored')
    self:RegisterMessage('KuiNameplates_PostShow', 'PostShow')
    self:RegisterMessage('KuiNameplates_PostHide', 'PostHide')
end
