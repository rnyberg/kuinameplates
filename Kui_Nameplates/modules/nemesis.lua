--[[
-- Kui_Nameplates
-- By Kesava at curse.com
--
-- Displays a race icon on enemy nameplates if they are the target of your
-- nemesis quest.
--
-- TODO
-- scan quests, don't activate with no nemesis quest
-- only display icon on active nemesis target
-- only display icon in draenor
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('NemesisHelper', 'AceEvent-3.0')

mod.uiName = 'Nemesis helper'

local RACE_ICON_TEXTURE = 'Interface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES'
local RACE_ICON_OFFSETS = {
    ['Human']    = { .0097, .1152, .0195, .2304 },
    ['Dwarf']    = { .1367, .2382, .0195, .2304 },
    ['Gnome']    = { .2597, .3652, .0195, .2304 },
    ['NightElf'] = { .3867, .4902, .0195, .2304 },
    ['Draenei']  = { .5117, .6171, .0195, .2304 },
    ['Worgen']   = { .6386, .7441, .0195, .2304 },
    ['Pandaren'] = { .7656, .8710, .0195, .2304 },
    ['Tauren']   = { .0097, .1152, .2695, .4804 },
    ['Scourge']  = { .1367, .2382, .2695, .4804 },
    ['Troll']    = { .2597, .3652, .2695, .4804 },
    ['Orc']      = { .3867, .4902, .2695, .4804 },
    ['BloodElf'] = { .5117, .6171, .2695, .4804 },
    ['Goblin']   = { .6386, .7441, .2695, .4804 },
}

local NEMESIS_QUEST_IDS = {
    ['Human']    = { 36921, 36897 },
    ['Dwarf']    = { 36924, 36923 },
    ['Gnome']    = { 36925, 36926 },
    ['Worgen']   = { 36927, 36928 },
    ['Draenei']  = { 36929, 36930 },
    ['NightElf'] = { 36931, 36932 },
    ['BloodElf'] = { 36957, 36958 },
    ['Scourge']  = { 36959, 36960 },
    ['Tauren']   = { 36961, 36962 },
    ['Orc']      = { 36963, 36964 },
    ['Troll']    = { 36965, 36966 },
    ['Pandaren'] = { 36967, 36933, 36968, 36934 },
    ['Goblin']   = { 36969, 36970 }
}

local raceStore = {}
local storeIndex = {}

local function GetGUIDInfo(guid)
    if not guid or guid == "" then return end

    local raceName,raceID,_,name = select(3, GetPlayerInfoByGUID(guid))
    if not name then return end

    if not raceStore[name] then
        -- don't increment with overwrites
        tinsert(storeIndex, name)

        if #storeIndex > 100 then
            -- purge index
            raceStore[tremove(storeIndex, 1)] = nil
        end
    end

    raceStore[name] = raceID

    -- update nameplate if it is visible
    local frame = addon:GetNameplate(guid, name)
    if frame then
        mod:PostShow(nil, frame)
    end
end

function mod:PostCreate(msg, frame)
    -- create race icon
    frame.raceIcon = CreateFrame('Frame')
    local ri = frame.raceIcon

    frame.raceIcon.bg = ri:CreateTexture(nil, 'ARTWORK')
    frame.raceIcon.icon = ri:CreateTexture(nil, 'ARTWORK')
    frame.raceIcon.glow = ri:CreateTexture(nil, 'ARTWORK')

    local ribg = frame.raceIcon.bg
    local rii = frame.raceIcon.icon
    local rig = frame.raceIcon.glow

    ri:SetPoint('LEFT', frame.overlay, 'RIGHT', 2, 0)
    ri:SetSize(18,18)
    ri:Hide()

    ribg:SetDrawLayer('ARTWORK', 2)
    ribg:SetTexture(kui.m.t.solid)
    ribg:SetAllPoints(ri)
    ribg:SetVertexColor(0,0,0)

    rii:SetDrawLayer('ARTWORK', 3)
    rii:SetTexture(RACE_ICON_TEXTURE)
    rii:SetPoint('TOPLEFT', ribg, 1, -1)
    rii:SetPoint('BOTTOMRIGHT', ribg, -1, 1)

    rig:SetDrawLayer('ARTWORK', 1)
    rig:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\combopoint-glow')
    rig:SetPoint('TOPLEFT', ribg, -8, 8)
    rig:SetPoint('BOTTOMRIGHT', ribg, 8, -8)
    rig:SetVertexColor(1,0,0)

    return
end
function mod:PostShow(msg, frame)
    if not frame.name.text then return end
    local name = gsub(frame.name.text, ' %(%*%)', '')

    local race = raceStore[name]
    if race then
        assert(RACE_ICON_OFFSETS[race], 'No offset for race ID: '..race)
        frame.raceIcon.icon:SetTexCoord(unpack(RACE_ICON_OFFSETS[race]))
        frame.raceIcon:Show()
        frame.raceIcon.glow:Show()
    end
end

function mod:PostHide(msg, frame)
    frame.raceIcon:Hide()
    frame.raceIcon.glow:Hide()
end

function mod:GUIDStored(msg, frame)
    GetGUIDInfo(frame.guid)
    self:PostShow(nil, frame)
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local sourceGUID = select(4,...)

    if sourceGUID then
        GetGUIDInfo(sourceGUID)

        local destGUID = select(8,...)
        if destGUID and destGUID ~= sourceGUID then
            GetGUIDInfo(destGUID)
        end
    end
end

function mod:OnInitialize()
    self:SetEnabledState(true)
end

function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostCreate', 'PostCreate')
    self:RegisterMessage('KuiNameplates_GUIDStored', 'GUIDStored')
    self:RegisterMessage('KuiNameplates_PostShow', 'PostShow')
    self:RegisterMessage('KuiNameplates_PostHide', 'PostHide')
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
end
function mod:OnDisable()
    self:UnregisterMessage('KuiNameplates_PostCreate', 'PostCreate')
end
