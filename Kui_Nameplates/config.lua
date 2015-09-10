--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
------------------------------------------------------------------ Ace config --
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

local RELOAD_HINT = '\n\n|cffff0000UI reload required to take effect.'
--------------------------------------------------------------- Options table --
do
    local StrataSelectList = {
        ['BACKGROUND'] = '1. BACKGROUND',
        ['LOW'] = '2. LOW',
        ['MEDIUM'] = '3. MEDIUM',
        ['HIGH'] = '4. HIGH',
        ['DIALOG'] = '5. DIALOG',
        ['TOOLTIP'] = '6. TOOLTIP',
    }

    local HealthTextSelectList = {
        'Current |cff888888(145k)', 'Maximum |cff888888(156k)', 'Percent |cff888888(93)', 'Deficit |cff888888(-10.9k)', 'Blank |cff888888(  )'
    }

    local globalConfigChangedListeners = {}

    local handlers = {}
    local handlerProto = {}
    local handlerMeta = { __index = handlerProto }

    -- called by handler:Set when configuration is changed
    local function ConfigChangedSkeleton(mod, key, profile)
        if mod.configChangedListener then
            -- notify that any option has changed
            mod:configChangedListener()
        end

        -- call option specific callbacks
        if mod.configChangedFuncs.runOnce and
           mod.configChangedFuncs.runOnce[key]
        then
            -- call runOnce function
            mod.configChangedFuncs.runOnce[key](profile[key])
        end

        -- find and call global config changed listeners
        local voyeurs = {}
        if  globalConfigChangedListeners[mod:GetName()] and
            globalConfigChangedListeners[mod:GetName()][key]
        then
            for _,voyeur in ipairs(globalConfigChangedListeners[mod:GetName()][key]) do
                voyeur = addon:GetModule(voyeur)

                if voyeur.configChangedFuncs.global.runOnce[key] then
                    voyeur.configChangedFuncs.global.runOnce[key](profile[key])
                end

                if voyeur.configChangedFuncs.global[key] then
                    -- also call when iterating frames
                    tinsert(voyeurs, voyeur)
                end
            end
        end

        if mod.configChangedFuncs[key] then
            -- iterate frames and call
            for _, frame in pairs(addon.frameList) do
                mod.configChangedFuncs[key](frame.kui, profile[key])

                for _,voyeur in ipairs(voyeurs) do
                    voyeur.configChangedFuncs.global[key](frame.kui, profile[key])
                end
            end
        end

    end

    function handlerProto:ResolveInfo(info)
        local p = self.dbPath.db.profile

        local child, k
        for i = 1, #info do
            k = info[i]

            if i < #info then
                if not child then
                    child = p[k]
                else
                    child = child[k]
                end
            end
        end

        return child or p, k
    end

    function handlerProto:Get(info, ...)
        local p, k = self:ResolveInfo(info)
        if not p[k] then return end

        if info.type == 'color' then
            return unpack(p[k])
        else
            return p[k]
        end
    end

    function handlerProto:Set(info, val, ...)
        local p, k = self:ResolveInfo(info)

        if info.type == 'color' then
            p[k] = { val, ... }
        else
            p[k] = val
        end

        if self.dbPath.ConfigChanged then
            -- inform module of configuration change
            self.dbPath:ConfigChanged(k, p)
        end
    end

    function addon:GetOptionHandler(mod)
        if not handlers[mod] then
            handlers[mod] = setmetatable({ dbPath = mod }, handlerMeta)
        end

        return handlers[mod]
    end

    local options = {
        name = 'Kui Nameplates',
        handler = addon:GetOptionHandler(addon),
        type = 'group',
        get = 'Get',
        set = 'Set',
        args = {
            header = {
                type = 'header',
                name = '|cffff4444Many options currently require a UI reload to take effect.|r',
                order = 0
            },
            general = {
                name = 'General display',
                type = 'group',
                order = 1,
                args = {
                    combataction_hostile = {
                        name = 'Combat action: hostile',
                        desc = 'Automatically toggle hostile nameplates when entering/leaving combat. Setting will be inverted upon leaving combat.',
                        type = 'select',
                        values = {
                            'Do nothing', 'Hide enemies', 'Show enemies'
                        },
                        order = 0
                    },
                    combataction_friendly = {
                        name = 'Combat action: friendly',
                        desc = 'Automatically toggle friendly nameplates when entering/leaving combat. Setting will be inverted upon leaving combat.',
                        type = 'select',
                        values = {
                            'Do nothing', 'Hide friendlies', 'Show friendlies'
                        },
                        order = 1
                    },
                    fixaa = {
                        name = 'Fix aliasing',
                        desc = 'Attempt to make plates appear sharper. Has a positive effect on FPS, but will make plates appear a bit "loose", especially at low frame rates. Works best when uiscale is disabled and at larger resolutions (lower resolutions automatically downscale the interface regardless of uiscale setting).'..RELOAD_HINT,
                        type = 'toggle',
                        order = 10
                    },
                    compatibility = {
                        name = 'Stereo compatibility',
                        desc = 'Fix compatibility with stereo video. This has a negative effect on performance when many nameplates are visible.'..RELOAD_HINT,
                        type = 'toggle',
                        order = 20
                    },
                    leftie = {
                        name = 'Use leftie layout',
                        desc = 'Use left-aligned text layout (similar to the pre-223 layout). Note that this layout truncates long names. But maybe you prefer that.'..RELOAD_HINT,
                        type = 'toggle',
                        order = 30
                    },
                    highlight = {
                        name = 'Highlight',
                        desc = 'Highlight plates on mouse over.',
                        type = 'toggle',
                        order = 40
                    },
                    highlight_target = {
                        name = 'Highlight target',
                        desc = 'Also highlight the current target.',
                        type = 'toggle',
                        order = 50,
                        disabled = function(info)
                            return not addon.db.profile.general.highlight
                        end
                    },
                    glowshadow = {
                        name = 'Use glow as shadow',
                        desc = 'The frame glow is used to indicate threat. It becomes black when a unit has no threat status. Disabling this option will make it transparent instead.',
                        type = 'toggle',
                        order = 70,
                        width = 'double'
                    },
                    targetglow = {
                        name = 'Show target glow',
                        desc = 'Make your target\'s nameplate glow',
                        type = 'toggle',
                        order = 80
                    },
                    targetglowcolour = {
                        name = 'Target glow colour',
                        type = 'color',
                        order = 90,
                        hasAlpha = true,
                        disabled = function(info)
                            return not addon.db.profile.general.targetglow and not addon.db.profile.general.targetarrows
                        end
                    },
                    targetarrows = {
                        name = 'Show target arrows',
                        desc = 'Show arrows around your target\'s nameplate. They will inherit the colour of the target glow, set above.',
                        type = 'toggle',
                        order = 100,
                        width = 'double'
                    },
                    hheight = {
                        name = 'Health bar height',
                        desc = 'Note that these values do not affect the size or shape of the click-box, which cannot be changed.',
                        order = 110,
                        type = 'range',
                        step = 1,
                        min = 1,
                        softMin = 3,
                        softMax = 30
                    },
                    thheight = {
                        name = 'Trivial health bar height',
                        desc = 'Height of the health bar of trivial (small, low maximum health) units.',
                        order = 120,
                        type = 'range',
                        step = 1,
                        min = 1,
                        softMin = 3,
                        softMax = 30
                    },
                    width = {
                        name = 'Frame width',
                        order = 130,
                        type = 'range',
                        step = 1,
                        min = 1,
                        softMin = 25,
                        softMax = 220
                    },
                    twidth = {
                        name = 'Trivial frame width',
                        order = 140,
                        type = 'range',
                        step = 1,
                        min = 1,
                        softMin = 25,
                        softMax = 220
                    },
                    bartexture = {
                        name = 'Status bar texture',
                        desc = 'The texture used for both the health and cast bars.',
                        type = 'select',
                        dialogControl = 'LSM30_Statusbar',
                        values = AceGUIWidgetLSMlists.statusbar,
                        order = 150,
                    },
                    strata = {
                        name = 'Frame strata',
                        desc = 'The frame strata used by all frames, which determines what "layer" of the UI the frame is on. Untargeted frames are displayed at frame level 0 of this strata. Targeted frames are bumped to frame level 3.\n\nThis does not and can not affect the click-box of the frames, only their visibility.',
                        type = 'select',
                        values = StrataSelectList,
                        order = 160
                    },
                    lowhealthval = {
                        name = 'Low health value',
                        desc = 'Low health value used by some modules, such as frame fading.',
                        type = 'range',
                        min = 1,
                        max = 100,
                        bigStep = 1,
                        order = 170
                    },
                }
            },
            fade = {
                name = 'Frame fading',
                type = 'group',
                order = 2,
                args = {
                    fadedalpha = {
                        name = 'Faded alpha',
                        desc = 'The alpha value to which plates fade out to',
                        type = 'range',
                        min = 0,
                        max = 1,
                        bigStep = .01,
                        isPercent = true,
                        order = 4
                    },
                    fademouse = {
                        name = 'Fade in with mouse',
                        desc = 'Fade plates in on mouse-over',
                        type = 'toggle',
                        order = 1
                    },
                    fadeall = {
                        name = 'Fade all frames',
                        desc = 'Fade out all frames by default (rather than in)',
                        type = 'toggle',
                        order = 2
                    },
                    smooth = {
                        name = 'Smoothly fade',
                        desc = 'Smoothly fade plates in/out (fading is instant when disabled)',
                        type = 'toggle',
                        order = 0
                    },
                    fadespeed = {
                        name = 'Smooth fade speed',
                        desc = 'Fade animation speed modifier (lower is faster)',
                        type = 'range',
                        min = 0,
                        softMax = 5,
                        order = 3,
                        disabled = function(info)
                            return not addon.db.profile.fade.smooth
                        end
                    },
                    rules = {
                        name = 'Fading rules',
                        type = 'group',
                        inline = true,
                        order = 20,
                        args = {
                            avoidhostilehp = {
                                name = 'Don\'t fade hostile units at low health',
                                desc = 'Avoid fading hostile units which are at or below a health value, determined by low health value under general display options.',
                                type = 'toggle',
                                order = 1
                            },
                            avoidfriendhp = {
                                name = 'Don\'t fade friendly units at low health',
                                desc = 'Avoid fading friendly units which are at or below a health value, determined by low health value under general display options.',
                                type = 'toggle',
                                order = 2
                            },
                            avoidcast = {
                                name = 'Don\'t fade casting units',
                                desc = 'Avoid fading units which are casting.',
                                type = 'toggle',
                                order = 5
                            },
                            avoidraidicon = {
                                name = 'Don\'t fade units with raid icons',
                                desc = 'Avoid fading units which have a raid icon (skull, cross, etc).',
                                type = 'toggle',
                                order = 10
                            },
                        },
                    },
                }
            },
            text = {
                name = 'Text',
                type = 'group',
                order = 3,
                args = {
                    healthoffset = {
                        name = 'Health bar text offset',
                        desc = 'Offset of the text on the top and bottom of the health bar: level, name, standard health and contextual health. The offset is reversed for contextual health.\n'..
                               'Note that the default values end in .5 as this prevents jittering text, but only if "fix aliasing" is also enabled.',
                        type = 'range',
                        bigStep = .5,
                        softMin = -5,
                        softMax = 10,
                        order = 1
                    },
                    level = {
                        name = 'Show levels',
                        desc = 'Show levels on nameplates',
                        type = 'toggle',
                        order = 2
                    },
                }
            },
            hp = {
                name = 'Health display',
                type = 'group',
                order = 4,
                args = {
                    reactioncolours = {
                        name = 'Reaction colours',
                        type = 'group',
                        inline = true,
                        order = 1,
                        args = {
                            hatedcol = {
                                name = 'Hostile',
                                type = 'color',
                                order = 1
                            },
                            neutralcol = {
                                name = 'Neutral',
                                type = 'color',
                                order = 2
                            },
                            friendlycol = {
                                name = 'Friendly',
                                type = 'color',
                                order = 3
                            },
                            tappedcol = {
                                name = 'Tapped',
                                type = 'color',
                                order = 4
                            },
                            playercol = {
                                name = 'Friendly player',
                                type = 'color',
                                order = 5
                            }
                        }
                    },
                    text = {
                        name = 'Health text',
                        type = 'group',
                        inline = true,
                        order = 10,
                        disabled = function(info)
                            return addon.db.profile.hp.text.hp_text_disabled
                        end,
                        args = {
                            hp_text_disabled = {
                                name = 'Never show health text',
                                type = 'toggle',
                                order = 0,
                                disabled = false
                            },
                            mouseover = {
                                name = 'Mouseover & target only',
                                desc = 'Show health only on mouseover or on the targeted plate',
                                type = 'toggle',
                                order = 10
                            },
                            hp_friend_max = {
                                name = 'Max. health friend',
                                desc = 'Health text to show on maximum health friendly units',
                                type = 'select',
                                values = HealthTextSelectList,
                                order = 20
                            },
                            hp_friend_low = {
                                name = 'Damaged friend',
                                desc = 'Health text to show on damaged friendly units',
                                type = 'select',
                                values = HealthTextSelectList,
                                order = 30
                            },
                            hp_hostile_max = {
                                name = 'Max. health hostile',
                                desc = 'Health text to show on maximum health hostile units',
                                type = 'select',
                                values = HealthTextSelectList,
                                order = 40
                            },
                            hp_hostile_low = {
                                name = 'Damaged hostile',
                                desc = 'Health text to show on damaged hostile units',
                                type = 'select',
                                values = HealthTextSelectList,
                                order = 50
                            },
                            hp_warning = {
                                name = 'Due to limitations introduced in patch 6.2.2, health text on nameplates is not known until the first mouseover/target of that frame. This value can be cached and restored for players, where names are reasonably unique, but not for NPCs.'
                            }
                        }
                    },
                    smooth = {
                        name = 'Smooth health bar',
                        desc = 'Smoothly animate health bar value updates',
                        type = 'toggle',
                        width = 'full',
                        order = 30
                    },
                }
            },
            fonts = {
                name = 'Fonts',
                type = 'group',
                args = {
                    options = {
                        name = 'Global font settings',
                        type = 'group',
                        inline = true,
                        args = {
                            font = {
                                name = 'Font',
                                desc = 'The font used for all text on nameplates',
                                type = 'select',
                                dialogControl = 'LSM30_Font',
                                values = AceGUIWidgetLSMlists.font,
                                order = 5
                            },
                            fontscale = {
                                name = 'Font scale',
                                desc = 'The scale of all fonts displayed on nameplates',
                                type = 'range',
                                min = 0.01,
                                softMax = 3,
                                order = 1
                            },
                            outline = {
                                name = 'Outline',
                                desc = 'Display an outline on all fonts',
                                type = 'toggle',
                                order = 10
                            },
                            monochrome = {
                                name = 'Monochrome',
                                desc = 'Don\'t anti-alias fonts',
                                type = 'toggle',
                                order = 15
                            },
                            onesize = {
                                name = 'Use one font size',
                                desc = 'Use the same font size for all strings. Useful when using a pixel font.',
                                type = 'toggle',
                                order = 20
                            },
                            noalpha = {
                                name = 'All fonts opaque',
                                desc = 'Use 100% alpha value on all fonts.'..RELOAD_HINT,
                                type = 'toggle',
                                order = 25
                            },
                        }
                    },
                }
            },
            reload = {
                name = 'Reload UI',
                type = 'execute',
                width = 'triple',
                order = 99,
                func = ReloadUI
            },
        }
    }

    local function RegisterForConfigChanged(module, target_module, key)
        -- this module wants to listen for another module's (or the addon's)
        -- configChanged calls
        local mod_name = module:GetName()

        if not target_module or target_module == 'addon' then
            target_module = 'KuiNameplates'
        end

        if not globalConfigChangedListeners[target_module] then
            globalConfigChangedListeners[target_module] = {}
        end

        if not globalConfigChangedListeners[target_module][key] then
            globalConfigChangedListeners[target_module][key] = {}
        end

        tinsert(globalConfigChangedListeners[target_module][key], mod_name)
    end

    function addon:ProfileChanged()
        -- call all configChangedListeners
        if addon.configChangedListener then
            addon:configChangedListener()
        end

        for _,module in addon:IterateModules() do
            if module.configChangedListener then
                module:configChangedListener()
            end
        end
    end

    -- create module.ConfigChanged function
    function addon:CreateConfigChangedListener(module)
        if module.configChangedFuncs and not module.ConfigChanged then
            module.ConfigChanged = ConfigChangedSkeleton
        end

        if module.configChangedListener then
            -- run listener upon initialisation
            module:configChangedListener()
        end
    end

    -- create an options table for the given module
    function addon:InitModuleOptions(module)
        if not module.GetOptions then return end
        local opts = module:GetOptions()
        local name = module.uiName or module.moduleName

        self:CreateConfigChangedListener(module)
        module.RegisterForConfigChanged = RegisterForConfigChanged

        options.args[name] = {
            name = name,
            handler = self:GetOptionHandler(module),
            type = 'group',
            order = 50+(#handlers*10),
            get = 'Get',
            set = 'Set',
            args = opts
        }
    end

    AceConfig:RegisterOptionsTable('kuinameplates', options)
    AceConfigDialog:AddToBlizOptions('kuinameplates', 'Kui Nameplates')
end

--------------------------------------------------------------- Slash command --
SLASH_KUINAMEPLATES1 = '/kuinameplates'
SLASH_KUINAMEPLATES2 = '/knp'

function SlashCmdList.KUINAMEPLATES()
    -- twice to workaround an issue introduced with 5.3
    InterfaceOptionsFrame_OpenToCategory('Kui Nameplates')
    InterfaceOptionsFrame_OpenToCategory('Kui Nameplates')
end
