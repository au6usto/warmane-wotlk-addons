-- CastBar.lua - Cast bar and Target HP tracker
DoroxAurasCastBar = {}

local playerCastBar = nil
local targetHPBar = nil
local isChanneling = false
local lastAlertTime = 0
local testMode = false
local dummyMode = false

local EXECUTE_THRESHOLDS = {
    DEMO = { show_percent = 40, alert_percent = 35, spell = "Soul Fire", color = {1, 0.5, 0} },
    AFFLI = { show_percent = 30, alert_percent = 25, spell = "Drain Soul", color = {0.5, 0, 1} },
}

local function GetWarlockSpec()
    local _, _, _, _, demoPoints = GetTalentTabInfo(2)
    local _, _, _, _, affliPoints = GetTalentTabInfo(1)
    local _, _, _, _, destroPoints = GetTalentTabInfo(3)
    demoPoints = demoPoints or 0
    affliPoints = affliPoints or 0
    destroPoints = destroPoints or 0
    if demoPoints >= affliPoints and demoPoints >= destroPoints then
        return "DEMO"
    elseif affliPoints >= demoPoints and affliPoints >= destroPoints then
        return "AFFLI"
    else
        return "DESTRO"
    end
end

local function CreatePlayerCastBar()
    if playerCastBar then return end
    local frame = CreateFrame("Frame", "DoroxCastBarFrame", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    frame:SetWidth(250)
    frame:SetHeight(25)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetPoint("TOPLEFT", 3, -3)
    frame.bar:SetPoint("BOTTOMRIGHT", -3, 3)
    frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.bar:SetStatusBarColor(1, 0.7, 0)
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(0)
    frame.spark = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    frame.spark:SetWidth(16)
    frame.spark:SetHeight(32)
    frame.spark:SetBlendMode("ADD")
    frame.spark:SetPoint("CENTER", frame.bar, "LEFT", 0, 0)
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("RIGHT", frame, "LEFT", -5, 0)
    frame.icon:SetWidth(25)
    frame.icon:SetHeight(25)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.spellName = frame.bar:CreateFontString(nil, "OVERLAY")
    frame.spellName:SetPoint("LEFT", frame.bar, "LEFT", 5, 0)
    frame.spellName:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.spellName:SetTextColor(1, 1, 1, 1)
    frame.castTime = frame.bar:CreateFontString(nil, "OVERLAY")
    frame.castTime:SetPoint("RIGHT", frame.bar, "RIGHT", -5, 0)
    frame.castTime:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.castTime:SetTextColor(1, 1, 1, 1)
    frame.latency = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.latency:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.latency:SetVertexColor(1, 0, 0, 0.5)
    frame.latency:SetPoint("TOPRIGHT", frame.bar, "TOPRIGHT", 0, 0)
    frame.latency:SetPoint("BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", 0, 0)
    frame.latency:SetWidth(0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if DoroxAurasDB and not DoroxAurasDB.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()
    playerCastBar = frame
end

local function CreateTargetHPBar()
    if targetHPBar then return end
    local frame = CreateFrame("Frame", "DoroxTargetHPFrame", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    frame:SetWidth(200)
    frame:SetHeight(30)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(0.5, 0, 0, 1)
    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetPoint("TOPLEFT", 3, -3)
    frame.bar:SetPoint("BOTTOMRIGHT", -3, 3)
    frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.bar:SetStatusBarColor(0.8, 0.2, 0.2)
    frame.bar:SetMinMaxValues(0, 100)
    frame.bar:SetValue(0)
    frame.threshold = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.threshold:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.threshold:SetVertexColor(1, 1, 0, 0.8)
    frame.threshold:SetWidth(2)
    frame.threshold:SetPoint("TOP", frame.bar, "TOP", 0, 0)
    frame.threshold:SetPoint("BOTTOM", frame.bar, "BOTTOM", 0, 0)
    frame.percent = frame.bar:CreateFontString(nil, "OVERLAY")
    frame.percent:SetPoint("CENTER", frame.bar, "CENTER", 0, 0)
    frame.percent:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    frame.percent:SetTextColor(1, 1, 1, 1)
    frame.targetName = frame:CreateFontString(nil, "OVERLAY")
    frame.targetName:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.targetName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.targetName:SetTextColor(1, 0.8, 0, 1)
    frame.spellReminder = frame:CreateFontString(nil, "OVERLAY")
    frame.spellReminder:SetPoint("TOP", frame, "BOTTOM", 0, -5)
    frame.spellReminder:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frame.spellReminder:SetTextColor(0, 1, 0, 1)
    frame.spellReminder:Hide()
    frame.glow = frame:CreateTexture(nil, "BACKGROUND")
    frame.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.glow:SetPoint("TOPLEFT", -15, 15)
    frame.glow:SetPoint("BOTTOMRIGHT", 15, -15)
    frame.glow:SetBlendMode("ADD")
    frame.glow:SetVertexColor(1, 0.5, 0, 0.5)
    frame.glow:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if DoroxAurasDB and not DoroxAurasDB.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()
    targetHPBar = frame
end

local function UpdateCastBar()
    if not playerCastBar or testMode then return end
    local spell, _, _, _, startTime, endTime, _, castID, interrupt = UnitCastingInfo("player")
    if not spell then
        spell, _, _, _, startTime, endTime, _, interrupt = UnitChannelInfo("player")
        isChanneling = (spell ~= nil)
    else
        isChanneling = false
    end
    if spell then
        local currentTime = GetTime() * 1000
        local duration = endTime - startTime
        local elapsed = currentTime - startTime
        local remaining = (endTime - currentTime) / 1000
        local progress = isChanneling and (1 - elapsed / duration) or (elapsed / duration)
        playerCastBar.bar:SetValue(progress)
        local sparkPos = progress * playerCastBar.bar:GetWidth()
        playerCastBar.spark:SetPoint("CENTER", playerCastBar.bar, "LEFT", sparkPos, 0)
        playerCastBar.spellName:SetText(spell)
        playerCastBar.castTime:SetFormattedText("%.1f", remaining)
        local _, _, icon = GetSpellInfo(spell)
        if icon then playerCastBar.icon:SetTexture(icon) end
        if interrupt then
            playerCastBar.bar:SetStatusBarColor(0.7, 0.7, 0.7)
        elseif isChanneling then
            playerCastBar.bar:SetStatusBarColor(0.3, 0.7, 1)
        else
            playerCastBar.bar:SetStatusBarColor(1, 0.7, 0)
        end
        local _, _, lagHome, lagWorld = GetNetStats()
        lagHome = lagHome or 0
        lagWorld = lagWorld or 0
        local latency = (lagHome + lagWorld) / 2000
        local latencyWidth = math.min((latency / (duration / 1000)) * playerCastBar.bar:GetWidth(), playerCastBar.bar:GetWidth() * 0.3)
        playerCastBar.latency:SetWidth(latencyWidth)
        playerCastBar:Show()
    else
        playerCastBar:Hide()
    end
end

local function UpdateTargetHP()
    if not targetHPBar or testMode then return end
    if not UnitExists("target") then
        targetHPBar:Hide()
        return
    end
    -- In dummy mode, show for any target; otherwise require attackable target
    if not dummyMode and not UnitCanAttack("player", "target") then
        targetHPBar:Hide()
        return
    end
    local hp = UnitHealth("target")
    local maxHp = UnitHealthMax("target")
    if maxHp == 0 then targetHPBar:Hide() return end
    local percent = (hp / maxHp) * 100
    local spec = GetWarlockSpec()
    local thresholds = EXECUTE_THRESHOLDS[spec] or EXECUTE_THRESHOLDS.DEMO

    -- In dummy mode, always show; otherwise hide if above threshold
    if not dummyMode and percent > thresholds.show_percent then
        targetHPBar:Hide()
        lastAlertTime = 0
        return
    end

    -- In dummy mode, show full 0-100 range; otherwise show threshold range
    if dummyMode then
        targetHPBar.bar:SetMinMaxValues(0, 100)
        targetHPBar.bar:SetValue(percent)
        -- Show threshold marker at the execute percent
        local barWidth = targetHPBar.bar:GetWidth()
        local thresholdPos = (thresholds.alert_percent / 100) * barWidth
        targetHPBar.threshold:SetPoint("LEFT", targetHPBar.bar, "LEFT", thresholdPos, 0)
    else
        targetHPBar.bar:SetMinMaxValues(0, thresholds.show_percent)
        targetHPBar.bar:SetValue(percent)
        local barWidth = targetHPBar.bar:GetWidth()
        local thresholdPos = (thresholds.alert_percent / thresholds.show_percent) * barWidth
        targetHPBar.threshold:SetPoint("LEFT", targetHPBar.bar, "LEFT", thresholdPos, 0)
    end

    targetHPBar.percent:SetFormattedText("%.1f%%", percent)

    -- Execute phase coloring (works in both modes)
    if percent <= thresholds.alert_percent then
        targetHPBar.bar:SetStatusBarColor(thresholds.color[1], thresholds.color[2], thresholds.color[3])
        targetHPBar.percent:SetTextColor(1, 1, 0, 1)
        targetHPBar.glow:Show()
        targetHPBar.spellReminder:SetText(">>> " .. thresholds.spell .. " <<<")
        targetHPBar.spellReminder:Show()
        targetHPBar:SetBackdropBorderColor(1, 0.5, 0, 1)
        local now = GetTime()
        if not dummyMode and (lastAlertTime == 0 or (now - lastAlertTime) > 30) then
            PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
            lastAlertTime = now
        end
    else
        targetHPBar.bar:SetStatusBarColor(0.8, 0.2, 0.2)
        targetHPBar.percent:SetTextColor(1, 1, 1, 1)
        targetHPBar.glow:Hide()
        targetHPBar.spellReminder:Hide()
        targetHPBar:SetBackdropBorderColor(0.5, 0, 0, 1)
    end
    targetHPBar.targetName:SetText(UnitName("target") or "")
    targetHPBar:Show()
end

function DoroxAurasCastBar:Initialize()
    CreatePlayerCastBar()
    CreateTargetHPBar()

    -- Hide default WoW cast bar
    CastingBarFrame:UnregisterAllEvents()
    CastingBarFrame:Hide()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            lastAlertTime = 0
            UpdateTargetHP()
        elseif unit == "player" then
            UpdateCastBar()
        end
    end)
    local updateFrame = CreateFrame("Frame")
    updateFrame.elapsed = 0
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.03 then
            self.elapsed = 0
            UpdateCastBar()
            UpdateTargetHP()
        end
    end)
    print("|cff00FF00[DoroxAuras]|r Cast Bar & Target HP loaded")
end

function DoroxAurasCastBar:Test()
    CreatePlayerCastBar()
    CreateTargetHPBar()
    testMode = true
    playerCastBar.spellName:SetText("Soul Fire")
    playerCastBar.castTime:SetText("2.5")
    playerCastBar.bar:SetValue(0.5)
    playerCastBar.icon:SetTexture("Interface\\Icons\\Spell_Fire_Fireball02")
    playerCastBar:Show()
    targetHPBar.percent:SetText("32.5%")
    targetHPBar.bar:SetValue(32.5)
    targetHPBar.targetName:SetText("Test Boss")
    targetHPBar.spellReminder:SetText(">>> Soul Fire <<<")
    targetHPBar.spellReminder:Show()
    targetHPBar.glow:Show()
    targetHPBar:Show()
    print("|cff00FF00[DoroxAuras]|r Test Mode (5 sec)")
    local timer = CreateFrame("Frame")
    timer.t = 0
    timer:SetScript("OnUpdate", function(s, e)
        s.t = s.t + e
        if s.t >= 5 then
            s:SetScript("OnUpdate", nil)
            testMode = false
            playerCastBar:Hide()
            targetHPBar:Hide()
            targetHPBar.glow:Hide()
            targetHPBar.spellReminder:Hide()
        end
    end)
end

function DoroxAurasCastBar:GetSpec()
    return GetWarlockSpec()
end

function DoroxAurasCastBar:Unlock()
    CreatePlayerCastBar()
    CreateTargetHPBar()
    testMode = true
    playerCastBar.spellName:SetText("Cast Bar")
    playerCastBar.castTime:SetText("--")
    playerCastBar.bar:SetValue(0.5)
    playerCastBar:Show()
    targetHPBar.percent:SetText("35%")
    targetHPBar.bar:SetValue(35)
    targetHPBar.targetName:SetText("Target HP")
    targetHPBar:Show()
    print("|cff00FF00[DoroxAuras]|r Cast Bar frames unlocked - drag to reposition")
end

function DoroxAurasCastBar:Lock()
    testMode = false
    if playerCastBar then playerCastBar:Hide() end
    if targetHPBar then targetHPBar:Hide() end
    print("|cff00FF00[DoroxAuras]|r Cast Bar frames locked")
end

function DoroxAurasCastBar:ToggleDummyMode()
    dummyMode = not dummyMode
    if dummyMode then
        print("|cff00FF00[DoroxAuras]|r Dummy Mode ON - Target HP bar always visible, no sound alerts")
        print("  Cast bar works normally. Target a dummy to see the HP bar.")
        print("  Type |cffFFFF00/da dummy|r again to disable.")
    else
        print("|cff00FF00[DoroxAuras]|r Dummy Mode OFF - Normal execute phase tracking")
        if targetHPBar then targetHPBar:Hide() end
    end
end

function DoroxAurasCastBar:IsDummyMode()
    return dummyMode
end
