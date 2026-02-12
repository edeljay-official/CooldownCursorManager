--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_spelllist.lua
-- Defensive cooldown durations and talent overrides
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, addonTable = ...

addonTable.BuffDurationSeed = {
    -- Warrior
    [871] = 8, -- Shield Wall
    [118038] = 8, -- Die by the Sword
    [184364] = 8, -- Enraged Regeneration
    [132404] = 6, -- Shield Block
    [23920] = 5, -- Spell Reflection
    [12975] = 15, -- Last Stand
    [97462] = 10, -- Rallying Cry
    [18499] = 6, -- Berserker Rage

    -- Paladin
    [642] = 8, -- Divine Shield
    [498] = 8, -- Divine Protection
    [31850] = 8, -- Ardent Defender
    [86659] = 8, -- Guardian of Ancient Kings
    [1022] = 10, -- Blessing of Protection
    [204018] = 10, -- Blessing of Spellwarding

    -- Death Knight
    [48792] = 8, -- Icebound Fortitude
    [51052] = 8, -- Anti-Magic Zone
    [55233] = 10, -- Vampiric Blood
    [49028] = 8, -- Dancing Rune Weapon
    [49039] = 10, -- Lichborne

    -- Demon Hunter
    [198589] = 10, -- Blur
    [196718] = 8, -- Darkness
    [187827] = 15, -- Metamorphosis (Vengeance)
    [203819] = 12, -- Demon Spikes (aura ID)
    [204021] = 12, -- Fiery Brand

    -- Mage
    [45438] = 10, -- Ice Block
    [414658] = 6, -- Ice Cold
    [342245] = 10, -- Alter Time

    -- Warlock
    [104773] = 8, -- Unending Resolve

    -- Priest
    [19236] = 10, -- Desperate Prayer
    [47585] = 6, -- Dispersion
    [586] = 10, -- Fade
    [15286] = 12, -- Vampiric Embrace
    [47788] = 10, -- Guardian Spirit
    [33206] = 8, -- Pain Suppression

    -- Evoker
    [363916] = 12, -- Obsidian Scales
    [374227] = 8, -- Zephyr

    -- Rogue
    [5277] = 10, -- Evasion
    [31224] = 5, -- Cloak of Shadows
    [1966] = 6, -- Feint
    [185311] = 4, -- Crimson Vial

    -- Hunter
    [186265] = 8, -- Aspect of the Turtle
    [264735] = 6, -- Survival of the Fittest

    -- Monk
    [120954] = 15, -- Fortifying Brew (aura ID)
    [122278] = 10, -- Dampen Harm

    -- Druid
    [22812] = 8, -- Barkskin
    [61336] = 6, -- Survival Instincts
    [192081] = 7, -- Ironfur
    [22842] = 3, -- Frenzied Regeneration
    [200851] = 8, -- Rage of the Sleeper

    -- Shaman
    [108271] = 12, -- Astral Shift
}

addonTable.BuffTalentOverrides = {
    [22812] = { -- Barkskin
        {327993, 4}, -- Improved Barkskin
        {393611, 2}, -- Ursoc's Endurance
    },
    [192081] = { -- Ironfur
        {393611, 2}, -- Ursoc's Endurance
    },
    [49028] = { -- Dancing Rune Weapon
        {377668, 4}, -- Everlasting Bond
    },
    [196718] = { -- Darkness
        {389781, 3}, -- Long Night
    },
    [187827] = { -- Metamorphosis (Vengeance)
        {1265818, 5}, -- Vengeful Beast
    },
    [31224] = { -- Cloak of Shadows
        {457022, 2}, -- Ethereal Cloak
    },
    [47585] = { -- Dispersion
        {453729, 2}, -- Heightened Alteration
    },
}
