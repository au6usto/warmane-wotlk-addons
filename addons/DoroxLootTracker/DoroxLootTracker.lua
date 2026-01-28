--[[
    DoroxLootTracker - WotLK 3.3.5a Addon
    Tracks and alerts for desired raid loot drops
    Author: Dorox @ Lordaeron
]]

DoroxLootTrackerDB = DoroxLootTrackerDB or {}

-- Tracked items from warlock-upgrades.md
local trackedItems = {
    -- Priority 1: Off-Hand (Current: 232)
    { name = "Sundial of Eternal Dusk", slot = "Off-Hand", ilvl = 264, source = "Sindragosa ICC25N", priority = 1 },
    { name = "Shadow Silk Spindle", slot = "Off-Hand", ilvl = 264, source = "Blood Princes ICC25N", priority = 1 },
    { name = "Nightmare Ender", slot = "Off-Hand", ilvl = 251, source = "Sindragosa ICC10N", priority = 1 },

    -- Priority 2: Wrists (Current: 245)
    { name = "Bracers of Fiery Night", slot = "Wrists", ilvl = 271, source = "Halion RS25N", priority = 2 },
    { name = "The Lady's Brittle Bracers", slot = "Wrists", ilvl = 264, source = "Lady Deathwhisper ICC25N", priority = 2 },
    { name = "Bracers of Dark Blessings", slot = "Wrists", ilvl = 251, source = "Gunship ICC10N", priority = 2 },

    -- Priority 3: Neck (Current: 245)
    { name = "Amulet of the Silent Eulogy", slot = "Neck", ilvl = 264, source = "Gunship ICC25N", priority = 3 },
    { name = "Blood Queen's Crimson Choker", slot = "Neck", ilvl = 264, source = "Lana'thel ICC25N", priority = 3 },

    -- Priority 4: Main Hand (Current: 251)
    { name = "Bloodsurge, Kel'Thuzad's Blade of Agony", slot = "Main Hand", ilvl = 264, source = "Lich King ICC25N", priority = 4 },
    { name = "Rigormortis", slot = "Main Hand", ilvl = 264, source = "Rotface ICC25N", priority = 4 },
    { name = "Frozen Bonespike", slot = "Main Hand", ilvl = 264, source = "Marrowgar ICC25N", priority = 4 },

    -- Priority 5: Trinket (Current: 271 - Charred Twilight Scale obtained!)
    { name = "Phylactery of the Nameless Lich", slot = "Trinket", ilvl = 264, source = "Sindragosa ICC25N", priority = 5 },

    -- Priority 6: Ring (Current: 251)
    { name = "Ring of Rapid Ascent", slot = "Ring", ilvl = 264, source = "Gunship ICC25N", priority = 6 },
    { name = "Memory of Malygos", slot = "Ring", ilvl = 264, source = "Sindragosa ICC25N", priority = 6 },
    { name = "Signet of Twilight", slot = "Ring", ilvl = 271, source = "Halion RS25N", priority = 6 },

    -- Priority 7: Tier Token
    { name = "Conqueror's Mark of Sanctification", slot = "Token", ilvl = 264, source = "ICC25N Bosses", priority = 7 },
}

-- Default settings
local defaults = {
    enabled = true,
    soundEnabled = true,
    chatEnabled = true,
    frameShown = true,
    framePosition = { point = "RIGHT", relPoint = "RIGHT", x = -50, y = 0 },
    obtainedItems = {},
}

-- Colors
local COLORS = {
    title = "FFD700",      -- Gold
    priority1 = "FF0000",  -- Red (highest priority)
    priority2 = "FF6600",  -- Orange
    priority3 = "FFFF00",  -- Yellow
    priority4 = "00FF00",  -- Green
    priority5 = "00FFFF",  -- Cyan
    priority6 = "0088FF",  -- Blue
    priority7 = "AA00FF",  -- Purple
    obtained = "666666",   -- Gray
    source = "AAAAAA",     -- Light gray
    alert = "FF0000",      -- Red
}

-- Get color for priority
local function GetPriorityColor(priority)
    return COLORS["priority" .. priority] or "FFFFFF"
end

-- Initialize saved variables
local function InitializeDB()
    for key, value in pairs(defaults) do
        if DoroxLootTrackerDB[key] == nil then
            if type(value) == "table" then
                DoroxLootTrackerDB[key] = {}
                for k, v in pairs(value) do
                    DoroxLootTrackerDB[key][k] = v
                end
            else
                DoroxLootTrackerDB[key] = value
            end
        end
    end
end

-- Sound cooldown
local lastSoundTime = 0
local SOUND_COOLDOWN = 2

local function PlayAlertSound()
    local now = GetTime()
    if now - lastSoundTime >= SOUND_COOLDOWN then
        PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
        lastSoundTime = now
    end
end

-- Check if item is tracked
local function IsTrackedItem(itemName)
    for _, item in ipairs(trackedItems) do
        if itemName:lower():find(item.name:lower(), 1, true) then
            return true, item
        end
    end
    return false, nil
end

-- Check if item is obtained
local function IsObtained(itemName)
    return DoroxLootTrackerDB.obtainedItems[itemName] == true
end

-- Toggle obtained status
local function ToggleObtained(itemName)
    if DoroxLootTrackerDB.obtainedItems[itemName] then
        DoroxLootTrackerDB.obtainedItems[itemName] = nil
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r " .. itemName .. " marked as |cffFF0000NOT obtained|r")
    else
        DoroxLootTrackerDB.obtainedItems[itemName] = true
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r " .. itemName .. " marked as |cff00FF00obtained|r")
    end
end

-- Create main frame
local trackerFrame = CreateFrame("Frame", "DoroxLootTrackerFrame", UIParent)
trackerFrame:SetWidth(220)
trackerFrame:SetHeight(400)
trackerFrame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
trackerFrame:SetMovable(true)
trackerFrame:EnableMouse(true)
trackerFrame:RegisterForDrag("LeftButton")
trackerFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
trackerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    DoroxLootTrackerDB.framePosition = { point = point, relPoint = relPoint, x = x, y = y }
end)

-- Background
trackerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
trackerFrame:SetBackdropColor(0, 0, 0, 0.8)

-- Title
local title = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", trackerFrame, "TOP", 0, -10)
title:SetText("|cff" .. COLORS.title .. "Loot Tracker|r")

-- Close button
local closeBtn = CreateFrame("Button", nil, trackerFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function()
    trackerFrame:Hide()
    DoroxLootTrackerDB.frameShown = false
end)

-- Scroll frame for items
local scrollFrame = CreateFrame("ScrollFrame", "DoroxLootTrackerScrollFrame", trackerFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 8, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", trackerFrame, "BOTTOMRIGHT", -28, 8)

-- Content frame
local contentFrame = CreateFrame("Frame", nil, scrollFrame)
contentFrame:SetWidth(180)
contentFrame:SetHeight(1) -- Will be updated
scrollFrame:SetScrollChild(contentFrame)

-- Item buttons storage
local itemButtons = {}

-- Create item list
local function CreateItemList()
    -- Clear existing buttons
    for _, btn in ipairs(itemButtons) do
        btn:Hide()
    end
    itemButtons = {}

    local yOffset = 0
    local currentPriority = 0

    for _, item in ipairs(trackedItems) do
        -- Priority header
        if item.priority ~= currentPriority then
            currentPriority = item.priority
            local header = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -yOffset)
            header:SetText("|cff" .. GetPriorityColor(currentPriority) .. "Priority " .. currentPriority .. " - " .. item.slot .. "|r")
            yOffset = yOffset + 16
        end

        -- Item button
        local btn = CreateFrame("Button", nil, contentFrame)
        btn:SetWidth(180)
        btn:SetHeight(28)
        btn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -yOffset)

        -- Highlight texture
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")

        -- Item text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, -2)
        text:SetWidth(172)
        text:SetJustifyH("LEFT")
        btn.text = text

        -- Source text
        local source = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        source:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, -14)
        source:SetWidth(172)
        source:SetJustifyH("LEFT")
        source:SetText("|cff" .. COLORS.source .. "  " .. item.source .. "|r")
        btn.source = source

        -- Store item reference
        btn.item = item

        -- Update appearance
        local function UpdateButton()
            local obtained = IsObtained(item.name)
            local color = obtained and COLORS.obtained or GetPriorityColor(item.priority)
            local prefix = obtained and "|cff" .. COLORS.obtained .. "[X] " or ""
            text:SetText(prefix .. "|cff" .. color .. item.name .. "|r")
        end
        btn.UpdateButton = UpdateButton
        UpdateButton()

        -- Click handler
        btn:SetScript("OnClick", function()
            ToggleObtained(item.name)
            UpdateButton()
        end)

        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(item.name, 1, 1, 1)
            GameTooltip:AddLine("Slot: " .. item.slot, 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Item Level: " .. item.ilvl, 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Source: " .. item.source, 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            if IsObtained(item.name) then
                GameTooltip:AddLine("Click to mark as NOT obtained", 1, 0, 0)
            else
                GameTooltip:AddLine("Click to mark as obtained", 0, 1, 0)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(itemButtons, btn)
        yOffset = yOffset + 30
    end

    contentFrame:SetHeight(yOffset)
end

-- Update all buttons
local function UpdateAllButtons()
    for _, btn in ipairs(itemButtons) do
        if btn.UpdateButton then
            btn.UpdateButton()
        end
    end
end

-- Loot detection
local function OnLootMessage(msg)
    if not DoroxLootTrackerDB.enabled then return end

    -- Check if message contains a tracked item
    for _, item in ipairs(trackedItems) do
        if msg:lower():find(item.name:lower(), 1, true) then
            -- Item dropped!
            if DoroxLootTrackerDB.soundEnabled then
                PlayAlertSound()
            end
            if DoroxLootTrackerDB.chatEnabled then
                print("|cff" .. COLORS.alert .. "[LOOT ALERT]|r |cff" .. COLORS.title .. item.name .. "|r dropped! (Priority " .. item.priority .. " - " .. item.slot .. ")")
            end
            return
        end
    end
end

-- Slash commands
local function HandleSlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "" or cmd == "help" then
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Commands:")
        print("  /dlt toggle - Enable/disable addon")
        print("  /dlt sound - Toggle sound alerts")
        print("  /dlt chat - Toggle chat alerts")
        print("  /dlt frame - Toggle tracker frame")
        print("  /dlt show - Show tracker frame")
        print("  /dlt hide - Hide tracker frame")
        print("  /dlt list - List all tracked items")
        print("  /dlt obtained <item> - Toggle item obtained status")
        print("  /dlt reset - Reset all settings")
        print("  /dlt test - Test alert system")

    elseif cmd == "toggle" then
        DoroxLootTrackerDB.enabled = not DoroxLootTrackerDB.enabled
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r " .. (DoroxLootTrackerDB.enabled and "Enabled" or "Disabled"))

    elseif cmd == "sound" then
        DoroxLootTrackerDB.soundEnabled = not DoroxLootTrackerDB.soundEnabled
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Sound: " .. (DoroxLootTrackerDB.soundEnabled and "On" or "Off"))

    elseif cmd == "chat" then
        DoroxLootTrackerDB.chatEnabled = not DoroxLootTrackerDB.chatEnabled
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Chat alerts: " .. (DoroxLootTrackerDB.chatEnabled and "On" or "Off"))

    elseif cmd == "frame" then
        if trackerFrame:IsShown() then
            trackerFrame:Hide()
            DoroxLootTrackerDB.frameShown = false
        else
            trackerFrame:Show()
            DoroxLootTrackerDB.frameShown = true
        end

    elseif cmd == "show" then
        trackerFrame:Show()
        DoroxLootTrackerDB.frameShown = true

    elseif cmd == "hide" then
        trackerFrame:Hide()
        DoroxLootTrackerDB.frameShown = false

    elseif cmd == "list" then
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Tracked items:")
        for _, item in ipairs(trackedItems) do
            local status = IsObtained(item.name) and "|cff00FF00[X]|r" or "|cffFF0000[ ]|r"
            print("  " .. status .. " |cff" .. GetPriorityColor(item.priority) .. "[P" .. item.priority .. "]|r " .. item.name)
        end

    elseif cmd == "obtained" then
        if arg ~= "" then
            -- Find item by partial name match
            for _, item in ipairs(trackedItems) do
                if item.name:lower():find(arg:lower(), 1, true) then
                    ToggleObtained(item.name)
                    UpdateAllButtons()
                    return
                end
            end
            print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Item not found: " .. arg)
        else
            print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Usage: /dlt obtained <item name>")
        end

    elseif cmd == "reset" then
        DoroxLootTrackerDB = {}
        InitializeDB()
        UpdateAllButtons()
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Settings reset")

    elseif cmd == "test" then
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Testing alert...")
        OnLootMessage("You receive loot: [Phylactery of the Nameless Lich]")

    else
        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Unknown command. Type /dlt help")
    end
end

-- Register slash commands
SLASH_DOROXLOOTTRACKER1 = "/dlt"
SLASH_DOROXLOOTTRACKER2 = "/doroxloot"
SlashCmdList["DOROXLOOTTRACKER"] = HandleSlashCommand

-- Check loot window for tracked items
local function CheckLootWindow()
    if not DoroxLootTrackerDB.enabled then return end

    local numItems = GetNumLootItems()
    for i = 1, numItems do
        local lootIcon, lootName, lootQuantity, rarity = GetLootSlotInfo(i)
        if lootName then
            for _, item in ipairs(trackedItems) do
                if lootName:lower():find(item.name:lower(), 1, true) then
                    -- Item is in loot window!
                    if DoroxLootTrackerDB.soundEnabled then
                        PlayAlertSound()
                    end
                    if DoroxLootTrackerDB.chatEnabled then
                        print("|cff" .. COLORS.alert .. "[LOOT ALERT]|r |cff" .. COLORS.title .. item.name .. "|r is in the loot! (Priority " .. item.priority .. " - " .. item.slot .. ")")
                    end
                    return -- Only alert once per loot window
                end
            end
        end
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "DoroxLootTracker" then
        InitializeDB()
        CreateItemList()

        -- Restore frame position
        local pos = DoroxLootTrackerDB.framePosition
        if pos then
            trackerFrame:ClearAllPoints()
            trackerFrame:SetPoint(pos.point or "RIGHT", UIParent, pos.relPoint or "RIGHT", pos.x or -50, pos.y or 0)
        end

        -- Restore frame visibility
        if DoroxLootTrackerDB.frameShown then
            trackerFrame:Show()
        else
            trackerFrame:Hide()
        end

        print("|cff" .. COLORS.title .. "[DoroxLootTracker]|r Loaded! Tracking " .. #trackedItems .. " items. Type /dlt help")

    elseif event == "CHAT_MSG_LOOT" then
        OnLootMessage(arg1)

    elseif event == "LOOT_OPENED" then
        CheckLootWindow()

    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateAllButtons()
    end
end)
