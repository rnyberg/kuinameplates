--[[
	Kui Nameplates
	By Kesava - Auchindoun, or Kesava at curse.com
	All rights reserved
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('TankMode', 'AceEvent-3.0')

mod.uiName = 'Tank mode'

function mod:OnEnable()
	self:Toggle()
end
--------------------------------------------------------- tank mode functions --
function mod:Update()
	if self.db.profile.tank.tankmode == 1 then
		-- smart - judge by spec
		local role = GetSpecializationRole(GetSpecialization())

		if role == 'TANK' then
			addon.TankMode = true
		else
			addon.TankMode = false
		end
	else
		addon.TankMode = (self.db.profile.mode == 3)
	end
end

function mod:Toggle()
	if self.db.profile.tank.tankmode == 1 then
		-- smart tank mode, listen for spec changes
		self:RegisterEvent('PLAYER_TALENT_UPDATE', 'Update')
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'Update')
	else
		self:UnregisterEvent('PLAYER_TALENT_UPDATE')
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	end

	self:Update()
end

function mod:OnInitialize()
	self.db = addon.db.RegisterNamespace(self.moduleName, {
		profile = {
		}
	})

	addon:InitModuleOptions(self)
	mod:SetEnabledState(true)
end

function mod:OnEnable()
	self:Toggle()
end
