--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_core.lua
-- Main addon logic: cooldown tracking, icon management, UI updates
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
local addonTable = CCM
local State = {
  openAfterCombat = false,
  guiIsOpen = false,
  iconsDirty = true,
  customBarsDirty = true,
  lastIconUpdate = 0,
  cursorIcons = {},
  customBar1Icons = {},
  customBar2Icons = {},
  customBar3Icons = {},
  customBar1Moving = false,
  customBar1Dragging = false,
  customBar2Moving = false,
  customBar2Dragging = false,
  customBar3Moving = false,
  customBar3Dragging = false,
  customBar4Icons = {},
  customBar4Moving = false,
  customBar4Dragging = false,
  customBar5Icons = {},
  customBar5Moving = false,
  customBar5Dragging = false,
  customBarVisibleIcons = {},
  customBar2VisibleIcons = {},
  customBar3VisibleIcons = {},
  customBar4VisibleIcons = {},
  customBar5VisibleIcons = {},
  gcdStartTime = 0,
  gcdDuration = 0,
  spellCdDurations = {},
  spellBaseCdDurations = {},
  spellCastTimes = {},
  spellStaticBuffDurations = {},
  prbDragging = false,
  prbTicker = nil,
  actionBar1Hidden = false,
  stanceBarHidden = false,
  petBarHidden = false,
  actionBar1Mouseover = false,
  actionButtonsHooked = false,
  actionBars2to8Hooked = {},
  stanceBarHooked = false,
  essentialBarActive = false,
  buffBarActive = false,
  buffBarVisibleIcons = {},
  lastBuffBarBorderSize = -1,
  buffBarIconScale = 1,
  buffBarCount = 0,
  buffBarIconWidth = 50,
  buffBarSpacing = 2,
  buffBarOriginalSetup = false,
  buffBarOriginalData = {},
  cachedBuffBarWidth = 0,
  essentialBarVisibleIcons = {},
  lastEssentialBarBorderSize = -1,
  essentialBarIconScale = 1,
  essentialBarCount = 0,
  essentialBarIconWidth = 50,
  essentialBarSpacing = 2,
  essentialBar = nil,
  essentialBarOriginalParent = nil,
  essentialBarOriginalPoint = nil,
  essentialBarOriginalSetup = false,
  essentialBarOriginalData = {},
  cachedEssentialBarWidth = 0,
  utilityBarVisibleIcons = {},
  lastUtilityBarBorderSize = -1,
  utilityBarIconScale = 1,
  utilityBarCount = 0,
  utilityBarIconWidth = 50,
  utilityBarSpacing = 2,
  standaloneSkinActive = false,
  standaloneBuffOriginals = {},
  standaloneEssentialOriginals = {},
  standaloneUtilityOriginals = {},
  standaloneNeedsSkinning = true,
  standaloneDirty = true,
  fadeInProgress = {},
  blizzBarPreviewFrames = {},
  blizzBarDragOverlays = {},
  blizzBarClickHandlersSetup = false,
  highlightFrames = {},
  lastRingTexturePath = nil,
  ringEnabled = false,
  ringCombatOnly = false,
  cachedUIScale = 1,
  lastScaleUpdate = 0,
  tickerProfile = nil,
  mouseCheckTicker = nil,
  lastBarUpdateTime = 0,
  barUpdateInterval = 0.05,
  lastCursorX = 0,
  lastCursorY = 0,
  cursorMoveThreshold = 0.5,
  minimapDragging = false,
  compactMinimapActive = false,
  compactMinimapPanelShown = false,
  compactMinimapButtons = {},
  compactMinimapProxyButtons = {},
  iconUpdatePending = false,
  customBarUpdatePending = false,
  standaloneAuraRelayoutPending = false,
  lastStandaloneUpdate = 0,
  lastStandaloneTick = 0,
  standaloneFastUntil = 0,
  mainTicker = nil,
  customBar1LayoutKey = nil,
  customBar2LayoutKey = nil,
  customBar3LayoutKey = nil,
  customBar4LayoutKey = nil,
  customBar5LayoutKey = nil,
  standaloneBuffLayoutKey = nil,
  standaloneEssentialLayoutKey = nil,
  standaloneUtilityLayoutKey = nil,
  standaloneEssentialWidth = 0,
  lastCustomBar1Update = 0,
  lastCustomBar2Update = 0,
  lastCustomBar3Update = 0,
  customBar1UpdateInterval = 0.08,
  customBar2UpdateInterval = 0.12,
  customBar3UpdateInterval = 0.12,
  lastCustomBar4Update = 0,
  lastCustomBar5Update = 0,
  customBar4UpdateInterval = 0.12,
  customBar5UpdateInterval = 0.12,
  customBar1HasActiveTimers = true,
  customBar2HasActiveTimers = true,
  customBar3HasActiveTimers = true,
  customBar4HasActiveTimers = true,
  customBar5HasActiveTimers = true,
  lastCustomBarDirtyMarkTime = 0,
  focusCastbarActive = false,
  focusCastbarTicker = nil,
  focusCastbarDragging = false,
  focusCastbarPreviewMode = false,
  focusCastbarLayoutKey = nil,
  focusCastbarTickKey = nil,
  targetCastbarActive = false,
  targetCastbarTicker = nil,
  targetCastbarDragging = false,
  targetCastbarPreviewMode = false,
  targetCastbarLayoutKey = nil,
  targetCastbarTickKey = nil,
  targetCastbarTickCache = nil,
  collapsingStarStacks = nil,
  combatStatusMessageToken = 0,
  combatStatusPreviewMode = false,
  combatStatusLastEntering = true,
}
addonTable.State = State
addonTable.UF_BIG_HB_TEXT_BASE = {
  player = { nameX = 36, nameY = -2, levelX = 0, levelY = -2 },
  target = { nameX = -4, nameY = 8, levelX = 2, levelY = -2 },
  focus = { nameX = 2, nameY = 8, levelX = 3, levelY = -2 },
}
State.tmpChildren = {}
State.tmpIconChildren = {}
State.tmpRegions = {}
State.tmpChildRegions = {}
addonTable.CollectChildren = function(frame, out)
  local count = (frame and frame.GetNumChildren and frame:GetNumChildren()) or 0
  for i = 1, count do
    out[i] = select(i, frame:GetChildren())
  end
  for i = count + 1, #out do
    out[i] = nil
  end
  return count
end
addonTable.CollectRegions = function(frame, out)
  local count = (frame and frame.GetNumRegions and frame:GetNumRegions()) or 0
  for i = 1, count do
    out[i] = select(i, frame:GetRegions())
  end
  for i = count + 1, #out do
    out[i] = nil
  end
  return count
end
addonTable.CLASS_POWER_CONFIG = {
  PALADIN = {default = {powerType = 9, segments = true}},
  ROGUE = {default = {powerType = 4, segments = true}},
  DRUID = {default = {powerType = 4, segments = true, requireForm = 1}},
  WARLOCK = {default = {powerType = 7, segments = true}},
  MONK = {default = {powerType = 12, segments = true}},
  EVOKER = {default = {powerType = 19, segments = true}},
  DEATHKNIGHT = {default = {powerType = 5, segments = true}},
  PRIEST = {[258] = {powerType = 13, continuous = true}},
  SHAMAN = {[262] = {powerType = 11, continuous = true}, [263] = {buffID = 344179, segments = true, maxStacks = 10}},
  MAGE = {[62] = {powerType = 16, segments = true}},
}
local function GetClassPowerConfig(ignoreFormRequirement)
  local _, playerClass = UnitClass("player")
  if not playerClass then return nil end
  local classConfig = addonTable.CLASS_POWER_CONFIG[playerClass]
  if not classConfig then return nil end
  if classConfig.default then
    local config = classConfig.default
    if config.requireForm and not ignoreFormRequirement then
      local form = GetShapeshiftFormID()
      if form ~= config.requireForm then return nil end
    end
    return config
  end
  local specIndex = GetSpecialization()
  if not specIndex then return nil end
  local specID = GetSpecializationInfo(specIndex)
  if not specID then return nil end
  return classConfig[specID]
end
addonTable.GetClassPowerConfig = GetClassPowerConfig
local GetGlobalFont
local IsClassPowerRedundant
IsClassPowerRedundant = function()
  local cpConfig = GetClassPowerConfig()
  if not cpConfig then return false end
  if cpConfig.buffID then return false end
  if cpConfig.continuous and cpConfig.powerType then
    return true
  end
  return false
end
local CCM_Curves = {}
local function InitCurves()
  if C_CurveUtil and C_CurveUtil.CreateCurve then
    CCM_Curves.Desaturation = C_CurveUtil.CreateCurve()
    CCM_Curves.Desaturation:SetType(Enum.LuaCurveType.Step)
    CCM_Curves.Desaturation:AddPoint(0.0, 0)
    CCM_Curves.Desaturation:AddPoint(0.001, 1)
    CCM_Curves.CdGradR = nil
    CCM_Curves.CdGradG = nil
    CCM_Curves.CdGradB = nil
    CCM_Curves.CdGradKey = nil
  end
end
local function GetChargeSpellDesaturation(spellID)
  if not CCM_Curves.Desaturation then return nil end
  if not C_Spell then return nil end
  local cooldown = C_Spell.GetSpellCooldown(spellID)
  if cooldown and cooldown.isOnGCD then return 0 end
  local cooldownDuration = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(spellID)
  if cooldownDuration and cooldownDuration.EvaluateRemainingPercent then
    local ok, result = pcall(cooldownDuration.EvaluateRemainingPercent, cooldownDuration, CCM_Curves.Desaturation)
    if ok and result then
      return result
    end
  end
  return 0
end
local ChargeSpellCache = {}
local BuffDurationCache = {}
addonTable.BuffDurationCache = BuffDurationCache
local ActiveBuffStart = {}
local function ResolveBuffDurations()
  wipe(BuffDurationCache)
  local seed = addonTable.BuffDurationSeed
  if not seed then return end
  for auraID, dur in pairs(seed) do
    BuffDurationCache[auraID] = dur
  end
  local overrides = addonTable.BuffTalentOverrides
  if not overrides then return end
  for auraID, talents in pairs(overrides) do
    for _, entry in ipairs(talents) do
      if C_SpellBook.IsSpellKnown(entry[1]) then
        BuffDurationCache[auraID] = (BuffDurationCache[auraID] or 0) + entry[2]
      end
    end
  end
end
local function GetActiveBuffOverlay(spellID)
  local duration = BuffDurationCache[spellID]
  if not duration or duration <= 0 then return nil, nil end
  local startTime = ActiveBuffStart[spellID]
  if not startTime then return nil, nil end
  if GetTime() >= startTime + duration then
    ActiveBuffStart[spellID] = nil
    return nil, nil
  end
  return startTime, duration
end
local function IsRealChargeSpell(charges, spellID)
  if not charges then
    if spellID then ChargeSpellCache[spellID] = false end
    return false
  end
  if charges.maxCharges == nil then
    if spellID then ChargeSpellCache[spellID] = false end
    return false
  end
  local inCombat = issecretvalue and issecretvalue(charges.maxCharges)
  if inCombat then
    if spellID and ChargeSpellCache[spellID] ~= nil then
      return ChargeSpellCache[spellID]
    end
    return false
  else
    local ok, result = pcall(function()
      return type(charges.maxCharges) == "number" and charges.maxCharges > 1
    end)
    local isChargeSpell = ok and result
    if spellID then
      ChargeSpellCache[spellID] = isChargeSpell
    end
    return isChargeSpell
  end
end
local function ScanSpellBookCharges()
  if not C_Spell or not C_Spell.GetSpellCharges then return end
  local function cacheSpell(id)
    if not id or type(id) ~= "number" or id <= 0 then return end
    if ChargeSpellCache[id] ~= nil then return end
    local charges = C_Spell.GetSpellCharges(id)
    if charges then
      IsRealChargeSpell(charges, id)
    end
  end
  local function cacheWithOverride(id)
    if not id or type(id) ~= "number" or id <= 0 then return end
    cacheSpell(id)
    local overrideID
    if FindSpellOverrideByID then
      local ok, oid = pcall(FindSpellOverrideByID, id)
      if ok and type(oid) == "number" and oid > 0 and oid ~= id then overrideID = oid end
    end
    if not overrideID and C_SpellBook and C_SpellBook.FindSpellOverrideByID then
      local ok, oid = pcall(C_SpellBook.FindSpellOverrideByID, id)
      if ok and type(oid) == "number" and oid > 0 and oid ~= id then overrideID = oid end
    end
    if overrideID then
      cacheSpell(overrideID)
      if ChargeSpellCache[id] == nil and ChargeSpellCache[overrideID] ~= nil then
        ChargeSpellCache[id] = ChargeSpellCache[overrideID]
      end
      if ChargeSpellCache[overrideID] == nil and ChargeSpellCache[id] ~= nil then
        ChargeSpellCache[overrideID] = ChargeSpellCache[id]
      end
    end
  end
  local spellBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  if C_SpellBook and spellBank then
    local scanned = false
    if C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo then
      local okLines, numLines = pcall(C_SpellBook.GetNumSpellBookSkillLines)
      if okLines and type(numLines) == "number" and numLines > 0 then
        scanned = true
        for lineIndex = 1, numLines do
          local okLine, skillLineInfo = pcall(C_SpellBook.GetSpellBookSkillLineInfo, lineIndex)
          if okLine and type(skillLineInfo) == "table" then
            local offset = type(skillLineInfo.itemIndexOffset) == "number" and skillLineInfo.itemIndexOffset or 0
            local count = type(skillLineInfo.numSpellBookItems) == "number" and skillLineInfo.numSpellBookItems or 0
            for i = 1, count do
              local slotIndex = offset + i
              local okItem, itemInfo = pcall(C_SpellBook.GetSpellBookItemInfo, slotIndex, spellBank)
              if okItem and type(itemInfo) == "table" then
                local spellID = itemInfo.spellID
                if type(spellID) == "number" and spellID > 0 then
                  cacheWithOverride(spellID)
                end
              end
            end
          end
        end
      end
    end
  end
  local cursorTrackedSpells = nil
  if addonTable.GetSpellList then
    cursorTrackedSpells = select(1, addonTable.GetSpellList())
  else
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    cursorTrackedSpells = profile and profile.trackedSpells or nil
  end
  if cursorTrackedSpells then
    for _, entryID in ipairs(cursorTrackedSpells) do
      if type(entryID) == "number" and entryID > 0 then
        cacheWithOverride(entryID)
      end
    end
  end
  if CooldownCursorManagerDB and CooldownCursorManagerDB.characterCustomBarSpells then
    local pName = UnitName and UnitName("player")
    local pRealm = GetRealmName and GetRealmName()
    local charKey = (pName and pRealm) and (pName .. "-" .. pRealm) or nil
    if charKey and CooldownCursorManagerDB.characterCustomBarSpells[charKey] then
      local specID = GetSpecialization and GetSpecialization() or 0
      local specSpells = CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID]
      if specSpells then
        for _, entryID in ipairs(specSpells) do
          if type(entryID) == "number" and entryID > 0 then
            cacheWithOverride(entryID)
          end
        end
      end
    end
  end
end
addonTable.ChargeSpellCache = ChargeSpellCache
local function GetSafeCurrentCharges(charges, spellID, cooldownFrame, originalSpellID)
  if not State.playerClassToken then
    State.playerClassToken = select(2, UnitClass("player"))
  end
  local playerClass = State.playerClassToken
  local isDemonHunter = playerClass == "DEMONHUNTER"
  local hasVoidMetaEmpowerBuff = false
  if isDemonHunter and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
    local okEmpAura, empAura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, 1217607)
    hasVoidMetaEmpowerBuff = okEmpAura and empAura ~= nil
  end
  local isVoidMetaEmpowered = (
    isDemonHunter and (spellID == 1217607 or spellID == 228260
    or (type(originalSpellID) == "number" and (originalSpellID == 1217607 or originalSpellID == 228260))
    or ((spellID == 1217605 or (type(originalSpellID) == "number" and originalSpellID == 1217605)) and hasVoidMetaEmpowerBuff)
  ))
  if isVoidMetaEmpowered and type(State.collapsingStarStacks) == "number" then
    return State.collapsingStarStacks
  end
  if isVoidMetaEmpowered and C_Spell and C_Spell.GetSpellCharges then
    local okProxy, proxyCharges = pcall(C_Spell.GetSpellCharges, 1227702)
    if okProxy and proxyCharges then
      local okProxyNum, proxyCurrent = pcall(tonumber, proxyCharges.currentCharges)
      local okProxyValid, proxyValid = pcall(function()
        return okProxyNum and type(proxyCurrent) == "number" and proxyCurrent >= 0
      end)
      if okProxyValid and proxyValid then
        return proxyCurrent
      end
    end
  end
  if isVoidMetaEmpowered and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    local function ReadAuraStack(aura)
      if not aura then return nil end
      local okApps, apps = pcall(tonumber, aura.applications)
      if okApps and type(apps) == "number" and apps > 0 then
        return apps
      end
      if aura.points then
        for i = 1, #aura.points do
          local okPoint, pointNum = pcall(tonumber, aura.points[i])
          if okPoint and type(pointNum) == "number" and pointNum > 0 then
            return pointNum
          end
        end
      end
      return nil
    end

    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
      if not aura then break end
      local okMatch, matchesVoidMetaStackAura = pcall(function()
        local auraSpellID = aura.spellId or aura.spellID
        if auraSpellID == 1227702 or auraSpellID == 1242173 then
          return true
        end
        local auraName = tostring(aura.name or "")
        if auraName == "Collapsing Star" then
          return true
        end
        return tonumber(aura.icon) == 7554199
      end)
      if okMatch and matchesVoidMetaStackAura then
        local stack = ReadAuraStack(aura)
        if type(stack) == "number" and stack > 0 then
          return stack
        end
      end
    end
    return 0
  end

  if charges then
    local maxSecret = issecretvalue and issecretvalue(charges.maxCharges)
    if maxSecret then
      local okCur, curCharges = pcall(tonumber, charges.currentCharges)
      if okCur and type(curCharges) == "number" then
        if spellID and ChargeSpellCache[spellID] then
          return curCharges
        end
      end
    else
      local okMax, maxC = pcall(tonumber, charges.maxCharges)
      if okMax and type(maxC) == "number" then
        local okCmp, isSingle = pcall(function() return maxC <= 1 end)
        if okCmp and isSingle then
          return nil
        end
      end
      local okNum, current = pcall(tonumber, charges.currentCharges)
      if okNum and type(current) == "number" then
        return current
      end
    end
  end

  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    if C_UnitAuras.GetPlayerAuraBySpellID then
      local candidates = {spellID}
      if type(originalSpellID) == "number" and originalSpellID ~= spellID then
        candidates[#candidates + 1] = originalSpellID
      end
      if isVoidMetaEmpowered then
        candidates[#candidates + 1] = 1227702
        candidates[#candidates + 1] = 1242173
      end
      for _, candidateID in ipairs(candidates) do
        if type(candidateID) == "number" then
          local okAura, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, candidateID)
          if okAura and aura then
            local okApps, apps = pcall(tonumber, aura.applications)
            local okAppsValid, appsValid = pcall(function() return okApps and type(apps) == "number" and apps > 0 end)
            if okAppsValid and appsValid then
              return apps
            end
          end
        end
      end
    end

    local spellName, spellIcon, originalName, originalIcon = nil, nil, nil, nil
    if C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(spellID)
      if info then
        spellName, spellIcon = info.name, info.iconID
      end
      if type(originalSpellID) == "number" and originalSpellID ~= spellID then
        local originalInfo = C_Spell.GetSpellInfo(originalSpellID)
        if originalInfo then
          originalName, originalIcon = originalInfo.name, originalInfo.iconID
        end
      end
    end
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
      if not aura then break end
      local auraSpellID = aura.spellId or aura.spellID
      local okMatch, isMatch = pcall(function()
        if not auraSpellID then return false end
        if auraSpellID == spellID then return true end
        return type(originalSpellID) == "number" and auraSpellID == originalSpellID
      end)
      if (not okMatch) or (not isMatch) then
        local okHeuristic, heuristicMatch = pcall(function()
          local auraName = tostring(aura.name or "")
          local auraIcon = aura.icon
          if auraName ~= "" then
            if spellName and auraName == tostring(spellName) then return true end
            if originalName and auraName == tostring(originalName) then return true end
          end
          if auraIcon then
            if spellIcon and auraIcon == spellIcon then return true end
            if originalIcon and auraIcon == originalIcon then return true end
          end
          return false
        end)
        if okHeuristic and heuristicMatch then
          okMatch, isMatch = true, true
        end
      end
      if okMatch and isMatch then
        local okApps, apps = pcall(tonumber, aura.applications)
        if okApps and type(apps) == "number" and apps > 0 then
          return apps
        end
      end
    end
  end

  if charges and not IsRealChargeSpell(charges, spellID) then
    return nil
  end
  return nil
end
local function ShouldHideLargeStackValue(value)
  if value == nil then return false end
  if issecretvalue and issecretvalue(value) then return false end
  local okNum, n = pcall(tonumber, value)
  if not okNum or type(n) ~= "number" then return false end
  local okCmp, tooLarge = pcall(function() return n > 100 end)
  return okCmp and tooLarge == true
end
local function GetSpellUsabilityState(spellID)
  local usableInfo, insufficientPower = C_Spell.IsSpellUsable(spellID)
  if usableInfo == nil then
    return true, false, false
  end
  return usableInfo == true, insufficientPower == true, true
end
local function ToPublicNumber(v)
  if v == nil then return nil end
  if issecretvalue and issecretvalue(v) then return nil end
  local ok, n = pcall(tonumber, v)
  if ok and type(n) == "number" then return n end
  return nil
end
local CCM = CreateFrame("Frame")
addonTable.Frame = CCM
local defaults = {
  profiles = {
    Default = {
      trackedSpells = {},
      spellsEnabled = {},
      uiScaleMode = "disabled",
      uiScale = nil,
      customBarsCount = 1,
      iconBorderSize = 0,
      iconStrata = "FULLSCREEN",
      showRadialCircle = true,
      showGCD = true,
      radialRadius = 20,
      radialThickness = 2,
      radialColorR = 1.0,
      radialColorG = 1.0,
      radialColorB = 1.0,
      radialAlpha = 0.8,
      globalFont = "lsm:Friz Quadrata TT",
      globalOutline = "OUTLINE",
      enableMasque = false,
      showMinimapButton = false,
      iconSize = 45,
      iconSpacing = 0,
      stackTextScale = 1.0,
      cdTextScale = 1.0,
      cdTextGradientThreshold = 0,
      cdTextGradientR = 1.0,
      cdTextGradientG = 0.0,
      cdTextGradientB = 0.0,
      iconsPerRow = 10,
      numColumns = 1,
      cooldownIconMode = "show",
      offsetX = 25,
      offsetY = 20,
      layoutDirection = "horizontal",
      growDirection = "right",
      stackTextPosition = "BOTTOMRIGHT",
      stackTextOffsetX = 0,
      stackTextOffsetY = 0,
      showInCombatOnly = false,
      iconsCombatOnly = false,
      cursorCombatOnly = false,
      cursorShowGCD = false,
      glowWhenReady = false,
      useSpellGlows = false,
      spellGlowDefaultType = "pixel",
      spellGlowSpeed = 0.0,
      spellGlowThickness = 2.0,
      useCustomHideReveal = false,
      spellHideRevealThresholds = {},
      customBarEnabled = true,
      customBarOutOfCombat = true,
      customBarShowGCD = true,
      customBarCentered = true,
      customBarIconSize = 50,
      customBarSpacing = 0,
      customBarCdTextScale = 1.0,
      customBarStackTextScale = 1.0,
      customBarIconsPerRow = 20,
      customBarCooldownMode = "show",
      customBarX = -200,
      customBarY = -200,
      customBarDirection = "horizontal",
      customBarAnchorPoint = "LEFT",
      customBarAnchorFrame = "UIParent",
      customBarAnchorToPoint = "CENTER",
      customBarGrowth = "UP",
      customBarStackTextPosition = "BOTTOMRIGHT",
      customBarStackTextOffsetX = 0,
      customBarStackTextOffsetY = 0,
      customBarCdGradientThreshold = 0,
      customBarCdGradientR = 1.0,
      customBarCdGradientG = 0.0,
      customBarCdGradientB = 0.0,
      customBarUseSpellGlows = false,
      customBarSpellGlowDefaultType = "pixel",
      customBarUseCustomHideReveal = false,
      customBar2Enabled = true,
      customBar2OutOfCombat = true,
      customBar2ShowGCD = true,
      customBar2Centered = true,
      customBar2IconSize = 50,
      customBar2Spacing = 0,
      customBar2CdTextScale = 1.0,
      customBar2StackTextScale = 1.0,
      customBar2IconsPerRow = 20,
      customBar2CooldownMode = "show",
      customBar2X = -200,
      customBar2Y = -200,
      customBar2Direction = "horizontal",
      customBar2AnchorPoint = "LEFT",
      customBar2AnchorFrame = "UIParent",
      customBar2AnchorToPoint = "CENTER",
      customBar2Growth = "UP",
      customBar2StackTextPosition = "BOTTOMRIGHT",
      customBar2StackTextOffsetX = 0,
      customBar2StackTextOffsetY = 0,
      customBar2CdGradientThreshold = 0,
      customBar2CdGradientR = 1.0,
      customBar2CdGradientG = 0.0,
      customBar2CdGradientB = 0.0,
      customBar2UseSpellGlows = false,
      customBar2SpellGlowDefaultType = "pixel",
      customBar2UseCustomHideReveal = false,
      customBar3Enabled = true,
      customBar3OutOfCombat = true,
      customBar3ShowGCD = true,
      customBar3Centered = true,
      customBar3IconSize = 50,
      customBar3Spacing = 0,
      customBar3CdTextScale = 1.0,
      customBar3StackTextScale = 1.0,
      customBar3IconsPerRow = 20,
      customBar3CooldownMode = "show",
      customBar3X = -200,
      customBar3Y = -200,
      customBar3Direction = "horizontal",
      customBar3AnchorPoint = "LEFT",
      customBar3AnchorFrame = "UIParent",
      customBar3AnchorToPoint = "CENTER",
      customBar3Growth = "UP",
      customBar3StackTextPosition = "BOTTOMRIGHT",
      customBar3StackTextOffsetX = 0,
      customBar3StackTextOffsetY = 0,
      customBar3CdGradientThreshold = 0,
      customBar3CdGradientR = 1.0,
      customBar3CdGradientG = 0.0,
      customBar3CdGradientB = 0.0,
      customBar3UseSpellGlows = false,
      customBar3SpellGlowDefaultType = "pixel",
      customBar3UseCustomHideReveal = false,
      customBar4Enabled = true,
      customBar4OutOfCombat = true,
      customBar4ShowGCD = true,
      customBar4Centered = true,
      customBar4IconSize = 50,
      customBar4Spacing = 0,
      customBar4CdTextScale = 1.0,
      customBar4StackTextScale = 1.0,
      customBar4IconsPerRow = 20,
      customBar4CooldownMode = "show",
      customBar4X = -200,
      customBar4Y = -200,
      customBar4Direction = "horizontal",
      customBar4AnchorPoint = "LEFT",
      customBar4AnchorFrame = "UIParent",
      customBar4AnchorToPoint = "CENTER",
      customBar4Growth = "UP",
      customBar4StackTextPosition = "BOTTOMRIGHT",
      customBar4StackTextOffsetX = 0,
      customBar4StackTextOffsetY = 0,
      customBar4CdGradientThreshold = 0,
      customBar4CdGradientR = 1.0,
      customBar4CdGradientG = 0.0,
      customBar4CdGradientB = 0.0,
      customBar4UseSpellGlows = false,
      customBar4SpellGlowDefaultType = "pixel",
      customBar4UseCustomHideReveal = false,
      customBar5Enabled = true,
      customBar5OutOfCombat = true,
      customBar5ShowGCD = true,
      customBar5Centered = true,
      customBar5IconSize = 50,
      customBar5Spacing = 0,
      customBar5CdTextScale = 1.0,
      customBar5StackTextScale = 1.0,
      customBar5IconsPerRow = 20,
      customBar5CooldownMode = "show",
      customBar5X = -200,
      customBar5Y = -200,
      customBar5Direction = "horizontal",
      customBar5AnchorPoint = "LEFT",
      customBar5AnchorFrame = "UIParent",
      customBar5AnchorToPoint = "CENTER",
      customBar5Growth = "UP",
      customBar5StackTextPosition = "BOTTOMRIGHT",
      customBar5StackTextOffsetX = 0,
      customBar5StackTextOffsetY = 0,
      customBar5CdGradientThreshold = 0,
      customBar5CdGradientR = 1.0,
      customBar5CdGradientG = 0.0,
      customBar5CdGradientB = 0.0,
      customBar5UseSpellGlows = false,
      customBar5SpellGlowDefaultType = "pixel",
      customBar5UseCustomHideReveal = false,
      blizzardBarSkinning = true,
      disableBlizzCDM = false,
      buffBarIconSizeOffset = -10,
      useBuffBar = false,
      useEssentialBar = false,
      essentialBarSpacing = 5,
      standaloneSkinBuff = false,
      standaloneSkinEssential = false,
      standaloneSkinUtility = false,
      standaloneIconBorderSize = 1,
      standaloneCdTextScale = 1.0,
      standaloneBuffCdTextScale = 1.0,
      standaloneEssentialCdTextScale = 1.0,
      standaloneUtilityCdTextScale = 1.0,
      standaloneCentered = false,
      standaloneBuffCentered = false,
      standaloneEssentialCentered = false,
      standaloneUtilityCentered = false,
      standaloneSpacing = 0,
      standaloneBuffSize = 45,
      standaloneBuffIconsPerRow = 0,
      standaloneBuffMaxRows = 2,
      standaloneBuffGrowDirection = "right",
      standaloneBuffRowGrowDirection = "down",
      standaloneBuffY = 0,
      standaloneEssentialSize = 45,
      standaloneEssentialSecondRowSize = 45,
      standaloneEssentialIconsPerRow = 0,
      standaloneEssentialMaxRows = 2,
      standaloneEssentialGrowDirection = "right",
      standaloneEssentialRowGrowDirection = "down",
      standaloneEssentialY = 50,
      standaloneUtilitySize = 45,
      standaloneUtilitySecondRowSize = 45,
      standaloneUtilityIconsPerRow = 0,
      standaloneUtilityMaxRows = 2,
      standaloneUtilityGrowDirection = "right",
      standaloneUtilityRowGrowDirection = "down",
      standaloneUtilityAutoWidth = "off",
      standaloneUtilityY = -50,
      hideActionBar1InCombat = false,
      hideActionBar1Mouseover = false,
      hideAB2InCombat = false, hideAB2Mouseover = false,
      hideAB3InCombat = false, hideAB3Mouseover = false,
      hideAB4InCombat = false, hideAB4Mouseover = false,
      hideAB5InCombat = false, hideAB5Mouseover = false,
      hideAB6InCombat = false, hideAB6Mouseover = false,
      hideAB7InCombat = false, hideAB7Mouseover = false,
      hideAB8InCombat = false, hideAB8Mouseover = false,
      hideStanceBarInCombat = false,
      hideStanceBarMouseover = false,
      hidePetBarInCombat = false,
      hidePetBarMouseover = false,
      actionBarGlobalMode = "custom",
      autoRepair = false,
      showTooltipIDs = false,
      compactMinimapIcons = false,
      combatTimerEnabled = false,
      combatTimerMode = "combat",
      combatTimerStyle = "boxed",
      combatTimerCentered = false,
      combatTimerX = 0,
      combatTimerY = 200,
      combatTimerScale = 1,
      combatTimerTextColorR = 1,
      combatTimerTextColorG = 1,
      combatTimerTextColorB = 1,
      combatTimerBgColorR = 0.12,
      combatTimerBgColorG = 0.12,
      combatTimerBgColorB = 0.12,
      combatTimerBgAlpha = 0.85,
      crTimerEnabled = false,
      crTimerMode = "combat",
      crTimerLayout = "vertical",
      crTimerCentered = false,
      crTimerX = 0,
      crTimerY = 150,
      combatStatusEnabled = false,
      combatStatusCentered = true,
      combatStatusX = 0,
      combatStatusY = 280,
      combatStatusScale = 1,
      combatStatusEnterColorR = 1,
      combatStatusEnterColorG = 1,
      combatStatusEnterColorB = 1,
      combatStatusLeaveColorR = 1,
      combatStatusLeaveColorG = 1,
      combatStatusLeaveColorB = 1,
      ufClassColor = false,
      ufUseCustomTextures = false,
      ufHealthTexture = "lsm:Clean",
      ufCustomBorderColorR = 0,
      ufCustomBorderColorG = 0,
      ufCustomBorderColorB = 0,
      ufDisableGlows = false,
      ufDisableCombatText = false,
      ufHideGroupIndicator = false,
      disableTargetBuffs = false,
      hideEliteTexture = false,
      cdFont = "lsm:Friz Quadrata TT",
      usePersonalResourceBar = false,
      prbX = 0,
      prbY = -180,
      prbWidth = 220,
      prbHealthHeight = 18,
      prbPowerHeight = 8,
      prbSpacing = 0,
      prbShowHealth = false,
      prbShowPower = false,
      prbShowMode = "always",
      prbHealthTextMode = "hidden",
      prbPowerTextMode = "hidden",
      prbCentered = false,
      prbAutoWidthSource = "off",
      prbHealthTexture = "solid",
      prbAbsorbTexture = "normtex",
      prbPowerTexture = "solid",
      prbManaTexture = "solid",
      prbHealthTextScale = 1,
      prbPowerTextScale = 1,
      prbManaTextScale = 1,
      prbHealthTextY = 0,
      prbPowerTextY = 0,
      prbManaTextY = 0,
      prbUseClassColor = true,
      prbHealthColorR = 0,
      prbHealthColorG = 1,
      prbHealthColorB = 0,
      prbHealthTextColorR = 1,
      prbHealthTextColorG = 1,
      prbHealthTextColorB = 1,
      prbUsePowerTypeColor = true,
      prbPowerColorR = 0,
      prbPowerColorG = 0.5,
      prbPowerColorB = 1,
      prbPowerTextColorR = 1,
      prbPowerTextColorG = 1,
      prbPowerTextColorB = 1,
      prbBorderSize = 1,
      prbBackgroundAlpha = 70,
      prbBgColorR = 0.1,
      prbBgColorG = 0.1,
      prbBgColorB = 0.1,
      prbClampBars = false,
      prbClampAnchor = "top",
      prbShowManaBar = false,
      prbManaHeight = 6,
      prbManaTextMode = "hidden",
      prbManaColorR = 0,
      prbManaColorG = 0.5,
      prbManaColorB = 1,
      prbManaTextColorR = 1,
      prbManaTextColorG = 1,
      prbManaTextColorB = 1,
      useCastbar = false,
      castbarWidth = 250,
      castbarHeight = 20,
      castbarX = 0,
      castbarY = -250,
      castbarCentered = true,
      castbarShowIcon = true,
      castbarIconSize = 24,
      castbarTexture = "solid",
      castbarUseClassColor = true,
      castbarColorR = 1,
      castbarColorG = 0.7,
      castbarColorB = 0,
      castbarBgAlpha = 70,
      castbarBgColorR = 0.1,
      castbarBgColorG = 0.1,
      castbarBgColorB = 0.1,
      castbarBorderSize = 1,
      castbarAutoWidthSource = "off",
      castbarShowTime = true,
      castbarTimeScale = 1.0,
      castbarTimeXOffset = 0,
      castbarTimeYOffset = 0,
      castbarTimePrecision = "1",
      castbarTimeDirection = "remaining",
      castbarShowSpellName = true,
      castbarSpellNameScale = 1.0,
      castbarSpellNameXOffset = 0,
      castbarSpellNameYOffset = 0,
      castbarTextColorR = 1,
      castbarTextColorG = 1,
      castbarTextColorB = 1,
      castbarShowTicks = true,
      useFocusCastbar = false,
      focusCastbarWidth = 250,
      focusCastbarHeight = 20,
      focusCastbarX = 0,
      focusCastbarY = -210,
      focusCastbarCentered = true,
      focusCastbarShowIcon = true,
      focusCastbarIconSize = 24,
      focusCastbarTexture = "solid",
      focusCastbarColorR = 1,
      focusCastbarColorG = 0.7,
      focusCastbarColorB = 0,
      focusCastbarBgAlpha = 70,
      focusCastbarBgColorR = 0.1,
      focusCastbarBgColorG = 0.1,
      focusCastbarBgColorB = 0.1,
      focusCastbarBorderSize = 1,
      focusCastbarShowTime = true,
      focusCastbarTimeScale = 1.0,
      focusCastbarTimeXOffset = 0,
      focusCastbarTimeYOffset = 0,
      focusCastbarTimePrecision = "1",
      focusCastbarTimeDirection = "remaining",
      focusCastbarShowSpellName = true,
      focusCastbarSpellNameScale = 1.0,
      focusCastbarSpellNameXOffset = 0,
      focusCastbarSpellNameYOffset = 0,
      focusCastbarTextColorR = 1,
      focusCastbarTextColorG = 1,
      focusCastbarTextColorB = 1,
      focusCastbarShowTicks = true,
      useTargetCastbar = false,
      targetCastbarWidth = 250,
      targetCastbarHeight = 20,
      targetCastbarX = 0,
      targetCastbarY = -250,
      targetCastbarCentered = true,
      targetCastbarShowIcon = true,
      targetCastbarIconSize = 24,
      targetCastbarTexture = "solid",
      targetCastbarColorR = 1,
      targetCastbarColorG = 0.7,
      targetCastbarColorB = 0,
      targetCastbarBgAlpha = 70,
      targetCastbarBgColorR = 0.1,
      targetCastbarBgColorG = 0.1,
      targetCastbarBgColorB = 0.1,
      targetCastbarBorderSize = 1,
      targetCastbarShowTime = true,
      targetCastbarTimeScale = 1.0,
      targetCastbarTimeXOffset = 0,
      targetCastbarTimeYOffset = 0,
      targetCastbarTimePrecision = "1",
      targetCastbarTimeDirection = "remaining",
      targetCastbarShowSpellName = true,
      targetCastbarSpellNameScale = 1.0,
      targetCastbarSpellNameXOffset = 0,
      targetCastbarSpellNameYOffset = 0,
      targetCastbarTextColorR = 1,
      targetCastbarTextColorG = 1,
      targetCastbarTextColorB = 1,
      targetCastbarShowTicks = true,
      selfHighlightShape = "off",
      selfHighlightCombatOnly = false,
      selfHighlightSize = 20,
      selfHighlightThickness = "medium",
      selfHighlightOutline = true,
      selfHighlightColorR = 1,
      selfHighlightColorG = 1,
      selfHighlightColorB = 1,
      selfHighlightAlpha = 1,
      noTargetAlertEnabled = false,
      noTargetAlertX = 0,
      noTargetAlertY = 100,
      noTargetAlertFontSize = 36,
      noTargetAlertColorR = 1,
      noTargetAlertColorG = 0,
      noTargetAlertColorB = 0,
      enablePlayerDebuffs = false,
      enableUnitFrameCustomization = true,
      playerDebuffSize = 32,
      playerDebuffSpacing = 2,
      playerDebuffX = 0,
      playerDebuffY = 0,
      playerDebuffSortDirection = "right",
      playerDebuffIconsPerRow = 10,
      playerDebuffRowGrowDirection = "down",
      playerDebuffBorderSize = 1,
    }
  },
  currentProfile = "Default",
  characterProfiles = {},
  characterCustomBarSpells = {},
  characterCustomBar2Spells = {},
  characterCustomBar3Spells = {},
  characterCustomBarSpellGlowEnabled = {},
  characterCustomBar2SpellGlowEnabled = {},
  characterCustomBar3SpellGlowEnabled = {},
  characterCustomBarSpellGlowType = {},
  characterCustomBar2SpellGlowType = {},
  characterCustomBar3SpellGlowType = {},
  characterCustomBarHideRevealThresholds = {},
  characterCustomBar2HideRevealThresholds = {},
  characterCustomBar3HideRevealThresholds = {},
  minimap = {
    hide = true,
    minimapPos = 220,
  }
}
local Masque = LibStub and LibStub("Masque", true)
local LibButtonGlow = LibStub("LibButtonGlow-1.0")
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local MasqueGroups = {}
addonTable.MasqueGroups = MasqueGroups
local function InitMasque()
  if not Masque then return end
  MasqueGroups.CursorIcons = Masque:Group("Cooldown Cursor Manager", "Cursor Icons")
  MasqueGroups.CustomBar = Masque:Group("Cooldown Cursor Manager", "Custom Bar")
  MasqueGroups.BuffBar = Masque:Group("Cooldown Cursor Manager", "Attached Buff Bar")
  MasqueGroups.EssentialBar = Masque:Group("Cooldown Cursor Manager", "Attached Essential Bar")
  MasqueGroups.CustomBar2 = Masque:Group("Cooldown Cursor Manager", "Custom Bar 2")
  MasqueGroups.CustomBar3 = Masque:Group("Cooldown Cursor Manager", "Custom Bar 3")
  MasqueGroups.CustomBar4 = Masque:Group("Cooldown Cursor Manager", "Custom Bar 4")
  MasqueGroups.CustomBar5 = Masque:Group("Cooldown Cursor Manager", "Custom Bar 5")
end
local function SkinButtonWithMasque(button, group)
  if not Masque or not group then return end
  local profile = CooldownCursorManagerDB and CooldownCursorManagerDB.profiles and CooldownCursorManagerDB.profiles[CooldownCursorManagerDB.currentProfile]
  if not profile or not profile.enableMasque then return end
  local iconTex = button.Icon or button.icon
  local cooldownFrame = button.Cooldown or button.cooldown or button.ccmCooldown
  local countText = button.Count or button.stackText or button.ccmChargeText
  local buttonData = {
    Icon = iconTex,
    Cooldown = cooldownFrame,
    Count = countText,
    FloatingBG = nil,
    Flash = nil,
    Pushed = nil,
    Normal = nil,
    Disabled = nil,
    Checked = nil,
    Border = nil,
    AutoCastable = nil,
    Highlight = nil,
    HotKey = nil,
    Duration = nil,
    Shine = nil,
  }
  group:AddButton(button, buttonData)
end
local function RemoveButtonFromMasque(button, group)
  if not Masque or not group then return end
  group:RemoveButton(button)
end
local function ReSkinMasqueGroup(group)
  if not Masque or not group then return end
  group:ReSkin()
end
addonTable.SkinButtonWithMasque = SkinButtonWithMasque
addonTable.RemoveButtonFromMasque = RemoveButtonFromMasque
addonTable.ReSkinMasqueGroup = ReSkinMasqueGroup
addonTable.InitMasque = InitMasque
addonTable.Masque = Masque
local minimapButton = CreateFrame("Button", "CCMMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapButton:RegisterForClicks("AnyUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetClampedToScreen(true)
minimapButton:Hide()
local minimapOverlay = minimapButton:CreateTexture(nil, "OVERLAY")
minimapOverlay:SetSize(53, 53)
minimapOverlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapOverlay:SetPoint("TOPLEFT", 0, 0)
local minimapBackground = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapBackground:SetSize(21, 21)
minimapBackground:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
minimapBackground:SetPoint("TOPLEFT", 7, -5)
local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetSize(18, 18)
minimapIcon:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\icon.tga")
minimapIcon:SetPoint("TOPLEFT", 7, -6)
local compactMinimapPanel = CreateFrame("Frame", "CCMCompactMinimapPanel", minimapButton, "BackdropTemplate")
compactMinimapPanel:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  edgeSize = 1,
})
compactMinimapPanel:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
compactMinimapPanel:SetBackdropBorderColor(0.30, 0.30, 0.35, 1)
compactMinimapPanel:SetFrameStrata("TOOLTIP")
compactMinimapPanel:SetFrameLevel(30)
compactMinimapPanel:SetPoint("BOTTOMLEFT", minimapButton, "TOPLEFT", 0, 8)
compactMinimapPanel:EnableMouse(true)
compactMinimapPanel:Hide()
function addonTable.IsCompactMinimapCandidate(button)
  if not button or button == minimapButton then return false end
  if not button.GetName or not button.IsObjectType or not button:IsObjectType("Button") then return false end
  local name = button:GetName()
  if type(name) ~= "string" then return false end
  if name:match("^LibDBIcon10_") then return true end
  return false
end
function addonTable.GetCompactButtonTexture(button)
  if not button then return nil end
  if button.icon and button.icon.GetTexture then
    local tex = button.icon:GetTexture()
    if tex then return tex end
  end
  local regions = {button:GetRegions()}
  for _, region in ipairs(regions) do
    if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.GetTexture then
      local tex = region:GetTexture()
      if tex then return tex end
    end
  end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end
function addonTable.EnsureCompactProxyButton(index)
  local proxy = State.compactMinimapProxyButtons[index]
  if proxy then return proxy end
  proxy = CreateFrame("Button", nil, compactMinimapPanel, "BackdropTemplate")
  proxy:SetSize(24, 24)
  proxy:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  proxy:SetBackdropColor(0.10, 0.10, 0.12, 1)
  proxy:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
  proxy.icon = proxy:CreateTexture(nil, "ARTWORK")
  proxy.icon:SetPoint("TOPLEFT", proxy, "TOPLEFT", 2, -2)
  proxy.icon:SetPoint("BOTTOMRIGHT", proxy, "BOTTOMRIGHT", -2, 2)
  proxy:SetScript("OnClick", function(self, buttonName, down)
    local src = self.ccmSourceButton
    if not src then return end
    local clickHandler = src:GetScript("OnClick")
    if clickHandler then
      pcall(clickHandler, src, buttonName, down)
    end
  end)
  proxy:SetScript("OnEnter", function(self)
    local src = self.ccmSourceButton
    if src then
      local onEnter = src:GetScript("OnEnter")
      if onEnter then
        pcall(onEnter, src)
        return
      end
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Compacted Minimap Icon", 1, 0.82, 0)
    if src and src.GetName then
      local srcName = src:GetName()
      if srcName then
        GameTooltip:AddLine(srcName, 0.8, 0.8, 0.8)
      end
    end
    GameTooltip:Show()
  end)
  proxy:SetScript("OnLeave", function(self)
    local src = self.ccmSourceButton
    if src then
      local onLeave = src:GetScript("OnLeave")
      if onLeave then
        pcall(onLeave, src)
        return
      end
    end
    GameTooltip:Hide()
  end)
  State.compactMinimapProxyButtons[index] = proxy
  return proxy
end
function addonTable.SetCompactMinimapPanelVisible(visible)
  if visible then
    if not State.compactMinimapActive then return end
    compactMinimapPanel:Show()
    State.compactMinimapPanelShown = true
  else
    compactMinimapPanel:Hide()
    State.compactMinimapPanelShown = false
  end
end
function addonTable.ScheduleCompactMinimapAutoHide()
  C_Timer.After(0.05, function()
    if not State.compactMinimapActive then
      addonTable.SetCompactMinimapPanelVisible(false)
      return
    end
    local overButton = minimapButton:IsMouseOver()
    local overPanel = compactMinimapPanel:IsMouseOver()
    if not overButton and not overPanel then
      addonTable.SetCompactMinimapPanelVisible(false)
    end
  end)
end
compactMinimapPanel:SetScript("OnEnter", function()
  if State.compactMinimapActive then
    addonTable.SetCompactMinimapPanelVisible(true)
  end
end)
compactMinimapPanel:SetScript("OnLeave", function()
  addonTable.ScheduleCompactMinimapAutoHide()
end)
function addonTable.RestoreCompactedMinimapButtons()
  for button, info in pairs(State.compactMinimapButtons) do
    if button and button.Show and info and info.wasShown then
      button:Show()
    end
    State.compactMinimapButtons[button] = nil
  end
  for _, proxy in ipairs(State.compactMinimapProxyButtons) do
    proxy.ccmSourceButton = nil
    proxy:Hide()
  end
end
function addonTable.RebuildCompactedMinimapButtons(force)
  if not State.compactMinimapActive then
    addonTable.RestoreCompactedMinimapButtons()
    return
  end
  local now = GetTime()
  if (not force) and State.compactMinimapLastRebuild and (now - State.compactMinimapLastRebuild) < 0.25 then
    return
  end
  addonTable.RestoreCompactedMinimapButtons()
  local children = {Minimap:GetChildren()}
  local count = 0
  for _, child in ipairs(children) do
    if addonTable.IsCompactMinimapCandidate(child) then
      count = count + 1
      State.compactMinimapButtons[child] = {wasShown = child:IsShown()}
      child:Hide()
      local proxy = addonTable.EnsureCompactProxyButton(count)
      proxy.ccmSourceButton = child
      proxy.icon:SetTexture(addonTable.GetCompactButtonTexture(child))
      proxy:Show()
      local columns = 4
      local row = math.floor((count - 1) / columns)
      local col = (count - 1) % columns
      proxy:ClearAllPoints()
      proxy:SetPoint("TOPLEFT", compactMinimapPanel, "TOPLEFT", 8 + col * 28, -8 - row * 28)
    end
  end
  if count <= 0 then
    compactMinimapPanel:SetSize(40, 40)
    addonTable.SetCompactMinimapPanelVisible(false)
    return
  end
  local columns = math.min(4, count)
  local rows = math.ceil(count / 4)
  compactMinimapPanel:SetSize(16 + columns * 28, 16 + rows * 28)
  State.compactMinimapLastRebuild = now
end
function addonTable.ApplyCompactMinimapIcons()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local enabled = profile and profile.compactMinimapIcons == true
  State.compactMinimapActive = enabled
  if enabled then
    if profile.showMinimapButton == false then
      profile.showMinimapButton = true
    end
    minimapButton:Show()
    addonTable.RebuildCompactedMinimapButtons(true)
  else
    addonTable.RestoreCompactedMinimapButtons()
    addonTable.SetCompactMinimapPanelVisible(false)
  end
end
addonTable.ToggleCompactMinimapPanel = function()
  if not State.compactMinimapActive then return end
  addonTable.RebuildCompactedMinimapButtons(true)
  addonTable.SetCompactMinimapPanelVisible(not State.compactMinimapPanelShown)
end
function addonTable.UpdateMinimapButtonPosition()
  local db = CooldownCursorManagerDB and CooldownCursorManagerDB.minimap
  if not db then return end
  local angle = math.rad(db.minimapPos or 220)
  local radius = 80 + (minimapButton:GetWidth() * 0.75)
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
addonTable.SetOpenAfterCombat = function(val) State.openAfterCombat = val end
addonTable.GetOpenAfterCombat = function() return State.openAfterCombat end
minimapButton:SetScript("OnDragStart", function(self)
  State.minimapDragging = true
  self:SetScript("OnUpdate", function(self)
    if not State.minimapDragging then
      self:SetScript("OnUpdate", nil)
      return
    end
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    local angle = math.deg(math.atan2(cy - my, cx - mx))
    if angle < 0 then angle = angle + 360 end
    if CooldownCursorManagerDB and CooldownCursorManagerDB.minimap then
      CooldownCursorManagerDB.minimap.minimapPos = angle
    end
    addonTable.UpdateMinimapButtonPosition()
  end)
end)
minimapButton:SetScript("OnDragStop", function(self)
  State.minimapDragging = false
  self:SetScript("OnUpdate", nil)
end)
minimapButton:SetScript("OnClick", function(self, button)
  local profile = CooldownCursorManagerDB and CooldownCursorManagerDB.profiles and CooldownCursorManagerDB.profiles[CooldownCursorManagerDB.currentProfile]
  if profile and profile.compactMinimapIcons == true then
    addonTable.RebuildCompactedMinimapButtons(false)
    addonTable.SetCompactMinimapPanelVisible(true)
  end
  if button == "LeftButton" then
    if InCombatLockdown() then
      State.openAfterCombat = true
      print("|cff00ff00CCM:|r Settings will open after combat.")
      return
    end
    if addonTable.ConfigFrame then
      if addonTable.ConfigFrame:IsShown() then
        addonTable.ConfigFrame:Hide()
        if addonTable.SetGUIOpen then addonTable.SetGUIOpen(false) end
      else
        if addonTable.SetGUIOpen then addonTable.SetGUIOpen(true) end
        if addonTable.MaybeShowUpdateChangelogOnConfigOpen then addonTable.MaybeShowUpdateChangelogOnConfigOpen() end
        addonTable.ConfigFrame:Show()
        if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
      end
    end
  elseif button == "RightButton" then
    if profile then
      profile.showRadialCircle = not profile.showRadialCircle
      if profile.showRadialCircle then
        print("|cff00ff00CCM:|r Radial Circle enabled")
      else
        print("|cff00ff00CCM:|r Radial Circle disabled")
      end
      if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    end
  end
end)
minimapButton:SetScript("OnEnter", function(self)
  local profile = CooldownCursorManagerDB and CooldownCursorManagerDB.profiles and CooldownCursorManagerDB.profiles[CooldownCursorManagerDB.currentProfile]
  if profile and profile.compactMinimapIcons == true then
    addonTable.RebuildCompactedMinimapButtons(false)
    addonTable.SetCompactMinimapPanelVisible(true)
  end
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("Cooldown Cursor Manager", 1, 0.82, 0)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("|cffffffffLeft-Click:|r Open Settings", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("|cffffffffRight-Click:|r Toggle Radial Circle", 0.8, 0.8, 0.8)
  if profile and profile.compactMinimapIcons == true then
    GameTooltip:AddLine("|cffffffffHover/Click:|r Show compact icons", 0.8, 0.8, 0.8)
  end
  GameTooltip:AddLine("|cffffffffDrag:|r Move this button", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function(self)
  GameTooltip:Hide()
  addonTable.ScheduleCompactMinimapAutoHide()
end)
function addonTable.ShowMinimapButton()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile and profile.showMinimapButton == false and not (profile.compactMinimapIcons == true) then
    minimapButton:Hide()
    return
  end
  minimapButton:Show()
  addonTable.UpdateMinimapButtonPosition()
  if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
end
function addonTable.HideMinimapButton()
  addonTable.SetCompactMinimapPanelVisible(false)
  if State.compactMinimapActive then
    return
  end
  minimapButton:Hide()
end
addonTable.MinimapButton = minimapButton
addonTable.SetupTooltipIDHooks = function()
  if addonTable.tooltipIDHooksInstalled then return end
  local function IsIDsEnabled()
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    return profile and profile.showTooltipIDs == true
  end
  local function SafeToNumber(v)
    local ok, n = pcall(tonumber, v)
    if ok and type(n) == "number" then return n end
    return nil
  end
  local function AddSpellLines(tt, spellID)
    local sid = SafeToNumber(spellID)
    if not sid then return false end
    tt:AddLine(string.format("|cff888888SpellID:|r %d", sid), 0.75, 0.75, 0.75)
    return true
  end
  local function AddItemLines(tt, itemIDOrLink)
    if not C_Item.GetItemInfoInstant then return false end
    local itemID = C_Item.GetItemInfoInstant(itemIDOrLink)
    local iid = SafeToNumber(itemID)
    if not iid then return false end
    tt:AddLine(string.format("|cff888888ItemID:|r %d", iid), 0.75, 0.75, 0.75)
    return true
  end
  local function AddTooltipIDs(tt, tooltipData)
    if not IsIDsEnabled() then return end
    if not tt or tt.ccmIDsAdded then return end
    local added = false
    if type(tooltipData) == "table" then
      local byItemID = SafeToNumber(tooltipData.itemID)
      local bySpellID = SafeToNumber(tooltipData.spellID)
      local byID = SafeToNumber(tooltipData.id)
      local linkType, linkID
      if type(tooltipData.hyperlink) == "string" then
        linkType, linkID = tooltipData.hyperlink:match("H([^:]+):(%d+)")
        if not linkType then
          linkType, linkID = tooltipData.hyperlink:match("^([^:]+):(%d+)")
        end
      end
      linkID = SafeToNumber(linkID)
      if byItemID and AddItemLines(tt, byItemID) then
        added = true
      elseif bySpellID and AddSpellLines(tt, bySpellID) then
        added = true
      elseif linkType == "item" and linkID and AddItemLines(tt, linkID) then
        added = true
      elseif linkType == "spell" and linkID and AddSpellLines(tt, linkID) then
        added = true
      elseif byID and Enum and Enum.TooltipDataType then
        local dtype = SafeToNumber(tooltipData.type or tooltipData.tooltipDataType)
        if dtype == Enum.TooltipDataType.Item and AddItemLines(tt, byID) then
          added = true
        elseif dtype == Enum.TooltipDataType.Spell and AddSpellLines(tt, byID) then
          added = true
        elseif Enum.TooltipDataType.UnitAura and dtype == Enum.TooltipDataType.UnitAura and AddSpellLines(tt, byID) then
          added = true
        end
      end
    end
    if not added and tt.GetItem then
      local _, itemLink = tt:GetItem()
      if itemLink then
        if AddItemLines(tt, itemLink) then
          added = true
        end
      end
    end
    if not added and tt.GetSpell then
      local _, _, spellID = tt:GetSpell()
      if AddSpellLines(tt, spellID) then
        added = true
      end
    end
    if not added and tt.ccmForcedSpellID then
      if AddSpellLines(tt, tt.ccmForcedSpellID) then
        added = true
      end
    end
    if not added and tt.ccmActionSlot and GetActionInfo then
      local actionType, actionID = GetActionInfo(tt.ccmActionSlot)
      local isSpell, isItem, isMacro = false, false, false
      pcall(function()
        isSpell = actionType == "spell"
        isItem = actionType == "item"
        isMacro = actionType == "macro"
      end)
      if isSpell then
        if AddSpellLines(tt, actionID) then
          added = true
        end
      elseif isItem then
        if AddItemLines(tt, actionID) then
          added = true
        end
      elseif isMacro and GetMacroItem then
        local macroItemLink = GetMacroItem(actionID)
        if macroItemLink and AddItemLines(tt, macroItemLink) then
          added = true
        end
      end
    end
    if not added and tt.ccmSpellBookSlot and tt.ccmSpellBookType then
      local spellBookSpellID
      if GetSpellBookItemInfo then
        local _, sbSpellID = GetSpellBookItemInfo(tt.ccmSpellBookSlot, tt.ccmSpellBookType)
        spellBookSpellID = SafeToNumber(sbSpellID)
      end
      if not spellBookSpellID and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        local okSB, spellBookItemInfo = pcall(C_SpellBook.GetSpellBookItemInfo, tt.ccmSpellBookSlot, tt.ccmSpellBookType)
        if okSB and type(spellBookItemInfo) == "table" then
          spellBookSpellID = SafeToNumber(spellBookItemInfo.spellID)
        end
      end
      if spellBookSpellID and AddSpellLines(tt, spellBookSpellID) then
        added = true
      end
    end
    tt.ccmActionSlot = nil
    tt.ccmSpellBookSlot = nil
    tt.ccmSpellBookType = nil
    tt.ccmForcedSpellID = nil
    if added then
      tt.ccmIDsAdded = true
      tt:Show()
    end
  end
  local function SafeHookScript(tooltip, scriptName, fn)
    if not tooltip or not tooltip.HookScript then return false end
    local okHas, hasScript = pcall(function()
      if tooltip.HasScript then
        return tooltip:HasScript(scriptName)
      end
      return tooltip.GetScript and tooltip:GetScript(scriptName) ~= nil
    end)
    if not okHas or not hasScript then return false end
    local okHook = pcall(function()
      tooltip:HookScript(scriptName, fn)
    end)
    return okHook
  end
  local function HookTooltip(tooltip)
    if not tooltip then return end
    SafeHookScript(tooltip, "OnTooltipCleared", function(tt)
      tt.ccmIDsAdded = nil
      tt.ccmActionSlot = nil
      tt.ccmSpellBookSlot = nil
      tt.ccmSpellBookType = nil
      tt.ccmForcedSpellID = nil
    end)
    local hookedItem = SafeHookScript(tooltip, "OnTooltipSetItem", AddTooltipIDs)
    local hookedSpell = SafeHookScript(tooltip, "OnTooltipSetSpell", AddTooltipIDs)
    if not hookedItem and not hookedSpell then
      SafeHookScript(tooltip, "OnShow", AddTooltipIDs)
    end
  end
  HookTooltip(GameTooltip)
  HookTooltip(ItemRefTooltip)
  HookTooltip(SpellBookTooltip)
  local function QueueTooltipIDUpdate(tt)
    if not tt then return end
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        if tt and tt.IsShown and tt:IsShown() and not tt.ccmIDsAdded then
          AddTooltipIDs(tt)
        end
      end)
    else
      AddTooltipIDs(tt)
    end
  end
  local function HookSpellSources(tooltip)
    if not tooltip then return end
    if tooltip.SetAction then
      hooksecurefunc(tooltip, "SetAction", function(tt, actionSlot)
        if not tt then return end
        if tt.ccmActionSlot ~= actionSlot then
          tt.ccmIDsAdded = nil
        end
        tt.ccmActionSlot = actionSlot
      end)
    end
    if tooltip.SetSpellBookItem then
      hooksecurefunc(tooltip, "SetSpellBookItem", function(tt, slotIndex, spellBookType)
        if not tt then return end
        if tt.ccmSpellBookSlot ~= slotIndex or tt.ccmSpellBookType ~= spellBookType then
          tt.ccmIDsAdded = nil
        end
        tt.ccmSpellBookSlot = slotIndex
        tt.ccmSpellBookType = spellBookType
        QueueTooltipIDUpdate(tt)
      end)
    end
    if tooltip.SetSpellByID then
      hooksecurefunc(tooltip, "SetSpellByID", function(tt, spellID)
        if not tt then return end
        if tt.ccmForcedSpellID ~= spellID then
          tt.ccmIDsAdded = nil
        end
        tt.ccmForcedSpellID = spellID
        QueueTooltipIDUpdate(tt)
      end)
    end
  end
  HookSpellSources(GameTooltip)
  HookSpellSources(SpellBookTooltip)
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    if Enum.TooltipDataType.Item then
      TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddTooltipIDs)
    end
    if Enum.TooltipDataType.Spell then
      TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, AddTooltipIDs)
    end
    if Enum.TooltipDataType.UnitAura then
      TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, AddTooltipIDs)
    end
  end
  addonTable.tooltipIDHooksInstalled = true
end
addonTable.SetupEnhancedTooltipHook = function()
  if addonTable.enhancedTooltipHookInstalled then return end
  addonTable.enhancedTooltipHookInstalled = true
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if not profile or not profile.enhancedTooltip then return end
      if tooltip ~= GameTooltip then return end
      local unit = "mouseover"
      if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
      local _, classToken = UnitClass(unit)
      if not classToken then return end
      local color = RAID_CLASS_COLORS[classToken]
      if not color then return end
      local nameText = GameTooltipTextLeft1
      if nameText then
        nameText:SetTextColor(color.r, color.g, color.b)
      end
      local engFaction, locFaction = UnitFactionGroup(unit)
      local numLines = tooltip:NumLines()
      for i = 2, numLines do
        local line = _G["GameTooltipTextLeft" .. i]
        if line then
          local text = line:GetText()
          if text then
            if locFaction and text == locFaction then
              if engFaction == "Alliance" then
                line:SetTextColor(0.3, 0.5, 1.0)
              elseif engFaction == "Horde" then
                line:SetTextColor(0.9, 0.2, 0.2)
              end
            end
            local guildName, guildRank = GetGuildInfo(unit)
            if guildName and guildRank and text:find(guildName, 1, true) then
              line:SetText("<" .. guildName .. "> " .. guildRank)
            end
          end
        end
      end
    end)
  end
end
addonTable.TryAutoRepair = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or profile.autoRepair ~= true then return end
  if not CanMerchantRepair or not CanMerchantRepair() then return end
  if not GetRepairAllCost or not RepairAllItems then return end
  local repairCost, canRepair = GetRepairAllCost()
  if not canRepair or type(repairCost) ~= "number" or repairCost <= 0 then return end
  local repairedFromGuild = false
  if CanGuildBankRepair and CanGuildBankRepair() then
    local canUseGuildMoney = true
    if GetGuildBankWithdrawMoney then
      local guildMoney = GetGuildBankWithdrawMoney()
      if type(guildMoney) == "number" and guildMoney >= 0 and guildMoney < repairCost then
        canUseGuildMoney = false
      end
    end
    if canUseGuildMoney then
      RepairAllItems(true)
      repairedFromGuild = true
    end
  end
  if repairedFromGuild then return end
  if not GetMoney then return end
  local playerMoney = GetMoney()
  if type(playerMoney) == "number" and playerMoney >= repairCost then
    RepairAllItems(false)
  end
end
local function AddIconBorder(icon, borderSize)
  if borderSize <= 0 then return end
  icon.borderTop = icon:CreateTexture(nil, "OVERLAY")
  icon.borderTop:SetColorTexture(0, 0, 0, 1)
  icon.borderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
  icon.borderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
  icon.borderTop:SetHeight(borderSize)
  icon.borderBottom = icon:CreateTexture(nil, "OVERLAY")
  icon.borderBottom:SetColorTexture(0, 0, 0, 1)
  icon.borderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
  icon.borderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
  icon.borderBottom:SetHeight(borderSize)
  icon.borderLeft = icon:CreateTexture(nil, "OVERLAY")
  icon.borderLeft:SetColorTexture(0, 0, 0, 1)
  icon.borderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
  icon.borderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
  icon.borderLeft:SetWidth(borderSize)
  icon.borderRight = icon:CreateTexture(nil, "OVERLAY")
  icon.borderRight:SetColorTexture(0, 0, 0, 1)
  icon.borderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
  icon.borderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
  icon.borderRight:SetWidth(borderSize)
end
addonTable.AddIconBorder = AddIconBorder
local function IsRealNumber(value)
  if value == nil then return false end
  local ok = pcall(function()
    local _ = (value > -999999999)
  end)
  return ok
end
addonTable.IsRealNumber = IsRealNumber
local function IsShowModeActive(mode, skipCombatOverride)
  if not mode or mode == "always" then return true end
  if not skipCombatOverride and UnitAffectingCombat("player") then return true end
  local inInstance, instanceType = IsInInstance()
  if mode == "raid" then return inInstance and instanceType == "raid" end
  if mode == "dungeon" then return inInstance and instanceType == "party" end
  if mode == "raidanddungeon" then return inInstance and (instanceType == "raid" or instanceType == "party") end
  return true
end
addonTable.IsShowModeActive = IsShowModeActive
local function IsOnlyGCD(startTime, duration, spellID, cdExpectedEnd, cachedGcdInfo)
  local st = ToPublicNumber(startTime)
  local dur = ToPublicNumber(duration)
  local gcdInfo = cachedGcdInfo
  local gcdStart = gcdInfo and ToPublicNumber(gcdInfo.startTime) or nil
  local gcdDur = gcdInfo and ToPublicNumber(gcdInfo.duration) or nil
  local gcdOn = gcdInfo and (gcdInfo.isOnGCD == true) or false
  if startTime == nil or duration == nil then return false end
  if st and st == 0 then return false end
  if dur and dur == 0 then return false end
  if dur and dur > 1.6 then return false end
  if st and dur and gcdStart and gcdDur and gcdStart > 0 and gcdDur > 0 then
    local okDiff, startDiff, durDiff = pcall(function()
      return math.abs(st - gcdStart), math.abs(dur - gcdDur)
    end)
    if okDiff and startDiff and durDiff and startDiff <= 0.10 and durDiff <= 0.20 then
      return true
    end
  end
  if dur and dur > 0 and dur <= 1.6 then return true end
  if gcdOn and ((issecretvalue and (issecretvalue(startTime) or issecretvalue(duration))) or (not st and not dur)) then
    local now = GetTime and GetTime() or 0
    if type(cdExpectedEnd) == "number" and cdExpectedEnd > (now + 0.05) then
      return false
    end
    if spellID then
      local baseDur = State.spellBaseCdDurations[spellID]
      if type(baseDur) == "number" and baseDur > 1.6 and cdExpectedEnd and cdExpectedEnd > now then return false end
      local knownDur = State.spellCdDurations[spellID]
      if type(knownDur) == "number" and knownDur > 1.6 and cdExpectedEnd and cdExpectedEnd > now then return false end
    end
    return true
  end
  if gcdOn and ((gcdDur and gcdDur > 0 and gcdDur <= 1.6) or dur == nil) then
    return true
  end
  return false
end
local function ShouldSuppressGCDSwipe(showGCD, startTime, duration, spellID, cdExpectedEnd, cachedGcdInfo)
  if showGCD then return false end
  if IsOnlyGCD(startTime, duration, spellID, cdExpectedEnd, cachedGcdInfo) then return true end
  if not cachedGcdInfo then return false end
  if not (type(cachedGcdInfo) == "table" and cachedGcdInfo.isOnGCD == true) then
    return false
  end
  local dur = ToPublicNumber(duration)
  local gcdDur = ToPublicNumber(cachedGcdInfo.duration)
  local now = GetTime and GetTime() or 0
  if type(cdExpectedEnd) == "number" and cdExpectedEnd > (now + 0.05) then
    return false
  end
  if dur and dur > 0 and dur <= 1.8 then
    if gcdDur and gcdDur > 0 and gcdDur <= 1.8 then
      return true
    end
    if issecretvalue and issecretvalue(startTime) then
      return true
    end
  end
  if dur == nil then
    return true
  end
  if issecretvalue and (issecretvalue(startTime) or issecretvalue(duration)) then
    return true
  end
  return false
end
local function GetFramePointCoords(frame, point)
  local l, b, w, h = frame:GetRect()
  if not (l and b and w and h) then return frame:GetCenter() end
  local p = point and point:upper() or "CENTER"
  if p == "TOPLEFT" then return l, b + h
  elseif p == "TOP" then return l + w / 2, b + h
  elseif p == "TOPRIGHT" then return l + w, b + h
  elseif p == "LEFT" then return l, b + h / 2
  elseif p == "RIGHT" then return l + w, b + h / 2
  elseif p == "BOTTOMLEFT" then return l, b
  elseif p == "BOTTOM" then return l + w / 2, b
  elseif p == "BOTTOMRIGHT" then return l + w, b
  else return l + w / 2, b + h / 2 end
end
local customBarFrame = CreateFrame("Frame", "CCMCustomBar", UIParent, "BackdropTemplate")
customBarFrame:SetSize(200, 50)
customBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
customBarFrame:SetFrameStrata("MEDIUM")
customBarFrame:SetClampedToScreen(true)
customBarFrame:SetMovable(false)
customBarFrame:EnableMouse(true)
customBarFrame:RegisterForDrag("LeftButton")
customBarFrame:Hide()
addonTable.SetCustomBarMoving = function(moving) State.customBar1Moving = moving end
addonTable.GetCustomBarMoving = function() return State.customBar1Moving end
addonTable.CustomBarFrame = customBarFrame
customBarFrame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 3 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(3) end
  end
  State.cb1Dragging = true
  self:StartMoving()
end)
customBarFrame:SetScript("OnDragStop", function(self)
  if not State.cb1Dragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local resolve = addonTable.ResolveCustomBarAnchorFrame
    local anchorFrame = resolve and resolve(profile.customBarAnchorFrame) or UIParent
    local anchorToPoint = profile.customBarAnchorToPoint or "CENTER"
    local selfScale = self:GetEffectiveScale()
    local anchorScale = anchorFrame:GetEffectiveScale()
    local aX, aY = GetFramePointCoords(anchorFrame, anchorToPoint)
    local frameX, frameY = self:GetCenter()
    local newX = math.floor((frameX * selfScale - aX * anchorScale) / selfScale + 0.5)
    local newY = math.floor((frameY * selfScale - aY * anchorScale) / selfScale + 0.5)
    profile.customBarX = newX
    profile.customBarY = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(1, newX, newY) end
    State.cb1Dragging = false
    self:ClearAllPoints()
    self:SetPoint("CENTER", anchorFrame, anchorToPoint, newX, newY)
  else
    State.cb1Dragging = false
  end
end)
customBarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.cb1Dragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(3) end
    end
  end
end)
local customBar2Frame = CreateFrame("Frame", "CCMCustomBar2", UIParent, "BackdropTemplate")
customBar2Frame:SetSize(200, 50)
customBar2Frame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
customBar2Frame:SetFrameStrata("MEDIUM")
customBar2Frame:SetClampedToScreen(true)
customBar2Frame:SetMovable(false)
customBar2Frame:EnableMouse(true)
customBar2Frame:RegisterForDrag("LeftButton")
customBar2Frame:Hide()
addonTable.SetCustomBar2Moving = function(moving) State.customBar2Moving = moving end
addonTable.GetCustomBar2Moving = function() return State.customBar2Moving end
addonTable.CustomBar2Frame = customBar2Frame
customBar2Frame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 4 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(4) end
  end
  State.cb2Dragging = true
  self:StartMoving()
end)
customBar2Frame:SetScript("OnDragStop", function(self)
  if not State.cb2Dragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local resolve = addonTable.ResolveCustomBarAnchorFrame
    local anchorFrame = resolve and resolve(profile.customBar2AnchorFrame) or UIParent
    local anchorToPoint = profile.customBar2AnchorToPoint or "CENTER"
    local selfScale = self:GetEffectiveScale()
    local anchorScale = anchorFrame:GetEffectiveScale()
    local aX, aY = GetFramePointCoords(anchorFrame, anchorToPoint)
    local frameX, frameY = self:GetCenter()
    local newX = math.floor((frameX * selfScale - aX * anchorScale) / selfScale + 0.5)
    local newY = math.floor((frameY * selfScale - aY * anchorScale) / selfScale + 0.5)
    profile.customBar2X = newX
    profile.customBar2Y = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(2, newX, newY) end
    State.cb2Dragging = false
    self:ClearAllPoints()
    self:SetPoint("CENTER", anchorFrame, anchorToPoint, newX, newY)
  else
    State.cb2Dragging = false
  end
end)
customBar2Frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.cb2Dragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(4) end
    end
  end
end)
local customBar3Frame = CreateFrame("Frame", "CCMCustomBar3", UIParent, "BackdropTemplate")
customBar3Frame:SetSize(200, 50)
customBar3Frame:SetPoint("CENTER", UIParent, "CENTER", 0, -300)
customBar3Frame:SetFrameStrata("MEDIUM")
customBar3Frame:SetClampedToScreen(true)
customBar3Frame:SetMovable(false)
customBar3Frame:EnableMouse(true)
customBar3Frame:RegisterForDrag("LeftButton")
customBar3Frame:Hide()
addonTable.SetCustomBar3Moving = function(moving) State.customBar3Moving = moving end
addonTable.GetCustomBar3Moving = function() return State.customBar3Moving end
addonTable.CustomBar3Frame = customBar3Frame
customBar3Frame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 5 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(5) end
  end
  State.cb3Dragging = true
  self:StartMoving()
end)
customBar3Frame:SetScript("OnDragStop", function(self)
  if not State.cb3Dragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local resolve = addonTable.ResolveCustomBarAnchorFrame
    local anchorFrame = resolve and resolve(profile.customBar3AnchorFrame) or UIParent
    local anchorToPoint = profile.customBar3AnchorToPoint or "CENTER"
    local selfScale = self:GetEffectiveScale()
    local anchorScale = anchorFrame:GetEffectiveScale()
    local aX, aY = GetFramePointCoords(anchorFrame, anchorToPoint)
    local frameX, frameY = self:GetCenter()
    local newX = math.floor((frameX * selfScale - aX * anchorScale) / selfScale + 0.5)
    local newY = math.floor((frameY * selfScale - aY * anchorScale) / selfScale + 0.5)
    profile.customBar3X = newX
    profile.customBar3Y = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(3, newX, newY) end
    State.cb3Dragging = false
    self:ClearAllPoints()
    self:SetPoint("CENTER", anchorFrame, anchorToPoint, newX, newY)
  else
    State.cb3Dragging = false
  end
end)
customBar3Frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.cb3Dragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(5) end
    end
  end
end)
local customBar4Frame = CreateFrame("Frame", "CCMCustomBar4", UIParent, "BackdropTemplate")
customBar4Frame:SetSize(200, 50)
customBar4Frame:SetPoint("CENTER", UIParent, "CENTER", 0, -350)
customBar4Frame:SetFrameStrata("MEDIUM")
customBar4Frame:SetClampedToScreen(true)
customBar4Frame:SetMovable(false)
customBar4Frame:EnableMouse(true)
customBar4Frame:RegisterForDrag("LeftButton")
customBar4Frame:Hide()
addonTable.SetCustomBar4Moving = function(moving) State.customBar4Moving = moving end
addonTable.GetCustomBar4Moving = function() return State.customBar4Moving end
addonTable.CustomBar4Frame = customBar4Frame
customBar4Frame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 20 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(20) end
  end
  State.cb4Dragging = true
  self:StartMoving()
end)
customBar4Frame:SetScript("OnDragStop", function(self)
  if not State.cb4Dragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local resolve = addonTable.ResolveCustomBarAnchorFrame
    local anchorFrame = resolve and resolve(profile.customBar4AnchorFrame) or UIParent
    local anchorToPoint = profile.customBar4AnchorToPoint or "CENTER"
    local selfScale = self:GetEffectiveScale()
    local anchorScale = anchorFrame:GetEffectiveScale()
    local aX, aY = GetFramePointCoords(anchorFrame, anchorToPoint)
    local frameX, frameY = self:GetCenter()
    local newX = math.floor((frameX * selfScale - aX * anchorScale) / selfScale + 0.5)
    local newY = math.floor((frameY * selfScale - aY * anchorScale) / selfScale + 0.5)
    profile.customBar4X = newX
    profile.customBar4Y = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(4, newX, newY) end
    State.cb4Dragging = false
    self:ClearAllPoints()
    self:SetPoint("CENTER", anchorFrame, anchorToPoint, newX, newY)
  else
    State.cb4Dragging = false
  end
end)
customBar4Frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.cb4Dragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(20) end
    end
  end
end)
local customBar5Frame = CreateFrame("Frame", "CCMCustomBar5", UIParent, "BackdropTemplate")
customBar5Frame:SetSize(200, 50)
customBar5Frame:SetPoint("CENTER", UIParent, "CENTER", 0, -400)
customBar5Frame:SetFrameStrata("MEDIUM")
customBar5Frame:SetClampedToScreen(true)
customBar5Frame:SetMovable(false)
customBar5Frame:EnableMouse(true)
customBar5Frame:RegisterForDrag("LeftButton")
customBar5Frame:Hide()
addonTable.SetCustomBar5Moving = function(moving) State.customBar5Moving = moving end
addonTable.GetCustomBar5Moving = function() return State.customBar5Moving end
addonTable.CustomBar5Frame = customBar5Frame
customBar5Frame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 21 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(21) end
  end
  State.cb5Dragging = true
  self:StartMoving()
end)
customBar5Frame:SetScript("OnDragStop", function(self)
  if not State.cb5Dragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local resolve = addonTable.ResolveCustomBarAnchorFrame
    local anchorFrame = resolve and resolve(profile.customBar5AnchorFrame) or UIParent
    local anchorToPoint = profile.customBar5AnchorToPoint or "CENTER"
    local selfScale = self:GetEffectiveScale()
    local anchorScale = anchorFrame:GetEffectiveScale()
    local aX, aY = GetFramePointCoords(anchorFrame, anchorToPoint)
    local frameX, frameY = self:GetCenter()
    local newX = math.floor((frameX * selfScale - aX * anchorScale) / selfScale + 0.5)
    local newY = math.floor((frameY * selfScale - aY * anchorScale) / selfScale + 0.5)
    profile.customBar5X = newX
    profile.customBar5Y = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(5, newX, newY) end
    State.cb5Dragging = false
    self:ClearAllPoints()
    self:SetPoint("CENTER", anchorFrame, anchorToPoint, newX, newY)
  else
    State.cb5Dragging = false
  end
end)
customBar5Frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.cb5Dragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(21) end
    end
  end
end)
addonTable.UpdateCustomBarSliders = function(barIndex, x, y)
  local cbTbl = barIndex == 1 and addonTable.cb1 or barIndex == 2 and addonTable.cb2 or barIndex == 3 and addonTable.cb3 or barIndex == 4 and addonTable.cb4 or barIndex == 5 and addonTable.cb5 or nil
  if not cbTbl then return end
  if cbTbl.xSlider then cbTbl.xSlider:SetValue(x); cbTbl.xSlider.valueText:SetText(math.floor(x)) end
  if cbTbl.ySlider then cbTbl.ySlider:SetValue(y); cbTbl.ySlider.valueText:SetText(math.floor(y)) end
end
local function GetClassColor()
  local _, class = UnitClass("player")
  local colors = RAID_CLASS_COLORS[class]
  if colors then return colors.r, colors.g, colors.b end
  return 0, 1, 0
end
addonTable.GetClassColor = GetClassColor
GetGlobalFont = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local fontPath = "Fonts\\FRIZQT__.TTF"
  local fontOutline = "OUTLINE"
  if profile then
    if profile.globalFont and profile.globalFont ~= "" then
      local fontValue = profile.globalFont
      if fontValue == "default" then
        fontPath = "Fonts\\FRIZQT__.TTF"
      elseif fontValue == "arial" then
        fontPath = "Fonts\\ARIALN.TTF"
      elseif fontValue == "morpheus" then
        fontPath = "Fonts\\MORPHEUS.TTF"
      elseif fontValue == "skurri" then
        fontPath = "Fonts\\SKURRI.TTF"
      elseif fontValue:sub(1, 4) == "lsm:" then
        local lsmFontName = fontValue:sub(5)
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
          local lsmPath = LSM:Fetch("font", lsmFontName)
          if lsmPath then
            fontPath = lsmPath
          end
        end
      else
        fontPath = fontValue
      end
    end
    if profile.globalOutline ~= nil then
      fontOutline = profile.globalOutline
    end
  end
  return fontPath, fontOutline
end
local function FitTextToBar(textObj, barWidth, baseScale, padding, barHeight)
  padding = padding or 6
  textObj:SetScale(baseScale)
  local textWidth = textObj:GetStringWidth()
  if issecurevariable and issecretvalue and issecretvalue(textWidth) then
    return
  end
  textWidth = (textWidth or 0) * baseScale
  local availableWidth = barWidth - padding
  local fitScale = baseScale
  if textWidth > availableWidth and textWidth > 0 then
    fitScale = (availableWidth / textWidth) * baseScale
  end
  if barHeight and barHeight > 0 then
    local textHeight = textObj:GetStringHeight()
    if not (issecurevariable and issecretvalue and issecretvalue(textHeight)) then
      textHeight = (textHeight or 0) * fitScale
      if textHeight > barHeight - 2 then
        local heightScale = (barHeight - 2) / ((textObj:GetStringHeight() or 12) * baseScale) * baseScale
        if heightScale < fitScale then
          fitScale = heightScale
        end
      end
    end
  end
  if fitScale < baseScale * 0.3 then fitScale = baseScale * 0.3 end
  textObj:SetScale(fitScale)
end
addonTable.FitTextToBar = FitTextToBar
local HideBlizzBarPreviews, HideBlizzBarDragOverlays
local function HasVisibleBlizzBarContent(bar)
  if not bar then return false end
  if not bar:IsShown() then return false end
  local childCount = addonTable.CollectChildren(bar, State.tmpChildren)
  for i = 1, childCount do
    local child = State.tmpChildren[i]
    if child and child:IsShown() and child:GetWidth() > 5 then
      return true
    end
  end
  return false
end
local function CreateBlizzBarPreview(barType)
  if State.blizzBarPreviewFrames[barType] then return State.blizzBarPreviewFrames[barType] end
  local frame = CreateFrame("Frame", "CCMBlizzPreview" .. barType, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
  frame:SetBackdropBorderColor(1, 0.82, 0, 0.8)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)
  frame.barType = barType
  local function NormalizeHalf(v)
    return math.floor((tonumber(v) or 0) * 2 + 0.5) / 2
  end
  frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if profile then
      local x, y = self:GetCenter()
      local screenWidth = UIParent:GetWidth()
      local screenHeight = UIParent:GetHeight()
      local relX = x - screenWidth / 2
      local relY = y - screenHeight / 2
      relX = NormalizeHalf(relX)
      relY = NormalizeHalf(relY)
      local centered = false
      if barType == "buff" then centered = profile.standaloneBuffCentered == true
      elseif barType == "essential" then centered = profile.standaloneEssentialCentered == true
      elseif barType == "utility" then centered = profile.standaloneUtilityCentered == true end
      if centered then relX = 0 end
      if barType == "buff" then
        profile.blizzBarBuffX = relX
        profile.blizzBarBuffY = relY
        profile.standaloneBuffY = relY
        if addonTable.standalone and addonTable.standalone.buffYSlider then
          addonTable.standalone.buffYSlider:SetValue(relY)
        end
      elseif barType == "essential" then
        profile.blizzBarEssentialX = relX
        profile.blizzBarEssentialY = relY
        profile.standaloneEssentialY = relY
        if addonTable.standalone and addonTable.standalone.essentialYSlider then
          addonTable.standalone.essentialYSlider:SetValue(relY)
        end
      elseif barType == "utility" then
        profile.blizzBarUtilityX = relX
        profile.blizzBarUtilityY = relY
        profile.standaloneUtilityY = relY
        if addonTable.standalone and addonTable.standalone.utilityYSlider then
          addonTable.standalone.utilityYSlider:SetValue(relY)
        end
      end
      if centered then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, relY)
      end
      if addonTable.UpdateStandaloneBlizzardBars then
        addonTable.UpdateStandaloneBlizzardBars()
      end
    end
  end)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("CENTER", frame, "CENTER", 0, 0)
  local displayName = "Buff Bar"
  if barType == "essential" then displayName = "Essential Bar"
  elseif barType == "utility" then displayName = "Utility Bar" end
  label:SetText("|cffffcc00" .. displayName .. "|r\n|cff888888(Hidden - Drag to move)|r")
  label:SetJustifyH("CENTER")
  frame.label = label
  frame:Hide()
  State.blizzBarPreviewFrames[barType] = frame
  return frame
end
local function UpdateBlizzBarPreview(barType, profile)
  local frame = CreateBlizzBarPreview(barType)
  if not frame or not profile then return end
  local iconSize, posX, posY = 45, 0, 0
  if barType == "buff" then
    local centered = profile.standaloneBuffCentered == true
    iconSize = type(profile.standaloneBuffSize) == "number" and profile.standaloneBuffSize or 45
    posX = centered and 0 or (profile.blizzBarBuffX or 0)
    posY = profile.blizzBarBuffY or (profile.standaloneBuffY or 0)
  elseif barType == "essential" then
    local centered = profile.standaloneEssentialCentered == true
    iconSize = type(profile.standaloneEssentialSize) == "number" and profile.standaloneEssentialSize or 45
    posX = centered and 0 or (profile.blizzBarEssentialX or 0)
    posY = profile.blizzBarEssentialY or (profile.standaloneEssentialY or 50)
  elseif barType == "utility" then
    local centered = profile.standaloneUtilityCentered == true
    iconSize = type(profile.standaloneUtilitySize) == "number" and profile.standaloneUtilitySize or 45
    posX = centered and 0 or (profile.blizzBarUtilityX or 0)
    posY = profile.blizzBarUtilityY or (profile.standaloneUtilityY or -50)
  end
  frame:SetSize(iconSize * 3 + 20, iconSize + 10)
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
  return frame
end
local function ShowBlizzBarPreviews()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if not HasVisibleBlizzBarContent(BuffIconCooldownViewer) then
    local preview = UpdateBlizzBarPreview("buff", profile)
    if preview then preview:Show() end
  end
  if not HasVisibleBlizzBarContent(EssentialCooldownViewer) then
    local preview = UpdateBlizzBarPreview("essential", profile)
    if preview then preview:Show() end
  end
  if not HasVisibleBlizzBarContent(UtilityCooldownViewer) then
    local preview = UpdateBlizzBarPreview("utility", profile)
    if preview then preview:Show() end
  end
end
HideBlizzBarPreviews = function()
  for _, frame in pairs(State.blizzBarPreviewFrames) do
    if frame then frame:Hide() end
  end
end
addonTable.ShowBlizzBarPreviews = ShowBlizzBarPreviews
addonTable.HideBlizzBarPreviews = HideBlizzBarPreviews
addonTable.UpdateBlizzBarPreview = UpdateBlizzBarPreview
local function CreateBlizzBarDragOverlay(barType, targetBar)
  if State.blizzBarDragOverlays[barType] then return State.blizzBarDragOverlays[barType] end
  local frame = CreateFrame("Frame", "CCMBlizzDrag" .. barType, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
  frame:SetBackdropBorderColor(1, 0.82, 0, 0.8)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)
  frame.barType = barType
  local function NormalizeHalf(v)
    return math.floor((tonumber(v) or 0) * 2 + 0.5) / 2
  end
  frame.targetBar = targetBar
  frame.clickStartTime = 0
  frame.clickStartX = 0
  frame.clickStartY = 0
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self.clickStartTime = GetTime()
      self.clickStartX, self.clickStartY = GetCursorPosition()
      self.wasDragged = false
    end
  end)
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      local endX, endY = GetCursorPosition()
      local dx = math.abs(endX - self.clickStartX)
      local dy = math.abs(endY - self.clickStartY)
      local elapsed = GetTime() - self.clickStartTime
      if not self.wasDragged and dx < 10 and dy < 10 and elapsed < 0.5 then
        if addonTable.SwitchToTab then
          addonTable.SwitchToTab(6)
          C_Timer.After(0.05, function()
            if addonTable.HighlightCustomBar then
              addonTable.HighlightCustomBar(6)
            end
          end)
        end
      end
    end
  end)
  frame:SetScript("OnDragStart", function(self)
    self.wasDragged = true
    self:StartMoving()
    if self.targetBar and self.targetBar:IsShown() then
      pcall(function()
        self.targetBar:SetMovable(true)
        self.targetBar:StartMoving()
      end)
    end
    local highlightIndex = 1
    if barType == "essential" then highlightIndex = 2
    elseif barType == "utility" then highlightIndex = 3 end
    self:SetScript("OnUpdate", function(s)
      local highlight = State.highlightFrames[highlightIndex]
      if highlight and highlight:IsShown() then
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", s, "TOPLEFT", -4, 4)
        highlight:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 4, -4)
      end
    end)
  end)
  frame:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:StopMovingOrSizing()
    if self.targetBar then
      pcall(function()
        self.targetBar:StopMovingOrSizing()
        self.targetBar:SetMovable(false)
      end)
    end
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if profile then
      local x, y = self:GetCenter()
      local screenWidth = UIParent:GetWidth()
      local screenHeight = UIParent:GetHeight()
      local relX = x - screenWidth / 2
      local relY = y - screenHeight / 2
      relX = NormalizeHalf(relX)
      relY = NormalizeHalf(relY)
      local centered = false
      if barType == "buff" then centered = profile.standaloneBuffCentered == true
      elseif barType == "essential" then centered = profile.standaloneEssentialCentered == true
      elseif barType == "utility" then centered = profile.standaloneUtilityCentered == true end
      if centered then relX = 0 end
      if barType == "buff" then
        profile.blizzBarBuffX = relX
        profile.blizzBarBuffY = relY
        profile.standaloneBuffY = relY
        if addonTable.standalone and addonTable.standalone.buffYSlider then
          addonTable.standalone.buffYSlider:SetValue(relY)
        end
      elseif barType == "essential" then
        profile.blizzBarEssentialX = relX
        profile.blizzBarEssentialY = relY
        profile.standaloneEssentialY = relY
        if addonTable.standalone and addonTable.standalone.essentialYSlider then
          addonTable.standalone.essentialYSlider:SetValue(relY)
        end
      elseif barType == "utility" then
        profile.blizzBarUtilityX = relX
        profile.blizzBarUtilityY = relY
        profile.standaloneUtilityY = relY
        if addonTable.standalone and addonTable.standalone.utilityYSlider then
          addonTable.standalone.utilityYSlider:SetValue(relY)
        end
      end
      if centered then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, relY)
        if self.targetBar then
          pcall(function()
            self.targetBar:ClearAllPoints()
            self.targetBar:SetPoint("CENTER", UIParent, "CENTER", 0, relY)
          end)
        end
      end
      if addonTable.UpdateStandaloneBlizzardBars then
        addonTable.UpdateStandaloneBlizzardBars()
      end
    end
  end)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("BOTTOM", frame, "TOP", 0, 4)
  local displayName = "Buff Bar"
  if barType == "essential" then displayName = "Essential Bar"
  elseif barType == "utility" then displayName = "Utility Bar" end
  label:SetText("|cffffcc00" .. displayName .. " - Drag to move|r")
  frame.label = label
  frame:Hide()
  State.blizzBarDragOverlays[barType] = frame
  return frame
end
local function ShowBlizzBarDragOverlays(showHighlight)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if not State.guiIsOpen then return end
  local currentTab = addonTable.activeTab and addonTable.activeTab()
  if currentTab ~= 6 then HideBlizzBarDragOverlays(); return end
  HideBlizzBarPreviews()
  local function showOverlay(barType, bar, defaultY, defaultX)
    local overlay = State.blizzBarDragOverlays[barType]
    if not overlay then
      overlay = CreateBlizzBarDragOverlay(barType, bar)
    end
    if overlay then 
      overlay.targetBar = bar
      local hasContent = bar and bar:IsShown() and HasVisibleBlizzBarContent(bar)
      if hasContent then
        local childCount = addonTable.CollectChildren(bar, State.tmpChildren)
        local minX, maxX, minY, maxY = nil, nil, nil, nil
        local visibleCount = 0
        for i = 1, childCount do
          local child = State.tmpChildren[i]
          if child and child:IsShown() and child:GetWidth() > 5 then
            visibleCount = visibleCount + 1
            local left = child:GetLeft()
            local right = child:GetRight()
            local top = child:GetTop()
            local bottom = child:GetBottom()
            if left and right and top and bottom then
              if not minX or left < minX then minX = left end
              if not maxX or right > maxX then maxX = right end
              if not minY or bottom < minY then minY = bottom end
              if not maxY or top > maxY then maxY = top end
            end
          end
        end
        if minX and maxX and minY and maxY and visibleCount > 0 then
          local width = maxX - minX
          local height = maxY - minY + 20
          if width < 30 then width = 120 end
          if height < 30 then height = 50 end
          overlay:SetSize(width, height)
          overlay:ClearAllPoints()
          local centerX = (minX + maxX) / 2
          local centerY = (minY + maxY) / 2
          overlay:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
        else
          local width, height = bar:GetSize()
          if width < 30 then width = 120 end
          if height < 30 then height = 50 end
          height = height + 20
          overlay:SetSize(width, height)
          overlay:ClearAllPoints()
          overlay:SetPoint("CENTER", bar, "CENTER", 0, 0)
        end
      else
        overlay:SetSize(120, 70)
        overlay:ClearAllPoints()
        local yKey = "blizzBar" .. barType:sub(1,1):upper() .. barType:sub(2) .. "Y"
        local xKey = "blizzBar" .. barType:sub(1,1):upper() .. barType:sub(2) .. "X"
        local yPos = profile[yKey] or defaultY
        local xPos = profile[xKey] or defaultX
        local centered = false
        if barType == "buff" then centered = profile.standaloneBuffCentered == true
        elseif barType == "essential" then centered = profile.standaloneEssentialCentered == true
        elseif barType == "utility" then centered = profile.standaloneUtilityCentered == true end
        if centered then xPos = 0 end
        overlay:SetPoint("CENTER", UIParent, "CENTER", xPos, yPos)
      end
      if showHighlight then
        overlay:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        overlay:SetBackdropBorderColor(1, 0.82, 0, 0.8)
        if overlay.label then overlay.label:Show() end
      else
        overlay:SetBackdropColor(0, 0, 0, 0)
        overlay:SetBackdropBorderColor(0, 0, 0, 0)
        if overlay.label then overlay.label:Hide() end
      end
      overlay:Show() 
    end
  end
  if not profile.useBuffBar then
    showOverlay("buff", BuffIconCooldownViewer, 0, -150)
  end
  if not profile.useEssentialBar then
    showOverlay("essential", EssentialCooldownViewer, 0, 0)
  end
  showOverlay("utility", UtilityCooldownViewer, 0, 150)
end
HideBlizzBarDragOverlays = function()
  for _, frame in pairs(State.blizzBarDragOverlays) do
    if frame then frame:Hide() end
  end
end
addonTable.ShowBlizzBarDragOverlays = ShowBlizzBarDragOverlays
addonTable.HideBlizzBarDragOverlays = HideBlizzBarDragOverlays
local function SetupBlizzBarClickHandlers()
  if State.guiIsOpen then
    ShowBlizzBarDragOverlays(false)
  end
  State.blizzBarClickHandlersSetup = true
end
addonTable.SetupBlizzBarClickHandlers = SetupBlizzBarClickHandlers
local function CreateHighlightFrame(index)
  if State.highlightFrames[index] then return State.highlightFrames[index] end
  local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("FULLSCREEN")
  frame:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
  frame:SetBackdropBorderColor(1, 0.82, 0, 1)
  frame:Hide()
  State.highlightFrames[index] = frame
  return frame
end
local function HideAllHighlights()
  for _, frame in pairs(State.highlightFrames) do
    frame:Hide()
  end
  HideBlizzBarPreviews()
  if customBarFrame and customBarFrame.highlightVisible then
    customBarFrame.highlightVisible = nil
    customBarFrame:Hide()
  end
  if customBar2Frame and customBar2Frame.highlightVisible then
    customBar2Frame.highlightVisible = nil
    customBar2Frame:Hide()
  end
  if customBar3Frame and customBar3Frame.highlightVisible then
    customBar3Frame.highlightVisible = nil
    customBar3Frame:Hide()
  end
  if customBar4Frame and customBar4Frame.highlightVisible then
    customBar4Frame.highlightVisible = nil
    customBar4Frame:Hide()
  end
  if customBar5Frame and customBar5Frame.highlightVisible then
    customBar5Frame.highlightVisible = nil
    customBar5Frame:Hide()
  end
  if addonTable.PRBFrame and addonTable.PRBFrame.highlightVisible then
    addonTable.PRBFrame.highlightVisible = nil
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if not profile or not profile.usePersonalResourceBar then
      addonTable.PRBFrame:Hide()
    end
  end
  if State.guiIsOpen then
    ShowBlizzBarDragOverlays(false)
  end
end
local function HighlightFrame(index, targetFrame)
  if not targetFrame then return end
  local highlight = CreateHighlightFrame(index)
  highlight:ClearAllPoints()
  highlight:SetPoint("TOPLEFT", targetFrame, "TOPLEFT", -4, 14)
  highlight:SetPoint("BOTTOMRIGHT", targetFrame, "BOTTOMRIGHT", 4, -14)
  highlight:Show()
end
local function HighlightCustomBar(tabIdx)
  HideAllHighlights()
  if State.highlightsDisabled then return end
  if tabIdx == 3 then
    if customBarFrame then
      if not customBarFrame:IsShown() then
        customBarFrame:SetSize(100, 50)
        customBarFrame:Show()
        customBarFrame.highlightVisible = true
      end
      HighlightFrame(1, customBarFrame)
    end
  elseif tabIdx == 4 then
    if customBar2Frame then
      if not customBar2Frame:IsShown() then
        customBar2Frame:SetSize(100, 50)
        customBar2Frame:Show()
        customBar2Frame.highlightVisible = true
      end
      HighlightFrame(1, customBar2Frame)
    end
  elseif tabIdx == 5 then
    if customBar3Frame then
      if not customBar3Frame:IsShown() then
        customBar3Frame:SetSize(100, 50)
        customBar3Frame:Show()
        customBar3Frame.highlightVisible = true
      end
      HighlightFrame(1, customBar3Frame)
    end
  elseif tabIdx == 20 then
    if customBar4Frame then
      if not customBar4Frame:IsShown() then
        customBar4Frame:SetSize(100, 50)
        customBar4Frame:Show()
        customBar4Frame.highlightVisible = true
      end
      HighlightFrame(1, customBar4Frame)
    end
  elseif tabIdx == 21 then
    if customBar5Frame then
      if not customBar5Frame:IsShown() then
        customBar5Frame:SetSize(100, 50)
        customBar5Frame:Show()
        customBar5Frame.highlightVisible = true
      end
      HighlightFrame(1, customBar5Frame)
    end
  elseif tabIdx == 6 then
    ShowBlizzBarDragOverlays(true)
  elseif tabIdx == 7 then
    if addonTable.PRBFrame then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile and profile.usePersonalResourceBar then
        if not addonTable.PRBFrame:IsShown() then
          addonTable.PRBFrame:SetSize(220, 30)
          addonTable.PRBFrame:Show()
          addonTable.PRBFrame.highlightVisible = true
        end
        local minY, maxY = 0, 0
        local width = profile.prbWidth or 220
        local autoWidthSource = profile.prbAutoWidthSource or "off"
        if autoWidthSource ~= "off" then
          if autoWidthSource == "essential" then
            local essBar = EssentialCooldownViewer
            if essBar and essBar:IsShown() then
              local childCount = addonTable.CollectChildren(essBar, State.tmpChildren)
              local minX, maxX = nil, nil
              for i = 1, childCount do
                local child = State.tmpChildren[i]
                if child and child:IsShown() and child:GetWidth() > 5 then
                  local left = child:GetLeft()
                  local right = child:GetRight()
                  if left and right then
                    if not minX or left < minX then minX = left end
                    if not maxX or right > maxX then maxX = right end
                  end
                end
              end
              if minX and maxX then
                width = maxX - minX
              end
            end
          elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" or autoWidthSource == "cbar4" or autoWidthSource == "cbar5" then
            local barNum = tonumber(string.sub(autoWidthSource, 5, 5)) or 1
            local prefix = barNum == 1 and "customBar" or ("customBar" .. barNum)
            local cbarWidth = profile[prefix .. "IconSize"] or 28
            local cbarSpacing = type(profile[prefix .. "Spacing"]) == "number" and profile[prefix .. "Spacing"] or 2
            local cbarCount = 0
            local getSpellsFunc = barNum == 1 and addonTable.GetCustomBarSpells or addonTable["GetCustomBar" .. barNum .. "Spells"]
            if getSpellsFunc then
              local spells = getSpellsFunc()
              if spells then cbarCount = #spells end
            end
            if cbarCount > 0 then
              width = (cbarWidth * cbarCount) + (cbarSpacing * (cbarCount - 1))
            end
          end
        end
        local healthHeight = profile.prbHealthHeight or 18
        local powerHeight = profile.prbPowerHeight or 8
        local manaHeight = profile.prbManaHeight or 6
        local spacing = profile.prbSpacing or 0
        local healthYOffset = profile.prbHealthYOffset or 0
        local powerYOffset = profile.prbPowerYOffset or 0
        local manaYOffset = profile.prbManaYOffset or 0
        local clampBars = profile.prbClampBars == true
        if clampBars then
          healthYOffset = 0
          powerYOffset = 0
          manaYOffset = 0
        end
        local showHealth = profile.prbShowHealth == true
        local showPower = profile.prbShowPower == true
        local showManaBar = profile.prbShowManaBar == true
        local yOff = 0
        local barPositions = {}
        if showHealth then
          local barTop = -yOff + healthYOffset
          local barBottom = barTop - healthHeight
          table.insert(barPositions, {top = barTop, bottom = barBottom})
          if showPower then yOff = yOff + healthHeight + spacing else yOff = yOff + healthHeight end
        end
        if showPower then
          local barTop = -yOff + powerYOffset
          local barBottom = barTop - powerHeight
          table.insert(barPositions, {top = barTop, bottom = barBottom})
          yOff = yOff + powerHeight
        end
        if showManaBar and (showHealth or showPower) then
          yOff = yOff + spacing
          local barTop = -yOff + manaYOffset
          local barBottom = barTop - manaHeight
          table.insert(barPositions, {top = barTop, bottom = barBottom})
        end
        if #barPositions > 0 then
          maxY = barPositions[1].top
          minY = barPositions[1].bottom
          for _, pos in ipairs(barPositions) do
            if pos.top > maxY then maxY = pos.top end
            if pos.bottom < minY then minY = pos.bottom end
          end
        end
        local highlightHeight = maxY - minY + 8
        local highlight = CreateHighlightFrame(1)
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", addonTable.PRBFrame, "TOPLEFT", -14, maxY + 14)
        highlight:SetPoint("BOTTOMRIGHT", addonTable.PRBFrame, "TOPLEFT", width + 14, minY - 24)
        highlight:Show()
      end
    end
  elseif tabIdx == 8 then
    if addonTable.CastbarFrame and not addonTable.CastbarFrame:IsShown() then
      if addonTable.ShowCastbarPreview then addonTable.ShowCastbarPreview() end
    end
    if addonTable.CastbarFrame then
      HighlightFrame(1, addonTable.CastbarFrame)
    end
  elseif tabIdx == 9 then
    if addonTable.FocusCastbarFrame and not addonTable.FocusCastbarFrame:IsShown() then
      if addonTable.ShowFocusCastbarPreview then addonTable.ShowFocusCastbarPreview() end
    end
    if addonTable.FocusCastbarFrame then
      HighlightFrame(1, addonTable.FocusCastbarFrame)
    end
  elseif tabIdx == 13 then
    if addonTable.TargetCastbarFrame and not addonTable.TargetCastbarFrame:IsShown() then
      if addonTable.ShowTargetCastbarPreview then addonTable.ShowTargetCastbarPreview() end
    end
    if addonTable.TargetCastbarFrame then
      HighlightFrame(1, addonTable.TargetCastbarFrame)
    end
  elseif tabIdx == 10 then
    if not addonTable.DebuffFrame or not addonTable.DebuffFrame:IsShown() then
      if addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
    end
    if addonTable.DebuffFrame then
      local minX, maxX, minY, maxY
      local frameLeft, frameRight = addonTable.DebuffFrame:GetLeft(), addonTable.DebuffFrame:GetRight()
      local frameBottom, frameTop = addonTable.DebuffFrame:GetBottom(), addonTable.DebuffFrame:GetTop()
      if frameLeft and frameRight and frameBottom and frameTop then
        for i = 1, 16 do
          local icon = addonTable.DebuffIcons[i]
          if icon and icon:IsShown() then
            local l, r = icon:GetLeft(), icon:GetRight()
            local b, t = icon:GetBottom(), icon:GetTop()
            if l and r and b and t then
              local relL = l - frameLeft
              local relR = r - frameLeft
              local relB = b - frameBottom
              local relT = t - frameBottom
              if not minX or relL < minX then minX = relL end
              if not maxX or relR > maxX then maxX = relR end
              if not minY or relB < minY then minY = relB end
              if not maxY or relT > maxY then maxY = relT end
            end
          end
        end
      end
      if minX and maxX and minY and maxY then
        local highlight = CreateHighlightFrame(1)
        highlight:ClearAllPoints()
        highlight:SetPoint("BOTTOMLEFT", addonTable.DebuffFrame, "BOTTOMLEFT", minX - 4, minY - 4)
        highlight:SetPoint("TOPRIGHT", addonTable.DebuffFrame, "BOTTOMLEFT", maxX + 4, maxY + 4)
        highlight:Show()
      else
        HighlightFrame(1, addonTable.DebuffFrame)
      end
    end
  end
end
addonTable.HighlightCustomBar = HighlightCustomBar
addonTable.highlightToggleBtns = {}
local function SyncHighlightButtons()
  local label = State.highlightsDisabled and "Highlight On" or "Highlight Off"
  for _, btn in ipairs(addonTable.highlightToggleBtns) do
    if btn and btn.text then btn.text:SetText(label) end
  end
end
addonTable.ToggleHighlights = function()
  State.highlightsDisabled = not State.highlightsDisabled
  SyncHighlightButtons()
  if State.highlightsDisabled then
    HideAllHighlights()
  else
    local currentTab = addonTable.activeTab and addonTable.activeTab()
    if currentTab then HighlightCustomBar(currentTab) end
  end
end
addonTable.GetDefaults = function() return defaults end
addonTable.GetIcons = function() return State.cursorIcons end
local READY_GLOW_KEY = "CCMReady"
local function NormalizeGlowType(glowType)
  local value = type(glowType) == "string" and string.lower(glowType) or ""
  if value == "blizzard" or value == "pixel" or value == "autocast" or value == "proc" then
    return value
  end
  return "pixel"
end
local function StopReadyGlow(icon)
  if not icon or not icon._ccmReadyGlowStyle then return end
  local style = icon._ccmReadyGlowStyle
  if style == "blizzard" then
    LibButtonGlow.HideOverlayGlow(icon)
  elseif style == "pixel" then
    LibCustomGlow.PixelGlow_Stop(icon, READY_GLOW_KEY)
  elseif style == "autocast" then
    LibCustomGlow.AutoCastGlow_Stop(icon, READY_GLOW_KEY)
  elseif style == "proc" then
    LibCustomGlow.ProcGlow_Stop(icon, READY_GLOW_KEY)
  end
  icon._ccmReadyGlowStyle = nil
  icon._ccmReadyGlowParamsKey = nil
end
local function RefreshGlowParams()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local speed = profile and tonumber(profile.spellGlowSpeed) or 0
  local thickness = profile and tonumber(profile.spellGlowThickness) or 2
  if type(speed) ~= "number" then speed = 0 end
  if type(thickness) ~= "number" then thickness = 2 end
  if speed < 0.0 then speed = 0.0 end
  if speed > 4.0 then speed = 4.0 end
  if thickness < 0.1 then thickness = 0.1 end
  if thickness > 4.0 then thickness = 4.0 end
  local effectiveSpeed = 0.15 + (speed * 0.9625)
  if effectiveSpeed < 0.15 then effectiveSpeed = 0.15 end
  if effectiveSpeed > 4.0 then effectiveSpeed = 4.0 end
  local key = string.format("%.1f_%.1f", speed, thickness)
  if State._glowParamsKey == key then return end
  State._glowParamsKey = key
  State._glowThickness = thickness
  State._glowEffectiveSpeed = effectiveSpeed
end
local function StartReadyGlow(icon, glowType)
  if not icon then return end
  if icon._ccmHiddenByScale then return end
  local style = NormalizeGlowType(glowType)
  if icon._ccmReadyGlowStyle == style and icon._ccmReadyGlowParamsKey == State._glowParamsKey then
    return
  end
  StopReadyGlow(icon)
  local thickness = State._glowThickness or 2
  local effectiveSpeed = State._glowEffectiveSpeed or 1
  if style == "blizzard" then
    LibButtonGlow.ShowOverlayGlow(icon)
  elseif style == "pixel" then
    local alpha = 0.2 + (thickness * 0.35)
    if alpha > 1 then alpha = 1 end
    local color = {1, 0.82, 0, alpha}
    local lines = math.max(4, math.floor(5 + thickness * 2 + 0.5))
    local frequency = 0.45 + effectiveSpeed * 0.75
    local lineThickness = 0.1 + thickness * 1.1
    LibCustomGlow.PixelGlow_Start(icon, color, lines, frequency, nil, lineThickness, 0, 0, false, READY_GLOW_KEY, 8)
  elseif style == "autocast" then
    local alpha = 0.2 + (thickness * 0.35)
    if alpha > 1 then alpha = 1 end
    local color = {1, 0.82, 0, alpha}
    local frequency = 0.45 + effectiveSpeed * 0.75
    local scale = 0.1 + thickness * 1.1
    LibCustomGlow.AutoCastGlow_Start(icon, color, 4, frequency, scale, 0, 0, READY_GLOW_KEY, 8)
  elseif style == "proc" then
    local duration = 1.3 - (effectiveSpeed * 0.35)
    if duration < 0.5 then duration = 0.5 end
    local spread = (thickness - 1.0) * 2.2
    if spread < 0 then spread = 0 end
    LibCustomGlow.ProcGlow_Start(icon, { key = READY_GLOW_KEY, duration = duration, startAnim = false, frameLevel = 8, xOffset = spread, yOffset = spread })
  end
  icon._ccmReadyGlowStyle = style
  icon._ccmReadyGlowParamsKey = State._glowParamsKey
end
local function SetGlowIdentityMethods(icon)
  if not icon then return end
  if icon.GetSpellId == nil then
    icon.GetSpellId = function(self)
      if self.isItem then return nil end
      return self.actualID or self.spellID
    end
  end
end
local function HideIconByScale(icon)
  StopReadyGlow(icon)
  icon._ccmHiddenByScale = true
  icon:SetScale(0.0001)
  icon:SetAlpha(0)
  icon:Show()
end
local function EnsureIconRestored(icon)
  if icon._ccmHiddenByScale then
    icon._ccmHiddenByScale = false
    icon._ccmReadyGlowStyle = nil
    icon._ccmReadyGlowParamsKey = nil
    icon:Show()
    icon:SetScale(1)
    icon:SetAlpha(1)
  end
end
addonTable.ApplyConfigPreviewCountdown = function(cooldownFrame, cdTextScale, inCombat)
  if not cooldownFrame then return end
  if type(cdTextScale) ~= "number" or cdTextScale <= 0 then return end
  local startTime = GetTime() - 2
  if inCombat then
    pcall(cooldownFrame.SetCooldown, cooldownFrame, startTime, 12)
  else
    cooldownFrame:SetCooldown(startTime, 12)
  end
  cooldownFrame:SetDrawSwipe(true)
  cooldownFrame:SetHideCountdownNumbers(false)
  cooldownFrame._ccmConfigPreviewActive = true
end
addonTable.ClearConfigPreviewCountdowns = function()
  local function ClearIconPreview(icon)
    if not icon then return end
    local cd = icon.cooldown or icon.Cooldown or icon.ccmCooldown
    if cd and cd._ccmConfigPreviewActive then
      cd._ccmConfigPreviewActive = nil
      if cd.Clear then
        pcall(cd.Clear, cd)
      elseif cd.SetCooldown then
        pcall(cd.SetCooldown, cd, 0, 0)
      end
    end
  end
  for _, icon in ipairs(State.cursorIcons or {}) do
    ClearIconPreview(icon)
  end
  for _, icon in ipairs(State.customBar1Icons or {}) do
    ClearIconPreview(icon)
  end
  for _, icon in ipairs(State.customBar2Icons or {}) do
    ClearIconPreview(icon)
  end
  for _, icon in ipairs(State.customBar3Icons or {}) do
    ClearIconPreview(icon)
  end
  for _, icon in ipairs(State.customBar4Icons or {}) do
    ClearIconPreview(icon)
  end
  for _, icon in ipairs(State.customBar5Icons or {}) do
    ClearIconPreview(icon)
  end
  if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
  if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
  if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
  if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
  if addonTable.UpdateCustomBar4 then addonTable.UpdateCustomBar4() end
  if addonTable.UpdateCustomBar5 then addonTable.UpdateCustomBar5() end
end
addonTable.ShowCursorIconPreview = function()
  State.cursorIconPreviewActive = true
  for _, icon in ipairs(State.cursorIcons) do
    if not icon._ccmPreviewSaved then
      icon._ccmPreviewSaved = true
      icon._ccmPreviewStrata = icon:GetFrameStrata()
      icon._ccmPreviewLevel = icon:GetFrameLevel()
      icon._ccmPreviewWasHidden = icon._ccmHiddenByScale
    end
    icon:SetFrameStrata("TOOLTIP")
    icon:SetFrameLevel(9999)
    EnsureIconRestored(icon)
  end
end
addonTable.StopCursorIconPreview = function()
  if not State.cursorIconPreviewActive then return end
  State.cursorIconPreviewActive = false
  for _, icon in ipairs(State.cursorIcons) do
    if icon._ccmPreviewSaved then
      icon:SetFrameStrata(icon._ccmPreviewStrata or "MEDIUM")
      icon:SetFrameLevel(icon._ccmPreviewLevel or 1)
      if icon._ccmPreviewWasHidden then HideIconByScale(icon) end
      icon._ccmPreviewSaved = nil
      icon._ccmPreviewStrata = nil
      icon._ccmPreviewLevel = nil
      icon._ccmPreviewWasHidden = nil
    end
  end
end
addonTable.SetGUIOpen = function(open) 
  State.guiIsOpen = open
  if not open and addonTable.ClearConfigPreviewCountdowns then
    addonTable.ClearConfigPreviewCountdowns()
  end
  local rf = addonTable.ringFrame
  if rf then
    if not State.ringFrameOriginalStrata then
      State.ringFrameOriginalStrata = rf:GetFrameStrata()
      State.ringFrameOriginalLevel = rf:GetFrameLevel()
    end
    if open then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile and profile.showRadialCircle then
        local cfg = addonTable.ConfigFrame
        if cfg then
          rf:SetFrameStrata(cfg:GetFrameStrata() or "TOOLTIP")
          rf:SetFrameLevel((cfg:GetFrameLevel() or 1) + 50)
        else
          rf:SetFrameStrata("TOOLTIP")
          rf:SetFrameLevel(5000)
        end
        rf:Show()
      end
    else
      if State.ringFrameOriginalStrata then
        rf:SetFrameStrata(State.ringFrameOriginalStrata)
      end
      if State.ringFrameOriginalLevel then
        rf:SetFrameLevel(State.ringFrameOriginalLevel)
      end
    end
  end
  if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
  if open then
    if customBarFrame then customBarFrame:SetMovable(true) end
    if customBar2Frame then customBar2Frame:SetMovable(true) end
    if customBar3Frame then customBar3Frame:SetMovable(true) end
    if customBar4Frame then customBar4Frame:SetMovable(true) end
    if customBar5Frame then customBar5Frame:SetMovable(true) end
    if addonTable.PRBFrame then addonTable.PRBFrame:SetMovable(true) end
    if addonTable.CastbarFrame then addonTable.CastbarFrame:SetMovable(true) end
    if addonTable.FocusCastbarFrame then addonTable.FocusCastbarFrame:SetMovable(true) end
    if addonTable.TargetCastbarFrame then addonTable.TargetCastbarFrame:SetMovable(true) end
    local function updateOverlays()
      if State.guiIsOpen then
        ShowBlizzBarDragOverlays(false)
      end
    end
    C_Timer.After(0.1, updateOverlays)
    C_Timer.After(0.5, updateOverlays)
    C_Timer.After(1.0, updateOverlays)
    C_Timer.After(2.0, updateOverlays)
  else
    if customBarFrame then customBarFrame:SetMovable(false) end
    if customBar2Frame then customBar2Frame:SetMovable(false) end
    if customBar3Frame then customBar3Frame:SetMovable(false) end
    if customBar4Frame then customBar4Frame:SetMovable(false) end
    if customBar5Frame then customBar5Frame:SetMovable(false) end
    if addonTable.PRBFrame then addonTable.PRBFrame:SetMovable(false) end
    if addonTable.CastbarFrame then addonTable.CastbarFrame:SetMovable(false) end
    if addonTable.FocusCastbarFrame then addonTable.FocusCastbarFrame:SetMovable(false) end
    if addonTable.TargetCastbarFrame then addonTable.TargetCastbarFrame:SetMovable(false) end
    HideAllHighlights()
    HideBlizzBarPreviews()
    HideBlizzBarDragOverlays()
    State.highlightsDisabled = false
    SyncHighlightButtons()
  end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
end
addonTable.GetGUIOpen = function() return State.guiIsOpen end
local function DeepCopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = DeepCopy(orig_value)
    end
  else
    copy = orig
  end
  return copy
end
local function ApplyDefaults()
  CooldownCursorManagerDB = CooldownCursorManagerDB or {}
  if not CooldownCursorManagerDB.profiles then
    CooldownCursorManagerDB.profiles = DeepCopy(defaults.profiles)
  end
  if not CooldownCursorManagerDB.profiles.Default then
    CooldownCursorManagerDB.profiles.Default = DeepCopy(defaults.profiles.Default)
  end
  if not CooldownCursorManagerDB.currentProfile then
    CooldownCursorManagerDB.currentProfile = defaults.currentProfile
  end
  if not CooldownCursorManagerDB.characterProfiles then
    CooldownCursorManagerDB.characterProfiles = {}
  end
  if not CooldownCursorManagerDB.minimap then
    CooldownCursorManagerDB.minimap = DeepCopy(defaults.minimap)
  end
  if CooldownCursorManagerDB.minimap.hide == nil then
    CooldownCursorManagerDB.minimap.hide = true
  end
  if not CooldownCursorManagerDB.characterCustomBarSpells then
    CooldownCursorManagerDB.characterCustomBarSpells = {}
  end
  if not CooldownCursorManagerDB.characterCustomBarSpellsEnabled then
    CooldownCursorManagerDB.characterCustomBarSpellsEnabled = {}
  end
  if not CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled then
    CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled = {}
  end
  if not CooldownCursorManagerDB.characterCustomBarSpellGlowType then
    CooldownCursorManagerDB.characterCustomBarSpellGlowType = {}
  end
  if not CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled then
    CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled = {}
  end
  if not CooldownCursorManagerDB.characterCustomBar2SpellGlowType then
    CooldownCursorManagerDB.characterCustomBar2SpellGlowType = {}
  end
  if not CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled then
    CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled = {}
  end
  if not CooldownCursorManagerDB.characterCustomBar3SpellGlowType then
    CooldownCursorManagerDB.characterCustomBar3SpellGlowType = {}
  end
  if type(CooldownCursorManagerDB.moduleStates) ~= "table" then
    CooldownCursorManagerDB.moduleStates = {}
  end
  local ms = CooldownCursorManagerDB.moduleStates
  if ms.custombars == nil then ms.custombars = true end
  if ms.blizzcdm == nil then ms.blizzcdm = true end
  if ms.prb == nil then ms.prb = true end
  if ms.castbars == nil then ms.castbars = true end
  if ms.debuffs == nil then ms.debuffs = true end
  if ms.qol == nil then ms.qol = true end
end
local function MigrateOldCustomBarData()
  if not CooldownCursorManagerDB then return end
  local playerName = UnitName("player")
  local realmName = GetRealmName()
  if not playerName or not realmName then return end
  local charKey = playerName .. "-" .. realmName
  local specID = GetSpecialization() or 1
  local migrated = false
  if CooldownCursorManagerDB.profiles then
    for profileName, profile in pairs(CooldownCursorManagerDB.profiles) do
      if profile.customBarSpells and #profile.customBarSpells > 0 then
        CooldownCursorManagerDB.characterCustomBarSpells = CooldownCursorManagerDB.characterCustomBarSpells or {}
        CooldownCursorManagerDB.characterCustomBarSpells[charKey] = CooldownCursorManagerDB.characterCustomBarSpells[charKey] or {}
        if not CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] or #CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] == 0 then
          CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] = DeepCopy(profile.customBarSpells)
          if profile.customBarSpellsEnabled then
            CooldownCursorManagerDB.characterCustomBarSpellsEnabled = CooldownCursorManagerDB.characterCustomBarSpellsEnabled or {}
            CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] or {}
            CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID] = DeepCopy(profile.customBarSpellsEnabled)
          end
          migrated = true
        end
        profile.customBarSpells = nil
        profile.customBarSpellsEnabled = nil
      end
    end
  end
  if migrated then
    print("|cff00ff00CCM:|r Custom Bar data migrated to new per-spec storage. Your spells have been preserved!")
  end
end
addonTable.MigrateOldCustomBarData = MigrateOldCustomBarData
local function MigrateRenamedProfileKeys()
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then return end
  local keyMap = {
    useBiggerPlayerHealthframeClassColor = "ufClassColor",
    useBiggerPlayerHealthframeTexture = "ufHealthTexture",
    useBiggerPlayerHealthframeDisableGlows = "ufDisableGlows",
    useBiggerPlayerHealthframeDisableCombatText = "ufDisableCombatText",
  }
  for _, profile in pairs(CooldownCursorManagerDB.profiles) do
    for oldKey, newKey in pairs(keyMap) do
      if profile[oldKey] ~= nil and profile[newKey] == nil then
        profile[newKey] = profile[oldKey]
      end
      profile[oldKey] = nil
    end
  end
end
local function GetProfile()
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then
    return nil
  end
  local profile = CooldownCursorManagerDB.profiles[CooldownCursorManagerDB.currentProfile]
  if not profile then
    CooldownCursorManagerDB.currentProfile = "Default"
    profile = CooldownCursorManagerDB.profiles["Default"]
    if not profile then
      CooldownCursorManagerDB.profiles["Default"] = DeepCopy(defaults.profiles.Default)
      profile = CooldownCursorManagerDB.profiles["Default"]
    end
  end
  if type(profile.trackedSpellsBySpec) ~= "table" then profile.trackedSpellsBySpec = {} end
  if type(profile.spellsEnabledBySpec) ~= "table" then profile.spellsEnabledBySpec = {} end
  if type(profile.spellGlowEnabledBySpec) ~= "table" then profile.spellGlowEnabledBySpec = {} end
  if type(profile.spellGlowTypeBySpec) ~= "table" then profile.spellGlowTypeBySpec = {} end
  if type(profile.spellHideRevealThresholdsBySpec) ~= "table" then profile.spellHideRevealThresholdsBySpec = {} end
  profile.offsetX = profile.offsetX or defaults.profiles.Default.offsetX
  profile.offsetY = profile.offsetY or defaults.profiles.Default.offsetY
  profile.iconSize = profile.iconSize or defaults.profiles.Default.iconSize
  profile.iconSpacing = profile.iconSpacing or defaults.profiles.Default.iconSpacing
  profile.cdTextScale = profile.cdTextScale or defaults.profiles.Default.cdTextScale
  profile.stackTextScale = profile.stackTextScale or defaults.profiles.Default.stackTextScale
  profile.radialRadius = profile.radialRadius or defaults.profiles.Default.radialRadius
  profile.radialColorR = profile.radialColorR or defaults.profiles.Default.radialColorR
  profile.radialColorG = profile.radialColorG or defaults.profiles.Default.radialColorG
  profile.radialColorB = profile.radialColorB or defaults.profiles.Default.radialColorB
  profile.radialAlpha = profile.radialAlpha or defaults.profiles.Default.radialAlpha
  profile.radialThickness = profile.radialThickness or defaults.profiles.Default.radialThickness
  profile.layoutDirection = profile.layoutDirection or defaults.profiles.Default.layoutDirection
  profile.growDirection = profile.growDirection or defaults.profiles.Default.growDirection
  profile.iconsPerRow = profile.iconsPerRow or defaults.profiles.Default.iconsPerRow
  if profile.showInCombatOnly == nil then
    profile.showInCombatOnly = defaults.profiles.Default.showInCombatOnly
  end
  if profile.showRadialCircle == nil then
    profile.showRadialCircle = defaults.profiles.Default.showRadialCircle
  end
  if profile.showGCD == nil then
    profile.showGCD = defaults.profiles.Default.showGCD
  end
  if profile.enableUnitFrameCustomization == nil then
    profile.enableUnitFrameCustomization = defaults.profiles.Default.enableUnitFrameCustomization
  end
  if profile.ufCustomBorderColorR == nil then
    profile.ufCustomBorderColorR = profile.ufBorderPlayerColorR or defaults.profiles.Default.ufCustomBorderColorR
  end
  if profile.ufCustomBorderColorG == nil then
    profile.ufCustomBorderColorG = profile.ufBorderPlayerColorG or defaults.profiles.Default.ufCustomBorderColorG
  end
  if profile.ufCustomBorderColorB == nil then
    profile.ufCustomBorderColorB = profile.ufBorderPlayerColorB or defaults.profiles.Default.ufCustomBorderColorB
  end
  if profile.ufUseCustomNameColor == nil then profile.ufUseCustomNameColor = false end
  if profile.ufUseCustomTextures == nil then profile.ufUseCustomTextures = false end
  if profile.ufNameColorR == nil then profile.ufNameColorR = defaults.profiles.Default.ufNameColorR end
  if profile.ufNameColorG == nil then profile.ufNameColorG = defaults.profiles.Default.ufNameColorG end
  if profile.ufNameColorB == nil then profile.ufNameColorB = defaults.profiles.Default.ufNameColorB end
  if profile.combatTimerEnabled == nil then
    profile.combatTimerEnabled = defaults.profiles.Default.combatTimerEnabled
  end
  if type(profile.combatTimerMode) ~= "string" then
    profile.combatTimerMode = defaults.profiles.Default.combatTimerMode
  end
  if type(profile.combatTimerStyle) ~= "string" then
    profile.combatTimerStyle = defaults.profiles.Default.combatTimerStyle
  end
  if profile.combatTimerCentered == nil then
    profile.combatTimerCentered = defaults.profiles.Default.combatTimerCentered
  end
  if profile.combatTimerX == nil then profile.combatTimerX = defaults.profiles.Default.combatTimerX end
  if profile.combatTimerY == nil then profile.combatTimerY = defaults.profiles.Default.combatTimerY end
  if profile.combatTimerScale == nil then profile.combatTimerScale = defaults.profiles.Default.combatTimerScale end
  if profile.combatTimerTextColorR == nil then profile.combatTimerTextColorR = defaults.profiles.Default.combatTimerTextColorR end
  if profile.combatTimerTextColorG == nil then profile.combatTimerTextColorG = defaults.profiles.Default.combatTimerTextColorG end
  if profile.combatTimerTextColorB == nil then profile.combatTimerTextColorB = defaults.profiles.Default.combatTimerTextColorB end
  if profile.combatTimerBgColorR == nil then profile.combatTimerBgColorR = defaults.profiles.Default.combatTimerBgColorR end
  if profile.combatTimerBgColorG == nil then profile.combatTimerBgColorG = defaults.profiles.Default.combatTimerBgColorG end
  if profile.combatTimerBgColorB == nil then profile.combatTimerBgColorB = defaults.profiles.Default.combatTimerBgColorB end
  if profile.combatTimerBgAlpha == nil then profile.combatTimerBgAlpha = defaults.profiles.Default.combatTimerBgAlpha end
  if profile.crTimerEnabled == nil and profile.blcrTimerEnabled ~= nil then profile.crTimerEnabled = profile.blcrTimerEnabled end
  if type(profile.crTimerMode) ~= "string" and type(profile.blcrTimerMode) == "string" then profile.crTimerMode = profile.blcrTimerMode end
  if type(profile.crTimerLayout) ~= "string" and type(profile.blcrTimerLayout) == "string" then profile.crTimerLayout = profile.blcrTimerLayout end
  if profile.crTimerCentered == nil and profile.blcrTimerCentered ~= nil then profile.crTimerCentered = profile.blcrTimerCentered end
  if profile.crTimerX == nil and profile.blcrTimerX ~= nil then profile.crTimerX = profile.blcrTimerX end
  if profile.crTimerY == nil and profile.blcrTimerY ~= nil then profile.crTimerY = profile.blcrTimerY end
  if profile.crTimerEnabled == nil then profile.crTimerEnabled = defaults.profiles.Default.crTimerEnabled end
  if type(profile.crTimerMode) ~= "string" then profile.crTimerMode = defaults.profiles.Default.crTimerMode end
  if type(profile.crTimerLayout) ~= "string" then profile.crTimerLayout = defaults.profiles.Default.crTimerLayout end
  if profile.crTimerCentered == nil then profile.crTimerCentered = defaults.profiles.Default.crTimerCentered end
  if profile.crTimerX == nil then profile.crTimerX = defaults.profiles.Default.crTimerX end
  if profile.crTimerY == nil then profile.crTimerY = defaults.profiles.Default.crTimerY end
  if profile.crTimerScale == nil then profile.crTimerScale = defaults.profiles.Default.crTimerScale end
  if profile.standaloneEssentialSecondRowSize == nil then profile.standaloneEssentialSecondRowSize = defaults.profiles.Default.standaloneEssentialSecondRowSize end
  if profile.standaloneEssentialIconsPerRow == nil then profile.standaloneEssentialIconsPerRow = defaults.profiles.Default.standaloneEssentialIconsPerRow end
  if profile.standaloneEssentialMaxRows == nil then profile.standaloneEssentialMaxRows = defaults.profiles.Default.standaloneEssentialMaxRows end
  if type(profile.standaloneEssentialGrowDirection) ~= "string" then profile.standaloneEssentialGrowDirection = defaults.profiles.Default.standaloneEssentialGrowDirection end
  if type(profile.standaloneEssentialRowGrowDirection) ~= "string" then profile.standaloneEssentialRowGrowDirection = defaults.profiles.Default.standaloneEssentialRowGrowDirection end
  if profile.standaloneUtilitySecondRowSize == nil then profile.standaloneUtilitySecondRowSize = defaults.profiles.Default.standaloneUtilitySecondRowSize end
  if profile.standaloneUtilityIconsPerRow == nil then profile.standaloneUtilityIconsPerRow = defaults.profiles.Default.standaloneUtilityIconsPerRow end
  if profile.standaloneUtilityMaxRows == nil then profile.standaloneUtilityMaxRows = defaults.profiles.Default.standaloneUtilityMaxRows end
  if type(profile.standaloneUtilityGrowDirection) ~= "string" then profile.standaloneUtilityGrowDirection = defaults.profiles.Default.standaloneUtilityGrowDirection end
  if type(profile.standaloneUtilityRowGrowDirection) ~= "string" then profile.standaloneUtilityRowGrowDirection = defaults.profiles.Default.standaloneUtilityRowGrowDirection end
  if profile.combatStatusEnabled == nil then profile.combatStatusEnabled = defaults.profiles.Default.combatStatusEnabled end
  if profile.combatStatusCentered == nil then profile.combatStatusCentered = defaults.profiles.Default.combatStatusCentered end
  if profile.combatStatusX == nil then profile.combatStatusX = defaults.profiles.Default.combatStatusX end
  if profile.combatStatusY == nil then profile.combatStatusY = defaults.profiles.Default.combatStatusY end
  if profile.combatStatusScale == nil then profile.combatStatusScale = defaults.profiles.Default.combatStatusScale end
  if profile.combatStatusEnterColorR == nil then profile.combatStatusEnterColorR = defaults.profiles.Default.combatStatusEnterColorR end
  if profile.combatStatusEnterColorG == nil then profile.combatStatusEnterColorG = defaults.profiles.Default.combatStatusEnterColorG end
  if profile.combatStatusEnterColorB == nil then profile.combatStatusEnterColorB = defaults.profiles.Default.combatStatusEnterColorB end
  if profile.combatStatusLeaveColorR == nil then profile.combatStatusLeaveColorR = defaults.profiles.Default.combatStatusLeaveColorR end
  if profile.combatStatusLeaveColorG == nil then profile.combatStatusLeaveColorG = defaults.profiles.Default.combatStatusLeaveColorG end
  if profile.combatStatusLeaveColorB == nil then profile.combatStatusLeaveColorB = defaults.profiles.Default.combatStatusLeaveColorB end
  if profile.useCustomHideReveal == nil then profile.useCustomHideReveal = false end
  if type(profile.spellHideRevealThresholds) ~= "table" then profile.spellHideRevealThresholds = {} end
  if profile.customBarUseCustomHideReveal == nil then profile.customBarUseCustomHideReveal = false end
  if profile.customBar2UseCustomHideReveal == nil then profile.customBar2UseCustomHideReveal = false end
  if profile.customBar3UseCustomHideReveal == nil then profile.customBar3UseCustomHideReveal = false end
  return profile
end
addonTable.GetProfile = GetProfile
addonTable.GetGlobalFont = GetGlobalFont
addonTable.IsClassPowerRedundant = IsClassPowerRedundant
addonTable.ModuleCompanionAddOns = addonTable.ModuleCompanionAddOns or {
  custombars = "CooldownCursorManager_CustomBars",
  blizzcdm = "CooldownCursorManager_BlizzCDM",
  prb = "CooldownCursorManager_PRB",
  castbars = "CooldownCursorManager_Castbars",
  debuffs = "CooldownCursorManager_Debuffs",
  unitframes = "CooldownCursorManager_UnitFrames",
  qol = "CooldownCursorManager_QOL",
}
addonTable.GetModuleStates = function()
  CooldownCursorManagerDB = CooldownCursorManagerDB or {}
  if type(CooldownCursorManagerDB.moduleStates) ~= "table" then
    CooldownCursorManagerDB.moduleStates = {}
  end
  local ms = CooldownCursorManagerDB.moduleStates
  if not CooldownCursorManagerDB._moduleStatesMigrated71 then
    CooldownCursorManagerDB._moduleStatesMigrated71 = true
    local allFalse = true
    for _, v in pairs(ms) do
      if v ~= false then allFalse = false break end
    end
    if allFalse and next(ms) ~= nil then
      for k in pairs(ms) do ms[k] = nil end
    end
  end
  if ms.custombars == nil then ms.custombars = true end
  if ms.blizzcdm == nil then ms.blizzcdm = true end
  if ms.prb == nil then ms.prb = true end
  if ms.castbars == nil then ms.castbars = true end
  if ms.debuffs == nil then ms.debuffs = true end
  if ms.unitframes == nil then ms.unitframes = true end
  if ms.qol == nil then ms.qol = true end
  return ms
end
addonTable.IsModuleEnabled = function(moduleKey)
  if moduleKey == "cursor" then
    return true
  end
  local companionAddon = addonTable.ModuleCompanionAddOns[moduleKey]
  if companionAddon and C_AddOns and C_AddOns.GetAddOnEnableState then
    if C_AddOns.GetAddOnEnableState(companionAddon) == 0 then return false end
  end
  local ms = addonTable.GetModuleStates()
  return ms[moduleKey] ~= false
end
addonTable.ApplyModuleStateToProfile = function(profile)
  if type(profile) ~= "table" then return end
  local ms = addonTable.GetModuleStates()
  if ms.custombars == false then
    profile.customBarsCount = 0
    profile.customBarEnabled = false
    profile.customBar2Enabled = false
    profile.customBar3Enabled = false
    profile.customBar4Enabled = false
    profile.customBar5Enabled = false
  end
  if ms.blizzcdm == false then
    profile.disableBlizzCDM = true
    profile.useBuffBar = false
    profile.useEssentialBar = false
  end
  if ms.prb == false then
    profile.usePersonalResourceBar = false
  end
  if ms.castbars == false then
    profile.useCastbar = false
    profile.useFocusCastbar = false
    profile.useTargetCastbar = false
  end
  if ms.debuffs == false then
    profile.enablePlayerDebuffs = false
  end
  if ms.unitframes == false then
    profile.enableUnitFrameCustomization = false
  end
  if ms.qol == false then
    profile.combatTimerEnabled = false
    profile.crTimerEnabled = false
    profile.combatStatusEnabled = false
    profile.selfHighlightEnabled = false
    profile.lowHealthWarningEnabled = false
    profile.noTargetAlertEnabled = false
    profile.autoRepair = false
    profile.autoSellJunk = false
    profile.autoQuest = false
    profile.autoFillDelete = false
    profile.quickRoleSignup = false
    profile.skyridingEnabled = false
  end
end
addonTable.SetModuleEnabled = function(moduleKey, enabled)
  if moduleKey == "cursor" then
    return false
  end
  local changed = false
  local needsReload = false
  local ms = addonTable.GetModuleStates()
  local targetEnabled = enabled == true
  if ms[moduleKey] ~= targetEnabled then
    ms[moduleKey] = targetEnabled
    changed = true
  end
  local companionAddon = addonTable.ModuleCompanionAddOns[moduleKey]
  if companionAddon and C_AddOns then
    local isEnabledNow = true
    if C_AddOns.GetAddOnEnableState then
      isEnabledNow = C_AddOns.GetAddOnEnableState(companionAddon) ~= 0
    end
    if targetEnabled and not isEnabledNow and C_AddOns.EnableAddOn then
      pcall(C_AddOns.EnableAddOn, companionAddon)
      changed = true
    elseif (not targetEnabled) and isEnabledNow and C_AddOns.DisableAddOn then
      pcall(C_AddOns.DisableAddOn, companionAddon)
      changed = true
    end
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  addonTable.ApplyModuleStateToProfile(profile)
  if changed then
    needsReload = true
  end
  return changed, needsReload
end
local function NormalizeHideRevealThresholdValue(value)
  local n = tonumber(value)
  if not n then return 0 end
  n = math.floor(n * 2 + 0.5) / 2
  if n < 0 then n = 0 end
  if n > 10 then n = 10 end
  return n
end
addonTable.NormalizeHideRevealThresholdValue = NormalizeHideRevealThresholdValue
local function HasClassPowerAvailable()
  local cpConfig = GetClassPowerConfig()
  if not cpConfig then return false end
  if IsClassPowerRedundant() then return false end
  if cpConfig.buffID then return true end
  local classPowerType = cpConfig.powerType
  if not classPowerType then return false end
  local maxPower = UnitPowerMax("player", classPowerType) or 0
  return maxPower > 0
end
addonTable.HasClassPowerAvailable = HasClassPowerAvailable
local function GetSpellList()
  local profile = addonTable.GetProfile()
  if not profile then return {}, {}, {}, {}, {} end
  local specID = GetSpecialization() or 1
  if type(profile.trackedSpellsBySpec) ~= "table" then profile.trackedSpellsBySpec = {} end
  if type(profile.spellsEnabledBySpec) ~= "table" then profile.spellsEnabledBySpec = {} end
  if type(profile.spellGlowEnabledBySpec) ~= "table" then profile.spellGlowEnabledBySpec = {} end
  if type(profile.spellGlowTypeBySpec) ~= "table" then profile.spellGlowTypeBySpec = {} end
  if type(profile.spellHideRevealThresholdsBySpec) ~= "table" then profile.spellHideRevealThresholdsBySpec = {} end
  profile.trackedSpellsBySpec[specID] = profile.trackedSpellsBySpec[specID] or {}
  profile.spellsEnabledBySpec[specID] = profile.spellsEnabledBySpec[specID] or {}
  profile.spellGlowEnabledBySpec[specID] = profile.spellGlowEnabledBySpec[specID] or {}
  profile.spellGlowTypeBySpec[specID] = profile.spellGlowTypeBySpec[specID] or {}
  profile.spellHideRevealThresholdsBySpec[specID] = profile.spellHideRevealThresholdsBySpec[specID] or {}
  local trackedSpells = profile.trackedSpellsBySpec[specID]
  local spellsEnabled = profile.spellsEnabledBySpec[specID]
  local spellGlowEnabled = profile.spellGlowEnabledBySpec[specID]
  local spellGlowType = profile.spellGlowTypeBySpec[specID]
  local spellHideRevealThresholds = profile.spellHideRevealThresholdsBySpec[specID]
  if #trackedSpells == 0 and type(profile.trackedSpells) == "table" and #profile.trackedSpells > 0 then
    profile.trackedSpellsBySpec[specID] = DeepCopy(profile.trackedSpells)
    profile.spellsEnabledBySpec[specID] = type(profile.spellsEnabled) == "table" and DeepCopy(profile.spellsEnabled) or {}
    profile.spellGlowEnabledBySpec[specID] = type(profile.spellGlowEnabled) == "table" and DeepCopy(profile.spellGlowEnabled) or {}
    profile.spellGlowTypeBySpec[specID] = type(profile.spellGlowType) == "table" and DeepCopy(profile.spellGlowType) or {}
    profile.spellHideRevealThresholdsBySpec[specID] = type(profile.spellHideRevealThresholds) == "table" and DeepCopy(profile.spellHideRevealThresholds) or {}
    trackedSpells = profile.trackedSpellsBySpec[specID]
    spellsEnabled = profile.spellsEnabledBySpec[specID]
    spellGlowEnabled = profile.spellGlowEnabledBySpec[specID]
    spellGlowType = profile.spellGlowTypeBySpec[specID]
    spellHideRevealThresholds = profile.spellHideRevealThresholdsBySpec[specID]
    profile.trackedSpells = nil
    profile.spellsEnabled = nil
    profile.spellGlowEnabled = nil
    profile.spellGlowType = nil
    profile.spellHideRevealThresholds = nil
  end
  return trackedSpells, spellsEnabled, spellGlowEnabled, spellGlowType, spellHideRevealThresholds
end
local function SetSpellList(spells, enabled, glowEnabled, glowType, hideRevealThresholds)
  local profile = addonTable.GetProfile()
  if not profile then return end
  local specID = GetSpecialization() or 1
  if type(profile.trackedSpellsBySpec) ~= "table" then profile.trackedSpellsBySpec = {} end
  if type(profile.spellsEnabledBySpec) ~= "table" then profile.spellsEnabledBySpec = {} end
  if type(profile.spellGlowEnabledBySpec) ~= "table" then profile.spellGlowEnabledBySpec = {} end
  if type(profile.spellGlowTypeBySpec) ~= "table" then profile.spellGlowTypeBySpec = {} end
  if type(profile.spellHideRevealThresholdsBySpec) ~= "table" then profile.spellHideRevealThresholdsBySpec = {} end
  profile.trackedSpellsBySpec[specID] = spells or {}
  profile.spellsEnabledBySpec[specID] = enabled or {}
  profile.spellGlowEnabledBySpec[specID] = glowEnabled or profile.spellGlowEnabledBySpec[specID] or {}
  profile.spellGlowTypeBySpec[specID] = glowType or profile.spellGlowTypeBySpec[specID] or {}
  if hideRevealThresholds then profile.spellHideRevealThresholdsBySpec[specID] = hideRevealThresholds end
  if type(profile.spellHideRevealThresholdsBySpec[specID]) ~= "table" then profile.spellHideRevealThresholdsBySpec[specID] = {} end
  local trackedSpells = profile.trackedSpellsBySpec[specID]
  local spellsEnabled = profile.spellsEnabledBySpec[specID]
  local spellGlowEnabled = profile.spellGlowEnabledBySpec[specID]
  local spellGlowType = profile.spellGlowTypeBySpec[specID]
  local spellHideRevealThresholds = profile.spellHideRevealThresholdsBySpec[specID]
  local listSize = #trackedSpells
  for i = 1, listSize do
    if spellGlowEnabled[i] == nil then
      spellGlowEnabled[i] = false
    end
    if type(spellGlowType[i]) ~= "string" then
      spellGlowType[i] = profile.spellGlowDefaultType or "pixel"
    end
    if spellHideRevealThresholds[i] then
      spellHideRevealThresholds[i] = NormalizeHideRevealThresholdValue(spellHideRevealThresholds[i])
    end
  end
  for i = #spellGlowEnabled, listSize + 1, -1 do
    spellGlowEnabled[i] = nil
  end
  for i = #spellGlowType, listSize + 1, -1 do
    spellGlowType[i] = nil
  end
  for i = #spellsEnabled, listSize + 1, -1 do
    spellsEnabled[i] = nil
  end
  local thresholds = spellHideRevealThresholds
  for i = #thresholds, listSize + 1, -1 do
    thresholds[i] = nil
  end
end
addonTable.GetSpellList = GetSpellList
addonTable.SetSpellList = SetSpellList
local function GetActiveSpellHideRevealThresholds(profile)
  if type(profile) ~= "table" then return nil end
  local bySpec = profile.spellHideRevealThresholdsBySpec
  if type(bySpec) == "table" then
    local specID = GetSpecialization() or 1
    local t = bySpec[specID]
    if type(t) == "table" then
      return t
    end
  end
  if type(profile.spellHideRevealThresholds) == "table" then
    return profile.spellHideRevealThresholds
  end
  return nil
end
local function GetCharacterKey()
  local playerName = UnitName("player")
  local realmName = GetRealmName()
  if playerName and realmName then
    return playerName .. "-" .. realmName
  end
  return nil
end
local function GetCurrentSpecID()
  return GetSpecialization() or 1
end
local function GetCustomBarSpells()
  if not CooldownCursorManagerDB then return {}, {}, {}, {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {}, {}, {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBarSpells = CooldownCursorManagerDB.characterCustomBarSpells or {}
  CooldownCursorManagerDB.characterCustomBarSpells[charKey] = CooldownCursorManagerDB.characterCustomBarSpells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] = CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled = CooldownCursorManagerDB.characterCustomBarSpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled = CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowType = CooldownCursorManagerDB.characterCustomBarSpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey][specID] = CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarHideRevealThresholds = CooldownCursorManagerDB.characterCustomBarHideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID] = CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID],
         CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey][specID],
         CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID]
end
local function SetCustomBarSpells(spells, enabled, glowEnabled, glowType, hideRevealThresholds)
  if not CooldownCursorManagerDB then return end
  local charKey = GetCharacterKey()
  if not charKey then return end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBarSpells = CooldownCursorManagerDB.characterCustomBarSpells or {}
  CooldownCursorManagerDB.characterCustomBarSpells[charKey] = CooldownCursorManagerDB.characterCustomBarSpells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] = spells or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled = CooldownCursorManagerDB.characterCustomBarSpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID] = enabled or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled = CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey][specID] = glowEnabled or CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowType = CooldownCursorManagerDB.characterCustomBarSpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey][specID] = glowType or CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarHideRevealThresholds = CooldownCursorManagerDB.characterCustomBarHideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey] or {}
  if hideRevealThresholds then
    CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID] = hideRevealThresholds
  end
  if type(CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID]) ~= "table" then
    CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID] = {}
  end
  local listSize = #CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID]
  local glowEnabledTable = CooldownCursorManagerDB.characterCustomBarSpellGlowEnabled[charKey][specID]
  local glowTypeTable = CooldownCursorManagerDB.characterCustomBarSpellGlowType[charKey][specID]
  local hrTable = CooldownCursorManagerDB.characterCustomBarHideRevealThresholds[charKey][specID]
  for i = 1, listSize do
    if glowEnabledTable[i] == nil then
      glowEnabledTable[i] = false
    end
    if type(glowTypeTable[i]) ~= "string" then
      glowTypeTable[i] = "pixel"
    end
    if hrTable[i] then
      hrTable[i] = NormalizeHideRevealThresholdValue(hrTable[i])
    end
  end
  for i = #glowEnabledTable, listSize + 1, -1 do
    glowEnabledTable[i] = nil
  end
  for i = #glowTypeTable, listSize + 1, -1 do
    glowTypeTable[i] = nil
  end
  for i = #hrTable, listSize + 1, -1 do
    hrTable[i] = nil
  end
end
addonTable.GetCharacterKey = GetCharacterKey
addonTable.GetCurrentSpecID = GetCurrentSpecID
addonTable.GetCustomBarSpells = GetCustomBarSpells
addonTable.SetCustomBarSpells = SetCustomBarSpells
local function GetCustomBar2Spells()
  if not CooldownCursorManagerDB then return {}, {}, {}, {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {}, {}, {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar2Spells = CooldownCursorManagerDB.characterCustomBar2Spells or {}
  CooldownCursorManagerDB.characterCustomBar2Spells[charKey] = CooldownCursorManagerDB.characterCustomBar2Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowType = CooldownCursorManagerDB.characterCustomBar2SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID]
end
local function SetCustomBar2Spells(spells, enabled, glowEnabled, glowType, hideRevealThresholds)
  if not CooldownCursorManagerDB then return end
  local charKey = GetCharacterKey()
  if not charKey then return end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar2Spells = CooldownCursorManagerDB.characterCustomBar2Spells or {}
  CooldownCursorManagerDB.characterCustomBar2Spells[charKey] = CooldownCursorManagerDB.characterCustomBar2Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID] = spells or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID] = enabled or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey][specID] = glowEnabled or CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowType = CooldownCursorManagerDB.characterCustomBar2SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey][specID] = glowType or CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey] or {}
  if hideRevealThresholds then
    CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID] = hideRevealThresholds
  end
  if type(CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID]) ~= "table" then
    CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID] = {}
  end
  local listSize = #CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID]
  local glowEnabledTable = CooldownCursorManagerDB.characterCustomBar2SpellGlowEnabled[charKey][specID]
  local glowTypeTable = CooldownCursorManagerDB.characterCustomBar2SpellGlowType[charKey][specID]
  local hrTable = CooldownCursorManagerDB.characterCustomBar2HideRevealThresholds[charKey][specID]
  for i = 1, listSize do
    if glowEnabledTable[i] == nil then
      glowEnabledTable[i] = false
    end
    if type(glowTypeTable[i]) ~= "string" then
      glowTypeTable[i] = "pixel"
    end
    if hrTable[i] then
      hrTable[i] = NormalizeHideRevealThresholdValue(hrTable[i])
    end
  end
  for i = #glowEnabledTable, listSize + 1, -1 do
    glowEnabledTable[i] = nil
  end
  for i = #glowTypeTable, listSize + 1, -1 do
    glowTypeTable[i] = nil
  end
  for i = #hrTable, listSize + 1, -1 do
    hrTable[i] = nil
  end
end
addonTable.GetCustomBar2Spells = GetCustomBar2Spells
addonTable.SetCustomBar2Spells = SetCustomBar2Spells
local function GetCustomBar3Spells()
  if not CooldownCursorManagerDB then return {}, {}, {}, {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {}, {}, {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar3Spells = CooldownCursorManagerDB.characterCustomBar3Spells or {}
  CooldownCursorManagerDB.characterCustomBar3Spells[charKey] = CooldownCursorManagerDB.characterCustomBar3Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowType = CooldownCursorManagerDB.characterCustomBar3SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID]
end
local function SetCustomBar3Spells(spells, enabled, glowEnabled, glowType, hideRevealThresholds)
  if not CooldownCursorManagerDB then return end
  local charKey = GetCharacterKey()
  if not charKey then return end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar3Spells = CooldownCursorManagerDB.characterCustomBar3Spells or {}
  CooldownCursorManagerDB.characterCustomBar3Spells[charKey] = CooldownCursorManagerDB.characterCustomBar3Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID] = spells or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID] = enabled or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey][specID] = glowEnabled or CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowType = CooldownCursorManagerDB.characterCustomBar3SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey][specID] = glowType or CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey] or {}
  if hideRevealThresholds then
    CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID] = hideRevealThresholds
  end
  if type(CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID]) ~= "table" then
    CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID] = {}
  end
  local listSize = #CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID]
  local glowEnabledTable = CooldownCursorManagerDB.characterCustomBar3SpellGlowEnabled[charKey][specID]
  local glowTypeTable = CooldownCursorManagerDB.characterCustomBar3SpellGlowType[charKey][specID]
  local hrTable = CooldownCursorManagerDB.characterCustomBar3HideRevealThresholds[charKey][specID]
  for i = 1, listSize do
    if glowEnabledTable[i] == nil then
      glowEnabledTable[i] = false
    end
    if type(glowTypeTable[i]) ~= "string" then
      glowTypeTable[i] = "pixel"
    end
    if hrTable[i] then
      hrTable[i] = NormalizeHideRevealThresholdValue(hrTable[i])
    end
  end
  for i = #glowEnabledTable, listSize + 1, -1 do
    glowEnabledTable[i] = nil
  end
  for i = #glowTypeTable, listSize + 1, -1 do
    glowTypeTable[i] = nil
  end
  for i = #hrTable, listSize + 1, -1 do
    hrTable[i] = nil
  end
end
addonTable.GetCustomBar3Spells = GetCustomBar3Spells
addonTable.SetCustomBar3Spells = SetCustomBar3Spells
local function GetCustomBar4Spells()
  if not CooldownCursorManagerDB then return {}, {}, {}, {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {}, {}, {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar4Spells = CooldownCursorManagerDB.characterCustomBar4Spells or {}
  CooldownCursorManagerDB.characterCustomBar4Spells[charKey] = CooldownCursorManagerDB.characterCustomBar4Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4Spells[charKey][specID] = CooldownCursorManagerDB.characterCustomBar4Spells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellsEnabled = CooldownCursorManagerDB.characterCustomBar4SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowType = CooldownCursorManagerDB.characterCustomBar4SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey][specID] = CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID] = CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBar4Spells[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID]
end
local function SetCustomBar4Spells(spells, enabled, glowEnabled, glowType, hideRevealThresholds)
  if not CooldownCursorManagerDB then return end
  local charKey = GetCharacterKey()
  if not charKey then return end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar4Spells = CooldownCursorManagerDB.characterCustomBar4Spells or {}
  CooldownCursorManagerDB.characterCustomBar4Spells[charKey] = CooldownCursorManagerDB.characterCustomBar4Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4Spells[charKey][specID] = spells or {}
  CooldownCursorManagerDB.characterCustomBar4SpellsEnabled = CooldownCursorManagerDB.characterCustomBar4SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellsEnabled[charKey][specID] = enabled or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey][specID] = glowEnabled or CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowType = CooldownCursorManagerDB.characterCustomBar4SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey][specID] = glowType or CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey] or {}
  if hideRevealThresholds then
    CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID] = hideRevealThresholds
  end
  if type(CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID]) ~= "table" then
    CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID] = {}
  end
  local listSize = #CooldownCursorManagerDB.characterCustomBar4Spells[charKey][specID]
  local glowEnabledTable = CooldownCursorManagerDB.characterCustomBar4SpellGlowEnabled[charKey][specID]
  local glowTypeTable = CooldownCursorManagerDB.characterCustomBar4SpellGlowType[charKey][specID]
  local hrTable = CooldownCursorManagerDB.characterCustomBar4HideRevealThresholds[charKey][specID]
  for i = 1, listSize do
    if glowEnabledTable[i] == nil then
      glowEnabledTable[i] = false
    end
    if type(glowTypeTable[i]) ~= "string" then
      glowTypeTable[i] = "pixel"
    end
    if hrTable[i] then
      hrTable[i] = NormalizeHideRevealThresholdValue(hrTable[i])
    end
  end
  for i = #glowEnabledTable, listSize + 1, -1 do
    glowEnabledTable[i] = nil
  end
  for i = #glowTypeTable, listSize + 1, -1 do
    glowTypeTable[i] = nil
  end
  for i = #hrTable, listSize + 1, -1 do
    hrTable[i] = nil
  end
end
addonTable.GetCustomBar4Spells = GetCustomBar4Spells
addonTable.SetCustomBar4Spells = SetCustomBar4Spells
local function GetCustomBar5Spells()
  if not CooldownCursorManagerDB then return {}, {}, {}, {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {}, {}, {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar5Spells = CooldownCursorManagerDB.characterCustomBar5Spells or {}
  CooldownCursorManagerDB.characterCustomBar5Spells[charKey] = CooldownCursorManagerDB.characterCustomBar5Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5Spells[charKey][specID] = CooldownCursorManagerDB.characterCustomBar5Spells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellsEnabled = CooldownCursorManagerDB.characterCustomBar5SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowType = CooldownCursorManagerDB.characterCustomBar5SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey][specID] = CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID] = CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBar5Spells[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey][specID],
         CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID]
end
local function SetCustomBar5Spells(spells, enabled, glowEnabled, glowType, hideRevealThresholds)
  if not CooldownCursorManagerDB then return end
  local charKey = GetCharacterKey()
  if not charKey then return end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar5Spells = CooldownCursorManagerDB.characterCustomBar5Spells or {}
  CooldownCursorManagerDB.characterCustomBar5Spells[charKey] = CooldownCursorManagerDB.characterCustomBar5Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5Spells[charKey][specID] = spells or {}
  CooldownCursorManagerDB.characterCustomBar5SpellsEnabled = CooldownCursorManagerDB.characterCustomBar5SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellsEnabled[charKey][specID] = enabled or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled = CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey][specID] = glowEnabled or CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowType = CooldownCursorManagerDB.characterCustomBar5SpellGlowType or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey] = CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey][specID] = glowType or CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds = CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds or {}
  CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey] = CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey] or {}
  if hideRevealThresholds then
    CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID] = hideRevealThresholds
  end
  if type(CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID]) ~= "table" then
    CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID] = {}
  end
  local listSize = #CooldownCursorManagerDB.characterCustomBar5Spells[charKey][specID]
  local glowEnabledTable = CooldownCursorManagerDB.characterCustomBar5SpellGlowEnabled[charKey][specID]
  local glowTypeTable = CooldownCursorManagerDB.characterCustomBar5SpellGlowType[charKey][specID]
  local hrTable = CooldownCursorManagerDB.characterCustomBar5HideRevealThresholds[charKey][specID]
  for i = 1, listSize do
    if glowEnabledTable[i] == nil then
      glowEnabledTable[i] = false
    end
    if type(glowTypeTable[i]) ~= "string" then
      glowTypeTable[i] = "pixel"
    end
    if hrTable[i] then
      hrTable[i] = NormalizeHideRevealThresholdValue(hrTable[i])
    end
  end
  for i = #glowEnabledTable, listSize + 1, -1 do
    glowEnabledTable[i] = nil
  end
  for i = #glowTypeTable, listSize + 1, -1 do
    glowTypeTable[i] = nil
  end
  for i = #hrTable, listSize + 1, -1 do
    hrTable[i] = nil
  end
end
addonTable.GetCustomBar5Spells = GetCustomBar5Spells
addonTable.SetCustomBar5Spells = SetCustomBar5Spells
local function IsSpellKnownByPlayer(spellID)
  if not spellID then return false end
  if C_SpellBook.IsSpellInSpellBook(spellID) then return true end
  if C_SpellBook.IsSpellKnown(spellID) then return true end
  if C_SpellBook.IsSpellInSpellBook(spellID, Enum.SpellBookSpellBank.Player, true) then return true end
  return false
end
addonTable.IsSpellKnownByPlayer = IsSpellKnownByPlayer
local function IsKnownCdmBuffSpell(spellID)
  if type(spellID) ~= "number" or spellID <= 0 then return false end
  local known = addonTable.GetCdmKnownBuffSpellIDs and addonTable.GetCdmKnownBuffSpellIDs()
  if type(known) == "table" and known[spellID] == true then
    return true
  end
  local pure = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs()
  if type(pure) == "table" and pure[spellID] == true then
    return true
  end
  return false
end
local function IsTrackedEntryAvailable(isItem, originalID, activeID, allowUnknownSpellInfo)
  if isItem then
    local count = C_Item.GetItemCount(originalID, true, true)
    if not count or count <= 0 then
      return false
    end
    return true
  end
  if IsSpellKnownByPlayer(activeID) then return true end
  if IsSpellKnownByPlayer(originalID) then return true end
  if allowUnknownSpellInfo then
    if IsKnownCdmBuffSpell(activeID) or IsKnownCdmBuffSpell(originalID) then
      return true
    end
    local resolved = addonTable.ResolveTrackedSpellID and addonTable.ResolveTrackedSpellID(activeID) or nil
    if type(resolved) == "number" and resolved > 0 and IsKnownCdmBuffSpell(resolved) then
      return true
    end
  end
  return false
end
addonTable._resolveCache = {}
addonTable.InvalidateResolveCache = function()
  wipe(addonTable._resolveCache)
end
local function ResolveTrackedSpellID(spellID)
  if type(spellID) ~= "number" then return spellID end
  local rc = addonTable._resolveCache
  local cached = rc[spellID]
  if cached then return cached end
  if FindSpellOverrideByID then
    local okOverride, overrideID = pcall(FindSpellOverrideByID, spellID)
    if okOverride and type(overrideID) == "number" and overrideID > 0 and overrideID ~= spellID then
      rc[spellID] = overrideID
      return overrideID
    end
  end
  if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
    local okBookOverride, bookOverrideID = pcall(C_SpellBook.FindSpellOverrideByID, spellID)
    if okBookOverride and type(bookOverrideID) == "number" and bookOverrideID > 0 and bookOverrideID ~= spellID then
      rc[spellID] = bookOverrideID
      return bookOverrideID
    end
  end
  local baseInfo = C_Spell.GetSpellInfo(spellID)
  local spellName = baseInfo and baseInfo.name
  if not spellName then
    rc[spellID] = spellID
    return spellID
  end
  local replacementInfo = C_Spell.GetSpellInfo(spellName)
  local replacementID = replacementInfo and replacementInfo.spellID
  if type(replacementID) == "number" and replacementID > 0 and replacementID ~= spellID then
    rc[spellID] = replacementID
    return replacementID
  end
  rc[spellID] = spellID
  return spellID
end
addonTable.ResolveTrackedSpellID = ResolveTrackedSpellID
local function ScanTooltipForCooldown(spellID)
  if UnitAffectingCombat("player") then return nil end
  if not State._cdScanTip then
    State._cdScanTip = CreateFrame("GameTooltip", "CCMCDScanTip", nil, "GameTooltipTemplate")
    State._cdScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
  end
  State._cdScanTip:ClearLines()
  local ok = pcall(State._cdScanTip.SetSpellByID, State._cdScanTip, spellID)
  if not ok then return nil end
  for i = 1, State._cdScanTip:NumLines() do
    for _, side in ipairs({"Left", "Right"}) do
      local fontStr = _G["CCMCDScanTipText" .. side .. i]
      if fontStr then
        local ok2, t = pcall(fontStr.GetText, fontStr)
        if ok2 and t and type(t) == "string" then
          if t:match("[Cc]ooldown") or t:match("Abklingzeit") or t:match("[Rr]echarge") or t:match("Aufladung") then
            local m = t:match("(%d+%.?%d*) [Mm]in")
            if m then return tonumber(m) * 60 end
            local s = t:match("(%d+%.?%d*)")
            if s then
              local dur = tonumber(s)
              if dur and dur > 1.5 then return dur end
            end
          end
        end
      end
    end
  end
  return nil
end
local function PreCacheSpellDurations()
  local allSpellIDs = {}
  for _, icon in ipairs(State.cursorIcons) do
    if not icon.isItem and icon.spellID then
      allSpellIDs[icon.spellID] = true
      local resolved = ResolveTrackedSpellID(icon.spellID)
      if resolved and resolved ~= icon.spellID then
        allSpellIDs[resolved] = true
      end
    end
  end
  for _, icons in ipairs({State.customBar1Icons, State.customBar2Icons, State.customBar3Icons, State.customBar4Icons, State.customBar5Icons}) do
    for _, icon in ipairs(icons) do
      if not icon.isItem then
        local sid = icon.actualID or icon.spellID
        if sid then
          allSpellIDs[sid] = true
          local resolved = ResolveTrackedSpellID(sid)
          if resolved and resolved ~= sid then
            allSpellIDs[resolved] = true
          end
        end
      end
    end
  end
  local cacheHaste = GetHaste and GetHaste() or 0
  for spellID in pairs(allSpellIDs) do
    if not State.spellBaseCdDurations[spellID] then
      local tooltipDur = ScanTooltipForCooldown(spellID)
      if tooltipDur then
        State.spellBaseCdDurations[spellID] = tooltipDur * (1 + cacheHaste / 100)
      else
        local okBase, baseCd = pcall(GetSpellBaseCooldown, spellID)
        if okBase and baseCd and type(baseCd) == "number" and baseCd > 1500 then
          State.spellBaseCdDurations[spellID] = baseCd / 1000
        end
      end
    end
  end
end
local ringFrame = CreateFrame("Frame", "CCMRadialCircle", UIParent)
ringFrame:SetSize(120, 120)
ringFrame:SetFrameStrata("FULLSCREEN")
ringFrame:SetFrameLevel(200)
ringFrame:Hide()
if ringFrame.SetSnapToPixelGrid then ringFrame:SetSnapToPixelGrid(false) end
if ringFrame.SetTexelSnappingBias then ringFrame:SetTexelSnappingBias(0) end
addonTable.ringFrame = ringFrame
local ringTexture = ringFrame:CreateTexture(nil, "ARTWORK")
ringTexture:SetAllPoints()
ringTexture:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\Ring_Default.png")
ringTexture:SetVertexColor(1, 1, 1, 0.8)
if ringTexture.SetSnapToPixelGrid then
  ringTexture:SetSnapToPixelGrid(false)
end
if ringTexture.SetTexelSnappingBias then
  ringTexture:SetTexelSnappingBias(0)
end
local gcdOverlay = CreateFrame("Cooldown", "CCMGCDCooldown", ringFrame, "CooldownFrameTemplate")
gcdOverlay:SetAllPoints(ringFrame)
gcdOverlay:SetDrawEdge(false)
gcdOverlay:SetDrawSwipe(true)
gcdOverlay:SetReverse(true)
gcdOverlay:SetHideCountdownNumbers(true)
gcdOverlay:SetSwipeTexture("Interface\\AddOns\\CooldownCursorManager\\media\\Ring_Default.png")
local function GetRingTexturePath(thickness, radius)
  local t = math.floor(thickness)
  if t < 1 then t = 1 end
  if t > 5 then t = 5 end
  return "Interface\\AddOns\\CooldownCursorManager\\media\\Ring_32_T" .. t .. ".png"
end
local ringOnUpdateFunc = function(self)
  if not self:IsShown() then return end
  local now = GetTime()
  if now - State.lastScaleUpdate > 0.5 then
    State.cachedUIScale = UIParent:GetEffectiveScale()
    State.lastScaleUpdate = now
  end
  local x, y = GetCursorPosition()
  self:ClearAllPoints()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / State.cachedUIScale, y / State.cachedUIScale)
end
State.ringOnUpdateFunc = ringOnUpdateFunc
ringFrame:SetScript("OnUpdate", ringOnUpdateFunc)
local function UpdateRadialCircle()
  local profile = addonTable.GetProfile()
  if not profile or not profile.showRadialCircle then
    ringFrame:Hide()
    State.ringEnabled = false
    return
  end
  local iconStrata = profile.iconStrata or "FULLSCREEN"
  local onQolTab = State.guiIsOpen and addonTable.activeTab and addonTable.activeTab() == 18
  if onQolTab then
    ringFrame:SetFrameStrata("TOOLTIP")
    ringFrame:SetFrameLevel(9999)
  else
    ringFrame:SetFrameStrata(iconStrata)
  end
  State.ringCombatOnly = profile.cursorCombatOnly or profile.showInCombatOnly
  if State.ringCombatOnly and not UnitAffectingCombat("player") and not onQolTab then
    ringFrame:Hide()
    return
  end
  State.ringEnabled = true
  local radiusSize = type(profile.radialRadius) == "number" and profile.radialRadius or 30
  local thicknessLevel = type(profile.radialThickness) == "number" and profile.radialThickness or 4
  local texturePath = GetRingTexturePath(thicknessLevel, radiusSize)
  if texturePath ~= State.lastRingTexturePath then
    ringTexture:SetTexture(texturePath)
    gcdOverlay:SetSwipeTexture(texturePath)
    State.lastRingTexturePath = texturePath
  end
  local colorR = type(profile.radialColorR) == "number" and profile.radialColorR or 1.0
  local colorG = type(profile.radialColorG) == "number" and profile.radialColorG or 1.0
  local colorB = type(profile.radialColorB) == "number" and profile.radialColorB or 1.0
  local colorAlpha = type(profile.radialAlpha) == "number" and profile.radialAlpha or 0.8
  local diameter = radiusSize * 2
  ringFrame:SetSize(diameter, diameter)
  gcdOverlay:SetSize(diameter, diameter)
  local isGCDActive = false
  if profile.showGCD then
    local currentTime = GetTime()
    local remainingTime = State.gcdDuration - (currentTime - State.gcdStartTime)
    if State.gcdStartTime > 0 and State.gcdDuration > 0 and remainingTime > 0 then
      isGCDActive = true
      ringTexture:Hide()
      gcdOverlay:SetSwipeColor(colorR, colorG, colorB, colorAlpha)
      gcdOverlay:SetCooldown(State.gcdStartTime, State.gcdDuration)
      gcdOverlay:Show()
    end
  end
  if not isGCDActive then
    ringTexture:SetVertexColor(colorR, colorG, colorB, colorAlpha)
    ringTexture:Show()
    gcdOverlay:Hide()
  end
  ringFrame:Show()
end
addonTable.UpdateRadialCircle = UpdateRadialCircle
local function SaveEssentialBarOriginals()
  if State.essentialBarOriginalSetup then return end
  local main = EssentialCooldownViewer
  if main then
    local point, relativeTo, relativePoint, xOfs, yOfs = main:GetPoint(1)
    State.essentialBarOriginalData = {
      point = point or "CENTER",
      relativeTo = relativeTo or UIParent,
      relativePoint = relativePoint or "CENTER",
      xOfs = xOfs or 0,
      yOfs = yOfs or 0,
      strata = main:GetFrameStrata(),
      scale = main:GetScale()
    }
  end
  State.essentialBarOriginalSetup = true
end
local function SaveBuffBarOriginals()
  if State.buffBarOriginalSetup then return end
  local buffs = BuffIconCooldownViewer
  if buffs then
    local point, relativeTo, relativePoint, xOfs, yOfs = buffs:GetPoint(1)
    State.buffBarOriginalData = {
      point = point or "CENTER",
      relativeTo = relativeTo or UIParent,
      relativePoint = relativePoint or "CENTER",
      xOfs = xOfs or 0,
      yOfs = yOfs or 0,
      strata = buffs:GetFrameStrata(),
      scale = buffs:GetScale()
    }
  end
  State.buffBarOriginalSetup = true
end
local function RestoreEssentialBarPosition()
  if InCombatLockdown() then return end
  local main = EssentialCooldownViewer
  if main then
    local childCount = addonTable.CollectChildren(main, State.tmpChildren)
    for i = 1, childCount do
      local child = State.tmpChildren[i]
      if child.ccmBackdrop then
        child.ccmBackdrop:Hide()
      end
      if child.ccmSkinned or child.ccmStripped then
        local iconTexture = child.Icon or child.icon
        if iconTexture then
          iconTexture:SetTexCoord(0, 1, 0, 1)
          iconTexture:ClearAllPoints()
          iconTexture:SetAllPoints(child)
        end
        if child.ccmCooldown then
          child.ccmCooldown:ClearAllPoints()
          child.ccmCooldown:SetAllPoints(child)
          child.ccmCooldown:SetScale(1)
        end
        child.ccmSkinned = false
        child.ccmStripped = false
        child.ccmLastBorder = nil
      end
    end
    if State.essentialBarOriginalData.point then
      main:ClearAllPoints()
      main:SetPoint(
        State.essentialBarOriginalData.point,
        State.essentialBarOriginalData.relativeTo or UIParent,
        State.essentialBarOriginalData.relativePoint,
        State.essentialBarOriginalData.xOfs,
        State.essentialBarOriginalData.yOfs
      )
      main:SetFrameStrata(State.essentialBarOriginalData.strata or "MEDIUM")
      main:SetScale(State.essentialBarOriginalData.scale or 1)
    end
  end
  State.essentialBarActive = false
end
local function layoutIndexSort(a, b)
  return (a.layoutIndex or 0) < (b.layoutIndex or 0)
end
local SanitizeCooldownViewerChargeState
local PatchCooldownViewerIconChargeMethods
local PatchAllCooldownViewerChargeMethods
local function RestoreBuffBarPosition()
  if InCombatLockdown() then return end
  local buffs = BuffIconCooldownViewer
  if buffs then
    local childCount = addonTable.CollectChildren(buffs, State.tmpChildren)
    for i = 1, childCount do
      local child = State.tmpChildren[i]
      if child.ccmBackdrop then
        child.ccmBackdrop:Hide()
      end
      if child.ccmSkinned or child.ccmStripped then
        local iconTexture = child.Icon or child.icon
        if iconTexture then
          iconTexture:SetTexCoord(0, 1, 0, 1)
          iconTexture:ClearAllPoints()
          iconTexture:SetAllPoints(child)
        end
        if child.ccmCooldown then
          child.ccmCooldown:ClearAllPoints()
          child.ccmCooldown:SetAllPoints(child)
          child.ccmCooldown:SetScale(1)
        end
        child.ccmSkinned = false
        child.ccmStripped = false
        child.ccmLastBorder = nil
      end
    end
    if State.buffBarOriginalData.point then
      buffs:ClearAllPoints()
      buffs:SetPoint(
        State.buffBarOriginalData.point,
        State.buffBarOriginalData.relativeTo or UIParent,
        State.buffBarOriginalData.relativePoint,
        State.buffBarOriginalData.xOfs,
        State.buffBarOriginalData.yOfs
      )
      buffs:SetFrameStrata(State.buffBarOriginalData.strata or "MEDIUM")
      buffs:SetScale(State.buffBarOriginalData.scale or 1)
    end
  end
  State.buffBarActive = false
end
-- Build / cache 3 numeric curves (R, G, B) for CD text gradient
local function BuildCdGradientCurves(threshold, tR, tG, tB)
  if CCM_Curves.CdGradT == threshold and CCM_Curves.CdGradTR == tR and CCM_Curves.CdGradTG == tG and CCM_Curves.CdGradTB == tB then return end
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return end
  local rCurve = C_CurveUtil.CreateCurve()
  rCurve:SetType(Enum.LuaCurveType.Linear)
  rCurve:AddPoint(0, tR)
  rCurve:AddPoint(threshold, 1)
  rCurve:AddPoint(86400, 1)
  CCM_Curves.CdGradR = rCurve

  local gCurve = C_CurveUtil.CreateCurve()
  gCurve:SetType(Enum.LuaCurveType.Linear)
  gCurve:AddPoint(0, tG)
  gCurve:AddPoint(threshold, 1)
  gCurve:AddPoint(86400, 1)
  CCM_Curves.CdGradG = gCurve

  local bCurve = C_CurveUtil.CreateCurve()
  bCurve:SetType(Enum.LuaCurveType.Linear)
  bCurve:AddPoint(0, tB)
  bCurve:AddPoint(threshold, 1)
  bCurve:AddPoint(86400, 1)
  CCM_Curves.CdGradB = bCurve

  CCM_Curves.CdGradT = threshold
  CCM_Curves.CdGradTR = tR
  CCM_Curves.CdGradTG = tG
  CCM_Curves.CdGradTB = tB
end
addonTable.GetCachedFontStrings = function(cooldownFrame)
  local cached = cooldownFrame._ccmFontStrings
  if cached then return cached end
  local list = {}
  for i = 1, select("#", cooldownFrame:GetRegions()) do
    local region = select(i, cooldownFrame:GetRegions())
    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
      list[#list + 1] = region
    end
  end
  cooldownFrame._ccmFontStrings = list
  return list
end
local function ApplyCdTextGradient(cooldownFrame, threshold, tR, tG, tB, spellID)
  if threshold <= 0 then return end
  BuildCdGradientCurves(threshold, tR, tG, tB)
  local r, g, b = 1, 1, 1
  local usedCurve = false
  if spellID and CCM_Curves.CdGradR and C_Spell and C_Spell.GetSpellCooldownDuration then
    if ChargeSpellCache[spellID] then
    else
      local inCombat = InCombatLockdown()
      if inCombat then
        local okD, duration = pcall(C_Spell.GetSpellCooldownDuration, spellID)
        if okD and duration and duration.EvaluateRemainingDuration then
          local okR, vR = pcall(duration.EvaluateRemainingDuration, duration, CCM_Curves.CdGradR)
          local okG, vG = pcall(duration.EvaluateRemainingDuration, duration, CCM_Curves.CdGradG)
          local okB, vB = pcall(duration.EvaluateRemainingDuration, duration, CCM_Curves.CdGradB)
          if okR and okG and okB and vR and vG and vB then
            r, g, b = vR, vG, vB
            usedCurve = true
          end
        end
      else
        local duration = C_Spell.GetSpellCooldownDuration(spellID)
        if duration and duration.EvaluateRemainingDuration then
          local vR = duration:EvaluateRemainingDuration(CCM_Curves.CdGradR)
          local vG = duration:EvaluateRemainingDuration(CCM_Curves.CdGradG)
          local vB = duration:EvaluateRemainingDuration(CCM_Curves.CdGradB)
          if vR and vG and vB then
            r, g, b = vR, vG, vB
            usedCurve = true
          end
        end
      end
    end
  end
  if not usedCurve then
    local ok2, fr, fg, fb = pcall(function()
      local startMs, durationMs = cooldownFrame:GetCooldownTimes()
      if not startMs or not durationMs or durationMs <= 0 or startMs <= 0 then
        return 1, 1, 1
      end
      local remaining = (startMs + durationMs) / 1000 - GetTime()
      if remaining > 0 and remaining <= threshold then
        local t = 1 - (remaining / threshold)
        return 1 + (tR - 1) * t, 1 + (tG - 1) * t, 1 + (tB - 1) * t
      end
      return 1, 1, 1
    end)
    if ok2 and fr then r, g, b = fr, fg, fb end
  end
  local fontStrings = addonTable.GetCachedFontStrings(cooldownFrame)
  pcall(function()
    local prevR, prevG, prevB = cooldownFrame._ccmGradR, cooldownFrame._ccmGradG, cooldownFrame._ccmGradB
    if prevR == r and prevG == g and prevB == b then return end
    cooldownFrame._ccmGradR, cooldownFrame._ccmGradG, cooldownFrame._ccmGradB = r, g, b
    for i = 1, #fontStrings do
      fontStrings[i]:SetTextColor(r, g, b, 1)
    end
  end)
end
local function ResetCdTextGradient(cooldownFrame)
  if cooldownFrame._ccmGradR == 1 and cooldownFrame._ccmGradG == 1 and cooldownFrame._ccmGradB == 1 then return end
  cooldownFrame._ccmGradR, cooldownFrame._ccmGradG, cooldownFrame._ccmGradB = 1, 1, 1
  local fontStrings = addonTable.GetCachedFontStrings(cooldownFrame)
  for i = 1, #fontStrings do
    fontStrings[i]:SetTextColor(1, 1, 1, 1)
  end
end
local _buffBarBackdrop = {
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
local function UpdateBuffBarPosition(cursorX, cursorY, uiScale, profile)
  local buffs = BuffIconCooldownViewer
  if not buffs or not profile.useBuffBar then return end
  if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return end
  local posX = (cursorX / uiScale) + profile.offsetX
  local posY = (cursorY / uiScale) + profile.offsetY
  local scale = State.buffBarIconScale or 1
  buffs:ClearAllPoints()
  buffs:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", posX / scale, posY / scale)
end
local function UpdateBuffBar(cursorX, cursorY, uiScale, profile)
  if PatchAllCooldownViewerChargeMethods then
    PatchAllCooldownViewerChargeMethods()
  end
  if profile.disableBlizzCDM == true then
    if State.buffBarActive then
      RestoreBuffBarPosition()
      State.buffBarActive = false
    end
    return 0, 1
  end
  if not profile.useBuffBar then
    if State.buffBarActive then
      RestoreBuffBarPosition()
    end
    return 0, 1
  end
  if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
    if State.buffBarActive then
      RestoreBuffBarPosition()
    end
    return 0, 1
  end
  local buffs = BuffIconCooldownViewer
  if not buffs then
    return 0, 1
  end
  SaveBuffBarOriginals()
  State.buffBarActive = true
  local spacing = type(profile.iconSpacing) == "number" and profile.iconSpacing or 2
  State.buffBarSpacing = spacing
  local baseIconSize = type(profile.iconSize) == "number" and profile.iconSize or 23
  local buffBarOffset = type(profile.buffBarIconSizeOffset) == "number" and profile.buffBarIconSizeOffset or 0
  local targetSize = baseIconSize + buffBarOffset
  buffs:SetScale(1)
  local iconStrata = profile.iconStrata or "FULLSCREEN"
  buffs:SetFrameStrata(iconStrata)
  buffs:SetFrameLevel(200)
  local posX = (cursorX / uiScale) + profile.offsetX
  local posY = (cursorY / uiScale) + profile.offsetY
  wipe(State.buffBarVisibleIcons)
  local childCount = addonTable.CollectChildren(buffs, State.tmpChildren)
  for i = 1, childCount do
    local child = State.tmpChildren[i]
    PatchCooldownViewerIconChargeMethods(child)
    if child and child:IsShown() and child:GetWidth() > 5 then
      State.buffBarVisibleIcons[#State.buffBarVisibleIcons + 1] = child
    end
  end
  if #State.buffBarVisibleIcons > 1 then
    table.sort(State.buffBarVisibleIcons, layoutIndexSort)
  end
  local count = #State.buffBarVisibleIcons
  State.buffBarCount = count
  if count == 0 then
    buffs:ClearAllPoints()
    buffs:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", posX, posY)
    return 0, 1
  end
  buffs:ClearAllPoints()
  buffs:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", posX, posY)
  for i, icon in ipairs(State.buffBarVisibleIcons) do
    SanitizeCooldownViewerChargeState(icon)
    icon:SetSize(targetSize, targetSize)
    local iconX = (i - 1) * (targetSize + spacing)
    icon:ClearAllPoints()
    icon:SetPoint("BOTTOMLEFT", buffs, "BOTTOMLEFT", iconX, 0)
    local iconTexture = icon.Icon or icon.icon
    local doSkinning = profile.blizzardBarSkinning ~= false
    if iconTexture and not icon.ccmStripped and doSkinning then
      if iconTexture.GetMaskTexture then
        local idx = 1
        local mask = iconTexture:GetMaskTexture(idx)
        while mask do
          iconTexture:RemoveMaskTexture(mask)
          idx = idx + 1
          mask = iconTexture:GetMaskTexture(idx)
        end
      end
      local regionCount = addonTable.CollectRegions(icon, State.tmpRegions)
      for r = 1, regionCount do
        local region = State.tmpRegions[r]
        if region and region:IsObjectType("Texture") and region ~= iconTexture and region:IsShown() then
          region:SetTexture(nil)
          region:Hide()
        end
      end
      if icon.CooldownFlash then icon.CooldownFlash:SetAlpha(0) end
      if icon.DebuffBorder then icon.DebuffBorder:SetAlpha(0) end
      if icon.Border then icon.Border:Hide() end
      if icon.IconBorder then icon.IconBorder:Hide() end
      local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 0
      iconTexture:ClearAllPoints()
      iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      if borderSize > 0 and not icon.ccmBorderTop then
        icon.ccmBorderTop = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderTop:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderTop:SetHeight(borderSize)
        icon.ccmBorderBottom = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderBottom:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderBottom:SetHeight(borderSize)
        icon.ccmBorderLeft = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderLeft:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderLeft:SetWidth(borderSize)
        icon.ccmBorderRight = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderRight:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderRight:SetWidth(borderSize)
      end
      local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
      for c = 1, iconChildCount do
        local child = State.tmpIconChildren[c]
        if child and child:GetObjectType() == "Cooldown" then
          child:ClearAllPoints()
          child:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
          child:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
          child:SetSwipeColor(0, 0, 0, 0.8)
          child:SetDrawSwipe(true)
          child:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
          child:SetHideCountdownNumbers(false)
          icon.ccmCooldown = child
        end
      end
      if icon.ChargeCount and icon.ChargeCount.Current then
        icon.ccmChargeText = icon.ChargeCount.Current
      end
      if icon.Applications and icon.Applications.Applications then
        icon.ccmChargeText = icon.Applications.Applications
      end
      icon.ccmStripped = true
    end
    if icon.ccmStripped then
      local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 0
      if icon.ccmBorderTop then
        if borderSize > 0 then
          icon.ccmBorderTop:SetHeight(borderSize)
          icon.ccmBorderBottom:SetHeight(borderSize)
          icon.ccmBorderLeft:SetWidth(borderSize)
          icon.ccmBorderRight:SetWidth(borderSize)
          icon.ccmBorderTop:Show()
          icon.ccmBorderBottom:Show()
          icon.ccmBorderLeft:Show()
          icon.ccmBorderRight:Show()
        else
          icon.ccmBorderTop:Hide()
          icon.ccmBorderBottom:Hide()
          icon.ccmBorderLeft:Hide()
          icon.ccmBorderRight:Hide()
        end
      elseif borderSize > 0 then
        icon.ccmBorderTop = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderTop:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderTop:SetHeight(borderSize)
        icon.ccmBorderBottom = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderBottom:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderBottom:SetHeight(borderSize)
        icon.ccmBorderLeft = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderLeft:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderLeft:SetWidth(borderSize)
        icon.ccmBorderRight = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderRight:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderRight:SetWidth(borderSize)
      end
      iconTexture:ClearAllPoints()
      iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      if icon.ccmCooldown then
        icon.ccmCooldown:ClearAllPoints()
        icon.ccmCooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
        icon.ccmCooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      end
    end
    if icon.ccmChargeText and doSkinning then
      local stackPos = profile.stackTextPosition or "BOTTOMRIGHT"
      local stackOffX = profile.stackTextOffsetX or 0
      local stackOffY = profile.stackTextOffsetY or 0
      local stackScale = profile.stackTextScale or 1.0
      icon.ccmChargeText:ClearAllPoints()
      icon.ccmChargeText:SetPoint(stackPos, icon, stackPos, stackOffX, stackOffY)
      icon.ccmChargeText:SetScale(stackScale)
      icon.ccmChargeText:SetTextColor(1, 1, 1, 1)
    end
    if icon.ccmChargeText then
      local globalFont, globalOutline = GetGlobalFont()
      local _, ccmSize = GameFontHighlightLarge:GetFont()
      icon.ccmChargeText:SetFont(globalFont, ccmSize, globalOutline or "OUTLINE")
    end
    if icon.ccmCooldown then
      local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
      icon.ccmCooldown:SetScale((cdTextScale > 0 and cdTextScale or 1) * 0.8)
      icon.ccmCooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      local globalFont, globalOutline = GetGlobalFont()
      local regionCount = addonTable.CollectRegions(icon.ccmCooldown, State.tmpRegions)
      for r = 1, regionCount do
        local region = State.tmpRegions[r]
        if region and region:GetObjectType() == "FontString" then
          local _, size = region:GetFont()
          if size then
            region:SetFont(globalFont, size, globalOutline or "OUTLINE")
          end
        end
      end
    end
    if not doSkinning then
      local globalFont, globalOutline = GetGlobalFont()
      local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
      for c = 1, iconChildCount do
        local child = State.tmpIconChildren[c]
        if child and child:GetObjectType() == "Cooldown" then
          local regionCount = addonTable.CollectRegions(child, State.tmpChildRegions)
          for r = 1, regionCount do
            local region = State.tmpChildRegions[r]
            if region and region:GetObjectType() == "FontString" then
              local _, size = region:GetFont()
              if size then
                region:SetFont(globalFont, size, globalOutline or "OUTLINE")
              end
            end
          end
        end
      end
      local chargeText = (icon.ChargeCount and icon.ChargeCount.Current) or (icon.Applications and icon.Applications.Applications)
      if chargeText then
        local _, ccmSize = GameFontHighlightLarge:GetFont()
        chargeText:SetFont(globalFont, ccmSize, globalOutline or "OUTLINE")
      end
    end
    icon.ccmSkinned = doSkinning
    if Masque and profile.enableMasque and MasqueGroups.BuffBar and not icon.ccmMasqueAdded then
      SkinButtonWithMasque(icon, MasqueGroups.BuffBar)
      icon.ccmMasqueAdded = true
    end
  end
  if Masque and profile.enableMasque and MasqueGroups.BuffBar then
    MasqueGroups.BuffBar:ReSkin()
  end
  local totalWidth = count * targetSize + (count - 1) * spacing
  return totalWidth, 1
end
local _essentialBarBackdrop = {
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
local function UpdateEssentialBarPosition(cursorX, cursorY, uiScale, profile, buffBarWidth)
  local main = EssentialCooldownViewer
  if not main or not profile.useEssentialBar then return end
  if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return end
  local posX = (cursorX / uiScale) + profile.offsetX
  local posY = (cursorY / uiScale) + profile.offsetY
  local essentialBarX = posX + buffBarWidth
  local scale = State.essentialBarIconScale or 1
  main:ClearAllPoints()
  main:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", essentialBarX / scale, posY / scale)
end
local function UpdateEssentialBar(cursorX, cursorY, uiScale, profile, buffBarWidth)
  if PatchAllCooldownViewerChargeMethods then
    PatchAllCooldownViewerChargeMethods()
  end
  if profile.disableBlizzCDM == true then
    if State.essentialBarActive then
      RestoreEssentialBarPosition()
      State.essentialBarActive = false
    end
    return 0, 1
  end
  if not profile.useEssentialBar then
    if State.essentialBarActive then
      RestoreEssentialBarPosition()
    end
    return 0, 1
  end
  if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
    if State.essentialBarActive then
      RestoreEssentialBarPosition()
    end
    return 0, 1
  end
  local main = EssentialCooldownViewer
  if not main then
    return 0, 1
  end
  SaveEssentialBarOriginals()
  State.essentialBarActive = true
  local spacing = type(profile.iconSpacing) == "number" and profile.iconSpacing or 2
  State.essentialBarSpacing = spacing
  local targetSize = type(profile.iconSize) == "number" and profile.iconSize or 23
  main:SetScale(1)
  local iconStrata = profile.iconStrata or "FULLSCREEN"
  main:SetFrameStrata(iconStrata)
  main:SetFrameLevel(200)
  local posX = (cursorX / uiScale) + profile.offsetX
  local posY = (cursorY / uiScale) + profile.offsetY
  local essentialBarX = posX + buffBarWidth
  wipe(State.essentialBarVisibleIcons)
  local childCount = addonTable.CollectChildren(main, State.tmpChildren)
  for i = 1, childCount do
    local child = State.tmpChildren[i]
    PatchCooldownViewerIconChargeMethods(child)
    if child and child:IsShown() and child:GetWidth() > 5 then
      State.essentialBarVisibleIcons[#State.essentialBarVisibleIcons + 1] = child
    end
  end
  if #State.essentialBarVisibleIcons > 1 then
    table.sort(State.essentialBarVisibleIcons, layoutIndexSort)
  end
  local count = #State.essentialBarVisibleIcons
  if count == 0 then
    main:ClearAllPoints()
    main:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", essentialBarX, posY)
    return 0, 1
  end
  local padding = spacing
  main:ClearAllPoints()
  main:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", essentialBarX, posY)
  for i, icon in ipairs(State.essentialBarVisibleIcons) do
    SanitizeCooldownViewerChargeState(icon)
    local targetSize = type(profile.iconSize) == "number" and profile.iconSize or 23
    icon:SetSize(targetSize, targetSize)
    local iconX = (i - 1) * (targetSize + padding)
    icon:ClearAllPoints()
    icon:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", iconX, 0)
    local iconTexture = icon.Icon or icon.icon
    local doSkinning = profile.blizzardBarSkinning ~= false
    if iconTexture and not icon.ccmStripped and doSkinning then
      if iconTexture.GetMaskTexture then
        local idx = 1
        local mask = iconTexture:GetMaskTexture(idx)
        while mask do
          iconTexture:RemoveMaskTexture(mask)
          idx = idx + 1
          mask = iconTexture:GetMaskTexture(idx)
        end
      end
      local regionCount = addonTable.CollectRegions(icon, State.tmpRegions)
      for r = 1, regionCount do
        local region = State.tmpRegions[r]
        if region and region:IsObjectType("Texture") and region ~= iconTexture and region:IsShown() then
          region:SetTexture(nil)
          region:Hide()
        end
      end
      if icon.CooldownFlash then icon.CooldownFlash:SetAlpha(0) end
      if icon.DebuffBorder then icon.DebuffBorder:SetAlpha(0) end
      if icon.Border then icon.Border:Hide() end
      if icon.IconBorder then icon.IconBorder:Hide() end
      local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 0
      iconTexture:ClearAllPoints()
      iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      if borderSize > 0 and not icon.ccmBorderTop then
        icon.ccmBorderTop = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderTop:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderTop:SetHeight(borderSize)
        icon.ccmBorderBottom = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderBottom:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderBottom:SetHeight(borderSize)
        icon.ccmBorderLeft = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderLeft:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderLeft:SetWidth(borderSize)
        icon.ccmBorderRight = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderRight:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderRight:SetWidth(borderSize)
      end
      local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
      for c = 1, iconChildCount do
        local child = State.tmpIconChildren[c]
        if child and child:GetObjectType() == "Cooldown" then
          child:ClearAllPoints()
          child:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
          child:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
          child:SetSwipeColor(0, 0, 0, 0.8)
          child:SetDrawSwipe(true)
          child:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
          child:SetHideCountdownNumbers(false)
          icon.ccmCooldown = child
        end
      end
      if icon.ChargeCount and icon.ChargeCount.Current then
        icon.ccmChargeText = icon.ChargeCount.Current
      end
      icon.ccmStripped = true
    end
    if icon.ccmStripped then
      local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 0
      if icon.ccmBorderTop then
        if borderSize > 0 then
          icon.ccmBorderTop:SetHeight(borderSize)
          icon.ccmBorderBottom:SetHeight(borderSize)
          icon.ccmBorderLeft:SetWidth(borderSize)
          icon.ccmBorderRight:SetWidth(borderSize)
          icon.ccmBorderTop:Show()
          icon.ccmBorderBottom:Show()
          icon.ccmBorderLeft:Show()
          icon.ccmBorderRight:Show()
        else
          icon.ccmBorderTop:Hide()
          icon.ccmBorderBottom:Hide()
          icon.ccmBorderLeft:Hide()
          icon.ccmBorderRight:Hide()
        end
      elseif borderSize > 0 then
        icon.ccmBorderTop = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderTop:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderTop:SetHeight(borderSize)
        icon.ccmBorderBottom = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderBottom:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderBottom:SetHeight(borderSize)
        icon.ccmBorderLeft = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderLeft:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        icon.ccmBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        icon.ccmBorderLeft:SetWidth(borderSize)
        icon.ccmBorderRight = icon:CreateTexture(nil, "OVERLAY")
        icon.ccmBorderRight:SetColorTexture(0, 0, 0, 1)
        icon.ccmBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        icon.ccmBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        icon.ccmBorderRight:SetWidth(borderSize)
      end
      iconTexture:ClearAllPoints()
      iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      if icon.ccmCooldown then
        icon.ccmCooldown:ClearAllPoints()
        icon.ccmCooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
        icon.ccmCooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      end
    end
    if icon.ccmChargeText and doSkinning then
      local stackPos = profile.stackTextPosition or "BOTTOMRIGHT"
      local stackOffX = profile.stackTextOffsetX or 0
      local stackOffY = profile.stackTextOffsetY or 0
      local stackScale = profile.stackTextScale or 1.0
      icon.ccmChargeText:ClearAllPoints()
      icon.ccmChargeText:SetPoint(stackPos, icon, stackPos, stackOffX, stackOffY)
      icon.ccmChargeText:SetScale(stackScale)
      icon.ccmChargeText:SetTextColor(1, 1, 1, 1)
    end
    if icon.ccmChargeText then
      local globalFont, globalOutline = GetGlobalFont()
      local _, ccmSize = GameFontHighlightLarge:GetFont()
      icon.ccmChargeText:SetFont(globalFont, ccmSize, globalOutline or "OUTLINE")
    end
    if icon.ccmCooldown and doSkinning then
      local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
      icon.ccmCooldown:SetScale((cdTextScale > 0 and cdTextScale or 1) * 0.8)
      icon.ccmCooldown:SetHideCountdownNumbers(cdTextScale <= 0)
    end
    if icon.ccmCooldown then
      local globalFont, globalOutline = GetGlobalFont()
      local regionCount = addonTable.CollectRegions(icon.ccmCooldown, State.tmpRegions)
      for r = 1, regionCount do
        local region = State.tmpRegions[r]
        if region and region:GetObjectType() == "FontString" then
          local _, size = region:GetFont()
          if size then
            region:SetFont(globalFont, size, globalOutline or "OUTLINE")
          end
        end
      end
    end
    if not doSkinning then
      local globalFont, globalOutline = GetGlobalFont()
      local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
      for c = 1, iconChildCount do
        local child = State.tmpIconChildren[c]
        if child and child:GetObjectType() == "Cooldown" then
          local regionCount = addonTable.CollectRegions(child, State.tmpChildRegions)
          for r = 1, regionCount do
            local region = State.tmpChildRegions[r]
            if region and region:GetObjectType() == "FontString" then
              local _, size = region:GetFont()
              if size then
                region:SetFont(globalFont, size, globalOutline or "OUTLINE")
              end
            end
          end
        end
      end
      local chargeText = (icon.ChargeCount and icon.ChargeCount.Current) or (icon.Applications and icon.Applications.Applications)
      if chargeText then
        local _, ccmSize = GameFontHighlightLarge:GetFont()
        chargeText:SetFont(globalFont, ccmSize, globalOutline or "OUTLINE")
      end
    end
    icon.ccmSkinned = doSkinning
    if Masque and profile.enableMasque and MasqueGroups.EssentialBar and not icon.ccmMasqueAdded then
      SkinButtonWithMasque(icon, MasqueGroups.EssentialBar)
      icon.ccmMasqueAdded = true
    end
  end
  if Masque and profile.enableMasque and MasqueGroups.EssentialBar then
    MasqueGroups.EssentialBar:ReSkin()
  end
  local targetSize = type(profile.iconSize) == "number" and profile.iconSize or 23
  local totalWidth = count * targetSize + (count - 1) * padding
  return totalWidth, 1
end
local function ResetBlizzardBarSkinning()
  local profile = addonTable.GetProfile()
  local buffs = BuffIconCooldownViewer
  if buffs then
    local childCount = addonTable.CollectChildren(buffs, State.tmpChildren)
    for i = 1, childCount do
      local child = State.tmpChildren[i]
      if child.ccmBackdrop then
        child.ccmBackdrop:SetBackdrop(nil)
        child.ccmBackdrop:Hide()
      end
      local iconTexture = child.Icon or child.icon
      if iconTexture then
        iconTexture:ClearAllPoints()
        iconTexture:SetAllPoints(child)
        iconTexture:SetTexCoord(0, 1, 0, 1)
      end
      if child.ccmCooldown then
        child.ccmCooldown:ClearAllPoints()
        child.ccmCooldown:SetAllPoints(child)
        child.ccmCooldown:SetScale(1)
        child.ccmCooldown:SetDrawEdge(false)
      end
      if child.ccmChargeText then
        child.ccmChargeText:SetScale(1)
      end
      child.ccmSkinned = false
      child.ccmStripped = false
      child.ccmLastBorder = nil
    end
  end
  local main = EssentialCooldownViewer
  if main then
    local childCount = addonTable.CollectChildren(main, State.tmpChildren)
    for i = 1, childCount do
      local child = State.tmpChildren[i]
      if child.ccmBackdrop then
        child.ccmBackdrop:SetBackdrop(nil)
        child.ccmBackdrop:Hide()
      end
      local iconTexture = child.Icon or child.icon
      if iconTexture then
        iconTexture:ClearAllPoints()
        iconTexture:SetAllPoints(child)
        iconTexture:SetTexCoord(0, 1, 0, 1)
      end
      if child.ccmCooldown then
        child.ccmCooldown:ClearAllPoints()
        child.ccmCooldown:SetAllPoints(child)
        child.ccmCooldown:SetScale(1)
        child.ccmCooldown:SetDrawEdge(false)
      end
      if child.ccmChargeText then
        child.ccmChargeText:SetScale(1)
      end
      child.ccmSkinned = false
      child.ccmStripped = false
      child.ccmLastBorder = nil
    end
  end
end
addonTable.RestoreEssentialBarPosition = RestoreEssentialBarPosition
addonTable.RestoreBuffBarPosition = RestoreBuffBarPosition
addonTable.ResetBlizzardBarSkinning = ResetBlizzardBarSkinning
addonTable.UpdateEssentialBar = UpdateEssentialBar
addonTable.UpdateBuffBar = UpdateBuffBar
local function SaveStandaloneBarOriginals(bar, origTable)
  if not bar or origTable.saved then return end
  local point, relativeTo, relativePoint, xOfs, yOfs = bar:GetPoint(1)
  origTable.point = point or "CENTER"
  origTable.relativeTo = relativeTo or UIParent
  origTable.relativePoint = relativePoint or "CENTER"
  origTable.xOfs = xOfs or 0
  origTable.yOfs = yOfs or 0
  origTable.scale = bar:GetScale() or 1
  origTable.saved = true
end
local function RestoreStandaloneBar(bar, origTable)
  if InCombatLockdown() then return end
  if not bar or not origTable.saved then return end
  bar:ClearAllPoints()
  bar:SetPoint(origTable.point, origTable.relativeTo or UIParent, origTable.relativePoint, origTable.xOfs, origTable.yOfs)
  if origTable.scale then
    bar:SetScale(origTable.scale)
  end
  origTable.saved = false
end
local function SetPointSnapped(frame, point, relativeTo, relativePoint, xOfs, yOfs)
  if PixelUtil and PixelUtil.SetPoint then
    PixelUtil.SetPoint(frame, point, relativeTo, relativePoint, xOfs or 0, yOfs or 0)
  else
    frame:SetPoint(point, relativeTo, relativePoint, xOfs or 0, yOfs or 0)
  end
end
local function SetPointIfChanged(frame, point, relativeTo, relativePoint, xOfs, yOfs)
  xOfs = xOfs or 0
  yOfs = yOfs or 0
  if frame.GetNumPoints and frame:GetNumPoints() == 1 and frame.GetPoint then
    local p, rel, rp, ox, oy = frame:GetPoint(1)
    if p == point and rel == relativeTo and rp == relativePoint then
      local dx = math.abs((ox or 0) - xOfs)
      local dy = math.abs((oy or 0) - yOfs)
      if dx < 0.5 and dy < 0.5 then return end
    end
  end
  frame:ClearAllPoints()
  SetPointSnapped(frame, point, relativeTo, relativePoint, xOfs, yOfs)
end
SanitizeCooldownViewerChargeState = function(icon)
  if not icon then return end
  local function IsSecretValue(v)
    return issecretvalue and issecretvalue(v) or false
  end
  local function ToSafeNumber(v, defaultValue)
    if v == nil then return defaultValue end
    if IsSecretValue(v) then return defaultValue end
    local ok, n = pcall(tonumber, v)
    if ok and type(n) == "number" then return n end
    return defaultValue
  end
  local function ToSafeSpellID(v)
    local n = ToSafeNumber(v, nil)
    if type(n) ~= "number" or n <= 0 then return nil end
    return math.floor(n + 0.5)
  end
  local function SanitizeChargeTable(tbl)
    if type(tbl) ~= "table" then return end
    if IsSecretValue(tbl.currentCharges) then tbl.currentCharges = nil end
    if IsSecretValue(tbl.maxCharges) then tbl.maxCharges = nil end
    if IsSecretValue(tbl.cooldownStartTime) then tbl.cooldownStartTime = nil end
    if IsSecretValue(tbl.cooldownDuration) then tbl.cooldownDuration = nil end
    if IsSecretValue(tbl.chargeModRate) then tbl.chargeModRate = nil end
    local cur = ToSafeNumber(tbl.currentCharges, nil)
    local maxC = ToSafeNumber(tbl.maxCharges, nil)
    local st = ToSafeNumber(tbl.cooldownStartTime, nil)
    local dur = ToSafeNumber(tbl.cooldownDuration, nil)
    local mod = ToSafeNumber(tbl.chargeModRate, nil)
    if cur ~= nil then tbl.currentCharges = cur end
    if maxC ~= nil then tbl.maxCharges = maxC end
    if st ~= nil then tbl.cooldownStartTime = st end
    if dur ~= nil then tbl.cooldownDuration = dur end
    if mod ~= nil then tbl.chargeModRate = mod end
  end

  icon.previousCooldownChargesCount = ToSafeNumber(icon.previousCooldownChargesCount, 0)
  icon.cooldownChargesCount = ToSafeNumber(icon.cooldownChargesCount, 0)
  icon.cooldownStartTime = ToSafeNumber(icon.cooldownStartTime, 0)
  icon.cooldownDuration = ToSafeNumber(icon.cooldownDuration, 0)
  icon.cooldownModRate = ToSafeNumber(icon.cooldownModRate, 1)
  if IsSecretValue(icon.cooldownEnabled) then
    icon.cooldownEnabled = true
  end

  SanitizeChargeTable(icon.spellChargeInfo)
  SanitizeChargeTable(icon.cooldownChargesInfo)
end
local function CooldownViewerIsSecretValueError(err)
  local msg = tostring(err or "")
  return msg:find("secret value", 1, true) ~= nil
end
local function CooldownViewerToSafeNumber(v, defaultValue)
  if v == nil then return defaultValue end
  if issecretvalue and issecretvalue(v) then return defaultValue end
  local ok, n = pcall(tonumber, v)
  if ok and type(n) == "number" then return n end
  return defaultValue
end
local function CooldownViewerToSafeSpellID(v)
  local n = CooldownViewerToSafeNumber(v, nil)
  if type(n) ~= "number" or n <= 0 then return nil end
  return math.floor(n + 0.5)
end
local function ApplyCooldownViewerChargeFallback(icon, count, shown)
  if not icon then return end
  local safeCount = CooldownViewerToSafeNumber(count, 0) or 0
  if safeCount < 0 then safeCount = 0 end
  local safeShown = shown == true
  icon.previousCooldownChargesCount = CooldownViewerToSafeNumber(icon.cooldownChargesCount, 0) or 0
  icon.cooldownChargesCount = safeCount
  icon.cooldownChargesShown = safeShown

  local chargeText = nil
  if icon.ChargeCount and icon.ChargeCount.Current then
    chargeText = icon.ChargeCount.Current
  elseif icon.Applications and icon.Applications.Applications then
    chargeText = icon.Applications.Applications
  end
  if chargeText and chargeText.SetText then
    if safeShown then
      pcall(chargeText.SetText, chargeText, tostring(math.floor(safeCount + 0.5)))
      if chargeText.Show then pcall(chargeText.Show, chargeText) end
    else
      pcall(chargeText.SetText, chargeText, "")
      if chargeText.Hide then pcall(chargeText.Hide, chargeText) end
    end
  end
end
local function BuildCooldownViewerFallbackChargeState(icon)
  local count = CooldownViewerToSafeNumber(icon and icon.cooldownChargesCount, 0) or 0
  local shown = (icon and icon.cooldownChargesShown == true) or false
  local spellID = nil
  if icon and type(icon.cooldownInfo) == "table" then
    spellID = icon.cooldownInfo.overrideSpellID or icon.cooldownInfo.spellID
  end
  if not spellID and icon then
    spellID = icon.rangeCheckSpellID
  end
  spellID = CooldownViewerToSafeSpellID(spellID)
  if spellID and C_Spell and C_Spell.GetSpellCharges then
    local okCharges, chargeInfo = pcall(C_Spell.GetSpellCharges, spellID)
    if okCharges and type(chargeInfo) == "table" then
      local cur = CooldownViewerToSafeNumber(chargeInfo.currentCharges, nil)
      local maxC = CooldownViewerToSafeNumber(chargeInfo.maxCharges, nil)
      if cur ~= nil then count = cur end
      if maxC ~= nil then
        shown = maxC > 1
      end
    end
  end
  if count < 0 then count = 0 end
  return count, shown
end
local function GetPublicSpellCooldownInfo(spellID)
  local info = { startTime = 0, duration = 0, isEnabled = false, modRate = 1 }
  local sid = CooldownViewerToSafeSpellID(spellID)
  if sid and GetSpellCooldown then
    local ok, st, dur, en, mod = pcall(GetSpellCooldown, sid)
    if ok then
      info.startTime = CooldownViewerToSafeNumber(st, info.startTime)
      info.duration = CooldownViewerToSafeNumber(dur, info.duration)
      if en ~= nil then
        info.isEnabled = (en == true or en == 1)
      end
      info.modRate = CooldownViewerToSafeNumber(mod, info.modRate)
    end
  end
  if sid and C_Spell and C_Spell.GetSpellCooldown then
    local ok, cd = pcall(C_Spell.GetSpellCooldown, sid)
    if ok and type(cd) == "table" then
      local st = CooldownViewerToSafeNumber(cd.startTime, nil)
      local dur = CooldownViewerToSafeNumber(cd.duration, nil)
      local mod = CooldownViewerToSafeNumber(cd.modRate, nil)
      if st ~= nil then info.startTime = st end
      if dur ~= nil then info.duration = dur end
      if mod ~= nil then info.modRate = mod end
      if cd.isEnabled ~= nil and not (issecretvalue and issecretvalue(cd.isEnabled)) then
        info.isEnabled = (cd.isEnabled == true)
      end
    end
  end
  if info.startTime < 0 then info.startTime = 0 end
  if info.duration < 0 then info.duration = 0 end
  if info.modRate <= 0 then info.modRate = 1 end
  return info
end
local function SanitizeCooldownViewerSpellCooldownInfo(spellCooldownInfo, spellID)
  local fallback = GetPublicSpellCooldownInfo(spellID)
  if type(spellCooldownInfo) ~= "table" then
    return fallback
  end
  local function SafeNum(v, defaultValue)
    if v == nil then return defaultValue end
    if issecretvalue and issecretvalue(v) then return defaultValue end
    local ok, n = pcall(tonumber, v)
    if ok and type(n) == "number" then return n end
    return defaultValue
  end
  spellCooldownInfo.startTime = SafeNum(spellCooldownInfo.startTime, fallback.startTime)
  spellCooldownInfo.duration = SafeNum(spellCooldownInfo.duration, fallback.duration)
  spellCooldownInfo.modRate = SafeNum(spellCooldownInfo.modRate, fallback.modRate)
  if issecretvalue and issecretvalue(spellCooldownInfo.isEnabled) then
    spellCooldownInfo.isEnabled = fallback.isEnabled
  else
    if spellCooldownInfo.isEnabled == nil then
      spellCooldownInfo.isEnabled = fallback.isEnabled
    else
      spellCooldownInfo.isEnabled = (spellCooldownInfo.isEnabled == true or spellCooldownInfo.isEnabled == 1)
    end
  end
  if spellCooldownInfo.startTime < 0 then spellCooldownInfo.startTime = 0 end
  if spellCooldownInfo.duration < 0 then spellCooldownInfo.duration = 0 end
  if spellCooldownInfo.modRate <= 0 then spellCooldownInfo.modRate = 1 end
  return spellCooldownInfo
end
local function PatchCooldownViewerMethodContainer(container)
  -- Safety: avoid tainting Blizzard CooldownViewer internals.
  -- Runtime monkey-patching these method tables can propagate taint into secure/secret values.
  if true then return end
  if type(container) ~= "table" then return end
  local function WrapMethod(methodName, markerName, wrapperFactory)
    if container[markerName] then return end
    local original = container[methodName]
    if type(original) ~= "function" then return end
    container[methodName] = wrapperFactory(original)
    container[markerName] = true
  end

  WrapMethod("SetCachedChargeValues", "_ccmPatchedSetCachedChargeValues", function(originalSetCachedChargeValues)
    return function(self, count, shown, considerAddingAlert)
      SanitizeCooldownViewerChargeState(self)
      local safeCount = CooldownViewerToSafeNumber(count, 0) or 0
      if safeCount < 0 then safeCount = 0 end
      local safeShown = shown == true
      local ok, r1, r2, r3, r4 = pcall(originalSetCachedChargeValues, self, safeCount, safeShown, considerAddingAlert)
      if ok then
        SanitizeCooldownViewerChargeState(self)
        return r1, r2, r3, r4
      end
      if not CooldownViewerIsSecretValueError(r1) then error(r1, 0) end
      ApplyCooldownViewerChargeFallback(self, safeCount, safeShown)
      return nil
    end
  end)

  WrapMethod("CacheChargeValues", "_ccmPatchedCacheChargeValues", function(originalCacheChargeValues)
    return function(self, ...)
      SanitizeCooldownViewerChargeState(self)
      local ok, r1, r2, r3, r4 = pcall(originalCacheChargeValues, self, ...)
      if ok then
        SanitizeCooldownViewerChargeState(self)
        return r1, r2, r3, r4
      end
      if not CooldownViewerIsSecretValueError(r1) then error(r1, 0) end
      local count, shown = BuildCooldownViewerFallbackChargeState(self)
      if type(self.SetCachedChargeValues) == "function" then
        local okSet = pcall(self.SetCachedChargeValues, self, count, shown, true)
        if okSet then return nil end
      end
      ApplyCooldownViewerChargeFallback(self, count, shown)
      return nil
    end
  end)

  WrapMethod("CheckCacheCooldownValuesFromSpellCooldown", "_ccmPatchedCheckCacheCooldownValuesFromSpellCooldown", function(originalCheckCacheCooldownValuesFromSpellCooldown)
    return function(self, timeNow, spellID, spellCooldownInfo, ...)
      SanitizeCooldownViewerChargeState(self)
      local safeTimeNow = CooldownViewerToSafeNumber(timeNow, (GetTime and GetTime() or 0))
      local safeSpellID = spellID
      if issecretvalue and issecretvalue(spellID) then
        safeSpellID = nil
      else
        local sid = CooldownViewerToSafeSpellID(spellID)
        if sid ~= nil then safeSpellID = sid end
      end
      local refSpellID = safeSpellID
      if refSpellID == nil and self and type(self.cooldownInfo) == "table" then
        refSpellID = self.cooldownInfo.overrideSpellID or self.cooldownInfo.spellID
      end
      if refSpellID == nil and self then
        refSpellID = self.rangeCheckSpellID
      end
      refSpellID = CooldownViewerToSafeSpellID(refSpellID)
      local safeInfo = SanitizeCooldownViewerSpellCooldownInfo(spellCooldownInfo, refSpellID)
      local ok, ret = pcall(originalCheckCacheCooldownValuesFromSpellCooldown, self, safeTimeNow, safeSpellID, safeInfo, ...)
      if ok then
        SanitizeCooldownViewerChargeState(self)
        return ret
      end
      if not CooldownViewerIsSecretValueError(ret) then error(ret, 0) end
      local fallbackInfo = GetPublicSpellCooldownInfo(refSpellID)
      local ok2, ret2 = pcall(originalCheckCacheCooldownValuesFromSpellCooldown, self, safeTimeNow, refSpellID, fallbackInfo, ...)
      if ok2 then return ret2 end
      if not CooldownViewerIsSecretValueError(ret2) then error(ret2, 0) end
      return true
    end
  end)

  WrapMethod("CacheCooldownValues", "_ccmPatchedCacheCooldownValues", function(originalCacheCooldownValues)
    return function(self, ...)
      SanitizeCooldownViewerChargeState(self)
      local ok, r1, r2, r3, r4 = pcall(originalCacheCooldownValues, self, ...)
      if ok then
        SanitizeCooldownViewerChargeState(self)
        return r1, r2, r3, r4
      end
      if not CooldownViewerIsSecretValueError(r1) then error(r1, 0) end
      local sid = nil
      if self and type(self.cooldownInfo) == "table" then
        sid = self.cooldownInfo.overrideSpellID or self.cooldownInfo.spellID
      end
      if sid == nil and self then
        sid = self.rangeCheckSpellID
      end
      sid = CooldownViewerToSafeSpellID(sid)
      local fb = GetPublicSpellCooldownInfo(sid)
      if self then
        self.cooldownStartTime = fb.startTime or 0
        self.cooldownDuration = fb.duration or 0
        self.cooldownModRate = fb.modRate or 1
        self.cooldownEnabled = fb.isEnabled == true
        local now = GetTime and GetTime() or 0
        self.cooldownIsActive = self.cooldownEnabled and (self.cooldownDuration > 0)
        self.isOnActualCooldown = self.cooldownIsActive and (now < (self.cooldownStartTime + self.cooldownDuration))
        if self.Cooldown and self.Cooldown.SetCooldown then
          pcall(self.Cooldown.SetCooldown, self.Cooldown, self.cooldownStartTime, self.cooldownDuration, self.cooldownModRate)
        end
      end
      return nil
    end
  end)

  WrapMethod("NeedsAddedAuraUpdate", "_ccmPatchedNeedsAddedAuraUpdate", function(originalNeedsAddedAuraUpdate)
    return function(self, spellID, ...)
      SanitizeCooldownViewerChargeState(self)
      if issecretvalue and issecretvalue(spellID) then return true end
      local argSpellID = spellID
      local safeSpellID = CooldownViewerToSafeSpellID(spellID)
      if safeSpellID ~= nil then
        argSpellID = safeSpellID
      end
      local ok, ret = pcall(originalNeedsAddedAuraUpdate, self, argSpellID, ...)
      if ok then return ret end
      if not CooldownViewerIsSecretValueError(ret) then error(ret, 0) end
      return true
    end
  end)

  WrapMethod("SpellIDMatchesAnyAssociatedSpellIDs", "_ccmPatchedSpellIDMatchesAnyAssociatedSpellIDs", function(originalSpellIDMatchesAnyAssociatedSpellIDs)
    return function(self, spellID, ...)
      if issecretvalue and issecretvalue(spellID) then return true end
      local argSpellID = spellID
      local safeSpellID = CooldownViewerToSafeSpellID(spellID)
      if safeSpellID ~= nil then
        argSpellID = safeSpellID
      end
      local ok, ret = pcall(originalSpellIDMatchesAnyAssociatedSpellIDs, self, argSpellID, ...)
      if ok then return ret end
      if not CooldownViewerIsSecretValueError(ret) then error(ret, 0) end
      return true
    end
  end)

end
PatchCooldownViewerIconChargeMethods = function(icon)
  if not icon then return end
  if icon.GetObjectType and icon:GetObjectType() ~= "Frame" then return end

  SanitizeCooldownViewerChargeState(icon)
  PatchCooldownViewerMethodContainer(icon)
end
PatchAllCooldownViewerChargeMethods = function()
  local now = GetTime and GetTime() or 0
  if (not State.cooldownViewerLastGlobalWrapScan) or ((now - State.cooldownViewerLastGlobalWrapScan) >= 2) then
    for gName, gValue in pairs(_G) do
      if type(gName) == "string" and gName:find("CooldownViewer") and type(gValue) == "table" then
        PatchCooldownViewerMethodContainer(gValue)
      end
    end
    State.cooldownViewerLastGlobalWrapScan = now
  end

  local function PatchFrameChildren(frame, depth)
    if not frame then return end
    depth = depth or 0
    if depth > 6 then return end
    local childCount = (frame.GetNumChildren and frame:GetNumChildren()) or 0
    for i = 1, childCount do
      local child = select(i, frame:GetChildren())
      PatchCooldownViewerIconChargeMethods(child)
      PatchFrameChildren(child, depth + 1)
    end
  end
  PatchFrameChildren(BuffIconCooldownViewer, 0)
  PatchFrameChildren(EssentialCooldownViewer, 0)
  PatchFrameChildren(UtilityCooldownViewer, 0)
end
SanitizeCooldownViewerChargeState = function() end
PatchCooldownViewerIconChargeMethods = function() end
PatchAllCooldownViewerChargeMethods = function() end
addonTable.LayoutStandaloneRows = function(frame, visibleIcons, numCols, firstRowSize, secondRowSize, spacing, centered, growLeft, growUp, maxRows, pinFirstRowY)
  if not frame or not visibleIcons or #visibleIcons == 0 then return 0, 0 end
  local function SnapHalf(v)
    return math.floor((v or 0) * 2 + 0.5) / 2
  end
  local rowSpacing = spacing
  if type(rowSpacing) ~= "number" then rowSpacing = 0 end
  if rowSpacing < 0 then rowSpacing = 0 end
  if type(numCols) ~= "number" or numCols < 1 then numCols = #visibleIcons end
  if type(maxRows) ~= "number" or maxRows < 1 then maxRows = 2 end
  if maxRows == 1 then
    numCols = #visibleIcons
  else
    numCols = math.max(1, math.max(numCols, math.ceil(#visibleIcons / maxRows)))
  end
  local rowCount = math.max(1, math.ceil(#visibleIcons / numCols))
  local rowSizes, rowWidths, rowIconCounts = {}, {}, {}
  local remaining = #visibleIcons
  local totalWidth = 0
  local totalHeight = 0
  for row = 1, rowCount do
    local iconsInRow = math.min(numCols, remaining)
    remaining = remaining - iconsInRow
    rowIconCounts[row] = iconsInRow
    local size = (row == 2 and type(secondRowSize) == "number" and secondRowSize > 5) and secondRowSize or firstRowSize
    rowSizes[row] = size
    local width = (iconsInRow * size) + ((iconsInRow - 1) * spacing)
    rowWidths[row] = width
    if width > totalWidth then totalWidth = width end
    totalHeight = totalHeight + size
    if row > 1 then totalHeight = totalHeight + rowSpacing end
  end
  totalWidth = math.floor(totalWidth + 0.5)
  totalHeight = math.floor(totalHeight + 0.5)
  local canResizeFrame = true
  if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
    canResizeFrame = false
  end
  if canResizeFrame then
    if pinFirstRowY then
      frame:SetSize(totalWidth, firstRowSize)
    else
      frame:SetSize(totalWidth, totalHeight)
    end
  end
  local iconIndex = 1
  local yTop = 0
  local yAbove = 0
  for row = 1, rowCount do
    local iconsInRow = rowIconCounts[row]
    local size = rowSizes[row]
    local rowWidth = rowWidths[row]
    local startX = centered and ((totalWidth - rowWidth) / 2) or 0
    if (not centered) and growLeft then
      startX = totalWidth - rowWidth
    end
    if row > 1 and growUp and pinFirstRowY then
      yAbove = yAbove + rowSpacing + size
    end
    for col = 1, iconsInRow do
      local icon = visibleIcons[iconIndex]
      if icon then
        local vCol = growLeft and (iconsInRow - col) or (col - 1)
      local xPos = startX + (vCol * (size + spacing))
      icon:SetSize(size, size)
      local targetX = SnapHalf(xPos)
      local targetY
      if growUp then
        local yPos
        if pinFirstRowY then
          yPos = row == 1 and 0 or -yAbove
        else
          yPos = totalHeight - yTop - size
        end
        targetY = -SnapHalf(yPos)
      else
        targetY = -SnapHalf(yTop)
      end
      SetPointIfChanged(icon, "TOPLEFT", frame, "TOPLEFT", targetX, targetY)
      end
      iconIndex = iconIndex + 1
    end
    yTop = yTop + size + rowSpacing
  end
  return totalWidth, totalHeight
end
local function SkinStandaloneBarIcon(icon, profile, barType)
  if not icon or not icon:IsShown() or icon:GetWidth() <= 5 then return end
  PatchCooldownViewerIconChargeMethods(icon)
  SanitizeCooldownViewerChargeState(icon)
  local iconTexture = icon.Icon or icon.icon
  if not iconTexture then return end
  local doSkinning = profile.blizzardBarSkinning ~= false
  local borderSize = type(profile.standaloneIconBorderSize) == "number" and profile.standaloneIconBorderSize or (type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1)
  do
    local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
    for c = 1, iconChildCount do
      local child = State.tmpIconChildren[c]
      if child and child:GetObjectType() == "Cooldown" then
        icon.ccmStandaloneCooldown = child
        break
      end
    end
    if icon.ChargeCount and icon.ChargeCount.Current then
      icon.ccmStandaloneChargeText = icon.ChargeCount.Current
    end
    if icon.Applications and icon.Applications.Applications then
      icon.ccmStandaloneChargeText = icon.Applications.Applications
    end
  end
  if not icon.ccmStandaloneSkinned and doSkinning then
    if iconTexture.GetMaskTexture then
      local idx = 1
      local mask = iconTexture:GetMaskTexture(idx)
      while mask do
        iconTexture:RemoveMaskTexture(mask)
        idx = idx + 1
        mask = iconTexture:GetMaskTexture(idx)
      end
    end
    local regionCount = addonTable.CollectRegions(icon, State.tmpRegions)
    for r = 1, regionCount do
      local region = State.tmpRegions[r]
      if region and region:IsObjectType("Texture") and region ~= iconTexture and region:IsShown() then
        region:SetTexture(nil)
        region:Hide()
      end
    end
    if icon.CooldownFlash then icon.CooldownFlash:SetAlpha(0) end
    if icon.DebuffBorder then icon.DebuffBorder:SetAlpha(0) end
    if icon.Border then icon.Border:Hide() end
    if icon.IconBorder then icon.IconBorder:Hide() end
    iconTexture:ClearAllPoints()
    iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
    iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
    iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if borderSize > 0 and not icon.ccmBorderTop then
      icon.ccmBorderTop = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderTop:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
      icon.ccmBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
      icon.ccmBorderTop:SetHeight(borderSize)
      icon.ccmBorderBottom = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderBottom:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
      icon.ccmBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
      icon.ccmBorderBottom:SetHeight(borderSize)
      icon.ccmBorderLeft = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderLeft:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
      icon.ccmBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
      icon.ccmBorderLeft:SetWidth(borderSize)
      icon.ccmBorderRight = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderRight:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
      icon.ccmBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
      icon.ccmBorderRight:SetWidth(borderSize)
    end
    local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
    for c = 1, iconChildCount do
      local child = State.tmpIconChildren[c]
      if child and child:GetObjectType() == "Cooldown" then
        child:ClearAllPoints()
        child:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
        child:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
        child:SetSwipeColor(0, 0, 0, 0.8)
        child:SetDrawSwipe(true)
        child:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
        child:SetHideCountdownNumbers(false)
        icon.ccmStandaloneCooldown = child
      end
    end
    if icon.ChargeCount and icon.ChargeCount.Current then
      icon.ccmStandaloneChargeText = icon.ChargeCount.Current
    end
    if icon.Applications and icon.Applications.Applications then
      icon.ccmStandaloneChargeText = icon.Applications.Applications
    end
    icon.ccmStandaloneSkinned = true
  end
  if icon.ccmStandaloneSkinned then
    if icon.ccmBorderTop then
      if borderSize > 0 then
        icon.ccmBorderTop:SetHeight(borderSize)
        icon.ccmBorderBottom:SetHeight(borderSize)
        icon.ccmBorderLeft:SetWidth(borderSize)
        icon.ccmBorderRight:SetWidth(borderSize)
        icon.ccmBorderTop:Show()
        icon.ccmBorderBottom:Show()
        icon.ccmBorderLeft:Show()
        icon.ccmBorderRight:Show()
      else
        icon.ccmBorderTop:Hide()
        icon.ccmBorderBottom:Hide()
        icon.ccmBorderLeft:Hide()
        icon.ccmBorderRight:Hide()
      end
    elseif borderSize > 0 then
      icon.ccmBorderTop = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderTop:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
      icon.ccmBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
      icon.ccmBorderTop:SetHeight(borderSize)
      icon.ccmBorderBottom = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderBottom:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
      icon.ccmBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
      icon.ccmBorderBottom:SetHeight(borderSize)
      icon.ccmBorderLeft = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderLeft:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
      icon.ccmBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
      icon.ccmBorderLeft:SetWidth(borderSize)
      icon.ccmBorderRight = icon:CreateTexture(nil, "OVERLAY")
      icon.ccmBorderRight:SetColorTexture(0, 0, 0, 1)
      icon.ccmBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
      icon.ccmBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
      icon.ccmBorderRight:SetWidth(borderSize)
    end
    iconTexture:ClearAllPoints()
    iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
    iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
    if icon.ccmStandaloneCooldown then
      icon.ccmStandaloneCooldown:ClearAllPoints()
      icon.ccmStandaloneCooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.ccmStandaloneCooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
    end
  end
  if icon.ccmStandaloneChargeText then
    local stackPos = type(profile.stackTextPosition) == "string" and profile.stackTextPosition or "BOTTOMRIGHT"
    local stackOffX = type(profile.stackTextOffsetX) == "number" and profile.stackTextOffsetX or 0
    local stackOffY = type(profile.stackTextOffsetY) == "number" and profile.stackTextOffsetY or 0
    local stackScale = type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0
    icon.ccmStandaloneChargeText:ClearAllPoints()
    icon.ccmStandaloneChargeText:SetPoint(stackPos, icon, stackPos, stackOffX, stackOffY)
    icon.ccmStandaloneChargeText:SetScale(stackScale)
    icon.ccmStandaloneChargeText:SetTextColor(1, 1, 1, 1)
  end
  if icon.ccmStandaloneChargeText then
    local globalFont, globalOutline = GetGlobalFont()
    local _, ccmSize = GameFontHighlightLarge:GetFont()
    icon.ccmStandaloneChargeText:SetFont(globalFont, ccmSize, globalOutline or "OUTLINE")
  end
  do
    local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
    local cdTextScale
    if barType == "buff" then
      cdTextScale = type(profile.standaloneBuffCdTextScale) == "number" and profile.standaloneBuffCdTextScale or (type(profile.standaloneCdTextScale) == "number" and profile.standaloneCdTextScale or 1.0)
    elseif barType == "essential" then
      cdTextScale = type(profile.standaloneEssentialCdTextScale) == "number" and profile.standaloneEssentialCdTextScale or (type(profile.standaloneCdTextScale) == "number" and profile.standaloneCdTextScale or 1.0)
    elseif barType == "utility" then
      cdTextScale = type(profile.standaloneUtilityCdTextScale) == "number" and profile.standaloneUtilityCdTextScale or (type(profile.standaloneCdTextScale) == "number" and profile.standaloneCdTextScale or 1.0)
    else
      cdTextScale = type(profile.standaloneCdTextScale) == "number" and profile.standaloneCdTextScale or 1.0
    end
    local globalFont, globalOutline = GetGlobalFont()
    for c = 1, iconChildCount do
      local child = State.tmpIconChildren[c]
      if child and child:GetObjectType() == "Cooldown" then
        icon.ccmStandaloneCooldown = child
        -- Keep swipe coverage exact; scale only countdown text, not the cooldown frame.
        child:SetScale(1)
        child:SetHideCountdownNumbers(cdTextScale <= 0)
        local regionCount = addonTable.CollectRegions(child, State.tmpChildRegions)
        for r = 1, regionCount do
          local region = State.tmpChildRegions[r]
          if region and region:GetObjectType() == "FontString" then
            local _, size = region:GetFont()
            if size then
              if not region._ccmStandaloneBaseFontSize then
                region._ccmStandaloneBaseFontSize = size
              end
              local baseSize = region._ccmStandaloneBaseFontSize or size
              local factor = (cdTextScale > 0 and cdTextScale or 1) * 0.8
              region:SetFont(globalFont, baseSize * factor, globalOutline or "OUTLINE")
            end
          end
        end
      end
    end
  end
  local doSkinning = profile.blizzardBarSkinning ~= false
  if not doSkinning then
    local globalFont, globalOutline = GetGlobalFont()
    local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
    for c = 1, iconChildCount do
      local child = State.tmpIconChildren[c]
      if child and child:GetObjectType() == "Cooldown" then
        local regionCount = addonTable.CollectRegions(child, State.tmpChildRegions)
        for r = 1, regionCount do
          local region = State.tmpChildRegions[r]
          if region and region:GetObjectType() == "FontString" then
            local _, size = region:GetFont()
            if size then
              region:SetFont(globalFont, size, globalOutline or "OUTLINE")
            end
          end
        end
      end
    end
    local chargeText = (icon.ChargeCount and icon.ChargeCount.Current) or (icon.Applications and icon.Applications.Applications)
    if chargeText then
      local _, ccmSize = GameFontHighlightLarge:GetFont()
      chargeText:SetFont(globalFont, ccmSize, globalOutline or "OUTLINE")
    end
  end
end
local function IsValidStandaloneIcon(icon)
  if not icon or not icon:IsShown() or icon:GetWidth() <= 5 then return false end
  local tex = icon.Icon or icon.icon
  if not tex then return false end
  local hasTex = tex.GetTexture and tex:GetTexture()
  local hasAtlas = tex.GetAtlas and tex:GetAtlas()
  return hasTex ~= nil or hasAtlas ~= nil
end
local function CompareByLayoutIndex(a, b)
  return (a.layoutIndex or 0) < (b.layoutIndex or 0)
end
local function UpdateStandaloneBlizzardBars()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local function CanRepositionFrame(frame)
    if not frame then return false end
    if not InCombatLockdown() then return true end
    if frame.IsProtected and frame:IsProtected() then return false end
    return true
  end
  if profile.disableBlizzCDM == true then
    if State.standaloneBuffOriginals.saved and BuffIconCooldownViewer and CanRepositionFrame(BuffIconCooldownViewer) then
        RestoreStandaloneBar(BuffIconCooldownViewer, State.standaloneBuffOriginals)
    end
    if State.standaloneEssentialOriginals.saved and EssentialCooldownViewer and CanRepositionFrame(EssentialCooldownViewer) then
        RestoreStandaloneBar(EssentialCooldownViewer, State.standaloneEssentialOriginals)
    end
    if State.standaloneUtilityOriginals.saved and UtilityCooldownViewer and CanRepositionFrame(UtilityCooldownViewer) then
        RestoreStandaloneBar(UtilityCooldownViewer, State.standaloneUtilityOriginals)
    end
    State.standaloneSkinActive = false
    State.standaloneNeedsSkinning = false
    return
  end
  if profile.useBuffBar and State.standaloneBuffOriginals.saved and BuffIconCooldownViewer and CanRepositionFrame(BuffIconCooldownViewer) then
    RestoreStandaloneBar(BuffIconCooldownViewer, State.standaloneBuffOriginals)
  end
  if profile.useEssentialBar and State.standaloneEssentialOriginals.saved and EssentialCooldownViewer and CanRepositionFrame(EssentialCooldownViewer) then
    RestoreStandaloneBar(EssentialCooldownViewer, State.standaloneEssentialOriginals)
  end
  if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
    return
  end
  local needsSkinning = State.standaloneNeedsSkinning
  local guiOpen = State.guiIsOpen
  if not needsSkinning and not guiOpen then
    local buffShown = BuffIconCooldownViewer and BuffIconCooldownViewer:IsShown()
    local essentialShown = EssentialCooldownViewer and EssentialCooldownViewer:IsShown()
    local utilityShown = UtilityCooldownViewer and UtilityCooldownViewer:IsShown()
    if not buffShown and not essentialShown and not utilityShown then
      return
    end
  end
  local buffCentered = profile.standaloneBuffCentered == true
  local essentialCentered = profile.standaloneEssentialCentered == true
  local utilityCentered = profile.standaloneUtilityCentered == true
  local anyCentered = buffCentered or essentialCentered or utilityCentered
  if not needsSkinning and not guiOpen and not anyCentered and State.standaloneSkinActive then
    return
  end
  if not State.standaloneDirty and not needsSkinning and not guiOpen then
    return
  end
  local doSkinning = profile.blizzardBarSkinning ~= false
  local spacing = type(profile.standaloneSpacing) == "number" and profile.standaloneSpacing or 0
  local buffY = type(profile.standaloneBuffY) == "number" and profile.standaloneBuffY or 0
  local essentialY = type(profile.standaloneEssentialY) == "number" and profile.standaloneEssentialY or 50
  local utilityY = type(profile.standaloneUtilityY) == "number" and profile.standaloneUtilityY or -50
  local buffSize = type(profile.standaloneBuffSize) == "number" and profile.standaloneBuffSize or 45
  local buffMaxRows = type(profile.standaloneBuffMaxRows) == "number" and profile.standaloneBuffMaxRows or 2
  local buffGrowLeft = (profile.standaloneBuffGrowDirection or "right") == "left"
  local buffGrowUp = (profile.standaloneBuffRowGrowDirection or "down") == "up"
  local essentialSize = type(profile.standaloneEssentialSize) == "number" and profile.standaloneEssentialSize or 45
  local essentialSecondRowSize = type(profile.standaloneEssentialSecondRowSize) == "number" and profile.standaloneEssentialSecondRowSize or essentialSize
  local essentialMaxRows = type(profile.standaloneEssentialMaxRows) == "number" and profile.standaloneEssentialMaxRows or 2
  local essentialGrowLeft = (profile.standaloneEssentialGrowDirection or "right") == "left"
  local essentialGrowUp = (profile.standaloneEssentialRowGrowDirection or "down") == "up"
  local utilitySize = type(profile.standaloneUtilitySize) == "number" and profile.standaloneUtilitySize or 45
  local utilitySecondRowSize = utilitySize
  local utilityMaxRows = type(profile.standaloneUtilityMaxRows) == "number" and profile.standaloneUtilityMaxRows or 2
  local utilityGrowLeft = (profile.standaloneUtilityGrowDirection or "right") == "left"
  local utilityGrowUp = (profile.standaloneUtilityRowGrowDirection or "down") == "up"
  local utilityAutoWidthSource = profile.standaloneUtilityAutoWidth or "off"
  local essentialBarWidth = 0
  local anyActive = false
  local buffEnabled = profile.standaloneSkinBuff == true
  local essentialEnabled = profile.standaloneSkinEssential == true
  local utilityEnabled = profile.standaloneSkinUtility == true
  local hasBuffPos = profile.blizzBarBuffX ~= nil or profile.blizzBarBuffY ~= nil
  local hasEssentialPos = profile.blizzBarEssentialX ~= nil or profile.blizzBarEssentialY ~= nil
  local hasUtilityPos = profile.blizzBarUtilityX ~= nil or profile.blizzBarUtilityY ~= nil
  local buffActive = (not profile.useBuffBar) and (buffEnabled or buffCentered or hasBuffPos or State.guiIsOpen)
  if buffActive then
    local buffs = BuffIconCooldownViewer
    if buffs and buffs:IsShown() then
      anyActive = true
      SaveStandaloneBarOriginals(buffs, State.standaloneBuffOriginals)
      if buffs:GetScale() ~= 1 then
        buffs:SetScale(1)
      end
      local visibleIcons = {}
      local childCount = addonTable.CollectChildren(buffs, State.tmpChildren)
      for i = 1, childCount do
        local icon = State.tmpChildren[i]
        if IsValidStandaloneIcon(icon) then
          if doSkinning and buffEnabled and (needsSkinning or not icon.ccmStandaloneSkinned) then
            SkinStandaloneBarIcon(icon, profile, "buff")
          end
          icon:SetSize(buffSize, buffSize)
          table.insert(visibleIcons, icon)
        end
      end
      if #visibleIcons > 1 then
        table.sort(visibleIcons, CompareByLayoutIndex)
      end
      if #visibleIcons > 0 then
        local iconSize = buffSize
        local iconSpacing = spacing
        local numCols = #visibleIcons
        if buffs.iconGridNumColumns and buffs.iconGridNumColumns > 0 then
          numCols = buffs.iconGridNumColumns
        elseif buffs.GetNumColumns and type(buffs.GetNumColumns) == "function" then
          local cols = buffs:GetNumColumns()
          if cols and cols > 0 then numCols = cols end
        elseif buffs.numColumns and buffs.numColumns > 0 then
          numCols = buffs.numColumns
        else
          if #visibleIcons > 1 then
            local firstIcon = visibleIcons[1]
            local pt = {firstIcon:GetPoint(1)}
            local firstY = pt[5]
            if firstY then
              for i = 2, #visibleIcons do
                local pt2 = {visibleIcons[i]:GetPoint(1)}
                local iconY = pt2[5]
                if iconY and math.abs(iconY - firstY) > iconSize / 2 then
                  numCols = i - 1
                  break
                end
              end
            end
          end
        end
        local buffCustomCols = type(profile.standaloneBuffIconsPerRow) == "number" and math.floor(profile.standaloneBuffIconsPerRow) or 0
        if buffMaxRows <= 1 then
          numCols = #visibleIcons
        elseif buffCustomCols > 0 then
          numCols = math.max(buffCustomCols, math.ceil(#visibleIcons / buffMaxRows))
        else
          numCols = math.ceil(#visibleIcons / buffMaxRows)
        end
        numCols = math.max(1, math.min(numCols, #visibleIcons))
        local buffPosX = buffCentered and 0 or (profile.blizzBarBuffX or 0)
        local buffPosY = profile.blizzBarBuffY or buffY
        if CanRepositionFrame(buffs) and (buffCentered or profile.blizzBarBuffX ~= nil or profile.blizzBarBuffY ~= nil or State.guiIsOpen) then
          SetPointIfChanged(buffs, "CENTER", UIParent, "CENTER", buffPosX, buffPosY)
        end
        local buffKeyParts = {
          #visibleIcons, numCols, iconSize, iconSpacing,
          buffCentered and 1 or 0, buffGrowLeft and 1 or 0, buffGrowUp and 1 or 0, buffMaxRows,
          buffPosX, buffPosY
        }
        for i = 1, #visibleIcons do
          buffKeyParts[#buffKeyParts + 1] = visibleIcons[i].layoutIndex or i
        end
        local buffLayoutKey = table.concat(buffKeyParts, "|")
        if needsSkinning or buffCentered or State.standaloneBuffLayoutKey ~= buffLayoutKey then
          State.standaloneBuffLayoutKey = buffLayoutKey
          addonTable.LayoutStandaloneRows(
            buffs,
            visibleIcons,
            numCols,
            iconSize,
            iconSize,
            iconSpacing,
            buffCentered,
            buffGrowLeft,
            buffGrowUp,
            buffMaxRows,
            true
          )
        end
      else
        State.standaloneBuffLayoutKey = nil
      end
    end
  elseif State.standaloneBuffOriginals.saved and BuffIconCooldownViewer then
    if CanRepositionFrame(BuffIconCooldownViewer) then
      RestoreStandaloneBar(BuffIconCooldownViewer, State.standaloneBuffOriginals)
    end
    State.standaloneBuffLayoutKey = nil
  end
  local essentialActive = (not profile.useEssentialBar) and (essentialEnabled or essentialCentered or hasEssentialPos or State.guiIsOpen)
  if essentialActive then
    local main = EssentialCooldownViewer
    if main and main:IsShown() then
      anyActive = true
      SaveStandaloneBarOriginals(main, State.standaloneEssentialOriginals)
      if main:GetScale() ~= 1 then
        main:SetScale(1)
      end
      local visibleIcons = {}
      local childCount = addonTable.CollectChildren(main, State.tmpChildren)
      for i = 1, childCount do
        local icon = State.tmpChildren[i]
        if IsValidStandaloneIcon(icon) then
          if doSkinning and essentialEnabled and (needsSkinning or not icon.ccmStandaloneSkinned) then
            SkinStandaloneBarIcon(icon, profile, "essential")
          end
          table.insert(visibleIcons, icon)
        end
      end
      if #visibleIcons > 1 then
        table.sort(visibleIcons, CompareByLayoutIndex)
      end
      if #visibleIcons > 0 then
        local iconSpacing = spacing
        local iconSize = essentialSize
        local numCols = #visibleIcons
        if main.iconGridNumColumns and main.iconGridNumColumns > 0 then
          numCols = main.iconGridNumColumns
        elseif main.GetNumColumns and type(main.GetNumColumns) == "function" then
          local cols = main:GetNumColumns()
          if cols and cols > 0 then numCols = cols end
        elseif main.numColumns and main.numColumns > 0 then
          numCols = main.numColumns
        else
          if #visibleIcons > 1 then
            local firstIcon = visibleIcons[1]
            local pt = {firstIcon:GetPoint(1)}
            local firstY = pt[5]
            if firstY then
              for i = 2, #visibleIcons do
                local pt2 = {visibleIcons[i]:GetPoint(1)}
                local iconY = pt2[5]
                if iconY and math.abs(iconY - firstY) > iconSize / 2 then
                  numCols = i - 1
                  break
                end
              end
            end
          end
        end
        numCols = math.max(1, numCols)
        local essentialCustomCols = type(profile.standaloneEssentialIconsPerRow) == "number" and math.floor(profile.standaloneEssentialIconsPerRow) or 0
        local layoutMaxRows = essentialMaxRows
        if essentialMaxRows <= 1 then
          numCols = #visibleIcons
        elseif essentialCustomCols > 0 then
          numCols = essentialCustomCols
          layoutMaxRows = #visibleIcons
        else
          numCols = math.ceil(#visibleIcons / essentialMaxRows)
        end
        numCols = math.max(1, math.min(numCols, #visibleIcons))
        if essentialSecondRowSize == essentialSize then
          essentialSecondRowSize = iconSize
        end
        local essentialPosX = essentialCentered and 0 or (profile.blizzBarEssentialX or 0)
        local essentialPosY = profile.blizzBarEssentialY or essentialY
        if CanRepositionFrame(main) and (essentialCentered or profile.blizzBarEssentialX ~= nil or profile.blizzBarEssentialY ~= nil or State.guiIsOpen) then
          SetPointIfChanged(main, "CENTER", UIParent, "CENTER", essentialPosX, essentialPosY)
        end
        local essentialKeyParts = {
          #visibleIcons, numCols, iconSize, essentialSecondRowSize, iconSpacing,
          essentialCentered and 1 or 0, essentialGrowLeft and 1 or 0, essentialGrowUp and 1 or 0, layoutMaxRows,
          essentialPosX, essentialPosY
        }
        for i = 1, #visibleIcons do
          essentialKeyParts[#essentialKeyParts + 1] = visibleIcons[i].layoutIndex or i
        end
        local essentialLayoutKey = table.concat(essentialKeyParts, "|")
        if needsSkinning or essentialCentered or State.standaloneEssentialLayoutKey ~= essentialLayoutKey then
          State.standaloneEssentialLayoutKey = essentialLayoutKey
          local layoutWidth = addonTable.LayoutStandaloneRows(
            main,
            visibleIcons,
            numCols,
            iconSize,
            essentialSecondRowSize,
            iconSpacing,
            essentialCentered,
            essentialGrowLeft,
            essentialGrowUp,
            layoutMaxRows,
            true
          )
          State.standaloneEssentialWidth = layoutWidth or 0
        end
        local sizeIdx = 1
        for ri = 1, math.ceil(#visibleIcons / numCols) do
          local size = (ri >= 2 and type(essentialSecondRowSize) == "number" and essentialSecondRowSize > 5) and essentialSecondRowSize or iconSize
          local iconsInRow = math.min(numCols, #visibleIcons - sizeIdx + 1)
          for _ = 1, iconsInRow do
            if visibleIcons[sizeIdx] then visibleIcons[sizeIdx]:SetSize(size, size) end
            sizeIdx = sizeIdx + 1
          end
        end
      else
        State.standaloneEssentialWidth = 0
        State.standaloneEssentialLayoutKey = nil
      end
    end
  elseif State.standaloneEssentialOriginals.saved and EssentialCooldownViewer then
    if CanRepositionFrame(EssentialCooldownViewer) then
      RestoreStandaloneBar(EssentialCooldownViewer, State.standaloneEssentialOriginals)
    end
    State.standaloneEssentialLayoutKey = nil
  end
  if not essentialActive or not (EssentialCooldownViewer and EssentialCooldownViewer:IsShown()) then
    State.standaloneEssentialWidth = 0
  end
  local utilityActive = utilityEnabled or utilityCentered or hasUtilityPos or State.guiIsOpen
  if utilityActive then
    local utility = UtilityCooldownViewer
    if utility and utility:IsShown() then
      anyActive = true
      SaveStandaloneBarOriginals(utility, State.standaloneUtilityOriginals)
      if utility:GetScale() ~= 1 then
        utility:SetScale(1)
      end
      local visibleIcons = {}
      local childCount = addonTable.CollectChildren(utility, State.tmpChildren)
      for i = 1, childCount do
        local icon = State.tmpChildren[i]
        if IsValidStandaloneIcon(icon) then
          if doSkinning and utilityEnabled and (needsSkinning or not icon.ccmStandaloneSkinned) then
            SkinStandaloneBarIcon(icon, profile, "utility")
          end
          icon:SetSize(utilitySize, utilitySize)
          table.insert(visibleIcons, icon)
        end
      end
      if #visibleIcons > 1 then
        table.sort(visibleIcons, CompareByLayoutIndex)
      end
      if #visibleIcons > 0 then
        local iconSize = utilitySize
        local iconSpacing = spacing
        local numCols = #visibleIcons
        if utility.iconGridNumColumns and utility.iconGridNumColumns > 0 then
          numCols = utility.iconGridNumColumns
        elseif utility.GetNumColumns and type(utility.GetNumColumns) == "function" then
          local cols = utility:GetNumColumns()
          if cols and cols > 0 then numCols = cols end
        elseif utility.numColumns and utility.numColumns > 0 then
          numCols = utility.numColumns
        else
          if #visibleIcons > 1 then
            local firstIcon = visibleIcons[1]
            local pt = {firstIcon:GetPoint(1)}
            local firstY = pt[5]
            if firstY then
              for i = 2, #visibleIcons do
                local pt2 = {visibleIcons[i]:GetPoint(1)}
                local iconY = pt2[5]
                if iconY and math.abs(iconY - firstY) > iconSize / 2 then
                  numCols = i - 1
                  break
                end
              end
            end
          end
        end
        numCols = math.max(1, numCols)
        local utilityCustomCols = type(profile.standaloneUtilityIconsPerRow) == "number" and math.floor(profile.standaloneUtilityIconsPerRow) or 0
        local layoutMaxRows = utilityMaxRows
        if utilityMaxRows <= 1 then
          numCols = #visibleIcons
        elseif utilityCustomCols > 0 then
          numCols = utilityCustomCols
          layoutMaxRows = #visibleIcons
        else
          numCols = math.ceil(#visibleIcons / utilityMaxRows)
        end
        numCols = math.max(1, math.min(numCols, #visibleIcons))
        if utilityAutoWidthSource ~= "off" then
          local targetWidth = 0
          if utilityAutoWidthSource == "essential" then
            if State.standaloneEssentialWidth and State.standaloneEssentialWidth > 0 then
              targetWidth = State.standaloneEssentialWidth
            elseif EssentialCooldownViewer and EssentialCooldownViewer:IsShown() then
              local w = EssentialCooldownViewer:GetWidth()
              if w and w > 0 then
                local scale = EssentialCooldownViewer.GetEffectiveScale and EssentialCooldownViewer:GetEffectiveScale() or 1
                local parentScale = UIParent:GetEffectiveScale()
                if parentScale and parentScale > 0 then
                  targetWidth = w * (scale / parentScale)
                else
                  targetWidth = w
                end
              end
            end
          elseif utilityAutoWidthSource == "cbar1" or utilityAutoWidthSource == "cbar2" or utilityAutoWidthSource == "cbar3" then
            local barNum = tonumber(string.sub(utilityAutoWidthSource, 5, 5)) or 1
            local prefix = barNum == 1 and "customBar" or ("customBar" .. barNum)
            local cbarWidth = profile[prefix .. "IconSize"] or 28
            local cbarSpacing = type(profile[prefix .. "Spacing"]) == "number" and profile[prefix .. "Spacing"] or 2
            local cbarCount = 0
            local getSpellsFunc = barNum == 1 and addonTable.GetCustomBarSpells or addonTable["GetCustomBar" .. barNum .. "Spells"]
            if getSpellsFunc then
              local spells = getSpellsFunc()
              if spells then cbarCount = #spells end
            end
            if cbarCount > 0 then
              targetWidth = (cbarWidth * cbarCount) + (cbarSpacing * (cbarCount - 1))
            end
          end
          if targetWidth > 0 then
            local fitted = (targetWidth - ((numCols - 1) * iconSpacing)) / numCols
            if fitted > 5 then
              iconSize = math.max(10, fitted)
            end
          end
        end
        utilitySecondRowSize = iconSize
        local utilityPosX = utilityCentered and 0 or (profile.blizzBarUtilityX or 0)
        local utilityPosY = profile.blizzBarUtilityY or utilityY
        if CanRepositionFrame(utility) and (utilityCentered or profile.blizzBarUtilityX ~= nil or profile.blizzBarUtilityY ~= nil or State.guiIsOpen) then
          SetPointIfChanged(utility, "CENTER", UIParent, "CENTER", utilityPosX, utilityPosY)
        end
        local utilityKeyParts = {
          #visibleIcons, numCols, iconSize, utilitySecondRowSize, iconSpacing,
          utilityCentered and 1 or 0, utilityGrowLeft and 1 or 0, utilityGrowUp and 1 or 0, layoutMaxRows,
          utilityPosX, utilityPosY, utilityAutoWidthSource
        }
        for i = 1, #visibleIcons do
          utilityKeyParts[#utilityKeyParts + 1] = visibleIcons[i].layoutIndex or i
        end
        local utilityLayoutKey = table.concat(utilityKeyParts, "|")
        if needsSkinning or utilityCentered or State.standaloneUtilityLayoutKey ~= utilityLayoutKey then
          State.standaloneUtilityLayoutKey = utilityLayoutKey
          addonTable.LayoutStandaloneRows(
            utility,
            visibleIcons,
            numCols,
            iconSize,
            utilitySecondRowSize,
            iconSpacing,
            utilityCentered,
            utilityGrowLeft,
            utilityGrowUp,
            layoutMaxRows
          )
        end
      else
        State.standaloneUtilityLayoutKey = nil
      end
    end
  elseif State.standaloneUtilityOriginals.saved and UtilityCooldownViewer then
    if CanRepositionFrame(UtilityCooldownViewer) then
      RestoreStandaloneBar(UtilityCooldownViewer, State.standaloneUtilityOriginals)
    end
    State.standaloneUtilityLayoutKey = nil
  end
  State.standaloneSkinActive = anyActive
  if needsSkinning then
    State.standaloneNeedsSkinning = false
  end
  State.standaloneDirty = false
end
addonTable.UpdateStandaloneBlizzardBars = UpdateStandaloneBlizzardBars
if CooldownViewerSettings and CooldownViewerSettings.RefreshLayout then
  hooksecurefunc(CooldownViewerSettings, "RefreshLayout", function()
    State.standaloneNeedsSkinning = true
    State.standaloneDirty = true
    State.standaloneFastUntil = GetTime() + 0.3
    State.lastStandaloneTick = 0
    UpdateStandaloneBlizzardBars()
    C_Timer.After(0, function()
      State.standaloneNeedsSkinning = true
      State.standaloneDirty = true
      UpdateStandaloneBlizzardBars()
    end)
  end)
end
for _, viewerName in ipairs({"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer"}) do
  local viewer = _G[viewerName]
  if viewer and viewer.RefreshLayout then
    hooksecurefunc(viewer, "RefreshLayout", function()
      State.standaloneNeedsSkinning = true
      State.standaloneDirty = true
      UpdateStandaloneBlizzardBars()
    end)
  end
end
do
  local centerFrame = CreateFrame("Frame")
  centerFrame.elapsed = 0
  centerFrame.periodicElapsed = 0
  centerFrame:Hide()
  centerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    self.periodicElapsed = self.periodicElapsed + elapsed
    if self.periodicElapsed >= 2 then
      self.periodicElapsed = 0
      State.standaloneDirty = true
    end
    local threshold = (State.standaloneFastUntil and GetTime() < State.standaloneFastUntil) and 0.05 or 0.25
    if self.elapsed < threshold then return end
    self.elapsed = 0
    UpdateStandaloneBlizzardBars()
  end)
  State.standaloneCenterFrame = centerFrame
end
if EditModeManagerFrame then
  hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
    if PatchAllCooldownViewerChargeMethods then
      PatchAllCooldownViewerChargeMethods()
    end
    if InCombatLockdown() then return end
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
  end)
end
if C_Timer and C_Timer.After then
  C_Timer.After(0, function()
    if PatchAllCooldownViewerChargeMethods then
      PatchAllCooldownViewerChargeMethods()
    end
  end)
  C_Timer.After(1, function()
    if PatchAllCooldownViewerChargeMethods then
      PatchAllCooldownViewerChargeMethods()
    end
  end)
  C_Timer.After(5, function()
    if PatchAllCooldownViewerChargeMethods then
      PatchAllCooldownViewerChargeMethods()
    end
  end)
end
if C_Timer and C_Timer.NewTicker and not State.cooldownViewerChargePatchTicker then
  State.cooldownViewerChargePatchTicker = C_Timer.NewTicker(1, function(ticker)
    if PatchAllCooldownViewerChargeMethods then
      PatchAllCooldownViewerChargeMethods()
    end
    if ticker._ccmTicks then
      ticker._ccmTicks = ticker._ccmTicks + 1
    else
      ticker._ccmTicks = 1
    end
    if ticker._ccmTicks >= 10 then
      ticker:Cancel()
      State.cooldownViewerChargePatchTicker = nil
    end
  end)
end
local function ClearCustomBarIcons()
  if Masque and MasqueGroups.CustomBar then
    for _, icon in ipairs(State.customBar1Icons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CustomBar)
    end
  end
  for _, icon in ipairs(State.customBar1Icons) do
    HideIconByScale(icon)
    icon:SetScript("OnUpdate", nil)
  end
  wipe(State.customBar1Icons)
end
local function ResolveCustomBarAnchorFrame(anchorName)
  local function HasObjectTypeMethod(obj)
    local ok, method = pcall(function()
      return obj and obj.GetObjectType
    end)
    return ok and type(method) == "function"
  end
  local raw = type(anchorName) == "string" and anchorName or ""
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if trimmed == "" then return UIParent, "UIParent" end
  local normalized = trimmed:lower():gsub("_", "")
  if normalized == "uiparent" then return UIParent, "UIParent" end
  State.customBarAnchorCache = State.customBarAnchorCache or {}
  local cache = State.customBarAnchorCache
  local cached = cache[normalized]
  if cached ~= nil then
    if cached == false then
      return UIParent, "UIParent"
    end
    return cached, (cached.GetName and cached:GetName()) or trimmed
  end
  local frame = _G[trimmed]
  if not HasObjectTypeMethod(frame) then
    for name, obj in pairs(_G) do
      if type(name) == "string" and name:lower():gsub("_", "") == normalized and HasObjectTypeMethod(obj) then
        frame = obj
        break
      end
    end
  end
  if HasObjectTypeMethod(frame) then
    cache[normalized] = frame
    return frame, (frame.GetName and frame:GetName()) or trimmed
  end
  cache[normalized] = false
  return UIParent, "UIParent"
end
addonTable.ResolveCustomBarAnchorFrame = ResolveCustomBarAnchorFrame
addonTable.GetAnchorFrameOptions = function(excludeBarNum)
  local opts = {{text = "UIParent", value = "UIParent"}}
  local candidates = {
    {name = "PlayerFrame", text = "PlayerFrame"},
    {name = "TargetFrame", text = "TargetFrame"},
    {name = "FocusFrame", text = "FocusFrame"},
    {name = "CCMPersonalResourceBar", text = "PRB", excludeBar = 0},
    {name = "CCMCustomBar", text = "CBar 1", excludeBar = 1},
    {name = "CCMCustomBar2", text = "CBar 2", excludeBar = 2},
    {name = "CCMCustomBar3", text = "CBar 3", excludeBar = 3},
    {name = "CCMCustomBar4", text = "CBar 4", excludeBar = 4},
    {name = "CCMCustomBar5", text = "CBar 5", excludeBar = 5},
  }
  for _, c in ipairs(candidates) do
    if c.excludeBar ~= excludeBarNum and _G[c.name] then
      opts[#opts + 1] = {text = c.text, value = c.name}
    end
  end
  return opts
end
local function CreateCustomBarIcons()
  if State.customBar1Moving then return end
  State.customBar1LayoutKey = nil
  ClearCustomBarIcons()
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBarEnabled then
    customBarFrame:Hide()
    return
  end
  local entries, entriesEnabled, entryGlowEnabled, entryGlowType, entryHRT = GetCustomBarSpells()
  if #entries == 0 then
    customBarFrame:Hide()
    return
  end
  local iconSize = type(profile.customBarIconSize) == "number" and profile.customBarIconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, id in ipairs(entries) do
    if entriesEnabled[i] == nil or entriesEnabled[i] ~= false then
      local icon = CreateFrame("Button", "CCMCustomBarIcon" .. i, customBarFrame, "BackdropTemplate")
      icon:SetSize(iconSize, iconSize)
      icon:SetFrameStrata(profile.iconStrata or "FULLSCREEN")
      icon:SetFrameLevel(10)
      icon:EnableMouse(false)
      icon.Icon = icon:CreateTexture(nil, "BACKGROUND")
      icon.Icon:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Icon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon.icon = icon.Icon
      AddIconBorder(icon, borderSize)
      icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
      icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Cooldown:SetDrawEdge(false)
      icon.Cooldown:SetDrawBling(false)
      icon.Cooldown:SetDrawSwipe(true)
      icon.Cooldown:SetReverse(false)
      icon.Cooldown:SetHideCountdownNumbers(false)
      icon.cooldown = icon.Cooldown
      icon.stackTextFrame = CreateFrame("Frame", nil, icon)
      icon.stackTextFrame:SetAllPoints()
      icon.stackTextFrame:SetFrameLevel(icon.Cooldown:GetFrameLevel() + 5)
      icon.Count = icon.stackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      icon.Count:SetPoint("BOTTOMRIGHT", icon.stackTextFrame, "BOTTOMRIGHT", -2, 2)
      icon.Count:SetTextColor(1, 1, 1, 1)
      local globalFont, globalOutline = GetGlobalFont()
      local _, fontSize = icon.Count:GetFont()
      icon.Count:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.entryIndex = i
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      icon.glowType = (entryGlowEnabled[i] == true) and (entryGlowType[i] or profile.customBarSpellGlowDefaultType or "pixel") or "off"
      icon.hideRevealThreshold = tonumber(entryHRT[i]) or 0
      SetGlowIdentityMethods(icon)
      if icon.isItem then
        local itemIcon = C_Item.GetItemIconByID(icon.actualID)
        icon.Icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      else
        local spellInfo = C_Spell.GetSpellInfo(icon.actualID)
        icon.Icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      end
      table.insert(State.customBar1Icons, icon)
      if Masque and profile.enableMasque and MasqueGroups.CustomBar then
        SkinButtonWithMasque(icon, MasqueGroups.CustomBar)
      end
    end
  end
  local centered = profile.customBarCentered == true
  local x = type(profile.customBarX) == "number" and profile.customBarX or 0
  local y = type(profile.customBarY) == "number" and profile.customBarY or -200
  local anchorFrame, _ = ResolveCustomBarAnchorFrame(profile.customBarAnchorFrame)
  local anchorToPoint = profile.customBarAnchorToPoint or "CENTER"
  if centered then
    x = 0 + x
  end
  if not State.cb1Dragging then
    customBarFrame:ClearAllPoints()
    customBarFrame:SetPoint("CENTER", anchorFrame, anchorToPoint, x, y)
  end
  customBarFrame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar then
    ReSkinMasqueGroup(MasqueGroups.CustomBar)
  end
end
local function UpdateCustomBar()
  State.customBar1HasActiveTimers = false
  if State.customBar1Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBarEnabled then
    customBarFrame:Hide()
    return
  end
  local inCombat = InCombatLockdown()
  local onMyTab = State.guiIsOpen and addonTable.activeTab and addonTable.activeTab() == 3
  if not IsShowModeActive(profile.customBarShowMode, true) then
    if not customBarFrame.highlightVisible and not onMyTab then
      customBarFrame:Hide()
      return
    end
  end
  if profile.customBarOutOfCombat == false and not inCombat then
    if not customBarFrame.highlightVisible then
      customBarFrame:Hide()
      return
    end
  end
  if #State.customBar1Icons == 0 then
    if not customBarFrame.highlightVisible and not onMyTab then
      customBarFrame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBarIconSize) == "number" and profile.customBarIconSize or 30
  local spacing = type(profile.customBarSpacing) == "number" and profile.customBarSpacing or 2
  local growth = profile.customBarGrowth or "DOWN"
  local anchor = profile.customBarAnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBarCdTextScale) == "number" and profile.customBarCdTextScale or 1.0
  local cdTextHidden = cdTextScale <= 0
  local stackTextScale = type(profile.customBarStackTextScale) == "number" and profile.customBarStackTextScale or 1.0
  local centered = profile.customBarCentered == true
  local cooldownMode = profile.customBarCooldownMode or "show"
  local _, _, _, _, entryHRT = GetCustomBarSpells()
  local iconsPerRow = type(profile.customBarIconsPerRow) == "number" and profile.customBarIconsPerRow or 20
  local showGCD = profile.customBarShowGCD == true
  local cbTrackBuffs = profile.customBarTrackBuffs ~= false
  local cbAllowBuffSpellInfo = cbTrackBuffs
  local pureBuffSpellIDs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {}
  local barHasActiveTimers = false
  local nowCB = GetTime()
  local cachedGcdInfo = nil
  if C_Spell and C_Spell.GetSpellCooldown then
    if inCombat then
      local okGcd, gi = pcall(C_Spell.GetSpellCooldown, 61304)
      if okGcd and type(gi) == "table" then cachedGcdInfo = gi end
    else
      cachedGcdInfo = C_Spell.GetSpellCooldown(61304)
    end
  end
  RefreshGlowParams()
  wipe(State.customBarVisibleIcons)
  local visibleIcons = State.customBarVisibleIcons
  local demoCdApplied = false
  for originalIdx, icon in ipairs(State.customBar1Icons) do
    icon.hideRevealThreshold = tonumber(entryHRT and entryHRT[icon.entryIndex or originalIdx]) or 0
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = actualID
    local iconTexture, itemCount
    local isOnCooldown = false
    local isChargeSpell = false
    local cdStart, cdDuration = 0, 0
    local chargesData = nil
    if isItem then
      iconTexture = icon.cachedItemIcon
      if not iconTexture then
        iconTexture = C_Item.GetItemIconByID(actualID)
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = C_Item.GetItemCount(actualID, false, true)
      cdStart, cdDuration = C_Item.GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
        if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
        icon.cooldown:SetHideCountdownNumbers(false)
      else
        icon.cooldown:Clear()
      end
      local itemNotInBags = not itemCount or itemCount <= 0
      if itemNotInBags or (cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5) then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID, cbAllowBuffSpellInfo) then
        iconTexture = nil
        icon.cooldown:Clear()
      else
        if icon._cachedCBActiveSpellID ~= activeSpellID then
          local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
          icon._cachedCBIconID = spellInfo and spellInfo.iconID or nil
          icon._cachedCBActiveSpellID = activeSpellID
        end
        iconTexture = icon._cachedCBIconID
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          local shouldShowSwipe = true
          if (not isChargeSpell) and ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
            shouldShowSwipe = false
          end
          if shouldShowSwipe and cdStart and cdDuration then
            if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            local shouldShowSwipe = true
            if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
              shouldShowSwipe = false
            end
            if shouldShowSwipe then
              if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            else
              icon.cooldown:Clear()
            end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        end
      end
    end
    local buffOverlayActive = false
    if not isItem and cbTrackBuffs then
      local overlayApplied = false
      if cbTrackBuffs and addonTable.TryApplyLiveAuraOverlay then
        overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, activeSpellID)
        if not overlayApplied and activeSpellID ~= actualID then
          overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, actualID)
        end
      end
      buffOverlayActive = overlayApplied
    end
    if inCombat then pcall(icon.cooldown.SetReverse, icon.cooldown, buffOverlayActive) else icon.cooldown:SetReverse(buffOverlayActive) end
    if not isItem and not isChargeSpell then
      local cdStartPublic = ToPublicNumber(cdStart)
      local cdDurationPublic = ToPublicNumber(cdDuration)
      if cdStartPublic and cdDurationPublic then
        if inCombat then
          local okZero, isZero = pcall(function() return cdStartPublic == 0 end)
          if okZero and isZero then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local okGcd, isGcdMatch = pcall(function()
                  local gcdStart = ToPublicNumber(gcdInfo.startTime)
                  local gcdDuration = ToPublicNumber(gcdInfo.duration)
                  return gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration
                end)
                if okGcd and isGcdMatch then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            local okCD, isCD = pcall(function() return cdStartPublic > 0 and cdDurationPublic > 1.5 end)
            if okCD and isCD then
              isOnCooldown = true
              local ok2, endTime = pcall(function() return cdStartPublic + cdDurationPublic end)
              if ok2 and endTime then
                icon._cdExpectedEnd = endTime
                State.spellCdDurations[activeSpellID] = cdDurationPublic
                if actualID ~= activeSpellID then
                  State.spellCdDurations[actualID] = cdDurationPublic
                end
              end
            end
          end
        else
          if cdStartPublic == 0 then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local gcdStart = ToPublicNumber(gcdInfo.startTime)
                local gcdDuration = ToPublicNumber(gcdInfo.duration)
                if gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            if cdStartPublic > 0 and cdDurationPublic > 1.5 then
              isOnCooldown = true
              icon._cdExpectedEnd = cdStartPublic + cdDurationPublic
              State.spellCdDurations[activeSpellID] = cdDurationPublic
              if actualID ~= activeSpellID then
                State.spellCdDurations[actualID] = cdDurationPublic
              end
            end
          end
        end
      end
      if not isOnCooldown then
        if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 and nowCB < icon._cdExpectedEnd then
          isOnCooldown = true
        end
      end
    end
    local isUsable, notEnoughResources, hasUsability = true, false, false
    if not isItem then
      isUsable, notEnoughResources, hasUsability = GetSpellUsabilityState(activeSpellID)
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
      if isChargeSpell then
        if hasUsability == false then
          isUsable = false
        end
        notEnoughResources = false
      end
    end
    local hasChargeRecharge = false
    if (not isItem) and isChargeSpell and chargesData then
      if inCombat then
        local okRecharge, recharge = pcall(function()
          return chargesData.cooldownStartTime and chargesData.cooldownDuration
            and chargesData.cooldownStartTime > 0 and chargesData.cooldownDuration > 0
        end)
        hasChargeRecharge = okRecharge and recharge or false
      else
        hasChargeRecharge = chargesData.cooldownStartTime and chargesData.cooldownDuration
          and chargesData.cooldownStartTime > 0 and chargesData.cooldownDuration > 0 or false
      end
    end
    if buffOverlayActive or isOnCooldown or hasChargeRecharge then
      barHasActiveTimers = true
    end
    local td = icon._tempData
    if not td then
      td = {}
      icon._tempData = td
    end
    td.iconTexture = iconTexture
    td.itemCount = itemCount
    td.isOnCooldown = isOnCooldown
    td.isChargeSpell = isChargeSpell
    td.isUsable = isUsable
    td.originalIndex = originalIdx
    td.notEnoughResources = notEnoughResources
    td.activeSpellID = activeSpellID
    td.chargesData = chargesData
    td.buffOverlayActive = buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    local isPureBuff = pureBuffSpellIDs[activeSpellID] == true or pureBuffSpellIDs[actualID] == true
    if isPureBuff then
      if not cbTrackBuffs or not buffOverlayActive then
        shouldShow = false
      end
    end
    if not onMyTab and not buffOverlayActive then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          if not icon.isItem and profile.customBarUseCustomHideReveal and icon.hideRevealThreshold and icon.hideRevealThreshold > 0 then
            local expectedEnd = icon._cdExpectedEnd or 0
            if expectedEnd <= 0 and cdStart and cdDuration then
              expectedEnd = cdStart + cdDuration
            end
            local remaining = expectedEnd - nowCB
            if remaining <= 0 or remaining > icon.hideRevealThreshold then
              shouldShow = false
            end
          else
            shouldShow = false
          end
        elseif notEnoughResources then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      HideIconByScale(icon)
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    State.customBar1HasActiveTimers = barHasActiveTimers
    if not onMyTab then
      customBarFrame:Hide()
    end
    return
  end
  local totalIcons = #State.customBar1Icons
  local direction = profile.customBarDirection or "horizontal"
  local isHorizontal = (direction == "horizontal")
  local numRows, numCols
  if centered then
    if isHorizontal then
      numCols = math.min(visibleCount, iconsPerRow)
      numRows = math.ceil(visibleCount / iconsPerRow)
    else
      numRows = math.min(visibleCount, iconsPerRow)
      numCols = math.ceil(visibleCount / iconsPerRow)
    end
  else
    if isHorizontal then
      numCols = math.min(totalIcons, iconsPerRow)
      numRows = math.ceil(totalIcons / iconsPerRow)
    else
      numRows = math.min(totalIcons, iconsPerRow)
      numCols = math.ceil(totalIcons / iconsPerRow)
    end
  end
  local totalWidth, totalHeight
  if isHorizontal then
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  else
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  end
  local posX = type(profile.customBarX) == "number" and profile.customBarX or 0
  local posY = type(profile.customBarY) == "number" and profile.customBarY or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBarAnchorFrame)
  local layoutKey = string.format("%d|%d|%s|%s|%d|%s|%d|%d|%s|%s|%s",
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName or "")
  local layoutChanged = layoutKey ~= State.customBar1LayoutKey
  if layoutChanged then
    State.customBar1LayoutKey = layoutKey
  end
  local _useSpellGlows = profile.customBarUseSpellGlows == true
  local _cbGradT = type(profile.customBarCdGradientThreshold) == "number" and profile.customBarCdGradientThreshold or 0
  local _cbGradR, _cbGradG, _cbGradB
  if _cbGradT > 0 then
    _cbGradR = type(profile.customBarCdGradientR) == "number" and profile.customBarCdGradientR or 1
    _cbGradG = type(profile.customBarCdGradientG) == "number" and profile.customBarCdGradientG or 0
    _cbGradB = type(profile.customBarCdGradientB) == "number" and profile.customBarCdGradientB or 0
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = data.activeSpellID or (isItem and actualID or ResolveTrackedSpellID(actualID))
    if icon._lastTexture ~= iconTexture then
      icon.icon:SetTexture(iconTexture)
      icon._lastTexture = iconTexture
    end
    local needsPosition = layoutChanged or (icon.GetNumPoints and icon:GetNumPoints() == 0)
    if needsPosition then
      icon:SetSize(iconSize, iconSize)
      if icon.Icon then
        icon.Icon:SetAllPoints(icon)
      end
      if icon.Cooldown then
        icon.Cooldown:SetAllPoints(icon)
      end
      icon:ClearAllPoints()
      local posIndex = centered and idx or data.originalIndex
      local row, col
      if isHorizontal then
        row = math.floor((posIndex - 1) / iconsPerRow)
        col = (posIndex - 1) % iconsPerRow
      else
        col = math.floor((posIndex - 1) / iconsPerRow)
        row = (posIndex - 1) % iconsPerRow
      end
      local xPos, yPos = 0, 0
      if centered then
        if isHorizontal then
          local rowIconCount = math.min(visibleCount - row * iconsPerRow, iconsPerRow)
          local rowWidth = rowIconCount * iconSize + (rowIconCount - 1) * spacing
          local startX = -rowWidth / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -startX - col * (iconSize + spacing)
          else
            xPos = startX + col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
          else
            yPos = -row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBarFrame, "CENTER", xPos, yPos)
        else
          local colIconCount = math.min(visibleCount - col * iconsPerRow, iconsPerRow)
          local colHeight = colIconCount * iconSize + (colIconCount - 1) * spacing
          local startY = -colHeight / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -col * (iconSize + spacing)
          else
            xPos = col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = -startY + row * (iconSize + spacing)
          else
            yPos = startY - row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBarFrame, "CENTER", xPos, yPos)
        end
      else
        if anchor == "RIGHT" then
          xPos = -col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMRIGHT", customBarFrame, "BOTTOMRIGHT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPRIGHT", customBarFrame, "TOPRIGHT", xPos, yPos)
          end
        else
          xPos = col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMLEFT", customBarFrame, "BOTTOMLEFT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPLEFT", customBarFrame, "TOPLEFT", xPos, yPos)
          end
        end
      end
    end
    if icon.cooldown._ccmLastScale ~= cdTextScale then
      icon.cooldown:SetScale(cdTextHidden and 1 or cdTextScale)
      icon.cooldown:SetHideCountdownNumbers(cdTextHidden)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local fs = addonTable.GetCachedFontStrings(icon.cooldown)
      for i = 1, #fs do
        local _, sz = fs[i]:GetFont()
        if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
      end
    end
    local shouldDesaturate = false
    local isUsable = icon._tempData and icon._tempData.isUsable
    if isUsable == nil then isUsable = true end
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local buffOverlayActive = icon._tempData and icon._tempData.buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    if buffOverlayActive then
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    elseif isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        local cDesat = GetChargeSpellDesaturation(activeSpellID)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(cDesat)
        else
          icon.icon:SetDesaturated(cDesat and cDesat > 0)
        end
      else
        icon:SetAlpha(1)
        icon.icon:SetDesaturated(false)
      end
    else
      icon:SetAlpha(1)
      if cooldownMode == "desaturate" then
        shouldDesaturate = isUnavailable
      else
        shouldDesaturate = false
      end
    end
    if isItem then
      if itemCount and itemCount > 1 then
        icon.stackText:SetText(itemCount)
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif itemCount and itemCount == 0 then
        icon.stackText:SetText("0")
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
        shouldDesaturate = true
      else
        icon.stackText:Hide()
      end
    else
      local charges = data.chargesData
      local safeCharges = nil
      local overlayStackText = nil
      if isChargeSpell then
        safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      elseif buffOverlayActive and addonTable.TryGetCdmAuraOverlayStackDisplay then
        safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(activeSpellID)
        if safeCharges == nil and overlayStackText == nil and activeSpellID ~= actualID then
          safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(actualID)
        end
      end
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif overlayStackText ~= nil then
        local okSet = pcall(icon.stackText.SetText, icon.stackText, overlayStackText)
        if okSet then
          icon.stackText:SetScale(stackTextScale)
          icon.stackText:Show()
        else
          icon.stackText:Hide()
        end
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    local readySpell = buffOverlayActive or (not isOnCooldown and not notEnoughResources)
    if isItem then
      readySpell = itemCount and itemCount > 0 and not isOnCooldown
    elseif isChargeSpell then
      readySpell = buffOverlayActive or isUsable
    end
    EnsureIconRestored(icon)
    if _useSpellGlows and icon.glowType ~= "off" and readySpell then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    if _cbGradT > 0 and not buffOverlayActive then
      ApplyCdTextGradient(icon.cooldown, _cbGradT, _cbGradR, _cbGradG, _cbGradB, (not isItem) and activeSpellID or nil)
      icon._cdGradApplied = true
    elseif icon._cdGradApplied then
      ResetCdTextGradient(icon.cooldown)
      icon._cdGradApplied = false
    end
    if onMyTab and not demoCdApplied and cdTextScale > 0 and not isOnCooldown and not buffOverlayActive then
      addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, inCombat)
      demoCdApplied = true
    end
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar then
      MasqueGroups.CustomBar:ReSkin()
    end
    if not State.cb1Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBarAnchorFrame)
      local anchorToPoint = profile.customBarAnchorToPoint or "CENTER"
      customBarFrame:ClearAllPoints()
      customBarFrame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
    end
    customBarFrame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  State.customBar1HasActiveTimers = barHasActiveTimers
  customBarFrame:Show()
end
local function UpdateCustomBarPosition()
  if State.cb1Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBarX) == "number" and profile.customBarX or 0
  local posY = type(profile.customBarY) == "number" and profile.customBarY or -200
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBarAnchorFrame)
  local anchorToPoint = profile.customBarAnchorToPoint or "CENTER"
  customBarFrame:ClearAllPoints()
  customBarFrame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
  if customBarFrame.highlightVisible or #State.customBar1Icons > 0 then
    customBarFrame:Show()
  end
end
local function UpdateCustomBarStackTextPositions()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local stackPos = type(profile.customBarStackTextPosition) == "string" and profile.customBarStackTextPosition or "BOTTOMRIGHT"
  local stackOffX = type(profile.customBarStackTextOffsetX) == "number" and profile.customBarStackTextOffsetX or 0
  local stackOffY = type(profile.customBarStackTextOffsetY) == "number" and profile.customBarStackTextOffsetY or 0
  for _, icon in ipairs(State.customBar1Icons) do
    if icon.stackText then
      icon.stackText:ClearAllPoints()
      icon.stackText:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
    end
  end
end
addonTable.CreateCustomBarIcons = CreateCustomBarIcons
addonTable.UpdateCustomBar = UpdateCustomBar
addonTable.UpdateCustomBarPosition = UpdateCustomBarPosition
addonTable.UpdateCustomBarStackTextPositions = UpdateCustomBarStackTextPositions
local function ClearCustomBar2Icons()
  if Masque and MasqueGroups.CustomBar2 then
    for _, icon in ipairs(State.customBar2Icons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CustomBar2)
    end
  end
  for _, icon in ipairs(State.customBar2Icons) do
    HideIconByScale(icon)
    icon:SetScript("OnUpdate", nil)
  end
  wipe(State.customBar2Icons)
end
local function CreateCustomBar2Icons()
  if State.customBar2Moving then return end
  State.customBar2LayoutKey = nil
  ClearCustomBar2Icons()
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar2Enabled then
    customBar2Frame:Hide()
    return
  end
  local entries, entriesEnabled, entryGlowEnabled, entryGlowType, entryHRT = GetCustomBar2Spells()
  if #entries == 0 then
    customBar2Frame:Hide()
    return
  end
  local iconSize = type(profile.customBar2IconSize) == "number" and profile.customBar2IconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, id in ipairs(entries) do
    if entriesEnabled[i] == nil or entriesEnabled[i] ~= false then
      local icon = CreateFrame("Button", "CCMCustomBar2Icon" .. i, customBar2Frame, "BackdropTemplate")
      icon:SetSize(iconSize, iconSize)
      icon:SetFrameStrata(profile.iconStrata or "FULLSCREEN")
      icon:SetFrameLevel(10)
      icon:EnableMouse(false)
      icon.Icon = icon:CreateTexture(nil, "BACKGROUND")
      icon.Icon:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Icon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon.icon = icon.Icon
      AddIconBorder(icon, borderSize)
      icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
      icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Cooldown:SetDrawEdge(false)
      icon.Cooldown:SetDrawBling(false)
      icon.Cooldown:SetDrawSwipe(true)
      icon.Cooldown:SetReverse(false)
      icon.Cooldown:SetHideCountdownNumbers(false)
      icon.cooldown = icon.Cooldown
      icon.stackTextFrame = CreateFrame("Frame", nil, icon)
      icon.stackTextFrame:SetAllPoints()
      icon.stackTextFrame:SetFrameLevel(icon.Cooldown:GetFrameLevel() + 5)
      icon.Count = icon.stackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      icon.Count:SetPoint("BOTTOMRIGHT", icon.stackTextFrame, "BOTTOMRIGHT", -2, 2)
      icon.Count:SetTextColor(1, 1, 1, 1)
      local globalFont, globalOutline = GetGlobalFont()
      local _, fontSize = icon.Count:GetFont()
      icon.Count:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.entryIndex = i
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      icon.glowType = (entryGlowEnabled[i] == true) and (entryGlowType[i] or profile.customBar2SpellGlowDefaultType or "pixel") or "off"
      icon.hideRevealThreshold = tonumber(entryHRT[i]) or 0
      SetGlowIdentityMethods(icon)
      if icon.isItem then
        local itemIcon = C_Item.GetItemIconByID(icon.actualID)
        icon.Icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      else
        local spellInfo = C_Spell.GetSpellInfo(icon.actualID)
        icon.Icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      end
      table.insert(State.customBar2Icons, icon)
      if Masque and profile.enableMasque and MasqueGroups.CustomBar2 then
        SkinButtonWithMasque(icon, MasqueGroups.CustomBar2)
      end
    end
  end
  local centered = profile.customBar2Centered == true
  local x = type(profile.customBar2X) == "number" and profile.customBar2X or 0
  local y = type(profile.customBar2Y) == "number" and profile.customBar2Y or -250
  local anchorFrame, _ = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
  local anchorToPoint = profile.customBar2AnchorToPoint or "CENTER"
  if centered then
    x = 0 + x
  end
  if not State.cb2Dragging then
    customBar2Frame:ClearAllPoints()
    customBar2Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, x, y)
  end
  customBar2Frame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar2 then
    ReSkinMasqueGroup(MasqueGroups.CustomBar2)
  end
end
local function UpdateCustomBar2()
  State.customBar2HasActiveTimers = false
  if State.customBar2Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar2Enabled then
    customBar2Frame:Hide()
    return
  end
  local inCombat = InCombatLockdown()
  local onMyTab = State.guiIsOpen and addonTable.activeTab and addonTable.activeTab() == 4
  if not IsShowModeActive(profile.customBar2ShowMode, true) then
    if not customBar2Frame.highlightVisible and not onMyTab then
      customBar2Frame:Hide()
      return
    end
  end
  if profile.customBar2OutOfCombat == false and not inCombat then
    if not customBar2Frame.highlightVisible then
      customBar2Frame:Hide()
      return
    end
  end
  if #State.customBar2Icons == 0 then
    if not customBar2Frame.highlightVisible and not onMyTab then
      customBar2Frame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBar2IconSize) == "number" and profile.customBar2IconSize or 30
  local spacing = type(profile.customBar2Spacing) == "number" and profile.customBar2Spacing or 2
  local growth = profile.customBar2Growth or "DOWN"
  local anchor = profile.customBar2AnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBar2CdTextScale) == "number" and profile.customBar2CdTextScale or 1.0
  local cdTextHidden = cdTextScale <= 0
  local stackTextScale = type(profile.customBar2StackTextScale) == "number" and profile.customBar2StackTextScale or 1.0
  local centered = profile.customBar2Centered == true
  local cooldownMode = profile.customBar2CooldownMode or "show"
  local _, _, _, _, entryHRT = GetCustomBar2Spells()
  local iconsPerRow = type(profile.customBar2IconsPerRow) == "number" and profile.customBar2IconsPerRow or 20
  local showGCD = profile.customBar2ShowGCD == true
  local cbTrackBuffs = profile.customBar2TrackBuffs ~= false
  local cbAllowBuffSpellInfo = cbTrackBuffs
  local pureBuffSpellIDs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {}
  local barHasActiveTimers = false
  local nowCB = GetTime()
  local cachedGcdInfo = nil
  if C_Spell and C_Spell.GetSpellCooldown then
    if inCombat then
      local okGcd, gi = pcall(C_Spell.GetSpellCooldown, 61304)
      if okGcd and type(gi) == "table" then cachedGcdInfo = gi end
    else
      cachedGcdInfo = C_Spell.GetSpellCooldown(61304)
    end
  end
  RefreshGlowParams()
  wipe(State.customBar2VisibleIcons)
  local visibleIcons = State.customBar2VisibleIcons
  local demoCdApplied = false
  for originalIdx, icon in ipairs(State.customBar2Icons) do
    icon.hideRevealThreshold = tonumber(entryHRT and entryHRT[icon.entryIndex or originalIdx]) or 0
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = actualID
    local iconTexture, itemCount
    local isOnCooldown = false
    local isChargeSpell = false
    local cdStart, cdDuration = 0, 0
    local chargesData = nil
    if isItem then
      iconTexture = icon.cachedItemIcon
      if not iconTexture then
        iconTexture = C_Item.GetItemIconByID(actualID)
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = C_Item.GetItemCount(actualID, false, true)
      cdStart, cdDuration = C_Item.GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
        if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
        icon.cooldown:SetHideCountdownNumbers(false)
      else
        icon.cooldown:Clear()
      end
      local itemNotInBags = not itemCount or itemCount <= 0
      if itemNotInBags or (cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5) then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID, cbAllowBuffSpellInfo) then
        iconTexture = nil
        icon.cooldown:Clear()
      else
        if icon._cachedCBActiveSpellID ~= activeSpellID then
          local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
          icon._cachedCBIconID = spellInfo and spellInfo.iconID or nil
          icon._cachedCBActiveSpellID = activeSpellID
        end
        iconTexture = icon._cachedCBIconID
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          local shouldShowSwipe = true
          if (not isChargeSpell) and ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
            shouldShowSwipe = false
          end
          if shouldShowSwipe and cdStart and cdDuration then
            if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            local shouldShowSwipe = true
            if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
              shouldShowSwipe = false
            end
            if shouldShowSwipe then
              if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            else
              icon.cooldown:Clear()
            end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        end
      end
    end
    local buffOverlayActive = false
    if not isItem and cbTrackBuffs then
      local overlayApplied = false
      if cbTrackBuffs and addonTable.TryApplyLiveAuraOverlay then
        overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, activeSpellID)
        if not overlayApplied and activeSpellID ~= actualID then
          overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, actualID)
        end
      end
      buffOverlayActive = overlayApplied
    end
    if inCombat then pcall(icon.cooldown.SetReverse, icon.cooldown, buffOverlayActive) else icon.cooldown:SetReverse(buffOverlayActive) end
    if not isItem and not isChargeSpell then
      local cdStartPublic = ToPublicNumber(cdStart)
      local cdDurationPublic = ToPublicNumber(cdDuration)
      if cdStartPublic and cdDurationPublic then
        if inCombat then
          local okZero, isZero = pcall(function() return cdStartPublic == 0 end)
          if okZero and isZero then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local okGcd, isGcdMatch = pcall(function()
                  local gcdStart = ToPublicNumber(gcdInfo.startTime)
                  local gcdDuration = ToPublicNumber(gcdInfo.duration)
                  return gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration
                end)
                if okGcd and isGcdMatch then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            local okCD, isCD = pcall(function() return cdStartPublic > 0 and cdDurationPublic > 1.5 end)
            if okCD and isCD then
              isOnCooldown = true
              local ok2, endTime = pcall(function() return cdStartPublic + cdDurationPublic end)
              if ok2 and endTime then
                icon._cdExpectedEnd = endTime
                State.spellCdDurations[activeSpellID] = cdDurationPublic
                if actualID ~= activeSpellID then
                  State.spellCdDurations[actualID] = cdDurationPublic
                end
              end
            end
          end
        else
          if cdStartPublic == 0 then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local gcdStart = ToPublicNumber(gcdInfo.startTime)
                local gcdDuration = ToPublicNumber(gcdInfo.duration)
                if gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            if cdStartPublic > 0 and cdDurationPublic > 1.5 then
              isOnCooldown = true
              icon._cdExpectedEnd = cdStartPublic + cdDurationPublic
              State.spellCdDurations[activeSpellID] = cdDurationPublic
              if actualID ~= activeSpellID then
                State.spellCdDurations[actualID] = cdDurationPublic
              end
            end
          end
        end
      end
      if not isOnCooldown then
        if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 and nowCB < icon._cdExpectedEnd then
          isOnCooldown = true
        end
      end
    end
    local isUsable, notEnoughResources, hasUsability = true, false, false
    if not isItem then
      isUsable, notEnoughResources, hasUsability = GetSpellUsabilityState(activeSpellID)
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
      if isChargeSpell then
        if hasUsability == false then
          isUsable = false
        end
        notEnoughResources = false
      end
    end
    local hasChargeRecharge = false
    if (not isItem) and isChargeSpell and chargesData then
      if inCombat then
        local okRecharge, recharge = pcall(function()
          return chargesData.cooldownStartTime and chargesData.cooldownDuration
            and chargesData.cooldownStartTime > 0 and chargesData.cooldownDuration > 0
        end)
        hasChargeRecharge = okRecharge and recharge or false
      else
        hasChargeRecharge = chargesData.cooldownStartTime and chargesData.cooldownDuration
          and chargesData.cooldownStartTime > 0 and chargesData.cooldownDuration > 0 or false
      end
    end
    if buffOverlayActive or isOnCooldown or hasChargeRecharge then
      barHasActiveTimers = true
    end
    local td = icon._tempData
    if not td then
      td = {}
      icon._tempData = td
    end
    td.iconTexture = iconTexture
    td.itemCount = itemCount
    td.isOnCooldown = isOnCooldown
    td.isChargeSpell = isChargeSpell
    td.isUsable = isUsable
    td.originalIndex = originalIdx
    td.notEnoughResources = notEnoughResources
    td.activeSpellID = activeSpellID
    td.chargesData = chargesData
    td.buffOverlayActive = buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    local isPureBuff = pureBuffSpellIDs[activeSpellID] == true or pureBuffSpellIDs[actualID] == true
    if isPureBuff then
      if not cbTrackBuffs or not buffOverlayActive then
        shouldShow = false
      end
    end
    if not onMyTab and not buffOverlayActive then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          if not icon.isItem and profile.customBar2UseCustomHideReveal and icon.hideRevealThreshold and icon.hideRevealThreshold > 0 then
            local expectedEnd = icon._cdExpectedEnd or 0
            if expectedEnd <= 0 and cdStart and cdDuration then
              expectedEnd = cdStart + cdDuration
            end
            local remaining = expectedEnd - nowCB
            if remaining <= 0 or remaining > icon.hideRevealThreshold then
              shouldShow = false
            end
          else
            shouldShow = false
          end
        elseif notEnoughResources then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      HideIconByScale(icon)
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    State.customBar2HasActiveTimers = barHasActiveTimers
    if not onMyTab then
      customBar2Frame:Hide()
    end
    return
  end
  local totalIcons = #State.customBar2Icons
  local direction = profile.customBar2Direction or "horizontal"
  local isHorizontal = (direction == "horizontal")
  local numRows, numCols
  if centered then
    if isHorizontal then
      numCols = math.min(visibleCount, iconsPerRow)
      numRows = math.ceil(visibleCount / iconsPerRow)
    else
      numRows = math.min(visibleCount, iconsPerRow)
      numCols = math.ceil(visibleCount / iconsPerRow)
    end
  else
    if isHorizontal then
      numCols = math.min(totalIcons, iconsPerRow)
      numRows = math.ceil(totalIcons / iconsPerRow)
    else
      numRows = math.min(totalIcons, iconsPerRow)
      numCols = math.ceil(totalIcons / iconsPerRow)
    end
  end
  local totalWidth, totalHeight
  if isHorizontal then
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  else
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  end
  local posX = type(profile.customBar2X) == "number" and profile.customBar2X or 0
  local posY = type(profile.customBar2Y) == "number" and profile.customBar2Y or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
  local layoutKey = string.format("%d|%d|%s|%s|%d|%s|%d|%d|%s|%s|%s",
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName or "")
  local layoutChanged = layoutKey ~= State.customBar2LayoutKey
  if layoutChanged then
    State.customBar2LayoutKey = layoutKey
  end
  local _useSpellGlows = profile.customBar2UseSpellGlows == true
  local _cbGradT = type(profile.customBar2CdGradientThreshold) == "number" and profile.customBar2CdGradientThreshold or 0
  local _cbGradR, _cbGradG, _cbGradB
  if _cbGradT > 0 then
    _cbGradR = type(profile.customBar2CdGradientR) == "number" and profile.customBar2CdGradientR or 1
    _cbGradG = type(profile.customBar2CdGradientG) == "number" and profile.customBar2CdGradientG or 0
    _cbGradB = type(profile.customBar2CdGradientB) == "number" and profile.customBar2CdGradientB or 0
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = data.activeSpellID or (isItem and actualID or ResolveTrackedSpellID(actualID))
    if icon._lastTexture ~= iconTexture then
      icon.icon:SetTexture(iconTexture)
      icon._lastTexture = iconTexture
    end
    local needsPosition = layoutChanged or (icon.GetNumPoints and icon:GetNumPoints() == 0)
    if needsPosition then
      icon:SetSize(iconSize, iconSize)
      if icon.Icon then
        icon.Icon:SetAllPoints(icon)
      end
      if icon.Cooldown then
        icon.Cooldown:SetAllPoints(icon)
      end
      icon:ClearAllPoints()
      local posIndex = centered and idx or data.originalIndex
      local row, col
      if isHorizontal then
        row = math.floor((posIndex - 1) / iconsPerRow)
        col = (posIndex - 1) % iconsPerRow
      else
        col = math.floor((posIndex - 1) / iconsPerRow)
        row = (posIndex - 1) % iconsPerRow
      end
      local xPos, yPos = 0, 0
      if centered then
        if isHorizontal then
          local rowIconCount = math.min(visibleCount - row * iconsPerRow, iconsPerRow)
          local rowWidth = rowIconCount * iconSize + (rowIconCount - 1) * spacing
          local startX = -rowWidth / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -startX - col * (iconSize + spacing)
          else
            xPos = startX + col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
          else
            yPos = -row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar2Frame, "CENTER", xPos, yPos)
        else
          local colIconCount = math.min(visibleCount - col * iconsPerRow, iconsPerRow)
          local colHeight = colIconCount * iconSize + (colIconCount - 1) * spacing
          local startY = -colHeight / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -col * (iconSize + spacing)
          else
            xPos = col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = -startY + row * (iconSize + spacing)
          else
            yPos = startY - row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar2Frame, "CENTER", xPos, yPos)
        end
      else
        if anchor == "RIGHT" then
          xPos = -col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMRIGHT", customBar2Frame, "BOTTOMRIGHT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPRIGHT", customBar2Frame, "TOPRIGHT", xPos, yPos)
          end
        else
          xPos = col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMLEFT", customBar2Frame, "BOTTOMLEFT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPLEFT", customBar2Frame, "TOPLEFT", xPos, yPos)
          end
        end
      end
    end
    if icon.cooldown._ccmLastScale ~= cdTextScale then
      icon.cooldown:SetScale(cdTextHidden and 1 or cdTextScale)
      icon.cooldown:SetHideCountdownNumbers(cdTextHidden)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local fs = addonTable.GetCachedFontStrings(icon.cooldown)
      for i = 1, #fs do
        local _, sz = fs[i]:GetFont()
        if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
      end
    end
    local shouldDesaturate = false
    local isUsable = icon._tempData and icon._tempData.isUsable
    if isUsable == nil then isUsable = true end
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local buffOverlayActive = icon._tempData and icon._tempData.buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    if buffOverlayActive then
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    elseif isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        local cDesat = GetChargeSpellDesaturation(activeSpellID)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(cDesat)
        else
          icon.icon:SetDesaturated(cDesat and cDesat > 0)
        end
      else
        icon:SetAlpha(1)
        icon.icon:SetDesaturated(false)
      end
    else
      icon:SetAlpha(1)
      if cooldownMode == "desaturate" then
        shouldDesaturate = isUnavailable
      else
        shouldDesaturate = false
      end
    end
    if isItem then
      if itemCount and itemCount > 1 then
        icon.stackText:SetText(itemCount)
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif itemCount and itemCount == 0 then
        icon.stackText:SetText("0")
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
        shouldDesaturate = true
      else
        icon.stackText:Hide()
      end
    else
      local charges = data.chargesData
      local safeCharges = nil
      local overlayStackText = nil
      if isChargeSpell then
        safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      elseif buffOverlayActive and addonTable.TryGetCdmAuraOverlayStackDisplay then
        safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(activeSpellID)
        if safeCharges == nil and overlayStackText == nil and activeSpellID ~= actualID then
          safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(actualID)
        end
      end
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif overlayStackText ~= nil then
        local okSet = pcall(icon.stackText.SetText, icon.stackText, overlayStackText)
        if okSet then
          icon.stackText:SetScale(stackTextScale)
          icon.stackText:Show()
        else
          icon.stackText:Hide()
        end
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    local readySpell = buffOverlayActive or (not isOnCooldown and not notEnoughResources)
    if isItem then
      readySpell = itemCount and itemCount > 0 and not isOnCooldown
    elseif isChargeSpell then
      readySpell = buffOverlayActive or isUsable
    end
    EnsureIconRestored(icon)
    if _useSpellGlows and icon.glowType ~= "off" and readySpell then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    if _cbGradT > 0 and not buffOverlayActive then
      ApplyCdTextGradient(icon.cooldown, _cbGradT, _cbGradR, _cbGradG, _cbGradB, (not isItem) and activeSpellID or nil)
      icon._cdGradApplied = true
    elseif icon._cdGradApplied then
      ResetCdTextGradient(icon.cooldown)
      icon._cdGradApplied = false
    end
    if onMyTab and not demoCdApplied and cdTextScale > 0 and not isOnCooldown and not buffOverlayActive then
      addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, inCombat)
      demoCdApplied = true
    end
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar2 then
      MasqueGroups.CustomBar2:ReSkin()
    end
    if not State.cb2Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
      local anchorToPoint = profile.customBar2AnchorToPoint or "CENTER"
      customBar2Frame:ClearAllPoints()
      customBar2Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
    end
    customBar2Frame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  State.customBar2HasActiveTimers = barHasActiveTimers
  customBar2Frame:Show()
end
local function UpdateCustomBar2Position()
  if State.cb2Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBar2X) == "number" and profile.customBar2X or 0
  local posY = type(profile.customBar2Y) == "number" and profile.customBar2Y or -250
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
  local anchorToPoint = profile.customBar2AnchorToPoint or "CENTER"
  customBar2Frame:ClearAllPoints()
  customBar2Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
  if customBar2Frame.highlightVisible or #State.customBar2Icons > 0 then
    customBar2Frame:Show()
  end
end
local function UpdateCustomBar2StackTextPositions()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local stackPos = type(profile.customBar2StackTextPosition) == "string" and profile.customBar2StackTextPosition or "BOTTOMRIGHT"
  local stackOffX = type(profile.customBar2StackTextOffsetX) == "number" and profile.customBar2StackTextOffsetX or 0
  local stackOffY = type(profile.customBar2StackTextOffsetY) == "number" and profile.customBar2StackTextOffsetY or 0
  for _, icon in ipairs(State.customBar2Icons) do
    if icon.stackText then
      icon.stackText:ClearAllPoints()
      icon.stackText:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
    end
  end
end
addonTable.CreateCustomBar2Icons = CreateCustomBar2Icons
addonTable.UpdateCustomBar2 = UpdateCustomBar2
addonTable.UpdateCustomBar2Position = UpdateCustomBar2Position
addonTable.UpdateCustomBar2StackTextPositions = UpdateCustomBar2StackTextPositions
local function ClearCustomBar3Icons()
  if Masque and MasqueGroups.CustomBar3 then
    for _, icon in ipairs(State.customBar3Icons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CustomBar3)
    end
  end
  for _, icon in ipairs(State.customBar3Icons) do
    HideIconByScale(icon)
    icon:SetScript("OnUpdate", nil)
  end
  wipe(State.customBar3Icons)
end
local function CreateCustomBar3Icons()
  if State.customBar3Moving then return end
  State.customBar3LayoutKey = nil
  ClearCustomBar3Icons()
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar3Enabled then
    customBar3Frame:Hide()
    return
  end
  local entries, entriesEnabled, entryGlowEnabled, entryGlowType, entryHRT = GetCustomBar3Spells()
  if #entries == 0 then
    customBar3Frame:Hide()
    return
  end
  local iconSize = type(profile.customBar3IconSize) == "number" and profile.customBar3IconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, id in ipairs(entries) do
    if entriesEnabled[i] == nil or entriesEnabled[i] ~= false then
      local icon = CreateFrame("Button", "CCMCustomBar3Icon" .. i, customBar3Frame, "BackdropTemplate")
      icon:SetSize(iconSize, iconSize)
      icon:SetFrameStrata(profile.iconStrata or "FULLSCREEN")
      icon:SetFrameLevel(10)
      icon:EnableMouse(false)
      icon.Icon = icon:CreateTexture(nil, "BACKGROUND")
      icon.Icon:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Icon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon.icon = icon.Icon
      AddIconBorder(icon, borderSize)
      icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
      icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Cooldown:SetDrawEdge(false)
      icon.Cooldown:SetDrawBling(false)
      icon.Cooldown:SetDrawSwipe(true)
      icon.Cooldown:SetReverse(false)
      icon.Cooldown:SetHideCountdownNumbers(false)
      icon.cooldown = icon.Cooldown
      icon.stackTextFrame = CreateFrame("Frame", nil, icon)
      icon.stackTextFrame:SetAllPoints()
      icon.stackTextFrame:SetFrameLevel(icon.Cooldown:GetFrameLevel() + 5)
      icon.Count = icon.stackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      icon.Count:SetPoint("BOTTOMRIGHT", icon.stackTextFrame, "BOTTOMRIGHT", -2, 2)
      icon.Count:SetTextColor(1, 1, 1, 1)
      local globalFont, globalOutline = GetGlobalFont()
      local _, fontSize = icon.Count:GetFont()
      icon.Count:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.entryIndex = i
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      icon.glowType = (entryGlowEnabled[i] == true) and (entryGlowType[i] or profile.customBar3SpellGlowDefaultType or "pixel") or "off"
      icon.hideRevealThreshold = tonumber(entryHRT[i]) or 0
      SetGlowIdentityMethods(icon)
      if icon.isItem then
        local itemIcon = C_Item.GetItemIconByID(icon.actualID)
        icon.Icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      else
        local spellInfo = C_Spell.GetSpellInfo(icon.actualID)
        icon.Icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      end
      table.insert(State.customBar3Icons, icon)
      if Masque and profile.enableMasque and MasqueGroups.CustomBar3 then
        SkinButtonWithMasque(icon, MasqueGroups.CustomBar3)
      end
    end
  end
  local centered = profile.customBar3Centered == true
  local x = type(profile.customBar3X) == "number" and profile.customBar3X or 0
  local y = type(profile.customBar3Y) == "number" and profile.customBar3Y or -300
  local anchorFrame, _ = ResolveCustomBarAnchorFrame(profile.customBar3AnchorFrame)
  local anchorToPoint = profile.customBar3AnchorToPoint or "CENTER"
  if centered then
    x = 0 + x
  end
  if not State.cb3Dragging then
    customBar3Frame:ClearAllPoints()
    customBar3Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, x, y)
  end
  customBar3Frame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar3 then
    ReSkinMasqueGroup(MasqueGroups.CustomBar3)
  end
end
local function UpdateCustomBar3()
  if State.customBar3Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar3Enabled then
    customBar3Frame:Hide()
    return
  end
  local inCombat = InCombatLockdown()
  local onMyTab = State.guiIsOpen and addonTable.activeTab and addonTable.activeTab() == 5
  if not IsShowModeActive(profile.customBar3ShowMode, true) then
    if not customBar3Frame.highlightVisible and not onMyTab then
      customBar3Frame:Hide()
      return
    end
  end
  if profile.customBar3OutOfCombat == false and not inCombat then
    if not customBar3Frame.highlightVisible then
      customBar3Frame:Hide()
      return
    end
  end
  if #State.customBar3Icons == 0 then
    if not customBar3Frame.highlightVisible and not onMyTab then
      customBar3Frame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBar3IconSize) == "number" and profile.customBar3IconSize or 30
  local spacing = type(profile.customBar3Spacing) == "number" and profile.customBar3Spacing or 2
  local growth = profile.customBar3Growth or "DOWN"
  local anchor = profile.customBar3AnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBar3CdTextScale) == "number" and profile.customBar3CdTextScale or 1.0
  local cdTextHidden = cdTextScale <= 0
  local stackTextScale = type(profile.customBar3StackTextScale) == "number" and profile.customBar3StackTextScale or 1.0
  local centered = profile.customBar3Centered == true
  local cooldownMode = profile.customBar3CooldownMode or "show"
  local _, _, _, _, entryHRT = GetCustomBar3Spells()
  local iconsPerRow = type(profile.customBar3IconsPerRow) == "number" and profile.customBar3IconsPerRow or 20
  local showGCD = profile.customBar3ShowGCD == true
  local cbTrackBuffs = profile.customBar3TrackBuffs ~= false
  local cbAllowBuffSpellInfo = cbTrackBuffs
  local pureBuffSpellIDs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {}
  local nowCB = GetTime()
  local cachedGcdInfo = nil
  if C_Spell and C_Spell.GetSpellCooldown then
    if inCombat then
      local okGcd, gi = pcall(C_Spell.GetSpellCooldown, 61304)
      if okGcd and type(gi) == "table" then cachedGcdInfo = gi end
    else
      cachedGcdInfo = C_Spell.GetSpellCooldown(61304)
    end
  end
  RefreshGlowParams()
  wipe(State.customBar3VisibleIcons)
  local visibleIcons = State.customBar3VisibleIcons
  local demoCdApplied = false
  for originalIdx, icon in ipairs(State.customBar3Icons) do
    icon.hideRevealThreshold = tonumber(entryHRT and entryHRT[icon.entryIndex or originalIdx]) or 0
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = actualID
    local iconTexture, itemCount
    local isOnCooldown = false
    local isChargeSpell = false
    local cdStart, cdDuration = 0, 0
    local chargesData = nil
    if isItem then
      iconTexture = icon.cachedItemIcon
      if not iconTexture then
        iconTexture = C_Item.GetItemIconByID(actualID)
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = C_Item.GetItemCount(actualID, false, true)
      cdStart, cdDuration = C_Item.GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
        if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
        icon.cooldown:SetHideCountdownNumbers(false)
      else
        icon.cooldown:Clear()
      end
      local itemNotInBags = not itemCount or itemCount <= 0
      if itemNotInBags or (cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5) then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID, cbAllowBuffSpellInfo) then
        iconTexture = nil
        icon.cooldown:Clear()
      else
        if icon._cachedCBActiveSpellID ~= activeSpellID then
          local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
          icon._cachedCBIconID = spellInfo and spellInfo.iconID or nil
          icon._cachedCBActiveSpellID = activeSpellID
        end
        iconTexture = icon._cachedCBIconID
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          local shouldShowSwipe = true
          if (not isChargeSpell) and ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
            shouldShowSwipe = false
          end
          if shouldShowSwipe and cdStart and cdDuration then
            if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            local shouldShowSwipe = true
            if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
              shouldShowSwipe = false
            end
            if shouldShowSwipe then
              if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            else
              icon.cooldown:Clear()
            end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        end
      end
    end
    local buffOverlayActive = false
    if not isItem and cbTrackBuffs then
      local overlayApplied = false
      if cbTrackBuffs and addonTable.TryApplyLiveAuraOverlay then
        overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, activeSpellID)
        if not overlayApplied and activeSpellID ~= actualID then
          overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, actualID)
        end
      end
      buffOverlayActive = overlayApplied
    end
    if inCombat then pcall(icon.cooldown.SetReverse, icon.cooldown, buffOverlayActive) else icon.cooldown:SetReverse(buffOverlayActive) end
    if not isItem and not isChargeSpell then
      local cdStartPublic = ToPublicNumber(cdStart)
      local cdDurationPublic = ToPublicNumber(cdDuration)
      if cdStartPublic and cdDurationPublic then
        if inCombat then
          local okZero, isZero = pcall(function() return cdStartPublic == 0 end)
          if okZero and isZero then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local okGcd, isGcdMatch = pcall(function()
                  local gcdStart = ToPublicNumber(gcdInfo.startTime)
                  local gcdDuration = ToPublicNumber(gcdInfo.duration)
                  return gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration
                end)
                if okGcd and isGcdMatch then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            local okCD, isCD = pcall(function() return cdStartPublic > 0 and cdDurationPublic > 1.5 end)
            if okCD and isCD then
              isOnCooldown = true
              local ok2, endTime = pcall(function() return cdStartPublic + cdDurationPublic end)
              if ok2 and endTime then
                icon._cdExpectedEnd = endTime
                State.spellCdDurations[activeSpellID] = cdDurationPublic
                if actualID ~= activeSpellID then
                  State.spellCdDurations[actualID] = cdDurationPublic
                end
              end
            end
          end
        else
          if cdStartPublic == 0 then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local gcdStart = ToPublicNumber(gcdInfo.startTime)
                local gcdDuration = ToPublicNumber(gcdInfo.duration)
                if gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            if cdStartPublic > 0 and cdDurationPublic > 1.5 then
              isOnCooldown = true
              icon._cdExpectedEnd = cdStartPublic + cdDurationPublic
              State.spellCdDurations[activeSpellID] = cdDurationPublic
              if actualID ~= activeSpellID then
                State.spellCdDurations[actualID] = cdDurationPublic
              end
            end
          end
        end
      end
      if not isOnCooldown then
        if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 and nowCB < icon._cdExpectedEnd then
          isOnCooldown = true
        end
      end
    end
    local isUsable, notEnoughResources, hasUsability = true, false, false
    if not isItem then
      isUsable, notEnoughResources, hasUsability = GetSpellUsabilityState(activeSpellID)
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
      if isChargeSpell then
        if hasUsability == false then
          isUsable = false
        end
        notEnoughResources = false
      end
    end
    local td = icon._tempData
    if not td then
      td = {}
      icon._tempData = td
    end
    td.iconTexture = iconTexture
    td.itemCount = itemCount
    td.isOnCooldown = isOnCooldown
    td.isChargeSpell = isChargeSpell
    td.isUsable = isUsable
    td.originalIndex = originalIdx
    td.notEnoughResources = notEnoughResources
    td.activeSpellID = activeSpellID
    td.chargesData = chargesData
    td.buffOverlayActive = buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    local isPureBuff = pureBuffSpellIDs[activeSpellID] == true or pureBuffSpellIDs[actualID] == true
    if isPureBuff then
      if not cbTrackBuffs or not buffOverlayActive then
        shouldShow = false
      end
    end
    if not onMyTab and not buffOverlayActive then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          if not icon.isItem and profile.customBar3UseCustomHideReveal and icon.hideRevealThreshold and icon.hideRevealThreshold > 0 then
            local expectedEnd = icon._cdExpectedEnd or 0
            if expectedEnd <= 0 and cdStart and cdDuration then
              expectedEnd = cdStart + cdDuration
            end
            local remaining = expectedEnd - nowCB
            if remaining <= 0 or remaining > icon.hideRevealThreshold then
              shouldShow = false
            end
          else
            shouldShow = false
          end
        elseif notEnoughResources then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      HideIconByScale(icon)
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    if not onMyTab then
      customBar3Frame:Hide()
    end
    return
  end
  local totalIcons = #State.customBar3Icons
  local direction = profile.customBar3Direction or "horizontal"
  local isHorizontal = (direction == "horizontal")
  local numRows, numCols
  if centered then
    if isHorizontal then
      numCols = math.min(visibleCount, iconsPerRow)
      numRows = math.ceil(visibleCount / iconsPerRow)
    else
      numRows = math.min(visibleCount, iconsPerRow)
      numCols = math.ceil(visibleCount / iconsPerRow)
    end
  else
    if isHorizontal then
      numCols = math.min(totalIcons, iconsPerRow)
      numRows = math.ceil(totalIcons / iconsPerRow)
    else
      numRows = math.min(totalIcons, iconsPerRow)
      numCols = math.ceil(totalIcons / iconsPerRow)
    end
  end
  local totalWidth, totalHeight
  if isHorizontal then
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  else
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  end
  local posX = type(profile.customBar3X) == "number" and profile.customBar3X or 0
  local posY = type(profile.customBar3Y) == "number" and profile.customBar3Y or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBar3AnchorFrame)
  local layoutKey = string.format("%d|%d|%s|%s|%d|%s|%d|%d|%s|%s|%s",
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName or "")
  local layoutChanged = layoutKey ~= State.customBar3LayoutKey
  if layoutChanged then
    State.customBar3LayoutKey = layoutKey
  end
  local _useSpellGlows = profile.customBar3UseSpellGlows == true
  local _cbGradT = type(profile.customBar3CdGradientThreshold) == "number" and profile.customBar3CdGradientThreshold or 0
  local _cbGradR, _cbGradG, _cbGradB
  if _cbGradT > 0 then
    _cbGradR = type(profile.customBar3CdGradientR) == "number" and profile.customBar3CdGradientR or 1
    _cbGradG = type(profile.customBar3CdGradientG) == "number" and profile.customBar3CdGradientG or 0
    _cbGradB = type(profile.customBar3CdGradientB) == "number" and profile.customBar3CdGradientB or 0
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = data.activeSpellID or (isItem and actualID or ResolveTrackedSpellID(actualID))
    if icon._lastTexture ~= iconTexture then
      icon.icon:SetTexture(iconTexture)
      icon._lastTexture = iconTexture
    end
    local needsPosition = layoutChanged or (icon.GetNumPoints and icon:GetNumPoints() == 0)
    if needsPosition then
      icon:SetSize(iconSize, iconSize)
      if icon.Icon then
        icon.Icon:SetAllPoints(icon)
      end
      if icon.Cooldown then
        icon.Cooldown:SetAllPoints(icon)
      end
      icon:ClearAllPoints()
      local posIndex = centered and idx or data.originalIndex
      local row, col
      if isHorizontal then
        row = math.floor((posIndex - 1) / iconsPerRow)
        col = (posIndex - 1) % iconsPerRow
      else
        col = math.floor((posIndex - 1) / iconsPerRow)
        row = (posIndex - 1) % iconsPerRow
      end
      local xPos, yPos = 0, 0
      if centered then
        if isHorizontal then
          local rowIconCount = math.min(visibleCount - row * iconsPerRow, iconsPerRow)
          local rowWidth = rowIconCount * iconSize + (rowIconCount - 1) * spacing
          local startX = -rowWidth / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -startX - col * (iconSize + spacing)
          else
            xPos = startX + col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
          else
            yPos = -row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar3Frame, "CENTER", xPos, yPos)
        else
          local colIconCount = math.min(visibleCount - col * iconsPerRow, iconsPerRow)
          local colHeight = colIconCount * iconSize + (colIconCount - 1) * spacing
          local startY = -colHeight / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -col * (iconSize + spacing)
          else
            xPos = col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = -startY + row * (iconSize + spacing)
          else
            yPos = startY - row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar3Frame, "CENTER", xPos, yPos)
        end
      else
        if anchor == "RIGHT" then
          xPos = -col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMRIGHT", customBar3Frame, "BOTTOMRIGHT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPRIGHT", customBar3Frame, "TOPRIGHT", xPos, yPos)
          end
        else
          xPos = col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMLEFT", customBar3Frame, "BOTTOMLEFT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPLEFT", customBar3Frame, "TOPLEFT", xPos, yPos)
          end
        end
      end
    end
    if icon.cooldown._ccmLastScale ~= cdTextScale then
      icon.cooldown:SetScale(cdTextHidden and 1 or cdTextScale)
      icon.cooldown:SetHideCountdownNumbers(cdTextHidden)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local fs = addonTable.GetCachedFontStrings(icon.cooldown)
      for i = 1, #fs do
        local _, sz = fs[i]:GetFont()
        if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
      end
    end
    local shouldDesaturate = false
    local isUsable = icon._tempData and icon._tempData.isUsable
    if isUsable == nil then isUsable = true end
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local buffOverlayActive = icon._tempData and icon._tempData.buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    if buffOverlayActive then
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    elseif isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        local cDesat = GetChargeSpellDesaturation(activeSpellID)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(cDesat)
        else
          icon.icon:SetDesaturated(cDesat and cDesat > 0)
        end
      else
        icon:SetAlpha(1)
        icon.icon:SetDesaturated(false)
      end
    else
      icon:SetAlpha(1)
      if cooldownMode == "desaturate" then
        shouldDesaturate = isUnavailable
      else
        shouldDesaturate = false
      end
    end
    if isItem then
      if itemCount and itemCount > 1 then
        icon.stackText:SetText(itemCount)
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif itemCount and itemCount == 0 then
        icon.stackText:SetText("0")
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
        shouldDesaturate = true
      else
        icon.stackText:Hide()
      end
    else
      local charges = data.chargesData
      local safeCharges = nil
      local overlayStackText = nil
      if isChargeSpell then
        safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      elseif buffOverlayActive and addonTable.TryGetCdmAuraOverlayStackDisplay then
        safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(activeSpellID)
        if safeCharges == nil and overlayStackText == nil and activeSpellID ~= actualID then
          safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(actualID)
        end
      end
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif overlayStackText ~= nil then
        local okSet = pcall(icon.stackText.SetText, icon.stackText, overlayStackText)
        if okSet then
          icon.stackText:SetScale(stackTextScale)
          icon.stackText:Show()
        else
          icon.stackText:Hide()
        end
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    local readySpell = buffOverlayActive or (not isOnCooldown and not notEnoughResources)
    if isItem then
      readySpell = itemCount and itemCount > 0 and not isOnCooldown
    elseif isChargeSpell then
      readySpell = buffOverlayActive or isUsable
    end
    EnsureIconRestored(icon)
    if _useSpellGlows and icon.glowType ~= "off" and readySpell then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    if _cbGradT > 0 and not buffOverlayActive then
      ApplyCdTextGradient(icon.cooldown, _cbGradT, _cbGradR, _cbGradG, _cbGradB, (not isItem) and activeSpellID or nil)
      icon._cdGradApplied = true
    elseif icon._cdGradApplied then
      ResetCdTextGradient(icon.cooldown)
      icon._cdGradApplied = false
    end
    if onMyTab and not demoCdApplied and cdTextScale > 0 and not isOnCooldown and not buffOverlayActive then
      addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, inCombat)
      demoCdApplied = true
    end
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar3 then
      MasqueGroups.CustomBar3:ReSkin()
    end
    if not State.cb3Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar3AnchorFrame)
      local anchorToPoint = profile.customBar3AnchorToPoint or "CENTER"
      customBar3Frame:ClearAllPoints()
      customBar3Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
    end
    customBar3Frame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  customBar3Frame:Show()
end
local function UpdateCustomBar3Position()
  if State.cb3Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBar3X) == "number" and profile.customBar3X or 0
  local posY = type(profile.customBar3Y) == "number" and profile.customBar3Y or -300
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar3AnchorFrame)
  local anchorToPoint = profile.customBar3AnchorToPoint or "CENTER"
  customBar3Frame:ClearAllPoints()
  customBar3Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
  if customBar3Frame.highlightVisible or #State.customBar3Icons > 0 then
    customBar3Frame:Show()
  end
end
local function UpdateCustomBar3StackTextPositions()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local stackPos = type(profile.customBar3StackTextPosition) == "string" and profile.customBar3StackTextPosition or "BOTTOMRIGHT"
  local stackOffX = type(profile.customBar3StackTextOffsetX) == "number" and profile.customBar3StackTextOffsetX or 0
  local stackOffY = type(profile.customBar3StackTextOffsetY) == "number" and profile.customBar3StackTextOffsetY or 0
  for _, icon in ipairs(State.customBar3Icons) do
    if icon.stackText then
      icon.stackText:ClearAllPoints()
      icon.stackText:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
    end
  end
end
addonTable.CreateCustomBar3Icons = CreateCustomBar3Icons
addonTable.UpdateCustomBar3 = UpdateCustomBar3
addonTable.UpdateCustomBar3Position = UpdateCustomBar3Position
addonTable.UpdateCustomBar3StackTextPositions = UpdateCustomBar3StackTextPositions
local function ClearCustomBar4Icons()
  if Masque and MasqueGroups.CustomBar4 then
    for _, icon in ipairs(State.customBar4Icons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CustomBar4)
    end
  end
  for _, icon in ipairs(State.customBar4Icons) do
    HideIconByScale(icon)
    icon:SetScript("OnUpdate", nil)
  end
  wipe(State.customBar4Icons)
end
local function CreateCustomBar4Icons()
  if State.customBar4Moving then return end
  State.customBar4LayoutKey = nil
  ClearCustomBar4Icons()
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar4Enabled then
    customBar4Frame:Hide()
    return
  end
  local entries, entriesEnabled, entryGlowEnabled, entryGlowType, entryHRT = GetCustomBar4Spells()
  if #entries == 0 then
    customBar4Frame:Hide()
    return
  end
  local iconSize = type(profile.customBar4IconSize) == "number" and profile.customBar4IconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, id in ipairs(entries) do
    if entriesEnabled[i] == nil or entriesEnabled[i] ~= false then
      local icon = CreateFrame("Button", "CCMCustomBar4Icon" .. i, customBar4Frame, "BackdropTemplate")
      icon:SetSize(iconSize, iconSize)
      icon:SetFrameStrata(profile.iconStrata or "FULLSCREEN")
      icon:SetFrameLevel(10)
      icon:EnableMouse(false)
      icon.Icon = icon:CreateTexture(nil, "BACKGROUND")
      icon.Icon:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Icon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon.icon = icon.Icon
      AddIconBorder(icon, borderSize)
      icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
      icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Cooldown:SetDrawEdge(false)
      icon.Cooldown:SetDrawBling(false)
      icon.Cooldown:SetDrawSwipe(true)
      icon.Cooldown:SetReverse(false)
      icon.Cooldown:SetHideCountdownNumbers(false)
      icon.cooldown = icon.Cooldown
      icon.stackTextFrame = CreateFrame("Frame", nil, icon)
      icon.stackTextFrame:SetAllPoints()
      icon.stackTextFrame:SetFrameLevel(icon.Cooldown:GetFrameLevel() + 5)
      icon.Count = icon.stackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      icon.Count:SetPoint("BOTTOMRIGHT", icon.stackTextFrame, "BOTTOMRIGHT", -2, 2)
      icon.Count:SetTextColor(1, 1, 1, 1)
      local globalFont, globalOutline = GetGlobalFont()
      local _, fontSize = icon.Count:GetFont()
      icon.Count:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.entryIndex = i
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      icon.glowType = (entryGlowEnabled[i] == true) and (entryGlowType[i] or profile.customBar4SpellGlowDefaultType or "pixel") or "off"
      icon.hideRevealThreshold = tonumber(entryHRT[i]) or 0
      SetGlowIdentityMethods(icon)
      if icon.isItem then
        local itemIcon = C_Item.GetItemIconByID(icon.actualID)
        icon.Icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      else
        local spellInfo = C_Spell.GetSpellInfo(icon.actualID)
        icon.Icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      end
      table.insert(State.customBar4Icons, icon)
      if Masque and profile.enableMasque and MasqueGroups.CustomBar4 then
        SkinButtonWithMasque(icon, MasqueGroups.CustomBar4)
      end
    end
  end
  local centered = profile.customBar4Centered == true
  local x = type(profile.customBar4X) == "number" and profile.customBar4X or 0
  local y = type(profile.customBar4Y) == "number" and profile.customBar4Y or -300
  local anchorFrame, _ = ResolveCustomBarAnchorFrame(profile.customBar4AnchorFrame)
  local anchorToPoint = profile.customBar4AnchorToPoint or "CENTER"
  if centered then
    x = 0 + x
  end
  if not State.cb4Dragging then
    customBar4Frame:ClearAllPoints()
    customBar4Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, x, y)
  end
  customBar4Frame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar4 then
    ReSkinMasqueGroup(MasqueGroups.CustomBar4)
  end
end
local function UpdateCustomBar4()
  if State.customBar4Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar4Enabled then
    customBar4Frame:Hide()
    return
  end
  local inCombat = InCombatLockdown()
  local onMyTab = State.guiIsOpen and addonTable.activeTab and addonTable.activeTab() == 5
  if not IsShowModeActive(profile.customBar4ShowMode, true) then
    if not customBar4Frame.highlightVisible and not onMyTab then
      customBar4Frame:Hide()
      return
    end
  end
  if profile.customBar4OutOfCombat == false and not inCombat then
    if not customBar4Frame.highlightVisible then
      customBar4Frame:Hide()
      return
    end
  end
  if #State.customBar4Icons == 0 then
    if not customBar4Frame.highlightVisible and not onMyTab then
      customBar4Frame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBar4IconSize) == "number" and profile.customBar4IconSize or 30
  local spacing = type(profile.customBar4Spacing) == "number" and profile.customBar4Spacing or 2
  local growth = profile.customBar4Growth or "DOWN"
  local anchor = profile.customBar4AnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBar4CdTextScale) == "number" and profile.customBar4CdTextScale or 1.0
  local cdTextHidden = cdTextScale <= 0
  local stackTextScale = type(profile.customBar4StackTextScale) == "number" and profile.customBar4StackTextScale or 1.0
  local centered = profile.customBar4Centered == true
  local cooldownMode = profile.customBar4CooldownMode or "show"
  local _, _, _, _, entryHRT = GetCustomBar4Spells()
  local iconsPerRow = type(profile.customBar4IconsPerRow) == "number" and profile.customBar4IconsPerRow or 20
  local showGCD = profile.customBar4ShowGCD == true
  local cbTrackBuffs = profile.customBar4TrackBuffs ~= false
  local cbAllowBuffSpellInfo = cbTrackBuffs
  local pureBuffSpellIDs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {}
  local nowCB = GetTime()
  local cachedGcdInfo = nil
  if C_Spell and C_Spell.GetSpellCooldown then
    if inCombat then
      local okGcd, gi = pcall(C_Spell.GetSpellCooldown, 61304)
      if okGcd and type(gi) == "table" then cachedGcdInfo = gi end
    else
      cachedGcdInfo = C_Spell.GetSpellCooldown(61304)
    end
  end
  RefreshGlowParams()
  wipe(State.customBar4VisibleIcons)
  local visibleIcons = State.customBar4VisibleIcons
  local demoCdApplied = false
  for originalIdx, icon in ipairs(State.customBar4Icons) do
    icon.hideRevealThreshold = tonumber(entryHRT and entryHRT[icon.entryIndex or originalIdx]) or 0
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = actualID
    local iconTexture, itemCount
    local isOnCooldown = false
    local isChargeSpell = false
    local cdStart, cdDuration = 0, 0
    local chargesData = nil
    if isItem then
      iconTexture = icon.cachedItemIcon
      if not iconTexture then
        iconTexture = C_Item.GetItemIconByID(actualID)
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = C_Item.GetItemCount(actualID, false, true)
      cdStart, cdDuration = C_Item.GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
        if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
        icon.cooldown:SetHideCountdownNumbers(false)
      else
        icon.cooldown:Clear()
      end
      local itemNotInBags = not itemCount or itemCount <= 0
      if itemNotInBags or (cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5) then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID, cbAllowBuffSpellInfo) then
        iconTexture = nil
        icon.cooldown:Clear()
      else
        if icon._cachedCBActiveSpellID ~= activeSpellID then
          local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
          icon._cachedCBIconID = spellInfo and spellInfo.iconID or nil
          icon._cachedCBActiveSpellID = activeSpellID
        end
        iconTexture = icon._cachedCBIconID
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          local shouldShowSwipe = true
          if (not isChargeSpell) and ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
            shouldShowSwipe = false
          end
          if shouldShowSwipe and cdStart and cdDuration then
            if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            local shouldShowSwipe = true
            if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
              shouldShowSwipe = false
            end
            if shouldShowSwipe then
              if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            else
              icon.cooldown:Clear()
            end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        end
      end
    end
    local buffOverlayActive = false
    if not isItem and cbTrackBuffs then
      local overlayApplied = false
      if cbTrackBuffs and addonTable.TryApplyLiveAuraOverlay then
        overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, activeSpellID)
        if not overlayApplied and activeSpellID ~= actualID then
          overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, actualID)
        end
      end
      buffOverlayActive = overlayApplied
    end
    if inCombat then pcall(icon.cooldown.SetReverse, icon.cooldown, buffOverlayActive) else icon.cooldown:SetReverse(buffOverlayActive) end
    if not isItem and not isChargeSpell then
      local cdStartPublic = ToPublicNumber(cdStart)
      local cdDurationPublic = ToPublicNumber(cdDuration)
      if cdStartPublic and cdDurationPublic then
        if inCombat then
          local okZero, isZero = pcall(function() return cdStartPublic == 0 end)
          if okZero and isZero then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local okGcd, isGcdMatch = pcall(function()
                  local gcdStart = ToPublicNumber(gcdInfo.startTime)
                  local gcdDuration = ToPublicNumber(gcdInfo.duration)
                  return gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration
                end)
                if okGcd and isGcdMatch then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            local okCD, isCD = pcall(function() return cdStartPublic > 0 and cdDurationPublic > 1.5 end)
            if okCD and isCD then
              isOnCooldown = true
              local ok2, endTime = pcall(function() return cdStartPublic + cdDurationPublic end)
              if ok2 and endTime then
                icon._cdExpectedEnd = endTime
                State.spellCdDurations[activeSpellID] = cdDurationPublic
                if actualID ~= activeSpellID then
                  State.spellCdDurations[actualID] = cdDurationPublic
                end
              end
            end
          end
        else
          if cdStartPublic == 0 then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local gcdStart = ToPublicNumber(gcdInfo.startTime)
                local gcdDuration = ToPublicNumber(gcdInfo.duration)
                if gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            if cdStartPublic > 0 and cdDurationPublic > 1.5 then
              isOnCooldown = true
              icon._cdExpectedEnd = cdStartPublic + cdDurationPublic
              State.spellCdDurations[activeSpellID] = cdDurationPublic
              if actualID ~= activeSpellID then
                State.spellCdDurations[actualID] = cdDurationPublic
              end
            end
          end
        end
      end
      if not isOnCooldown then
        if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 and nowCB < icon._cdExpectedEnd then
          isOnCooldown = true
        end
      end
    end
    local isUsable, notEnoughResources, hasUsability = true, false, false
    if not isItem then
      isUsable, notEnoughResources, hasUsability = GetSpellUsabilityState(activeSpellID)
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
      if isChargeSpell then
        if hasUsability == false then
          isUsable = false
        end
        notEnoughResources = false
      end
    end
    local td = icon._tempData
    if not td then
      td = {}
      icon._tempData = td
    end
    td.iconTexture = iconTexture
    td.itemCount = itemCount
    td.isOnCooldown = isOnCooldown
    td.isChargeSpell = isChargeSpell
    td.isUsable = isUsable
    td.originalIndex = originalIdx
    td.notEnoughResources = notEnoughResources
    td.activeSpellID = activeSpellID
    td.chargesData = chargesData
    td.buffOverlayActive = buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    local isPureBuff = pureBuffSpellIDs[activeSpellID] == true or pureBuffSpellIDs[actualID] == true
    if isPureBuff then
      if not cbTrackBuffs or not buffOverlayActive then
        shouldShow = false
      end
    end
    if not onMyTab and not buffOverlayActive then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          if not icon.isItem and profile.customBar4UseCustomHideReveal and icon.hideRevealThreshold and icon.hideRevealThreshold > 0 then
            local expectedEnd = icon._cdExpectedEnd or 0
            if expectedEnd <= 0 and cdStart and cdDuration then
              expectedEnd = cdStart + cdDuration
            end
            local remaining = expectedEnd - nowCB
            if remaining <= 0 or remaining > icon.hideRevealThreshold then
              shouldShow = false
            end
          else
            shouldShow = false
          end
        elseif notEnoughResources then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      HideIconByScale(icon)
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    if not onMyTab then
      customBar4Frame:Hide()
    end
    return
  end
  local totalIcons = #State.customBar4Icons
  local direction = profile.customBar4Direction or "horizontal"
  local isHorizontal = (direction == "horizontal")
  local numRows, numCols
  if centered then
    if isHorizontal then
      numCols = math.min(visibleCount, iconsPerRow)
      numRows = math.ceil(visibleCount / iconsPerRow)
    else
      numRows = math.min(visibleCount, iconsPerRow)
      numCols = math.ceil(visibleCount / iconsPerRow)
    end
  else
    if isHorizontal then
      numCols = math.min(totalIcons, iconsPerRow)
      numRows = math.ceil(totalIcons / iconsPerRow)
    else
      numRows = math.min(totalIcons, iconsPerRow)
      numCols = math.ceil(totalIcons / iconsPerRow)
    end
  end
  local totalWidth, totalHeight
  if isHorizontal then
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  else
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  end
  local posX = type(profile.customBar4X) == "number" and profile.customBar4X or 0
  local posY = type(profile.customBar4Y) == "number" and profile.customBar4Y or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBar4AnchorFrame)
  local layoutKey = string.format("%d|%d|%s|%s|%d|%s|%d|%d|%s|%s|%s",
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName or "")
  local layoutChanged = layoutKey ~= State.customBar4LayoutKey
  if layoutChanged then
    State.customBar4LayoutKey = layoutKey
  end
  local _useSpellGlows = profile.customBar4UseSpellGlows == true
  local _cbGradT = type(profile.customBar4CdGradientThreshold) == "number" and profile.customBar4CdGradientThreshold or 0
  local _cbGradR, _cbGradG, _cbGradB
  if _cbGradT > 0 then
    _cbGradR = type(profile.customBar4CdGradientR) == "number" and profile.customBar4CdGradientR or 1
    _cbGradG = type(profile.customBar4CdGradientG) == "number" and profile.customBar4CdGradientG or 0
    _cbGradB = type(profile.customBar4CdGradientB) == "number" and profile.customBar4CdGradientB or 0
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = data.activeSpellID or (isItem and actualID or ResolveTrackedSpellID(actualID))
    if icon._lastTexture ~= iconTexture then
      icon.icon:SetTexture(iconTexture)
      icon._lastTexture = iconTexture
    end
    local needsPosition = layoutChanged or (icon.GetNumPoints and icon:GetNumPoints() == 0)
    if needsPosition then
      icon:SetSize(iconSize, iconSize)
      if icon.Icon then
        icon.Icon:SetAllPoints(icon)
      end
      if icon.Cooldown then
        icon.Cooldown:SetAllPoints(icon)
      end
      icon:ClearAllPoints()
      local posIndex = centered and idx or data.originalIndex
      local row, col
      if isHorizontal then
        row = math.floor((posIndex - 1) / iconsPerRow)
        col = (posIndex - 1) % iconsPerRow
      else
        col = math.floor((posIndex - 1) / iconsPerRow)
        row = (posIndex - 1) % iconsPerRow
      end
      local xPos, yPos = 0, 0
      if centered then
        if isHorizontal then
          local rowIconCount = math.min(visibleCount - row * iconsPerRow, iconsPerRow)
          local rowWidth = rowIconCount * iconSize + (rowIconCount - 1) * spacing
          local startX = -rowWidth / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -startX - col * (iconSize + spacing)
          else
            xPos = startX + col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
          else
            yPos = -row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar4Frame, "CENTER", xPos, yPos)
        else
          local colIconCount = math.min(visibleCount - col * iconsPerRow, iconsPerRow)
          local colHeight = colIconCount * iconSize + (colIconCount - 1) * spacing
          local startY = -colHeight / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -col * (iconSize + spacing)
          else
            xPos = col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = -startY + row * (iconSize + spacing)
          else
            yPos = startY - row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar4Frame, "CENTER", xPos, yPos)
        end
      else
        if anchor == "RIGHT" then
          xPos = -col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMRIGHT", customBar4Frame, "BOTTOMRIGHT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPRIGHT", customBar4Frame, "TOPRIGHT", xPos, yPos)
          end
        else
          xPos = col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMLEFT", customBar4Frame, "BOTTOMLEFT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPLEFT", customBar4Frame, "TOPLEFT", xPos, yPos)
          end
        end
      end
    end
    if icon.cooldown._ccmLastScale ~= cdTextScale then
      icon.cooldown:SetScale(cdTextHidden and 1 or cdTextScale)
      icon.cooldown:SetHideCountdownNumbers(cdTextHidden)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local fs = addonTable.GetCachedFontStrings(icon.cooldown)
      for i = 1, #fs do
        local _, sz = fs[i]:GetFont()
        if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
      end
    end
    local shouldDesaturate = false
    local isUsable = icon._tempData and icon._tempData.isUsable
    if isUsable == nil then isUsable = true end
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local buffOverlayActive = icon._tempData and icon._tempData.buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    if buffOverlayActive then
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    elseif isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        local cDesat = GetChargeSpellDesaturation(activeSpellID)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(cDesat)
        else
          icon.icon:SetDesaturated(cDesat and cDesat > 0)
        end
      else
        icon:SetAlpha(1)
        icon.icon:SetDesaturated(false)
      end
    else
      icon:SetAlpha(1)
      if cooldownMode == "desaturate" then
        shouldDesaturate = isUnavailable
      else
        shouldDesaturate = false
      end
    end
    if isItem then
      if itemCount and itemCount > 1 then
        icon.stackText:SetText(itemCount)
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif itemCount and itemCount == 0 then
        icon.stackText:SetText("0")
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
        shouldDesaturate = true
      else
        icon.stackText:Hide()
      end
    else
      local charges = data.chargesData
      local safeCharges = nil
      local overlayStackText = nil
      if isChargeSpell then
        safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      elseif buffOverlayActive and addonTable.TryGetCdmAuraOverlayStackDisplay then
        safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(activeSpellID)
        if safeCharges == nil and overlayStackText == nil and activeSpellID ~= actualID then
          safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(actualID)
        end
      end
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif overlayStackText ~= nil then
        local okSet = pcall(icon.stackText.SetText, icon.stackText, overlayStackText)
        if okSet then
          icon.stackText:SetScale(stackTextScale)
          icon.stackText:Show()
        else
          icon.stackText:Hide()
        end
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    local readySpell = buffOverlayActive or (not isOnCooldown and not notEnoughResources)
    if isItem then
      readySpell = itemCount and itemCount > 0 and not isOnCooldown
    elseif isChargeSpell then
      readySpell = buffOverlayActive or isUsable
    end
    EnsureIconRestored(icon)
    if _useSpellGlows and icon.glowType ~= "off" and readySpell then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    if _cbGradT > 0 and not buffOverlayActive then
      ApplyCdTextGradient(icon.cooldown, _cbGradT, _cbGradR, _cbGradG, _cbGradB, (not isItem) and activeSpellID or nil)
      icon._cdGradApplied = true
    elseif icon._cdGradApplied then
      ResetCdTextGradient(icon.cooldown)
      icon._cdGradApplied = false
    end
    if onMyTab and not demoCdApplied and cdTextScale > 0 and not isOnCooldown and not buffOverlayActive then
      addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, inCombat)
      demoCdApplied = true
    end
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar4 then
      MasqueGroups.CustomBar4:ReSkin()
    end
    if not State.cb4Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar4AnchorFrame)
      local anchorToPoint = profile.customBar4AnchorToPoint or "CENTER"
      customBar4Frame:ClearAllPoints()
      customBar4Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
    end
    customBar4Frame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  customBar4Frame:Show()
end
local function UpdateCustomBar4Position()
  if State.cb4Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBar4X) == "number" and profile.customBar4X or 0
  local posY = type(profile.customBar4Y) == "number" and profile.customBar4Y or -300
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar4AnchorFrame)
  local anchorToPoint = profile.customBar4AnchorToPoint or "CENTER"
  customBar4Frame:ClearAllPoints()
  customBar4Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
  if customBar4Frame.highlightVisible or #State.customBar4Icons > 0 then
    customBar4Frame:Show()
  end
end
local function UpdateCustomBar4StackTextPositions()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local stackPos = type(profile.customBar4StackTextPosition) == "string" and profile.customBar4StackTextPosition or "BOTTOMRIGHT"
  local stackOffX = type(profile.customBar4StackTextOffsetX) == "number" and profile.customBar4StackTextOffsetX or 0
  local stackOffY = type(profile.customBar4StackTextOffsetY) == "number" and profile.customBar4StackTextOffsetY or 0
  for _, icon in ipairs(State.customBar4Icons) do
    if icon.stackText then
      icon.stackText:ClearAllPoints()
      icon.stackText:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
    end
  end
end
addonTable.CreateCustomBar4Icons = CreateCustomBar4Icons
addonTable.UpdateCustomBar4 = UpdateCustomBar4
addonTable.UpdateCustomBar4Position = UpdateCustomBar4Position
addonTable.UpdateCustomBar4StackTextPositions = UpdateCustomBar4StackTextPositions
local function ClearCustomBar5Icons()
  if Masque and MasqueGroups.CustomBar5 then
    for _, icon in ipairs(State.customBar5Icons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CustomBar5)
    end
  end
  for _, icon in ipairs(State.customBar5Icons) do
    HideIconByScale(icon)
    icon:SetScript("OnUpdate", nil)
  end
  wipe(State.customBar5Icons)
end
local function CreateCustomBar5Icons()
  if State.customBar5Moving then return end
  State.customBar5LayoutKey = nil
  ClearCustomBar5Icons()
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar5Enabled then
    customBar5Frame:Hide()
    return
  end
  local entries, entriesEnabled, entryGlowEnabled, entryGlowType, entryHRT = GetCustomBar5Spells()
  if #entries == 0 then
    customBar5Frame:Hide()
    return
  end
  local iconSize = type(profile.customBar5IconSize) == "number" and profile.customBar5IconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, id in ipairs(entries) do
    if entriesEnabled[i] == nil or entriesEnabled[i] ~= false then
      local icon = CreateFrame("Button", "CCMCustomBar5Icon" .. i, customBar5Frame, "BackdropTemplate")
      icon:SetSize(iconSize, iconSize)
      icon:SetFrameStrata(profile.iconStrata or "FULLSCREEN")
      icon:SetFrameLevel(10)
      icon:EnableMouse(false)
      icon.Icon = icon:CreateTexture(nil, "BACKGROUND")
      icon.Icon:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Icon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon.icon = icon.Icon
      AddIconBorder(icon, borderSize)
      icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
      icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Cooldown:SetDrawEdge(false)
      icon.Cooldown:SetDrawBling(false)
      icon.Cooldown:SetDrawSwipe(true)
      icon.Cooldown:SetReverse(false)
      icon.Cooldown:SetHideCountdownNumbers(false)
      icon.cooldown = icon.Cooldown
      icon.stackTextFrame = CreateFrame("Frame", nil, icon)
      icon.stackTextFrame:SetAllPoints()
      icon.stackTextFrame:SetFrameLevel(icon.Cooldown:GetFrameLevel() + 5)
      icon.Count = icon.stackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      icon.Count:SetPoint("BOTTOMRIGHT", icon.stackTextFrame, "BOTTOMRIGHT", -2, 2)
      icon.Count:SetTextColor(1, 1, 1, 1)
      local globalFont, globalOutline = GetGlobalFont()
      local _, fontSize = icon.Count:GetFont()
      icon.Count:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.entryIndex = i
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      icon.glowType = (entryGlowEnabled[i] == true) and (entryGlowType[i] or profile.customBar5SpellGlowDefaultType or "pixel") or "off"
      icon.hideRevealThreshold = tonumber(entryHRT[i]) or 0
      SetGlowIdentityMethods(icon)
      if icon.isItem then
        local itemIcon = C_Item.GetItemIconByID(icon.actualID)
        icon.Icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      else
        local spellInfo = C_Spell.GetSpellInfo(icon.actualID)
        icon.Icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      end
      table.insert(State.customBar5Icons, icon)
      if Masque and profile.enableMasque and MasqueGroups.CustomBar5 then
        SkinButtonWithMasque(icon, MasqueGroups.CustomBar5)
      end
    end
  end
  local centered = profile.customBar5Centered == true
  local x = type(profile.customBar5X) == "number" and profile.customBar5X or 0
  local y = type(profile.customBar5Y) == "number" and profile.customBar5Y or -300
  local anchorFrame, _ = ResolveCustomBarAnchorFrame(profile.customBar5AnchorFrame)
  local anchorToPoint = profile.customBar5AnchorToPoint or "CENTER"
  if centered then
    x = 0 + x
  end
  if not State.cb5Dragging then
    customBar5Frame:ClearAllPoints()
    customBar5Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, x, y)
  end
  customBar5Frame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar5 then
    ReSkinMasqueGroup(MasqueGroups.CustomBar5)
  end
end
local function UpdateCustomBar5()
  if State.customBar5Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar5Enabled then
    customBar5Frame:Hide()
    return
  end
  local inCombat = InCombatLockdown()
  local onMyTab = State.guiIsOpen and addonTable.activeTab and addonTable.activeTab() == 5
  if not IsShowModeActive(profile.customBar5ShowMode, true) then
    if not customBar5Frame.highlightVisible and not onMyTab then
      customBar5Frame:Hide()
      return
    end
  end
  if profile.customBar5OutOfCombat == false and not inCombat then
    if not customBar5Frame.highlightVisible then
      customBar5Frame:Hide()
      return
    end
  end
  if #State.customBar5Icons == 0 then
    if not customBar5Frame.highlightVisible and not onMyTab then
      customBar5Frame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBar5IconSize) == "number" and profile.customBar5IconSize or 30
  local spacing = type(profile.customBar5Spacing) == "number" and profile.customBar5Spacing or 2
  local growth = profile.customBar5Growth or "DOWN"
  local anchor = profile.customBar5AnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBar5CdTextScale) == "number" and profile.customBar5CdTextScale or 1.0
  local cdTextHidden = cdTextScale <= 0
  local stackTextScale = type(profile.customBar5StackTextScale) == "number" and profile.customBar5StackTextScale or 1.0
  local centered = profile.customBar5Centered == true
  local cooldownMode = profile.customBar5CooldownMode or "show"
  local _, _, _, _, entryHRT = GetCustomBar5Spells()
  local iconsPerRow = type(profile.customBar5IconsPerRow) == "number" and profile.customBar5IconsPerRow or 20
  local showGCD = profile.customBar5ShowGCD == true
  local cbTrackBuffs = profile.customBar5TrackBuffs ~= false
  local cbAllowBuffSpellInfo = cbTrackBuffs
  local pureBuffSpellIDs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {}
  local nowCB = GetTime()
  local cachedGcdInfo = nil
  if C_Spell and C_Spell.GetSpellCooldown then
    if inCombat then
      local okGcd, gi = pcall(C_Spell.GetSpellCooldown, 61304)
      if okGcd and type(gi) == "table" then cachedGcdInfo = gi end
    else
      cachedGcdInfo = C_Spell.GetSpellCooldown(61304)
    end
  end
  RefreshGlowParams()
  wipe(State.customBar5VisibleIcons)
  local visibleIcons = State.customBar5VisibleIcons
  local demoCdApplied = false
  for originalIdx, icon in ipairs(State.customBar5Icons) do
    icon.hideRevealThreshold = tonumber(entryHRT and entryHRT[icon.entryIndex or originalIdx]) or 0
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = actualID
    local iconTexture, itemCount
    local isOnCooldown = false
    local isChargeSpell = false
    local cdStart, cdDuration = 0, 0
    local chargesData = nil
    if isItem then
      iconTexture = icon.cachedItemIcon
      if not iconTexture then
        iconTexture = C_Item.GetItemIconByID(actualID)
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = C_Item.GetItemCount(actualID, false, true)
      cdStart, cdDuration = C_Item.GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
        if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
        icon.cooldown:SetHideCountdownNumbers(false)
      else
        icon.cooldown:Clear()
      end
      local itemNotInBags = not itemCount or itemCount <= 0
      if itemNotInBags or (cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5) then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID, cbAllowBuffSpellInfo) then
        iconTexture = nil
        icon.cooldown:Clear()
      else
        if icon._cachedCBActiveSpellID ~= activeSpellID then
          local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
          icon._cachedCBIconID = spellInfo and spellInfo.iconID or nil
          icon._cachedCBActiveSpellID = activeSpellID
        end
        iconTexture = icon._cachedCBIconID
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          local shouldShowSwipe = true
          if (not isChargeSpell) and ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
            shouldShowSwipe = false
          end
          if shouldShowSwipe and cdStart and cdDuration then
            if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            local shouldShowSwipe = true
            if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
              shouldShowSwipe = false
            end
            if shouldShowSwipe then
              if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
            else
              icon.cooldown:Clear()
            end
            icon.cooldown:SetHideCountdownNumbers(false)
            icon.cooldown:SetDrawEdge(false)
          else
            icon.cooldown:Clear()
          end
        end
      end
    end
    local buffOverlayActive = false
    if not isItem and cbTrackBuffs then
      local overlayApplied = false
      if cbTrackBuffs and addonTable.TryApplyLiveAuraOverlay then
        overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, activeSpellID)
        if not overlayApplied and activeSpellID ~= actualID then
          overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, actualID)
        end
      end
      buffOverlayActive = overlayApplied
    end
    if inCombat then pcall(icon.cooldown.SetReverse, icon.cooldown, buffOverlayActive) else icon.cooldown:SetReverse(buffOverlayActive) end
    if not isItem and not isChargeSpell then
      local cdStartPublic = ToPublicNumber(cdStart)
      local cdDurationPublic = ToPublicNumber(cdDuration)
      if cdStartPublic and cdDurationPublic then
        if inCombat then
          local okZero, isZero = pcall(function() return cdStartPublic == 0 end)
          if okZero and isZero then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local okGcd, isGcdMatch = pcall(function()
                  local gcdStart = ToPublicNumber(gcdInfo.startTime)
                  local gcdDuration = ToPublicNumber(gcdInfo.duration)
                  return gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration
                end)
                if okGcd and isGcdMatch then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            local okCD, isCD = pcall(function() return cdStartPublic > 0 and cdDurationPublic > 1.5 end)
            if okCD and isCD then
              isOnCooldown = true
              local ok2, endTime = pcall(function() return cdStartPublic + cdDurationPublic end)
              if ok2 and endTime then
                icon._cdExpectedEnd = endTime
                State.spellCdDurations[activeSpellID] = cdDurationPublic
                if actualID ~= activeSpellID then
                  State.spellCdDurations[actualID] = cdDurationPublic
                end
              end
            end
          end
        else
          if cdStartPublic == 0 then
            icon._cdExpectedEnd = 0
          else
            if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
              local gcdInfo = cachedGcdInfo
              if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
                local gcdStart = ToPublicNumber(gcdInfo.startTime)
                local gcdDuration = ToPublicNumber(gcdInfo.duration)
                if gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration then
                  local nowTs = nowCB or GetTime()
                  if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                    icon._cdExpectedEnd = 0
                  end
                end
              end
            end
            if cdStartPublic > 0 and cdDurationPublic > 1.5 then
              isOnCooldown = true
              icon._cdExpectedEnd = cdStartPublic + cdDurationPublic
              State.spellCdDurations[activeSpellID] = cdDurationPublic
              if actualID ~= activeSpellID then
                State.spellCdDurations[actualID] = cdDurationPublic
              end
            end
          end
        end
      end
      if not isOnCooldown then
        if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 and nowCB < icon._cdExpectedEnd then
          isOnCooldown = true
        end
      end
    end
    local isUsable, notEnoughResources, hasUsability = true, false, false
    if not isItem then
      isUsable, notEnoughResources, hasUsability = GetSpellUsabilityState(activeSpellID)
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
      if isChargeSpell then
        if hasUsability == false then
          isUsable = false
        end
        notEnoughResources = false
      end
    end
    local td = icon._tempData
    if not td then
      td = {}
      icon._tempData = td
    end
    td.iconTexture = iconTexture
    td.itemCount = itemCount
    td.isOnCooldown = isOnCooldown
    td.isChargeSpell = isChargeSpell
    td.isUsable = isUsable
    td.originalIndex = originalIdx
    td.notEnoughResources = notEnoughResources
    td.activeSpellID = activeSpellID
    td.chargesData = chargesData
    td.buffOverlayActive = buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    local isPureBuff = pureBuffSpellIDs[activeSpellID] == true or pureBuffSpellIDs[actualID] == true
    if isPureBuff then
      if not cbTrackBuffs or not buffOverlayActive then
        shouldShow = false
      end
    end
    if not onMyTab and not buffOverlayActive then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          if not icon.isItem and profile.customBar5UseCustomHideReveal and icon.hideRevealThreshold and icon.hideRevealThreshold > 0 then
            local expectedEnd = icon._cdExpectedEnd or 0
            if expectedEnd <= 0 and cdStart and cdDuration then
              expectedEnd = cdStart + cdDuration
            end
            local remaining = expectedEnd - nowCB
            if remaining <= 0 or remaining > icon.hideRevealThreshold then
              shouldShow = false
            end
          else
            shouldShow = false
          end
        elseif notEnoughResources then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      HideIconByScale(icon)
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    if not onMyTab then
      customBar5Frame:Hide()
    end
    return
  end
  local totalIcons = #State.customBar5Icons
  local direction = profile.customBar5Direction or "horizontal"
  local isHorizontal = (direction == "horizontal")
  local numRows, numCols
  if centered then
    if isHorizontal then
      numCols = math.min(visibleCount, iconsPerRow)
      numRows = math.ceil(visibleCount / iconsPerRow)
    else
      numRows = math.min(visibleCount, iconsPerRow)
      numCols = math.ceil(visibleCount / iconsPerRow)
    end
  else
    if isHorizontal then
      numCols = math.min(totalIcons, iconsPerRow)
      numRows = math.ceil(totalIcons / iconsPerRow)
    else
      numRows = math.min(totalIcons, iconsPerRow)
      numCols = math.ceil(totalIcons / iconsPerRow)
    end
  end
  local totalWidth, totalHeight
  if isHorizontal then
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  else
    totalWidth = numCols * iconSize + (numCols - 1) * spacing
    totalHeight = numRows * iconSize + (numRows - 1) * spacing
  end
  local posX = type(profile.customBar5X) == "number" and profile.customBar5X or 0
  local posY = type(profile.customBar5Y) == "number" and profile.customBar5Y or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBar5AnchorFrame)
  local layoutKey = string.format("%d|%d|%s|%s|%d|%s|%d|%d|%s|%s|%s",
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName or "")
  local layoutChanged = layoutKey ~= State.customBar5LayoutKey
  if layoutChanged then
    State.customBar5LayoutKey = layoutKey
  end
  local _useSpellGlows = profile.customBar5UseSpellGlows == true
  local _cbGradT = type(profile.customBar5CdGradientThreshold) == "number" and profile.customBar5CdGradientThreshold or 0
  local _cbGradR, _cbGradG, _cbGradB
  if _cbGradT > 0 then
    _cbGradR = type(profile.customBar5CdGradientR) == "number" and profile.customBar5CdGradientR or 1
    _cbGradG = type(profile.customBar5CdGradientG) == "number" and profile.customBar5CdGradientG or 0
    _cbGradB = type(profile.customBar5CdGradientB) == "number" and profile.customBar5CdGradientB or 0
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = data.activeSpellID or (isItem and actualID or ResolveTrackedSpellID(actualID))
    if icon._lastTexture ~= iconTexture then
      icon.icon:SetTexture(iconTexture)
      icon._lastTexture = iconTexture
    end
    local needsPosition = layoutChanged or (icon.GetNumPoints and icon:GetNumPoints() == 0)
    if needsPosition then
      icon:SetSize(iconSize, iconSize)
      if icon.Icon then
        icon.Icon:SetAllPoints(icon)
      end
      if icon.Cooldown then
        icon.Cooldown:SetAllPoints(icon)
      end
      icon:ClearAllPoints()
      local posIndex = centered and idx or data.originalIndex
      local row, col
      if isHorizontal then
        row = math.floor((posIndex - 1) / iconsPerRow)
        col = (posIndex - 1) % iconsPerRow
      else
        col = math.floor((posIndex - 1) / iconsPerRow)
        row = (posIndex - 1) % iconsPerRow
      end
      local xPos, yPos = 0, 0
      if centered then
        if isHorizontal then
          local rowIconCount = math.min(visibleCount - row * iconsPerRow, iconsPerRow)
          local rowWidth = rowIconCount * iconSize + (rowIconCount - 1) * spacing
          local startX = -rowWidth / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -startX - col * (iconSize + spacing)
          else
            xPos = startX + col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
          else
            yPos = -row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar5Frame, "CENTER", xPos, yPos)
        else
          local colIconCount = math.min(visibleCount - col * iconsPerRow, iconsPerRow)
          local colHeight = colIconCount * iconSize + (colIconCount - 1) * spacing
          local startY = -colHeight / 2 + iconSize / 2
          if anchor == "RIGHT" then
            xPos = -col * (iconSize + spacing)
          else
            xPos = col * (iconSize + spacing)
          end
          if growth == "UP" then
            yPos = -startY + row * (iconSize + spacing)
          else
            yPos = startY - row * (iconSize + spacing)
          end
          icon:SetPoint("CENTER", customBar5Frame, "CENTER", xPos, yPos)
        end
      else
        if anchor == "RIGHT" then
          xPos = -col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMRIGHT", customBar5Frame, "BOTTOMRIGHT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPRIGHT", customBar5Frame, "TOPRIGHT", xPos, yPos)
          end
        else
          xPos = col * (iconSize + spacing)
          if growth == "UP" then
            yPos = row * (iconSize + spacing)
            icon:SetPoint("BOTTOMLEFT", customBar5Frame, "BOTTOMLEFT", xPos, yPos)
          else
            yPos = -row * (iconSize + spacing)
            icon:SetPoint("TOPLEFT", customBar5Frame, "TOPLEFT", xPos, yPos)
          end
        end
      end
    end
    if icon.cooldown._ccmLastScale ~= cdTextScale then
      icon.cooldown:SetScale(cdTextHidden and 1 or cdTextScale)
      icon.cooldown:SetHideCountdownNumbers(cdTextHidden)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local fs = addonTable.GetCachedFontStrings(icon.cooldown)
      for i = 1, #fs do
        local _, sz = fs[i]:GetFont()
        if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
      end
    end
    local shouldDesaturate = false
    local isUsable = icon._tempData and icon._tempData.isUsable
    if isUsable == nil then isUsable = true end
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local buffOverlayActive = icon._tempData and icon._tempData.buffOverlayActive
    local isUnavailable = isOnCooldown or notEnoughResources
    if buffOverlayActive then
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    elseif isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        local cDesat = GetChargeSpellDesaturation(activeSpellID)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(cDesat)
        else
          icon.icon:SetDesaturated(cDesat and cDesat > 0)
        end
      else
        icon:SetAlpha(1)
        icon.icon:SetDesaturated(false)
      end
    else
      icon:SetAlpha(1)
      if cooldownMode == "desaturate" then
        shouldDesaturate = isUnavailable
      else
        shouldDesaturate = false
      end
    end
    if isItem then
      if itemCount and itemCount > 1 then
        icon.stackText:SetText(itemCount)
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif itemCount and itemCount == 0 then
        icon.stackText:SetText("0")
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
        shouldDesaturate = true
      else
        icon.stackText:Hide()
      end
    else
      local charges = data.chargesData
      local safeCharges = nil
      local overlayStackText = nil
      if isChargeSpell then
        safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      elseif buffOverlayActive and addonTable.TryGetCdmAuraOverlayStackDisplay then
        safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(activeSpellID)
        if safeCharges == nil and overlayStackText == nil and activeSpellID ~= actualID then
          safeCharges, overlayStackText = addonTable.TryGetCdmAuraOverlayStackDisplay(actualID)
        end
      end
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif overlayStackText ~= nil then
        local okSet = pcall(icon.stackText.SetText, icon.stackText, overlayStackText)
        if okSet then
          icon.stackText:SetScale(stackTextScale)
          icon.stackText:Show()
        else
          icon.stackText:Hide()
        end
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    local readySpell = buffOverlayActive or (not isOnCooldown and not notEnoughResources)
    if isItem then
      readySpell = itemCount and itemCount > 0 and not isOnCooldown
    elseif isChargeSpell then
      readySpell = buffOverlayActive or isUsable
    end
    EnsureIconRestored(icon)
    if _useSpellGlows and icon.glowType ~= "off" and readySpell then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    if _cbGradT > 0 and not buffOverlayActive then
      ApplyCdTextGradient(icon.cooldown, _cbGradT, _cbGradR, _cbGradG, _cbGradB, (not isItem) and activeSpellID or nil)
      icon._cdGradApplied = true
    elseif icon._cdGradApplied then
      ResetCdTextGradient(icon.cooldown)
      icon._cdGradApplied = false
    end
    if onMyTab and not demoCdApplied and cdTextScale > 0 and not isOnCooldown and not buffOverlayActive then
      addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, inCombat)
      demoCdApplied = true
    end
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar5 then
      MasqueGroups.CustomBar5:ReSkin()
    end
    if not State.cb5Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar5AnchorFrame)
      local anchorToPoint = profile.customBar5AnchorToPoint or "CENTER"
      customBar5Frame:ClearAllPoints()
      customBar5Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
    end
    customBar5Frame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  customBar5Frame:Show()
end
local function UpdateCustomBar5Position()
  if State.cb5Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBar5X) == "number" and profile.customBar5X or 0
  local posY = type(profile.customBar5Y) == "number" and profile.customBar5Y or -300
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar5AnchorFrame)
  local anchorToPoint = profile.customBar5AnchorToPoint or "CENTER"
  customBar5Frame:ClearAllPoints()
  customBar5Frame:SetPoint("CENTER", anchorFrame, anchorToPoint, posX, posY)
  if customBar5Frame.highlightVisible or #State.customBar5Icons > 0 then
    customBar5Frame:Show()
  end
end
local function UpdateCustomBar5StackTextPositions()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local stackPos = type(profile.customBar5StackTextPosition) == "string" and profile.customBar5StackTextPosition or "BOTTOMRIGHT"
  local stackOffX = type(profile.customBar5StackTextOffsetX) == "number" and profile.customBar5StackTextOffsetX or 0
  local stackOffY = type(profile.customBar5StackTextOffsetY) == "number" and profile.customBar5StackTextOffsetY or 0
  for _, icon in ipairs(State.customBar5Icons) do
    if icon.stackText then
      icon.stackText:ClearAllPoints()
      icon.stackText:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
    end
  end
end
addonTable.CreateCustomBar5Icons = CreateCustomBar5Icons
addonTable.UpdateCustomBar5 = UpdateCustomBar5
addonTable.UpdateCustomBar5Position = UpdateCustomBar5Position
addonTable.UpdateCustomBar5StackTextPositions = UpdateCustomBar5StackTextPositions

local cursorIconContainer = CreateFrame("Frame", "CCMCursorIconContainer", UIParent)
cursorIconContainer:SetSize(1, 1)
cursorIconContainer:EnableMouse(false)
if cursorIconContainer.SetSnapToPixelGrid then cursorIconContainer:SetSnapToPixelGrid(false) end
if cursorIconContainer.SetTexelSnappingBias then cursorIconContainer:SetTexelSnappingBias(0) end
cursorIconContainer:Show()
local function UpdateCursorIconAnchors()
  local cache = State.cursorLayoutCache
  local row, col = 0, 0
  for _, icon in ipairs(State.cursorIcons) do
    if not icon._ccmHiddenByScale then
      local xPos, yPos
      if cache.isHorizontal then
        xPos = col * (cache.iconSize + cache.iconSpacing)
        yPos = row * (cache.iconSize + cache.iconSpacing)
        col = col + 1
        if col >= cache.iconsPerRow then
          col = 0
          row = row + 1
          if cache.numColumns > 1 and row >= cache.numColumns then break end
        end
      else
        xPos = col * (cache.iconSize + cache.iconSpacing)
        yPos = row * (cache.iconSize + cache.iconSpacing)
        row = row + 1
        if row >= cache.iconsPerRow then
          row = 0
          col = col + 1
          if cache.numColumns > 1 and col >= cache.numColumns then break end
        end
      end
      icon:ClearAllPoints()
      icon:SetPoint("BOTTOMLEFT", cursorIconContainer, "BOTTOMLEFT", xPos, yPos)
    end
  end
end
addonTable.UpdateCursorIconAnchors = UpdateCursorIconAnchors
local UpdateSpellIcon
local function ClearIcons()
  if Masque and MasqueGroups.CursorIcons then
    for _, icon in ipairs(State.cursorIcons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CursorIcons)
    end
  end
  for i, icon in ipairs(State.cursorIcons) do
    HideIconByScale(icon)
    icon:SetScript("OnUpdate", nil)
    icon:SetScript("OnEvent", nil)
    icon:UnregisterAllEvents()
  end
  wipe(State.cursorIcons)
end
local function CreateIcons()
  ClearIcons()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local trackedSpells, spellsEnabled, spellGlowEnabled, spellGlowType = addonTable.GetSpellList()
  local iconSize = type(profile.iconSize) == "number" and profile.iconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, entryID in ipairs(trackedSpells) do
    if spellsEnabled[i] == nil then
      spellsEnabled[i] = true
    end
    if spellsEnabled[i] then
      local isItem = entryID < 0
      local actualID = math.abs(entryID)
      local iconStrata = profile.iconStrata or "FULLSCREEN"
      local icon = CreateFrame("Button", "CCMIcon" .. i, UIParent, "BackdropTemplate")
      icon:SetFrameStrata(iconStrata)
      icon:SetFrameLevel(200)
      icon:EnableMouse(false)
      icon:SetSize(iconSize, iconSize)
      HideIconByScale(icon)
      icon.Icon = icon:CreateTexture(nil, "BACKGROUND")
      icon.Icon:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Icon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon.icon = icon.Icon
      AddIconBorder(icon, borderSize)
      icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
      icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
      icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
      icon.Cooldown:SetDrawEdge(false)
      icon.Cooldown:SetDrawSwipe(true)
      icon.Cooldown:SetReverse(false)
      icon.Cooldown:SetHideCountdownNumbers(false)
      icon.cooldown = icon.Cooldown
      icon.stackTextFrame = CreateFrame("Frame", nil, icon)
      icon.stackTextFrame:SetAllPoints()
      icon.stackTextFrame:SetFrameLevel(icon.Cooldown:GetFrameLevel() + 5)
      icon.Count = icon.stackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      local stackPos = profile.stackTextPosition or "BOTTOMRIGHT"
      local stackOffX = profile.stackTextOffsetX or 0
      local stackOffY = profile.stackTextOffsetY or 0
      icon.Count:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
      icon.Count:SetTextColor(1, 1, 1, 1)
      local globalFont, globalOutline = GetGlobalFont()
      local _, fontSize = icon.Count:GetFont()
      icon.Count:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.spellID = actualID
      icon.isItem = isItem
      icon.spellIndex = i
      icon.glowType = (spellGlowEnabled[i] == true) and (spellGlowType[i] or profile.spellGlowDefaultType or "pixel") or "off"
      icon.actualID = actualID
      SetGlowIdentityMethods(icon)
      table.insert(State.cursorIcons, icon)
      if Masque and profile.enableMasque and MasqueGroups.CursorIcons then
        SkinButtonWithMasque(icon, MasqueGroups.CursorIcons)
      end
    end
  end
  if Masque and profile.enableMasque and MasqueGroups.CursorIcons then
    ReSkinMasqueGroup(MasqueGroups.CursorIcons)
  end
  for _, icon in ipairs(State.cursorIcons) do
    UpdateSpellIcon(icon)
  end
  UpdateCursorIconAnchors()
  if State.cursorIconPreviewActive and addonTable.ShowCursorIconPreview then
    addonTable.ShowCursorIconPreview()
  end
  C_Timer.After(0.1, function()
    for _, icon in ipairs(State.cursorIcons) do
      UpdateSpellIcon(icon)
    end
    UpdateCursorIconAnchors()
  end)
  C_Timer.After(0.5, function()
    for _, icon in ipairs(State.cursorIcons) do
      UpdateSpellIcon(icon)
    end
    UpdateCursorIconAnchors()
  end)
end
addonTable.CreateIcons = function()
  CreateIcons()
  PreCacheSpellDurations()
  if State.cursorIconPreviewActive then
    for _, icon in ipairs(State.cursorIcons) do
      icon._ccmPreviewSaved = true
      icon._ccmPreviewStrata = icon:GetFrameStrata()
      icon._ccmPreviewLevel = icon:GetFrameLevel()
      icon._ccmPreviewWasHidden = false
      icon:SetFrameStrata("TOOLTIP")
      icon:SetFrameLevel(9999)
      EnsureIconRestored(icon)
    end
    UpdateCursorIconAnchors()
  end
end
local onUpdateElapsed = 0
local cursorTrackElapsed = 0
local ON_UPDATE_THROTTLE = 0.033
local CURSOR_TRACK_THROTTLE = 0
local cachedProfile = nil
local lastProfileCheck = 0
local cachedUIScale = UIParent:GetEffectiveScale()
local lastScaleCheck = 0
State.cursorLayoutCache = {
  offsetX = 30,
  offsetY = 45,
  iconSize = 42,
  iconSpacing = 2,
  isHorizontal = true,
  iconsPerRow = 10,
  numColumns = 1,
  totalBarWidth = 0,
}
local cursorTrackingFrame = CreateFrame("Frame", "CCMCursorTrackingFrame", UIParent)
addonTable.ShouldRunCursorTracking = function(profile)
  if not profile then return false end
  if State.guiIsOpen then return true end
  local hasBars = (profile.useBuffBar or profile.useEssentialBar) and profile.disableBlizzCDM ~= true
  return profile.cursorIconsEnabled or hasBars
end
addonTable.ShouldRunMainOnUpdate = function(profile)
  if not profile then return false end
  if State.guiIsOpen then return true end
  local hasBars = (profile.useBuffBar or profile.useEssentialBar) and profile.disableBlizzCDM ~= true
  return profile.cursorIconsEnabled or hasBars or profile.showRadialCircle
end
addonTable.CursorTrackingOnUpdate = function(self, elapsed)
  cursorTrackElapsed = cursorTrackElapsed + elapsed
  if cursorTrackElapsed < CURSOR_TRACK_THROTTLE then return end
  cursorTrackElapsed = 0
  local profile = cachedProfile
  if not profile then return end
  if not addonTable.ShouldRunCursorTracking(profile) then
    self:SetScript("OnUpdate", nil)
    return
  end
  local x, y = GetCursorPosition()
  State.lastTrackCursorX, State.lastTrackCursorY = x, y
  local scale = cachedUIScale
  local cache = State.cursorLayoutCache
  if profile.useBuffBar then
    UpdateBuffBarPosition(x, y, scale, profile)
  end
  if profile.useEssentialBar then
    local buffBarWidth = State.cachedBuffBarWidth or 0
    local attachedSpacing = type(profile.iconSpacing) == "number" and profile.iconSpacing or 2
    local essentialOffset = buffBarWidth > 0 and (buffBarWidth + attachedSpacing) or 0
    UpdateEssentialBarPosition(x, y, scale, profile, essentialOffset)
  end
  local cursorEnabled = profile.cursorIconsEnabled
  if not cursorEnabled and not State.cursorIconPreviewActive then return end
  local baseX = (x / scale) + cache.offsetX + cache.totalBarWidth
  local baseY = (y / scale) + cache.offsetY
  cursorIconContainer:ClearAllPoints()
  cursorIconContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", baseX, baseY)
end
addonTable.MainOnUpdate = function(self, elapsed)
  onUpdateElapsed = onUpdateElapsed + elapsed
  if onUpdateElapsed < ON_UPDATE_THROTTLE then return end
  onUpdateElapsed = 0
  local now = GetTime()
  if not cachedProfile or (now - lastProfileCheck) > 1.0 then
    cachedProfile = GetProfile()
    lastProfileCheck = now
  end
  if (now - lastScaleCheck) > 0.5 then
    cachedUIScale = UIParent:GetEffectiveScale()
    lastScaleCheck = now
  end
  local profile = cachedProfile
  if not profile then return end
  if not addonTable.ShouldRunMainOnUpdate(profile) then
    if State.ringEnabled then
      ringFrame:Hide()
      gcdOverlay:Hide()
      State.ringEnabled = false
    end
    self:SetScript("OnUpdate", nil)
    return
  end
  local x, y = GetCursorPosition()
  local scale = cachedUIScale
  local inCombat = InCombatLockdown()
  local guiOpen = State.guiIsOpen == true
  local cursorMoved = math.abs(x - State.lastCursorX) > State.cursorMoveThreshold or math.abs(y - State.lastCursorY) > State.cursorMoveThreshold
  local iconsDirty = State.iconsDirty
  local timeSinceBarUpdate = now - State.lastBarUpdateTime
  local anyTrackBuffs = (profile.trackBuffs ~= false)
    or (profile.customBarTrackBuffs ~= false)
    or (profile.customBar2TrackBuffs ~= false)
    or (profile.customBar3TrackBuffs ~= false)
    or (profile.customBar4TrackBuffs ~= false)
    or (profile.customBar5TrackBuffs ~= false)
  local expensiveInterval = 1.0
  if (not inCombat) and (not guiOpen) then
    expensiveInterval = anyTrackBuffs and 2.5 or 4.0
  elseif anyTrackBuffs then
    expensiveInterval = 0.75
  end
  if profile.cooldownIconMode == "hide" and profile.useCustomHideReveal then
    local hrThresholds = GetActiveSpellHideRevealThresholds(profile)
    if type(hrThresholds) == "table" then
      for _, v in ipairs(hrThresholds) do
        if type(v) == "number" and v > 0 then
          if inCombat or guiOpen then
            expensiveInterval = math.min(expensiveInterval, 0.25)
          else
            expensiveInterval = math.min(expensiveInterval, 1.0)
          end
          break
        end
      end
    end
  end
  local doExpensiveUpdate = iconsDirty or timeSinceBarUpdate >= expensiveInterval
  if not cursorMoved and not doExpensiveUpdate then
    if profile.showRadialCircle then
      UpdateRadialCircle()
    end
    return
  end
  State.lastCursorX, State.lastCursorY = x, y
  local totalBarWidth = 0
  local buffBarWidth = 0
  local essentialBarWidth = 0
  local iconSize = profile.iconSize
  local iconSpacing = profile.iconSpacing
  local attachedSpacing = type(profile.iconSpacing) == "number" and profile.iconSpacing or 2
  local isHorizontal = (profile.layoutDirection == "horizontal")
  local iconsPerRow = profile.iconsPerRow or 10
  local numColumns = type(profile.numColumns) == "number" and profile.numColumns or 1
  local blizzCDMDisabled = profile.disableBlizzCDM == true
  if (not blizzCDMDisabled) and profile.useBuffBar then
    State.cachedBuffBarWidth, _ = UpdateBuffBar(x, y, scale, profile)
    buffBarWidth = State.cachedBuffBarWidth or 0
    totalBarWidth = buffBarWidth
    if buffBarWidth > 0 then
      totalBarWidth = totalBarWidth + attachedSpacing
    end
  elseif State.buffBarActive then
    RestoreBuffBarPosition()
  end
  if (not blizzCDMDisabled) and profile.useEssentialBar then
    State.cachedEssentialBarWidth, _ = UpdateEssentialBar(x, y, scale, profile, totalBarWidth)
    essentialBarWidth = State.cachedEssentialBarWidth or 0
    if essentialBarWidth > 0 then
      totalBarWidth = totalBarWidth + essentialBarWidth + attachedSpacing
    end
  elseif State.essentialBarActive then
    RestoreEssentialBarPosition()
  end
  if doExpensiveUpdate then
    State.lastBarUpdateTime = now
    State.iconsDirty = false
    if anyTrackBuffs and addonTable.ScanCdmAuraOverlayCache then
      addonTable.ScanCdmAuraOverlayCache(now)
    end
    if addonTable.UpdateAllIcons and (profile.cursorIconsEnabled or State.cursorIconPreviewActive or guiOpen) then
      addonTable.UpdateAllIcons()
    end
  end
  local cachedIconSize = State.cursorLayoutCache.iconSize or 42
  local desiredIconSize = iconSize or 42
  local sizeChanged = (cachedIconSize ~= desiredIconSize)
  State.cursorLayoutCache.offsetX = profile.offsetX or 30
  State.cursorLayoutCache.offsetY = profile.offsetY or 45
  State.cursorLayoutCache.iconSize = desiredIconSize
  State.cursorLayoutCache.iconSpacing = iconSpacing or 2
  State.cursorLayoutCache.isHorizontal = isHorizontal
  State.cursorLayoutCache.iconsPerRow = iconsPerRow
  State.cursorLayoutCache.numColumns = numColumns
  State.cursorLayoutCache.totalBarWidth = totalBarWidth
  local masqueEnabled = profile.enableMasque and Masque
  if sizeChanged then
    for _, icon in ipairs(State.cursorIcons) do
      if icon:IsShown() and icon._ccmSize ~= iconSize then
        icon:SetSize(iconSize, iconSize)
        icon._ccmSize = iconSize
        if icon.Icon then
          icon.Icon:SetAllPoints(icon)
        end
        if icon.Cooldown then
          icon.Cooldown:SetAllPoints(icon)
        end
      end
    end
  end
  if masqueEnabled and MasqueGroups.CursorIcons and doExpensiveUpdate then
    MasqueGroups.CursorIcons:ReSkin()
  end
  if doExpensiveUpdate then
    UpdateCursorIconAnchors()
  end
  if profile.showRadialCircle then
    UpdateRadialCircle()
  end
end
addonTable.EvaluateOnUpdateHandlers = function(profile)
  if not profile then
    profile = GetProfile()
  end
  cachedProfile = profile
  lastProfileCheck = GetTime()
  if addonTable.ShouldRunCursorTracking(profile) then
    if not cursorTrackingFrame:GetScript("OnUpdate") then
      cursorTrackingFrame:SetScript("OnUpdate", addonTable.CursorTrackingOnUpdate)
    end
  elseif cursorTrackingFrame:GetScript("OnUpdate") then
    cursorTrackingFrame:SetScript("OnUpdate", nil)
  end
  if addonTable.ShouldRunMainOnUpdate(profile) then
    if not CCM:GetScript("OnUpdate") then
      CCM:SetScript("OnUpdate", addonTable.MainOnUpdate)
    end
  else
    if CCM:GetScript("OnUpdate") then
      CCM:SetScript("OnUpdate", nil)
    end
    if State.ringEnabled then
      ringFrame:Hide()
      gcdOverlay:Hide()
      State.ringEnabled = false
    end
  end
end
cursorTrackingFrame:SetScript("OnUpdate", addonTable.CursorTrackingOnUpdate)
CCM:SetScript("OnUpdate", addonTable.MainOnUpdate)
UpdateSpellIcon = function(icon, profile, cachedGcdInfo, tickCtx)
  profile = profile or addonTable.GetProfile()
  if not profile then return end
  if State.cursorIconPreviewActive then
    local spellID = icon.spellID
    local isItem = icon.isItem
    if isItem then
      local itemIcon = icon.cachedItemIcon
      if not itemIcon then
        itemIcon = C_Item.GetItemIconByID(spellID)
        if not itemIcon then
          local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(spellID)
          itemIcon = infoIcon
        end
        if itemIcon then icon.cachedItemIcon = itemIcon end
      end
      icon.icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      if not itemIcon then C_Item.RequestLoadItemDataByID(spellID) end
      local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
      icon.cooldown:SetScale(cdTextScale > 0 and cdTextScale or 1)
      icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      local cdStart, cdDuration = C_Item.GetItemCooldown(spellID)
      if cdStart and cdDuration and cdDuration > 1.5 then
        icon.cooldown:SetCooldown(cdStart, cdDuration)
        icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      else
        icon.cooldown:Clear()
        addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, false)
      end
      local stackTextScale = type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0
      icon.stackText:SetScale(stackTextScale)
      local itemCount = C_Item.GetItemCount(spellID, false, true)
      if not itemCount or itemCount <= 0 then
        icon.stackText:SetText("0")
        icon.stackText:Show()
      elseif itemCount > 1 then
        icon.stackText:SetText(itemCount)
        icon.stackText:Show()
      else
        icon.stackText:Hide()
      end
    else
      local activeSpellID = ResolveTrackedSpellID(spellID)
      local info = C_Spell.GetSpellInfo(activeSpellID)
      icon.icon:SetTexture(info and info.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
      icon.cooldown:SetScale(cdTextScale > 0 and cdTextScale or 1)
      icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      local charges = C_Spell.GetSpellCharges(activeSpellID)
      local safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, spellID)
      local stackTextScale = type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0
      icon.stackText:SetScale(stackTextScale)
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:Show()
      else
        icon.stackText:Hide()
      end
      local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
      if charges and charges.cooldownStartTime and charges.cooldownDuration then
        pcall(icon.cooldown.SetCooldown, icon.cooldown, charges.cooldownStartTime, charges.cooldownDuration)
        icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      elseif cdInfo and cdInfo.startTime and cdInfo.duration and cdInfo.duration > 1.5 then
        pcall(icon.cooldown.SetCooldown, icon.cooldown, cdInfo.startTime, cdInfo.duration)
        icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      else
        icon.cooldown:Clear()
        addonTable.ApplyConfigPreviewCountdown(icon.cooldown, cdTextScale, false)
      end
    end
    EnsureIconRestored(icon)
    if profile.useSpellGlows == true and icon.glowType ~= "off" then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    return
  end
  if profile.cursorIconsEnabled == false then
    HideIconByScale(icon)
    return
  end
  local spellID = icon.spellID
  local isItem = icon.isItem
  local showGCD = tickCtx and tickCtx.showGCD or (profile.cursorShowGCD == true)
  local alwaysShowInActive = tickCtx and tickCtx.alwaysShowInActive or false
  if not tickCtx and not alwaysShowInActive and profile.alwaysShowInEnabled and profile.alwaysShowInMode then
    local inInstance, instanceType = IsInInstance()
    if profile.alwaysShowInMode == "raid" and inInstance and instanceType == "raid" then
      alwaysShowInActive = true
    elseif profile.alwaysShowInMode == "dungeon" and inInstance and instanceType == "party" then
      alwaysShowInActive = true
    elseif profile.alwaysShowInMode == "raidanddungeon" and inInstance and (instanceType == "raid" or instanceType == "party") then
      alwaysShowInActive = true
    end
  end
  local playerInCombat = tickCtx and tickCtx.playerInCombat or UnitAffectingCombat("player")
  if (profile.iconsCombatOnly or profile.showInCombatOnly) and not playerInCombat and not alwaysShowInActive then
    HideIconByScale(icon)
    return
  end
  if isItem then
    local itemIcon = icon.cachedItemIcon
    if not itemIcon then
      itemIcon = C_Item.GetItemIconByID(spellID)
      if not itemIcon then
        local _, _, _, _, _, _, _, _, _, infoIcon = C_Item.GetItemInfo(spellID)
        itemIcon = infoIcon
      end
      if itemIcon then
        icon.cachedItemIcon = itemIcon
      end
    end
    if not itemIcon then
      C_Item.RequestLoadItemDataByID(spellID)
      EnsureIconRestored(icon)
      icon.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      return
    end
    EnsureIconRestored(icon)
    icon.icon:SetTexture(itemIcon)
    icon.icon:SetVertexColor(1, 1, 1)
    icon.icon:SetDesaturated(false)
    if icon.cdText then icon.cdText:Hide() end
    local cdTextScale = tickCtx and tickCtx.cdTextScale or (type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0)
    icon.cooldown:SetScale(cdTextScale > 0 and cdTextScale or 1)
    icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local fs = addonTable.GetCachedFontStrings(icon.cooldown)
      for i = 1, #fs do
        local _, sz = fs[i]:GetFont()
        if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
      end
    end
    local cdStart, cdDuration = C_Item.GetItemCooldown(spellID)
    local shouldShowSwipe = true
    if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
      if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, nil, icon._cdExpectedEnd, cachedGcdInfo) then
        shouldShowSwipe = false
      end
    end
    if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
      icon.cooldown:SetDrawSwipe(true)
      icon.cooldown:SetCooldown(cdStart, cdDuration)
      icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
    else
      icon.cooldown:SetDrawSwipe(false)
      icon.cooldown:Clear()
    end
    local itemCount = C_Item.GetItemCount(spellID, false, true)
    local itemNotInBags = not itemCount or itemCount <= 0
    local isItemOnCooldown = itemNotInBags or (cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5)
    local cooldownMode = tickCtx and tickCtx.cooldownMode or (profile.cooldownIconMode or "show")
    if cooldownMode == "hideAvailable" then
      if not isItemOnCooldown then
        HideIconByScale(icon)
        return
      end
      icon.icon:SetDesaturated(itemNotInBags)
    elseif cooldownMode == "hide" and isItemOnCooldown then
      HideIconByScale(icon)
      return
    elseif cooldownMode == "desaturate" then
      icon.icon:SetDesaturated(isItemOnCooldown)
    else
      icon.icon:SetDesaturated(itemNotInBags)
    end
    local stackTextScale = tickCtx and tickCtx.stackTextScale or (type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0)
    if itemNotInBags then
      icon.stackText:SetText("0")
      icon.stackText:SetScale(stackTextScale)
      icon.stackText:Show()
    elseif itemCount and itemCount > 1 then
      icon.stackText:SetText(itemCount)
      icon.stackText:SetScale(stackTextScale)
      icon.stackText:Show()
    else
      icon.stackText:Hide()
    end
    local useSpellGlows = tickCtx and tickCtx.useSpellGlows or (profile.useSpellGlows == true)
    local shouldGlow = useSpellGlows and icon.glowType ~= "off" and (not isItemOnCooldown) and (not itemNotInBags)
    if shouldGlow then
      StartReadyGlow(icon, icon.glowType)
    else
      StopReadyGlow(icon)
    end
    local cdGradT = tickCtx and tickCtx.cdGradT or (type(profile.cdTextGradientThreshold) == "number" and profile.cdTextGradientThreshold or 0)
    if cdGradT > 0 then
      local gR = tickCtx and tickCtx.cdGradR or (type(profile.cdTextGradientR) == "number" and profile.cdTextGradientR or 1)
      local gG = tickCtx and tickCtx.cdGradG or (type(profile.cdTextGradientG) == "number" and profile.cdTextGradientG or 0)
      local gB = tickCtx and tickCtx.cdGradB or (type(profile.cdTextGradientB) == "number" and profile.cdTextGradientB or 0)
      ApplyCdTextGradient(icon.cooldown, cdGradT, gR, gG, gB, nil)
      icon._cdGradApplied = true
    elseif icon._cdGradApplied then
      ResetCdTextGradient(icon.cooldown)
      icon._cdGradApplied = false
    end
    return
  end
  local activeSpellID = ResolveTrackedSpellID(spellID)
  local cursorTrackBuffs = (State._ccmCursorTrackBuffs ~= nil) and State._ccmCursorTrackBuffs or (profile.trackBuffs ~= false)
  if not IsTrackedEntryAvailable(false, spellID, activeSpellID, cursorTrackBuffs) then
    HideIconByScale(icon)
    return
  end
  local iconID = icon._cachedIconID
  if icon._cachedActiveSpellID ~= activeSpellID then
    local info = C_Spell.GetSpellInfo(activeSpellID)
    if not info or not info.iconID then
      HideIconByScale(icon)
      return
    end
    iconID = info.iconID
    icon._cachedIconID = iconID
    icon._cachedActiveSpellID = activeSpellID
  end
  if not iconID then
    HideIconByScale(icon)
    return
  end
  EnsureIconRestored(icon)
  icon.icon:SetTexture(iconID)
  icon.icon:SetVertexColor(1, 1, 1)
  if icon.cdText then
    icon.cdText:Hide()
  end
  local cdTextScale = tickCtx and tickCtx.cdTextScale or (type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0)
  icon.cooldown:SetScale(cdTextScale > 0 and cdTextScale or 1)
  icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
  if not icon.cooldown._ccmFontApplied then
    icon.cooldown._ccmFontApplied = true
    local gf, go = GetGlobalFont()
    local oFlag = go or "OUTLINE"
    local fs = addonTable.GetCachedFontStrings(icon.cooldown)
    for i = 1, #fs do
      local _, sz = fs[i]:GetFont()
      if sz then pcall(fs[i].SetFont, fs[i], gf, sz, oFlag) end
    end
  end
  local charges = C_Spell.GetSpellCharges(activeSpellID)
  local isChargeSpell = IsRealChargeSpell(charges, spellID)
  local safeCharges = nil
  local stackTextScale = tickCtx and tickCtx.stackTextScale or (type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0)
  if isChargeSpell then
    safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, spellID)
  end
  local inCombat = tickCtx and tickCtx.inCombat or InCombatLockdown()
  local cdInfo
  if inCombat then
    local okCd, ci = pcall(C_Spell.GetSpellCooldown, activeSpellID)
    if okCd and type(ci) == "table" then cdInfo = ci end
  else
    cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
  end
  if safeCharges ~= nil then
    icon.stackText:SetText(tostring(safeCharges))
    icon.stackText:SetScale(stackTextScale)
    icon.stackText:Show()
    local cdStart, cdDuration
    if charges then
      cdStart, cdDuration = charges.cooldownStartTime, charges.cooldownDuration
    elseif cdInfo then
      cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
    end
    local shouldShowSwipe = true
    if (not isChargeSpell) and ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
      shouldShowSwipe = false
    end
    if shouldShowSwipe and cdStart and cdDuration then
      icon.cooldown:SetDrawSwipe(true)
      if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
      icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      icon.cooldown:SetDrawEdge(false)
    else
      icon.cooldown:SetDrawSwipe(false)
      icon.cooldown:Clear()
    end
  else
    icon.stackText:Hide()
    if cdInfo then
      local cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
      local shouldShowSwipe = true
      if ShouldSuppressGCDSwipe(showGCD, cdStart, cdDuration, activeSpellID, icon._cdExpectedEnd, cachedGcdInfo) then
        shouldShowSwipe = false
      end
      if shouldShowSwipe then
        icon.cooldown:SetDrawSwipe(true)
        if inCombat then pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration) else icon.cooldown:SetCooldown(cdStart, cdDuration) end
      else
        icon.cooldown:SetDrawSwipe(false)
        icon.cooldown:Clear()
      end
      icon.cooldown:SetHideCountdownNumbers(cdTextScale <= 0)
      icon.cooldown:SetDrawEdge(false)
    else
      icon.cooldown:Clear()
    end
  end
  local buffOverlayActive = false
  if cursorTrackBuffs then
    local overlayApplied = false
    if addonTable.TryApplyLiveAuraOverlay then
      overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, activeSpellID)
      if not overlayApplied and activeSpellID ~= spellID then
        overlayApplied = addonTable.TryApplyLiveAuraOverlay(icon.cooldown, spellID)
      end
    end
    buffOverlayActive = overlayApplied
  end
  if inCombat then pcall(icon.cooldown.SetReverse, icon.cooldown, buffOverlayActive) else icon.cooldown:SetReverse(buffOverlayActive) end
  if not isChargeSpell then
    if buffOverlayActive and addonTable.TryGetCdmAuraOverlayStackDisplay then
      local overlayCharges, overlayText = addonTable.TryGetCdmAuraOverlayStackDisplay(activeSpellID)
      if overlayCharges == nil and overlayText == nil and activeSpellID ~= spellID then
        overlayCharges, overlayText = addonTable.TryGetCdmAuraOverlayStackDisplay(spellID)
      end
      if overlayCharges ~= nil then
        safeCharges = overlayCharges
        icon.stackText:SetText(tostring(overlayCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      elseif overlayText ~= nil then
        local okSet = pcall(icon.stackText.SetText, icon.stackText, overlayText)
        if okSet then
          icon.stackText:SetScale(stackTextScale)
          icon.stackText:Show()
        else
          icon.stackText:Hide()
        end
      else
        safeCharges = nil
        icon.stackText:Hide()
      end
    else
      safeCharges = nil
      icon.stackText:Hide()
    end
  end
  local isOnCooldown = false
  if not isChargeSpell then
    local cdStartPublic = cdInfo and ToPublicNumber(cdInfo.startTime) or nil
    local cdDurationPublic = cdInfo and ToPublicNumber(cdInfo.duration) or nil
    if cdStartPublic and cdDurationPublic then
      if inCombat then
        local okZero, isZero = pcall(function() return cdStartPublic == 0 end)
        if okZero and isZero then
          icon._cdExpectedEnd = 0
        else
          if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
            local gcdInfo = cachedGcdInfo
            if gcdInfo and gcdInfo.startTime and gcdInfo.duration then
              local okGcd, isGcdMatch = pcall(function()
                local gcdStart = ToPublicNumber(gcdInfo.startTime)
                local gcdDuration = ToPublicNumber(gcdInfo.duration)
                return gcdStart and gcdDuration and cdStartPublic == gcdStart and cdDurationPublic == gcdDuration
              end)
              if okGcd and isGcdMatch then
                local nowTs = (tickCtx and tickCtx.now) or GetTime()
                if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                  icon._cdExpectedEnd = 0
                end
              end
            end
          end
          local okCD, isCD = pcall(function() return cdStartPublic > 0 and cdDurationPublic > 1.5 end)
          if okCD and isCD then
            isOnCooldown = true
            local ok2, endTime = pcall(function() return cdStartPublic + cdDurationPublic end)
            if ok2 and endTime then
              icon._cdExpectedEnd = endTime
              State.spellCdDurations[activeSpellID] = cdDurationPublic
              if spellID ~= activeSpellID then
                State.spellCdDurations[spellID] = cdDurationPublic
              end
            end
          end
        end
      else
        if cdStartPublic == 0 then
          icon._cdExpectedEnd = 0
        else
          if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 then
            local gcdInfo = cachedGcdInfo
            if gcdInfo and gcdInfo.startTime and gcdInfo.duration
               and ToPublicNumber(gcdInfo.startTime) and ToPublicNumber(gcdInfo.duration)
               and cdStartPublic == ToPublicNumber(gcdInfo.startTime) and cdDurationPublic == ToPublicNumber(gcdInfo.duration) then
              local nowTs = (tickCtx and tickCtx.now) or GetTime()
              if not (icon._cdExpectedEnd and icon._cdExpectedEnd > nowTs) then
                icon._cdExpectedEnd = 0
              end
            end
          end
          if cdStartPublic > 0 and cdDurationPublic > 1.5 then
            isOnCooldown = true
            icon._cdExpectedEnd = cdStartPublic + cdDurationPublic
            State.spellCdDurations[activeSpellID] = cdDurationPublic
            if spellID ~= activeSpellID then
              State.spellCdDurations[spellID] = cdDurationPublic
            end
          end
        end
      end
    end
    if not isOnCooldown then
      local now = tickCtx and tickCtx.now or GetTime()
      if icon._cdExpectedEnd and icon._cdExpectedEnd > 0 and now < icon._cdExpectedEnd then
        isOnCooldown = true
      end
    end
  end
  local isUsable, notEnoughResources, hasUsability = GetSpellUsabilityState(activeSpellID)
  if notEnoughResources and isOnCooldown then
    notEnoughResources = false
  end
  if isChargeSpell then
    if hasUsability == false then
      isUsable = false
    end
    notEnoughResources = false
  end
  local isUnavailable = isOnCooldown or notEnoughResources
  local pureBuffSpellIDs = State._ccmPureBuffSpellIDs or (addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {})
  local isPureBuff = pureBuffSpellIDs[activeSpellID] == true or pureBuffSpellIDs[spellID] == true
  if isPureBuff then
    if not cursorTrackBuffs or not buffOverlayActive then
      HideIconByScale(icon)
      return
    end
  end
  local cooldownMode = tickCtx and tickCtx.cooldownMode or (profile.cooldownIconMode or "show")
  if buffOverlayActive then
    icon:SetAlpha(1)
    icon.icon:SetDesaturated(false)
  elseif isChargeSpell then
    local chargeDesat
    if cooldownMode == "hideAvailable" then
      if not isUnavailable then
        HideIconByScale(icon)
        return
      end
      icon:SetAlpha(1)
      chargeDesat = GetChargeSpellDesaturation(activeSpellID)
      if icon.icon.SetDesaturation then
        icon.icon:SetDesaturation(chargeDesat)
      else
        icon.icon:SetDesaturated(chargeDesat > 0)
      end
    elseif cooldownMode == "hide" then
      if isOnCooldown then
        local hrThreshold = 0
        if profile.useCustomHideReveal and icon.spellIndex then
          local hrThresholds = GetActiveSpellHideRevealThresholds(profile)
          if type(hrThresholds) == "table" then
            hrThreshold = tonumber(hrThresholds[icon.spellIndex]) or 0
          end
        end
        if hrThreshold > 0 then
          local expectedEnd = icon._cdExpectedEnd or 0
          local remaining = expectedEnd - (tickCtx and tickCtx.now or GetTime())
          if remaining <= 0 or remaining > hrThreshold then
            HideIconByScale(icon)
            return
          end
        else
          HideIconByScale(icon)
          return
        end
      end
      icon:SetAlpha(1)
      chargeDesat = chargeDesat or GetChargeSpellDesaturation(activeSpellID)
      if icon.icon.SetDesaturation then
        icon.icon:SetDesaturation(chargeDesat)
      else
        icon.icon:SetDesaturated(chargeDesat > 0)
      end
    elseif cooldownMode == "desaturate" then
      icon:SetAlpha(1)
      chargeDesat = chargeDesat or GetChargeSpellDesaturation(activeSpellID)
      if icon.icon.SetDesaturation then
        icon.icon:SetDesaturation(chargeDesat)
      else
        icon.icon:SetDesaturated(chargeDesat > 0)
      end
    else
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    end
  else
    icon:SetAlpha(1)
    if cooldownMode == "hideAvailable" then
      if not isUnavailable then
        HideIconByScale(icon)
        return
      end
      icon.icon:SetDesaturated(false)
    elseif cooldownMode == "hide" then
      if isOnCooldown then
        local hrThreshold = 0
        if profile.useCustomHideReveal and icon.spellIndex then
          local hrThresholds = GetActiveSpellHideRevealThresholds(profile)
          if type(hrThresholds) == "table" then
            hrThreshold = tonumber(hrThresholds[icon.spellIndex]) or 0
          end
        end
        if hrThreshold > 0 then
          local expectedEnd = icon._cdExpectedEnd or 0
          local remaining = expectedEnd - (tickCtx and tickCtx.now or GetTime())
          if remaining > 0 and remaining <= hrThreshold then
            icon.icon:SetDesaturated(false)
          else
            HideIconByScale(icon)
            return
          end
        else
          HideIconByScale(icon)
          return
        end
      end
      if notEnoughResources then
        HideIconByScale(icon)
        return
      end
      icon.icon:SetDesaturated(false)
    elseif cooldownMode == "desaturate" then
      icon.icon:SetDesaturated(isUnavailable)
    else
      icon.icon:SetDesaturated(false)
    end
  end
  local useSpellGlows = tickCtx and tickCtx.useSpellGlows or (profile.useSpellGlows == true)
  local readySpell = buffOverlayActive or (not isOnCooldown and not notEnoughResources)
  if isChargeSpell then
    readySpell = buffOverlayActive or isUsable
  end
  local shouldGlow = useSpellGlows and icon.glowType ~= "off" and readySpell
  if shouldGlow then
    StartReadyGlow(icon, icon.glowType)
  else
    StopReadyGlow(icon)
  end
  local cdGradT = tickCtx and tickCtx.cdGradT or (type(profile.cdTextGradientThreshold) == "number" and profile.cdTextGradientThreshold or 0)
  if cdGradT > 0 and not buffOverlayActive then
    local gR = tickCtx and tickCtx.cdGradR or (type(profile.cdTextGradientR) == "number" and profile.cdTextGradientR or 1)
    local gG = tickCtx and tickCtx.cdGradG or (type(profile.cdTextGradientG) == "number" and profile.cdTextGradientG or 0)
    local gB = tickCtx and tickCtx.cdGradB or (type(profile.cdTextGradientB) == "number" and profile.cdTextGradientB or 0)
    ApplyCdTextGradient(icon.cooldown, cdGradT, gR, gG, gB, activeSpellID)
    icon._cdGradApplied = true
  elseif icon._cdGradApplied then
    ResetCdTextGradient(icon.cooldown)
    icon._cdGradApplied = false
  end
end
local function UpdateAllIcons()
  local profile = addonTable.GetProfile and addonTable.GetProfile() or nil
  if not profile then return end
  State._ccmCursorTrackBuffs = (profile.trackBuffs ~= false)
  State._ccmPureBuffSpellIDs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs() or {}
  local now = GetTime()
  local inCombat = InCombatLockdown()
  local cachedGcdInfo = nil
  if C_Spell and C_Spell.GetSpellCooldown then
    if inCombat then
      local okGcd, gi = pcall(C_Spell.GetSpellCooldown, 61304)
      if okGcd and type(gi) == "table" then cachedGcdInfo = gi end
    else
      cachedGcdInfo = C_Spell.GetSpellCooldown(61304)
    end
  end
  RefreshGlowParams()
  local alwaysShowInActive = false
  if profile.alwaysShowInEnabled and profile.alwaysShowInMode then
    local inInstance, instanceType = IsInInstance()
    if profile.alwaysShowInMode == "raid" and inInstance and instanceType == "raid" then
      alwaysShowInActive = true
    elseif profile.alwaysShowInMode == "dungeon" and inInstance and instanceType == "party" then
      alwaysShowInActive = true
    elseif profile.alwaysShowInMode == "raidanddungeon" and inInstance and (instanceType == "raid" or instanceType == "party") then
      alwaysShowInActive = true
    end
  end
  local playerInCombat = UnitAffectingCombat("player")
  local tickCtx = {
    now = now,
    inCombat = inCombat,
    playerInCombat = playerInCombat,
    alwaysShowInActive = alwaysShowInActive,
    showGCD = profile.cursorShowGCD == true,
    cooldownMode = profile.cooldownIconMode or "show",
    cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0,
    stackTextScale = type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0,
    useSpellGlows = profile.useSpellGlows == true,
    cdGradT = type(profile.cdTextGradientThreshold) == "number" and profile.cdTextGradientThreshold or 0,
    cdGradR = type(profile.cdTextGradientR) == "number" and profile.cdTextGradientR or 1,
    cdGradG = type(profile.cdTextGradientG) == "number" and profile.cdTextGradientG or 0,
    cdGradB = type(profile.cdTextGradientB) == "number" and profile.cdTextGradientB or 0,
  }
  local idleSparse = (not inCombat) and (not State.guiIsOpen) and (State.iconsDirty ~= true)
  for _, icon in ipairs(State.cursorIcons) do
    if idleSparse then
      local shouldUpdate = icon:IsShown()
      if not shouldUpdate and icon._cdExpectedEnd and icon._cdExpectedEnd > now then
        shouldUpdate = true
      end
      if shouldUpdate then
        icon._ccmIdleSkipCount = 0
        UpdateSpellIcon(icon, profile, cachedGcdInfo, tickCtx)
      else
        local skipCount = icon._ccmIdleSkipCount or 0
        if skipCount >= 8 then
          icon._ccmIdleSkipCount = 0
          UpdateSpellIcon(icon, profile, cachedGcdInfo, tickCtx)
        else
          icon._ccmIdleSkipCount = skipCount + 1
        end
      end
    else
      icon._ccmIdleSkipCount = 0
      UpdateSpellIcon(icon, profile, cachedGcdInfo, tickCtx)
    end
  end
  State._ccmCursorTrackBuffs = nil
  State._ccmPureBuffSpellIDs = nil
end
addonTable.UpdateAllIcons = UpdateAllIcons

local unpack = unpack or table.unpack
local function PackResults(...)
  return { n = select("#", ...), ... }
end
local CCMProfiler = {
  active = false,
  wrapped = {},
  data = {},
  duration = 10,
  startCPU = 0,
  stopTimer = nil,
}

local function CCMProfilerRecord(name, elapsedMS)
  local entry = CCMProfiler.data[name]
  if not entry then
    entry = { calls = 0, total = 0, max = 0 }
    CCMProfiler.data[name] = entry
  end
  entry.calls = entry.calls + 1
  entry.total = entry.total + elapsedMS
  if elapsedMS > entry.max then
    entry.max = elapsedMS
  end
end

local function WrapProfiledFunction(owner, key, name)
  if type(owner) ~= "table" then return end
  local original = owner[key]
  if type(original) ~= "function" then return end
  if CCMProfiler.wrapped[name] then return end
  owner[key] = function(...)
    if not CCMProfiler.active then
      return original(...)
    end
    local t0 = debugprofilestop and debugprofilestop() or 0
    local results = PackResults(original(...))
    local t1 = debugprofilestop and debugprofilestop() or t0
    CCMProfilerRecord(name, t1 - t0)
    return unpack(results, 1, results.n)
  end
  CCMProfiler.wrapped[name] = true
end

local function WrapLocalProfiledFunction(name, fn)
  if type(fn) ~= "function" then return fn end
  if CCMProfiler.wrapped[name] then return fn end
  local original = fn
  local wrapped = function(...)
    if not CCMProfiler.active then
      return original(...)
    end
    local t0 = debugprofilestop and debugprofilestop() or 0
    local results = PackResults(original(...))
    local t1 = debugprofilestop and debugprofilestop() or t0
    CCMProfilerRecord(name, t1 - t0)
    return unpack(results, 1, results.n)
  end
  CCMProfiler.wrapped[name] = true
  return wrapped
end

local function EnsureCCMProfilerWrappers()
  local targets = {
    {"UpdateAllIcons", addonTable, "UpdateAllIcons"},
    {"UpdateCustomBar", addonTable, "UpdateCustomBar"},
    {"UpdateCustomBar2", addonTable, "UpdateCustomBar2"},
    {"UpdateCustomBar3", addonTable, "UpdateCustomBar3"},
    {"UpdateCustomBar4", addonTable, "UpdateCustomBar4"},
    {"UpdateCustomBar5", addonTable, "UpdateCustomBar5"},
    {"UpdateStandaloneBlizzardBars", addonTable, "UpdateStandaloneBlizzardBars"},
    {"MainTickerTick", addonTable, "MainTickerTick"},
    {"MainOnUpdate", addonTable, "MainOnUpdate"},
    {"CursorTrackingOnUpdate", addonTable, "CursorTrackingOnUpdate"},
    {"UpdatePRB", addonTable, "UpdatePRB"},
    {"ApplyUnitFrameCustomization", addonTable, "ApplyUnitFrameCustomization"},
    {"UpdateCombatTimer", addonTable, "UpdateCombatTimer"},
    {"UpdateCRTimer", addonTable, "UpdateCRTimer"},
    {"UpdateCombatStatus", addonTable, "UpdateCombatStatus"},
    {"UpdateSkyriding", addonTable, "UpdateSkyriding"},
  }
  for i = 1, #targets do
    local t = targets[i]
    WrapProfiledFunction(t[2], t[3], t[1])
  end

  UpdateSpellIcon = WrapLocalProfiledFunction("UpdateSpellIcon(local)", UpdateSpellIcon)
  UpdateAllIcons = WrapLocalProfiledFunction("UpdateAllIcons(local)", UpdateAllIcons)
  UpdateCustomBar = WrapLocalProfiledFunction("UpdateCustomBar(local)", UpdateCustomBar)
  UpdateCustomBar2 = WrapLocalProfiledFunction("UpdateCustomBar2(local)", UpdateCustomBar2)
  UpdateCustomBar3 = WrapLocalProfiledFunction("UpdateCustomBar3(local)", UpdateCustomBar3)
  UpdateCustomBar4 = WrapLocalProfiledFunction("UpdateCustomBar4(local)", UpdateCustomBar4)
  UpdateCustomBar5 = WrapLocalProfiledFunction("UpdateCustomBar5(local)", UpdateCustomBar5)
  UpdateStandaloneBlizzardBars = WrapLocalProfiledFunction("UpdateStandaloneBlizzardBars(local)", UpdateStandaloneBlizzardBars)
  if type(UpdateGCD) == "function" then
    UpdateGCD = WrapLocalProfiledFunction("UpdateGCD(local)", UpdateGCD)
  end
end

local function PrintCCMProfilerReport(durationSec, addonCpuDelta)
  local rows = {}
  for name, entry in pairs(CCMProfiler.data) do
    rows[#rows + 1] = {
      name = name,
      calls = entry.calls,
      total = entry.total,
      avg = (entry.calls > 0 and (entry.total / entry.calls) or 0),
      max = entry.max,
    }
  end
  table.sort(rows, function(a, b) return a.total > b.total end)
  print(string.format("|cff00ff00CCM Debug:|r %.1fs complete, AddOn CPU +%.2f ms", durationSec or 0, addonCpuDelta or 0))
  if #rows == 0 then
    print("|cff00ff00CCM Debug:|r no profiled function calls recorded.")
    return
  end
  local limit = math.min(#rows, 20)
  print("|cff00ff00CCM Debug Top Functions (wall-time ms):|r")
  for i = 1, limit do
    local r = rows[i]
    print(string.format("|cff00ff00CCM Debug|r %2d. %s  total=%.2f  calls=%d  avg=%.3f  max=%.3f", i, r.name, r.total, r.calls, r.avg, r.max))
  end
end

addonTable.StopCCMDebugProfile = function()
  if not CCMProfiler.active then return end
  CCMProfiler.active = false
  local durationSec = CCMProfiler.duration or 10
  local addonCpuDelta = 0
  if UpdateAddOnCPUUsage and GetAddOnCPUUsage then
    UpdateAddOnCPUUsage()
    local nowCPU = GetAddOnCPUUsage(addonName) or 0
    addonCpuDelta = nowCPU - (CCMProfiler.startCPU or 0)
  end
  if addonCpuDelta < 0 then addonCpuDelta = 0 end
  PrintCCMProfilerReport(durationSec, addonCpuDelta)
end

addonTable.StartCCMDebugProfile = function(durationSec)
  local dur = tonumber(durationSec) or 10
  if dur < 1 then dur = 1 end
  if dur > 60 then dur = 60 end
  EnsureCCMProfilerWrappers()
  CCMProfiler.data = {}
  CCMProfiler.duration = dur
  CCMProfiler.active = true
  CCMProfiler.startCPU = 0
  if UpdateAddOnCPUUsage and GetAddOnCPUUsage then
    UpdateAddOnCPUUsage()
    CCMProfiler.startCPU = GetAddOnCPUUsage(addonName) or 0
  end
  print(string.format("|cff00ff00CCM Debug:|r recording for %.1f seconds...", dur))
  C_Timer.After(dur, function()
    if addonTable.StopCCMDebugProfile then
      addonTable.StopCCMDebugProfile()
    end
  end)
end

local UpdateGCD
addonTable.UpdateEnabledCustomBars = function(profile, force)
  if not profile then return false end
  local now = GetTime()
  local inCombat = InCombatLockdown()
  local guiOpen = State.guiIsOpen == true
  local function IsPollingCooldownMode(mode)
    return mode == "hide" or mode == "hideAvailable" or mode == "desaturate"
  end
  local function GetAdaptiveBarInterval(baseInterval, cooldownMode, trackBuffsEnabled)
    local interval = baseInterval or 0.12
    return interval
  end
  local function ShouldKeepPollingBar(cooldownMode, hasActiveTimers)
    if not IsPollingCooldownMode(cooldownMode) then
      return false
    end
    if guiOpen or inCombat then
      return true
    end
    if hasActiveTimers == nil then
      return true
    end
    return hasActiveTimers == true
  end
  local hasPending = false
  local keepPolling = false
  if profile.customBarEnabled then
    local cb1ShowActive = IsShowModeActive(profile.customBarShowMode, true)
    local cb1CombatOk = profile.customBarOutOfCombat ~= false or inCombat
    if cb1ShowActive and cb1CombatOk then
      local m = profile.customBarCooldownMode or "show"
      if ShouldKeepPollingBar(m, State.customBar1HasActiveTimers) then
        keepPolling = true
      end
      local interval = GetAdaptiveBarInterval(State.customBar1UpdateInterval or 0.08, m, profile.customBarTrackBuffs ~= false)
      if force or (now - (State.lastCustomBar1Update or 0)) >= interval then
        UpdateCustomBar()
        State.lastCustomBar1Update = now
      else
        hasPending = true
      end
    elseif cb1ShowActive then
      UpdateCustomBar()
    end
  end
  if profile.customBar2Enabled then
    local cb2ShowActive = IsShowModeActive(profile.customBar2ShowMode, true)
    local cb2CombatOk = profile.customBar2OutOfCombat ~= false or inCombat
    if cb2ShowActive and cb2CombatOk then
      local m = profile.customBar2CooldownMode or "show"
      if ShouldKeepPollingBar(m, State.customBar2HasActiveTimers) then
        keepPolling = true
      end
      local interval = GetAdaptiveBarInterval(State.customBar2UpdateInterval or 0.12, m, profile.customBar2TrackBuffs ~= false)
      if force or (now - (State.lastCustomBar2Update or 0)) >= interval then
        UpdateCustomBar2()
        State.lastCustomBar2Update = now
      else
        hasPending = true
      end
    elseif cb2ShowActive then
      UpdateCustomBar2()
    end
  end
  if profile.customBar3Enabled then
    local cb3ShowActive = IsShowModeActive(profile.customBar3ShowMode, true)
    local cb3CombatOk = profile.customBar3OutOfCombat ~= false or inCombat
    if cb3ShowActive and cb3CombatOk then
      local m = profile.customBar3CooldownMode or "show"
      if IsPollingCooldownMode(m) and (inCombat or State.guiIsOpen) then
        keepPolling = true
      end
      local interval = GetAdaptiveBarInterval(State.customBar3UpdateInterval or 0.12, m, profile.customBar3TrackBuffs ~= false)
      if force or (now - (State.lastCustomBar3Update or 0)) >= interval then
        UpdateCustomBar3()
        State.lastCustomBar3Update = now
      else
        hasPending = true
      end
    elseif cb3ShowActive then
      UpdateCustomBar3()
    end
  end
  if profile.customBar4Enabled then
    local cb4ShowActive = IsShowModeActive(profile.customBar4ShowMode, true)
    local cb4CombatOk = profile.customBar4OutOfCombat ~= false or inCombat
    if cb4ShowActive and cb4CombatOk then
      local m = profile.customBar4CooldownMode or "show"
      if IsPollingCooldownMode(m) and (inCombat or State.guiIsOpen) then
        keepPolling = true
      end
      local interval = GetAdaptiveBarInterval(State.customBar4UpdateInterval or 0.12, m, profile.customBar4TrackBuffs ~= false)
      if force or (now - (State.lastCustomBar4Update or 0)) >= interval then
        UpdateCustomBar4()
        State.lastCustomBar4Update = now
      else
        hasPending = true
      end
    elseif cb4ShowActive then
      UpdateCustomBar4()
    end
  end
  if profile.customBar5Enabled then
    local cb5ShowActive = IsShowModeActive(profile.customBar5ShowMode, true)
    local cb5CombatOk = profile.customBar5OutOfCombat ~= false or inCombat
    if cb5ShowActive and cb5CombatOk then
      local m = profile.customBar5CooldownMode or "show"
      if IsPollingCooldownMode(m) and (inCombat or State.guiIsOpen) then
        keepPolling = true
      end
      local interval = GetAdaptiveBarInterval(State.customBar5UpdateInterval or 0.12, m, profile.customBar5TrackBuffs ~= false)
      if force or (now - (State.lastCustomBar5Update or 0)) >= interval then
        UpdateCustomBar5()
        State.lastCustomBar5Update = now
      else
        hasPending = true
      end
    elseif cb5ShowActive then
      UpdateCustomBar5()
    end
  end
  if (not keepPolling) and (not inCombat) and (not guiOpen) then
    hasPending = false
  end
  State.customBarsDirty = hasPending or keepPolling
  return not (hasPending or keepPolling)
end
addonTable.RequestIconUpdate = function()
  if State.iconUpdatePending then return end
  State.iconUpdatePending = true
  C_Timer.After(0.05, function()
    State.iconUpdatePending = false
    UpdateAllIcons()
  end)
end
addonTable.RequestCustomBarUpdate = function()
  if State.customBarUpdatePending then return end
  State.customBarUpdatePending = true
  local profile = GetProfile()
  local inCombat = InCombatLockdown()
  local guiOpen = State.guiIsOpen == true
  local minInterval = nil
  local function ComputeAdaptiveBarInterval(baseInterval, cooldownMode, trackBuffsEnabled)
    local interval = baseInterval or 0.12
    return interval
  end
  local function AccumulateBarInterval(enabled, baseInterval, cooldownMode, trackBuffsEnabled)
    if not enabled then return end
    local iv = ComputeAdaptiveBarInterval(baseInterval, cooldownMode, trackBuffsEnabled)
    if not minInterval or iv < minInterval then
      minInterval = iv
    end
  end
  if profile then
    AccumulateBarInterval(profile.customBarEnabled, State.customBar1UpdateInterval or 0.08, profile.customBarCooldownMode or "show", profile.customBarTrackBuffs ~= false)
    AccumulateBarInterval(profile.customBar2Enabled, State.customBar2UpdateInterval or 0.12, profile.customBar2CooldownMode or "show", profile.customBar2TrackBuffs ~= false)
    AccumulateBarInterval(profile.customBar3Enabled, State.customBar3UpdateInterval or 0.12, profile.customBar3CooldownMode or "show", profile.customBar3TrackBuffs ~= false)
    AccumulateBarInterval(profile.customBar4Enabled, State.customBar4UpdateInterval or 0.12, profile.customBar4CooldownMode or "show", profile.customBar4TrackBuffs ~= false)
    AccumulateBarInterval(profile.customBar5Enabled, State.customBar5UpdateInterval or 0.12, profile.customBar5CooldownMode or "show", profile.customBar5TrackBuffs ~= false)
  end
  if not minInterval then
    minInterval = 0.12
  end
  C_Timer.After(minInterval, function()
    State.customBarUpdatePending = false
    addonTable.UpdateEnabledCustomBars(GetProfile(), false)
  end)
end
addonTable.RequestStandaloneBuffRelayout = function()
  if State.standaloneAuraRelayoutPending then return end
  State.standaloneAuraRelayoutPending = true
  State.standaloneFastUntil = GetTime() + 0.3
  State.lastStandaloneTick = 0
  C_Timer.After(0, function()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
  end)
  C_Timer.After(0.10, function()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
    State.standaloneAuraRelayoutPending = false
  end)
end
addonTable.MainTickerTick = function()
  State.tickerProfile = GetProfile()
  if not State.tickerProfile then return end
  local now = GetTime()
  if (State.tickerProfile.showRadialCircle and State.tickerProfile.showGCD) or State.tickerProfile.cursorShowGCD
     or State.tickerProfile.cursorIconsEnabled or State.tickerProfile.customBarEnabled
     or State.tickerProfile.customBar2Enabled or State.tickerProfile.customBar3Enabled
     or State.tickerProfile.customBar4Enabled or State.tickerProfile.customBar5Enabled then
    local shouldUpdateGcdNow = true
    if (not InCombatLockdown()) and (not State.guiIsOpen) then
      local gcdEnd = (State.gcdStartTime or 0) + (State.gcdDuration or 0)
      shouldUpdateGcdNow = gcdEnd > now
    end
    if shouldUpdateGcdNow then
      UpdateGCD()
    end
  end
  if State.customBarsDirty and not State.customBarUpdatePending then
    addonTable.UpdateEnabledCustomBars(State.tickerProfile, false)
  end
  if State.tickerProfile.standaloneSkinBuff or State.tickerProfile.standaloneSkinEssential or State.tickerProfile.standaloneSkinUtility or State.tickerProfile.standaloneBuffCentered or State.tickerProfile.standaloneEssentialCentered or State.tickerProfile.standaloneUtilityCentered then
    local centeredStandalone = (State.tickerProfile.standaloneBuffCentered == true) or (State.tickerProfile.standaloneEssentialCentered == true) or (State.tickerProfile.standaloneUtilityCentered == true)
    local fast = State.standaloneFastUntil and now < State.standaloneFastUntil
    local interval = centeredStandalone and 0.1 or (fast and 0.25 or 1.0)
    if State.standaloneNeedsSkinning or (now - (State.lastStandaloneTick or 0)) >= interval then
      UpdateStandaloneBlizzardBars()
      State.lastStandaloneTick = now
    end
  end
end
addonTable.StartMainTicker = function()
  if State.mainTicker then return end
  State.mainTicker = C_Timer.NewTicker(0.5, addonTable.MainTickerTick)
end
addonTable.StopMainTicker = function()
  if State.mainTicker then
    State.mainTicker:Cancel()
    State.mainTicker = nil
  end
end
addonTable.EvaluateMainTicker = function()
  local profile = GetProfile()
  local shouldRun = false
  if profile then
    if State.guiIsOpen then
      shouldRun = true
    elseif (profile.showRadialCircle and profile.showGCD) then
      shouldRun = true
    elseif profile.customBarEnabled or profile.customBar2Enabled or profile.customBar3Enabled or profile.customBar4Enabled or profile.customBar5Enabled then
      shouldRun = true
    elseif profile.standaloneSkinBuff or profile.standaloneSkinEssential or profile.standaloneSkinUtility or profile.standaloneBuffCentered or profile.standaloneEssentialCentered or profile.standaloneUtilityCentered then
      shouldRun = true
    end
  end
  if State.standaloneNeedsSkinning then
    shouldRun = true
  end
  if shouldRun then
    addonTable.StartMainTicker()
  else
    addonTable.StopMainTicker()
  end
  if State.standaloneCenterFrame then
    local needsCenter = profile and (profile.standaloneBuffCentered or profile.standaloneEssentialCentered or profile.standaloneUtilityCentered)
    if needsCenter then
      State.standaloneCenterFrame:Show()
    else
      State.standaloneCenterFrame:Hide()
    end
  end
  if addonTable.EvaluateOnUpdateHandlers then
    addonTable.EvaluateOnUpdateHandlers(profile)
  end
end
local function UpdateStackTextPositions()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local stackPos = type(profile.stackTextPosition) == "string" and profile.stackTextPosition or "BOTTOMRIGHT"
  local stackOffX = type(profile.stackTextOffsetX) == "number" and profile.stackTextOffsetX or 0
  local stackOffY = type(profile.stackTextOffsetY) == "number" and profile.stackTextOffsetY or 0
  for _, icon in ipairs(State.cursorIcons) do
    if icon.stackText then
      icon.stackText:ClearAllPoints()
      icon.stackText:SetPoint(stackPos, icon.stackTextFrame, stackPos, stackOffX, stackOffY)
    end
  end
end
addonTable.UpdateStackTextPositions = UpdateStackTextPositions
UpdateGCD = function()
  local profile = addonTable.GetProfile()
  if not profile then
    State.gcdStartTime = 0
    State.gcdDuration = 0
    return
  end
  if not profile.showGCD and not profile.cursorShowGCD
     and not profile.customBarShowGCD and not profile.customBar2ShowGCD and not profile.customBar3ShowGCD
     and not profile.customBar4ShowGCD and not profile.customBar5ShowGCD
     and not profile.cursorIconsEnabled and not profile.customBarEnabled
     and not profile.customBar2Enabled and not profile.customBar3Enabled
     and not profile.customBar4Enabled and not profile.customBar5Enabled then
    State.gcdStartTime = 0
    State.gcdDuration = 0
    return
  end
  local trackedSpells = addonTable.GetSpellList and select(1, addonTable.GetSpellList()) or nil
  if trackedSpells then
    for _, spellID in ipairs(trackedSpells) do
      local spellCDInfo = C_Spell.GetSpellCooldown(spellID)
      if spellCDInfo and spellCDInfo.startTime and spellCDInfo.duration then
        local start = spellCDInfo.startTime
        local duration = spellCDInfo.duration
        local success, isGCD = pcall(function()
          return type(start) == "number" and type(duration) == "number"
                 and start > 0 and duration > 0.5 and duration <= 2
        end)
        if success and isGCD then
          State.gcdStartTime = start
          State.gcdDuration = duration
          return
        end
      end
    end
  end
  local gcdSpells = {61304, 6603}
  for _, spellID in ipairs(gcdSpells) do
    local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    if cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
      local start = cooldownInfo.startTime
      local duration = cooldownInfo.duration
      local success, isGCD = pcall(function()
        return type(start) == "number" and type(duration) == "number"
               and start > 0 and duration > 0.5 and duration <= 2
      end)
      if success and isGCD then
        State.gcdStartTime = start
        State.gcdDuration = duration
        return
      end
      if start == 0 then
        State.gcdStartTime = 0
        State.gcdDuration = 0
        return
      end
      State.gcdStartTime = start
      State.gcdDuration = duration
      return
    end
  end
end
CCM:RegisterEvent("ADDON_LOADED")
CCM:RegisterEvent("PLAYER_LOGIN")
CCM:RegisterEvent("SPELL_UPDATE_COOLDOWN")
CCM:RegisterEvent("SPELL_UPDATE_CHARGES")
CCM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
CCM:RegisterEvent("PLAYER_REGEN_ENABLED")
CCM:RegisterEvent("PLAYER_REGEN_DISABLED")
CCM:RegisterEvent("UNIT_SPELLCAST_START")
CCM:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
CCM:RegisterEvent("UNIT_SPELLCAST_SENT")
CCM:RegisterEvent("UNIT_SPELLCAST_STOP")
CCM:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
CCM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
CCM:RegisterEvent("UNIT_SPELLCAST_FAILED")
CCM:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
CCM:RegisterEvent("BAG_UPDATE_COOLDOWN")
CCM:RegisterEvent("BAG_UPDATE")
CCM:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
CCM:RegisterEvent("TRAIT_CONFIG_UPDATED")
CCM:RegisterEvent("PLAYER_TARGET_CHANGED")
CCM:RegisterEvent("PLAYER_FOCUS_CHANGED")
CCM:RegisterEvent("PLAYER_ENTERING_WORLD")
CCM:RegisterEvent("MERCHANT_SHOW")
CCM:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
CCM:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
CCM:RegisterUnitEvent("UNIT_AURA", "player")
CCM:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
CCM:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
CCM:RegisterEvent("UNIT_HEAL_PREDICTION")
CCM:RegisterUnitEvent("UNIT_HEALTH", "player", "target", "focus")
CCM:RegisterUnitEvent("UNIT_MAXHEALTH", "player", "target", "focus")
local function GetCharacterSpecKey()
  local playerName = UnitName("player")
  local realmName = GetRealmName()
  local specID = GetSpecialization() or 0
  if playerName and realmName then
    return playerName .. "-" .. realmName .. "-" .. specID
  end
  return nil
end
local function ApplyCharacterProfile()
  if not CooldownCursorManagerDB then return end
  CooldownCursorManagerDB.specProfiles = CooldownCursorManagerDB.specProfiles or {}
  local specKey = GetCharacterSpecKey()
  local charKey = GetCharacterKey()
  if specKey then
    local savedProfile = CooldownCursorManagerDB.specProfiles[specKey]
    if savedProfile and CooldownCursorManagerDB.profiles[savedProfile] then
      CooldownCursorManagerDB.currentProfile = savedProfile
      return
    end
  end
  if charKey then
    local savedProfile = CooldownCursorManagerDB.characterProfiles and CooldownCursorManagerDB.characterProfiles[charKey]
    if savedProfile and CooldownCursorManagerDB.profiles[savedProfile] then
      CooldownCursorManagerDB.currentProfile = savedProfile
      return
    end
  end
  CooldownCursorManagerDB.currentProfile = "Default"
end
local function SaveCurrentProfileForSpec()
  if not CooldownCursorManagerDB then return end
  CooldownCursorManagerDB.specProfiles = CooldownCursorManagerDB.specProfiles or {}
  local specKey = GetCharacterSpecKey()
  local charKey = GetCharacterKey()
  if specKey and CooldownCursorManagerDB.currentProfile then
    CooldownCursorManagerDB.specProfiles[specKey] = CooldownCursorManagerDB.currentProfile
  end
  if charKey and CooldownCursorManagerDB.currentProfile then
    CooldownCursorManagerDB.characterProfiles = CooldownCursorManagerDB.characterProfiles or {}
    CooldownCursorManagerDB.characterProfiles[charKey] = CooldownCursorManagerDB.currentProfile
  end
end
addonTable.SaveCurrentProfileForSpec = SaveCurrentProfileForSpec
addonTable.GetCharacterSpecKey = GetCharacterSpecKey
local ChangelogPopupFrame
local CHANGELOG_V710_TEXT = table.concat({
  "|cff9ad0ff- addon has now addon modules|r",
  "|cff9ad0ff- added CCM Installer for first time users or when press installer button in profile tab|r",
  "|cff9ad0ff- removed damage reduction tracker, works now with track buffs|r",
  "|cff9ad0ff- bugfixes|r",
  "|cff9ad0ff- performance fixes|r",
  "|cff9ad0ff- fixed gui elements for different scalings|r",
  "|cff9ad0ff- optimized buff tracker for Cursor CDM and Custom Bars|r",
}, "\n")
local CHANGELOG_TEXT_BY_VERSION = {
  ["7.2.0"] = CHANGELOG_V710_TEXT,
}
local function GetCurrentAddonVersion()
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    local v = C_AddOns.GetAddOnMetadata(addonName, "Version")
    if type(v) == "string" and v ~= "" then return v end
  end
  if GetAddOnMetadata then
    local v = GetAddOnMetadata(addonName, "Version")
    if type(v) == "string" and v ~= "" then return v end
  end
  return "0.0.0"
end
local function EnsureChangelogPopup()
  if ChangelogPopupFrame then return ChangelogPopupFrame end
  local f = CreateFrame("Frame", "CCMChangelogPopup", UIParent, "BackdropTemplate")
  f:SetSize(760, 350)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(6500)
  f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  f:SetBackdropColor(0.08, 0.08, 0.10, 0.96)
  f:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  f:EnableMouse(true)
  f:Hide()
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
  title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -14)
  title:SetJustifyH("LEFT")
  title:SetTextColor(1, 0.82, 0)
  title:SetText("CCM Changelog")
  local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  body:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -12)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetSpacing(6)
  body:SetTextColor(0.95, 0.95, 0.95)
  body:SetText("")
  local closeBtn
  if addonTable.CreateStyledButton then
    closeBtn = addonTable.CreateStyledButton(f, "Close", 110, 24)
  else
    closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(110, 24)
    closeBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    closeBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    closeBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    local t = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("CENTER")
    t:SetTextColor(0.9, 0.9, 0.9)
    t:SetText("Close")
  end
  closeBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 14)
  closeBtn:SetScript("OnClick", function()
    f:Hide()
  end)
  f.Title = title
  f.Body = body
  ChangelogPopupFrame = f
  return f
end
local function ShowChangelogPopup(version, text)
  if type(text) ~= "string" or text == "" then return end
  local popup = EnsureChangelogPopup()
  popup.Title:SetText("CCM Changelog - v" .. tostring(version or ""))
  popup.Body:SetText(text)
  popup:Show()
end
local function MaybeShowUpdateChangelog()
  if not CooldownCursorManagerDB then return end
  local currentVersion = GetCurrentAddonVersion()
  local changelogText = CHANGELOG_TEXT_BY_VERSION[currentVersion]
  local lastShownVersion = CooldownCursorManagerDB.lastShownChangelogVersion
  if lastShownVersion == currentVersion then return end
  CooldownCursorManagerDB.lastShownChangelogVersion = currentVersion
  if changelogText then
    C_Timer.After(0.3, function()
      ShowChangelogPopup(currentVersion, changelogText)
    end)
  end
end
addonTable.MaybeShowUpdateChangelogOnConfigOpen = MaybeShowUpdateChangelog
CCM:SetScript("OnEvent", function(self, event, arg1, _, spellID)
  if event == "ADDON_LOADED" and arg1 == addonName then
    addonTable.WasFreshInstall = (type(CooldownCursorManagerDB) ~= "table")
    ApplyDefaults()
    CooldownCursorManagerDB = CooldownCursorManagerDB or {}


    InitCurves()
    InitMasque()
    if CCM.RegisterMedia then CCM:RegisterMedia() end
    if addonTable.ApplyModuleStateToProfile then
      addonTable.ApplyModuleStateToProfile(addonTable.GetProfile and addonTable.GetProfile() or nil)
    end
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    CreateCustomBar4Icons()
    CreateCustomBar5Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    UpdateCustomBar4()
    UpdateCustomBar5()
    UpdateStandaloneBlizzardBars()
    if addonTable.ShowMinimapButton then addonTable.ShowMinimapButton() end
    print("|cff00ff00CooldownCursorManager loaded!|r Type /ccm to configure")
    if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.SetupTooltipIDHooks then addonTable.SetupTooltipIDHooks() end
    if addonTable.SetupEnhancedTooltipHook then addonTable.SetupEnhancedTooltipHook() end
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("qol") then
      if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
      if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
    end
  elseif event == "PLAYER_LOGIN" then
    ApplyCharacterProfile()
    MigrateOldCustomBarData()
    MigrateRenamedProfileKeys()
    local profile = addonTable.GetProfile()
    if profile then
      if addonTable.ApplyModuleStateToProfile then
        addonTable.ApplyModuleStateToProfile(profile)
      end
      if profile.uiScaleMode ~= "disabled" and profile.uiScale then
        SetCVar("uiScale", profile.uiScale)
        UIParent:SetScale(profile.uiScale)
      end
      if profile.lowHealthWarningEnabled then
        SetCVar("doNotFlashLowHealthWarning", "0")
      end
      if profile.skyridingScreenFx ~= nil and C_CVar then
        C_CVar.SetCVar("DisableAdvancedFlyingFullScreenEffects", profile.skyridingScreenFx and "0" or "1")
      end
      if profile.skyridingSpeedFx ~= nil and C_CVar then
        C_CVar.SetCVar("DisableAdvancedFlyingVelocityVFX", profile.skyridingSpeedFx and "0" or "1")
      end
      if profile.disableBlizzCDM == true then
        profile.trackBuffs = false
        profile.customBarTrackBuffs = false
        profile.customBar2TrackBuffs = false
        profile.customBar3TrackBuffs = false
      end
    end
    ScanSpellBookCharges()
    ResolveBuffDurations()
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    CreateCustomBar4Icons()
    CreateCustomBar5Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    UpdateCustomBar4()
    UpdateCustomBar5()
    UpdateStandaloneBlizzardBars()
    PreCacheSpellDurations()
    C_Timer.After(1, function() ScanSpellBookCharges() PreCacheSpellDurations() State.standaloneNeedsSkinning = true UpdateStandaloneBlizzardBars() end)
    C_Timer.After(3, function() ScanSpellBookCharges() PreCacheSpellDurations() State.standaloneNeedsSkinning = true UpdateStandaloneBlizzardBars() end)
    if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("prb") and profile and profile.usePersonalResourceBar then
      if addonTable.StartPRBTicker then addonTable.StartPRBTicker() end
    end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("castbars") and profile and profile.useCastbar then
      if addonTable.SetBlizzardCastbarVisibility then
        addonTable.SetBlizzardCastbarVisibility(false)
      end
      if addonTable.SetupCastbarEvents then
        addonTable.SetupCastbarEvents()
      end
    else
      if addonTable.CastbarFrame then
        addonTable.CastbarFrame:Hide()
      end
    end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("castbars") and profile and profile.useFocusCastbar then
      if addonTable.SetupFocusCastbarEvents then
        addonTable.SetupFocusCastbarEvents()
      end
    else
      if addonTable.FocusCastbarFrame then
        addonTable.FocusCastbarFrame:Hide()
      end
    end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("castbars") and profile and profile.useTargetCastbar then
      if addonTable.SetupTargetCastbarEvents then
        addonTable.SetupTargetCastbarEvents()
      end
    else
      if addonTable.TargetCastbarFrame then
        addonTable.TargetCastbarFrame:Hide()
      end
    end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("debuffs") and profile and profile.enablePlayerDebuffs then
      if addonTable.ApplyPlayerDebuffsSkinning then
        addonTable.ApplyPlayerDebuffsSkinning()
      end
    end
    if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
    if State._ufCustomizationTimer then State._ufCustomizationTimer:Cancel() end
    State._ufCustomizationTimer = C_Timer.NewTimer(2.0, function()
      State._ufCustomizationTimer = nil
      if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    end)
    if addonTable.SetupTooltipIDHooks then addonTable.SetupTooltipIDHooks() end
    if addonTable.SetupEnhancedTooltipHook then addonTable.SetupEnhancedTooltipHook() end
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("qol") then
      if addonTable.SetCombatTimerActive then addonTable.SetCombatTimerActive(UnitAffectingCombat("player") == true) end
      if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
      if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      if addonTable.SetupChatEnhancements then addonTable.SetupChatEnhancements() end
      if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end
      if addonTable.SetupAutoQuest then addonTable.SetupAutoQuest() end
      if addonTable.SetupAutoFillDelete then addonTable.SetupAutoFillDelete() end
      if addonTable.SetupQuickRoleSignup then addonTable.SetupQuickRoleSignup() end
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    ScanSpellBookCharges()
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
    if State._ufCustomizationTimer then State._ufCustomizationTimer:Cancel() end
    State._ufCustomizationTimer = C_Timer.NewTimer(2.0, function()
      State._ufCustomizationTimer = nil
      if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    end)
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("qol") then
      if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
    end
  elseif event == "MERCHANT_SHOW" then
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("qol") then
      if addonTable.TryAutoRepair then addonTable.TryAutoRepair() end
      if addonTable.TryAutoSellJunk then addonTable.TryAutoSellJunk() end
    end
  elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("castbars") and event == "PLAYER_FOCUS_CHANGED" then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile and profile.useFocusCastbar then
        if UnitExists("focus") then
          if addonTable.SetupFocusCastbarEvents then addonTable.SetupFocusCastbarEvents() end
          local castName = UnitCastingInfo("focus")
          if not castName then castName = UnitChannelInfo("focus") end
          if castName and addonTable.StartFocusCastbarTicker then
            addonTable.StartFocusCastbarTicker()
          elseif not castName and addonTable.StopFocusCastbarTicker then
            addonTable.StopFocusCastbarTicker()
          end
        else
          if addonTable.StopFocusCastbarTicker then addonTable.StopFocusCastbarTicker() end
          if addonTable.FocusCastbarFrame then addonTable.FocusCastbarFrame:Hide() end
        end
      end
    end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("castbars") and event == "PLAYER_TARGET_CHANGED" then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile and profile.useTargetCastbar then
        if UnitExists("target") then
          if addonTable.SetupTargetCastbarEvents then addonTable.SetupTargetCastbarEvents() end
          local castName = UnitCastingInfo("target")
          if not castName then castName = UnitChannelInfo("target") end
          if castName and addonTable.StartTargetCastbarTicker then
            addonTable.StartTargetCastbarTicker()
          elseif not castName and addonTable.StopTargetCastbarTicker then
            addonTable.StopTargetCastbarTicker()
          end
        else
          if addonTable.StopTargetCastbarTicker then addonTable.StopTargetCastbarTicker() end
          if addonTable.TargetCastbarFrame then addonTable.TargetCastbarFrame:Hide() end
        end
      end
    end
    if State.ufBigHBOverlays then
      State.ufBigHBAbsorbSwapUntil = State.ufBigHBAbsorbSwapUntil or {}
      local nowTs = (GetTime and GetTime()) or 0
      if type(nowTs) ~= "number" then nowTs = 0 end
      local swapUnits = {"target", "focus"}
      for i = 1, #swapUnits do
        local unit = swapUnits[i]
        local ov = State.ufBigHBOverlays[unit]
        State.ufBigHBAbsorbSwapUntil[unit] = nowTs + 0.10
        if ov then
          if ov.dmgAbsorbFrame and ov.dmgAbsorbFrame.Hide then ov.dmgAbsorbFrame:Hide() end
          if ov.fullDmgAbsorbFrame and ov.fullDmgAbsorbFrame.Hide then ov.fullDmgAbsorbFrame:Hide() end
          if ov.dmgAbsorbGlow and ov.dmgAbsorbGlow.Hide then ov.dmgAbsorbGlow:Hide() end
        end
      end
    end
    if C_Timer and C_Timer.After and State.ufBigHBOverlays and addonTable.UpdateUFBigHBHealPrediction then
      C_Timer.After(0.02, function()
        local units = {"target", "focus"}
        for i = 1, #units do
          local unit = units[i]
          local ov = State.ufBigHBOverlays and State.ufBigHBOverlays[unit]
          if ov then
            if ov.origHP and addonTable.SyncUFBigHBOverlayValue then
              addonTable.SyncUFBigHBOverlayValue(ov, ov.origHP)
            end
            addonTable.UpdateUFBigHBHealPrediction(ov, unit)
          end
        end
        if C_Timer and C_Timer.After and State.ufBigHBOverlays and addonTable.UpdateUFBigHBDmgAbsorb then
          C_Timer.After(0.10, function()
            local swapUnits = {"target", "focus"}
            for i = 1, #swapUnits do
              local unit = swapUnits[i]
              local ov = State.ufBigHBOverlays and State.ufBigHBOverlays[unit]
              if ov then
                if ov.origHP and addonTable.SyncUFBigHBOverlayValue then
                  addonTable.SyncUFBigHBOverlayValue(ov, ov.origHP)
                end
                addonTable.UpdateUFBigHBDmgAbsorb(ov, unit)
              end
              if State.ufBigHBAbsorbSwapUntil then
                State.ufBigHBAbsorbSwapUntil[unit] = nil
              end
            end
          end)
        end
      end)
    end
  elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    if (arg1 == "player" or arg1 == "target" or arg1 == "focus") and State.ufBigHBOverlays then
      local ov = State.ufBigHBOverlays[arg1]
      local skipAbsorbUpdate = false
      if (arg1 == "target" or arg1 == "focus") and State.ufBigHBAbsorbSwapUntil and GetTime then
        local blockUntil = State.ufBigHBAbsorbSwapUntil[arg1]
        local nowTs = GetTime()
        if type(blockUntil) == "number" and type(nowTs) == "number" and nowTs < blockUntil then
          skipAbsorbUpdate = true
        else
          State.ufBigHBAbsorbSwapUntil[arg1] = nil
        end
      end
      if ov and ov.origHP and addonTable.SyncUFBigHBOverlayValue then
        addonTable.SyncUFBigHBOverlayValue(ov, ov.origHP)
      end
      if ov and ov.myHealPredFrame and addonTable.UpdateUFBigHBHealPrediction then
        addonTable.UpdateUFBigHBHealPrediction(ov, arg1)
      end
      if skipAbsorbUpdate and ov then
        if ov.dmgAbsorbFrame and ov.dmgAbsorbFrame.Hide then ov.dmgAbsorbFrame:Hide() end
        if ov.fullDmgAbsorbFrame and ov.fullDmgAbsorbFrame.Hide then ov.fullDmgAbsorbFrame:Hide() end
        if ov.dmgAbsorbGlow and ov.dmgAbsorbGlow.Hide then ov.dmgAbsorbGlow:Hide() end
      end
      if (not skipAbsorbUpdate) and ov and ov.dmgAbsorbFrame and addonTable.UpdateUFBigHBDmgAbsorb then
        addonTable.UpdateUFBigHBDmgAbsorb(ov, arg1)
      end
    end
    if addonTable.IsModuleEnabled and addonTable.IsModuleEnabled("prb") and arg1 == "player" and addonTable.UpdatePRB then
      addonTable.UpdatePRB()
    end
  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" or event == "BAG_UPDATE_COOLDOWN" or event == "BAG_UPDATE" then
    UpdateGCD()
    local nowTs = GetTime()
    local inCombat = InCombatLockdown()
    local minDirtyInterval = 0
    if (not inCombat) and (not State.guiIsOpen) then
      minDirtyInterval = 1.25
    end
    if State.guiIsOpen then
      minDirtyInterval = 0
    end
    local lastDirty = State.lastIconDirtyMarkTime or 0
    if (nowTs - lastDirty) >= minDirtyInterval then
      State.iconsDirty = true
      State.lastIconDirtyMarkTime = nowTs
    end
    local minBarDirtyInterval = inCombat and 0 or 1.20
    if State.guiIsOpen then
      minBarDirtyInterval = 0
    end
    local lastBarDirty = State.lastCustomBarDirtyMarkTime or 0
    if (nowTs - lastBarDirty) >= minBarDirtyInterval then
      State.customBarsDirty = true
      State.lastCustomBarDirtyMarkTime = nowTs
      addonTable.RequestCustomBarUpdate()
    end
    State.lastIconUpdate = nowTs
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
    C_Timer.After(0.01, UpdateGCD)
    State.iconsDirty = true
    State.customBarsDirty = true
    if spellID then
      local now = GetTime()
      State.spellCastTimes[spellID] = now
      if addonTable.RememberSpellCastTimestamp then
        addonTable.RememberSpellCastTimestamp(spellID, now)
      end
      if BuffDurationCache[spellID] then
        ActiveBuffStart[spellID] = now
      end
      local isCharge = ChargeSpellCache[spellID]
      if not isCharge then
        local resolved = ResolveTrackedSpellID(spellID)
        if resolved then isCharge = ChargeSpellCache[resolved] end
      end
      if not isCharge then
        local ch = C_Spell.GetSpellCharges(spellID)
        if ch and ch.maxCharges then
          local okMc, isMc = pcall(function() return ch.maxCharges > 1 end)
          if okMc and isMc then isCharge = true end
        end
      end
      local endTime
      if not isCharge then
        local baseDur = State.spellBaseCdDurations[spellID]
        if not baseDur then
          local resolved = ResolveTrackedSpellID(spellID)
          if resolved and resolved ~= spellID then
            baseDur = State.spellBaseCdDurations[resolved]
          end
        end
        if not baseDur then
          local cdRaw = C_Spell.GetSpellCooldown(spellID)
          if cdRaw and cdRaw.duration then
            local okBig, isBig = pcall(function() return cdRaw.duration > 1.5 end)
            if okBig and isBig then
              local okVal, val = pcall(function() return cdRaw.duration * (1 + (GetHaste() or 0) / 100) end)
              if okVal and type(val) == "number" then
                baseDur = val
                State.spellBaseCdDurations[spellID] = baseDur
              end
            end
          end
        end
        if not baseDur then
          local okBase, baseCd = pcall(GetSpellBaseCooldown, spellID)
          if okBase and baseCd and type(baseCd) == "number" and baseCd > 1500 then
            baseDur = baseCd / 1000
            State.spellBaseCdDurations[spellID] = baseDur
          end
        end
        if baseDur and baseDur > 1.5 then
          local haste = GetHaste and GetHaste() or 0
          local dur = baseDur / (1 + haste / 100)
          if dur > 1.5 then
            endTime = now + dur
          end
        end
      end
      if endTime then
        for _, icon in ipairs(State.cursorIcons) do
          if not icon.isItem then
            local sid = icon.spellID
            if sid == spellID or ResolveTrackedSpellID(sid) == spellID then
              icon._cdExpectedEnd = endTime
            end
          end
        end
        for _, icon in ipairs(State.customBar1Icons) do
          if not icon.isItem then
            local aid = icon.actualID
            if aid == spellID or ResolveTrackedSpellID(aid) == spellID then
              icon._cdExpectedEnd = endTime
            end
          end
        end
        for _, icon in ipairs(State.customBar2Icons) do
          if not icon.isItem then
            local aid = icon.actualID
            if aid == spellID or ResolveTrackedSpellID(aid) == spellID then
              icon._cdExpectedEnd = endTime
            end
          end
        end
        for _, icon in ipairs(State.customBar3Icons) do
          if not icon.isItem then
            local aid = icon.actualID
            if aid == spellID or ResolveTrackedSpellID(aid) == spellID then
              icon._cdExpectedEnd = endTime
            end
          end
        end
        for _, icon in ipairs(State.customBar4Icons) do
          if not icon.isItem then
            local aid = icon.actualID
            if aid == spellID or ResolveTrackedSpellID(aid) == spellID then
              icon._cdExpectedEnd = endTime
            end
          end
        end
        for _, icon in ipairs(State.customBar5Icons) do
          if not icon.isItem then
            local aid = icon.actualID
            if aid == spellID or ResolveTrackedSpellID(aid) == spellID then
              icon._cdExpectedEnd = endTime
            end
          end
        end
      end
    end
    addonTable.RequestCustomBarUpdate()
  elseif event == "UNIT_SPELLCAST_START" and arg1 == "player" then
    C_Timer.After(0.01, UpdateGCD)
  elseif event == "UNIT_SPELLCAST_START" and arg1 == "focus" then
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if profile and profile.useFocusCastbar and addonTable.StartFocusCastbarTicker then
      addonTable.StartFocusCastbarTicker()
    end
  elseif event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
    C_Timer.After(0.01, UpdateGCD)
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" and arg1 == "player" then
    C_Timer.After(0.01, UpdateGCD)
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" and arg1 == "focus" then
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if profile and profile.useFocusCastbar and addonTable.StartFocusCastbarTicker then
      addonTable.StartFocusCastbarTicker()
    end
  elseif (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or
          event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" or
          event == "UNIT_SPELLCAST_FAILED_QUIET") and arg1 == "player" then
  elseif (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or
          event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" or
          event == "UNIT_SPELLCAST_FAILED_QUIET") and arg1 == "focus" then
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if profile and profile.useFocusCastbar and addonTable.StopFocusCastbarTicker then
      C_Timer.After(0.05, addonTable.StopFocusCastbarTicker)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    State.iconsDirty = true
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
    C_Timer.After(0.05, function()
      State.standaloneNeedsSkinning = true
      UpdateStandaloneBlizzardBars()
    end)
    C_Timer.After(0.20, function()
      State.standaloneNeedsSkinning = true
      UpdateStandaloneBlizzardBars()
    end)
    if addonTable.SetCombatTimerActive then addonTable.SetCombatTimerActive(false) end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
    if addonTable.ShowCombatStatusMessage then addonTable.ShowCombatStatusMessage(false) end
    if State.unitFrameCustomizationPending and addonTable.ApplyUnitFrameCustomization then
      addonTable.ApplyUnitFrameCustomization()
    end
    if State.openAfterCombat then
      State.openAfterCombat = false
      if addonTable.ConfigFrame and not addonTable.ConfigFrame:IsShown() then
        if addonTable.SetGUIOpen then addonTable.SetGUIOpen(true) end
        if addonTable.MaybeShowUpdateChangelogOnConfigOpen then addonTable.MaybeShowUpdateChangelogOnConfigOpen() end
        if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
        addonTable.ConfigFrame:Show()
      end
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    PreCacheSpellDurations()
    State.iconsDirty = true
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
    C_Timer.After(0.05, function()
      State.standaloneNeedsSkinning = true
      UpdateStandaloneBlizzardBars()
    end)
    C_Timer.After(0.20, function()
      State.standaloneNeedsSkinning = true
      UpdateStandaloneBlizzardBars()
    end)
    if addonTable.SetCombatTimerActive then addonTable.SetCombatTimerActive(true) end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
    if addonTable.ShowCombatStatusMessage then addonTable.ShowCombatStatusMessage(true) end
    if addonTable.ConfigFrame and addonTable.ConfigFrame:IsShown() then
      State.openAfterCombat = true
      addonTable.ConfigFrame:Hide()
      if addonTable.SetGUIOpen then addonTable.SetGUIOpen(false) end
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
    addonTable.InvalidateResolveCache()
    wipe(ChargeSpellCache)
    wipe(State.spellCdDurations)
    wipe(State.spellBaseCdDurations)
    ScanSpellBookCharges()
    ResolveBuffDurations()
    ApplyCharacterProfile()
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    CreateCustomBar4Icons()
    CreateCustomBar5Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    UpdateCustomBar4()
    UpdateCustomBar5()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
    if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if addonTable.ConfigFrame and addonTable.ConfigFrame:IsShown() then
      if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
    end
    if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if State._ufCustomizationTimer then State._ufCustomizationTimer:Cancel() end
    State._ufCustomizationTimer = C_Timer.NewTimer(1.5, function()
      State._ufCustomizationTimer = nil
      if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    end)
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
  elseif event == "TRAIT_CONFIG_UPDATED" then
    addonTable.InvalidateResolveCache()
    wipe(ChargeSpellCache)
    wipe(State.spellCdDurations)
    wipe(State.spellBaseCdDurations)
    ScanSpellBookCharges()
    ResolveBuffDurations()
    PreCacheSpellDurations()
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    CreateCustomBar4Icons()
    CreateCustomBar5Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    UpdateCustomBar4()
    UpdateCustomBar5()
    if addonTable.RefreshCursorSpellList then addonTable.RefreshCursorSpellList() end
    if addonTable.RefreshCB1SpellList then addonTable.RefreshCB1SpellList() end
    if addonTable.RefreshCB2SpellList then addonTable.RefreshCB2SpellList() end
    if addonTable.RefreshCB3SpellList then addonTable.RefreshCB3SpellList() end
    if addonTable.RefreshCB4SpellList then addonTable.RefreshCB4SpellList() end
    if addonTable.RefreshCB5SpellList then addonTable.RefreshCB5SpellList() end
  elseif event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
    if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if State._ufCustomizationTimer then State._ufCustomizationTimer:Cancel() end
    State._ufCustomizationTimer = C_Timer.NewTimer(1.0, function()
      State._ufCustomizationTimer = nil
      if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    end)
  elseif event == "UPDATE_SHAPESHIFT_FORM" then
    if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if State._ufCustomizationTimer then State._ufCustomizationTimer:Cancel() end
    State._ufCustomizationTimer = C_Timer.NewTimer(1.5, function()
      State._ufCustomizationTimer = nil
      if addonTable.InvalidateUFBigHBPlayerOverlay then addonTable.InvalidateUFBigHBPlayerOverlay() end
      if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    end)
  elseif event == "UNIT_AURA" and arg1 == "player" then
    local profile = GetProfile()
    if profile and (not profile.useBuffBar) and (profile.standaloneBuffCentered == true or profile.standaloneSkinBuff == true) then
      if addonTable.RequestStandaloneBuffRelayout then
        addonTable.RequestStandaloneBuffRelayout()
      end
    end
    local newStacks = 0
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
      local okAura, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, 1227702)
      if okAura and aura then
        local okApps, apps = pcall(tonumber, aura.applications)
        if okApps and type(apps) == "number" and apps > 0 then
          newStacks = apps
        elseif aura.points then
          for i = 1, #aura.points do
            local okPoint, pointNum = pcall(tonumber, aura.points[i])
            if okPoint and type(pointNum) == "number" and pointNum > 0 then
              newStacks = pointNum
              break
            end
          end
        end
      end
    end
    if State.collapsingStarStacks ~= newStacks then
      State.collapsingStarStacks = newStacks
      State.iconsDirty = true
      addonTable.RequestCustomBarUpdate()
      if addonTable.RefreshCRTimerText then addonTable.RefreshCRTimerText() end
    end
  end
end)
if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end

