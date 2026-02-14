--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_buff.lua
-- Buff tracking via Blizzard CDM and live aura overlay
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
local addonTable = CCM
local GetTime = GetTime
local wipe = wipe
local pcall = pcall
local type = type

local State = addonTable.State
local CdmAuraOverlayCache = { bySpellID = {}, bySpellName = {}, knownBuffSpellIDs = {}, pureBuffSpellIDs = {}, lastScan = 0, notBuff = {} }
local AuraOverlayScanChildren = {}
local BlizzBuffSuppressionState = setmetatable({}, { __mode = "k" })

local function IsSafePublicNumber(value)
  if type(value) ~= "number" then return false end
  if issecretvalue and issecretvalue(value) then return false end
  return true
end

local function IsSafePublicString(value)
  if type(value) ~= "string" then return false end
  if issecretvalue and issecretvalue(value) then return false end
  if value == "" then return false end
  return true
end

local function ShouldUseLiveBuffTrackingForProfile(profile)
  if type(profile) ~= "table" then return false end
  if profile.trackBuffs ~= false then return true end
  if profile.customBarTrackBuffs ~= false then return true end
  if profile.customBar2TrackBuffs ~= false then return true end
  if profile.customBar3TrackBuffs ~= false then return true end
  if profile.customBar4TrackBuffs ~= false then return true end
  if profile.customBar5TrackBuffs ~= false then return true end
  return false
end

local function ParseSafePublicDurationValue(value)
  if IsSafePublicNumber(value) then
    return value
  end
  if not IsSafePublicString(value) then
    return nil
  end
  local okNum, n = pcall(tonumber, value)
  if okNum and type(n) == "number" then
    return n
  end
  return nil
end

local function ParsePublicStackDisplayValue(value)
  if IsSafePublicNumber(value) then
    return value
  end
  if IsSafePublicString(value) then
    local okNum, n = pcall(tonumber, value)
    if okNum and type(n) == "number" then
      return n
    end
  end
  return nil
end

--------------------------------------------------------------------------------
-- Suppression
--------------------------------------------------------------------------------

local function AddSuppressedBuffSpell(bySpellID, bySpellName, spellID)
  if type(spellID) ~= "number" or spellID <= 0 then return end
  if issecretvalue and issecretvalue(spellID) then return end
  bySpellID[spellID] = true

  local ResolveTrackedSpellID = addonTable.ResolveTrackedSpellID
  local resolved = ResolveTrackedSpellID and ResolveTrackedSpellID(spellID) or nil
  if IsSafePublicNumber(resolved) and resolved > 0 then
    bySpellID[resolved] = true
  end

  local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
  local spellName = spellInfo and spellInfo.name
  if IsSafePublicString(spellName) then
    bySpellName[spellName] = true
  end

  if IsSafePublicNumber(resolved) and resolved > 0 and resolved ~= spellID then
    local resolvedInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(resolved)
    local resolvedName = resolvedInfo and resolvedInfo.name
    if IsSafePublicString(resolvedName) then
      bySpellName[resolvedName] = true
    end
  end
end

local function BuildSuppressedBuffSpellLookups(profile)
  local bySpellID, bySpellName = {}, {}
  local function AddFromIconList(iconList)
    if type(iconList) ~= "table" then return end
    for i = 1, #iconList do
      local icon = iconList[i]
      if icon and icon.isItem ~= true then
        local spellID = icon.actualID or icon.spellID
        AddSuppressedBuffSpell(bySpellID, bySpellName, spellID)
        if IsSafePublicNumber(icon.spellID) and icon.spellID ~= spellID then
          AddSuppressedBuffSpell(bySpellID, bySpellName, icon.spellID)
        end
      end
    end
  end
  if type(profile) ~= "table" then
    return bySpellID, bySpellName
  end
  if profile.trackBuffs ~= false then
    AddFromIconList(State.cursorIcons)
  end
  if profile.customBarTrackBuffs ~= false then
    AddFromIconList(State.customBar1Icons)
  end
  if profile.customBar2TrackBuffs ~= false then
    AddFromIconList(State.customBar2Icons)
  end
  if profile.customBar3TrackBuffs ~= false then
    AddFromIconList(State.customBar3Icons)
  end
  if profile.customBar4TrackBuffs ~= false then
    AddFromIconList(State.customBar4Icons)
  end
  if profile.customBar5TrackBuffs ~= false then
    AddFromIconList(State.customBar5Icons)
  end
  return bySpellID, bySpellName
end

local function MatchesSuppressedBuffSpellID(bySpellID, value)
  if not bySpellID then return false end
  if not IsSafePublicNumber(value) then return false end
  return bySpellID[value] == true
end

local function MatchesSuppressedBuffSpellName(bySpellName, value)
  if not bySpellName then return false end
  if not IsSafePublicString(value) then return false end
  return bySpellName[value] == true
end

local function ShouldSuppressBlizzBuffViewerIcon(child, info, bySpellID, bySpellName)
  if not child then return false end
  if MatchesSuppressedBuffSpellID(bySpellID, child.spellID) then return true end
  if MatchesSuppressedBuffSpellID(bySpellID, child.actualID) then return true end

  local childInfo = child.cooldownInfo
  if type(childInfo) == "table" then
    if MatchesSuppressedBuffSpellID(bySpellID, childInfo.spellID) then return true end
    if MatchesSuppressedBuffSpellID(bySpellID, childInfo.overrideSpellID) then return true end
    if MatchesSuppressedBuffSpellName(bySpellName, childInfo.name) then return true end
    if MatchesSuppressedBuffSpellName(bySpellName, childInfo.spellName) then return true end
    if type(childInfo.linkedSpellIDs) == "table" then
      for i = 1, #childInfo.linkedSpellIDs do
        if MatchesSuppressedBuffSpellID(bySpellID, childInfo.linkedSpellIDs[i]) then
          return true
        end
      end
    end
  end

  if type(info) == "table" then
    if MatchesSuppressedBuffSpellID(bySpellID, info.spellID) then return true end
    if MatchesSuppressedBuffSpellID(bySpellID, info.overrideSpellID) then return true end
    if MatchesSuppressedBuffSpellName(bySpellName, info.name) then return true end
    if MatchesSuppressedBuffSpellName(bySpellName, info.spellName) then return true end
    if type(info.linkedSpellIDs) == "table" then
      for i = 1, #info.linkedSpellIDs do
        if MatchesSuppressedBuffSpellID(bySpellID, info.linkedSpellIDs[i]) then
          return true
        end
      end
    end
  end
  return false
end

local function SetBlizzBuffViewerIconSuppressed(icon, suppress)
  if not icon then return end
  if icon.GetObjectType and icon:GetObjectType() ~= "Frame" then return end
  local state = BlizzBuffSuppressionState[icon]

  if suppress then
    if not state then
      local okScale, oldScale = pcall(icon.GetScale, icon)
      local okAlpha, oldAlpha = pcall(icon.GetAlpha, icon)
      local okWidth, oldWidth = pcall(icon.GetWidth, icon)
      local okHeight, oldHeight = pcall(icon.GetHeight, icon)
      state = {
        scale = (okScale and type(oldScale) == "number") and oldScale or 1,
        alpha = (okAlpha and type(oldAlpha) == "number") and oldAlpha or 1,
        width = (okWidth and type(oldWidth) == "number") and oldWidth or nil,
        height = (okHeight and type(oldHeight) == "number") and oldHeight or nil,
      }
      BlizzBuffSuppressionState[icon] = state
    end
    pcall(icon.SetScale, icon, 1)
    pcall(icon.SetAlpha, icon, 0)
    if icon.SetSize then
      pcall(icon.SetSize, icon, 0.001, 0.001)
    else
      if icon.SetWidth then pcall(icon.SetWidth, icon, 0.001) end
      if icon.SetHeight then pcall(icon.SetHeight, icon, 0.001) end
    end
    pcall(icon.Show, icon)
    return
  end

  if state then
    local restoreScale = type(state.scale) == "number" and state.scale or 1
    local restoreAlpha = type(state.alpha) == "number" and state.alpha or 1
    local restoreWidth = state.width
    local restoreHeight = state.height
    pcall(icon.SetScale, icon, restoreScale)
    pcall(icon.SetAlpha, icon, restoreAlpha)
    if type(restoreWidth) == "number" and type(restoreHeight) == "number" then
      if icon.SetSize then
        pcall(icon.SetSize, icon, restoreWidth, restoreHeight)
      else
        if icon.SetWidth then pcall(icon.SetWidth, icon, restoreWidth) end
        if icon.SetHeight then pcall(icon.SetHeight, icon, restoreHeight) end
      end
    end
    BlizzBuffSuppressionState[icon] = nil
  end
end

--------------------------------------------------------------------------------
-- CDM Aura Cache
--------------------------------------------------------------------------------

local function CollectChildren(frame, out)
  local count = (frame and frame.GetNumChildren and frame:GetNumChildren()) or 0
  for i = 1, count do
    out[i] = select(i, frame:GetChildren())
  end
  for i = count + 1, #out do
    out[i] = nil
  end
  return count
end

local function AddCdmAuraOverlayCacheName(spellName, entry)
  if entry == nil then return end
  if type(spellName) ~= "string" then return end
  if issecretvalue and issecretvalue(spellName) then return end
  if spellName == "" then return end
  CdmAuraOverlayCache.bySpellName[spellName] = entry
end

local function AddCdmAuraOverlayCacheEntry(spellID, auraInstanceID, sourceFrame)
  if type(spellID) ~= "number" then return end
  if issecretvalue and issecretvalue(spellID) then return end
  if auraInstanceID == nil then return end
  local entry = { auraInstanceID = auraInstanceID, frame = sourceFrame }
  CdmAuraOverlayCache.bySpellID[spellID] = entry
  local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
  local spellName = spellInfo and spellInfo.name
  AddCdmAuraOverlayCacheName(spellName, entry)
end

local function MarkKnownSpellInCache(knownBuffSpellIDs, id, ResolveTrackedSpellID)
  if not IsSafePublicNumber(id) or id <= 0 then return end
  knownBuffSpellIDs[id] = true
  if ResolveTrackedSpellID then
    local resolved = ResolveTrackedSpellID(id)
    if IsSafePublicNumber(resolved) and resolved > 0 then
      knownBuffSpellIDs[resolved] = true
    end
  end
end

local function ScanCdmAuraOverlayCache(now)
  wipe(CdmAuraOverlayCache.bySpellID)
  wipe(CdmAuraOverlayCache.bySpellName)
  wipe(CdmAuraOverlayCache.knownBuffSpellIDs)
  wipe(CdmAuraOverlayCache.notBuff)
  CdmAuraOverlayCache.lastScan = now or GetTime()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local suppressTrackedBuffIcons = profile and profile.hideTrackedBlizzBuffIcons ~= false and ShouldUseLiveBuffTrackingForProfile(profile) and profile.disableBlizzCDM ~= true
  local knownBuffSpellIDs = CdmAuraOverlayCache.knownBuffSpellIDs
  local ResolveTrackedSpellID = addonTable.ResolveTrackedSpellID
  local suppressBySpellID, suppressBySpellName
  if suppressTrackedBuffIcons then
    suppressBySpellID, suppressBySpellName = BuildSuppressedBuffSpellLookups(profile)
    if not next(suppressBySpellID) and not next(suppressBySpellName) then
      suppressTrackedBuffIcons = false
    end
  end
  local viewer = BuffIconCooldownViewer
  if viewer then
    local canSuppressViewer = suppressTrackedBuffIcons
    local childCount = CollectChildren(viewer, AuraOverlayScanChildren)
    for i = 1, childCount do
      local child = AuraOverlayScanChildren[i]
      local shouldSuppressChild = false
      local info = child and child.cooldownInfo
      if type(info) ~= "table" then
        local cooldownID = child and child.cooldownID
        local canQueryCooldown = false
        if type(cooldownID) == "number" and not (issecretvalue and issecretvalue(cooldownID)) then
          canQueryCooldown = cooldownID > 0
        end
        if canQueryCooldown and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
          local okInfo, fetched = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
          if okInfo and type(fetched) == "table" then
            info = fetched
          end
        end
      end
      if type(info) == "table" then
        MarkKnownSpellInCache(knownBuffSpellIDs, info.spellID, ResolveTrackedSpellID)
        MarkKnownSpellInCache(knownBuffSpellIDs, info.overrideSpellID, ResolveTrackedSpellID)
        if type(info.linkedSpellIDs) == "table" then
          for li = 1, #info.linkedSpellIDs do
            MarkKnownSpellInCache(knownBuffSpellIDs, info.linkedSpellIDs[li], ResolveTrackedSpellID)
          end
        end
      end
      MarkKnownSpellInCache(knownBuffSpellIDs, child and child.spellID, ResolveTrackedSpellID)
      MarkKnownSpellInCache(knownBuffSpellIDs, child and child.actualID, ResolveTrackedSpellID)
      local auraInstanceID = child and child.auraInstanceID
      if auraInstanceID ~= nil then
        if type(info) == "table" then
          AddCdmAuraOverlayCacheEntry(info.spellID, auraInstanceID, child)
          AddCdmAuraOverlayCacheEntry(info.overrideSpellID, auraInstanceID, child)
          if type(info.linkedSpellIDs) == "table" then
            for li = 1, #info.linkedSpellIDs do
              AddCdmAuraOverlayCacheEntry(info.linkedSpellIDs[li], auraInstanceID, child)
            end
          end
        end
        AddCdmAuraOverlayCacheEntry(child.spellID, auraInstanceID, child)
        AddCdmAuraOverlayCacheEntry(child.actualID, auraInstanceID, child)
        if canSuppressViewer then
          shouldSuppressChild = ShouldSuppressBlizzBuffViewerIcon(child, info, suppressBySpellID, suppressBySpellName)
        end
      end
      SetBlizzBuffViewerIconSuppressed(child, canSuppressViewer and shouldSuppressChild)
    end
  end
  wipe(CdmAuraOverlayCache.pureBuffSpellIDs)
  local spellCdDurations = State.spellCdDurations or {}
  local spellBaseCdDurations = State.spellBaseCdDurations or {}
  for spellID in pairs(knownBuffSpellIDs) do
    local hasRealCD = false
    local okBase, baseCd = pcall(GetSpellBaseCooldown, spellID)
    if okBase and type(baseCd) == "number" and baseCd > 1500 then
      hasRealCD = true
    end
    if not hasRealCD then
      local tracked = spellCdDurations[spellID]
      if type(tracked) == "number" and tracked > 1.5 then
        hasRealCD = true
      end
    end
    if not hasRealCD then
      local baseDur = spellBaseCdDurations[spellID]
      if type(baseDur) == "number" and baseDur > 1.5 then
        hasRealCD = true
      end
    end
    if not hasRealCD then
      local cdInfo = C_Spell.GetSpellCooldown(spellID)
      if cdInfo and cdInfo.duration then
        local okDur, isBig = pcall(function() return cdInfo.duration > 1.5 end)
        if okDur and isBig then
          hasRealCD = true
        end
      end
    end
    if not hasRealCD then
      CdmAuraOverlayCache.pureBuffSpellIDs[spellID] = true
    end
  end
end

--------------------------------------------------------------------------------
-- Cache Lookup
--------------------------------------------------------------------------------

local function GetCdmAuraOverlayEntryFromCache(spellID)
  if type(spellID) ~= "number" then return nil end
  if CdmAuraOverlayCache.notBuff[spellID] then return nil end
  local entry = CdmAuraOverlayCache.bySpellID[spellID]
  local ResolveTrackedSpellID = addonTable.ResolveTrackedSpellID
  if not entry and ResolveTrackedSpellID then
    local resolved = ResolveTrackedSpellID(spellID)
    if IsSafePublicNumber(resolved) and resolved ~= spellID then
      entry = CdmAuraOverlayCache.bySpellID[resolved]
    end
  end
  if not entry then
    local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name
    if IsSafePublicString(spellName) then
      entry = CdmAuraOverlayCache.bySpellName[spellName]
    end
  end
  if not entry then
    CdmAuraOverlayCache.notBuff[spellID] = true
  end
  return entry
end

local function GetCdmAuraOverlayEntry(spellID, now, forceRescanIfMissing)
  if type(spellID) ~= "number" then return nil end
  local scanNow = now or GetTime()
  local justScanned = false
  if scanNow - (CdmAuraOverlayCache.lastScan or 0) > 0.10 then
    ScanCdmAuraOverlayCache(scanNow)
    justScanned = true
  end
  local entry = GetCdmAuraOverlayEntryFromCache(spellID)
  if entry or not forceRescanIfMissing or justScanned then
    return entry
  end
  ScanCdmAuraOverlayCache(GetTime())
  return GetCdmAuraOverlayEntryFromCache(spellID)
end

--------------------------------------------------------------------------------
-- Duration Objects
--------------------------------------------------------------------------------

local function GetAuraOverlayDurationObjectFromInstance(unit, auraInstanceID)
  if not C_UnitAuras or not C_UnitAuras.GetAuraDuration then return nil end
  if auraInstanceID == nil then return nil end
  local okObj, durationObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
  if not okObj or not durationObj then return nil end
  return durationObj
end

local function GetDurationObjectFromCdmCacheEntry(entry)
  if entry == nil then return nil end
  if type(entry) == "number" then
    return GetAuraOverlayDurationObjectFromInstance("player", entry)
  end
  if type(entry) ~= "table" then return nil end
  local auraInstanceID = entry.auraInstanceID
  local frame = entry.frame
  if frame and frame.auraInstanceID ~= nil then
    auraInstanceID = frame.auraInstanceID
    entry.auraInstanceID = auraInstanceID
  end
  if auraInstanceID == nil then return nil end
  return GetAuraOverlayDurationObjectFromInstance("player", auraInstanceID)
end

local function ApplyAuraOverlayDurationObject(cooldownFrame, durationObj)
  if not cooldownFrame or not durationObj then return false end
  if cooldownFrame.SetDrawSwipe then
    pcall(cooldownFrame.SetDrawSwipe, cooldownFrame, true)
  end
  local setDurationObj = cooldownFrame.SetCooldownFromDurationObject
  if type(setDurationObj) ~= "function" then
    return false
  end
  local okSet = pcall(setDurationObj, cooldownFrame, durationObj, true)
  return okSet == true
end

--------------------------------------------------------------------------------
-- Stack Display
--------------------------------------------------------------------------------

local function ReadPublicStackValueFromFontString(fontString)
  if not fontString or type(fontString.GetText) ~= "function" then return nil end
  local okText, text = pcall(fontString.GetText, fontString)
  if not okText then return nil end
  return ParsePublicStackDisplayValue(text)
end

local function ReadRawStackValueFromFontString(fontString)
  if not fontString or type(fontString.GetText) ~= "function" then return nil end
  local okText, text = pcall(fontString.GetText, fontString)
  if not okText then return nil end
  return text
end

local function TryGetCdmAuraOverlayStackFromEntry(entry)
  if type(entry) ~= "table" then return nil, nil end

  local auraInstanceID = entry.auraInstanceID
  local frame = entry.frame
  if frame and frame.auraInstanceID ~= nil then
    auraInstanceID = frame.auraInstanceID
    entry.auraInstanceID = auraInstanceID
  end

  if type(frame) == "table" then
    local appFrame = frame.Applications
    local okAppVis, appVis = pcall(function() if appFrame and type(appFrame.IsShown) == "function" and appFrame:IsShown() then return true end return false end)
    if okAppVis and appVis == true then
      local stackText = appFrame.Applications
      local okStVis, stVis = pcall(function() if stackText and type(stackText.IsShown) == "function" and stackText:IsShown() then return true end return false end)
      if okStVis and stVis == true then
        local stackCount = ReadPublicStackValueFromFontString(stackText)
        if type(stackCount) == "number" and stackCount > 0 then
          return stackCount, nil
        end
        local rawStackText = ReadRawStackValueFromFontString(stackText)
        local rawType = type(rawStackText)
        if rawType == "string" then
          if issecretvalue and issecretvalue(rawStackText) then
            return nil, rawStackText
          end
          return nil, rawStackText
        elseif rawType == "number" then
          if IsSafePublicNumber(rawStackText) then
            return nil, rawStackText
          end
        end
      end
    end

    local chargeFrame = frame.ChargeCount
    local chargeText = chargeFrame and chargeFrame.Current
    local okChVis, chVis = pcall(function() if chargeText and type(chargeText.IsShown) == "function" and chargeText:IsShown() then return true end return false end)
    if okChVis and chVis == true then
      local stackCount = ReadPublicStackValueFromFontString(chargeText)
      if type(stackCount) == "number" and stackCount > 0 then
        return stackCount, nil
      end
      local rawChargeText = ReadRawStackValueFromFontString(chargeText)
      local rawType = type(rawChargeText)
      if rawType == "string" then
        if issecretvalue and issecretvalue(rawChargeText) then
          return nil, rawChargeText
        end
        return nil, rawChargeText
      elseif rawType == "number" then
        if IsSafePublicNumber(rawChargeText) then
          return nil, rawChargeText
        end
      end
    end

    local stackCount = ParsePublicStackDisplayValue(frame.cooldownChargesCount)
    if type(stackCount) == "number" and stackCount > 0 then
      return stackCount, nil
    end

    local chargeInfo = frame.cooldownChargesInfo
    if type(chargeInfo) == "table" then
      local stackCount = ParsePublicStackDisplayValue(chargeInfo.currentCharges)
      if type(stackCount) == "number" and stackCount > 0 then
        return stackCount, nil
      end
    end
  end

  return nil, nil
end

local function TryGetCdmAuraOverlayStackDisplay(spellID)
  local entry = GetCdmAuraOverlayEntry(spellID, GetTime(), true)
  return TryGetCdmAuraOverlayStackFromEntry(entry)
end

--------------------------------------------------------------------------------
-- Static Buff Duration Learning
--------------------------------------------------------------------------------

local function RememberSpellCastTimestamp(spellID, timestamp)
  if type(spellID) ~= "number" or spellID <= 0 then return end
  local castAt = ParseSafePublicDurationValue(timestamp)
  if type(castAt) ~= "number" then
    castAt = GetTime()
  end
  State.spellCastTimes[spellID] = castAt
  local ResolveTrackedSpellID = addonTable.ResolveTrackedSpellID
  if ResolveTrackedSpellID then
    local resolved = ResolveTrackedSpellID(spellID)
    if IsSafePublicNumber(resolved) and resolved > 0 then
      State.spellCastTimes[resolved] = castAt
    end
  end
end

local function RememberStaticBuffDurationSample(spellID, duration)
  if type(spellID) ~= "number" or spellID <= 0 then return nil end
  local sample = ParseSafePublicDurationValue(duration)
  if type(sample) ~= "number" then return nil end
  if sample <= 0 then return nil end
  if not State.spellStaticBuffDurations then
    State.spellStaticBuffDurations = {}
  end
  State.spellStaticBuffDurations[spellID] = sample
  local ResolveTrackedSpellID = addonTable.ResolveTrackedSpellID
  if ResolveTrackedSpellID then
    local resolved = ResolveTrackedSpellID(spellID)
    if IsSafePublicNumber(resolved) and resolved > 0 then
      State.spellStaticBuffDurations[resolved] = sample
    end
  end
  return sample
end

local function ReadStaticBuffDurationFromAuraData(spellID, auraData)
  if type(auraData) ~= "table" then return nil end
  local duration = ParseSafePublicDurationValue(auraData.duration) or ParseSafePublicDurationValue(auraData.totalDuration)
  if type(duration) ~= "number" or duration <= 0 then
    local expiration = ParseSafePublicDurationValue(auraData.expirationTime)
    local startTime = ParseSafePublicDurationValue(auraData.startTime)
    if type(expiration) == "number" and type(startTime) == "number" then
      local derived = expiration - startTime
      if derived > 0 then
        duration = derived
      end
    end
  end
  if type(duration) ~= "number" or duration <= 0 then
    return nil
  end
  local auraSpellID = ParseSafePublicDurationValue(auraData.spellId or auraData.spellID)
  if type(auraSpellID) == "number" and auraSpellID > 0 then
    RememberStaticBuffDurationSample(auraSpellID, duration)
  end
  return RememberStaticBuffDurationSample(spellID, duration)
end

local function RememberStaticBuffDurationFromAuraInstance(spellID, auraInstanceID)
  if type(spellID) ~= "number" or spellID <= 0 then return nil end
  if auraInstanceID == nil then return nil end
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByAuraInstanceID then return nil end
  local okAura, auraData = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", auraInstanceID)
  if not okAura or type(auraData) ~= "table" then return nil end
  return ReadStaticBuffDurationFromAuraData(spellID, auraData)
end

local function RememberStaticBuffDurationFromPlayerAura(spellID)
  if type(spellID) ~= "number" or spellID <= 0 then return nil end
  if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return nil end
  local okAura, auraData = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
  if not okAura or type(auraData) ~= "table" then return nil end
  return ReadStaticBuffDurationFromAuraData(spellID, auraData)
end

local function RememberStaticBuffDurationFromCdmEntry(spellID, entry)
  if type(spellID) ~= "number" or spellID <= 0 then return nil end
  if type(entry) == "number" then
    return RememberStaticBuffDurationFromAuraInstance(spellID, entry)
  end
  if type(entry) ~= "table" then
    return RememberStaticBuffDurationFromPlayerAura(spellID)
  end
  local auraInstanceID = entry.auraInstanceID
  local frame = entry.frame
  if frame and frame.auraInstanceID ~= nil then
    auraInstanceID = frame.auraInstanceID
    entry.auraInstanceID = auraInstanceID
  end
  local learned = RememberStaticBuffDurationFromAuraInstance(spellID, auraInstanceID)
  if learned then
    return learned
  end
  return RememberStaticBuffDurationFromPlayerAura(spellID)
end

--------------------------------------------------------------------------------
-- Static Overlay
--------------------------------------------------------------------------------

local function GetStaticBuffDurationSample(spellID, alternateSpellID)
  local cache = State.spellStaticBuffDurations or {}
  local function ReadCached(id)
    if type(id) ~= "number" or id <= 0 then return nil end
    local duration = cache[id]
    if type(duration) == "number" and duration > 0 then
      return duration
    end
    local hardcoded = addonTable.BuffDurationCache and addonTable.BuffDurationCache[id]
    if type(hardcoded) == "number" and hardcoded > 0 then
      return hardcoded
    end
    return nil
  end
  local duration = ReadCached(spellID)
  if not duration and type(alternateSpellID) == "number" then
    duration = ReadCached(alternateSpellID)
  end
  if not duration and type(spellID) == "number" then
    duration = RememberStaticBuffDurationFromCdmEntry(spellID, GetCdmAuraOverlayEntry(spellID, GetTime(), false))
  end
  if not duration and type(alternateSpellID) == "number" and alternateSpellID ~= spellID then
    duration = RememberStaticBuffDurationFromCdmEntry(alternateSpellID, GetCdmAuraOverlayEntry(alternateSpellID, GetTime(), false))
  end
  return duration
end

local function GetMostRecentSpellCastTimeForStatic(spellID, alternateSpellID)
  local latest = nil
  local ResolveTrackedSpellID = addonTable.ResolveTrackedSpellID
  local function Consider(id)
    if type(id) ~= "number" or id <= 0 then return end
    local castAt = State.spellCastTimes[id]
    if type(castAt) == "number" and (latest == nil or castAt > latest) then
      latest = castAt
    end
    if ResolveTrackedSpellID then
      local resolved = ResolveTrackedSpellID(id)
      if IsSafePublicNumber(resolved) and resolved > 0 and resolved ~= id then
        local resolvedCast = State.spellCastTimes[resolved]
        if type(resolvedCast) == "number" and (latest == nil or resolvedCast > latest) then
          latest = resolvedCast
        end
      end
    end
  end
  Consider(spellID)
  if type(alternateSpellID) == "number" then
    Consider(alternateSpellID)
  end
  return latest
end

local function TryApplyStaticAuraOverlayFromCast(cooldownFrame, spellID, alternateSpellID)
  if not cooldownFrame or type(spellID) ~= "number" or spellID <= 0 then return false end
  local duration = GetStaticBuffDurationSample(spellID, alternateSpellID)
  if type(duration) ~= "number" or duration <= 0 then return false end
  local castAt = GetMostRecentSpellCastTimeForStatic(spellID, alternateSpellID)
  if type(castAt) ~= "number" or castAt <= 0 then return false end
  local now = GetTime()
  if castAt > now then
    castAt = now
  end
  if (castAt + duration) <= now then
    return false
  end
  if cooldownFrame.SetDrawSwipe then
    pcall(cooldownFrame.SetDrawSwipe, cooldownFrame, true)
  end
  local okSet = pcall(cooldownFrame.SetCooldown, cooldownFrame, castAt, duration)
  return okSet == true
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

local function TryApplyLiveAuraOverlay(cooldownFrame, spellID)
  if not cooldownFrame or type(spellID) ~= "number" then return false end
  local entry = GetCdmAuraOverlayEntry(spellID, GetTime(), true)
  if entry then
    RememberStaticBuffDurationFromCdmEntry(spellID, entry)
  end
  local durationObj = GetDurationObjectFromCdmCacheEntry(entry)
  if durationObj and ApplyAuraOverlayDurationObject(cooldownFrame, durationObj) then
    return true
  end
  return false
end

local function TryApplyStaticAuraOverlay(cooldownFrame, spellID, alternateSpellID)
  if not cooldownFrame or type(spellID) ~= "number" or spellID <= 0 then return false end
  return TryApplyStaticAuraOverlayFromCast(cooldownFrame, spellID, alternateSpellID)
end

--------------------------------------------------------------------------------
-- Expose on addon table
--------------------------------------------------------------------------------

addonTable.TryApplyLiveAuraOverlay = TryApplyLiveAuraOverlay
addonTable.TryApplyStaticAuraOverlay = TryApplyStaticAuraOverlay
addonTable.ScanCdmAuraOverlayCache = ScanCdmAuraOverlayCache
addonTable.GetCdmKnownBuffSpellIDs = function() return CdmAuraOverlayCache.knownBuffSpellIDs end
addonTable.GetCdmPureBuffSpellIDs = function() return CdmAuraOverlayCache.pureBuffSpellIDs end
addonTable.IsSafePublicNumber = IsSafePublicNumber
addonTable.RememberSpellCastTimestamp = RememberSpellCastTimestamp
addonTable.TryGetCdmAuraOverlayStackDisplay = TryGetCdmAuraOverlayStackDisplay
addonTable.CollectChildren = CollectChildren
