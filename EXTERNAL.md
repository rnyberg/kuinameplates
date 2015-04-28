# Tiny module documentation (WIP)

The functionality of KNP can be extensively modified with external addons (modules). Castbars, combo points, tank mode, etc are all modules which could be external addons but are included by default for obvious reasons. Auras are a module provided by an external addon.

This version of KNP relies on Ace3 for module hooking, events and messages. A simple module with no functionality or options looks like this:

    local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
    local mod = addon:NewModule('BlankModuleName')

    function mod:OnInitialize()
        self:SetEnabledState(true)
    end
    function mod:OnEnable()
        -- do stuff!
    end

To add function which modifies the castbar, we could add the following code in the mod:OnEable function:

    self:RegisterMessage('KuiNameplates_PostCreate', 'ModifyCastbar')

And create a new function:

    function mod:ModifyCastbar(message, frame)
        -- ensure the internal castbar module is actually enabled before hooking to it
        if frame.castbar then
            frame.castbar:HookScript('OnShow', OnCastbarShow)
        end
    end

That hookscript call obviously also requires a new function:

    local function OnCastbarShow(self)
        -- "self" here refers to Kui's castbar. We can get the frame itself like this:
        local frame = self:GetParent()

        -- this module changes the colour of the cast bar for no reason at all:
        self:SetStatusBarColor(0,1,0,1)
        -- this overrides any colour set by the internal castbar module.
    end
