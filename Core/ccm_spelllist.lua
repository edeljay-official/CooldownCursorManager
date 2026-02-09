local _, addonTable = ...

-- ============================================================================
-- Defensive Cooldown Buff-Durations (BASE, in Sekunden)
-- Verifiziert gegen offizielle Patch 12.0 Midnight Pre-Patch Notes + Guides
-- Keine Absorb-Effekte
-- ============================================================================

addonTable.BuffDurationSeed = {

    -- ========================
    -- WARRIOR
    -- ========================
    [871]    = 8,   -- Shield Wall (Prot, 40% DR)
    [118038] = 8,   -- Die by the Sword (Arms, 100% Parry + 20% DR)
    [184364] = 8,   -- Enraged Regeneration (Fury, Heal + HoT)
    [132404] = 6,   -- Shield Block (Prot, Block all melee)
    [23920]  = 5,   -- Spell Reflection (Reflect + 20% magic DR)
    [12975]  = 15,  -- Last Stand (Prot, +30% max HP) — ab 12.0 passiv via Shield Wall
    [97462]  = 10,  -- Rallying Cry (+15% max HP, group)
    [18499]  = 6,   -- Berserker Rage (CC immunity)

    -- ========================
    -- PALADIN
    -- ========================
    [642]    = 8,   -- Divine Shield (Full immunity)
    [498]    = 8,   -- Divine Protection (Holy/Ret, 20% DR)
    [31850]  = 8,   -- Ardent Defender (Prot, 20% DR + cheat death)
    [86659]  = 8,   -- Guardian of Ancient Kings (Prot, 50% DR)
    [1022]   = 10,  -- Blessing of Protection (Physical immunity)
    [204018] = 10,  -- Blessing of Spellwarding (Magic immunity)

    -- ========================
    -- DEATH KNIGHT
    -- ========================
    [48792]  = 8,   -- Icebound Fortitude (30% DR + stun immune)
    [51052]  = 8,   -- Anti-Magic Zone (20% magic DR, zone)
    [55233]  = 10,  -- Vampiric Blood (Blood, +30% HP + 30% healing)
    [49028]  = 8,   -- Dancing Rune Weapon (Blood, Mirror + 20% parry)
    [49039]  = 10,  -- Lichborne (CC immune + 6% leech)

    -- ========================
    -- DEMON HUNTER
    -- ========================
    [198589] = 10,  -- Blur (Havoc/Devourer, 25% DR base, 35% mit Desperate Instincts)
    [196718] = 8,   -- Darkness (15% avoidance, group)
    [187827] = 15,  -- Metamorphosis (Vengeance, +40% HP + armor, 2min CD)
    [203819] = 12,  -- Demon Spikes (Vengeance, Armor + parry) !! Aura ID, cast = 203720
    [204021] = 12,  -- Fiery Brand (Vengeance, 40% DR self-buff) NEU in 12.0!

    -- ========================
    -- MAGE
    -- ========================
    [45438]  = 10,  -- Ice Block (Full immunity)
    [414658] = 6,   -- Ice Cold (70% DR, ersetzt Ice Block)
    [342245] = 10,  -- Alter Time (Health snapshot)

    -- ========================
    -- WARLOCK
    -- ========================
    [104773] = 8,   -- Unending Resolve (25% DR + interrupt immune)

    -- ========================
    -- PRIEST
    -- ========================
    [19236]  = 10,  -- Desperate Prayer (Heal + 25% max HP)
    [47585]  = 6,   -- Dispersion (Shadow, 75% DR + heal)
    [586]    = 10,  -- Fade (10% DR mit Translucent Image)
    [15286]  = 12,  -- Vampiric Embrace (Shadow, group healing)
    [47788]  = 10,  -- Guardian Spirit (Holy, +60% healing + cheat death)
    [33206]  = 8,   -- Pain Suppression (Disc, 40% DR)

    -- ========================
    -- EVOKER
    -- ========================
    [363916] = 12,  -- Obsidian Scales (30% DR)
    [374227] = 8,   -- Zephyr (20% AoE DR, group)

    -- ========================
    -- ROGUE
    -- ========================
    [5277]   = 10,  -- Evasion (100% dodge)
    [31224]  = 5,   -- Cloak of Shadows (Magic immunity)
    [1966]   = 6,   -- Feint (40% AoE DR)
    [185311] = 4,   -- Crimson Vial (20% HP HoT)

    -- ========================
    -- HUNTER
    -- ========================
    [186265] = 8,   -- Aspect of the Turtle (Near-immunity)
    [264735] = 6,   -- Survival of the Fittest (30% DR)

    -- ========================
    -- MONK
    -- ========================
    [120954] = 15,  -- Fortifying Brew (20% DR + 20% HP) !! Aura ID, cast = 115203/243435
    [122278] = 10,  -- Dampen Harm (20-50% DR)
    -- Diffuse Magic (122783) ist ab 12.0 PASSIV → Modifier auf Fortifying Brew, kein eigener Buff

    -- ========================
    -- DRUID
    -- ========================
    [22812]  = 8,   -- Barkskin (20% DR, base 8s)
    [61336]  = 6,   -- Survival Instincts (Guardian/Feral, 50% DR, 2 Charges baseline in 12.0)
    [192081] = 7,   -- Ironfur (Guardian, +Armor, stackable)
    [22842]  = 3,   -- Frenzied Regeneration (Guardian, 20% HP HoT)
    [200851] = 8,   -- Rage of the Sleeper (Guardian, 20% DR + leech)

    -- ========================
    -- SHAMAN
    -- ========================
    [108271] = 12,  -- Astral Shift (40% DR)
}

-- ============================================================================
-- Talent-Overrides: Talente die die Buff-Duration verändern
-- Format: [auraID] = { { talentSpellID, delta_seconds }, ... }
-- Delta-Werte werden ADDITIV auf die Base-Duration addiert
-- Mehrere Talente pro Spell stapeln sich
-- Addon prüft per IsPlayerSpell(talentSpellID) ob Talent aktiv
-- ============================================================================

addonTable.BuffTalentOverrides = {

    -- DRUID: Barkskin (base 8s)
    -- Improved Barkskin (+4s, Class Tree, alle Specs)
    -- Ursoc's Endurance (+2s, Guardian Spec Tree)
    -- Beide aktiv = 8 + 4 + 2 = 14s
    [22812] = {
        { 327993, 4 },   -- Improved Barkskin (+4s)
        { 393611, 2 },   -- Ursoc's Endurance (+2s)
    },

    -- DRUID: Ironfur (base 7s)
    -- Ursoc's Endurance (+2s, Guardian Spec Tree)
    [192081] = {
        { 393611, 2 },   -- Ursoc's Endurance (+2s)
    },

    -- DEATH KNIGHT: Dancing Rune Weapon (base 8s)
    -- Everlasting Bond (+4s, Blood Spec Tree)
    [49028] = {
        { 377668, 4 },   -- Everlasting Bond (+4s)
    },

    -- DEMON HUNTER: Darkness (base 8s)
    -- Long Night (+3s, Class Tree)
    [196718] = {
        { 389781, 3 },   -- Long Night (+3s)
    },

    -- DEMON HUNTER: Metamorphosis Vengeance (base 15s)
    -- Vengeful Beast (+5s, Vengeance Spec Tree, NEU in 12.0)
    [187827] = {
        { 1265818, 5 },  -- Vengeful Beast (+5s)
    },

    -- ROGUE: Cloak of Shadows (base 5s)
    -- Ethereal Cloak (+2s, Deathstalker Hero Talent)
    [31224] = {
        { 457022, 2 },   -- Ethereal Cloak (+2s)
    },

    -- PRIEST: Dispersion (base 6s)
    -- Heightened Alteration (+2s, Priest Class Tree)
    [47585] = {
        { 453729, 2 },   -- Heightened Alteration (+2s)
    },
}
