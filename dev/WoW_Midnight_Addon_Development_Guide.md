# WoW Midnight (Patch 12.0.0) - Addon Entwicklungs-Guide
## World of Warcraft Midnight Addon Development Reference Guide

**Version:** 12.0.0 (Midnight Pre-Patch) / 12.0.1 (Midnight Launch)  
**Letztes Update:** Februar 2026  
**TOC Version:** 120000 / 120001

---

## Inhaltsverzeichnis / Table of Contents

1. [Überblick: Die "Addon Apocalypse"](#überblick-die-addon-apocalypse)
2. [Secret Values System](#secret-values-system)
3. [Taint System & Combat Lockdown](#taint-system--combat-lockdown)
4. [Was funktioniert noch? Safe vs. Tainted Code](#was-funktioniert-noch-safe-vs-tainted-code)
5. [Secret Values Testen & Guards](#secret-values-testen--guards)
6. [Secret Values Anzeigen (Ohne Auslesen)](#secret-values-anzeigen-ohne-auslesen)
7. [Curve & ColorCurve APIs](#curve--colorcurve-apis)
8. [Duration Objects](#duration-objects)
9. [Event-Based Tracking](#event-based-tracking)
10. [Whitelisted Spells](#whitelisted-spells)
11. [Action Button APIs](#action-button-apis)
12. [Praktische Implementierungsstrategien](#praktische-implementierungsstrategien)
13. [Migration von 11.x zu 12.0](#migration-von-11x-zu-120)
14. [Bekannte Probleme & Workarounds](#bekannte-probleme--workarounds)
15. [Code-Beispiele](#code-beispiele)
16. [Wichtige Ressourcen](#wichtige-ressourcen)

---

## Überblick: Die "Addon Apocalypse"

### Was hat sich geändert?

Patch 12.0.0 bringt die größten Änderungen am Addon-System in der Geschichte von WoW. Das Hauptziel: **Addons sollen keinen Wettbewerbsvorteil mehr im Kampf bieten**.

#### Philosophie von Blizzard:
- **Addons können Informationen ANZEIGEN** → ✅ Erlaubt
- **Addons können Informationen WISSEN** → ❌ Blockiert
- **Addons können Entscheidungen treffen** → ❌ Blockiert

### Die Grundidee

> "Combat events are in a black box; addons can change the size or shape of the box, and they can paint it a different color, but what they can't do is look inside the box."
> 
> — Ion Hazzikostas, WoW Game Director

**Analogy:** Es ist wie ein verschlossener Briefumschlag. Du siehst, dass ein Brief da ist, du kannst ihn zeigen, du kannst ihn bemalen – aber du darfst ihn nicht öffnen und lesen.

### Warum diese Änderungen?

1. **Automatisierung verhindern:** Addons konnten perfekte Rotationen vorgeben
2. **Level Playing Field:** Spieler ohne Addons waren im Nachteil
3. **Design-Freiheit:** Blizzard musste um Addons herum designen
4. **Zugänglichkeit:** Das Spiel soll ohne Addons spielbar sein

### Was bedeutet das konkret?

**Nicht mehr möglich:**
- `if currentCharges == 0 then` → ❌ Lua Error
- `if health < 50000 then` → ❌ Lua Error
- Rotation Helper basierend auf Cooldowns
- Automatische Entscheidungen basierend auf Buff-Status

**Weiterhin möglich:**
- UI-Anpassungen (Position, Größe, Design)
- Informationen anzeigen (mit speziellen APIs)
- Event-basierte Tracking-Systeme
- Cosmetic Changes

---

## Secret Values System

### Was sind Secret Values?

Secret Values sind "Black Box" Datentypen, die von APIs im Combat zurückgegeben werden. Sie haben folgende Eigenschaften:

- **Können empfangen werden** → ✅
- **Können gespeichert werden** → ✅
- **Können an bestimmte APIs übergeben werden** → ✅
- **Können NICHT ausgelesen werden** → ❌
- **Können NICHT verglichen werden** → ❌
- **Können NICHT für Berechnungen verwendet werden** → ❌

### Wann werden Werte zu Secrets?

Ein Wert wird zu einem Secret, wenn:
1. Die Execution Path "tainted" ist (z.B. im Combat)
2. Die aufgerufene API Secret Values zurückgeben kann
3. Die aktuelle Situation Combat-relevante Daten betrifft

**Beispiel:**
```lua
-- Out of Combat:
local health = UnitHealth("player")  -- normale Zahl: 250000
print(health)  -- funktioniert: "250000"

-- In Combat (tainted execution):
local health = UnitHealth("player")  -- SECRET VALUE
print(health)  -- funktioniert: zeigt Wert an
if health < 50000 then  -- ERROR! Comparison not allowed
    -- ...
end
```

### Verbotene Operationen auf Secret Values

Diese Operationen führen zu **sofortigen Lua Errors**:

#### 1. Vergleiche (Comparisons)
```lua
-- ALLE VERBOTEN:
if secret == 0 then end          -- ❌
if secret ~= nil then end        -- ❌
if secret < 100 then end         -- ❌
if secret > 0 then end           -- ❌
if secret <= 50 then end         -- ❌
if secret >= 10 then end         -- ❌
```

#### 2. Arithmetik
```lua
-- ALLE VERBOTEN:
local result = secret + 10       -- ❌
local result = secret - 5        -- ❌
local result = secret * 2        -- ❌
local result = secret / 3        -- ❌
local result = secret % 2        -- ❌
local result = -secret           -- ❌
```

#### 3. Boolean Tests
```lua
-- ALLE VERBOTEN:
if secret then end               -- ❌
if not secret then end           -- ❌
local x = secret and true        -- ❌
local y = secret or false        -- ❌
```

#### 4. String Operationen
```lua
-- ALLE VERBOTEN:
local str = "Value: " .. secret  -- ❌
local len = #secret              -- ❌
```

#### 5. Table Operations
```lua
-- VERBOTEN:
myTable[secret] = "value"        -- ❌ Secret als Key
for k, v in pairs(secretTable) do end  -- ❌ Iteration über Secret Table
```

### Erlaubte Operationen auf Secret Values

Diese Operationen funktionieren:

#### 1. Speichern
```lua
-- ✅ Erlaubt:
local mySecret = secretValue
self.storedSecret = secretValue
myTable.secret = secretValue
myTable[1] = secretValue
```

#### 2. Weitergeben an Funktionen
```lua
-- ✅ Erlaubt:
MyFunction(secretValue)
DoSomething(arg1, secretValue, arg3)
```

#### 3. Übergabe an spezifische Blizzard APIs
```lua
-- ✅ Erlaubt:
StatusBar:SetValue(secretValue)
FontString:SetText(tostring(secretValue))
Texture:SetVertexColor(secretColor:GetRGB())
StatusBar:SetTimerDuration(secretDuration)
```

#### 4. tostring() für Display
```lua
-- ✅ Erlaubt (nur für Anzeige!):
local displayText = tostring(secretValue)
FontString:SetText(displayText)
-- Aber du kannst den String nicht für Logik verwenden!
```

### Secret Tables

Tables können als Ganzes "secret" markiert werden:

```lua
-- Wenn du ein Secret als Key verwendest:
myTable[secretKey] = "value"
-- → Die gesamte Table wird unwiderruflich als "secret" markiert

-- Tainted Code kann dann nicht mehr auf die Table zugreifen:
local value = myTable["key"]  -- ❌ ERROR wenn tainted
```

**Wichtig:** Dies ist **permanent** und kann nicht rückgängig gemacht werden!

---

## Taint System & Combat Lockdown

### Was ist "Taint"?

"Taint" bedeutet, dass Code als "unsicher" oder "von Addon stammend" markiert wurde. Tainted Code hat eingeschränkte Rechte.

#### Wann wird Code "tainted"?

1. **Beim Laden von Addon-Code:** Jeglicher Code aus .lua-Dateien ist automatisch tainted
2. **Bei Verwendung von /run oder /script:** Manuell ausgeführter Code ist tainted
3. **Wenn Blizzard-Funktionen von tainted Code aufgerufen werden:** Die Taint breitet sich aus
4. **Im Combat (zusätzliche Einschränkungen):** Viele APIs geben dann Secret Values zurück

#### Was ist "Secure Execution"?

Secure Execution = Code läuft in einem "vertrauenswürdigen" Kontext:
- Blizzards eigener UI-Code
- Code in SecureTemplates
- Bestimmte Pre-Combat Setup-Funktionen

### Combat Lockdown

Im Combat gelten zusätzliche Einschränkungen:

#### Protected Functions (können NUR von secure Code aufgerufen werden):
- `CastSpellByName()`
- `UseAction()`
- `TargetUnit()`
- Frame-Manipulationen an Protected Frames
- Viele Action-Button Funktionen

#### Protected Frames

Frames können "protected" sein:
```lua
-- Protected Frame erstellen:
local btn = CreateFrame("Button", "MyBtn", UIParent, "SecureActionButtonTemplate")
-- → Dieser Button ist jetzt "protected"

-- Im Combat:
btn:Hide()  -- ❌ ERROR! Kann nicht von tainted Code aufgerufen werden
btn:SetPoint("CENTER")  -- ❌ ERROR!
```

**Lösung:** Verwende `hooksecurefunc` um Blizzard-Funktionen zu erweitern ohne Taint zu verursachen:
```lua
hooksecurefunc("FunctionName", function(...)
    -- Dein Code hier
    -- Verursacht keine Taint!
end)
```

### Secure Templates

Secure Templates erlauben eingeschränkte Aktionen im Combat:

```lua
-- SecureActionButton erstellen:
local btn = CreateFrame("Button", "MySecureBtn", UIParent, "SecureActionButtonTemplate")

-- Attribute AUSSERHALB von Combat setzen:
btn:SetAttribute("type", "spell")
btn:SetAttribute("spell", "Fireball")

-- Im Combat: Button funktioniert automatisch!
-- Der Spieler muss nur klicken, keine Addon-Logik involviert
```

**Wichtig:** Attribute müssen **vor Combat** gesetzt werden!

---

## Was funktioniert noch? Safe vs. Tainted Code

### ✅ Vollständig funktionierende APIs (auch in Combat, auch tainted)

#### Display & UI Manipulation (auf non-protected Frames):
```lua
-- Frame-Erstellung & Manipulation:
CreateFrame("Frame", "MyFrame", UIParent)
frame:SetSize(200, 100)
frame:SetPoint("CENTER", 0, 0)
frame:Show() / frame:Hide()
frame:SetAlpha(0.5)

-- Textures & FontStrings:
frame:CreateTexture()
texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
fontstring:SetText("Hello World")
fontstring:SetFont("Fonts\\FRIZQT__.TTF", 14)

-- Colors:
texture:SetVertexColor(1, 0, 0, 1)  -- Rot
```

#### Event System:
```lua
-- Event Registration (immer erlaubt):
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterUnitEvent("UNIT_AURA", "player")
frame:SetScript("OnEvent", function(self, event, ...)
    -- Event Handler
end)
```

#### Timer & Scheduling:
```lua
-- C_Timer (komplett safe):
C_Timer.After(5, function()
    print("5 seconds later")
end)

C_Timer.NewTicker(1, function()
    -- Jede Sekunde
end)
```

#### String & Math Operations:
```lua
-- Alle Standard-Lua-Funktionen auf NICHT-SECRET Values:
string.format("%d", 123)
math.floor(12.7)
table.insert(myTable, "value")
```

### ⚠️ Eingeschränkt funktionierende APIs

Diese funktionieren, aber geben in Combat **Secret Values** zurück:

#### Unit Information:
```lua
-- Funktioniert, aber Secret in Combat:
UnitHealth("player")        -- → Secret in Combat, normal sonst
UnitHealthMax("player")     -- → Secret in Combat
UnitPower("player", 0)      -- → Secret in Combat (Mana)
UnitAura("player", 1)       -- → Mehrere Return-Werte sind Secret

-- Immer normal (nicht secret):
UnitName("player")          -- → Spielername (nie secret)
UnitClass("player")         -- → Klasse (nie secret)
UnitLevel("player")         -- → Level (nie secret)
```

#### Cooldown APIs:
```lua
-- Secret in Combat (wenn nicht whitelisted):
GetSpellCooldown(spellID)   -- → start, duration können Secret sein
GetSpellCharges(spellID)    -- → charges, maxCharges können Secret sein

-- Nicht secret:
GetSpellInfo(spellID)       -- → Spell Name, Rank, Icon etc.
IsSpellKnown(spellID)       -- → boolean (nie secret)
```

#### Aura APIs:
```lua
-- Meist Secret in Combat:
C_UnitAuras.GetAuraDataByIndex("player", 1)
-- → Aura-Daten (duration, expirationTime etc.) sind Secret

-- Für Whitelisted Spells: nicht secret
C_UnitAuras.GetPlayerAuraBySpellID(325153)  -- Maelstrom Weapon (whitelisted)
```

### ❌ Im Combat blockierte APIs (Protected Functions)

Diese können im Combat **NUR von secure Code** aufgerufen werden:

```lua
-- Protected Actions:
CastSpellByName("Fireball")     -- ❌ In Combat nur secure
UseAction(1)                     -- ❌ In Combat nur secure
TargetUnit("target")             -- ❌ In Combat nur secure
SpellStopCasting()               -- ❌ In Combat nur secure

-- Protected Frame Manipulation:
ActionButton1:Hide()             -- ❌ Wenn protected frame
MainMenuBar:SetPoint(...)        -- ❌ Wenn protected frame
```

### 🔧 Workarounds für Protected Functions

#### 1. Secure Templates verwenden:
```lua
-- Button VOR Combat einrichten:
local btn = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
btn:SetAttribute("type", "spell")
btn:SetAttribute("spell", "Fireball")
-- Im Combat: Spieler klickt, Addon entscheidet nicht
```

#### 2. hooksecurefunc verwenden:
```lua
-- Blizzard-Funktion "beobachten" ohne zu tainten:
hooksecurefunc("ActionButton_Update", function()
    -- Wird ausgeführt wenn Blizzard die Funktion aufruft
    -- Verursacht keine Taint!
end)
```

#### 3. Event-basierte Alternativen:
```lua
-- Statt Polling im Combat:
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
-- Event-Handler reagiert automatisch
```

---

## Secret Values Testen & Guards

### APIs zum Testen von Secrets

Blizzard bietet fünf Funktionen zum Arbeiten mit Secrets:

#### 1. issecretvalue(value)
```lua
-- Prüft ob ein Wert secret ist:
local health = UnitHealth("player")

if issecretvalue(health) then
    print("Health is SECRET - cannot compare!")
else
    print("Health is normal:", health)
    if health < 50000 then
        -- Kann nur ausgeführt werden wenn nicht secret
    end
end
```

#### 2. canaccesssecrets()
```lua
-- Prüft ob der aktuelle Code Zugriff auf Secrets hat:
if canaccesssecrets() then
    print("Execution is SECURE - can access secrets")
else
    print("Execution is TAINTED - secrets are blocked")
end
```

#### 3. canaccessvalue(value)
```lua
-- Prüft ob ein bestimmter Wert zugänglich ist:
local data = GetSomeData()

if canaccessvalue(data) then
    -- Kann mit data arbeiten
    local result = data * 2
else
    -- data ist secret und nicht zugänglich
end
```

#### 4. issecrettable(table)
```lua
-- Prüft ob eine Table als secret markiert ist:
if issecrettable(myTable) then
    print("Table is SECRET")
else
    print("Table is normal")
end
```

#### 5. canaccesstable(table)
```lua
-- Prüft ob auf eine Table zugegriffen werden kann:
if canaccesstable(myTable) then
    local value = myTable["key"]
end
```

### Standard Guard Pattern

Die meisten Addons verwenden dieses Pattern:

```lua
function MyAddon:UpdateHealth()
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    
    -- Guard: Prüfe zuerst ob Werte secret sind
    if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
        -- Secret values - nutze alternative Methode
        self:DisplayHealthViaSecretAPI(health, maxHealth)
        return
    end
    
    -- Normale Logik (nur wenn nicht secret):
    local percent = health / maxHealth
    if percent < 0.2 then
        self:ShowLowHealthWarning()
    end
end
```

### Defensive Programmierung

Best Practice: **Immer guards verwenden**, auch wenn du denkst die Funktion wird nicht in Combat aufgerufen:

```lua
-- SCHLECHT (wird in Combat crashen):
function GetHealthPercent(unit)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    return health / maxHealth  -- CRASH wenn secret!
end

-- GUT (defensive):
function GetHealthPercent(unit)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
        return nil  -- oder verwende Secret-API
    end
    
    return health / maxHealth
end
```

---

## Secret Values Anzeigen (Ohne Auslesen)

### Grundprinzip: "Computed Displays"

Du kannst Secret Values **anzeigen** ohne sie zu **kennen**. Blizzard bietet spezielle APIs die Secret Values als Input akzeptieren und die Anzeige intern berechnen.

### StatusBar:SetValue()

Die einfachste Methode:

```lua
local healthBar = CreateFrame("StatusBar", nil, UIParent)
healthBar:SetSize(200, 20)
healthBar:SetPoint("CENTER")
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetMinMaxValues(0, 1)

-- Update Funktion:
function UpdateHealthBar()
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    
    -- SetValue akzeptiert auch Secret Values!
    -- Keine Guards nötig, funktioniert immer:
    healthBar:SetValue(health / maxHealth)  -- Funktioniert auch mit Secrets!
end
```

**Wichtig:** Die **Division** `health / maxHealth` ist hier erlaubt, weil:
- Wenn beide Werte normal sind → normale Division
- Wenn beide Werte secret sind → interne "secret division" die ein secret result zurückgibt
- `SetValue()` akzeptiert sowohl normale als auch secret values

### FontString:SetText()

Für Text-Anzeige:

```lua
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- tostring() funktioniert auf Secret Values:
local health = UnitHealth("player")
text:SetText(tostring(health))  -- Zeigt den Wert an!

-- Aber du kannst den String nicht für Logik verwenden:
local str = tostring(health)
if str == "50000" then end  -- Das wäre sinnlos, da str immer eine spezielle Darstellung ist
```

### Secret Value + Text kombinieren:

```lua
-- Funktioniert:
local health = UnitHealth("player")
text:SetText("Health: " .. tostring(health))

-- Aber aufpassen:
local str = "Health: " .. tostring(health)
-- str ist jetzt auch "tainted" und kann nicht für Vergleiche verwendet werden
```

---

## Curve & ColorCurve APIs

### Was sind Curves?

Curves sind Funktionen die eine **Transformation** auf Secret Values anwenden ohne dass dein Code den Wert kennt.

**Analogy:** 
- Du hast einen verschlossenen Brief (Secret Value)
- Du gibst Blizzard eine "Regel" (Curve): "Wenn der Wert X ist, färbe es rot; wenn Y, dann grün"
- Blizzard öffnet den Brief, wendet die Regel an, und zeigt das Ergebnis
- Du siehst das Ergebnis (Farbe), kennst aber nie den ursprünglichen Wert

### ColorCurve: Health Bar Coloring

Standard Use Case: Health Bar von Grün → Gelb → Rot färben:

```lua
-- 1. ColorCurve erstellen:
local curve = C_CurveUtil.CreateColorCurve()

-- 2. Typ setzen (Step = keine Interpolation, Linear = smooth transition):
curve:SetType(Enum.LuaCurveType.Linear)

-- 3. Points hinzufügen (x = Prozent [0-1], y = Color):
curve:AddPoint(0.0, CreateColor(1, 0, 0, 1))    -- Rot bei 0%
curve:AddPoint(0.3, CreateColor(1, 1, 0, 1))    -- Gelb bei 30%
curve:AddPoint(0.7, CreateColor(0, 1, 0, 1))    -- Grün bei 70%
curve:AddPoint(1.0, CreateColor(0, 1, 0, 1))    -- Grün bei 100%

-- 4. Curve mit UnitHealthPercent verwenden:
local usePredicted = false
local color = UnitHealthPercent("player", usePredicted, curve)

-- 5. Farbe auf StatusBar anwenden:
statusBar:GetStatusBarTexture():SetVertexColor(color:GetRGB())
```

**Was passiert hier?**
- `UnitHealthPercent("player", false, curve)` gibt einen Secret-Color zurück
- Dein Code kennt NICHT den Health-Prozentsatz
- Aber die StatusBar wird korrekt gefärbt!

### Vollständiges Beispiel: Self-Updating Health Bar

```lua
-- Setup:
local frame = CreateFrame("Frame", "MyHealthFrame", UIParent)
local statusBar = CreateFrame("StatusBar", nil, frame)
statusBar:SetPoint("CENTER", -150, -50)
statusBar:SetSize(144, 17)
statusBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
statusBar:SetMinMaxValues(0, 1)

-- Color Curve:
local curve = C_CurveUtil.CreateColorCurve()
curve:SetType(Enum.LuaCurveType.Linear)
curve:AddPoint(0.0, CreateColor(1, 0, 0))  -- Rot bei 0%
curve:AddPoint(0.3, CreateColor(1, 1, 0))  -- Gelb bei 30%
curve:AddPoint(0.7, CreateColor(0, 1, 0))  -- Grün bei 70%

-- Event Handler:
local function OnHealthUpdate(self, event, unit)
    if unit ~= "player" then return end
    
    local usePredicted = false
    
    -- Color (mit Curve):
    local color = UnitHealthPercent(unit, usePredicted, curve)
    statusBar:GetStatusBarTexture():SetVertexColor(color:GetRGB())
    
    -- Value (ohne Curve - gibt 0-1 Secret zurück):
    local value = UnitHealthPercent(unit, usePredicted, CurveConstants.ZeroToOne)
    statusBar:SetValue(value)
    
    -- Debug (funktioniert auch mit Secrets!):
    print(string.format("%s, health=%.2f, r=%.2f, g=%.2f, b=%.2f", 
        unit, value, color:GetRGB()))
end

frame:RegisterUnitEvent("UNIT_HEALTH", "player")
frame:SetScript("OnEvent", OnHealthUpdate)
```

### Step vs. Linear Curves

```lua
-- STEP: Harte Übergänge (spring von Farbe zu Farbe):
curve:SetType(Enum.LuaCurveType.Step)
curve:AddPoint(0.0, CreateColor(1, 0, 0))  -- Rot 0-49.9%
curve:AddPoint(0.5, CreateColor(0, 1, 0))  -- Grün ab 50%
-- Ergebnis: Bei 49% = Rot, bei 50% = plötzlich Grün

-- LINEAR: Smooth Transitions (interpoliert zwischen Farben):
curve:SetType(Enum.LuaCurveType.Linear)
curve:AddPoint(0.0, CreateColor(1, 0, 0))  -- Rot
curve:AddPoint(1.0, CreateColor(0, 1, 0))  -- Grün
-- Ergebnis: Bei 25% = Orange-ish, bei 50% = Gelb-ish, bei 75% = Hell-Grün
```

### Zero-Charge Detection mit ColorCurve

Problem: `if charges == 0` ist verboten.  
Lösung: Curve die bei 0 eine spezielle Farbe zeigt:

```lua
-- Spell Charge Indicator:
local curve = C_CurveUtil.CreateColorCurve()
curve:SetType(Enum.LuaCurveType.Step)

-- Bei 0 Charges: Rot (nicht bereit)
curve:AddPoint(0.0, CreateColor(1, 0, 0, 1))

-- Bei >0 Charges: Grün (bereit)
curve:AddPoint(0.01, CreateColor(0, 1, 0, 1))

-- Anwendung:
-- Angenommen GetSpellCharges() gibt secret charges zurück
local charges = GetSpellCharges(12345)  -- Secret!

-- Curve auf Texture anwenden (Blizzard macht die Logik intern):
-- Dies erfordert einen speziellen Widget oder Color-Evaluate API
-- Details siehe Duration Objects Section
```

### Boolean → Color Conversion

Neu in 12.0: Direkte Boolean zu Color Conversion:

```lua
-- Für Secret Booleans:
local isReady = SomeSecretBooleanAPI()  -- Secret boolean

-- Konvertieren zu Farbe:
local color1 = C_CurveUtil.EvaluateColorFromBoolean(
    isReady,
    CreateColor(0, 1, 0),  -- true = Grün
    CreateColor(1, 0, 0)   -- false = Rot
)

-- Alternative:
local r, g, b, a = C_CurveUtil.EvaluateColorValueFromBoolean(
    isReady,
    0, 1, 0, 1,  -- true
    1, 0, 0, 1   -- false
)
```

---

## Duration Objects

### Was sind Duration Objects?

Duration Objects sind Blizzard's Lösung für Zeit-basierte Secret Values (Cooldowns, Buff-Durations, etc.).

**Problem ohne Duration Objects:**
```lua
local start, duration = GetSpellCooldown(133)  -- Secret im Combat!
if duration > 0 then  -- ❌ ERROR: Cannot compare secret
    -- ...
end
```

**Lösung mit Duration Objects:**
```lua
local duration = C_ActionBar.GetActionChargeDuration(actionID)  -- Duration Object!
statusBar:SetTimerDuration(duration)  -- Widget kümmert sich um alles
```

### Duration Object erstellen

```lua
-- Leeres Duration Object erstellen:
local duration = C_DurationUtil.CreateDuration()

-- Duration mit Werten füllen (nur AUSSERHALB combat mit nicht-secret values!):
duration:SetTimeSpan(startTime, endTime)
-- ODER:
duration:SetTimeFromStart(startTime, durationSec, modRate)
-- ODER:
duration:SetTimeFromEnd(endTime, durationSec, modRate)
```

**Wichtig:** Diese Set-Methoden akzeptieren **keine Secret Values** vom tainted caller!

### Duration Objects von APIs erhalten

Viele neue APIs geben Duration Objects direkt zurück:

```lua
-- Action Bar Cooldowns:
local duration = C_ActionBar.GetActionChargeDuration(actionID)
-- → Gibt Duration Object zurück (auch im Combat!)

-- Dieses Duration Object kann direkt verwendet werden:
cooldownFrame:SetCooldownFromDurationObject(duration, clearIfZero)
statusBar:SetTimerDuration(duration, interpolation)
```

### StatusBar mit Timer Duration

```lua
local bar = CreateFrame("StatusBar", nil, UIParent)
bar:SetSize(200, 20)
bar:SetPoint("CENTER")
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)

-- Duration Object setzen:
local duration = C_ActionBar.GetActionChargeDuration(actionID)
bar:SetTimerDuration(duration)

-- StatusBar zeigt jetzt automatisch den Timer an!
-- Update erfolgt intern durch Blizzard
```

### Cooldown Frame mit Duration

```lua
local cooldown = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
cooldown:SetSize(36, 36)
cooldown:SetPoint("CENTER")

-- Duration Object setzen:
local duration = C_ActionBar.GetActionChargeDuration(actionID)
cooldown:SetCooldownFromDurationObject(duration, true)  -- true = clear if zero

-- Cooldown Spiral wird automatisch angezeigt!
```

### Duration Methods

Duration Objects haben verschiedene Methoden um Berechnungen durchzuführen:

```lua
local duration = C_ActionBar.GetActionChargeDuration(actionID)

-- Berechnungen (funktionieren auch mit Secret Duration!):
local elapsed = duration:GetElapsedDuration()      -- Secret number
local remaining = duration:GetRemainingDuration()  -- Secret number
local progress = duration:EvaluateElapsedProgress() -- Secret 0-1

-- Mit Curve kombinieren:
local modifiedRemaining = duration:EvaluateRemainingDuration(curve, modifier)
local modifiedElapsed = duration:EvaluateElapsedDuration(curve, modifier)
```

### Praktisches Beispiel: Charge Cooldown Display

```lua
-- Charge-based Spell Cooldown Tracker:
local MyChargeTracker = {}

function MyChargeTracker:Create()
    local frame = CreateFrame("Frame", nil, UIParent)
    
    -- Status Bar für Cooldown:
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetSize(100, 20)
    bar:SetPoint("CENTER")
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    
    -- Text für Charges:
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    
    -- Update function:
    local function Update()
        local spellID = 12345  -- Dein Spell
        
        -- Charges Info:
        local charges, maxCharges = GetSpellCharges(spellID)
        
        -- Text setzen (funktioniert auch mit Secrets!):
        text:SetText(tostring(charges) .. "/" .. tostring(maxCharges))
        
        -- Cooldown Duration:
        local start, duration = GetSpellCooldown(spellID)
        
        -- Für Action Buttons: Duration Object verwenden:
        -- local duration = C_ActionBar.GetActionChargeDuration(actionID)
        -- bar:SetTimerDuration(duration)
        
        -- Alternativen wenn kein Duration Object verfügbar:
        if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
            -- Secret - können nicht direkt berechnen
            -- Fallback oder andere Lösung
        else
            -- Normal - können selbst berechnen
            local remaining = start + duration - GetTime()
            bar:SetValue(1 - (remaining / duration))
        end
    end
    
    -- Event-basiertes Update:
    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:SetScript("OnEvent", Update)
    
    -- Initial Update:
    Update()
    
    return frame
end
```

---

## Event-Based Tracking

### Warum Event-Based?

**Problem mit Polling:**
```lua
-- SCHLECHT (alt, funktioniert nicht mehr gut):
function OnUpdate(self, elapsed)
    local charges = GetSpellCharges(12345)  -- Secret im Combat!
    if charges == 0 then  -- ❌ ERROR!
        -- ...
    end
end
```

**Lösung mit Events:**
```lua
-- GUT (modern):
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:SetScript("OnEvent", function(self, event, ...)
    -- Event gefeuert → irgendwas hat sich geändert
    -- Kein Vergleich nötig!
    self:UpdateDisplay()
end)
```

### Wichtigste Events für Cooldown/Charge Tracking

#### SPELL_UPDATE_CHARGES
```lua
-- Feuert wenn sich Spell Charges ändern:
frame:RegisterEvent("SPELL_UPDATE_CHARGES")

frame:SetScript("OnEvent", function(self, event, ...)
    -- Event hat KEINE Parameter
    -- Du musst alle relevanten Spells prüfen:
    
    for spellID in pairs(self.trackedSpells) do
        local charges, maxCharges, start, duration = GetSpellCharges(spellID)
        self:UpdateChargeDisplay(spellID, charges, maxCharges)
    end
end)
```

#### SPELL_UPDATE_COOLDOWN
```lua
-- Feuert bei generellen Cooldown-Änderungen:
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

frame:SetScript("OnEvent", function(self, event, ...)
    -- Event hat KEINE Parameter
    -- Prüfe alle getrackte Spells:
    
    for spellID in pairs(self.trackedSpells) do
        local start, duration = GetSpellCooldown(spellID)
        self:UpdateCooldownDisplay(spellID, start, duration)
    end
end)
```

#### UNIT_SPELLCAST_SUCCEEDED
```lua
-- Feuert wenn ein Cast erfolgreich war:
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    -- unit = "player"
    -- spellID = ID des gecasteten Spells
    
    if spellID == self.trackedSpellID then
        -- Spell wurde gecastet!
        -- Für Charge-Spells: Charge wurde verbraucht
        self:OnSpellCast(spellID)
    end
end)
```

#### UNIT_AURA
```lua
-- Feuert wenn sich Auras ändern:
frame:RegisterUnitEvent("UNIT_AURA", "player")

frame:SetScript("OnEvent", function(self, event, unit, updateInfo)
    -- updateInfo enthält Details über was sich geändert hat
    
    if updateInfo.addedAuras then
        for _, auraData in ipairs(updateInfo.addedAuras) do
            -- Neue Aura!
            self:OnAuraAdded(auraData)
        end
    end
    
    if updateInfo.removedAuraInstanceIDs then
        for _, instanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
            -- Aura removed!
            self:OnAuraRemoved(instanceID)
        end
    end
end)
```

#### ACTIONBAR_UPDATE_COOLDOWN
```lua
-- Feuert bei Action Button Cooldown Updates:
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

frame:SetScript("OnEvent", function(self, event)
    -- Kein Parameter - update all action buttons
    for i = 1, 12 do
        self:UpdateActionButton(i)
    end
end)
```

### Event Filtering Pattern

Effizientes Pattern um nur relevante Events zu verarbeiten:

```lua
local MyAddon = {
    trackedSpells = {
        [114049] = true,  -- Ascendance (Shaman)
        [51505] = true,   -- Lava Burst
        [16166] = true,   -- Elemental Mastery
    }
}

function MyAddon:OnEvent(event, ...)
    if event == "SPELL_UPDATE_CHARGES" then
        self:UpdateAllCharges()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellID = ...
        if self.trackedSpells[spellID] then
            self:OnTrackedSpellCast(spellID)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:InitializeTracking()
    end
end

-- Event Registration:
local frame = CreateFrame("Frame")
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    MyAddon:OnEvent(event, ...)
end)
```

### Timer Fallback für Event-basiertes Tracking

Manchmal sind Events nicht ausreichend, dann Hybrid-Approach:

```lua
local ChargeTracker = {}

function ChargeTracker:Create(spellID)
    local tracker = {
        spellID = spellID,
        estimatedCharges = 0,
        timer = nil
    }
    
    -- Event Handler:
    tracker.frame = CreateFrame("Frame")
    
    tracker.frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    tracker.frame:SetScript("OnEvent", function()
        tracker:OnChargesChanged()
    end)
    
    function tracker:OnChargesChanged()
        -- Event: Charges haben sich geändert
        local charges, maxCharges, start, duration = GetSpellCharges(self.spellID)
        
        if issecretvalue and issecretvalue(charges) then
            -- Secret - können nicht direkt lesen
            -- Arbeite mit letztem bekannten Wert weiter
        else
            -- Normal - update known value
            self.estimatedCharges = charges
        end
        
        -- Timer für nächste Charge:
        self:ScheduleNextChargeTimer(start, duration)
    end
    
    function tracker:ScheduleNextChargeTimer(start, duration)
        -- Cancel old timer:
        if self.timer then
            self.timer:Cancel()
        end
        
        if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
            -- Secret - können nicht schedulen
            return
        end
        
        -- Schedule new timer:
        local nextChargeTime = start + duration
        local delay = nextChargeTime - GetTime()
        
        if delay > 0 then
            self.timer = C_Timer.After(delay, function()
                self.estimatedCharges = self.estimatedCharges + 1
                self:OnChargesChanged()
            end)
        end
    end
    
    return tracker
end
```

---

## Whitelisted Spells

### Was sind Whitelisted Spells?

Blizzard kann bestimmte Spells vom Secret System **ausnehmen**. Diese Spells geben dann **normale** (nicht-secret) Werte zurück, auch im Combat.

### Aktuell Whitelisted (Stand Dezember 2025)

#### 1. Combat Resurrection Spells
```lua
-- Alle Combat-Res Spells sind NON-SECRET:
-- Druid: Rebirth (20484)
-- Warlock: Soulstone (20707)
-- Death Knight: Raise Ally (61999)
-- etc.

-- Cooldown ist normal zugänglich:
local start, duration = GetSpellCooldown(20484)  -- Rebirth
if duration > 0 then  -- ✅ Funktioniert! Kein Error!
    print("Combat Res on cooldown!")
end

-- Charges sind normal zugänglich:
local charges, maxCharges = GetSpellCharges(20484)
print("Available combat res:", charges)  -- ✅ Funktioniert!
```

**Warum whitelisted?**  
Raid-Koordination erfordert zu wissen wer Combat Res verfügbar hat.

#### 2. Skyriding Abilities
```lua
-- Alle Skyriding/Dragonriding Abilities:
-- Skyward Ascent, Surge Forward, etc.

-- Charge Tracking ist verfügbar:
local charges, maxCharges = GetSpellCharges(361584)  -- Skyward Ascent
-- ✅ Normal, nicht secret!
```

**Warum whitelisted?**  
Navigation & Exploration Mechanics sind nicht combat-relevant.

#### 3. Global Cooldown (GCD)
```lua
-- Spell ID 61304 = Global Cooldown

local start, duration = GetSpellCooldown(61304)
-- ✅ Normal, nicht secret!

-- Nützlich für GCD Tracking in Addons:
if duration > 0 then
    print("GCD active:", duration)
end
```

#### 4. Enhancement Shaman: Maelstrom Weapon
```lua
-- Spell ID 344179 = Maelstrom Weapon buff

local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179)
if auraData then
    local stacks = auraData.applications  -- ✅ Normal, nicht secret!
    print("Maelstrom stacks:", stacks)
end
```

**Warum whitelisted?**  
Wichtige Klassen-Resource die schwer zu tracken wäre.

#### 5. Devourer Demon Hunter: Soul Fragments
```lua
-- Soul Fragment Spells sind NON-SECRET

-- Kann Stack-Zähler direkt auslesen:
local stacks = GetSoulFragmentCount()  -- ✅ (hypothetische API)
```

**Warum whitelisted?**  
Kritische Resource für Devourer Tank-Spec.

### Spell-Whitelist Anfragen

Blizzard akzeptiert Requests um Spells zu whitelisten:

**Kriterien für Whitelist:**
1. Nicht-combat-relevant ODER
2. Kritisch für Koordination (Combat Res) ODER
3. Klassen-Resource die sonst nicht trackbar ist ODER
4. QoL Feature ohne competitive Vorteil

**Wo anfragen?**  
WoW UI Dev Discord Server (#addon-restrictions-feedback channel)

### Checking ob ein Spell Whitelisted ist

```lua
function IsSpellWhitelisted(spellID)
    -- Teste ob Cooldown-Info normal ist:
    local start, duration = GetSpellCooldown(spellID)
    
    if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
        return false  -- Secret → nicht whitelisted
    else
        return true   -- Normal → whitelisted (oder out of combat)
    end
end

-- Usage:
if IsSpellWhitelisted(20484) then
    print("Rebirth ist whitelisted!")
end
```

**Achtung:** Diese Methode funktioniert nur **im Combat**! Out of combat sind alle Werte normal.

---

## Action Button APIs

### Das Action Button Problem

Action Buttons sind speziell, weil:
1. Sie sind **protected** im Combat
2. Sie enthalten Cooldown-Informationen
3. Sie haben Charge-Tracking

**Problem in 12.0:**  
Action Button Cooldown/Charge APIs geben Secret Values zurück.

### Lösung: C_ActionBar APIs

Blizzard hat neue APIs hinzugefügt die **Duration Objects** zurückgeben:

#### GetActionChargeDuration()
```lua
-- Gibt Duration Object zurück (NICHT secret!):
local actionID = 1  -- Action Button 1
local duration = C_ActionBar.GetActionChargeDuration(actionID)

-- Duration Object direkt an Widget übergeben:
cooldownFrame:SetCooldownFromDurationObject(duration)
-- ODER:
statusBar:SetTimerDuration(duration)
```

#### GetActionCooldown()
```lua
-- Alte API (gibt Secrets zurück):
local start, duration = GetActionCooldown(slot)  -- ❌ Secret im Combat

-- Neue API (gibt normale Werte ODER Duration Object):
local cooldownInfo = C_ActionBar.GetActionCooldown(slot)
-- cooldownInfo.startTime
-- cooldownInfo.duration
-- (Details siehe API Docs)
```

### Parent Reference Pattern

Cooldown Addons wie OmniCC nutzen dieses Pattern:

```lua
-- Blizzard's ActionButton.lua erstellt:
-- button.chargeCooldown = CreateFrame("Cooldown", ...)

-- Cooldown Addon kann prüfen:
local cooldown = ... -- irgendein Cooldown Frame

local parent = cooldown:GetParent()
if parent and parent.chargeCooldown == cooldown then
    -- Dies ist ein Charge Cooldown!
    return "charge"
else
    -- Normaler Cooldown
    return "normal"
end
```

**Vorteil:** Funktioniert durch Referenz-Vergleich ohne Secret Values auszulesen.

### LibActionButton-1.0

Library die Standard-Interface für Action Buttons bietet:

```lua
-- Erstellt kompatible Action Buttons die:
-- 1. parent.chargeCooldown Referenz haben
-- 2. Mit C_ActionBar APIs arbeiten
-- 3. Von anderen Addons erkannt werden

-- Beispiel (vereinfacht):
local button = LibActionButton:CreateButton(1)
button:SetAction(1)  -- Bindet an Action Slot 1

-- Button erstellt automatisch:
-- button.chargeCooldown für Charge-based Spells
```

**Verwendet von:** Bartender4, ElvUI, Dominos

### Praktisches Beispiel: Custom Action Button

```lua
local MyActionButton = {}

function MyActionButton:Create(actionSlot)
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    button:SetSize(36, 36)
    button:SetPoint("CENTER")
    
    -- Secure attributes (VOR Combat setzen!):
    button:SetAttribute("type", "action")
    button:SetAttribute("action", actionSlot)
    
    -- Icon:
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    button.icon = icon
    
    -- Cooldown Frame:
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    button.cooldown = cooldown
    
    -- Charge Cooldown Frame:
    local chargeCooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    chargeCooldown:SetAllPoints()
    chargeCooldown:SetDrawEdge(false)
    button.chargeCooldown = chargeCooldown
    
    -- Charge Text:
    local charges = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    charges:SetPoint("BOTTOMRIGHT", -2, 2)
    button.charges = charges
    
    -- Update Function:
    function button:Update()
        local actionID = self:GetAttribute("action")
        
        -- Icon:
        local texture = GetActionTexture(actionID)
        self.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        
        -- Cooldown (Duration Object):
        local duration = C_ActionBar.GetActionChargeDuration(actionID)
        if duration then
            self.chargeCooldown:SetCooldownFromDurationObject(duration, true)
        end
        
        -- Charges (können Secret sein, aber tostring funktioniert!):
        local charges, maxCharges = GetActionCharges(actionID)
        if charges and maxCharges and maxCharges > 1 then
            self.charges:SetText(tostring(charges))
            self.charges:Show()
        else
            self.charges:Hide()
        end
    end
    
    -- Event-based updates:
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    
    button:SetScript("OnEvent", function(self, event)
        self:Update()
    end)
    
    -- Initial update:
    button:Update()
    
    return button
end
```

---

## Praktische Implementierungsstrategien

### 1. Graceful Degradation

**Prinzip:** Addon funktioniert so gut wie möglich, auch wenn Secrets es einschränken.

```lua
function MyAddon:UpdateHealthDisplay()
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    
    -- Guard check:
    if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
        -- Secret - zeige nur visuelle Repräsentation:
        self.healthBar:SetValue(health / maxHealth)  -- Funktioniert mit Secrets
        self.healthText:SetText("???")  -- Können Zahl nicht zeigen
        
        -- Feature degradation:
        self.lowHealthWarning:Hide()  -- Können nicht wissen ob low
        
        return
    end
    
    -- Normal - volle Funktionalität:
    local percent = health / maxHealth
    self.healthBar:SetValue(percent)
    self.healthText:SetText(string.format("%d / %d", health, maxHealth))
    
    -- Konditionale Features:
    if percent < 0.3 then
        self.lowHealthWarning:Show()
    else
        self.lowHealthWarning:Hide()
    end
end
```

### 2. Pre-Combat Caching

**Prinzip:** Sammle normale Werte bevor Combat startet.

```lua
local MyAddon = {
    cache = {
        lastKnownHealth = 0,
        lastKnownMaxHealth = 1,
        playerLevel = 1,
    }
}

function MyAddon:CachePlayerInfo()
    -- Wird OUT OF COMBAT aufgerufen:
    self.cache.lastKnownMaxHealth = UnitHealthMax("player")
    self.cache.playerLevel = UnitLevel("player")
    
    -- Weitere Infos cachen...
end

function MyAddon:OnCombatStart()
    -- Combat startet - cache aktuelle Werte:
    self:CachePlayerInfo()
end

function MyAddon:OnCombatEnd()
    -- Combat endet - refresh cache:
    self:CachePlayerInfo()
end

-- Event Registration:
function MyAddon:Initialize()
    local frame = CreateFrame("Frame")
    
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Enter Combat
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leave Combat
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")   -- Initial load
    
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            MyAddon:OnCombatStart()
        elseif event == "PLAYER_REGEN_ENABLED" then
            MyAddon:OnCombatEnd()
        elseif event == "PLAYER_ENTERING_WORLD" then
            MyAddon:CachePlayerInfo()
        end
    end)
end
```

### 3. Event-Driven Architecture

**Prinzip:** Reagiere auf Änderungen, nicht auf absolute Werte.

```lua
local BuffTracker = {}

function BuffTracker:Create()
    local tracker = {
        activeBuffs = {},  -- Set von aktiven Buff Spell IDs
    }
    
    -- Event Handler:
    tracker.frame = CreateFrame("Frame")
    tracker.frame:RegisterUnitEvent("UNIT_AURA", "player")
    
    tracker.frame:SetScript("OnEvent", function(self, event, unit, updateInfo)
        if not updateInfo then return end
        
        -- Added Buffs:
        if updateInfo.addedAuras then
            for _, auraData in ipairs(updateInfo.addedAuras) do
                tracker:OnBuffGained(auraData)
            end
        end
        
        -- Removed Buffs:
        if updateInfo.removedAuraInstanceIDs then
            for _, instanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                tracker:OnBuffLost(instanceID)
            end
        end
    end)
    
    function tracker:OnBuffGained(auraData)
        local spellID = auraData.spellId
        self.activeBuffs[spellID] = true
        
        -- Reagiere auf Buff GAINED event:
        -- Keine Vergleiche mit Secret Values nötig!
        
        if spellID == 12345 then  -- Wichtiger Buff
            print("Important buff gained!")
            -- Trigger visual indicator
        end
    end
    
    function tracker:OnBuffLost(instanceID)
        -- Find and remove from activeBuffs
        -- Reagiere auf Buff LOST event
        
        print("Buff lost!")
    end
    
    function tracker:HasBuff(spellID)
        -- Simple check - keine Secret Values involviert:
        return self.activeBuffs[spellID] == true
    end
    
    return tracker
end
```

### 4. Alternative Input Methods

**Prinzip:** Wenn Secret Values das Problem sind, finde einen anderen Weg.

```lua
-- PROBLEM: Spell auf Cooldown?
local start, duration = GetSpellCooldown(spellID)  -- Secret!
if duration > 0 then  -- ❌ Cannot compare
    -- ...
end

-- LÖSUNG 1: Event-based
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:SetScript("OnEvent", function()
    -- Irgendein Cooldown hat sich geändert
    -- Update Display für alle Spells
end)

-- LÖSUNG 2: IsSpellUsable (gibt boolean zurück, aber kann auch secret sein)
local usable, notEnoughPower = IsSpellUsable(spellID)
if issecretvalue(usable) then
    -- Secret - nutze alternatives Display
else
    -- Können boolean verwenden
end

-- LÖSUNG 3: Whitelisted Spell prüfen
-- Wenn möglich, Whitelist Request stellen

-- LÖSUNG 4: Visual Indicators statt Logic
-- Zeige Cooldown Spiral, entscheide nicht programmatisch
```

### 5. User Feedback über Limitations

**Prinzip:** Sei transparent mit dem Nutzer über Einschränkungen.

```lua
function MyAddon:ShowLimitationWarning()
    if InCombatLockdown() then
        local msg = "Some features limited during combat due to WoW 12.0 restrictions"
        UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME)
    end
end

function MyAddon:UpdateFeature()
    if issecretvalue and issecretvalue(someValue) then
        -- Feature nicht verfügbar
        self.featureButton:Disable()
        self.featureButton.tooltip = "This feature is unavailable in combat due to WoW API restrictions"
    else
        self.featureButton:Enable()
        self.featureButton.tooltip = "Click to activate feature"
    end
end
```

---

## Migration von 11.x zu 12.0

### Pre-Migration Checklist

- [ ] Addon auf 11.2.7 getestet und funktional
- [ ] TOC Version auf 120000 (Pre-Patch) oder 120001 (Launch) updated
- [ ] Backup vom funktionierenden Code erstellt
- [ ] Liste von Features die Combat-Daten verwenden

### Schritt 1: TOC File Update

```toc
## Interface: 120000
## Title: My Addon
## Author: YourName
## Version: 12.0.0
## SavedVariables: MyAddonDB

# Core Files
Core.lua
Display.lua
Events.lua
```

### Schritt 2: Identifiziere Problembereiche

**Suche nach diesen Patterns:**

```lua
-- PROBLEM-PATTERNS:

-- 1. Direkte Vergleiche mit API Results:
if UnitHealth("player") < 50000 then

-- 2. Arithmetik mit API Results:
local healthPercent = UnitHealth("player") / UnitHealthMax("player")

-- 3. Polling in OnUpdate:
function OnUpdate(self, elapsed)
    local charges = GetSpellCharges(spellID)
    if charges == 0 then
    
-- 4. String Concatenation mit API Results:
local text = "Health: " .. UnitHealth("player")

-- 5. Boolean Tests von API Results:
if cooldownDuration then
```

### Schritt 3: Add Guards

**Quick Fix für existierenden Code:**

```lua
-- VORHER:
function UpdateHealth()
    local health = UnitHealth("player")
    if health < 50000 then
        ShowWarning()
    end
end

-- NACHHER (mit Guard):
function UpdateHealth()
    local health = UnitHealth("player")
    
    -- GUARD:
    if issecretvalue and issecretvalue(health) then
        -- Secret - degraded functionality
        UpdateHealthBar(health)  -- Kann nur Bar updaten
        return
    end
    
    -- Original Logic (nur wenn nicht secret):
    if health < 50000 then
        ShowWarning()
    end
end
```

### Schritt 4: Ersetze Polling durch Events

```lua
-- VORHER (Polling):
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer >= 0.1 then
        self.timer = 0
        local charges = GetSpellCharges(mySpellID)
        UpdateChargeDisplay(charges)
    end
end)

-- NACHHER (Event-based):
local frame = CreateFrame("Frame")
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:SetScript("OnEvent", function(self, event)
    local charges = GetSpellCharges(mySpellID)
    UpdateChargeDisplay(charges)
end)
```

### Schritt 5: Verwende Secret-Safe Display Methods

```lua
-- VORHER:
function UpdateHealthText(health, maxHealth)
    local text = health .. " / " .. maxHealth
    fontString:SetText(text)
end

-- NACHHER (Secret-safe):
function UpdateHealthText(health, maxHealth)
    -- tostring() funktioniert auf Secrets:
    local text = tostring(health) .. " / " .. tostring(maxHealth)
    fontString:SetText(text)
    
    -- ODER: Verwende SetValue für Bars:
    healthBar:SetValue(health / maxHealth)  -- Funktioniert auch mit Secrets!
end
```

### Schritt 6: Adoptiere Duration Objects

```lua
-- VORHER:
function UpdateCooldown(spellID)
    local start, duration = GetSpellCooldown(spellID)
    cooldownFrame:SetCooldown(start, duration)
end

-- NACHHER (mit Duration Object für Action Buttons):
function UpdateCooldown(actionID)
    local duration = C_ActionBar.GetActionChargeDuration(actionID)
    if duration then
        cooldownFrame:SetCooldownFromDurationObject(duration)
    end
end

-- NACHHER (mit Guard für Spells):
function UpdateCooldown(spellID)
    local start, duration = GetSpellCooldown(spellID)
    
    if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
        -- Secret - alternative handling
        -- Option: Show generic "on cooldown" indicator
        return
    end
    
    cooldownFrame:SetCooldown(start, duration)
end
```

### Schritt 7: Teste auf Beta/PTR

**Test Cases:**
1. Out of Combat - sollte wie vorher funktionieren
2. Enter Combat - prüfe auf Lua Errors
3. During Combat - prüfe ob Features funktionieren oder graceful degradieren
4. Leave Combat - prüfe ob alles wieder normal funktioniert

### Migration Beispiel: Komplettes Feature

**VORHER (11.x):**
```lua
local LowHealthWarning = {}

function LowHealthWarning:Create()
    local frame = CreateFrame("Frame", "LowHealthFrame", UIParent)
    frame:SetSize(200, 50)
    frame:SetPoint("CENTER", 0, 200)
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("LOW HEALTH!")
    text:SetTextColor(1, 0, 0)
    frame.text = text
    
    frame:Hide()
    
    function frame:Update()
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        local percent = health / maxHealth
        
        if percent < 0.3 then
            self:Show()
        else
            self:Hide()
        end
    end
    
    frame:SetScript("OnUpdate", function(self, elapsed)
        self:Update()
    end)
    
    return frame
end
```

**NACHHER (12.0):**
```lua
local LowHealthWarning = {}

function LowHealthWarning:Create()
    local frame = CreateFrame("Frame", "LowHealthFrame", UIParent)
    frame:SetSize(200, 50)
    frame:SetPoint("CENTER", 0, 200)
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("LOW HEALTH!")
    text:SetTextColor(1, 0, 0)
    frame.text = text
    
    frame:Hide()
    
    -- Status tracking:
    frame.isLowHealth = false
    frame.canCheckHealth = true
    
    function frame:Update()
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        
        -- GUARD: Check if values are secret
        if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
            -- Secret - cannot determine if low health
            -- Keep current state or hide warning
            self.canCheckHealth = false
            if self.isLowHealth then
                -- Keep showing if was already low
                self:Show()
            end
            return
        end
        
        -- Not secret - normal logic:
        self.canCheckHealth = true
        local percent = health / maxHealth
        
        if percent < 0.3 then
            self.isLowHealth = true
            self:Show()
        else
            self.isLowHealth = false
            self:Hide()
        end
    end
    
    -- EVENT-BASED (statt OnUpdate):
    frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Enter Combat
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leave Combat
    
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Combat start - cache current state
            self.isLowHealth = false  -- Reset
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Combat end - full functionality restored
            self.canCheckHealth = true
        end
        
        self:Update()
    end)
    
    -- Initial update:
    frame:Update()
    
    return frame
end
```

---

## Bekannte Probleme & Workarounds

### Problem 1: Charge-Based Spells - Zero Detection

**Problem:**  
`if charges == 0 then` ist verboten.

**Workaround 1: ColorCurve**
```lua
local curve = C_CurveUtil.CreateColorCurve()
curve:SetType(Enum.LuaCurveType.Step)
curve:AddPoint(0.0, CreateColor(1, 0, 0, 1))  -- Rot bei 0
curve:AddPoint(0.01, CreateColor(0, 1, 0, 1)) -- Grün bei >0

-- Farbe setzt sich automatisch basierend auf Charges
```

**Workaround 2: Event-Based State Machine**
```lua
local chargeState = {
    estimatedCharges = 1,  -- Annahme: startet mit Charges
}

frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if spellID == mySpellID then
        -- Spell wurde gecastet → Charge verbraucht
        chargeState.estimatedCharges = math.max(0, chargeState.estimatedCharges - 1)
        
        if chargeState.estimatedCharges == 0 then
            -- Wir DENKEN Charges sind 0
            ShowOutOfChargesWarning()
        end
    end
end)

frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:SetScript("OnEvent", function()
    -- Charge regeneriert → refresh estimate
    local charges = GetSpellCharges(mySpellID)
    if not (issecretvalue and issecretvalue(charges)) then
        chargeState.estimatedCharges = charges
    end
end)
```

### Problem 2: Health Thresholds

**Problem:**  
`if health < threshold then` ist verboten.

**Workaround: ColorCurve für Visuals**
```lua
-- Statt Logic, nutze visuelle Indikatoren:
local curve = C_CurveUtil.CreateColorCurve()
curve:SetType(Enum.LuaCurveType.Linear)

-- Definiere Thresholds als Farb-Übergänge:
curve:AddPoint(0.0, CreateColor(1, 0, 0, 1))   -- Rot bei 0% (tot)
curve:AddPoint(0.2, CreateColor(1, 0, 0, 1))   -- Rot bis 20%
curve:AddPoint(0.5, CreateColor(1, 1, 0, 1))   -- Gelb bei 50%
curve:AddPoint(1.0, CreateColor(0, 1, 0, 1))   -- Grün bei 100%

-- Health Bar färbt sich automatisch:
local color = UnitHealthPercent("player", false, curve)
healthBar:GetStatusBarTexture():SetVertexColor(color:GetRGB())

-- Spieler SIEHT die Farbe → muss selbst entscheiden
-- Addon kann nicht automatisch reagieren
```

### Problem 3: Buff Duration Tracking

**Problem:**  
`expirationTime` von Buffs kann Secret sein.

**Workaround 1: UNIT_AURA Event**
```lua
-- Tracke WANN Buffs added/removed werden statt Duration:
local buffTracker = {
    activeBuff = nil,
    buffStartTime = 0,
}

frame:RegisterUnitEvent("UNIT_AURA", "player")
frame:SetScript("OnEvent", function(self, event, unit, updateInfo)
    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if aura.spellId == myBuffID then
                buffTracker.activeBuff = aura
                buffTracker.buffStartTime = GetTime()
                OnBuffGained(aura)
            end
        end
    end
    
    if updateInfo.removedAuraInstanceIDs then
        -- Buff removed
        buffTracker.activeBuff = nil
        OnBuffLost()
    end
end)
```

**Workaround 2: Duration Object (falls verfügbar)**
```lua
-- Für bestimmte Buffs/Auras:
local auraData = C_UnitAuras.GetAuraDataByIndex("player", 1)
if auraData and auraData.duration then
    -- Könnte Duration Object sein
    -- Übergebe an Timer Widget
end
```

### Problem 4: Cooldown Scheduling

**Problem:**  
Kann nicht mehr `C_Timer.After(cooldownRemaining, ...)` machen wenn `cooldownRemaining` Secret ist.

**Workaround: Event-Based + Periodic Updates**
```lua
local cooldownTracker = {
    knownCooldownEnd = 0,
    updateTimer = nil,
}

-- Event: Cooldown started
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:SetScript("OnEvent", function()
    local start, duration = GetSpellCooldown(spellID)
    
    if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
        -- Secret - können nicht schedulen
        -- Stattdessen: Periodic Check
        if not cooldownTracker.updateTimer then
            cooldownTracker.updateTimer = C_Timer.NewTicker(0.5, function()
                UpdateCooldownDisplay()
            end)
        end
    else
        -- Normal - können schedulen
        if cooldownTracker.updateTimer then
            cooldownTracker.updateTimer:Cancel()
            cooldownTracker.updateTimer = nil
        end
        
        cooldownTracker.knownCooldownEnd = start + duration
        C_Timer.After(duration, function()
            OnCooldownComplete()
        end)
    end
end)
```

### Problem 5: Combat Log Parsing

**Problem:**  
`COMBAT_LOG_EVENT_UNFILTERED` ist blockiert während Encounter/M+.

**Status:**  
- Komplett disabled während Raid Encounters
- Komplett disabled während M+ runs
- Funktioniert außerhalb von Encounters

**Workaround:**  
Keine echte Lösung. Blizzard bietet alternative APIs:
- Damage Meter: Nutze Blizzards built-in Damage Meter
- Boss Mods: Nutze Blizzards Boss Warnings System
- Für Custom Features: Nutze andere Events (`UNIT_SPELLCAST_*`, `UNIT_AURA`, etc.)

### Problem 6: Secret Tables

**Problem:**  
Table wurde permanent als "secret" markiert (durch Secret als Key).

**Lösung:**  
**VERMEIDEN!** Nie Secrets als Table Keys verwenden!

```lua
-- SCHLECHT (macht Table permanent secret):
local myTable = {}
local secretKey = GetSomeSecret()
myTable[secretKey] = "value"  -- ❌ Table ist jetzt permanent secret!

-- GUT (verwende separate Tables):
local normalTable = {}
local keyMapping = {}

local secretKey = GetSomeSecret()
local normalKey = "key_" .. tostring(GetTime())  -- oder UUID
normalTable[normalKey] = "value"
keyMapping[normalKey] = secretKey  -- Mapping gespeichert aber Table bleibt normal
```

---

## Code-Beispiele

### Beispiel 1: Simple Health Bar

```lua
local SimpleHealthBar = {}

function SimpleHealthBar:Create()
    -- Frame Setup
    local frame = CreateFrame("Frame", "SimpleHealthBar", UIParent)
    frame:SetSize(250, 30)
    frame:SetPoint("CENTER", 0, -100)
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Status Bar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("TOPLEFT", 5, -5)
    bar:SetPoint("BOTTOMRIGHT", -5, 5)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    frame.bar = bar
    
    -- Color Curve (Green → Yellow → Red)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:AddPoint(0.0, CreateColor(1, 0, 0, 1))   -- Red
    curve:AddPoint(0.4, CreateColor(1, 1, 0, 1))   -- Yellow
    curve:AddPoint(0.7, CreateColor(0, 1, 0, 1))   -- Green
    frame.curve = curve
    
    -- Text
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    frame.text = text
    
    -- Update Function
    function frame:Update()
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        
        -- Bar Value (works with secrets!)
        self.bar:SetValue(health / maxHealth)
        
        -- Color (works with secrets!)
        local usePredicted = false
        local color = UnitHealthPercent("player", usePredicted, self.curve)
        self.bar:GetStatusBarTexture():SetVertexColor(color:GetRGB())
        
        -- Text (tostring works on secrets!)
        self.text:SetText(tostring(health) .. " / " .. tostring(maxHealth))
    end
    
    -- Event Registration
    frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    
    frame:SetScript("OnEvent", function(self)
        self:Update()
    end)
    
    -- Initial Update
    frame:Update()
    
    return frame
end

-- Usage:
-- local myHealthBar = SimpleHealthBar:Create()
```

### Beispiel 2: Charge-Based Spell Tracker

```lua
local ChargeTracker = {}

function ChargeTracker:Create(spellID, spellName)
    -- Frame Setup
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(100, 50)
    frame:SetPoint("CENTER")
    
    frame.spellID = spellID
    frame.spellName = spellName or GetSpellInfo(spellID)
    
    -- Icon
    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetSize(40, 40)
    icon:SetTexture(select(3, GetSpellInfo(spellID)))
    frame.icon = icon
    
    -- Charge Text
    local charges = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    charges:SetPoint("RIGHT", icon, "RIGHT", -5, 0)
    charges:SetJustifyH("RIGHT")
    frame.charges = charges
    
    -- Cooldown Frame
    local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    cd:SetDrawEdge(false)
    frame.cooldown = cd
    
    -- Ready Indicator
    local ready = frame:CreateTexture(nil, "OVERLAY")
    ready:SetPoint("CENTER", icon)
    ready:SetSize(50, 50)
    ready:SetTexture("Interface\\Cooldown\\star4")
    ready:SetBlendMode("ADD")
    ready:Hide()
    frame.ready = ready
    
    -- State
    frame.lastChargeCount = 0
    
    -- Update Function
    function frame:Update()
        local charges, maxCharges, start, duration = GetSpellCharges(self.spellID)
        
        -- Text Display (works with secrets!)
        if charges and maxCharges then
            self.charges:SetText(tostring(charges) .. "/" .. tostring(maxCharges))
            
            -- Check if we can compare (not secret):
            if not (issecretvalue and issecretvalue(charges)) then
                -- Normal - can do logic
                if charges > self.lastChargeCount and charges == maxCharges then
                    -- Charges are full!
                    self:ShowReadyAnimation()
                end
                self.lastChargeCount = charges
            end
        else
            self.charges:SetText("?")
        end
        
        -- Cooldown Display
        if not (issecretvalue and (issecretvalue(start) or issecretvalue(duration))) then
            -- Normal - can use SetCooldown
            if duration > 0 then
                self.cooldown:SetCooldown(start, duration)
            else
                self.cooldown:Clear()
            end
        end
    end
    
    function frame:ShowReadyAnimation()
        self.ready:Show()
        self.ready:SetAlpha(1)
        
        -- Fade out animation
        UIFrameFadeOut(self.ready, 1, 1, 0)
        C_Timer.After(1, function()
            self.ready:Hide()
        end)
    end
    
    -- Event Registration
    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    
    frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if spellID == self.spellID then
                self:Update()
            end
        else
            self:Update()
        end
    end)
    
    -- Initial Update
    frame:Update()
    
    return frame
end

-- Usage:
-- local tracker = ChargeTracker:Create(51505, "Lava Burst")
```

### Beispiel 3: Safe API Wrapper

```lua
-- Utility Library für Safe API Calls:
local SafeAPI = {}

-- Wrapper für UnitHealth mit automatic guards:
function SafeAPI.GetUnitHealth(unit)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    local isSecret = issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth))
    
    return {
        current = health,
        max = maxHealth,
        isSecret = isSecret,
        
        -- Helper methods:
        GetPercent = function(self)
            if self.isSecret then
                return nil  -- Cannot calculate
            end
            return self.current / self.max
        end,
        
        IsLow = function(self, threshold)
            if self.isSecret then
                return nil  -- Cannot determine
            end
            return self:GetPercent() < threshold
        end,
        
        -- For display (always works):
        GetDisplayText = function(self)
            return tostring(self.current) .. " / " .. tostring(self.max)
        end,
        
        SetStatusBar = function(self, statusBar)
            -- Works even with secrets:
            statusBar:SetValue(self.current / self.max)
        end,
    }
end

-- Usage:
local health = SafeAPI.GetUnitHealth("player")

-- For logic (might be nil):
local percent = health:GetPercent()
if percent and percent < 0.3 then
    print("Low health!")
end

-- For display (always works):
fontString:SetText(health:GetDisplayText())
healthBar:SetValue(health.current / health.max)
```

### Beispiel 4: Event-Based Buff Monitor

```lua
local BuffMonitor = {}

function BuffMonitor:Create(trackedBuffs)
    -- trackedBuffs = { [spellID] = true, ... }
    
    local monitor = {
        trackedBuffs = trackedBuffs or {},
        activeBuffs = {},  -- { [spellID] = auraData }
        callbacks = {},    -- { gained = {}, lost = {} }
    }
    
    -- Frame for events
    monitor.frame = CreateFrame("Frame")
    monitor.frame:RegisterUnitEvent("UNIT_AURA", "player")
    
    monitor.frame:SetScript("OnEvent", function(self, event, unit, updateInfo)
        if not updateInfo then return end
        
        -- Added Auras
        if updateInfo.addedAuras then
            for _, auraData in ipairs(updateInfo.addedAuras) do
                local spellID = auraData.spellId
                if monitor.trackedBuffs[spellID] then
                    monitor.activeBuffs[spellID] = auraData
                    monitor:FireCallback("gained", spellID, auraData)
                end
            end
        end
        
        -- Removed Auras
        if updateInfo.removedAuraInstanceIDs then
            -- Need to check which spellID was removed
            for spellID, auraData in pairs(monitor.activeBuffs) do
                for _, instanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                    if auraData.auraInstanceID == instanceID then
                        monitor.activeBuffs[spellID] = nil
                        monitor:FireCallback("lost", spellID, auraData)
                        break
                    end
                end
            end
        end
    end)
    
    -- Register Callback
    function monitor:On(event, callback)
        -- event = "gained" or "lost"
        if not self.callbacks[event] then
            self.callbacks[event] = {}
        end
        table.insert(self.callbacks[event], callback)
    end
    
    -- Fire Callbacks
    function monitor:FireCallback(event, spellID, auraData)
        if not self.callbacks[event] then return end
        
        for _, callback in ipairs(self.callbacks[event]) do
            callback(spellID, auraData)
        end
    end
    
    -- Check if buff is active
    function monitor:HasBuff(spellID)
        return self.activeBuffs[spellID] ~= nil
    end
    
    -- Get buff data (might have secret values!)
    function monitor:GetBuff(spellID)
        return self.activeBuffs[spellID]
    end
    
    return monitor
end

-- Usage:
local monitor = BuffMonitor:Create({
    [1126] = true,   -- Mark of the Wild
    [21562] = true,  -- Power Word: Fortitude
})

monitor:On("gained", function(spellID, auraData)
    print("Buff gained:", GetSpellInfo(spellID))
    
    -- Can use event-based logic without comparing secret values
    if spellID == 1126 then
        print("Got Mark of the Wild!")
    end
end)

monitor:On("lost", function(spellID, auraData)
    print("Buff lost:", GetSpellInfo(spellID))
end)

-- Check status (no secret comparison needed):
if monitor:HasBuff(1126) then
    print("Has Mark of the Wild")
end
```

---

## Wichtige Ressourcen

### Offizielle Dokumentation

1. **In-Game API Documentation**
   ```lua
   /api
   ```
   - Öffnet das offizielle API Documentation Interface
   - Zeigt alle verfügbaren APIs mit Parametern

2. **Blizzard News Post**
   - https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight
   - Offizielle Erklärung der Änderungen

3. **Warcraft Wiki - API Changes**
   - https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
   - Detaillierte Liste aller API-Änderungen

4. **Warcraft Wiki - Planned Changes**
   - https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes
   - Updates und Änderungen während Alpha/Beta

### Community Ressourcen

1. **WoW UI Dev Discord**
   - Haupt-Community für Addon Entwickler
   - #addon-restrictions-feedback channel für 12.0 Issues
   - Direkter Kontakt zu Blizzard Devs

2. **GitHub - WoWUIBugs**
   - https://github.com/Stanzilla/WoWUIBugs/issues/
   - Bug Reports und Issues tracking
   - Real-world Probleme und Solutions

3. **Wowhead Guides**
   - https://www.wowhead.com/news/ (filter: addon)
   - News und Updates zu Addon-Änderungen

4. **Icy Veins**
   - https://www.icy-veins.com/wow/news/
   - Addon News und Guides

### Code Repositories

1. **LibActionButton-1.0**
   - Standard Library für Action Buttons
   - Compatibility Layer für verschiedene Addons

2. **tullaCTC (tullamods)**
   - https://github.com/tullamods/tullaCTC
   - Charge Cooldown Addon - gutes Beispiel für 12.0 Patterns

3. **OmniCC**
   - Cooldown Text Addon
   - Zeigt moderne Cooldown Detection Patterns

4. **Inomena**
   - https://github.com/p3lim-wow/Inomena
   - Cooldown Module mit hooksecurefunc Beispielen

### Testing & Development

1. **PTR (Public Test Realm)**
   - Für 12.0.0 (Pre-Patch) Testing
   - Verfügbar mehrere Wochen vor Release

2. **Beta**
   - Für 12.0.1 (Midnight Launch) Testing
   - Addon Developer Access möglich

3. **BugGrabber & BugSack**
   - Essential für Lua Error Tracking
   - Zeigt detaillierte Error Messages

### Lua Resources

1. **Lua 5.1 Reference Manual**
   - http://www.lua.org/manual/5.1/
   - WoW nutzt Lua 5.1

2. **WoW Programming Forums**
   - https://wowprogramming.com/
   - Alte aber wertvolle Ressource

3. **WoWInterface Forums**
   - https://www.wowinterface.com/forums/
   - Addon Development Community

---

## Abschluss & Best Practices

### Die wichtigsten Takeaways

1. **Secret Values sind "Black Boxes"**
   - Du kannst sie empfangen und anzeigen
   - Du kannst sie NICHT auslesen oder vergleichen
   - Du kannst KEINE Logik darauf basieren

2. **Denke in Events, nicht in Polling**
   - `SPELL_UPDATE_CHARGES` statt OnUpdate mit GetSpellCharges()
   - `UNIT_AURA` statt wiederholtes C_UnitAuras aufrufen
   - `UNIT_HEALTH` statt konstantes UnitHealth() polling

3. **Verwende die neuen APIs**
   - ColorCurve für visuelle Thresholds
   - Duration Objects für Cooldowns
   - C_ActionBar für Action Button Infos

4. **Guards, Guards, Guards**
   ```lua
   if issecretvalue and issecretvalue(value) then
       -- Handle secret case
       return
   end
   -- Normal logic
   ```

5. **Graceful Degradation**
   - Addon sollte nie crashen
   - Features können im Combat eingeschränkt sein
   - Informiere den User über Limitations

### Philosophie-Shift

**Alt (11.x):**
- "Mein Addon weiß alles und entscheidet automatisch"
- "Ich zeige dem Spieler was zu tun ist"
- "Perfekte Rotation, automatisch berechnet"

**Neu (12.0):**
- "Mein Addon zeigt Informationen an"
- "Der Spieler sieht die Info und entscheidet selbst"
- "Visuelles Feedback statt automatische Entscheidungen"

### Debugging Tipps

1. **Secret Value Errors erkennen:**
   ```
   Error: attempt to compare secret with number
   Error: attempt to perform arithmetic on secret
   ```

2. **BugSack/BugGrabber verwenden:**
   - Zeigt komplette Stack Traces
   - Filtere nach "secret" um relevante Errors zu finden

3. **Out-of-Combat Testing:**
   - Teste IMMER out of combat zuerst
   - Dann in Combat testen
   - Vergleiche Verhalten

4. **Print Debugging mit tostring():**
   ```lua
   print("Value:", tostring(secretValue))  -- Funktioniert!
   print("Is secret?", issecretvalue(secretValue))
   ```

### Performance Überlegungen

1. **Event-based ist effizienter als Polling**
   ```lua
   -- SCHLECHT (CPU-intensiv):
   frame:SetScript("OnUpdate", function(self, elapsed)
       -- Läuft jeden Frame!
   end)
   
   -- GUT (nur wenn nötig):
   frame:RegisterEvent("SPELL_UPDATE_CHARGES")
   ```

2. **Cached Curves wiederverwenden:**
   ```lua
   -- SCHLECHT (erstellt jedes Mal neu):
   function Update()
       local curve = C_CurveUtil.CreateColorCurve()
       curve:SetType(...)
       -- ...
   end
   
   -- GUT (erstelle einmal):
   local curve = C_CurveUtil.CreateColorCurve()
   curve:SetType(...)
   
   function Update()
       -- Verwende existierende curve
   end
   ```

3. **Event Filtering:**
   ```lua
   -- Registriere nur Events die du brauchst
   -- Filtere in OnEvent so früh wie möglich
   frame:SetScript("OnEvent", function(self, event, unit, ...)
       if unit ~= "player" then return end  -- Early return
       -- ...
   end)
   ```

### Zukunftssicher bleiben

1. **Folge den offiziellen Updates**
   - Blizzard posted regelmäßig in WoW UI Dev Discord
   - Warcraft Wiki wird aktualisiert
   - Patch Notes lesen!

2. **Teste auf PTR/Beta**
   - Neue Patches können weitere Änderungen bringen
   - Früh testen = früh anpassen

3. **Flexible Code-Architektur**
   - Mache es einfach Features zu disablen
   - Verwende Feature Flags
   - Graceful Degradation einbauen

4. **Community Engagement**
   - Teile deine Lösungen
   - Lerne von anderen Addon-Entwicklern
   - Stelle Whitelist-Requests für wichtige Spells

### Schlusswort

Die Änderungen in 12.0 sind drastisch, aber sie sind **machbar**. Die Addon-Community hat schon viele große Änderungen gemeistert (2.0 Secure Templates, 7.0 API Changes, etc.).

**Wichtig:**
- Panik ist nicht notwendig
- Die meisten Features sind adaptierbar
- Manche Features müssen wegfallen
- Das Spiel wird zugänglicher für alle

**Dein Addon in 12.0:**
- Kann weiterhin existieren
- Muss anders implementiert werden
- Wird eingeschränkter sein
- Aber kann immer noch wertvoll sein

Viel Erfolg beim Addon-Development für Midnight! 🚀

---

**Letztes Update:** Februar 2026  
**Für:** WoW Patch 12.0.0 (Midnight Pre-Patch) & 12.0.1 (Midnight Launch)  
**Status:** Beta/PTR Testing Phase

---
