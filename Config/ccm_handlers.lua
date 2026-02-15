--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_handlers.lua
-- Configuration UI event handlers and callbacks
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, CCM = ...
local addonTable = CCM
local function GetProfile() return addonTable.GetProfile and addonTable.GetProfile() end
local function CreateIcons() if addonTable.CreateIcons then addonTable.CreateIcons() end end
local function UpdateAllIcons()
  if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
end
local SetStyledSliderShown = addonTable.SetStyledSliderShown
local AttachCheckboxTooltip = addonTable.AttachCheckboxTooltip
local TRACK_BUFFS_TOOLTIP_TEXT = "Add buffs to Blizzard's CDM Buff Tracker\nand to the spell list below.\nTracked buffs are hidden in Blizzard CDM.\nIn Edit Mode, set Buff Tracker to\nAlways Visible or In Combat."
local DISABLE_BLIZZ_CDM_TOOLTIP_TEXT = "Disables Blizzard CDM bars and related integration.\nIf Track Buffs is enabled in any bar,\nthis option is re-enabled automatically."
local function IsAnyTrackBuffsEnabled(profile)
  if not profile then return false end
  if profile.trackBuffs ~= false then return true end
  if profile.customBarTrackBuffs ~= false then return true end
  if profile.customBar2TrackBuffs ~= false then return true end
  if profile.customBar3TrackBuffs ~= false then return true end
  if profile.customBar4TrackBuffs ~= false then return true end
  if profile.customBar5TrackBuffs ~= false then return true end
  return false
end
local function SetAllTrackBuffsEnabled(profile, enabled)
  if type(profile) ~= "table" then return false end
  local target = enabled == true
  local changed = false
  local function SetFlag(key)
    local isEnabled = profile[key] ~= false
    if isEnabled ~= target then
      profile[key] = target
      changed = true
    end
  end
  SetFlag("trackBuffs")
  SetFlag("customBarTrackBuffs")
  SetFlag("customBar2TrackBuffs")
  SetFlag("customBar3TrackBuffs")
  SetFlag("customBar4TrackBuffs")
  SetFlag("customBar5TrackBuffs")
  return changed
end
local function IsModuleEnabled(moduleKey)
  if addonTable.IsModuleEnabled then
    return addonTable.IsModuleEnabled(moduleKey)
  end
  return true
end
local function SetModuleEnabled(moduleKey, enabled)
  if addonTable.SetModuleEnabled then
    return addonTable.SetModuleEnabled(moduleKey, enabled)
  end
  return false, false
end
local function SetTabControlsEnabled(tabIndex, enabled)
  if type(tabIndex) ~= "number" then return end
  local tabFrames = addonTable.tabFrames
  local root = tabFrames and tabFrames[tabIndex]
  if not root then return end
  root:SetAlpha(enabled and 1 or 0.45)
  local seen = {}
  local function Walk(frame)
    if not frame or seen[frame] then return end
    seen[frame] = true
    if frame.SetEnabled then pcall(frame.SetEnabled, frame, enabled) end
    if frame.EnableMouse then pcall(frame.EnableMouse, frame, enabled) end
    if frame.GetNumChildren and frame.GetChildren then
      local n = frame:GetNumChildren() or 0
      for i = 1, n do
        local child = select(i, frame:GetChildren())
        Walk(child)
      end
    end
  end
  Walk(root)
end
local function SyncQolTabControlsState()
  local qolOn = IsModuleEnabled("qol")
  SetTabControlsEnabled(addonTable.TAB_QOL or 12, qolOn)
  SetTabControlsEnabled(addonTable.TAB_FEATURES or 18, qolOn)
  SetTabControlsEnabled(addonTable.TAB_ACTIONBARS or 14, qolOn)
  SetTabControlsEnabled(addonTable.TAB_CHAT or 15, qolOn)
  SetTabControlsEnabled(addonTable.TAB_SKYRIDING or 16, qolOn)
  SetTabControlsEnabled(addonTable.TAB_COMBAT or 19, qolOn)
end
local function SyncModuleControlsState()
  local function SetControlEnabled(control, enabled)
    if not control then return end
    if control.SetEnabled then control:SetEnabled(enabled) end
    if control.SetAlpha then control:SetAlpha(enabled and 1 or 0.45) end
    if control.label and control.label.SetTextColor then
      control.label:SetTextColor(enabled and 0.9 or 0.45, enabled and 0.9 or 0.45, enabled and 0.9 or 0.45)
    end
  end
  local cbarsOn = IsModuleEnabled("custombars")
  local castbarsOn = IsModuleEnabled("castbars")
  local debuffsOn = IsModuleEnabled("debuffs")
  local unitframesOn = IsModuleEnabled("unitframes")
  local qolOn = IsModuleEnabled("qol")
  SetControlEnabled(addonTable.customBarsModuleCB, true)
  SetControlEnabled(addonTable.qolModuleCB, true)
  SetControlEnabled(addonTable.customBarsCountSlider, cbarsOn)
  SetControlEnabled(addonTable.disableBlizzCDMCB, true)
  SetControlEnabled(addonTable.prbCB, true)
  SetControlEnabled(addonTable.castbarCB, true)
  SetControlEnabled(addonTable.focusCastbarCB, castbarsOn)
  SetControlEnabled(addonTable.targetCastbarCB, castbarsOn)
  SetControlEnabled(addonTable.playerDebuffsCB, true)
  SetControlEnabled(addonTable.unitFrameCustomizationCB, true)
  SetControlEnabled(addonTable.combatTimerCB, qolOn)
  SetControlEnabled(addonTable.crTimerCB, qolOn)
  SetControlEnabled(addonTable.combatStatusCB, qolOn)
  if not castbarsOn then
    if addonTable.StopCastbarPreview then addonTable.StopCastbarPreview() end
    if addonTable.StopFocusCastbarPreview then addonTable.StopFocusCastbarPreview() end
    if addonTable.StopTargetCastbarPreview then addonTable.StopTargetCastbarPreview() end
  end
  if not debuffsOn then
    if addonTable.StopDebuffPreview then addonTable.StopDebuffPreview() end
  end
  if not qolOn then
    if addonTable.StopNoTargetAlertPreview then addonTable.StopNoTargetAlertPreview() end
    if addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end
    if addonTable.StopSkyridingPreview then addonTable.StopSkyridingPreview() end
    if addonTable.StopLowHealthWarningPreview then addonTable.StopLowHealthWarningPreview() end
  end
  if addonTable.ResetAllPreviewHighlights then addonTable.ResetAllPreviewHighlights() end
  SetTabControlsEnabled(addonTable.TAB_UF or 11, unitframesOn)
  SetTabControlsEnabled(addonTable.TAB_UF_PLAYER or 22, unitframesOn)
  SetTabControlsEnabled(addonTable.TAB_UF_TARGET or 23, unitframesOn)
  SetTabControlsEnabled(addonTable.TAB_UF_FOCUS or 24, unitframesOn)
  SetTabControlsEnabled(addonTable.TAB_UF_BOSS or 25, unitframesOn)
  SyncQolTabControlsState()
end
local function SyncTrackBuffsCheckboxesFromProfile(profile)
  if type(profile) ~= "table" then return end
  if addonTable.cur and addonTable.cur.trackBuffsCB then addonTable.cur.trackBuffsCB:SetChecked(profile.trackBuffs ~= false) end
  if addonTable.cur and addonTable.cur.openBlizzBuffBtn then addonTable.cur.openBlizzBuffBtn:SetShown(profile.trackBuffs ~= false) end
  if addonTable.cb1 and addonTable.cb1.trackBuffsCB then addonTable.cb1.trackBuffsCB:SetChecked(profile.customBarTrackBuffs ~= false) end
  if addonTable.cb1 and addonTable.cb1.openBlizzBuffBtn then addonTable.cb1.openBlizzBuffBtn:SetShown(profile.customBarTrackBuffs ~= false) end
  if addonTable.cb2 and addonTable.cb2.trackBuffsCB then addonTable.cb2.trackBuffsCB:SetChecked(profile.customBar2TrackBuffs ~= false) end
  if addonTable.cb2 and addonTable.cb2.openBlizzBuffBtn then addonTable.cb2.openBlizzBuffBtn:SetShown(profile.customBar2TrackBuffs ~= false) end
  if addonTable.cb3 and addonTable.cb3.trackBuffsCB then addonTable.cb3.trackBuffsCB:SetChecked(profile.customBar3TrackBuffs ~= false) end
  if addonTable.cb3 and addonTable.cb3.openBlizzBuffBtn then addonTable.cb3.openBlizzBuffBtn:SetShown(profile.customBar3TrackBuffs ~= false) end
  if addonTable.cb4 and addonTable.cb4.trackBuffsCB then addonTable.cb4.trackBuffsCB:SetChecked(profile.customBar4TrackBuffs ~= false) end
  if addonTable.cb4 and addonTable.cb4.openBlizzBuffBtn then addonTable.cb4.openBlizzBuffBtn:SetShown(profile.customBar4TrackBuffs ~= false) end
  if addonTable.cb5 and addonTable.cb5.trackBuffsCB then addonTable.cb5.trackBuffsCB:SetChecked(profile.customBar5TrackBuffs ~= false) end
  if addonTable.cb5 and addonTable.cb5.openBlizzBuffBtn then addonTable.cb5.openBlizzBuffBtn:SetShown(profile.customBar5TrackBuffs ~= false) end
end
local function EnsureTrackBuffsCompatible(profile)
  if type(profile) ~= "table" then return false end
  if profile.disableBlizzCDM == true and IsAnyTrackBuffsEnabled(profile) then
    return SetAllTrackBuffsEnabled(profile, false)
  end
  return false
end
local function EnsureDisableBlizzCDMCompatible(profile)
  if type(profile) ~= "table" then return false end
  if profile.disableBlizzCDM == true and IsAnyTrackBuffsEnabled(profile) then
    local changed = false
    local moduleChanged, needsReload = SetModuleEnabled("blizzcdm", true)
    if moduleChanged then
      changed = true
    end
    if profile.disableBlizzCDM == true then
      profile.disableBlizzCDM = false
      changed = true
    end
    return changed, needsReload
  end
  return false, false
end
local function ResolveLSMFontValueFromPath(path)
  if type(path) ~= "string" or path == "" then return nil end
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if not LSM then return nil end
  local lsmFonts = LSM:HashTable("font")
  if not lsmFonts then return nil end
  for name, fontPath in pairs(lsmFonts) do
    if fontPath == path then
      return "lsm:" .. name
    end
  end
  return nil
end
local function NormalizeGlobalFontSelection(profile)
  if not profile then return "lsm:Friz Quadrata TT" end
  local sel = profile.cdFont
  if type(sel) == "string" and sel:sub(1, 4) == "lsm:" then
    profile.globalFont = sel
    return sel
  end
  if type(profile.globalFont) == "string" and profile.globalFont:sub(1, 4) == "lsm:" then
    profile.cdFont = profile.globalFont
    return profile.globalFont
  end
  local fromPath = ResolveLSMFontValueFromPath(profile.globalFont)
  if fromPath then
    profile.globalFont = fromPath
    profile.cdFont = fromPath
    return fromPath
  end
  profile.globalFont = "lsm:Friz Quadrata TT"
  profile.cdFont = "lsm:Friz Quadrata TT"
  return profile.globalFont
end
local function RoundToHalf(v)
  return math.floor((tonumber(v) or 0) * 2 + 0.5) / 2
end
local function FormatHalf(v)
  local n = tonumber(v) or 0
  if n == math.floor(n) then
    return tostring(math.floor(n))
  end
  return string.format("%.1f", n)
end
local SetButtonHighlighted = addonTable.SetButtonHighlighted
local ShowColorPicker = addonTable.ShowColorPicker
local function RadialThicknessToPreset(thickness)
  local t = tonumber(thickness)
  if not t then return "middle" end
  if t <= 2 then return "thin" end
  if t >= 4 then return "thick" end
  return "middle"
end
local function PresetToRadialThickness(preset)
  if preset == "thin" then return 2 end
  if preset == "thick" then return 5 end
  return 3
end
local function ABFlagsToMode(inCombat, mouseover, always)
  if always then
    return mouseover and "always_mouseover" or "always"
  end
  if inCombat then
    return mouseover and "combat_mouseover" or "combat"
  end
  return "off"
end
local function ApplyABModeToProfile(profile, inCombatKey, mouseoverKey, alwaysKey, mode)
  if not profile then return end
  local m = mode or "off"
  profile[inCombatKey] = (m == "combat" or m == "combat_mouseover")
  profile[alwaysKey] = (m == "always" or m == "always_mouseover")
  profile[mouseoverKey] = (m == "combat_mouseover" or m == "always_mouseover")
end
local function ForEachABModeDropdown(fn)
  if type(fn) ~= "function" then return end
  if addonTable.actionBar1ModeDD then fn(addonTable.actionBar1ModeDD) end
  for n = 2, 8 do
    local dd = addonTable["actionBar" .. n .. "ModeDD"]
    if dd then fn(dd) end
  end
  if addonTable.stanceBarModeDD then fn(addonTable.stanceBarModeDD) end
  if addonTable.petBarModeDD then fn(addonTable.petBarModeDD) end
end
local function SetABModeDropdownsEnabled(enabled)
  ForEachABModeDropdown(function(dd) dd:SetEnabled(enabled) end)
end
local function ApplyABModeToAllBars(profile, mode)
  if not profile then return end
  ApplyABModeToProfile(profile, "hideActionBar1InCombat", "hideActionBar1Mouseover", "hideActionBar1Always", mode)
  for n = 2, 8 do
    ApplyABModeToProfile(profile, "hideAB"..n.."InCombat", "hideAB"..n.."Mouseover", "hideAB"..n.."Always", mode)
  end
  ApplyABModeToProfile(profile, "hideStanceBarInCombat", "hideStanceBarMouseover", "hideStanceBarAlways", mode)
  ApplyABModeToProfile(profile, "hidePetBarInCombat", "hidePetBarMouseover", "hidePetBarAlways", mode)
end
local function ShowReloadPrompt(text, okText, cancelText)
  if addonTable.ShowReloadPrompt then
    addonTable.ShowReloadPrompt(text, okText, cancelText)
    return
  end
  local msg = text or "A UI reload is recommended."
  if addonTable.Print then
    addonTable:Print(msg)
  elseif print then
    print("|cffffd200CCM:|r " .. msg)
  end
end
local function ShowModuleActivatedMessage(moduleName)
  if type(moduleName) ~= "string" or moduleName == "" then return end
  local msg = moduleName .. " module activated."
  if addonTable.Print then
    addonTable:Print(msg)
  elseif print then
    print("|cffffd200CCM:|r " .. msg)
  end
end
local function ResetAllPreviewHighlights()
  if addonTable.noTargetAlertPreviewOnBtn then
    SetButtonHighlighted(addonTable.noTargetAlertPreviewOnBtn, false)
  end
  if addonTable.castbar and addonTable.castbar.previewOnBtn then
    SetButtonHighlighted(addonTable.castbar.previewOnBtn, false)
  end
  if addonTable.debuffs and addonTable.debuffs.previewOnBtn then
    SetButtonHighlighted(addonTable.debuffs.previewOnBtn, false)
  end
  if addonTable.combatStatusPreviewOnBtn then
    SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, false)
  end
  if addonTable.skyridingPreviewOnBtn then
    SetButtonHighlighted(addonTable.skyridingPreviewOnBtn, false)
  end
  if addonTable.ufBossFramePreviewOnBtn then
    SetButtonHighlighted(addonTable.ufBossFramePreviewOnBtn, false)
  end
  if addonTable.lowHealthWarningPreviewOnBtn then
    SetButtonHighlighted(addonTable.lowHealthWarningPreviewOnBtn, false)
  end
end
addonTable.ResetAllPreviewHighlights = ResetAllPreviewHighlights
local CreateSpellRow = addonTable.CreateSpellRow
local function IsEntryChargeSpell(entryID)
  if type(entryID) ~= "number" or entryID < 0 then return false end
  local actualID = math.abs(entryID)
  local resolvedID = actualID
  if addonTable.ResolveTrackedSpellID then
    local rid = addonTable.ResolveTrackedSpellID(actualID)
    if type(rid) == "number" and rid > 0 then
      resolvedID = rid
    end
  end

  local function ReadLiveChargeFlag(spellID)
    if type(spellID) ~= "number" or spellID <= 0 then return nil end
    if not (C_Spell and C_Spell.GetSpellCharges) then return nil end
    local okCharges, chargesInfo = pcall(C_Spell.GetSpellCharges, spellID)
    if not okCharges then return nil end
    if type(chargesInfo) ~= "table" then return false end
    if chargesInfo.maxCharges == nil then return false end
    if issecretvalue and issecretvalue(chargesInfo.maxCharges) then return nil end
    local maxCharges = tonumber(chargesInfo.maxCharges)
    if type(maxCharges) == "number" then
      return maxCharges > 1
    end
    return nil
  end

  local actualFlag = ReadLiveChargeFlag(actualID)
  local resolvedFlag = (resolvedID ~= actualID) and ReadLiveChargeFlag(resolvedID) or nil

  if actualFlag == true or resolvedFlag == true then
    return true
  end
  if actualFlag == false or resolvedFlag == false then
    return false
  end

  local cache = addonTable.ChargeSpellCache
  if type(cache) == "table" then
    if cache[actualID] == true then return true end
    if resolvedID ~= actualID and cache[resolvedID] == true then return true end
  end
  return false
end
local function HasRealCooldownForHideReveal(entryID, isChargeSpell)
  if type(entryID) ~= "number" then return false end
  local isItem = entryID < 0
  local actualID = math.abs(entryID)
  if isItem then
    if C_Item and C_Item.GetItemCooldown then
      local _, duration = C_Item.GetItemCooldown(actualID)
      if type(duration) == "number" and duration > 1.5 then return true end
    end
    return false
  end
  local resolvedID = actualID
  if addonTable.ResolveTrackedSpellID then
    local rid = addonTable.ResolveTrackedSpellID(actualID)
    if type(rid) == "number" and rid > 0 then
      resolvedID = rid
    end
  end
  local checked = {}
  local idsToCheck = { actualID }
  if resolvedID ~= actualID then
    idsToCheck[#idsToCheck + 1] = resolvedID
  end

  local function HasDesignCooldown(spellID)
    if type(spellID) ~= "number" or spellID <= 0 or checked[spellID] then return false end
    checked[spellID] = true

    if GetSpellBaseCooldown then
      local okBase, baseCDMS = pcall(GetSpellBaseCooldown, spellID)
      if okBase and type(baseCDMS) == "number" and baseCDMS > 1500 then
        return true
      end
    end
    if C_Spell and C_Spell.GetSpellCharges then
      local okCharges, chargesInfo = pcall(C_Spell.GetSpellCharges, spellID)
      if okCharges and type(chargesInfo) == "table" then
        local maxCharges = tonumber(chargesInfo.maxCharges) or 0
        if maxCharges > 1 then
          return true
        end
      end
    end
    if C_Spell and C_Spell.GetSpellCooldown then
      local okCD, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID)
      if okCD and type(cdInfo) == "table" then
        local dur = nil
        if not (issecretvalue and issecretvalue(cdInfo.duration)) then
          dur = tonumber(cdInfo.duration)
        end
        if type(dur) == "number" and dur > 1.5 then
          return true
        end
      end
    end
    local state = addonTable and addonTable.State
    if state and state.spellBaseCdDurations then
      local baseDur = state.spellBaseCdDurations[spellID]
      if type(baseDur) == "number" and baseDur > 1.5 then
        return true
      end
    end
    return false
  end

  for i = 1, #idsToCheck do
    if HasDesignCooldown(idsToCheck[i]) then return true end
  end
  return false
end
local function IsHideRevealBlockedForEntry(entryID, isChargeSpell)
  if type(entryID) ~= "number" or entryID < 0 then return false end
  if isChargeSpell then return true end
  local actualID = math.abs(entryID)
  local resolvedID = actualID
  if addonTable.ResolveTrackedSpellID then
    local rid = addonTable.ResolveTrackedSpellID(actualID)
    if type(rid) == "number" and rid > 0 then
      resolvedID = rid
    end
  end
  local isOverride = false
  if addonTable.IsOverrideRecastSpell then
    isOverride = addonTable.IsOverrideRecastSpell(resolvedID, actualID) == true
  end
  if isOverride and addonTable.HasActivePlayerAuraForSpell then
    if addonTable.HasActivePlayerAuraForSpell(resolvedID, actualID) == true then
      return true
    end
  end
  if addonTable.IsBuffTrackingBlockedSpell then
    if addonTable.IsBuffTrackingBlockedSpell(resolvedID, actualID) == true then
      return true
    end
  end
  return false
end
local function UpdateSpellListHeight(spellChild, count)
  local rowHeight = 34
  local padding = 16
  local contentHeight = count * rowHeight + padding
  spellChild:SetHeight(math.max(1, contentHeight - 8))
end
local function RefreshCursorSpellList()
  local cur = addonTable.cursor
  if not cur or not cur.spellChild then return end
  for _, child in ipairs({cur.spellChild:GetChildren()}) do
    child:Hide()
    child:SetParent(nil)
  end
  if not addonTable.GetSpellList then return end
  local spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds = addonTable.GetSpellList()
  if not spellList then return end
  local profile = GetProfile()
  local useGlobalGlows = profile and profile.useSpellGlows == true
  local useCustomHideReveal = profile and profile.useCustomHideReveal == true
  local trackBuffsOff = profile and profile.trackBuffs == false
  local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or nil
  local function onToggle(idx, checked)
    spellEnabled[idx] = checked
    addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
    CreateIcons()
  end
  local function onDelete(idx)
    table.remove(spellList, idx)
    table.remove(spellEnabled, idx)
    table.remove(spellGlowEnabled, idx)
    table.remove(spellGlowType, idx)
    table.remove(spellHideRevealThresholds, idx)
    addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
    RefreshCursorSpellList()
    CreateIcons()
  end
  local function onMoveUp(idx)
    if idx > 1 then
      spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]
      spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]
      spellGlowEnabled[idx], spellGlowEnabled[idx-1] = spellGlowEnabled[idx-1], spellGlowEnabled[idx]
      spellGlowType[idx], spellGlowType[idx-1] = spellGlowType[idx-1], spellGlowType[idx]
      spellHideRevealThresholds[idx], spellHideRevealThresholds[idx-1] = spellHideRevealThresholds[idx-1], spellHideRevealThresholds[idx]
      addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
      RefreshCursorSpellList()
      CreateIcons()
    end
  end
  local function onMoveDown(idx)
    if idx < #spellList then
      spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]
      spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]
      spellGlowEnabled[idx], spellGlowEnabled[idx+1] = spellGlowEnabled[idx+1], spellGlowEnabled[idx]
      spellGlowType[idx], spellGlowType[idx+1] = spellGlowType[idx+1], spellGlowType[idx]
      spellHideRevealThresholds[idx], spellHideRevealThresholds[idx+1] = spellHideRevealThresholds[idx+1], spellHideRevealThresholds[idx]
      addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
      RefreshCursorSpellList()
      CreateIcons()
    end
  end
  local function onReorder(sourceIdx, targetIdx)
    local entry = table.remove(spellList, sourceIdx)
    local en = table.remove(spellEnabled, sourceIdx)
    local glowEnabled = table.remove(spellGlowEnabled, sourceIdx)
    local glowType = table.remove(spellGlowType, sourceIdx)
    local hr = table.remove(spellHideRevealThresholds, sourceIdx)
    table.insert(spellList, targetIdx, entry)
    table.insert(spellEnabled, targetIdx, en)
    table.insert(spellGlowEnabled, targetIdx, glowEnabled)
    table.insert(spellGlowType, targetIdx, glowType)
    table.insert(spellHideRevealThresholds, targetIdx, hr)
    addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
    RefreshCursorSpellList()
    CreateIcons()
  end
  local function onGlowTypeSelect(idx, value)
    spellGlowType[idx] = value or "off"
    spellGlowEnabled[idx] = (value ~= "off")
    addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
    CreateIcons()
  end
  local function onHideRevealChange(idx, value)
    spellHideRevealThresholds[idx] = value
    addonTable.SetSpellList(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds)
  end
  for i, eID in ipairs(spellList) do
    local effectiveType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or "pixel") or "off"
    local isCharge = IsEntryChargeSpell(eID)
    local hasRealCooldown = HasRealCooldownForHideReveal(eID, isCharge)
    local hideRevealBlocked = IsHideRevealBlockedForEntry(eID, isCharge)
    local pureBuffOff = trackBuffsOff and pureBuffs and eID > 0 and pureBuffs[eID] == true
    local pureBuffEntry = pureBuffs and eID > 0 and pureBuffs[eID] == true
    CreateSpellRow(cur.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder, useGlobalGlows, effectiveType, onGlowTypeSelect, isCharge, hideRevealBlocked, hasRealCooldown, useCustomHideReveal, spellHideRevealThresholds[i], onHideRevealChange, pureBuffOff, pureBuffEntry)
  end
  UpdateSpellListHeight(cur.spellChild, #spellList)
end
local function RefreshCB1SpellList()
  local cb = addonTable.cb1
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBarSpells then return end
  local spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT = addonTable.GetCustomBarSpells()
  if not spellList then return end
  local profile = GetProfile()
  local useGlobalGlows = profile and profile.customBarUseSpellGlows == true
  local useCustomHR = profile and profile.customBarUseCustomHideReveal == true
  local trackBuffsOff = profile and profile.customBarTrackBuffs == false
  local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or nil
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); table.remove(spellGlowEnabled, idx); table.remove(spellGlowType, idx); table.remove(spellHRT, idx); addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx-1] = spellGlowEnabled[idx-1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx-1] = spellGlowType[idx-1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx-1] = spellHRT[idx-1], spellHRT[idx]; addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx+1] = spellGlowEnabled[idx+1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx+1] = spellGlowType[idx+1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx+1] = spellHRT[idx+1], spellHRT[idx]; addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); local glowEnabled = table.remove(spellGlowEnabled, sourceIdx); local glowType = table.remove(spellGlowType, sourceIdx); local hr = table.remove(spellHRT, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); table.insert(spellGlowEnabled, targetIdx, glowEnabled); table.insert(spellGlowType, targetIdx, glowType); table.insert(spellHRT, targetIdx, hr); addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  local function onGlowTypeSelect(idx, value) spellGlowType[idx] = value or "off"; spellGlowEnabled[idx] = (value ~= "off"); addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  local function onHideRevealChange(idx, value) spellHRT[idx] = value; addonTable.SetCustomBarSpells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT) end
  for i, eID in ipairs(spellList) do local effectiveType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or "pixel") or "off"; local isCharge = IsEntryChargeSpell(eID); local hasRealCooldown = HasRealCooldownForHideReveal(eID, isCharge); local hideRevealBlocked = IsHideRevealBlockedForEntry(eID, isCharge); local pureBuffOff = trackBuffsOff and pureBuffs and eID > 0 and pureBuffs[eID] == true; local pureBuffEntry = pureBuffs and eID > 0 and pureBuffs[eID] == true; CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder, useGlobalGlows, effectiveType, onGlowTypeSelect, isCharge, hideRevealBlocked, hasRealCooldown, useCustomHR, spellHRT[i], onHideRevealChange, pureBuffOff, pureBuffEntry) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function RefreshCB2SpellList()
  local cb = addonTable.cb2
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBar2Spells then return end
  local spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT = addonTable.GetCustomBar2Spells()
  if not spellList then return end
  local profile = GetProfile()
  local useGlobalGlows = profile and profile.customBar2UseSpellGlows == true
  local useCustomHR = profile and profile.customBar2UseCustomHideReveal == true
  local trackBuffsOff = profile and profile.customBar2TrackBuffs == false
  local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or nil
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); table.remove(spellGlowEnabled, idx); table.remove(spellGlowType, idx); table.remove(spellHRT, idx); addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx-1] = spellGlowEnabled[idx-1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx-1] = spellGlowType[idx-1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx-1] = spellHRT[idx-1], spellHRT[idx]; addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx+1] = spellGlowEnabled[idx+1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx+1] = spellGlowType[idx+1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx+1] = spellHRT[idx+1], spellHRT[idx]; addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); local glowEnabled = table.remove(spellGlowEnabled, sourceIdx); local glowType = table.remove(spellGlowType, sourceIdx); local hr = table.remove(spellHRT, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); table.insert(spellGlowEnabled, targetIdx, glowEnabled); table.insert(spellGlowType, targetIdx, glowType); table.insert(spellHRT, targetIdx, hr); addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  local function onGlowTypeSelect(idx, value) spellGlowType[idx] = value or "off"; spellGlowEnabled[idx] = (value ~= "off"); addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  local function onHideRevealChange(idx, value) spellHRT[idx] = value; addonTable.SetCustomBar2Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT) end
  for i, eID in ipairs(spellList) do local effectiveType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or "pixel") or "off"; local isCharge = IsEntryChargeSpell(eID); local hasRealCooldown = HasRealCooldownForHideReveal(eID, isCharge); local hideRevealBlocked = IsHideRevealBlockedForEntry(eID, isCharge); local pureBuffOff = trackBuffsOff and pureBuffs and eID > 0 and pureBuffs[eID] == true; local pureBuffEntry = pureBuffs and eID > 0 and pureBuffs[eID] == true; CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder, useGlobalGlows, effectiveType, onGlowTypeSelect, isCharge, hideRevealBlocked, hasRealCooldown, useCustomHR, spellHRT[i], onHideRevealChange, pureBuffOff, pureBuffEntry) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function RefreshCB3SpellList()
  local cb = addonTable.cb3
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBar3Spells then return end
  local spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT = addonTable.GetCustomBar3Spells()
  if not spellList then return end
  local profile = GetProfile()
  local useGlobalGlows = profile and profile.customBar3UseSpellGlows == true
  local useCustomHR = profile and profile.customBar3UseCustomHideReveal == true
  local trackBuffsOff = profile and profile.customBar3TrackBuffs == false
  local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or nil
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); table.remove(spellGlowEnabled, idx); table.remove(spellGlowType, idx); table.remove(spellHRT, idx); addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx-1] = spellGlowEnabled[idx-1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx-1] = spellGlowType[idx-1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx-1] = spellHRT[idx-1], spellHRT[idx]; addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx+1] = spellGlowEnabled[idx+1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx+1] = spellGlowType[idx+1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx+1] = spellHRT[idx+1], spellHRT[idx]; addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); local glowEnabled = table.remove(spellGlowEnabled, sourceIdx); local glowType = table.remove(spellGlowType, sourceIdx); local hr = table.remove(spellHRT, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); table.insert(spellGlowEnabled, targetIdx, glowEnabled); table.insert(spellGlowType, targetIdx, glowType); table.insert(spellHRT, targetIdx, hr); addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  local function onGlowTypeSelect(idx, value) spellGlowType[idx] = value or "off"; spellGlowEnabled[idx] = (value ~= "off"); addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  local function onHideRevealChange(idx, value) spellHRT[idx] = value; addonTable.SetCustomBar3Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT) end
  for i, eID in ipairs(spellList) do local effectiveType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or "pixel") or "off"; local isCharge = IsEntryChargeSpell(eID); local hasRealCooldown = HasRealCooldownForHideReveal(eID, isCharge); local hideRevealBlocked = IsHideRevealBlockedForEntry(eID, isCharge); local pureBuffOff = trackBuffsOff and pureBuffs and eID > 0 and pureBuffs[eID] == true; local pureBuffEntry = pureBuffs and eID > 0 and pureBuffs[eID] == true; CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder, useGlobalGlows, effectiveType, onGlowTypeSelect, isCharge, hideRevealBlocked, hasRealCooldown, useCustomHR, spellHRT[i], onHideRevealChange, pureBuffOff, pureBuffEntry) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function SetupDragDrop(tabFrame, getSpellsFunc, setSpellsFunc, refreshFunc, createIconsFunc, updateFunc, extraFrames)
  local handler = function()
    local infoType, info1, info2, info3 = GetCursorInfo()
    if infoType == "spell" then
      local spellID = info3 or info1
      if not info3 and info1 and info2 then
        local spellInfo = C_SpellBook.GetSpellBookItemInfo(info1, Enum.SpellBookSpellBank.Player)
        if spellInfo and spellInfo.spellID then spellID = spellInfo.spellID end
      end
      if spellID and getSpellsFunc and setSpellsFunc then
        local spells, enabled = getSpellsFunc()
        table.insert(spells, spellID)
        table.insert(enabled, true)
        setSpellsFunc(spells, enabled)
        refreshFunc()
        if createIconsFunc then createIconsFunc() end
        if updateFunc then updateFunc() end
      end
      ClearCursor()
    elseif infoType == "item" then
      local itemID = info1
      if itemID and getSpellsFunc and setSpellsFunc then
        local spells, enabled = getSpellsFunc()
        table.insert(spells, -itemID)
        table.insert(enabled, true)
        setSpellsFunc(spells, enabled)
        refreshFunc()
        if createIconsFunc then createIconsFunc() end
        if updateFunc then updateFunc() end
      end
      ClearCursor()
    end
  end
  tabFrame:SetScript("OnReceiveDrag", handler)
  tabFrame:SetScript("OnMouseUp", handler)
  if extraFrames then
    for _, f in ipairs(extraFrames) do
      if f then
        f:SetScript("OnReceiveDrag", handler)
        f:SetScript("OnMouseUp", handler)
      end
    end
  end
end
local function RefreshCB4SpellList()
  local cb = addonTable.cb4
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBar4Spells then return end
  local spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT = addonTable.GetCustomBar4Spells()
  if not spellList then return end
  local profile = GetProfile()
  local useGlobalGlows = profile and profile.customBar4UseSpellGlows == true
  local useCustomHR = profile and profile.customBar4UseCustomHideReveal == true
  local trackBuffsOff = profile and profile.customBar4TrackBuffs == false
  local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or nil
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); table.remove(spellGlowEnabled, idx); table.remove(spellGlowType, idx); table.remove(spellHRT, idx); addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx-1] = spellGlowEnabled[idx-1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx-1] = spellGlowType[idx-1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx-1] = spellHRT[idx-1], spellHRT[idx]; addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx+1] = spellGlowEnabled[idx+1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx+1] = spellGlowType[idx+1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx+1] = spellHRT[idx+1], spellHRT[idx]; addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); local glowEnabled = table.remove(spellGlowEnabled, sourceIdx); local glowType = table.remove(spellGlowType, sourceIdx); local hr = table.remove(spellHRT, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); table.insert(spellGlowEnabled, targetIdx, glowEnabled); table.insert(spellGlowType, targetIdx, glowType); table.insert(spellHRT, targetIdx, hr); addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end
  local function onGlowTypeSelect(idx, value) spellGlowType[idx] = value or "off"; spellGlowEnabled[idx] = (value ~= "off"); addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end
  local function onHideRevealChange(idx, value) spellHRT[idx] = value; addonTable.SetCustomBar4Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT) end
  for i, eID in ipairs(spellList) do local effectiveType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or "pixel") or "off"; local isCharge = IsEntryChargeSpell(eID); local hasRealCooldown = HasRealCooldownForHideReveal(eID, isCharge); local hideRevealBlocked = IsHideRevealBlockedForEntry(eID, isCharge); local pureBuffOff = trackBuffsOff and pureBuffs and eID > 0 and pureBuffs[eID] == true; local pureBuffEntry = pureBuffs and eID > 0 and pureBuffs[eID] == true; CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder, useGlobalGlows, effectiveType, onGlowTypeSelect, isCharge, hideRevealBlocked, hasRealCooldown, useCustomHR, spellHRT[i], onHideRevealChange, pureBuffOff, pureBuffEntry) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function RefreshCB5SpellList()
  local cb = addonTable.cb5
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBar5Spells then return end
  local spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT = addonTable.GetCustomBar5Spells()
  if not spellList then return end
  local profile = GetProfile()
  local useGlobalGlows = profile and profile.customBar5UseSpellGlows == true
  local useCustomHR = profile and profile.customBar5UseCustomHideReveal == true
  local trackBuffsOff = profile and profile.customBar5TrackBuffs == false
  local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or nil
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); table.remove(spellGlowEnabled, idx); table.remove(spellGlowType, idx); table.remove(spellHRT, idx); addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx-1] = spellGlowEnabled[idx-1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx-1] = spellGlowType[idx-1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx-1] = spellHRT[idx-1], spellHRT[idx]; addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; spellGlowEnabled[idx], spellGlowEnabled[idx+1] = spellGlowEnabled[idx+1], spellGlowEnabled[idx]; spellGlowType[idx], spellGlowType[idx+1] = spellGlowType[idx+1], spellGlowType[idx]; spellHRT[idx], spellHRT[idx+1] = spellHRT[idx+1], spellHRT[idx]; addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); local glowEnabled = table.remove(spellGlowEnabled, sourceIdx); local glowType = table.remove(spellGlowType, sourceIdx); local hr = table.remove(spellHRT, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); table.insert(spellGlowEnabled, targetIdx, glowEnabled); table.insert(spellGlowType, targetIdx, glowType); table.insert(spellHRT, targetIdx, hr); addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end
  local function onGlowTypeSelect(idx, value) spellGlowType[idx] = value or "off"; spellGlowEnabled[idx] = (value ~= "off"); addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end
  local function onHideRevealChange(idx, value) spellHRT[idx] = value; addonTable.SetCustomBar5Spells(spellList, spellEnabled, spellGlowEnabled, spellGlowType, spellHRT) end
  for i, eID in ipairs(spellList) do local effectiveType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or "pixel") or "off"; local isCharge = IsEntryChargeSpell(eID); local hasRealCooldown = HasRealCooldownForHideReveal(eID, isCharge); local hideRevealBlocked = IsHideRevealBlockedForEntry(eID, isCharge); local pureBuffOff = trackBuffsOff and pureBuffs and eID > 0 and pureBuffs[eID] == true; local pureBuffEntry = pureBuffs and eID > 0 and pureBuffs[eID] == true; CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder, useGlobalGlows, effectiveType, onGlowTypeSelect, isCharge, hideRevealBlocked, hasRealCooldown, useCustomHR, spellHRT[i], onHideRevealChange, pureBuffOff, pureBuffEntry) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
addonTable.RefreshCursorSpellList = RefreshCursorSpellList
addonTable.RefreshCB1SpellList = RefreshCB1SpellList
addonTable.RefreshCB2SpellList = RefreshCB2SpellList
addonTable.RefreshCB3SpellList = RefreshCB3SpellList
addonTable.RefreshCB4SpellList = RefreshCB4SpellList
addonTable.RefreshCB5SpellList = RefreshCB5SpellList
local function UpdateAllControls()
  local profile = GetProfile()
  if not profile then return end
  if addonTable.ApplyModuleStateToProfile then
    addonTable.ApplyModuleStateToProfile(profile)
  end
  local function num(val, default) return type(val) == "number" and val or default end
  local currentScale = profile.uiScale or tonumber(GetCVar("uiScale")) or UIParent:GetScale() or 0.71
  local currentMode = profile.uiScaleMode or "disabled"
  if addonTable.uiScaleDD then
    addonTable.uiScaleDD:SetValue(currentMode)
  end
  if addonTable.uiScaleSlider then
    addonTable.uiScaleSlider._updating = true
    addonTable.uiScaleSlider:SetValue(currentScale)
    addonTable.uiScaleSlider._updating = false
    addonTable.uiScaleSlider.valueText:SetText(string.format("%.2f", currentScale))
    if currentMode == "custom" then
      addonTable.uiScaleSlider:Enable()
      addonTable.uiScaleSlider:SetAlpha(1)
    else
      addonTable.uiScaleSlider:Disable()
      addonTable.uiScaleSlider:SetAlpha(0.5)
    end
  end
  if addonTable.customBarsCountSlider then
    local count = math.floor(num(profile.customBarsCount, 0))
    if count < 0 then count = 0 end
    if count > 5 then count = 5 end
    addonTable.customBarsCountSlider._updating = true
    addonTable.customBarsCountSlider:SetValue(count)
    addonTable.customBarsCountSlider._updating = false
    addonTable.customBarsCountSlider.valueText:SetText(count)
  end
  if addonTable.iconBorderSlider then addonTable.iconBorderSlider:SetValue(num(profile.iconBorderSize, 1)); addonTable.iconBorderSlider.valueText:SetText(math.floor(num(profile.iconBorderSize, 1))) end
  if addonTable.strataDD then addonTable.strataDD:SetValue(profile.iconStrata or "FULLSCREEN") end
  if addonTable.fontDD then addonTable.fontDD:SetValue(NormalizeGlobalFontSelection(profile)) end
  if addonTable.outlineDD then addonTable.outlineDD:SetValue(profile.globalOutline or "OUTLINE") end
  if addonTable.audioChannelDD then addonTable.audioChannelDD:SetValue(profile.audioChannel or "Master") end
  if addonTable.actionBar1ModeDD then
    addonTable.actionBar1ModeDD:SetValue(ABFlagsToMode(profile.hideActionBar1InCombat == true, profile.hideActionBar1Mouseover == true, profile.hideActionBar1Always == true))
  end
  for n = 2, 8 do
    local dd = addonTable["actionBar"..n.."ModeDD"]
    if dd then
      dd:SetValue(ABFlagsToMode(profile["hideAB"..n.."InCombat"] == true, profile["hideAB"..n.."Mouseover"] == true, profile["hideAB"..n.."Always"] == true))
    end
  end
  if addonTable.stanceBarModeDD then
    addonTable.stanceBarModeDD:SetValue(ABFlagsToMode(profile.hideStanceBarInCombat == true, profile.hideStanceBarMouseover == true, profile.hideStanceBarAlways == true))
  end
  if addonTable.petBarModeDD then
    addonTable.petBarModeDD:SetValue(ABFlagsToMode(profile.hidePetBarInCombat == true, profile.hidePetBarMouseover == true, profile.hidePetBarAlways == true))
  end
  local globalABMode = profile.actionBarGlobalMode or "custom"
  if addonTable.actionBarGlobalModeDD then
    addonTable.actionBarGlobalModeDD:SetValue(globalABMode)
  end
  SetABModeDropdownsEnabled(globalABMode ~= "off")
  if addonTable.hideAB1CB then addonTable.hideAB1CB:SetChecked(profile.hideActionBar1InCombat == true) end
  if addonTable.hideAB1MouseoverCB then addonTable.hideAB1MouseoverCB:SetChecked(profile.hideActionBar1Mouseover == true) end
  if addonTable.hideAB1AlwaysCB then addonTable.hideAB1AlwaysCB:SetChecked(profile.hideActionBar1Always == true) end
  for n = 2, 8 do
    if addonTable["hideAB"..n.."CB"] then addonTable["hideAB"..n.."CB"]:SetChecked(profile["hideAB"..n.."InCombat"] == true) end
    if addonTable["hideAB"..n.."MouseoverCB"] then addonTable["hideAB"..n.."MouseoverCB"]:SetChecked(profile["hideAB"..n.."Mouseover"] == true) end
    if addonTable["hideAB"..n.."AlwaysCB"] then addonTable["hideAB"..n.."AlwaysCB"]:SetChecked(profile["hideAB"..n.."Always"] == true) end
  end
  if addonTable.hideStanceBarCB then addonTable.hideStanceBarCB:SetChecked(profile.hideStanceBarInCombat == true) end
  if addonTable.hideStanceBarMouseoverCB then addonTable.hideStanceBarMouseoverCB:SetChecked(profile.hideStanceBarMouseover == true) end
  if addonTable.hideStanceBarAlwaysCB then addonTable.hideStanceBarAlwaysCB:SetChecked(profile.hideStanceBarAlways == true) end
  if addonTable.hidePetBarCB then addonTable.hidePetBarCB:SetChecked(profile.hidePetBarInCombat == true) end
  if addonTable.hidePetBarMouseoverCB then addonTable.hidePetBarMouseoverCB:SetChecked(profile.hidePetBarMouseover == true) end
  if addonTable.hidePetBarAlwaysCB then addonTable.hidePetBarAlwaysCB:SetChecked(profile.hidePetBarAlways == true) end
  if addonTable.fadeMicroMenuCB then addonTable.fadeMicroMenuCB:SetChecked(profile.fadeMicroMenu == true) end
  if addonTable.hideABBordersCB then addonTable.hideABBordersCB:SetChecked(profile.hideActionBarBorders == true) end
  local abSkinOn = profile.hideActionBarBorders == true
  if addonTable.hideABGlowsCB then addonTable.hideABGlowsCB:SetChecked(profile.hideActionBarGlows ~= false); addonTable.hideABGlowsCB:SetEnabled(abSkinOn); addonTable.hideABGlowsCB:SetAlpha(abSkinOn and 1 or 0.4) end
  if addonTable.abSkinSpacingSlider then addonTable.abSkinSpacingSlider:SetValue(profile.abSkinSpacing or 2); addonTable.abSkinSpacingSlider:SetEnabled(abSkinOn); addonTable.abSkinSpacingSlider:SetAlpha(abSkinOn and 1 or 0.4) end
  if addonTable.fadeObjectiveTrackerCB then addonTable.fadeObjectiveTrackerCB:SetChecked(profile.fadeObjectiveTracker == true) end
  if addonTable.fadeBagBarCB then addonTable.fadeBagBarCB:SetChecked(profile.fadeBagBar == true) end
  if addonTable.betterItemLevelCB then addonTable.betterItemLevelCB:SetChecked(profile.betterItemLevel == true) end
  if addonTable.showEquipDetailsCB then addonTable.showEquipDetailsCB:SetChecked(profile.showEquipmentDetails == true) end
  if addonTable.chatClassColorCB then addonTable.chatClassColorCB:SetChecked(profile.chatClassColorNames == true) end
  if addonTable.chatTimestampsCB then addonTable.chatTimestampsCB:SetChecked(profile.chatTimestamps == true) end
  if addonTable.chatTimestampFormatDD then addonTable.chatTimestampFormatDD:SetValue(profile.chatTimestampFormat or "HH:MM") end
  local chatTsEnabled = profile.chatTimestamps == true
  if addonTable.chatTimestampFormatDD then addonTable.chatTimestampFormatDD:SetEnabled(chatTsEnabled) end
  if addonTable.chatTimestampFormatLbl then addonTable.chatTimestampFormatLbl:SetTextColor(chatTsEnabled and 0.9 or 0.4, chatTsEnabled and 0.9 or 0.4, chatTsEnabled and 0.9 or 0.4) end
  if addonTable.chatCopyButtonCB then addonTable.chatCopyButtonCB:SetChecked(profile.chatCopyButton == true) end
  local chatCopyEnabled = profile.chatCopyButton == true
  if addonTable.chatCopyButtonCornerDD then addonTable.chatCopyButtonCornerDD:SetValue(profile.chatCopyButtonCorner or "TOPRIGHT"); addonTable.chatCopyButtonCornerDD:SetEnabled(chatCopyEnabled) end
  if addonTable.chatCopyButtonCornerLbl then addonTable.chatCopyButtonCornerLbl:SetTextColor(chatCopyEnabled and 0.9 or 0.4, chatCopyEnabled and 0.9 or 0.4, chatCopyEnabled and 0.9 or 0.4) end
  if addonTable.chatUrlDetectionCB then addonTable.chatUrlDetectionCB:SetChecked(profile.chatUrlDetection == true) end
  if addonTable.chatBackgroundCB then addonTable.chatBackgroundCB:SetChecked(profile.chatBackground == true) end
  local chatBgEnabled = profile.chatBackground == true
  if addonTable.chatBgAlphaSlider then addonTable.chatBgAlphaSlider:SetValue(num(profile.chatBackgroundAlpha, 40)); addonTable.chatBgAlphaSlider.valueText:SetText(math.floor(num(profile.chatBackgroundAlpha, 40))); addonTable.chatBgAlphaSlider:SetEnabled(chatBgEnabled) end
  if addonTable.chatBgColorBtn then addonTable.chatBgColorBtn:SetEnabled(chatBgEnabled); addonTable.chatBgColorBtn:SetAlpha(chatBgEnabled and 1 or 0.4) end
  if addonTable.chatBgColorSwatch then addonTable.chatBgColorSwatch:SetBackdropColor(num(profile.chatBackgroundColorR, 0), num(profile.chatBackgroundColorG, 0), num(profile.chatBackgroundColorB, 0), 1); addonTable.chatBgColorSwatch:SetAlpha(chatBgEnabled and 1 or 0.4) end
  if addonTable.chatHideButtonsCB then addonTable.chatHideButtonsCB:SetChecked(profile.chatHideButtons == true) end
  if addonTable.chatFadeToggleCB then addonTable.chatFadeToggleCB:SetChecked(profile.chatFadeToggle == true) end
  local chatFadeOn = profile.chatFadeToggle == true
  if addonTable.chatFadeDelaySlider then addonTable.chatFadeDelaySlider:SetValue(num(profile.chatFadeDelay, 20)); addonTable.chatFadeDelaySlider.valueText:SetText(math.floor(num(profile.chatFadeDelay, 20))); addonTable.chatFadeDelaySlider:SetEnabled(chatFadeOn) end
  if addonTable.chatEditBoxDD then addonTable.chatEditBoxDD:SetValue(profile.chatEditBoxPosition or "bottom") end
  if addonTable.chatEditBoxStyledCB then addonTable.chatEditBoxStyledCB:SetChecked(profile.chatEditBoxStyled == true) end
  if addonTable.chatTabFlashCB then addonTable.chatTabFlashCB:SetChecked(profile.chatTabFlash == true) end
  if addonTable.chatHideTabsDD then addonTable.chatHideTabsDD:SetValue(profile.chatHideTabs or "off") end
  if addonTable.skyridingEnabledCB then addonTable.skyridingEnabledCB:SetChecked(profile.skyridingEnabled == true) end
  local skyOn = profile.skyridingEnabled == true
  if addonTable.skyridingHideCDMCB then addonTable.skyridingHideCDMCB:SetChecked(profile.skyridingHideCDM == true); addonTable.skyridingHideCDMCB:SetEnabled(skyOn); addonTable.skyridingHideCDMCB:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingVigorBarCB then addonTable.skyridingVigorBarCB:SetChecked(profile.skyridingVigorBar ~= false); addonTable.skyridingVigorBarCB:SetEnabled(skyOn); addonTable.skyridingVigorBarCB:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingCooldownsCB then addonTable.skyridingCooldownsCB:SetChecked(profile.skyridingCooldowns ~= false); addonTable.skyridingCooldownsCB:SetEnabled(skyOn); addonTable.skyridingCooldownsCB:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingCenteredCB then addonTable.skyridingCenteredCB:SetChecked(profile.skyridingCentered == true); addonTable.skyridingCenteredCB:SetEnabled(skyOn); addonTable.skyridingCenteredCB:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingScaleSlider then addonTable.skyridingScaleSlider:SetValue(num(profile.skyridingScale, 100)); addonTable.skyridingScaleSlider.valueText:SetText(math.floor(num(profile.skyridingScale, 100))); addonTable.skyridingScaleSlider:SetEnabled(skyOn); addonTable.skyridingScaleSlider:SetAlpha(skyOn and 1 or 0.4) end
  local skyCen = skyOn and profile.skyridingCentered == true
  if addonTable.skyridingXSlider then addonTable.skyridingXSlider:SetValue(num(profile.skyridingX, 0)); addonTable.skyridingXSlider.valueText:SetText(math.floor(num(profile.skyridingX, 0))); addonTable.skyridingXSlider:SetEnabled(skyOn and not skyCen); addonTable.skyridingXSlider:SetAlpha((skyOn and not skyCen) and 1 or 0.4) end
  if addonTable.skyridingYSlider then addonTable.skyridingYSlider:SetValue(num(profile.skyridingY, -200)); addonTable.skyridingYSlider.valueText:SetText(math.floor(num(profile.skyridingY, -200))); addonTable.skyridingYSlider:SetEnabled(skyOn); addonTable.skyridingYSlider:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingScreenFxCB then local val = profile.skyridingScreenFx; if val == nil then local d = C_CVar and C_CVar.GetCVar("DisableAdvancedFlyingFullScreenEffects"); val = (d ~= "1") end; addonTable.skyridingScreenFxCB:SetChecked(val == true); addonTable.skyridingScreenFxCB:SetEnabled(skyOn); addonTable.skyridingScreenFxCB:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingSpeedFxCB then local val = profile.skyridingSpeedFx; if val == nil then local d = C_CVar and C_CVar.GetCVar("DisableAdvancedFlyingVelocityVFX"); val = (d ~= "1") end; addonTable.skyridingSpeedFxCB:SetChecked(val == true); addonTable.skyridingSpeedFxCB:SetEnabled(skyOn); addonTable.skyridingSpeedFxCB:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingVigorColorBtn then addonTable.skyridingVigorColorBtn:SetEnabled(skyOn); addonTable.skyridingVigorColorBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingVigorColorSwatch then addonTable.skyridingVigorColorSwatch:SetBackdropColor(num(profile.skyridingVigorColorR, 0.2), num(profile.skyridingVigorColorG, 0.8), num(profile.skyridingVigorColorB, 0.2), 1); addonTable.skyridingVigorColorSwatch:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingEmptyColorBtn then addonTable.skyridingEmptyColorBtn:SetEnabled(skyOn); addonTable.skyridingEmptyColorBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingEmptyColorSwatch then addonTable.skyridingEmptyColorSwatch:SetBackdropColor(num(profile.skyridingVigorEmptyColorR, 0.15), num(profile.skyridingVigorEmptyColorG, 0.15), num(profile.skyridingVigorEmptyColorB, 0.15), 1); addonTable.skyridingEmptyColorSwatch:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingRechargeColorBtn then addonTable.skyridingRechargeColorBtn:SetEnabled(skyOn); addonTable.skyridingRechargeColorBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingRechargeColorSwatch then addonTable.skyridingRechargeColorSwatch:SetBackdropColor(num(profile.skyridingVigorRechargeColorR, 0.85), num(profile.skyridingVigorRechargeColorG, 0.65), num(profile.skyridingVigorRechargeColorB, 0.1), 1); addonTable.skyridingRechargeColorSwatch:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingSurgeColorBtn then addonTable.skyridingSurgeColorBtn:SetEnabled(skyOn); addonTable.skyridingSurgeColorBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingSurgeColorSwatch then addonTable.skyridingSurgeColorSwatch:SetBackdropColor(num(profile.skyridingWhirlingSurgeColorR, 0.85), num(profile.skyridingWhirlingSurgeColorG, 0.65), num(profile.skyridingWhirlingSurgeColorB, 0.1), 1); addonTable.skyridingSurgeColorSwatch:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingWindColorBtn then addonTable.skyridingWindColorBtn:SetEnabled(skyOn); addonTable.skyridingWindColorBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingWindColorSwatch then addonTable.skyridingWindColorSwatch:SetBackdropColor(num(profile.skyridingSecondWindColorR, 0.2), num(profile.skyridingSecondWindColorG, 0.8), num(profile.skyridingSecondWindColorB, 0.2), 1); addonTable.skyridingWindColorSwatch:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingTextureDD then addonTable.skyridingTextureDD:SetValue(profile.skyridingTexture or "solid"); addonTable.skyridingTextureDD:SetEnabled(skyOn); addonTable.skyridingTextureDD:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingPreviewOnBtn then addonTable.skyridingPreviewOnBtn:SetEnabled(skyOn); addonTable.skyridingPreviewOnBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.skyridingPreviewOffBtn then addonTable.skyridingPreviewOffBtn:SetEnabled(skyOn); addonTable.skyridingPreviewOffBtn:SetAlpha(skyOn and 1 or 0.4) end
  if addonTable.customBarsModuleCB then addonTable.customBarsModuleCB:SetChecked(IsModuleEnabled("custombars")) end
  if addonTable.prbCB then addonTable.prbCB:SetChecked(IsModuleEnabled("prb")) end
  if addonTable.castbarCB then addonTable.castbarCB:SetChecked(IsModuleEnabled("castbars")) end
  if addonTable.focusCastbarCB then addonTable.focusCastbarCB:SetChecked(IsModuleEnabled("castbars") and profile.useFocusCastbar == true) end
  if addonTable.targetCastbarCB then addonTable.targetCastbarCB:SetChecked(IsModuleEnabled("castbars") and profile.useTargetCastbar == true) end
  if addonTable.playerDebuffsCB then addonTable.playerDebuffsCB:SetChecked(IsModuleEnabled("debuffs")) end
  if addonTable.qolModuleCB then addonTable.qolModuleCB:SetChecked(IsModuleEnabled("qol")) end
  if IsModuleEnabled("unitframes") and profile.enableUnitFrameCustomization == false then
    profile.enableUnitFrameCustomization = true
  end
  if addonTable.unitFrameCustomizationCB then addonTable.unitFrameCustomizationCB:SetChecked(IsModuleEnabled("unitframes")) end
  local ufOn = IsModuleEnabled("unitframes") and profile.enableUnitFrameCustomization == true
  if addonTable.radialCB then addonTable.radialCB:SetChecked(profile.showRadialCircle == true) end
  if addonTable.radialCombatCB then addonTable.radialCombatCB:SetChecked(profile.cursorCombatOnly == true) end
  if addonTable.radialGcdCB then addonTable.radialGcdCB:SetChecked(profile.showGCD == true) end
  if addonTable.ufClassColorCB then
    local classColorOn = ufOn and profile.ufUseCustomTextures == true
    addonTable.ufClassColorCB:SetChecked(profile.ufClassColor == true)
    addonTable.ufClassColorCB:SetEnabled(classColorOn)
    addonTable.ufClassColorCB:SetAlpha(classColorOn and 1 or 0.5)
  end
  local ufBigMaster = profile.ufBigHBEnabled
  if ufBigMaster == nil then
    ufBigMaster = (profile.ufBigHBPlayerEnabled == true) or (profile.ufBigHBTargetEnabled == true) or (profile.ufBigHBFocusEnabled == true)
  end
  profile.ufBigHBEnabled = ufBigMaster == true
  local bigHBPlayerOn = ufOn and profile.ufBigHBEnabled == true and profile.ufBigHBPlayerEnabled == true
  if addonTable.ufDisableGlowsCB then
    if bigHBPlayerOn then
      addonTable.ufDisableGlowsCB:SetChecked(true)
      addonTable.ufDisableGlowsCB:SetEnabled(false)
      if addonTable.ufDisableGlowsCB.SetAlpha then addonTable.ufDisableGlowsCB:SetAlpha(0.5) end
    else
      addonTable.ufDisableGlowsCB:SetChecked(profile.ufDisableGlows == true)
      addonTable.ufDisableGlowsCB:SetEnabled(ufOn)
      if addonTable.ufDisableGlowsCB.SetAlpha then addonTable.ufDisableGlowsCB:SetAlpha(ufOn and 1 or 0.5) end
    end
  end
  if addonTable.ufDisableCombatTextCB then
    addonTable.ufDisableCombatTextCB:SetChecked(profile.ufDisableCombatText == true)
    addonTable.ufDisableCombatTextCB:SetEnabled(ufOn)
    if addonTable.ufDisableCombatTextCB.SetAlpha then
      addonTable.ufDisableCombatTextCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  if addonTable.ufHideGroupIndicatorCB then
    addonTable.ufHideGroupIndicatorCB:SetChecked(profile.ufHideGroupIndicator == true)
    addonTable.ufHideGroupIndicatorCB:SetEnabled(ufOn)
    if addonTable.ufHideGroupIndicatorCB.SetAlpha then
      addonTable.ufHideGroupIndicatorCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  if addonTable.disableTargetBuffsCB then
    addonTable.disableTargetBuffsCB:SetChecked(profile.disableTargetBuffs == true)
    addonTable.disableTargetBuffsCB:SetEnabled(ufOn)
    if addonTable.disableTargetBuffsCB.SetAlpha then
      addonTable.disableTargetBuffsCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  if addonTable.hideEliteTextureCB then
    addonTable.hideEliteTextureCB:SetChecked(profile.hideEliteTexture == true)
    addonTable.hideEliteTextureCB:SetEnabled(ufOn)
    if addonTable.hideEliteTextureCB.SetAlpha then
      addonTable.hideEliteTextureCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  local bigHBOn = ufOn and (profile.ufBigHBPlayerEnabled == true or profile.ufBigHBTargetEnabled == true or profile.ufBigHBFocusEnabled == true)
  if addonTable.ufUseCustomTexturesCB then
    addonTable.ufUseCustomTexturesCB:SetChecked(profile.ufUseCustomTextures == true)
    addonTable.ufUseCustomTexturesCB:SetEnabled(ufOn)
    if addonTable.ufUseCustomTexturesCB.SetAlpha then addonTable.ufUseCustomTexturesCB:SetAlpha(ufOn and 1 or 0.5) end
  end
  local texOn = ufOn and profile.ufUseCustomTextures == true
  if addonTable.ufHealthTextureDD then
    addonTable.ufHealthTextureDD:SetValue(profile.ufHealthTexture or "lsm:Clean")
    addonTable.ufHealthTextureDD:SetEnabled(texOn)
    if addonTable.ufHealthTextureDD.SetAlpha then
      addonTable.ufHealthTextureDD:SetAlpha(texOn and 1 or 0.5)
    end
    if addonTable.ufHealthTextureLbl then
      addonTable.ufHealthTextureLbl:SetTextColor(texOn and 0.9 or 0.4, texOn and 0.9 or 0.4, texOn and 0.9 or 0.4)
    end
  end
  if addonTable.useCustomBorderColorCB then
    if bigHBOn then
      addonTable.useCustomBorderColorCB:SetChecked(true)
      addonTable.useCustomBorderColorCB:SetEnabled(false)
    else
      addonTable.useCustomBorderColorCB:SetChecked(profile.useCustomBorderColor == true)
      addonTable.useCustomBorderColorCB:SetEnabled(ufOn)
    end
  end
  if addonTable.ufBorderColorBtn then addonTable.ufBorderColorBtn:SetEnabled(bigHBOn or (ufOn and profile.useCustomBorderColor == true)) end
  if addonTable.ufBorderColorSwatch then
    addonTable.ufBorderColorSwatch:SetBackdropColor(num(profile.ufCustomBorderColorR, 0), num(profile.ufCustomBorderColorG, 0), num(profile.ufCustomBorderColorB, 0), 1)
  end
  if addonTable.ufUseCustomNameColorCB then
    if bigHBOn then
      addonTable.ufUseCustomNameColorCB:SetChecked(true)
      addonTable.ufUseCustomNameColorCB:SetEnabled(false)
      if addonTable.ufUseCustomNameColorCB.SetAlpha then addonTable.ufUseCustomNameColorCB:SetAlpha(0.5) end
    else
      addonTable.ufUseCustomNameColorCB:SetChecked(profile.ufUseCustomNameColor == true)
      addonTable.ufUseCustomNameColorCB:SetEnabled(ufOn)
      if addonTable.ufUseCustomNameColorCB.SetAlpha then addonTable.ufUseCustomNameColorCB:SetAlpha(ufOn and 1 or 0.5) end
    end
  end
  local nameColorOn = ufOn and (bigHBOn or profile.ufUseCustomNameColor == true)
  if addonTable.ufNameColorBtn then
    addonTable.ufNameColorBtn:SetEnabled(nameColorOn)
    if addonTable.ufNameColorBtn.SetAlpha then
      addonTable.ufNameColorBtn:SetAlpha(nameColorOn and 1 or 0.5)
    end
  end
  if addonTable.ufNameColorSwatch then
    addonTable.ufNameColorSwatch:SetBackdropColor(num(profile.ufNameColorR, 1), num(profile.ufNameColorG, 1), num(profile.ufNameColorB, 1), 1)
    if addonTable.ufNameColorSwatch.SetAlpha then
      addonTable.ufNameColorSwatch:SetAlpha(nameColorOn and 1 or 0.5)
    end
  end
  local ufBigPlayer = profile.ufBigHBPlayerEnabled == true
  local ufBigTarget = profile.ufBigHBTargetEnabled == true
  local ufBigFocus = profile.ufBigHBFocusEnabled == true
  local ufBossOn = profile.ufBossFramesEnabled == true
  local ufBigPlayerNameMaxChars = num(profile.ufBigHBPlayerNameMaxChars, num(profile.ufBigHBNameMaxChars, 0))
  local ufBigTargetNameMaxChars = num(profile.ufBigHBTargetNameMaxChars, num(profile.ufBigHBNameMaxChars, 0))
  local ufBigFocusNameMaxChars = num(profile.ufBigHBFocusNameMaxChars, num(profile.ufBigHBNameMaxChars, 0))
  if addonTable.ufBigHBPlayerCB then addonTable.ufBigHBPlayerCB:SetChecked(ufBigPlayer); addonTable.ufBigHBPlayerCB:SetEnabled(ufOn) end
  if addonTable.ufBigHBTargetCB then addonTable.ufBigHBTargetCB:SetChecked(ufBigTarget); addonTable.ufBigHBTargetCB:SetEnabled(ufOn) end
  if addonTable.ufBigHBFocusCB then addonTable.ufBigHBFocusCB:SetChecked(ufBigFocus); addonTable.ufBigHBFocusCB:SetEnabled(ufOn) end
  if addonTable.ufBossFramesEnabledCB then addonTable.ufBossFramesEnabledCB:SetChecked(ufBossOn); addonTable.ufBossFramesEnabledCB:SetEnabled(ufOn) end

  local function ApplyUFBigSlider(slider, value, enabled, fmt)
    if not slider then return end
    slider:SetEnabled(enabled)
    slider:SetAlpha(enabled and 1 or 0.35)
    if slider.valueTextBg then slider.valueTextBg:SetAlpha(enabled and 1 or 0.35) end
    slider._updating = true
    slider:SetValue(value)
    slider._updating = false
    if slider.valueText then
      if fmt then slider.valueText:SetText(string.format(fmt, value)) else slider.valueText:SetText(math.floor(value + 0.5)) end
    end
  end
  local playerGroupEnabled = bigHBOn and ufBigPlayer
  local targetGroupEnabled = bigHBOn and ufBigTarget
  local focusGroupEnabled = bigHBOn and ufBigFocus
  local bossGroupEnabled = ufOn and ufBossOn
  if addonTable.ufBigHBPlayerHideRealmCB then addonTable.ufBigHBPlayerHideRealmCB:SetChecked((profile.ufBigHBPlayerHideRealm == true) or (profile.ufBigHBHideRealm == true)); addonTable.ufBigHBPlayerHideRealmCB:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBTargetHideRealmCB then addonTable.ufBigHBTargetHideRealmCB:SetChecked((profile.ufBigHBTargetHideRealm == true) or (profile.ufBigHBHideRealm == true)); addonTable.ufBigHBTargetHideRealmCB:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBFocusHideRealmCB then addonTable.ufBigHBFocusHideRealmCB:SetChecked((profile.ufBigHBFocusHideRealm == true) or (profile.ufBigHBHideRealm == true)); addonTable.ufBigHBFocusHideRealmCB:SetEnabled(focusGroupEnabled) end
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameMaxCharsSlider, ufBigPlayerNameMaxChars, playerGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameMaxCharsSlider, ufBigTargetNameMaxChars, targetGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameMaxCharsSlider, ufBigFocusNameMaxChars, focusGroupEnabled)
  if addonTable.ufBigHBHidePlayerNameCB then addonTable.ufBigHBHidePlayerNameCB:SetChecked(profile.ufBigHBHidePlayerName == true); addonTable.ufBigHBHidePlayerNameCB:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerLevelDD then addonTable.ufBigHBPlayerLevelDD:SetValue(profile.ufBigHBPlayerLevelMode or "always"); addonTable.ufBigHBPlayerLevelDD:SetEnabled(playerGroupEnabled) end
  local playerNameEnabled = playerGroupEnabled and (profile.ufBigHBHidePlayerName ~= true)
  local playerLevelEnabled = playerGroupEnabled and ((profile.ufBigHBPlayerLevelMode or "always") ~= "hide")
  if addonTable.ufBigHBPlayerNameAnchorDD then addonTable.ufBigHBPlayerNameAnchorDD:SetValue(profile.ufBigHBPlayerNameAnchor or "center"); addonTable.ufBigHBPlayerNameAnchorDD:SetEnabled(playerNameEnabled) end
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameXSlider, num(profile.ufBigHBPlayerNameX, 0), playerNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameYSlider, num(profile.ufBigHBPlayerNameY, 0), playerNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerLevelXSlider, num(profile.ufBigHBPlayerLevelX, 0), playerLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerLevelYSlider, num(profile.ufBigHBPlayerLevelY, 0), playerLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameTextScaleSlider, num(profile.ufBigHBPlayerNameTextScale or profile.ufBigHBPlayerTextScale, 1), playerNameEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBigHBPlayerLevelTextScaleSlider, num(profile.ufBigHBPlayerLevelTextScale or profile.ufBigHBPlayerTextScale, 1), playerLevelEnabled, "%.2f")
  if addonTable.ufBigHBPlayerHealAbsorbDD then addonTable.ufBigHBPlayerHealAbsorbDD:SetValue(profile.ufBigHBPlayerHealAbsorb or "on"); addonTable.ufBigHBPlayerHealAbsorbDD:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerDmgAbsorbDD then addonTable.ufBigHBPlayerDmgAbsorbDD:SetValue(profile.ufBigHBPlayerDmgAbsorb or "bar_glow"); addonTable.ufBigHBPlayerDmgAbsorbDD:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerHealPredDD then addonTable.ufBigHBPlayerHealPredDD:SetValue(profile.ufBigHBPlayerHealPred or "on"); addonTable.ufBigHBPlayerHealPredDD:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerAbsorbStripesCB then addonTable.ufBigHBPlayerAbsorbStripesCB:SetChecked(profile.ufBigHBPlayerAbsorbStripes ~= false); addonTable.ufBigHBPlayerAbsorbStripesCB:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBHideTargetNameCB then addonTable.ufBigHBHideTargetNameCB:SetChecked(profile.ufBigHBHideTargetName == true); addonTable.ufBigHBHideTargetNameCB:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetLevelDD then addonTable.ufBigHBTargetLevelDD:SetValue(profile.ufBigHBTargetLevelMode or "always"); addonTable.ufBigHBTargetLevelDD:SetEnabled(targetGroupEnabled) end
  local targetNameEnabled = targetGroupEnabled and (profile.ufBigHBHideTargetName ~= true)
  local targetLevelEnabled = targetGroupEnabled and ((profile.ufBigHBTargetLevelMode or "always") ~= "hide")
  if addonTable.ufBigHBTargetNameAnchorDD then addonTable.ufBigHBTargetNameAnchorDD:SetValue(profile.ufBigHBTargetNameAnchor or "center"); addonTable.ufBigHBTargetNameAnchorDD:SetEnabled(targetNameEnabled) end
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameXSlider, num(profile.ufBigHBTargetNameX, 0), targetNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameYSlider, num(profile.ufBigHBTargetNameY, 0), targetNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetLevelXSlider, num(profile.ufBigHBTargetLevelX, 0), targetLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetLevelYSlider, num(profile.ufBigHBTargetLevelY, 0), targetLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameTextScaleSlider, num(profile.ufBigHBTargetNameTextScale or profile.ufBigHBTargetTextScale, 1), targetNameEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBigHBTargetLevelTextScaleSlider, num(profile.ufBigHBTargetLevelTextScale or profile.ufBigHBTargetTextScale, 1), targetLevelEnabled, "%.2f")
  if addonTable.ufBigHBTargetHealAbsorbDD then addonTable.ufBigHBTargetHealAbsorbDD:SetValue(profile.ufBigHBTargetHealAbsorb or "on"); addonTable.ufBigHBTargetHealAbsorbDD:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetDmgAbsorbDD then addonTable.ufBigHBTargetDmgAbsorbDD:SetValue(profile.ufBigHBTargetDmgAbsorb or "bar_glow"); addonTable.ufBigHBTargetDmgAbsorbDD:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetHealPredDD then addonTable.ufBigHBTargetHealPredDD:SetValue(profile.ufBigHBTargetHealPred or "on"); addonTable.ufBigHBTargetHealPredDD:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetAbsorbStripesCB then addonTable.ufBigHBTargetAbsorbStripesCB:SetChecked(profile.ufBigHBTargetAbsorbStripes ~= false); addonTable.ufBigHBTargetAbsorbStripesCB:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBHideFocusNameCB then addonTable.ufBigHBHideFocusNameCB:SetChecked(profile.ufBigHBHideFocusName == true); addonTable.ufBigHBHideFocusNameCB:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusLevelDD then addonTable.ufBigHBFocusLevelDD:SetValue(profile.ufBigHBFocusLevelMode or "always"); addonTable.ufBigHBFocusLevelDD:SetEnabled(focusGroupEnabled) end
  local focusNameEnabled = focusGroupEnabled and (profile.ufBigHBHideFocusName ~= true)
  local focusLevelEnabled = focusGroupEnabled and ((profile.ufBigHBFocusLevelMode or "always") ~= "hide")
  if addonTable.ufBigHBFocusNameAnchorDD then addonTable.ufBigHBFocusNameAnchorDD:SetValue(profile.ufBigHBFocusNameAnchor or "center"); addonTable.ufBigHBFocusNameAnchorDD:SetEnabled(focusNameEnabled) end
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameXSlider, num(profile.ufBigHBFocusNameX, 0), focusNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameYSlider, num(profile.ufBigHBFocusNameY, 0), focusNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusLevelXSlider, num(profile.ufBigHBFocusLevelX, 0), focusLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusLevelYSlider, num(profile.ufBigHBFocusLevelY, 0), focusLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameTextScaleSlider, num(profile.ufBigHBFocusNameTextScale or profile.ufBigHBFocusTextScale, 1), focusNameEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBigHBFocusLevelTextScaleSlider, num(profile.ufBigHBFocusLevelTextScale or profile.ufBigHBFocusTextScale, 1), focusLevelEnabled, "%.2f")
  if addonTable.ufBigHBFocusHealAbsorbDD then addonTable.ufBigHBFocusHealAbsorbDD:SetValue(profile.ufBigHBFocusHealAbsorb or "on"); addonTable.ufBigHBFocusHealAbsorbDD:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusDmgAbsorbDD then addonTable.ufBigHBFocusDmgAbsorbDD:SetValue(profile.ufBigHBFocusDmgAbsorb or "bar_glow"); addonTable.ufBigHBFocusDmgAbsorbDD:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusHealPredDD then addonTable.ufBigHBFocusHealPredDD:SetValue(profile.ufBigHBFocusHealPred or "on"); addonTable.ufBigHBFocusHealPredDD:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusAbsorbStripesCB then addonTable.ufBigHBFocusAbsorbStripesCB:SetChecked(profile.ufBigHBFocusAbsorbStripes ~= false); addonTable.ufBigHBFocusAbsorbStripesCB:SetEnabled(focusGroupEnabled) end
  ApplyUFBigSlider(addonTable.ufBossFrameXSlider, num(profile.ufBossFrameX, -245), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossFrameYSlider, num(profile.ufBossFrameY, -280), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossFrameSpacingSlider, num(profile.ufBossFrameSpacing, 36), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossFrameWidthSlider, num(profile.ufBossFrameWidth, 168), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossFrameHealthHeightSlider, num(profile.ufBossFrameHealthHeight, 20), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossFramePowerHeightSlider, num(profile.ufBossFramePowerHeight, 8), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossFrameScaleSlider, num(profile.ufBossFrameScale, 1), bossGroupEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBossFrameBorderSizeSlider, num(profile.ufBossFrameBorderSize, 1), bossGroupEnabled)
  if addonTable.ufBossFrameShowLevelCB then addonTable.ufBossFrameShowLevelCB:SetChecked(profile.ufBossFrameShowLevel ~= false); addonTable.ufBossFrameShowLevelCB:SetEnabled(bossGroupEnabled) end
  if addonTable.ufBossFrameHidePortraitCB then addonTable.ufBossFrameHidePortraitCB:SetChecked(profile.ufBossFrameHidePortrait == true); addonTable.ufBossFrameHidePortraitCB:SetEnabled(bossGroupEnabled) end
  if addonTable.ufBossFrameShowHealthTextCB then addonTable.ufBossFrameShowHealthTextCB:SetChecked(profile.ufBossFrameShowHealthText ~= false); addonTable.ufBossFrameShowHealthTextCB:SetEnabled(bossGroupEnabled) end
  local bossHpTextEnabled = bossGroupEnabled and (profile.ufBossFrameShowHealthText ~= false)
  if addonTable.ufBossHealthTextFormatDD then addonTable.ufBossHealthTextFormatDD:SetValue(profile.ufBossHealthTextFormat or "percent_value"); addonTable.ufBossHealthTextFormatDD:SetEnabled(bossHpTextEnabled); addonTable.ufBossHealthTextFormatDD:SetAlpha(bossHpTextEnabled and 1 or 0.35) end
  ApplyUFBigSlider(addonTable.ufBossHealthTextScaleSlider, num(profile.ufBossHealthTextScale, 1), bossHpTextEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBossHealthTextXSlider, num(profile.ufBossHealthTextX, -4), bossHpTextEnabled)
  ApplyUFBigSlider(addonTable.ufBossHealthTextYSlider, num(profile.ufBossHealthTextY, 0), bossHpTextEnabled)
  if addonTable.ufBossFrameShowPowerTextCB then addonTable.ufBossFrameShowPowerTextCB:SetChecked(profile.ufBossFrameShowPowerText ~= false); addonTable.ufBossFrameShowPowerTextCB:SetEnabled(bossGroupEnabled) end
  local bossPpTextEnabled = bossGroupEnabled and (profile.ufBossFrameShowPowerText ~= false)
  ApplyUFBigSlider(addonTable.ufBossPowerTextScaleSlider, num(profile.ufBossPowerTextScale, 1), bossPpTextEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBossPowerTextXSlider, num(profile.ufBossPowerTextX, -4), bossPpTextEnabled)
  ApplyUFBigSlider(addonTable.ufBossPowerTextYSlider, num(profile.ufBossPowerTextY, 0), bossPpTextEnabled)
  if addonTable.ufBossFrameShowAbsorbCB then addonTable.ufBossFrameShowAbsorbCB:SetChecked(profile.ufBossFrameShowAbsorb == true); addonTable.ufBossFrameShowAbsorbCB:SetEnabled(bossGroupEnabled) end
  if addonTable.ufBossAbsorbColorBtn then addonTable.ufBossAbsorbColorBtn:SetEnabled(bossGroupEnabled and (profile.ufBossFrameShowAbsorb == true)); addonTable.ufBossAbsorbColorBtn:SetAlpha((bossGroupEnabled and (profile.ufBossFrameShowAbsorb == true)) and 1 or 0.35) end
  if addonTable.ufBossBarTextureDD then addonTable.ufBossBarTextureDD:SetValue(profile.ufBossBarTexture or "lsm:Blizzard"); addonTable.ufBossBarTextureDD:SetEnabled(bossGroupEnabled); addonTable.ufBossBarTextureDD:SetAlpha(bossGroupEnabled and 1 or 0.35) end
  ApplyUFBigSlider(addonTable.ufBossFrameBarBgAlphaSlider, num(profile.ufBossFrameBarBgAlpha, 0.45), bossGroupEnabled, "%.2f")
  local bossCastClamped = profile.ufBossCastbarClamped ~= false
  if addonTable.ufBossCastbarClampedCB then addonTable.ufBossCastbarClampedCB:SetChecked(bossCastClamped); addonTable.ufBossCastbarClampedCB:SetEnabled(bossGroupEnabled) end
  if addonTable.ufBossCastbarAnchorDD then addonTable.ufBossCastbarAnchorDD:SetOptions({{text = "Bottom", value = "bottom"}, {text = "Top", value = "top"}, {text = "Left", value = "left", disabled = bossCastClamped}, {text = "Right", value = "right", disabled = bossCastClamped}}); addonTable.ufBossCastbarAnchorDD:SetValue(profile.ufBossCastbarAnchor or "bottom"); addonTable.ufBossCastbarAnchorDD:SetEnabled(bossGroupEnabled); addonTable.ufBossCastbarAnchorDD:SetAlpha(bossGroupEnabled and 1 or 0.35) end
  ApplyUFBigSlider(addonTable.ufBossCastbarHeightSlider, num(profile.ufBossCastbarHeight, 12), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossCastbarWidthSlider, num(profile.ufBossCastbarWidth, 0), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossCastbarSpacingSlider, num(profile.ufBossCastbarSpacing, 2), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossCastbarTextScaleSlider, num(profile.ufBossCastbarTextScale, 1), bossGroupEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBossCastbarXSlider, num(profile.ufBossCastbarX, 0), bossGroupEnabled)
  ApplyUFBigSlider(addonTable.ufBossCastbarYSlider, num(profile.ufBossCastbarY, 0), bossGroupEnabled)
  if addonTable.ufBossCastbarIconCB then addonTable.ufBossCastbarIconCB:SetChecked(profile.ufBossCastbarIcon ~= false); addonTable.ufBossCastbarIconCB:SetEnabled(bossGroupEnabled) end
  if addonTable.ufBossFramePreviewOnBtn then addonTable.ufBossFramePreviewOnBtn:SetEnabled(bossGroupEnabled); addonTable.ufBossFramePreviewOnBtn:SetAlpha(bossGroupEnabled and 1 or 0.45) end
  if addonTable.ufBossFramePreviewOffBtn then addonTable.ufBossFramePreviewOffBtn:SetEnabled(true); addonTable.ufBossFramePreviewOffBtn:SetAlpha(1) end
  if addonTable.autoRepairCB then addonTable.autoRepairCB:SetChecked(profile.autoRepair == true) end
  if addonTable.showTooltipIDsCB then addonTable.showTooltipIDsCB:SetChecked(profile.showTooltipIDs == true) end
  if addonTable.compactMinimapIconsCB then addonTable.compactMinimapIconsCB:SetChecked(profile.compactMinimapIcons == true) end
  if addonTable.enhancedTooltipCB then addonTable.enhancedTooltipCB:SetChecked(profile.enhancedTooltip == true) end
  if addonTable.autoQuestCB then addonTable.autoQuestCB:SetChecked(profile.autoQuest == true) end
  if addonTable.autoQuestExcludeDailyCB then addonTable.autoQuestExcludeDailyCB:SetChecked(profile.autoQuestExcludeDaily == true) end
  if addonTable.autoQuestExcludeWeeklyCB then addonTable.autoQuestExcludeWeeklyCB:SetChecked(profile.autoQuestExcludeWeekly == true) end
  if addonTable.autoQuestExcludeTrivialCB then addonTable.autoQuestExcludeTrivialCB:SetChecked(profile.autoQuestExcludeTrivial == true) end
  if addonTable.autoQuestExcludeCompletedCB then addonTable.autoQuestExcludeCompletedCB:SetChecked(profile.autoQuestExcludeCompleted == true) end
  if addonTable.autoQuestRewardDD then addonTable.autoQuestRewardDD:SetValue(profile.autoQuestRewardMode or "skip") end
  local aqEnabled = profile.autoQuest == true
  local aqAlpha = aqEnabled and 1 or 0.4
  if addonTable.autoQuestExcludeDailyCB then addonTable.autoQuestExcludeDailyCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeDailyCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestExcludeWeeklyCB then addonTable.autoQuestExcludeWeeklyCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeWeeklyCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestExcludeTrivialCB then addonTable.autoQuestExcludeTrivialCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeTrivialCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestExcludeCompletedCB then addonTable.autoQuestExcludeCompletedCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeCompletedCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestRewardDD then addonTable.autoQuestRewardDD:SetAlpha(aqAlpha) end
  if addonTable.autoSellJunkCB then addonTable.autoSellJunkCB:SetChecked(profile.autoSellJunk == true) end
  if addonTable.autoFillDeleteCB then addonTable.autoFillDeleteCB:SetChecked(profile.autoFillDelete == true) end
  if addonTable.quickRoleSignupCB then addonTable.quickRoleSignupCB:SetChecked(profile.quickRoleSignup == true) end
  if addonTable.combatTimerCB then addonTable.combatTimerCB:SetChecked(profile.combatTimerEnabled == true) end
  if addonTable.combatTimerModeDD then addonTable.combatTimerModeDD:SetValue(profile.combatTimerMode or "combat") end
  if addonTable.combatTimerStyleDD then addonTable.combatTimerStyleDD:SetValue(profile.combatTimerStyle or "boxed") end
  if addonTable.combatTimerCenteredCB then addonTable.combatTimerCenteredCB:SetChecked(profile.combatTimerCentered == true) end
  local combatTimerEnabled = profile.combatTimerEnabled == true
  if addonTable.combatTimerModeDD then addonTable.combatTimerModeDD:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerModeLbl then addonTable.combatTimerModeLbl:SetTextColor(combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4) end
  if addonTable.combatTimerStyleDD then addonTable.combatTimerStyleDD:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerStyleLbl then addonTable.combatTimerStyleLbl:SetTextColor(combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4) end
  local combatTimerCentered = profile.combatTimerCentered == true
  if addonTable.combatTimerXSlider then addonTable.combatTimerXSlider:SetValue(num(profile.combatTimerX, 0)); addonTable.combatTimerXSlider.valueText:SetText(math.floor(num(profile.combatTimerX, 0))); addonTable.combatTimerXSlider:SetEnabled(combatTimerEnabled and (not combatTimerCentered)) end
  if addonTable.combatTimerYSlider then addonTable.combatTimerYSlider:SetValue(num(profile.combatTimerY, 200)); addonTable.combatTimerYSlider.valueText:SetText(math.floor(num(profile.combatTimerY, 200))); addonTable.combatTimerYSlider:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerScaleSlider then addonTable.combatTimerScaleSlider:SetValue(num(profile.combatTimerScale, 1)); addonTable.combatTimerScaleSlider.valueText:SetText(string.format("%.2f", num(profile.combatTimerScale, 1))); addonTable.combatTimerScaleSlider:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerTextColorBtn then addonTable.combatTimerTextColorBtn:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerBgColorBtn then addonTable.combatTimerBgColorBtn:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerTextColorSwatch then addonTable.combatTimerTextColorSwatch:SetBackdropColor(num(profile.combatTimerTextColorR, 1), num(profile.combatTimerTextColorG, 1), num(profile.combatTimerTextColorB, 1), 1) end
  if addonTable.combatTimerBgColorSwatch then addonTable.combatTimerBgColorSwatch:SetBackdropColor(num(profile.combatTimerBgColorR, 0.12), num(profile.combatTimerBgColorG, 0.12), num(profile.combatTimerBgColorB, 0.12), 1) end
  local crEnabled = profile.crTimerEnabled == true
  if addonTable.crTimerCB then addonTable.crTimerCB:SetChecked(crEnabled) end
  if addonTable.crTimerModeDD then addonTable.crTimerModeDD:SetValue(profile.crTimerMode or "combat"); addonTable.crTimerModeDD:SetEnabled(crEnabled) end
  if addonTable.crTimerModeLbl then addonTable.crTimerModeLbl:SetTextColor(crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4) end
  local crDisplayMode = profile.crTimerDisplay or "timer"
  if addonTable.crTimerDisplayDD then addonTable.crTimerDisplayDD:SetValue(crDisplayMode); addonTable.crTimerDisplayDD:SetEnabled(crEnabled) end
  if addonTable.crTimerDisplayLbl then addonTable.crTimerDisplayLbl:SetTextColor(crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4) end
  local layoutEnabled = crEnabled and (crDisplayMode ~= "count")
  if addonTable.crTimerLayoutDD then addonTable.crTimerLayoutDD:SetValue(profile.crTimerLayout or "vertical"); addonTable.crTimerLayoutDD:SetEnabled(layoutEnabled) end
  if addonTable.crTimerLayoutLbl then addonTable.crTimerLayoutLbl:SetTextColor(layoutEnabled and 0.9 or 0.4, layoutEnabled and 0.9 or 0.4, layoutEnabled and 0.9 or 0.4) end
  local crCentered = profile.crTimerCentered == true
  if addonTable.crTimerCenteredCB then addonTable.crTimerCenteredCB:SetChecked(crCentered); addonTable.crTimerCenteredCB:SetEnabled(crEnabled) end
  if addonTable.crTimerXSlider then addonTable.crTimerXSlider:SetValue(num(profile.crTimerX, 0)); addonTable.crTimerXSlider.valueText:SetText(math.floor(num(profile.crTimerX, 0))); addonTable.crTimerXSlider:SetEnabled(crEnabled and (not crCentered)) end
  if addonTable.crTimerYSlider then addonTable.crTimerYSlider:SetValue(num(profile.crTimerY, 150)); addonTable.crTimerYSlider.valueText:SetText(math.floor(num(profile.crTimerY, 150))); addonTable.crTimerYSlider:SetEnabled(crEnabled) end
  if addonTable.crTimerScaleSlider then addonTable.crTimerScaleSlider:SetValue(num(profile.crTimerScale, 1)); addonTable.crTimerScaleSlider.valueText:SetText(string.format("%.2f", num(profile.crTimerScale, 1))); addonTable.crTimerScaleSlider:SetEnabled(crEnabled) end
  local combatStatusEnabled = profile.combatStatusEnabled == true
  if addonTable.combatStatusCB then addonTable.combatStatusCB:SetChecked(combatStatusEnabled) end
  local combatStatusCentered = profile.combatStatusCentered == true
  if addonTable.combatStatusCenteredCB then addonTable.combatStatusCenteredCB:SetChecked(combatStatusCentered); addonTable.combatStatusCenteredCB:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusXSlider then addonTable.combatStatusXSlider:SetValue(num(profile.combatStatusX, 0)); addonTable.combatStatusXSlider.valueText:SetText(math.floor(num(profile.combatStatusX, 0))); addonTable.combatStatusXSlider:SetEnabled(combatStatusEnabled and (not combatStatusCentered)) end
  if addonTable.combatStatusYSlider then addonTable.combatStatusYSlider:SetValue(num(profile.combatStatusY, 280)); addonTable.combatStatusYSlider.valueText:SetText(math.floor(num(profile.combatStatusY, 280))); addonTable.combatStatusYSlider:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusScaleSlider then addonTable.combatStatusScaleSlider:SetValue(num(profile.combatStatusScale, 1)); addonTable.combatStatusScaleSlider.valueText:SetText(string.format("%.2f", num(profile.combatStatusScale, 1))); addonTable.combatStatusScaleSlider:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusEnterColorBtn then addonTable.combatStatusEnterColorBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusLeaveColorBtn then addonTable.combatStatusLeaveColorBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusPreviewOnBtn then addonTable.combatStatusPreviewOnBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusPreviewOffBtn then addonTable.combatStatusPreviewOffBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusEnterColorSwatch then addonTable.combatStatusEnterColorSwatch:SetBackdropColor(num(profile.combatStatusEnterColorR, 1), num(profile.combatStatusEnterColorG, 1), num(profile.combatStatusEnterColorB, 1), 1) end
  if addonTable.combatStatusLeaveColorSwatch then addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(num(profile.combatStatusLeaveColorR, 1), num(profile.combatStatusLeaveColorG, 1), num(profile.combatStatusLeaveColorB, 1), 1) end
  if addonTable.minimapCB then
    local compact = profile.compactMinimapIcons == true
    if compact then
      profile.showMinimapButton = true
      addonTable.minimapCB:SetChecked(true)
    else
      addonTable.minimapCB:SetChecked(profile.showMinimapButton ~= false)
    end
    if addonTable.minimapCB.SetEnabled then addonTable.minimapCB:SetEnabled(not compact) end
    if addonTable.minimapCB.SetAlpha then addonTable.minimapCB:SetAlpha(compact and 0.5 or 1) end
    if addonTable.minimapCB.label then
      addonTable.minimapCB.label:SetTextColor(compact and 0.5 or 0.9, compact and 0.5 or 0.9, compact and 0.5 or 0.9)
    end
  end
  if addonTable.radiusSlider then addonTable.radiusSlider:SetValue(num(profile.radialRadius, 30)); addonTable.radiusSlider.valueText:SetText(math.floor(num(profile.radialRadius, 30))) end
  if addonTable.radialThicknessDD then addonTable.radialThicknessDD:SetValue(RadialThicknessToPreset(profile.radialThickness)) end
  if addonTable.colorSwatch then addonTable.colorSwatch:SetBackdropColor(num(profile.radialColorR, 1), num(profile.radialColorG, 1), num(profile.radialColorB, 1), 1) end
  if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end
  local shapeEnabled = (profile.selfHighlightShape or "off") ~= "off"
  if addonTable.selfHighlightCB then addonTable.selfHighlightCB:SetChecked(shapeEnabled) end
  if addonTable.selfHighlightVisibilityDD then addonTable.selfHighlightVisibilityDD:SetValue(profile.selfHighlightCombatOnly and "combat" or "always"); addonTable.selfHighlightVisibilityDD:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightSizeSlider then addonTable.selfHighlightSizeSlider:SetValue(num(profile.selfHighlightSize, 20)); addonTable.selfHighlightSizeSlider.valueText:SetText(math.floor(num(profile.selfHighlightSize, 20))); addonTable.selfHighlightSizeSlider:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightYSlider then addonTable.selfHighlightYSlider:SetValue(num(profile.selfHighlightY, 0)); addonTable.selfHighlightYSlider.valueText:SetText(math.floor(num(profile.selfHighlightY, 0))); addonTable.selfHighlightYSlider:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightThicknessDD then addonTable.selfHighlightThicknessDD:SetValue(profile.selfHighlightThickness or "medium"); addonTable.selfHighlightThicknessDD:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightThicknessLbl then addonTable.selfHighlightThicknessLbl:SetTextColor(shapeEnabled and 0.9 or 0.4, shapeEnabled and 0.9 or 0.4, shapeEnabled and 0.9 or 0.4) end
  if addonTable.selfHighlightOutlineCB then addonTable.selfHighlightOutlineCB:SetChecked(profile.selfHighlightOutline ~= false); addonTable.selfHighlightOutlineCB:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightColorBtn then addonTable.selfHighlightColorBtn:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightColorSwatch then addonTable.selfHighlightColorSwatch:SetBackdropColor(num(profile.selfHighlightColorR, 1), num(profile.selfHighlightColorG, 1), num(profile.selfHighlightColorB, 1), 1) end
  local ntaEnabled = profile.noTargetAlertEnabled == true
  if addonTable.noTargetAlertCB then addonTable.noTargetAlertCB:SetChecked(ntaEnabled) end
  if addonTable.noTargetAlertFlashCB then addonTable.noTargetAlertFlashCB:SetChecked(profile.noTargetAlertFlash == true); addonTable.noTargetAlertFlashCB:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertXSlider then addonTable.noTargetAlertXSlider:SetValue(num(profile.noTargetAlertX, 0)); addonTable.noTargetAlertXSlider.valueText:SetText(math.floor(num(profile.noTargetAlertX, 0))); addonTable.noTargetAlertXSlider:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertYSlider then addonTable.noTargetAlertYSlider:SetValue(num(profile.noTargetAlertY, 100)); addonTable.noTargetAlertYSlider.valueText:SetText(math.floor(num(profile.noTargetAlertY, 100))); addonTable.noTargetAlertYSlider:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertFontSizeSlider then addonTable.noTargetAlertFontSizeSlider:SetValue(num(profile.noTargetAlertFontSize, 36)); addonTable.noTargetAlertFontSizeSlider.valueText:SetText(math.floor(num(profile.noTargetAlertFontSize, 36))); addonTable.noTargetAlertFontSizeSlider:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertColorBtn then addonTable.noTargetAlertColorBtn:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertColorSwatch then addonTable.noTargetAlertColorSwatch:SetBackdropColor(num(profile.noTargetAlertColorR, 1), num(profile.noTargetAlertColorG, 0), num(profile.noTargetAlertColorB, 0), 1) end
  local lhwEnabled = profile.lowHealthWarningEnabled == true
  if lhwEnabled then SetCVar("doNotFlashLowHealthWarning", "0") end
  if addonTable.lowHealthWarningCB then addonTable.lowHealthWarningCB:SetChecked(lhwEnabled) end
  if addonTable.lowHealthWarningTextBox then addonTable.lowHealthWarningTextBox:SetText(profile.lowHealthWarningText or "LOW HEALTH"); addonTable.lowHealthWarningTextBox:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningFontSizeSlider then addonTable.lowHealthWarningFontSizeSlider:SetValue(num(profile.lowHealthWarningFontSize, 36)); addonTable.lowHealthWarningFontSizeSlider.valueText:SetText(math.floor(num(profile.lowHealthWarningFontSize, 36))); addonTable.lowHealthWarningFontSizeSlider:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningSoundDD then addonTable.lowHealthWarningSoundDD:SetValue(profile.lowHealthWarningSound or "None"); addonTable.lowHealthWarningSoundDD:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningFlashCB then addonTable.lowHealthWarningFlashCB:SetChecked(profile.lowHealthWarningFlash == true); addonTable.lowHealthWarningFlashCB:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningXSlider then addonTable.lowHealthWarningXSlider:SetValue(num(profile.lowHealthWarningX, 0)); addonTable.lowHealthWarningXSlider.valueText:SetText(math.floor(num(profile.lowHealthWarningX, 0))); addonTable.lowHealthWarningXSlider:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningYSlider then addonTable.lowHealthWarningYSlider:SetValue(num(profile.lowHealthWarningY, 200)); addonTable.lowHealthWarningYSlider.valueText:SetText(math.floor(num(profile.lowHealthWarningY, 200))); addonTable.lowHealthWarningYSlider:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningColorBtn then addonTable.lowHealthWarningColorBtn:SetEnabled(lhwEnabled) end
  if addonTable.lowHealthWarningColorSwatch then addonTable.lowHealthWarningColorSwatch:SetBackdropColor(num(profile.lowHealthWarningColorR, 1), num(profile.lowHealthWarningColorG, 0), num(profile.lowHealthWarningColorB, 0), 1) end
  if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
  if addonTable.UpdateNoTargetAlert then addonTable.UpdateNoTargetAlert() end
  if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  local cur = addonTable.cursor
  if cur then
    if cur.combatOnlyCB then cur.combatOnlyCB:SetChecked(profile.iconsCombatOnly == true) end
    if cur.gcdCB then cur.gcdCB:SetChecked(profile.cursorShowGCD == true) end
    if cur.iconSizeSlider then cur.iconSizeSlider:SetValue(num(profile.iconSize, 23)); cur.iconSizeSlider.valueText:SetText(math.floor(num(profile.iconSize, 23))) end
    if cur.spacingSlider then cur.spacingSlider:SetValue(num(profile.iconSpacing, 2)); cur.spacingSlider.valueText:SetText(math.floor(num(profile.iconSpacing, 2))) end
    if cur.cdTextSlider then cur.cdTextSlider:SetValue(num(profile.cdTextScale, 1.0)); cur.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.cdTextScale, 1.0))) end
    if cur.cdGradientSlider then local gv = num(profile.cdTextGradientThreshold, 0); cur.cdGradientSlider:SetValue(gv); cur.cdGradientSlider.valueText:SetText(gv > 0 and math.floor(gv) or "Off") end
    if cur.cdGradientColorSwatch then cur.cdGradientColorSwatch:SetBackdropColor(num(profile.cdTextGradientR, 1), num(profile.cdTextGradientG, 0), num(profile.cdTextGradientB, 0), 1); cur.cdGradientColorSwatch:SetShown(num(profile.cdTextGradientThreshold, 0) > 0) end
    if cur.stackTextSlider then cur.stackTextSlider:SetValue(num(profile.stackTextScale, 1.0)); cur.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.stackTextScale, 1.0))) end
    if cur.iconsPerRowSlider then cur.iconsPerRowSlider:SetValue(num(profile.iconsPerRow, 10)); cur.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.iconsPerRow, 10))) end
    if cur.cooldownModeDD then cur.cooldownModeDD:SetValue(profile.cooldownIconMode or "show") end
    if cur.alwaysShowInCB then cur.alwaysShowInCB:SetChecked(profile.alwaysShowInEnabled == true) end
    if cur.alwaysShowInDD then cur.alwaysShowInDD:SetValue(profile.alwaysShowInMode or "raid"); cur.alwaysShowInDD:SetEnabled(profile.alwaysShowInEnabled == true) end
    if cur.offsetXSlider then cur.offsetXSlider:SetValue(num(profile.offsetX, 10)); cur.offsetXSlider.valueText:SetText(math.floor(num(profile.offsetX, 10))) end
    if cur.offsetYSlider then cur.offsetYSlider:SetValue(num(profile.offsetY, 25)); cur.offsetYSlider.valueText:SetText(math.floor(num(profile.offsetY, 25))) end
    if cur.directionDD then cur.directionDD:SetValue(profile.layoutDirection or "horizontal") end
	    if cur.stackAnchorDD then cur.stackAnchorDD:SetValue(profile.stackTextPosition or "BOTTOMRIGHT") end
	    if cur.buffOverlayCB then
	      profile.useBuffOverlay = false
	      cur.buffOverlayCB:SetChecked(false)
	      cur.buffOverlayCB:SetEnabled(false)
	      if cur.buffOverlayCB.label and cur.buffOverlayCB.label.Hide then cur.buffOverlayCB.label:Hide() end
	      if cur.buffOverlayCB.Hide then cur.buffOverlayCB:Hide() end
	    end
	    if cur.trackBuffsCB then cur.trackBuffsCB:SetChecked(profile.trackBuffs ~= false) end
	    if cur.openBlizzBuffBtn then cur.openBlizzBuffBtn:SetShown(profile.trackBuffs ~= false) end
	    if cur.useGlowsCB then cur.useGlowsCB:SetChecked(profile.useSpellGlows == true) end
	    if cur.customHideRevealCB then cur.customHideRevealCB:SetChecked(profile.useCustomHideReveal == true); cur.customHideRevealCB:SetEnabled((profile.cooldownIconMode or "show") == "hide") end
	    local cursorGlowsEnabled = profile.useSpellGlows == true
	    if cur.glowSpeedSlider then
	      cur.glowSpeedSlider:SetValue(num(profile.spellGlowSpeed, 0.0))
	      cur.glowSpeedSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowSpeed, 0.0)))
	      SetStyledSliderShown(cur.glowSpeedSlider, cursorGlowsEnabled)
	    end
	    if cur.glowThicknessSlider then
	      cur.glowThicknessSlider:SetValue(num(profile.spellGlowThickness, 2.0))
	      cur.glowThicknessSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowThickness, 2.0)))
	      SetStyledSliderShown(cur.glowThicknessSlider, cursorGlowsEnabled)
	    end
	    if cur.stackXSlider then cur.stackXSlider:SetValue(num(profile.stackTextOffsetX, 0)); cur.stackXSlider.valueText:SetText(math.floor(num(profile.stackTextOffsetX, 0))) end
    if cur.stackYSlider then cur.stackYSlider:SetValue(num(profile.stackTextOffsetY, 0)); cur.stackYSlider.valueText:SetText(math.floor(num(profile.stackTextOffsetY, 0))) end
  end
  local cb1 = addonTable.cb1
  if cb1 then
    if cb1.combatOnlyCB then cb1.combatOnlyCB:SetChecked(profile.customBarOutOfCombat == false) end
    if cb1.gcdCB then cb1.gcdCB:SetChecked(profile.customBarShowGCD == true) end
    if cb1.buffOverlayCB then
      profile.customBarUseBuffOverlay = false
      cb1.buffOverlayCB:SetChecked(false)
      cb1.buffOverlayCB:SetEnabled(false)
      if cb1.buffOverlayCB.label and cb1.buffOverlayCB.label.Hide then cb1.buffOverlayCB.label:Hide() end
      if cb1.buffOverlayCB.Hide then cb1.buffOverlayCB:Hide() end
    end
    if cb1.trackBuffsCB then cb1.trackBuffsCB:SetChecked(profile.customBarTrackBuffs ~= false) end
    if cb1.openBlizzBuffBtn then cb1.openBlizzBuffBtn:SetShown(profile.customBarTrackBuffs ~= false) end
    if cb1.centeredCB then cb1.centeredCB:SetChecked(profile.customBarCentered == true) end
    if cb1.iconSizeSlider then cb1.iconSizeSlider:SetValue(num(profile.customBarIconSize, 30)); cb1.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBarIconSize, 30))) end
    if cb1.spacingSlider then cb1.spacingSlider:SetValue(num(profile.customBarSpacing, 2)); cb1.spacingSlider.valueText:SetText(math.floor(num(profile.customBarSpacing, 2))) end
    if cb1.cdTextSlider then cb1.cdTextSlider:SetValue(num(profile.customBarCdTextScale, 1.0)); cb1.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBarCdTextScale, 1.0))) end
    if cb1.cdGradientSlider then local gv = num(profile.customBarCdGradientThreshold, 0); cb1.cdGradientSlider:SetValue(gv); cb1.cdGradientSlider.valueText:SetText(gv > 0 and math.floor(gv) or "Off") end
    if cb1.cdGradientColorSwatch then cb1.cdGradientColorSwatch:SetBackdropColor(num(profile.customBarCdGradientR, 1), num(profile.customBarCdGradientG, 0), num(profile.customBarCdGradientB, 0), 1); cb1.cdGradientColorSwatch:SetShown(num(profile.customBarCdGradientThreshold, 0) > 0) end
    if cb1.stackTextSlider then cb1.stackTextSlider:SetValue(num(profile.customBarStackTextScale, 1.0)); cb1.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBarStackTextScale, 1.0))) end
    if cb1.iconsPerRowSlider then cb1.iconsPerRowSlider:SetValue(num(profile.customBarIconsPerRow, 20)); cb1.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBarIconsPerRow, 20))) end
    if cb1.cdModeDD then cb1.cdModeDD:SetValue(profile.customBarCooldownMode or "show") end
    if cb1.showModeDD then cb1.showModeDD:SetValue(profile.customBarShowMode or "always") end
    if cb1.xSlider then cb1.xSlider:SetValue(num(profile.customBarX, 0)); cb1.xSlider.valueText:SetText(math.floor(num(profile.customBarX, 0))) end
    if cb1.ySlider then cb1.ySlider:SetValue(num(profile.customBarY, -200)); cb1.ySlider.valueText:SetText(math.floor(num(profile.customBarY, -200))) end
    if cb1.directionDD then cb1.directionDD:SetValue(profile.customBarDirection or "horizontal") end
    if cb1.anchorDD then cb1.anchorDD:SetValue(profile.customBarAnchorPoint or "LEFT") end
	    if cb1.growthDD then cb1.growthDD:SetValue(profile.customBarGrowth or "DOWN") end
	    if cb1.useGlowsCB then cb1.useGlowsCB:SetChecked(profile.customBarUseSpellGlows == true) end
	    if cb1.customHideRevealCB then cb1.customHideRevealCB:SetChecked(profile.customBarUseCustomHideReveal == true); cb1.customHideRevealCB:SetEnabled((profile.customBarCooldownMode or "show") == "hide") end
	    local cb1GlowsEnabled = profile.customBarUseSpellGlows == true
	    if cb1.glowSpeedSlider then
	      cb1.glowSpeedSlider:SetValue(num(profile.spellGlowSpeed, 0.0))
	      cb1.glowSpeedSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowSpeed, 0.0)))
	      SetStyledSliderShown(cb1.glowSpeedSlider, cb1GlowsEnabled)
	    end
	    if cb1.glowThicknessSlider then
	      cb1.glowThicknessSlider:SetValue(num(profile.spellGlowThickness, 2.0))
	      cb1.glowThicknessSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowThickness, 2.0)))
	      SetStyledSliderShown(cb1.glowThicknessSlider, cb1GlowsEnabled)
	    end
	    if cb1.anchorTargetDD then if addonTable.GetAnchorFrameOptions then cb1.anchorTargetDD:SetOptions(addonTable.GetAnchorFrameOptions(1)) end; cb1.anchorTargetDD:SetValue(profile.customBarAnchorFrame or "UIParent") end
    if cb1.anchorToPointDD then cb1.anchorToPointDD:SetValue(profile.customBarAnchorToPoint or "CENTER"); cb1.anchorToPointDD:SetEnabled((profile.customBarAnchorFrame or "UIParent") ~= "UIParent") end
    if cb1.stackAnchorDD then cb1.stackAnchorDD:SetValue(profile.customBarStackTextPosition or "BOTTOMRIGHT") end
    if cb1.stackXSlider then cb1.stackXSlider:SetValue(num(profile.customBarStackTextOffsetX, 0)); cb1.stackXSlider.valueText:SetText(math.floor(num(profile.customBarStackTextOffsetX, 0))) end
    if cb1.stackYSlider then cb1.stackYSlider:SetValue(num(profile.customBarStackTextOffsetY, 0)); cb1.stackYSlider.valueText:SetText(math.floor(num(profile.customBarStackTextOffsetY, 0))) end
  end
  local cb2 = addonTable.cb2
  if cb2 then
    if cb2.combatOnlyCB then cb2.combatOnlyCB:SetChecked(profile.customBar2OutOfCombat == false) end
    if cb2.gcdCB then cb2.gcdCB:SetChecked(profile.customBar2ShowGCD == true) end
    if cb2.buffOverlayCB then
      profile.customBar2UseBuffOverlay = false
      cb2.buffOverlayCB:SetChecked(false)
      cb2.buffOverlayCB:SetEnabled(false)
      if cb2.buffOverlayCB.label and cb2.buffOverlayCB.label.Hide then cb2.buffOverlayCB.label:Hide() end
      if cb2.buffOverlayCB.Hide then cb2.buffOverlayCB:Hide() end
    end
    if cb2.trackBuffsCB then cb2.trackBuffsCB:SetChecked(profile.customBar2TrackBuffs ~= false) end
    if cb2.openBlizzBuffBtn then cb2.openBlizzBuffBtn:SetShown(profile.customBar2TrackBuffs ~= false) end
    if cb2.centeredCB then cb2.centeredCB:SetChecked(profile.customBar2Centered == true) end
    if cb2.iconSizeSlider then cb2.iconSizeSlider:SetValue(num(profile.customBar2IconSize, 30)); cb2.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBar2IconSize, 30))) end
    if cb2.spacingSlider then cb2.spacingSlider:SetValue(num(profile.customBar2Spacing, 2)); cb2.spacingSlider.valueText:SetText(math.floor(num(profile.customBar2Spacing, 2))) end
    if cb2.cdTextSlider then cb2.cdTextSlider:SetValue(num(profile.customBar2CdTextScale, 1.0)); cb2.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar2CdTextScale, 1.0))) end
    if cb2.cdGradientSlider then local gv = num(profile.customBar2CdGradientThreshold, 0); cb2.cdGradientSlider:SetValue(gv); cb2.cdGradientSlider.valueText:SetText(gv > 0 and math.floor(gv) or "Off") end
    if cb2.cdGradientColorSwatch then cb2.cdGradientColorSwatch:SetBackdropColor(num(profile.customBar2CdGradientR, 1), num(profile.customBar2CdGradientG, 0), num(profile.customBar2CdGradientB, 0), 1); cb2.cdGradientColorSwatch:SetShown(num(profile.customBar2CdGradientThreshold, 0) > 0) end
    if cb2.stackTextSlider then cb2.stackTextSlider:SetValue(num(profile.customBar2StackTextScale, 1.0)); cb2.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar2StackTextScale, 1.0))) end
    if cb2.iconsPerRowSlider then cb2.iconsPerRowSlider:SetValue(num(profile.customBar2IconsPerRow, 20)); cb2.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBar2IconsPerRow, 20))) end
    if cb2.cdModeDD then cb2.cdModeDD:SetValue(profile.customBar2CooldownMode or "show") end
    if cb2.showModeDD then cb2.showModeDD:SetValue(profile.customBar2ShowMode or "always") end
    if cb2.xSlider then cb2.xSlider:SetValue(num(profile.customBar2X, 0)); cb2.xSlider.valueText:SetText(math.floor(num(profile.customBar2X, 0))) end
    if cb2.ySlider then cb2.ySlider:SetValue(num(profile.customBar2Y, -250)); cb2.ySlider.valueText:SetText(math.floor(num(profile.customBar2Y, -250))) end
    if cb2.directionDD then cb2.directionDD:SetValue(profile.customBar2Direction or "horizontal") end
    if cb2.anchorDD then cb2.anchorDD:SetValue(profile.customBar2AnchorPoint or "LEFT") end
	    if cb2.growthDD then cb2.growthDD:SetValue(profile.customBar2Growth or "DOWN") end
	    if cb2.useGlowsCB then cb2.useGlowsCB:SetChecked(profile.customBar2UseSpellGlows == true) end
	    if cb2.customHideRevealCB then cb2.customHideRevealCB:SetChecked(profile.customBar2UseCustomHideReveal == true); cb2.customHideRevealCB:SetEnabled((profile.customBar2CooldownMode or "show") == "hide") end
	    local cb2GlowsEnabled = profile.customBar2UseSpellGlows == true
	    if cb2.glowSpeedSlider then
	      cb2.glowSpeedSlider:SetValue(num(profile.spellGlowSpeed, 0.0))
	      cb2.glowSpeedSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowSpeed, 0.0)))
	      SetStyledSliderShown(cb2.glowSpeedSlider, cb2GlowsEnabled)
	    end
	    if cb2.glowThicknessSlider then
	      cb2.glowThicknessSlider:SetValue(num(profile.spellGlowThickness, 2.0))
	      cb2.glowThicknessSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowThickness, 2.0)))
	      SetStyledSliderShown(cb2.glowThicknessSlider, cb2GlowsEnabled)
	    end
	    if cb2.anchorTargetDD then if addonTable.GetAnchorFrameOptions then cb2.anchorTargetDD:SetOptions(addonTable.GetAnchorFrameOptions(2)) end; cb2.anchorTargetDD:SetValue(profile.customBar2AnchorFrame or "UIParent") end
    if cb2.anchorToPointDD then cb2.anchorToPointDD:SetValue(profile.customBar2AnchorToPoint or "CENTER"); cb2.anchorToPointDD:SetEnabled((profile.customBar2AnchorFrame or "UIParent") ~= "UIParent") end
    if cb2.stackAnchorDD then cb2.stackAnchorDD:SetValue(profile.customBar2StackTextPosition or "BOTTOMRIGHT") end
    if cb2.stackXSlider then cb2.stackXSlider:SetValue(num(profile.customBar2StackTextOffsetX, 0)); cb2.stackXSlider.valueText:SetText(math.floor(num(profile.customBar2StackTextOffsetX, 0))) end
    if cb2.stackYSlider then cb2.stackYSlider:SetValue(num(profile.customBar2StackTextOffsetY, 0)); cb2.stackYSlider.valueText:SetText(math.floor(num(profile.customBar2StackTextOffsetY, 0))) end
  end
  local cb3 = addonTable.cb3
  if cb3 then
    if cb3.combatOnlyCB then cb3.combatOnlyCB:SetChecked(profile.customBar3OutOfCombat == false) end
    if cb3.gcdCB then cb3.gcdCB:SetChecked(profile.customBar3ShowGCD == true) end
    if cb3.buffOverlayCB then
      profile.customBar3UseBuffOverlay = false
      cb3.buffOverlayCB:SetChecked(false)
      cb3.buffOverlayCB:SetEnabled(false)
      if cb3.buffOverlayCB.label and cb3.buffOverlayCB.label.Hide then cb3.buffOverlayCB.label:Hide() end
      if cb3.buffOverlayCB.Hide then cb3.buffOverlayCB:Hide() end
    end
    if cb3.trackBuffsCB then cb3.trackBuffsCB:SetChecked(profile.customBar3TrackBuffs ~= false) end
    if cb3.openBlizzBuffBtn then cb3.openBlizzBuffBtn:SetShown(profile.customBar3TrackBuffs ~= false) end
    if cb3.centeredCB then cb3.centeredCB:SetChecked(profile.customBar3Centered == true) end
    if cb3.iconSizeSlider then cb3.iconSizeSlider:SetValue(num(profile.customBar3IconSize, 30)); cb3.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBar3IconSize, 30))) end
    if cb3.spacingSlider then cb3.spacingSlider:SetValue(num(profile.customBar3Spacing, 2)); cb3.spacingSlider.valueText:SetText(math.floor(num(profile.customBar3Spacing, 2))) end
    if cb3.cdTextSlider then cb3.cdTextSlider:SetValue(num(profile.customBar3CdTextScale, 1.0)); cb3.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar3CdTextScale, 1.0))) end
    if cb3.cdGradientSlider then local gv = num(profile.customBar3CdGradientThreshold, 0); cb3.cdGradientSlider:SetValue(gv); cb3.cdGradientSlider.valueText:SetText(gv > 0 and math.floor(gv) or "Off") end
    if cb3.cdGradientColorSwatch then cb3.cdGradientColorSwatch:SetBackdropColor(num(profile.customBar3CdGradientR, 1), num(profile.customBar3CdGradientG, 0), num(profile.customBar3CdGradientB, 0), 1); cb3.cdGradientColorSwatch:SetShown(num(profile.customBar3CdGradientThreshold, 0) > 0) end
    if cb3.stackTextSlider then cb3.stackTextSlider:SetValue(num(profile.customBar3StackTextScale, 1.0)); cb3.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar3StackTextScale, 1.0))) end
    if cb3.iconsPerRowSlider then cb3.iconsPerRowSlider:SetValue(num(profile.customBar3IconsPerRow, 20)); cb3.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBar3IconsPerRow, 20))) end
    if cb3.cdModeDD then cb3.cdModeDD:SetValue(profile.customBar3CooldownMode or "show") end
    if cb3.showModeDD then cb3.showModeDD:SetValue(profile.customBar3ShowMode or "always") end
    if cb3.xSlider then cb3.xSlider:SetValue(num(profile.customBar3X, 0)); cb3.xSlider.valueText:SetText(math.floor(num(profile.customBar3X, 0))) end
    if cb3.ySlider then cb3.ySlider:SetValue(num(profile.customBar3Y, -300)); cb3.ySlider.valueText:SetText(math.floor(num(profile.customBar3Y, -300))) end
    if cb3.directionDD then cb3.directionDD:SetValue(profile.customBar3Direction or "horizontal") end
    if cb3.anchorDD then cb3.anchorDD:SetValue(profile.customBar3AnchorPoint or "LEFT") end
	    if cb3.growthDD then cb3.growthDD:SetValue(profile.customBar3Growth or "DOWN") end
	    if cb3.useGlowsCB then cb3.useGlowsCB:SetChecked(profile.customBar3UseSpellGlows == true) end
	    if cb3.customHideRevealCB then cb3.customHideRevealCB:SetChecked(profile.customBar3UseCustomHideReveal == true); cb3.customHideRevealCB:SetEnabled((profile.customBar3CooldownMode or "show") == "hide") end
	    local cb3GlowsEnabled = profile.customBar3UseSpellGlows == true
	    if cb3.glowSpeedSlider then
	      cb3.glowSpeedSlider:SetValue(num(profile.spellGlowSpeed, 0.0))
	      cb3.glowSpeedSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowSpeed, 0.0)))
	      SetStyledSliderShown(cb3.glowSpeedSlider, cb3GlowsEnabled)
	    end
	    if cb3.glowThicknessSlider then
	      cb3.glowThicknessSlider:SetValue(num(profile.spellGlowThickness, 2.0))
	      cb3.glowThicknessSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowThickness, 2.0)))
	      SetStyledSliderShown(cb3.glowThicknessSlider, cb3GlowsEnabled)
	    end
	    if cb3.anchorTargetDD then if addonTable.GetAnchorFrameOptions then cb3.anchorTargetDD:SetOptions(addonTable.GetAnchorFrameOptions(3)) end; cb3.anchorTargetDD:SetValue(profile.customBar3AnchorFrame or "UIParent") end
    if cb3.anchorToPointDD then cb3.anchorToPointDD:SetValue(profile.customBar3AnchorToPoint or "CENTER"); cb3.anchorToPointDD:SetEnabled((profile.customBar3AnchorFrame or "UIParent") ~= "UIParent") end
    if cb3.stackAnchorDD then cb3.stackAnchorDD:SetValue(profile.customBar3StackTextPosition or "BOTTOMRIGHT") end
    if cb3.stackXSlider then cb3.stackXSlider:SetValue(num(profile.customBar3StackTextOffsetX, 0)); cb3.stackXSlider.valueText:SetText(math.floor(num(profile.customBar3StackTextOffsetX, 0))) end
    if cb3.stackYSlider then cb3.stackYSlider:SetValue(num(profile.customBar3StackTextOffsetY, 0)); cb3.stackYSlider.valueText:SetText(math.floor(num(profile.customBar3StackTextOffsetY, 0))) end
  end
  local cb4 = addonTable.cb4
  if cb4 then
    if cb4.combatOnlyCB then cb4.combatOnlyCB:SetChecked(profile.customBar4OutOfCombat == false) end
    if cb4.gcdCB then cb4.gcdCB:SetChecked(profile.customBar4ShowGCD == true) end
    if cb4.buffOverlayCB then
      profile.customBar4UseBuffOverlay = false
      cb4.buffOverlayCB:SetChecked(false)
      cb4.buffOverlayCB:SetEnabled(false)
      if cb4.buffOverlayCB.label and cb4.buffOverlayCB.label.Hide then cb4.buffOverlayCB.label:Hide() end
      if cb4.buffOverlayCB.Hide then cb4.buffOverlayCB:Hide() end
    end
    if cb4.trackBuffsCB then cb4.trackBuffsCB:SetChecked(profile.customBar4TrackBuffs ~= false) end
    if cb4.openBlizzBuffBtn then cb4.openBlizzBuffBtn:SetShown(profile.customBar4TrackBuffs ~= false) end
    if cb4.centeredCB then cb4.centeredCB:SetChecked(profile.customBar4Centered == true) end
    if cb4.iconSizeSlider then cb4.iconSizeSlider:SetValue(num(profile.customBar4IconSize, 30)); cb4.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBar4IconSize, 30))) end
    if cb4.spacingSlider then cb4.spacingSlider:SetValue(num(profile.customBar4Spacing, 2)); cb4.spacingSlider.valueText:SetText(math.floor(num(profile.customBar4Spacing, 2))) end
    if cb4.cdTextSlider then cb4.cdTextSlider:SetValue(num(profile.customBar4CdTextScale, 1.0)); cb4.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar4CdTextScale, 1.0))) end
    if cb4.cdGradientSlider then local gv = num(profile.customBar4CdGradientThreshold, 0); cb4.cdGradientSlider:SetValue(gv); cb4.cdGradientSlider.valueText:SetText(gv > 0 and math.floor(gv) or "Off") end
    if cb4.cdGradientColorSwatch then cb4.cdGradientColorSwatch:SetBackdropColor(num(profile.customBar4CdGradientR, 1), num(profile.customBar4CdGradientG, 0), num(profile.customBar4CdGradientB, 0), 1); cb4.cdGradientColorSwatch:SetShown(num(profile.customBar4CdGradientThreshold, 0) > 0) end
    if cb4.stackTextSlider then cb4.stackTextSlider:SetValue(num(profile.customBar4StackTextScale, 1.0)); cb4.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar4StackTextScale, 1.0))) end
    if cb4.iconsPerRowSlider then cb4.iconsPerRowSlider:SetValue(num(profile.customBar4IconsPerRow, 20)); cb4.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBar4IconsPerRow, 20))) end
    if cb4.cdModeDD then cb4.cdModeDD:SetValue(profile.customBar4CooldownMode or "show") end
    if cb4.showModeDD then cb4.showModeDD:SetValue(profile.customBar4ShowMode or "always") end
    if cb4.xSlider then cb4.xSlider:SetValue(num(profile.customBar4X, 0)); cb4.xSlider.valueText:SetText(math.floor(num(profile.customBar4X, 0))) end
    if cb4.ySlider then cb4.ySlider:SetValue(num(profile.customBar4Y, -350)); cb4.ySlider.valueText:SetText(math.floor(num(profile.customBar4Y, -350))) end
    if cb4.directionDD then cb4.directionDD:SetValue(profile.customBar4Direction or "horizontal") end
    if cb4.anchorDD then cb4.anchorDD:SetValue(profile.customBar4AnchorPoint or "LEFT") end
    if cb4.growthDD then cb4.growthDD:SetValue(profile.customBar4Growth or "DOWN") end
    if cb4.useGlowsCB then cb4.useGlowsCB:SetChecked(profile.customBar4UseSpellGlows == true) end
    if cb4.customHideRevealCB then cb4.customHideRevealCB:SetChecked(profile.customBar4UseCustomHideReveal == true); cb4.customHideRevealCB:SetEnabled((profile.customBar4CooldownMode or "show") == "hide") end
    local cb4GlowsEnabled = profile.customBar4UseSpellGlows == true
    if cb4.glowSpeedSlider then
      cb4.glowSpeedSlider:SetValue(num(profile.spellGlowSpeed, 0.0))
      cb4.glowSpeedSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowSpeed, 0.0)))
      SetStyledSliderShown(cb4.glowSpeedSlider, cb4GlowsEnabled)
    end
    if cb4.glowThicknessSlider then
      cb4.glowThicknessSlider:SetValue(num(profile.spellGlowThickness, 2.0))
      cb4.glowThicknessSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowThickness, 2.0)))
      SetStyledSliderShown(cb4.glowThicknessSlider, cb4GlowsEnabled)
    end
    if cb4.anchorTargetDD then if addonTable.GetAnchorFrameOptions then cb4.anchorTargetDD:SetOptions(addonTable.GetAnchorFrameOptions(4)) end; cb4.anchorTargetDD:SetValue(profile.customBar4AnchorFrame or "UIParent") end
    if cb4.anchorToPointDD then cb4.anchorToPointDD:SetValue(profile.customBar4AnchorToPoint or "CENTER"); cb4.anchorToPointDD:SetEnabled((profile.customBar4AnchorFrame or "UIParent") ~= "UIParent") end
    if cb4.stackAnchorDD then cb4.stackAnchorDD:SetValue(profile.customBar4StackTextPosition or "BOTTOMRIGHT") end
    if cb4.stackXSlider then cb4.stackXSlider:SetValue(num(profile.customBar4StackTextOffsetX, 0)); cb4.stackXSlider.valueText:SetText(math.floor(num(profile.customBar4StackTextOffsetX, 0))) end
    if cb4.stackYSlider then cb4.stackYSlider:SetValue(num(profile.customBar4StackTextOffsetY, 0)); cb4.stackYSlider.valueText:SetText(math.floor(num(profile.customBar4StackTextOffsetY, 0))) end
  end
  local cb5 = addonTable.cb5
  if cb5 then
    if cb5.combatOnlyCB then cb5.combatOnlyCB:SetChecked(profile.customBar5OutOfCombat == false) end
    if cb5.gcdCB then cb5.gcdCB:SetChecked(profile.customBar5ShowGCD == true) end
    if cb5.buffOverlayCB then
      profile.customBar5UseBuffOverlay = false
      cb5.buffOverlayCB:SetChecked(false)
      cb5.buffOverlayCB:SetEnabled(false)
      if cb5.buffOverlayCB.label and cb5.buffOverlayCB.label.Hide then cb5.buffOverlayCB.label:Hide() end
      if cb5.buffOverlayCB.Hide then cb5.buffOverlayCB:Hide() end
    end
    if cb5.trackBuffsCB then cb5.trackBuffsCB:SetChecked(profile.customBar5TrackBuffs ~= false) end
    if cb5.openBlizzBuffBtn then cb5.openBlizzBuffBtn:SetShown(profile.customBar5TrackBuffs ~= false) end
    if cb5.centeredCB then cb5.centeredCB:SetChecked(profile.customBar5Centered == true) end
    if cb5.iconSizeSlider then cb5.iconSizeSlider:SetValue(num(profile.customBar5IconSize, 30)); cb5.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBar5IconSize, 30))) end
    if cb5.spacingSlider then cb5.spacingSlider:SetValue(num(profile.customBar5Spacing, 2)); cb5.spacingSlider.valueText:SetText(math.floor(num(profile.customBar5Spacing, 2))) end
    if cb5.cdTextSlider then cb5.cdTextSlider:SetValue(num(profile.customBar5CdTextScale, 1.0)); cb5.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar5CdTextScale, 1.0))) end
    if cb5.cdGradientSlider then local gv = num(profile.customBar5CdGradientThreshold, 0); cb5.cdGradientSlider:SetValue(gv); cb5.cdGradientSlider.valueText:SetText(gv > 0 and math.floor(gv) or "Off") end
    if cb5.cdGradientColorSwatch then cb5.cdGradientColorSwatch:SetBackdropColor(num(profile.customBar5CdGradientR, 1), num(profile.customBar5CdGradientG, 0), num(profile.customBar5CdGradientB, 0), 1); cb5.cdGradientColorSwatch:SetShown(num(profile.customBar5CdGradientThreshold, 0) > 0) end
    if cb5.stackTextSlider then cb5.stackTextSlider:SetValue(num(profile.customBar5StackTextScale, 1.0)); cb5.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar5StackTextScale, 1.0))) end
    if cb5.iconsPerRowSlider then cb5.iconsPerRowSlider:SetValue(num(profile.customBar5IconsPerRow, 20)); cb5.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBar5IconsPerRow, 20))) end
    if cb5.cdModeDD then cb5.cdModeDD:SetValue(profile.customBar5CooldownMode or "show") end
    if cb5.showModeDD then cb5.showModeDD:SetValue(profile.customBar5ShowMode or "always") end
    if cb5.xSlider then cb5.xSlider:SetValue(num(profile.customBar5X, 0)); cb5.xSlider.valueText:SetText(math.floor(num(profile.customBar5X, 0))) end
    if cb5.ySlider then cb5.ySlider:SetValue(num(profile.customBar5Y, -400)); cb5.ySlider.valueText:SetText(math.floor(num(profile.customBar5Y, -400))) end
    if cb5.directionDD then cb5.directionDD:SetValue(profile.customBar5Direction or "horizontal") end
    if cb5.anchorDD then cb5.anchorDD:SetValue(profile.customBar5AnchorPoint or "LEFT") end
    if cb5.growthDD then cb5.growthDD:SetValue(profile.customBar5Growth or "DOWN") end
    if cb5.useGlowsCB then cb5.useGlowsCB:SetChecked(profile.customBar5UseSpellGlows == true) end
    if cb5.customHideRevealCB then cb5.customHideRevealCB:SetChecked(profile.customBar5UseCustomHideReveal == true); cb5.customHideRevealCB:SetEnabled((profile.customBar5CooldownMode or "show") == "hide") end
    local cb5GlowsEnabled = profile.customBar5UseSpellGlows == true
    if cb5.glowSpeedSlider then
      cb5.glowSpeedSlider:SetValue(num(profile.spellGlowSpeed, 0.0))
      cb5.glowSpeedSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowSpeed, 0.0)))
      SetStyledSliderShown(cb5.glowSpeedSlider, cb5GlowsEnabled)
    end
    if cb5.glowThicknessSlider then
      cb5.glowThicknessSlider:SetValue(num(profile.spellGlowThickness, 2.0))
      cb5.glowThicknessSlider.valueText:SetText(string.format("%.1f", num(profile.spellGlowThickness, 2.0)))
      SetStyledSliderShown(cb5.glowThicknessSlider, cb5GlowsEnabled)
    end
    if cb5.anchorTargetDD then if addonTable.GetAnchorFrameOptions then cb5.anchorTargetDD:SetOptions(addonTable.GetAnchorFrameOptions(5)) end; cb5.anchorTargetDD:SetValue(profile.customBar5AnchorFrame or "UIParent") end
    if cb5.anchorToPointDD then cb5.anchorToPointDD:SetValue(profile.customBar5AnchorToPoint or "CENTER"); cb5.anchorToPointDD:SetEnabled((profile.customBar5AnchorFrame or "UIParent") ~= "UIParent") end
    if cb5.stackAnchorDD then cb5.stackAnchorDD:SetValue(profile.customBar5StackTextPosition or "BOTTOMRIGHT") end
    if cb5.stackXSlider then cb5.stackXSlider:SetValue(num(profile.customBar5StackTextOffsetX, 0)); cb5.stackXSlider.valueText:SetText(math.floor(num(profile.customBar5StackTextOffsetX, 0))) end
    if cb5.stackYSlider then cb5.stackYSlider:SetValue(num(profile.customBar5StackTextOffsetY, 0)); cb5.stackYSlider.valueText:SetText(math.floor(num(profile.customBar5StackTextOffsetY, 0))) end
  end
  if addonTable.skinningModeDD then
    local skinMode = "none"
    if profile.enableMasque then skinMode = "masque"
    elseif profile.blizzardBarSkinning ~= false then skinMode = "ccm" end
    addonTable.skinningModeDD:SetValue(skinMode)
  end
  if addonTable.cursorCDMCB then addonTable.cursorCDMCB:SetChecked(profile.cursorIconsEnabled ~= false); addonTable.cursorCDMCB:SetEnabled(true) end
  if IsModuleEnabled("custombars") then
    local count = math.floor(num(profile.customBarsCount, 0))
    if count < 1 then
      count = 1
      profile.customBarsCount = 1
    end
    profile.customBarEnabled = (count >= 1)
    profile.customBar2Enabled = (count >= 2)
    profile.customBar3Enabled = (count >= 3)
    profile.customBar4Enabled = (count >= 4)
    profile.customBar5Enabled = (count >= 5)
  end
  if IsModuleEnabled("blizzcdm") and profile.disableBlizzCDM == true then
    profile.disableBlizzCDM = false
  end
  if IsModuleEnabled("prb") and profile.usePersonalResourceBar ~= true then
    profile.usePersonalResourceBar = true
  end
  if IsModuleEnabled("castbars") and profile.useCastbar ~= true then
    profile.useCastbar = true
  end
  if IsModuleEnabled("debuffs") and profile.enablePlayerDebuffs ~= true then
    profile.enablePlayerDebuffs = true
  end
  if addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(IsModuleEnabled("blizzcdm")) end
  if addonTable.buffBarCB then addonTable.buffBarCB:SetChecked(profile.useBuffBar == true) end
  if addonTable.essentialBarCB then addonTable.essentialBarCB:SetChecked(profile.useEssentialBar == true) end
  if addonTable.buffSizeSlider then addonTable.buffSizeSlider:SetValue(num(profile.buffBarIconSizeOffset, 0)); addonTable.buffSizeSlider.valueText:SetText(math.floor(num(profile.buffBarIconSizeOffset, 0))) end
  local sa = addonTable.standalone
  if sa then
    if sa.skinBuffCB then sa.skinBuffCB:SetChecked(profile.standaloneSkinBuff == true) end
    if sa.skinEssentialCB then sa.skinEssentialCB:SetChecked(profile.standaloneSkinEssential == true) end
    if sa.skinUtilityCB then sa.skinUtilityCB:SetChecked(profile.standaloneSkinUtility == true) end
    if sa.buffCenteredCB then sa.buffCenteredCB:SetChecked(profile.standaloneBuffCentered == true) end
    if sa.essentialCenteredCB then sa.essentialCenteredCB:SetChecked(profile.standaloneEssentialCentered == true) end
    if sa.utilityCenteredCB then sa.utilityCenteredCB:SetChecked(profile.standaloneUtilityCentered == true) end
    if sa.hideGlowsCB then sa.hideGlowsCB:SetChecked(profile.hideBlizzCDMGlows == true) end
    if sa.spacingSlider then sa.spacingSlider:SetValue(num(profile.standaloneSpacing, 0)); sa.spacingSlider.valueText:SetText(math.floor(num(profile.standaloneSpacing, 0))) end
    if sa.borderSizeSlider then sa.borderSizeSlider:SetValue(num(profile.standaloneIconBorderSize, 1)); sa.borderSizeSlider.valueText:SetText(math.floor(num(profile.standaloneIconBorderSize, 1))) end
    if sa.cdTextScaleSlider then sa.cdTextScaleSlider:SetValue(num(profile.standaloneCdTextScale, 1.0)); sa.cdTextScaleSlider.valueText:SetText(string.format("%.1f", num(profile.standaloneCdTextScale, 1.0))) end
    if sa.buffSizeSlider then sa.buffSizeSlider:SetValue(num(profile.standaloneBuffSize, 45)); sa.buffSizeSlider.valueText:SetText(num(profile.standaloneBuffSize, 45)) end
    if sa.buffCdTextSlider then sa.buffCdTextSlider:SetValue(num(profile.standaloneBuffCdTextScale, 1.0)); sa.buffCdTextSlider.valueText:SetText(string.format("%.1f", num(profile.standaloneBuffCdTextScale, 1.0))) end
    if sa.buffYSlider then local yVal = profile.blizzBarBuffY or profile.standaloneBuffY or 0; local n = RoundToHalf(num(yVal, 0)); sa.buffYSlider:SetValue(n); sa.buffYSlider.valueText:SetText(FormatHalf(n)) end
    if sa.buffXSlider then local xVal = profile.blizzBarBuffX or -150; local n = RoundToHalf(num(xVal, -150)); sa.buffXSlider:SetValue(n); sa.buffXSlider.valueText:SetText(FormatHalf(n)) end
    if sa.buffIconsPerRowSlider then sa.buffIconsPerRowSlider:SetValue(num(profile.standaloneBuffIconsPerRow, 0)); sa.buffIconsPerRowSlider.valueText:SetText(math.floor(num(profile.standaloneBuffIconsPerRow, 0))) end
    if sa.buffRowsDD then sa.buffRowsDD:SetValue(tostring(math.max(1, math.min(2, math.floor(num(profile.standaloneBuffMaxRows, 2)))))) end
    if sa.buffGrowDD then sa.buffGrowDD:SetValue(profile.standaloneBuffGrowDirection or "right") end
    if sa.buffRowGrowDD then sa.buffRowGrowDD:SetValue(profile.standaloneBuffRowGrowDirection or "down") end
    if sa.essentialSizeSlider then sa.essentialSizeSlider:SetValue(num(profile.standaloneEssentialSize, 45)); sa.essentialSizeSlider.valueText:SetText(num(profile.standaloneEssentialSize, 45)) end
    if sa.essentialSecondRowSizeSlider then sa.essentialSecondRowSizeSlider:SetValue(num(profile.standaloneEssentialSecondRowSize, num(profile.standaloneEssentialSize, 45))); sa.essentialSecondRowSizeSlider.valueText:SetText(num(profile.standaloneEssentialSecondRowSize, num(profile.standaloneEssentialSize, 45))) end
    if sa.essentialCdTextSlider then sa.essentialCdTextSlider:SetValue(num(profile.standaloneEssentialCdTextScale, 1.0)); sa.essentialCdTextSlider.valueText:SetText(string.format("%.1f", num(profile.standaloneEssentialCdTextScale, 1.0))) end
    if sa.essentialIconsPerRowSlider then sa.essentialIconsPerRowSlider:SetValue(num(profile.standaloneEssentialIconsPerRow, 0)); sa.essentialIconsPerRowSlider.valueText:SetText(math.floor(num(profile.standaloneEssentialIconsPerRow, 0))) end
    if sa.essentialRowsDD then sa.essentialRowsDD:SetValue(tostring(math.max(1, math.min(2, math.floor(num(profile.standaloneEssentialMaxRows, 2)))))) end
    if sa.essentialGrowDD then sa.essentialGrowDD:SetValue(profile.standaloneEssentialGrowDirection or "right") end
    if sa.essentialRowGrowDD then sa.essentialRowGrowDD:SetValue(profile.standaloneEssentialRowGrowDirection or "down") end
    if sa.essentialYSlider then local yVal = profile.blizzBarEssentialY or profile.standaloneEssentialY or 50; local n = RoundToHalf(num(yVal, 50)); sa.essentialYSlider:SetValue(n); sa.essentialYSlider.valueText:SetText(FormatHalf(n)) end
    if sa.essentialXSlider then local xVal = profile.blizzBarEssentialX or 0; local n = RoundToHalf(num(xVal, 0)); sa.essentialXSlider:SetValue(n); sa.essentialXSlider.valueText:SetText(FormatHalf(n)) end
    if sa.utilitySizeSlider then sa.utilitySizeSlider:SetValue(num(profile.standaloneUtilitySize, 45)); sa.utilitySizeSlider.valueText:SetText(num(profile.standaloneUtilitySize, 45)) end
    if sa.utilityCdTextSlider then sa.utilityCdTextSlider:SetValue(num(profile.standaloneUtilityCdTextScale, 1.0)); sa.utilityCdTextSlider.valueText:SetText(string.format("%.1f", num(profile.standaloneUtilityCdTextScale, 1.0))) end
    if sa.utilityIconsPerRowSlider then sa.utilityIconsPerRowSlider:SetValue(num(profile.standaloneUtilityIconsPerRow, 0)); sa.utilityIconsPerRowSlider.valueText:SetText(math.floor(num(profile.standaloneUtilityIconsPerRow, 0))) end
    if sa.utilityRowsDD then sa.utilityRowsDD:SetValue(tostring(math.max(1, math.min(2, math.floor(num(profile.standaloneUtilityMaxRows, 2)))))) end
    if sa.utilityGrowDD then sa.utilityGrowDD:SetValue(profile.standaloneUtilityGrowDirection or "right") end
    if sa.utilityRowGrowDD then sa.utilityRowGrowDD:SetValue(profile.standaloneUtilityRowGrowDirection or "down") end
    if sa.utilityAutoWidthDD then sa.utilityAutoWidthDD:SetValue(profile.standaloneUtilityAutoWidth or "off") end
    if sa.utilityYSlider then local yVal = profile.blizzBarUtilityY or profile.standaloneUtilityY or -50; local n = RoundToHalf(num(yVal, -50)); sa.utilityYSlider:SetValue(n); sa.utilityYSlider.valueText:SetText(FormatHalf(n)) end
    if sa.utilityXSlider then local xVal = profile.blizzBarUtilityX or 150; local n = RoundToHalf(num(xVal, 150)); sa.utilityXSlider:SetValue(n); sa.utilityXSlider.valueText:SetText(FormatHalf(n)) end
  end
  if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
  if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
  SyncModuleControlsState()
  if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
  NormalizeGlobalFontSelection(profile)
  RefreshCursorSpellList()
  RefreshCB1SpellList()
  RefreshCB2SpellList()
  RefreshCB3SpellList()
  RefreshCB4SpellList()
  RefreshCB5SpellList()
  if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
end
local function UpdateProfileDisplay()
  if CooldownCursorManagerDB and CooldownCursorManagerDB.currentProfile and addonTable.profileText then
    addonTable.profileText:SetText(CooldownCursorManagerDB.currentProfile)
  end
end
local function UpdateProfileList()
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then return end
  local profileDropdown = addonTable.profileDropdown
  local profileList = addonTable.profileList
  local profileText = addonTable.profileText
  if not profileDropdown or not profileList then return end
  profileDropdown:SetScript("OnMouseDown", function()
    if profileList:IsShown() then profileList:Hide() return end
    for _, child in ipairs({profileList:GetChildren()}) do child:Hide() end
    local yOff = 0
    local _, playerClass = UnitClass("player")
    local profileClasses = CooldownCursorManagerDB.profileClasses or {}
    local function CreateProfileButton(name)
      local btn = CreateFrame("Button", nil, profileList, "BackdropTemplate")
      btn:SetSize(108, 22)
      btn:SetPoint("TOPLEFT", profileList, "TOPLEFT", 1, -yOff - 1)
      local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
      btnText:SetText(name)
      if name == CooldownCursorManagerDB.currentProfile then btnText:SetTextColor(1, 0.82, 0) else btnText:SetTextColor(0.9, 0.9, 0.9) end
      btn:SetScript("OnEnter", function() btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"}); btn:SetBackdropColor(0.25, 0.25, 0.3, 1) end)
      btn:SetScript("OnLeave", function() btn:SetBackdrop(nil) end)
      btn:SetScript("OnClick", function()
        CooldownCursorManagerDB.currentProfile = name
        if addonTable.SaveCurrentProfileForSpec then
          addonTable.SaveCurrentProfileForSpec()
        else
          local playerName = UnitName("player")
          local realmName = GetRealmName()
          if playerName and realmName then
            local characterKey = playerName .. "-" .. realmName
            CooldownCursorManagerDB.characterProfiles = CooldownCursorManagerDB.characterProfiles or {}
            CooldownCursorManagerDB.characterProfiles[characterKey] = name
          end
        end
        profileText:SetText(name)
        profileList:Hide()
        UpdateAllControls()
        CreateIcons()
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
        if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
        ShowReloadPrompt("Profile switched to '" .. name .. "'.\n\nA UI reload is recommended for all changes to take effect. Reload now?", "Reload", "Later")
      end)
      yOff = yOff + 22
    end
    local sharedProfiles = {}
    local classProfiles = {}
    for name in pairs(CooldownCursorManagerDB.profiles) do
      local profClass = profileClasses[name]
      if name == "Default" or profClass == nil then
        table.insert(sharedProfiles, name)
      elseif profClass == playerClass then
        table.insert(classProfiles, name)
      end
    end
    table.sort(sharedProfiles)
    table.sort(classProfiles)
    for _, name in ipairs(sharedProfiles) do
      CreateProfileButton(name)
    end
    if #classProfiles > 0 then
      local sep = profileList:CreateTexture(nil, "ARTWORK")
      sep:SetHeight(1)
      sep:SetPoint("TOPLEFT", profileList, "TOPLEFT", 4, -yOff - 4)
      sep:SetPoint("TOPRIGHT", profileList, "TOPRIGHT", -4, -yOff - 4)
      sep:SetColorTexture(1, 0.82, 0, 1)
      yOff = yOff + 8
      for _, name in ipairs(classProfiles) do
        CreateProfileButton(name)
      end
    end
    profileList:SetHeight(yOff + 2)
    profileList:SetFrameLevel(math.max((profileDropdown:GetFrameLevel() or 1) + 200, 2000))
    profileList:Show()
  end)
end
addonTable.UpdateAllControls = UpdateAllControls
addonTable.UpdateProfileDisplay = UpdateProfileDisplay
addonTable.UpdateProfileList = UpdateProfileList
local function InitHandlers()
  local tabFrames = addonTable.tabFrames
  local function RecreateAllIcons()
    CreateIcons()
    if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
    if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
    if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
    if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
    if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
    if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
    if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
    if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
    if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
    if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
    if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
    if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
  end
  local function ApplyUIScale(scale)
    SetCVar("uiScale", scale)
    UIParent:SetScale(scale)
  end
  local function UpdateSliderEnabled(mode)
    if addonTable.uiScaleSlider then
      if mode == "custom" then
        addonTable.uiScaleSlider:Enable()
        addonTable.uiScaleSlider:SetAlpha(1)
      else
        addonTable.uiScaleSlider:Disable()
        addonTable.uiScaleSlider:SetAlpha(0.5)
      end
    end
  end
  if addonTable.uiScaleDD then
    addonTable.uiScaleDD.onSelect = function(v)
      local p = GetProfile()
      if not p then return end
      p.uiScaleMode = v
      UpdateSliderEnabled(v)
      if v == "disabled" then
        ShowReloadPrompt("UI Scale disabled. A reload is recommended to restore WoW defaults.", "Reload Now", "Later")
        return
      end
      local scale
      if v == "1080p" then
        scale = 0.71111
        if addonTable.uiScaleSlider then
          addonTable.uiScaleSlider:SetValue(scale)
          addonTable.uiScaleSlider.valueText:SetText(string.format("%.2f", scale))
        end
      elseif v == "1440p" then
        scale = 0.53333
        if addonTable.uiScaleSlider then
          addonTable.uiScaleSlider:SetValue(scale)
          addonTable.uiScaleSlider.valueText:SetText(string.format("%.2f", scale))
        end
      else
        scale = addonTable.uiScaleSlider and addonTable.uiScaleSlider:GetValue() or 0.71
      end
      p.uiScale = scale
      ApplyUIScale(scale)
      print("|cff00ff00CCM:|r UI Scale set to " .. string.format("%.2f", scale))
    end
  end
  if addonTable.uiScaleSlider then
    addonTable.uiScaleSlider:SetScript("OnValueChanged", function(s, v)
      if s._updating then return end
      local p = GetProfile()
      if p then
        local scale = math.floor(v * 100 + 0.5) / 100
        s.valueText:SetText(string.format("%.2f", scale))
        local currentMode = p.uiScaleMode or "disabled"
        if currentMode == "disabled" then return end
        p.uiScale = scale
        if addonTable.uiScaleDD then
          if currentMode ~= "custom" then
            if math.abs(scale - 0.71111) < 0.01 then
              p.uiScaleMode = "1080p"
              addonTable.uiScaleDD:SetValue("1080p")
            elseif math.abs(scale - 0.53333) < 0.01 then
              p.uiScaleMode = "1440p"
              addonTable.uiScaleDD:SetValue("1440p")
            else
              p.uiScaleMode = "custom"
              addonTable.uiScaleDD:SetValue("custom")
            end
          end
        end
      end
    end)
    addonTable.uiScaleSlider:SetScript("OnMouseUp", function()
      local p = GetProfile()
      if p and p.uiScale then
        ApplyUIScale(p.uiScale)
        print("|cff00ff00CCM:|r UI Scale set to " .. string.format("%.2f", p.uiScale))
      end
    end)
  end
  if addonTable.customBarsCountSlider then
    addonTable.customBarsCountSlider:SetScript("OnValueChanged", function(s, v)
      if s._updating then return end
      if not IsModuleEnabled("custombars") then
        s._updating = true
        s:SetValue(0)
        s._updating = false
        s.valueText:SetText("0")
        return
      end
      local p = GetProfile()
      if p then
        local count = math.floor((tonumber(v) or 0) + 0.5)
        if count < 0 then count = 0 end
        if count > 5 then count = 5 end
        if p.customBarsCount == count then
          s.valueText:SetText(count)
          return
        end
        s._updating = true
        s:SetValue(count)
        s._updating = false
        s.valueText:SetText(count)
        p.customBarsCount = count
        local wasBar1Enabled = p.customBarEnabled
        local wasBar2Enabled = p.customBar2Enabled
        local wasBar3Enabled = p.customBar3Enabled
        local wasBar4Enabled = p.customBar4Enabled
        local wasBar5Enabled = p.customBar5Enabled
        p.customBarEnabled = (count >= 1)
        p.customBar2Enabled = (count >= 2)
        p.customBar3Enabled = (count >= 3)
        p.customBar4Enabled = (count >= 4)
        p.customBar5Enabled = (count >= 5)
        if p.customBarEnabled and not wasBar1Enabled then
          if p.customBarCentered == nil then p.customBarCentered = true end
          if p.customBarX == nil then p.customBarX = 0 end
        end
        if p.customBar2Enabled and not wasBar2Enabled then
          if p.customBar2Centered == nil then p.customBar2Centered = true end
          if p.customBar2X == nil then p.customBar2X = 0 end
        end
        if p.customBar3Enabled and not wasBar3Enabled then
          if p.customBar3Centered == nil then p.customBar3Centered = true end
          if p.customBar3X == nil then p.customBar3X = 0 end
        end
        if p.customBar4Enabled and not wasBar4Enabled then
          if p.customBar4Centered == nil then p.customBar4Centered = true end
          if p.customBar4X == nil then p.customBar4X = 0 end
        end
        if p.customBar5Enabled and not wasBar5Enabled then
          if p.customBar5Centered == nil then p.customBar5Centered = true end
          if p.customBar5X == nil then p.customBar5X = 0 end
        end
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
        if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
        if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end
        if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end
        if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end
        if addonTable.UpdateCustomBar4Position then addonTable.UpdateCustomBar4Position() end
        if addonTable.UpdateCustomBar5Position then addonTable.UpdateCustomBar5Position() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
        if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      end
    end)
  end
  if addonTable.installWizardBtn then
    addonTable.installWizardBtn:SetScript("OnClick", function()
      if InCombatLockdown() then
        print("|cff00ff00CCM:|r Cannot open installer during combat.")
        return
      end
      if addonTable.OpenInstallWizard then
        addonTable.OpenInstallWizard()
      end
    end)
  end
  if addonTable.iconBorderSlider then
    addonTable.iconBorderSlider:SetScript("OnValueChanged", function(s, v)
      local p = GetProfile()
      if p then
        p.iconBorderSize = math.floor(v)
        s.valueText:SetText(math.floor(v))
        RecreateAllIcons()
        if p.hideActionBarBorders and addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end
      end
    end)
  end
  if addonTable.strataDD then
    addonTable.strataDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.iconStrata = v
        RecreateAllIcons()
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
        if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
      end
    end
  end
  if addonTable.fontDD then
    addonTable.fontDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        if type(v) ~= "string" or v:sub(1, 4) ~= "lsm:" then
          return
        end
        p.cdFont = v
        p.globalFont = v
        RecreateAllIcons()
        if addonTable.UpdatePRBFonts then addonTable.UpdatePRBFonts() end
        if addonTable.UpdatePRB then addonTable.UpdatePRB() end
        if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
        if addonTable.UpdateFocusCastbar then addonTable.UpdateFocusCastbar() end
        if addonTable.UpdateTargetCastbar then addonTable.UpdateTargetCastbar() end
        if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end
        if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if addonTable.MarkSkyridingFontDirty then addonTable.MarkSkyridingFontDirty() end
        if addonTable.ApplySkyridingFonts then addonTable.ApplySkyridingFonts() end
      end
    end
  end
  if addonTable.outlineDD then
    addonTable.outlineDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.globalOutline = v
        RecreateAllIcons()
        if addonTable.UpdatePRBFonts then addonTable.UpdatePRBFonts() end
        if addonTable.UpdatePRB then addonTable.UpdatePRB() end
        if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
        if addonTable.UpdateFocusCastbar then addonTable.UpdateFocusCastbar() end
        if addonTable.UpdateTargetCastbar then addonTable.UpdateTargetCastbar() end
        if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end
        if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if addonTable.MarkSkyridingFontDirty then addonTable.MarkSkyridingFontDirty() end
        if addonTable.ApplySkyridingFonts then addonTable.ApplySkyridingFonts() end
      end
    end
  end
  if addonTable.audioChannelDD then
    addonTable.audioChannelDD.onSelect = function(v)
      local p = GetProfile()
      if p then p.audioChannel = v end
    end
  end
  if addonTable.actionBar1ModeDD then
    addonTable.actionBar1ModeDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.actionBarGlobalMode = "custom"
        if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
        SetABModeDropdownsEnabled(true)
        ApplyABModeToProfile(p, "hideActionBar1InCombat", "hideActionBar1Mouseover", "hideActionBar1Always", v)
        if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
      end
    end
  end
  if addonTable.actionBarGlobalModeDD then
    addonTable.actionBarGlobalModeDD.onSelect = function(v)
      local p = GetProfile()
      if not p then return end
      p.actionBarGlobalMode = v or "custom"
      if v == "custom" then
        SetABModeDropdownsEnabled(true)
      elseif v == "off" then
        ApplyABModeToAllBars(p, "off")
        SetABModeDropdownsEnabled(false)
      else
        ApplyABModeToAllBars(p, v)
        SetABModeDropdownsEnabled(true)
      end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
    end
  end
  for n = 2, 8 do
    local dd = addonTable["actionBar"..n.."ModeDD"]
    if dd then
      dd.onSelect = function(v)
        local p = GetProfile()
        if p then
          p.actionBarGlobalMode = "custom"
          if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
          SetABModeDropdownsEnabled(true)
          ApplyABModeToProfile(p, "hideAB"..n.."InCombat", "hideAB"..n.."Mouseover", "hideAB"..n.."Always", v)
          if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
        end
      end
    end
  end
  if addonTable.stanceBarModeDD then
    addonTable.stanceBarModeDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.actionBarGlobalMode = "custom"
        if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
        SetABModeDropdownsEnabled(true)
        ApplyABModeToProfile(p, "hideStanceBarInCombat", "hideStanceBarMouseover", "hideStanceBarAlways", v)
        if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
      end
    end
  end
  if addonTable.petBarModeDD then
    addonTable.petBarModeDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.actionBarGlobalMode = "custom"
        if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
        SetABModeDropdownsEnabled(true)
        ApplyABModeToProfile(p, "hidePetBarInCombat", "hidePetBarMouseover", "hidePetBarAlways", v)
        if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
      end
    end
  end
  if addonTable.hideAB1CB then addonTable.hideAB1CB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBar1InCombat = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideAB1MouseoverCB then addonTable.hideAB1MouseoverCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBar1Mouseover = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideAB1AlwaysCB then addonTable.hideAB1AlwaysCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBar1Always = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  for n = 2, 8 do
    if addonTable["hideAB"..n.."CB"] then addonTable["hideAB"..n.."CB"].customOnClick = function(s) local p = GetProfile(); if p then p["hideAB"..n.."InCombat"] = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
    if addonTable["hideAB"..n.."MouseoverCB"] then addonTable["hideAB"..n.."MouseoverCB"].customOnClick = function(s) local p = GetProfile(); if p then p["hideAB"..n.."Mouseover"] = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
    if addonTable["hideAB"..n.."AlwaysCB"] then addonTable["hideAB"..n.."AlwaysCB"].customOnClick = function(s) local p = GetProfile(); if p then p["hideAB"..n.."Always"] = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  end
  if addonTable.hideStanceBarCB then addonTable.hideStanceBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideStanceBarInCombat = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideStanceBarMouseoverCB then addonTable.hideStanceBarMouseoverCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideStanceBarMouseover = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideStanceBarAlwaysCB then addonTable.hideStanceBarAlwaysCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideStanceBarAlways = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hidePetBarCB then addonTable.hidePetBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.hidePetBarInCombat = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hidePetBarMouseoverCB then addonTable.hidePetBarMouseoverCB.customOnClick = function(s) local p = GetProfile(); if p then p.hidePetBarMouseover = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hidePetBarAlwaysCB then addonTable.hidePetBarAlwaysCB.customOnClick = function(s) local p = GetProfile(); if p then p.hidePetBarAlways = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.fadeMicroMenuCB then addonTable.fadeMicroMenuCB.customOnClick = function(s) local p = GetProfile(); if p then p.fadeMicroMenu = s:GetChecked(); if addonTable.SetupFadeMicroMenu then addonTable.SetupFadeMicroMenu() end end end end
  if addonTable.hideABBordersCB then addonTable.hideABBordersCB.customOnClick = function(s) local p = GetProfile(); if p then local was = p.hideActionBarBorders; p.hideActionBarBorders = s:GetChecked(); if addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end; if was and not s:GetChecked() then ShowReloadPrompt("Disabling Action Bar Skinning requires a UI reload for best results. Reload now?", "Reload", "Later") end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end end end end
  if addonTable.hideABGlowsCB then addonTable.hideABGlowsCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBarGlows = s:GetChecked(); if addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end end end end
  if addonTable.abSkinSpacingSlider then addonTable.abSkinSpacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.abSkinSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end end end) end
  if addonTable.fadeObjectiveTrackerCB then addonTable.fadeObjectiveTrackerCB.customOnClick = function(s) local p = GetProfile(); if p then p.fadeObjectiveTracker = s:GetChecked(); if addonTable.SetupFadeObjectiveTracker then addonTable.SetupFadeObjectiveTracker() end end end end
  if addonTable.fadeBagBarCB then addonTable.fadeBagBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.fadeBagBar = s:GetChecked(); if addonTable.SetupFadeBagBar then addonTable.SetupFadeBagBar() end end end end
  if addonTable.betterItemLevelCB then addonTable.betterItemLevelCB.customOnClick = function(s) local p = GetProfile(); if p then p.betterItemLevel = s:GetChecked(); if addonTable.SetupBetterItemLevel then addonTable.SetupBetterItemLevel() end end end end
  if addonTable.showEquipDetailsCB then addonTable.showEquipDetailsCB.customOnClick = function(s) local p = GetProfile(); if p then p.showEquipmentDetails = s:GetChecked(); if addonTable.SetupEquipmentDetails then addonTable.SetupEquipmentDetails() end end end end
  if addonTable.chatClassColorCB then addonTable.chatClassColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatClassColorNames = s:GetChecked() end; if addonTable.SetupChatClassColorNames then addonTable.SetupChatClassColorNames() end end end
  if addonTable.chatTimestampsCB then addonTable.chatTimestampsCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatTimestamps = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatTimestamps then addonTable.SetupChatTimestamps() end end end
  if addonTable.chatTimestampFormatDD then addonTable.chatTimestampFormatDD.onSelect = function(v) local p = GetProfile(); if p then p.chatTimestampFormat = v end; if addonTable.SetupChatTimestamps then addonTable.SetupChatTimestamps() end end end
  if addonTable.chatCopyButtonCB then addonTable.chatCopyButtonCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatCopyButton = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatCopyButton then addonTable.SetupChatCopyButton() end end end
  if addonTable.chatCopyButtonCornerDD then addonTable.chatCopyButtonCornerDD.onSelect = function(v) local p = GetProfile(); if p then p.chatCopyButtonCorner = v end; if addonTable.SetupChatCopyButton then addonTable.SetupChatCopyButton() end end end
  if addonTable.chatUrlDetectionCB then addonTable.chatUrlDetectionCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatUrlDetection = s:GetChecked() end; if addonTable.SetupChatUrlDetection then addonTable.SetupChatUrlDetection() end end end
  if addonTable.chatBackgroundCB then addonTable.chatBackgroundCB.customOnClick = function(s) local p = GetProfile(); if p then local was = p.chatBackground; p.chatBackground = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPrompt("Disabling Chat Background requires a UI reload for best results. Reload now?", "Reload", "Later") end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end; if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end end end
  if addonTable.chatBgAlphaSlider then addonTable.chatBgAlphaSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.chatBackgroundAlpha = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end; if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end end end) end
  if addonTable.chatBgColorBtn then
    addonTable.chatBgColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.chatBackgroundColorR or 0
      local g = p.chatBackgroundColorG or 0
      local b = p.chatBackgroundColorB or 0
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.chatBackgroundColorR = nr
        p.chatBackgroundColorG = ng
        p.chatBackgroundColorB = nb
        if addonTable.chatBgColorSwatch then addonTable.chatBgColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end
        if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end
      end
      local function OnCancel(prev)
        p.chatBackgroundColorR = prev.r
        p.chatBackgroundColorG = prev.g
        p.chatBackgroundColorB = prev.b
        if addonTable.chatBgColorSwatch then addonTable.chatBgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end
        if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end
      end
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.chatHideButtonsCB then addonTable.chatHideButtonsCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatHideButtons = s:GetChecked() end; if addonTable.SetupChatHideButtons then addonTable.SetupChatHideButtons() end end end
  if addonTable.chatFadeToggleCB then addonTable.chatFadeToggleCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatFadeToggle = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatFade then addonTable.SetupChatFade() end end end
  if addonTable.chatFadeDelaySlider then addonTable.chatFadeDelaySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.chatFadeDelay = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.SetupChatFade then addonTable.SetupChatFade() end end end) end
  if addonTable.chatEditBoxDD then addonTable.chatEditBoxDD.onSelect = function(v) local p = GetProfile(); if p then p.chatEditBoxPosition = v end; if addonTable.SetupChatEditBoxPosition then addonTable.SetupChatEditBoxPosition() end end end
  if addonTable.chatEditBoxStyledCB then addonTable.chatEditBoxStyledCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatEditBoxStyled = s:GetChecked() end; if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end end end
  if addonTable.chatTabFlashCB then addonTable.chatTabFlashCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatTabFlash = s:GetChecked() end end end
  if addonTable.chatHideTabsDD then addonTable.chatHideTabsDD.onSelect = function(v) local p = GetProfile(); if p then p.chatHideTabs = v end; if addonTable.SetupChatHideTabs then addonTable.SetupChatHideTabs() end end end
  if addonTable.skyridingEnabledCB then addonTable.skyridingEnabledCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingEnabled = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingHideCDMCB then addonTable.skyridingHideCDMCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingHideCDM = s:GetChecked() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingVigorBarCB then addonTable.skyridingVigorBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingVigorBar = s:GetChecked() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingCooldownsCB then addonTable.skyridingCooldownsCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingCooldowns = s:GetChecked() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingScreenFxCB then addonTable.skyridingScreenFxCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingScreenFx = s:GetChecked() end; if C_CVar then C_CVar.SetCVar("DisableAdvancedFlyingFullScreenEffects", s:GetChecked() and "0" or "1") end; ShowReloadPrompt("Screen Effects change requires a UI reload to take effect. Reload now?", "Reload", "Later") end end
  if addonTable.skyridingSpeedFxCB then addonTable.skyridingSpeedFxCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingSpeedFx = s:GetChecked() end; if C_CVar then C_CVar.SetCVar("DisableAdvancedFlyingVelocityVFX", s:GetChecked() and "0" or "1") end; ShowReloadPrompt("Speed Effects change requires a UI reload to take effect. Reload now?", "Reload", "Later") end end
  if addonTable.skyridingPreviewOnBtn then
    addonTable.skyridingPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowSkyridingPreview then addonTable.ShowSkyridingPreview() end
      SetButtonHighlighted(addonTable.skyridingPreviewOnBtn, true)
    end)
  end
  if addonTable.skyridingPreviewOffBtn then
    addonTable.skyridingPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopSkyridingPreview then addonTable.StopSkyridingPreview() end
      SetButtonHighlighted(addonTable.skyridingPreviewOnBtn, false)
    end)
  end
  if addonTable.skyridingTextureDD then addonTable.skyridingTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.skyridingTexture = v end; if addonTable.InvalidateSkyridingTexture then addonTable.InvalidateSkyridingTexture() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end end end
  if addonTable.skyridingScaleSlider then addonTable.skyridingScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.skyridingScale = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end) end
  if addonTable.skyridingCenteredCB then addonTable.skyridingCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingCentered = s:GetChecked(); if s:GetChecked() then p.skyridingX = 0 end end; local cen = s:GetChecked(); if addonTable.skyridingXSlider then addonTable.skyridingXSlider:SetEnabled(not cen); addonTable.skyridingXSlider:SetAlpha(cen and 0.4 or 1); if cen then addonTable.skyridingXSlider:SetValue(0); addonTable.skyridingXSlider.valueText:SetText("0") end end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingXSlider then addonTable.skyridingXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.skyridingX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end) end
  if addonTable.skyridingYSlider then addonTable.skyridingYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.skyridingY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end) end
  if addonTable.skyridingVigorColorBtn then
    addonTable.skyridingVigorColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingVigorColorR or 0.2, p.skyridingVigorColorG or 0.8, p.skyridingVigorColorB or 0.2
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingVigorColorR = nr; p.skyridingVigorColorG = ng; p.skyridingVigorColorB = nb
        if addonTable.skyridingVigorColorSwatch then addonTable.skyridingVigorColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingVigorColorR = prev.r; p.skyridingVigorColorG = prev.g; p.skyridingVigorColorB = prev.b
        if addonTable.skyridingVigorColorSwatch then addonTable.skyridingVigorColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingEmptyColorBtn then
    addonTable.skyridingEmptyColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingVigorEmptyColorR or 0.15, p.skyridingVigorEmptyColorG or 0.15, p.skyridingVigorEmptyColorB or 0.15
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingVigorEmptyColorR = nr; p.skyridingVigorEmptyColorG = ng; p.skyridingVigorEmptyColorB = nb
        if addonTable.skyridingEmptyColorSwatch then addonTable.skyridingEmptyColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingVigorEmptyColorR = prev.r; p.skyridingVigorEmptyColorG = prev.g; p.skyridingVigorEmptyColorB = prev.b
        if addonTable.skyridingEmptyColorSwatch then addonTable.skyridingEmptyColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingRechargeColorBtn then
    addonTable.skyridingRechargeColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingVigorRechargeColorR or 0.85, p.skyridingVigorRechargeColorG or 0.65, p.skyridingVigorRechargeColorB or 0.1
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingVigorRechargeColorR = nr; p.skyridingVigorRechargeColorG = ng; p.skyridingVigorRechargeColorB = nb
        if addonTable.skyridingRechargeColorSwatch then addonTable.skyridingRechargeColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingVigorRechargeColorR = prev.r; p.skyridingVigorRechargeColorG = prev.g; p.skyridingVigorRechargeColorB = prev.b
        if addonTable.skyridingRechargeColorSwatch then addonTable.skyridingRechargeColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end

  if addonTable.skyridingSurgeColorBtn then
    addonTable.skyridingSurgeColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingWhirlingSurgeColorR or 0.85, p.skyridingWhirlingSurgeColorG or 0.65, p.skyridingWhirlingSurgeColorB or 0.1
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingWhirlingSurgeColorR = nr; p.skyridingWhirlingSurgeColorG = ng; p.skyridingWhirlingSurgeColorB = nb
        if addonTable.skyridingSurgeColorSwatch then addonTable.skyridingSurgeColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingWhirlingSurgeColorR = prev.r; p.skyridingWhirlingSurgeColorG = prev.g; p.skyridingWhirlingSurgeColorB = prev.b
        if addonTable.skyridingSurgeColorSwatch then addonTable.skyridingSurgeColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingWindColorBtn then
    addonTable.skyridingWindColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingSecondWindColorR or 0.2, p.skyridingSecondWindColorG or 0.8, p.skyridingSecondWindColorB or 0.2
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingSecondWindColorR = nr; p.skyridingSecondWindColorG = ng; p.skyridingSecondWindColorB = nb
        if addonTable.skyridingWindColorSwatch then addonTable.skyridingWindColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingSecondWindColorR = prev.r; p.skyridingSecondWindColorG = prev.g; p.skyridingSecondWindColorB = prev.b
        if addonTable.skyridingWindColorSwatch then addonTable.skyridingWindColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.radialCB then addonTable.radialCB.customOnClick = function(s) local p = GetProfile(); if p then p.showRadialCircle = s:GetChecked(); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
  if addonTable.radialCombatCB then addonTable.radialCombatCB.customOnClick = function(s) local p = GetProfile(); if p then p.cursorCombatOnly = s:GetChecked(); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end end end end
  if addonTable.radialGcdCB then addonTable.radialGcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.showGCD = s:GetChecked(); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
  if addonTable.ufClassColorCB then addonTable.ufClassColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufClassColor = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end end end
  if addonTable.ufDisableGlowsCB then
    addonTable.ufDisableGlowsCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.ufDisableGlows = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.ufDisableCombatTextCB then
    addonTable.ufDisableCombatTextCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.ufDisableCombatText = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.ufHideGroupIndicatorCB then
    addonTable.ufHideGroupIndicatorCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.ufHideGroupIndicator = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.disableTargetBuffsCB then
    addonTable.disableTargetBuffsCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.disableTargetBuffs = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.hideEliteTextureCB then
    addonTable.hideEliteTextureCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.hideEliteTexture = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.ufUseCustomTexturesCB then
    addonTable.ufUseCustomTexturesCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.ufUseCustomTextures = s:GetChecked()
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if not s:GetChecked() then ShowReloadPrompt("Disabling custom textures requires a reload to fully restore default textures.") end
      end
    end
  end
  if addonTable.ufHealthTextureDD then addonTable.ufHealthTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.ufHealthTexture = v; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end end end
  if addonTable.useCustomBorderColorCB then
    addonTable.useCustomBorderColorCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.useCustomBorderColor = s:GetChecked()
        if addonTable.ufBorderColorBtn then addonTable.ufBorderColorBtn:SetEnabled(s:GetChecked()) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
    end
  end
  if addonTable.ufBorderColorBtn then
    addonTable.ufBorderColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.ufCustomBorderColorR or 1
      local g = p.ufCustomBorderColorG or 1
      local b = p.ufCustomBorderColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.ufCustomBorderColorR, p.ufCustomBorderColorG, p.ufCustomBorderColorB = nr, ng, nb
        if addonTable.ufBorderColorSwatch then addonTable.ufBorderColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      local function OnCancel(prev)
        p.ufCustomBorderColorR, p.ufCustomBorderColorG, p.ufCustomBorderColorB = prev.r, prev.g, prev.b
        if addonTable.ufBorderColorSwatch then addonTable.ufBorderColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.ufUseCustomNameColorCB then
    addonTable.ufUseCustomNameColorCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.ufUseCustomNameColor = s:GetChecked()
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if not s:GetChecked() then ShowReloadPrompt("Disabling custom name color requires a reload to fully restore default colors.") end
      end
    end
  end
  if addonTable.ufNameColorBtn then
    addonTable.ufNameColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.ufNameColorR or 1
      local g = p.ufNameColorG or 1
      local b = p.ufNameColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.ufNameColorR, p.ufNameColorG, p.ufNameColorB = nr, ng, nb
        if addonTable.ufNameColorSwatch then addonTable.ufNameColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      local function OnCancel(prev)
        p.ufNameColorR, p.ufNameColorG, p.ufNameColorB = prev.r, prev.g, prev.b
        if addonTable.ufNameColorSwatch then addonTable.ufNameColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  local function ApplyUFBigHealthbarChanges(forceTargetImmediate, skipControlSync)
    local p = GetProfile()
    if p and p.ufBigHBEnabled == true and (p.ufBigHBPlayerEnabled == true or p.ufBigHBTargetEnabled == true or p.ufBigHBFocusEnabled == true) then
      p.useCustomBorderColor = true
      p.ufUseCustomNameColor = true
      if (p.ufCustomBorderColorR or 0) == 0 and (p.ufCustomBorderColorG or 0) == 0 and (p.ufCustomBorderColorB or 0) == 0 then
      elseif not p.useCustomBorderColor then
        p.ufCustomBorderColorR = 0; p.ufCustomBorderColorG = 0; p.ufCustomBorderColorB = 0
      end
    end
    if not skipControlSync and addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if addonTable.ApplyUnitFrameCustomization then
      if skipControlSync and C_Timer and C_Timer.After then
        if addonTable._ufBigHBApplyQueued then return end
        addonTable._ufBigHBApplyQueued = true
        C_Timer.After(0, function()
          addonTable._ufBigHBApplyQueued = false
          if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        end)
      else
        addonTable.ApplyUnitFrameCustomization()
      end
    end
    if forceTargetImmediate and addonTable.ApplyUnitFrameCustomization and C_Timer and C_Timer.After then
      C_Timer.After(0.03, function()
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end)
      C_Timer.After(0.09, function()
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end)
      C_Timer.After(0.18, function()
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end)
    end
  end
  local function EnsureBossPreviewFrame()
    if addonTable.ufBossPreviewHolder and addonTable.ufBossPreviewRows then
      return addonTable.ufBossPreviewHolder
    end
    local holder = CreateFrame("Frame", "CCMUFBossPreview", UIParent, "BackdropTemplate")
    holder:SetSize(260, 280)
    holder:SetFrameStrata("HIGH")
    holder:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    holder:SetBackdropColor(0.02, 0.02, 0.03, 0.55)
    holder:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    holder:EnableMouse(true)
    holder._ccmDragStartCursorX = nil
    holder._ccmDragStartCursorY = nil
    holder._ccmDragStartX = nil
    holder._ccmDragStartY = nil
    holder._ccmDragAnchor = nil
    local function BeginBossPreviewDrag()
      local p = GetProfile()
      if not p then return end
      local uiScale = UIParent:GetEffectiveScale() or 1
      local cx, cy = GetCursorPosition()
      holder._ccmDragStartCursorX = (tonumber(cx) or 0) / uiScale
      holder._ccmDragStartCursorY = (tonumber(cy) or 0) / uiScale
      holder._ccmDragAnchor = p.ufBossFrameAnchor or "TOPRIGHT"
      holder._ccmDragStartX = tonumber(p.ufBossFrameX) or -245
      holder._ccmDragStartY = tonumber(p.ufBossFrameY) or -280
      holder._ccmDragging = true
      holder:StartMoving()
    end
    local function CommitBossPreviewDragPosition()
      local p = GetProfile()
      if not p then return end
      local uiScale = UIParent:GetEffectiveScale() or 1
      local cx, cy = GetCursorPosition()
      local curX = (tonumber(cx) or 0) / uiScale
      local curY = (tonumber(cy) or 0) / uiScale
      local startCX = tonumber(holder._ccmDragStartCursorX) or curX
      local startCY = tonumber(holder._ccmDragStartCursorY) or curY
      local dx = curX - startCX
      local dy = curY - startCY
      local anchor = holder._ccmDragAnchor or p.ufBossFrameAnchor or "TOPRIGHT"
      local x = (tonumber(holder._ccmDragStartX) or tonumber(p.ufBossFrameX) or -245) + dx
      local y = (tonumber(holder._ccmDragStartY) or tonumber(p.ufBossFrameY) or -280) + dy
      local function RoundSigned(v)
        if v >= 0 then return math.floor(v + 0.5) end
        return math.ceil(v - 0.5)
      end
      p.ufBossFrameAnchor = anchor
      p.ufBossFrameX = RoundSigned(tonumber(x) or 0)
      p.ufBossFrameY = RoundSigned(tonumber(y) or 0)
      holder:ClearAllPoints()
      holder:SetPoint(p.ufBossFrameAnchor, UIParent, p.ufBossFrameAnchor, p.ufBossFrameX, p.ufBossFrameY)
      holder._ccmDragStartCursorX = nil
      holder._ccmDragStartCursorY = nil
      holder._ccmDragStartX = nil
      holder._ccmDragStartY = nil
      holder._ccmDragAnchor = nil
      if addonTable.ufBossFrameXSlider then addonTable.ufBossFrameXSlider:SetValue(p.ufBossFrameX) end
      if addonTable.ufBossFrameYSlider then addonTable.ufBossFrameYSlider:SetValue(p.ufBossFrameY) end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    end
    local function ForceStopBossPreviewDrag()
      if not holder._ccmDragging then return end
      holder:StopMovingOrSizing()
      holder._ccmDragging = false
      CommitBossPreviewDragPosition()
    end
    holder:RegisterForDrag("LeftButton")
    holder:SetScript("OnDragStart", function(self)
      BeginBossPreviewDrag()
    end)
    holder:SetScript("OnDragStop", function(self)
      ForceStopBossPreviewDrag()
    end)
    local dragLayer = CreateFrame("Frame", nil, holder)
    dragLayer:SetAllPoints(holder)
    dragLayer:EnableMouse(true)
    dragLayer:RegisterForDrag("LeftButton")
    dragLayer:SetFrameStrata(holder:GetFrameStrata())
    dragLayer:SetFrameLevel((holder:GetFrameLevel() or 1) + 50)
    dragLayer:SetScript("OnDragStart", function()
      BeginBossPreviewDrag()
    end)
    dragLayer:SetScript("OnDragStop", function()
      ForceStopBossPreviewDrag()
    end)
    dragLayer:SetScript("OnMouseUp", function()
      ForceStopBossPreviewDrag()
    end)
    holder:SetScript("OnHide", function()
      ForceStopBossPreviewDrag()
    end)
    holder:SetScript("OnUpdate", function(self)
      if self._ccmDragging and IsMouseButtonDown and (not IsMouseButtonDown("LeftButton")) then
        ForceStopBossPreviewDrag()
      end
    end)
    holder._ccmDragLayer = dragLayer
    local dragNote = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragNote:SetPoint("TOP", holder, "TOP", 0, -4)
    dragNote:SetText("Boss Preview (drag)")
    dragNote:SetTextColor(1, 0.82, 0.1)
    addonTable.ufBossPreviewRows = {}
    for i = 1, 5 do
      local row = CreateFrame("Frame", nil, holder, "BackdropTemplate")
      row:SetSize(230, 42)
      row:SetPoint("TOPLEFT", holder, "TOPLEFT", 14, -(i - 1) * 52 - 18)
      row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      row:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
      row:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
      local portrait = row:CreateTexture(nil, "ARTWORK")
      portrait:SetSize(36, 36)
      portrait:SetPoint("LEFT", row, "LEFT", 3, 0)
      portrait:SetTexture("Interface\\Icons\\Achievement_Boss_YoggSaron_01")
      portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      local baseLevel = row:GetFrameLevel()
      local hpBg = CreateFrame("StatusBar", nil, row)
      hpBg:SetFrameLevel(baseLevel + 1)
      hpBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      hpBg:SetStatusBarColor(0, 0, 0, 0.45)
      local hp = CreateFrame("StatusBar", nil, row)
      hp:SetFrameLevel(baseLevel + 2)
      hp:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 4, -1)
      hp:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, -1)
      hp:SetHeight(24)
      hp:SetMinMaxValues(0, 1)
      hp:SetValue(0.75)
      hp:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      hp:GetStatusBarTexture():SetVertexColor(0.16, 0.72, 0.21, 1)
      hp:SetClipsChildren(true)
      local absorb = CreateFrame("StatusBar", nil, hp)
      absorb:SetFrameLevel(hp:GetFrameLevel() + 1)
      absorb:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      absorb:SetStatusBarColor(0.85, 0.95, 1.00, 0.28)
      local barBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
      barBorder:SetFrameLevel(baseLevel + 4)
      barBorder:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      barBorder:SetBackdropColor(0, 0, 0, 0)
      barBorder:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
      local ppBg = CreateFrame("StatusBar", nil, row)
      ppBg:SetFrameLevel(baseLevel + 1)
      ppBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      ppBg:SetStatusBarColor(0, 0, 0, 0.45)
      local pp = CreateFrame("StatusBar", nil, row)
      pp:SetFrameLevel(baseLevel + 2)
      pp:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -2)
      pp:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -2)
      pp:SetHeight(8)
      pp:SetMinMaxValues(0, 1)
      pp:SetValue(0.45)
      pp:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      pp:GetStatusBarTexture():SetVertexColor(0.45, 0.24, 0.78, 1)
      local textOverlay = CreateFrame("Frame", nil, row)
      textOverlay:SetAllPoints(row)
      textOverlay:SetFrameLevel(row:GetFrameLevel() + 10)
      local name = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      name:SetPoint("LEFT", hp, "LEFT", 4, 0)
      name:SetText("Boss " .. i)
      local hpText = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      hpText:SetPoint("RIGHT", hp, "RIGHT", -30, 0)
      hpText:SetText("100% (879K)")
      local lvl = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      lvl:SetPoint("RIGHT", hp, "RIGHT", -4, 0)
      lvl:SetText("??")
      local ppText = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      ppText:SetPoint("RIGHT", pp, "RIGHT", -4, 0)
      ppText:SetText("90")
      local castHolder = CreateFrame("Frame", nil, row, "BackdropTemplate")
      castHolder:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      castHolder:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
      castHolder:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
      local castBaseLevel = castHolder:GetFrameLevel()
      local castBg = CreateFrame("StatusBar", nil, castHolder)
      castBg:SetFrameLevel(castBaseLevel + 1)
      castBg:SetAllPoints(castHolder)
      castBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      castBg:SetStatusBarColor(0, 0, 0, 0.45)
      castBg:SetMinMaxValues(0, 1)
      castBg:SetValue(1)
      local cast = CreateFrame("StatusBar", nil, castHolder)
      cast:SetFrameLevel(castBaseLevel + 2)
      cast:SetAllPoints(castHolder)
      cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      cast:SetMinMaxValues(0, 1)
      cast:SetValue(0.55)
      cast:SetStatusBarColor(1.00, 0.72, 0.12, 1)
      local castTextOverlay = CreateFrame("Frame", nil, castHolder)
      castTextOverlay:SetAllPoints(castHolder)
      castTextOverlay:SetFrameLevel(cast:GetFrameLevel() + 5)
      local castText = castTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      castText:SetPoint("LEFT", castHolder, "LEFT", 4, 0)
      castText:SetText("Ethereal Portal")
      local castTime = castTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      castTime:SetPoint("RIGHT", castHolder, "RIGHT", -4, 0)
      castTime:SetText("2.3")
      local castIcon = castHolder:CreateTexture(nil, "ARTWORK")
      castIcon:SetTexture("Interface\\Icons\\spell_arcane_portalstormwind")
      castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      addonTable.ufBossPreviewRows[i] = {row = row, barBorder = barBorder, hpBg = hpBg, hp = hp, absorb = absorb, ppBg = ppBg, pp = pp, name = name, hpText = hpText, ppText = ppText, lvl = lvl, portrait = portrait, castHolder = castHolder, cast = cast, castBg = castBg, castTextOverlay = castTextOverlay, castText = castText, castTime = castTime, castIcon = castIcon}
    end
    addonTable.ufBossPreviewHolder = holder
    holder:Hide()
    return holder
  end
  local function UpdateBossPreviewFromProfile()
    local p = GetProfile()
    local holder = EnsureBossPreviewFrame()
    local rows = addonTable.ufBossPreviewRows
    if not p or not holder or type(rows) ~= "table" then return end
    local gf, go
    if addonTable.GetGlobalFont then gf, go = addonTable.GetGlobalFont() end
    gf = gf or "Fonts\\FRIZQT__.TTF"
    go = go or ""
    local borderOn = p.useCustomBorderColor == true
    local br = borderOn and (p.ufCustomBorderColorR or 0.22) or 0.22
    local bg = borderOn and (p.ufCustomBorderColorG or 0.22) or 0.22
    local bb = borderOn and (p.ufCustomBorderColorB or 0.26) or 0.26
    local nameR = (p.ufUseCustomNameColor == true) and (p.ufNameColorR or 1) or 1
    local nameG = (p.ufUseCustomNameColor == true) and (p.ufNameColorG or 1) or 1
    local nameB = (p.ufUseCustomNameColor == true) and (p.ufNameColorB or 1) or 1
    local width = math.max(120, tonumber(p.ufBossFrameWidth) or 168)
    local hpH = math.max(8, tonumber(p.ufBossFrameHealthHeight) or 20)
    local ppH = math.max(4, tonumber(p.ufBossFramePowerHeight) or 8)
    local spacing = math.max(0, tonumber(p.ufBossFrameSpacing) or 36)
    local showLevel = p.ufBossFrameShowLevel ~= false
    local hidePortrait = p.ufBossFrameHidePortrait == true
    local borderSize = math.max(0, math.min(3, math.floor((tonumber(p.ufBossFrameBorderSize) or ((p.ufBossFrameUseBorder == true) and 1 or 0)) + 0.5)))
    local useBorder = borderSize > 0
    local castbarClamped = p.ufBossCastbarClamped ~= false
    local castbarAnchor = p.ufBossCastbarAnchor or "bottom"
    local castbarHeight = tonumber(p.ufBossCastbarHeight) or 12
    local castbarWidthOverride = tonumber(p.ufBossCastbarWidth) or 0
    local castbarSpacing = castbarClamped and 0 or (tonumber(p.ufBossCastbarSpacing) or 2)
    local castIconEnabled = p.ufBossCastbarIcon ~= false
    local castbarOffX = tonumber(p.ufBossCastbarX) or 0
    local castbarOffY = tonumber(p.ufBossCastbarY) or 0
    local showHealthText = p.ufBossFrameShowHealthText ~= false
    local healthTextX = tonumber(p.ufBossHealthTextX) or -4
    local healthTextY = tonumber(p.ufBossHealthTextY) or 0
    local healthTextScale = tonumber(p.ufBossHealthTextScale) or 1
    local showPowerText = p.ufBossFrameShowPowerText ~= false
    local powerTextX = tonumber(p.ufBossPowerTextX) or -4
    local powerTextY = tonumber(p.ufBossPowerTextY) or 0
    local powerTextScale = tonumber(p.ufBossPowerTextScale) or 1
    local castbarTextScale = tonumber(p.ufBossCastbarTextScale) or 1
    local showAbsorb = p.ufBossFrameShowAbsorb == true
    local absorbR = tonumber(p.ufBossAbsorbColorR) or 0.85
    local absorbG = tonumber(p.ufBossAbsorbColorG) or 0.95
    local absorbB = tonumber(p.ufBossAbsorbColorB) or 1.00
    local absorbA = tonumber(p.ufBossAbsorbColorA) or 0.28
    local barBgAlpha = math.max(0, math.min(1, tonumber(p.ufBossFrameBarBgAlpha) or 0.45))
    local totalH = hpH + ppH + 7
    local rowStride = totalH + 16 + spacing
    local bossTexKey = p.ufBossBarTexture or "lsm:Blizzard"
    local texturePath = (addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(bossTexKey)) or "Interface\\TargetingFrame\\UI-StatusBar"
    if not holder._ccmDragging then
      holder:ClearAllPoints()
      holder:SetPoint(p.ufBossFrameAnchor or "TOPRIGHT", UIParent, p.ufBossFrameAnchor or "TOPRIGHT", tonumber(p.ufBossFrameX) or -245, tonumber(p.ufBossFrameY) or -280)
    end
    holder:SetScale(tonumber(p.ufBossFrameScale) or 1)
    holder:SetHeight((rowStride * 5) + 24)
    holder:SetWidth(width + 64)
    for i = 1, #rows do
      local rowData = rows[i]
      local row = rowData and rowData.row
      local barBorder = rowData and rowData.barBorder
      local hpBg = rowData and rowData.hpBg
      local hp = rowData and rowData.hp
      local absorb = rowData and rowData.absorb
      local ppBg = rowData and rowData.ppBg
      local pp = rowData and rowData.pp
      local name = rowData and rowData.name
      local hpText = rowData and rowData.hpText
      local ppText = rowData and rowData.ppText
      local lvl = rowData and rowData.lvl
      local portrait = rowData and rowData.portrait
      local castHolder = rowData and rowData.castHolder
      local cast = rowData and rowData.cast
      local castBg = rowData and rowData.castBg
      local castTextOverlay = rowData and rowData.castTextOverlay
      local castText = rowData and rowData.castText
      local castTime = rowData and rowData.castTime
      local castIcon = rowData and rowData.castIcon
      if row and hp and pp and name and lvl then
        local portraitSize = hpH + ppH
        local leftInset = hidePortrait and 5 or (portraitSize + 5)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 14, -(i - 1) * rowStride - 18)
        row:SetSize(width + 46, totalH + 22)
        row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        row:SetBackdropColor(0, 0, 0, 0)
        row:SetBackdropBorderColor(br, bg, bb, 0)
        hp:ClearAllPoints()
        hp:SetPoint("TOPLEFT", row, "TOPLEFT", leftInset, -4)
        hp:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, -4)
        hp:SetHeight(hpH)
        if hpBg then
          hpBg:ClearAllPoints()
          hpBg:SetPoint("TOPLEFT", hp, "TOPLEFT", 0, 0)
          hpBg:SetPoint("TOPRIGHT", hp, "TOPRIGHT", 0, 0)
          hpBg:SetHeight(hpH)
          hpBg:SetMinMaxValues(0, 1)
          hpBg:SetValue(1)
          if hpBg.SetStatusBarTexture then pcall(hpBg.SetStatusBarTexture, hpBg, "Interface\\Buttons\\WHITE8x8") end
          hpBg:SetStatusBarColor(0, 0, 0, barBgAlpha)
          hpBg:Show()
        end
        pp:ClearAllPoints()
        pp:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, 0)
        pp:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, 0)
        pp:SetHeight(ppH)
        if portrait then
          portrait:ClearAllPoints()
          portrait:SetSize(portraitSize, portraitSize)
          portrait:SetPoint("TOPRIGHT", hp, "TOPLEFT", 0, 0)
          portrait:SetShown(not hidePortrait)
        end
        if ppBg then
          ppBg:ClearAllPoints()
          ppBg:SetPoint("TOPLEFT", pp, "TOPLEFT", 0, 0)
          ppBg:SetPoint("TOPRIGHT", pp, "TOPRIGHT", 0, 0)
          ppBg:SetHeight(ppH)
          ppBg:SetMinMaxValues(0, 1)
          ppBg:SetValue(1)
          if ppBg.SetStatusBarTexture then pcall(ppBg.SetStatusBarTexture, ppBg, "Interface\\Buttons\\WHITE8x8") end
          ppBg:SetStatusBarColor(0, 0, 0, barBgAlpha)
          ppBg:Show()
        end
        if barBorder then
          barBorder:ClearAllPoints()
          local borderLeft = (not hidePortrait and portrait) and portrait or (hpBg or hp)
          barBorder:SetPoint("TOPLEFT", borderLeft, "TOPLEFT", -borderSize, borderSize)
          barBorder:SetPoint("BOTTOMRIGHT", ppBg or pp, "BOTTOMRIGHT", borderSize, -borderSize)
          barBorder:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = math.max(1, borderSize)})
          barBorder:SetBackdropColor(0, 0, 0, 0)
          barBorder:SetBackdropBorderColor(br, bg, bb, useBorder and 1 or 0)
        end
        if absorb then
          absorb:ClearAllPoints()
          local hpTex = hp:GetStatusBarTexture()
          absorb:SetPoint("TOPLEFT", hpTex, "TOPRIGHT", 0, 0)
          absorb:SetPoint("BOTTOMLEFT", hpTex, "BOTTOMRIGHT", 0, 0)
          absorb:SetWidth(hp:GetWidth() or width)
          absorb:SetMinMaxValues(0, 1)
          absorb:SetValue(0.18)
          absorb:SetStatusBarColor(absorbR, absorbG, absorbB, absorbA)
          absorb:SetShown(showAbsorb)
        end
        if hp.SetStatusBarTexture then pcall(hp.SetStatusBarTexture, hp, texturePath) end
        if pp.SetStatusBarTexture then pcall(pp.SetStatusBarTexture, pp, texturePath) end
        if absorb and absorb.SetStatusBarTexture then pcall(absorb.SetStatusBarTexture, absorb, texturePath) end
        hp:SetValue(math.max(0.15, 0.95 - (i * 0.11)))
        pp:SetValue(math.max(0.05, 0.66 - (i * 0.09)))
        if name.SetFont then pcall(name.SetFont, name, gf, 11, go or "") end
        if lvl.SetFont then pcall(lvl.SetFont, lvl, gf, 10, go or "") end
        if name.SetTextColor then name:SetTextColor(nameR, nameG, nameB) end
        if lvl.SetTextColor then lvl:SetTextColor(nameR, nameG, nameB) end
        if hpText then
          if hpText.SetFont then pcall(hpText.SetFont, hpText, gf, math.max(6, math.floor(10 * healthTextScale + 0.5)), go or "") end
          hpText:ClearAllPoints()
          hpText:SetPoint("RIGHT", hp, "RIGHT", healthTextX, healthTextY)
          hpText:SetTextColor(nameR, nameG, nameB)
          hpText:SetShown(showHealthText)
        end
        if ppText then
          if ppText.SetFont then pcall(ppText.SetFont, ppText, gf, math.max(6, math.floor(10 * powerTextScale + 0.5)), go or "") end
          ppText:ClearAllPoints()
          ppText:SetPoint("RIGHT", pp, "RIGHT", powerTextX, powerTextY)
          ppText:SetTextColor(nameR, nameG, nameB)
          ppText:SetShown(showPowerText)
        end
        lvl:ClearAllPoints()
        lvl:SetPoint("RIGHT", hp, "RIGHT", -4, 0)
        if hpText and showHealthText then
          local hpFmt = p.ufBossHealthTextFormat or "percent_value"
          if hpFmt == "percent" then hpText:SetText("100%")
          elseif hpFmt == "value" then hpText:SetText("879K")
          elseif hpFmt == "value_percent" then hpText:SetText("879K | 100%")
          elseif hpFmt == "full" then hpText:SetText("879,412")
          else hpText:SetText("100% (879K)") end
        end
        if ppText and showPowerText then
          ppText:SetText("90")
        end
        lvl:SetShown(showLevel)
        if castHolder and cast then
          castHolder:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = math.max(1, borderSize)})
          castHolder:SetBackdropColor(0, 0, 0, 0)
          castHolder:SetBackdropBorderColor(br, bg, bb, useBorder and 1 or 0)
          local castBorderLeft = (not hidePortrait and portrait) and portrait or (hpBg or hp)
          local useCustomWidth = castbarWidthOverride > 0
          castHolder:ClearAllPoints()
          if castbarAnchor == "top" then
            if useCustomWidth then
              castHolder:SetPoint("BOTTOM", hpBg or hp, "TOP", castbarOffX, castbarSpacing + castbarOffY)
              castHolder:SetSize(castbarWidthOverride + borderSize * 2, castbarHeight + borderSize * 2)
            else
              castHolder:SetPoint("BOTTOMLEFT", castBorderLeft, "TOPLEFT", -borderSize + castbarOffX, castbarSpacing + castbarOffY)
              castHolder:SetPoint("BOTTOMRIGHT", hpBg or hp, "TOPRIGHT", borderSize + castbarOffX, castbarSpacing + castbarOffY)
              castHolder:SetHeight(castbarHeight + borderSize * 2)
            end
          elseif castbarAnchor == "left" then
            castHolder:SetPoint("RIGHT", castBorderLeft, "LEFT", -castbarSpacing + castbarOffX, castbarOffY)
            local castW = (useCustomWidth and castbarWidthOverride or width) + borderSize * 2
            castHolder:SetSize(castW, castbarHeight + borderSize * 2)
          elseif castbarAnchor == "right" then
            castHolder:SetPoint("LEFT", hpBg or hp, "RIGHT", castbarSpacing + castbarOffX, castbarOffY)
            local castW = (useCustomWidth and castbarWidthOverride or width) + borderSize * 2
            castHolder:SetSize(castW, castbarHeight + borderSize * 2)
          else
            local ppRef = ppBg or pp
            if useCustomWidth then
              castHolder:SetPoint("TOP", ppRef, "BOTTOM", castbarOffX, -castbarSpacing + castbarOffY)
              castHolder:SetSize(castbarWidthOverride + borderSize * 2, castbarHeight + borderSize * 2)
            else
              castHolder:SetPoint("TOPLEFT", ppRef, "BOTTOMLEFT", -(hidePortrait and 0 or portraitSize) - borderSize + castbarOffX, -castbarSpacing + castbarOffY)
              castHolder:SetPoint("TOPRIGHT", ppRef, "BOTTOMRIGHT", borderSize + castbarOffX, -castbarSpacing + castbarOffY)
              castHolder:SetHeight(castbarHeight + borderSize * 2)
            end
          end
          local castIconVisible = castIconEnabled and not hidePortrait
          local iconSpace = castIconVisible and castbarHeight or 0
          if castIcon then
            castIcon:ClearAllPoints()
            castIcon:SetSize(castbarHeight, castbarHeight)
            castIcon:SetPoint("TOPLEFT", castHolder, "TOPLEFT", borderSize, -borderSize)
            castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            castIcon:SetShown(castIconVisible)
          end
          if castBg then
            castBg:ClearAllPoints()
            castBg:SetPoint("TOPLEFT", castHolder, "TOPLEFT", borderSize + iconSpace, -borderSize)
            castBg:SetPoint("BOTTOMRIGHT", castHolder, "BOTTOMRIGHT", -borderSize, borderSize)
            castBg:SetStatusBarColor(0, 0, 0, barBgAlpha)
          end
          if cast then
            cast:ClearAllPoints()
            cast:SetPoint("TOPLEFT", castHolder, "TOPLEFT", borderSize + iconSpace, -borderSize)
            cast:SetPoint("BOTTOMRIGHT", castHolder, "BOTTOMRIGHT", -borderSize, borderSize)
            if cast.SetStatusBarTexture then pcall(cast.SetStatusBarTexture, cast, texturePath) end
          end
          cast:SetValue(math.max(0.10, 0.85 - (i * 0.12)))
          if castTextOverlay then
            castTextOverlay:ClearAllPoints()
            castTextOverlay:SetPoint("TOPLEFT", castHolder, "TOPLEFT", borderSize + iconSpace, -borderSize)
            castTextOverlay:SetPoint("BOTTOMRIGHT", castHolder, "BOTTOMRIGHT", -borderSize, borderSize)
          end
          local castFS = math.max(6, math.floor(10 * castbarTextScale + 0.5))
          if castText then
            castText:ClearAllPoints()
            castText:SetPoint("LEFT", castTextOverlay or cast, "LEFT", 4, 0)
            castText:SetText("Ethereal Portal")
            if castText.SetFont then pcall(castText.SetFont, castText, gf, castFS, go or "") end
            castText:SetTextColor(nameR, nameG, nameB)
          end
          if castTime then
            castTime:ClearAllPoints()
            castTime:SetPoint("RIGHT", castTextOverlay or cast, "RIGHT", -4, 0)
            if castTime.SetFont then pcall(castTime.SetFont, castTime, gf, castFS, go or "") end
            castTime:SetTextColor(nameR, nameG, nameB)
            castTime:SetText(string.format("%.1f", math.max(0.1, 3.5 - (i * 0.3))))
          end
          castHolder:Show()
        end
      end
    end
  end
  local function SetBossPreviewShown(show)
    local holder = EnsureBossPreviewFrame()
    if not holder then return end
    holder:SetShown(show == true)
    if show == true then
      UpdateBossPreviewFromProfile()
      SetButtonHighlighted(addonTable.ufBossFramePreviewOnBtn, true)
    else
      SetButtonHighlighted(addonTable.ufBossFramePreviewOnBtn, false)
    end
  end
  addonTable.StopUFBossPreview = function()
    SetBossPreviewShown(false)
  end
  if addonTable.ufBigHBPlayerCB then addonTable.ufBigHBPlayerCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBPlayerEnabled = s:GetChecked(); if p.ufBigHBPlayerEnabled == true then p.ufBigHBEnabled = true elseif p.ufBigHBTargetEnabled ~= true and p.ufBigHBFocusEnabled ~= true then p.ufBigHBEnabled = false end; ApplyUFBigHealthbarChanges(); if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end; ShowReloadPrompt("Toggling Bigger Healthbars requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBigHBTargetCB then addonTable.ufBigHBTargetCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBTargetEnabled = s:GetChecked(); if p.ufBigHBTargetEnabled == true then p.ufBigHBEnabled = true elseif p.ufBigHBPlayerEnabled ~= true and p.ufBigHBFocusEnabled ~= true then p.ufBigHBEnabled = false end; ApplyUFBigHealthbarChanges(); if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end; ShowReloadPrompt("Toggling Bigger Healthbars requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBigHBFocusCB then addonTable.ufBigHBFocusCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBFocusEnabled = s:GetChecked(); if p.ufBigHBFocusEnabled == true then p.ufBigHBEnabled = true elseif p.ufBigHBPlayerEnabled ~= true and p.ufBigHBTargetEnabled ~= true then p.ufBigHBEnabled = false end; ApplyUFBigHealthbarChanges(); if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end; ShowReloadPrompt("Toggling Bigger Healthbars requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBossFramesEnabledCB then addonTable.ufBossFramesEnabledCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossFramesEnabled = s:GetChecked(); if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; ShowReloadPrompt("Toggling Boss Frame Customization requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBigHBPlayerHideRealmCB then addonTable.ufBigHBPlayerHideRealmCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBPlayerHideRealm = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetHideRealmCB then addonTable.ufBigHBTargetHideRealmCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBTargetHideRealm = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusHideRealmCB then addonTable.ufBigHBFocusHideRealmCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBFocusHideRealm = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end

  if addonTable.ufBigHBPlayerNameMaxCharsSlider then addonTable.ufBigHBPlayerNameMaxCharsSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerNameMaxChars = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetNameMaxCharsSlider then addonTable.ufBigHBTargetNameMaxCharsSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetNameMaxChars = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusNameMaxCharsSlider then addonTable.ufBigHBFocusNameMaxCharsSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusNameMaxChars = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBHidePlayerNameCB then addonTable.ufBigHBHidePlayerNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHidePlayerName = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerNameAnchorDD then addonTable.ufBigHBPlayerNameAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBPlayerNameAnchor = v or "center"; ApplyUFBigHealthbarChanges(true) end end end
  if addonTable.ufBigHBPlayerLevelDD then addonTable.ufBigHBPlayerLevelDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBPlayerLevelMode = v; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBHideTargetNameCB then addonTable.ufBigHBHideTargetNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHideTargetName = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetNameAnchorDD then addonTable.ufBigHBTargetNameAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBTargetNameAnchor = v or "center"; ApplyUFBigHealthbarChanges(true) end end end
  if addonTable.ufBigHBTargetLevelDD then addonTable.ufBigHBTargetLevelDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBTargetLevelMode = v; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBHideFocusNameCB then addonTable.ufBigHBHideFocusNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHideFocusName = s:GetChecked(); ApplyUFBigHealthbarChanges(true) end end end
  if addonTable.ufBigHBFocusNameAnchorDD then addonTable.ufBigHBFocusNameAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBFocusNameAnchor = v or "center"; ApplyUFBigHealthbarChanges(true) end end end
  if addonTable.ufBigHBFocusLevelDD then addonTable.ufBigHBFocusLevelDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBFocusLevelMode = v; ApplyUFBigHealthbarChanges() end end end
  local function BindUFBigIntSlider(slider, key)
    if not slider then return end
    slider:SetScript("OnValueChanged", function(s, v)
      if s._updating then return end
      local p = GetProfile()
      if not p then return end
      local rounded = math.floor(v + 0.5)
      if p[key] == rounded then
        if s.valueText and not s.valueText:HasFocus() then s.valueText:SetText(rounded) end
        return
      end
      p[key] = rounded
      if s.valueText then s.valueText:SetText(rounded) end
      ApplyUFBigHealthbarChanges(nil, true)
    end)
  end
  local function BindUFBigScaleSlider(slider, key)
    if not slider then return end
    slider:SetScript("OnValueChanged", function(s, v)
      if s._updating then return end
      local p = GetProfile()
      if not p then return end
      local rounded = math.floor(v * 100 + 0.5) / 100
      if p[key] == rounded then
        if s.valueText and not s.valueText:HasFocus() then s.valueText:SetText(string.format("%.2f", rounded)) end
        return
      end
      p[key] = rounded
      if s.valueText then s.valueText:SetText(string.format("%.2f", rounded)) end
      ApplyUFBigHealthbarChanges(nil, true)
    end)
  end
  BindUFBigIntSlider(addonTable.ufBigHBPlayerNameXSlider, "ufBigHBPlayerNameX")
  BindUFBigIntSlider(addonTable.ufBigHBPlayerNameYSlider, "ufBigHBPlayerNameY")
  BindUFBigIntSlider(addonTable.ufBigHBPlayerLevelXSlider, "ufBigHBPlayerLevelX")
  BindUFBigIntSlider(addonTable.ufBigHBPlayerLevelYSlider, "ufBigHBPlayerLevelY")
  BindUFBigScaleSlider(addonTable.ufBigHBPlayerNameTextScaleSlider, "ufBigHBPlayerNameTextScale")
  BindUFBigScaleSlider(addonTable.ufBigHBPlayerLevelTextScaleSlider, "ufBigHBPlayerLevelTextScale")
  BindUFBigIntSlider(addonTable.ufBigHBTargetNameXSlider, "ufBigHBTargetNameX")
  BindUFBigIntSlider(addonTable.ufBigHBTargetNameYSlider, "ufBigHBTargetNameY")
  BindUFBigIntSlider(addonTable.ufBigHBTargetLevelXSlider, "ufBigHBTargetLevelX")
  BindUFBigIntSlider(addonTable.ufBigHBTargetLevelYSlider, "ufBigHBTargetLevelY")
  BindUFBigScaleSlider(addonTable.ufBigHBTargetNameTextScaleSlider, "ufBigHBTargetNameTextScale")
  BindUFBigScaleSlider(addonTable.ufBigHBTargetLevelTextScaleSlider, "ufBigHBTargetLevelTextScale")
  BindUFBigIntSlider(addonTable.ufBigHBFocusNameXSlider, "ufBigHBFocusNameX")
  BindUFBigIntSlider(addonTable.ufBigHBFocusNameYSlider, "ufBigHBFocusNameY")
  BindUFBigIntSlider(addonTable.ufBigHBFocusLevelXSlider, "ufBigHBFocusLevelX")
  BindUFBigIntSlider(addonTable.ufBigHBFocusLevelYSlider, "ufBigHBFocusLevelY")
  BindUFBigScaleSlider(addonTable.ufBigHBFocusNameTextScaleSlider, "ufBigHBFocusNameTextScale")
  BindUFBigScaleSlider(addonTable.ufBigHBFocusLevelTextScaleSlider, "ufBigHBFocusLevelTextScale")
  local function BindBossIntSlider(slider, key)
    if not slider then return end
    slider:SetScript("OnValueChanged", function(s, v)
      if s._updating or not s:IsEnabled() then return end
      local p = GetProfile()
      if not p then return end
      local rounded = math.floor(v + 0.5)
      if p[key] == rounded then
        if s.valueText and not s.valueText:HasFocus() then s.valueText:SetText(rounded) end
        return
      end
      p[key] = rounded
      if s.valueText then s.valueText:SetText(rounded) end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      UpdateBossPreviewFromProfile()
    end)
  end
  local function BindBossScaleSlider(slider, key)
    if not slider then return end
    slider:SetScript("OnValueChanged", function(s, v)
      if s._updating or not s:IsEnabled() then return end
      local p = GetProfile()
      if not p then return end
      local rounded = math.floor(v * 100 + 0.5) / 100
      if p[key] == rounded then
        if s.valueText and not s.valueText:HasFocus() then s.valueText:SetText(string.format("%.2f", rounded)) end
        return
      end
      p[key] = rounded
      if s.valueText then s.valueText:SetText(string.format("%.2f", rounded)) end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      UpdateBossPreviewFromProfile()
    end)
  end
  BindBossIntSlider(addonTable.ufBossFrameXSlider, "ufBossFrameX")
  BindBossIntSlider(addonTable.ufBossFrameYSlider, "ufBossFrameY")
  BindBossIntSlider(addonTable.ufBossFrameSpacingSlider, "ufBossFrameSpacing")
  BindBossIntSlider(addonTable.ufBossFrameWidthSlider, "ufBossFrameWidth")
  BindBossIntSlider(addonTable.ufBossFrameHealthHeightSlider, "ufBossFrameHealthHeight")
  BindBossIntSlider(addonTable.ufBossFramePowerHeightSlider, "ufBossFramePowerHeight")
  BindBossIntSlider(addonTable.ufBossFrameBorderSizeSlider, "ufBossFrameBorderSize")
  BindBossIntSlider(addonTable.ufBossCastbarHeightSlider, "ufBossCastbarHeight")
  BindBossIntSlider(addonTable.ufBossCastbarWidthSlider, "ufBossCastbarWidth")
  BindBossIntSlider(addonTable.ufBossCastbarSpacingSlider, "ufBossCastbarSpacing")
  BindBossScaleSlider(addonTable.ufBossCastbarTextScaleSlider, "ufBossCastbarTextScale")
  BindBossIntSlider(addonTable.ufBossCastbarXSlider, "ufBossCastbarX")
  BindBossIntSlider(addonTable.ufBossCastbarYSlider, "ufBossCastbarY")
  BindBossScaleSlider(addonTable.ufBossFrameScaleSlider, "ufBossFrameScale")
  if addonTable.ufBossFrameShowLevelCB then addonTable.ufBossFrameShowLevelCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossFrameShowLevel = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile() end end end
  if addonTable.ufBossFrameHidePortraitCB then addonTable.ufBossFrameHidePortraitCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossFrameHidePortrait = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile() end end end
  if addonTable.ufBossFrameShowHealthTextCB then addonTable.ufBossFrameShowHealthTextCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossFrameShowHealthText = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile(); UpdateAllControls() end end end
  if addonTable.ufBossHealthTextFormatDD then addonTable.ufBossHealthTextFormatDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBossHealthTextFormat = v or "percent_value"; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile() end end end
  BindBossScaleSlider(addonTable.ufBossHealthTextScaleSlider, "ufBossHealthTextScale")
  BindBossIntSlider(addonTable.ufBossHealthTextXSlider, "ufBossHealthTextX")
  BindBossIntSlider(addonTable.ufBossHealthTextYSlider, "ufBossHealthTextY")
  if addonTable.ufBossFrameShowPowerTextCB then addonTable.ufBossFrameShowPowerTextCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossFrameShowPowerText = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile(); UpdateAllControls() end end end
  BindBossScaleSlider(addonTable.ufBossPowerTextScaleSlider, "ufBossPowerTextScale")
  BindBossIntSlider(addonTable.ufBossPowerTextXSlider, "ufBossPowerTextX")
  BindBossIntSlider(addonTable.ufBossPowerTextYSlider, "ufBossPowerTextY")
  if addonTable.ufBossFrameShowAbsorbCB then addonTable.ufBossFrameShowAbsorbCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossFrameShowAbsorb = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile(); UpdateAllControls() end end end
  if addonTable.ufBossAbsorbColorBtn then addonTable.ufBossAbsorbColorBtn:SetScript("OnClick", function()
    local p = GetProfile()
    if not p then return end
    local r, g, b = p.ufBossAbsorbColorR or 0.85, p.ufBossAbsorbColorG or 0.95, p.ufBossAbsorbColorB or 1.00
    local a = p.ufBossAbsorbColorA or 0.28
    local function GetAlpha()
      if ColorPickerFrame.GetColorAlpha then return ColorPickerFrame:GetColorAlpha() end
      return 1 - a
    end
    local function ApplyAbsorbColor()
      local nr, ng, nb = ColorPickerFrame:GetColorRGB()
      local na = 1 - GetAlpha()
      p.ufBossAbsorbColorR = nr; p.ufBossAbsorbColorG = ng; p.ufBossAbsorbColorB = nb; p.ufBossAbsorbColorA = na
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      UpdateBossPreviewFromProfile()
    end
    ShowColorPicker({r = r, g = g, b = b, opacity = 1 - a, hasOpacity = true,
      swatchFunc = ApplyAbsorbColor, opacityFunc = ApplyAbsorbColor,
      cancelFunc = function(prev)
        p.ufBossAbsorbColorR = prev.r; p.ufBossAbsorbColorG = prev.g; p.ufBossAbsorbColorB = prev.b
        p.ufBossAbsorbColorA = 1 - (prev.opacity or (1 - a))
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        UpdateBossPreviewFromProfile()
      end})
  end) end
  if addonTable.ufBossBarTextureDD then addonTable.ufBossBarTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBossBarTexture = v or "lsm:Blizzard"; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile() end end end
  if addonTable.ufBossCastbarAnchorDD then addonTable.ufBossCastbarAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBossCastbarAnchor = v or "bottom"; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile() end end end
  if addonTable.ufBossCastbarClampedCB then addonTable.ufBossCastbarClampedCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossCastbarClamped = s:GetChecked(); if s:GetChecked() and (p.ufBossCastbarAnchor == "left" or p.ufBossCastbarAnchor == "right") then p.ufBossCastbarAnchor = "bottom" end; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile(); UpdateAllControls() end end end
  if addonTable.ufBossCastbarIconCB then addonTable.ufBossCastbarIconCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBossCastbarIcon = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end; UpdateBossPreviewFromProfile() end end end
  BindBossScaleSlider(addonTable.ufBossFrameBarBgAlphaSlider, "ufBossFrameBarBgAlpha")
  if addonTable.ufBossFramePreviewOnBtn then addonTable.ufBossFramePreviewOnBtn:SetScript("OnClick", function() SetBossPreviewShown(true) end) end
  if addonTable.ufBossFramePreviewOffBtn then addonTable.ufBossFramePreviewOffBtn:SetScript("OnClick", function() SetBossPreviewShown(false) end) end
  if addonTable.ufBigHBPlayerHealAbsorbDD then addonTable.ufBigHBPlayerHealAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBPlayerHealAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerDmgAbsorbDD then addonTable.ufBigHBPlayerDmgAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBPlayerDmgAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerHealPredDD then addonTable.ufBigHBPlayerHealPredDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBPlayerHealPred = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetHealAbsorbDD then addonTable.ufBigHBTargetHealAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBTargetHealAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetDmgAbsorbDD then addonTable.ufBigHBTargetDmgAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBTargetDmgAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetHealPredDD then addonTable.ufBigHBTargetHealPredDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBTargetHealPred = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusHealAbsorbDD then addonTable.ufBigHBFocusHealAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBFocusHealAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusDmgAbsorbDD then addonTable.ufBigHBFocusDmgAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBFocusDmgAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusHealPredDD then addonTable.ufBigHBFocusHealPredDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBFocusHealPred = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerAbsorbStripesCB then addonTable.ufBigHBPlayerAbsorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBPlayerAbsorbStripes = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetAbsorbStripesCB then addonTable.ufBigHBTargetAbsorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBTargetAbsorbStripes = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusAbsorbStripesCB then addonTable.ufBigHBFocusAbsorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBFocusAbsorbStripes = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.autoRepairCB then addonTable.autoRepairCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoRepair = s:GetChecked() end end end
  if addonTable.showTooltipIDsCB then addonTable.showTooltipIDsCB.customOnClick = function(s) local p = GetProfile(); if p then p.showTooltipIDs = s:GetChecked() end; if addonTable.SetupTooltipIDHooks then addonTable.SetupTooltipIDHooks() end end end
  if addonTable.compactMinimapIconsCB then addonTable.compactMinimapIconsCB.customOnClick = function(s) local p = GetProfile(); if p then p.compactMinimapIcons = s:GetChecked(); if p.compactMinimapIcons then p.showMinimapButton = true; if addonTable.minimapCB then addonTable.minimapCB:SetChecked(true) end; if addonTable.ShowMinimapButton then addonTable.ShowMinimapButton() end end; if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end end end end
  if addonTable.enhancedTooltipCB then addonTable.enhancedTooltipCB.customOnClick = function(s) local p = GetProfile(); if p then p.enhancedTooltip = s:GetChecked() end; if addonTable.SetupEnhancedTooltipHook then addonTable.SetupEnhancedTooltipHook() end end end
  if addonTable.autoQuestCB then addonTable.autoQuestCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuest = s:GetChecked() end; if addonTable.SetupAutoQuest then addonTable.SetupAutoQuest() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end end end
  if addonTable.autoQuestExcludeDailyCB then addonTable.autoQuestExcludeDailyCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeDaily = s:GetChecked() end end end
  if addonTable.autoQuestExcludeWeeklyCB then addonTable.autoQuestExcludeWeeklyCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeWeekly = s:GetChecked() end end end
  if addonTable.autoQuestExcludeTrivialCB then addonTable.autoQuestExcludeTrivialCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeTrivial = s:GetChecked() end end end
  if addonTable.autoQuestExcludeCompletedCB then addonTable.autoQuestExcludeCompletedCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeCompleted = s:GetChecked() end end end
  if addonTable.autoQuestRewardDD then addonTable.autoQuestRewardDD.onSelect = function(v) local p = GetProfile(); if p then p.autoQuestRewardMode = v end end end
  if addonTable.autoSellJunkCB then addonTable.autoSellJunkCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoSellJunk = s:GetChecked() end end end
  if addonTable.autoFillDeleteCB then addonTable.autoFillDeleteCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoFillDelete = s:GetChecked() end end end
  if addonTable.quickRoleSignupCB then addonTable.quickRoleSignupCB.customOnClick = function(s) local p = GetProfile(); if p then p.quickRoleSignup = s:GetChecked() end; if addonTable.SetupQuickRoleSignup then addonTable.SetupQuickRoleSignup() end end end
  if addonTable.combatTimerCB then
    addonTable.combatTimerCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local wasOff = p.combatTimerEnabled ~= true
        p.combatTimerEnabled = s:GetChecked()
        if wasOff and p.combatTimerEnabled then p.combatTimerMode = "always" end
      end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    end
  end
  if addonTable.combatTimerModeDD then addonTable.combatTimerModeDD.onSelect = function(v) local p = GetProfile(); if p then p.combatTimerMode = v end; if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end
  if addonTable.combatTimerStyleDD then addonTable.combatTimerStyleDD.onSelect = function(v) local p = GetProfile(); if p then p.combatTimerStyle = v end; if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end
  if addonTable.combatTimerCenteredCB then addonTable.combatTimerCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.combatTimerCentered = s:GetChecked(); if p.combatTimerCentered then p.combatTimerX = 0 end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end
  if addonTable.combatTimerXSlider then addonTable.combatTimerXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatTimerX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end) end
  if addonTable.combatTimerYSlider then addonTable.combatTimerYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatTimerY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end) end
  if addonTable.combatTimerScaleSlider then addonTable.combatTimerScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatTimerScale = v; s.valueText:SetText(string.format("%.2f", v)); if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end) end
  addonTable.UpdateCombatTimerSliders = function(x, y)
    if addonTable.combatTimerXSlider then addonTable.combatTimerXSlider:SetValue(x or 0); addonTable.combatTimerXSlider.valueText:SetText(math.floor(x or 0)) end
    if addonTable.combatTimerYSlider then addonTable.combatTimerYSlider:SetValue(y or 200); addonTable.combatTimerYSlider.valueText:SetText(math.floor(y or 200)) end
  end
  if addonTable.combatTimerTextColorBtn then
    addonTable.combatTimerTextColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatTimerTextColorR or 1
      local g = p.combatTimerTextColorG or 1
      local b = p.combatTimerTextColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.combatTimerTextColorR = nr
        p.combatTimerTextColorG = ng
        p.combatTimerTextColorB = nb
        if addonTable.combatTimerTextColorSwatch then addonTable.combatTimerTextColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      local function OnCancel(prev)
        p.combatTimerTextColorR = prev.r
        p.combatTimerTextColorG = prev.g
        p.combatTimerTextColorB = prev.b
        if addonTable.combatTimerTextColorSwatch then addonTable.combatTimerTextColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.combatTimerBgColorBtn then
    addonTable.combatTimerBgColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatTimerBgColorR or 0.12
      local g = p.combatTimerBgColorG or 0.12
      local b = p.combatTimerBgColorB or 0.12
      local a = p.combatTimerBgAlpha or 0.85
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local na = ColorPickerFrame:GetColorAlpha() or 1
        p.combatTimerBgColorR = nr
        p.combatTimerBgColorG = ng
        p.combatTimerBgColorB = nb
        p.combatTimerBgAlpha = na
        if addonTable.combatTimerBgColorSwatch then addonTable.combatTimerBgColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      local function OnCancel(prev)
        p.combatTimerBgColorR = prev.r
        p.combatTimerBgColorG = prev.g
        p.combatTimerBgColorB = prev.b
        p.combatTimerBgAlpha = a
        if addonTable.combatTimerBgColorSwatch then addonTable.combatTimerBgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnColorChanged, opacityFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.crTimerCB then addonTable.crTimerCB.customOnClick = function(s) local p = GetProfile(); if p then local wasOff = p.crTimerEnabled ~= true; p.crTimerEnabled = s:GetChecked(); if wasOff and p.crTimerEnabled then p.crTimerMode = "always" end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerModeDD then addonTable.crTimerModeDD.onSelect = function(v) local p = GetProfile(); if p then p.crTimerMode = v end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerLayoutDD then addonTable.crTimerLayoutDD.onSelect = function(v) local p = GetProfile(); if p then p.crTimerLayout = v end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerDisplayDD then addonTable.crTimerDisplayDD.onSelect = function(v) local p = GetProfile(); if p then p.crTimerDisplay = v end; local enableLayout = v ~= "count"; if addonTable.crTimerLayoutDD then addonTable.crTimerLayoutDD:SetEnabled(enableLayout) end; if addonTable.crTimerLayoutLbl then addonTable.crTimerLayoutLbl:SetTextColor(enableLayout and 0.9 or 0.4, enableLayout and 0.9 or 0.4, enableLayout and 0.9 or 0.4) end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerCenteredCB then addonTable.crTimerCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.crTimerCentered = s:GetChecked(); if p.crTimerCentered then p.crTimerX = 0 end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerXSlider then addonTable.crTimerXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.crTimerX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end) end
  if addonTable.crTimerYSlider then addonTable.crTimerYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.crTimerY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end) end
  if addonTable.crTimerScaleSlider then addonTable.crTimerScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.crTimerScale = v; s.valueText:SetText(string.format("%.2f", v)); if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end) end
  addonTable.UpdateCRTimerSliders = function(x, y)
    if addonTable.crTimerXSlider then addonTable.crTimerXSlider:SetValue(x or 0); addonTable.crTimerXSlider.valueText:SetText(math.floor(x or 0)) end
    if addonTable.crTimerYSlider then addonTable.crTimerYSlider:SetValue(y or 150); addonTable.crTimerYSlider.valueText:SetText(math.floor(y or 150)) end
  end
  if addonTable.combatStatusCB then addonTable.combatStatusCB.customOnClick = function(s) local p = GetProfile(); if p then p.combatStatusEnabled = s:GetChecked() end; if not s:GetChecked() and addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end; if addonTable.combatStatusPreviewOnBtn then SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, false) end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end
  if addonTable.combatStatusCenteredCB then addonTable.combatStatusCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.combatStatusCentered = s:GetChecked(); if p.combatStatusCentered then p.combatStatusX = 0 end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end
  if addonTable.combatStatusXSlider then addonTable.combatStatusXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatStatusX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end) end
  if addonTable.combatStatusYSlider then addonTable.combatStatusYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatStatusY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end) end
  if addonTable.combatStatusScaleSlider then addonTable.combatStatusScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatStatusScale = v; s.valueText:SetText(string.format("%.2f", v)); if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end) end
  addonTable.UpdateCombatStatusSliders = function(x, y)
    if addonTable.combatStatusXSlider then addonTable.combatStatusXSlider:SetValue(x or 0); addonTable.combatStatusXSlider.valueText:SetText(math.floor(x or 0)) end
    if addonTable.combatStatusYSlider then addonTable.combatStatusYSlider:SetValue(y or 280); addonTable.combatStatusYSlider.valueText:SetText(math.floor(y or 280)) end
  end
  if addonTable.combatStatusEnterColorBtn then
    addonTable.combatStatusEnterColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatStatusEnterColorR or 1
      local g = p.combatStatusEnterColorG or 1
      local b = p.combatStatusEnterColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.combatStatusEnterColorR = nr
        p.combatStatusEnterColorG = ng
        p.combatStatusEnterColorB = nb
        if addonTable.combatStatusEnterColorSwatch then addonTable.combatStatusEnterColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      local function OnCancel(prev)
        p.combatStatusEnterColorR = prev.r
        p.combatStatusEnterColorG = prev.g
        p.combatStatusEnterColorB = prev.b
        if addonTable.combatStatusEnterColorSwatch then addonTable.combatStatusEnterColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.combatStatusLeaveColorBtn then
    addonTable.combatStatusLeaveColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatStatusLeaveColorR or 1
      local g = p.combatStatusLeaveColorG or 1
      local b = p.combatStatusLeaveColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.combatStatusLeaveColorR = nr
        p.combatStatusLeaveColorG = ng
        p.combatStatusLeaveColorB = nb
        if addonTable.combatStatusLeaveColorSwatch then addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      local function OnCancel(prev)
        p.combatStatusLeaveColorR = prev.r
        p.combatStatusLeaveColorG = prev.g
        p.combatStatusLeaveColorB = prev.b
        if addonTable.combatStatusLeaveColorSwatch then addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.combatStatusPreviewOnBtn then
    addonTable.combatStatusPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowCombatStatusPreview then addonTable.ShowCombatStatusPreview() end
      SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, true)
    end)
  end
  if addonTable.combatStatusPreviewOffBtn then
    addonTable.combatStatusPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end
      SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, false)
    end)
  end
  if addonTable.minimapCB then addonTable.minimapCB.customOnClick = function(s) local p = GetProfile(); if p then if p.compactMinimapIcons == true then s:SetChecked(true); p.showMinimapButton = true; if addonTable.ShowMinimapButton then addonTable.ShowMinimapButton() end; return end; p.showMinimapButton = s:GetChecked(); if s:GetChecked() then addonTable.ShowMinimapButton() else addonTable.HideMinimapButton() end end end end
  if addonTable.radiusSlider then addonTable.radiusSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.radialRadius = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end end end) end
  if addonTable.radialThicknessDD then addonTable.radialThicknessDD.onSelect = function(v) local p = GetProfile(); if p then p.radialThickness = PresetToRadialThickness(v); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end end end end
  if addonTable.selfHighlightCB then
    addonTable.selfHighlightCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked()
        p.selfHighlightShape = enabled and "cross" or "off"
        if addonTable.selfHighlightVisibilityDD then addonTable.selfHighlightVisibilityDD:SetEnabled(enabled) end
        if addonTable.selfHighlightSizeSlider then addonTable.selfHighlightSizeSlider:SetEnabled(enabled) end
        if addonTable.selfHighlightYSlider then addonTable.selfHighlightYSlider:SetEnabled(enabled) end
        if addonTable.selfHighlightThicknessDD then addonTable.selfHighlightThicknessDD:SetEnabled(enabled) end
        if addonTable.selfHighlightThicknessLbl then addonTable.selfHighlightThicknessLbl:SetTextColor(enabled and 0.9 or 0.4, enabled and 0.9 or 0.4, enabled and 0.9 or 0.4) end
        if addonTable.selfHighlightOutlineCB then addonTable.selfHighlightOutlineCB:SetEnabled(enabled) end
        if addonTable.selfHighlightColorBtn then addonTable.selfHighlightColorBtn:SetEnabled(enabled) end
        if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
      end
    end
  end
  if addonTable.selfHighlightVisibilityDD then addonTable.selfHighlightVisibilityDD.onSelect = function(v) local p = GetProfile(); if p then p.selfHighlightCombatOnly = (v == "combat"); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end end
  if addonTable.selfHighlightSizeSlider then addonTable.selfHighlightSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.selfHighlightSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end) end
  if addonTable.selfHighlightYSlider then addonTable.selfHighlightYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.selfHighlightY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end) end
  if addonTable.selfHighlightThicknessDD then addonTable.selfHighlightThicknessDD.onSelect = function(v) local p = GetProfile(); if p then p.selfHighlightThickness = v; if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end end
  if addonTable.selfHighlightOutlineCB then addonTable.selfHighlightOutlineCB.customOnClick = function(s) local p = GetProfile(); if p then p.selfHighlightOutline = s:GetChecked(); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end end
  if addonTable.selfHighlightColorBtn then
    addonTable.selfHighlightColorBtn:SetScript("OnClick", function()
      local profile = GetProfile()
      if not profile then return end
      local r = profile.selfHighlightColorR or 1
      local g = profile.selfHighlightColorG or 1
      local b = profile.selfHighlightColorB or 1
      local a = profile.selfHighlightAlpha or 1
      local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = ColorPickerFrame:GetColorAlpha() or 1
        profile.selfHighlightColorR = newR
        profile.selfHighlightColorG = newG
        profile.selfHighlightColorB = newB
        profile.selfHighlightAlpha = newA
        if addonTable.selfHighlightColorSwatch then addonTable.selfHighlightColorSwatch:SetBackdropColor(newR, newG, newB, 1) end
        if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
      end
      local function OnCancel(prevValues)
        profile.selfHighlightColorR = prevValues.r
        profile.selfHighlightColorG = prevValues.g
        profile.selfHighlightColorB = prevValues.b
        profile.selfHighlightAlpha = a
        if addonTable.selfHighlightColorSwatch then addonTable.selfHighlightColorSwatch:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, 1) end
        if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
      end
      ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnColorChanged, opacityFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.noTargetAlertCB then
    addonTable.noTargetAlertCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.noTargetAlertEnabled = s:GetChecked()
        local enabled = s:GetChecked()
        if addonTable.noTargetAlertFlashCB then addonTable.noTargetAlertFlashCB:SetEnabled(enabled) end
        if addonTable.noTargetAlertXSlider then addonTable.noTargetAlertXSlider:SetEnabled(enabled) end
        if addonTable.noTargetAlertYSlider then addonTable.noTargetAlertYSlider:SetEnabled(enabled) end
        if addonTable.noTargetAlertFontSizeSlider then addonTable.noTargetAlertFontSizeSlider:SetEnabled(enabled) end
        if addonTable.noTargetAlertColorBtn then addonTable.noTargetAlertColorBtn:SetEnabled(enabled) end
        if addonTable.UpdateNoTargetAlert then addonTable.UpdateNoTargetAlert() end
      end
    end
  end
  if addonTable.noTargetAlertFlashCB then
    addonTable.noTargetAlertFlashCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.noTargetAlertFlash = s:GetChecked()
        if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end
      end
    end
  end
  if addonTable.noTargetAlertPreviewOnBtn then
    addonTable.noTargetAlertPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowNoTargetAlertPreview then addonTable.ShowNoTargetAlertPreview() end
      SetButtonHighlighted(addonTable.noTargetAlertPreviewOnBtn, true)
    end)
  end
  if addonTable.noTargetAlertPreviewOffBtn then
    addonTable.noTargetAlertPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopNoTargetAlertPreview then addonTable.StopNoTargetAlertPreview() end
      SetButtonHighlighted(addonTable.noTargetAlertPreviewOnBtn, false)
    end)
  end
  if addonTable.noTargetAlertXSlider then addonTable.noTargetAlertXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.noTargetAlertX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end end end) end
  if addonTable.noTargetAlertYSlider then addonTable.noTargetAlertYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.noTargetAlertY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end end end) end
  if addonTable.noTargetAlertFontSizeSlider then addonTable.noTargetAlertFontSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.noTargetAlertFontSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end end end) end
  if addonTable.noTargetAlertColorBtn then
    addonTable.noTargetAlertColorBtn:SetScript("OnClick", function()
      local profile = GetProfile()
      if not profile then return end
      local r = profile.noTargetAlertColorR or 1
      local g = profile.noTargetAlertColorG or 0
      local b = profile.noTargetAlertColorB or 0
      local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        profile.noTargetAlertColorR = newR
        profile.noTargetAlertColorG = newG
        profile.noTargetAlertColorB = newB
        if addonTable.noTargetAlertColorSwatch then addonTable.noTargetAlertColorSwatch:SetBackdropColor(newR, newG, newB, 1) end
        if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end
      end
      local function OnCancel(prevValues)
        profile.noTargetAlertColorR = prevValues.r
        profile.noTargetAlertColorG = prevValues.g
        profile.noTargetAlertColorB = prevValues.b
        if addonTable.noTargetAlertColorSwatch then addonTable.noTargetAlertColorSwatch:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, 1) end
        if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.lowHealthWarningCB then
    addonTable.lowHealthWarningCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.lowHealthWarningEnabled = s:GetChecked()
        local enabled = s:GetChecked()
        if enabled then
          SetCVar("doNotFlashLowHealthWarning", "0")
        else
          SetCVar("doNotFlashLowHealthWarning", "1")
        end
        if addonTable.lowHealthWarningFlashCB then addonTable.lowHealthWarningFlashCB:SetEnabled(enabled) end
        if addonTable.lowHealthWarningTextBox then addonTable.lowHealthWarningTextBox:SetEnabled(enabled) end
        if addonTable.lowHealthWarningFontSizeSlider then addonTable.lowHealthWarningFontSizeSlider:SetEnabled(enabled) end
        if addonTable.lowHealthWarningXSlider then addonTable.lowHealthWarningXSlider:SetEnabled(enabled) end
        if addonTable.lowHealthWarningYSlider then addonTable.lowHealthWarningYSlider:SetEnabled(enabled) end
        if addonTable.lowHealthWarningSoundDD then addonTable.lowHealthWarningSoundDD:SetEnabled(enabled) end
        if addonTable.lowHealthWarningColorBtn then addonTable.lowHealthWarningColorBtn:SetEnabled(enabled) end
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
      end
    end
  end
  if addonTable.lowHealthWarningFlashCB then
    addonTable.lowHealthWarningFlashCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.lowHealthWarningFlash = s:GetChecked()
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
    end
  end
  if addonTable.lowHealthWarningTextBox then
    addonTable.lowHealthWarningTextBox:SetScript("OnEnterPressed", function(self)
      local p = GetProfile()
      if p then
        p.lowHealthWarningText = self:GetText()
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
      self:ClearFocus()
    end)
    addonTable.lowHealthWarningTextBox:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
    end)
  end
  if addonTable.lowHealthWarningFontSizeSlider then
    addonTable.lowHealthWarningFontSizeSlider:SetScript("OnValueChanged", function(s, v)
      local p = GetProfile()
      if p then
        p.lowHealthWarningFontSize = math.floor(v)
        s.valueText:SetText(math.floor(v))
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
    end)
  end
  if addonTable.lowHealthWarningXSlider then
    addonTable.lowHealthWarningXSlider:SetScript("OnValueChanged", function(s, v)
      local p = GetProfile()
      if p then
        p.lowHealthWarningX = math.floor(v)
        s.valueText:SetText(math.floor(v))
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
    end)
  end
  if addonTable.lowHealthWarningYSlider then
    addonTable.lowHealthWarningYSlider:SetScript("OnValueChanged", function(s, v)
      local p = GetProfile()
      if p then
        p.lowHealthWarningY = math.floor(v)
        s.valueText:SetText(math.floor(v))
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
    end)
  end
  if addonTable.lowHealthWarningSoundDD then
    addonTable.lowHealthWarningSoundDD.onSelect = function(v)
      local p = GetProfile()
      if p then p.lowHealthWarningSound = v end
    end
  end
  if addonTable.lowHealthWarningColorBtn then
    addonTable.lowHealthWarningColorBtn:SetScript("OnClick", function()
      local profile = GetProfile()
      if not profile then return end
      local r = profile.lowHealthWarningColorR or 1
      local g = profile.lowHealthWarningColorG or 0
      local b = profile.lowHealthWarningColorB or 0
      local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        profile.lowHealthWarningColorR = newR
        profile.lowHealthWarningColorG = newG
        profile.lowHealthWarningColorB = newB
        if addonTable.lowHealthWarningColorSwatch then addonTable.lowHealthWarningColorSwatch:SetBackdropColor(newR, newG, newB, 1) end
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
      local function OnCancel(prevValues)
        profile.lowHealthWarningColorR = prevValues.r
        profile.lowHealthWarningColorG = prevValues.g
        profile.lowHealthWarningColorB = prevValues.b
        if addonTable.lowHealthWarningColorSwatch then addonTable.lowHealthWarningColorSwatch:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, 1) end
        if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
        if addonTable.UpdateLowHealthWarningPreviewIfActive then addonTable.UpdateLowHealthWarningPreviewIfActive() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.lowHealthWarningPreviewOnBtn then
    addonTable.lowHealthWarningPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowLowHealthWarningPreview then addonTable.ShowLowHealthWarningPreview() end
      SetButtonHighlighted(addonTable.lowHealthWarningPreviewOnBtn, true)
    end)
  end
  if addonTable.lowHealthWarningPreviewOffBtn then
    addonTable.lowHealthWarningPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopLowHealthWarningPreview then addonTable.StopLowHealthWarningPreview() end
      SetButtonHighlighted(addonTable.lowHealthWarningPreviewOnBtn, false)
    end)
  end
  local ApplySerializedDataToProfile
  local EXAMPLE_IMPORT_DATA_DPS_TANK
  local function CreateExampleProfile(role, profileName)
    local exampleProfiles = CCM and CCM.Defaults and CCM.Defaults.exampleProfiles
    if not exampleProfiles or not exampleProfiles[role] then
      print("|cffff6666CCM:|r Example profile '" .. role .. "' not found!")
      return
    end
    if CooldownCursorManagerDB.profiles[profileName] then
      print("|cffff6666CCM:|r Profile '" .. profileName .. "' already exists!")
      return
    end
    local defaults = CCM and CCM.Defaults and CCM.Defaults.profiles and CCM.Defaults.profiles.Default
    CooldownCursorManagerDB.profiles[profileName] = {}
    local newProfile = CooldownCursorManagerDB.profiles[profileName]
    if defaults then
      for key, value in pairs(defaults) do
        if type(value) == "table" then
          newProfile[key] = {}
          for k, v in pairs(value) do newProfile[key][k] = v end
        else
          newProfile[key] = value
        end
      end
    end
    if (role == "DPS" or role == "Tank") and EXAMPLE_IMPORT_DATA_DPS_TANK ~= "" then
      ApplySerializedDataToProfile(newProfile, EXAMPLE_IMPORT_DATA_DPS_TANK)
    else
      for key, value in pairs(exampleProfiles[role]) do
        newProfile[key] = value
      end
    end
    CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
    CooldownCursorManagerDB.profileClasses[profileName] = nil
    CooldownCursorManagerDB.currentProfile = profileName
    if addonTable.SaveCurrentProfileForSpec then
      addonTable.SaveCurrentProfileForSpec()
    end
    UpdateProfileList()
    UpdateProfileDisplay()
    UpdateAllControls()
    CreateIcons()
    if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
    if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
    if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
    if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
    if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
    if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
    if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
    if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
    if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
    if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
    if addonTable.UpdatePRB then addonTable.UpdatePRB() end
    if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
    if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
    if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
    if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end
    if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end
    print("|cff00ff00CCM:|r Created example profile: " .. profileName)
    ShowReloadPrompt("Example profile '" .. profileName .. "' created.\n\nA UI reload is recommended. Reload now?", "Reload", "Later")
  end
  local function ShowExampleProfileDialog(role, roleColor)
    local popup = addonTable.examplePopup
    local title = addonTable.examplePopupTitle
    local editBox = addonTable.examplePopupEditBox
    local okBtn = addonTable.examplePopupOkBtn
    if not popup then return end
    title:SetText("Create |cff" .. roleColor .. role .. "|r Profile")
    editBox:SetText(role)
    okBtn:SetScript("OnClick", function()
      local name = editBox:GetText()
      if name and name ~= "" then
        CreateExampleProfile(role, name)
        popup:Hide()
      end
    end)
    popup:Show()
    editBox:SetFocus()
    editBox:HighlightText()
  end
  if addonTable.exampleProfileDPSBtn then
    addonTable.exampleProfileDPSBtn:SetScript("OnClick", function()
      ShowExampleProfileDialog("DPS", "ff4444")
    end)
  end
  if addonTable.exampleProfileTankBtn then
    addonTable.exampleProfileTankBtn:SetScript("OnClick", function()
      ShowExampleProfileDialog("Tank", "4488ff")
    end)
  end
  if addonTable.exampleProfileHealerBtn then
    addonTable.exampleProfileHealerBtn:SetScript("OnClick", function()
      ShowExampleProfileDialog("Healer", "44ff88")
    end)
  end
  local cur = addonTable.cursor
  if cur then
    if cur.combatOnlyCB then cur.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.iconsCombatOnly = s:GetChecked(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.gcdCB then cur.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.cursorShowGCD = s:GetChecked(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.iconSizeSlider then cur.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.iconSize = math.floor(v); s.valueText:SetText(math.floor(v)); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.spacingSlider then cur.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.iconSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.cdTextSlider then cur.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.cdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.cdGradientSlider then cur.cdGradientSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then local fv = math.floor(v); p.cdTextGradientThreshold = fv; s.valueText:SetText(fv > 0 and fv or "Off"); if cur.cdGradientColorSwatch then cur.cdGradientColorSwatch:SetShown(fv > 0) end; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.cdGradientColorSwatch then cur.cdGradientColorSwatch:SetScript("OnMouseDown", function() local p = GetProfile(); if not p then return end; local r = p.cdTextGradientR or 1; local g = p.cdTextGradientG or 0; local b = p.cdTextGradientB or 0; local function OnColorChanged() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); p.cdTextGradientR = nr; p.cdTextGradientG = ng; p.cdTextGradientB = nb; if cur.cdGradientColorSwatch then cur.cdGradientColorSwatch:SetBackdropColor(nr, ng, nb, 1) end; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end; local function OnCancel(prev) p.cdTextGradientR = prev.r; p.cdTextGradientG = prev.g; p.cdTextGradientB = prev.b; if cur.cdGradientColorSwatch then cur.cdGradientColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end; ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel}) end) end
    if cur.stackTextSlider then cur.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.stackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.iconsPerRowSlider then cur.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.iconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.cooldownModeDD then cur.cooldownModeDD.onSelect = function(v)
      local p = GetProfile(); if p then p.cooldownIconMode = v; if cur.customHideRevealCB then cur.customHideRevealCB:SetEnabled(v == "hide"); if v ~= "hide" then cur.customHideRevealCB:SetChecked(false); p.useCustomHideReveal = false end end; if addonTable.RefreshCursorSpellList then addonTable.RefreshCursorSpellList() end; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end
    end end
    if cur.alwaysShowInCB then cur.alwaysShowInCB.customOnClick = function(s) local p = GetProfile(); if p then p.alwaysShowInEnabled = s:GetChecked(); if cur.alwaysShowInDD then cur.alwaysShowInDD:SetEnabled(s:GetChecked()) end; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.alwaysShowInDD then cur.alwaysShowInDD.onSelect = function(v) local p = GetProfile(); if p then p.alwaysShowInMode = v; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.offsetXSlider then cur.offsetXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.offsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.offsetYSlider then cur.offsetYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.offsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.directionDD then cur.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.layoutDirection = v; CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.addSpellBtn then
      cur.addSpellBtn:SetScript("OnClick", function()
        local id = tonumber(cur.addBox:GetText())
        if id and addonTable.GetSpellList then
          local s,e = addonTable.GetSpellList()
          table.insert(s, id)
          addonTable.SetSpellList(s,e)
          cur.addBox:SetText("")
          RefreshCursorSpellList()
          CreateIcons()
        end
      end)
    end
    if cur.addItemBtn then
      cur.addItemBtn:SetScript("OnClick", function()
        local id = tonumber(cur.addBox:GetText())
        if id and addonTable.GetSpellList then
          local s,e = addonTable.GetSpellList()
          table.insert(s, -id)
          addonTable.SetSpellList(s,e)
          cur.addBox:SetText("")
          RefreshCursorSpellList()
          CreateIcons()
        end
      end)
    end
    if cur.addTrinketsBtn then
      cur.addTrinketsBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local added = 0
        for _, slot in ipairs({13, 14}) do
          local trinketID = GetInventoryItemID("player", slot)
          if trinketID then
            local spellName = C_Item.GetItemSpell(trinketID)
            if spellName then
              local exists = false
              for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end
              if not exists then table.insert(s, -trinketID); added = added + 1 end
            end
          end
        end
        if added > 0 then addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
      end)
    end
    if cur.addRacialBtn then
      cur.addRacialBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local added = 0
        local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}
        for _, spellID in ipairs(racialSpells) do
          if C_SpellBook.IsSpellKnown(spellID) then
            local exists = false
            for _, id in ipairs(s) do if id == spellID then exists = true; break end end
            if not exists then table.insert(s, spellID); added = added + 1 end
          end
        end
        if added > 0 then addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
      end)
    end
    if cur.addPotionBtn then
      cur.addPotionBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local added = 0
        for bag = 0, 4 do
          local numSlots = C_Container.GetContainerNumSlots(bag)
          for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
              local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
              if classID == 0 and subClassID == 1 then
                local spellName = C_Item.GetItemSpell(itemID)
                if spellName then
                  local exists = false
                  for _, id in ipairs(s) do if id == -itemID then exists = true; break end end
                  if not exists then table.insert(s, -itemID); added = added + 1 end
                end
              end
            end
          end
        end
        local _, _, playerClassID = UnitClass("player")
        local hsID = playerClassID == 9 and 224464 or 5512
        local hsExists = false
        for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end
        if not hsExists then table.insert(s, -hsID); added = added + 1 end
        if added > 0 then addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
      end)
    end
    if cur.addGCSBtn then
      cur.addGCSBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local gcsID = 188152
        local found = false
        for bag = 0, 4 do
          local numSlots = C_Container.GetContainerNumSlots(bag)
          for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID == gcsID then found = true; break end
          end
          if found then break end
        end
        if found then
          local exists = false
          for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end
          if not exists then table.insert(s, -gcsID); addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
        end
      end)
    end
    if cur.addBox then
      cur.addBox:SetScript("OnEnterPressed", function()
        if cur.addSpellBtn then cur.addSpellBtn:Click() end
        cur.addBox:ClearFocus()
      end)
    end
    if cur.stackAnchorDD then cur.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.stackTextPosition = v; if addonTable.UpdateStackTextPositions then addonTable.UpdateStackTextPositions() end end end end
    if cur.buffOverlayCB then
      cur.buffOverlayCB:SetChecked(false)
      cur.buffOverlayCB:SetEnabled(false)
      if cur.buffOverlayCB.label and cur.buffOverlayCB.label.Hide then cur.buffOverlayCB.label:Hide() end
      if cur.buffOverlayCB.Hide then cur.buffOverlayCB:Hide() end
    end
    if cur.trackBuffsCB then cur.trackBuffsCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      p.trackBuffs = s:GetChecked()
      if cur.openBlizzBuffBtn then cur.openBlizzBuffBtn:SetShown(s:GetChecked()) end
      if s:GetChecked() == true then
        local forcedOff, needsReload = EnsureDisableBlizzCDMCompatible(p)
        if forcedOff and addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(true) end
        if forcedOff then
          ShowReloadPrompt("Track Buffs requires Blizzard CDM. Blizz CDM has been re-enabled. Reload now?", "Reload", "Later")
        elseif needsReload then
          ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
        end
      end
      RefreshCursorSpellList()
      if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
      if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
      if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    end end
    AttachCheckboxTooltip(cur.trackBuffsCB, TRACK_BUFFS_TOOLTIP_TEXT, {anchor = "ANCHOR_LEFT", minWidth = 360})
    if cur.useGlowsCB then cur.useGlowsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked() == true
        p.useSpellGlows = enabled
        if cur.glowSpeedSlider then SetStyledSliderShown(cur.glowSpeedSlider, enabled) end
        if cur.glowThicknessSlider then SetStyledSliderShown(cur.glowThicknessSlider, enabled) end
        RefreshCursorSpellList()
        UpdateAllIcons()
      end
    end end
    if cur.customHideRevealCB then cur.customHideRevealCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.useCustomHideReveal = s:GetChecked() == true
        RefreshCursorSpellList()
      end
    end end
    if cur.glowSpeedSlider then cur.glowSpeedSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowSpeed = tonumber(string.format("%.1f", v)) or 0.0; s.valueText:SetText(string.format("%.1f", p.spellGlowSpeed)); UpdateAllIcons(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cur.glowThicknessSlider then cur.glowThicknessSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowThickness = tonumber(string.format("%.1f", v)) or 2.0; s.valueText:SetText(string.format("%.1f", p.spellGlowThickness)); UpdateAllIcons(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cur.stackXSlider then cur.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.stackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStackTextPositions then addonTable.UpdateStackTextPositions() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.stackYSlider then cur.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.stackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStackTextPositions then addonTable.UpdateStackTextPositions() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if tabFrames and tabFrames[2] then
      SetupDragDrop(tabFrames[2], addonTable.GetSpellList, addonTable.SetSpellList, RefreshCursorSpellList, CreateIcons, nil, {cur.spellBg, cur.spellScroll, cur.spellChild})
    end
  end
  local cb1 = addonTable.cb1
  if cb1 then
    if cb1.combatOnlyCB then cb1.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBarOutOfCombat = not s:GetChecked(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.gcdCB then cb1.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBarShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.buffOverlayCB then
      cb1.buffOverlayCB:SetChecked(false)
      cb1.buffOverlayCB:SetEnabled(false)
      if cb1.buffOverlayCB.label and cb1.buffOverlayCB.label.Hide then cb1.buffOverlayCB.label:Hide() end
      if cb1.buffOverlayCB.Hide then cb1.buffOverlayCB:Hide() end
    end
    if cb1.trackBuffsCB then cb1.trackBuffsCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      p.customBarTrackBuffs = s:GetChecked()
      if cb1.openBlizzBuffBtn then cb1.openBlizzBuffBtn:SetShown(s:GetChecked()) end
      if s:GetChecked() == true then
        local forcedOff, needsReload = EnsureDisableBlizzCDMCompatible(p)
        if forcedOff and addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(true) end
        if forcedOff then
          ShowReloadPrompt("Track Buffs requires Blizzard CDM. Blizz CDM has been re-enabled. Reload now?", "Reload", "Later")
        elseif needsReload then
          ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
        end
      end
      RefreshCB1SpellList()
      if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
      if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
      if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    end end
    AttachCheckboxTooltip(cb1.trackBuffsCB, TRACK_BUFFS_TOOLTIP_TEXT, {anchor = "ANCHOR_LEFT", minWidth = 360})
    if cb1.useGlowsCB then cb1.useGlowsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked() == true
        p.customBarUseSpellGlows = enabled
        if cb1.glowSpeedSlider then SetStyledSliderShown(cb1.glowSpeedSlider, enabled) end
        if cb1.glowThicknessSlider then SetStyledSliderShown(cb1.glowThicknessSlider, enabled) end
        RefreshCB1SpellList()
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      end
    end end
    if cb1.customHideRevealCB then cb1.customHideRevealCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBarUseCustomHideReveal = s:GetChecked() == true
        RefreshCB1SpellList()
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      end
    end end
    if cb1.glowSpeedSlider then cb1.glowSpeedSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowSpeed = tonumber(string.format("%.1f", v)) or 0.0; s.valueText:SetText(string.format("%.1f", p.spellGlowSpeed)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb1.glowThicknessSlider then cb1.glowThicknessSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowThickness = tonumber(string.format("%.1f", v)) or 2.0; s.valueText:SetText(string.format("%.1f", p.spellGlowThickness)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb1.centeredCB then cb1.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBarCentered = s:GetChecked()
        if s:GetChecked() then
          p.customBarX = 0
          if cb1.xSlider then cb1.xSlider:SetValue(0); cb1.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      end
    end end
    if cb1.iconSizeSlider then cb1.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarIconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.spacingSlider then cb1.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.cdTextSlider then cb1.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarCdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.cdGradientSlider then cb1.cdGradientSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then local fv = math.floor(v); p.customBarCdGradientThreshold = fv; s.valueText:SetText(fv > 0 and fv or "Off"); if cb1.cdGradientColorSwatch then cb1.cdGradientColorSwatch:SetShown(fv > 0) end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.cdGradientColorSwatch then cb1.cdGradientColorSwatch:SetScript("OnMouseDown", function() local p = GetProfile(); if not p then return end; local r = p.customBarCdGradientR or 1; local g = p.customBarCdGradientG or 0; local b = p.customBarCdGradientB or 0; local function OnColorChanged() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); p.customBarCdGradientR = nr; p.customBarCdGradientG = ng; p.customBarCdGradientB = nb; if cb1.cdGradientColorSwatch then cb1.cdGradientColorSwatch:SetBackdropColor(nr, ng, nb, 1) end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end; local function OnCancel(prev) p.customBarCdGradientR = prev.r; p.customBarCdGradientG = prev.g; p.customBarCdGradientB = prev.b; if cb1.cdGradientColorSwatch then cb1.cdGradientColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end; ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel}) end) end
    if cb1.stackTextSlider then cb1.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarStackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.iconsPerRowSlider then cb1.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.cdModeDD then cb1.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarCooldownMode = v; if cb1.customHideRevealCB then cb1.customHideRevealCB:SetEnabled(v == "hide"); if v ~= "hide" then cb1.customHideRevealCB:SetChecked(false); p.customBarUseCustomHideReveal = false end end; if addonTable.RefreshCB1SpellList then addonTable.RefreshCB1SpellList() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.showModeDD then cb1.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarShowMode = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.xSlider then cb1.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.ySlider then cb1.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.directionDD then cb1.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarDirection = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.anchorDD then cb1.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarAnchorPoint = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.growthDD then cb1.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarGrowth = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.anchorTargetDD then
      cb1.anchorTargetDD.refreshOptions = function(dd) if addonTable.GetAnchorFrameOptions then dd:SetOptions(addonTable.GetAnchorFrameOptions(1)) end end
      cb1.anchorTargetDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarAnchorFrame = v; p.customBarX = 0; p.customBarY = 0; if cb1.xSlider then cb1.xSlider:SetValue(0); cb1.xSlider.valueText:SetText("0") end; if cb1.ySlider then cb1.ySlider:SetValue(0); cb1.ySlider.valueText:SetText("0") end; if v == "UIParent" then p.customBarAnchorToPoint = "CENTER"; if cb1.anchorToPointDD then cb1.anchorToPointDD:SetValue("CENTER") end end; if cb1.anchorToPointDD then cb1.anchorToPointDD:SetEnabled(v ~= "UIParent") end; if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end
    end
    if cb1.anchorToPointDD then cb1.anchorToPointDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarAnchorToPoint = v; if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.stackAnchorDD then cb1.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarStackTextPosition = v; if addonTable.UpdateCustomBarStackTextPositions then addonTable.UpdateCustomBarStackTextPositions() end end end end
    if cb1.stackXSlider then cb1.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarStackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarStackTextPositions then addonTable.UpdateCustomBarStackTextPositions() end end end) end
    if cb1.stackYSlider then cb1.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarStackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarStackTextPositions then addonTable.UpdateCustomBarStackTextPositions() end end end) end
    if cb1.addSpellBtn then cb1.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb1.addBox:GetText()); if id and addonTable.GetCustomBarSpells then local s,e = addonTable.GetCustomBarSpells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBarSpells(s,e); cb1.addBox:SetText(""); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addItemBtn then cb1.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb1.addBox:GetText()); if id and addonTable.GetCustomBarSpells then local s,e = addonTable.GetCustomBarSpells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBarSpells(s,e); cb1.addBox:SetText(""); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addTrinketsBtn then cb1.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = C_Item.GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addRacialBtn then cb1.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if C_SpellBook.IsSpellKnown(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addPotionBtn then cb1.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = C_Item.GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addGCSBtn then cb1.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end) end
    if cb1.addBox then cb1.addBox:SetScript("OnEnterPressed", function() if cb1.addSpellBtn then cb1.addSpellBtn:Click() end; cb1.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[3] then SetupDragDrop(tabFrames[3], addonTable.GetCustomBarSpells, addonTable.SetCustomBarSpells, RefreshCB1SpellList, addonTable.CreateCustomBarIcons, addonTable.UpdateCustomBar, {cb1.spellBg, cb1.spellScroll, cb1.spellChild}) end
  end
  local cb2 = addonTable.cb2
  if cb2 then
    if cb2.combatOnlyCB then cb2.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar2OutOfCombat = not s:GetChecked(); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.gcdCB then cb2.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar2ShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.buffOverlayCB then
      cb2.buffOverlayCB:SetChecked(false)
      cb2.buffOverlayCB:SetEnabled(false)
      if cb2.buffOverlayCB.label and cb2.buffOverlayCB.label.Hide then cb2.buffOverlayCB.label:Hide() end
      if cb2.buffOverlayCB.Hide then cb2.buffOverlayCB:Hide() end
    end
    if cb2.trackBuffsCB then cb2.trackBuffsCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      p.customBar2TrackBuffs = s:GetChecked()
      if cb2.openBlizzBuffBtn then cb2.openBlizzBuffBtn:SetShown(s:GetChecked()) end
      if s:GetChecked() == true then
        local forcedOff, needsReload = EnsureDisableBlizzCDMCompatible(p)
        if forcedOff and addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(true) end
        if forcedOff then
          ShowReloadPrompt("Track Buffs requires Blizzard CDM. Blizz CDM has been re-enabled. Reload now?", "Reload", "Later")
        elseif needsReload then
          ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
        end
      end
      RefreshCB2SpellList()
      if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
      if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
      if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    end end
    AttachCheckboxTooltip(cb2.trackBuffsCB, TRACK_BUFFS_TOOLTIP_TEXT, {anchor = "ANCHOR_LEFT", minWidth = 360})
    if cb2.useGlowsCB then cb2.useGlowsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked() == true
        p.customBar2UseSpellGlows = enabled
        if cb2.glowSpeedSlider then SetStyledSliderShown(cb2.glowSpeedSlider, enabled) end
        if cb2.glowThicknessSlider then SetStyledSliderShown(cb2.glowThicknessSlider, enabled) end
        RefreshCB2SpellList()
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      end
    end end
    if cb2.customHideRevealCB then cb2.customHideRevealCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar2UseCustomHideReveal = s:GetChecked() == true
        RefreshCB2SpellList()
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      end
    end end
    if cb2.glowSpeedSlider then cb2.glowSpeedSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowSpeed = tonumber(string.format("%.1f", v)) or 0.0; s.valueText:SetText(string.format("%.1f", p.spellGlowSpeed)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb2.glowThicknessSlider then cb2.glowThicknessSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowThickness = tonumber(string.format("%.1f", v)) or 2.0; s.valueText:SetText(string.format("%.1f", p.spellGlowThickness)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb2.centeredCB then cb2.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar2Centered = s:GetChecked()
        if s:GetChecked() then
          p.customBar2X = 0
          if cb2.xSlider then cb2.xSlider:SetValue(0); cb2.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      end
    end end
    if cb2.iconSizeSlider then cb2.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2IconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.spacingSlider then cb2.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2Spacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.cdTextSlider then cb2.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2CdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.cdGradientSlider then cb2.cdGradientSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then local fv = math.floor(v); p.customBar2CdGradientThreshold = fv; s.valueText:SetText(fv > 0 and fv or "Off"); if cb2.cdGradientColorSwatch then cb2.cdGradientColorSwatch:SetShown(fv > 0) end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.cdGradientColorSwatch then cb2.cdGradientColorSwatch:SetScript("OnMouseDown", function() local p = GetProfile(); if not p then return end; local r = p.customBar2CdGradientR or 1; local g = p.customBar2CdGradientG or 0; local b = p.customBar2CdGradientB or 0; local function OnColorChanged() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); p.customBar2CdGradientR = nr; p.customBar2CdGradientG = ng; p.customBar2CdGradientB = nb; if cb2.cdGradientColorSwatch then cb2.cdGradientColorSwatch:SetBackdropColor(nr, ng, nb, 1) end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end; local function OnCancel(prev) p.customBar2CdGradientR = prev.r; p.customBar2CdGradientG = prev.g; p.customBar2CdGradientB = prev.b; if cb2.cdGradientColorSwatch then cb2.cdGradientColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end; ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel}) end) end
    if cb2.stackTextSlider then cb2.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2StackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.iconsPerRowSlider then cb2.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2IconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.cdModeDD then cb2.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2CooldownMode = v; if cb2.customHideRevealCB then cb2.customHideRevealCB:SetEnabled(v == "hide"); if v ~= "hide" then cb2.customHideRevealCB:SetChecked(false); p.customBar2UseCustomHideReveal = false end end; if addonTable.RefreshCB2SpellList then addonTable.RefreshCB2SpellList() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.showModeDD then cb2.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2ShowMode = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.xSlider then cb2.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2X = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.ySlider then cb2.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2Y = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.directionDD then cb2.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2Direction = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.anchorDD then cb2.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2AnchorPoint = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.growthDD then cb2.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2Growth = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.anchorTargetDD then
      cb2.anchorTargetDD.refreshOptions = function(dd) if addonTable.GetAnchorFrameOptions then dd:SetOptions(addonTable.GetAnchorFrameOptions(2)) end end
      cb2.anchorTargetDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2AnchorFrame = v; p.customBar2X = 0; p.customBar2Y = 0; if cb2.xSlider then cb2.xSlider:SetValue(0); cb2.xSlider.valueText:SetText("0") end; if cb2.ySlider then cb2.ySlider:SetValue(0); cb2.ySlider.valueText:SetText("0") end; if v == "UIParent" then p.customBar2AnchorToPoint = "CENTER"; if cb2.anchorToPointDD then cb2.anchorToPointDD:SetValue("CENTER") end end; if cb2.anchorToPointDD then cb2.anchorToPointDD:SetEnabled(v ~= "UIParent") end; if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end
    end
    if cb2.anchorToPointDD then cb2.anchorToPointDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2AnchorToPoint = v; if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.stackAnchorDD then cb2.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2StackTextPosition = v; if addonTable.UpdateCustomBar2StackTextPositions then addonTable.UpdateCustomBar2StackTextPositions() end end end end
    if cb2.stackXSlider then cb2.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2StackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2StackTextPositions then addonTable.UpdateCustomBar2StackTextPositions() end end end) end
    if cb2.stackYSlider then cb2.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2StackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2StackTextPositions then addonTable.UpdateCustomBar2StackTextPositions() end end end) end
    if cb2.addSpellBtn then cb2.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb2.addBox:GetText()); if id and addonTable.GetCustomBar2Spells then local s,e = addonTable.GetCustomBar2Spells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBar2Spells(s,e); cb2.addBox:SetText(""); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addItemBtn then cb2.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb2.addBox:GetText()); if id and addonTable.GetCustomBar2Spells then local s,e = addonTable.GetCustomBar2Spells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBar2Spells(s,e); cb2.addBox:SetText(""); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addTrinketsBtn then cb2.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = C_Item.GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addRacialBtn then cb2.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if C_SpellBook.IsSpellKnown(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addPotionBtn then cb2.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = C_Item.GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addGCSBtn then cb2.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end) end
    if cb2.addBox then cb2.addBox:SetScript("OnEnterPressed", function() if cb2.addSpellBtn then cb2.addSpellBtn:Click() end; cb2.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[4] then SetupDragDrop(tabFrames[4], addonTable.GetCustomBar2Spells, addonTable.SetCustomBar2Spells, RefreshCB2SpellList, addonTable.CreateCustomBar2Icons, addonTable.UpdateCustomBar2, {cb2.spellBg, cb2.spellScroll, cb2.spellChild}) end
  end
  local cb3 = addonTable.cb3
  if cb3 then
    if cb3.combatOnlyCB then cb3.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar3OutOfCombat = not s:GetChecked(); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.gcdCB then cb3.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar3ShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.buffOverlayCB then
      cb3.buffOverlayCB:SetChecked(false)
      cb3.buffOverlayCB:SetEnabled(false)
      if cb3.buffOverlayCB.label and cb3.buffOverlayCB.label.Hide then cb3.buffOverlayCB.label:Hide() end
      if cb3.buffOverlayCB.Hide then cb3.buffOverlayCB:Hide() end
    end
    if cb3.trackBuffsCB then cb3.trackBuffsCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      p.customBar3TrackBuffs = s:GetChecked()
      if cb3.openBlizzBuffBtn then cb3.openBlizzBuffBtn:SetShown(s:GetChecked()) end
      if s:GetChecked() == true then
        local forcedOff, needsReload = EnsureDisableBlizzCDMCompatible(p)
        if forcedOff and addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(true) end
        if forcedOff then
          ShowReloadPrompt("Track Buffs requires Blizzard CDM. Blizz CDM has been re-enabled. Reload now?", "Reload", "Later")
        elseif needsReload then
          ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
        end
      end
      RefreshCB3SpellList()
      if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
      if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
      if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    end end
    AttachCheckboxTooltip(cb3.trackBuffsCB, TRACK_BUFFS_TOOLTIP_TEXT, {anchor = "ANCHOR_LEFT", minWidth = 360})
    if cb3.useGlowsCB then cb3.useGlowsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked() == true
        p.customBar3UseSpellGlows = enabled
        if cb3.glowSpeedSlider then SetStyledSliderShown(cb3.glowSpeedSlider, enabled) end
        if cb3.glowThicknessSlider then SetStyledSliderShown(cb3.glowThicknessSlider, enabled) end
        RefreshCB3SpellList()
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      end
    end end
    if cb3.customHideRevealCB then cb3.customHideRevealCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar3UseCustomHideReveal = s:GetChecked() == true
        RefreshCB3SpellList()
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      end
    end end
    if cb3.glowSpeedSlider then cb3.glowSpeedSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowSpeed = tonumber(string.format("%.1f", v)) or 0.0; s.valueText:SetText(string.format("%.1f", p.spellGlowSpeed)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb3.glowThicknessSlider then cb3.glowThicknessSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowThickness = tonumber(string.format("%.1f", v)) or 2.0; s.valueText:SetText(string.format("%.1f", p.spellGlowThickness)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb3.centeredCB then cb3.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar3Centered = s:GetChecked()
        if s:GetChecked() then
          p.customBar3X = 0
          if cb3.xSlider then cb3.xSlider:SetValue(0); cb3.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      end
    end end
    if cb3.iconSizeSlider then cb3.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3IconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.spacingSlider then cb3.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3Spacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.cdTextSlider then cb3.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3CdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.cdGradientSlider then cb3.cdGradientSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then local fv = math.floor(v); p.customBar3CdGradientThreshold = fv; s.valueText:SetText(fv > 0 and fv or "Off"); if cb3.cdGradientColorSwatch then cb3.cdGradientColorSwatch:SetShown(fv > 0) end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.cdGradientColorSwatch then cb3.cdGradientColorSwatch:SetScript("OnMouseDown", function() local p = GetProfile(); if not p then return end; local r = p.customBar3CdGradientR or 1; local g = p.customBar3CdGradientG or 0; local b = p.customBar3CdGradientB or 0; local function OnColorChanged() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); p.customBar3CdGradientR = nr; p.customBar3CdGradientG = ng; p.customBar3CdGradientB = nb; if cb3.cdGradientColorSwatch then cb3.cdGradientColorSwatch:SetBackdropColor(nr, ng, nb, 1) end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end; local function OnCancel(prev) p.customBar3CdGradientR = prev.r; p.customBar3CdGradientG = prev.g; p.customBar3CdGradientB = prev.b; if cb3.cdGradientColorSwatch then cb3.cdGradientColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end; ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel}) end) end
    if cb3.stackTextSlider then cb3.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3StackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.iconsPerRowSlider then cb3.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3IconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.cdModeDD then cb3.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3CooldownMode = v; if cb3.customHideRevealCB then cb3.customHideRevealCB:SetEnabled(v == "hide"); if v ~= "hide" then cb3.customHideRevealCB:SetChecked(false); p.customBar3UseCustomHideReveal = false end end; if addonTable.RefreshCB3SpellList then addonTable.RefreshCB3SpellList() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.showModeDD then cb3.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3ShowMode = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.xSlider then cb3.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3X = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.ySlider then cb3.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3Y = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.directionDD then cb3.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3Direction = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.anchorDD then cb3.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3AnchorPoint = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.growthDD then cb3.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3Growth = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.anchorTargetDD then
      cb3.anchorTargetDD.refreshOptions = function(dd) if addonTable.GetAnchorFrameOptions then dd:SetOptions(addonTable.GetAnchorFrameOptions(3)) end end
      cb3.anchorTargetDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3AnchorFrame = v; p.customBar3X = 0; p.customBar3Y = 0; if cb3.xSlider then cb3.xSlider:SetValue(0); cb3.xSlider.valueText:SetText("0") end; if cb3.ySlider then cb3.ySlider:SetValue(0); cb3.ySlider.valueText:SetText("0") end; if v == "UIParent" then p.customBar3AnchorToPoint = "CENTER"; if cb3.anchorToPointDD then cb3.anchorToPointDD:SetValue("CENTER") end end; if cb3.anchorToPointDD then cb3.anchorToPointDD:SetEnabled(v ~= "UIParent") end; if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end
    end
    if cb3.anchorToPointDD then cb3.anchorToPointDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3AnchorToPoint = v; if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.stackAnchorDD then cb3.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3StackTextPosition = v; if addonTable.UpdateCustomBar3StackTextPositions then addonTable.UpdateCustomBar3StackTextPositions() end end end end
    if cb3.stackXSlider then cb3.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3StackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3StackTextPositions then addonTable.UpdateCustomBar3StackTextPositions() end end end) end
    if cb3.stackYSlider then cb3.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3StackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3StackTextPositions then addonTable.UpdateCustomBar3StackTextPositions() end end end) end
    if cb3.addSpellBtn then cb3.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb3.addBox:GetText()); if id and addonTable.GetCustomBar3Spells then local s,e = addonTable.GetCustomBar3Spells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBar3Spells(s,e); cb3.addBox:SetText(""); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addItemBtn then cb3.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb3.addBox:GetText()); if id and addonTable.GetCustomBar3Spells then local s,e = addonTable.GetCustomBar3Spells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBar3Spells(s,e); cb3.addBox:SetText(""); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addTrinketsBtn then cb3.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = C_Item.GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addRacialBtn then cb3.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if C_SpellBook.IsSpellKnown(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addPotionBtn then cb3.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = C_Item.GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addGCSBtn then cb3.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end) end
    if cb3.addBox then cb3.addBox:SetScript("OnEnterPressed", function() if cb3.addSpellBtn then cb3.addSpellBtn:Click() end; cb3.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[5] then SetupDragDrop(tabFrames[5], addonTable.GetCustomBar3Spells, addonTable.SetCustomBar3Spells, RefreshCB3SpellList, addonTable.CreateCustomBar3Icons, addonTable.UpdateCustomBar3, {cb3.spellBg, cb3.spellScroll, cb3.spellChild}) end
  end
  local cb4 = addonTable.cb4
  if cb4 then
    if cb4.combatOnlyCB then cb4.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar4OutOfCombat = not s:GetChecked(); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.gcdCB then cb4.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar4ShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.buffOverlayCB then
      cb4.buffOverlayCB:SetChecked(false)
      cb4.buffOverlayCB:SetEnabled(false)
      if cb4.buffOverlayCB.label and cb4.buffOverlayCB.label.Hide then cb4.buffOverlayCB.label:Hide() end
      if cb4.buffOverlayCB.Hide then cb4.buffOverlayCB:Hide() end
    end
    if cb4.trackBuffsCB then cb4.trackBuffsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar4TrackBuffs = s:GetChecked()
        if cb4.openBlizzBuffBtn then cb4.openBlizzBuffBtn:SetShown(p.customBar4TrackBuffs ~= false) end
        if p.customBar4TrackBuffs then
          local forcedOff, needsReload = EnsureDisableBlizzCDMCompatible(p)
          if forcedOff then
            if addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(true) end
            ShowReloadPrompt("Track Buffs requires Blizzard CDM. Blizz CDM has been re-enabled. Reload now?", "Reload", "Later")
          elseif needsReload then
            ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
          end
        end
        RefreshCB4SpellList()
        if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
        if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
        if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
        if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
        if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      end end
    end
    AttachCheckboxTooltip(cb4.trackBuffsCB, TRACK_BUFFS_TOOLTIP_TEXT, {anchor = "ANCHOR_LEFT", minWidth = 360})
    if cb4.useGlowsCB then cb4.useGlowsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked() == true
        p.customBar4UseSpellGlows = enabled
        if cb4.glowSpeedSlider then SetStyledSliderShown(cb4.glowSpeedSlider, enabled) end
        if cb4.glowThicknessSlider then SetStyledSliderShown(cb4.glowThicknessSlider, enabled) end
        RefreshCB4SpellList()
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
      end
    end end
    if cb4.customHideRevealCB then cb4.customHideRevealCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar4UseCustomHideReveal = s:GetChecked() == true
        RefreshCB4SpellList()
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
      end
    end end
    if cb4.glowSpeedSlider then cb4.glowSpeedSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowSpeed = tonumber(string.format("%.1f", v)) or 0.0; s.valueText:SetText(string.format("%.1f", p.spellGlowSpeed)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb4.glowThicknessSlider then cb4.glowThicknessSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowThickness = tonumber(string.format("%.1f", v)) or 2.0; s.valueText:SetText(string.format("%.1f", p.spellGlowThickness)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb4.centeredCB then cb4.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar4Centered = s:GetChecked()
        if s:GetChecked() then
          p.customBar4X = 0
          if cb4.xSlider then cb4.xSlider:SetValue(0); cb4.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
      end
    end end
    if cb4.iconSizeSlider then cb4.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4IconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.spacingSlider then cb4.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4Spacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.cdTextSlider then cb4.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4CdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.cdGradientSlider then cb4.cdGradientSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then local fv = math.floor(v); p.customBar4CdGradientThreshold = fv; s.valueText:SetText(fv > 0 and fv or "Off"); if cb4.cdGradientColorSwatch then cb4.cdGradientColorSwatch:SetShown(fv > 0) end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.cdGradientColorSwatch then cb4.cdGradientColorSwatch:SetScript("OnMouseDown", function() local p = GetProfile(); if not p then return end; local r = p.customBar4CdGradientR or 1; local g = p.customBar4CdGradientG or 0; local b = p.customBar4CdGradientB or 0; local function OnColorChanged() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); p.customBar4CdGradientR = nr; p.customBar4CdGradientG = ng; p.customBar4CdGradientB = nb; if cb4.cdGradientColorSwatch then cb4.cdGradientColorSwatch:SetBackdropColor(nr, ng, nb, 1) end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end; local function OnCancel(prev) p.customBar4CdGradientR = prev.r; p.customBar4CdGradientG = prev.g; p.customBar4CdGradientB = prev.b; if cb4.cdGradientColorSwatch then cb4.cdGradientColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end; ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel}) end) end
    if cb4.stackTextSlider then cb4.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4StackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.iconsPerRowSlider then cb4.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4IconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.cdModeDD then cb4.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4CooldownMode = v; if cb4.customHideRevealCB then cb4.customHideRevealCB:SetEnabled(v == "hide"); if v ~= "hide" then cb4.customHideRevealCB:SetChecked(false); p.customBar4UseCustomHideReveal = false end end; if addonTable.RefreshCB4SpellList then addonTable.RefreshCB4SpellList() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.showModeDD then cb4.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4ShowMode = v; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.xSlider then cb4.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4X = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4Position then addonTable.UpdateCustomBar4Position() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.ySlider then cb4.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4Y = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4Position then addonTable.UpdateCustomBar4Position() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.directionDD then cb4.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4Direction = v; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.anchorDD then cb4.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4AnchorPoint = v; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.growthDD then cb4.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4Growth = v; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.anchorTargetDD then
      cb4.anchorTargetDD.refreshOptions = function(dd) if addonTable.GetAnchorFrameOptions then dd:SetOptions(addonTable.GetAnchorFrameOptions(4)) end end
      cb4.anchorTargetDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4AnchorFrame = v; p.customBar4X = 0; p.customBar4Y = 0; if cb4.xSlider then cb4.xSlider:SetValue(0); cb4.xSlider.valueText:SetText("0") end; if cb4.ySlider then cb4.ySlider:SetValue(0); cb4.ySlider.valueText:SetText("0") end; if v == "UIParent" then p.customBar4AnchorToPoint = "CENTER"; if cb4.anchorToPointDD then cb4.anchorToPointDD:SetValue("CENTER") end end; if cb4.anchorToPointDD then cb4.anchorToPointDD:SetEnabled(v ~= "UIParent") end; if addonTable.UpdateCustomBar4Position then addonTable.UpdateCustomBar4Position() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end
    end
    if cb4.anchorToPointDD then cb4.anchorToPointDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4AnchorToPoint = v; if addonTable.UpdateCustomBar4Position then addonTable.UpdateCustomBar4Position() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end
    if cb4.stackAnchorDD then cb4.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar4StackTextPosition = v; if addonTable.UpdateCustomBar4StackTextPositions then addonTable.UpdateCustomBar4StackTextPositions() end end end end
    if cb4.stackXSlider then cb4.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4StackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4StackTextPositions then addonTable.UpdateCustomBar4StackTextPositions() end end end) end
    if cb4.stackYSlider then cb4.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar4StackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar4StackTextPositions then addonTable.UpdateCustomBar4StackTextPositions() end end end) end
    if cb4.addSpellBtn then cb4.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb4.addBox:GetText()); if id and addonTable.GetCustomBar4Spells then local s,e = addonTable.GetCustomBar4Spells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBar4Spells(s,e); cb4.addBox:SetText(""); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.addItemBtn then cb4.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb4.addBox:GetText()); if id and addonTable.GetCustomBar4Spells then local s,e = addonTable.GetCustomBar4Spells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBar4Spells(s,e); cb4.addBox:SetText(""); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.addTrinketsBtn then cb4.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar4Spells then return end; local s,e = addonTable.GetCustomBar4Spells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = C_Item.GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBar4Spells(s,e); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.addRacialBtn then cb4.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar4Spells then return end; local s,e = addonTable.GetCustomBar4Spells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if C_SpellBook.IsSpellKnown(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBar4Spells(s,e); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.addPotionBtn then cb4.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar4Spells then return end; local s,e = addonTable.GetCustomBar4Spells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = C_Item.GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBar4Spells(s,e); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end) end
    if cb4.addGCSBtn then cb4.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar4Spells then return end; local s,e = addonTable.GetCustomBar4Spells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBar4Spells(s,e); RefreshCB4SpellList(); if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end end end end) end
    if cb4.addBox then cb4.addBox:SetScript("OnEnterPressed", function() if cb4.addSpellBtn then cb4.addSpellBtn:Click() end; cb4.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[20] then SetupDragDrop(tabFrames[20], addonTable.GetCustomBar4Spells, addonTable.SetCustomBar4Spells, RefreshCB4SpellList, addonTable.CreateCustomBar4Icons, addonTable.UpdateCustomBar4, {cb4.spellBg, cb4.spellScroll, cb4.spellChild}) end
  end
  local cb5 = addonTable.cb5
  if cb5 then
    if cb5.combatOnlyCB then cb5.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar5OutOfCombat = not s:GetChecked(); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.gcdCB then cb5.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar5ShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.buffOverlayCB then
      cb5.buffOverlayCB:SetChecked(false)
      cb5.buffOverlayCB:SetEnabled(false)
      if cb5.buffOverlayCB.label and cb5.buffOverlayCB.label.Hide then cb5.buffOverlayCB.label:Hide() end
      if cb5.buffOverlayCB.Hide then cb5.buffOverlayCB:Hide() end
    end
    if cb5.trackBuffsCB then cb5.trackBuffsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar5TrackBuffs = s:GetChecked()
        if cb5.openBlizzBuffBtn then cb5.openBlizzBuffBtn:SetShown(p.customBar5TrackBuffs ~= false) end
        if p.customBar5TrackBuffs then
          local forcedOff, needsReload = EnsureDisableBlizzCDMCompatible(p)
          if forcedOff then
            if addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(true) end
            ShowReloadPrompt("Track Buffs requires Blizzard CDM. Blizz CDM has been re-enabled. Reload now?", "Reload", "Later")
          elseif needsReload then
            ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
          end
        end
        RefreshCB5SpellList()
        if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
        if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
        if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
        if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
        if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
        if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      end end
    end
    AttachCheckboxTooltip(cb5.trackBuffsCB, TRACK_BUFFS_TOOLTIP_TEXT, {anchor = "ANCHOR_LEFT", minWidth = 360})
    if cb5.useGlowsCB then cb5.useGlowsCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked() == true
        p.customBar5UseSpellGlows = enabled
        if cb5.glowSpeedSlider then SetStyledSliderShown(cb5.glowSpeedSlider, enabled) end
        if cb5.glowThicknessSlider then SetStyledSliderShown(cb5.glowThicknessSlider, enabled) end
        RefreshCB5SpellList()
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
      end
    end end
    if cb5.customHideRevealCB then cb5.customHideRevealCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar5UseCustomHideReveal = s:GetChecked() == true
        RefreshCB5SpellList()
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
      end
    end end
    if cb5.glowSpeedSlider then cb5.glowSpeedSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowSpeed = tonumber(string.format("%.1f", v)) or 0.0; s.valueText:SetText(string.format("%.1f", p.spellGlowSpeed)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.glowThicknessSlider then cb5.glowThicknessSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.spellGlowThickness = tonumber(string.format("%.1f", v)) or 2.0; s.valueText:SetText(string.format("%.1f", p.spellGlowThickness)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end; if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.centeredCB then cb5.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar5Centered = s:GetChecked()
        if s:GetChecked() then
          p.customBar5X = 0
          if cb5.xSlider then cb5.xSlider:SetValue(0); cb5.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
        if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
      end
    end end
    if cb5.iconSizeSlider then cb5.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5IconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.spacingSlider then cb5.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5Spacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.cdTextSlider then cb5.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5CdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.cdGradientSlider then cb5.cdGradientSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then local fv = math.floor(v); p.customBar5CdGradientThreshold = fv; s.valueText:SetText(fv > 0 and fv or "Off"); if cb5.cdGradientColorSwatch then cb5.cdGradientColorSwatch:SetShown(fv > 0) end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.cdGradientColorSwatch then cb5.cdGradientColorSwatch:SetScript("OnMouseDown", function() local p = GetProfile(); if not p then return end; local r = p.customBar5CdGradientR or 1; local g = p.customBar5CdGradientG or 0; local b = p.customBar5CdGradientB or 0; local function OnColorChanged() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); p.customBar5CdGradientR = nr; p.customBar5CdGradientG = ng; p.customBar5CdGradientB = nb; if cb5.cdGradientColorSwatch then cb5.cdGradientColorSwatch:SetBackdropColor(nr, ng, nb, 1) end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end; local function OnCancel(prev) p.customBar5CdGradientR = prev.r; p.customBar5CdGradientG = prev.g; p.customBar5CdGradientB = prev.b; if cb5.cdGradientColorSwatch then cb5.cdGradientColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end; ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel}) end) end
    if cb5.stackTextSlider then cb5.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5StackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.iconsPerRowSlider then cb5.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5IconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.cdModeDD then cb5.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5CooldownMode = v; if cb5.customHideRevealCB then cb5.customHideRevealCB:SetEnabled(v == "hide"); if v ~= "hide" then cb5.customHideRevealCB:SetChecked(false); p.customBar5UseCustomHideReveal = false end end; if addonTable.RefreshCB5SpellList then addonTable.RefreshCB5SpellList() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.showModeDD then cb5.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5ShowMode = v; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.xSlider then cb5.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5X = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5Position then addonTable.UpdateCustomBar5Position() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.ySlider then cb5.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5Y = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5Position then addonTable.UpdateCustomBar5Position() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.directionDD then cb5.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5Direction = v; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.anchorDD then cb5.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5AnchorPoint = v; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.growthDD then cb5.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5Growth = v; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.anchorTargetDD then
      cb5.anchorTargetDD.refreshOptions = function(dd) if addonTable.GetAnchorFrameOptions then dd:SetOptions(addonTable.GetAnchorFrameOptions(5)) end end
      cb5.anchorTargetDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5AnchorFrame = v; p.customBar5X = 0; p.customBar5Y = 0; if cb5.xSlider then cb5.xSlider:SetValue(0); cb5.xSlider.valueText:SetText("0") end; if cb5.ySlider then cb5.ySlider:SetValue(0); cb5.ySlider.valueText:SetText("0") end; if v == "UIParent" then p.customBar5AnchorToPoint = "CENTER"; if cb5.anchorToPointDD then cb5.anchorToPointDD:SetValue("CENTER") end end; if cb5.anchorToPointDD then cb5.anchorToPointDD:SetEnabled(v ~= "UIParent") end; if addonTable.UpdateCustomBar5Position then addonTable.UpdateCustomBar5Position() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end
    end
    if cb5.anchorToPointDD then cb5.anchorToPointDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5AnchorToPoint = v; if addonTable.UpdateCustomBar5Position then addonTable.UpdateCustomBar5Position() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end
    if cb5.stackAnchorDD then cb5.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar5StackTextPosition = v; if addonTable.UpdateCustomBar5StackTextPositions then addonTable.UpdateCustomBar5StackTextPositions() end end end end
    if cb5.stackXSlider then cb5.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5StackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5StackTextPositions then addonTable.UpdateCustomBar5StackTextPositions() end end end) end
    if cb5.stackYSlider then cb5.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar5StackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar5StackTextPositions then addonTable.UpdateCustomBar5StackTextPositions() end end end) end
    if cb5.addSpellBtn then cb5.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb5.addBox:GetText()); if id and addonTable.GetCustomBar5Spells then local s,e = addonTable.GetCustomBar5Spells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBar5Spells(s,e); cb5.addBox:SetText(""); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.addItemBtn then cb5.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb5.addBox:GetText()); if id and addonTable.GetCustomBar5Spells then local s,e = addonTable.GetCustomBar5Spells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBar5Spells(s,e); cb5.addBox:SetText(""); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.addTrinketsBtn then cb5.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar5Spells then return end; local s,e = addonTable.GetCustomBar5Spells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = C_Item.GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBar5Spells(s,e); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.addRacialBtn then cb5.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar5Spells then return end; local s,e = addonTable.GetCustomBar5Spells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if C_SpellBook.IsSpellKnown(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBar5Spells(s,e); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.addPotionBtn then cb5.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar5Spells then return end; local s,e = addonTable.GetCustomBar5Spells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = C_Item.GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBar5Spells(s,e); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end) end
    if cb5.addGCSBtn then cb5.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar5Spells then return end; local s,e = addonTable.GetCustomBar5Spells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBar5Spells(s,e); RefreshCB5SpellList(); if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end; if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end end end end) end
    if cb5.addBox then cb5.addBox:SetScript("OnEnterPressed", function() if cb5.addSpellBtn then cb5.addSpellBtn:Click() end; cb5.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[21] then SetupDragDrop(tabFrames[21], addonTable.GetCustomBar5Spells, addonTable.SetCustomBar5Spells, RefreshCB5SpellList, addonTable.CreateCustomBar5Icons, addonTable.UpdateCustomBar5, {cb5.spellBg, cb5.spellScroll, cb5.spellChild}) end
  end
  local function UpdateStandaloneControlsState()
    local p = GetProfile()
    local sa = addonTable.standalone
    if not p or not sa then return end
    local function SC(c, en)
      if not c then return end
      if c.SetEnabled then c:SetEnabled(en) end
      if c.SetAlpha then c:SetAlpha(en and 1 or 0.45) end
    end
    local buffAttached = p.useBuffBar == true
    local essentialAttached = p.useEssentialBar == true
    if sa.skinBuffCB then
      SC(sa.skinBuffCB, not buffAttached)
      if buffAttached then
        sa.skinBuffCB:SetChecked(true)
        p.standaloneSkinBuff = false
      end
    end
    if sa.skinEssentialCB then
      SC(sa.skinEssentialCB, not essentialAttached)
      if essentialAttached then
        sa.skinEssentialCB:SetChecked(true)
        p.standaloneSkinEssential = false
      end
    end
    SC(sa.skinUtilityCB, true)
    local anyAttached = buffAttached or essentialAttached
    if sa.centeredCB then
      SC(sa.centeredCB, not anyAttached)
      if anyAttached then
        sa.centeredCB:SetChecked(false)
        p.standaloneCentered = false
      end
    end
    if sa.buffCenteredCB then
      SC(sa.buffCenteredCB, not buffAttached)
      if buffAttached then sa.buffCenteredCB:SetChecked(false); p.standaloneBuffCentered = false end
    end
    if sa.essentialCenteredCB then
      SC(sa.essentialCenteredCB, not essentialAttached)
      if essentialAttached then sa.essentialCenteredCB:SetChecked(false); p.standaloneEssentialCentered = false end
    end
    SC(sa.utilityCenteredCB, true)
    SC(sa.buffSizeSlider, not buffAttached)
    SC(sa.buffRowsDD, not buffAttached)
    SC(sa.buffGrowDD, (not buffAttached) and (not p.standaloneBuffCentered))
    SC(sa.buffRowGrowDD, not buffAttached)
    SC(sa.buffIconsPerRowSlider, not buffAttached)
    SC(sa.buffYSlider, not buffAttached)
    SC(sa.buffXSlider, not buffAttached and not p.standaloneBuffCentered)
    SC(sa.essentialSizeSlider, not essentialAttached)
    if sa.essentialSecondRowSizeSlider then
      local essentialRows = type(p.standaloneEssentialMaxRows) == "number" and p.standaloneEssentialMaxRows or 2
      SC(sa.essentialSecondRowSizeSlider, (not essentialAttached) and (essentialRows > 1))
    end
    SC(sa.essentialRowsDD, not essentialAttached)
    SC(sa.essentialGrowDD, (not essentialAttached) and (not p.standaloneEssentialCentered))
    SC(sa.essentialRowGrowDD, not essentialAttached)
    SC(sa.essentialIconsPerRowSlider, not essentialAttached)
    SC(sa.essentialYSlider, not essentialAttached)
    SC(sa.essentialXSlider, not essentialAttached and not p.standaloneEssentialCentered)
    local utilityAuto = (p.standaloneUtilityAutoWidth or "off") ~= "off"
    if sa.utilitySizeSlider then
      SC(sa.utilitySizeSlider, not utilityAuto)
      if sa.utilitySizeSlider.label then
        sa.utilitySizeSlider.label:SetTextColor(utilityAuto and 0.5 or 1, utilityAuto and 0.5 or 1, utilityAuto and 0.5 or 1)
      end
    end
    SC(sa.utilityRowsDD, true)
    SC(sa.utilityGrowDD, not p.standaloneUtilityCentered)
    SC(sa.utilityRowGrowDD, true)
    SC(sa.utilityIconsPerRowSlider, true)
    SC(sa.utilityYSlider, true)
    SC(sa.utilityXSlider, not p.standaloneUtilityCentered)
    if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
  end
  addonTable.UpdateStandaloneControlsState = UpdateStandaloneControlsState
  local function UpdateBlizzCDMDisabledState()
    local p = GetProfile()
    if not p then return end
    local moduleEnabled = IsModuleEnabled("blizzcdm")
    local disabled = (p.disableBlizzCDM == true) or (not moduleEnabled)
    local buffAttached = p.useBuffBar == true
    local essentialAttached = p.useEssentialBar == true
    local function SetControlEnabled(control, enabled)
      if not control then return end
      if control.SetEnabled then control:SetEnabled(enabled) end
      if control.SetAlpha then control:SetAlpha(enabled and 1 or 0.45) end
    end
    SetControlEnabled(addonTable.skinningModeDD, not disabled)
    SetControlEnabled(addonTable.buffBarCB, not disabled)
    SetControlEnabled(addonTable.essentialBarCB, not disabled)
    SetControlEnabled(addonTable.buffSizeSlider, not disabled)
    local sa = addonTable.standalone
    if sa then
      local buffOK = not disabled and not buffAttached
      local essentialOK = not disabled and not essentialAttached
      SetControlEnabled(sa.skinBuffCB, buffOK)
      SetControlEnabled(sa.skinEssentialCB, essentialOK)
      SetControlEnabled(sa.skinUtilityCB, not disabled)
      SetControlEnabled(sa.hideGlowsCB, not disabled)
      SetControlEnabled(sa.buffCenteredCB, buffOK)
      SetControlEnabled(sa.essentialCenteredCB, essentialOK)
      SetControlEnabled(sa.utilityCenteredCB, not disabled)
      SetControlEnabled(sa.spacingSlider, not disabled)
      SetControlEnabled(sa.borderSizeSlider, not disabled)
      SetControlEnabled(sa.cdTextScaleSlider, not disabled)
      SetControlEnabled(sa.buffSizeSlider, buffOK)
      SetControlEnabled(sa.buffCdTextSlider, buffOK)
      SetControlEnabled(sa.buffRowsDD, buffOK)
      SetControlEnabled(sa.buffGrowDD, buffOK and (not p.standaloneBuffCentered))
      SetControlEnabled(sa.buffRowGrowDD, buffOK)
      SetControlEnabled(sa.buffIconsPerRowSlider, buffOK)
      SetControlEnabled(sa.buffYSlider, buffOK)
      SetControlEnabled(sa.buffXSlider, buffOK and not p.standaloneBuffCentered)
      SetControlEnabled(sa.essentialSizeSlider, essentialOK)
      SetControlEnabled(sa.essentialSecondRowSizeSlider, essentialOK)
      SetControlEnabled(sa.essentialCdTextSlider, essentialOK)
      SetControlEnabled(sa.essentialIconsPerRowSlider, essentialOK)
      SetControlEnabled(sa.essentialRowsDD, essentialOK)
      SetControlEnabled(sa.essentialGrowDD, essentialOK and (not p.standaloneEssentialCentered))
      SetControlEnabled(sa.essentialRowGrowDD, essentialOK)
      SetControlEnabled(sa.essentialYSlider, essentialOK)
      SetControlEnabled(sa.essentialXSlider, essentialOK and not p.standaloneEssentialCentered)
      SetControlEnabled(sa.utilityAutoWidthDD, not disabled)
      local utilityAuto = (p.standaloneUtilityAutoWidth or "off") ~= "off"
      SetControlEnabled(sa.utilitySizeSlider, (not disabled) and (not utilityAuto))
      SetControlEnabled(sa.utilityCdTextSlider, not disabled)
      SetControlEnabled(sa.utilityIconsPerRowSlider, not disabled)
      SetControlEnabled(sa.utilityRowsDD, not disabled)
      SetControlEnabled(sa.utilityGrowDD, (not disabled) and (not p.standaloneUtilityCentered))
      SetControlEnabled(sa.utilityRowGrowDD, not disabled)
      SetControlEnabled(sa.utilityYSlider, not disabled)
      SetControlEnabled(sa.utilityXSlider, not disabled)
    end
  end
  addonTable.UpdateBlizzCDMDisabledState = UpdateBlizzCDMDisabledState
  local function UpdateSkinCheckboxes()
    local p = GetProfile()
    local sa = addonTable.standalone
    if not p or not sa then return end
    local enabled = (p.blizzardBarSkinning ~= false) or (p.enableMasque == true)
    if sa.skinBuffCB and sa.skinBuffCB.SetEnabled then sa.skinBuffCB:SetEnabled(enabled) end
    if sa.skinEssentialCB and sa.skinEssentialCB.SetEnabled then sa.skinEssentialCB:SetEnabled(enabled) end
    if sa.skinUtilityCB and sa.skinUtilityCB.SetEnabled then sa.skinUtilityCB:SetEnabled(enabled) end
  end
  local Masque = LibStub and LibStub("Masque", true)
  if addonTable.skinningModeDD then
    addonTable.skinningModeDD:SetOptions({
      {text = "None", value = "none"},
      {text = "CCM Built-in", value = "ccm"},
      {text = Masque and "Masque" or "Masque (not installed)", value = "masque", disabled = not Masque},
    })
    addonTable.skinningModeDD.onSelect = function(v)
      local p = GetProfile(); if not p then return end
      if p.disableBlizzCDM == true then return end
      local wasEnabled = p.enableMasque or p.blizzardBarSkinning
      if v == "masque" then
        p.enableMasque = true; p.blizzardBarSkinning = false
      elseif v == "ccm" then
        p.enableMasque = false; p.blizzardBarSkinning = true
      else
        p.enableMasque = false; p.blizzardBarSkinning = false
        if wasEnabled then
          ShowReloadPrompt("Disabling skinning mode requires a UI reload to fully remove skin effects. Reload now?", "Reload", "Later")
        end
      end
      UpdateSkinCheckboxes()
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
    end
  end
  if addonTable.disableBlizzCDMCB then
    addonTable.disableBlizzCDMCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      local wasDisabled = p.disableBlizzCDM == true
      local promptShown = false
      local _, needsReload = SetModuleEnabled("blizzcdm", s:GetChecked())
      if not IsModuleEnabled("blizzcdm") then
        p.disableBlizzCDM = true
        s:SetChecked(false)
      else
        p.disableBlizzCDM = false
      end
      local changedTrackBuffs = false
      p.disableBlizzCDM = not IsModuleEnabled("blizzcdm")
      if p.disableBlizzCDM then
        changedTrackBuffs = EnsureTrackBuffsCompatible(p)
        if changedTrackBuffs then
          SyncTrackBuffsCheckboxesFromProfile(p)
        end
      end
      if p.disableBlizzCDM then
        if addonTable.ResetBlizzardBarSkinning then addonTable.ResetBlizzardBarSkinning() end
        if addonTable.RestoreBuffBarPosition then addonTable.RestoreBuffBarPosition() end
        if addonTable.RestoreEssentialBarPosition then addonTable.RestoreEssentialBarPosition() end
      end
      if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
      if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end
      if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
      if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
      if p.disableBlizzCDM and not wasDisabled then
        if changedTrackBuffs then
          ShowReloadPrompt("|cffff3333Track Buffs was active and is now disabled because Blizz CDM was turned off.|r\n\n|cffff3333Reload UI now?|r", "Reload", "Later")
          promptShown = true
        else
          ShowReloadPrompt("Disabling Blizz CDM is safest after a UI reload. Reload now?", "Reload", "Later")
          promptShown = true
        end
      end
      if needsReload and not promptShown then
        ShowReloadPrompt("Blizz CDM module state changed. Reload UI now?", "Reload", "Later")
      end
      SyncModuleControlsState()
    end
    AttachCheckboxTooltip(addonTable.disableBlizzCDMCB, DISABLE_BLIZZ_CDM_TOOLTIP_TEXT)
  end
  if addonTable.openBlizzCDMBtn then
    addonTable.openBlizzCDMBtn:SetScript("OnClick", function()
      local cfg = addonTable.ConfigFrame
      if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      end
      local opened = false
      if SlashCmdList and SlashCmdList.BLIZZCM then
        local ok = pcall(SlashCmdList.BLIZZCM, "")
        opened = ok == true
      end
      if not opened and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
        if SlashCmdList and SlashCmdList.BLIZZCM then
          pcall(SlashCmdList.BLIZZCM, "")
          opened = true
        end
      end
      if not opened and addonTable.ShowMessagePopup then
        addonTable.ShowMessagePopup("Blizzard CDM konnte nicht geoeffnet werden.", "OK")
      end
    end)
  end
  if addonTable.openEditModeBtn then
    addonTable.openEditModeBtn:SetScript("OnClick", function()
      local cfg = addonTable.ConfigFrame
      if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      end
      local opened = false
      if SlashCmdList and SlashCmdList.CCMEDITMODE then
        local ok = pcall(SlashCmdList.CCMEDITMODE, "")
        opened = ok == true
      end
      if not opened and EditModeManagerFrame and EditModeManagerFrame.Show then
        local ok = pcall(EditModeManagerFrame.Show, EditModeManagerFrame)
        opened = ok == true
      end
      if not opened and addonTable.ShowMessagePopup then
        addonTable.ShowMessagePopup("Edit Mode konnte nicht geoeffnet werden.", "OK")
      end
    end)
  end
  if addonTable.buffBarCB then addonTable.buffBarCB.customOnClick = function(s) 
    local p = GetProfile()
    if p and p.disableBlizzCDM == true then s:SetChecked(false); return end
    if p then 
      local wasAttached = p.useBuffBar
      p.useBuffBar = s:GetChecked()
      UpdateStandaloneControlsState()
      if s:GetChecked() and not wasAttached then
        ShowReloadPrompt("Attaching Blizzard bars to cursor requires a UI reload for best results. Reload now?", "Reload", "Later")
      end
    end 
  end end
  if addonTable.essentialBarCB then addonTable.essentialBarCB.customOnClick = function(s) 
    local p = GetProfile()
    if p and p.disableBlizzCDM == true then s:SetChecked(false); return end
    if p then 
      local wasAttached = p.useEssentialBar
      p.useEssentialBar = s:GetChecked()
      UpdateStandaloneControlsState()
      if s:GetChecked() and not wasAttached then
        ShowReloadPrompt("Attaching Blizzard bars to cursor requires a UI reload for best results. Reload now?", "Reload", "Later")
      end
    end 
  end end
  if addonTable.buffSizeSlider then addonTable.buffSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.buffBarIconSizeOffset = math.floor(v); s.valueText:SetText(math.floor(v)) end end) end
  local sa = addonTable.standalone
  if sa then
    local function ShowReloadPromptLocal(was)
      if was then
        ShowReloadPrompt("Disabling standalone bar skinning requires a UI reload. Reload now?", "Reload", "Later")
      end
    end
    if sa.skinBuffCB then sa.skinBuffCB.customOnClick = function(s) local p = GetProfile(); if p and p.disableBlizzCDM == true then s:SetChecked(false); return end; if p then local was = p.standaloneSkinBuff; p.standaloneSkinBuff = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPromptLocal(true) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.skinEssentialCB then sa.skinEssentialCB.customOnClick = function(s) local p = GetProfile(); if p and p.disableBlizzCDM == true then s:SetChecked(false); return end; if p then local was = p.standaloneSkinEssential; p.standaloneSkinEssential = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPromptLocal(true) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.skinUtilityCB then sa.skinUtilityCB.customOnClick = function(s) local p = GetProfile(); if p and p.disableBlizzCDM == true then s:SetChecked(false); return end; if p then local was = p.standaloneSkinUtility; p.standaloneSkinUtility = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPromptLocal(true) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.buffCenteredCB then sa.buffCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true then s:SetChecked(p.standaloneBuffCentered == true); return end; p.standaloneBuffCentered = s:GetChecked(); if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.essentialCenteredCB then sa.essentialCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true then s:SetChecked(p.standaloneEssentialCentered == true); return end; p.standaloneEssentialCentered = s:GetChecked(); if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.utilityCenteredCB then sa.utilityCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true then s:SetChecked(p.standaloneUtilityCentered == true); return end; p.standaloneUtilityCentered = s:GetChecked(); if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.hideGlowsCB then sa.hideGlowsCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true or not IsModuleEnabled("blizzcdm") then s:SetChecked(p.hideBlizzCDMGlows == true); return end; p.hideBlizzCDMGlows = s:GetChecked(); ShowReloadPrompt("A reload is required for glow changes to take effect.", "Reload", "Later") end end end
    if sa.spacingSlider then sa.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end end end) end
    if sa.borderSizeSlider then sa.borderSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneIconBorderSize = math.floor(v); s.valueText:SetText(math.floor(v)); addonTable.State.standaloneNeedsSkinning = true; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end end end) end
    if sa.cdTextScaleSlider then sa.cdTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local rv = math.floor(v * 10 + 0.5) / 10; p.standaloneCdTextScale = rv; s.valueText:SetText(string.format("%.1f", rv)); addonTable.State.standaloneNeedsSkinning = true; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.buffSizeSlider then sa.buffSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffSize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.buffCdTextSlider then sa.buffCdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local rv = math.floor(v * 10 + 0.5) / 10; p.standaloneBuffCdTextScale = rv; s.valueText:SetText(string.format("%.1f", rv)); addonTable.State.standaloneNeedsSkinning = true; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.buffIconsPerRowSlider then sa.buffIconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.buffRowsDD then sa.buffRowsDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffMaxRows = tonumber(v) or 2; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.buffGrowDD then sa.buffGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffGrowDirection = v or "right"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.buffRowGrowDD then sa.buffRowGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffRowGrowDirection = v or "down"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.buffYSlider then sa.buffYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarBuffY = n; p.standaloneBuffY = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.buffXSlider then sa.buffXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarBuffX = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.essentialSizeSlider then sa.essentialSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialSize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.essentialSecondRowSizeSlider then sa.essentialSecondRowSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialSecondRowSize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.essentialCdTextSlider then sa.essentialCdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local rv = math.floor(v * 10 + 0.5) / 10; p.standaloneEssentialCdTextScale = rv; s.valueText:SetText(string.format("%.1f", rv)); addonTable.State.standaloneNeedsSkinning = true; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.essentialIconsPerRowSlider then sa.essentialIconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.essentialRowsDD then sa.essentialRowsDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialMaxRows = tonumber(v) or 2; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.essentialGrowDD then sa.essentialGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialGrowDirection = v or "right"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.essentialRowGrowDD then sa.essentialRowGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialRowGrowDirection = v or "down"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.essentialYSlider then sa.essentialYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarEssentialY = n; p.standaloneEssentialY = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.essentialXSlider then sa.essentialXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarEssentialX = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.utilitySizeSlider then sa.utilitySizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilitySize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.utilityCdTextSlider then sa.utilityCdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local rv = math.floor(v * 10 + 0.5) / 10; p.standaloneUtilityCdTextScale = rv; s.valueText:SetText(string.format("%.1f", rv)); addonTable.State.standaloneNeedsSkinning = true; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.utilityIconsPerRowSlider then sa.utilityIconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.utilityRowsDD then sa.utilityRowsDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityMaxRows = tonumber(v) or 2; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.utilityGrowDD then sa.utilityGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityGrowDirection = v or "right"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.utilityRowGrowDD then sa.utilityRowGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityRowGrowDirection = v or "down"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.utilityAutoWidthDD then sa.utilityAutoWidthDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityAutoWidth = v; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end end end end
    if sa.utilityYSlider then sa.utilityYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarUtilityY = n; p.standaloneUtilityY = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.utilityXSlider then sa.utilityXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarUtilityX = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
  end
  local exportCategoryKeys = {
    general = {"iconBorderSize", "iconStrata", "enableMasque", "showMinimapButton", "minimapButtonAngle",
               "customBarsCount", "uiScale", "uiScaleMode", "blizzardBarSkinning",
               "cdFont", "globalFont", "globalOutline", "audioChannel",
               "customBarIconSize", "customBarSpacing", "customBarCdTextScale",
               "customBarCdGradientThreshold", "customBarCdGradientR", "customBarCdGradientG", "customBarCdGradientB",
               "customBarStackTextScale", "customBarDirection", "customBarGrowth", "customBarAnchorPoint", "customBarAnchorFrame", "customBarAnchorToPoint",
               "customBarX", "customBarY", "customBarCentered", "customBarCooldownMode", "customBarShowMode", "customBarIconsPerRow",
               "customBarOutOfCombat", "customBarShowGCD", "customBarUseBuffOverlay", "customBarTrackBuffs", "customBarUseSpellGlows", "customBarSpellGlowDefaultType", "customBarStackTextPosition",
               "customBarStackTextOffsetX", "customBarStackTextOffsetY",
               "customBar2IconSize", "customBar2Spacing", "customBar2CdTextScale",
               "customBar2CdGradientThreshold", "customBar2CdGradientR", "customBar2CdGradientG", "customBar2CdGradientB",
               "customBar2StackTextScale", "customBar2Direction", "customBar2Growth", "customBar2AnchorPoint", "customBar2AnchorFrame", "customBar2AnchorToPoint",
               "customBar2X", "customBar2Y", "customBar2Centered", "customBar2CooldownMode", "customBar2ShowMode", "customBar2IconsPerRow",
               "customBar2OutOfCombat", "customBar2ShowGCD", "customBar2UseBuffOverlay", "customBar2TrackBuffs", "customBar2UseSpellGlows", "customBar2SpellGlowDefaultType", "customBar2StackTextPosition",
               "customBar2StackTextOffsetX", "customBar2StackTextOffsetY",
               "customBar3IconSize", "customBar3Spacing", "customBar3CdTextScale",
               "customBar3CdGradientThreshold", "customBar3CdGradientR", "customBar3CdGradientG", "customBar3CdGradientB",
               "customBar3StackTextScale", "customBar3Direction", "customBar3Growth", "customBar3AnchorPoint", "customBar3AnchorFrame", "customBar3AnchorToPoint",
               "customBar3X", "customBar3Y", "customBar3Centered", "customBar3CooldownMode", "customBar3ShowMode", "customBar3IconsPerRow",
               "customBar3OutOfCombat", "customBar3ShowGCD", "customBar3UseBuffOverlay", "customBar3TrackBuffs", "customBar3UseSpellGlows", "customBar3SpellGlowDefaultType", "customBar3StackTextPosition",
               "customBar3StackTextOffsetX", "customBar3StackTextOffsetY",
               "customBar4IconSize", "customBar4Spacing", "customBar4CdTextScale",
               "customBar4CdGradientThreshold", "customBar4CdGradientR", "customBar4CdGradientG", "customBar4CdGradientB",
               "customBar4StackTextScale", "customBar4Direction", "customBar4Growth", "customBar4AnchorPoint", "customBar4AnchorFrame", "customBar4AnchorToPoint",
               "customBar4X", "customBar4Y", "customBar4Centered", "customBar4CooldownMode", "customBar4ShowMode", "customBar4IconsPerRow",
               "customBar4OutOfCombat", "customBar4ShowGCD", "customBar4UseBuffOverlay", "customBar4TrackBuffs", "customBar4UseSpellGlows", "customBar4SpellGlowDefaultType", "customBar4StackTextPosition",
               "customBar4StackTextOffsetX", "customBar4StackTextOffsetY",
               "customBar5IconSize", "customBar5Spacing", "customBar5CdTextScale",
               "customBar5CdGradientThreshold", "customBar5CdGradientR", "customBar5CdGradientG", "customBar5CdGradientB",
               "customBar5StackTextScale", "customBar5Direction", "customBar5Growth", "customBar5AnchorPoint", "customBar5AnchorFrame", "customBar5AnchorToPoint",
               "customBar5X", "customBar5Y", "customBar5Centered", "customBar5CooldownMode", "customBar5ShowMode", "customBar5IconsPerRow",
               "customBar5OutOfCombat", "customBar5ShowGCD", "customBar5UseBuffOverlay", "customBar5TrackBuffs", "customBar5UseSpellGlows", "customBar5SpellGlowDefaultType", "customBar5StackTextPosition",
               "customBar5StackTextOffsetX", "customBar5StackTextOffsetY"},
    qol = {"selfHighlightShape", "selfHighlightVisibility", "selfHighlightSize", "selfHighlightY",
           "selfHighlightThickness", "selfHighlightOutline", "selfHighlightColorR", "selfHighlightColorG", "selfHighlightColorB",
           "noTargetAlertEnabled", "noTargetAlertFlash", "noTargetAlertX", "noTargetAlertY", "noTargetAlertFontSize",
           "noTargetAlertColorR", "noTargetAlertColorG", "noTargetAlertColorB",
           "lowHealthWarningEnabled", "lowHealthWarningFlash", "lowHealthWarningText", "lowHealthWarningFontSize",
           "lowHealthWarningX", "lowHealthWarningY",
           "lowHealthWarningColorR", "lowHealthWarningColorG", "lowHealthWarningColorB", "lowHealthWarningSound",
              "hideActionBar1InCombat", "hideActionBar1Mouseover", "hideActionBar1Always",
               "hideAB2InCombat", "hideAB2Mouseover", "hideAB2Always",
               "hideAB3InCombat", "hideAB3Mouseover", "hideAB3Always",
               "hideAB4InCombat", "hideAB4Mouseover", "hideAB4Always",
               "hideAB5InCombat", "hideAB5Mouseover", "hideAB5Always",
               "hideAB6InCombat", "hideAB6Mouseover", "hideAB6Always",
               "hideAB7InCombat", "hideAB7Mouseover", "hideAB7Always",
               "hideAB8InCombat", "hideAB8Mouseover", "hideAB8Always",
                "hideStanceBarInCombat", "hideStanceBarMouseover", "hideStanceBarAlways",
                "hidePetBarInCombat", "hidePetBarMouseover", "hidePetBarAlways",
                "actionBarGlobalMode", "fadeMicroMenu", "hideActionBarBorders", "hideActionBarGlows", "abSkinSpacing", "fadeObjectiveTracker", "fadeBagBar",
               "betterItemLevel", "showEquipmentDetails",
               "chatClassColorNames", "chatTimestamps", "chatTimestampFormat", "chatCopyButton", "chatCopyButtonCorner",
               "chatUrlDetection", "chatBackground", "chatBackgroundAlpha", "chatBackgroundColorR", "chatBackgroundColorG", "chatBackgroundColorB",
               "chatHideButtons", "chatFadeToggle", "chatFadeDelay", "chatEditBoxPosition", "chatEditBoxStyled", "chatTabFlash", "chatHideTabs",
               "skyridingEnabled", "skyridingScale", "skyridingCentered", "skyridingX", "skyridingY",
               "skyridingVigorBar", "skyridingVigorColorR", "skyridingVigorColorG", "skyridingVigorColorB",
               "skyridingVigorEmptyColorR", "skyridingVigorEmptyColorG", "skyridingVigorEmptyColorB",
               "skyridingVigorRechargeColorR", "skyridingVigorRechargeColorG", "skyridingVigorRechargeColorB",
               "skyridingWhirlingSurgeColorR", "skyridingWhirlingSurgeColorG", "skyridingWhirlingSurgeColorB",
               "skyridingSecondWindColorR", "skyridingSecondWindColorG", "skyridingSecondWindColorB",
               "skyridingTexture", "skyridingCooldowns", "skyridingHideCDM",
                "showRadialCircle", "radialRadius", "radialColorR", "radialColorG", "radialColorB",
             "autoRepair", "showTooltipIDs", "compactMinimapIcons", "enhancedTooltip",
             "autoQuest", "autoQuestExcludeDaily", "autoQuestExcludeWeekly", "autoQuestExcludeTrivial", "autoQuestExcludeCompleted", "autoQuestRewardMode",
             "autoSellJunk", "autoFillDelete", "quickRoleSignup",
             "combatTimerEnabled", "combatTimerMode", "combatTimerStyle", "combatTimerCentered",
             "combatTimerX", "combatTimerY", "combatTimerScale",
              "combatTimerTextColorR", "combatTimerTextColorG", "combatTimerTextColorB",
              "combatTimerBgColorR", "combatTimerBgColorG", "combatTimerBgColorB", "combatTimerBgAlpha",
              "crTimerEnabled", "crTimerMode", "crTimerDisplay", "crTimerLayout", "crTimerCentered", "crTimerX", "crTimerY", "crTimerScale",
              "combatStatusEnabled", "combatStatusCentered", "combatStatusX", "combatStatusY", "combatStatusScale",
              "combatStatusEnterColorR", "combatStatusEnterColorG", "combatStatusEnterColorB",
              "combatStatusLeaveColorR", "combatStatusLeaveColorG", "combatStatusLeaveColorB",
                "radialAlpha", "radialThickness", "radialCombatOnly", "radialShowGCD"},
	    cursor = {"iconSize", "iconSpacing", "offsetX", "offsetY", "cdTextScale", "cdTextGradientThreshold", "cdTextGradientR", "cdTextGradientG", "cdTextGradientB", "stackTextScale",
	              "layoutDirection", "growDirection", "iconsPerRow",
	              "numColumns", "showGCD", "cursorShowGCD", "iconsCombatOnly", "cursorCombatOnly",
	              "stackTextPosition", "stackTextOffsetX", "stackTextOffsetY", "useBuffOverlay", "trackBuffs", "useSpellGlows", "spellGlowDefaultType", "spellGlowSpeed", "spellGlowThickness", "cooldownIconMode",
	              "glowWhenReady", "showInCombatOnly", "alwaysShowInEnabled", "alwaysShowInMode"},
    blizzcdm = {"disableBlizzCDM", "hideTrackedBlizzBuffIcons", "useBuffBar", "useEssentialBar",
                "essentialBarSpacing", "standaloneIconBorderSize", "standaloneSkinBuff", "standaloneSkinEssential", "standaloneSkinUtility",
                "standaloneCentered", "standaloneBuffCentered", "standaloneEssentialCentered", "standaloneUtilityCentered", "hideBlizzCDMGlows",
                "standaloneSpacing", "standaloneBuffSize", "standaloneBuffIconsPerRow", "standaloneBuffMaxRows", "standaloneBuffGrowDirection", "standaloneBuffRowGrowDirection", "standaloneBuffY", "standaloneBuffX",
                "standaloneEssentialSize", "standaloneEssentialSecondRowSize", "standaloneEssentialIconsPerRow", "standaloneEssentialMaxRows", "standaloneEssentialGrowDirection", "standaloneEssentialRowGrowDirection", "standaloneEssentialY", "standaloneEssentialX",
                "standaloneUtilitySize", "standaloneUtilitySecondRowSize", "standaloneUtilityIconsPerRow", "standaloneUtilityMaxRows", "standaloneUtilityGrowDirection", "standaloneUtilityRowGrowDirection", "standaloneUtilityY", "standaloneUtilityX", "standaloneUtilityAutoWidth",
                "blizzBarBuffX", "blizzBarBuffY", "blizzBarEssentialX", "blizzBarEssentialY",
                "blizzBarUtilityX", "blizzBarUtilityY",
                "standaloneCdTextScale", "standaloneBuffCdTextScale", "standaloneEssentialCdTextScale", "standaloneUtilityCdTextScale"},
    prb = {"usePersonalResourceBar", "prbWidth", "prbX", "prbY", "prbCentered", "prbShowMode", "prbAutoWidthSource",
           "prbSpacing", "prbBorderSize", "prbBackgroundAlpha", "prbClampBars", "prbClampAnchor",
           "prbBgColorR", "prbBgColorG", "prbBgColorB",
           "prbShowHealth", "prbShowPower", "prbShowClassPower",
           "prbHealthHeight", "prbHealthYOffset", "prbHealthTexture", "prbAbsorbTexture", "prbHealAbsorb", "prbDmgAbsorb", "prbHealPred", "prbAbsorbStripes", "prbOverAbsorbBar", "prbHealthTextMode", "prbHealthTextScale", "prbHealthTextY",
           "prbHealthColorR", "prbHealthColorG", "prbHealthColorB",
           "prbUseLowHealthColor", "prbLowHealthThreshold", "prbLowHealthColorR", "prbLowHealthColorG", "prbLowHealthColorB",
           "prbHealthTextColorR", "prbHealthTextColorG", "prbHealthTextColorB", "prbUseClassColor",
           "prbPowerHeight", "prbPowerYOffset", "prbPowerTexture", "prbPowerTextMode", "prbPowerTextScale", "prbPowerTextY",
           "prbPowerColorR", "prbPowerColorG", "prbPowerColorB",
           "prbUseLowPowerColor", "prbLowPowerThreshold", "prbLowPowerColorR", "prbLowPowerColorG", "prbLowPowerColorB",
           "prbPowerTextColorR", "prbPowerTextColorG", "prbPowerTextColorB", "prbUsePowerTypeColor",
           "prbManaHeight", "prbManaYOffset", "prbManaTexture", "prbManaTextMode", "prbManaTextScale", "prbManaTextY",
           "prbManaColorR", "prbManaColorG", "prbManaColorB",
           "prbManaTextColorR", "prbManaTextColorG", "prbManaTextColorB", "prbShowManaBar",
           "prbClassPowerHeight", "prbClassPowerY", "prbClassPowerX",
           "prbClassPowerColorR", "prbClassPowerColorG", "prbClassPowerColorB"},
    castbar = {"useCastbar",
               "castbarWidth", "castbarHeight", "castbarX", "castbarY", "castbarCentered",
               "castbarTexture", "castbarBorderSize", "castbarBgAlpha", "castbarAutoWidthSource",
               "castbarColorR", "castbarColorG", "castbarColorB",
               "castbarBgColorR", "castbarBgColorG", "castbarBgColorB",
               "castbarTextColorR", "castbarTextColorG", "castbarTextColorB",
               "castbarUseClassColor", "castbarShowIcon", "castbarIconSize",
               "castbarShowTime", "castbarTimeScale",
               "castbarShowSpellName", "castbarSpellNameScale"},
    focuscastbar = {"useFocusCastbar",
               "focusCastbarWidth", "focusCastbarHeight", "focusCastbarX", "focusCastbarY", "focusCastbarCentered",
               "focusCastbarTexture", "focusCastbarBorderSize", "focusCastbarBgAlpha",
               "focusCastbarColorR", "focusCastbarColorG", "focusCastbarColorB",
               "focusCastbarBgColorR", "focusCastbarBgColorG", "focusCastbarBgColorB",
               "focusCastbarTextColorR", "focusCastbarTextColorG", "focusCastbarTextColorB",
               "focusCastbarShowIcon", "focusCastbarIconSize",
               "focusCastbarShowTime", "focusCastbarTimeScale",
               "focusCastbarShowSpellName", "focusCastbarSpellNameScale",
               "focusCastbarShowTicks", "focusCastbarSpellNameXOffset", "focusCastbarSpellNameYOffset",
               "focusCastbarTimeXOffset", "focusCastbarTimeYOffset", "focusCastbarTimePrecision", "focusCastbarTimeDirection"},
    targetcastbar = {"useTargetCastbar",
               "targetCastbarWidth", "targetCastbarHeight", "targetCastbarX", "targetCastbarY", "targetCastbarCentered",
               "targetCastbarTexture", "targetCastbarBorderSize", "targetCastbarBgAlpha",
               "targetCastbarColorR", "targetCastbarColorG", "targetCastbarColorB",
               "targetCastbarBgColorR", "targetCastbarBgColorG", "targetCastbarBgColorB",
               "targetCastbarTextColorR", "targetCastbarTextColorG", "targetCastbarTextColorB",
               "targetCastbarShowIcon", "targetCastbarIconSize",
               "targetCastbarShowTime", "targetCastbarTimeScale",
               "targetCastbarShowSpellName", "targetCastbarSpellNameScale",
               "targetCastbarShowTicks", "targetCastbarSpellNameXOffset", "targetCastbarSpellNameYOffset",
               "targetCastbarTimeXOffset", "targetCastbarTimeYOffset", "targetCastbarTimePrecision", "targetCastbarTimeDirection"},
    debuffs = {"playerDebuffSize", "playerDebuffSpacing", "playerDebuffX", "playerDebuffY",
               "playerDebuffSortDirection", "playerDebuffIconsPerRow", "playerDebuffRowGrowDirection",
               "playerDebuffBorderSize"},
    uf = {"enablePlayerDebuffs",
               "ufClassColor", "ufUseCustomTextures", "ufHealthTexture",
               "ufDisableGlows", "ufDisableCombatText", "ufHideGroupIndicator",
               "disableTargetBuffs", "hideEliteTexture",
               "useCustomBorderColor", "ufCustomBorderColorR", "ufCustomBorderColorG", "ufCustomBorderColorB",
               "ufUseCustomNameColor", "ufNameColorR", "ufNameColorG", "ufNameColorB",
               "ufBigHBPlayerEnabled", "ufBigHBTargetEnabled", "ufBigHBFocusEnabled",
               "ufBigHBPlayerHealAbsorb", "ufBigHBPlayerDmgAbsorb", "ufBigHBPlayerHealPred", "ufBigHBPlayerAbsorbStripes",
               "ufBigHBTargetHealAbsorb", "ufBigHBTargetDmgAbsorb", "ufBigHBTargetHealPred", "ufBigHBTargetAbsorbStripes",
               "ufBigHBFocusHealAbsorb", "ufBigHBFocusDmgAbsorb", "ufBigHBFocusHealPred", "ufBigHBFocusAbsorbStripes",
               "ufBigHBHidePlayerName", "ufBigHBPlayerNameAnchor", "ufBigHBPlayerLevelMode",
               "ufBigHBPlayerNameX", "ufBigHBPlayerNameY", "ufBigHBPlayerLevelX", "ufBigHBPlayerLevelY",
               "ufBigHBPlayerNameTextScale", "ufBigHBPlayerLevelTextScale",
               "ufBigHBHideTargetName", "ufBigHBTargetNameAnchor", "ufBigHBTargetLevelMode",
               "ufBigHBTargetNameX", "ufBigHBTargetNameY", "ufBigHBTargetLevelX", "ufBigHBTargetLevelY",
               "ufBigHBTargetNameTextScale", "ufBigHBTargetLevelTextScale",
                "ufBigHBHideFocusName", "ufBigHBFocusNameAnchor", "ufBigHBFocusLevelMode",
                "ufBigHBFocusNameX", "ufBigHBFocusNameY", "ufBigHBFocusLevelX", "ufBigHBFocusLevelY",
                 "ufBigHBFocusNameTextScale", "ufBigHBFocusLevelTextScale",
                 "ufBigHBPlayerNameMaxChars", "ufBigHBTargetNameMaxChars", "ufBigHBFocusNameMaxChars",
                 "ufBigHBPlayerHideRealm", "ufBigHBTargetHideRealm", "ufBigHBFocusHideRealm",
                 "ufBigHBNameMaxChars",
                 "ufBigHBHideRealm",
                 },
  }
  local keyToCategory = {}
  for cat, keys in pairs(exportCategoryKeys) do
    for _, k in ipairs(keys) do
      keyToCategory[k] = cat
    end
  end
  local serializedBoolKeys = {
    showRadialCircle = true, showGCD = true, cursorShowGCD = true, showInCombatOnly = true,
    iconsCombatOnly = true, cursorCombatOnly = true, glowWhenReady = true,
    customBarOutOfCombat = true, customBarShowGCD = true, customBarCentered = true,
    customBar2OutOfCombat = true, customBar2ShowGCD = true, customBar2Centered = true,
    customBar3OutOfCombat = true, customBar3ShowGCD = true, customBar3Centered = true,
    useBuffBar = true, useEssentialBar = true, blizzardBarSkinning = true, enableMasque = true, showMinimapButton = true,
    standaloneSkinBuff = true, standaloneSkinEssential = true, standaloneSkinUtility = true,
    standaloneCentered = true, standaloneBuffCentered = true, standaloneEssentialCentered = true, standaloneUtilityCentered = true,
    usePersonalResourceBar = true, prbCentered = true, prbShowHealth = true, prbShowPower = true,
    prbShowClassPower = true, prbUseClassColor = true, prbUsePowerTypeColor = true, prbShowManaBar = true, prbClampBars = true,
    hideActionBar1InCombat = true, hideActionBar1Mouseover = true, hideActionBar1Always = true,
    hideAB2InCombat = true, hideAB2Mouseover = true, hideAB2Always = true,
    hideAB3InCombat = true, hideAB3Mouseover = true, hideAB3Always = true,
    hideAB4InCombat = true, hideAB4Mouseover = true, hideAB4Always = true,
    hideAB5InCombat = true, hideAB5Mouseover = true, hideAB5Always = true,
    hideAB6InCombat = true, hideAB6Mouseover = true, hideAB6Always = true,
    hideAB7InCombat = true, hideAB7Mouseover = true, hideAB7Always = true,
    hideAB8InCombat = true, hideAB8Mouseover = true, hideAB8Always = true,
    hideStanceBarInCombat = true, hideStanceBarMouseover = true, hideStanceBarAlways = true,
    hidePetBarInCombat = true, hidePetBarMouseover = true, hidePetBarAlways = true,
    fadeMicroMenu = true, hideActionBarBorders = true, hideActionBarGlows = true, fadeObjectiveTracker = true, fadeBagBar = true, betterItemLevel = true, showEquipmentDetails = true,
    chatClassColorNames = true, chatTimestamps = true, chatCopyButton = true, chatUrlDetection = true, chatBackground = true, chatHideButtons = true, chatFadeToggle = true, chatEditBoxStyled = true, chatTabFlash = true,
    skyridingEnabled = true, skyridingHideCDM = true, skyridingVigorBar = true, skyridingCooldowns = true, skyridingCentered = true,
    autoRepair = true, showTooltipIDs = true, compactMinimapIcons = true, enhancedTooltip = true,
    autoQuest = true, autoQuestExcludeDaily = true, autoQuestExcludeWeekly = true, autoQuestExcludeTrivial = true, autoQuestExcludeCompleted = true,
    autoSellJunk = true, autoFillDelete = true, quickRoleSignup = true,
    combatTimerEnabled = true, combatTimerCentered = true, crTimerEnabled = true, crTimerMode = "combat",
    crTimerCentered = true, combatStatusEnabled = true, combatStatusCentered = true,
    useCastbar = true, useFocusCastbar = true,
    useCustomHideReveal = true, customBarUseCustomHideReveal = true, customBar2UseCustomHideReveal = true, customBar3UseCustomHideReveal = true,
    castbarCentered = true, castbarUseClassColor = true,
    castbarShowIcon = true, castbarShowTime = true, castbarShowSpellName = true,
    focusCastbarCentered = true,
    focusCastbarShowIcon = true, focusCastbarShowTime = true, focusCastbarShowSpellName = true, focusCastbarShowTicks = true,
    enablePlayerDebuffs = true,
    ufClassColor = true, ufUseCustomTextures = true, ufUseCustomNameColor = true, ufDisableGlows = true, ufDisableCombatText = true, ufHideGroupIndicator = true,
    disableTargetBuffs = true, hideEliteTexture = true, useCustomBorderColor = true,
    ufBigHBPlayerEnabled = true, ufBigHBTargetEnabled = true, ufBigHBFocusEnabled = true,
    ufBigHBHidePlayerName = true, ufBigHBHideTargetName = true, ufBigHBHideFocusName = true, ufBigHBHideRealm = true,
    ufBigHBPlayerHideRealm = true, ufBigHBTargetHideRealm = true, ufBigHBFocusHideRealm = true,
    ufBigHBPlayerAbsorbStripes = true, ufBigHBTargetAbsorbStripes = true, ufBigHBFocusAbsorbStripes = true,
    useBiggerPlayerHealthframe = true, useBiggerPlayerHealthframeClassColor = true,
    useBiggerPlayerHealthframeDisableGlows = true, useBiggerPlayerHealthframeDisableCombatText = true,
  }
  local serializedRenamedKeys = {
    useBiggerPlayerHealthframeClassColor = "ufClassColor",
    useBiggerPlayerHealthframeTexture = "ufHealthTexture",
    useBiggerPlayerHealthframeDisableGlows = "ufDisableGlows",
    useBiggerPlayerHealthframeDisableCombatText = "ufDisableCombatText",
  }
  ApplySerializedDataToProfile = function(profile, data)
    if type(profile) ~= "table" or type(data) ~= "string" then return end
    for k, v in data:gmatch("([%w_]+)=([^;]+);") do
      if v:match("^\"(.*)\"$") then
        profile[k] = v:match("^\"(.*)\"$")
      elseif tonumber(v) then
        local num = tonumber(v)
        if num == 0 or num == 1 then
          if serializedBoolKeys[k] then
            profile[k] = (num == 1)
          else
            profile[k] = num
          end
        else
          profile[k] = num
        end
      end
    end
    for oldK, newK in pairs(serializedRenamedKeys) do
      if profile[oldK] ~= nil and profile[newK] == nil then
        profile[newK] = profile[oldK]
      end
      profile[oldK] = nil
    end
    local count = profile.customBarsCount or 0
    profile.customBarEnabled = (count >= 1)
    profile.customBar2Enabled = (count >= 2)
    profile.customBar3Enabled = (count >= 3)
    profile.customBar4Enabled = (count >= 4)
    profile.customBar5Enabled = (count >= 5)
  end
  EXAMPLE_IMPORT_DATA_DPS_TANK = [[customBarOutOfCombat=1;customBarAnchorPoint="RIGHT";hideAB4InCombat=1;hideAB5Mouseover=1;ufBigHBTargetLevelTextScale=0.95;enableMasque=0;customBarCdGradientR=0;chatBackgroundColorG=0;blizzBarUtilityY=-352.5;prbUseLowPowerColor=1;compactMinimapIcons=0;combatTimerStyle="boxed";selfHighlightColorB=0.0078431377187371;prbLowPowerThreshold=20;prbClassPowerY=-99;ufBigHBTargetNameX=6;chatCopyButton=1;prbDmgAbsorb="bar";combatTimerBgColorB=0.12;chatBackgroundAlpha=40;combatTimerBgAlpha=0.85;skyridingVigorEmptyColorR=0.14901961386204;prbX=2;cursorShowGCD=0;prbShowHealth=0;ufUseCustomNameColor=1;standaloneEssentialIconsPerRow=5;combatStatusEnabled=1;prbPowerTextScale=1.3;ufBigHBPlayerNameX=0;customBar3AnchorFrame="UIParent";castbarTimeScale=1.2;customBar3IconsPerRow=20;standaloneBuffRowGrowDirection="up";skyridingVigorColorR=0;lowHealthWarningColorR=1;hideAB2InCombat=1;ufCustomBorderColorG=0;standaloneUtilityMaxRows=2;ufBigHBNameMaxChars=18;combatTimerScale=0.89999997615814;hidePetBarAlways=0;stackTextOffsetY=0;offsetX=20;combatTimerY=-536;combatTimerX=828;crTimerY=-537;crTimerLayout="horizontal";useCustomBorderColor=1;ufBigHBTargetNameTextScale=1.05;prbLowHealthColorB=0;autoQuestRewardMode="skip";autoRepair=1;ufBigHBTargetNameY=1;castbarBgColorB=0.13333334028721;customBarUseBuffOverlay=0;playerDebuffSortDirection="right";customBar2IconsPerRow=20;hideAB2Always=0;prbAutoWidthSource="essential";noTargetAlertColorR=1;hideEliteTexture=0;fadeBagBar=1;noTargetAlertY=95;iconsCombatOnly=0;castbarBgColorR=0.13333334028721;standaloneEssentialSecondRowSize=39.5;ufNameColorR=1;selfHighlightShape="cross";prbY=-271;playerDebuffY=231;skyridingWhirlingSurgeColorG=0.23921570181847;selfHighlightThickness="thin";lowHealthWarningEnabled=1;crTimerScale=1.1000000238419;lowHealthWarningX=0;iconBorderSize=1;showTooltipIDs=1;prbAbsorbStripes=1;standaloneUtilitySize=42.5;spellGlowThickness=2.8;blizzBarUtilityX=0;chatTabFlash=1;castbarY=-291;customBar2CdGradientR=0;prbHealthColorR=0;combatStatusLeaveColorG=1;hideAB4Mouseover=1;focusCastbarCentered=1;customBar2AnchorPoint="RIGHT";prbCentered=1;noTargetAlertFontSize=37;customBar2CdGradientB=0;skyridingHideCDM=1;abSkinSpacing=0;radialAlpha=1;skyridingY=-205;customBar3X=-188;standaloneIconBorderSize=1;prbLowHealthThreshold=40;customBarY=0;ufBigHBPlayerNameY=12;customBarCdGradientThreshold=5;prbBorderSize=1;quickRoleSignup=1;noTargetAlertColorG=0;ufBigHBFocusNameAnchor="left";cdTextGradientG=1;skyridingTexture="lsm:Solid";iconSize=45;focusCastbarY=106;ufBigHBHideTargetName=0;customBar3IconSize=55;hidePetBarInCombat=1;standaloneUtilityCentered=1;skyridingVigorBar=1;standaloneUtilityIconsPerRow=6;prbOverAbsorbBar=1;focusCastbarColorB=0.023529414087534;standaloneBuffCentered=1;standaloneEssentialCentered=1;focusCastbarWidth=300;castbarColorB=0;standaloneEssentialSize=50;skyridingWhirlingSurgeColorB=0.96862751245499;focusCastbarColorR=1;customBar3Y=-118;prbHealthYOffset=9;skyridingVigorEmptyColorG=0.14901961386204;castbarSpellNameScale=1.2;enhancedTooltip=1;customBar3TrackBuffs=0;chatHideButtons=1;prbHealPred="on";showGCD=0;standaloneEssentialY=-218;castbarBorderSize=1;hideAB6Mouseover=1;focusCastbarX=0;hideAB6InCombat=1;blizzBarBuffX=0;ufBigHBFocusNameY=0;hideStanceBarMouseover=1;prbManaYOffset=-23;blizzBarEssentialY=-218;hideActionBar1InCombat=1;ufHideGroupIndicator=1;focusCastbarShowIcon=1;radialColorR=0;selfHighlightColorG=1;customBarGrowth="UP";customBarUseSpellGlows=1;customBar2X=-41;selfHighlightY=0;customBarCdGradientB=0.1843137294054;usePersonalResourceBar=1;autoQuestExcludeCompleted=1;customBar2CdGradientG=1;skyridingSecondWindColorB=0.23529413342476;skyridingVigorColorG=1;prbShowManaBar=0;combatStatusY=59;lowHealthWarningSound="Details Horn";customBar3ShowMode="always";ufBigHBTargetNameAnchor="left";chatEditBoxStyled=1;prbBgColorB=0;castbarCentered=1;ufBigHBPlayerHealAbsorb="on";ufBigHBFocusLevelMode="hidemax";fadeMicroMenu=1;ufBigHBPlayerNameAnchor="center";useCastbar=1;hidePetBarMouseover=1;customBar2IconSize=40;hideAB4Always=0;stackTextScale=1.1000000238419;prbHealthTextMode="percent";skyridingVigorRechargeColorR=0.68627452850342;cooldownIconMode="show";castbarColorG=0;customBar2CdTextScale=1;customBar2Spacing=0;standaloneUtilitySecondRowSize=45;castbarShowIcon=0;skyridingEnabled=1;castbarX=0;standaloneEssentialMaxRows=2;customBar2CdGradientThreshold=10;selfHighlightColorR=0;castbarAutoWidthSource="utility";prbLowPowerColorR=1;prbBackgroundAlpha=100;ufBigHBFocusEnabled=1;cursorCombatOnly=1;spellGlowSpeed=0;prbPowerTextMode="percentnumber";disableBlizzCDM=0;autoQuestExcludeDaily=1;skyridingScale=110;autoQuest=1;customBarAnchorToPoint="TOPRIGHT";customBar2Y=20;ufBigHBFocusLevelY=0;showMinimapButton=1;skyridingVigorColorB=0.59607845544815;crTimerMode="always";prbLowHealthColorR=1;cdTextScale=1;skyridingSecondWindColorG=0;standaloneUtilityGrowDirection="right";disableTargetBuffs=1;hideAB3InCombat=1;castbarTexture="lsm:Solid";standaloneCdTextScale=1.7;noTargetAlertFlash=1;combatTimerMode="always";skyridingCooldowns=1;alwaysShowInEnabled=0;standaloneUtilityRowGrowDirection="down";standaloneBuffMaxRows=2;hideActionBarBorders=1;customBar3Centered=1;useBuffOverlay=0;customBar3StackTextOffsetX=0;blizzBarBuffY=-170;standaloneBuffIconsPerRow=10;combatStatusX=0;noTargetAlertEnabled=1;chatUrlDetection=1;focusCastbarTexture="lsm:Solid";customBar3Spacing=2;customBarIconSize=40;ufBigHBPlayerAbsorbStripes=1;customBarAnchorFrame="PlayerFrame";ufCustomBorderColorB=0;skyridingX=0;customBarIconsPerRow=4;playerDebuffRowGrowDirection="up";ufClassColor=1;skyridingCentered=1;ufBigHBPlayerLevelMode="hidemax";ufBigHBPlayerEnabled=1;customBar2UseSpellGlows=1;ufDisableGlows=1;hideStanceBarAlways=0;actionBarGlobalMode="combat_mouseover";selfHighlightSize=23;useFocusCastbar=1;customBarStackTextScale=1;hideActionBar1Mouseover=1;stackTextOffsetX=0;combatTimerTextColorR=1;ufBigHBTargetLevelX=-1;ufUseCustomTextures=1;prbShowClassPower=1;hideAB7Mouseover=1;combatStatusEnterColorR=1;trackBuffs=0;chatClassColorNames=1;layoutDirection="horizontal";hideAB8Mouseover=1;hideAB6Always=0;customBarTrackBuffs=0;combatTimerTextColorG=1;playerDebuffIconsPerRow=5;radialColorB=0.61568629741669;hideAB5Always=0;ufBigHBPlayerLevelX=-106;globalFont="lsm:Expressway";hideAB2Mouseover=1;cdTextGradientThreshold=7;customBar2UseBuffOverlay=0;prbClampBars=1;autoSellJunk=1;crTimerEnabled=1;customBarShowMode="always";prbLowHealthColorG=0;standaloneEssentialCdTextScale=2;radialRadius=20;customBarCdTextScale=1;blizzBarEssentialX=0;standaloneSkinEssential=1;customBar4X=0;hideAB3Always=0;useEssentialBar=0;prbHealthColorG=1;customBarShowGCD=1;chatTimestamps=1;prbBgColorG=0;prbSpacing=-1;chatBackgroundColorB=0;ufBigHBTargetLevelMode="hidemax";ufNameColorG=1;ufBigHBFocusLevelX=107;skyridingWhirlingSurgeColorR=0;customBar4Centered=1;cdTextGradientB=0;prbLowPowerColorG=0.17254902422428;customBarStackTextOffsetY=0;combatStatusEnterColorB=0;prbPowerTexture="lsm:Solid";crTimerX=997;combatTimerBgColorR=0.12;standaloneBuffCdTextScale=1.2;cdTextGradientR=0.062745101749897;standaloneUtilityCdTextScale=2.3;customBar2AnchorFrame="CCMCustomBar";betterItemLevel=1;customBar2OutOfCombat=1;cdFont="lsm:Expressway";hideAB8Always=0;customBarCdGradientG=1;stackTextPosition="BOTTOMRIGHT";hideTrackedBlizzBuffIcons=1;prbUseClassColor=0;standaloneBuffY=-170;focusCastbarHeight=35;growDirection="right";ufBigHBHidePlayerName=0;ufBigHBHideRealm=1;lowHealthWarningColorG=0;chatBackground=1;ufBigHBPlayerLevelY=1;prbPowerYOffset=-38;prbClassPowerHeight=12;skyridingVigorRechargeColorG=0;globalOutline="OUTLINE";combatStatusScale=1.1000000238419;offsetY=20;standaloneSpacing=0;autoQuestExcludeTrivial=1;crTimerCentered=0;customBar3OutOfCombat=1;autoQuestExcludeWeekly=1;standaloneEssentialRowGrowDirection="up";customBarStackTextOffsetX=2;customBarCooldownMode="hide";customBar2AnchorToPoint="TOPRIGHT";prbPowerHeight=15;combatTimerBgColorG=0.12;standaloneUtilityY=-352.5;prbShowPower=1;combatTimerTextColorB=1;ufCustomBorderColorR=0;customBar3CdTextScale=1;prbLowPowerColorB=0;ufBigHBTargetLevelY=0;lowHealthWarningFontSize=45;chatFadeToggle=1;combatTimerEnabled=1;fadeObjectiveTracker=1;focusCastbarColorG=0;standaloneSkinBuff=1;skyridingSecondWindColorR=0.50588238239288;noTargetAlertColorB=0.031372550874949;customBar2Centered=1;prbHealAbsorb="on";customBar2ShowMode="raid";chatFadeDelay=20;iconsPerRow=5;skyridingVigorRechargeColorB=0.0078431377187371;radialThickness=3;radialColorG=1;customBarsCount=2;crTimerDisplay="timer";prbPowerTextY=0;useBuffBar=0;ufBigHBTargetHealPred="off";ufBigHBFocusHealPred="off";iconSpacing=0;lowHealthWarningY=-33;chatEditBoxPosition="bottom";lowHealthWarningColorB=0;castbarUseClassColor=0;castbarBgAlpha=80;prbHealthColorB=0.21960785984993;skyridingVigorEmptyColorB=0.14901961386204;useSpellGlows=0;prbBgColorR=0;playerDebuffX=581;prbUsePowerTypeColor=1;playerDebuffSize=63;hideActionBar1Always=0;customBar2CooldownMode="hide";ufBigHBTargetAbsorbStripes=1;autoFillDelete=1;customBarX=-92;chatHideTabs="mouseover";castbarColorR=0.40000003576279;enablePlayerDebuffs=1;hideAB3Mouseover=1;prbUseLowHealthColor=1;customBarSpacing=0;playerDebuffSpacing=0;uiScale=0.53333;hideStanceBarInCombat=1;blizzardBarSkinning=1;showInCombatOnly=0;combatStatusLeaveColorB=0;playerDebuffBorderSize=2;ufHealthTexture="lsm:Solid";ufBigHBTargetEnabled=1;ufBigHBHideFocusName=0;hideAB8InCombat=1;chatBackgroundColorR=0;ufDisableCombatText=1;castbarBgColorG=0.13333334028721;castbarHeight=35;showRadialCircle=1;hideAB5InCombat=1;lowHealthWarningFlash=1;hideAB7Always=0;combatStatusEnterColorG=0.094117656350136;hideAB7InCombat=1;standaloneEssentialGrowDirection="right";ufBigHBPlayerLevelTextScale=0.95;standaloneSkinUtility=1;focusCastbarTimePrecision="1";combatTimerCentered=0;customBarCentered=1;chatCopyButtonCorner="TOPRIGHT";prbClampAnchor="top";ufBigHBFocusNameX=0;combatStatusCentered=1;standaloneUtilityAutoWidth="off";ufNameColorB=1;customBar3StackTextOffsetY=0;audioChannel="Master";standaloneBuffSize=40;showEquipmentDetails=1;combatStatusLeaveColorR=0.13333334028721;customBar2StackTextPosition="BOTTOMRIGHT";uiScaleMode="1440p";customBar2TrackBuffs=0;selfHighlightOutline=1;ufBigHBPlayerDmgAbsorb="bar_glow";]]
  if addonTable.importBtn then
    addonTable.importBtn:SetScript("OnClick", function()
      if addonTable.exportImportPopup then
        addonTable.exportImportTitle:SetText("Import Profile Settings")
        addonTable.importExportBox:SetText("")
        addonTable.exportCheckboxContainer:Hide()
        addonTable.generateExportBtn:Hide()
        addonTable.exportImportOkBtn:Show()
        addonTable.exportImportPopup:SetSize(480, 315)
        addonTable.exportImportScrollFrame:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 15, -110)
        addonTable.exportImportScrollFrame:SetSize(420, 145)
        addonTable.importExportBox:SetWidth(400)
        addonTable.importExportBox:SetHeight(200)
        if addonTable.exportImportOkBtn and addonTable.exportImportCancelBtn and addonTable.exportImportScrollFrame then
          addonTable.exportImportOkBtn:ClearAllPoints()
          addonTable.exportImportCancelBtn:ClearAllPoints()
          addonTable.exportImportOkBtn:SetPoint("TOPRIGHT", addonTable.exportImportScrollFrame, "BOTTOM", -5, -14)
          addonTable.exportImportCancelBtn:SetPoint("TOPLEFT", addonTable.exportImportScrollFrame, "BOTTOM", 5, -14)
          addonTable.exportImportCancelBtn:Show()
        end
        if addonTable.editBoxBg then
          addonTable.editBoxBg:SetPoint("TOPLEFT", addonTable.exportImportScrollFrame, "TOPLEFT", -5, 5)
          addonTable.editBoxBg:SetPoint("BOTTOMRIGHT", addonTable.exportImportScrollFrame, "BOTTOMRIGHT", 15, -5)
        end
        if addonTable.importContainer then addonTable.importContainer:Show() end
        if addonTable.importProfileNameBox then addonTable.importProfileNameBox:SetText("") end
        if addonTable.importSharedCB then addonTable.importSharedCB:SetChecked(true) end
        local function DoImport()
          local str = addonTable.importExportBox:GetText()
          local profileName = addonTable.importProfileNameBox and addonTable.importProfileNameBox:GetText() or ""
          if profileName == "" or profileName:match("^%s*$") then
            print("|cffff6666CCM:|r Please enter a profile name!")
            if addonTable.importProfileNameBox then
              addonTable.importProfileNameBox:SetBackdropBorderColor(1, 0.3, 0.3, 1)
              addonTable.importProfileNameBox:SetFocus()
              C_Timer.After(2, function()
                if addonTable.importProfileNameBox then
                  addonTable.importProfileNameBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                end
              end)
            end
            return
          end
          if not str or str == "" then
            print("|cffff6666CCM:|r Please paste an import string!")
            addonTable.importExportBox:SetFocus()
            return
          end
          if str and (str:match("^CCM:") or str:match("^CCM2:")) then
            local origName, data = str:match("^CCM2?:([^:]+):(.+)$")
            if origName and data then
              local baseName = profileName
              local counter = 1
              while CooldownCursorManagerDB.profiles[profileName] do
                profileName = baseName .. "_" .. counter
                counter = counter + 1
              end
              CooldownCursorManagerDB.profiles[profileName] = {}
              CooldownCursorManagerDB.currentProfile = profileName
              local isShared = addonTable.importSharedCB and addonTable.importSharedCB:GetChecked()
              if not isShared then
                local _, playerClass = UnitClass("player")
                if playerClass then
                  CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
                  CooldownCursorManagerDB.profileClasses[profileName] = playerClass
                end
              end
              if addonTable.SaveCurrentProfileForSpec then
                addonTable.SaveCurrentProfileForSpec()
              else
                local playerName = UnitName("player")
                local realmName = GetRealmName()
                if playerName and realmName then
                  local characterKey = playerName .. "-" .. realmName
                  CooldownCursorManagerDB.characterProfiles = CooldownCursorManagerDB.characterProfiles or {}
                  CooldownCursorManagerDB.characterProfiles[characterKey] = profileName
                end
              end
              local profile = GetProfile()
              if profile then
                ApplySerializedDataToProfile(profile, data)
                if addonTable.profileText then addonTable.profileText:SetText(profileName) end
                if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
                UpdateAllControls()
                C_Timer.After(0.1, function()
                  if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end
                  if addonTable.UpdatePRB then addonTable.UpdatePRB() end
                  if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end
                end)
                CreateIcons()
                if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
                if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
                if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
                if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
                if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
                if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
                if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
                print("|cff00ff00CCM:|r Imported settings to new profile: " .. profileName)
                ShowReloadPrompt("Profile '" .. profileName .. "' imported successfully.\n\nA UI reload is recommended for all changes to take effect. Reload now?", "Reload", "Later")
              end
            end
          else
            print("|cffff6666CCM:|r Invalid import string! Must start with CCM: or CCM2:")
          end
          addonTable.exportImportPopup:Hide()
        end
        addonTable.exportImportOkBtn:SetScript("OnClick", DoImport)
        addonTable.importExportBox:SetScript("OnEnterPressed", function()
          DoImport()
        end)
        if addonTable.importProfileNameBox then
          addonTable.importProfileNameBox:SetScript("OnEnterPressed", function(s)
            s:ClearFocus()
            DoImport()
          end)
        end
        addonTable.exportImportPopup:Show()
        addonTable.importProfileNameBox:SetFocus()
      end
    end)
  end
  if addonTable.exportBtn then
    addonTable.exportBtn:SetScript("OnClick", function()
      if addonTable.exportImportPopup then
        addonTable.exportImportTitle:SetText("Export Profile Settings")
        addonTable.importExportBox:SetText("")
        addonTable.exportCheckboxContainer:Show()
        addonTable.generateExportBtn:Show()
        addonTable.exportImportOkBtn:Hide()
        if addonTable.importContainer then addonTable.importContainer:Hide() end
        addonTable.exportImportPopup:SetSize(500, 360)
        addonTable.exportImportScrollFrame:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 15, -205)
        addonTable.exportImportScrollFrame:SetSize(420, 130)
        addonTable.importExportBox:SetWidth(400)
        if addonTable.generateExportBtn then
          addonTable.generateExportBtn:ClearAllPoints()
          addonTable.generateExportBtn:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 290, -192)
        end
        if addonTable.exportImportOkBtn then
          addonTable.exportImportOkBtn:ClearAllPoints()
          addonTable.exportImportOkBtn:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 290, -192)
        end
        if addonTable.exportImportCancelBtn then
          addonTable.exportImportCancelBtn:ClearAllPoints()
          addonTable.exportImportCancelBtn:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 380, -192)
          addonTable.exportImportCancelBtn:Show()
        end
        if addonTable.editBoxBg then
          addonTable.editBoxBg:SetPoint("TOPLEFT", addonTable.exportImportScrollFrame, "TOPLEFT", -5, 5)
          addonTable.editBoxBg:SetPoint("BOTTOMRIGHT", addonTable.exportImportScrollFrame, "BOTTOMRIGHT", 15, -5)
        end
        addonTable.importExportBox:SetScript("OnTextChanged", nil)
        for _, cb in pairs(addonTable.exportCategories) do
          cb:SetChecked(true)
        end
        addonTable.generateExportBtn:SetScript("OnClick", function()
          local profile = GetProfile()
          if profile then
            local str = "CCM2:" .. (CooldownCursorManagerDB.currentProfile or "Default") .. ":"
            local selectedCategories = {general = true, qol = true}
            for cat, cb in pairs(addonTable.exportCategories) do
              if cb:GetChecked() then
                selectedCategories[cat] = true
              end
            end
            for k, v in pairs(profile) do
              local cat = keyToCategory[k]
              if cat and selectedCategories[cat] then
                if type(v) == "boolean" then
                  str = str .. k .. "=" .. (v and "1" or "0") .. ";"
                elseif type(v) == "number" then
                  str = str .. k .. "=" .. v .. ";"
                elseif type(v) == "string" then
                  str = str .. k .. "=\"" .. v .. "\";"
                end
              end
            end
            addonTable.importExportBox:SetText(str)
            addonTable.importExportBox:HighlightText()
            addonTable.importExportBox:SetFocus()
          end
        end)
        addonTable.exportImportPopup:Show()
      end
    end)
  end
  C_Timer.After(0.2, UpdateSkinCheckboxes)
  if addonTable.cursorCDMCB then
    addonTable.cursorCDMCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      p.cursorIconsEnabled = s:GetChecked() == true
      if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
    end
  end
  if addonTable.customBarsModuleCB then
    addonTable.customBarsModuleCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      local _, needsReload = SetModuleEnabled("custombars", s:GetChecked())
      if not IsModuleEnabled("custombars") then
        s:SetChecked(false)
      elseif p.customBarsCount == 0 then
        p.customBarsCount = 1
      end
      local count = math.floor(tonumber(p.customBarsCount) or 0)
      if count < 0 then count = 0 end
      if count > 5 then count = 5 end
      p.customBarsCount = count
      p.customBarEnabled = (count >= 1)
      p.customBar2Enabled = (count >= 2)
      p.customBar3Enabled = (count >= 3)
      p.customBar4Enabled = (count >= 4)
      p.customBar5Enabled = (count >= 5)
      if addonTable.customBarsCountSlider then
        addonTable.customBarsCountSlider._updating = true
        addonTable.customBarsCountSlider:SetValue(count)
        addonTable.customBarsCountSlider._updating = false
        addonTable.customBarsCountSlider.valueText:SetText(count)
      end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
      if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
      if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
      if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
      if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
      if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
      if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end
      if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end
      if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end
      if addonTable.UpdateCustomBar4Position then addonTable.UpdateCustomBar4Position() end
      if addonTable.UpdateCustomBar5Position then addonTable.UpdateCustomBar5Position() end
      if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
      if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      SyncModuleControlsState()
      if s:GetChecked() and IsModuleEnabled("custombars") then
        ShowModuleActivatedMessage("Custom Bars")
      end
      if needsReload then
        ShowReloadPrompt("Custom Bars module state changed. Reload UI now?", "Reload", "Later")
      end
    end
  end
  if addonTable.prbCB then
    addonTable.prbCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        local _, needsReload = SetModuleEnabled("prb", s:GetChecked())
        if not IsModuleEnabled("prb") then
          s:SetChecked(false)
          if addonTable.UpdatePRB then addonTable.UpdatePRB() end
          SyncModuleControlsState()
          if needsReload then
            ShowReloadPrompt("PRB module state changed. Reload UI now?", "Reload", "Later")
          end
          return
        end
        p.usePersonalResourceBar = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if addonTable.UpdatePRB then addonTable.UpdatePRB() end
        if s:GetChecked() then C_Timer.After(0.1, function() if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end; if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end) end
        if s:GetChecked() and IsModuleEnabled("prb") then
          ShowModuleActivatedMessage("PRB")
        end
        if needsReload then
          ShowReloadPrompt("PRB module state changed. Reload UI now?", "Reload", "Later")
        end
      end
    end
  end
  local prb = addonTable.prb
  if prb then
    local function UpdatePRB() if addonTable.UpdatePRB then C_Timer.After(0, addonTable.UpdatePRB) end end
    local function num(v, d) return tonumber(v) or d end
    local function LoadPRBValues()
      local p = GetProfile(); if not p then return end
      if prb.centeredCB then prb.centeredCB:SetChecked(p.prbCentered == true) end
      if prb.showModeDD then prb.showModeDD:SetValue(p.prbShowMode or "always") end
      if prb.anchorDD then prb.anchorDD:SetValue(p.prbClampAnchor or "top") end
      if prb.autoWidthDD then prb.autoWidthDD:SetValue(p.prbAutoWidthSource or "off") end
      local isAuto = (p.prbAutoWidthSource or "off") ~= "off"
      local isCentered = p.prbCentered == true
      if prb.widthSlider then prb.widthSlider:SetValue(num(p.prbWidth, 220)); prb.widthSlider.valueText:SetText(math.floor(num(p.prbWidth, 220))); prb.widthSlider:SetEnabled(not isAuto); if prb.widthSlider.label then prb.widthSlider.label:SetTextColor(isAuto and 0.5 or 1, isAuto and 0.5 or 1, isAuto and 0.5 or 1) end end
      if prb.xSlider then prb.xSlider:SetValue(num(p.prbX, 0)); prb.xSlider.valueText:SetText(math.floor(num(p.prbX, 0))); prb.xSlider:SetEnabled(not isCentered); if prb.xSlider.label then prb.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1) end end
      if prb.ySlider then local yVal = num(p.prbY, -180); prb.ySlider:SetValue(yVal); prb.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if prb.spacingSlider then prb.spacingSlider:SetValue(num(p.prbSpacing, 0)); prb.spacingSlider.valueText:SetText(math.floor(num(p.prbSpacing, 0))) end
      if prb.borderSlider then prb.borderSlider:SetValue(num(p.prbBorderSize, 1)); prb.borderSlider.valueText:SetText(math.floor(num(p.prbBorderSize, 1))) end
      if prb.bgColorSwatch then prb.bgColorSwatch:SetBackdropColor(p.prbBgColorR or 0.1, p.prbBgColorG or 0.1, p.prbBgColorB or 0.1, 1) end
      if prb.clampBarsCB then prb.clampBarsCB:SetChecked(p.prbClampBars == true) end
      if prb.showHealthCB then prb.showHealthCB:SetChecked(p.prbShowHealth == true) end
      if prb.showPowerCB then prb.showPowerCB:SetChecked(p.prbShowPower == true) end
      if prb.healthHeightSlider then prb.healthHeightSlider:SetValue(num(p.prbHealthHeight, 18)); prb.healthHeightSlider.valueText:SetText(math.floor(num(p.prbHealthHeight, 18))) end
      if prb.healthYOffsetSlider then prb.healthYOffsetSlider:SetValue(num(p.prbHealthYOffset, 0)); prb.healthYOffsetSlider.valueText:SetText(math.floor(num(p.prbHealthYOffset, 0))) end
      if prb.healthTextureDD then prb.healthTextureDD:SetValue(p.prbHealthTexture or "solid") end
      if prb.healAbsorbCB then prb.healAbsorbCB:SetChecked((p.prbHealAbsorb or "on") ~= "off") end
      if prb.showAbsorbCB then
        local dmgMode = p.prbDmgAbsorb or "bar"
        prb.showAbsorbCB:SetChecked(dmgMode ~= "off")
      end
      if prb.absorbStripesCB then prb.absorbStripesCB:SetChecked(p.prbAbsorbStripes == true) end
      if prb.healPredCB then prb.healPredCB:SetChecked((p.prbHealPred or "on") ~= "off") end
      if prb.overAbsorbBarCB then prb.overAbsorbBarCB:SetChecked(p.prbOverAbsorbBar ~= false) end
      if prb.healthTextDD then prb.healthTextDD:SetValue(p.prbHealthTextMode or "hidden") end
      if prb.healthTextScaleSlider then prb.healthTextScaleSlider:SetValue(num(p.prbHealthTextScale, 1)); prb.healthTextScaleSlider.valueText:SetText(string.format("%.1f", num(p.prbHealthTextScale, 1))) end
      if prb.healthTextYSlider then prb.healthTextYSlider:SetValue(num(p.prbHealthTextY, 0)); prb.healthTextYSlider.valueText:SetText(math.floor(num(p.prbHealthTextY, 0))) end
      if prb.useClassColorCB then prb.useClassColorCB:SetChecked(p.prbUseClassColor == true) end
      local useClassColor = p.prbUseClassColor == true
      if prb.healthColorBtn then prb.healthColorBtn:SetEnabled(not useClassColor); prb.healthColorBtn:SetAlpha(useClassColor and 0.5 or 1) end
      if prb.healthColorSwatch then prb.healthColorSwatch:SetBackdropColor(p.prbHealthColorR or 0, p.prbHealthColorG or 1, p.prbHealthColorB or 0, 1); prb.healthColorSwatch:SetAlpha(useClassColor and 0.5 or 1) end
      if prb.lowHealthColorCB then prb.lowHealthColorCB:SetChecked(p.prbUseLowHealthColor == true) end
      local lowHPEnabled = p.prbUseLowHealthColor == true
      if prb.lowHealthColorBtn then prb.lowHealthColorBtn:SetEnabled(lowHPEnabled); prb.lowHealthColorBtn:SetAlpha(lowHPEnabled and 1 or 0.5) end
      if prb.lowHealthColorSwatch then prb.lowHealthColorSwatch:SetBackdropColor(p.prbLowHealthColorR or 1, p.prbLowHealthColorG or 0, p.prbLowHealthColorB or 0, 1); prb.lowHealthColorSwatch:SetAlpha(lowHPEnabled and 1 or 0.5) end
      if prb.lowHealthThresholdSlider then local tv = num(p.prbLowHealthThreshold, 50); prb.lowHealthThresholdSlider:SetValue(tv); prb.lowHealthThresholdSlider.valueText:SetText(math.floor(tv) .. "%"); prb.lowHealthThresholdSlider:SetEnabled(lowHPEnabled); prb.lowHealthThresholdSlider:SetAlpha(lowHPEnabled and 1 or 0.5) end
      if addonTable.RebuildLowHealthCurve then addonTable.RebuildLowHealthCurve(num(p.prbLowHealthThreshold, 50)) end
      if prb.healthTextColorSwatch then prb.healthTextColorSwatch:SetBackdropColor(p.prbHealthTextColorR or 1, p.prbHealthTextColorG or 1, p.prbHealthTextColorB or 1, 1) end
      if prb.powerHeightSlider then prb.powerHeightSlider:SetValue(num(p.prbPowerHeight, 8)); prb.powerHeightSlider.valueText:SetText(math.floor(num(p.prbPowerHeight, 8))) end
      if prb.powerYOffsetSlider then prb.powerYOffsetSlider:SetValue(num(p.prbPowerYOffset, 0)); prb.powerYOffsetSlider.valueText:SetText(math.floor(num(p.prbPowerYOffset, 0))) end
      if prb.powerTextureDD then prb.powerTextureDD:SetValue(p.prbPowerTexture or "solid") end
      if prb.powerTextDD then prb.powerTextDD:SetValue(p.prbPowerTextMode or "hidden") end
      if prb.powerTextScaleSlider then prb.powerTextScaleSlider:SetValue(num(p.prbPowerTextScale, 1)); prb.powerTextScaleSlider.valueText:SetText(string.format("%.1f", num(p.prbPowerTextScale, 1))) end
      if prb.powerTextYSlider then prb.powerTextYSlider:SetValue(num(p.prbPowerTextY, 0)); prb.powerTextYSlider.valueText:SetText(math.floor(num(p.prbPowerTextY, 0))) end
      if prb.usePowerTypeColorCB then prb.usePowerTypeColorCB:SetChecked(p.prbUsePowerTypeColor ~= false) end
      local usePowerTypeColor = p.prbUsePowerTypeColor ~= false
      if prb.powerColorBtn then prb.powerColorBtn:SetEnabled(not usePowerTypeColor); prb.powerColorBtn:SetAlpha(usePowerTypeColor and 0.5 or 1) end
      if prb.powerColorSwatch then prb.powerColorSwatch:SetBackdropColor(p.prbPowerColorR or 0, p.prbPowerColorG or 0.5, p.prbPowerColorB or 1, 1); prb.powerColorSwatch:SetAlpha(usePowerTypeColor and 0.5 or 1) end
      if prb.lowPowerColorCB then prb.lowPowerColorCB:SetChecked(p.prbUseLowPowerColor == true) end
      local lowPwrEnabled = p.prbUseLowPowerColor == true
      if prb.lowPowerColorBtn then prb.lowPowerColorBtn:SetEnabled(lowPwrEnabled); prb.lowPowerColorBtn:SetAlpha(lowPwrEnabled and 1 or 0.5) end
      if prb.lowPowerColorSwatch then prb.lowPowerColorSwatch:SetBackdropColor(p.prbLowPowerColorR or 1, p.prbLowPowerColorG or 0.5, p.prbLowPowerColorB or 0, 1); prb.lowPowerColorSwatch:SetAlpha(lowPwrEnabled and 1 or 0.5) end
      if prb.lowPowerThresholdSlider then local tv = num(p.prbLowPowerThreshold, 30); prb.lowPowerThresholdSlider:SetValue(tv); prb.lowPowerThresholdSlider.valueText:SetText(math.floor(tv) .. "%"); prb.lowPowerThresholdSlider:SetEnabled(lowPwrEnabled); prb.lowPowerThresholdSlider:SetAlpha(lowPwrEnabled and 1 or 0.5) end
      if addonTable.RebuildLowPowerCurve then addonTable.RebuildLowPowerCurve(num(p.prbLowPowerThreshold, 30)) end
      if prb.powerTextColorSwatch then prb.powerTextColorSwatch:SetBackdropColor(p.prbPowerTextColorR or 1, p.prbPowerTextColorG or 1, p.prbPowerTextColorB or 1, 1) end
      if prb.showManaBarCB then prb.showManaBarCB:SetChecked(p.prbShowManaBar == true) end
      if prb.manaHeightSlider then prb.manaHeightSlider:SetValue(num(p.prbManaHeight, 6)); prb.manaHeightSlider.valueText:SetText(math.floor(num(p.prbManaHeight, 6))) end
      if prb.manaYOffsetSlider then prb.manaYOffsetSlider:SetValue(num(p.prbManaYOffset, 0)); prb.manaYOffsetSlider.valueText:SetText(math.floor(num(p.prbManaYOffset, 0))) end
      if prb.manaTextureDD then prb.manaTextureDD:SetValue(p.prbManaTexture or "solid") end
      if prb.manaTextDD then prb.manaTextDD:SetValue(p.prbManaTextMode or "hidden") end
      if prb.manaTextScaleSlider then prb.manaTextScaleSlider:SetValue(num(p.prbManaTextScale, 1)); prb.manaTextScaleSlider.valueText:SetText(string.format("%.1f", num(p.prbManaTextScale, 1))) end
      if prb.manaTextYSlider then prb.manaTextYSlider:SetValue(num(p.prbManaTextY, 0)); prb.manaTextYSlider.valueText:SetText(math.floor(num(p.prbManaTextY, 0))) end
      if prb.manaColorSwatch then prb.manaColorSwatch:SetBackdropColor(p.prbManaColorR or 0, p.prbManaColorG or 0.4, p.prbManaColorB or 0.9, 1) end
      if prb.manaTextColorSwatch then prb.manaTextColorSwatch:SetBackdropColor(p.prbManaTextColorR or 1, p.prbManaTextColorG or 1, p.prbManaTextColorB or 1, 1) end
      if prb.showClassPowerCB then prb.showClassPowerCB:SetChecked(p.prbShowClassPower == true) end
      if prb.classPowerHeightSlider then prb.classPowerHeightSlider:SetValue(num(p.prbClassPowerHeight, 6)); prb.classPowerHeightSlider.valueText:SetText(math.floor(num(p.prbClassPowerHeight, 6))) end
      if prb.classPowerYSlider then prb.classPowerYSlider:SetValue(num(p.prbClassPowerY, 20)); prb.classPowerYSlider.valueText:SetText(math.floor(num(p.prbClassPowerY, 20))) end
      if prb.classPowerColorSwatch then prb.classPowerColorSwatch:SetBackdropColor(p.prbClassPowerColorR or 1, p.prbClassPowerColorG or 0.82, p.prbClassPowerColorB or 0, 1) end
    end
    addonTable.LoadPRBValues = LoadPRBValues
    C_Timer.After(0.3, LoadPRBValues)
    C_Timer.After(0.35, function() if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end)
    local function UpdatePRBAndHighlight() UpdatePRB(); if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(7) end end
    if prb.centeredCB then prb.centeredCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbCentered = s:GetChecked(); UpdatePRBAndHighlight(); local isCentered = s:GetChecked(); if prb.xSlider then prb.xSlider:SetEnabled(not isCentered); if prb.xSlider.label then prb.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1) end end end end end
    if prb.showModeDD then prb.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.prbShowMode = v; UpdatePRBAndHighlight() end end end
    if prb.anchorDD then prb.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.prbClampAnchor = v; UpdatePRBAndHighlight() end end end
    if prb.widthSlider then prb.widthSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbWidth = r; UpdatePRBAndHighlight() end end) end
    if prb.autoWidthDD then prb.autoWidthDD.onSelect = function(v) local p = GetProfile(); if p then p.prbAutoWidthSource = v; UpdatePRBAndHighlight(); local isAuto = (v ~= "off"); if prb.widthSlider then prb.widthSlider:SetEnabled(not isAuto); if prb.widthSlider.label then prb.widthSlider.label:SetTextColor(isAuto and 0.5 or 1, isAuto and 0.5 or 1, isAuto and 0.5 or 1) end end end end end
    if prb.xSlider then prb.xSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.prbX = r; UpdatePRBAndHighlight() end end) end
    if prb.ySlider then prb.ySlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 2 + 0.5) / 2; s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end; local p = GetProfile(); if p then p.prbY = r; UpdatePRBAndHighlight() end end) end
    if prb.spacingSlider then prb.spacingSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbSpacing = r; UpdatePRBAndHighlight() end end) end
    if prb.borderSlider then prb.borderSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbBorderSize = r; UpdatePRBAndHighlight() end end) end
    if prb.bgColorBtn then prb.bgColorBtn:SetScript("OnClick", function()
      local p = GetProfile(); if not p then return end
      local r, g, b = p.prbBgColorR or 0.1, p.prbBgColorG or 0.1, p.prbBgColorB or 0.1
      local a = (p.prbBackgroundAlpha or 80) / 100
      local function OnChange()
        local nR, nG, nB = ColorPickerFrame:GetColorRGB()
        local nA = ColorPickerFrame:GetColorAlpha() or 1
        p.prbBgColorR, p.prbBgColorG, p.prbBgColorB = nR, nG, nB
        p.prbBackgroundAlpha = math.floor(nA * 100)
        prb.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1)
        UpdatePRB()
      end
      local function OnCancel(prev)
        p.prbBgColorR, p.prbBgColorG, p.prbBgColorB = prev.r, prev.g, prev.b
        p.prbBackgroundAlpha = math.floor(prev.a * 100)
        prb.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
        UpdatePRB()
      end
      ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnChange, opacityFunc = OnChange, cancelFunc = OnCancel})
    end) end
    if prb.showHealthCB then prb.showHealthCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowHealth = s:GetChecked(); UpdatePRBAndHighlight(); if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end end end
    if prb.showPowerCB then prb.showPowerCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowPower = s:GetChecked(); UpdatePRBAndHighlight(); if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end end end
    if prb.healthHeightSlider then prb.healthHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbHealthHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.healthYOffsetSlider then prb.healthYOffsetSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbHealthYOffset = r; UpdatePRBAndHighlight() end end) end
    if prb.healthTextureDD then prb.healthTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.prbHealthTexture = v; UpdatePRBAndHighlight() end end end
    if prb.healAbsorbCB then prb.healAbsorbCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbHealAbsorb = s:GetChecked() and "on" or "off"; UpdatePRBAndHighlight() end end end
    if prb.showAbsorbCB then prb.showAbsorbCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      p.prbDmgAbsorb = s:GetChecked() and "bar" or "off"
      UpdatePRBAndHighlight()
      if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end
    end end
    if prb.absorbStripesCB then prb.absorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbAbsorbStripes = s:GetChecked() and true or false; UpdatePRBAndHighlight() end end end
    if prb.healPredCB then prb.healPredCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbHealPred = s:GetChecked() and "on" or "off"; UpdatePRBAndHighlight() end end end
    if prb.overAbsorbBarCB then prb.overAbsorbBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbOverAbsorbBar = s:GetChecked(); UpdatePRBAndHighlight() end end end
    if prb.healthTextDD then prb.healthTextDD.onSelect = function(v) local p = GetProfile(); if p then p.prbHealthTextMode = v; UpdatePRBAndHighlight() end end end
    if prb.healthTextScaleSlider then prb.healthTextScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.prbHealthTextScale = r; UpdatePRBAndHighlight() end end) end
    if prb.healthTextYSlider then prb.healthTextYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbHealthTextY = r; UpdatePRBAndHighlight() end end) end
    if prb.useClassColorCB then prb.useClassColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbUseClassColor = s:GetChecked(); local uc = s:GetChecked(); if prb.healthColorBtn then prb.healthColorBtn:SetEnabled(not uc); prb.healthColorBtn:SetAlpha(uc and 0.5 or 1) end; if prb.healthColorSwatch then prb.healthColorSwatch:SetAlpha(uc and 0.5 or 1) end; UpdatePRBAndHighlight() end end end
    if prb.lowHealthColorCB then prb.lowHealthColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbUseLowHealthColor = s:GetChecked(); local en = s:GetChecked(); if prb.lowHealthColorBtn then prb.lowHealthColorBtn:SetEnabled(en); prb.lowHealthColorBtn:SetAlpha(en and 1 or 0.5) end; if prb.lowHealthColorSwatch then prb.lowHealthColorSwatch:SetAlpha(en and 1 or 0.5) end; if prb.lowHealthThresholdSlider then prb.lowHealthThresholdSlider:SetEnabled(en); prb.lowHealthThresholdSlider:SetAlpha(en and 1 or 0.5) end; UpdatePRBAndHighlight() end end end
    if prb.lowHealthThresholdSlider then prb.lowHealthThresholdSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v / 5 + 0.5) * 5; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r .. "%"); local p = GetProfile(); if p then p.prbLowHealthThreshold = r; if addonTable.RebuildLowHealthCurve then addonTable.RebuildLowHealthCurve(r) end; UpdatePRBAndHighlight() end end) end
    if prb.powerHeightSlider then prb.powerHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbPowerHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.powerYOffsetSlider then prb.powerYOffsetSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbPowerYOffset = r; UpdatePRBAndHighlight() end end) end
    if prb.powerTextureDD then prb.powerTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.prbPowerTexture = v; UpdatePRBAndHighlight() end end end
    if prb.powerTextDD then prb.powerTextDD.onSelect = function(v) local p = GetProfile(); if p then p.prbPowerTextMode = v; UpdatePRBAndHighlight() end end end
    if prb.powerTextScaleSlider then prb.powerTextScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.prbPowerTextScale = r; UpdatePRBAndHighlight() end end) end
    if prb.powerTextYSlider then prb.powerTextYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbPowerTextY = r; UpdatePRBAndHighlight() end end) end
    if prb.usePowerTypeColorCB then prb.usePowerTypeColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbUsePowerTypeColor = s:GetChecked(); local up = s:GetChecked(); if prb.powerColorBtn then prb.powerColorBtn:SetEnabled(not up); prb.powerColorBtn:SetAlpha(up and 0.5 or 1) end; if prb.powerColorSwatch then prb.powerColorSwatch:SetAlpha(up and 0.5 or 1) end; UpdatePRBAndHighlight() end end end
    if prb.lowPowerColorCB then prb.lowPowerColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbUseLowPowerColor = s:GetChecked(); local en = s:GetChecked(); if prb.lowPowerColorBtn then prb.lowPowerColorBtn:SetEnabled(en); prb.lowPowerColorBtn:SetAlpha(en and 1 or 0.5) end; if prb.lowPowerColorSwatch then prb.lowPowerColorSwatch:SetAlpha(en and 1 or 0.5) end; if prb.lowPowerThresholdSlider then prb.lowPowerThresholdSlider:SetEnabled(en); prb.lowPowerThresholdSlider:SetAlpha(en and 1 or 0.5) end; UpdatePRBAndHighlight() end end end
    if prb.lowPowerThresholdSlider then prb.lowPowerThresholdSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v / 5 + 0.5) * 5; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r .. "%"); local p = GetProfile(); if p then p.prbLowPowerThreshold = r; if addonTable.RebuildLowPowerCurve then addonTable.RebuildLowPowerCurve(r) end; UpdatePRBAndHighlight() end end) end
    if prb.clampBarsCB then prb.clampBarsCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbClampBars = s:GetChecked(); UpdatePRBAndHighlight() end end end
    if prb.showManaBarCB then prb.showManaBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowManaBar = s:GetChecked(); UpdatePRBAndHighlight() end end end
    if prb.manaHeightSlider then prb.manaHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbManaHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.manaYOffsetSlider then prb.manaYOffsetSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbManaYOffset = r; UpdatePRBAndHighlight() end end) end
    if prb.manaTextureDD then prb.manaTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.prbManaTexture = v; UpdatePRBAndHighlight() end end end
    if prb.manaTextDD then prb.manaTextDD.onSelect = function(v) local p = GetProfile(); if p then p.prbManaTextMode = v; UpdatePRBAndHighlight() end end end
    if prb.manaTextScaleSlider then prb.manaTextScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.prbManaTextScale = r; UpdatePRBAndHighlight() end end) end
    if prb.manaTextYSlider then prb.manaTextYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbManaTextY = r; UpdatePRBAndHighlight() end end) end
    if prb.showClassPowerCB then prb.showClassPowerCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowClassPower = s:GetChecked(); UpdatePRBAndHighlight(); if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end end end
    if prb.classPowerHeightSlider then prb.classPowerHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbClassPowerHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.classPowerYSlider then prb.classPowerYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.prbClassPowerY = r; UpdatePRBAndHighlight() end end) end
    local function SetupColorBtn(btn, swatch, rKey, gKey, bKey)
      if btn then btn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p[rKey] or 1, p[gKey] or 1, p[bKey] or 1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p[rKey], p[gKey], p[bKey] = nR, nG, nB; swatch:SetBackdropColor(nR, nG, nB, 1); UpdatePRB() end
        local function OnCancel(prev) p[rKey], p[gKey], p[bKey] = prev.r, prev.g, prev.b; swatch:SetBackdropColor(prev.r, prev.g, prev.b, 1); UpdatePRB() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end) end
    end
    SetupColorBtn(prb.healthColorBtn, prb.healthColorSwatch, "prbHealthColorR", "prbHealthColorG", "prbHealthColorB")
    SetupColorBtn(prb.lowHealthColorBtn, prb.lowHealthColorSwatch, "prbLowHealthColorR", "prbLowHealthColorG", "prbLowHealthColorB")
    SetupColorBtn(prb.healthTextColorBtn, prb.healthTextColorSwatch, "prbHealthTextColorR", "prbHealthTextColorG", "prbHealthTextColorB")
    SetupColorBtn(prb.powerColorBtn, prb.powerColorSwatch, "prbPowerColorR", "prbPowerColorG", "prbPowerColorB")
    SetupColorBtn(prb.lowPowerColorBtn, prb.lowPowerColorSwatch, "prbLowPowerColorR", "prbLowPowerColorG", "prbLowPowerColorB")
    SetupColorBtn(prb.powerTextColorBtn, prb.powerTextColorSwatch, "prbPowerTextColorR", "prbPowerTextColorG", "prbPowerTextColorB")
    SetupColorBtn(prb.manaColorBtn, prb.manaColorSwatch, "prbManaColorR", "prbManaColorG", "prbManaColorB")
    SetupColorBtn(prb.manaTextColorBtn, prb.manaTextColorSwatch, "prbManaTextColorR", "prbManaTextColorG", "prbManaTextColorB")
    SetupColorBtn(prb.classPowerColorBtn, prb.classPowerColorSwatch, "prbClassPowerColorR", "prbClassPowerColorG", "prbClassPowerColorB")
  end
  if addonTable.castbarCB then
    addonTable.castbarCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        local _, needsReload = SetModuleEnabled("castbars", s:GetChecked())
        if not IsModuleEnabled("castbars") then
          s:SetChecked(false)
          if addonTable.StopCastbarPreview then addonTable.StopCastbarPreview() end
          if addonTable.StopFocusCastbarPreview then addonTable.StopFocusCastbarPreview() end
          if addonTable.StopTargetCastbarPreview then addonTable.StopTargetCastbarPreview() end
          if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
          SyncModuleControlsState()
          if needsReload then
            ShowReloadPrompt("Castbars module state changed. Reload UI now?", "Reload", "Later")
          end
          return
        end
        local wasEnabled = p.useCastbar
        p.useCastbar = s:GetChecked()
        if s:GetChecked() and not wasEnabled then
          if p.useFocusCastbar == nil then p.useFocusCastbar = true end
          if p.useTargetCastbar == nil then p.useTargetCastbar = true end
        end
        SyncModuleControlsState()
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          if addonTable.SetBlizzardCastbarVisibility then
            addonTable.SetBlizzardCastbarVisibility(false)
          end
          C_Timer.After(0.1, function()
            if addonTable.LoadCastbarValues then addonTable.LoadCastbarValues() end
          end)
          if not wasEnabled then
            ShowReloadPrompt("Enabling the custom castbar requires a reload for full effect.", "Reload Now", "Later")
          end
        else
          if addonTable.StopCastbarTicker then addonTable.StopCastbarTicker() end
          if addonTable.StopCastbarPreview then addonTable.StopCastbarPreview() end
          if wasEnabled then
            ShowReloadPrompt("Reload UI recommended to properly restore the default castbar.\n\nThis ensures compatibility with other castbar addons.", "Reload Now", "Later")
          end
        end
        if s:GetChecked() and IsModuleEnabled("castbars") then
          ShowModuleActivatedMessage("Castbars")
        end
        if needsReload then
          ShowReloadPrompt("Castbars module state changed. Reload UI now?", "Reload", "Later")
        end
      end
    end
  end
  if addonTable.focusCastbarCB then
    addonTable.focusCastbarCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        if not IsModuleEnabled("castbars") then s:SetChecked(false); return end
        p.useFocusCastbar = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          if addonTable.SetBlizzardFocusCastbarVisibility then addonTable.SetBlizzardFocusCastbarVisibility(false) end
          if addonTable.SetupFocusCastbarEvents then addonTable.SetupFocusCastbarEvents() end
          C_Timer.After(0.1, function()
            if addonTable.LoadFocusCastbarValues then addonTable.LoadFocusCastbarValues() end
          end)
        else
          if addonTable.StopFocusCastbarTicker then addonTable.StopFocusCastbarTicker() end
          if addonTable.StopFocusCastbarPreview then addonTable.StopFocusCastbarPreview() end
          if addonTable.SetBlizzardFocusCastbarVisibility then addonTable.SetBlizzardFocusCastbarVisibility(true) end
        end
      end
    end
  end
  if addonTable.targetCastbarCB then
    addonTable.targetCastbarCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        if not IsModuleEnabled("castbars") then s:SetChecked(false); return end
        p.useTargetCastbar = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          if addonTable.SetBlizzardTargetCastbarVisibility then addonTable.SetBlizzardTargetCastbarVisibility(false) end
          if addonTable.SetupTargetCastbarEvents then addonTable.SetupTargetCastbarEvents() end
          C_Timer.After(0.1, function()
            if addonTable.LoadTargetCastbarValues then addonTable.LoadTargetCastbarValues() end
          end)
        else
          if addonTable.StopTargetCastbarTicker then addonTable.StopTargetCastbarTicker() end
          if addonTable.StopTargetCastbarPreview then addonTable.StopTargetCastbarPreview() end
          if addonTable.SetBlizzardTargetCastbarVisibility then addonTable.SetBlizzardTargetCastbarVisibility(true) end
        end
      end
    end
  end
  if addonTable.playerDebuffsCB then
    addonTable.playerDebuffsCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        local _, needsReload = SetModuleEnabled("debuffs", s:GetChecked())
        if not IsModuleEnabled("debuffs") then
          s:SetChecked(false)
          if addonTable.RestorePlayerDebuffs then addonTable.RestorePlayerDebuffs() end
          SyncModuleControlsState()
          if needsReload then
            ShowReloadPrompt("Debuffs module state changed. Reload UI now?", "Reload", "Later")
          end
          return
        end
        p.enablePlayerDebuffs = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          C_Timer.After(0.1, function()
            if addonTable.LoadPlayerDebuffsValues then addonTable.LoadPlayerDebuffsValues() end
            if addonTable.ApplyPlayerDebuffsSkinning then addonTable.ApplyPlayerDebuffsSkinning() end
          end)
        else
          if addonTable.RestorePlayerDebuffs then addonTable.RestorePlayerDebuffs() end
        end
        if s:GetChecked() and IsModuleEnabled("debuffs") then
          ShowModuleActivatedMessage("Debuffs")
        end
        if needsReload then
          ShowReloadPrompt("Debuffs module state changed. Reload UI now?", "Reload", "Later")
        end
      end
    end
  end
  if addonTable.qolModuleCB then
    addonTable.qolModuleCB.customOnClick = function(s)
      local _, needsReload = SetModuleEnabled("qol", s:GetChecked())
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
      if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      if not IsModuleEnabled("qol") then
        if addonTable.StopNoTargetAlertPreview then addonTable.StopNoTargetAlertPreview() end
        if addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end
        if addonTable.StopSkyridingPreview then addonTable.StopSkyridingPreview() end
        if addonTable.StopLowHealthWarningPreview then addonTable.StopLowHealthWarningPreview() end
        if addonTable.ResetAllPreviewHighlights then addonTable.ResetAllPreviewHighlights() end
      end
      SyncModuleControlsState()
      if s:GetChecked() and IsModuleEnabled("qol") then
        ShowModuleActivatedMessage("QoL")
      end
      if needsReload then
        ShowReloadPrompt("QOL module state changed. Reload UI now?", "Reload", "Later")
      end
    end
  end
  if addonTable.unitFrameCustomizationCB then
    addonTable.unitFrameCustomizationCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        local _, needsReload = SetModuleEnabled("unitframes", s:GetChecked())
        if not IsModuleEnabled("unitframes") then
          s:SetChecked(false)
          if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
          if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
          SyncModuleControlsState()
          if needsReload then
            ShowReloadPrompt("Unit Frames module state changed. Reload UI now?", "Reload", "Later")
          end
          return
        end
        p.enableUnitFrameCustomization = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if s:GetChecked() and IsModuleEnabled("unitframes") then
          ShowModuleActivatedMessage("Unit Frames")
        end
        if needsReload then
          ShowReloadPrompt("Unit Frames module state changed. Reload UI now?", "Reload", "Later")
        else
          ShowReloadPrompt("Unit Frame Customization changed. A UI reload is recommended.", "Reload", "Later")
        end
      end
    end
  end
  local cbar = addonTable.castbar
  if cbar then
    local function UpdateCastbar()
      if addonTable.UpdateCastbar then C_Timer.After(0, addonTable.UpdateCastbar) end
    end
    local function num(v, d) return tonumber(v) or d end
    local function UpdateCenteredState()
      local p = GetProfile()
      local isCentered = p and p.castbarCentered
      if cbar.xSlider then
        cbar.xSlider:SetEnabled(not isCentered)
        if cbar.xSlider.label then
          cbar.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1)
        end
        if isCentered then
          cbar.xSlider:SetValue(0)
          cbar.xSlider.valueText:SetText("0")
        end
      end
    end
    local function UpdateAutoWidthState()
      local p = GetProfile()
      local isAuto = p and (p.castbarAutoWidthSource or "off") ~= "off"
      if cbar.widthSlider then
        cbar.widthSlider:SetEnabled(not isAuto)
        if cbar.widthSlider.label then
          cbar.widthSlider.label:SetTextColor(isAuto and 0.5 or 1, isAuto and 0.5 or 1, isAuto and 0.5 or 1)
        end
      end
    end
    local function LoadCastbarValues()
      local p = GetProfile(); if not p then return end
      if cbar.centeredCB then cbar.centeredCB:SetChecked(p.castbarCentered == true) end
      if cbar.autoWidthDD then cbar.autoWidthDD:SetValue(p.castbarAutoWidthSource or "off") end
      if cbar.widthSlider then cbar.widthSlider:SetValue(num(p.castbarWidth, 250)); cbar.widthSlider.valueText:SetText(math.floor(num(p.castbarWidth, 250))) end
      if cbar.heightSlider then cbar.heightSlider:SetValue(num(p.castbarHeight, 20)); cbar.heightSlider.valueText:SetText(math.floor(num(p.castbarHeight, 20))) end
      if cbar.xSlider then cbar.xSlider:SetValue(num(p.castbarX, 0)); cbar.xSlider.valueText:SetText(math.floor(num(p.castbarX, 0))) end
      if cbar.ySlider then local yVal = num(p.castbarY, -250); cbar.ySlider:SetValue(yVal); cbar.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if cbar.bgAlphaSlider then cbar.bgAlphaSlider:SetValue(num(p.castbarBgAlpha, 70)); cbar.bgAlphaSlider.valueText:SetText(math.floor(num(p.castbarBgAlpha, 70))) end
      if cbar.bgColorSwatch then cbar.bgColorSwatch:SetBackdropColor(p.castbarBgColorR or 0.1, p.castbarBgColorG or 0.1, p.castbarBgColorB or 0.1, 1) end
      if cbar.borderSlider then cbar.borderSlider:SetValue(num(p.castbarBorderSize, 1)); cbar.borderSlider.valueText:SetText(math.floor(num(p.castbarBorderSize, 1))) end
      if cbar.textureDD then cbar.textureDD:SetValue(p.castbarTexture or "solid") end
      if cbar.useClassColorCB then cbar.useClassColorCB:SetChecked(p.castbarUseClassColor ~= false) end
      local useClassColor = p.castbarUseClassColor ~= false
      if cbar.barColorBtn then cbar.barColorBtn:SetEnabled(not useClassColor); cbar.barColorBtn:SetAlpha(useClassColor and 0.5 or 1) end
      if cbar.barColorSwatch then cbar.barColorSwatch:SetBackdropColor(p.castbarColorR or 1, p.castbarColorG or 0.7, p.castbarColorB or 0, 1); cbar.barColorSwatch:SetAlpha(useClassColor and 0.5 or 1) end
      if cbar.showIconCB then cbar.showIconCB:SetChecked(p.castbarShowIcon ~= false) end
      if cbar.showSpellNameCB then cbar.showSpellNameCB:SetChecked(p.castbarShowSpellName ~= false) end
      if cbar.showTimeCB then cbar.showTimeCB:SetChecked(p.castbarShowTime ~= false) end
      if cbar.showTicksCB then cbar.showTicksCB:SetChecked(p.castbarShowTicks ~= false) end
      if cbar.spellNameScaleSlider then cbar.spellNameScaleSlider:SetValue(num(p.castbarSpellNameScale, 1)); cbar.spellNameScaleSlider.valueText:SetText(string.format("%.1f", num(p.castbarSpellNameScale, 1))) end
      if cbar.timeScaleSlider then cbar.timeScaleSlider:SetValue(num(p.castbarTimeScale, 1)); cbar.timeScaleSlider.valueText:SetText(string.format("%.1f", num(p.castbarTimeScale, 1))) end
      if cbar.spellNameXSlider then cbar.spellNameXSlider:SetValue(num(p.castbarSpellNameXOffset, 0)); cbar.spellNameXSlider.valueText:SetText(math.floor(num(p.castbarSpellNameXOffset, 0))) end
      if cbar.spellNameYSlider then cbar.spellNameYSlider:SetValue(num(p.castbarSpellNameYOffset, 0)); cbar.spellNameYSlider.valueText:SetText(math.floor(num(p.castbarSpellNameYOffset, 0))) end
      if cbar.timeXSlider then cbar.timeXSlider:SetValue(num(p.castbarTimeXOffset, 0)); cbar.timeXSlider.valueText:SetText(math.floor(num(p.castbarTimeXOffset, 0))) end
      if cbar.timeYSlider then cbar.timeYSlider:SetValue(num(p.castbarTimeYOffset, 0)); cbar.timeYSlider.valueText:SetText(math.floor(num(p.castbarTimeYOffset, 0))) end
      if cbar.timePrecisionDD then cbar.timePrecisionDD:SetValue(p.castbarTimePrecision or "1") end
      if cbar.timeDirectionDD then cbar.timeDirectionDD:SetValue(p.castbarTimeDirection or "remaining") end
      if cbar.textColorSwatch then cbar.textColorSwatch:SetBackdropColor(p.castbarTextColorR or 1, p.castbarTextColorG or 1, p.castbarTextColorB or 1, 1) end
      UpdateCenteredState()
      UpdateAutoWidthState()
    end
    addonTable.LoadCastbarValues = LoadCastbarValues
    C_Timer.After(0.3, LoadCastbarValues)
    addonTable.UpdateCastbarSliders = function(x, y)
      if cbar.xSlider then cbar.xSlider:SetValue(x); cbar.xSlider.valueText:SetText(math.floor(x)) end
      if cbar.ySlider then cbar.ySlider:SetValue(y); cbar.ySlider.valueText:SetText(math.floor(y)) end
    end
    if cbar.autoWidthDD then
      cbar.autoWidthDD.onSelect = function(v)
        local p = GetProfile()
        if p then
          p.castbarAutoWidthSource = v
          UpdateAutoWidthState()
          UpdateCastbar()
        end
      end
    end
    if cbar.centeredCB then
      cbar.centeredCB.customOnClick = function(s)
        local p = GetProfile()
        if p then
          p.castbarCentered = s:GetChecked()
          if p.castbarCentered then
            p.castbarX = 0
          end
          UpdateCenteredState()
          UpdateCastbar()
        end
      end
    end
    if cbar.previewOnBtn then
      cbar.previewOnBtn:SetScript("OnClick", function()
        if addonTable.ShowCastbarPreview then
          addonTable.ShowCastbarPreview()
        end
        SetButtonHighlighted(cbar.previewOnBtn, true)
      end)
    end
    if cbar.previewOffBtn then
      cbar.previewOffBtn:SetScript("OnClick", function()
        if addonTable.StopCastbarPreview then
          addonTable.StopCastbarPreview()
        end
        SetButtonHighlighted(cbar.previewOnBtn, false)
      end)
    end
    if cbar.widthSlider then
      cbar.widthSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarWidth = r; UpdateCastbar() end
      end)
    end
    if cbar.heightSlider then
      cbar.heightSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarHeight = r; UpdateCastbar() end
      end)
    end
    if cbar.xSlider then
      cbar.xSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        if not s.valueText:HasFocus() then s.valueText:SetText(r) end
        local p = GetProfile(); if p then p.castbarX = r; UpdateCastbar() end
      end)
    end
    if cbar.ySlider then
      cbar.ySlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v * 2 + 0.5) / 2
        s._updating = true; s:SetValue(r); s._updating = false
        if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end
        local p = GetProfile(); if p then p.castbarY = r; UpdateCastbar() end
      end)
    end
    if cbar.bgAlphaSlider then
      cbar.bgAlphaSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarBgAlpha = r; UpdateCastbar() end
      end)
    end
    if cbar.bgColorBtn then
      cbar.bgColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.castbarBgColorR or 0.1, p.castbarBgColorG or 0.1, p.castbarBgColorB or 0.1
        local a = (p.castbarBgAlpha or 80) / 100
        local function OnChange()
          local nR, nG, nB = ColorPickerFrame:GetColorRGB()
          local nA = ColorPickerFrame:GetColorAlpha() or 1
          p.castbarBgColorR, p.castbarBgColorG, p.castbarBgColorB = nR, nG, nB
          p.castbarBgAlpha = math.floor(nA * 100)
          cbar.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1)
          if cbar.bgAlphaSlider then cbar.bgAlphaSlider:SetValue(p.castbarBgAlpha); cbar.bgAlphaSlider.valueText:SetText(p.castbarBgAlpha) end
          UpdateCastbar()
        end
        local function OnCancel(prev)
          p.castbarBgColorR, p.castbarBgColorG, p.castbarBgColorB = prev.r, prev.g, prev.b
          p.castbarBgAlpha = math.floor(a * 100)
          cbar.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
          if cbar.bgAlphaSlider then cbar.bgAlphaSlider:SetValue(p.castbarBgAlpha); cbar.bgAlphaSlider.valueText:SetText(p.castbarBgAlpha) end
          UpdateCastbar()
        end
        ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnChange, opacityFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if cbar.borderSlider then
      cbar.borderSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarBorderSize = r; UpdateCastbar() end
      end)
    end
    if cbar.textureDD then
      cbar.textureDD.onSelect = function(v)
        local p = GetProfile(); if p then p.castbarTexture = v; UpdateCastbar() end
      end
    end
    if cbar.useClassColorCB then
      cbar.useClassColorCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarUseClassColor = s:GetChecked(); local uc = s:GetChecked(); if cbar.barColorBtn then cbar.barColorBtn:SetEnabled(not uc); cbar.barColorBtn:SetAlpha(uc and 0.5 or 1) end; if cbar.barColorSwatch then cbar.barColorSwatch:SetAlpha(uc and 0.5 or 1) end; UpdateCastbar() end
      end
    end
    if cbar.barColorBtn then
      cbar.barColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.castbarColorR or 1, p.castbarColorG or 0.7, p.castbarColorB or 0
        local function OnChange()
          local nR, nG, nB = ColorPickerFrame:GetColorRGB()
          p.castbarColorR, p.castbarColorG, p.castbarColorB = nR, nG, nB
          cbar.barColorSwatch:SetBackdropColor(nR, nG, nB, 1)
          UpdateCastbar()
        end
        local function OnCancel(prev)
          p.castbarColorR, p.castbarColorG, p.castbarColorB = prev.r, prev.g, prev.b
          cbar.barColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
          UpdateCastbar()
        end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if cbar.showIconCB then
      cbar.showIconCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowIcon = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.showSpellNameCB then
      cbar.showSpellNameCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowSpellName = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.showTimeCB then
      cbar.showTimeCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowTime = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.showTicksCB then
      cbar.showTicksCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowTicks = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.spellNameScaleSlider then
      cbar.spellNameScaleSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v * 10 + 0.5) / 10
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(string.format("%.1f", r))
        local p = GetProfile(); if p then p.castbarSpellNameScale = r; UpdateCastbar() end
      end)
    end
    if cbar.timeScaleSlider then
      cbar.timeScaleSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v * 10 + 0.5) / 10
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(string.format("%.1f", r))
        local p = GetProfile(); if p then p.castbarTimeScale = r; UpdateCastbar() end
      end)
    end
    if cbar.spellNameXSlider then
      cbar.spellNameXSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarSpellNameXOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.spellNameYSlider then
      cbar.spellNameYSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarSpellNameYOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.timeXSlider then
      cbar.timeXSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarTimeXOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.timeYSlider then
      cbar.timeYSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarTimeYOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.timePrecisionDD then
      cbar.timePrecisionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.castbarTimePrecision = v; UpdateCastbar() end
      end
    end
    if cbar.timeDirectionDD then
      cbar.timeDirectionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.castbarTimeDirection = v; UpdateCastbar() end
      end
    end
    if cbar.textColorBtn then
      cbar.textColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.castbarTextColorR or 1, p.castbarTextColorG or 1, p.castbarTextColorB or 1
        local function OnChange()
          local nR, nG, nB = ColorPickerFrame:GetColorRGB()
          p.castbarTextColorR, p.castbarTextColorG, p.castbarTextColorB = nR, nG, nB
          cbar.textColorSwatch:SetBackdropColor(nR, nG, nB, 1)
          UpdateCastbar()
        end
        local function OnCancel(prev)
          p.castbarTextColorR, p.castbarTextColorG, p.castbarTextColorB = prev.r, prev.g, prev.b
          cbar.textColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
          UpdateCastbar()
        end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
  end
  local fcbar = addonTable.focusCastbar
  if fcbar then
    local function UpdateFocusCastbar()
      if addonTable.UpdateFocusCastbar then C_Timer.After(0, addonTable.UpdateFocusCastbar) end
    end
    local function num(v, d) return tonumber(v) or d end
    local function UpdateCenteredState()
      local p = GetProfile()
      local isCentered = p and p.focusCastbarCentered
      if fcbar.xSlider then
        fcbar.xSlider:SetEnabled(not isCentered)
        if fcbar.xSlider.label then
          fcbar.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1)
        end
        if isCentered then
          fcbar.xSlider:SetValue(0)
          fcbar.xSlider.valueText:SetText("0")
        end
      end
    end
    local function LoadFocusCastbarValues()
      local p = GetProfile(); if not p then return end
      if fcbar.centeredCB then fcbar.centeredCB:SetChecked(p.focusCastbarCentered == true) end
      if fcbar.widthSlider then fcbar.widthSlider:SetValue(num(p.focusCastbarWidth, 250)); fcbar.widthSlider.valueText:SetText(math.floor(num(p.focusCastbarWidth, 250))) end
      if fcbar.heightSlider then fcbar.heightSlider:SetValue(num(p.focusCastbarHeight, 20)); fcbar.heightSlider.valueText:SetText(math.floor(num(p.focusCastbarHeight, 20))) end
      if fcbar.xSlider then fcbar.xSlider:SetValue(num(p.focusCastbarX, 0)); fcbar.xSlider.valueText:SetText(math.floor(num(p.focusCastbarX, 0))) end
      if fcbar.ySlider then local yVal = num(p.focusCastbarY, -210); fcbar.ySlider:SetValue(yVal); fcbar.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if fcbar.bgAlphaSlider then fcbar.bgAlphaSlider:SetValue(num(p.focusCastbarBgAlpha, 70)); fcbar.bgAlphaSlider.valueText:SetText(math.floor(num(p.focusCastbarBgAlpha, 70))) end
      if fcbar.bgColorSwatch then fcbar.bgColorSwatch:SetBackdropColor(p.focusCastbarBgColorR or 0.1, p.focusCastbarBgColorG or 0.1, p.focusCastbarBgColorB or 0.1, 1) end
      if fcbar.borderSlider then fcbar.borderSlider:SetValue(num(p.focusCastbarBorderSize, 1)); fcbar.borderSlider.valueText:SetText(math.floor(num(p.focusCastbarBorderSize, 1))) end
      if fcbar.textureDD then fcbar.textureDD:SetValue(p.focusCastbarTexture or "solid") end
      if fcbar.barColorBtn then fcbar.barColorBtn:SetEnabled(true); fcbar.barColorBtn:SetAlpha(1) end
      if fcbar.barColorSwatch then fcbar.barColorSwatch:SetBackdropColor(p.focusCastbarColorR or 1, p.focusCastbarColorG or 0.7, p.focusCastbarColorB or 0, 1); fcbar.barColorSwatch:SetAlpha(1) end
      if fcbar.showIconCB then fcbar.showIconCB:SetChecked(p.focusCastbarShowIcon ~= false) end
      if fcbar.showSpellNameCB then fcbar.showSpellNameCB:SetChecked(p.focusCastbarShowSpellName ~= false) end
      if fcbar.showTimeCB then fcbar.showTimeCB:SetChecked(p.focusCastbarShowTime ~= false) end
      if fcbar.showTicksCB then fcbar.showTicksCB:SetChecked(p.focusCastbarShowTicks ~= false) end
      if fcbar.spellNameScaleSlider then fcbar.spellNameScaleSlider:SetValue(num(p.focusCastbarSpellNameScale, 1)); fcbar.spellNameScaleSlider.valueText:SetText(string.format("%.1f", num(p.focusCastbarSpellNameScale, 1))) end
      if fcbar.timeScaleSlider then fcbar.timeScaleSlider:SetValue(num(p.focusCastbarTimeScale, 1)); fcbar.timeScaleSlider.valueText:SetText(string.format("%.1f", num(p.focusCastbarTimeScale, 1))) end
      if fcbar.spellNameXSlider then fcbar.spellNameXSlider:SetValue(num(p.focusCastbarSpellNameXOffset, 0)); fcbar.spellNameXSlider.valueText:SetText(math.floor(num(p.focusCastbarSpellNameXOffset, 0))) end
      if fcbar.spellNameYSlider then fcbar.spellNameYSlider:SetValue(num(p.focusCastbarSpellNameYOffset, 0)); fcbar.spellNameYSlider.valueText:SetText(math.floor(num(p.focusCastbarSpellNameYOffset, 0))) end
      if fcbar.timeXSlider then fcbar.timeXSlider:SetValue(num(p.focusCastbarTimeXOffset, 0)); fcbar.timeXSlider.valueText:SetText(math.floor(num(p.focusCastbarTimeXOffset, 0))) end
      if fcbar.timeYSlider then fcbar.timeYSlider:SetValue(num(p.focusCastbarTimeYOffset, 0)); fcbar.timeYSlider.valueText:SetText(math.floor(num(p.focusCastbarTimeYOffset, 0))) end
      if fcbar.timePrecisionDD then fcbar.timePrecisionDD:SetValue(p.focusCastbarTimePrecision or "1") end
      if fcbar.timeDirectionDD then fcbar.timeDirectionDD:SetValue(p.focusCastbarTimeDirection or "remaining") end
      if fcbar.textColorSwatch then fcbar.textColorSwatch:SetBackdropColor(p.focusCastbarTextColorR or 1, p.focusCastbarTextColorG or 1, p.focusCastbarTextColorB or 1, 1) end
      UpdateCenteredState()
    end
    addonTable.LoadFocusCastbarValues = LoadFocusCastbarValues
    C_Timer.After(0.3, LoadFocusCastbarValues)
    addonTable.UpdateFocusCastbarSliders = function(x, y)
      if fcbar.xSlider then fcbar.xSlider:SetValue(x); fcbar.xSlider.valueText:SetText(math.floor(x)) end
      if fcbar.ySlider then fcbar.ySlider:SetValue(y); fcbar.ySlider.valueText:SetText(math.floor(y)) end
    end
    if fcbar.centeredCB then fcbar.centeredCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarCentered = s:GetChecked(); if p.focusCastbarCentered then p.focusCastbarX = 0 end; UpdateCenteredState(); UpdateFocusCastbar() end end end
    if fcbar.widthSlider then fcbar.widthSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarWidth = r; UpdateFocusCastbar() end end) end
    if fcbar.heightSlider then fcbar.heightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarHeight = r; UpdateFocusCastbar() end end) end
    if fcbar.xSlider then fcbar.xSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.focusCastbarX = r; UpdateFocusCastbar() end end) end
    if fcbar.ySlider then fcbar.ySlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 2 + 0.5) / 2; s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end; local p = GetProfile(); if p then p.focusCastbarY = r; UpdateFocusCastbar() end end) end
    if fcbar.bgAlphaSlider then fcbar.bgAlphaSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarBgAlpha = r; UpdateFocusCastbar() end end) end
    if fcbar.borderSlider then fcbar.borderSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarBorderSize = r; UpdateFocusCastbar() end end) end
    if fcbar.textureDD then fcbar.textureDD.onSelect = function(v) local p = GetProfile(); if p then p.focusCastbarTexture = v; UpdateFocusCastbar() end end end

    if fcbar.showIconCB then fcbar.showIconCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowIcon = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.showSpellNameCB then fcbar.showSpellNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowSpellName = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.showTimeCB then fcbar.showTimeCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowTime = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.showTicksCB then fcbar.showTicksCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowTicks = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.spellNameScaleSlider then fcbar.spellNameScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.focusCastbarSpellNameScale = r; UpdateFocusCastbar() end end) end
    if fcbar.timeScaleSlider then fcbar.timeScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.focusCastbarTimeScale = r; UpdateFocusCastbar() end end) end
    if fcbar.spellNameXSlider then fcbar.spellNameXSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarSpellNameXOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.spellNameYSlider then fcbar.spellNameYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarSpellNameYOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.timeXSlider then fcbar.timeXSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarTimeXOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.timeYSlider then fcbar.timeYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarTimeYOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.timePrecisionDD then fcbar.timePrecisionDD.onSelect = function(v) local p = GetProfile(); if p then p.focusCastbarTimePrecision = v; UpdateFocusCastbar() end end end
    if fcbar.timeDirectionDD then fcbar.timeDirectionDD.onSelect = function(v) local p = GetProfile(); if p then p.focusCastbarTimeDirection = v; UpdateFocusCastbar() end end end
    if fcbar.bgColorBtn then
      fcbar.bgColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.focusCastbarBgColorR or 0.1, p.focusCastbarBgColorG or 0.1, p.focusCastbarBgColorB or 0.1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.focusCastbarBgColorR, p.focusCastbarBgColorG, p.focusCastbarBgColorB = nR, nG, nB; if fcbar.bgColorSwatch then fcbar.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateFocusCastbar() end
        local function OnCancel(prev) p.focusCastbarBgColorR, p.focusCastbarBgColorG, p.focusCastbarBgColorB = prev.r, prev.g, prev.b; if fcbar.bgColorSwatch then fcbar.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateFocusCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if fcbar.barColorBtn then
      fcbar.barColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.focusCastbarColorR or 1, p.focusCastbarColorG or 0.7, p.focusCastbarColorB or 0
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.focusCastbarColorR, p.focusCastbarColorG, p.focusCastbarColorB = nR, nG, nB; if fcbar.barColorSwatch then fcbar.barColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateFocusCastbar() end
        local function OnCancel(prev) p.focusCastbarColorR, p.focusCastbarColorG, p.focusCastbarColorB = prev.r, prev.g, prev.b; if fcbar.barColorSwatch then fcbar.barColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateFocusCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if fcbar.textColorBtn then
      fcbar.textColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.focusCastbarTextColorR or 1, p.focusCastbarTextColorG or 1, p.focusCastbarTextColorB or 1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.focusCastbarTextColorR, p.focusCastbarTextColorG, p.focusCastbarTextColorB = nR, nG, nB; if fcbar.textColorSwatch then fcbar.textColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateFocusCastbar() end
        local function OnCancel(prev) p.focusCastbarTextColorR, p.focusCastbarTextColorG, p.focusCastbarTextColorB = prev.r, prev.g, prev.b; if fcbar.textColorSwatch then fcbar.textColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateFocusCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
  end
  local tcbar = addonTable.targetCastbar
  if tcbar then
    local function UpdateTargetCastbar()
      if addonTable.UpdateTargetCastbar then C_Timer.After(0, addonTable.UpdateTargetCastbar) end
    end
    local function num(v, d) return tonumber(v) or d end
    local function UpdateTCCenteredState()
      local p = GetProfile()
      local isCentered = p and p.targetCastbarCentered
      if tcbar.xSlider then
        tcbar.xSlider:SetEnabled(not isCentered)
        if tcbar.xSlider.label then
          tcbar.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1)
        end
        if isCentered then
          tcbar.xSlider:SetValue(0)
          tcbar.xSlider.valueText:SetText("0")
        end
      end
    end
    local function LoadTargetCastbarValues()
      local p = GetProfile(); if not p then return end
      if tcbar.centeredCB then tcbar.centeredCB:SetChecked(p.targetCastbarCentered == true) end
      if tcbar.widthSlider then tcbar.widthSlider:SetValue(num(p.targetCastbarWidth, 250)); tcbar.widthSlider.valueText:SetText(math.floor(num(p.targetCastbarWidth, 250))) end
      if tcbar.heightSlider then tcbar.heightSlider:SetValue(num(p.targetCastbarHeight, 20)); tcbar.heightSlider.valueText:SetText(math.floor(num(p.targetCastbarHeight, 20))) end
      if tcbar.xSlider then tcbar.xSlider:SetValue(num(p.targetCastbarX, 0)); tcbar.xSlider.valueText:SetText(math.floor(num(p.targetCastbarX, 0))) end
      if tcbar.ySlider then local yVal = num(p.targetCastbarY, -250); tcbar.ySlider:SetValue(yVal); tcbar.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if tcbar.bgAlphaSlider then tcbar.bgAlphaSlider:SetValue(num(p.targetCastbarBgAlpha, 70)); tcbar.bgAlphaSlider.valueText:SetText(math.floor(num(p.targetCastbarBgAlpha, 70))) end
      if tcbar.bgColorSwatch then tcbar.bgColorSwatch:SetBackdropColor(p.targetCastbarBgColorR or 0.1, p.targetCastbarBgColorG or 0.1, p.targetCastbarBgColorB or 0.1, 1) end
      if tcbar.borderSlider then tcbar.borderSlider:SetValue(num(p.targetCastbarBorderSize, 1)); tcbar.borderSlider.valueText:SetText(math.floor(num(p.targetCastbarBorderSize, 1))) end
      if tcbar.textureDD then tcbar.textureDD:SetValue(p.targetCastbarTexture or "solid") end
      if tcbar.barColorBtn then tcbar.barColorBtn:SetEnabled(true); tcbar.barColorBtn:SetAlpha(1) end
      if tcbar.barColorSwatch then tcbar.barColorSwatch:SetBackdropColor(p.targetCastbarColorR or 1, p.targetCastbarColorG or 0.7, p.targetCastbarColorB or 0, 1); tcbar.barColorSwatch:SetAlpha(1) end
      if tcbar.showIconCB then tcbar.showIconCB:SetChecked(p.targetCastbarShowIcon ~= false) end
      if tcbar.showSpellNameCB then tcbar.showSpellNameCB:SetChecked(p.targetCastbarShowSpellName ~= false) end
      if tcbar.showTimeCB then tcbar.showTimeCB:SetChecked(p.targetCastbarShowTime ~= false) end
      if tcbar.showTicksCB then tcbar.showTicksCB:SetChecked(p.targetCastbarShowTicks ~= false) end
      if tcbar.spellNameScaleSlider then tcbar.spellNameScaleSlider:SetValue(num(p.targetCastbarSpellNameScale, 1)); tcbar.spellNameScaleSlider.valueText:SetText(string.format("%.1f", num(p.targetCastbarSpellNameScale, 1))) end
      if tcbar.timeScaleSlider then tcbar.timeScaleSlider:SetValue(num(p.targetCastbarTimeScale, 1)); tcbar.timeScaleSlider.valueText:SetText(string.format("%.1f", num(p.targetCastbarTimeScale, 1))) end
      if tcbar.spellNameXSlider then tcbar.spellNameXSlider:SetValue(num(p.targetCastbarSpellNameXOffset, 0)); tcbar.spellNameXSlider.valueText:SetText(math.floor(num(p.targetCastbarSpellNameXOffset, 0))) end
      if tcbar.spellNameYSlider then tcbar.spellNameYSlider:SetValue(num(p.targetCastbarSpellNameYOffset, 0)); tcbar.spellNameYSlider.valueText:SetText(math.floor(num(p.targetCastbarSpellNameYOffset, 0))) end
      if tcbar.timeXSlider then tcbar.timeXSlider:SetValue(num(p.targetCastbarTimeXOffset, 0)); tcbar.timeXSlider.valueText:SetText(math.floor(num(p.targetCastbarTimeXOffset, 0))) end
      if tcbar.timeYSlider then tcbar.timeYSlider:SetValue(num(p.targetCastbarTimeYOffset, 0)); tcbar.timeYSlider.valueText:SetText(math.floor(num(p.targetCastbarTimeYOffset, 0))) end
      if tcbar.timePrecisionDD then tcbar.timePrecisionDD:SetValue(p.targetCastbarTimePrecision or "1") end
      if tcbar.timeDirectionDD then tcbar.timeDirectionDD:SetValue(p.targetCastbarTimeDirection or "remaining") end
      if tcbar.textColorSwatch then tcbar.textColorSwatch:SetBackdropColor(p.targetCastbarTextColorR or 1, p.targetCastbarTextColorG or 1, p.targetCastbarTextColorB or 1, 1) end
      UpdateTCCenteredState()
    end
    addonTable.LoadTargetCastbarValues = LoadTargetCastbarValues
    C_Timer.After(0.3, LoadTargetCastbarValues)
    addonTable.UpdateTargetCastbarSliders = function(x, y)
      if tcbar.xSlider then tcbar.xSlider:SetValue(x); tcbar.xSlider.valueText:SetText(math.floor(x)) end
      if tcbar.ySlider then tcbar.ySlider:SetValue(y); tcbar.ySlider.valueText:SetText(math.floor(y)) end
    end
    if tcbar.centeredCB then tcbar.centeredCB.customOnClick = function(s) local p = GetProfile(); if p then p.targetCastbarCentered = s:GetChecked(); if p.targetCastbarCentered then p.targetCastbarX = 0 end; UpdateTCCenteredState(); UpdateTargetCastbar() end end end
    if tcbar.widthSlider then tcbar.widthSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarWidth = r; UpdateTargetCastbar() end end) end
    if tcbar.heightSlider then tcbar.heightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarHeight = r; UpdateTargetCastbar() end end) end
    if tcbar.xSlider then tcbar.xSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.targetCastbarX = r; UpdateTargetCastbar() end end) end
    if tcbar.ySlider then tcbar.ySlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 2 + 0.5) / 2; s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end; local p = GetProfile(); if p then p.targetCastbarY = r; UpdateTargetCastbar() end end) end
    if tcbar.bgAlphaSlider then tcbar.bgAlphaSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarBgAlpha = r; UpdateTargetCastbar() end end) end
    if tcbar.borderSlider then tcbar.borderSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarBorderSize = r; UpdateTargetCastbar() end end) end
    if tcbar.textureDD then tcbar.textureDD.onSelect = function(v) local p = GetProfile(); if p then p.targetCastbarTexture = v; UpdateTargetCastbar() end end end

    if tcbar.showIconCB then tcbar.showIconCB.customOnClick = function(s) local p = GetProfile(); if p then p.targetCastbarShowIcon = s:GetChecked(); UpdateTargetCastbar() end end end
    if tcbar.showSpellNameCB then tcbar.showSpellNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.targetCastbarShowSpellName = s:GetChecked(); UpdateTargetCastbar() end end end
    if tcbar.showTimeCB then tcbar.showTimeCB.customOnClick = function(s) local p = GetProfile(); if p then p.targetCastbarShowTime = s:GetChecked(); UpdateTargetCastbar() end end end
    if tcbar.showTicksCB then tcbar.showTicksCB.customOnClick = function(s) local p = GetProfile(); if p then p.targetCastbarShowTicks = s:GetChecked(); UpdateTargetCastbar() end end end
    if tcbar.spellNameScaleSlider then tcbar.spellNameScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.targetCastbarSpellNameScale = r; UpdateTargetCastbar() end end) end
    if tcbar.timeScaleSlider then tcbar.timeScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.targetCastbarTimeScale = r; UpdateTargetCastbar() end end) end
    if tcbar.spellNameXSlider then tcbar.spellNameXSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarSpellNameXOffset = r; UpdateTargetCastbar() end end) end
    if tcbar.spellNameYSlider then tcbar.spellNameYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarSpellNameYOffset = r; UpdateTargetCastbar() end end) end
    if tcbar.timeXSlider then tcbar.timeXSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarTimeXOffset = r; UpdateTargetCastbar() end end) end
    if tcbar.timeYSlider then tcbar.timeYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.targetCastbarTimeYOffset = r; UpdateTargetCastbar() end end) end
    if tcbar.timePrecisionDD then tcbar.timePrecisionDD.onSelect = function(v) local p = GetProfile(); if p then p.targetCastbarTimePrecision = v; UpdateTargetCastbar() end end end
    if tcbar.timeDirectionDD then tcbar.timeDirectionDD.onSelect = function(v) local p = GetProfile(); if p then p.targetCastbarTimeDirection = v; UpdateTargetCastbar() end end end
    if tcbar.bgColorBtn then
      tcbar.bgColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.targetCastbarBgColorR or 0.1, p.targetCastbarBgColorG or 0.1, p.targetCastbarBgColorB or 0.1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.targetCastbarBgColorR, p.targetCastbarBgColorG, p.targetCastbarBgColorB = nR, nG, nB; if tcbar.bgColorSwatch then tcbar.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateTargetCastbar() end
        local function OnCancel(prev) p.targetCastbarBgColorR, p.targetCastbarBgColorG, p.targetCastbarBgColorB = prev.r, prev.g, prev.b; if tcbar.bgColorSwatch then tcbar.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateTargetCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if tcbar.barColorBtn then
      tcbar.barColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.targetCastbarColorR or 1, p.targetCastbarColorG or 0.7, p.targetCastbarColorB or 0
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.targetCastbarColorR, p.targetCastbarColorG, p.targetCastbarColorB = nR, nG, nB; if tcbar.barColorSwatch then tcbar.barColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateTargetCastbar() end
        local function OnCancel(prev) p.targetCastbarColorR, p.targetCastbarColorG, p.targetCastbarColorB = prev.r, prev.g, prev.b; if tcbar.barColorSwatch then tcbar.barColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateTargetCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if tcbar.textColorBtn then
      tcbar.textColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.targetCastbarTextColorR or 1, p.targetCastbarTextColorG or 1, p.targetCastbarTextColorB or 1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.targetCastbarTextColorR, p.targetCastbarTextColorG, p.targetCastbarTextColorB = nR, nG, nB; if tcbar.textColorSwatch then tcbar.textColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateTargetCastbar() end
        local function OnCancel(prev) p.targetCastbarTextColorR, p.targetCastbarTextColorG, p.targetCastbarTextColorB = prev.r, prev.g, prev.b; if tcbar.textColorSwatch then tcbar.textColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateTargetCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
  end
  local db = addonTable.debuffs
  if db then
    local function UpdateDebuffs()
      if addonTable.State and addonTable.State.debuffPreviewMode then
        if addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
      else
        if addonTable.ApplyPlayerDebuffsSkinning then C_Timer.After(0, addonTable.ApplyPlayerDebuffsSkinning) end
      end
      if addonTable.activeTab and addonTable.activeTab() == 10 and addonTable.HighlightCustomBar then
        addonTable.HighlightCustomBar(10)
      end
    end
    local function num(v, d) return tonumber(v) or d end
    local function LoadPlayerDebuffsValues()
      local p = GetProfile(); if not p then return end
      if db.sizeSlider then db.sizeSlider:SetValue(num(p.playerDebuffSize, 32)); db.sizeSlider.valueText:SetText(math.floor(num(p.playerDebuffSize, 32))) end
      if db.spacingSlider then db.spacingSlider:SetValue(num(p.playerDebuffSpacing, 2)); db.spacingSlider.valueText:SetText(math.floor(num(p.playerDebuffSpacing, 2))) end
      if db.xSlider then db.xSlider:SetValue(num(p.playerDebuffX, 0)); db.xSlider.valueText:SetText(math.floor(num(p.playerDebuffX, 0))) end
      if db.ySlider then db.ySlider:SetValue(num(p.playerDebuffY, 0)); db.ySlider.valueText:SetText(math.floor(num(p.playerDebuffY, 0))) end
      if db.iconsPerRowSlider then db.iconsPerRowSlider:SetValue(num(p.playerDebuffIconsPerRow, 10)); db.iconsPerRowSlider.valueText:SetText(math.floor(num(p.playerDebuffIconsPerRow, 10))) end
      if db.sortDirectionDD then db.sortDirectionDD:SetValue(p.playerDebuffSortDirection or "right") end
      if db.growDirectionDD then db.growDirectionDD:SetValue(p.playerDebuffRowGrowDirection or "down") end
      if db.borderSizeSlider then db.borderSizeSlider:SetValue(num(p.playerDebuffBorderSize, 1)); db.borderSizeSlider.valueText:SetText(math.floor(num(p.playerDebuffBorderSize, 1))) end
    end
    addonTable.LoadPlayerDebuffsValues = LoadPlayerDebuffsValues
    C_Timer.After(0.3, LoadPlayerDebuffsValues)
    if db.sizeSlider then
      db.sizeSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffSize = r; UpdateDebuffs() end
      end)
    end
    if db.spacingSlider then
      db.spacingSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffSpacing = r; UpdateDebuffs() end
      end)
    end
    if db.xSlider then
      db.xSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffX = r; UpdateDebuffs() end
      end)
    end
    if db.ySlider then
      db.ySlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffY = r; UpdateDebuffs() end
      end)
    end
    if db.iconsPerRowSlider then
      db.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffIconsPerRow = r; UpdateDebuffs() end
      end)
    end
    if db.sortDirectionDD then
      db.sortDirectionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.playerDebuffSortDirection = v; UpdateDebuffs() end
      end
    end
    if db.growDirectionDD then
      db.growDirectionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.playerDebuffRowGrowDirection = v; UpdateDebuffs() end
      end
    end
    if db.borderSizeSlider then
      db.borderSizeSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffBorderSize = r; UpdateDebuffs() end
      end)
    end
    if db.previewOnBtn then
      db.previewOnBtn:SetScript("OnClick", function()
        if addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
        SetButtonHighlighted(db.previewOnBtn, true)
      end)
    end
    if db.previewOffBtn then
      db.previewOffBtn:SetScript("OnClick", function()
        if addonTable.StopDebuffPreview then addonTable.StopDebuffPreview() end
        SetButtonHighlighted(db.previewOnBtn, false)
      end)
    end
  end
end
C_Timer.After(0.1, InitHandlers)
