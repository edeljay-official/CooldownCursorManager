# WoW Addon Development Research - Patch 12.0.0

This document summarizes research for developing World of Warcraft addons for the Midnight expansion (Patch 12.0.0).

## Table of Contents
- [Key Resources](#key-resources)
- [Patch 12.0.0 API Changes](#patch-1200-api-changes)
- [Taint System, Secure Execution, and Secret Values](#taint-system-secure-execution-and-secret-values)
- [Displaying and Manipulating Secret Values](#displaying-and-manipulating-secret-values)
  - [Using Duration and Curve APIs](#using-duration-and-curve-apis)
  - [Event-Based Tracking](#event-based-tracking)
- [Findings from Local Files](#findings-from-local-files)
- [Web Research Summary](#web-research-summary)

---

## Key Resources
- **[Patch 12.0.0/API changes (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)**: Primary source for high-level API changes, the introduction of Secret Values, and the new security model.
- **[message.txt (local file)](message.txt)**: Crucial, in-depth explanation of Secret Values, permitted/prohibited operations, and practical workarounds using Duration/Curve APIs.
- **[Inomena Cooldowns Module (GitHub)](https://github.com/p3lim-wow/Inomena/blob/master/modules/blizzard/cooldowns.lua)**: Practical code example of interacting with cooldowns and using `hooksecurefunc` to avoid taint.
- **[WoWUIBugs (GitHub Issues)](https://github.com/Stanzilla/WoWUIBugs/issues/)**: Real-world examples of bugs and developer struggles with the new secret value system.
- **[World of Warcraft API (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)**: General overview of the API structure.
- **[WoW Programming API Docs](https://wowprogramming.com/docs/api.html)**: Detailed reference for specific API functions, including `[protected]` and `[deprecated]` tags.

---

## Patch 12.0.0 API Changes
Patch 12.0.0 introduces massive security-focused changes to the addon API. The goal is to allow addons to display combat data without being able to programmatically read or make decisions based on it.

- **Introduction of "Secret Values"**: The core of the change. Many combat-related API functions now return "secret" values instead of plain numbers or strings when called on a "tainted" execution path (e.g., in combat).
- **New `C_` APIs**:
    - `C_RestrictedActions` and `C_Secrets` provide functions to test the state of addon restrictions.
    - New functions like `issecretvalue(value)`, `canaccesssecrets()`, `issecrettable(table)` are available to check if you are dealing with secret data.
- **Changes to Existing Functions**: Many functions, especially those related to unit stats (`UnitHealth`), cooldowns (`GetSpellCharges`), and action bars, are affected by the new security model.
- **Official In-Game Documentation**: The API is now officially documented in-game via the `Blizzard_APIDocumentation` addon.

---

## Taint System, Secure Execution, and Secret Values
This is the most significant change for addon developers in Patch 12.0.0.

- **What are Secret Values?** They are "black box" data types. Your code can receive them, store them, and pass them to *specific* Blizzard APIs, but you cannot inspect or operate on them directly. The philosophy is: **addons can show information, but cannot know or automate decisions based on it.**

- **What is a "Tainted" Execution Path?** In simple terms, code is considered "tainted" when it's running in a context where Blizzard wants to prevent automation, primarily during combat. Any function that is not "secure" can taint the execution path. For example, trying to use a protected function from an insecure context.

- **Prohibited Operations (cause Lua errors):**
    - **Comparison:** `==`, `<`, `>`, `<=`, `>=`
    - **Arithmetic:** `+`, `-`, `*`, `/`
    - **Boolean Tests:** `if secretValue then ...`
    - **Concatenation:** `..`
    - **Length Operator:** `#`
    - **Table Keys:** Using a secret value as a key in a table.

- **Permitted Operations:**
    - Storing in variables.
    - Passing to other Lua functions.
    - Passing to specific, approved Blizzard APIs (e.g., `StatusBar:SetValue`, `FontString:SetText`).
    - Using `tostring(secretValue)` for display purposes.

- **The Guard Pattern:** To prevent errors, you must check if a value is secret before operating on it.
    ```lua
    -- Example guard before performing an operation
    if issecretvalue and issecretvalue(myValue) then
        -- It's a secret, so don't try to compare or do math.
        -- Use an approved display method instead.
        return
    end
    -- If we get here, myValue is not a secret and is safe to use.
    ```

---

## Displaying and Manipulating Secret Values

### Using Duration and Curve APIs
You cannot check `if currentCharges == 0 then`. Instead, you use "computed displays" that transform the secret value into a visual output without your code ever knowing the number.

- **`C_CurveUtil.CreateColorCurve()`**: This allows you to define a visual change based on a value. For example, to make a texture red when charges are at 0 and green otherwise:
    ```lua
    -- Create a curve that changes color at the zero point.
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    -- AddPoint(value, color)
    curve:AddPoint(0.0, CreateColor(1, 0, 0, 1))  -- Red at value 0
    curve:AddPoint(0.01, CreateColor(0, 1, 0, 1)) -- Green at any value > 0
    ```
    You would then use this curve with a UI widget that can apply it to a secret value. The UI element itself handles the logic internally.

- **`C_DurationUtil.CreateDuration()`**: For time-based secret values (like cooldowns), you can create a Duration object. This object can be passed directly to timer-enabled widgets.
    ```lua
    -- C_ActionBar functions often return a non-secret DurationObject directly
    local durationObject = C_ActionBar.GetActionChargeDuration(actionID)
    -- This object can be used to drive a status bar or cooldown spiral
    StatusBar:SetTimerDuration(durationObject)
    ```

### Event-Based Tracking
Instead of polling a function like `GetSpellCharges()` every frame (which would return a secret value in combat), the modern approach is to listen for events.

- **`SPELL_UPDATE_CHARGES`**: Fires when a spell's charges change.
- **`SPELL_UPDATE_COOLDOWN`**: Fires on general cooldown state changes.
- **`UNIT_SPELLCAST_SUCCEEDED`**: Can be used to decrement a charge counter you maintain (this counter would be an estimate, not the true value).

By tracking these events, an addon can maintain a reasonably accurate state of charges and cooldowns without ever needing to inspect a secret value.

---

## Findings from Local Files
- **`message.txt`**: This file is the cornerstone of this research. It provides a phenomenal, in-depth guide to the entire "Secret Values" system, detailing the problems and the solutions. It explains the design philosophy, what operations are permitted versus prohibited, the new API functions for checking secrets (`issecretvalue` etc.), and the practical workarounds using the Curve and Duration APIs. It is the primary source for the "Secret Values" and "Curve Functions" sections of this document.
- **`README.md`**: Describes the **CooldownCursorManager** addon. This serves as a good example of a modern, feature-rich addon that interacts with cooldowns and personal resources, demonstrating the kinds of UI manipulations that are possible within the API's rules.

---

## Web Research Summary
The web research confirmed and expanded upon the information in `message.txt`.

- The **Warcraft Wiki** and **WoW Programming** sites provide the high-level context and API references, confirming the introduction of the secret value system and listing the new functions.
- The **Inomena GitHub file** shows a real-world implementation of a cooldown module, making use of `hooksecurefunc`. This is a key technique to safely modify the behavior of Blizzard's default UI without causing taint issues.
- The **WoWUIBugs GitHub issues page** is a valuable resource, showing the real-time struggles and bug reports from addon authors. It contains many discussions about "secret value errors" and shows how developers are trying to adapt.
- Several links to **townlong-yak.com**, a popular FrameXML resource, were inaccessible. This means direct browsing of the default UI code from that source is not possible at this time.
