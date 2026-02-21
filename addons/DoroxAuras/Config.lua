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
            refresh_warn = 600,
            priority = 1,
        },
        {
            name = "Life Tap",
            group = "self_buffs",
            unit = "player",
            type = "buff",
            spell = "Life Tap",
            show_missing = true,
            refresh_warn = 5,
            glow_on_missing = true,
            priority = 2,
        },
        {
            name = "Soul Link",
            group = "self_buffs",
            unit = "player",
            type = "buff",
            spell = "Soul Link",
            show_missing = true,
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
            name = "Immolation Aura",
            group = "self_buffs",
            unit = "player",
            type = "buff",
            spell = "Immolation Aura",
            requires_talent = "Metamorphosis",  -- Demonology 51-point talent
            priority = 5,
        },

        -- ==================== PROCS ====================
        {
            name = "Decimation",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Decimation",
            glow = true,
            sound = "raid_warning",
            priority = 1,
        },
        {
            name = "Molten Core",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Molten Core",
            glow = true,
            sound = "map_ping",
            show_stacks = true,
            priority = 2,
        },
        {
            name = "Shadow Trance",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Shadow Trance",
            glow = true,
            sound = "raid_warning",
            priority = 3,
        },
        {
            name = "Shadow Mastery",
            group = "procs",
            unit = "player",
            type = "buff",
            spell = "Shadow Mastery",
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

        -- ==================== RAID BUFFS (show when missing) ====================
        -- Smart tracking: only shows if required class is in raid
        -- Paladin blessings: limited by number of paladins in raid
        {
            name = "Gift of the Wild",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spells = {"Gift of the Wild", "Mark of the Wild"},
            show_missing = true,
            in_raid_only = true,
            required_class = "DRUID",
            priority = 1,
        },
        {
            name = "Intellect",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Mage buffs OR Fel Intelligence (Felhunter) - they don't stack
            spells = {"Arcane Brilliance", "Arcane Intellect", "Dalaran Brilliance", "Fel Intelligence"},
            show_missing = true,
            in_raid_only = true,
            -- No required_class - can come from Mage OR Warlock pet
            priority = 2,
        },
        {
            name = "Blessing of Kings",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Also includes Drums of Forgotten Kings (Leatherworking)
            spells = {"Greater Blessing of Kings", "Blessing of Kings", "Drums of the Forgotten Kings"},
            show_missing = true,
            in_raid_only = true,
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
            show_missing = true,
            in_raid_only = true,
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
            show_missing = true,
            in_raid_only = true,
            required_class = "PALADIN",
            is_paladin_blessing = true,
            blessing_priority = 3,
            priority = 5,
        },
        {
            name = "Fel Intelligence",
            group = "self_buffs",
            unit = "player",
            type = "buff",
            spell = "Fel Intelligence",
            show_missing = true,
            requires_pet = "Felhunter",
            priority = 6,
        },
        {
            name = "Spirit",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            -- Priest buffs OR Fel Intelligence - they provide spirit
            spells = {"Prayer of Spirit", "Divine Spirit", "Fel Intelligence"},
            show_missing = true,
            in_raid_only = true,
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
            show_missing = true,
            in_raid_only = true,
            -- No required_class - multiple sources
            priority = 8,
        },
        {
            name = "Flask",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spells = {"Flask of the Frost Wyrm", "Flask of Pure Mojo", "Flask of Endless Rage", "Flask of Stoneblood"},
            show_missing = true,
            in_raid_only = true,
            priority = 9,
        },
        {
            name = "Well Fed",
            group = "raid_buffs",
            unit = "player",
            type = "buff",
            spell = "Well Fed",
            show_missing = true,
            in_raid_only = true,
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
            in_raid_only = true,
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
            in_raid_only = true,
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
            group = "self_buffs",
            show_missing = true,
            refresh_warn = 600,
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
