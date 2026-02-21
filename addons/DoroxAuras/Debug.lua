-- Debug.lua - Debug mode for capturing aura data in dungeons
DoroxAurasDebug = {}

local debugEnabled = false
local debugLog = {}
local sessionStart = nil
local maxLogEntries = 5000  -- Prevent memory issues

-- Get timestamp string
local function GetTimestamp()
    local now = GetTime()
    if sessionStart then
        return string.format("%.2f", now - sessionStart)
    end
    return string.format("%.2f", now)
end

-- Get zone info
local function GetZoneInfo()
    local zone = GetRealZoneText() or "Unknown"
    local subzone = GetSubZoneText() or ""
    local instanceName, instanceType, difficultyID = GetInstanceInfo()
    return {
        zone = zone,
        subzone = subzone,
        instance = instanceName,
        instanceType = instanceType,
        difficulty = difficultyID,
    }
end

-- Check if debug is enabled
function DoroxAurasDebug:IsEnabled()
    return debugEnabled
end

-- Toggle debug mode
function DoroxAurasDebug:Toggle()
    debugEnabled = not debugEnabled

    if debugEnabled then
        sessionStart = GetTime()
        debugLog = {}

        -- Log session start
        local zoneInfo = GetZoneInfo()
        self:Log("SESSION", "start", {
            timestamp = date("%Y-%m-%d %H:%M:%S"),
            zone = zoneInfo.zone,
            instance = zoneInfo.instance,
            difficulty = zoneInfo.difficulty,
            playerClass = select(2, UnitClass("player")),
            playerLevel = UnitLevel("player"),
        })

        print("|cff00FF00[DoroxAuras Debug]|r Enabled - logging all aura activity")
        print("  Zone: " .. zoneInfo.zone .. (zoneInfo.subzone ~= "" and " - " .. zoneInfo.subzone or ""))
        print("  Use |cffFFFF00/da debugstop|r to stop and save data")
        print("  Use |cffFFFF00/da debugshow|r to view log summary")
        print("  Use |cffFFFF00/da debugexport|r to export log")
    else
        self:Log("SESSION", "end", {
            timestamp = date("%Y-%m-%d %H:%M:%S"),
            totalEntries = #debugLog,
        })

        -- Save to SavedVariables
        local config = DoroxAurasConfig:GetConfig()
        config.debugLog = debugLog
        config.lastDebugSession = date("%Y-%m-%d %H:%M:%S")

        print("|cff00FF00[DoroxAuras Debug]|r Disabled - " .. #debugLog .. " entries logged")
        print("  Data saved to SavedVariables")
        print("  Use |cffFFFF00/da debugexport|r to view")
    end
end

-- Log an event
function DoroxAurasDebug:Log(category, event, data)
    if not debugEnabled then return end
    if #debugLog >= maxLogEntries then return end  -- Prevent overflow

    local entry = {
        t = GetTimestamp(),
        cat = category,
        evt = event,
        data = data,
    }

    table.insert(debugLog, entry)
end

-- Log aura scan result
function DoroxAurasDebug:LogAuraScan(unit, auraConfig, found, icon, remaining, stacks)
    if not debugEnabled then return end

    self:Log("SCAN", found and "found" or "missing", {
        unit = unit,
        name = auraConfig.name,
        spell = auraConfig.spell or (auraConfig.spells and table.concat(auraConfig.spells, ",")),
        type = auraConfig.type,
        group = auraConfig.group,
        found = found,
        icon = icon,
        remaining = remaining and string.format("%.1f", remaining),
        stacks = stacks,
    })
end

-- Log all buffs/debuffs on a unit
function DoroxAurasDebug:LogAllAuras(unit)
    if not debugEnabled then return end
    if not UnitExists(unit) then return end

    local unitName = UnitName(unit) or unit

    -- Log buffs
    local buffs = {}
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitBuff(unit, i)
        if not name then break end

        table.insert(buffs, {
            name = name,
            icon = icon,
            stacks = count,
            duration = duration,
            remaining = expirationTime and (expirationTime - GetTime()) or nil,
            caster = caster,
        })
    end

    -- Log debuffs
    local debuffs = {}
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff(unit, i)
        if not name then break end

        table.insert(debuffs, {
            name = name,
            icon = icon,
            stacks = count,
            duration = duration,
            remaining = expirationTime and (expirationTime - GetTime()) or nil,
            caster = caster,
            debuffType = debuffType,
        })
    end

    if #buffs > 0 or #debuffs > 0 then
        self:Log("UNIT_AURAS", unit, {
            unitName = unitName,
            buffCount = #buffs,
            debuffCount = #debuffs,
            buffs = buffs,
            debuffs = debuffs,
        })
    end
end

-- Log raid composition
function DoroxAurasDebug:LogRaidComposition()
    if not debugEnabled then return end

    local composition = {}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()

    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, _, _, class = GetRaidRosterInfo(i)
            if name and class then
                composition[class] = (composition[class] or 0) + 1
            end
        end
    elseif numParty > 0 then
        local _, myClass = UnitClass("player")
        composition[myClass] = 1
        for i = 1, numParty do
            local _, class = UnitClass("party" .. i)
            if class then
                composition[class] = (composition[class] or 0) + 1
            end
        end
    end

    self:Log("RAID", "composition", {
        size = numRaid > 0 and numRaid or (numParty + 1),
        isRaid = numRaid > 0,
        classes = composition,
    })
end

-- Log icon lookup
function DoroxAurasDebug:LogIconLookup(spellName, icon, fromCache)
    if not debugEnabled then return end

    self:Log("ICON", fromCache and "cache_hit" or "lookup", {
        spell = spellName,
        icon = icon,
        missing = icon == "Interface\\Icons\\INV_Misc_QuestionMark",
    })
end

-- Log condition check
function DoroxAurasDebug:LogConditionCheck(auraConfig, result, reason)
    if not debugEnabled then return end

    self:Log("CONDITION", result and "pass" or "fail", {
        name = auraConfig.name,
        result = result,
        reason = reason,
        requires_talent = auraConfig.requires_talent,
        requires_pet = auraConfig.requires_pet,
        required_class = auraConfig.required_class,
        in_raid_only = auraConfig.in_raid_only,
    })
end

-- Show debug summary
function DoroxAurasDebug:ShowSummary()
    local log = debugEnabled and debugLog or (DoroxAurasConfig:GetConfig().debugLog or {})

    if #log == 0 then
        print("|cffFF0000[DoroxAuras Debug]|r No debug data available")
        print("  Use |cffFFFF00/da debug|r to start logging")
        return
    end

    print("|cff00FF00[DoroxAuras Debug]|r Summary (" .. #log .. " entries)")

    -- Count by category
    local categories = {}
    local missingIcons = {}
    local missingSpells = {}

    for _, entry in ipairs(log) do
        categories[entry.cat] = (categories[entry.cat] or 0) + 1

        -- Track missing icons
        if entry.cat == "ICON" and entry.data and entry.data.missing then
            missingIcons[entry.data.spell] = true
        end

        -- Track missing spells
        if entry.cat == "SCAN" and entry.evt == "missing" and entry.data then
            local key = entry.data.name
            missingSpells[key] = (missingSpells[key] or 0) + 1
        end
    end

    -- Print categories
    print("  Categories:")
    for cat, count in pairs(categories) do
        print("    " .. cat .. ": " .. count)
    end

    -- Print missing icons
    if next(missingIcons) then
        print("  |cffFF0000Missing Icons:|r")
        for spell, _ in pairs(missingIcons) do
            print("    - " .. spell)
        end
    end

    -- Print frequently missing spells
    local sorted = {}
    for name, count in pairs(missingSpells) do
        if count > 5 then
            table.insert(sorted, {name = name, count = count})
        end
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    if #sorted > 0 then
        print("  |cffFFFF00Frequently Missing (top 10):|r")
        for i = 1, math.min(10, #sorted) do
            print("    - " .. sorted[i].name .. ": " .. sorted[i].count .. "x")
        end
    end
end

-- Export debug log
function DoroxAurasDebug:Export()
    local log = debugEnabled and debugLog or (DoroxAurasConfig:GetConfig().debugLog or {})

    if #log == 0 then
        print("|cffFF0000[DoroxAuras Debug]|r No debug data to export")
        return
    end

    print("|cff00FF00[DoroxAuras Debug]|r Exporting " .. #log .. " entries...")
    print("Data is saved in: WTF/Account/YOUR_ACCOUNT/SavedVariables/DoroxAuras.lua")
    print("Search for 'debugLog' to find the data")
    print("")
    print("To share, copy the debugLog section from SavedVariables")

    -- Print compact summary for chat
    print("")
    print("=== Quick Summary ===")

    -- Find session info
    for _, entry in ipairs(log) do
        if entry.cat == "SESSION" and entry.evt == "start" and entry.data then
            print("Session: " .. (entry.data.timestamp or "?"))
            print("Zone: " .. (entry.data.zone or "?"))
            print("Instance: " .. (entry.data.instance or "none"))
            break
        end
    end

    self:ShowSummary()
end

-- Clear debug log
function DoroxAurasDebug:Clear()
    debugLog = {}
    local config = DoroxAurasConfig:GetConfig()
    config.debugLog = nil
    config.lastDebugSession = nil
    print("|cff00FF00[DoroxAuras Debug]|r Log cleared")
end

-- Get log for external access
function DoroxAurasDebug:GetLog()
    return debugEnabled and debugLog or (DoroxAurasConfig:GetConfig().debugLog or {})
end
