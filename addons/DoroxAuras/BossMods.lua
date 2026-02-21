-- BossMods.lua - Boss encounter tracking for ICC, TOGC, RS
DoroxAurasBossMods = {}

local currentZone = ""
local currentBoss = ""
local inEncounter = false
local encounterStartTime = 0

-- Spell IDs for WotLK 3.3.5 (some use names for compatibility)
local SPELLS = {
    -- Player abilities
    SHADOW_WARD = "Shadow Ward",
    EVERY_MAN = "Every Man for Himself",
    CURSE_OF_TONGUES = "Curse of Tongues",

    -- ICC - Lady Deathwhisper
    VENGEFUL_SHADE = "Vengeful Blast",  -- The debuff from shade

    -- ICC - Saurfang
    MARK_OF_FALLEN_CHAMPION = "Mark of the Fallen Champion",
    DIVINE_INTERVENTION = "Divine Intervention",

    -- ICC - Rotface
    MUTATED_INFECTION = "Mutated Infection",
    SLIME_SPRAY = "Slime Spray",
    UNSTABLE_OOZE_EXPLOSION = "Unstable Ooze Explosion",

    -- ICC - Blood Princes
    KELESETH = "Prince Keleseth",
    TALDARAM = "Prince Taldaram",
    VALANAR = "Prince Valanar",
    EMPOWERED_SHOCK_VORTEX = "Empowered Shock Vortex",
    INVOCATION_OF_BLOOD = "Invocation of Blood",

    -- ICC - Blood Queen
    VAMPIRIC_BITE = "Vampiric Bite",
    ESSENCE_OF_BLOOD_QUEEN = "Essence of the Blood Queen",
    FRENZIED_BLOODTHIRST = "Frenzied Bloodthirst",
    PACT_OF_DARKFALLEN = "Pact of the Darkfallen",
    SWARMING_SHADOWS = "Swarming Shadows",

    -- ICC - Sindragosa
    UNCHAINED_MAGIC = "Unchained Magic",
    INSTABILITY = "Instability",
    ICE_TOMB = "Ice Tomb",
    FROST_BEACON = "Frost Beacon",
    MYSTIC_BUFFET = "Mystic Buffet",

    -- ICC - Lich King
    NECROTIC_PLAGUE = "Necrotic Plague",
    DEFILE = "Defile",
    HARVEST_SOUL = "Harvest Soul",
    SOUL_RIP = "Soul Rip",
    VILE_SPIRITS = "Vile Spirits",
    SHADOW_TRAP = "Shadow Trap",

    -- TOGC - Gormok
    FIRE_BOMB = "Fire Bomb",
    IMPALE = "Impale",

    -- TOGC - Acidmaw/Dreadscale
    PARALYTIC_TOXIN = "Paralytic Toxin",
    BURNING_BILE = "Burning Bile",
    SLIME_POOL = "Slime Pool",
    ACID_SPEW = "Acid Spew",
    MOLTEN_SPEW = "Molten Spew",

    -- TOGC - Jaraxxus
    LEGION_FLAME = "Legion Flame",
    INCINERATE_FLESH = "Incinerate Flesh",
    TOUCH_OF_JARAXXUS = "Touch of Jaraxxus",

    -- TOGC - Faction Champions (CC)
    POLYMORPH = "Polymorph",
    BLIND = "Blind",
    HAMMER_OF_JUSTICE = "Hammer of Justice",
    MORTAL_STRIKE = "Mortal Strike",
    WOUND_POISON = "Wound Poison",
    FEAR = "Fear",
    PSYCHIC_SCREAM = "Psychic Scream",

    -- TOGC - Twin Val'kyr
    LIGHT_ESSENCE = "Light Essence",
    DARK_ESSENCE = "Dark Essence",
    LIGHT_VORTEX = "Light Vortex",
    DARK_VORTEX = "Dark Vortex",
    TWINS_PACT = "Twin's Pact",

    -- RS - Halion
    FIERY_COMBUSTION = "Fiery Combustion",
    SOUL_CONSUMPTION = "Soul Consumption",
    METEOR_STRIKE = "Meteor Strike",
    TWILIGHT_CUTTER = "Twilight Cutter",
    CORPOREALITY = "Corporeality",
}

-- Zone IDs
local ZONES = {
    ICC = "Icecrown Citadel",
    TOGC = "Trial of the Crusader",
    RS = "The Ruby Sanctum",
}

-- Boss configs with mechanics
local BOSS_CONFIGS = {
    -- ==================== ICC ====================
    ["Lady Deathwhisper"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Vengeful Shade",
                spell = "Vengeful Blast",
                type = "debuff",
                unit = "player",
                message = "SHADE ON YOU! RUN OPPOSITE!",
                sound = "raid_warning",
                glow = true,
                arrow = "away_from_target",  -- Special: point away from shade
                color = "red",
            },
        },
    },

    ["Deathbringer Saurfang"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Mark of the Fallen Champion",
                spell = "Mark of the Fallen Champion",
                type = "debuff",
                unit = "player",
                message = "MARK ON YOU! Watch for Divine Intervention",
                sound = "raid_warning",
                glow = true,
                color = "red",
            },
            {
                name = "Divine Intervention",
                spell = "Divine Intervention",
                type = "buff",
                unit = "player",
                message = "DIVINE INTERVENTION - STOP CASTING!",
                sound = "alarm",
                glow = true,
                color = "yellow",
                on_fade = "DI FADED - RESUME CASTING!",
            },
        },
    },

    ["Rotface"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Mutated Infection",
                spell = "Mutated Infection",
                type = "debuff",
                unit = "player",
                message = "INFECTION! RUN TO OFF-TANK (OOZE)",
                sound = "raid_warning",
                glow = true,
                arrow = "fixed",  -- Point to ooze position
                arrow_angle = 45,  -- Configurable
                color = "green",
            },
            {
                name = "Slime Spray",
                spell = "Slime Spray",
                type = "cast",
                message = "SLIME SPRAY - MOVE BEHIND BOSS!",
                sound = "map_ping",
                duration = 3,
            },
            {
                name = "Unstable Ooze Explosion",
                spell = "Unstable Ooze Explosion",
                type = "cast",
                message = "BIG OOZE EXPLOSION! STOP MOVING then RUN!",
                sound = "raid_warning",
                color = "orange",
            },
        },
    },

    ["Blood Prince Council"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Keleseth Active",
                trigger = "keleseth_active",
                message = "KELESETH ACTIVE - Cast Curse of Tongues!",
                sound = "map_ping",
                glow = true,
                color = "purple",
                action_spell = "Curse of Tongues",
            },
            {
                name = "Empowered Shock Vortex",
                spell = "Empowered Shock Vortex",
                type = "debuff",
                unit = "player",
                message = "SHOCK VORTEX! SPREAD 12 YARDS!",
                sound = "raid_warning",
                glow = true,
                color = "blue",
            },
            {
                name = "Valanar Active",
                trigger = "valanar_active",
                message = "VALANAR ACTIVE - Spread for Vortex",
                sound = "map_ping",
            },
        },
    },

    ["Blood-Queen Lana'thel"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Essence of Blood Queen",
                spell = "Essence of the Blood Queen",
                type = "buff",
                unit = "player",
                message = "YOU HAVE ESSENCE! Bite someone at timer!",
                sound = "raid_warning",
                glow = true,
                color = "red",
                show_timer = true,
            },
            {
                name = "Frenzied Bloodthirst",
                spell = "Frenzied Bloodthirst",
                type = "debuff",
                unit = "player",
                message = "BITE NOW or MC!",
                sound = "alarm",
                glow = true,
                flash = true,
                color = "red",
            },
            {
                name = "Pact of the Darkfallen",
                spell = "Pact of the Darkfallen",
                type = "debuff",
                unit = "player",
                message = "PACT! Group with linked players!",
                sound = "raid_warning",
                glow = true,
                color = "purple",
            },
            {
                name = "Swarming Shadows",
                spell = "Swarming Shadows",
                type = "debuff",
                unit = "player",
                message = "SHADOWS! Run to wall!",
                sound = "raid_warning",
                arrow = "fixed",
                arrow_angle = 180,
                color = "purple",
            },
        },
    },

    ["Sindragosa"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Unchained Magic",
                spell = "Unchained Magic",
                type = "debuff",
                unit = "player",
                message = "UNCHAINED MAGIC! Watch stacks!",
                sound = "map_ping",
                glow = true,
                show_stacks = true,
                stack_threshold = 4,  -- Warn at 4+ stacks
                stack_message = "HIGH STACKS! STOP CASTING!",
                color = "blue",
            },
            {
                name = "Instability",
                spell = "Instability",
                type = "debuff",
                unit = "player",
                show_stacks = true,
                color = "blue",
            },
            {
                name = "Frost Beacon",
                spell = "Frost Beacon",
                type = "debuff",
                unit = "player",
                message = "ICE TOMB ON YOU! Run to position!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                arrow = "fixed",
                arrow_angle = 0,  -- Towards safe spot
                color = "cyan",
            },
            {
                name = "Mystic Buffet",
                spell = "Mystic Buffet",
                type = "debuff",
                unit = "player",
                show_stacks = true,
                stack_threshold = 6,
                stack_message = "HIGH MYSTIC BUFFET! LOS behind tomb!",
                color = "purple",
            },
        },
    },

    ["The Lich King"] = {
        zone = "ICC",
        alerts = {
            {
                name = "Necrotic Plague",
                spell = "Necrotic Plague",
                type = "debuff",
                unit = "player",
                message = "PLAGUE! RUN TO ADDS!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                arrow = "away",
                color = "green",
            },
            {
                name = "Defile",
                spell = "Defile",
                type = "debuff",
                unit = "player",
                message = "DEFILE ON YOU! MOVE OUT!",
                sound = "alarm",
                glow = true,
                flash = true,
                color = "black",
            },
            {
                name = "Harvest Soul",
                spell = "Harvest Soul",
                type = "debuff",
                unit = "player",
                message = "HARVEST SOUL! Kill Spirit Warden inside!",
                sound = "raid_warning",
                glow = true,
                color = "purple",
            },
            {
                name = "Shadow Trap",
                spell = "Shadow Trap",
                type = "debuff",
                unit = "player",
                message = "SHADOW TRAP! DON'T MOVE OFF PLATFORM!",
                sound = "alarm",
                glow = true,
                color = "black",
            },
            {
                name = "Vile Spirits",
                trigger = "vile_spirits",
                message = "VILE SPIRITS! AoE them down!",
                sound = "map_ping",
            },
        },
    },

    -- ==================== TOGC ====================
    ["Gormok the Impaler"] = {
        zone = "TOGC",
        alerts = {
            {
                name = "Fire Bomb",
                spell = "Fire Bomb",
                type = "ground",
                message = "FIRE BOMB! Move away from flames!",
                sound = "raid_warning",
                glow = true,
                color = "orange",
            },
            {
                name = "Impale",
                spell = "Impale",
                type = "debuff",
                unit = "player",
                message = "IMPALE! Healers focus you!",
                sound = "map_ping",
                color = "red",
            },
        },
    },

    ["Acidmaw"] = {
        zone = "TOGC",
        alerts = {
            {
                name = "Paralytic Toxin",
                spell = "Paralytic Toxin",
                type = "debuff",
                unit = "player",
                message = "PARALYTIC TOXIN! Find Burning Bile player!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                color = "green",
            },
            {
                name = "Burning Bile",
                spell = "Burning Bile",
                type = "debuff",
                unit = "player",
                message = "BURNING BILE! Touch Paralyzed player!",
                sound = "raid_warning",
                glow = true,
                color = "orange",
            },
            {
                name = "Slime Pool",
                spell = "Slime Pool",
                type = "ground",
                message = "SLIME POOL! Move out!",
                sound = "map_ping",
                color = "green",
            },
        },
    },

    ["Dreadscale"] = {
        zone = "TOGC",
        alerts = {
            {
                name = "Paralytic Toxin",
                spell = "Paralytic Toxin",
                type = "debuff",
                unit = "player",
                message = "PARALYTIC TOXIN! Find Burning Bile player!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                color = "green",
            },
            {
                name = "Burning Bile",
                spell = "Burning Bile",
                type = "debuff",
                unit = "player",
                message = "BURNING BILE! Touch Paralyzed player!",
                sound = "raid_warning",
                glow = true,
                color = "orange",
            },
        },
    },

    ["Lord Jaraxxus"] = {
        zone = "TOGC",
        alerts = {
            {
                name = "Legion Flame",
                spell = "Legion Flame",
                type = "debuff",
                unit = "player",
                message = "LEGION FLAME! RUN OUT OF RAID!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                arrow = "away",
                color = "orange",
            },
            {
                name = "Incinerate Flesh",
                spell = "Incinerate Flesh",
                type = "debuff",
                unit = "player",
                message = "INCINERATE FLESH! Healers focus you!",
                sound = "raid_warning",
                glow = true,
                color = "red",
            },
            {
                name = "Touch of Jaraxxus",
                spell = "Touch of Jaraxxus",
                type = "debuff",
                unit = "player",
                message = "TOUCH OF JARAXXUS! Stay away from others!",
                sound = "raid_warning",
                glow = true,
                color = "purple",
            },
        },
    },

    ["Faction Champions"] = {
        zone = "TOGC",
        alerts = {
            {
                name = "Polymorph",
                spell = "Polymorph",
                type = "debuff",
                unit = "player",
                message = "POLYMORPHED! Use Every Man for Himself!",
                sound = "raid_warning",
                glow = true,
                action_spell = "Every Man for Himself",
                color = "blue",
            },
            {
                name = "Blind",
                spell = "Blind",
                type = "debuff",
                unit = "player",
                message = "BLINDED! Use Every Man for Himself!",
                sound = "raid_warning",
                glow = true,
                action_spell = "Every Man for Himself",
                color = "yellow",
            },
            {
                name = "Hammer of Justice",
                spell = "Hammer of Justice",
                type = "debuff",
                unit = "player",
                message = "STUNNED! Use Every Man for Himself!",
                sound = "raid_warning",
                glow = true,
                action_spell = "Every Man for Himself",
                color = "yellow",
            },
            {
                name = "Fear",
                spell = "Fear",
                type = "debuff",
                unit = "player",
                message = "FEARED! Use Every Man for Himself!",
                sound = "raid_warning",
                glow = true,
                action_spell = "Every Man for Himself",
                color = "purple",
            },
            {
                name = "Psychic Scream",
                spell = "Psychic Scream",
                type = "debuff",
                unit = "player",
                message = "FEARED! Use Every Man for Himself!",
                sound = "raid_warning",
                glow = true,
                action_spell = "Every Man for Himself",
                color = "purple",
            },
        },
    },

    ["Twin Val'kyr"] = {
        zone = "TOGC",
        alerts = {
            {
                name = "Light Essence",
                spell = "Light Essence",
                type = "buff",
                unit = "player",
                track_only = true,
                color = "white",
            },
            {
                name = "Dark Essence",
                spell = "Dark Essence",
                type = "buff",
                unit = "player",
                track_only = true,
                color = "purple",
            },
            {
                name = "Light Vortex",
                spell = "Light Vortex",
                type = "cast",
                message = "LIGHT VORTEX! Switch to LIGHT essence!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                color = "white",
            },
            {
                name = "Dark Vortex",
                spell = "Dark Vortex",
                type = "cast",
                message = "DARK VORTEX! Switch to DARK essence!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                color = "purple",
            },
            {
                name = "Twin's Pact",
                spell = "Twin's Pact",
                type = "cast",
                message = "TWINS PACT! INTERRUPT or BURN SHIELD!",
                sound = "alarm",
                glow = true,
                color = "yellow",
            },
        },
    },

    -- ==================== RS ====================
    ["Halion"] = {
        zone = "RS",
        alerts = {
            {
                name = "Fiery Combustion",
                spell = "Fiery Combustion",
                type = "debuff",
                unit = "player",
                message = "COMBUSTION! RUN OUT before dispel!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                arrow = "away",
                show_stacks = true,
                color = "orange",
            },
            {
                name = "Soul Consumption",
                spell = "Soul Consumption",
                type = "debuff",
                unit = "player",
                message = "SOUL CONSUMPTION! RUN OUT before dispel!",
                sound = "raid_warning",
                glow = true,
                flash = true,
                arrow = "away",
                show_stacks = true,
                color = "purple",
            },
            {
                name = "Meteor Strike",
                spell = "Meteor Strike",
                type = "cast",
                message = "METEOR! Move from impact zone!",
                sound = "raid_warning",
                color = "orange",
            },
            {
                name = "Twilight Cutter",
                spell = "Twilight Cutter",
                type = "cast",
                message = "TWILIGHT CUTTER! Stay between beams!",
                sound = "alarm",
                glow = true,
                color = "purple",
            },
            {
                name = "Corporeality Low",
                trigger = "corporeality_low",
                message = "Corporeality LOW - Ease off DPS!",
                sound = "map_ping",
                color = "red",
            },
            {
                name = "Corporeality High",
                trigger = "corporeality_high",
                message = "Corporeality HIGH - Push DPS!",
                sound = "map_ping",
                color = "green",
            },
        },
    },
}

-- Generic alerts (all encounters)
local GENERIC_ALERTS = {
    {
        name = "Shadow Damage - Ward",
        trigger = "shadow_damage_incoming",
        message = "Shadow damage! Cast Shadow Ward!",
        sound = "map_ping",
        action_spell = "Shadow Ward",
        cooldown = 30,  -- Don't spam
    },
    {
        name = "CC Break",
        triggers = {"Fear", "Psychic Scream", "Howl of Terror", "Intimidating Shout",
                   "Polymorph", "Hex", "Blind", "Sap", "Hammer of Justice", "Repentance"},
        message = "CC! Use Every Man for Himself!",
        sound = "raid_warning",
        action_spell = "Every Man for Himself",
        cooldown = 120,  -- Racial CD
    },
}

-- State tracking
local activeAlerts = {}
local alertCooldowns = {}
local lastShadowDamageTime = 0

-- Create alert frame with arrow
local alertFrame = nil
local arrowFrame = nil

local function CreateAlertFrame()
    if alertFrame then return end

    alertFrame = CreateFrame("Frame", "DoroxAurasBossAlert", UIParent)
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    alertFrame:SetWidth(400)
    alertFrame:SetHeight(80)
    alertFrame:SetFrameStrata("HIGH")

    -- Background
    alertFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    alertFrame:SetBackdropColor(0, 0, 0, 0.8)
    alertFrame:SetBackdropBorderColor(1, 0.5, 0, 1)

    -- Icon
    alertFrame.icon = alertFrame:CreateTexture(nil, "ARTWORK")
    alertFrame.icon:SetPoint("LEFT", alertFrame, "LEFT", 10, 0)
    alertFrame.icon:SetWidth(50)
    alertFrame.icon:SetHeight(50)
    alertFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Text
    alertFrame.text = alertFrame:CreateFontString(nil, "OVERLAY")
    alertFrame.text:SetPoint("LEFT", alertFrame.icon, "RIGHT", 10, 0)
    alertFrame.text:SetPoint("RIGHT", alertFrame, "RIGHT", -10, 0)
    alertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    alertFrame.text:SetTextColor(1, 1, 1, 1)
    alertFrame.text:SetJustifyH("CENTER")

    -- Action text (spell to cast)
    alertFrame.action = alertFrame:CreateFontString(nil, "OVERLAY")
    alertFrame.action:SetPoint("BOTTOM", alertFrame, "BOTTOM", 0, 8)
    alertFrame.action:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    alertFrame.action:SetTextColor(0, 1, 0, 1)

    -- Timer
    alertFrame.timer = alertFrame:CreateFontString(nil, "OVERLAY")
    alertFrame.timer:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -10, -8)
    alertFrame.timer:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    alertFrame.timer:SetTextColor(1, 1, 0, 1)

    alertFrame:Hide()
end

local function CreateArrowFrame()
    if arrowFrame then return end

    arrowFrame = CreateFrame("Frame", "DoroxAurasArrow", UIParent)
    arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    arrowFrame:SetWidth(100)
    arrowFrame:SetHeight(100)
    arrowFrame:SetFrameStrata("HIGH")

    arrowFrame.texture = arrowFrame:CreateTexture(nil, "OVERLAY")
    arrowFrame.texture:SetAllPoints()
    arrowFrame.texture:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPGUIDEARROW")

    arrowFrame.text = arrowFrame:CreateFontString(nil, "OVERLAY")
    arrowFrame.text:SetPoint("TOP", arrowFrame, "BOTTOM", 0, -5)
    arrowFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    arrowFrame.text:SetTextColor(1, 1, 0, 1)
    arrowFrame.text:SetText("RUN THIS WAY")

    arrowFrame.angle = 0
    arrowFrame:Hide()
end

-- Show boss alert
function DoroxAurasBossMods:ShowAlert(config, icon, remaining, stacks)
    CreateAlertFrame()

    -- Set color
    local colors = {
        red = {1, 0.2, 0.2},
        orange = {1, 0.5, 0},
        yellow = {1, 1, 0},
        green = {0.2, 1, 0.2},
        blue = {0.3, 0.7, 1},
        purple = {0.7, 0.3, 1},
        cyan = {0, 1, 1},
        white = {1, 1, 1},
        black = {0.3, 0.3, 0.3},
    }
    local color = colors[config.color] or colors.yellow
    alertFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1)

    -- Set icon
    if icon then
        alertFrame.icon:SetTexture(icon)
        alertFrame.icon:Show()
    else
        alertFrame.icon:Hide()
    end

    -- Set text
    local message = config.message or config.name
    if stacks and stacks > 1 then
        message = message .. " (x" .. stacks .. ")"
    end
    alertFrame.text:SetText(message)
    alertFrame.text:SetTextColor(color[1], color[2], color[3], 1)

    -- Action spell
    if config.action_spell then
        alertFrame.action:SetText(">>> " .. config.action_spell .. " <<<")
        alertFrame.action:Show()
    else
        alertFrame.action:Hide()
    end

    -- Timer
    if remaining and remaining > 0 then
        alertFrame.timer:SetFormattedText("%.1f", remaining)
        alertFrame.timer:Show()
    else
        alertFrame.timer:Hide()
    end

    -- Play sound
    if config.sound then
        DoroxAurasAlerts:PlaySound(config.sound)
    end

    -- Screen flash
    if config.flash then
        DoroxAurasAlerts:FlashScreen(config.color)
    end

    alertFrame:Show()

    -- Auto-hide after duration or 5 seconds
    local duration = config.duration or 5
    C_Timer.After(duration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
        end
    end)
end

-- Show directional arrow
function DoroxAurasBossMods:ShowArrow(direction, message)
    CreateArrowFrame()

    local angle = 0
    if type(direction) == "number" then
        angle = direction
    elseif direction == "away" then
        -- Point away from target/boss
        if UnitExists("target") then
            local px, py = UnitPosition("player")
            local tx, ty = UnitPosition("target")
            if px and tx then
                angle = math.atan2(py - ty, px - tx)
            end
        end
    elseif direction == "towards" then
        -- Point towards target
        if UnitExists("target") then
            local px, py = UnitPosition("player")
            local tx, ty = UnitPosition("target")
            if px and tx then
                angle = math.atan2(ty - py, tx - px)
            end
        end
    end

    -- Convert to degrees and rotate texture
    local degrees = math.deg(angle)
    arrowFrame.texture:SetRotation(math.rad(-degrees + 90))  -- Adjust for texture orientation

    if message then
        arrowFrame.text:SetText(message)
    end

    arrowFrame:Show()
end

-- Hide arrow
function DoroxAurasBossMods:HideArrow()
    if arrowFrame then
        arrowFrame:Hide()
    end
end

-- Hide alert
function DoroxAurasBossMods:HideAlert()
    if alertFrame then
        alertFrame:Hide()
    end
end

-- Check if debuff on player
local function CheckPlayerDebuff(spellName)
    for i = 1, 40 do
        local name, _, icon, count, _, duration, expirationTime = UnitDebuff("player", i)
        if not name then break end
        if name == spellName then
            local remaining = expirationTime and (expirationTime - GetTime()) or nil
            return true, icon, remaining, duration, count
        end
    end
    return false
end

-- Check if buff on player
local function CheckPlayerBuff(spellName)
    for i = 1, 40 do
        local name, _, icon, count, _, duration, expirationTime = UnitBuff("player", i)
        if not name then break end
        if name == spellName then
            local remaining = expirationTime and (expirationTime - GetTime()) or nil
            return true, icon, remaining, duration, count
        end
    end
    return false
end

-- Process boss alerts
function DoroxAurasBossMods:ProcessAlerts()
    -- Check generic CC alerts first
    for _, alert in ipairs(GENERIC_ALERTS) do
        if alert.triggers then
            for _, spell in ipairs(alert.triggers) do
                local found, icon = CheckPlayerDebuff(spell)
                if found then
                    local now = GetTime()
                    if not alertCooldowns[alert.name] or
                       (now - alertCooldowns[alert.name]) > (alert.cooldown or 3) then
                        self:ShowAlert(alert, icon)
                        alertCooldowns[alert.name] = now
                    end
                    break
                end
            end
        end
    end

    -- Check boss-specific alerts
    if not currentBoss or currentBoss == "" then return end

    local bossConfig = BOSS_CONFIGS[currentBoss]
    if not bossConfig then return end

    for _, alert in ipairs(bossConfig.alerts) do
        if alert.type == "debuff" and alert.unit == "player" then
            local found, icon, remaining, duration, stacks = CheckPlayerDebuff(alert.spell)

            if found then
                if not activeAlerts[alert.name] then
                    activeAlerts[alert.name] = true
                    self:ShowAlert(alert, icon, remaining, stacks)

                    if alert.arrow then
                        self:ShowArrow(alert.arrow == "fixed" and alert.arrow_angle or alert.arrow,
                                      alert.message)
                    end
                end

                -- Check stack threshold
                if alert.stack_threshold and stacks >= alert.stack_threshold then
                    if alert.stack_message then
                        local stackAlert = {
                            name = alert.name .. "_stacks",
                            message = alert.stack_message,
                            sound = "alarm",
                            color = "red",
                            flash = true,
                        }
                        self:ShowAlert(stackAlert, icon, remaining, stacks)
                    end
                end
            else
                if activeAlerts[alert.name] then
                    activeAlerts[alert.name] = nil
                    self:HideArrow()

                    -- On fade message
                    if alert.on_fade then
                        DoroxAurasAlerts:ShowAlert(alert.on_fade, "green")
                    end
                end
            end
        elseif alert.type == "buff" and alert.unit == "player" then
            local found, icon, remaining, duration, stacks = CheckPlayerBuff(alert.spell)

            if found and not alert.track_only then
                if not activeAlerts[alert.name] then
                    activeAlerts[alert.name] = true
                    self:ShowAlert(alert, icon, remaining, stacks)
                end
            elseif not found and activeAlerts[alert.name] then
                activeAlerts[alert.name] = nil
                if alert.on_fade then
                    DoroxAurasAlerts:ShowAlert(alert.on_fade, "green")
                end
            end
        end
    end
end

-- Combat log handler for casts and special events
-- WotLK 3.3.5a format: timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...
local function OnCombatLogEvent(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags,
          destGUID, destName, destFlags = ...

    -- Safety check
    if not event then return end

    local spellId, spellName, spellSchool
    if event:find("SPELL") or event:find("RANGE") then
        -- In WotLK: spell info starts at arg 9
        spellId, spellName, spellSchool = select(9, ...)
    end

    -- Shadow damage detection (for Shadow Ward reminder)
    if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
        if destGUID == UnitGUID("player") then
            -- Check if shadow damage (school 32 = shadow, 0x20)
            -- In WotLK SPELL_DAMAGE: spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing
            local amount = select(12, ...)
            if spellSchool and bit.band(spellSchool, 0x20) > 0 then  -- Shadow
                local now = GetTime()
                if (now - lastShadowDamageTime) > 30 then
                    -- Check if Shadow Ward is on cooldown
                    local start, duration = GetSpellCooldown("Shadow Ward")
                    if start == 0 then
                        DoroxAurasAlerts:ShowAlert("Shadow damage! Cast Shadow Ward!", "purple")
                        lastShadowDamageTime = now
                    end
                end
            end
        end
    end

    -- Boss cast detection
    if event == "SPELL_CAST_START" then
        local bossConfig = BOSS_CONFIGS[currentBoss]
        if bossConfig then
            for _, alert in ipairs(bossConfig.alerts) do
                if alert.type == "cast" and alert.spell == spellName then
                    local _, _, icon = GetSpellInfo(spellName)
                    DoroxAurasBossMods:ShowAlert(alert, icon)
                end
            end
        end
    end

    -- Blood Prince active detection
    if currentBoss == "Blood Prince Council" then
        if event == "SPELL_AURA_APPLIED" and spellName == "Invocation of Blood" then
            if sourceName and sourceName:find("Keleseth") then
                local alert = {
                    name = "Keleseth Active",
                    message = "KELESETH ACTIVE - Cast Curse of Tongues!",
                    sound = "map_ping",
                    action_spell = "Curse of Tongues",
                    color = "purple",
                }
                DoroxAurasBossMods:ShowAlert(alert)
            elseif sourceName and sourceName:find("Valanar") then
                local alert = {
                    name = "Valanar Active",
                    message = "VALANAR ACTIVE - Spread for Shock Vortex!",
                    sound = "map_ping",
                    color = "blue",
                }
                DoroxAurasBossMods:ShowAlert(alert)
            end
        end
    end
end

-- Zone change handler
local function OnZoneChange()
    local zone = GetRealZoneText() or ""
    currentZone = zone

    -- Reset boss if zone changed
    if zone ~= ZONES.ICC and zone ~= ZONES.TOGC and zone ~= ZONES.RS then
        currentBoss = ""
        inEncounter = false
    end
end

-- Target change - detect boss
local function OnTargetChange()
    if not UnitExists("target") then return end

    local targetName = UnitName("target")
    if targetName and BOSS_CONFIGS[targetName] then
        currentBoss = targetName
    end
end

-- Encounter start/end (for WotLK we detect via boss unitIDs)
local function CheckBossFrames()
    for i = 1, 4 do
        local bossUnit = "boss" .. i
        if UnitExists(bossUnit) then
            local bossName = UnitName(bossUnit)
            if bossName and BOSS_CONFIGS[bossName] then
                currentBoss = bossName
                inEncounter = true
                return
            end
        end
    end
end

-- Initialize
function DoroxAurasBossMods:Initialize()
    CreateAlertFrame()
    CreateArrowFrame()

    -- Register combat log
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    combatFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    combatFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    combatFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

    combatFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            -- In WotLK 3.3.5a, combat log args come directly via vararg
            OnCombatLogEvent(...)
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            OnZoneChange()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnTargetChange()
        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            CheckBossFrames()
        end
    end)

    -- OnUpdate for continuous alert checking
    local updateFrame = CreateFrame("Frame")
    updateFrame.elapsed = 0
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.2 then  -- Check every 0.2 seconds
            self.elapsed = 0
            DoroxAurasBossMods:ProcessAlerts()
        end
    end)

    -- Initial zone check
    OnZoneChange()

    print("|cff00FF00[DoroxAuras]|r Boss Mods loaded (ICC, TOGC, RS)")
end

-- Get current boss
function DoroxAurasBossMods:GetCurrentBoss()
    return currentBoss
end

-- Set boss manually (for testing)
function DoroxAurasBossMods:SetBoss(bossName)
    if BOSS_CONFIGS[bossName] then
        currentBoss = bossName
        print("|cff00FF00[DoroxAuras]|r Boss set to: " .. bossName)
    else
        print("|cffFF0000[DoroxAuras]|r Unknown boss: " .. bossName)
    end
end

-- List available bosses
function DoroxAurasBossMods:ListBosses()
    print("|cff00FF00[DoroxAuras]|r Available bosses:")
    for boss, config in pairs(BOSS_CONFIGS) do
        print("  - " .. boss .. " (" .. config.zone .. ")")
    end
end
