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

local _
local whitelist
local class
local spellFrames = {}
local classes = {
	'DRUID', 'HUNTER', 'MAGE', 'DEATHKNIGHT', 'WARRIOR', 'PALADIN',
	'WARLOCK', 'SHAMAN', 'PRIEST', 'ROGUE', 'MONK'
}

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
	end

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
end
local function OnOptionsHide(self)
	HideAllSpellFrames()
end

-------------------------------------------------------------------- finalise --
opt:SetScript('OnShow', OnOptionsShow)
opt:SetScript('OnHide', OnOptionsHide)

InterfaceOptions_AddCategory(opt)

--------------------------------------------------------------- slash command --
SLASH_KUISPELLLIST1 = '/kuislc'
SLASH_KUISPELLLIST2 = '/kslc'

function SlashCmdList.KUISPELLLIST(msg)
	InterfaceOptionsFrame_OpenToCategory(category)
	InterfaceOptionsFrame_OpenToCategory(category)
end
