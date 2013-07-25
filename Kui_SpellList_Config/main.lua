--[[
-- Kui_SpellList_Config
-- By Kesava at curse.com
-- All rights reserved
--
-- TODO perhaps have a function to track auras applied to targets by the player
-- to make it easier to find things to add to the list.
--
-- Text box to type names of spells. Uses GetSpellInfo. Description:
-- "Type the name OR ID of an ability to track here.
-- Abilities can only be recognised by name if they are in your currently active
-- set of skills (i.e. your specialisation's page in your spell book). You can
-- use a website such as Wowhead to get spell IDs.
-- Note that although most de/buffs have the same name and ID as their parent ability (the ability that you use to cause it), some do not. For example, if an ability causes more than one effect at the same time, then those effects will use different IDs and only the primary effect will be tracked.
-- For this reason, you may choose to track abilities purely by name by unchecking the 'Search spellbook' option. This prevents the name of the ability being verified and converted when you add it.
-- Additions to this list are saved on a class-by-class basis."
]]
local addon,ns = ...
local category = 'Kui Spell List'
local spelllist = LibStub('KuiSpellList-1.0')
local f = CreateFrame('Frame')

local _
local whitelist
local class -- the currently selected class
local spellFrames = {}
local classes = {
	'DRUID', 'HUNTER', 'MAGE', 'DEATHKNIGHT', 'WARRIOR', 'PALADIN',
	'WARLOCK', 'SHAMAN', 'PRIEST', 'ROGUE', 'MONK'
}

------------------------------------------------- whitelist control functions --
local function RemoveAddedSpell(spellid)
	KuiSpellListCustom.Classes[class] = KuiSpellListCustom.Classes[class] or {}
	KuiSpellListCustom.Classes[class][spellid] = nil

	print('removed added spell `'..spellid..'`')
	print(GetSpellInfo(spellid))
end

local function AddSpellByName(spellname)
	KuiSpellListCustom.Classes[class] = KuiSpellListCustom.Classes[class] or {}
	KuiSpellListCustom.Classes[class][spellname] = true

	print('add spell by name `'..spellname..'`')
end

local function AddSpellByID(spellid)
	KuiSpellListCustom.Classes[class] = KuiSpellListCustom.Classes[class] or {}
	KuiSpellListCustom.Classes[class][spellid] = true

	print('add spell by ID `'..spellid..'`')
	print(GetSpellInfo(spellid))
end

local function IgnoreSpellID(spellid)
	KuiSpellListCustom.Ignore[class] = KuiSpellListCustom.Ignore[class] or {}
	KuiSpellListCustom.Ignore[class][spellid] = true

	print('ignore default spell `'..spellid..'`')
	print(GetSpellInfo(spellid))
end

------------------------------------------------------------- create category --
local opt = CreateFrame('Frame', 'KuiSpellListConfig', InterfaceOptionsFramePanelContainer)
opt:Hide()
opt.name = category

------------------------------------------------------------- create elements --

-- (selection box to select classes)

-- (scroll frame displaying spells)
local spellListFrame = CreateFrame('Frame', 'KuiSpellListConfigSpellListFrame', opt)
spellListFrame:SetSize(300, 300)

local spellListScroll = CreateFrame('ScrollFrame', 'KuiSpellListConfigSpellListScrollFrame', opt, 'UIPanelScrollFrameTemplate')
spellListScroll:SetSize(300, 300)
spellListScroll:SetScrollChild(spellListFrame)
spellListScroll:SetPoint('TOPLEFT', 20, -20)

local spellListBg = CreateFrame('Frame', nil, opt)
spellListBg:SetBackdrop({
	bgFile = 'Interface/ChatFrame/ChatFrameBackground',
	edgeFile = 'Interface/Tooltips/UI-Tooltip-border',
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
spellListBg:SetBackdropColor(.1, .1, .1, .3)
spellListBg:SetBackdropBorderColor(.5, .5, .5)
spellListBg:SetPoint('TOPLEFT', spellListScroll, -10, 10)
spellListBg:SetPoint('BOTTOMRIGHT', spellListScroll, 30, -10)

-- (text entry box to add spell by ID or name)
local spellEntryBox = CreateFrame('EditBox', 'KuiSpellListConfigSpellEntryBox', opt, 'InputBoxTemplate')
spellEntryBox:SetAutoFocus(false)
spellEntryBox:EnableMouse(true)
spellEntryBox:SetMaxLetters(100)
spellEntryBox:SetPoint('TOPLEFT', spellListScroll, 'BOTTOMLEFT', -4, -10)
spellEntryBox:SetSize(284, 25)

local spellAddButton = CreateFrame('Button', 'KuiSpellListConfigSpellAddButton', opt, 'UIPanelButtonTemplate')
spellAddButton:SetText('Add')
spellAddButton:SetPoint('LEFT', spellEntryBox, 'RIGHT')
spellAddButton:SetSize(50, 20)

----------------------------------------------------- element script handlers --
local function SpellFrameOnEnter(self)
	self.highlight:Show()

	if self.link then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:SetHyperlink(self.link)
		GameTooltip:Show()
	end
end
local function SpellFrameOnLeave(self)
	self.highlight:Hide()
	GameTooltip:Hide()
end
local function SpellFrameOnMouseUp(self, button)
	if button == 'RightButton' then
		IgnoreSpellID(self.id)
	end
end

local function SpellAddButtonOnClick(self)
	if spellEntryBox.spellID then
		AddSpellByID(spellEntryBox.spellID)
	elseif spellEntryBox:GetText() ~= '' then
		-- TODO only do this if verify is unchecked
		AddSpellByName(spellEntryBox:GetText())
	end

	spellEntryBox:SetText('')
	spellEntryBox:SetTextColor(1,1,1)
	spellEntryBox:SetFocus()
end

local function SpellEntryBoxOnEnterPressed(self)
	spellAddButton:Click()
end

local function SpellEntryBoxOnEscapePressed(self)
	self:ClearFocus()
end

local function SpellEntryBoxOnTextChanged(self, user)
	self.spellID = nil
	if not user then return end
	
	local text = self:GetText()

	if text == '' then
		spellEntryBox:SetTextColor(1,1,1)
		return
	end

	local usedID, name

	if strmatch(text, '^%d+$') then
		-- using a spell ID
		text = tonumber(text)
		usedID = true
	end

	name = GetSpellInfo(text)

	if name then
		self:SetTextColor(0, 1, 0)

		if not usedID then
			-- get the spell ID from the link
			self.spellID = strmatch(GetSpellLink(name), ':(%d+).h')
		else
			self.spellID = text
		end
	else
		self:SetTextColor(1, 0, 0)
	end
end

------------------------------------------------------------------- functions --
-- creates frame for spells (icon + name + delete button)
local function CreateSpellFrame(spellid)
	local name,_,icon = GetSpellInfo(spellid)
	local f

	if not name then
		name = spellid
		icon = 'Interface/ICONS/INV_Misc_QuestionMark'
	end

	for _,frame in pairs(spellFrames) do
		if not frame:IsShown() then
			f = frame
		end
	end

	if not f then
		f = CreateFrame('Frame', nil, spellListFrame)
		f:EnableMouse(true)

		f.highlight = f:CreateTexture('HIGHLIGHT')
		f.highlight:SetTexture('Interface/BUTTONS/UI-Listbox-Highlight')
		f.highlight:SetBlendMode('add')
		f.highlight:SetAlpha(.5)
		f.highlight:Hide()

		f.icon = f:CreateTexture('ARTWORK')

		f.name = f:CreateFontString(nil, 'ARTWORK')
		f.name:SetFont(STANDARD_TEXT_FONT, 12)

		f:SetSize(300, 20)

		f.highlight:SetAllPoints(f)

		f.icon:SetSize(18, 18)
		f.icon:SetPoint('LEFT')

		f.name:SetSize(280, 18)
		f.name:SetPoint('LEFT', f.icon, 'RIGHT', 4, 0)
		f.name:SetJustifyH('LEFT')

		f:SetScript('OnEnter', SpellFrameOnEnter)
		f:SetScript('OnLeave', SpellFrameOnLeave)
		f:SetScript('OnMouseUp', SpellFrameOnMouseUp)
	end

	f.id = spellid
	f.link = GetSpellLink(spellid)

	f.icon:SetTexture(icon)
	f.name:SetText(name)

	tinsert(spellFrames, f)

	return f
end

-- hides all spellFrames for reuse
local function HideAllSpellFrames()
	for _,frame in pairs(spellFrames) do
		frame:Hide()
		frame.highlight:Hide()
	end
end

-- called upon load or when a different class is selected
local function ClassUpdate()
	local pv
	whitelist = spelllist.GetImportantSpells(class)

	HideAllSpellFrames()

	for spellid,_ in pairs(whitelist) do
		local f = CreateSpellFrame(spellid)

		if pv then
			f:SetPoint('TOPLEFT', pv, 'BOTTOMLEFT', 0, -2)
		else
			f:SetPoint('TOPLEFT')
		end

		f:Show()
		pv = f
	end
end
------------------------------------------------------------- script handlers --
local function OnOptionsShow(self)
	class = select(2, UnitClass('player'))
	ClassUpdate()

	spellEntryBox:SetFocus()
end
local function OnOptionsHide(self)
	HideAllSpellFrames()
end

local function OnEvent(self, event, ...)
	self[event](self, ...)
end
-------------------------------------------------------------- event handlers --
function f:ADDON_LOADED(loaded)
	if loaded ~= addon then return end
	self:UnregisterEvent('ADDON_LOADED')

	-- create/verify saved table
	KuiSpellListCustom = KuiSpellListCustom or {}

	-- spell IDs from the default whitelist to ignore
	KuiSpellListCustom.Ignore = KuiSpellListCustom.Ignore or {}

	-- individual classes' custom whitelists
	KuiSpellListCustom.Classes = KuiSpellListCustom.Classes or {}
end
-------------------------------------------------------------------- finalise --
opt:SetScript('OnShow', OnOptionsShow)
opt:SetScript('OnHide', OnOptionsHide)

spellEntryBox:SetScript('OnEnterPressed', SpellEntryBoxOnEnterPressed)
spellEntryBox:SetScript('OnEscapePressed', SpellEntryBoxOnEscapePressed)
spellEntryBox:SetScript('OnTextChanged', SpellEntryBoxOnTextChanged)

spellAddButton:SetScript('OnClick', SpellAddButtonOnClick)

InterfaceOptions_AddCategory(opt)

f:SetScript('OnEvent', OnEvent)
f:RegisterEvent('ADDON_LOADED')
--------------------------------------------------------------- slash command --
SLASH_KUISPELLLIST1 = '/kuislc'
SLASH_KUISPELLLIST2 = '/kslc'

function SlashCmdList.KUISPELLLIST(msg)
	InterfaceOptionsFrame_OpenToCategory(category)
	InterfaceOptionsFrame_OpenToCategory(category)
end
