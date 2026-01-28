--[[
    DoroxChatFilter - WotLK 3.3.5a Addon
    Smart raid finder with category highlighting
    Author: Dorox @ Lordaeron
]]

DoroxChatFilterDB = DoroxChatFilterDB or {}

-- Default settings
local defaults = {
    enabled = true,
    playSound = true,
    showOnlyMatches = false,

    -- Colors (hex without |cff prefix)
    colors = {
        raids = "FF6600",      -- Orange for raid names
        size = "FFFF00",       -- Yellow for size/mode
        role = "00FFFF",       -- Cyan for role/class
        personal = "FF00FF",   -- Magenta for personal alerts
        background = "B0B0B0", -- Light gray for message background
    },

    -- Keywords by category
    raids = {
        "ICC", "RS", "VOA",
        "ICECROWN", "RUBY SANCTUM", "VAULT",
        "HALION", "TORAVON", "LK", "LICH KING",
    },

    -- Compound patterns (raid+size together like "icc10", "icc10nm", etc.)
    raidCompounds = {
        -- Basic
        "ICC10", "ICC25", "RS10", "RS25", "VOA10", "VOA25",
        "ICC 10", "ICC 25", "RS 10", "RS 25", "VOA 10", "VOA 25",
        -- Normal mode variants
        "ICC10N", "ICC25N", "RS10N", "RS25N", "VOA10N", "VOA25N",
        "ICC10NM", "ICC25NM", "RS10NM", "RS25NM", "VOA10NM", "VOA25NM",
        -- Heroic mode variants
        "ICC10H", "ICC25H", "RS10H", "RS25H", "VOA10H", "VOA25H",
        "ICC10HC", "ICC25HC", "RS10HC", "RS25HC", "VOA10HC", "VOA25HC",
        "ICC10HM", "ICC25HM", "RS10HM", "RS25HM",
    },

    sizes = {
        "10", "25", "10N", "25N", "10H", "25H",
        "10 MAN", "25 MAN", "NORMAL", "HEROIC",
        "ST", "SERVER TIME",
    },

    -- Roles that indicate they want ranged/caster DPS
    wantedRoles = {
        "RDPS", "CDPS", "CASTER", "RANGED", "CLOTH",
        "SPELLCASTER", "DPS", "ALL", "ANY",
    },

    -- Personal alert keywords (when in raid)
    personalAlerts = {
        "DOROX", "TV", "SUMM", "SUMMON", "SUMMONING",
        "TABLE", "SOUL", "SOULWELL", "HEALTHSTONE",
    },

    -- Exclusion keywords (messages containing these will be ignored)
    exclusions = {
        "REP FARM", "REPFARM", "REPUTATION FARM",
    },

    -- Ignored raid configurations (raid+size combos you don't want to see)
    -- Format: { ["ICC25"] = true, ["RS10"] = true }
    ignoredRaidConfigs = {
        ["ICC25"] = true,  -- Ignore all ICC 25 (normal and heroic)
    },

    -- Lockout awareness setting
    checkLockouts = true,
}

-- Map addon keywords to WoW instance names for lockout checking
local instanceNameMap = {
    ["ICC"] = "Icecrown Citadel",
    ["ICECROWN"] = "Icecrown Citadel",
    ["LK"] = "Icecrown Citadel",
    ["LICH KING"] = "Icecrown Citadel",
    ["RS"] = "The Ruby Sanctum",
    ["RUBY SANCTUM"] = "The Ruby Sanctum",
    ["HALION"] = "The Ruby Sanctum",
    ["VOA"] = "Vault of Archavon",
    ["VAULT"] = "Vault of Archavon",
    ["TORAVON"] = "Vault of Archavon",
}

-- Initialize saved variables (deep merge to add new defaults)
local function InitializeDB()
    for key, value in pairs(defaults) do
        if DoroxChatFilterDB[key] == nil then
            if type(value) == "table" then
                DoroxChatFilterDB[key] = {}
                for k, v in pairs(value) do
                    DoroxChatFilterDB[key][k] = v
                end
            else
                DoroxChatFilterDB[key] = value
            end
        elseif type(value) == "table" then
            -- Merge missing keys into existing tables (e.g., new colors)
            for k, v in pairs(value) do
                if DoroxChatFilterDB[key][k] == nil then
                    DoroxChatFilterDB[key][k] = v
                end
            end
        end
    end
end

-- Helper: Strip hyperlinks from text for pattern matching (preserves the visible text)
local function StripHyperlinks(text)
    -- Remove full hyperlink structure but keep display text: |c...|H...|h[text]|h|r -> text
    local stripped = text:gsub("|c%x%x%x%x%x%x%x%x|H.-|h%[(.-)%]|h|r", "%1")
    -- Remove standalone color codes
    stripped = stripped:gsub("|c%x%x%x%x%x%x%x%x", "")
    stripped = stripped:gsub("|r", "")
    -- Remove texture codes |T...|t
    stripped = stripped:gsub("|T.-|t", "")
    return stripped
end

-- Helper: Check if text contains any keyword from a list (case insensitive)
-- Strips hyperlinks before matching to avoid false positives from link metadata
local function ContainsAny(text, keywords)
    local stripped = StripHyperlinks(text)
    local upperText = stripped:upper()
    for _, keyword in ipairs(keywords) do
        -- Use word boundary matching
        local pattern = "%f[%w]" .. keyword:upper():gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%f[%W]"
        if upperText:match(pattern) then
            return true, keyword
        end
    end
    return false, nil
end

-- Helper: Check if text contains any role keyword (allows number prefix like "2rdps")
-- Strips hyperlinks before matching
local function ContainsRole(text, keywords)
    local stripped = StripHyperlinks(text)
    local upperText = stripped:upper()
    for _, keyword in ipairs(keywords) do
        local escapedKeyword = keyword:upper():gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        -- Match with optional digit prefix (e.g., "2rdps", "3dps")
        local pattern = "%f[%w]%d*" .. escapedKeyword .. "%f[%W]"
        if upperText:match(pattern) then
            return true, keyword
        end
    end
    return false, nil
end

-- Helper: Find all keywords from a list in text
-- Strips hyperlinks before matching
local function FindAllKeywords(text, keywords)
    local found = {}
    local stripped = StripHyperlinks(text)
    local upperText = stripped:upper()
    for _, keyword in ipairs(keywords) do
        local pattern = "%f[%w]" .. keyword:upper():gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%f[%W]"
        if upperText:match(pattern) then
            table.insert(found, keyword)
        end
    end
    return found
end

-- Helper: Find all role keywords in text (with optional number prefix)
-- Strips hyperlinks before matching
local function FindAllRoles(text, keywords)
    local found = {}
    local stripped = StripHyperlinks(text)
    local upperText = stripped:upper()
    for _, keyword in ipairs(keywords) do
        local escapedKeyword = keyword:upper():gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        local pattern = "%f[%w]%d*" .. escapedKeyword .. "%f[%W]"
        if upperText:match(pattern) then
            table.insert(found, keyword)
        end
    end
    return found
end

-- Special pattern characters that need escaping (NOT digits)
local PATTERN_SPECIAL = "([%(%)%.%%%+%-%*%?%[%]%^%$])"

-- Helper: Safely highlight text while preserving hyperlinks
-- Extracts hyperlinks, applies highlighting to non-link text, then restores links
local function SafeHighlight(text, highlightFunc)
    local links = {}
    local placeholder = "\001LINK%d\001"
    local counter = 0

    -- Extract all hyperlinks and replace with placeholders
    local protected = text:gsub("(|c%x%x%x%x%x%x%x%x|H.-|h%[.-%]|h|r)", function(link)
        counter = counter + 1
        links[counter] = link
        return placeholder:format(counter)
    end)

    -- Apply highlighting to the protected text
    local highlighted = highlightFunc(protected)

    -- Restore hyperlinks
    highlighted = highlighted:gsub("\001LINK(%d+)\001", function(num)
        return links[tonumber(num)] or ""
    end)

    return highlighted
end

-- Helper: Highlight a role keyword with optional number prefix (e.g., "2rdps" -> colored "2rdps")
local function HighlightRole(text, keyword, color)
    -- Build case-insensitive pattern with optional digit prefix
    local pattern = "(%f[%w])(%d*)("
    for char in keyword:gmatch(".") do
        if char:match("%a") then
            pattern = pattern .. "[" .. char:upper() .. char:lower() .. "]"
        elseif char:match("%d") then
            pattern = pattern .. char
        else
            pattern = pattern .. "%" .. char
        end
    end
    pattern = pattern .. ")(%f[%W])"

    local replacement = "%1|cff" .. color .. "%2%3|r%4"
    return text:gsub(pattern, replacement)
end

-- Helper: Highlight a keyword in text with color
local function HighlightWord(text, keyword, color)
    -- Create case-insensitive pattern
    local pattern = "(%f[%w])("
    for char in keyword:gmatch(".") do
        if char:match("%a") then
            -- Letters: make case-insensitive
            pattern = pattern .. "[" .. char:upper() .. char:lower() .. "]"
        elseif char == " " then
            -- Spaces: match one or more whitespace
            pattern = pattern .. "%s+"
        elseif char:match("%d") then
            -- Digits: use as-is (no escaping needed)
            pattern = pattern .. char
        else
            -- Special characters: escape them
            pattern = pattern .. "%" .. char
        end
    end
    pattern = pattern .. ")(%f[%W])"

    local replacement = "%1|cff" .. color .. "%2|r%3"
    return text:gsub(pattern, replacement)
end

-- Check if player is in a raid
local function IsInRaid()
    return UnitInRaid("player") ~= nil or GetNumRaidMembers() > 0
end

-- Check if player is in a party
local function IsInGroup()
    return IsInRaid() or GetNumPartyMembers() > 0
end

-- Check if player has lockout for specific raid/size/difficulty
-- WotLK difficulty IDs: 1=10N, 2=25N, 3=10H, 4=25H
local function HasRaidLockout(raidKeyword, size, isHeroic)
    local instanceName = instanceNameMap[raidKeyword:upper()]
    if not instanceName then return false end

    local targetDifficulty
    if size == 10 then
        targetDifficulty = isHeroic and 3 or 1
    else -- size == 25
        targetDifficulty = isHeroic and 4 or 2
    end

    local numSaved = GetNumSavedInstances()
    for i = 1, numSaved do
        local name, _, _, difficulty, locked = GetSavedInstanceInfo(i)
        if name == instanceName and difficulty == targetDifficulty and locked then
            return true
        end
    end
    return false
end

-- Extract raid info from message (returns raidKeyword, size, isHeroic)
local function ParseRaidFromMessage(msg)
    local upperMsg = msg:upper()
    local raidKeyword = nil
    local size = nil
    local isHeroic = false

    -- Check compound patterns first (e.g., ICC25H)
    for _, compound in ipairs(DoroxChatFilterDB.raidCompounds) do
        local escapedCompound = compound:upper():gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        if upperMsg:match("%f[%w]" .. escapedCompound .. "%f[%W]") then
            raidKeyword = compound:match("^(%a+)")
            size = tonumber(compound:match("(%d+)"))
            isHeroic = compound:upper():match("[H][CM]?$") ~= nil
            return raidKeyword, size, isHeroic
        end
    end

    -- Check standalone raid names
    for _, raid in ipairs(DoroxChatFilterDB.raids) do
        local escapedRaid = raid:upper():gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        if upperMsg:match("%f[%w]" .. escapedRaid .. "%f[%W]") then
            raidKeyword = raid
            break
        end
    end

    if not raidKeyword then return nil, nil, false end

    -- Parse size from message
    if upperMsg:match("%f[%w]25%f[%W]") or upperMsg:match("25[%s%-]*MAN") then
        size = 25
    elseif upperMsg:match("%f[%w]10%f[%W]") or upperMsg:match("10[%s%-]*MAN") then
        size = 10
    end

    -- Parse heroic from message
    if upperMsg:match("HEROIC") or upperMsg:match("%d+H[CM]?%f[%W]") then
        isHeroic = true
    end

    return raidKeyword, size, isHeroic
end

-- Sound cooldown system (prevents sound spam)
local lastRaidSoundTime = 0
local lastPersonalSoundTime = 0
local SOUND_COOLDOWN = 3 -- seconds

local function PlayRaidSound()
    local now = GetTime()
    if now - lastRaidSoundTime >= SOUND_COOLDOWN then
        PlaySoundFile("Sound\\Interface\\MapPing.wav")
        lastRaidSoundTime = now
    end
end

local function PlayPersonalSound()
    local now = GetTime()
    if now - lastPersonalSoundTime >= SOUND_COOLDOWN then
        PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
        lastPersonalSoundTime = now
    end
end

-- Helper: Highlight compound raid+size (e.g., "icc10" -> colored "icc" + colored "10")
local function HighlightCompound(text, compound, raidColor, sizeColor)
    -- Extract raid part and size part from compound
    local raidPart = compound:match("^(%a+)")
    local sizePart = compound:match("(%d+%a*)$")

    if not raidPart or not sizePart then return text end

    -- Build case-insensitive pattern for the compound
    local pattern = "(%f[%w])("
    for char in raidPart:gmatch(".") do
        pattern = pattern .. "[" .. char:upper() .. char:lower() .. "]"
    end
    -- Handle optional space between raid and size
    pattern = pattern .. "%s*"
    for char in sizePart:gmatch(".") do
        if char:match("%a") then
            pattern = pattern .. "[" .. char:upper() .. char:lower() .. "]"
        else
            pattern = pattern .. char
        end
    end
    pattern = pattern .. ")(%f[%W])"

    -- Build colored replacement
    local coloredRaid = "|cff" .. raidColor .. raidPart:upper() .. "|r"
    local coloredSize = "|cff" .. sizeColor .. sizePart:upper() .. "|r"

    -- Use gsub with function to preserve original case structure
    local result = text:gsub(pattern, function(pre, match, post)
        local r = match:match("^(%a+)")
        local s = match:match("(%d+%a*)$")
        return pre .. "|cff" .. raidColor .. r .. "|r|cff" .. sizeColor .. s .. "|r" .. post
    end)

    return result
end

-- Process LFM raid messages
local function ProcessRaidMessage(msg)
    local upperMsg = msg:upper()

    -- Must contain LFM or similar
    local hasLFM = upperMsg:match("%f[%w]LFM%f[%W]") or
                   upperMsg:match("%f[%w]LF%d+M%f[%W]") or
                   upperMsg:match("LOOKING FOR") or
                   upperMsg:match("NEED MORE")

    if not hasLFM then
        return nil, false
    end

    -- Check for exclusion keywords (e.g., REP FARM)
    local hasExclusion = ContainsAny(msg, DoroxChatFilterDB.exclusions)
    if hasExclusion then
        return nil, false
    end

    -- Check for compound raid names first (icc10, rs25, etc.)
    local hasCompound = ContainsAny(msg, DoroxChatFilterDB.raidCompounds)

    -- Must contain a raid name (standalone or compound)
    local hasRaid = hasCompound or ContainsAny(msg, DoroxChatFilterDB.raids)
    if not hasRaid then
        return nil, false
    end

    -- Must want RDPS/Caster/ALL or similar (allows number prefix like "2rdps")
    local hasRole = ContainsRole(msg, DoroxChatFilterDB.wantedRoles)
    if not hasRole then
        return nil, false
    end

    -- Check if this raid configuration is ignored (e.g., ICC25)
    local raidKeyword, size, isHeroic = ParseRaidFromMessage(msg)
    if raidKeyword and size and DoroxChatFilterDB.ignoredRaidConfigs then
        local configKey = raidKeyword:upper() .. tostring(size)
        if DoroxChatFilterDB.ignoredRaidConfigs[configKey] then
            return nil, false  -- Ignored raid config, skip
        end
    end

    -- Check if player is locked to this raid (skip highlighting if locked)
    if DoroxChatFilterDB.checkLockouts then
        if raidKeyword and size then
            if HasRaidLockout(raidKeyword, size, isHeroic) then
                return nil, false  -- Return as non-match (shows as normal chat)
            end
        end
    end

    -- All conditions met - highlight the message while preserving hyperlinks
    local newMsg = SafeHighlight(msg, function(text)
        local result = text

        -- First, highlight compound raid+size patterns (e.g., "icc10")
        local foundCompounds = FindAllKeywords(msg, DoroxChatFilterDB.raidCompounds)
        for _, compound in ipairs(foundCompounds) do
            result = HighlightCompound(result, compound, DoroxChatFilterDB.colors.raids, DoroxChatFilterDB.colors.size)
        end

        -- Highlight standalone raid names (Orange) - only if not part of compound
        local foundRaids = FindAllKeywords(msg, DoroxChatFilterDB.raids)
        for _, raid in ipairs(foundRaids) do
            -- Check if this raid is NOT already colored (part of a compound)
            if not result:match("|cff" .. DoroxChatFilterDB.colors.raids .. raid) then
                result = HighlightWord(result, raid, DoroxChatFilterDB.colors.raids)
            end
        end

        -- Highlight standalone sizes (Yellow) - only if not part of compound
        local foundSizes = FindAllKeywords(msg, DoroxChatFilterDB.sizes)
        for _, size in ipairs(foundSizes) do
            result = HighlightWord(result, size, DoroxChatFilterDB.colors.size)
        end

        -- Highlight time patterns like "19:00" or "19:00 ST" (Yellow)
        result = result:gsub("(%d%d?):(%d%d)", "|cff" .. DoroxChatFilterDB.colors.size .. "%1:%2|r")

        -- Highlight roles (Cyan) - includes number prefixes like "2rdps"
        local foundRoles = FindAllRoles(msg, DoroxChatFilterDB.wantedRoles)
        for _, role in ipairs(foundRoles) do
            result = HighlightRole(result, role, DoroxChatFilterDB.colors.role)
        end

        return result
    end)

    -- Apply light gray background to entire message
    newMsg = "|cff" .. DoroxChatFilterDB.colors.background .. "[|r" .. newMsg .. "|cff" .. DoroxChatFilterDB.colors.background .. "]|r"

    return newMsg, true
end

-- Process personal alert messages (when in raid/party)
local function ProcessPersonalAlert(msg)
    if not IsInGroup() then
        return nil, false
    end

    local hasPersonal, keyword = ContainsAny(msg, DoroxChatFilterDB.personalAlerts)
    if not hasPersonal then
        return nil, false
    end

    -- Highlight all personal keywords while preserving hyperlinks
    local newMsg = SafeHighlight(msg, function(text)
        local result = text
        local foundPersonal = FindAllKeywords(msg, DoroxChatFilterDB.personalAlerts)
        for _, word in ipairs(foundPersonal) do
            result = HighlightWord(result, word, DoroxChatFilterDB.colors.personal)
        end
        return result
    end)

    return newMsg, true
end

-- Events where personal alerts should trigger (raid/party only)
local personalAlertEvents = {
    ["CHAT_MSG_RAID"] = true,
    ["CHAT_MSG_RAID_LEADER"] = true,
    ["CHAT_MSG_RAID_WARNING"] = true,
    ["CHAT_MSG_PARTY"] = true,
    ["CHAT_MSG_PARTY_LEADER"] = true,
    ["CHAT_MSG_WHISPER"] = true,
}

-- Main filter function
local function FilterChatMessage(self, event, msg, author, ...)
    if not DoroxChatFilterDB.enabled then
        return false, msg, author, ...
    end

    local newMsg = nil
    local isRaidMatch = false
    local isPersonalMatch = false

    -- Check for personal alerts ONLY in raid/party/whisper chat
    if personalAlertEvents[event] and IsInGroup() then
        newMsg, isPersonalMatch = ProcessPersonalAlert(msg)

        if isPersonalMatch then
            -- Play personal alert sound (with cooldown)
            if DoroxChatFilterDB.playSound then
                PlayPersonalSound()
            end
            -- Add personal alert icon
            newMsg = "|cffFF00FF>>>|r " .. newMsg .. " |cffFF00FF<<<|r"
            return false, newMsg, author, ...
        end
    end

    -- Check for raid LFM messages (in any channel)
    newMsg, isRaidMatch = ProcessRaidMessage(msg)

    if isRaidMatch then
        -- Play raid match sound (with cooldown)
        if DoroxChatFilterDB.playSound then
            PlayRaidSound()
        end
        -- Message already has gray brackets from ProcessRaidMessage
        return false, newMsg, author, ...
    end

    -- No match - check if we should hide or show
    if DoroxChatFilterDB.showOnlyMatches then
        return true -- Hide message
    end

    return false, msg, author, ...
end

-- Hook into chat frames
local function HookChatFrames()
    local chatEvents = {
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_YELL",
        "CHAT_MSG_SAY",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_WHISPER",
    }

    for _, event in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(event, FilterChatMessage)
    end
end

-- Slash commands
local function HandleSlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "" or cmd == "help" then
        print("|cff00FF00[DoroxChatFilter]|r Commands:")
        print("  /dcf toggle - Enable/disable addon")
        print("  /dcf sound - Toggle sound notifications")
        print("  /dcf filter - Toggle show only matching messages")
        print("  /dcf lockout - Toggle lockout awareness (skip highlighting for saved raids)")
        print("  /dcf colors - Show current colors")
        print("  /dcf color <category> <hex> - Set color (raids/size/role/personal)")
        print("  /dcf addraid <keyword> - Add raid keyword")
        print("  /dcf addrole <keyword> - Add role keyword")
        print("  /dcf addpersonal <keyword> - Add personal alert keyword")
        print("  /dcf addexclude <keyword> - Add exclusion keyword (e.g., REP FARM)")
        print("  /dcf ignore <raid><size> - Ignore a raid config (e.g., ICC25, RS10)")
        print("  /dcf unignore <raid><size> - Stop ignoring a raid config")
        print("  /dcf list - List all keywords")
        print("  /dcf test - Test with sample message")
        print("  /dcf reset - Reset to defaults")
        print("  /dcf status - Show current settings")

    elseif cmd == "toggle" then
        DoroxChatFilterDB.enabled = not DoroxChatFilterDB.enabled
        print("|cff00FF00[DoroxChatFilter]|r " .. (DoroxChatFilterDB.enabled and "Enabled" or "Disabled"))

    elseif cmd == "sound" then
        DoroxChatFilterDB.playSound = not DoroxChatFilterDB.playSound
        print("|cff00FF00[DoroxChatFilter]|r Sound: " .. (DoroxChatFilterDB.playSound and "On" or "Off"))

    elseif cmd == "filter" then
        DoroxChatFilterDB.showOnlyMatches = not DoroxChatFilterDB.showOnlyMatches
        print("|cff00FF00[DoroxChatFilter]|r Show only matches: " .. (DoroxChatFilterDB.showOnlyMatches and "On" or "Off"))

    elseif cmd == "lockout" then
        DoroxChatFilterDB.checkLockouts = not DoroxChatFilterDB.checkLockouts
        print("|cff00FF00[DoroxChatFilter]|r Lockout awareness: " .. (DoroxChatFilterDB.checkLockouts and "On" or "Off"))

    elseif cmd == "colors" then
        print("|cff00FF00[DoroxChatFilter]|r Current colors:")
        print("  Raids: |cff" .. DoroxChatFilterDB.colors.raids .. DoroxChatFilterDB.colors.raids .. "|r")
        print("  Size: |cff" .. DoroxChatFilterDB.colors.size .. DoroxChatFilterDB.colors.size .. "|r")
        print("  Role: |cff" .. DoroxChatFilterDB.colors.role .. DoroxChatFilterDB.colors.role .. "|r")
        print("  Personal: |cff" .. DoroxChatFilterDB.colors.personal .. DoroxChatFilterDB.colors.personal .. "|r")

    elseif cmd == "color" then
        local category, hex = arg:match("^(%S+)%s+(%x%x%x%x%x%x)$")
        if category and hex and DoroxChatFilterDB.colors[category] then
            DoroxChatFilterDB.colors[category] = hex:upper()
            print("|cff00FF00[DoroxChatFilter]|r " .. category .. " color set to: |cff" .. hex .. hex .. "|r")
        else
            print("|cff00FF00[DoroxChatFilter]|r Usage: /dcf color <raids|size|role|personal> <hex>")
        end

    elseif cmd == "addraid" then
        if arg ~= "" then
            table.insert(DoroxChatFilterDB.raids, arg:upper())
            print("|cff00FF00[DoroxChatFilter]|r Added raid keyword: |cff" .. DoroxChatFilterDB.colors.raids .. arg .. "|r")
        end

    elseif cmd == "addrole" then
        if arg ~= "" then
            table.insert(DoroxChatFilterDB.wantedRoles, arg:upper())
            print("|cff00FF00[DoroxChatFilter]|r Added role keyword: |cff" .. DoroxChatFilterDB.colors.role .. arg .. "|r")
        end

    elseif cmd == "addpersonal" then
        if arg ~= "" then
            table.insert(DoroxChatFilterDB.personalAlerts, arg:upper())
            print("|cff00FF00[DoroxChatFilter]|r Added personal keyword: |cff" .. DoroxChatFilterDB.colors.personal .. arg .. "|r")
        end

    elseif cmd == "addexclude" then
        if arg ~= "" then
            table.insert(DoroxChatFilterDB.exclusions, arg:upper())
            print("|cff00FF00[DoroxChatFilter]|r Added exclusion keyword: |cffFF0000" .. arg .. "|r")
        end

    elseif cmd == "ignore" then
        if arg ~= "" then
            local configKey = arg:upper()
            DoroxChatFilterDB.ignoredRaidConfigs = DoroxChatFilterDB.ignoredRaidConfigs or {}
            DoroxChatFilterDB.ignoredRaidConfigs[configKey] = true
            print("|cff00FF00[DoroxChatFilter]|r Now ignoring: |cffFF0000" .. configKey .. "|r")
        else
            print("|cff00FF00[DoroxChatFilter]|r Usage: /dcf ignore <raid><size> (e.g., ICC25, RS10)")
        end

    elseif cmd == "unignore" then
        if arg ~= "" then
            local configKey = arg:upper()
            if DoroxChatFilterDB.ignoredRaidConfigs and DoroxChatFilterDB.ignoredRaidConfigs[configKey] then
                DoroxChatFilterDB.ignoredRaidConfigs[configKey] = nil
                print("|cff00FF00[DoroxChatFilter]|r No longer ignoring: |cff00FF00" .. configKey .. "|r")
            else
                print("|cff00FF00[DoroxChatFilter]|r " .. configKey .. " was not in the ignore list")
            end
        else
            print("|cff00FF00[DoroxChatFilter]|r Usage: /dcf unignore <raid><size> (e.g., ICC25, RS10)")
        end

    elseif cmd == "list" then
        print("|cff00FF00[DoroxChatFilter]|r Keywords:")
        print("|cff" .. DoroxChatFilterDB.colors.raids .. "Raids:|r " .. table.concat(DoroxChatFilterDB.raids, ", "))
        print("|cff" .. DoroxChatFilterDB.colors.size .. "Sizes:|r " .. table.concat(DoroxChatFilterDB.sizes, ", "))
        print("|cff" .. DoroxChatFilterDB.colors.role .. "Roles:|r " .. table.concat(DoroxChatFilterDB.wantedRoles, ", "))
        print("|cff" .. DoroxChatFilterDB.colors.personal .. "Personal:|r " .. table.concat(DoroxChatFilterDB.personalAlerts, ", "))
        print("|cffFF0000Exclusions:|r " .. table.concat(DoroxChatFilterDB.exclusions, ", "))
        -- List ignored raid configs
        local ignoredList = {}
        if DoroxChatFilterDB.ignoredRaidConfigs then
            for config, _ in pairs(DoroxChatFilterDB.ignoredRaidConfigs) do
                table.insert(ignoredList, config)
            end
        end
        print("|cffFF6666Ignored Raids:|r " .. (#ignoredList > 0 and table.concat(ignoredList, ", ") or "None"))

    elseif cmd == "test" then
        print("|cff00FF00[DoroxChatFilter]|r Test messages:")
        local testMsg1 = "LFM ICC 25N need RDPS and healers"
        local result1, matched1 = ProcessRaidMessage(testMsg1)
        print("  Input: " .. testMsg1)
        print("  Output: " .. (result1 or "NO MATCH"))

        local testMsg2 = "* lfm icc10 lk only id rdps, mdps, rsham 19:00 ST"
        local result2, matched2 = ProcessRaidMessage(testMsg2)
        print("  Input: " .. testMsg2)
        print("  Output: " .. (result2 or "NO MATCH"))

        local testMsg3 = "LFM RS 25N need all dps"
        local result3, matched3 = ProcessRaidMessage(testMsg3)
        print("  Input: " .. testMsg3)
        print("  Output: " .. (result3 or "NO MATCH"))

        local testMsg4 = "LFM ICC10nm -- aim BPC and weekley quest -- 1Bdk 1Ppal 1hpal 1rsham 2rdps 1mdps"
        local result4, matched4 = ProcessRaidMessage(testMsg4)
        print("  Input: " .. testMsg4)
        print("  Output: " .. (result4 or "NO MATCH"))

        -- Test with achievement link (simulated)
        local testMsg5 = "LFM ICC25 need rdps |cffffff00|Hachievement:4530|h[The Frozen Throne]|h|r"
        local result5, matched5 = ProcessRaidMessage(testMsg5)
        print("  Input: " .. testMsg5)
        print("  Output: " .. (result5 or "NO MATCH"))

        -- Test exclusion (REP FARM)
        local testMsg6 = "LFM ICC25 REP FARM need all dps"
        local result6, matched6 = ProcessRaidMessage(testMsg6)
        print("  Input: " .. testMsg6)
        print("  Output: " .. (result6 or "NO MATCH (excluded)"))

        -- Test ignored raid config (ICC25)
        local testMsg7 = "LFM ICC25H need rdps"
        local result7, matched7 = ProcessRaidMessage(testMsg7)
        print("  Input: " .. testMsg7)
        local ignoredNote = (DoroxChatFilterDB.ignoredRaidConfigs and DoroxChatFilterDB.ignoredRaidConfigs["ICC25"]) and " (ICC25 ignored)" or ""
        print("  Output: " .. (result7 or "NO MATCH" .. ignoredNote))

    elseif cmd == "reset" then
        DoroxChatFilterDB = {}
        InitializeDB()
        print("|cff00FF00[DoroxChatFilter]|r Reset to defaults")

    elseif cmd == "status" then
        print("|cff00FF00[DoroxChatFilter]|r Status:")
        print("  Enabled: " .. (DoroxChatFilterDB.enabled and "Yes" or "No"))
        print("  Sound: " .. (DoroxChatFilterDB.playSound and "On" or "Off"))
        print("  Filter mode: " .. (DoroxChatFilterDB.showOnlyMatches and "Show only matches" or "Show all"))
        print("  Lockout awareness: " .. (DoroxChatFilterDB.checkLockouts and "On" or "Off"))
        print("  Saved instances: " .. GetNumSavedInstances())
        print("  In group: " .. (IsInGroup() and "Yes" or "No"))
        print("  Raids: " .. #DoroxChatFilterDB.raids .. " keywords")
        print("  Roles: " .. #DoroxChatFilterDB.wantedRoles .. " keywords")
        print("  Personal: " .. #DoroxChatFilterDB.personalAlerts .. " keywords")
        -- Count ignored raid configs
        local ignoredCount = 0
        if DoroxChatFilterDB.ignoredRaidConfigs then
            for _ in pairs(DoroxChatFilterDB.ignoredRaidConfigs) do
                ignoredCount = ignoredCount + 1
            end
        end
        print("  Ignored raids: " .. ignoredCount .. " configs")
    else
        print("|cff00FF00[DoroxChatFilter]|r Unknown command. Type /dcf help")
    end
end

-- Register slash commands
SLASH_DOROXCHATFILTER1 = "/dcf"
SLASH_DOROXCHATFILTER2 = "/doroxchat"
SlashCmdList["DOROXCHATFILTER"] = HandleSlashCommand

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "DoroxChatFilter" then
        InitializeDB()
        HookChatFrames()
        print("|cff00FF00[DoroxChatFilter]|r Loaded! Filtering: LFM + Raid + RDPS/Caster/ALL")
        print("|cff00FF00[DoroxChatFilter]|r Type /dcf help for commands")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
