-- Config.lua - Configuration system with YAML-like parser
local ADDON_NAME = "DoroxAuras"
DoroxAurasConfig = {}

-- Default configuration
local defaults = {
    enabled = true,
    locked = true,
    showOutOfCombat = true,

    sounds = {
        raid_warning = "Sound\\Interface\\RaidWarning.wav",
        map_ping = "Sound\\Interface\\MapPing.wav",
        levelup = "Sound\\Interface\\LevelUp.wav",
    },

    -- Use custom HD icons instead of default WoW icons
    useCustomIcons = false,

    -- Custom icon overrides (spell name -> texture path)
    -- Only includes spells that are actually configured in auras below
    -- To add more: copy icon to textures/icons/ and add mapping here
    iconOverrides = {
        -- Target Debuffs
        ["Corruption"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\corruption",
        ["Unstable Affliction"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\unstableaffliction",
        ["Haunt"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\haunt",
        ["Immolate"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\immolate",
        ["Curse of Doom"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\curseofdoom",
        ["Curse of Agony"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\curseofagony",
        ["Curse of Tongues"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\curseoftongues",
        ["Shadowflame"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\shadowflame",
        ["Fear"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\fear",
        ["Banish"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\banish",

        -- Self Buffs
        ["Fel Armor"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\felarmor",
        ["Life Tap"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\lifetap",
        ["Soul Link"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\soullink",
        ["Demonic Empowerment"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\demonicempowerment",
        ["Immolation Aura"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\immolationaura",
        ["Demonic Circle: Summon"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\demoniccircle",
        ["Demonic Circle: Teleport"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\demoniccircleteleport",
        ["Soulstone Resurrection"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\soulstone",

        -- Procs
        ["Decimation"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\decimation",
        ["Molten Core"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\moltencore",
        ["Shadow Trance"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\shadowtrance",
        ["Eradication"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\eradication",

        -- Fillers
        ["Shadow Bolt"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\shadowbolt",
        ["Incinerate"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\incinerate",

        -- Raid Buffs
        ["Gift of the Wild"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\giftofthewild",
        ["Mark of the Wild"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\giftofthewild",
        ["Arcane Brilliance"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\arcaneintellect",
        ["Arcane Intellect"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\arcaneintellect",
        ["Dalaran Brilliance"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\arcaneintellect",
        ["Fel Intelligence"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\arcaneintellect",
        ["Greater Blessing of Kings"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofkings",
        ["Blessing of Kings"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofkings",
        ["Drums of the Forgotten Kings"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofkings",
        ["Greater Blessing of Wisdom"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofwisdom",
        ["Blessing of Wisdom"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofwisdom",
        ["Mana Spring"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofwisdom",
        ["Greater Blessing of Sanctuary"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofsanctuary",
        ["Blessing of Sanctuary"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\blessingofsanctuary",
        ["Prayer of Spirit"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\spirit",
        ["Divine Spirit"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\spirit",
        ["Prayer of Fortitude"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\fortitude",
        ["Power Word: Fortitude"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\fortitude",
        ["Blood Pact"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\fortitude",
        ["Commanding Shout"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\fortitude",
        ["Flask of the Frost Wyrm"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\flask",
        ["Flask of Pure Mojo"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\flask",
        ["Flask of Endless Rage"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\flask",
        ["Flask of Stoneblood"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\flask",
        ["Well Fed"] = "Interface\\AddOns\\DoroxAuras\\textures\\icons\\wellfed",
    },

    groups = {
        target_debuffs = {
            anchor = "CENTER",
            x = -127,
            y = -233,
            grow = "GRID",
            columns = 5,
            spacing = 2,
            icon_size = 50,
            show_timer = true,
        },
        self_buffs = {
            anchor = "CENTER",
            x = -106,
            y = 413,
            grow = "GRID",
            columns = 5,
            spacing = 2,
            icon_size = 50,
            show_timer = false,
        },
        procs = {
            anchor = "CENTER",
            x = 0,
            y = 100,
            grow = "HORIZONTAL",
            spacing = 5,
            icon_size = 64,
            show_timer = true,
        },
        raid_buffs = {
            anchor = "CENTER",
            x = 200,
            y = 413,
            grow = "HORIZONTAL",
            spacing = 2,
            icon_size = 40,
            show_timer = false,
        },
        -- Cooldown tracking (Haunt, Demonic Empowerment)
        cooldowns = {
            anchor = "CENTER",
            x = 0,
            y = 150,
            grow = "HORIZONTAL",
            spacing = 10,
            icon_size = 80,
            show_timer = true,
        },
        -- Trinket procs (DFO, CTS)
        trinket_procs = {
            anchor = "CENTER",
            x = 0,
            y = -100,
            grow = "HORIZONTAL",
            spacing = 5,
            icon_size = 60,
            show_timer = true,
        },
        -- Filler spell suggestions
        fillers = {
            anchor = "CENTER",
            x = 0,
            y = 50,
            grow = "HORIZONTAL",
            spacing = 5,
            icon_size = 50,
            show_timer = false,
        },
    },

    -- Warlock auras (default config)
    auras = {
        -- ==================== TARGET DEBUFFS ====================
        {
            name = "Corruption",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Corruption",
            refresh_warn = 3,
            show_missing = true,
            priority = 1,
        },
        {
            name = "Unstable Affliction",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Unstable Affliction",
            refresh_warn = 2,
            show_missing = true,
            -- Removed requires_spell - if debuff is active, you obviously know it
            priority = 2,
        },
        {
            name = "Haunt",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Haunt",
            refresh_warn = 1,
            show_missing = true,
            -- Removed requires_spell - if debuff is active, you obviously know it
            priority = 3,
        },
        {
            name = "Immolate",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Immolate",
            refresh_warn = 3,
            show_missing = true,
            -- No requires_spell - all warlocks have Immolate
            priority = 4,
        },
        {
            name = "Curse of Elements",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = false,
            spells = {"Curse of the Elements", "Earth and Moon", "Ebon Plaguebringer"},
            show_missing = true,
            in_group_only = true,  -- Only show when in party/raid
            -- Only show if no Druid or DK in group (they provide equivalent debuffs)
            hide_if_class_present = {"DRUID", "DEATHKNIGHT"},
            priority = 5,
        },
        {
            name = "Curse of Doom",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Curse of Doom",
            show_missing = true,
            -- All warlocks have CoD, no restriction needed
            priority = 6,
        },
        {
            name = "Curse of Agony",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Curse of Agony",
            refresh_warn = 2,
            show_missing = true,
            -- All warlocks have CoA, no restriction needed
            priority = 7,
        },
        {
            name = "Curse of Tongues",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Curse of Tongues",
            priority = 8,
        },
        {
            name = "Shadowflame",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Shadowflame",
            priority = 9,
        },
        {
            name = "Fear",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Fear",
            priority = 10,
        },
        {
            name = "Banish",
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = "Banish",
            priority = 11,
        },

        -- ==================== SELF BUFFS ====================
        {
            name = "Fel Armor",
            group = "self_buffs",
            unit = "player",
            type = "buff",
            spell = "Fel Armor",
            show_missing = true,
            refresh_warn = 600,  -- 10 minutes
            hide_when_healthy = true,  -- Only show when missing or < 10 min remaining
            priority = 1,
        },
        {
            name = "Healthstone",
            group = "self_buffs",
            unit = "player",
            type = "item",  -- Special: check bags for item
            item_ids = {36892, 36893, 36894},  -- Fel Healthstone (all ranks)
            show_missing = true,
            glow_on_missing = true,
            priority = 0,
        },
        {
            name = "Demonic Circle",
            group = "self_buffs",
            unit = "player",
            type = "special",  -- Special tracking for Demonic Circle
            spell = "Demonic Circle: Teleport",
            summon_spell = "Demonic Circle: Summon",
            show_missing = true,
            glow_on_missing = true,
            track_distance = true,  -- Show distance/direction when out of range
            max_range = 40,  -- Teleport range
            priority = 0,
        },
        {
            name = "Soulstone",
            group = "self_buffs",
            unit = "group",  -- Special: scan all group/raid members
            type = "buff",
            spell = "Soulstone Resurrection",
            show_missing = true,
            in_group_only = true,  -- Only show when in party/raid
            check_cooldown = true,  -- Only show missing if spell is off cooldown
            cooldown_spell = "Create Soulstone",  -- The spell to check cooldown for
            priority = 0,
        },
        {
            name = "Life Tap",
            group = "fillers",
            unit = "player",
            type = "buff",
            spell = "Life Tap",
            show_missing = true,
            refresh_warn = 10,  -- Show bouncing when < 10 seconds remaining
            hide_when_healthy = true,  -- Only show when missing or expiring
            glow_on_missing = true,
            priority = 3,
        },
        {
            name = "Life Tap Mana",
            group = "procs",  -- Show prominently with procs
            unit = "player",
            type = "mana_alert",
            spell = "Life Tap",
            show_below_mana = 40,  -- Show when mana < 40%
            priority = 10,
        },
        {
            name = "Soul Link",
            group = "self_buffs",
            unit = "player",
            type = "buff",
            spell = "Soul Link",
            show_missing = true,
            only_show_missing = true,  -- NEVER show when active, only when missing
            requires_talent = "Soul Link",  -- Only show if talented (Demonology)
            priority = 3,
        },
        {
            name = "Demonic Empowerment",
            group = "self_buffs",
            unit = "pet",
            type = "buff",
            spell = "Demonic Empowerment",
            requires_talent = "Demonic Empowerment",  -- Demonology talent
            priority = 4,
        },
        {
            name = "Immolation Aura CD",
            group = "fillers",
            unit = "player",
            type = "cooldown",
            spell = "Immolation Aura",
            show_when_ready = true,
            requires_spec = "DEMO",
            requires_buff = "Metamorphosis",  -- Only show when in Meta form
            priority = 4,
        },

        -- ==================== COOLDOWN TRACKING ====================
        -- Main rotation cooldowns shown prominently
        {
            name = "Haunt CD",
            group = "cooldowns",
            unit = "player",
            type = "cooldown",
            spell = "Haunt",
            show_when_ready = true,  -- Glow when CD = 0
            requires_spec = "AFFLI",
            priority = 1,
        },
        {
            name = "Demonic Empowerment CD",
            group = "cooldowns",
            unit = "player",
            type = "cooldown",
            spell = "Demonic Empowerment",
            show_when_ready = true,
            requires_spec = "DEMO",
            priority = 1,
        },

        -- ==================== TRINKET PROCS ====================
        {
            name = "DFO Proc",
            group = "trinket_procs",
            unit = "player",
            type = "buff",
            spell = "Surging Power",  -- DFO stacking buff
            glow = true,
            show_stacks = true,
            is_snapshot_trinket = true,  -- Flag for DoT sync logic
            sound = "raid_warning",  -- Loud sound like other important procs
            big_alert = true,
            alert_text = "DFO ACTIVE!",
            alert_subtext = "Refresh Corruption!",
            alert_color = {0, 1, 0.8},  -- Cyan-green
            priority = 1,
        },
        {
            name = "CTS Proc",
            group = "trinket_procs",
            unit = "player",
            type = "buff",
            spell = "Twilight Flames",  -- Charred Twilight Scale
            glow = true,
            sound = "map_ping",
            priority = 2,
        },

        -- ==================== FILLER SPELLS ====================
        -- Show suggested filler when DoTs stable and CDs used
        {
            name = "Shadow Bolt Filler",
            group = "fillers",
            unit = "player",
            type = "filler",
            spell = "Shadow Bolt",
            requires_spec = "AFFLI",
            glow = true,
            priority = 1,
        },
        {
            name = "Incinerate Filler",
            group = "fillers",
            unit = "player",
            type = "filler",
            spell = "Incinerate",
            requires_spec = "DEMO",
            glow = true,
            priority = 2,
        },

        -- ==================== PROCS ====================
        -- Decimation and Molten Core show icons when active + big center alert
        -- Using icon_spell = spell name that warlock KNOWS (GetSpellInfo will return texture)
        {
            name = "Decimation",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Decimation",
            icon_spell = "Soul Fire",  -- Use Soul Fire's icon (all warlocks know it)
            glow = true,
            sound = "raid_warning",
            big_alert = true,
            alert_text = "DECIMATION!",
            alert_subtext = "Cast Soul Fire!",
            alert_color = {1, 0.4, 0},  -- Orange
            -- Removed requires_spell - proc only shows when active anyway
            priority = 1,
        },
        {
            name = "Molten Core",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Molten Core",
            icon_spell = "Incinerate",  -- Use Incinerate's icon (all warlocks know it)
            glow = true,
            sound = "raid_warning",
            show_stacks = true,
            big_alert = true,
            alert_text = "MOLTEN CORE!",
            alert_subtext = "Incinerate or Soul Fire!",
            alert_color = {1, 0.5, 0},  -- Orange
            -- Removed requires_spell - proc only shows when active anyway
            priority = 2,
        },
        {
            name = "Shadow Trance",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Shadow Trance",
            icon_spell = "Shadow Bolt",  -- Use Shadow Bolt's icon (all warlocks know it)
            glow = true,
            sound = "raid_warning",
            big_alert = true,
            alert_text = "NIGHTFALL!",
            alert_subtext = "Instant Shadow Bolt!",
            alert_color = {0.6, 0.2, 1},  -- Purple
            priority = 3,
        },
        {
            name = "Shadow Mastery",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Shadow Mastery",
            icon_spell = "Corruption",  -- Use Corruption's icon (all warlocks know it)
            priority = 4,
        },
        -- ==================== AFFLICTION SNAPSHOT PROCS ====================
        -- Track spell power procs for recasting Corruption with higher damage
        {
            name = "Eradication",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Eradication",
            show_stacks = true,
            priority = 5,
        },
        {
            name = "Surge of Power",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Surge of Power",  -- Dying Curse trinket
            glow = true,
            priority = 6,
        },
        {
            name = "Illustrious",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Illustrious",  -- Illustration of the Dragon Soul
            show_stacks = true,
            glow_at_stacks = 8,  -- Glow when >= 8 stacks (recast Corruption!)
            priority = 7,
        },
        {
            name = "Now is the Time!",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Now is the Time!",  -- Sundial of the Exiled
            glow = true,
            priority = 8,
        },
        {
            name = "Abyssal Power",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Abyssal Power",  -- Abyssal Rune trinket
            glow = true,
            priority = 9,
        },

        -- ==================== RAID BUFFS (show when missing or < 10 min) ====================
        -- Smart tracking: only shows if required class is in raid
        -- Paladin blessings: limited by number of paladins in raid
        -- All raid buffs use hide_when_healthy with refresh_warn = 600 (10 min)
        {
            name = "Gift of the Wild",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spells = {"Gift of the Wild", "Mark of the Wild"},
            icon_spell = "Thorns",  -- Druid spell all druids know
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            required_class = "DRUID",
            priority = 1,
        },
        {
            name = "Intellect",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Mage buffs only (Fel Intelligence tracked separately in Spirit)
            spells = {"Arcane Brilliance", "Arcane Intellect", "Dalaran Brilliance"},
            icon_spell = "Fel Intelligence",  -- Warlock pet spell we can use
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            required_class = "MAGE",
            priority = 2,
        },
        {
            name = "Blessing of Kings",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Also includes Drums of Forgotten Kings (Leatherworking)
            spells = {"Greater Blessing of Kings", "Blessing of Kings", "Drums of the Forgotten Kings"},
            item_id = 49634,  -- Drums of Forgotten Kings (item exists in game)
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            required_class = "PALADIN",
            is_paladin_blessing = true,
            blessing_priority = 1,
            priority = 3,
        },
        {
            name = "Blessing of Wisdom",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Also includes Mana Spring Totem effect
            spells = {"Greater Blessing of Wisdom", "Blessing of Wisdom", "Mana Spring"},
            icon_spell = "Life Tap",  -- Warlock spell with blue/mana icon
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            required_class = "PALADIN",
            is_paladin_blessing = true,
            blessing_priority = 2,
            priority = 4,
        },
        {
            name = "Blessing of Sanctuary",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spells = {"Greater Blessing of Sanctuary", "Blessing of Sanctuary"},
            icon_spell = "Demon Armor",  -- Warlock spell with armor icon
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            required_class = "PALADIN",
            is_paladin_blessing = true,
            blessing_priority = 3,
            priority = 5,
        },
        {
            name = "Spirit",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Priest buffs OR Fel Intelligence - they provide spirit
            spells = {"Prayer of Spirit", "Divine Spirit", "Fel Intelligence"},
            icon_spell = "Fel Intelligence",  -- Warlock pet spell
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            -- No required_class - can come from Priest OR Warlock pet
            priority = 7,
        },
        {
            name = "Stamina",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Priest buffs OR Blood Pact (Imp) OR Commanding Shout (Warrior)
            spells = {"Prayer of Fortitude", "Power Word: Fortitude", "Blood Pact", "Commanding Shout"},
            icon_spell = "Blood Pact",  -- Imp spell warlocks have
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            -- No required_class - multiple sources
            priority = 8,
        },
        {
            name = "Flask",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spells = {"Flask of the Frost Wyrm", "Flask of Pure Mojo", "Flask of Endless Rage", "Flask of Stoneblood"},
            item_id = 46376,  -- Flask of the Frost Wyrm (item exists)
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            priority = 9,
        },
        {
            name = "Well Fed",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spell = "Well Fed",
            item_id = 43015,  -- Fish Feast (item exists)
            show_missing = true,
            refresh_warn = 600,
            hide_when_healthy = true,
            in_group_only = false,
            priority = 10,
        },

        -- ==================== PET BUFFS (Demonology) ====================
        {
            name = "Pet Food",
            group = "raid_buffs",
            unit = "pet",
            type = "buff",
            spells = {"Well Fed", "Kibler's Bits", "Sporeling Snack"},
            show_missing = true,
            in_group_only = false,
            requires_pet = "Felguard",  -- Only show for Felguard (Demo)
            priority = 11,
        },
        {
            name = "Pet Scroll",
            group = "raid_buffs",
            unit = "pet",
            type = "buff",
            spells = {"Strength", "Stamina", "Agility"},  -- Scroll buff names
            show_missing = true,
            in_group_only = false,
            requires_pet = "Felguard",
            priority = 12,
        },
    },

    -- Weapon enchant tracking
    weapon_enchants = {
        {
            name = "Grand Spellstone",
            slot = "main",
            enchant = "Grand Spellstone",
            item_id = 41196,  -- Grand Spellstone item
            group = "self_buffs",
            show_missing = true,
            refresh_warn = 600,  -- 10 minutes
            hide_when_healthy = true,  -- Only show when missing or < 10 min remaining
            priority = 10,
        },
    },

    positions = {},  -- Saved positions for groups
}

-- Deep copy helper
local function DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

-- Deep merge helper
local function DeepMerge(default, override)
    if type(default) ~= "table" or type(override) ~= "table" then
        return override ~= nil and override or default
    end

    local result = DeepCopy(default)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = DeepMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Parse YAML-like config string
function DoroxAurasConfig:ParseConfig(configStr)
    local config = {groups = {}, auras = {}}
    local lines = {}
    for line in configStr:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local currentSection = nil
    local currentGroup = nil
    local currentAura = nil
    local indentStack = {}

    for _, line in ipairs(lines) do
        -- Skip comments and empty lines
        local trimmed = line:gsub("#.*$", ""):match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            -- Count leading spaces
            local indent = #(line:match("^(%s*)") or "")
            local level = math.floor(indent / 2)

            -- Parse key: value
            local key, value = trimmed:match("^([%w_]+):%s*(.*)$")

            if key then
                -- Handle sections
                if key == "groups" then
                    currentSection = "groups"
                elseif key == "auras" then
                    currentSection = "auras"
                    if currentAura then
                        table.insert(config.auras, currentAura)
                        currentAura = nil
                    end
                elseif currentSection == "groups" and level == 1 then
                    currentGroup = key
                    config.groups[currentGroup] = {}
                elseif currentSection == "groups" and level == 2 and currentGroup then
                    -- Parse value
                    if value == "true" then value = true
                    elseif value == "false" then value = false
                    elseif tonumber(value) then value = tonumber(value)
                    end
                    config.groups[currentGroup][key] = value
                elseif currentSection == "auras" and currentAura then
                    -- Parse array syntax [a, b, c]
                    if value:match("^%[.*%]$") then
                        local arr = {}
                        for item in value:gmatch("[^%[%],]+") do
                            item = item:match("^%s*(.-)%s*$")
                            if item ~= "" then
                                table.insert(arr, item)
                            end
                        end
                        value = arr
                    elseif value == "true" then value = true
                    elseif value == "false" then value = false
                    elseif tonumber(value) then value = tonumber(value)
                    end
                    currentAura[key] = value
                end
            else
                -- Check for list item "- name: value"
                local listStart = trimmed:match("^%-%s*(.+)$")
                if listStart and currentSection == "auras" then
                    if currentAura then
                        table.insert(config.auras, currentAura)
                    end
                    currentAura = {}
                    local lk, lv = listStart:match("^([%w_]+):%s*(.*)$")
                    if lk then
                        currentAura[lk] = lv
                    end
                end
            end
        end
    end

    -- Don't forget last aura
    if currentAura then
        table.insert(config.auras, currentAura)
    end

    return config
end

-- Initialize database
function DoroxAurasConfig:InitializeDB()
    if not DoroxAurasDB then
        DoroxAurasDB = DeepCopy(defaults)
    else
        -- Merge with defaults for new fields
        DoroxAurasDB = DeepMerge(defaults, DoroxAurasDB)
    end
end

-- Get current config
function DoroxAurasConfig:GetConfig()
    if not DoroxAurasDB then
        self:InitializeDB()
    end
    return DoroxAurasDB
end

-- Get auras for a specific unit
function DoroxAurasConfig:GetAurasForUnit(unit)
    local config = self:GetConfig()
    local result = {}
    for _, aura in ipairs(config.auras) do
        if aura.unit == unit then
            table.insert(result, aura)
        end
    end
    return result
end

-- Get group config
function DoroxAurasConfig:GetGroupConfig(groupName)
    local config = self:GetConfig()
    return config.groups[groupName]
end

-- Save position for a group
function DoroxAurasConfig:SavePosition(groupName, point, relPoint, x, y)
    local config = self:GetConfig()
    config.positions[groupName] = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
    }
end

-- Get saved position for a group
function DoroxAurasConfig:GetPosition(groupName)
    local config = self:GetConfig()
    return config.positions[groupName]
end

-- Reset to defaults
function DoroxAurasConfig:ResetDefaults()
    DoroxAurasDB = DeepCopy(defaults)
end

-- Add/update an aura
function DoroxAurasConfig:SetAura(auraConfig)
    local config = self:GetConfig()

    -- Find existing aura by name
    for i, aura in ipairs(config.auras) do
        if aura.name == auraConfig.name then
            config.auras[i] = auraConfig
            return
        end
    end

    -- Add new aura
    table.insert(config.auras, auraConfig)
end

-- Remove an aura
function DoroxAurasConfig:RemoveAura(auraName)
    local config = self:GetConfig()
    for i, aura in ipairs(config.auras) do
        if aura.name == auraName then
            table.remove(config.auras, i)
            return true
        end
    end
    return false
end

-- Export config to YAML-like string
function DoroxAurasConfig:ExportConfig()
    local config = self:GetConfig()
    local lines = {"# DoroxAuras Configuration", "# Edit and /da reload to apply", ""}

    -- Export groups
    table.insert(lines, "groups:")
    for name, group in pairs(config.groups) do
        table.insert(lines, "  " .. name .. ":")
        for k, v in pairs(group) do
            table.insert(lines, "    " .. k .. ": " .. tostring(v))
        end
    end

    table.insert(lines, "")
    table.insert(lines, "auras:")

    -- Export auras
    for _, aura in ipairs(config.auras) do
        table.insert(lines, "  - name: " .. aura.name)
        for k, v in pairs(aura) do
            if k ~= "name" then
                if type(v) == "table" then
                    table.insert(lines, "    " .. k .. ": [" .. table.concat(v, ", ") .. "]")
                else
                    table.insert(lines, "    " .. k .. ": " .. tostring(v))
                end
            end
        end
    end

    return table.concat(lines, "\n")
end
