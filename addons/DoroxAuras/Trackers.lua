-- Trackers.lua - Aura tracking logic
DoroxAurasTrackers = {}

local aurasByUnit = {}  -- {player = {}, target = {}, pet = {}}
local spellTextureCache = {}
local talentCache = {}
local lastTalentCheck = 0

-- Demonic Circle tracking
local demonicCircle = {
    exists = false,
    x = 0,
    y = 0,
    mapId = nil,
    placedTime = 0,
}

-- Get player map position
local function GetPlayerPosition()
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    local mapId = GetCurrentMapAreaID()
    return x, y, mapId
end

-- Calculate distance between two map coordinates (approximate yards)
local function GetMapDistance(x1, y1, x2, y2)
    if not x1 or not y1 or not x2 or not y2 then return 999 end
    if x1 == 0 and y1 == 0 then return 999 end
    if x2 == 0 and y2 == 0 then return 999 end

    -- Map coordinates are 0-1, roughly 1000-1500 yards per zone
    -- This is an approximation
    local dx = (x2 - x1) * 1000
    local dy = (y2 - y1) * 1000
    return math.sqrt(dx * dx + dy * dy)
end

-- Get direction arrow based on angle
local function GetDirectionArrow(playerX, playerY, targetX, targetY, playerFacing)
    if not playerX or not targetX then return "" end

    local angle = math.atan2(targetY - playerY, targetX - playerX)
    local relative = angle - playerFacing

    -- Normalize to 0-2pi
    while relative < 0 do relative = relative + (2 * math.pi) end
    while relative > (2 * math.pi) do relative = relative - (2 * math.pi) end

    -- Convert to 8 directions
    local segment = math.floor((relative + math.pi/8) / (math.pi/4)) % 8
    local arrows = {"→", "↗", "↑", "↖", "←", "↙", "↓", "↘"}
    return arrows[segment + 1] or "?"
end

-- Check if Demonic Circle: Teleport is usable
local function IsDemonicCircleUsable()
    local usable, noMana = IsUsableSpell("Demonic Circle: Teleport")
    return usable
end

-- Called when Demonic Circle: Summon is cast
function DoroxAurasTrackers:OnDemonicCircleSummoned()
    local x, y, mapId = GetPlayerPosition()
    demonicCircle.exists = true
    demonicCircle.x = x
    demonicCircle.y = y
    demonicCircle.mapId = mapId
    demonicCircle.placedTime = GetTime()
end

-- Check Demonic Circle status
function DoroxAurasTrackers:GetDemonicCircleStatus()
    -- Circle expires after 6 minutes
    if demonicCircle.exists and (GetTime() - demonicCircle.placedTime) > 360 then
        demonicCircle.exists = false
    end

    -- Also check via spell usability as backup
    local teleportUsable = IsDemonicCircleUsable()

    if not demonicCircle.exists and not teleportUsable then
        return "missing", nil, nil
    end

    -- Get current position and calculate distance
    local playerX, playerY, currentMap = GetPlayerPosition()

    -- Different zone = out of range
    if demonicCircle.mapId and currentMap ~= demonicCircle.mapId then
        return "out_of_range", 999, "?"
    end

    local distance = GetMapDistance(playerX, playerY, demonicCircle.x, demonicCircle.y)

    if distance > 40 then
        local facing = GetPlayerFacing() or 0
        local arrow = GetDirectionArrow(playerX, playerY, demonicCircle.x, demonicCircle.y, facing)
        return "out_of_range", distance, arrow
    end

    return "ready", distance, nil
end

-- Get spell texture (cached)
local function GetSpellTexture(spellName)
    if spellTextureCache[spellName] then
        if DoroxAurasDebug and DoroxAurasDebug:IsEnabled() then
            DoroxAurasDebug:LogIconLookup(spellName, spellTextureCache[spellName], true)
        end
        return spellTextureCache[spellName]
    end

    local _, _, icon = GetSpellInfo(spellName)
    if icon then
        spellTextureCache[spellName] = icon
        if DoroxAurasDebug and DoroxAurasDebug:IsEnabled() then
            DoroxAurasDebug:LogIconLookup(spellName, icon, false)
        end
        return icon
    end

    local missingIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    if DoroxAurasDebug and DoroxAurasDebug:IsEnabled() then
        DoroxAurasDebug:LogIconLookup(spellName, missingIcon, false)
    end
    return missingIcon
end

-- Check if player is in raid/party
local function IsInGroup()
    return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
end

local function IsInRaid()
    return GetNumRaidMembers() > 0
end

-- Check if player has a talent/spell (cached, refreshed every 5 seconds)
local function HasTalent(spellName)
    local now = GetTime()

    -- Refresh cache every 5 seconds
    if (now - lastTalentCheck) > 5 then
        talentCache = {}
        lastTalentCheck = now
    end

    if talentCache[spellName] ~= nil then
        return talentCache[spellName]
    end

    -- Check if spell exists in spellbook
    local name = GetSpellInfo(spellName)
    if name then
        -- Try to find it in spellbook
        local i = 1
        while true do
            local sName = GetSpellName(i, BOOKTYPE_SPELL)
            if not sName then break end
            if sName == spellName then
                talentCache[spellName] = true
                return true
            end
            i = i + 1
        end
    end

    talentCache[spellName] = false
    return false
end

-- Warlock pet names (localized names may vary, these are common)
local PET_TYPES = {
    -- English
    ["Imp"] = "Imp",
    ["Voidwalker"] = "Voidwalker",
    ["Succubus"] = "Succubus",
    ["Felhunter"] = "Felhunter",
    ["Felguard"] = "Felguard",
    -- Spanish (for Warmane)
    ["Diablillo"] = "Imp",
    ["Abisario"] = "Voidwalker",
    ["Súcubo"] = "Succubus",
    ["Manáfago"] = "Felhunter",
    ["Guardia vil"] = "Felguard",
}

-- Get current pet type
local function GetPetType()
    if not UnitExists("pet") then
        return nil
    end

    local petName = UnitName("pet")
    local petFamily = UnitCreatureFamily("pet")

    -- Check by creature family first (most reliable)
    if petFamily then
        if petFamily == "Imp" or petFamily == "Diablillo" then return "Imp" end
        if petFamily == "Voidwalker" or petFamily == "Abisario" then return "Voidwalker" end
        if petFamily == "Succubus" or petFamily == "Súcubo" then return "Succubus" end
        if petFamily == "Felhunter" or petFamily == "Manáfago" then return "Felhunter" end
        if petFamily == "Felguard" or petFamily == "Guardia vil" then return "Felguard" end
    end

    -- Fallback: check pet abilities to determine type
    -- Felhunter has Fel Intelligence
    for i = 1, 10 do
        local name = GetPetActionInfo(i)
        if name then
            if name == "Fel Intelligence" or name == "Inteligencia vil" then
                return "Felhunter"
            elseif name == "Consume Shadows" or name == "Consumir sombras" then
                return "Voidwalker"
            elseif name == "Fire Shield" or name == "Escudo de Fuego" then
                return "Imp"
            elseif name == "Lash of Pain" or name == "Látigo de dolor" then
                return "Succubus"
            elseif name == "Anguish" or name == "Angustia" then
                return "Felguard"
            end
        end
    end

    return "Unknown"
end

-- Cache for raid composition
local raidClassCount = {}
local lastRaidScan = 0

-- Scan raid/party for class composition
local function ScanRaidComposition()
    local now = GetTime()
    -- Only rescan every 2 seconds
    if (now - lastRaidScan) < 2 then
        return raidClassCount
    end
    lastRaidScan = now
    raidClassCount = {}

    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()

    if numRaid > 0 then
        for i = 1, numRaid do
            local _, class = UnitClass("raid" .. i)
            if class then
                raidClassCount[class] = (raidClassCount[class] or 0) + 1
            end
        end
    elseif numParty > 0 then
        -- Include self
        local _, myClass = UnitClass("player")
        if myClass then
            raidClassCount[myClass] = 1
        end
        for i = 1, numParty do
            local _, class = UnitClass("party" .. i)
            if class then
                raidClassCount[class] = (raidClassCount[class] or 0) + 1
            end
        end
    end

    return raidClassCount
end

-- Count how many paladin blessings the player currently has
local function CountCurrentBlessings()
    local blessings = {
        "Blessing of Kings", "Greater Blessing of Kings",
        "Blessing of Wisdom", "Greater Blessing of Wisdom",
        "Blessing of Sanctuary", "Greater Blessing of Sanctuary",
        "Blessing of Might", "Greater Blessing of Might",
    }
    local count = 0
    for _, blessing in ipairs(blessings) do
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == blessing then
                count = count + 1
                break  -- Only count each blessing type once
            end
        end
    end
    return count
end

-- Check if aura conditions are met
local function CheckAuraConditions(auraConfig)
    local debug = DoroxAurasDebug and DoroxAurasDebug:IsEnabled()

    -- Check talent requirement
    if auraConfig.requires_talent then
        if not HasTalent(auraConfig.requires_talent) then
            if debug then
                DoroxAurasDebug:LogConditionCheck(auraConfig, false, "missing_talent:" .. auraConfig.requires_talent)
            end
            return false
        end
    end

    -- Check pet requirement
    if auraConfig.requires_pet then
        local currentPet = GetPetType()
        local hasPet = UnitExists("pet")

        -- If show_if_no_pet is true, allow showing when no pet exists
        if auraConfig.show_if_no_pet and not hasPet then
            -- No pet = show as missing (continue to check other conditions)
            if debug then
                DoroxAurasDebug:LogConditionCheck(auraConfig, true, "no_pet_show_missing")
            end
        elseif currentPet ~= auraConfig.requires_pet then
            -- Wrong pet type = hide
            if debug then
                DoroxAurasDebug:LogConditionCheck(auraConfig, false, "wrong_pet:" .. (currentPet or "none") .. "!=" .. auraConfig.requires_pet)
            end
            return false
        end
    end

    -- Check required class in raid (for raid buffs)
    if auraConfig.required_class then
        local classes = ScanRaidComposition()
        local classCount = classes[auraConfig.required_class] or 0
        if classCount == 0 then
            if debug then
                DoroxAurasDebug:LogConditionCheck(auraConfig, false, "no_class_in_raid:" .. auraConfig.required_class)
            end
            return false  -- No one of this class in raid, don't show missing buff
        end

        -- Special handling for paladin blessings
        if auraConfig.is_paladin_blessing then
            local numPaladins = classes["PALADIN"] or 0
            local currentBlessings = CountCurrentBlessings()

            -- If we already have as many blessings as paladins, don't show more as missing
            if currentBlessings >= numPaladins then
                if debug then
                    DoroxAurasDebug:LogConditionCheck(auraConfig, false, "blessing_limit:" .. currentBlessings .. ">=" .. numPaladins)
                end
                return false
            end
        end
    end

    -- Check if we should hide when certain classes are present
    -- (e.g., don't show Curse of Elements if Druid/DK can apply equivalent debuff)
    if auraConfig.hide_if_class_present then
        local classes = ScanRaidComposition()
        for _, className in ipairs(auraConfig.hide_if_class_present) do
            if classes[className] and classes[className] > 0 then
                if debug then
                    DoroxAurasDebug:LogConditionCheck(auraConfig, false, "class_provides_equivalent:" .. className)
                end
                return false
            end
        end
    end

    if debug then
        DoroxAurasDebug:LogConditionCheck(auraConfig, true, "all_conditions_met")
    end
    return true
end

-- Check a single aura on a unit
local function CheckAura(auraConfig, unit)
    local spells = auraConfig.spells or {auraConfig.spell}
    local filter = auraConfig.type == "buff" and "HELPFUL" or "HARMFUL"

    for _, spellName in ipairs(spells) do
        -- Iterate through auras on unit
        for i = 1, 40 do
            local name, rank, icon, count, debuffType, duration, expirationTime, caster

            if filter == "HELPFUL" then
                name, rank, icon, count, debuffType, duration, expirationTime, caster =
                    UnitBuff(unit, i)
            else
                name, rank, icon, count, debuffType, duration, expirationTime, caster =
                    UnitDebuff(unit, i)
            end

            if not name then break end

            -- Check if this is our spell
            if name == spellName then
                -- Check own only filter
                if auraConfig.own then
                    if caster == "player" or caster == "pet" or caster == "vehicle" then
                        local remaining = expirationTime and (expirationTime - GetTime()) or nil
                        return true, icon, remaining, duration, count
                    end
                    -- Not ours, continue searching for our version
                else
                    -- Any caster is fine
                    local remaining = expirationTime and (expirationTime - GetTime()) or nil
                    return true, icon, remaining, duration, count
                end
            end
        end
    end

    return false, nil, nil, nil, nil
end

-- Check if a buff exists on ANY group/raid member
local function CheckGroupBuff(auraConfig)
    local spells = auraConfig.spells or {auraConfig.spell}

    -- Check player first
    for _, spellName in ipairs(spells) do
        for i = 1, 40 do
            local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", i)
            if not name then break end
            if name == spellName then
                local remaining = expirationTime and (expirationTime - GetTime()) or nil
                return true, icon, remaining, duration, count
            end
        end
    end

    -- Check raid members
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for r = 1, numRaid do
            local unit = "raid" .. r
            for _, spellName in ipairs(spells) do
                for i = 1, 40 do
                    local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff(unit, i)
                    if not name then break end
                    if name == spellName then
                        local remaining = expirationTime and (expirationTime - GetTime()) or nil
                        return true, icon, remaining, duration, count
                    end
                end
            end
        end
    else
        -- Check party members
        local numParty = GetNumPartyMembers()
        for p = 1, numParty do
            local unit = "party" .. p
            for _, spellName in ipairs(spells) do
                for i = 1, 40 do
                    local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff(unit, i)
                    if not name then break end
                    if name == spellName then
                        local remaining = expirationTime and (expirationTime - GetTime()) or nil
                        return true, icon, remaining, duration, count
                    end
                end
            end
        end
    end

    return false, nil, nil, nil, nil
end

-- Check if a spell is off cooldown
local function IsSpellReady(spellName)
    local start, duration, enabled = GetSpellCooldown(spellName)
    if not start then return false end  -- Spell not found
    if duration == 0 then return true end  -- No cooldown
    if (start + duration - GetTime()) <= 0 then return true end  -- Cooldown finished
    return false
end

-- Initialize trackers
function DoroxAurasTrackers:Initialize()
    local config = DoroxAurasConfig:GetConfig()

    -- Reset unit indexing
    aurasByUnit = {
        player = {},
        target = {},
        focus = {},
        pet = {},
        group = {},  -- Special: scans all group/raid members
    }

    -- Index auras by unit for efficient lookup
    for _, aura in ipairs(config.auras) do
        local unit = aura.unit or "player"
        if not aurasByUnit[unit] then
            aurasByUnit[unit] = {}
        end
        table.insert(aurasByUnit[unit], aura)

        -- Pre-cache spell textures
        if aura.spell then
            GetSpellTexture(aura.spell)
        elseif aura.spells then
            for _, spell in ipairs(aura.spells) do
                GetSpellTexture(spell)
            end
        end
    end
end

-- Update auras for a specific unit
function DoroxAurasTrackers:UpdateUnit(unit)
    local config = DoroxAurasConfig:GetConfig()

    -- Check if addon is enabled
    if not config.enabled then
        return
    end

    -- Get auras for this unit
    local auras = aurasByUnit[unit]
    if not auras then return end

    -- Check if unit exists
    if not UnitExists(unit) then
        -- Hide all auras for this unit
        for _, auraConfig in ipairs(auras) do
            DoroxAurasDisplay:HideAura(auraConfig)
        end
        return
    end

    -- Check raid status for raid-only auras
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()

    local debug = DoroxAurasDebug and DoroxAurasDebug:IsEnabled()

    for _, auraConfig in ipairs(auras) do
        -- Check talent/pet requirements first
        if not CheckAuraConditions(auraConfig) then
            DoroxAurasDisplay:HideAura(auraConfig)
        -- Skip raid-only auras when not in raid
        elseif auraConfig.in_raid_only and not inRaid then
            if debug then
                DoroxAurasDebug:LogConditionCheck(auraConfig, false, "not_in_raid")
            end
            DoroxAurasDisplay:HideAura(auraConfig)
        -- Skip group-only auras when solo
        elseif auraConfig.in_group_only and not inGroup then
            if debug then
                DoroxAurasDebug:LogConditionCheck(auraConfig, false, "not_in_group")
            end
            DoroxAurasDisplay:HideAura(auraConfig)
        else
            local found, icon, remaining, duration, stacks = CheckAura(auraConfig, unit)

            -- Log scan result
            if debug then
                DoroxAurasDebug:LogAuraScan(unit, auraConfig, found, icon, remaining, stacks)
            end

            if found then
                -- Check if we should hide when "healthy" (active with plenty of time left)
                if auraConfig.hide_when_healthy and remaining and auraConfig.refresh_warn then
                    if remaining > auraConfig.refresh_warn then
                        -- Aura is healthy, hide it
                        DoroxAurasDisplay:HideAura(auraConfig)
                    else
                        -- Aura is expiring soon, show it
                        DoroxAurasDisplay:ShowAura(auraConfig, icon, remaining, duration, stacks)
                    end
                else
                    -- Normal behavior: show when active
                    DoroxAurasDisplay:ShowAura(auraConfig, icon, remaining, duration, stacks)
                end
            else
                -- Aura not found
                if auraConfig.show_missing then
                    -- Show as missing (desaturated)
                    local texture = GetSpellTexture(auraConfig.spell or auraConfig.spells[1])
                    local iconFrame = DoroxAurasDisplay:GetIcon(auraConfig)
                    if iconFrame then
                        DoroxAurasDisplay:ShowMissing(iconFrame, texture, nil, auraConfig.glow_on_missing)
                        DoroxAurasDisplay:ArrangeGroup(auraConfig.group)
                    end
                else
                    DoroxAurasDisplay:HideAura(auraConfig)
                end
            end
        end
    end
end

-- Update weapon enchants (Spellstone, etc.)
function DoroxAurasTrackers:UpdateWeaponEnchants()
    local config = DoroxAurasConfig:GetConfig()

    if not config.enabled then return end
    if not config.weapon_enchants then return end

    local hasMainHandEnchant, mainHandExpiration, mainHandCharges,
          hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()

    for _, enchantConfig in ipairs(config.weapon_enchants) do
        local hasEnchant, expiration

        if enchantConfig.slot == "main" then
            hasEnchant = hasMainHandEnchant
            expiration = mainHandExpiration and (mainHandExpiration / 1000) or nil
        else
            hasEnchant = hasOffHandEnchant
            expiration = offHandExpiration and (offHandExpiration / 1000) or nil
        end

        if hasEnchant then
            -- Get texture - try spell first, fallback to item
            local texture = GetSpellTexture(enchantConfig.enchant)
            if texture == "Interface\\Icons\\INV_Misc_QuestionMark" then
                texture = "Interface\\Icons\\INV_Misc_Gem_01"
            end

            -- Check if we should hide when "healthy"
            if enchantConfig.hide_when_healthy and expiration and enchantConfig.refresh_warn then
                if expiration > enchantConfig.refresh_warn then
                    -- Enchant is healthy, hide it
                    DoroxAurasDisplay:HideAura(enchantConfig)
                else
                    -- Enchant is expiring soon, show it
                    DoroxAurasDisplay:ShowAura(enchantConfig, texture, expiration, nil, nil)
                end
            else
                -- Normal behavior: show when active
                DoroxAurasDisplay:ShowAura(enchantConfig, texture, expiration, nil, nil)
            end
        else
            if enchantConfig.show_missing then
                local texture = "Interface\\Icons\\INV_Misc_Gem_01"
                local iconFrame = DoroxAurasDisplay:GetIcon(enchantConfig)
                if iconFrame then
                    DoroxAurasDisplay:ShowMissing(iconFrame, texture, enchantConfig.name, enchantConfig.glow_on_missing)
                    DoroxAurasDisplay:ArrangeGroup(enchantConfig.group)
                end
            else
                DoroxAurasDisplay:HideAura(enchantConfig)
            end
        end
    end
end

-- Update all units
function DoroxAurasTrackers:UpdateAll()
    self:UpdateUnit("player")

    if UnitExists("target") then
        self:UpdateUnit("target")
    else
        -- Clear target debuffs
        local auras = aurasByUnit["target"]
        if auras then
            for _, auraConfig in ipairs(auras) do
                DoroxAurasDisplay:HideAura(auraConfig)
            end
        end
    end

    if UnitExists("focus") then
        self:UpdateUnit("focus")
    end

    if UnitExists("pet") then
        self:UpdateUnit("pet")
    else
        -- Clear pet buffs
        local auras = aurasByUnit["pet"]
        if auras then
            for _, auraConfig in ipairs(auras) do
                DoroxAurasDisplay:HideAura(auraConfig)
            end
        end
    end

    self:UpdateGroupBuffs()
    self:UpdateWeaponEnchants()
    self:UpdateSpecialAuras()
end

-- Update special auras (items in bags, Demonic Circle, etc.)
function DoroxAurasTrackers:UpdateSpecialAuras()
    local config = DoroxAurasConfig:GetConfig()
    if not config.enabled then return end

    for _, auraConfig in ipairs(config.auras) do
        -- Handle item type (check bags)
        if auraConfig.type == "item" and auraConfig.item_ids then
            local hasItem = false
            local itemTexture = nil

            for _, itemId in ipairs(auraConfig.item_ids) do
                local count = GetItemCount(itemId)
                if count and count > 0 then
                    hasItem = true
                    itemTexture = GetItemIcon(itemId)
                    break
                end
            end

            if hasItem then
                DoroxAurasDisplay:HideAura(auraConfig)  -- Have item, hide
            else
                if auraConfig.show_missing then
                    -- Show missing with first item's icon
                    local texture = GetItemIcon(auraConfig.item_ids[1]) or "Interface\\Icons\\INV_Misc_QuestionMark"
                    local iconFrame = DoroxAurasDisplay:GetIcon(auraConfig)
                    if iconFrame then
                        DoroxAurasDisplay:ShowMissing(iconFrame, texture, nil, auraConfig.glow_on_missing)
                        DoroxAurasDisplay:ArrangeGroup(auraConfig.group)
                    end
                end
            end
        end

        -- Handle Demonic Circle special tracking
        if auraConfig.type == "special" and auraConfig.spell == "Demonic Circle: Teleport" then
            local status, distance, arrow = self:GetDemonicCircleStatus()

            if status == "missing" then
                if auraConfig.show_missing then
                    local texture = GetSpellTexture(auraConfig.summon_spell or auraConfig.spell)
                    local iconFrame = DoroxAurasDisplay:GetIcon(auraConfig)
                    if iconFrame then
                        DoroxAurasDisplay:ShowMissing(iconFrame, texture, "PLACE!", auraConfig.glow_on_missing)
                        DoroxAurasDisplay:ArrangeGroup(auraConfig.group)
                    end
                end
            elseif status == "out_of_range" then
                -- Show with distance and direction
                local texture = GetSpellTexture(auraConfig.spell)
                local iconFrame = DoroxAurasDisplay:GetIcon(auraConfig)
                if iconFrame then
                    iconFrame.icon:SetTexture(texture)
                    iconFrame.icon:SetDesaturated(false)
                    iconFrame.isMissing = false

                    -- Show distance and arrow
                    local distText = distance < 100 and string.format("%d", distance) or "FAR"
                    iconFrame.timer:SetText(arrow or "?")
                    iconFrame.timer:SetTextColor(1, 0.5, 0)  -- Orange
                    iconFrame.timer:Show()

                    iconFrame.stacks:SetText(distText)
                    iconFrame.stacks:Show()

                    -- Show glow for warning
                    iconFrame.glow:Show()
                    iconFrame:SetBackdropBorderColor(1, 0.5, 0, 1)
                    iconFrame:Show()

                    DoroxAurasDisplay:ArrangeGroup(auraConfig.group)
                end
            else
                -- Ready - hide or show green
                DoroxAurasDisplay:HideAura(auraConfig)
            end
        end
    end
end

-- Update group-wide buff tracking (Soulstone, etc.)
function DoroxAurasTrackers:UpdateGroupBuffs()
    local config = DoroxAurasConfig:GetConfig()

    if not config.enabled then return end

    local auras = aurasByUnit["group"]
    if not auras then return end

    local inGroup = IsInGroup()
    local debug = DoroxAurasDebug and DoroxAurasDebug:IsEnabled()

    for _, auraConfig in ipairs(auras) do
        -- Check if we should only show in group
        if auraConfig.in_group_only and not inGroup then
            DoroxAurasDisplay:HideAura(auraConfig)
        else
            -- Check cooldown requirement
            local cooldownReady = true
            if auraConfig.check_cooldown and auraConfig.cooldown_spell then
                cooldownReady = IsSpellReady(auraConfig.cooldown_spell)
            end

            if not cooldownReady then
                -- Spell on cooldown, hide the icon
                DoroxAurasDisplay:HideAura(auraConfig)
            else
                -- Scan group for the buff
                local found, icon, remaining, duration, stacks = CheckGroupBuff(auraConfig)

                if debug then
                    DoroxAurasDebug:LogAuraScan("group", auraConfig, found, icon, remaining, stacks)
                end

                if found then
                    DoroxAurasDisplay:HideAura(auraConfig)  -- Someone has it, hide
                else
                    -- No one has it, show as missing
                    if auraConfig.show_missing then
                        local texture = GetSpellTexture(auraConfig.spell or auraConfig.spells[1])
                        local iconFrame = DoroxAurasDisplay:GetIcon(auraConfig)
                        if iconFrame then
                            DoroxAurasDisplay:ShowMissing(iconFrame, texture, nil, auraConfig.glow_on_missing)
                            DoroxAurasDisplay:ArrangeGroup(auraConfig.group)
                        end
                    else
                        DoroxAurasDisplay:HideAura(auraConfig)
                    end
                end
            end
        end
    end
end

-- Clear all displayed auras
function DoroxAurasTrackers:ClearAll()
    local config = DoroxAurasConfig:GetConfig()

    for _, aura in ipairs(config.auras) do
        DoroxAurasDisplay:HideAura(aura)
    end

    if config.weapon_enchants then
        for _, enchant in ipairs(config.weapon_enchants) do
            DoroxAurasDisplay:HideAura(enchant)
        end
    end
end

-- Get spell texture (public helper)
function DoroxAurasTrackers:GetSpellTexture(spellName)
    return GetSpellTexture(spellName)
end
