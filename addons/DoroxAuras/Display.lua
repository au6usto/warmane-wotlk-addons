-- Display.lua - Icon frame creation and management
DoroxAurasDisplay = {}

local groupContainers = {}
local iconPool = {}

-- Create a single icon frame
local function CreateIconFrame(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(50)
    frame:SetHeight(50)
    frame:Hide()

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Icon texture
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 2, -2)
    frame.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame (for sweep animation)
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetReverse(true)

    -- Timer text (large centered)
    frame.timer = frame:CreateFontString(nil, "OVERLAY")
    frame.timer:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.timer:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frame.timer:SetTextColor(1, 1, 1, 1)

    -- Stack count (bottom right)
    frame.stacks = frame:CreateFontString(nil, "OVERLAY")
    frame.stacks:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    frame.stacks:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.stacks:SetTextColor(1, 1, 1, 1)

    -- Name text (for missing buffs)
    frame.nameText = frame:CreateFontString(nil, "OVERLAY")
    frame.nameText:SetPoint("BOTTOM", frame, "BOTTOM", 0, -12)
    frame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    frame.nameText:SetTextColor(1, 0.8, 0, 1)
    frame.nameText:Hide()

    -- Overlay text (for action hints like "ESPERA", "REFRESH!")
    -- Positioned ABOVE the icon for better visibility
    frame.overlay = frame:CreateFontString(nil, "OVERLAY")
    frame.overlay:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    frame.overlay:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    frame.overlay:SetTextColor(1, 1, 1, 1)
    frame.overlay:Hide()

    -- Inner glow overlay (for procs/warnings)
    frame.glow = frame:CreateTexture(nil, "OVERLAY")
    frame.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.glow:SetBlendMode("ADD")
    frame.glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.glow:SetWidth(frame:GetWidth() * 1.8)
    frame.glow:SetHeight(frame:GetHeight() * 1.8)
    frame.glow:SetVertexColor(1, 1, 0, 0.8)
    frame.glow:Hide()

    -- Outer glow (bigger, more visible)
    frame.outerGlow = frame:CreateTexture(nil, "BACKGROUND")
    frame.outerGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    frame.outerGlow:SetBlendMode("ADD")
    frame.outerGlow:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.outerGlow:SetWidth(frame:GetWidth() * 2.5)
    frame.outerGlow:SetHeight(frame:GetHeight() * 2.5)
    frame.outerGlow:SetVertexColor(1, 1, 0, 0.6)
    frame.outerGlow:Hide()

    -- Glow pulse animation state
    frame.glowAlpha = 0.3
    frame.glowDirection = 1
    frame.glowAnimating = false
    frame.pulseSpeed = 0.02  -- Default pulse speed

    -- Bounce animation state
    frame.bouncing = false
    frame.bounceScale = 1.0
    frame.bounceDirection = 1
    frame.bounceSpeed = 0.08

    -- Internal state
    frame.auraConfig = nil
    frame.soundPlayed = false
    frame.isMissing = false
    frame.currentTexture = nil
    frame.debugSpell = nil
    frame.overlayText = nil  -- Current overlay text ("ESPERA", "REFRESH!", etc.)
    frame.customBorderColor = nil  -- Custom border color override

    -- Enable mouse for tooltip
    frame:EnableMouse(true)

    -- Tooltip on mouseover
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        local config = self.auraConfig
        if config then
            -- Aura name
            GameTooltip:AddLine(config.name or "Unknown", 1, 1, 1)

            -- Spell name(s)
            if config.spell then
                GameTooltip:AddDoubleLine("Spell:", config.spell, 0.7, 0.7, 0.7, 1, 1, 0)
            elseif config.spells then
                GameTooltip:AddDoubleLine("Spells:", table.concat(config.spells, ", "), 0.7, 0.7, 0.7, 1, 1, 0)
            end

            -- Group
            if config.group then
                GameTooltip:AddDoubleLine("Group:", config.group, 0.7, 0.7, 0.7, 0.5, 1, 0.5)
            end

            -- Unit
            if config.unit then
                GameTooltip:AddDoubleLine("Unit:", config.unit, 0.7, 0.7, 0.7, 0.5, 0.8, 1)
            end

            -- Type
            if config.type then
                GameTooltip:AddDoubleLine("Type:", config.type, 0.7, 0.7, 0.7, 1, 0.5, 0.5)
            end

            -- Debug: current texture
            if self.currentTexture then
                GameTooltip:AddDoubleLine("Texture:", self.currentTexture, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
            end

            -- Missing indicator
            if self.isMissing then
                GameTooltip:AddLine("Status: MISSING", 1, 0.3, 0.3)
            end

            -- Refresh warning
            if config.refresh_warn then
                GameTooltip:AddDoubleLine("Refresh at:", config.refresh_warn .. "s", 0.7, 0.7, 0.7, 1, 0.8, 0)
            end
        else
            GameTooltip:AddLine("No config", 1, 0.3, 0.3)
        end

        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return frame
end

-- Update icon timer and visuals
function DoroxAurasDisplay:UpdateIcon(frame, remaining, duration, stacks, showGlow, refreshWarn)
    if not frame then return end

    -- Timer text
    if remaining and remaining > 0 then
        if remaining <= 10 then
            frame.timer:SetFormattedText("%.1f", remaining)
            -- Color based on remaining time
            if remaining <= 3 then
                frame.timer:SetTextColor(1, 0.2, 0.2)  -- Red
                frame:SetBackdropBorderColor(1, 0.2, 0.2, 1)
            elseif remaining <= 5 then
                frame.timer:SetTextColor(1, 0.8, 0)    -- Yellow
                frame:SetBackdropBorderColor(1, 0.8, 0, 1)
            else
                frame.timer:SetTextColor(1, 1, 1)
                frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            end
        elseif remaining <= 60 then
            frame.timer:SetFormattedText("%d", math.floor(remaining))
            frame.timer:SetTextColor(1, 1, 1)
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        else
            frame.timer:SetFormattedText("%d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
            frame.timer:SetTextColor(1, 1, 1)
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        end
        frame.timer:Show()

        -- Cooldown sweep
        if duration and duration > 0 then
            local start = GetTime() - (duration - remaining)
            frame.cooldown:SetCooldown(start, duration)
            frame.cooldown:Show()
        end

        -- Check refresh warning
        if refreshWarn and remaining <= refreshWarn then
            showGlow = true
        end
    else
        frame.timer:Hide()
        frame.cooldown:Hide()
    end

    -- Stack count
    if stacks and stacks > 1 then
        frame.stacks:SetText(stacks)
        frame.stacks:Show()
    else
        frame.stacks:Hide()
    end

    -- Glow effect
    if showGlow then
        frame.glow:Show()
        frame.glowAnimating = true
    else
        frame.glow:Hide()
        frame.glowAnimating = false
    end

    -- Reset missing state
    frame.isMissing = false
    frame.icon:SetDesaturated(false)
    frame.nameText:Hide()
end

-- Show icon as missing (desaturated)
function DoroxAurasDisplay:ShowMissing(frame, texture, name, showGlow)
    if not frame then return end

    frame.icon:SetTexture(texture)
    frame.currentTexture = texture  -- Store for tooltip debug
    frame.icon:SetDesaturated(true)
    frame.timer:Hide()
    frame.cooldown:Hide()
    frame.stacks:Hide()
    frame.isMissing = true

    -- Show name for missing buffs
    if name then
        frame.nameText:SetText(name)
        frame.nameText:Show()
    end

    if showGlow then
        frame.glow:Show()
        frame.glowAnimating = true
    else
        frame.glow:Hide()
        frame.glowAnimating = false
    end

    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    frame:Show()
end

-- Create group container frame
function DoroxAurasDisplay:CreateGroupFrame(name, config)
    local frame = CreateFrame("Frame", "DoroxAuras_" .. name, UIParent)

    -- Check for saved position
    local savedPos = DoroxAurasConfig:GetPosition(name)
    if savedPos then
        frame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
    else
        frame:SetPoint(config.anchor or "CENTER", UIParent, config.anchor or "CENTER",
                       config.x or 0, config.y or 0)
    end

    local size = config.icon_size or 50
    local cols = config.columns or 5
    local spacing = config.spacing or 2

    frame:SetWidth(size * cols + spacing * (cols - 1))
    frame:SetHeight(size * 3 + spacing * 2)  -- Allow 3 rows

    -- Make movable when unlocked
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        DoroxAurasConfig:SavePosition(name, point, relPoint, x, y)
    end)

    -- Debug background (shown when unlocked)
    frame.debugBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.debugBg:SetAllPoints()
    frame.debugBg:SetTexture(0, 0, 0, 0.3)
    frame.debugBg:Hide()

    frame.debugText = frame:CreateFontString(nil, "OVERLAY")
    frame.debugText:SetPoint("TOP", frame, "TOP", 0, -2)
    frame.debugText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.debugText:SetText(name)
    frame.debugText:SetTextColor(1, 1, 1, 0.8)
    frame.debugText:Hide()

    frame.config = config
    frame.icons = {}
    frame.name = name

    groupContainers[name] = frame
    return frame
end

-- Get or create icon for an aura
function DoroxAurasDisplay:GetIcon(auraConfig)
    if not auraConfig or not auraConfig.group then return nil end

    local container = groupContainers[auraConfig.group]
    if not container then return nil end

    local key = auraConfig.name
    if not container.icons[key] then
        container.icons[key] = CreateIconFrame(container)
        container.icons[key].auraConfig = auraConfig
    end

    return container.icons[key]
end

-- Show aura on icon
function DoroxAurasDisplay:ShowAura(auraConfig, texture, remaining, duration, stacks, syncStatus)
    local icon = self:GetIcon(auraConfig)
    if not icon then return end

    icon.icon:SetTexture(texture)
    icon.currentTexture = texture  -- Store for tooltip debug

    -- Determine if we should glow
    local showGlow = auraConfig.glow
    -- Check glow_at_stacks condition (e.g., glow when Illustrious >= 8 stacks)
    if auraConfig.glow_at_stacks and stacks and stacks >= auraConfig.glow_at_stacks then
        showGlow = true
    end

    self:UpdateIcon(icon, remaining, duration, stacks, showGlow, auraConfig.refresh_warn)

    -- Handle DoT sync status overlay
    if syncStatus then
        self:SetSyncOverlay(icon, syncStatus)
    else
        -- Clear overlay if no sync status
        icon.overlay:Hide()
        icon.customBorderColor = nil
        icon.pulseSpeed = 0.02  -- Reset to default
    end

    icon:Show()

    -- Show outer glow for important procs
    if showGlow and icon.outerGlow then
        icon.outerGlow:SetVertexColor(1, 1, 0, 0.6)
        icon.outerGlow:Show()
        icon.glowAnimating = true
    end

    -- Play sound once per show
    if auraConfig.sound and not icon.soundPlayed then
        if DoroxAurasAlerts then
            DoroxAurasAlerts:PlaySound(auraConfig.sound)
        end
        icon.soundPlayed = true
    end

    -- Show big center screen alert for important procs
    if auraConfig.big_alert and not icon.bigAlertPlayed then
        local alertColor = auraConfig.alert_color or {1, 1, 0}
        local alertText = auraConfig.alert_text or auraConfig.name
        local alertSubtext = auraConfig.alert_subtext
        self:ShowProcAlert(alertText, alertSubtext, texture, alertColor, 2.5, auraConfig.sound)
        icon.bigAlertPlayed = true
    end

    self:ArrangeGroup(auraConfig.group)
end

-- Set sync overlay status for DoT + DFO tracking
-- syncStatus: "refresh" (DFO active with good stacks - refresh for stronger DoT!), nil (normal)
function DoroxAurasDisplay:SetSyncOverlay(icon, syncStatus)
    if not icon then return end

    if syncStatus == "refresh" then
        -- DFO active with good stacks - refresh Corruption to snapshot higher SP!
        icon.overlay:SetText("REFRESH!")
        icon.overlay:SetTextColor(0, 1, 0.8)  -- Cyan-green
        icon.overlay:Show()
        icon:SetBackdropBorderColor(0, 1, 0.8, 1)  -- Cyan-green border
        icon.customBorderColor = {0, 1, 0.8, 1}
        icon.glow:SetVertexColor(0, 1, 0.8, 0.8)  -- Cyan-green glow
        icon.glow:Show()
        icon.glowAnimating = true
        if icon.outerGlow then
            icon.outerGlow:SetVertexColor(0, 1, 0.8, 0.6)
            icon.outerGlow:Show()
        end
        icon.pulseSpeed = 0.04  -- Fast pulse
        icon.bouncing = true  -- Bounce when DFO proc = refresh for stronger DoT
        icon.bounceSpeed = 0.06
        -- Play sound for refresh (DFO proc active)
        if DoroxAurasAlerts and not icon.refreshSoundPlayed then
            DoroxAurasAlerts:PlaySound("map_ping")
            icon.refreshSoundPlayed = true
        end
    else
        -- Normal state - no special action needed
        icon.overlay:Hide()
        icon.customBorderColor = nil
        -- Don't change glow color, let normal logic handle it
        if icon.outerGlow then
            icon.outerGlow:Hide()
        end
        icon.pulseSpeed = 0.02  -- Default pulse
        icon.bouncing = false  -- Stop bouncing - no reason to refresh
        icon.refreshSoundPlayed = false
    end
end

-- Hide aura icon
function DoroxAurasDisplay:HideAura(auraConfig)
    local icon = self:GetIcon(auraConfig)
    if icon then
        icon:Hide()
        icon.glow:Hide()
        if icon.outerGlow then
            icon.outerGlow:Hide()
        end
        if icon.overlay then
            icon.overlay:Hide()
        end
        icon.glowAnimating = false
        icon.bouncing = false
        icon.bounceScale = 1.0
        icon:SetScale(1.0)
        icon.soundPlayed = false
        icon.bigAlertPlayed = false
        icon.refreshSoundPlayed = false
        icon.urgentSoundPlayed = false
        icon.isMissing = false
        self:ArrangeGroup(auraConfig.group)
    end
end

-- Arrange icons in a group (grid layout)
function DoroxAurasDisplay:ArrangeGroup(groupName)
    local container = groupContainers[groupName]
    if not container then return end

    local config = container.config
    local cols = config.columns or 5
    local spacing = config.spacing or 2
    local size = config.icon_size or 50
    local grow = config.grow or "GRID"

    -- Collect visible icons and sort by priority
    local visibleIcons = {}
    for _, icon in pairs(container.icons) do
        if icon:IsShown() then
            table.insert(visibleIcons, icon)
        end
    end

    -- Sort by priority
    table.sort(visibleIcons, function(a, b)
        local pa = a.auraConfig and a.auraConfig.priority or 999
        local pb = b.auraConfig and b.auraConfig.priority or 999
        return pa < pb
    end)

    -- Position icons
    for i, icon in ipairs(visibleIcons) do
        icon:ClearAllPoints()
        icon:SetWidth(size)
        icon:SetHeight(size)

        if grow == "GRID" then
            local row = math.floor((i - 1) / cols)
            local col = (i - 1) % cols
            icon:SetPoint("TOPLEFT", container, "TOPLEFT",
                         col * (size + spacing), -row * (size + spacing))
        elseif grow == "HORIZONTAL" then
            icon:SetPoint("LEFT", container, "LEFT", (i - 1) * (size + spacing), 0)
        elseif grow == "VERTICAL" then
            icon:SetPoint("TOP", container, "TOP", 0, -(i - 1) * (size + spacing))
        end
    end
end

-- Initialize all group containers
function DoroxAurasDisplay:Initialize()
    local config = DoroxAurasConfig:GetConfig()

    for groupName, groupConfig in pairs(config.groups) do
        if not groupContainers[groupName] then
            self:CreateGroupFrame(groupName, groupConfig)
        end
    end
end

-- Lock frames (disable dragging)
function DoroxAurasDisplay:Lock()
    for _, container in pairs(groupContainers) do
        container:EnableMouse(false)
        container.debugBg:Hide()
        container.debugText:Hide()
    end
    local config = DoroxAurasConfig:GetConfig()
    config.locked = true
    print("|cff00FF00[DoroxAuras]|r Frames locked")
end

-- Unlock frames (enable dragging)
function DoroxAurasDisplay:Unlock()
    for _, container in pairs(groupContainers) do
        container:EnableMouse(true)
        container.debugBg:Show()
        container.debugText:Show()
    end
    local config = DoroxAurasConfig:GetConfig()
    config.locked = false
    print("|cff00FF00[DoroxAuras]|r Frames unlocked - drag to move")
end

-- Reset positions to defaults
function DoroxAurasDisplay:ResetPositions()
    local config = DoroxAurasConfig:GetConfig()
    config.positions = {}

    for groupName, container in pairs(groupContainers) do
        local groupConfig = config.groups[groupName]
        if groupConfig then
            container:ClearAllPoints()
            container:SetPoint(groupConfig.anchor or "CENTER", UIParent, groupConfig.anchor or "CENTER",
                              groupConfig.x or 0, groupConfig.y or 0)
        end
    end

    print("|cff00FF00[DoroxAuras]|r Positions reset to defaults")
end

-- Test mode - show all icons temporarily
function DoroxAurasDisplay:TestMode()
    print("|cff00FF00[DoroxAuras]|r Test mode - showing all icons for 5 seconds")

    local config = DoroxAurasConfig:GetConfig()

    for _, aura in ipairs(config.auras) do
        local icon = self:GetIcon(aura)
        if icon then
            -- Use a placeholder texture
            local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
            if aura.spell then
                local _, _, t = GetSpellInfo(aura.spell)
                if t then texture = t end
            elseif aura.spells and aura.spells[1] then
                local _, _, t = GetSpellInfo(aura.spells[1])
                if t then texture = t end
            end

            icon.icon:SetTexture(texture)
            icon.icon:SetDesaturated(false)
            self:UpdateIcon(icon, 15, 30, aura.show_stacks and 3 or 1, aura.glow)
            icon:Show()
        end
    end

    -- Arrange all groups
    for groupName in pairs(config.groups) do
        self:ArrangeGroup(groupName)
    end

    -- Hide after 5 seconds
    C_Timer.After(5, function()
        if DoroxAurasTrackers then
            DoroxAurasTrackers:UpdateAll()
        end
    end)
end

-- OnUpdate for glow and bounce animation
local glowFrame = CreateFrame("Frame")
glowFrame.elapsed = 0
glowFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.02 then return end
    self.elapsed = 0

    for _, container in pairs(groupContainers) do
        for _, icon in pairs(container.icons) do
            -- Glow pulse animation
            if icon.glowAnimating and icon.glow:IsShown() then
                local speed = icon.pulseSpeed or 0.02
                icon.glowAlpha = icon.glowAlpha + (speed * icon.glowDirection)
                if icon.glowAlpha >= 0.9 then
                    icon.glowAlpha = 0.9
                    icon.glowDirection = -1
                elseif icon.glowAlpha <= 0.2 then
                    icon.glowAlpha = 0.2
                    icon.glowDirection = 1
                end
                icon.glow:SetAlpha(icon.glowAlpha)
                -- Also pulse outer glow if visible
                if icon.outerGlow and icon.outerGlow:IsShown() then
                    icon.outerGlow:SetAlpha(icon.glowAlpha * 0.7)
                end
            end

            -- Bounce animation
            if icon.bouncing and icon:IsShown() then
                local speed = icon.bounceSpeed or 0.08
                icon.bounceScale = icon.bounceScale + (speed * icon.bounceDirection)
                if icon.bounceScale >= 1.2 then
                    icon.bounceScale = 1.2
                    icon.bounceDirection = -1
                elseif icon.bounceScale <= 1.0 then
                    icon.bounceScale = 1.0
                    icon.bounceDirection = 1
                end
                icon:SetScale(icon.bounceScale)
            elseif icon.bounceScale ~= 1.0 then
                icon.bounceScale = 1.0
                icon:SetScale(1.0)
            end
        end
    end
end)

-- Get group containers (for other modules)
function DoroxAurasDisplay:GetGroupContainers()
    return groupContainers
end

-- ==================== CENTER SCREEN PROC ALERT ====================
local procAlertFrame = nil
local procAlertHideTime = 0

local function CreateProcAlertFrame()
    if procAlertFrame then return end

    procAlertFrame = CreateFrame("Frame", "DoroxAuras_ProcAlert", UIParent)
    procAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    procAlertFrame:SetWidth(400)
    procAlertFrame:SetHeight(100)
    procAlertFrame:SetFrameStrata("HIGH")
    procAlertFrame:Hide()

    -- Big icon
    procAlertFrame.icon = procAlertFrame:CreateTexture(nil, "ARTWORK")
    procAlertFrame.icon:SetPoint("LEFT", procAlertFrame, "LEFT", 0, 0)
    procAlertFrame.icon:SetWidth(64)
    procAlertFrame.icon:SetHeight(64)

    -- Glow around icon
    procAlertFrame.glow = procAlertFrame:CreateTexture(nil, "BACKGROUND")
    procAlertFrame.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    procAlertFrame.glow:SetBlendMode("ADD")
    procAlertFrame.glow:SetPoint("CENTER", procAlertFrame.icon, "CENTER", 0, 0)
    procAlertFrame.glow:SetWidth(128)
    procAlertFrame.glow:SetHeight(128)

    -- Big text
    procAlertFrame.text = procAlertFrame:CreateFontString(nil, "OVERLAY")
    procAlertFrame.text:SetPoint("LEFT", procAlertFrame.icon, "RIGHT", 15, 0)
    procAlertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
    procAlertFrame.text:SetTextColor(1, 1, 0, 1)

    -- Subtext (smaller)
    procAlertFrame.subtext = procAlertFrame:CreateFontString(nil, "OVERLAY")
    procAlertFrame.subtext:SetPoint("TOP", procAlertFrame.text, "BOTTOM", 0, -5)
    procAlertFrame.subtext:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    procAlertFrame.subtext:SetTextColor(1, 1, 1, 0.9)

    -- Animation state
    procAlertFrame.alpha = 1
    procAlertFrame.glowAlpha = 0.5
    procAlertFrame.glowDir = 1

    -- OnUpdate for animation
    procAlertFrame:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end

        -- Auto-hide after duration
        if GetTime() >= procAlertHideTime then
            self:Hide()
            return
        end

        -- Pulse glow
        self.glowAlpha = self.glowAlpha + (0.03 * self.glowDir)
        if self.glowAlpha >= 1 then
            self.glowAlpha = 1
            self.glowDir = -1
        elseif self.glowAlpha <= 0.3 then
            self.glowAlpha = 0.3
            self.glowDir = 1
        end
        self.glow:SetAlpha(self.glowAlpha)

        -- Fade out in last second
        local remaining = procAlertHideTime - GetTime()
        if remaining < 0.5 then
            self:SetAlpha(remaining / 0.5)
        else
            self:SetAlpha(1)
        end
    end)
end

-- Show a big center screen proc alert
-- text: Main text (e.g., "DECIMATION!")
-- subtext: Optional subtext (e.g., "Cast Soul Fire")
-- icon: Texture path
-- color: {r, g, b} for text color
-- duration: How long to show (default 3s)
-- sound: Sound to play (optional)
function DoroxAurasDisplay:ShowProcAlert(text, subtext, icon, color, duration, sound)
    CreateProcAlertFrame()

    procAlertFrame.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    procAlertFrame.text:SetText(text or "PROC!")
    procAlertFrame.text:SetTextColor(color and color[1] or 1, color and color[2] or 1, color and color[3] or 0, 1)
    procAlertFrame.glow:SetVertexColor(color and color[1] or 1, color and color[2] or 1, color and color[3] or 0, 0.8)

    if subtext then
        procAlertFrame.subtext:SetText(subtext)
        procAlertFrame.subtext:Show()
    else
        procAlertFrame.subtext:Hide()
    end

    procAlertHideTime = GetTime() + (duration or 3)
    procAlertFrame:SetAlpha(1)
    procAlertFrame:Show()

    -- Play sound
    if sound and DoroxAurasAlerts then
        DoroxAurasAlerts:PlaySound(sound)
    end
end

-- Hide proc alert immediately
function DoroxAurasDisplay:HideProcAlert()
    if procAlertFrame then
        procAlertFrame:Hide()
    end
end

-- ==================== MANA BAR ====================
local manaBarFrame = nil

local function CreateManaBar()
    if manaBarFrame then return end

    manaBarFrame = CreateFrame("Frame", "DoroxAuras_ManaBar", UIParent)
    manaBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    manaBarFrame:SetWidth(200)
    manaBarFrame:SetHeight(16)
    manaBarFrame:SetFrameStrata("MEDIUM")
    manaBarFrame:Hide()

    -- Background
    manaBarFrame.bg = manaBarFrame:CreateTexture(nil, "BACKGROUND")
    manaBarFrame.bg:SetAllPoints()
    manaBarFrame.bg:SetTexture(0, 0, 0, 0.7)

    -- Border
    manaBarFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    manaBarFrame:SetBackdropBorderColor(0.3, 0.3, 0.8, 1)

    -- Mana bar fill
    manaBarFrame.bar = manaBarFrame:CreateTexture(nil, "ARTWORK")
    manaBarFrame.bar:SetPoint("TOPLEFT", manaBarFrame, "TOPLEFT", 2, -2)
    manaBarFrame.bar:SetPoint("BOTTOMLEFT", manaBarFrame, "BOTTOMLEFT", 2, 2)
    manaBarFrame.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    manaBarFrame.bar:SetVertexColor(0.2, 0.4, 1, 1)  -- Blue mana color

    -- Percentage text
    manaBarFrame.text = manaBarFrame:CreateFontString(nil, "OVERLAY")
    manaBarFrame.text:SetPoint("CENTER", manaBarFrame, "CENTER", 0, 0)
    manaBarFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    manaBarFrame.text:SetTextColor(1, 1, 1, 1)

    -- Label above bar
    manaBarFrame.label = manaBarFrame:CreateFontString(nil, "OVERLAY")
    manaBarFrame.label:SetPoint("BOTTOM", manaBarFrame, "TOP", 0, 2)
    manaBarFrame.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    manaBarFrame.label:SetTextColor(0.6, 0.8, 1, 0.9)
    manaBarFrame.label:SetText("MANA")

    -- Make movable
    manaBarFrame:SetMovable(true)
    manaBarFrame:EnableMouse(true)
    manaBarFrame:RegisterForDrag("LeftButton")
    manaBarFrame:SetScript("OnDragStart", function(self)
        if not DoroxAurasConfig:GetConfig().locked then
            self:StartMoving()
        end
    end)
    manaBarFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
end

-- Update mana bar display
-- Shows when mana < 80%, hides when >= 80%
function DoroxAurasDisplay:UpdateManaBar(manaPercent)
    CreateManaBar()

    if manaPercent < 80 then
        -- Show mana bar
        local barWidth = (manaBarFrame:GetWidth() - 4) * (manaPercent / 100)
        manaBarFrame.bar:SetWidth(math.max(1, barWidth))
        manaBarFrame.text:SetFormattedText("%d%%", math.floor(manaPercent))

        -- Color based on mana level
        if manaPercent < 20 then
            manaBarFrame.bar:SetVertexColor(1, 0.3, 0.3, 1)  -- Red
            manaBarFrame:SetBackdropBorderColor(1, 0.3, 0.3, 1)
        elseif manaPercent < 40 then
            manaBarFrame.bar:SetVertexColor(1, 0.6, 0, 1)  -- Orange
            manaBarFrame:SetBackdropBorderColor(1, 0.6, 0, 1)
        elseif manaPercent < 60 then
            manaBarFrame.bar:SetVertexColor(1, 1, 0, 1)  -- Yellow
            manaBarFrame:SetBackdropBorderColor(0.8, 0.8, 0, 1)
        else
            manaBarFrame.bar:SetVertexColor(0.2, 0.6, 1, 1)  -- Blue
            manaBarFrame:SetBackdropBorderColor(0.3, 0.5, 1, 1)
        end

        manaBarFrame:Show()
    else
        -- Hide when mana is healthy
        manaBarFrame:Hide()
    end
end

-- Hide mana bar
function DoroxAurasDisplay:HideManaBar()
    if manaBarFrame then
        manaBarFrame:Hide()
    end
end
