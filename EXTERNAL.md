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

To add a function which modifies the name text, we could add the following code in the mod:OnEnable function:

    self:RegisterMessage('KuiNameplates_PostCreate', 'ModifyName')

To get the RegisterMessage function, we need to mixin the AceEvent library, first.

    local mod = addon:NewModule('BlankModuleName', 'AceEvent-3.0')

And create a new function:

    function mod:ModifyName(message, frame)
        -- we "overload" the frame's SetName function, which is called every
        -- so often and OnShow to set the frame's name text
        frame.orig_SetName = frame.SetName
        frame.SetName = custom_SetName
    end

That obviously requires another function - custom_SetName:

    local function custom_SetName(self)
        -- "self" here refers to the frame, as SetName is a frame function
        -- allow the original function to actually set the name, first
        self:orig_SetName()

        -- now that the name is set, we can make our modifications
        -- let's just pointlessly add some brackets around the name of every frame
        self.name:SetText('['..self.name.text..']')
    end

So altogether, this module's code looks like this:

    local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
    local mod = addon:NewModule('BlankModuleName', 'AceEvent-3.0')

    local function custom_SetName(self)
        -- "self" here refers to the frame, as SetName is a frame function
        -- allow the original function to actually set the name, first
        self:orig_SetName()

        -- now that the name is set, we can make our modifications
        -- let's just pointlessly add some brackets around the name of every frame
        self.name:SetText('['..self.name.text..']')
    end
    function mod:ModifyName(message, frame)
        -- we "overload" the frame's SetName function, which is called every
        -- so often and OnShow to set the frame's name text
        frame.orig_SetName = frame.SetName
        frame.SetName = custom_SetName
    end
    function mod:OnInitialize()
        self:SetEnabledState(true)
    end
    function mod:OnEnable()
        self:RegisterMessage('KuiNameplates_PostCreate', 'ModifyName')
    end
