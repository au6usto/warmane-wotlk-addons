-- Core.lua - Main addon initialization and event handling
local ADDON_NAME = "DoroxAuras"
DoroxAuras = {}

local eventFrame = CreateFrame("Frame")
local isInitialized = false
local inCombat = false

-- Initialize the addon
function DoroxAuras:Initialize()
    if isInitialized then return end

    -- Initialize config
    DoroxAurasConfig:InitializeDB()

    -- Initialize display (create group containers)
    DoroxAurasDisplay:Initialize()

    -- Initialize trackers
    DoroxAurasTrackers:Initialize()

    -- Initial update
    DoroxAurasTrackers:UpdateAll()

    -- Initialize boss mods
    DoroxAurasBossMods:Initialize()

    -- Initialize cast bar and target HP tracker (with safety check)
    if DoroxAurasCastBar then
        DoroxAurasCastBar:Initialize()
    else
        print("|cffFF0000[DoroxAuras]|r Warning: CastBar module failed to load!")
    end

    isInitialized = true
    print("|cff00FF00[DoroxAuras]|r v1.2 loaded! Type |cffFFFF00/da help|r for commands")
end

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        DoroxAuras:Initialize()

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Delayed update after zone change
        C_Timer.After(0.5, function()
            DoroxAurasTrackers:UpdateAll()
        end)

    elseif event == "UNIT_AURA" then
        if arg1 == "player" then
            DoroxAurasTrackers:UpdateUnit("player")
        elseif arg1 == "target" then
            DoroxAurasTrackers:UpdateUnit("target")
        elseif arg1 == "focus" then
            DoroxAurasTrackers:UpdateUnit("focus")
        elseif arg1 == "pet" then
            DoroxAurasTrackers:UpdateUnit("pet")
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        DoroxAurasTrackers:UpdateUnit("target")

    elseif event == "PLAYER_FOCUS_CHANGED" then
        DoroxAurasTrackers:UpdateUnit("focus")

    elseif event == "UNIT_PET" and arg1 == "player" then
        DoroxAurasTrackers:UpdateUnit("pet")

    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        DoroxAurasTrackers:UpdateWeaponEnchants()

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        -- Force update when entering combat
        DoroxAurasTrackers:UpdateAll()

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        -- Check if we should hide out of combat
        local config = DoroxAurasConfig:GetConfig()
        if not config.showOutOfCombat then
            DoroxAurasTrackers:ClearAll()
        else
            DoroxAurasTrackers:UpdateAll()
        end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then
        -- Update raid buff checks
        DoroxAurasTrackers:UpdateUnit("player")

        -- Log raid composition if debug enabled
        if DoroxAurasDebug and DoroxAurasDebug:IsEnabled() then
            DoroxAurasDebug:LogRaidComposition()
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Track Demonic Circle: Summon
        if arg1 == "player" then
            local spellName = ...
            if spellName == "Demonic Circle: Summon" then
                DoroxAurasTrackers:OnDemonicCircleSummoned()
            end
        end

    elseif event == "BAG_UPDATE" then
        -- Update special auras (healthstone, etc.)
        DoroxAurasTrackers:UpdateSpecialAuras()

    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        -- Reset Demonic Circle on zone change
        DoroxAurasTrackers:UpdateSpecialAuras()
    end
end)

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Slash commands
SLASH_DOROXAURAS1 = "/da"
SLASH_DOROXAURAS2 = "/doroxauras"

SlashCmdList["DOROXAURAS"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "" or cmd == "help" then
        print("|cff00FF00[DoroxAuras]|r Commands:")
        print("  |cffFFFF00/da toggle|r - Enable/disable addon")
        print("  |cffFFFF00/da lock|r - Lock frame positions")
        print("  |cffFFFF00/da unlock|r - Unlock frames for moving")
        print("  |cffFFFF00/da reset|r - Reset positions to defaults")
        print("  |cffFFFF00/da reload|r - Reload configuration")
        print("  |cffFFFF00/da test|r - Test mode (show all icons)")
        print("  |cffFFFF00/da export|r - Export config to chat")
        print("  |cffFFFF00/da list|r - List configured auras")
        print("  |cffFFFF00/da add <spell>|r - Add a new aura to track")
        print("  |cffFFFF00/da remove <name>|r - Remove an aura")
        print("|cff00FF00[Boss Mods]|r")
        print("  |cffFFFF00/da boss|r - Show current boss")
        print("  |cffFFFF00/da boss <name>|r - Set boss manually (for testing)")
        print("  |cffFFFF00/da bosses|r - List all supported bosses")
        print("  |cffFFFF00/da testboss|r - Test boss alert display")
        print("|cff00FF00[Cast Bar & Execute]|r")
        print("  |cffFFFF00/da testcast|r - Test cast bar & target HP display")
        print("  |cffFFFF00/da spec|r - Show detected spec (Demo/Affli/Destro)")
        print("  |cffFFFF00/da dummy|r - Toggle dummy mode (always show HP bar)")
        print("|cff00FF00[Debug Mode]|r")
        print("  |cffFFFF00/da debug|r - Toggle debug logging")
        print("  |cffFFFF00/da debugstop|r - Stop debug and save")
        print("  |cffFFFF00/da debugshow|r - Show debug summary")
        print("  |cffFFFF00/da debugexport|r - Export debug log")
        print("  |cffFFFF00/da debugclear|r - Clear debug log")
        print("  |cffFFFF00/da debugauras|r - Dump all current auras on target")

    elseif cmd == "toggle" then
        local config = DoroxAurasConfig:GetConfig()
        config.enabled = not config.enabled

        if config.enabled then
            print("|cff00FF00[DoroxAuras]|r Enabled")
            DoroxAurasTrackers:UpdateAll()
        else
            print("|cff00FF00[DoroxAuras]|r Disabled")
            DoroxAurasTrackers:ClearAll()
        end

    elseif cmd == "lock" then
        DoroxAurasDisplay:Lock()
        if DoroxAurasCastBar then DoroxAurasCastBar:Lock() end

    elseif cmd == "unlock" then
        DoroxAurasDisplay:Unlock()
        if DoroxAurasCastBar then DoroxAurasCastBar:Unlock() end

    elseif cmd == "reset" then
        DoroxAurasDisplay:ResetPositions()

    elseif cmd == "reload" then
        -- Re-initialize trackers with current config
        DoroxAurasTrackers:Initialize()
        DoroxAurasTrackers:UpdateAll()
        print("|cff00FF00[DoroxAuras]|r Configuration reloaded")

    elseif cmd == "test" then
        DoroxAurasDisplay:TestMode()

    elseif cmd == "export" then
        local config = DoroxAurasConfig:ExportConfig()
        print("|cff00FF00[DoroxAuras]|r Config exported (see below):")
        -- Split into lines for readability
        for line in config:gmatch("[^\n]+") do
            print("  " .. line)
        end

    elseif cmd == "list" then
        local config = DoroxAurasConfig:GetConfig()
        print("|cff00FF00[DoroxAuras]|r Configured auras:")

        -- Group by group name
        local grouped = {}
        for _, aura in ipairs(config.auras) do
            local group = aura.group or "unknown"
            if not grouped[group] then
                grouped[group] = {}
            end
            table.insert(grouped[group], aura)
        end

        for groupName, auras in pairs(grouped) do
            print("  |cffFFFF00" .. groupName .. "|r:")
            for _, aura in ipairs(auras) do
                local spell = aura.spell or (aura.spells and table.concat(aura.spells, "/")) or "?"
                print("    - " .. aura.name .. " (" .. spell .. ")")
            end
        end

    elseif cmd == "add" and arg ~= "" then
        -- Quick add aura
        local spellName = arg

        -- Check if spell exists
        local name, _, icon = GetSpellInfo(spellName)
        if not name then
            print("|cffFF0000[DoroxAuras]|r Spell not found: " .. spellName)
            return
        end

        -- Determine type based on unit
        local auraConfig = {
            name = name,
            group = "target_debuffs",
            unit = "target",
            type = "debuff",
            own = true,
            spell = name,
            priority = 50,
        }

        DoroxAurasConfig:SetAura(auraConfig)
        DoroxAurasTrackers:Initialize()
        DoroxAurasTrackers:UpdateAll()

        print("|cff00FF00[DoroxAuras]|r Added: " .. name .. " (target debuff)")
        print("  Edit Config.lua to customize group, unit, type, etc.")

    elseif cmd == "remove" and arg ~= "" then
        local success = DoroxAurasConfig:RemoveAura(arg)
        if success then
            DoroxAurasTrackers:Initialize()
            DoroxAurasTrackers:UpdateAll()
            print("|cff00FF00[DoroxAuras]|r Removed: " .. arg)
        else
            print("|cffFF0000[DoroxAuras]|r Aura not found: " .. arg)
        end

    elseif cmd == "boss" then
        if arg and arg ~= "" then
            DoroxAurasBossMods:SetBoss(arg)
        else
            local currentBoss = DoroxAurasBossMods:GetCurrentBoss()
            if currentBoss and currentBoss ~= "" then
                print("|cff00FF00[DoroxAuras]|r Current boss: " .. currentBoss)
            else
                print("|cff00FF00[DoroxAuras]|r No boss detected")
            end
        end

    elseif cmd == "bosses" then
        DoroxAurasBossMods:ListBosses()

    elseif cmd == "testboss" then
        -- Test boss alert
        local testAlert = {
            name = "Test Alert",
            message = "TEST ALERT! This is how boss warnings look!",
            sound = "raid_warning",
            glow = true,
            flash = true,
            color = "orange",
            action_spell = "Shadow Ward",
            duration = 5,
        }
        DoroxAurasBossMods:ShowAlert(testAlert, "Interface\\Icons\\Spell_Shadow_AntiShadow")
        DoroxAurasBossMods:ShowArrow(45, "RUN THIS WAY!")
        C_Timer.After(5, function()
            DoroxAurasBossMods:HideArrow()
        end)

    elseif cmd == "testcast" then
        -- Test cast bar and target HP
        DoroxAurasCastBar:Test()

    elseif cmd == "spec" then
        local spec = DoroxAurasCastBar:GetSpec()
        local specNames = {
            DEMO = "Demonology (Soul Fire at 35%)",
            AFFLI = "Affliction (Drain Soul at 25%)",
            DESTRO = "Destruction",
        }
        print("|cff00FF00[DoroxAuras]|r Detected spec: " .. (specNames[spec] or spec))

    elseif cmd == "dummy" then
        if DoroxAurasCastBar then
            DoroxAurasCastBar:ToggleDummyMode()
        end

    elseif cmd == "debug" then
        if DoroxAurasDebug then
            DoroxAurasDebug:Toggle()
        end

    elseif cmd == "debugstop" then
        if DoroxAurasDebug and DoroxAurasDebug:IsEnabled() then
            DoroxAurasDebug:Toggle()  -- Toggle off to save
        else
            print("|cffFF0000[DoroxAuras]|r Debug mode is not running")
        end

    elseif cmd == "debugshow" then
        if DoroxAurasDebug then
            DoroxAurasDebug:ShowSummary()
        end

    elseif cmd == "debugexport" then
        if DoroxAurasDebug then
            DoroxAurasDebug:Export()
        end

    elseif cmd == "debugclear" then
        if DoroxAurasDebug then
            DoroxAurasDebug:Clear()
        end

    elseif cmd == "debugauras" then
        -- Dump all auras on target or player for debugging
        local unit = (arg ~= "" and arg) or "target"
        if unit == "self" or unit == "me" then unit = "player" end

        if not UnitExists(unit) then
            print("|cffFF0000[DoroxAuras]|r Unit not found: " .. unit)
            print("  Usage: /da debugauras [target|player|pet|focus]")
        else
            local unitName = UnitName(unit)
            print("|cff00FF00[DoroxAuras]|r Auras on " .. unitName .. " (" .. unit .. "):")

            print("  |cffFFFF00Buffs:|r")
            for i = 1, 40 do
                local name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitBuff(unit, i)
                if not name then break end
                local remaining = expirationTime and (expirationTime - GetTime()) or 0
                local stackStr = count and count > 0 and (" x" .. count) or ""
                print("    " .. i .. ". " .. name .. stackStr .. " (" .. string.format("%.1f", remaining) .. "s) caster:" .. (caster or "?"))
            end

            print("  |cffFFFF00Debuffs:|r")
            for i = 1, 40 do
                local name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff(unit, i)
                if not name then break end
                local remaining = expirationTime and (expirationTime - GetTime()) or 0
                local stackStr = count and count > 0 and (" x" .. count) or ""
                print("    " .. i .. ". " .. name .. stackStr .. " (" .. string.format("%.1f", remaining) .. "s) caster:" .. (caster or "?"))
            end

            -- Also log to debug if enabled
            if DoroxAurasDebug and DoroxAurasDebug:IsEnabled() then
                DoroxAurasDebug:LogAllAuras(unit)
            end
        end

    else
        print("|cffFF0000[DoroxAuras]|r Unknown command: " .. cmd)
        print("Type |cffFFFF00/da help|r for available commands")
    end
end

-- Public API
function DoroxAuras:IsEnabled()
    local config = DoroxAurasConfig:GetConfig()
    return config.enabled
end

function DoroxAuras:IsInCombat()
    return inCombat
end

function DoroxAuras:Refresh()
    DoroxAurasTrackers:UpdateAll()
end

-- C_Timer polyfill for WotLK (if not available)
if not C_Timer then
    C_Timer = {}
    function C_Timer.After(delay, callback)
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                callback()
            end
        end)
    end
end
