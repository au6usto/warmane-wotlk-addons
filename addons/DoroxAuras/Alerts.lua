-- Alerts.lua - Sound and visual alert system
DoroxAurasAlerts = {}

local soundCooldowns = {}
local SOUND_COOLDOWN = 1  -- Seconds between same sound

-- Sound file mappings
local soundFiles = {
    raid_warning = "Sound\\Interface\\RaidWarning.wav",
    map_ping = "Sound\\Interface\\MapPing.wav",
    levelup = "Sound\\Interface\\LevelUp.wav",
    ready_check = "Sound\\Interface\\ReadyCheck.wav",
    pvp_flag = "Sound\\Spells\\PVPFlagTaken.wav",
    alarm = "Sound\\Doodad\\BellTollNightElf.wav",
}

-- Play sound with cooldown
function DoroxAurasAlerts:PlaySound(soundKey)
    local now = GetTime()

    -- Check cooldown
    if soundCooldowns[soundKey] and (now - soundCooldowns[soundKey]) < SOUND_COOLDOWN then
        return
    end

    soundCooldowns[soundKey] = now

    -- Get sound file
    local soundFile = soundFiles[soundKey]
    if not soundFile then
        -- Try custom sound from config
        local config = DoroxAurasConfig:GetConfig()
        if config.sounds and config.sounds[soundKey] then
            soundFile = config.sounds[soundKey]
        end
    end

    if soundFile then
        PlaySoundFile(soundFile)
    end
end

-- Screen flash for high-priority alerts
local flashFrame = nil

function DoroxAurasAlerts:FlashScreen(color)
    if not flashFrame then
        flashFrame = CreateFrame("Frame", "DoroxAurasFlash", UIParent)
        flashFrame:SetAllPoints(UIParent)
        flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")

        local tex = flashFrame:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\FullScreenTextures\\LowHealth")
        tex:SetBlendMode("ADD")
        flashFrame.texture = tex

        flashFrame:Hide()
    end

    -- Set color (default yellow/gold)
    local r, g, b = 1, 0.8, 0
    if color == "red" then
        r, g, b = 1, 0.2, 0.2
    elseif color == "green" then
        r, g, b = 0.2, 1, 0.2
    elseif color == "blue" then
        r, g, b = 0.2, 0.5, 1
    end

    flashFrame.texture:SetVertexColor(r, g, b, 0.4)
    flashFrame:Show()

    -- Fade out animation
    local alpha = 0.4
    flashFrame:SetScript("OnUpdate", function(self, elapsed)
        alpha = alpha - elapsed * 2
        if alpha <= 0 then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        else
            self.texture:SetAlpha(alpha)
        end
    end)
end

-- Center screen text alert (like RaidWarning)
local alertFrame = nil

function DoroxAurasAlerts:ShowAlert(text, color)
    if not alertFrame then
        alertFrame = CreateFrame("Frame", "DoroxAurasAlert", UIParent)
        alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
        alertFrame:SetWidth(500)
        alertFrame:SetHeight(50)
        alertFrame:SetFrameStrata("HIGH")

        alertFrame.text = alertFrame:CreateFontString(nil, "OVERLAY")
        alertFrame.text:SetPoint("CENTER")
        alertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
        alertFrame.text:SetTextColor(1, 0.8, 0, 1)

        alertFrame:Hide()
    end

    -- Set color
    local r, g, b = 1, 0.8, 0
    if color == "red" then
        r, g, b = 1, 0.3, 0.3
    elseif color == "green" then
        r, g, b = 0.3, 1, 0.3
    elseif color == "blue" then
        r, g, b = 0.3, 0.7, 1
    end

    alertFrame.text:SetText(text)
    alertFrame.text:SetTextColor(r, g, b, 1)
    alertFrame:Show()

    -- Fade out after 2 seconds
    local remaining = 2
    alertFrame:SetScript("OnUpdate", function(self, elapsed)
        remaining = remaining - elapsed
        if remaining <= 0.5 then
            self.text:SetAlpha(remaining * 2)
        end
        if remaining <= 0 then
            self:Hide()
            self:SetScript("OnUpdate", nil)
            self.text:SetAlpha(1)
        end
    end)
end

-- Trigger glow on specific icon
function DoroxAurasAlerts:TriggerGlow(auraConfig)
    local icon = DoroxAurasDisplay:GetIcon(auraConfig)
    if icon then
        icon.glow:Show()
        icon.glowAnimating = true
    end
end

-- Stop glow on specific icon
function DoroxAurasAlerts:StopGlow(auraConfig)
    local icon = DoroxAurasDisplay:GetIcon(auraConfig)
    if icon then
        icon.glow:Hide()
        icon.glowAnimating = false
    end
end

-- Register a custom sound
function DoroxAurasAlerts:RegisterSound(key, filePath)
    soundFiles[key] = filePath
end

-- Get available sounds
function DoroxAurasAlerts:GetSounds()
    return soundFiles
end
