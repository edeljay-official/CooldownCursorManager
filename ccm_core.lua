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
  customBarVisibleIcons = {},
  customBar2VisibleIcons = {},
  customBar3VisibleIcons = {},
  gcdStartTime = 0,
  gcdDuration = 0,
  prbDragging = false,
  prbTicker = nil,
  actionBar1Hidden = false,
  actionBars2to8Hidden = false,
  stanceBarHidden = false,
  petBarHidden = false,
  actionBar1Mouseover = false,
  actionBars2to8Mouseover = false,
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
  focusCastbarActive = false,
  focusCastbarTicker = nil,
  focusCastbarDragging = false,
  focusCastbarPreviewMode = false,
  focusCastbarLayoutKey = nil,
  focusCastbarTickKey = nil,
  collapsingStarStacks = nil,
  combatStatusMessageToken = 0,
  combatStatusPreviewMode = false,
  combatStatusLastEntering = true,
}
addonTable.State = State
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
local CLASS_POWER_CONFIG = {
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
local function GetClassPowerConfig()
  local _, playerClass = UnitClass("player")
  if not playerClass then return nil end
  local classConfig = CLASS_POWER_CONFIG[playerClass]
  if not classConfig then return nil end
  if classConfig.default then
    local config = classConfig.default
    if config.requireForm then
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
            local okPoint, point = pcall(function() return aura.points and aura.points[1] end)
            local pointNum = okPoint and tonumber(point) or nil
            local okPointValid, pointValid = pcall(function() return type(pointNum) == "number" and pointNum > 0 end)
            if okPointValid and pointValid then
              return pointNum
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
        local okPoints, point1 = pcall(function()
          return aura.points and aura.points[1]
        end)
        local pointValue = okPoints and tonumber(point1) or nil
        if type(pointValue) == "number" and pointValue > 0 then
          return pointValue
        end
      end
    end
  end

  if charges and not IsRealChargeSpell(charges, spellID) then
    return nil
  end
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
      iconStrata = "TOOLTIP",
      showRadialCircle = true,
      showGCD = true,
      radialRadius = 20,
      radialThickness = 2,
      radialColorR = 1.0,
      radialColorG = 1.0,
      radialColorB = 1.0,
      radialAlpha = 0.8,
      globalFont = "Fonts\\FRIZQT__.TTF",
      globalOutline = "OUTLINE",
      enableMasque = false,
      showMinimapButton = false,
      iconSize = 45,
      iconSpacing = 0,
      stackTextScale = 1.0,
      cdTextScale = 1.0,
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
      showBeforeCdEnds = 0,
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
      customBarGrowth = "UP",
      customBarStackTextPosition = "BOTTOMRIGHT",
      customBarStackTextOffsetX = 0,
      customBarStackTextOffsetY = 0,
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
      customBar2Growth = "UP",
      customBar2StackTextPosition = "BOTTOMRIGHT",
      customBar2StackTextOffsetX = 0,
      customBar2StackTextOffsetY = 0,
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
      customBar3Growth = "UP",
      customBar3StackTextPosition = "BOTTOMRIGHT",
      customBar3StackTextOffsetX = 0,
      customBar3StackTextOffsetY = 0,
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
      hideActionBars2to8InCombat = false,
      hideActionBars2to8Mouseover = false,
      hideStanceBarInCombat = false,
      hideStanceBarMouseover = false,
      hidePetBarInCombat = false,
      hidePetBarMouseover = false,
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
      ufCustomizeHealth = false,
      ufClassColor = false,
      ufHealthTexture = "solid",
      ufCustomBorderColorR = 0,
      ufCustomBorderColorG = 0,
      ufCustomBorderColorB = 0,
      ufDisableGlows = false,
      ufDisableCombatText = false,
      disableTargetFocusBuffs = false,
      hideEliteTexture = false,
      cdFont = "default",
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
      prbHealthColorG = 0.8,
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
  minimap = {
    hide = true,
    minimapPos = 220,
  }
}
local Masque = LibStub and LibStub("Masque", true)
local MasqueGroups = {}
addonTable.MasqueGroups = MasqueGroups
local function InitMasque()
  if not Masque then return end
  MasqueGroups.CursorIcons = Masque:Group("Cooldown Cursor Manager", "Cursor Icons")
  MasqueGroups.CustomBar = Masque:Group("Cooldown Cursor Manager", "Custom Bar")
  MasqueGroups.BuffBar = Masque:Group("Cooldown Cursor Manager", "Attached Buff Bar")
  MasqueGroups.EssentialBar = Masque:Group("Cooldown Cursor Manager", "Attached Essential Bar")
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
    local overButton = MouseIsOver and MouseIsOver(minimapButton)
    local overPanel = MouseIsOver and MouseIsOver(compactMinimapPanel)
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
        addonTable.ConfigFrame:Show()
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
    if not GetItemInfoInstant then return false end
    local itemID = GetItemInfoInstant(itemIDOrLink)
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
      if not spellBookSpellID and C_SpellBook and C_SpellBook.GetSpellBookItemSpellID then
        local okSB, sbSpellID = pcall(C_SpellBook.GetSpellBookItemSpellID, tt.ccmSpellBookSlot, tt.ccmSpellBookType)
        if okSB then
          spellBookSpellID = SafeToNumber(sbSpellID)
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
  end
  addonTable.tooltipIDHooksInstalled = true
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
local function IsRealNumber(value)
  if value == nil then return false end
  local ok = pcall(function()
    local _ = (value > -999999999)
  end)
  return ok
end
local function IsShowModeActive(mode)
  if not mode or mode == "always" then return true end
  local inInstance, instanceType = IsInInstance()
  if mode == "raid" then return inInstance and instanceType == "raid" end
  if mode == "dungeon" then return inInstance and instanceType == "party" end
  if mode == "raidanddungeon" then return inInstance and (instanceType == "raid" or instanceType == "party") end
  return true
end
local function IsOnlyGCD(startTime, duration)
  if not IsRealNumber(startTime) or not IsRealNumber(duration) then return false end
  if startTime == 0 or duration == 0 then return false end
  if State.gcdStartTime > 0 and State.gcdDuration > 0 then
    if math.abs(startTime - State.gcdStartTime) < 0.1 and math.abs(duration - State.gcdDuration) < 0.1 then
      return true
    end
  end
  if duration <= 1.5 then
    return true
  end
  return false
end
local customBarFrame = CreateFrame("Frame", "CCMCustomBar", UIParent, "BackdropTemplate")
customBarFrame:SetSize(200, 50)
customBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
customBarFrame:SetFrameStrata("TOOLTIP")
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
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.customBarX = newX
    profile.customBarY = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(1, newX, newY) end
  end
  State.cb1Dragging = false
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
customBar2Frame:SetFrameStrata("TOOLTIP")
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
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.customBar2X = newX
    profile.customBar2Y = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(2, newX, newY) end
  end
  State.cb2Dragging = false
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
customBar3Frame:SetFrameStrata("TOOLTIP")
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
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.customBar3X = newX
    profile.customBar3Y = newY
    if addonTable.UpdateCustomBarSliders then addonTable.UpdateCustomBarSliders(3, newX, newY) end
  end
  State.cb3Dragging = false
end)
customBar3Frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.cb3Dragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(5) end
    end
  end
end)
local prbFrame = CreateFrame("Frame", "CCMPersonalResourceBar", UIParent, "BackdropTemplate")
prbFrame:SetSize(220, 40)
prbFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
prbFrame:SetFrameStrata("MEDIUM")
prbFrame:SetClampedToScreen(true)
prbFrame:SetMovable(false)
prbFrame:EnableMouse(true)
prbFrame:RegisterForDrag("LeftButton")
prbFrame:Hide()
addonTable.PRBFrame = prbFrame
prbFrame.textOverlay = CreateFrame("Frame", nil, prbFrame)
prbFrame.textOverlay:SetAllPoints()
prbFrame.textOverlay:SetFrameLevel(100)
prbFrame.healthBar = CreateFrame("StatusBar", nil, prbFrame)
prbFrame.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.healthBar:SetStatusBarColor(0, 1, 0)
prbFrame.healthBar.bg = prbFrame.healthBar:CreateTexture(nil, "BACKGROUND")
prbFrame.healthBar.bg:SetAllPoints()
prbFrame.healthBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
prbFrame.healthBar.border = CreateFrame("Frame", nil, prbFrame.healthBar, "BackdropTemplate")
prbFrame.healthBar.border:SetPoint("TOPLEFT", prbFrame.healthBar, "TOPLEFT", 0, 0)
prbFrame.healthBar.border:SetPoint("BOTTOMRIGHT", prbFrame.healthBar, "BOTTOMRIGHT", 0, 0)
prbFrame.healthBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
prbFrame.healthBar.border:SetBackdropBorderColor(0, 0, 0, 1)
prbFrame.healthBar.text = prbFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
prbFrame.healthBar.text:SetPoint("CENTER")
prbFrame.healthBar.text:SetTextColor(1, 1, 1)
prbFrame.powerBar = CreateFrame("StatusBar", nil, prbFrame)
prbFrame.powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.powerBar:SetStatusBarColor(0, 0.5, 1)
prbFrame.powerBar.bg = prbFrame.powerBar:CreateTexture(nil, "BACKGROUND")
prbFrame.powerBar.bg:SetAllPoints()
prbFrame.powerBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
prbFrame.powerBar.border = CreateFrame("Frame", nil, prbFrame.powerBar, "BackdropTemplate")
prbFrame.powerBar.border:SetPoint("TOPLEFT", prbFrame.powerBar, "TOPLEFT", 0, 0)
prbFrame.powerBar.border:SetPoint("BOTTOMRIGHT", prbFrame.powerBar, "BOTTOMRIGHT", 0, 0)
prbFrame.powerBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
prbFrame.powerBar.border:SetBackdropBorderColor(0, 0, 0, 1)
prbFrame.powerBar.text = prbFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
prbFrame.powerBar.text:SetPoint("CENTER")
prbFrame.powerBar.text:SetTextColor(1, 1, 1)
prbFrame.manaBar = CreateFrame("StatusBar", nil, prbFrame)
prbFrame.manaBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.manaBar:SetStatusBarColor(0, 0.5, 1)
prbFrame.manaBar.bg = prbFrame.manaBar:CreateTexture(nil, "BACKGROUND")
prbFrame.manaBar.bg:SetAllPoints()
prbFrame.manaBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
prbFrame.manaBar.border = CreateFrame("Frame", nil, prbFrame.manaBar, "BackdropTemplate")
prbFrame.manaBar.border:SetPoint("TOPLEFT", prbFrame.manaBar, "TOPLEFT", 0, 0)
prbFrame.manaBar.border:SetPoint("BOTTOMRIGHT", prbFrame.manaBar, "BOTTOMRIGHT", 0, 0)
prbFrame.manaBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
prbFrame.manaBar.border:SetBackdropBorderColor(0, 0, 0, 1)
prbFrame.manaBar.text = prbFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
prbFrame.manaBar.text:SetPoint("CENTER")
prbFrame.manaBar.text:SetTextColor(1, 1, 1)
prbFrame.manaBar:Hide()
prbFrame.classPowerBar = CreateFrame("StatusBar", nil, prbFrame)
prbFrame.classPowerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.classPowerBar:SetStatusBarColor(1, 0.82, 0)
prbFrame.classPowerBar.bg = prbFrame.classPowerBar:CreateTexture(nil, "BACKGROUND")
prbFrame.classPowerBar.bg:SetAllPoints()
prbFrame.classPowerBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
prbFrame.classPowerBar.border = CreateFrame("Frame", nil, prbFrame.classPowerBar, "BackdropTemplate")
prbFrame.classPowerBar.border:SetPoint("TOPLEFT", prbFrame.classPowerBar, "TOPLEFT", 0, 0)
prbFrame.classPowerBar.border:SetPoint("BOTTOMRIGHT", prbFrame.classPowerBar, "BOTTOMRIGHT", 0, 0)
prbFrame.classPowerBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
prbFrame.classPowerBar.border:SetBackdropBorderColor(0, 0, 0, 1)
prbFrame.classPowerBar.text = prbFrame.classPowerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
prbFrame.classPowerBar.text:SetPoint("CENTER")
prbFrame.classPowerBar.text:SetTextColor(1, 1, 1)
prbFrame.classPowerBar:Hide()
prbFrame.classPowerSegments = {}
for i = 1, 10 do
  local seg = CreateFrame("Frame", nil, prbFrame)
  seg.bg = seg:CreateTexture(nil, "BACKGROUND")
  seg.bg:SetAllPoints()
  seg.bg:SetColorTexture(1, 0.82, 0, 1)
  seg.border = CreateFrame("Frame", nil, seg, "BackdropTemplate")
  seg.border:SetPoint("TOPLEFT", seg, "TOPLEFT", 0, 0)
  seg.border:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", 0, 0)
  seg.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  seg.border:SetBackdropBorderColor(0, 0, 0, 1)
  seg:Hide()
  prbFrame.classPowerSegments[i] = seg
end
prbFrame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 7 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(7) end
  end
  State.prbDragging = true
  self:StartMoving()
end)
prbFrame:SetScript("OnDragStop", function(self)
  if not State.prbDragging then return end
  self:StopMovingOrSizing()
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.prbX = newX
    profile.prbY = newY
    if addonTable.UpdatePRBSliders then addonTable.UpdatePRBSliders(newX, newY) end
  end
  State.prbDragging = false
end)
prbFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.prbDragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(7) end
    end
  end
end)
local function GetClassColor()
  local _, class = UnitClass("player")
  local colors = RAID_CLASS_COLORS[class]
  if colors then return colors.r, colors.g, colors.b end
  return 0, 1, 0
end
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
    if profile.globalOutline then
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
local function SetBlizzardPlayerPowerBarsVisibility(showPower, showClassPower)
  local classPowerFrames = {
    ClassPowerBar,
    ComboPointPowerBar,
    PaladinPowerBar,
    PaladinPowerBarFrame,
    WarlockPowerBar,
    WarlockPowerFrame,
    MonkHarmonyBar,
    MonkHarmonyBarFrame,
    MageArcaneChargesFrame,
    RuneFrame,
    TotemFrame,
    EssencePlayerFrame,
  }
  for _, frame in ipairs(classPowerFrames) do
    if frame and frame.SetAlpha then
      if showClassPower then
        frame:SetAlpha(0)
        if frame.UnregisterAllEvents then
          pcall(function() frame:UnregisterAllEvents() end)
        end
      else
        frame:SetAlpha(1)
      end
    end
  end
  if PlayerFrameBottomManagedFramesContainer and PlayerFrameBottomManagedFramesContainer.SetAlpha then
    if showClassPower then
      PlayerFrameBottomManagedFramesContainer:SetAlpha(0)
    else
      PlayerFrameBottomManagedFramesContainer:SetAlpha(1)
    end
  end
  if ClassNameplateBar and ClassNameplateBar.SetAlpha then
    if showClassPower then
      ClassNameplateBar:SetAlpha(0)
      if ClassNameplateBar.UnregisterAllEvents then
        pcall(function() ClassNameplateBar:UnregisterAllEvents() end)
      end
    else
      ClassNameplateBar:SetAlpha(1)
    end
  end
end
addonTable.SetBlizzardPlayerPowerBarsVisibility = SetBlizzardPlayerPowerBarsVisibility
addonTable.ApplyUnitFrameCustomization = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local ufEnabled = profile.enableUnitFrameCustomization ~= false
  local function GetPlayerObjects()
    local pf = PlayerFrame
    local main = pf and pf.PlayerFrameContent and pf.PlayerFrameContent.PlayerFrameContentMain
    local hContainer = main and main.HealthBarsContainer
    local mArea = main and main.ManaBarArea
    local hp = PlayerFrameHealthBar or (hContainer and hContainer.HealthBar)
    local mp = PlayerFrameManaBar or (mArea and mArea.ManaBar)
    return {
      healthBar = hp,
      powerBar = mp,
      manaArea = mArea,
      healthMask = hContainer and hContainer.HealthBarMask,
    }
  end
  local function ResolveUnitHealthColorSafe(unitToken, useClassColor)
    local r, g, b
    if useClassColor and unitToken and UnitExists(unitToken) and UnitIsPlayer(unitToken) then
      local _, classToken = UnitClass(unitToken)
      local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
      if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
      end
    end
    if not r then
      if unitToken == "player" then
        r, g, b = 0, 1, 0
      elseif unitToken and UnitExists(unitToken) then
        if UnitIsFriend("player", unitToken) then
          r, g, b = 0, 1, 0
        elseif UnitCanAttack("player", unitToken) then
          r, g, b = 1, 0, 0
        else
          r, g, b = 1, 1, 0
        end
      end
    end
    if not r then
      r, g, b = 0, 1, 0
    end
    return r, g, b
  end
  local function ApplyHealthColorSafe(bar, unitToken, useClassColor)
    if not bar then return end
    local r, g, b = ResolveUnitHealthColorSafe(unitToken, useClassColor)
    bar:SetStatusBarColor(r, g, b)
    if bar.AnimatedLossBar and bar.AnimatedLossBar.SetStatusBarColor then
      bar.AnimatedLossBar:SetStatusBarColor(r, g, b)
    end
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if tex then
      tex:SetAlpha(1)
      tex:SetVertexColor(r, g, b, 1)
    end
  end
  local function ApplyUnitFrameClassColorsOnly()
    local prof = addonTable.GetProfile and addonTable.GetProfile()
    if not prof or not prof.ufClassColor then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local objs = GetPlayerObjects()
    if objs and objs.healthBar then
      ApplyHealthColorSafe(objs.healthBar, "player", true)
    end
    local tMain = TargetFrame and TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
    local targetBar = tMain and tMain.HealthBarsContainer and tMain.HealthBarsContainer.HealthBar
    if targetBar then
      ApplyHealthColorSafe(targetBar, "target", true)
    end
    local fMain = FocusFrame and FocusFrame.TargetFrameContent and FocusFrame.TargetFrameContent.TargetFrameContentMain
    local focusBar = fMain and fMain.HealthBarsContainer and fMain.HealthBarsContainer.HealthBar
    if focusBar then
      ApplyHealthColorSafe(focusBar, "focus", true)
    end
  end
  addonTable.ApplyUnitFrameClassColorsOnly = ApplyUnitFrameClassColorsOnly
  if InCombatLockdown and InCombatLockdown() then
    State.unitFrameCustomizationPending = true
    return
  end
  State.unitFrameCustomizationPending = false
  local player = GetPlayerObjects()
  local healthBar = player.healthBar
  local powerBar = player.powerBar
  local manaArea = player.manaArea
  local healthMask = player.healthMask
  if not healthBar or not powerBar then return end
  addonTable.ApplyUnitFrameStatusTexts = nil
  local function ApplyBorderTextureColor(frameObj, r, g, b)
    if not frameObj then return end
    local texSeen = {}
    local function applyTex(tex)
      if not tex or not tex.SetVertexColor then return end
      if texSeen[tex] then return end
      texSeen[tex] = true
      tex:SetVertexColor(r or 1, g or 1, b or 1, 1)
    end

    local playerContainer = frameObj.PlayerFrameContainer
    local targetContainer = frameObj.TargetFrameContainer

    applyTex(playerContainer and playerContainer.FrameTexture)
    applyTex(playerContainer and playerContainer.AlternatePowerFrameTexture)
    applyTex(targetContainer and targetContainer.FrameTexture)
    applyTex(targetContainer and targetContainer.BossPortraitFrameTexture)
    applyTex(frameObj.FrameTexture)
    applyTex(frameObj.BossPortraitFrameTexture)
  end
  local useCustomBorder = ufEnabled and profile.useCustomBorderColor
  local borderR = useCustomBorder and (profile.ufCustomBorderColorR or 0) or 1
  local borderG = useCustomBorder and (profile.ufCustomBorderColorG or 0) or 1
  local borderB = useCustomBorder and (profile.ufCustomBorderColorB or 0) or 1
  ApplyBorderTextureColor(PlayerFrame, borderR, borderG, borderB)
  ApplyBorderTextureColor(TargetFrame, borderR, borderG, borderB)
  ApplyBorderTextureColor(FocusFrame, borderR, borderG, borderB)
  ApplyBorderTextureColor(_G.TargetFrameToT, borderR, borderG, borderB)
  ApplyBorderTextureColor(_G.TargetFrameToTFrame, borderR, borderG, borderB)
  ApplyBorderTextureColor(_G.PetFrame, borderR, borderG, borderB)
  local petFrameTex = _G["PetFrameTexture"]
  if petFrameTex and petFrameTex.SetVertexColor then
    petFrameTex:SetVertexColor(borderR, borderG, borderB, 1)
  end
  for i = 1, 5 do
    ApplyBorderTextureColor(_G["Boss" .. i .. "TargetFrame"], borderR, borderG, borderB)
  end
  State.playerFrameOriginal = State.playerFrameOriginal or {}
  local orig = State.playerFrameOriginal
  local function CapturePoints(frame)
    local points = {}
    local numPoints = frame:GetNumPoints() or 0
    for i = 1, numPoints do
      local p, rel, rp, x, y = frame:GetPoint(i)
      if type(p) == "string" then
        points[#points + 1] = {p, rel, rp, x, y}
      end
    end
    return points
  end
  local function RestorePoints(frame, points)
    frame:ClearAllPoints()
    if not points or #points == 0 then return end
    for i = 1, #points do
      local pt = points[i]
      if pt and type(pt[1]) == "string" then
        pcall(frame.SetPoint, frame, pt[1], pt[2], pt[3], pt[4], pt[5])
      end
    end
  end
  local texturePaths = {
    solid = "Interface\\Buttons\\WHITE8x8",
    flat = "Interface\\Buttons\\WHITE8x8",
    blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
    blizzraid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    normtex = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\normTex",
    gloss = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Gloss",
    melli = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Melli",
    mellidark = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\MelliDark",
    betterblizzard = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\BetterBlizzard",
    skyline = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Skyline",
    dragonflight = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Dragonflight",
  }
  local selectedTexture = profile.ufHealthTexture or "solid"
  local selectedTexturePath = texturePaths[selectedTexture] or texturePaths.solid
  local function ResolveUnitHealthColor(unitToken, useClassColor)
    local r, g, b
    if useClassColor and unitToken and UnitExists(unitToken) and UnitIsPlayer(unitToken) then
      local _, classToken = UnitClass(unitToken)
      local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
      if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
      end
    end
    if not r then
      if unitToken == "player" then
        r, g, b = 0, 1, 0
      elseif unitToken and UnitExists(unitToken) then
        if UnitIsFriend("player", unitToken) then
          r, g, b = 0, 1, 0
        elseif UnitCanAttack("player", unitToken) then
          r, g, b = 1, 0, 0
        else
          r, g, b = 1, 1, 0
        end
      end
    end
    if not r then
      r, g, b = 0, 1, 0
    end
    return r, g, b
  end
  local function ApplyUnitHealthColor(bar, unitToken, useClassColor)
    if not bar then return end
    local r, g, b = ResolveUnitHealthColor(unitToken, useClassColor)
    bar:SetStatusBarColor(r, g, b)
    if bar.AnimatedLossBar and bar.AnimatedLossBar.SetStatusBarColor then
      bar.AnimatedLossBar:SetStatusBarColor(r, g, b)
    end
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if tex then
      tex:SetAlpha(1)
      tex:SetVertexColor(r, g, b, 1)
    end
  end
  local function GetStatusBarUnitToken(statusBar, fallbackUnit)
    if type(fallbackUnit) == "string" and fallbackUnit ~= "" then
      return fallbackUnit
    end
    if statusBar and type(statusBar.unit) == "string" and statusBar.unit ~= "" then
      return statusBar.unit
    end
    local uf = statusBar and statusBar.unitFrame
    if uf and type(uf.unit) == "string" and uf.unit ~= "" then
      return uf.unit
    end
    return nil
  end
  local function ApplyBiggerHealthForUnit(frame, enabled, stateKey, unitToken)
    if not frame then return end
    local main = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
    local hContainer = main and main.HealthBarsContainer
    local hp = hContainer and hContainer.HealthBar
    local mp = main and main.ManaBar
    local hMask = hContainer and hContainer.HealthBarMask
    if not hp or not mp then return end
    State[stateKey] = State[stateKey] or {}
    local o = State[stateKey]
    if not o.saved then
      o.saved = true
      o.healthPoints = CapturePoints(hp)
      o.powerPoints = CapturePoints(mp)
      o.healthHeight = hp:GetHeight()
      o.powerHeight = mp:GetHeight()
      o.powerAlpha = mp:GetAlpha()
      o.powerShown = mp:IsShown()
      o.powerFrameLevel = mp:GetFrameLevel()
      if hMask then
        o.maskPoints = CapturePoints(hMask)
        o.maskShown = hMask:IsShown()
      end
      local bonusHeight = o.powerHeight or 0
      o.expandedHealthHeight = (o.healthHeight or 0) + bonusHeight + 1
      if o.expandedHealthHeight < (o.healthHeight or 0) + 4 then
        o.expandedHealthHeight = (o.healthHeight or 0) + 4
      end
    end
    pcall(hp.SetStatusBarTexture, hp, selectedTexturePath)
    local st = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
    if st then
      st:ClearAllPoints()
      st:SetAllPoints(hp)
    end
    ApplyUnitHealthColor(hp, unitToken, profile.ufClassColor == true)
    if enabled then
      o.wasEnabled = true
      RestorePoints(hp, o.healthPoints)
      if o.expandedHealthHeight and o.expandedHealthHeight > 0 then
        hp:SetHeight(o.expandedHealthHeight)
      end
      local statusTex = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
      if statusTex then
        statusTex:ClearAllPoints()
        statusTex:SetAllPoints(hp)
        if statusTex.SetTexCoord then
          statusTex:SetTexCoord(0, 1, 0, 1)
        end
      end
      if hMask then
        hMask:Hide()
      end
      mp:SetAlpha(0)
      mp:Hide()
      mp:SetFrameLevel((hp:GetFrameLevel() or 1) + 2)
    else
      RestorePoints(hp, o.healthPoints)
      if o.healthHeight and o.healthHeight > 0 then
        hp:SetHeight(o.healthHeight)
      end
      if hMask then
        RestorePoints(hMask, o.maskPoints)
        if o.maskShown then hMask:Show() else hMask:Hide() end
      end
      if o.wasEnabled then
        o.wasEnabled = nil
        RestorePoints(mp, o.powerPoints)
        if o.powerHeight and o.powerHeight > 0 then
          mp:SetHeight(o.powerHeight)
        end
        mp:SetAlpha(1)
        mp:Show()
        if o.powerFrameLevel then
          mp:SetFrameLevel(o.powerFrameLevel)
        end
      end
    end
  end
  if not orig.saved then
    orig.saved = true
    orig.healthPoints = CapturePoints(healthBar)
    orig.powerPoints = CapturePoints(powerBar)
    if manaArea then
      orig.manaAreaPoints = CapturePoints(manaArea)
      orig.manaAreaAlpha = manaArea:GetAlpha()
      orig.manaAreaShown = manaArea:IsShown()
      orig.manaAreaHeight = manaArea:GetHeight()
    end
    orig.healthHeight = healthBar:GetHeight()
    orig.healthColorR, orig.healthColorG, orig.healthColorB = healthBar:GetStatusBarColor()
    if healthBar.Background and healthBar.Background.GetAlpha then
      orig.healthBgAlpha = healthBar.Background:GetAlpha()
    end
    local savedStatusTex = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
    if savedStatusTex and savedStatusTex.GetTexture then
      orig.healthTexturePath = savedStatusTex:GetTexture()
      orig.healthStatusTexPoints = CapturePoints(savedStatusTex)
    end
    orig.powerHeight = powerBar:GetHeight()
    orig.powerAlpha = powerBar:GetAlpha()
    orig.powerShown = powerBar:IsShown()
    orig.powerFrameLevel = powerBar:GetFrameLevel()
    if manaArea then
      orig.manaAreaFrameLevel = manaArea:GetFrameLevel()
    end
    if healthMask then
      orig.maskPoints = CapturePoints(healthMask)
      orig.maskShown = healthMask:IsShown()
    end
    if PlayerFrameManaBarText then
      orig.powerTextShown = PlayerFrameManaBarText:IsShown()
    end
    local bonusHeight = (orig.manaAreaHeight and orig.manaAreaHeight > 0) and orig.manaAreaHeight or (orig.powerHeight or 0)
    orig.expandedHealthHeight = (orig.healthHeight or 0) + bonusHeight + 1
    if orig.expandedHealthHeight < (orig.healthHeight or 0) + 4 then
      orig.expandedHealthHeight = (orig.healthHeight or 0) + 4
    end
  end
  local function ApplyPlayerHealthColor()
    if not healthBar then return end
    local defaultTexture = texturePaths.blizzard
    local useClassColor = ufEnabled and profile.ufClassColor == true
    if ufEnabled and profile.ufCustomizeHealth then
      pcall(healthBar.SetStatusBarTexture, healthBar, selectedTexturePath)
      local statusTex = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
      if useClassColor then
        ApplyUnitHealthColor(healthBar, "player", true)
        if healthBar.Background then
          healthBar.Background:SetAlpha(0)
        end
      else
        ApplyUnitHealthColor(healthBar, "player", false)
        if healthBar.Background then
          healthBar.Background:SetAlpha(orig.healthBgAlpha or 1)
        end
      end
    else
      pcall(healthBar.SetStatusBarTexture, healthBar, selectedTexturePath or defaultTexture)
      local statusTex = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
      if statusTex then
        statusTex:ClearAllPoints()
        statusTex:SetAllPoints(healthBar)
        statusTex:SetAlpha(1)
        statusTex:SetVertexColor(1, 1, 1, 1)
      end
      if useClassColor then
        ApplyUnitHealthColor(healthBar, "player", true)
      else
        ApplyUnitHealthColor(healthBar, "player", false)
      end
      if healthBar.Background then
        healthBar.Background:SetAlpha(orig.healthBgAlpha or 1)
      end
    end
  end
  if not orig.unitHealthColorHooked and type(hooksecurefunc) == "function" and type(UnitFrameHealthBar_Update) == "function" then
    orig.unitHealthColorHooked = true
    hooksecurefunc("UnitFrameHealthBar_Update", function(statusBar, unitToken)
      local p = addonTable.GetProfile and addonTable.GetProfile()
      if not p or not statusBar then return end
      if p.enableUnitFrameCustomization == false then return end
      local tMain = TargetFrame and TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
      local fMain = FocusFrame and FocusFrame.TargetFrameContent and FocusFrame.TargetFrameContent.TargetFrameContentMain
      local targetBar = tMain and tMain.HealthBarsContainer and tMain.HealthBarsContainer.HealthBar
      local focusBar = fMain and fMain.HealthBarsContainer and fMain.HealthBarsContainer.HealthBar
      local useClassColor = p.ufClassColor == true
      if not useClassColor and not p.ufCustomizeHealth then return end
      if healthBar then ApplyUnitHealthColor(healthBar, "player", useClassColor) end
      if targetBar then ApplyUnitHealthColor(targetBar, "target", useClassColor) end
      if focusBar then ApplyUnitHealthColor(focusBar, "focus", useClassColor) end
      local barUnit = GetStatusBarUnitToken(statusBar, unitToken)
      if not barUnit then
        if targetBar and statusBar == targetBar then
          barUnit = "target"
        elseif focusBar and statusBar == focusBar then
          barUnit = "focus"
        end
      end
      if barUnit == "player" or statusBar == healthBar then
        ApplyUnitHealthColor(statusBar, "player", useClassColor)
      elseif barUnit == "target" or barUnit == "focus" then
        ApplyUnitHealthColor(statusBar, barUnit, useClassColor)
      end
    end)
  end
  if not orig.powerHooked and powerBar.HookScript then
    orig.powerHooked = true
    powerBar:HookScript("OnShow", function(bar)
      local p = addonTable.GetProfile and addonTable.GetProfile()
      if p and p.ufCustomizeHealth then
        bar:SetAlpha(0)
      end
    end)
  end
  if manaArea and (not orig.manaAreaHooked) and manaArea.HookScript then
    orig.manaAreaHooked = true
    manaArea:HookScript("OnShow", function(frame)
      local p = addonTable.GetProfile and addonTable.GetProfile()
      if p and p.ufCustomizeHealth then
        frame:SetAlpha(0)
      end
    end)
  end
  
  local function CollectPlayerGlowTargets()
    local targets = {}
    local seen = {}
    local function add(obj)
      if obj and not seen[obj] then
        seen[obj] = true
        targets[#targets + 1] = obj
      end
    end
    local function addRestedRegions(frame)
      if not frame or not frame.GetRegions then return end
      for _, region in ipairs({frame:GetRegions()}) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.GetTexture then
          local tex = region:GetTexture()
          if type(tex) == "string" then
            local lower = string.lower(tex)
            if string.find(lower, "rest") or string.find(lower, "zzz") or string.find(lower, "sleep") then
              add(region)
            end
          elseif region.GetAtlas then
            local atlas = region:GetAtlas()
            if type(atlas) == "string" then
              local lowerAtlas = string.lower(atlas)
              if string.find(lowerAtlas, "rest") or string.find(lowerAtlas, "sleep") then
                add(region)
              end
            end
          end
        end
      end
    end
    local pf = PlayerFrame
    local pContainer = pf and pf.PlayerFrameContainer
    local content = pf and pf.PlayerFrameContent
    local main = content and content.PlayerFrameContentMain
    local contextual = content and content.PlayerFrameContentContextual
    add(main and main.StatusTexture)
    add(pContainer and pContainer.FrameFlash)
    add(main and main.Flash)
    add(main and main.AttentionIndicator)
    add(main and main.RestingIcon)
    add(contextual and contextual.RestingIcon)
    add(pf and pf.StatusTexture)
    add(pf and pf.RestingIcon)
    add(contextual and contextual.StatusTexture)
    add(main and main.HitIndicator)
    add(main and main.HitIndicator and main.HitIndicator.HitText)
    add(contextual and contextual.PlayerRestLoop)
    add(contextual and contextual.PlayerRestLoop and contextual.PlayerRestLoop.RestTexture)
    add(contextual and contextual.PlayerPortraitCornerIcon)
    addRestedRegions(main)
    addRestedRegions(contextual)
    addRestedRegions(pf)
    add(contextual and contextual.RoleIcon)
    local function addUnitFrameGlows(unitFrame)
      if not unitFrame then return end
      local tContent = unitFrame.TargetFrameContent
      local tMain = tContent and tContent.TargetFrameContentMain
      local tContextual = tContent and tContent.TargetFrameContentContextual
      local tContainer = unitFrame.TargetFrameContainer
      add(tMain and tMain.StatusTexture)
      add(tMain and tMain.Flash)
      add(tMain and tMain.AttentionIndicator)
      add(tContextual and tContextual.StatusTexture)
      add(tContainer and tContainer.Flash)
      add(tContainer and tContainer.FrameFlash)
      addRestedRegions(tMain)
      addRestedRegions(tContextual)
      addRestedRegions(unitFrame)
      add(tContextual and tContextual.RoleIcon)
    end
    addUnitFrameGlows(TargetFrame)
    addUnitFrameGlows(FocusFrame)
    return targets
  end
  local function IsGlowSuppressionEnabled()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p then return false end
    return p.ufDisableGlows == true
  end
  local function ApplyGlowSuppression(enabled)
    orig.glowTargets = orig.glowTargets or CollectPlayerGlowTargets()
    orig.glowStates = orig.glowStates or {}
    for _, obj in ipairs(orig.glowTargets) do
      if not orig.glowStates[obj] then
        orig.glowStates[obj] = {
          alpha = obj.GetAlpha and obj:GetAlpha() or nil,
          shown = obj.IsShown and obj:IsShown() or nil,
        }
      end
      if enabled then
        if obj.HookScript then
          orig.glowHideHooked = orig.glowHideHooked or {}
          if not orig.glowHideHooked[obj] then
            obj:HookScript("OnShow", function(self)
              if IsGlowSuppressionEnabled() then
                if self.SetAlpha then self:SetAlpha(0) end
                if self.Hide then self:Hide() end
              end
            end)
            orig.glowHideHooked[obj] = true
          end
        end
        if obj.Hide then obj:Hide() end
        if obj.SetAlpha then obj:SetAlpha(0) end
      else
        local st = orig.glowStates[obj]
        if st then
          if obj.SetAlpha and st.alpha ~= nil then obj:SetAlpha(st.alpha) end
          if obj.Show and st.shown == true then obj:Show() elseif obj.Hide and st.shown == false then obj:Hide() end
        end
      end
    end
    local frameFlash = PlayerFrame and PlayerFrame.PlayerFrameContainer and PlayerFrame.PlayerFrameContainer.FrameFlash
    if frameFlash and not orig.frameFlashHideHooked then
      frameFlash:HookScript("OnShow", function(self)
        if IsGlowSuppressionEnabled() then
          if self.SetAlpha then self:SetAlpha(0) end
          if self.Hide then self:Hide() end
        end
      end)
      orig.frameFlashHideHooked = true
    end
  end

  local function ApplyCombatTextSuppression(enabled)
    orig.combatTextCvars = orig.combatTextCvars or {}
    local cvars = {
      "floatingCombatTextCombatDamage",
      "floatingCombatTextCombatHealing",
    }
    for _, key in ipairs(cvars) do
      if orig.combatTextCvars[key] == nil then
        orig.combatTextCvars[key] = GetCVar and GetCVar(key)
      end
      if enabled then
        if SetCVar then SetCVar(key, "0") end
      else
        local prev = orig.combatTextCvars[key]
        if prev ~= nil and SetCVar then SetCVar(key, prev) end
      end
    end
    local hitIndicator = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator
    local hitText = hitIndicator and hitIndicator.HitText
    orig.combatTextFrames = orig.combatTextFrames or {}
    if hitIndicator and orig.combatTextFrames.hitIndicatorShown == nil and hitIndicator.IsShown then
      orig.combatTextFrames.hitIndicatorShown = hitIndicator:IsShown()
    end
    if hitText and orig.combatTextFrames.hitTextShown == nil and hitText.IsShown then
      orig.combatTextFrames.hitTextShown = hitText:IsShown()
    end
    if enabled then
      if hitText and hitText.Hide then hitText:Hide() end
      if hitIndicator and hitIndicator.Hide then hitIndicator:Hide() end
    else
      if hitText then
        if orig.combatTextFrames.hitTextShown then hitText:Show() elseif hitText.Hide then hitText:Hide() end
      end
      if hitIndicator then
        if orig.combatTextFrames.hitIndicatorShown then hitIndicator:Show() elseif hitIndicator.Hide then hitIndicator:Hide() end
      end
    end
  end

  local function ApplyTargetFocusBuffSuppression(enabled)
    local frames = {
      {frame = TargetFrame, prefix = "TargetFrame"},
      {frame = FocusFrame, prefix = "FocusFrame"},
    }
    for _, entry in ipairs(frames) do
      if entry.frame then
        if enabled then
          entry.frame.maxBuffs = 0
          entry.frame.maxDebuffs = 0
        else
          entry.frame.maxBuffs = nil
          entry.frame.maxDebuffs = nil
        end
        local function hideAuras()
          for i = 1, 40 do
            local buff = _G[entry.prefix .. "Buff" .. i]
            if buff and buff.Hide then buff:Hide() end
            local debuff = _G[entry.prefix .. "Debuff" .. i]
            if debuff and debuff.Hide then debuff:Hide() end
          end
        end
        if enabled then
          hideAuras()
        end
        if not orig.auraBuffsHooked then orig.auraBuffsHooked = {} end
        if not orig.auraBuffsHooked[entry.prefix] and type(hooksecurefunc) == "function" then
          orig.auraBuffsHooked[entry.prefix] = true
          if type(entry.frame.UpdateAuras) == "function" then
            hooksecurefunc(entry.frame, "UpdateAuras", function()
              local p = addonTable.GetProfile and addonTable.GetProfile()
              if p and p.disableTargetFocusBuffs then hideAuras() end
            end)
          end
        end
      end
    end
    if not orig.auraGlobalHooked and type(hooksecurefunc) == "function" and type(TargetFrame_UpdateAuras) == "function" then
      orig.auraGlobalHooked = true
      hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        local p = addonTable.GetProfile and addonTable.GetProfile()
        if not p or not p.disableTargetFocusBuffs then return end
        local prefix = (self == TargetFrame and "TargetFrame") or (self == FocusFrame and "FocusFrame") or nil
        if not prefix then return end
        for i = 1, 40 do
          local buff = _G[prefix .. "Buff" .. i]
          if buff and buff.Hide then buff:Hide() end
          local debuff = _G[prefix .. "Debuff" .. i]
          if debuff and debuff.Hide then debuff:Hide() end
        end
      end)
    end
  end

  local function ApplyEliteTextureSuppression(enabled)
    local unitFrames = {
      {frame = TargetFrame, key = "targetBoss"},
      {frame = FocusFrame, key = "focusBoss"},
    }
    if not orig.bossTexHooked then orig.bossTexHooked = {} end
    if not orig.bossTexSaved then orig.bossTexSaved = {} end
    for _, uf in ipairs(unitFrames) do
      local container = uf.frame and uf.frame.TargetFrameContainer
      local tex = container and container.BossPortraitFrameTexture
      if tex then
        if not orig.bossTexSaved[uf.key] then
          orig.bossTexSaved[uf.key] = true
          orig.bossTexSaved[uf.key .. "Shown"] = tex.IsShown and tex:IsShown() or nil
        end
        if enabled then
          if tex.Hide then tex:Hide() end
          if not orig.bossTexHooked[uf.key] and type(hooksecurefunc) == "function" then
            orig.bossTexHooked[uf.key] = true
            hooksecurefunc(tex, "Show", function(self)
              local p = addonTable.GetProfile and addonTable.GetProfile()
              if p and p.hideEliteTexture then self:Hide() end
            end)
          end
        else
          if orig.bossTexSaved[uf.key .. "Shown"] and tex.Show then tex:Show() end
        end
      end
    end
  end

  if ufEnabled and profile.ufCustomizeHealth == true then
    RestorePoints(healthBar, orig.healthPoints)
    if orig.expandedHealthHeight and orig.expandedHealthHeight > 0 then
      healthBar:SetHeight(orig.expandedHealthHeight)
    end
    local statusTex = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
    if statusTex then
      statusTex:ClearAllPoints()
      statusTex:SetAllPoints(healthBar)
      if statusTex.SetTexCoord then
        statusTex:SetTexCoord(0, 1, 0, 1)
      end
    end
    if healthMask then
      healthMask:Hide()
    end
    powerBar:SetAlpha(0)
    powerBar:Hide()
    powerBar:SetFrameLevel((healthBar:GetFrameLevel() or 1) + 2)
    if manaArea then
      manaArea:SetAlpha(0)
      manaArea:Hide()
      manaArea:SetFrameLevel((healthBar:GetFrameLevel() or 1) + 1)
      if orig.manaAreaHeight and orig.manaAreaHeight > 0 then
        manaArea:SetHeight(orig.manaAreaHeight)
      end
    else
      powerBar:ClearAllPoints()
      powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)
      powerBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -1)
    end
    if PlayerFrameManaBarText then
      PlayerFrameManaBarText:Hide()
    end
    ApplyPlayerHealthColor()
  else
    RestorePoints(healthBar, orig.healthPoints)
    RestorePoints(powerBar, orig.powerPoints)
    if manaArea then
      RestorePoints(manaArea, orig.manaAreaPoints)
      manaArea:SetAlpha(orig.manaAreaAlpha or 1)
      manaArea:Show()
    end
    if healthMask then
      RestorePoints(healthMask, orig.maskPoints)
      if orig.maskShown then
        healthMask:Show()
      else
        healthMask:Hide()
      end
    end
    if orig.healthHeight and orig.healthHeight > 0 then
      healthBar:SetHeight(orig.healthHeight)
    end
    ApplyPlayerHealthColor()
    if orig.powerHeight and orig.powerHeight > 0 then
      powerBar:SetHeight(orig.powerHeight)
    end
    powerBar:SetAlpha(orig.powerAlpha or 1)
    powerBar:SetAlpha(orig.powerAlpha or 1)
    powerBar:Show()
    if PlayerFrameManaBarText and orig.powerTextShown then
      PlayerFrameManaBarText:Show()
    end
    if orig.powerFrameLevel then
      powerBar:SetFrameLevel(orig.powerFrameLevel)
    end
    if manaArea and orig.manaAreaFrameLevel then
      manaArea:SetFrameLevel(orig.manaAreaFrameLevel)
    end
  end
  local disableGlows = profile.ufDisableGlows == true
  if disableGlows then
    ApplyGlowSuppression(true)
  else
    ApplyGlowSuppression(false)
  end
  local disableCombatText = profile.ufDisableCombatText == true
  if disableCombatText then
    ApplyCombatTextSuppression(true)
  else
    ApplyCombatTextSuppression(false)
  end
  local disableBuffs = profile.disableTargetFocusBuffs == true
  if disableBuffs then
    ApplyTargetFocusBuffSuppression(true)
  else
    ApplyTargetFocusBuffSuppression(false)
  end
  local hideElite = profile.hideEliteTexture == true
  if hideElite then
    ApplyEliteTextureSuppression(true)
  else
    ApplyEliteTextureSuppression(false)
  end
  ApplyBiggerHealthForUnit(TargetFrame, false, "targetFrameOriginal", "target")
  ApplyBiggerHealthForUnit(FocusFrame, false, "focusFrameOriginal", "focus")
  if not orig.ufFontHooked then
    orig.ufFontHooked = true
    orig.ufFontObjects = orig.ufFontObjects or {}
    local function GetOrCreateFontObject(size)
      local key = math.floor(size + 0.5)
      if not orig.ufFontObjects[key] then
        orig.ufFontObjects[key] = CreateFont("CCM_UFFont_" .. key)
      end
      local gf, go = GetGlobalFont()
      local oFlag = (go and go ~= "") and go or "OUTLINE"
      orig.ufFontObjects[key]:SetFont(gf, key, oFlag)
      return orig.ufFontObjects[key]
    end
    local function ApplyGlobalFontToUFs()
      local gf, go = GetGlobalFont()
      local oFlag = (go and go ~= "") and go or "OUTLINE"
      local function afs(fs)
        if not fs or not fs.GetFont or not fs.SetFont then return end
        local _, sz = fs:GetFont()
        if not sz or sz <= 0 then sz = 12 end
        pcall(fs.SetFont, fs, gf, sz, oFlag)
      end
      afs(_G["PlayerName"])
      afs(_G["PlayerLevelText"])
      if healthBar then
        afs(healthBar.TextString)
        afs(healthBar.LeftText)
        afs(healthBar.RightText)
      end
      afs(_G["PlayerFrameHealthBarText"])
      afs(_G["PlayerFrameHealthBarTextLeft"])
      afs(_G["PlayerFrameHealthBarTextRight"])
      afs(_G["PlayerFrameManaBarText"])
      afs(_G["PlayerFrameManaBarTextLeft"])
      afs(_G["PlayerFrameManaBarTextRight"])
      if powerBar then
        afs(powerBar.TextString)
        afs(powerBar.LeftText)
        afs(powerBar.RightText)
      end
      local function afsUnit(unitFrame)
        if not unitFrame then return end
        local tMain = unitFrame.TargetFrameContent and unitFrame.TargetFrameContent.TargetFrameContentMain
        if tMain then
          afs(tMain.Name)
          afs(tMain.LevelText)
        end
        local hc = tMain and tMain.HealthBarsContainer
        local hb = hc and hc.HealthBar
        if hb then afs(hb.TextString); afs(hb.LeftText); afs(hb.RightText) end
        local mb = tMain and tMain.ManaBar
        if mb then afs(mb.TextString); afs(mb.LeftText); afs(mb.RightText) end
      end
      afsUnit(TargetFrame)
      afsUnit(FocusFrame)
      local prof = addonTable.GetProfile and addonTable.GetProfile()
      if prof then
        local nr = prof.ufNameColorR or 1
        local ng = prof.ufNameColorG or 1
        local nb = prof.ufNameColorB or 1
        local function setNameColor(fs)
          if fs and fs.SetTextColor then pcall(fs.SetTextColor, fs, nr, ng, nb) end
        end
        setNameColor(_G["PlayerName"])
        setNameColor(_G["PlayerLevelText"])
        local function setUnitNameColor(unitFrame)
          if not unitFrame then return end
          local tMain = unitFrame.TargetFrameContent and unitFrame.TargetFrameContent.TargetFrameContentMain
          if tMain then
            setNameColor(tMain.Name)
            setNameColor(tMain.LevelText)
          end
        end
        setUnitNameColor(TargetFrame)
        setUnitNameColor(FocusFrame)
        local tot = _G.TargetFrameToT or _G.TargetFrameToTFrame
        if tot then
          local totMain = tot.TargetFrameContent and tot.TargetFrameContent.TargetFrameContentMain
          if totMain then setNameColor(totMain.Name) end
          if tot.Name then setNameColor(tot.Name) end
        end
        for i = 1, 5 do
          setUnitNameColor(_G["Boss" .. i .. "TargetFrame"])
        end
        local petFrame = _G.PetFrame
        if petFrame then
          local petMain = petFrame.TargetFrameContent and petFrame.TargetFrameContent.TargetFrameContentMain
          if petMain and petMain.Name then setNameColor(petMain.Name) end
          if petFrame.Name then setNameColor(petFrame.Name) end
        end
        setNameColor(_G["PetName"])
      end
    end
    orig.ApplyGlobalFontToUFs = ApplyGlobalFontToUFs
    hooksecurefunc("UnitFrameHealthBar_Update", function() ApplyGlobalFontToUFs() end)
    if type(UnitFrameManaBar_Update) == "function" then
      hooksecurefunc("UnitFrameManaBar_Update", function() ApplyGlobalFontToUFs() end)
    end
    local fontEventFrame = CreateFrame("Frame")
    fontEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    fontEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    fontEventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    fontEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    fontEventFrame:SetScript("OnEvent", function() ApplyGlobalFontToUFs() end)
  end
  if orig.ApplyGlobalFontToUFs then orig.ApplyGlobalFontToUFs() end
end
local function UpdatePRB()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.usePersonalResourceBar then
    prbFrame:Hide()
    SetBlizzardPlayerPowerBarsVisibility(false, false)
    return
  end
  local showMode = profile.prbShowMode or "always"
  if showMode == "combat" and not InCombatLockdown() then
    prbFrame:Hide()
    return
  end
  local width = profile.prbWidth or 220
  local rawBorder = profile.prbBorderSize or 1
  local borderSize = rawBorder > 0 and (rawBorder + 1) or 0
  local autoWidthSource = profile.prbAutoWidthSource or "off"
  if autoWidthSource ~= "off" then
    if autoWidthSource == "essential" then
      local widthFromEss = 0
      if profile.useEssentialBar and State.cachedEssentialBarWidth and State.cachedEssentialBarWidth > 0 then
        widthFromEss = State.cachedEssentialBarWidth
      else
        local essBar = EssentialCooldownViewer
        if essBar and essBar:IsShown() then
          local w = essBar:GetWidth()
          if w and w > 0 then
            local scale = essBar.GetEffectiveScale and essBar:GetEffectiveScale() or 1
            local parentScale = UIParent:GetEffectiveScale()
            if parentScale and parentScale > 0 then
              widthFromEss = w * (scale / parentScale)
            else
              widthFromEss = w
            end
          end
        end
        if widthFromEss <= 0 and State.standaloneEssentialWidth and State.standaloneEssentialWidth > 0 then
          widthFromEss = State.standaloneEssentialWidth
        end
      end
      if widthFromEss > 0 then
        width = widthFromEss - (borderSize * 2)
        if width < 10 then width = 10 end
      end
    elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" then
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
        width = (cbarWidth * cbarCount) + (cbarSpacing * (cbarCount - 1)) - (borderSize * 2)
        if width < 10 then width = 10 end
      end
    end
  end
  width = math.floor(width)
  local healthHeight = profile.prbHealthHeight or 18
  local powerHeight = profile.prbPowerHeight or 8
    local spacing = profile.prbSpacing
    if spacing == nil then spacing = 0 end
    local showHealth = profile.prbShowHealth == true
    local showPower = profile.prbShowPower == true
    local healthTextMode = profile.prbHealthTextMode or "hidden"
    local powerTextMode = profile.prbPowerTextMode or "hidden"
    local bgAlpha = (profile.prbBackgroundAlpha or 70) / 100
    local healthTextScale = profile.prbHealthTextScale or 1
    local powerTextScale = profile.prbPowerTextScale or 1
    local manaTextScale = profile.prbManaTextScale or 1
    local healthTextY = profile.prbHealthTextY or 0
    local powerTextY = profile.prbPowerTextY or 0
    local manaTextY = profile.prbManaTextY or 0
    local healthYOffset = profile.prbHealthYOffset or 0
    local powerYOffset = profile.prbPowerYOffset or 0
    local manaYOffset = profile.prbManaYOffset or 0
    local clampBars = profile.prbClampBars == true
    local healthTexture = profile.prbHealthTexture or "solid"
    local powerTexture = profile.prbPowerTexture or "solid"
    local manaTexture = profile.prbManaTexture or "solid"
    local texturePaths = {
      solid = "Interface\\Buttons\\WHITE8x8",
      flat = "Interface\\Buttons\\WHITE8x8",
      blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
      blizzraid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
      smooth = "Interface\\TargetingFrame\\UI-StatusBar-Glow",
      minimalist = "Interface\\ChatFrame\\ChatFrameBackground",
      cilo = "Interface\\TARGETINGFRAME\\UI-TargetingFrame-BarFill",
      glaze = "Interface\\TargetingFrame\\BarFill2",
      steel = "Interface\\TargetingFrame\\UI-TargetingFrame-Fill",
      aluminium = "Interface\\UNITPOWERBARALT\\Metal_Horizontal_Fill",
      metal = "Interface\\UNITPOWERBARALT\\Metal_Horizontal_Fill",
      amber = "Interface\\UNITPOWERBARALT\\Amber_Horizontal_Fill",
      arcane = "Interface\\UNITPOWERBARALT\\Arcane_Horizontal_Fill",
      fire = "Interface\\UNITPOWERBARALT\\Fire_Horizontal_Fill",
      water = "Interface\\UNITPOWERBARALT\\Water_Horizontal_Fill",
      waterdark = "Interface\\UNITPOWERBARALT\\WaterDark_Horizontal_Fill",
      generic = "Interface\\UNITPOWERBARALT\\Generic_Horizontal_Fill",
      round = "Interface\\AchievementFrame\\UI-Achievement-ProgressBar-Fill",
      diagonal = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-HorizontalShadow",
      striped = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
      armory = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",
      gradient = "Interface\\CHARACTERFRAME\\UI-Player-Status-Left",
      otravi = "Interface\\Tooltips\\UI-Tooltip-Background",
      rocks = "Interface\\FrameGeneral\\UI-Background-Rock",
      highlight = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight",
      inner = "Interface\\BUTTONS\\UI-Listbox-Highlight2",
      lite = "Interface\\LFGFRAME\\UI-LFG-SEPARATOR",
      spark = "Interface\\CastingBar\\UI-CastingBar-Spark",
      normtex = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\normTex",
      gloss = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Gloss",
      melli = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Melli",
      mellidark = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\MelliDark",
      betterblizzard = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\BetterBlizzard",
      skyline = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Skyline",
      dragonflight = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Dragonflight",
    }
    local healthTexturePath = texturePaths[healthTexture] or texturePaths.solid
    local powerTexturePath = texturePaths[powerTexture] or texturePaths.solid
    local manaTexturePath = texturePaths[manaTexture] or texturePaths.solid
    local showManaBarOption = profile.prbShowManaBar == true
    local _, playerClass = UnitClass("player")
    local currentPowerType = UnitPowerType("player")
    local hasMana = (playerClass ~= "WARRIOR" and playerClass ~= "ROGUE" and playerClass ~= "DEATHKNIGHT" and playerClass ~= "DEMONHUNTER")
    local needsManaBar = hasMana and currentPowerType ~= 0
    local showManaBar = showManaBarOption and needsManaBar
    local manaHeight = profile.prbManaHeight or 6
    local showClassPower = profile.prbShowClassPower == true
    local cpConfig = GetClassPowerConfig()
    local hasClassPower = cpConfig ~= nil and not IsClassPowerRedundant()
    local cpHeight = profile.prbClassPowerHeight or 6
    local cpYOffset = profile.prbClassPowerY or 20
    local clampAnchor = (profile.prbClampAnchor == "bottom") and "bottom" or "top"
    local barOrder = {}
    local clampTotalHeight = nil
    if clampBars then
      table.insert(barOrder, {type = "health", priority = healthYOffset, height = healthHeight, order = 1, active = showHealth})
      table.insert(barOrder, {type = "power", priority = powerYOffset, height = powerHeight, order = 2, active = showPower})
      table.insert(barOrder, {type = "mana", priority = manaYOffset, height = manaHeight, order = 3, active = showManaBar})
      table.insert(barOrder, {type = "classpower", priority = cpYOffset, height = cpHeight, order = 4, active = (showClassPower and hasClassPower)})
      table.sort(barOrder, function(a, b)
        if a.priority == b.priority then
          return (a.order or 99) < (b.order or 99)
        end
        return a.priority > b.priority
      end)
      local effectiveSpacing = spacing
      if borderSize > 0 then
        effectiveSpacing = effectiveSpacing + (borderSize * 2)
        if borderSize == 1 then
          effectiveSpacing = effectiveSpacing + 1
        end
      end
      local reservedHeight = 0
      for i, barInfo in ipairs(barOrder) do
        if i > 1 then
          reservedHeight = reservedHeight + effectiveSpacing
        end
        reservedHeight = reservedHeight + barInfo.height
      end
      local activePos = 0
      local activeCount = 0
      local activeHeight = 0
      for _, barInfo in ipairs(barOrder) do
        if barInfo.active ~= false then
          activeCount = activeCount + 1
          if activeCount > 1 then
            activePos = activePos + effectiveSpacing
          end
          barInfo.yPos = activePos
          activePos = activePos + barInfo.height
          activeHeight = activePos
        end
      end
      if clampAnchor == "bottom" and activeCount > 0 and reservedHeight > activeHeight then
        local bottomShift = reservedHeight - activeHeight
        for _, barInfo in ipairs(barOrder) do
          if barInfo.active ~= false and barInfo.yPos then
            barInfo.yPos = barInfo.yPos + bottomShift
          end
        end
      end
      clampTotalHeight = reservedHeight
    end
    local function GetBarYPos(barType, defaultYOff, yOffset)
      if clampBars then
        for _, barInfo in ipairs(barOrder) do
          if barInfo.type == barType then
            return barInfo.yPos
          end
        end
        return 0
      else
        return defaultYOff - yOffset
      end
    end
    local totalHeight = 0
    if clampBars then
      totalHeight = clampTotalHeight or 0
    else
      if showHealth then totalHeight = totalHeight + healthHeight end
      if showPower and showHealth then totalHeight = totalHeight + spacing + powerHeight end
      if showPower and not showHealth then totalHeight = totalHeight + powerHeight end
      if showManaBar and (showHealth or showPower) then totalHeight = totalHeight + spacing + manaHeight end
      if showManaBar and not showHealth and not showPower then totalHeight = totalHeight + manaHeight end
    end
    PixelUtil.SetSize(prbFrame, width, math.max(totalHeight, 10))
    if not State.prbDragging then
      local posX = profile.prbX or 0
      local posY = profile.prbY or -180
      prbFrame:ClearAllPoints()
      if profile.prbCentered then
        prbFrame:SetPoint("CENTER", UIParent, "CENTER", 0, posY)
      else
        prbFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
      end
    end
    local yOff = 0
    local powerYPosForClamp = nil
    if showHealth then
      prbFrame.healthBar:Show()
      prbFrame.healthBar:SetStatusBarTexture(healthTexturePath)
      prbFrame.healthBar:ClearAllPoints()
      local healthY = clampBars and GetBarYPos("health", 0, 0) or (yOff - healthYOffset)
      PixelUtil.SetPoint(prbFrame.healthBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -healthY)
      PixelUtil.SetSize(prbFrame.healthBar, width, healthHeight)
      prbFrame.healthBar:SetMinMaxValues(0, UnitHealthMax("player") or 1)
      prbFrame.healthBar:SetValue(UnitHealth("player") or 0)
      if profile.prbUseClassColor then
        local r, g, b = GetClassColor()
        prbFrame.healthBar:SetStatusBarColor(r, g, b)
      else
        local r = profile.prbHealthColorR or 0
        local g = profile.prbHealthColorG or 0.8
        local b = profile.prbHealthColorB or 0
        prbFrame.healthBar:SetStatusBarColor(r, g, b)
      end
      local bgR = profile.prbBgColorR or 0.1
      local bgG = profile.prbBgColorG or 0.1
      local bgB = profile.prbBgColorB or 0.1
      prbFrame.healthBar.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
      if borderSize > 0 then
        prbFrame.healthBar.border:ClearAllPoints()
        prbFrame.healthBar.border:SetPoint("TOPLEFT", prbFrame.healthBar, "TOPLEFT", -borderSize, borderSize)
        prbFrame.healthBar.border:SetPoint("BOTTOMRIGHT", prbFrame.healthBar, "BOTTOMRIGHT", borderSize, -borderSize)
        prbFrame.healthBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize, insets = {left = borderSize, right = borderSize, top = borderSize, bottom = borderSize}})
        prbFrame.healthBar.border:SetBackdropBorderColor(0, 0, 0, 1)
        prbFrame.healthBar.border:Show()
      else
        prbFrame.healthBar.border:SetBackdrop(nil)
        prbFrame.healthBar.border:Hide()
      end
      local htR = profile.prbHealthTextColorR or 1
      local htG = profile.prbHealthTextColorG or 1
      local htB = profile.prbHealthTextColorB or 1
      prbFrame.healthBar.text:SetTextColor(htR, htG, htB)
      prbFrame.healthBar.text:SetScale(healthTextScale)
      local globalFont, globalOutline = GetGlobalFont()
      local fontSize = 12 * healthTextScale
      prbFrame.healthBar.text:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      prbFrame.healthBar.text:ClearAllPoints()
      prbFrame.healthBar.text:SetPoint("CENTER", prbFrame.healthBar, "CENTER", 0, healthTextY)
      if healthTextMode ~= "hidden" then
        local healthText = ""
        if healthTextMode == "percent" then
          if UnitHealthPercent then
            local pct = UnitHealthPercent("player", false, CurveConstants.ScaleTo100)
            healthText = string.format("%.0f%%", pct or 100)
          else
            healthText = "100%"
          end
        elseif healthTextMode == "percentnumber" then
          if UnitHealthPercent then
            local pct = UnitHealthPercent("player", false, CurveConstants.ScaleTo100)
            healthText = string.format("%.0f", pct or 100)
          else
            healthText = "100"
          end
        elseif healthTextMode == "value" then
          healthText = AbbreviateNumbers(UnitHealth("player"))
        elseif healthTextMode == "both" then
          local valStr = AbbreviateNumbers(UnitHealth("player"))
          local pct = 100
          if UnitHealthPercent then
            pct = UnitHealthPercent("player", false, CurveConstants.ScaleTo100) or 100
          end
          healthText = string.format("%s (%.0f%%)", valStr, pct)
        end
        prbFrame.healthBar.text:SetText(healthText)
        FitTextToBar(prbFrame.healthBar.text, width, healthTextScale, 6, healthHeight)
        prbFrame.healthBar.text:Show()
      else
        prbFrame.healthBar.text:Hide()
      end
      if showPower then
        yOff = yOff + healthHeight + spacing
      else
        yOff = yOff + healthHeight
      end
    else
      prbFrame.healthBar:Hide()
      prbFrame.healthBar.text:Hide()
    end
    if showPower then
      prbFrame.powerBar:Show()
      prbFrame.powerBar:SetStatusBarTexture(powerTexturePath)
      prbFrame.powerBar:ClearAllPoints()
      local powerY = clampBars and GetBarYPos("power", 0, 0) or (yOff - powerYOffset)
      if clampBars then
        powerYPosForClamp = powerY
      end
      PixelUtil.SetPoint(prbFrame.powerBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -powerY)
      PixelUtil.SetSize(prbFrame.powerBar, width, powerHeight)
      local powerType = UnitPowerType("player") or 0
      prbFrame.powerBar:SetMinMaxValues(0, UnitPowerMax("player") or 1)
      prbFrame.powerBar:SetValue(UnitPower("player") or 0)
      if profile.prbUsePowerTypeColor then
        if powerType == 0 then
          prbFrame.powerBar:SetStatusBarColor(0, 0.298, 1)
        else
          local powerColors = PowerBarColor[powerType]
          if powerColors then
            prbFrame.powerBar:SetStatusBarColor(powerColors.r, powerColors.g, powerColors.b)
          else
            prbFrame.powerBar:SetStatusBarColor(0, 0.5, 1)
          end
        end
      else
        local r = profile.prbPowerColorR or 0
        local g = profile.prbPowerColorG or 0.5
        local b = profile.prbPowerColorB or 1
        prbFrame.powerBar:SetStatusBarColor(r, g, b)
      end
      local bgR = profile.prbBgColorR or 0.1
      local bgG = profile.prbBgColorG or 0.1
      local bgB = profile.prbBgColorB or 0.1
      prbFrame.powerBar.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
      if borderSize > 0 then
        prbFrame.powerBar.border:ClearAllPoints()
        prbFrame.powerBar.border:SetPoint("TOPLEFT", prbFrame.powerBar, "TOPLEFT", -borderSize, borderSize)
        prbFrame.powerBar.border:SetPoint("BOTTOMRIGHT", prbFrame.powerBar, "BOTTOMRIGHT", borderSize, -borderSize)
        prbFrame.powerBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize, insets = {left = borderSize, right = borderSize, top = borderSize, bottom = borderSize}})
        prbFrame.powerBar.border:SetBackdropBorderColor(0, 0, 0, 1)
        prbFrame.powerBar.border:Show()
      else
        prbFrame.powerBar.border:SetBackdrop(nil)
        prbFrame.powerBar.border:Hide()
      end
      local ptR = profile.prbPowerTextColorR or 1
      local ptG = profile.prbPowerTextColorG or 1
      local ptB = profile.prbPowerTextColorB or 1
      prbFrame.powerBar.text:SetTextColor(ptR, ptG, ptB)
      prbFrame.powerBar.text:SetScale(powerTextScale)
      local globalFont, globalOutline = GetGlobalFont()
      prbFrame.powerBar.text:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      prbFrame.powerBar.text:ClearAllPoints()
      prbFrame.powerBar.text:SetPoint("CENTER", prbFrame.powerBar, "CENTER", 0, powerTextY)
      if powerTextMode ~= "hidden" then
        local powerText = ""
        if powerTextMode == "percent" then
          if UnitPowerPercent then
            local pct = UnitPowerPercent("player", powerType, false, CurveConstants.ScaleTo100)
            powerText = string.format("%.0f%%", pct or 100)
          else
            powerText = "100%"
          end
        elseif powerTextMode == "percentnumber" then
          if UnitPowerPercent then
            local pct = UnitPowerPercent("player", powerType, false, CurveConstants.ScaleTo100)
            powerText = string.format("%.0f", pct or 100)
          else
            powerText = "100"
          end
        elseif powerTextMode == "value" then
          powerText = AbbreviateNumbers(UnitPower("player", powerType))
        elseif powerTextMode == "both" then
          local valStr = AbbreviateNumbers(UnitPower("player", powerType))
          local pct = 100
          if UnitPowerPercent then
            pct = UnitPowerPercent("player", powerType, false, CurveConstants.ScaleTo100) or 100
          end
          powerText = string.format("%s (%.0f%%)", valStr, pct)
        end
        prbFrame.powerBar.text:SetText(powerText)
        FitTextToBar(prbFrame.powerBar.text, width, powerTextScale, 6, powerHeight)
        prbFrame.powerBar.text:Show()
      else
        prbFrame.powerBar.text:Hide()
      end
      yOff = yOff + powerHeight
    else
      prbFrame.powerBar:Hide()
      prbFrame.powerBar.text:Hide()
    end
    if showManaBar then
      local manaTextMode = profile.prbManaTextMode or "hidden"
      if (showHealth or showPower) then
        yOff = yOff + spacing
      end
      prbFrame.manaBar:Show()
      prbFrame.manaBar:SetStatusBarTexture(manaTexturePath)
      prbFrame.manaBar:ClearAllPoints()
      local manaY = clampBars and GetBarYPos("mana", 0, 0) or (yOff - manaYOffset)
      if clampBars and powerYPosForClamp ~= nil then
        local minGap = spacing + (borderSize > 0 and (borderSize * 2) or 0)
        if borderSize == 1 then
          minGap = minGap + 1
        end
        minGap = math.max(1, minGap)
        prbFrame.manaBar:SetPoint("TOPLEFT", prbFrame.powerBar, "BOTTOMLEFT", 0, -minGap)
      else
        PixelUtil.SetPoint(prbFrame.manaBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -manaY)
      end
      PixelUtil.SetSize(prbFrame.manaBar, width, manaHeight)
      prbFrame.manaBar:SetMinMaxValues(0, UnitPowerMax("player", 0) or 1)
      prbFrame.manaBar:SetValue(UnitPower("player", 0) or 0)
      local mR = profile.prbManaColorR or 0
      local mG = profile.prbManaColorG or 0.5
      local mB = profile.prbManaColorB or 1
      prbFrame.manaBar:SetStatusBarColor(mR, mG, mB)
      local bgR = profile.prbBgColorR or 0.1
      local bgG = profile.prbBgColorG or 0.1
      local bgB = profile.prbBgColorB or 0.1
      prbFrame.manaBar.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
      if borderSize > 0 then
        prbFrame.manaBar.border:ClearAllPoints()
        prbFrame.manaBar.border:SetPoint("TOPLEFT", prbFrame.manaBar, "TOPLEFT", -borderSize, borderSize)
        prbFrame.manaBar.border:SetPoint("BOTTOMRIGHT", prbFrame.manaBar, "BOTTOMRIGHT", borderSize, -borderSize)
        prbFrame.manaBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize, insets = {left = borderSize, right = borderSize, top = borderSize, bottom = borderSize}})
        prbFrame.manaBar.border:SetBackdropBorderColor(0, 0, 0, 1)
        prbFrame.manaBar.border:Show()
      else
        prbFrame.manaBar.border:SetBackdrop(nil)
        prbFrame.manaBar.border:Hide()
      end
      local mtR = profile.prbManaTextColorR or 1
      local mtG = profile.prbManaTextColorG or 1
      local mtB = profile.prbManaTextColorB or 1
      prbFrame.manaBar.text:SetTextColor(mtR, mtG, mtB)
      prbFrame.manaBar.text:SetScale(manaTextScale)
      local globalFont, globalOutline = GetGlobalFont()
      prbFrame.manaBar.text:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      prbFrame.manaBar.text:ClearAllPoints()
      prbFrame.manaBar.text:SetPoint("CENTER", prbFrame.manaBar, "CENTER", 0, manaTextY)
      if manaTextMode ~= "hidden" then
        local manaText = ""
        if manaTextMode == "percent" then
          if UnitPowerPercent then
            local pct = UnitPowerPercent("player", 0, true, CurveConstants and CurveConstants.ScaleTo100 or 1)
            manaText = string.format("%.0f%%", pct or 100)
          else
            manaText = "100%"
          end
        elseif manaTextMode == "percentnumber" then
          if UnitPowerPercent then
            local pct = UnitPowerPercent("player", 0, true, CurveConstants and CurveConstants.ScaleTo100 or 1)
            manaText = string.format("%.0f", pct or 100)
          else
            manaText = "100"
          end
        elseif manaTextMode == "value" then
          manaText = AbbreviateNumbers(UnitPower("player", 0))
        elseif manaTextMode == "both" then
          local valStr = AbbreviateNumbers(UnitPower("player", 0))
          local pct = 100
          if UnitPowerPercent then
            pct = UnitPowerPercent("player", 0, true, CurveConstants and CurveConstants.ScaleTo100 or 1) or 100
          end
          manaText = string.format("%s (%.0f%%)", valStr, pct)
        end
        prbFrame.manaBar.text:SetText(manaText)
        FitTextToBar(prbFrame.manaBar.text, width, manaTextScale, 6, manaHeight)
        prbFrame.manaBar.text:Show()
      else
        prbFrame.manaBar.text:Hide()
      end
    else
      prbFrame.manaBar:Hide()
      prbFrame.manaBar.text:Hide()
    end
    local _, playerClass = UnitClass("player")
    SetBlizzardPlayerPowerBarsVisibility(showPower, showClassPower)
    local classPowerType = cpConfig and cpConfig.powerType
    local buffID = cpConfig and cpConfig.buffID
    local classPower = 0
    local maxClassPower = 5
    if hasClassPower and buffID then
      local auraData = C_UnitAuras.GetPlayerAuraBySpellID(buffID)
      if auraData then
        classPower = auraData.applications or auraData.count or 0
      end
      maxClassPower = cpConfig.maxStacks or 10
    elseif hasClassPower and classPowerType then
      local maxPower = UnitPowerMax("player", classPowerType) or 0
      if maxPower <= 0 then
        hasClassPower = false
      else
        classPower = UnitPower("player", classPowerType) or 0
        maxClassPower = maxPower
      end
    end
    for i = 1, 10 do
      if prbFrame.classPowerSegments[i] then
        prbFrame.classPowerSegments[i]:Hide()
      end
    end
    if showClassPower and hasClassPower then
      local cpR = profile.prbClassPowerColorR or 1
      local cpG = profile.prbClassPowerColorG or 0.82
      local cpB = profile.prbClassPowerColorB or 0
      local cpY = profile.prbClassPowerY or 20
      local cpX = profile.prbClassPowerX or 0
      local isContinuous = cpConfig.continuous == true
      if isContinuous then
        for i = 1, 10 do
          if prbFrame.classPowerSegments[i] then
            prbFrame.classPowerSegments[i]:Hide()
          end
        end
        PixelUtil.SetSize(prbFrame.classPowerBar, width, cpHeight)
        prbFrame.classPowerBar:ClearAllPoints()
        if clampBars then
          local classPowerYPos = GetBarYPos("classpower", 0, 0)
          PixelUtil.SetPoint(prbFrame.classPowerBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -classPowerYPos)
        elseif profile.prbCentered then
          prbFrame.classPowerBar:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", 0, cpY)
        else
          prbFrame.classPowerBar:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", cpX, cpY)
        end
        prbFrame.classPowerBar:SetMinMaxValues(0, maxClassPower)
        prbFrame.classPowerBar:SetValue(classPower)
        prbFrame.classPowerBar:SetStatusBarColor(cpR, cpG, cpB, 1)
        prbFrame.classPowerBar.bg:SetColorTexture(0.15, 0.15, 0.15, bgAlpha)
        if borderSize > 0 then
          prbFrame.classPowerBar.border:ClearAllPoints()
          prbFrame.classPowerBar.border:SetPoint("TOPLEFT", prbFrame.classPowerBar, "TOPLEFT", -borderSize, borderSize)
          prbFrame.classPowerBar.border:SetPoint("BOTTOMRIGHT", prbFrame.classPowerBar, "BOTTOMRIGHT", borderSize, -borderSize)
          prbFrame.classPowerBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize, insets = {left = borderSize, right = borderSize, top = borderSize, bottom = borderSize}})
          prbFrame.classPowerBar.border:SetBackdropBorderColor(0, 0, 0, 1)
          prbFrame.classPowerBar.border:Show()
        else
          prbFrame.classPowerBar.border:SetBackdrop(nil)
          prbFrame.classPowerBar.border:Hide()
        end
        prbFrame.classPowerBar:Show()
      else
        prbFrame.classPowerBar:Hide()
        if maxClassPower > 0 then
          local segSpacing = 2
          local segTotalWidth = prbFrame:GetWidth() or width
          local totalSpacing = (maxClassPower - 1) * segSpacing
          local baseSegWidth = math.floor((segTotalWidth - totalSpacing) / maxClassPower)
          for i = 1, maxClassPower do
            local seg = prbFrame.classPowerSegments[i]
            if seg then
              local xOff = (i - 1) * (baseSegWidth + segSpacing)
              seg:ClearAllPoints()
              if i == maxClassPower then
                if clampBars then
                  local classPowerYPos = GetBarYPos("classpower", 0, 0)
                  seg:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", xOff, -classPowerYPos)
                  seg:SetPoint("BOTTOMRIGHT", prbFrame, "TOPLEFT", segTotalWidth, -classPowerYPos - cpHeight)
                elseif profile.prbCentered then
                  seg:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", xOff, cpY)
                  seg:SetPoint("TOPRIGHT", prbFrame, "TOPLEFT", segTotalWidth, cpY + cpHeight)
                else
                  seg:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", xOff + cpX, cpY)
                  seg:SetPoint("TOPRIGHT", prbFrame, "TOPLEFT", cpX + segTotalWidth, cpY + cpHeight)
                end
              else
                PixelUtil.SetSize(seg, baseSegWidth, cpHeight)
                if clampBars then
                  local classPowerYPos = GetBarYPos("classpower", 0, 0)
                  seg:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", xOff, -classPowerYPos)
                elseif profile.prbCentered then
                  seg:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", xOff, cpY)
                else
                  seg:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", xOff + cpX, cpY)
                end
              end
              if borderSize > 0 then
                seg.border:ClearAllPoints()
                seg.border:SetPoint("TOPLEFT", seg, "TOPLEFT", -borderSize, borderSize)
                seg.border:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", borderSize, -borderSize)
                seg.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize, insets = {left = borderSize, right = borderSize, top = borderSize, bottom = borderSize}})
                seg.border:SetBackdropBorderColor(0, 0, 0, 1)
                seg.border:Show()
              else
                seg.border:SetBackdrop(nil)
                seg.border:Hide()
              end
              if i <= classPower then
                seg.bg:SetColorTexture(cpR, cpG, cpB, 1)
              else
                seg.bg:SetColorTexture(0.15, 0.15, 0.15, bgAlpha)
              end
              seg:Show()
            end
          end
          for i = maxClassPower + 1, 10 do
            if prbFrame.classPowerSegments[i] then
              prbFrame.classPowerSegments[i]:Hide()
            end
          end
        end
      end
    else
      prbFrame.classPowerBar:Hide()
      for i = 1, 10 do
        if prbFrame.classPowerSegments[i] then
          prbFrame.classPowerSegments[i]:Hide()
        end
      end
    end
    prbFrame:Show()
end
addonTable.UpdatePRB = UpdatePRB
local function UpdatePRBFonts()
  UpdatePRB()
end
addonTable.UpdatePRBFonts = UpdatePRBFonts
local function StartPRBTicker()
  if State.prbTicker then return end
  State.prbTicker = C_Timer.NewTicker(0.1, UpdatePRB)
end
local function StopPRBTicker()
  if State.prbTicker then
    State.prbTicker:Cancel()
    State.prbTicker = nil
  end
end
addonTable.StartPRBTicker = StartPRBTicker
addonTable.StopPRBTicker = StopPRBTicker
local castbarFrame = CreateFrame("Frame", "CCMCastbar", UIParent, "BackdropTemplate")
castbarFrame:SetSize(250, 20)
castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
castbarFrame:SetFrameStrata("MEDIUM")
castbarFrame:SetClampedToScreen(true)
castbarFrame:SetMovable(false)
castbarFrame:EnableMouse(true)
castbarFrame:RegisterForDrag("LeftButton")
castbarFrame:Hide()
addonTable.CastbarFrame = castbarFrame
castbarFrame.bar = CreateFrame("StatusBar", nil, castbarFrame)
castbarFrame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
castbarFrame.bar:SetStatusBarColor(1, 0.7, 0)
castbarFrame.bar:SetAllPoints()
castbarFrame.bg = castbarFrame.bar:CreateTexture(nil, "BACKGROUND")
castbarFrame.bg:SetAllPoints()
castbarFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
castbarFrame.textOverlay = CreateFrame("Frame", nil, castbarFrame)
castbarFrame.textOverlay:SetAllPoints()
castbarFrame.textOverlay:SetFrameLevel(castbarFrame:GetFrameLevel() + 10)
castbarFrame.spellText = castbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5, 0)
castbarFrame.spellText:SetTextColor(1, 1, 1)
castbarFrame.spellText:SetJustifyH("LEFT")
castbarFrame.timeText = castbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5, 0)
castbarFrame.timeText:SetTextColor(1, 1, 1)
castbarFrame.timeText:SetJustifyH("RIGHT")
castbarFrame.icon = CreateFrame("Frame", nil, castbarFrame)
castbarFrame.icon:SetSize(24, 24)
castbarFrame.icon:SetPoint("RIGHT", castbarFrame, "LEFT", -4, 0)
castbarFrame.icon.texture = castbarFrame.icon:CreateTexture(nil, "ARTWORK")
castbarFrame.icon.texture:SetAllPoints()
castbarFrame.icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
castbarFrame.border = CreateFrame("Frame", nil, castbarFrame, "BackdropTemplate")
castbarFrame.border:SetFrameLevel(castbarFrame:GetFrameLevel() + 20)
castbarFrame.border:SetAllPoints()
castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
castbarFrame.ticks = {}
for i = 1, 10 do
  local tick = castbarFrame.bar:CreateTexture(nil, "OVERLAY")
  tick:SetColorTexture(1, 1, 1, 0.8)
  tick:SetSize(2, 1)
  tick:Hide()
  castbarFrame.ticks[i] = tick
end
castbarFrame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 8 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(8) end
  end
  State.castbarDragging = true
  self:StartMoving()
end)
castbarFrame:SetScript("OnDragStop", function(self)
  if not State.castbarDragging then return end
  self:StopMovingOrSizing()
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.castbarX = newX
    profile.castbarY = newY
    if addonTable.UpdateCastbarSliders then addonTable.UpdateCastbarSliders(newX, newY) end
  end
  State.castbarDragging = false
end)
castbarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.castbarDragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(8) end
    end
  end
end)
local castbarTextures = {
  solid = "Interface\\Buttons\\WHITE8x8",
  flat = "Interface\\Buttons\\WHITE8x8",
  blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
  blizzraid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
  smooth = "Interface\\TargetingFrame\\UI-StatusBar-Glow",
  minimalist = "Interface\\ChatFrame\\ChatFrameBackground",
  cilo = "Interface\\TARGETINGFRAME\\UI-TargetingFrame-BarFill",
  glaze = "Interface\\TargetingFrame\\BarFill2",
  steel = "Interface\\TargetingFrame\\UI-TargetingFrame-Fill",
  aluminium = "Interface\\UNITPOWERBARALT\\Metal_Horizontal_Fill",
  metal = "Interface\\UNITPOWERBARALT\\Metal_Horizontal_Fill",
  amber = "Interface\\UNITPOWERBARALT\\Amber_Horizontal_Fill",
  arcane = "Interface\\UNITPOWERBARALT\\Arcane_Horizontal_Fill",
  fire = "Interface\\UNITPOWERBARALT\\Fire_Horizontal_Fill",
  water = "Interface\\UNITPOWERBARALT\\Water_Horizontal_Fill",
  waterdark = "Interface\\UNITPOWERBARALT\\WaterDark_Horizontal_Fill",
  generic = "Interface\\UNITPOWERBARALT\\Generic_Horizontal_Fill",
  round = "Interface\\AchievementFrame\\UI-Achievement-ProgressBar-Fill",
  diagonal = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-HorizontalShadow",
  striped = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
  armory = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",
  gradient = "Interface\\CHARACTERFRAME\\UI-Player-Status-Left",
  otravi = "Interface\\Tooltips\\UI-Tooltip-Background",
  rocks = "Interface\\FrameGeneral\\UI-Background-Rock",
  highlight = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight",
  inner = "Interface\\BUTTONS\\UI-Listbox-Highlight2",
  lite = "Interface\\LFGFRAME\\UI-LFG-SEPARATOR",
  spark = "Interface\\CastingBar\\UI-CastingBar-Spark",
  normtex = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\normTex",
  gloss = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Gloss",
  melli = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Melli",
  mellidark = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\MelliDark",
  betterblizzard = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\BetterBlizzard",
  skyline = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Skyline",
  dragonflight = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Dragonflight",
}
State.castbarActive = false
State.castbarChanneling = false
State.castbarStartTime = 0
State.castbarEndTime = 0
State.castbarDragging = false
State.castbarPreviewMode = false
local channelTickData = {
  [234153] = 6,
  [198590] = 6,
  [755] = 5,
  [5740] = 8,
  [5143] = 5,
  [12051] = 3,
  [205021] = 10,
  [64843] = 4,
  [47540] = 2,
  [204197] = 2,
  [15407] = 4,
  [263165] = 4,
  [48045] = 5,
  [205065] = 4,
  [740] = 4,
  [16914] = 10,
  [61295] = 3,
  [115175] = 8,
  [191837] = 3,
  [382614] = 4,
  [355936] = 3,
  [356995] = 4,
  [361469] = 3,
  [382411] = 4,
  [120360] = 15,
  [257044] = 4,
  [206930] = 3,
  [198013] = 2,
  [258920] = 2,
}
local selfHighlightFrame = CreateFrame("Frame", "CCMSelfHighlight", UIParent)
selfHighlightFrame:SetSize(40, 40)
selfHighlightFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
selfHighlightFrame:SetFrameStrata("TOOLTIP")
selfHighlightFrame:SetFrameLevel(1000)
selfHighlightFrame:Hide()
selfHighlightFrame.lines = {}
for i = 1, 4 do
  selfHighlightFrame.lines[i] = selfHighlightFrame:CreateLine(nil, "OVERLAY")
  selfHighlightFrame.lines[i]:SetColorTexture(1, 1, 1, 1)
end
addonTable.SelfHighlightFrame = selfHighlightFrame
local function UpdateSelfHighlight()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then selfHighlightFrame:Hide(); return end
  local shape = profile.selfHighlightShape or "off"
  if shape == "off" then selfHighlightFrame:Hide(); return end
  local combatOnly = profile.selfHighlightCombatOnly == true
  if combatOnly and not InCombatLockdown() then selfHighlightFrame:Hide(); return end
  local size = profile.selfHighlightSize or 20
  local thickness = profile.selfHighlightThickness or "medium"
  local outline = profile.selfHighlightOutline ~= false
  local r = profile.selfHighlightColorR or 1
  local g = profile.selfHighlightColorG or 1
  local b = profile.selfHighlightColorB or 1
  local a = profile.selfHighlightAlpha or 1
  local yOffset = profile.selfHighlightY or 0
  selfHighlightFrame:SetSize(size, size)
  selfHighlightFrame:ClearAllPoints()
  selfHighlightFrame:SetPoint("CENTER", UIParent, "CENTER", 0, yOffset)
  if shape == "cross" then
    local lineThickness = thickness == "thin" and 1 or (thickness == "thick" and 4 or 2)
    local halfSize = size / 2
    if outline then
      local outlineThickness = lineThickness + 2
      selfHighlightFrame.lines[3]:SetStartPoint("CENTER", -halfSize, 0)
      selfHighlightFrame.lines[3]:SetEndPoint("CENTER", halfSize, 0)
      selfHighlightFrame.lines[3]:SetThickness(outlineThickness)
      selfHighlightFrame.lines[3]:SetColorTexture(0, 0, 0, a)
      selfHighlightFrame.lines[3]:SetDrawLayer("OVERLAY", 0)
      selfHighlightFrame.lines[3]:Show()
      selfHighlightFrame.lines[4]:SetStartPoint("CENTER", 0, -halfSize)
      selfHighlightFrame.lines[4]:SetEndPoint("CENTER", 0, halfSize)
      selfHighlightFrame.lines[4]:SetThickness(outlineThickness)
      selfHighlightFrame.lines[4]:SetColorTexture(0, 0, 0, a)
      selfHighlightFrame.lines[4]:SetDrawLayer("OVERLAY", 0)
      selfHighlightFrame.lines[4]:Show()
    else
      selfHighlightFrame.lines[3]:Hide()
      selfHighlightFrame.lines[4]:Hide()
    end
    selfHighlightFrame.lines[1]:SetStartPoint("CENTER", -halfSize, 0)
    selfHighlightFrame.lines[1]:SetEndPoint("CENTER", halfSize, 0)
    selfHighlightFrame.lines[1]:SetThickness(lineThickness)
    selfHighlightFrame.lines[1]:SetColorTexture(r, g, b, a)
    selfHighlightFrame.lines[1]:SetDrawLayer("OVERLAY", 1)
    selfHighlightFrame.lines[1]:Show()
    selfHighlightFrame.lines[2]:SetStartPoint("CENTER", 0, -halfSize)
    selfHighlightFrame.lines[2]:SetEndPoint("CENTER", 0, halfSize)
    selfHighlightFrame.lines[2]:SetThickness(lineThickness)
    selfHighlightFrame.lines[2]:SetColorTexture(r, g, b, a)
    selfHighlightFrame.lines[2]:SetDrawLayer("OVERLAY", 1)
    selfHighlightFrame.lines[2]:Show()
    selfHighlightFrame:Show()
  end
end
addonTable.UpdateSelfHighlight = UpdateSelfHighlight
local selfHighlightTicker = nil
local function StartSelfHighlightTicker()
  if selfHighlightTicker then return end
  selfHighlightTicker = C_Timer.NewTicker(0.1, function()
    if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
  end)
end
local function StopSelfHighlightTicker()
  if selfHighlightTicker then
    selfHighlightTicker:Cancel()
    selfHighlightTicker = nil
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile and profile.selfHighlightCombatOnly then
    selfHighlightFrame:Hide()
  end
end
addonTable.StartSelfHighlightTicker = StartSelfHighlightTicker
addonTable.StopSelfHighlightTicker = StopSelfHighlightTicker
local noTargetAlertFrame = CreateFrame("Frame", "CCMNoTargetAlert", UIParent)
noTargetAlertFrame:SetSize(300, 50)
noTargetAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
noTargetAlertFrame:SetFrameStrata("HIGH")
noTargetAlertFrame:Hide()
noTargetAlertFrame.text = noTargetAlertFrame:CreateFontString(nil, "OVERLAY")
noTargetAlertFrame.text:SetPoint("CENTER")
noTargetAlertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
noTargetAlertFrame.text:SetText("NO TARGET")
noTargetAlertFrame.text:SetTextColor(1, 0, 0, 1)
addonTable.NoTargetAlertFrame = noTargetAlertFrame
State.noTargetAlertFlashActive = false
State.noTargetAlertFlashTime = 0
addonTable.CombatTimerFrame = CreateFrame("Frame", "CCMCombatTimer", UIParent, "BackdropTemplate")
addonTable.CombatTimerFrame:SetSize(96, 34)
addonTable.CombatTimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
addonTable.CombatTimerFrame:SetFrameStrata("HIGH")
addonTable.CombatTimerFrame:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  edgeSize = 1
})
addonTable.CombatTimerFrame:SetBackdropColor(0.12, 0.12, 0.12, 0.85)
addonTable.CombatTimerFrame:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
addonTable.CombatTimerFrame.text = addonTable.CombatTimerFrame:CreateFontString(nil, "OVERLAY")
addonTable.CombatTimerFrame.text:SetPoint("CENTER")
addonTable.CombatTimerFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
addonTable.CombatTimerFrame.text:SetTextColor(1, 1, 1, 1)
addonTable.CombatTimerFrame.text:SetText("00:00.0")
addonTable.CombatTimerFrame:SetMovable(true)
addonTable.CombatTimerFrame:EnableMouse(true)
addonTable.CombatTimerFrame:SetClampedToScreen(true)
addonTable.CombatTimerFrame:RegisterForDrag("LeftButton")
addonTable.CombatTimerFrame:SetScript("OnDragStart", function(self)
  local guiOpen = addonTable.GetGUIOpen and addonTable.GetGUIOpen()
  local activeTab = addonTable.activeTab and addonTable.activeTab()
  if not guiOpen or activeTab ~= 11 then return end
  self:StartMoving()
end)
addonTable.CombatTimerFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local scale = UIParent:GetEffectiveScale() or 1
    local rx = (centerX - parentCenterX) * scale
    local ry = (centerY - parentCenterY) * scale
    local centered = profile.combatTimerCentered == true
    profile.combatTimerX = centered and 0 or ((rx >= 0) and math.floor(rx + 0.5) or math.ceil(rx - 0.5))
    profile.combatTimerY = (ry >= 0) and math.floor(ry + 0.5) or math.ceil(ry - 0.5)
    if addonTable.UpdateCombatTimerSliders then
      addonTable.UpdateCombatTimerSliders(profile.combatTimerX, profile.combatTimerY)
    end
    if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  end
end)
addonTable.CombatTimerFrame:Hide()
State.combatTimerStart = 0
State.combatTimerElapsed = 0
State.combatTimerActive = false
State.combatTimerTicker = nil
local function ApplyCombatTimerStyle(style)
  local frame = addonTable.CombatTimerFrame
  if not frame or not frame.text then return end
  if style == "minimal" then
    frame:SetSize(128, 44)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", 34, "OUTLINE")
    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER")
  else
    frame:SetSize(96, 34)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER")
  end
end
function addonTable.UpdateCombatTimer()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.CombatTimerFrame
  if not frame then return end
  if not profile or profile.combatTimerEnabled ~= true then
    if addonTable.StopCombatTimerTicker then addonTable.StopCombatTimerTicker() end
    frame:Hide()
    return
  end
  local x = type(profile.combatTimerX) == "number" and profile.combatTimerX or 0
  local y = type(profile.combatTimerY) == "number" and profile.combatTimerY or 200
  local centered = profile.combatTimerCentered == true
  local scale = type(profile.combatTimerScale) == "number" and profile.combatTimerScale or 1
  local tr = type(profile.combatTimerTextColorR) == "number" and profile.combatTimerTextColorR or 1
  local tg = type(profile.combatTimerTextColorG) == "number" and profile.combatTimerTextColorG or 1
  local tb = type(profile.combatTimerTextColorB) == "number" and profile.combatTimerTextColorB or 1
  local br = type(profile.combatTimerBgColorR) == "number" and profile.combatTimerBgColorR or 0.12
  local bg = type(profile.combatTimerBgColorG) == "number" and profile.combatTimerBgColorG or 0.12
  local bb = type(profile.combatTimerBgColorB) == "number" and profile.combatTimerBgColorB or 0.12
  local ba = type(profile.combatTimerBgAlpha) == "number" and profile.combatTimerBgAlpha or 0.85
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", centered and 0 or x, y)
  frame:SetScale(scale)
  local style = profile.combatTimerStyle == "minimal" and "minimal" or "boxed"
  ApplyCombatTimerStyle(style)
  if style == "minimal" then
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
  else
    frame:SetBackdropColor(br, bg, bb, ba)
    frame:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
  end
  frame.text:SetTextColor(tr, tg, tb, 1)
  local mode = profile.combatTimerMode == "always" and "always" or "combat"
  local shouldShow = (mode == "always") or State.combatTimerActive
  local qolTab = addonTable.TAB_QOL or 11
  local draggable = (addonTable.GetGUIOpen and addonTable.GetGUIOpen()) and (addonTable.activeTab and addonTable.activeTab() == qolTab)
  frame:EnableMouse(draggable)
  if shouldShow then
    frame:Show()
    if addonTable.StartCombatTimerTicker then addonTable.StartCombatTimerTicker() end
  else
    frame:Hide()
    if addonTable.StopCombatTimerTicker then addonTable.StopCombatTimerTicker() end
  end
end
function addonTable.RefreshCombatTimerText()
  local frame = addonTable.CombatTimerFrame
  if not frame or not frame.text then return end
  local elapsed = State.combatTimerElapsed or 0
  if State.combatTimerActive and State.combatTimerStart and State.combatTimerStart > 0 then
    elapsed = GetTime() - State.combatTimerStart
    if elapsed < 0 then elapsed = 0 end
    State.combatTimerElapsed = elapsed
  end
  local minutes = math.floor(elapsed / 60)
  local seconds = elapsed - (minutes * 60)
  frame.text:SetText(string.format("%02d:%04.1f", minutes, seconds))
end
function addonTable.StartCombatTimerTicker()
  if State.combatTimerTicker then return end
  State.combatTimerTicker = C_Timer.NewTicker(0.05, function()
    if addonTable.RefreshCombatTimerText then addonTable.RefreshCombatTimerText() end
  end)
end
function addonTable.StopCombatTimerTicker()
  if State.combatTimerTicker then
    State.combatTimerTicker:Cancel()
    State.combatTimerTicker = nil
  end
end
function addonTable.SetCombatTimerActive(active)
  if active then
    State.combatTimerActive = true
    State.combatTimerStart = GetTime()
    State.combatTimerElapsed = 0
    if addonTable.StartCombatTimerTicker then addonTable.StartCombatTimerTicker() end
  else
    if State.combatTimerActive and State.combatTimerStart and State.combatTimerStart > 0 then
      local elapsed = GetTime() - State.combatTimerStart
      if elapsed > 0 then
        State.combatTimerElapsed = elapsed
      end
    end
    State.combatTimerActive = false
    State.combatTimerStart = 0
  end
  if addonTable.RefreshCombatTimerText then addonTable.RefreshCombatTimerText() end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
end
addonTable.crTimerFrame = CreateFrame("Frame", "CCMCRTimer", UIParent)
addonTable.crTimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
addonTable.crTimerFrame:SetSize(180, 42)
addonTable.crTimerFrame:SetFrameStrata("HIGH")
addonTable.crTimerFrame:SetMovable(true)
addonTable.crTimerFrame:EnableMouse(true)
addonTable.crTimerFrame:SetClampedToScreen(true)
addonTable.crTimerFrame:RegisterForDrag("LeftButton")
addonTable.crTimerFrame.crText = addonTable.crTimerFrame:CreateFontString(nil, "OVERLAY")
addonTable.crTimerFrame.crText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
addonTable.crTimerFrame.crText:SetTextColor(1, 1, 1, 1)
addonTable.crTimerFrame.blText = addonTable.crTimerFrame:CreateFontString(nil, "OVERLAY")
addonTable.crTimerFrame.blText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
addonTable.crTimerFrame.blText:SetTextColor(1, 1, 1, 1)
addonTable.crTimerFrame:SetScript("OnDragStart", function(self)
  local guiOpen = addonTable.GetGUIOpen and addonTable.GetGUIOpen()
  local activeTab = addonTable.activeTab and addonTable.activeTab()
  if not guiOpen or activeTab ~= 11 then return end
  self:StartMoving()
end)
addonTable.crTimerFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local scale = UIParent:GetEffectiveScale() or 1
    local rx = (centerX - parentCenterX) * scale
    local ry = (centerY - parentCenterY) * scale
    profile.crTimerX = (profile.crTimerCentered == true) and 0 or ((rx >= 0) and math.floor(rx + 0.5) or math.ceil(rx - 0.5))
    profile.crTimerY = (ry >= 0) and math.floor(ry + 0.5) or math.ceil(ry - 0.5)
    if addonTable.UpdateCRTimerSliders then addonTable.UpdateCRTimerSliders(profile.crTimerX, profile.crTimerY) end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  end
end)
addonTable.crTimerFrame:Hide()
addonTable.CombatStatusFrame = CreateFrame("Frame", "CCMCombatStatus", UIParent)
addonTable.CombatStatusFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 280)
addonTable.CombatStatusFrame:SetSize(360, 40)
addonTable.CombatStatusFrame:SetFrameStrata("HIGH")
addonTable.CombatStatusFrame:SetMovable(true)
addonTable.CombatStatusFrame:EnableMouse(true)
addonTable.CombatStatusFrame:SetClampedToScreen(true)
addonTable.CombatStatusFrame:RegisterForDrag("LeftButton")
addonTable.CombatStatusFrame.text = addonTable.CombatStatusFrame:CreateFontString(nil, "OVERLAY")
addonTable.CombatStatusFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")
addonTable.CombatStatusFrame.text:SetPoint("CENTER")
addonTable.CombatStatusFrame.text:SetTextColor(1, 1, 1, 1)
addonTable.CombatStatusFrame.text:SetText("* Entering Combat *")
addonTable.CombatStatusFrame:SetScript("OnDragStart", function(self)
  local guiOpen = addonTable.GetGUIOpen and addonTable.GetGUIOpen()
  local activeTab = addonTable.activeTab and addonTable.activeTab()
  if not guiOpen or activeTab ~= 11 then return end
  self:StartMoving()
end)
addonTable.CombatStatusFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local scale = UIParent:GetEffectiveScale() or 1
    local rx = (centerX - parentCenterX) * scale
    local ry = (centerY - parentCenterY) * scale
    profile.combatStatusX = (profile.combatStatusCentered == true) and 0 or ((rx >= 0) and math.floor(rx + 0.5) or math.ceil(rx - 0.5))
    profile.combatStatusY = (ry >= 0) and math.floor(ry + 0.5) or math.ceil(ry - 0.5)
    if addonTable.UpdateCombatStatusSliders then addonTable.UpdateCombatStatusSliders(profile.combatStatusX, profile.combatStatusY) end
    if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  end
end)
addonTable.CombatStatusFrame:Hide()
local function SetCombatStatusText(isEntering)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.CombatStatusFrame
  if not profile or not frame or not frame.text then return end
  local r, g, b
  if isEntering then
    r = profile.combatStatusEnterColorR or 1
    g = profile.combatStatusEnterColorG or 1
    b = profile.combatStatusEnterColorB or 1
    frame.text:SetText("* Entering Combat *")
  else
    r = profile.combatStatusLeaveColorR or 1
    g = profile.combatStatusLeaveColorG or 1
    b = profile.combatStatusLeaveColorB or 1
    frame.text:SetText("* Leaving Combat *")
  end
  frame.text:SetTextColor(r, g, b, 1)
  State.combatStatusLastEntering = isEntering and true or false
end
function addonTable.UpdateCombatStatus()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.CombatStatusFrame
  if not profile or not frame or not frame.text then return end
  if profile.combatStatusEnabled ~= true and not State.combatStatusPreviewMode then
    frame:Hide()
    return
  end
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", profile.combatStatusCentered == true and 0 or (profile.combatStatusX or 0), profile.combatStatusY or 280)
  frame:SetScale(type(profile.combatStatusScale) == "number" and profile.combatStatusScale or 1)
  SetCombatStatusText(State.combatStatusLastEntering ~= false)
  local qolTab = addonTable.TAB_QOL or 11
  local draggable = (addonTable.GetGUIOpen and addonTable.GetGUIOpen()) and (addonTable.activeTab and addonTable.activeTab() == qolTab)
  frame:EnableMouse(draggable)
  if State.combatStatusPreviewMode then
    frame:Show()
  end
end
function addonTable.ShowCombatStatusPreview()
  State.combatStatusPreviewMode = true
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  SetCombatStatusText(true)
  if addonTable.CombatStatusFrame then addonTable.CombatStatusFrame:Show() end
end
function addonTable.StopCombatStatusPreview()
  State.combatStatusPreviewMode = false
  if addonTable.CombatStatusFrame then addonTable.CombatStatusFrame:Hide() end
end
function addonTable.ShowCombatStatusMessage(isEntering)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.CombatStatusFrame
  if not profile or not frame or not frame.text then return end
  if profile.combatStatusEnabled ~= true then return end
  if State.combatStatusPreviewMode then return end
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  SetCombatStatusText(isEntering)
  frame:Show()
  State.combatStatusMessageToken = (State.combatStatusMessageToken or 0) + 1
  local token = State.combatStatusMessageToken
  C_Timer.After(1.5, function()
    if State.combatStatusMessageToken ~= token then return end
    if frame then frame:Hide() end
  end)
end
local BL_AURA_IDS = {2825, 32182, 80353, 264667, 390386, 381301}
local BL_DEBUFF_IDS = {57724, 57723, 80354, 264689, 390435}
local function FormatMMSS(seconds)
  local s = tonumber(seconds) or 0
  if s < 0 then s = 0 end
  local m = math.floor(s / 60)
  local r = math.floor(s - (m * 60))
  return string.format("%d:%02d", m, r)
end
local function GetPlayerAuraRemainingByIDs(idList)
  if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return 0 end
  local now = GetTime()
  local bestRemaining = 0
  for i = 1, #idList do
    local okAura, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, idList[i])
    if okAura and aura and aura.expirationTime then
      local okExp, exp = pcall(tonumber, aura.expirationTime)
      if okExp and type(exp) == "number" and exp > 0 then
        local rem = exp - now
        if rem > bestRemaining then bestRemaining = rem end
      end
    end
  end
  return bestRemaining
end
function addonTable.RefreshCRTimerText()
  local frame = addonTable.crTimerFrame
  if not frame or not frame.crText then return end
  local charges = 0
  local crTimeText = "READY"
  local chargesInfo = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(20484)
  if chargesInfo then
    local okCharges, currentCharges = pcall(tonumber, chargesInfo.currentCharges)
    if okCharges and type(currentCharges) == "number" then charges = currentCharges end
    local okStart, startTime = pcall(tonumber, chargesInfo.cooldownStartTime)
    local okDur, duration = pcall(tonumber, chargesInfo.cooldownDuration)
    if okStart and okDur and type(startTime) == "number" and type(duration) == "number" and startTime > 0 and duration > 0 then
      local rem = (startTime + duration) - GetTime()
      if rem > 0 then crTimeText = FormatMMSS(rem) end
    end
  end
  frame.crText:SetText(string.format("CR: |cffFFFFFF%d|r / |cffFFFFFF%s|r", charges, crTimeText))
  if frame.blText then
    frame.blText:Hide()
  end
end
function addonTable.UpdateCRTimer()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.crTimerFrame
  if not profile or not frame then return end
  if profile.crTimerEnabled ~= true then
    frame:Hide()
    if addonTable.StopCRTimerTicker then addonTable.StopCRTimerTicker() end
    return
  end
  local mode = profile.crTimerMode == "always" and "always" or "combat"
  local shouldShow = (mode == "always") or UnitAffectingCombat("player")
  if not shouldShow then
    frame:Hide()
    if addonTable.StopCRTimerTicker then addonTable.StopCRTimerTicker() end
    return
  end
  local scale = type(profile.crTimerScale) == "number" and profile.crTimerScale or 1
  frame:SetScale(scale)
  frame:ClearAllPoints()
  local centered = profile.crTimerCentered == true
  local ox = centered and 0 or (profile.crTimerX or 0)
  local oy = profile.crTimerY or 150
  frame:SetPoint("CENTER", UIParent, "CENTER", ox / scale, oy / scale)
  local vertical = profile.crTimerLayout ~= "horizontal"
  frame.crText:ClearAllPoints()
  if frame.blText then
    frame.blText:ClearAllPoints()
    frame.blText:Hide()
  end
  if vertical then
    frame.crText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame:SetSize(190, 26)
  else
    frame.crText:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame:SetSize(190, 26)
  end
  local qolTab = addonTable.TAB_QOL or 11
  local draggable = (addonTable.GetGUIOpen and addonTable.GetGUIOpen()) and (addonTable.activeTab and addonTable.activeTab() == qolTab)
  frame:EnableMouse(draggable)
  if addonTable.RefreshCRTimerText then addonTable.RefreshCRTimerText() end
  frame:Show()
  if addonTable.StartCRTimerTicker then addonTable.StartCRTimerTicker() end
end
function addonTable.StartCRTimerTicker()
  if State.crTimerTicker then return end
  State.crTimerTicker = C_Timer.NewTicker(0.2, function()
    if addonTable.RefreshCRTimerText then addonTable.RefreshCRTimerText() end
  end)
end
function addonTable.StopCRTimerTicker()
  if State.crTimerTicker then
    State.crTimerTicker:Cancel()
    State.crTimerTicker = nil
  end
end
local function StartNoTargetAlertFlash()
  if State.noTargetAlertFlashActive then return end
  State.noTargetAlertFlashActive = true
  State.noTargetAlertFlashTime = 0
  noTargetAlertFrame:SetScript("OnUpdate", function(self, elapsed)
    if not State.noTargetAlertFlashActive then return end
    State.noTargetAlertFlashTime = State.noTargetAlertFlashTime + elapsed
    local alpha = 0.55 + 0.45 * math.cos(State.noTargetAlertFlashTime * math.pi * 2)
    noTargetAlertFrame.text:SetAlpha(alpha)
  end)
end
local function StopNoTargetAlertFlash()
  State.noTargetAlertFlashActive = false
  noTargetAlertFrame:SetScript("OnUpdate", nil)
  noTargetAlertFrame.text:SetAlpha(1)
end
local function UpdateNoTargetAlert()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.noTargetAlertEnabled then
    if not State.noTargetAlertPreviewMode then
      noTargetAlertFrame:Hide()
      StopNoTargetAlertFlash()
    end
    return
  end
  if State.noTargetAlertPreviewMode then return end
  local x = profile.noTargetAlertX or 0
  local y = profile.noTargetAlertY or 100
  local fontSize = profile.noTargetAlertFontSize or 36
  local r = profile.noTargetAlertColorR or 1
  local g = profile.noTargetAlertColorG or 0
  local b = profile.noTargetAlertColorB or 0
  noTargetAlertFrame:ClearAllPoints()
  noTargetAlertFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
  local globalFont, globalOutline = GetGlobalFont()
  noTargetAlertFrame.text:SetFont(globalFont, fontSize, globalOutline ~= "" and globalOutline or "OUTLINE")
  noTargetAlertFrame.text:SetTextColor(r, g, b, 1)
  local inCombat = InCombatLockdown()
  local hasTarget = UnitExists("target")
  if inCombat and not hasTarget then
    noTargetAlertFrame:Show()
    if profile.noTargetAlertFlash then
      StartNoTargetAlertFlash()
    else
      StopNoTargetAlertFlash()
    end
  else
    noTargetAlertFrame:Hide()
    StopNoTargetAlertFlash()
  end
end
addonTable.UpdateNoTargetAlert = UpdateNoTargetAlert
local function ShowNoTargetAlertPreview()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local x = profile.noTargetAlertX or 0
  local y = profile.noTargetAlertY or 100
  local fontSize = profile.noTargetAlertFontSize or 36
  local r = profile.noTargetAlertColorR or 1
  local g = profile.noTargetAlertColorG or 0
  local b = profile.noTargetAlertColorB or 0
  noTargetAlertFrame:ClearAllPoints()
  noTargetAlertFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
  local globalFont, globalOutline = GetGlobalFont()
  noTargetAlertFrame.text:SetFont(globalFont, fontSize, globalOutline ~= "" and globalOutline or "OUTLINE")
  noTargetAlertFrame.text:SetTextColor(r, g, b, 1)
  State.noTargetAlertPreviewMode = true
  noTargetAlertFrame:Show()
  if profile.noTargetAlertFlash then
    StartNoTargetAlertFlash()
  else
    StopNoTargetAlertFlash()
  end
end
addonTable.ShowNoTargetAlertPreview = ShowNoTargetAlertPreview
local function StopNoTargetAlertPreview()
  State.noTargetAlertPreviewMode = false
  StopNoTargetAlertFlash()
  UpdateNoTargetAlert()
end
addonTable.StopNoTargetAlertPreview = StopNoTargetAlertPreview
local function UpdateNoTargetAlertPreviewIfActive()
  if State.noTargetAlertPreviewMode then
    ShowNoTargetAlertPreview()
  end
end
addonTable.UpdateNoTargetAlertPreviewIfActive = UpdateNoTargetAlertPreviewIfActive
local noTargetEventFrame = CreateFrame("Frame")
noTargetEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
noTargetEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
noTargetEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
noTargetEventFrame:SetScript("OnEvent", function(self, event)
  if addonTable.UpdateNoTargetAlert then addonTable.UpdateNoTargetAlert() end
  if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile and profile.selfHighlightCombatOnly and profile.selfHighlightShape ~= "off" then
    if event == "PLAYER_REGEN_DISABLED" then
      if addonTable.StartSelfHighlightTicker then addonTable.StartSelfHighlightTicker() end
    elseif event == "PLAYER_REGEN_ENABLED" then
      if addonTable.StopSelfHighlightTicker then addonTable.StopSelfHighlightTicker() end
    end
  end
end)
local function UpdateCastbar()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useCastbar then
    if not State.castbarPreviewMode then
      castbarFrame:Hide()
    end
    return
  end
  if State.castbarPreviewMode then
    local width = type(profile.castbarWidth) == "number" and profile.castbarWidth or 250
    local borderSize = type(profile.castbarBorderSize) == "number" and profile.castbarBorderSize or 1
    local autoWidthSource = profile.castbarAutoWidthSource or "off"
    if autoWidthSource ~= "off" then
      if autoWidthSource == "essential" then
        local widthFromEss = 0
        if profile.useEssentialBar and State.cachedEssentialBarWidth and State.cachedEssentialBarWidth > 0 then
          widthFromEss = State.cachedEssentialBarWidth
        else
          local essBar = EssentialCooldownViewer
          if essBar and essBar:IsShown() then
            local w = essBar:GetWidth()
            if w and w > 0 then
              local scale = essBar.GetEffectiveScale and essBar:GetEffectiveScale() or 1
              local parentScale = UIParent:GetEffectiveScale()
              if parentScale and parentScale > 0 then
                widthFromEss = w * (scale / parentScale)
              else
                widthFromEss = w
              end
            end
          end
          if widthFromEss <= 0 and State.standaloneEssentialWidth and State.standaloneEssentialWidth > 0 then
            widthFromEss = State.standaloneEssentialWidth
          end
        end
        if widthFromEss > 0 then
          width = widthFromEss
          if width < 20 then width = 20 end
        end
      elseif autoWidthSource == "utility" then
        local widthFromUtility = 0
        local utilityBar = UtilityCooldownViewer
        if utilityBar and utilityBar:IsShown() then
          local w = utilityBar:GetWidth()
          if w and w > 0 then
            local scale = utilityBar.GetEffectiveScale and utilityBar:GetEffectiveScale() or 1
            local parentScale = UIParent:GetEffectiveScale()
            if parentScale and parentScale > 0 then
              widthFromUtility = w * (scale / parentScale)
            else
              widthFromUtility = w
            end
          end
        end
        if widthFromUtility > 0 then
          width = widthFromUtility
          if width < 20 then width = 20 end
        end
      elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" then
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
          if width < 20 then width = 20 end
        end
      elseif autoWidthSource == "prbhealth" or autoWidthSource == "prbpower" then
        local prbWidth = profile.prbWidth or 220
        local prbAutoWidth = profile.prbAutoWidthSource or "off"
        if prbAutoWidth ~= "off" then
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
              prbWidth = (maxX - minX) - (borderSize * 2)
              if prbWidth < 20 then prbWidth = 20 end
            end
          end
        end
        width = prbWidth
      end
    end
    local height = type(profile.castbarHeight) == "number" and profile.castbarHeight or 20
    local centered = profile.castbarCentered == true
    local showIcon = profile.castbarShowIcon ~= false
    local iconSize = height
    local posX
    if centered then
      posX = showIcon and (iconSize / 2) or 0
    else
      posX = type(profile.castbarX) == "number" and profile.castbarX or 0
    end
    local posY = type(profile.castbarY) == "number" and profile.castbarY or -250
    if autoWidthSource ~= "off" and showIcon then
      width = width - iconSize
      if width < 20 then width = 20 end
    end
    width = math.floor(width)
    local bgAlpha = (type(profile.castbarBgAlpha) == "number" and profile.castbarBgAlpha or 70) / 100
    local showTime = profile.castbarShowTime ~= false
    local showSpellName = profile.castbarShowSpellName ~= false
    local timeScale = type(profile.castbarTimeScale) == "number" and profile.castbarTimeScale or 1.0
    local spellNameScale = type(profile.castbarSpellNameScale) == "number" and profile.castbarSpellNameScale or 1.0
    local spellNameX = type(profile.castbarSpellNameXOffset) == "number" and profile.castbarSpellNameXOffset or 0
    local spellNameY = type(profile.castbarSpellNameYOffset) == "number" and profile.castbarSpellNameYOffset or 0
    local timeX = type(profile.castbarTimeXOffset) == "number" and profile.castbarTimeXOffset or 0
    local timeY = type(profile.castbarTimeYOffset) == "number" and profile.castbarTimeYOffset or 0
    local timePrecision = profile.castbarTimePrecision or "1"
    local textR = profile.castbarTextColorR or 1
    local textG = profile.castbarTextColorG or 1
    local textB = profile.castbarTextColorB or 1
    local texturePath = castbarTextures[profile.castbarTexture] or castbarTextures.solid
    castbarFrame.bar:SetStatusBarTexture(texturePath)
    local r, g, b
    if profile.castbarUseClassColor then
      r, g, b = GetClassColor()
    else
      r = profile.castbarColorR or 1
      g = profile.castbarColorG or 0.7
      b = profile.castbarColorB or 0
    end
    castbarFrame.bar:SetStatusBarColor(r, g, b)
    PixelUtil.SetSize(castbarFrame, width, height)
    if not State.castbarDragging then
      castbarFrame:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame, "CENTER", UIParent, "CENTER", posX, posY)
    end
    local bgR = profile.castbarBgColorR or 0.1
    local bgG = profile.castbarBgColorG or 0.1
    local bgB = profile.castbarBgColorB or 0.1
    castbarFrame.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
    if showIcon then
      PixelUtil.SetSize(castbarFrame.icon, iconSize, iconSize)
      castbarFrame.icon:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame.icon, "RIGHT", castbarFrame, "LEFT", 0, 0)
      castbarFrame.icon:Show()
    else
      castbarFrame.icon:Hide()
    end
    if borderSize > 0 then
      castbarFrame.border:ClearAllPoints()
      if showIcon then
        castbarFrame.border:SetPoint("TOPLEFT", castbarFrame.icon, "TOPLEFT", 0, 0)
        castbarFrame.border:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 0, 0)
      else
        castbarFrame.border:SetAllPoints(castbarFrame)
      end
      castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
      castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
      castbarFrame.border:Show()
    else
      castbarFrame.border:Hide()
    end
    local globalFont, globalOutline = GetGlobalFont()
    if showSpellName then
      castbarFrame.spellText:ClearAllPoints()
      castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5 + spellNameX, spellNameY)
      castbarFrame.spellText:SetTextColor(textR, textG, textB)
      castbarFrame.spellText:SetScale(spellNameScale)
      castbarFrame.spellText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      castbarFrame.spellText:Show()
    else
      castbarFrame.spellText:Hide()
    end
    if showTime then
      castbarFrame.timeText:ClearAllPoints()
      castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5 + timeX, timeY)
      local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
      castbarFrame.timeText:SetText(string.format(timeFormat, 1.5))
      castbarFrame.timeText:SetTextColor(textR, textG, textB)
      castbarFrame.timeText:SetScale(timeScale)
      castbarFrame.timeText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      castbarFrame.timeText:Show()
    else
      castbarFrame.timeText:Hide()
    end
    for i = 1, 10 do
      castbarFrame.ticks[i]:Hide()
    end
    return
  end
  local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo("player")
  local isChanneling = false
  if not name then
    name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellID = UnitChannelInfo("player")
    isChanneling = name ~= nil
  end
  if not name then
    castbarFrame:Hide()
    State.castbarActive = false
    State.castbarTickKey = nil
    castbarFrame._fallbackSpellID = nil
    castbarFrame._fallbackChanneling = nil
    castbarFrame._fallbackStart = nil
    castbarFrame._fallbackDuration = nil
    castbarFrame.spellText._lastText = nil
    castbarFrame.icon.texture._lastTexture = nil
    for i = 1, 10 do
      castbarFrame.ticks[i]:Hide()
    end
    return
  end
  local width = type(profile.castbarWidth) == "number" and profile.castbarWidth or 250
  local borderSize = type(profile.castbarBorderSize) == "number" and profile.castbarBorderSize or 1
  local autoWidthSource = profile.castbarAutoWidthSource or "off"
  if autoWidthSource ~= "off" then
    if autoWidthSource == "essential" then
      local widthFromEss = 0
      if profile.useEssentialBar and State.cachedEssentialBarWidth and State.cachedEssentialBarWidth > 0 then
        widthFromEss = State.cachedEssentialBarWidth
      else
        local essBar = EssentialCooldownViewer
        if essBar and essBar:IsShown() then
          local w = essBar:GetWidth()
          if w and w > 0 then
            local scale = essBar.GetEffectiveScale and essBar:GetEffectiveScale() or 1
            local parentScale = UIParent:GetEffectiveScale()
            if parentScale and parentScale > 0 then
              widthFromEss = w * (scale / parentScale)
            else
              widthFromEss = w
            end
          end
        end
        if widthFromEss <= 0 and State.standaloneEssentialWidth and State.standaloneEssentialWidth > 0 then
          widthFromEss = State.standaloneEssentialWidth
        end
      end
      if widthFromEss > 0 then
        width = widthFromEss
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "utility" then
      local widthFromUtility = 0
      local utilityBar = UtilityCooldownViewer
      if utilityBar and utilityBar:IsShown() then
        local w = utilityBar:GetWidth()
        if w and w > 0 then
          local scale = utilityBar.GetEffectiveScale and utilityBar:GetEffectiveScale() or 1
          local parentScale = UIParent:GetEffectiveScale()
          if parentScale and parentScale > 0 then
            widthFromUtility = w * (scale / parentScale)
          else
            widthFromUtility = w
          end
        end
      end
      if widthFromUtility > 0 then
        width = widthFromUtility
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" then
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
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "prbhealth" or autoWidthSource == "prbpower" then
      local prbWidth = profile.prbWidth or 220
      local prbAutoWidth = profile.prbAutoWidthSource or "off"
      if prbAutoWidth ~= "off" then
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
            prbWidth = (maxX - minX) - (borderSize * 2)
            if prbWidth < 20 then prbWidth = 20 end
          end
        end
      end
      width = prbWidth
    end
  end
  local height = type(profile.castbarHeight) == "number" and profile.castbarHeight or 20
  local centered = profile.castbarCentered == true
  local showIcon = profile.castbarShowIcon ~= false
  local iconSize = height
  local posX
  if centered then
    posX = showIcon and (iconSize / 2) or 0
  else
    posX = type(profile.castbarX) == "number" and profile.castbarX or 0
  end
  local posY = type(profile.castbarY) == "number" and profile.castbarY or -250
  if autoWidthSource ~= "off" and showIcon then
    width = width - iconSize
    if width < 20 then width = 20 end
  end
  width = math.floor(width)
  local bgAlpha = (type(profile.castbarBgAlpha) == "number" and profile.castbarBgAlpha or 70) / 100
  local showTime = profile.castbarShowTime ~= false
  local showSpellName = profile.castbarShowSpellName ~= false
  local timeScale = type(profile.castbarTimeScale) == "number" and profile.castbarTimeScale or 1.0
  local spellNameScale = type(profile.castbarSpellNameScale) == "number" and profile.castbarSpellNameScale or 1.0
  local spellNameX = type(profile.castbarSpellNameXOffset) == "number" and profile.castbarSpellNameXOffset or 0
  local spellNameY = type(profile.castbarSpellNameYOffset) == "number" and profile.castbarSpellNameYOffset or 0
  local timeX = type(profile.castbarTimeXOffset) == "number" and profile.castbarTimeXOffset or 0
  local timeY = type(profile.castbarTimeYOffset) == "number" and profile.castbarTimeYOffset or 0
  local timePrecision = profile.castbarTimePrecision or "1"
  local textR = profile.castbarTextColorR or 1
  local textG = profile.castbarTextColorG or 1
  local textB = profile.castbarTextColorB or 1
  local texturePath = castbarTextures[profile.castbarTexture] or castbarTextures.solid
  local castIconShown = showIcon and texture
  local r, g, b
  if profile.castbarUseClassColor then
    r, g, b = GetClassColor()
  else
    r = profile.castbarColorR or 1
    g = profile.castbarColorG or 0.7
    b = profile.castbarColorB or 0
  end
  local bgR = profile.castbarBgColorR or 0.1
  local bgG = profile.castbarBgColorG or 0.1
  local bgB = profile.castbarBgColorB or 0.1
  local layoutKey = table.concat({
    width, height, posX, posY, autoWidthSource, borderSize, castIconShown and 1 or 0, iconSize,
    texturePath, r, g, b, bgR, bgG, bgB, bgAlpha,
    showSpellName and 1 or 0, spellNameScale, spellNameX, spellNameY,
    showTime and 1 or 0, timeScale, timeX, timeY, timePrecision, textR, textG, textB
  }, "|")
  if State.castbarLayoutKey ~= layoutKey then
    State.castbarLayoutKey = layoutKey
    castbarFrame.bar:SetStatusBarTexture(texturePath)
    castbarFrame.bar:SetStatusBarColor(r, g, b)
    PixelUtil.SetSize(castbarFrame, width, height)
    if not State.castbarDragging then
      castbarFrame:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame, "CENTER", UIParent, "CENTER", posX, posY)
    end
    castbarFrame.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
    if castIconShown then
      PixelUtil.SetSize(castbarFrame.icon, iconSize, iconSize)
      castbarFrame.icon:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame.icon, "RIGHT", castbarFrame, "LEFT", 0, 0)
      castbarFrame.icon:Show()
    else
      castbarFrame.icon:Hide()
    end
    if borderSize > 0 then
      castbarFrame.border:ClearAllPoints()
      if castIconShown then
        castbarFrame.border:SetPoint("TOPLEFT", castbarFrame.icon, "TOPLEFT", 0, 0)
        castbarFrame.border:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 0, 0)
      else
        castbarFrame.border:SetAllPoints(castbarFrame)
      end
      castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
      castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
      castbarFrame.border:Show()
    else
      castbarFrame.border:Hide()
    end
    local globalFont, globalOutline = GetGlobalFont()
    if showSpellName then
      castbarFrame.spellText:ClearAllPoints()
      castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5 + spellNameX, spellNameY)
      castbarFrame.spellText:SetTextColor(textR, textG, textB)
      castbarFrame.spellText:SetScale(spellNameScale)
      castbarFrame.spellText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      castbarFrame.spellText:Show()
    else
      castbarFrame.spellText:Hide()
    end
    if showTime then
      castbarFrame.timeText:ClearAllPoints()
      castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5 + timeX, timeY)
      castbarFrame.timeText:SetTextColor(textR, textG, textB)
      castbarFrame.timeText:SetScale(timeScale)
      castbarFrame.timeText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
      castbarFrame.timeText:Show()
    else
      castbarFrame.timeText:Hide()
    end
  end
  if castIconShown and castbarFrame.icon.texture._lastTexture ~= texture then
    castbarFrame.icon.texture:SetTexture(texture)
    castbarFrame.icon.texture._lastTexture = texture
  end
  local okStart, startTime = pcall(function() return startTimeMS / 1000 end)
  local okEnd, endTime = pcall(function() return endTimeMS / 1000 end)
  if not okStart or not okEnd then
    local now = GetTime()
    local fallbackDuration = castbarFrame._fallbackDuration or 1.5
    local fallbackElapsed = castbarFrame._fallbackStart and (now - castbarFrame._fallbackStart) or 0
    if (not castbarFrame._fallbackStart) or (castbarFrame._fallbackChanneling ~= isChanneling) or (fallbackElapsed > (fallbackDuration + 0.05)) then
      castbarFrame._fallbackChanneling = isChanneling
      castbarFrame._fallbackStart = now
      castbarFrame._fallbackDuration = 1.5
    end
    local duration = castbarFrame._fallbackDuration or 1.5
    local elapsed = math.max(0, now - (castbarFrame._fallbackStart or now))
    local progress = isChanneling and (1 - (elapsed / duration)) or (elapsed / duration)
    progress = math.max(0, math.min(1, progress))
    castbarFrame.bar:SetMinMaxValues(0, 1)
    castbarFrame.bar:SetValue(progress)
    if showSpellName and name then castbarFrame.spellText:SetText(name) end
    if showTime then
      local remaining = math.max(0, duration - elapsed)
      local timeDirection = profile.castbarTimeDirection or "remaining"
      local timeValue = timeDirection == "elapsed" and elapsed or remaining
      local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
      castbarFrame.timeText:SetText(string.format(timeFormat, timeValue))
      castbarFrame.timeText:Show()
    else
      castbarFrame.timeText:Hide()
    end
    castbarFrame:Show()
    State.castbarActive = true
    return
  end
  castbarFrame._fallbackSpellID = nil
  castbarFrame._fallbackChanneling = nil
  castbarFrame._fallbackStart = nil
  castbarFrame._fallbackDuration = nil
  local currentTime = GetTime()
  local duration = endTime - startTime
  local elapsed = currentTime - startTime
  local progress
  if isChanneling then
    progress = (endTime - currentTime) / duration
  else
    progress = elapsed / duration
  end
  progress = math.max(0, math.min(1, progress))
  castbarFrame.bar:SetMinMaxValues(0, 1)
  castbarFrame.bar:SetValue(progress)
  if showSpellName then
    castbarFrame.spellText:SetText(name)
  else
    castbarFrame.spellText:Hide()
  end
  if showTime then
    local remaining = math.max(0, endTime - currentTime)
    local elapsedTime = math.max(0, currentTime - startTime)
    local timeDirection = profile.castbarTimeDirection or "remaining"
    local timeValue = timeDirection == "elapsed" and elapsedTime or remaining
    local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
    castbarFrame.timeText:SetText(string.format(timeFormat, timeValue))
  else
    castbarFrame.timeText:Hide()
  end
  local showTicks = profile.castbarShowTicks ~= false
  if isChanneling and showTicks and spellID and channelTickData[spellID] then
    local numTicks = channelTickData[spellID]
    local barWidth = castbarFrame:GetWidth()
    local barHeight = castbarFrame:GetHeight()
    local tickKey = table.concat({spellID, numTicks, barWidth, barHeight}, "|")
    if State.castbarTickKey ~= tickKey then
      State.castbarTickKey = tickKey
      for i = 1, 10 do
        if i <= numTicks then
          local tickPos = (i / numTicks) * barWidth
          castbarFrame.ticks[i]:ClearAllPoints()
          castbarFrame.ticks[i]:SetPoint("LEFT", castbarFrame.bar, "LEFT", tickPos - 1, 0)
          castbarFrame.ticks[i]:SetSize(2, barHeight)
          castbarFrame.ticks[i]:SetColorTexture(1, 1, 1, 0.7)
          castbarFrame.ticks[i]:Show()
        else
          castbarFrame.ticks[i]:Hide()
        end
      end
    end
  else
    if State.castbarTickKey ~= nil then
      State.castbarTickKey = nil
      for i = 1, 10 do
        castbarFrame.ticks[i]:Hide()
      end
    end
  end
  State.castbarActive = true
  castbarFrame:Show()
end
addonTable.UpdateCastbar = UpdateCastbar
local function SetBlizzardCastbarVisibility(show)
  local castingBar = PlayerCastingBarFrame
  if not castingBar then return end
  if show then
    castingBar:RegisterEvent("UNIT_SPELLCAST_START")
    castingBar:RegisterEvent("UNIT_SPELLCAST_STOP")
    castingBar:RegisterEvent("UNIT_SPELLCAST_FAILED")
    castingBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castingBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    castingBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    castingBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    castingBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castingBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    castingBar:Show()
  else
    castingBar:UnregisterEvent("UNIT_SPELLCAST_START")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_STOP")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_FAILED")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    castingBar:Hide()
  end
end
addonTable.SetBlizzardCastbarVisibility = SetBlizzardCastbarVisibility
local function StartCastbarTicker()
  if State.castbarTicker then return end
  SetBlizzardCastbarVisibility(false)
  State.castbarTicker = C_Timer.NewTicker(0.02, UpdateCastbar)
end
local function StopCastbarTicker()
  local newCastName = UnitCastingInfo("player")
  if not newCastName then
    newCastName = UnitChannelInfo("player")
  end
  if newCastName then
    return
  end
  local hadTicker = State.castbarTicker ~= nil
  if State.castbarTicker then
    State.castbarTicker:Cancel()
    State.castbarTicker = nil
  end
  State.castbarActive = false
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if State.castbarPreviewMode then
    C_Timer.After(0.1, function()
      if State.castbarPreviewMode and not State.castbarActive then
        addonTable.ShowCastbarPreview()
      end
    end)
  else
    castbarFrame:Hide()
  end
  if hadTicker and (not profile or not profile.useCastbar) then
    SetBlizzardCastbarVisibility(true)
  end
end
addonTable.StartCastbarTicker = StartCastbarTicker
addonTable.StopCastbarTicker = StopCastbarTicker
local castbarEventFrame = CreateFrame("Frame")
local function SetupCastbarEvents()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useCastbar then
    castbarEventFrame:UnregisterAllEvents()
    return
  end
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
end
castbarEventFrame:SetScript("OnEvent", function(self, event, unit, ...)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useCastbar then return end
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
    StartCastbarTicker()
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or
         event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or
         event == "UNIT_SPELLCAST_EMPOWER_STOP" then
    C_Timer.After(0.05, function()
      local castName = UnitCastingInfo("player")
      if not castName then castName = UnitChannelInfo("player") end
      if not castName then
        StopCastbarTicker()
      end
    end)
  end
end)
addonTable.SetupCastbarEvents = SetupCastbarEvents
local function ShowCastbarPreview()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  State.castbarPreviewMode = true
  local width = type(profile.castbarWidth) == "number" and profile.castbarWidth or 250
  local borderSize = type(profile.castbarBorderSize) == "number" and profile.castbarBorderSize or 1
  local autoWidthSource = profile.castbarAutoWidthSource or "off"
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
          width = (maxX - minX)
          if width < 20 then width = 20 end
        end
      end
    elseif autoWidthSource == "utility" then
      local utilityBar = UtilityCooldownViewer
      if utilityBar and utilityBar:IsShown() then
        local childCount = addonTable.CollectChildren(utilityBar, State.tmpChildren)
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
          width = (maxX - minX)
          if width < 20 then width = 20 end
        end
      end
    elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" then
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
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "prbhealth" or autoWidthSource == "prbpower" then
      local prbWidth = profile.prbWidth or 220
      local prbAutoWidth = profile.prbAutoWidthSource or "off"
        if prbAutoWidth ~= "off" then
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
            prbWidth = (maxX - minX) - (borderSize * 2)
            if prbWidth < 20 then prbWidth = 20 end
          end
        end
      end
      width = prbWidth
    end
  end
  local height = type(profile.castbarHeight) == "number" and profile.castbarHeight or 20
  local showIcon = profile.castbarShowIcon ~= false
  local iconSize = height
  local posX
  if profile.castbarCentered then
    posX = showIcon and (iconSize / 2) or 0
  else
    posX = type(profile.castbarX) == "number" and profile.castbarX or 0
  end
  local posY = type(profile.castbarY) == "number" and profile.castbarY or -250
  if autoWidthSource ~= "off" and showIcon then
    width = width - iconSize
    if width < 20 then width = 20 end
  end
  width = math.floor(width)
  local bgAlpha = (type(profile.castbarBgAlpha) == "number" and profile.castbarBgAlpha or 70) / 100
  local showTime = profile.castbarShowTime ~= false
  local showSpellName = profile.castbarShowSpellName ~= false
  local timeScale = type(profile.castbarTimeScale) == "number" and profile.castbarTimeScale or 1.0
  local spellNameScale = type(profile.castbarSpellNameScale) == "number" and profile.castbarSpellNameScale or 1.0
  local spellNameX = type(profile.castbarSpellNameXOffset) == "number" and profile.castbarSpellNameXOffset or 0
  local spellNameY = type(profile.castbarSpellNameYOffset) == "number" and profile.castbarSpellNameYOffset or 0
  local timeX = type(profile.castbarTimeXOffset) == "number" and profile.castbarTimeXOffset or 0
  local timeY = type(profile.castbarTimeYOffset) == "number" and profile.castbarTimeYOffset or 0
  local timePrecision = profile.castbarTimePrecision or "1"
  local textR = profile.castbarTextColorR or 1
  local textG = profile.castbarTextColorG or 1
  local textB = profile.castbarTextColorB or 1
  local texturePath = castbarTextures[profile.castbarTexture] or castbarTextures.solid
  castbarFrame.bar:SetStatusBarTexture(texturePath)
  local r, g, b
  if profile.castbarUseClassColor then
    r, g, b = GetClassColor()
  else
    r = profile.castbarColorR or 1
    g = profile.castbarColorG or 0.7
    b = profile.castbarColorB or 0
  end
  castbarFrame.bar:SetStatusBarColor(r, g, b)
  PixelUtil.SetSize(castbarFrame, width, height)
  castbarFrame:ClearAllPoints()
  PixelUtil.SetPoint(castbarFrame, "CENTER", UIParent, "CENTER", posX, posY)
  local bgR = profile.castbarBgColorR or 0.1
  local bgG = profile.castbarBgColorG or 0.1
  local bgB = profile.castbarBgColorB or 0.1
  castbarFrame.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
  if showIcon then
    PixelUtil.SetSize(castbarFrame.icon, iconSize, iconSize)
    castbarFrame.icon.texture:SetTexture(136116)
    castbarFrame.icon:ClearAllPoints()
    PixelUtil.SetPoint(castbarFrame.icon, "RIGHT", castbarFrame, "LEFT", 0, 0)
    castbarFrame.icon:Show()
  else
    castbarFrame.icon:Hide()
  end
  if borderSize > 0 then
    castbarFrame.border:ClearAllPoints()
    if showIcon then
      castbarFrame.border:SetPoint("TOPLEFT", castbarFrame.icon, "TOPLEFT", 0, 0)
      castbarFrame.border:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 0, 0)
    else
      castbarFrame.border:SetAllPoints(castbarFrame)
    end
    castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
    castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
    castbarFrame.border:Show()
  else
    castbarFrame.border:Hide()
  end
  castbarFrame.bar:SetMinMaxValues(0, 1)
  castbarFrame.bar:SetValue(0.65)
  local globalFont, globalOutline = GetGlobalFont()
  if showSpellName then
    castbarFrame.spellText:ClearAllPoints()
    castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5 + spellNameX, spellNameY)
    castbarFrame.spellText:SetText("Preview Spell")
    castbarFrame.spellText:SetTextColor(textR, textG, textB)
    castbarFrame.spellText:SetScale(spellNameScale)
    castbarFrame.spellText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
    castbarFrame.spellText:Show()
  else
    castbarFrame.spellText:Hide()
  end
  if showTime then
    castbarFrame.timeText:ClearAllPoints()
    castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5 + timeX, timeY)
    local timeFormat = timePrecision == "0" and "1" or (timePrecision == "2" and "1.50" or "1.5")
    castbarFrame.timeText:SetText(timeFormat)
    castbarFrame.timeText:SetTextColor(textR, textG, textB)
    castbarFrame.timeText:SetScale(timeScale)
    castbarFrame.timeText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
    castbarFrame.timeText:Show()
  else
    castbarFrame.timeText:Hide()
  end
  castbarFrame:Show()
end
local function StopCastbarPreview()
  State.castbarPreviewMode = false
  if State.castbarPreviewTimer then
    State.castbarPreviewTimer:Cancel()
    State.castbarPreviewTimer = nil
  end
  if not State.castbarActive then
    castbarFrame:Hide()
  end
end
addonTable.ShowCastbarPreview = ShowCastbarPreview
addonTable.StopCastbarPreview = StopCastbarPreview
addonTable.FocusCastbarFrame = CreateFrame("Frame", "CCMFocusCastbar", UIParent, "BackdropTemplate")
addonTable.FocusCastbarFrame:SetSize(250, 20)
addonTable.FocusCastbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -210)
addonTable.FocusCastbarFrame:SetFrameStrata("MEDIUM")
addonTable.FocusCastbarFrame:SetClampedToScreen(true)
addonTable.FocusCastbarFrame:SetMovable(false)
addonTable.FocusCastbarFrame:EnableMouse(true)
addonTable.FocusCastbarFrame:RegisterForDrag("LeftButton")
addonTable.FocusCastbarFrame:Hide()
addonTable.FocusCastbarFrame.bar = CreateFrame("StatusBar", nil, addonTable.FocusCastbarFrame)
addonTable.FocusCastbarFrame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
addonTable.FocusCastbarFrame.bar:SetStatusBarColor(1, 0.7, 0)
addonTable.FocusCastbarFrame.bar:SetAllPoints()
addonTable.FocusCastbarFrame.bg = addonTable.FocusCastbarFrame.bar:CreateTexture(nil, "BACKGROUND")
addonTable.FocusCastbarFrame.bg:SetAllPoints()
addonTable.FocusCastbarFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
addonTable.FocusCastbarFrame.textOverlay = CreateFrame("Frame", nil, addonTable.FocusCastbarFrame)
addonTable.FocusCastbarFrame.textOverlay:SetAllPoints()
addonTable.FocusCastbarFrame.textOverlay:SetFrameLevel(addonTable.FocusCastbarFrame:GetFrameLevel() + 10)
addonTable.FocusCastbarFrame.spellText = addonTable.FocusCastbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addonTable.FocusCastbarFrame.spellText:SetPoint("LEFT", addonTable.FocusCastbarFrame, "LEFT", 5, 0)
addonTable.FocusCastbarFrame.timeText = addonTable.FocusCastbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addonTable.FocusCastbarFrame.timeText:SetPoint("RIGHT", addonTable.FocusCastbarFrame, "RIGHT", -5, 0)
addonTable.FocusCastbarFrame.icon = CreateFrame("Frame", nil, addonTable.FocusCastbarFrame)
addonTable.FocusCastbarFrame.icon:SetSize(24, 24)
addonTable.FocusCastbarFrame.icon:SetPoint("RIGHT", addonTable.FocusCastbarFrame, "LEFT", -4, 0)
addonTable.FocusCastbarFrame.icon.texture = addonTable.FocusCastbarFrame.icon:CreateTexture(nil, "ARTWORK")
addonTable.FocusCastbarFrame.icon.texture:SetAllPoints()
addonTable.FocusCastbarFrame.icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
addonTable.FocusCastbarFrame.border = CreateFrame("Frame", nil, addonTable.FocusCastbarFrame, "BackdropTemplate")
addonTable.FocusCastbarFrame.border:SetFrameLevel(addonTable.FocusCastbarFrame:GetFrameLevel() + 20)
addonTable.FocusCastbarFrame.border:SetAllPoints()
addonTable.FocusCastbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
addonTable.FocusCastbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
addonTable.FocusCastbarFrame.ticks = {}
for i = 1, 10 do
  local tick = addonTable.FocusCastbarFrame.bar:CreateTexture(nil, "OVERLAY")
  tick:SetColorTexture(1, 1, 1, 0.7)
  tick:SetSize(2, 1)
  tick:Hide()
  addonTable.FocusCastbarFrame.ticks[i] = tick
end
addonTable.FocusCastbarFrame:SetScript("OnDragStart", function(self)
  if not addonTable.GetGUIOpen or not addonTable.GetGUIOpen() then return end
  self:StartMoving()
  State.focusCastbarDragging = true
end)
addonTable.FocusCastbarFrame:SetScript("OnDragStop", function(self)
  if not State.focusCastbarDragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local _, _, _, newX, newY = self:GetPoint(1)
    profile.focusCastbarX = newX
    profile.focusCastbarY = newY
    if addonTable.UpdateFocusCastbarSliders then addonTable.UpdateFocusCastbarSliders(newX, newY) end
  end
  State.focusCastbarDragging = false
end)
addonTable.FocusCastbarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.focusCastbarDragging then
    self:StopMovingOrSizing()
    State.focusCastbarDragging = false
  end
end)
local function SetBlizzardFocusCastbarVisibility(show)
  if FocusFrameSpellBar then
    if show then
      FocusFrameSpellBar:SetAlpha(1)
      FocusFrameSpellBar:Show()
      if FocusFrameSpellBar.Border then FocusFrameSpellBar.Border:Show() end
      if FocusFrameSpellBar.Text then FocusFrameSpellBar.Text:Show() end
      if FocusFrameSpellBar.TextBorder then FocusFrameSpellBar.TextBorder:Show() end
    else
      FocusFrameSpellBar:SetAlpha(0)
      if FocusFrameSpellBar.Border then FocusFrameSpellBar.Border:Hide() end
      if FocusFrameSpellBar.Text then FocusFrameSpellBar.Text:Hide() end
      if FocusFrameSpellBar.TextBorder then FocusFrameSpellBar.TextBorder:Hide() end
      FocusFrameSpellBar:Hide()
    end
  end
  if FocusCastingBarFrame then
    if show then
      FocusCastingBarFrame:SetAlpha(1)
      FocusCastingBarFrame:Show()
    else
      FocusCastingBarFrame:SetAlpha(0)
      FocusCastingBarFrame:Hide()
    end
  end
end
addonTable.SetBlizzardFocusCastbarVisibility = SetBlizzardFocusCastbarVisibility
local function ShouldHideDefaultFocusCastbar()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  return profile and profile.useFocusCastbar == true
end
if FocusFrameSpellBar and not FocusFrameSpellBar._ccmHideHooked then
  FocusFrameSpellBar:HookScript("OnShow", function(self)
    if ShouldHideDefaultFocusCastbar() then
      self:SetAlpha(0)
      if self.Border then self.Border:Hide() end
      if self.Text then self.Text:Hide() end
      if self.TextBorder then self.TextBorder:Hide() end
      self:Hide()
    end
  end)
  FocusFrameSpellBar._ccmHideHooked = true
end
if FocusCastingBarFrame and not FocusCastingBarFrame._ccmHideHooked then
  FocusCastingBarFrame:HookScript("OnShow", function(self)
    if ShouldHideDefaultFocusCastbar() then
      self:SetAlpha(0)
      self:Hide()
    end
  end)
  FocusCastingBarFrame._ccmHideHooked = true
end
addonTable.UpdateFocusCastbar = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.FocusCastbarFrame
  if not frame then return end
  if not profile or not profile.useFocusCastbar then
    frame:Hide()
    State.focusCastbarActive = false
    SetBlizzardFocusCastbarVisibility(true)
    return
  end
  SetBlizzardFocusCastbarVisibility(false)
  local name, text, texture, startTimeMS, endTimeMS, _, _, _, spellID = UnitCastingInfo("focus")
  local isChanneling = false
  if not name then
    name, text, texture, startTimeMS, endTimeMS, _, _, spellID = UnitChannelInfo("focus")
    isChanneling = name ~= nil
  end
  if name and addonTable.StartFocusCastbarTicker then
    addonTable.StartFocusCastbarTicker()
  end
  if not name and not State.focusCastbarPreviewMode then
    frame:Hide()
    State.focusCastbarActive = false
    State.focusCastbarTickKey = nil
    frame._fallbackSpellID = nil
    frame._fallbackChanneling = nil
    frame._fallbackStart = nil
    frame._fallbackDuration = nil
    return
  end
  local width = type(profile.focusCastbarWidth) == "number" and profile.focusCastbarWidth or 250
  local borderSize = type(profile.focusCastbarBorderSize) == "number" and profile.focusCastbarBorderSize or 1
  width = math.max(20, math.floor(width))
  local height = type(profile.focusCastbarHeight) == "number" and profile.focusCastbarHeight or 20
  local showIcon = profile.focusCastbarShowIcon ~= false
  local iconSize = height
  local posX = type(profile.focusCastbarX) == "number" and profile.focusCastbarX or 0
  local posY = type(profile.focusCastbarY) == "number" and profile.focusCastbarY or -210
  if profile.focusCastbarCentered then
    posX = showIcon and (iconSize / 2) or 0
  end
  local bgAlpha = (type(profile.focusCastbarBgAlpha) == "number" and profile.focusCastbarBgAlpha or 70) / 100
  local showTime = profile.focusCastbarShowTime ~= false
  local showSpellName = profile.focusCastbarShowSpellName ~= false
  local timeScale = type(profile.focusCastbarTimeScale) == "number" and profile.focusCastbarTimeScale or 1.0
  local spellNameScale = type(profile.focusCastbarSpellNameScale) == "number" and profile.focusCastbarSpellNameScale or 1.0
  local spellNameX = type(profile.focusCastbarSpellNameXOffset) == "number" and profile.focusCastbarSpellNameXOffset or 0
  local spellNameY = type(profile.focusCastbarSpellNameYOffset) == "number" and profile.focusCastbarSpellNameYOffset or 0
  local timeX = type(profile.focusCastbarTimeXOffset) == "number" and profile.focusCastbarTimeXOffset or 0
  local timeY = type(profile.focusCastbarTimeYOffset) == "number" and profile.focusCastbarTimeYOffset or 0
  local timePrecision = profile.focusCastbarTimePrecision or "1"
  local function FormatFocusTimeValue(rawValue)
    local num = nil
    if type(rawValue) == "number" then
      num = rawValue
    else
      local rawText = tostring(rawValue or "")
      num = tonumber(rawText)
      if not num then
        local parsedText = string.match(rawText, "[-+]?%d*%.?%d+")
        num = tonumber(parsedText)
      end
    end
    if num ~= nil then
      local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
      return string.format(timeFormat, num)
    end
    return tostring(rawValue or "")
  end
  local textR = profile.focusCastbarTextColorR or 1
  local textG = profile.focusCastbarTextColorG or 1
  local textB = profile.focusCastbarTextColorB or 1
  frame.bar:SetStatusBarTexture(castbarTextures[profile.focusCastbarTexture] or castbarTextures.solid)
  local r = profile.focusCastbarColorR or 1
  local g = profile.focusCastbarColorG or 0.7
  local b = profile.focusCastbarColorB or 0
  frame.bar:SetStatusBarColor(r, g, b)
  PixelUtil.SetSize(frame, width, height)
  if not State.focusCastbarDragging then
    frame:ClearAllPoints()
    PixelUtil.SetPoint(frame, "CENTER", UIParent, "CENTER", posX, posY)
  end
  frame.bg:SetColorTexture(profile.focusCastbarBgColorR or 0.1, profile.focusCastbarBgColorG or 0.1, profile.focusCastbarBgColorB or 0.1, bgAlpha)
  if showIcon and texture then
    PixelUtil.SetSize(frame.icon, iconSize, iconSize)
    frame.icon.texture:SetTexture(texture)
    frame.icon:ClearAllPoints()
    PixelUtil.SetPoint(frame.icon, "RIGHT", frame, "LEFT", 0, 0)
    frame.icon:Show()
  else
    frame.icon:Hide()
  end
  if borderSize > 0 then
    frame.border:ClearAllPoints()
    if showIcon and texture then
      frame.border:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 0)
      frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    else
      frame.border:SetAllPoints(frame)
    end
    frame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
    frame.border:SetBackdropBorderColor(0, 0, 0, 1)
    frame.border:Show()
  else
    frame.border:Hide()
  end
  local globalFont, globalOutline = GetGlobalFont()
  local focusTextStyleKey = table.concat({
    showSpellName and 1 or 0, showTime and 1 or 0,
    spellNameScale, spellNameX, spellNameY,
    timeScale, timeX, timeY,
    textR, textG, textB,
    globalFont, globalOutline ~= "" and globalOutline or "OUTLINE"
  }, "|")
  if frame._textStyleKey ~= focusTextStyleKey then
    frame._textStyleKey = focusTextStyleKey
    frame.spellText:ClearAllPoints()
    frame.spellText:SetPoint("LEFT", frame, "LEFT", 5 + spellNameX, spellNameY)
    frame.spellText:SetTextColor(textR, textG, textB)
    frame.spellText:SetScale(spellNameScale)
    frame.spellText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
    frame.timeText:ClearAllPoints()
    frame.timeText:SetPoint("RIGHT", frame, "RIGHT", -5 + timeX, timeY)
    frame.timeText:SetTextColor(textR, textG, textB)
    frame.timeText:SetScale(timeScale)
    frame.timeText:SetFont(globalFont, 12, globalOutline ~= "" and globalOutline or "OUTLINE")
  end
  if showSpellName then
    frame.spellText:SetText(name or "Focus Cast")
    frame.spellText:Show()
  else
    frame.spellText:Hide()
  end
  local durationObject = nil
  if name then
    if isChanneling and UnitChannelDuration then
      local okDur, durObj = pcall(UnitChannelDuration, "focus")
      if okDur then durationObject = durObj end
    elseif UnitCastingDuration then
      local okDur, durObj = pcall(UnitCastingDuration, "focus")
      if okDur then durationObject = durObj end
    end
  end
  if name and durationObject and frame.bar and frame.bar.SetTimerDuration then
    local interpolation = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or nil
    local timerDirection = Enum and Enum.StatusBarTimerDirection and (isChanneling and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime) or nil
    local okTimer = pcall(frame.bar.SetTimerDuration, frame.bar, durationObject, interpolation, timerDirection)
    if okTimer then
      if showTime then
        local okRemaining, remaining = pcall(function()
          return durationObject:GetRemainingDuration()
        end)
        local timeValue = okRemaining and remaining or nil
        local timeDirection = profile.focusCastbarTimeDirection or "remaining"
        if timeDirection == "elapsed" and okRemaining then
          local okTotal, totalDuration = pcall(function()
            return durationObject:GetTotalDuration()
          end)
          if okTotal and totalDuration ~= nil then
            local okElapsed, elapsedValue = pcall(function()
              return totalDuration - remaining
            end)
            if okElapsed then
              timeValue = elapsedValue
            end
          end
        end
        if timeValue ~= nil then
          frame.timeText:SetText(FormatFocusTimeValue(timeValue))
          frame.timeText:Show()
        else
          frame.timeText:Hide()
        end
      else
        frame.timeText:Hide()
      end
      local showTicks = profile.focusCastbarShowTicks ~= false
      if isChanneling and showTicks and spellID and channelTickData[spellID] then
        local numTicks = channelTickData[spellID]
        local barWidth = frame:GetWidth()
        local barHeight = frame:GetHeight()
        local tickKey = table.concat({spellID, numTicks, barWidth, barHeight}, "|")
        if State.focusCastbarTickKey ~= tickKey then
          State.focusCastbarTickKey = tickKey
          for i = 1, 10 do
            if i <= numTicks then
              local tickPos = (i / numTicks) * barWidth
              frame.ticks[i]:ClearAllPoints()
              frame.ticks[i]:SetPoint("LEFT", frame.bar, "LEFT", tickPos - 1, 0)
              frame.ticks[i]:SetSize(2, barHeight)
              frame.ticks[i]:SetColorTexture(1, 1, 1, 0.7)
              frame.ticks[i]:Show()
            else
              frame.ticks[i]:Hide()
            end
          end
        end
      else
        State.focusCastbarTickKey = nil
        for i = 1, 10 do frame.ticks[i]:Hide() end
      end
      frame:Show()
      State.focusCastbarActive = true
      return
    end
  end
  if name and startTimeMS and endTimeMS then
    local okStart, startTime = pcall(function() return startTimeMS / 1000 end)
    local okEnd, endTime = pcall(function() return endTimeMS / 1000 end)
    if not okStart or not okEnd then
      local now = GetTime()
      local fallbackDuration = 1.5
      if type(spellID) == "number" then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if info then
          local castTime = tonumber(info.castTimeMS) or tonumber(info.castTime)
          local okCastTime, hasPositiveCastTime = pcall(function()
            return castTime and castTime > 0
          end)
          if okCastTime and hasPositiveCastTime then
            fallbackDuration = castTime / 1000
          end
        end
      end
      if (not frame._fallbackStart) or (frame._fallbackChanneling ~= isChanneling) then
        frame._fallbackSpellID = nil
        frame._fallbackChanneling = isChanneling
        frame._fallbackStart = now
        frame._fallbackDuration = fallbackDuration
      end
      local duration = frame._fallbackDuration or 1.5
      local elapsed = math.max(0, now - (frame._fallbackStart or now))
      local progress = isChanneling and (1 - (elapsed / duration)) or (elapsed / duration)
      progress = math.max(0, math.min(1, progress))
      frame.bar:SetMinMaxValues(0, 1)
      frame.bar:SetValue(progress)
      if showTime then
        local barValue = frame.bar:GetValue()
        local remaining = math.max(0, duration * (1 - barValue))
        local elapsedFromBar = math.max(0, duration * barValue)
        local timeDirection = profile.focusCastbarTimeDirection or "remaining"
        local timeValue = timeDirection == "elapsed" and elapsedFromBar or remaining
        frame.timeText:SetText(FormatFocusTimeValue(timeValue))
        frame.timeText:Show()
      else
        frame.timeText:Hide()
      end
      frame:Show()
      State.focusCastbarActive = true
      return
    end
    frame._fallbackSpellID = nil
    frame._fallbackChanneling = nil
    frame._fallbackStart = nil
    frame._fallbackDuration = nil
    local currentTime = GetTime()
    local duration = endTime - startTime
    local progress = 0
    if duration > 0 then
      if isChanneling then
        progress = (endTime - currentTime) / duration
      else
        progress = (currentTime - startTime) / duration
      end
    end
    progress = math.max(0, math.min(1, progress))
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(progress)
    if showTime then
      local barValue = frame.bar:GetValue()
      local remaining = math.max(0, duration * (1 - barValue))
      local elapsedFromBar = math.max(0, duration * barValue)
      local timeDirection = profile.focusCastbarTimeDirection or "remaining"
      local timeValue = timeDirection == "elapsed" and elapsedFromBar or remaining
      frame.timeText:SetText(FormatFocusTimeValue(timeValue))
      frame.timeText:Show()
    else
      frame.timeText:Hide()
    end
    local showTicks = profile.focusCastbarShowTicks ~= false
    if isChanneling and showTicks and spellID and channelTickData[spellID] then
      local numTicks = channelTickData[spellID]
      local barWidth = frame:GetWidth()
      local barHeight = frame:GetHeight()
      local tickKey = table.concat({spellID, numTicks, barWidth, barHeight}, "|")
      if State.focusCastbarTickKey ~= tickKey then
        State.focusCastbarTickKey = tickKey
        for i = 1, 10 do
          if i <= numTicks then
            local tickPos = (i / numTicks) * barWidth
            frame.ticks[i]:ClearAllPoints()
            frame.ticks[i]:SetPoint("LEFT", frame.bar, "LEFT", tickPos - 1, 0)
            frame.ticks[i]:SetSize(2, barHeight)
            frame.ticks[i]:SetColorTexture(1, 1, 1, 0.7)
            frame.ticks[i]:Show()
          else
            frame.ticks[i]:Hide()
          end
        end
      end
    else
      State.focusCastbarTickKey = nil
      for i = 1, 10 do frame.ticks[i]:Hide() end
    end
  else
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(0.65)
    if showTime then
      frame.timeText:SetText(FormatFocusTimeValue(1.5))
      frame.timeText:Show()
    else
      frame.timeText:Hide()
    end
    for i = 1, 10 do frame.ticks[i]:Hide() end
  end
  State.focusCastbarActive = true
  frame:Show()
end
addonTable.StartFocusCastbarTicker = function()
  if State.focusCastbarTicker then return end
  SetBlizzardFocusCastbarVisibility(false)
  State.focusCastbarTicker = C_Timer.NewTicker(0.02, addonTable.UpdateFocusCastbar)
end
addonTable.StopFocusCastbarTicker = function()
  local castName = UnitCastingInfo("focus")
  if not castName then castName = UnitChannelInfo("focus") end
  if castName then return end
  if State.focusCastbarTicker then
    State.focusCastbarTicker:Cancel()
    State.focusCastbarTicker = nil
  end
  State.focusCastbarActive = false
  State.focusCastbarTickKey = nil
  if not State.focusCastbarPreviewMode and addonTable.FocusCastbarFrame then
    addonTable.FocusCastbarFrame:Hide()
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useFocusCastbar then
    SetBlizzardFocusCastbarVisibility(true)
  end
end
local focusCastbarEventFrame = CreateFrame("Frame")
addonTable.SetupFocusCastbarEvents = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useFocusCastbar then
    focusCastbarEventFrame:UnregisterAllEvents()
    return
  end
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "focus")
  focusCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "focus")
end
focusCastbarEventFrame:SetScript("OnEvent", function(_, event)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useFocusCastbar then return end
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
    addonTable.StartFocusCastbarTicker()
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
    C_Timer.After(0.05, function()
      local castName = UnitCastingInfo("focus")
      if not castName then castName = UnitChannelInfo("focus") end
      if not castName then addonTable.StopFocusCastbarTicker() end
    end)
  end
end)
addonTable.ShowFocusCastbarPreview = function()
  State.focusCastbarPreviewMode = true
  addonTable.UpdateFocusCastbar()
end
addonTable.StopFocusCastbarPreview = function()
  State.focusCastbarPreviewMode = false
  State.focusCastbarTickKey = nil
  if addonTable.FocusCastbarFrame then
    for i = 1, 10 do addonTable.FocusCastbarFrame.ticks[i]:Hide() end
  end
  local castName = UnitCastingInfo("focus")
  if not castName then castName = UnitChannelInfo("focus") end
  if not castName and addonTable.FocusCastbarFrame then
    addonTable.FocusCastbarFrame:Hide()
  end
end
local debuffSkinningActive = false
local debuffUpdateTicker = nil
local debuffIcons = {}
local debuffFrame = nil
local MAX_DEBUFF_ICONS = 16
local function CreateDebuffIcon(parent, index)
  local size = 32
  local icon = CreateFrame("Button", "CCMDebuffIcon"..index, parent, "BackdropTemplate")
  icon:SetSize(size, size)
  icon:EnableMouse(false)
  icon:Hide()
  icon.icon = icon:CreateTexture(nil, "ARTWORK")
  icon.icon:SetAllPoints()
  icon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon.border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
  icon.border:SetAllPoints()
  icon.border:SetFrameLevel(icon:GetFrameLevel() + 1)
  icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
  icon.cooldown:SetAllPoints()
  icon.cooldown:SetDrawEdge(false)
  icon.cooldown:SetDrawBling(false)
  icon.cooldown:SetDrawSwipe(true)
  icon.cooldown:SetReverse(true)
  icon.cooldown:SetHideCountdownNumbers(false)
  return icon
end
local function CreateDebuffFrame()
  if debuffFrame then return debuffFrame end
  debuffFrame = CreateFrame("Frame", "CCMPlayerDebuffFrame", UIParent)
  debuffFrame:SetSize(400, 50)
  debuffFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
  debuffFrame:SetFrameStrata("MEDIUM")
  debuffFrame:SetMovable(true)
  debuffFrame:EnableMouse(true)
  debuffFrame:RegisterForDrag("LeftButton")
  debuffFrame:SetScript("OnDragStart", function(self)
    if State.debuffPreviewMode then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile then
        State.debuffDragStartX = profile.playerDebuffX or 0
        State.debuffDragStartY = profile.playerDebuffY or 0
      end
      State.debuffDragStartCX, State.debuffDragStartCY = self:GetCenter()
      self:StartMoving()
      State.debuffDragging = true
    end
  end)
  debuffFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if State.debuffPreviewMode then
      local startCX, startCY = State.debuffDragStartCX, State.debuffDragStartCY
      local curCX, curCY = self:GetCenter()
      if startCX and startCY and curCX and curCY then
        local deltaX = curCX - startCX
        local deltaY = curCY - startCY
        local baseX = State.debuffDragStartX or 0
        local baseY = State.debuffDragStartY or 0
        local newX = math.floor((baseX + deltaX) + 0.5)
        local newY = math.floor((baseY + deltaY) + 0.5)
        local profile = addonTable.GetProfile and addonTable.GetProfile()
        if profile then
          profile.playerDebuffX = newX
          profile.playerDebuffY = newY
          if addonTable.debuffs then
            if addonTable.debuffs.xSlider then
              addonTable.debuffs.xSlider._updating = true
              addonTable.debuffs.xSlider:SetValue(newX)
              addonTable.debuffs.xSlider._updating = false
              addonTable.debuffs.xSlider.valueText:SetText(newX)
            end
            if addonTable.debuffs.ySlider then
              addonTable.debuffs.ySlider._updating = true
              addonTable.debuffs.ySlider:SetValue(newY)
              addonTable.debuffs.ySlider._updating = false
              addonTable.debuffs.ySlider.valueText:SetText(newY)
            end
          end
          self:ClearAllPoints()
          self:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", newX, newY)
        end
      end
    end
    State.debuffDragging = false
    State.debuffDragStartX, State.debuffDragStartY = nil, nil
    State.debuffDragStartCX, State.debuffDragStartCY = nil, nil
  end)
  for i = 1, MAX_DEBUFF_ICONS do
    debuffIcons[i] = CreateDebuffIcon(debuffFrame, i)
  end
  return debuffFrame
end
local function UpdateDebuffIconStyle(icon, profile)
  local borderSize = profile.playerDebuffBorderSize or 1
  local iconSize = profile.playerDebuffSize or 32
  icon:SetSize(iconSize, iconSize)
  if borderSize > 0 then
    icon.border:SetBackdrop({
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = borderSize,
    })
    icon.border:SetBackdropBorderColor(0.8, 0, 0, 1)
    icon.border:Show()
  else
    icon.border:Hide()
  end
end
local function UpdatePlayerDebuffs()
  if State.debuffPreviewMode then
    return
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.enablePlayerDebuffs or profile.enableUnitFrameCustomization == false then
    if debuffFrame then debuffFrame:Hide() end
    return
  end
  if not debuffFrame then
    CreateDebuffFrame()
  end
  local iconSize = profile.playerDebuffSize or 32
  local spacing = profile.playerDebuffSpacing or 2
  local iconsPerRow = profile.playerDebuffIconsPerRow or 10
  local sortDirection = profile.playerDebuffSortDirection or "right"
  local rowGrowth = profile.playerDebuffRowGrowDirection or "down" 
  local debuffFilter = "HARMFUL"
  local continuationToken, slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8,
        slot9, slot10, slot11, slot12, slot13, slot14, slot15, slot16 = C_UnitAuras.GetAuraSlots("player", debuffFilter)
  local slots = {slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8,
                 slot9, slot10, slot11, slot12, slot13, slot14, slot15, slot16}
  local visibleCount = 0
  for i = 1, MAX_DEBUFF_ICONS do
    local slot = slots[i]
    if slot then
      local data = C_UnitAuras.GetAuraDataBySlot("player", slot)
      if data then
        visibleCount = visibleCount + 1
        local icon = debuffIcons[visibleCount]
        if icon then
          if data.icon then
            icon.icon:SetTexture(data.icon)
          end
          if data.auraInstanceID then
            local durationObj = C_UnitAuras.GetAuraDuration("player", data.auraInstanceID)
            if durationObj then
              icon.cooldown:SetCooldownFromDurationObject(durationObj)
              icon.cooldown:Show()
            else
              icon.cooldown:Hide()
            end
          end
          UpdateDebuffIconStyle(icon, profile)
          local index = visibleCount - 1
          local col = index % iconsPerRow
          local row = math.floor(index / iconsPerRow)
          local xPos
          if sortDirection == "left" then
            xPos = -col * (iconSize + spacing)
          else 
            xPos = col * (iconSize + spacing)
          end
          local yPos
          if rowGrowth == "up" then
            yPos = row * (iconSize + spacing)
          else 
            yPos = -row * (iconSize + spacing)
          end
          icon:ClearAllPoints()
          icon:SetPoint("TOPLEFT", debuffFrame, "TOPLEFT", xPos, yPos)
          icon:Show()
        end
      end
    end
  end
  for i = visibleCount + 1, MAX_DEBUFF_ICONS do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
  local numRows = math.ceil(visibleCount / iconsPerRow)
  local iconsInFirstRow = math.min(visibleCount, iconsPerRow)
  local totalWidth = iconsInFirstRow * iconSize + math.max(0, iconsInFirstRow - 1) * spacing
  local totalHeight = numRows * iconSize + math.max(0, numRows - 1) * spacing
  debuffFrame:SetSize(math.max(totalWidth, 1), math.max(totalHeight, 1))
  local xOffset = profile.playerDebuffX or 0
  local yOffset = profile.playerDebuffY or 0
  debuffFrame:ClearAllPoints()
  debuffFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", xOffset, yOffset)
  debuffFrame:Show()
end
local function StartPlayerDebuffsTicker()
  if debuffUpdateTicker then return end
  if not debuffFrame then CreateDebuffFrame() end
  debuffFrame:RegisterUnitEvent("UNIT_AURA", "player")
  debuffFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
      UpdatePlayerDebuffs()
    end
  end)
  debuffUpdateTicker = true
  UpdatePlayerDebuffs()
end
local function StopPlayerDebuffsTicker()
  if debuffUpdateTicker then
    if type(debuffUpdateTicker) == "table" and debuffUpdateTicker.Cancel then
      debuffUpdateTicker:Cancel()
    end
    debuffUpdateTicker = nil
  end
  if debuffFrame then
    debuffFrame:UnregisterAllEvents()
    debuffFrame:SetScript("OnEvent", nil)
  end
end
local function ShowDebuffPreview()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if not debuffFrame then
    CreateDebuffFrame()
  end
  State.debuffPreviewMode = true
  local iconSize = profile.playerDebuffSize or 32
  local spacing = profile.playerDebuffSpacing or 2
  local sortDirection = profile.playerDebuffSortDirection or "right"
  local iconsPerRow = profile.playerDebuffIconsPerRow or 10
  local rowGrowth = profile.playerDebuffRowGrowDirection or "down"
  local previewTextures = {
    136122,
    135849,
    136139,
  }
  for i = 1, 3 do
    local icon = debuffIcons[i]
    if icon then
      icon.icon:SetTexture(previewTextures[i])
      local startTime = GetTime()
      local duration = 5 + i * 2
      icon.cooldown:SetCooldown(startTime, duration)
      icon.cooldown:Show()
      UpdateDebuffIconStyle(icon, profile)
      local index = i - 1
      local col = index % iconsPerRow
      local row = math.floor(index / iconsPerRow)
      local xPos
      if sortDirection == "left" then
        xPos = -col * (iconSize + spacing)
      else
        xPos = col * (iconSize + spacing)
      end
      local yPos
      if rowGrowth == "up" then
        yPos = row * (iconSize + spacing)
      else
        yPos = -row * (iconSize + spacing)
      end
      icon:ClearAllPoints()
      icon:SetPoint("TOPLEFT", debuffFrame, "TOPLEFT", xPos, yPos)
      icon:Show()
    end
  end
  for i = 4, MAX_DEBUFF_ICONS do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
  local numRows = math.ceil(3 / iconsPerRow)
  local iconsInFirstRow = math.min(3, iconsPerRow)
  local totalWidth = iconsInFirstRow * iconSize + math.max(0, iconsInFirstRow - 1) * spacing
  local totalHeight = numRows * iconSize + math.max(0, numRows - 1) * spacing
  debuffFrame:SetSize(math.max(totalWidth, 1), math.max(totalHeight, 1))
  if not State.debuffDragging then
    local xOffset = profile.playerDebuffX or 0
    local yOffset = profile.playerDebuffY or 0
    debuffFrame:ClearAllPoints()
    debuffFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", xOffset, yOffset)
  end
  debuffFrame:Show()
end
local function StopDebuffPreview()
  State.debuffPreviewMode = false
  if debuffFrame then
    debuffFrame:Hide()
  end
  for i = 1, MAX_DEBUFF_ICONS do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
end
local function RestorePlayerDebuffs()
  StopPlayerDebuffsTicker()
  if debuffFrame then
    debuffFrame:Hide()
  end
  for i = 1, MAX_DEBUFF_ICONS do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
  debuffSkinningActive = false
end
local function ApplyPlayerDebuffsSkinning()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.enablePlayerDebuffs then
    RestorePlayerDebuffs()
    return
  end
  StartPlayerDebuffsTicker()
  UpdatePlayerDebuffs()
  debuffSkinningActive = true
end
addonTable.ShowDebuffPreview = ShowDebuffPreview
addonTable.StopDebuffPreview = StopDebuffPreview
addonTable.ApplyPlayerDebuffsSkinning = ApplyPlayerDebuffsSkinning
addonTable.RestorePlayerDebuffs = RestorePlayerDebuffs
addonTable.UpdatePlayerDebuffs = UpdatePlayerDebuffs
local actionBarHideFrame = CreateFrame("Frame", "CCMActionBarHideFrame", UIParent)
actionBarHideFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
actionBarHideFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
actionBarHideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local HideBlizzBarPreviews, HideBlizzBarDragOverlays
local function GetActionBar1Frames()
  local frames = {}
  local names = {
    "MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarArtFrameBackground",
    "MicroButtonAndBagsBar", "MainMenuBarBackpackButton",
  }
  for _, name in ipairs(names) do
    local f = _G[name]
    if f then table.insert(frames, f) end
  end
  return frames
end
local function GetActionButtons()
  local buttons = {}
  for i = 1, 12 do
    local btn = _G["ActionButton" .. i]
    if btn then table.insert(buttons, btn) end
  end
  return buttons
end
local function GetStanceButtons()
  local buttons = {}
  for i = 1, 10 do
    local btn = _G["StanceButton" .. i]
    if btn then table.insert(buttons, btn) end
  end
  return buttons
end
local function GetStanceBarFrames()
  local frames = {}
  local names = {"StanceBar", "StanceBarFrame"}
  for _, name in ipairs(names) do
    local f = _G[name]
    if f then table.insert(frames, f) end
  end
  return frames
end
local function GetPetButtons()
  local buttons = {}
  for i = 1, 10 do
    local btn = _G["PetActionButton" .. i]
    if btn then table.insert(buttons, btn) end
  end
  return buttons
end
local function GetPetBarFrames()
  local frames = {}
  local names = {"PetActionBarFrame", "PetActionBar"}
  for _, name in ipairs(names) do
    local f = _G[name]
    if f then table.insert(frames, f) end
  end
  return frames
end
local function SetActionBar1Alpha(alpha)
  for _, btn in ipairs(GetActionButtons()) do
    if btn and btn.SetAlpha then btn:SetAlpha(alpha) end
  end
  for _, f in ipairs(GetActionBar1Frames()) do
    if f and f.SetAlpha then f:SetAlpha(alpha) end
  end
end
local function SetStanceBarAlpha(alpha)
  for _, f in ipairs(GetStanceBarFrames()) do
    if f and f.SetAlpha then f:SetAlpha(alpha) end
  end
  for _, btn in ipairs(GetStanceButtons()) do
    if btn and btn.SetAlpha then btn:SetAlpha(alpha) end
  end
end
local function SetPetBarAlpha(alpha)
  for _, f in ipairs(GetPetBarFrames()) do
    if f and f.SetAlpha then f:SetAlpha(alpha) end
  end
  for _, btn in ipairs(GetPetButtons()) do
    if btn and btn.SetAlpha then btn:SetAlpha(alpha) end
  end
end
local function SetActionBars2to8Alpha(alpha)
  local barNames = {
    "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
    "MultiBar5", "MultiBar6", "MultiBar7",
  }
  for _, name in ipairs(barNames) do
    local bar = _G[name]
    if bar and bar.SetAlpha then bar:SetAlpha(alpha) end
  end
end
local ab1MouseoverFrame = CreateFrame("Frame", "CCMAB1MouseoverFrame", UIParent)
ab1MouseoverFrame:SetFrameStrata("BACKGROUND")
ab1MouseoverFrame:SetFrameLevel(1)
ab1MouseoverFrame:SetSize(800, 80)
ab1MouseoverFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
ab1MouseoverFrame:EnableMouse(false)
ab1MouseoverFrame:Show()
local ab2MouseoverFrame = CreateFrame("Frame", "CCMAB2MouseoverFrame", UIParent)
ab2MouseoverFrame:SetFrameStrata("BACKGROUND")
ab2MouseoverFrame:SetFrameLevel(1)
ab2MouseoverFrame:SetSize(800, 80)
ab2MouseoverFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 80)
ab2MouseoverFrame:EnableMouse(false)
ab2MouseoverFrame:Show()
local stanceMouseoverFrame = CreateFrame("Frame", "CCMStanceMouseoverFrame", UIParent)
stanceMouseoverFrame:SetFrameStrata("BACKGROUND")
stanceMouseoverFrame:SetFrameLevel(1)
stanceMouseoverFrame:SetSize(200, 60)
stanceMouseoverFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
stanceMouseoverFrame:EnableMouse(false)
stanceMouseoverFrame:Show()
local ab2to8DetectionFrames = {}
local function UpdateMouseoverDetectionFrames()
  local mainBar = _G["MainMenuBar"]
  if mainBar and mainBar:IsShown() then
    ab1MouseoverFrame:ClearAllPoints()
    ab1MouseoverFrame:SetSize(mainBar:GetWidth() or 800, (mainBar:GetHeight() or 40) + 40)
    local point, relativeTo, relativePoint, x, y = mainBar:GetPoint()
    if point then
      ab1MouseoverFrame:SetPoint(point, relativeTo or UIParent, relativePoint or point, x or 0, (y or 0) - 20)
    else
      ab1MouseoverFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    end
  end
  local barNames = {"MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"}
  for i, barName in ipairs(barNames) do
    local bar = _G[barName]
    if bar and bar:IsShown() then
      if not ab2to8DetectionFrames[barName] then
        local df = CreateFrame("Frame", "CCM" .. barName .. "DetectionFrame", UIParent)
        df:SetFrameStrata("BACKGROUND")
        df:SetFrameLevel(1)
        df:EnableMouse(false)
        df:Show()
        ab2to8DetectionFrames[barName] = df
      end
      local df = ab2to8DetectionFrames[barName]
      df:ClearAllPoints()
      df:SetSize((bar:GetWidth() or 400) + 20, (bar:GetHeight() or 40) + 20)
      local point, relativeTo, relativePoint, x, y = bar:GetPoint()
      if point then
        df:SetPoint(point, relativeTo or UIParent, relativePoint or point, x or 0, y or 0)
      end
      df:Show()
    end
  end
  local stanceBar = _G["StanceBar"]
  if stanceBar and stanceBar:IsShown() then
    stanceMouseoverFrame:ClearAllPoints()
    stanceMouseoverFrame:SetSize((stanceBar:GetWidth() or 200) + 40, (stanceBar:GetHeight() or 40) + 20)
    local point, relativeTo, relativePoint, x, y = stanceBar:GetPoint()
    if point then
      stanceMouseoverFrame:SetPoint(point, relativeTo or UIParent, relativePoint or point, x or 0, y or 0)
    else
      stanceMouseoverFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    end
  end
end
C_Timer.After(2, UpdateMouseoverDetectionFrames)
local function IsMouseOverAB2to8DetectionFrames()
  for _, df in pairs(ab2to8DetectionFrames) do
    if df and df:IsShown() and df:IsMouseOver() then
      return true
    end
  end
  return false
end
local ab2to8BarsConst = {
  "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
  "MultiBar5", "MultiBar6", "MultiBar7",
}
local function IsMouseOverFrameOrChildren(frame)
  if not frame then return false end
  if frame:IsMouseOver() then return true end
  for i = 1, select('#', frame:GetChildren()) do
    local child = select(i, frame:GetChildren())
    if child and child:IsMouseOver() then
      return true
    end
  end
  return false
end
local function StartMouseCheck()
  if State.mouseCheckTicker then return end
  State.mouseCheckTicker = C_Timer.NewTicker(0.15, function()
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if not profile then return end
    if not InCombatLockdown() then
      if State.actionBar1Hidden then
        SetActionBar1Alpha(1)
        State.actionBar1Hidden = false
      end
      if State.actionBars2to8Hidden then
        SetActionBars2to8Alpha(1)
        State.actionBars2to8Hidden = false
      end
      if State.stanceBarHidden then
        SetStanceBarAlpha(1)
        State.stanceBarHidden = false
      end
      if State.petBarHidden then
        SetPetBarAlpha(1)
        State.petBarHidden = false
      end
      return
    end
    local mouseOverAB1 = false
    local mouseOverAB2to8 = false
    local mouseOverStance = false
    local mouseOverPet = false
    local ab1Mouseover = profile.hideActionBar1Mouseover == true
    local ab2to8Mouseover = profile.hideActionBars2to8Mouseover == true
    local stanceMouseover = profile.hideStanceBarMouseover == true
    local petMouseover = profile.hidePetBarMouseover == true
    local mouseOverCCMFrames = false
    if BuffIconCooldownViewer then
      if IsMouseOverFrameOrChildren(BuffIconCooldownViewer) then mouseOverCCMFrames = true end
    end
    if EssentialCooldownViewer then
      if IsMouseOverFrameOrChildren(EssentialCooldownViewer) then mouseOverCCMFrames = true end
    end
    if UtilityCooldownViewer then
      if IsMouseOverFrameOrChildren(UtilityCooldownViewer) then mouseOverCCMFrames = true end
    end
    for _, overlay in pairs(State.blizzBarDragOverlays) do
      if overlay and overlay:IsMouseOver() then
        mouseOverCCMFrames = true
        break
      end
    end
    if customBarFrame and customBarFrame:IsShown() and IsMouseOverFrameOrChildren(customBarFrame) then
      mouseOverCCMFrames = true
    end
    if customBar2Frame and customBar2Frame:IsShown() and IsMouseOverFrameOrChildren(customBar2Frame) then
      mouseOverCCMFrames = true
    end
    if customBar3Frame and customBar3Frame:IsShown() and IsMouseOverFrameOrChildren(customBar3Frame) then
      mouseOverCCMFrames = true
    end
    if prbFrame and prbFrame:IsShown() and IsMouseOverFrameOrChildren(prbFrame) then
      mouseOverCCMFrames = true
    end
    if mouseOverCCMFrames then
      mouseOverAB1 = false
      mouseOverAB2to8 = false
      mouseOverStance = false
    else
      local isOverExcludedFrame = false
      local spellOverlay = SpellActivationOverlayFrame
      if spellOverlay and spellOverlay:IsShown() and spellOverlay:IsMouseOver() then
        isOverExcludedFrame = true
      end
      local widgetCenter = UIWidgetCenterScreenContainerFrame
      if widgetCenter and widgetCenter:IsShown() and widgetCenter:IsMouseOver() then
        isOverExcludedFrame = true
      end
      if not isOverExcludedFrame then
        for _, name in ipairs(ab2to8BarsConst) do
          local bar = _G[name]
          if bar and bar:IsShown() and bar:IsMouseOver() then
            mouseOverAB2to8 = true
            break
          end
        end
        if not mouseOverAB2to8 and IsMouseOverAB2to8DetectionFrames() then
          mouseOverAB2to8 = true
        end
        if not mouseOverAB2to8 then
          for _, btn in ipairs(GetActionButtons()) do
            if btn and btn:IsShown() and btn:IsMouseOver() then
              mouseOverAB1 = true
              break
            end
          end
        end
        if not mouseOverAB1 and ab1MouseoverFrame and ab1MouseoverFrame:IsMouseOver() then
          mouseOverAB1 = true
        end
        for _, btn in ipairs(GetStanceButtons()) do
          if btn and btn:IsShown() and btn:IsMouseOver() then
            mouseOverStance = true
            break
          end
        end
        for _, f in ipairs(GetStanceBarFrames()) do
          if f and f:IsShown() and f:IsMouseOver() then
            mouseOverStance = true
            break
          end
        end
        if not mouseOverStance and stanceMouseoverFrame and stanceMouseoverFrame:IsMouseOver() then
          mouseOverStance = true
        end
        for _, btn in ipairs(GetPetButtons()) do
          if btn and btn:IsShown() and btn:IsMouseOver() then
            mouseOverPet = true
            break
          end
        end
        if not mouseOverPet then
          for _, f in ipairs(GetPetBarFrames()) do
            if f and f:IsShown() and f:IsMouseOver() then
              mouseOverPet = true
              break
            end
          end
        end
      end
    end
    local mouseOverAnyHiddenBar = false
    if profile.hideActionBar1InCombat and ab1Mouseover and mouseOverAB1 then mouseOverAnyHiddenBar = true end
    if profile.hideActionBars2to8InCombat and ab2to8Mouseover and mouseOverAB2to8 then mouseOverAnyHiddenBar = true end
    if profile.hideStanceBarInCombat and stanceMouseover and mouseOverStance then mouseOverAnyHiddenBar = true end
    if profile.hidePetBarInCombat and petMouseover and mouseOverPet then mouseOverAnyHiddenBar = true end
    local ab1HiddenByBlizz = false
    local ab2to8HiddenByBlizz = false
    local stanceHiddenByBlizz = false
    local petHiddenByBlizz = false
    local mainBar = _G["MainMenuBar"]
    if mainBar and (not mainBar:IsShown() or mainBar:GetAlpha() < 0.1) then
      ab1HiddenByBlizz = true
    end
    for _, name in ipairs(ab2to8BarsConst) do
      local bar = _G[name]
      if bar and (not bar:IsShown() or bar:GetAlpha() < 0.1) then
        ab2to8HiddenByBlizz = true
        break
      end
    end
    local stanceBar = _G["StanceBar"]
    if stanceBar and (not stanceBar:IsShown() or stanceBar:GetAlpha() < 0.1) then
      stanceHiddenByBlizz = true
    end
    local petBar = _G["PetActionBarFrame"] or _G["PetActionBar"]
    if petBar and (not petBar:IsShown() or petBar:GetAlpha() < 0.1) then
      petHiddenByBlizz = true
    end
    if ab1Mouseover and mouseOverAB1 and ab1HiddenByBlizz then mouseOverAnyHiddenBar = true end
    if ab2to8Mouseover and mouseOverAB2to8 and ab2to8HiddenByBlizz then mouseOverAnyHiddenBar = true end
    if stanceMouseover and mouseOverStance and stanceHiddenByBlizz then mouseOverAnyHiddenBar = true end
    if petMouseover and mouseOverPet and petHiddenByBlizz then mouseOverAnyHiddenBar = true end
    if profile.hideActionBar1InCombat or ab1HiddenByBlizz then
      local showAB1 = mouseOverAnyHiddenBar
      if showAB1 then
        if State.actionBar1Hidden or ab1HiddenByBlizz then
          SetActionBar1Alpha(1)
          State.actionBar1Hidden = false
        end
      else
        if profile.hideActionBar1InCombat and not State.actionBar1Hidden then
          SetActionBar1Alpha(0)
          State.actionBar1Hidden = true
        end
      end
    end
    if profile.hideActionBars2to8InCombat or ab2to8HiddenByBlizz then
      local showAB2to8 = mouseOverAnyHiddenBar
      if showAB2to8 then
        if State.actionBars2to8Hidden or ab2to8HiddenByBlizz then
          SetActionBars2to8Alpha(1)
          State.actionBars2to8Hidden = false
        end
      else
        if profile.hideActionBars2to8InCombat and not State.actionBars2to8Hidden then
          SetActionBars2to8Alpha(0)
          State.actionBars2to8Hidden = true
        end
      end
    end
    if profile.hideStanceBarInCombat or stanceHiddenByBlizz then
      local showStance = mouseOverAnyHiddenBar
      if showStance then
        if State.stanceBarHidden or stanceHiddenByBlizz then
          SetStanceBarAlpha(1)
          State.stanceBarHidden = false
        end
      else
        if profile.hideStanceBarInCombat and not State.stanceBarHidden then
          SetStanceBarAlpha(0)
          State.stanceBarHidden = true
        end
      end
    end
    if profile.hidePetBarInCombat or petHiddenByBlizz then
      local showPet = mouseOverAnyHiddenBar
      if showPet then
        if State.petBarHidden or petHiddenByBlizz then
          SetPetBarAlpha(1)
          State.petBarHidden = false
        end
      else
        if profile.hidePetBarInCombat and not State.petBarHidden then
          SetPetBarAlpha(0)
          State.petBarHidden = true
        end
      end
    end
  end)
end
local function StopMouseCheck()
  if State.mouseCheckTicker then
    State.mouseCheckTicker:Cancel()
    State.mouseCheckTicker = nil
  end
end
local function SetupActionBarHiding()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local hideAB1 = profile.hideActionBar1InCombat == true
  local hideAB2to8 = profile.hideActionBars2to8InCombat == true
  local hideStance = profile.hideStanceBarInCombat == true
  local hidePet = profile.hidePetBarInCombat == true
  local anyMouseover = profile.hideActionBar1Mouseover or profile.hideActionBars2to8Mouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
  if hideAB1 or hideAB2to8 or hideStance or hidePet or anyMouseover then
    if InCombatLockdown() then
      StartMouseCheck()
      if hideAB1 then
        SetActionBar1Alpha(0)
        State.actionBar1Hidden = true
      end
      if hideAB2to8 then
        SetActionBars2to8Alpha(0)
        State.actionBars2to8Hidden = true
      end
      if hideStance then
        SetStanceBarAlpha(0)
        State.stanceBarHidden = true
      end
      if hidePet then
        SetPetBarAlpha(0)
        State.petBarHidden = true
      end
    end
  else
    StopMouseCheck()
    if State.actionBar1Hidden then
      SetActionBar1Alpha(1)
      State.actionBar1Hidden = false
    end
    if State.actionBars2to8Hidden then
      SetActionBars2to8Alpha(1)
      State.actionBars2to8Hidden = false
    end
    if State.stanceBarHidden then
      SetStanceBarAlpha(1)
      State.stanceBarHidden = false
    end
    if State.petBarHidden then
      SetPetBarAlpha(1)
      State.petBarHidden = false
    end
  end
end
addonTable.SetupActionBarHiding = SetupActionBarHiding
local function UpdateActionBarVisibility()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local inCombat = InCombatLockdown()
  if inCombat then
    if profile.hideActionBar1InCombat then
      if not State.actionBar1Hidden then
        SetActionBar1Alpha(0)
        State.actionBar1Hidden = true
      end
    else
      if State.actionBar1Hidden then
        SetActionBar1Alpha(1)
        State.actionBar1Hidden = false
      end
    end
    if profile.hideActionBars2to8InCombat then
      if not State.actionBars2to8Hidden then
        SetActionBars2to8Alpha(0)
        State.actionBars2to8Hidden = true
      end
    else
      if State.actionBars2to8Hidden then
        SetActionBars2to8Alpha(1)
        State.actionBars2to8Hidden = false
      end
    end
    if profile.hideStanceBarInCombat then
      if not State.stanceBarHidden then
        SetStanceBarAlpha(0)
        State.stanceBarHidden = true
      end
    else
      if State.stanceBarHidden then
        SetStanceBarAlpha(1)
        State.stanceBarHidden = false
      end
    end
    if profile.hidePetBarInCombat then
      if not State.petBarHidden then
        SetPetBarAlpha(0)
        State.petBarHidden = true
      end
    else
      if State.petBarHidden then
        SetPetBarAlpha(1)
        State.petBarHidden = false
      end
    end
    local anyHideInCombat = profile.hideActionBar1InCombat or profile.hideActionBars2to8InCombat or profile.hideStanceBarInCombat or profile.hidePetBarInCombat
    local anyMouseover = profile.hideActionBar1Mouseover or profile.hideActionBars2to8Mouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
    if anyHideInCombat or anyMouseover then
      StartMouseCheck()
    else
      StopMouseCheck()
    end
  else
    SetActionBar1Alpha(1)
    SetActionBars2to8Alpha(1)
    SetStanceBarAlpha(1)
    SetPetBarAlpha(1)
    State.actionBar1Hidden = false
    State.actionBars2to8Hidden = false
    State.stanceBarHidden = false
    State.petBarHidden = false
    StopMouseCheck()
  end
end
addonTable.UpdateActionBarVisibility = UpdateActionBarVisibility
actionBarHideFrame:SetScript("OnEvent", function(self, event)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if event == "PLAYER_REGEN_DISABLED" then
    HideBlizzBarPreviews()
    if UpdateMouseoverDetectionFrames then UpdateMouseoverDetectionFrames() end
    local anyHideInCombat = profile.hideActionBar1InCombat or profile.hideActionBars2to8InCombat or profile.hideStanceBarInCombat or profile.hidePetBarInCombat
    local anyMouseover = profile.hideActionBar1Mouseover or profile.hideActionBars2to8Mouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
    if anyHideInCombat or anyMouseover then
      StartMouseCheck()
    end
    if profile.hideActionBar1InCombat then
      SetActionBar1Alpha(0)
      State.actionBar1Hidden = true
    end
    if profile.hideActionBars2to8InCombat then
      SetActionBars2to8Alpha(0)
      State.actionBars2to8Hidden = true
    end
    if profile.hideStanceBarInCombat then
      SetStanceBarAlpha(0)
      State.stanceBarHidden = true
    end
    if profile.hidePetBarInCombat then
      SetPetBarAlpha(0)
      State.petBarHidden = true
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    StopMouseCheck()
    if State.actionBar1Hidden then
      SetActionBar1Alpha(1)
      State.actionBar1Hidden = false
    end
    if State.actionBars2to8Hidden then
      SetActionBars2to8Alpha(1)
      State.actionBars2to8Hidden = false
    end
    if State.stanceBarHidden then
      SetStanceBarAlpha(1)
      State.stanceBarHidden = false
    end
    if State.petBarHidden then
      SetPetBarAlpha(1)
      State.petBarHidden = false
    end
    C_Timer.After(0.5, function()
      if not InCombatLockdown() and UpdateMouseoverDetectionFrames then
        UpdateMouseoverDetectionFrames()
      end
    end)
  elseif event == "PLAYER_ENTERING_WORLD" then
    C_Timer.After(1, SetupActionBarHiding)
    C_Timer.After(3, function()
      if addonTable.SetupBlizzBarClickHandlers then
        addonTable.SetupBlizzBarClickHandlers()
      end
    end)
    C_Timer.After(2, function()
      local profile = addonTable.GetProfile()
      if profile and profile.useFrameSkin and addonTable.ApplyFrameSkin then
        addonTable.ApplyFrameSkin()
      end
    end)
  end
end)
C_Timer.After(2, SetupActionBarHiding)
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
          addonTable.standalone.buffYSlider:SetValue(math.floor(relY))
        end
      elseif barType == "essential" then
        profile.blizzBarEssentialX = relX
        profile.blizzBarEssentialY = relY
        profile.standaloneEssentialY = relY
        if addonTable.standalone and addonTable.standalone.essentialYSlider then
          addonTable.standalone.essentialYSlider:SetValue(math.floor(relY))
        end
      elseif barType == "utility" then
        profile.blizzBarUtilityX = relX
        profile.blizzBarUtilityY = relY
        profile.standaloneUtilityY = relY
        if addonTable.standalone and addonTable.standalone.utilityYSlider then
          addonTable.standalone.utilityYSlider:SetValue(math.floor(relY))
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
          addonTable.standalone.buffYSlider:SetValue(math.floor(relY))
        end
      elseif barType == "essential" then
        profile.blizzBarEssentialX = relX
        profile.blizzBarEssentialY = relY
        profile.standaloneEssentialY = relY
        if addonTable.standalone and addonTable.standalone.essentialYSlider then
          addonTable.standalone.essentialYSlider:SetValue(math.floor(relY))
        end
      elseif barType == "utility" then
        profile.blizzBarUtilityX = relX
        profile.blizzBarUtilityY = relY
        profile.standaloneUtilityY = relY
        if addonTable.standalone and addonTable.standalone.utilityYSlider then
          addonTable.standalone.utilityYSlider:SetValue(math.floor(relY))
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
  if prbFrame and prbFrame.highlightVisible then
    prbFrame.highlightVisible = nil
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if not profile or not profile.usePersonalResourceBar then
      prbFrame:Hide()
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
  elseif tabIdx == 6 then
    ShowBlizzBarDragOverlays(true)
  elseif tabIdx == 7 then
    if prbFrame then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile and profile.usePersonalResourceBar then
        if not prbFrame:IsShown() then
          prbFrame:SetSize(220, 30)
          prbFrame:Show()
          prbFrame.highlightVisible = true
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
          elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" then
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
        highlight:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", -14, maxY + 14)
        highlight:SetPoint("BOTTOMRIGHT", prbFrame, "TOPLEFT", width + 14, minY - 24)
        highlight:Show()
      end
    end
  elseif tabIdx == 8 then
    if not castbarFrame:IsShown() then
      if addonTable.ShowCastbarPreview then addonTable.ShowCastbarPreview() end
    end
    if castbarFrame then
      HighlightFrame(1, castbarFrame)
    end
  elseif tabIdx == 9 then
    if addonTable.FocusCastbarFrame and not addonTable.FocusCastbarFrame:IsShown() then
      if addonTable.ShowFocusCastbarPreview then addonTable.ShowFocusCastbarPreview() end
    end
    if addonTable.FocusCastbarFrame then
      HighlightFrame(1, addonTable.FocusCastbarFrame)
    end
  elseif tabIdx == 10 then
    if not debuffFrame or not debuffFrame:IsShown() then
      if addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
    end
    if debuffFrame then
      local minX, maxX, minY, maxY
      local frameLeft, frameRight = debuffFrame:GetLeft(), debuffFrame:GetRight()
      local frameBottom, frameTop = debuffFrame:GetBottom(), debuffFrame:GetTop()
      if frameLeft and frameRight and frameBottom and frameTop then
        for i = 1, MAX_DEBUFF_ICONS do
          local icon = debuffIcons[i]
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
        highlight:SetPoint("BOTTOMLEFT", debuffFrame, "BOTTOMLEFT", minX - 4, minY - 4)
        highlight:SetPoint("TOPRIGHT", debuffFrame, "BOTTOMLEFT", maxX + 4, maxY + 4)
        highlight:Show()
      else
        HighlightFrame(1, debuffFrame)
      end
    end
  end
end
addonTable.HighlightCustomBar = HighlightCustomBar
addonTable.GetDefaults = function() return defaults end
addonTable.GetIcons = function() return State.cursorIcons end
addonTable.SetGUIOpen = function(open) 
  State.guiIsOpen = open
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
    if prbFrame then prbFrame:SetMovable(true) end
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
    if prbFrame then prbFrame:SetMovable(false) end
    HideAllHighlights()
    HideBlizzBarPreviews()
    HideBlizzBarDragOverlays()
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
    useBiggerPlayerHealthframe = "ufCustomizeHealth",
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
  if not profile.trackedSpells then profile.trackedSpells = {} end
  if not profile.spellsEnabled then profile.spellsEnabled = {} end
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
  return profile
end
addonTable.GetProfile = GetProfile
addonTable.GetGlobalFont = GetGlobalFont
addonTable.IsClassPowerRedundant = IsClassPowerRedundant
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
  if not profile then return {}, {} end
  if not profile.trackedSpells then profile.trackedSpells = {} end
  if not profile.spellsEnabled then profile.spellsEnabled = {} end
  return profile.trackedSpells, profile.spellsEnabled
end
local function SetSpellList(spells, enabled)
  local profile = addonTable.GetProfile()
  if not profile then return end
  profile.trackedSpells = spells or {}
  profile.spellsEnabled = enabled or {}
end
addonTable.GetSpellList = GetSpellList
addonTable.SetSpellList = SetSpellList
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
  if not CooldownCursorManagerDB then return {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBarSpells = CooldownCursorManagerDB.characterCustomBarSpells or {}
  CooldownCursorManagerDB.characterCustomBarSpells[charKey] = CooldownCursorManagerDB.characterCustomBarSpells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] = CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled = CooldownCursorManagerDB.characterCustomBarSpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBarSpells[charKey][specID], CooldownCursorManagerDB.characterCustomBarSpellsEnabled[charKey][specID]
end
local function SetCustomBarSpells(spells, enabled)
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
end
addonTable.GetCharacterKey = GetCharacterKey
addonTable.GetCurrentSpecID = GetCurrentSpecID
addonTable.GetCustomBarSpells = GetCustomBarSpells
addonTable.SetCustomBarSpells = SetCustomBarSpells
local function GetCustomBar2Spells()
  if not CooldownCursorManagerDB then return {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar2Spells = CooldownCursorManagerDB.characterCustomBar2Spells or {}
  CooldownCursorManagerDB.characterCustomBar2Spells[charKey] = CooldownCursorManagerDB.characterCustomBar2Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBar2Spells[charKey][specID], CooldownCursorManagerDB.characterCustomBar2SpellsEnabled[charKey][specID]
end
local function SetCustomBar2Spells(spells, enabled)
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
end
addonTable.GetCustomBar2Spells = GetCustomBar2Spells
addonTable.SetCustomBar2Spells = SetCustomBar2Spells
local function GetCustomBar3Spells()
  if not CooldownCursorManagerDB then return {}, {} end
  local charKey = GetCharacterKey()
  if not charKey then return {}, {} end
  local specID = GetCurrentSpecID()
  CooldownCursorManagerDB.characterCustomBar3Spells = CooldownCursorManagerDB.characterCustomBar3Spells or {}
  CooldownCursorManagerDB.characterCustomBar3Spells[charKey] = CooldownCursorManagerDB.characterCustomBar3Spells[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey] = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey] or {}
  CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID] = CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID] or {}
  return CooldownCursorManagerDB.characterCustomBar3Spells[charKey][specID], CooldownCursorManagerDB.characterCustomBar3SpellsEnabled[charKey][specID]
end
local function SetCustomBar3Spells(spells, enabled)
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
end
addonTable.GetCustomBar3Spells = GetCustomBar3Spells
addonTable.SetCustomBar3Spells = SetCustomBar3Spells
local function IsSpellKnownByPlayer(spellID)
  if not spellID then return false end
  if IsSpellKnown(spellID) then return true end
  if IsPlayerSpell(spellID) then return true end
  if IsSpellKnown(spellID, true) then return true end
  return false
end
addonTable.IsSpellKnownByPlayer = IsSpellKnownByPlayer
local function IsTrackedEntryAvailable(isItem, originalID, activeID)
  if isItem then
    local count = GetItemCount(originalID, true, true)
    if not count or count <= 0 then
      return false
    end
    return true
  end
  if IsSpellKnownByPlayer(activeID) then return true end
  if IsSpellKnownByPlayer(originalID) then return true end
  return false
end
local function ResolveTrackedSpellID(spellID)
  if type(spellID) ~= "number" then return spellID end
  if FindSpellOverrideByID then
    local okOverride, overrideID = pcall(FindSpellOverrideByID, spellID)
    if okOverride and type(overrideID) == "number" and overrideID > 0 and overrideID ~= spellID then
      return overrideID
    end
  end
  if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
    local okBookOverride, bookOverrideID = pcall(C_SpellBook.FindSpellOverrideByID, spellID)
    if okBookOverride and type(bookOverrideID) == "number" and bookOverrideID > 0 and bookOverrideID ~= spellID then
      return bookOverrideID
    end
  end
  local baseInfo = C_Spell.GetSpellInfo(spellID)
  local spellName = baseInfo and baseInfo.name
  if not spellName then return spellID end
  local replacementInfo = C_Spell.GetSpellInfo(spellName)
  local replacementID = replacementInfo and replacementInfo.spellID
  if type(replacementID) == "number" and replacementID > 0 and replacementID ~= spellID then
    return replacementID
  end
  return spellID
end
local ringFrame = CreateFrame("Frame", "CCMRadialCircle", UIParent)
ringFrame:SetSize(120, 120)
ringFrame:SetFrameStrata("TOOLTIP")
ringFrame:SetFrameLevel(200)
ringFrame:Hide()
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
ringFrame:SetScript("OnUpdate", function(self)
  local now = GetTime()
  if now - State.lastScaleUpdate > 0.5 then
    State.cachedUIScale = UIParent:GetEffectiveScale()
    State.lastScaleUpdate = now
  end
  local x, y = GetCursorPosition()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / State.cachedUIScale, y / State.cachedUIScale)
end)
local function UpdateRadialCircle()
  local profile = addonTable.GetProfile()
  if not profile or not profile.showRadialCircle then
    ringFrame:Hide()
    State.ringEnabled = false
    return
  end
  if State.guiIsOpen then
    local cfg = addonTable.ConfigFrame
    if cfg then
      ringFrame:SetFrameStrata(cfg:GetFrameStrata() or "TOOLTIP")
      ringFrame:SetFrameLevel((cfg:GetFrameLevel() or 1) + 50)
    else
      ringFrame:SetFrameStrata("TOOLTIP")
      ringFrame:SetFrameLevel(5000)
    end
  end
  State.ringCombatOnly = profile.cursorCombatOnly or profile.showInCombatOnly
  if State.ringCombatOnly and not UnitAffectingCombat("player") then
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
  local iconStrata = profile.iconStrata or "TOOLTIP"
  buffs:SetFrameStrata(iconStrata)
  buffs:SetFrameLevel(200)
  local posX = (cursorX / uiScale) + profile.offsetX
  local posY = (cursorY / uiScale) + profile.offsetY
  wipe(State.buffBarVisibleIcons)
  local childCount = addonTable.CollectChildren(buffs, State.tmpChildren)
  for i = 1, childCount do
    local child = State.tmpChildren[i]
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
  if buffs.Layout then buffs.Layout = function() end end
  if buffs.MarkDirty then buffs.MarkDirty = function() end end
  if buffs.layout then buffs.layout = nil end
  for i, icon in ipairs(State.buffBarVisibleIcons) do
    icon:SetSize(targetSize, targetSize)
    local iconX = (i - 1) * (targetSize + spacing)
    icon:ClearAllPoints()
    icon:SetPoint("BOTTOMLEFT", buffs, "BOTTOMLEFT", iconX, 0)
    if icon.Layout then icon.Layout = function() end end
    if icon.MarkDirty then icon.MarkDirty = function() end end
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
      icon.ccmChargeText:SetFont(globalFont, ccmSize, globalOutline ~= "" and globalOutline or "OUTLINE")
    end
    if icon.ccmCooldown then
      local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
      icon.ccmCooldown:SetScale(cdTextScale * 0.8)
      local globalFont, globalOutline = GetGlobalFont()
      local regionCount = addonTable.CollectRegions(icon.ccmCooldown, State.tmpRegions)
      for r = 1, regionCount do
        local region = State.tmpRegions[r]
        if region and region:GetObjectType() == "FontString" then
          local _, size = region:GetFont()
          if size then
            region:SetFont(globalFont, size, globalOutline ~= "" and globalOutline or "OUTLINE")
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
                region:SetFont(globalFont, size, globalOutline ~= "" and globalOutline or "OUTLINE")
              end
            end
          end
        end
      end
      local chargeText = (icon.ChargeCount and icon.ChargeCount.Current) or (icon.Applications and icon.Applications.Applications)
      if chargeText then
        local _, ccmSize = GameFontHighlightLarge:GetFont()
        chargeText:SetFont(globalFont, ccmSize, globalOutline ~= "" and globalOutline or "OUTLINE")
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
  local iconStrata = profile.iconStrata or "TOOLTIP"
  main:SetFrameStrata(iconStrata)
  main:SetFrameLevel(200)
  local posX = (cursorX / uiScale) + profile.offsetX
  local posY = (cursorY / uiScale) + profile.offsetY
  local essentialBarX = posX + buffBarWidth
  wipe(State.essentialBarVisibleIcons)
  local childCount = addonTable.CollectChildren(main, State.tmpChildren)
  for i = 1, childCount do
    local child = State.tmpChildren[i]
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
  if main.Layout then main.Layout = function() end end
  if main.MarkDirty then main.MarkDirty = function() end end
  if main.layout then main.layout = nil end
  for i, icon in ipairs(State.essentialBarVisibleIcons) do
    local targetSize = type(profile.iconSize) == "number" and profile.iconSize or 23
    icon:SetSize(targetSize, targetSize)
    local iconX = (i - 1) * (targetSize + padding)
    icon:ClearAllPoints()
    icon:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", iconX, 0)
    if icon.Layout then icon.Layout = function() end end
    if icon.MarkDirty then icon.MarkDirty = function() end end
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
      icon.ccmChargeText:SetFont(globalFont, ccmSize, globalOutline ~= "" and globalOutline or "OUTLINE")
    end
    if icon.ccmCooldown and doSkinning then
      local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
      icon.ccmCooldown:SetScale(cdTextScale * 0.8)
    end
    if icon.ccmCooldown then
      local globalFont, globalOutline = GetGlobalFont()
      local regionCount = addonTable.CollectRegions(icon.ccmCooldown, State.tmpRegions)
      for r = 1, regionCount do
        local region = State.tmpRegions[r]
        if region and region:GetObjectType() == "FontString" then
          local _, size = region:GetFont()
          if size then
            region:SetFont(globalFont, size, globalOutline ~= "" and globalOutline or "OUTLINE")
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
                region:SetFont(globalFont, size, globalOutline ~= "" and globalOutline or "OUTLINE")
              end
            end
          end
        end
      end
      local chargeText = (icon.ChargeCount and icon.ChargeCount.Current) or (icon.Applications and icon.Applications.Applications)
      if chargeText then
        local _, ccmSize = GameFontHighlightLarge:GetFont()
        chargeText:SetFont(globalFont, ccmSize, globalOutline ~= "" and globalOutline or "OUTLINE")
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
  if centered then
    if canResizeFrame then
      if pinFirstRowY then
        frame:SetSize(totalWidth, firstRowSize)
      else
        frame:SetSize(totalWidth, totalHeight)
      end
    end
  end
  local iconIndex = 1
  local yTop = 0
  for row = 1, rowCount do
    local iconsInRow = rowIconCounts[row]
    local size = rowSizes[row]
    local rowWidth = rowWidths[row]
    local startX = centered and ((totalWidth - rowWidth) / 2) or 0
    if (not centered) and growLeft then
      startX = totalWidth - rowWidth
    end
    for col = 1, iconsInRow do
      local icon = visibleIcons[iconIndex]
      if icon then
        local vCol = growLeft and (iconsInRow - col) or (col - 1)
      local xPos = startX + (vCol * (size + spacing))
      icon:SetSize(size, size)
      icon:ClearAllPoints()
      if growUp then
        local yPos
        if pinFirstRowY then
          yPos = -yTop
        else
          yPos = totalHeight - yTop - size
        end
        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", SnapHalf(xPos), -SnapHalf(yPos))
      else
        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", SnapHalf(xPos), -SnapHalf(yTop))
      end
      end
      iconIndex = iconIndex + 1
    end
    yTop = yTop + size + rowSpacing
  end
  return totalWidth, totalHeight
end
local function SkinStandaloneBarIcon(icon, profile)
  if not icon or not icon:IsShown() or icon:GetWidth() <= 5 then return end
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
    icon.ccmStandaloneChargeText:SetFont(globalFont, ccmSize, globalOutline ~= "" and globalOutline or "OUTLINE")
  end
  do
    local iconChildCount = addonTable.CollectChildren(icon, State.tmpIconChildren)
    local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
    local globalFont, globalOutline = GetGlobalFont()
    for c = 1, iconChildCount do
      local child = State.tmpIconChildren[c]
      if child and child:GetObjectType() == "Cooldown" then
        icon.ccmStandaloneCooldown = child
        child:SetScale(cdTextScale * 0.8)
        local regionCount = addonTable.CollectRegions(child, State.tmpChildRegions)
        for r = 1, regionCount do
          local region = State.tmpChildRegions[r]
          if region and region:GetObjectType() == "FontString" then
            local _, size = region:GetFont()
            if size then
              region:SetFont(globalFont, size, globalOutline ~= "" and globalOutline or "OUTLINE")
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
              region:SetFont(globalFont, size, globalOutline ~= "" and globalOutline or "OUTLINE")
            end
          end
        end
      end
    end
    local chargeText = (icon.ChargeCount and icon.ChargeCount.Current) or (icon.Applications and icon.Applications.Applications)
    if chargeText then
      local _, ccmSize = GameFontHighlightLarge:GetFont()
      chargeText:SetFont(globalFont, ccmSize, globalOutline ~= "" and globalOutline or "OUTLINE")
    end
  end
end
local function UpdateStandaloneBlizzardBars()
  local profile = addonTable.GetProfile()
  if not profile then return end
  local function IsValidStandaloneIcon(icon)
    if not icon or not icon:IsShown() or icon:GetWidth() <= 5 then return false end
    local tex = icon.Icon or icon.icon
    if not tex then return false end
    local hasTex = tex.GetTexture and tex:GetTexture()
    local hasAtlas = tex.GetAtlas and tex:GetAtlas()
    return hasTex ~= nil or hasAtlas ~= nil
  end
  if profile.disableBlizzCDM == true then
    if not InCombatLockdown() then
      if State.standaloneBuffOriginals.saved and BuffIconCooldownViewer then
        RestoreStandaloneBar(BuffIconCooldownViewer, State.standaloneBuffOriginals)
      end
      if State.standaloneEssentialOriginals.saved and EssentialCooldownViewer then
        RestoreStandaloneBar(EssentialCooldownViewer, State.standaloneEssentialOriginals)
      end
      if State.standaloneUtilityOriginals.saved and UtilityCooldownViewer then
        RestoreStandaloneBar(UtilityCooldownViewer, State.standaloneUtilityOriginals)
      end
    end
    State.standaloneSkinActive = false
    State.standaloneNeedsSkinning = false
    return
  end
  if not InCombatLockdown() then
    if profile.useBuffBar and State.standaloneBuffOriginals.saved and BuffIconCooldownViewer then
      RestoreStandaloneBar(BuffIconCooldownViewer, State.standaloneBuffOriginals)
    end
    if profile.useEssentialBar and State.standaloneEssentialOriginals.saved and EssentialCooldownViewer then
      RestoreStandaloneBar(EssentialCooldownViewer, State.standaloneEssentialOriginals)
    end
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
  local canReposition = not InCombatLockdown()
  local buffCentered = profile.standaloneBuffCentered == true
  local essentialCentered = profile.standaloneEssentialCentered == true
  local utilityCentered = profile.standaloneUtilityCentered == true
  local anyCentered = buffCentered or essentialCentered or utilityCentered
  if anyCentered and not needsSkinning and not guiOpen then
    local now = GetTime()
    if (now - State.lastStandaloneUpdate) < 0.2 then
      return
    end
    State.lastStandaloneUpdate = now
  end
  if not needsSkinning and not guiOpen and not anyCentered and State.standaloneSkinActive then
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
            SkinStandaloneBarIcon(icon, profile)
          end
          icon:SetSize(buffSize, buffSize)
          table.insert(visibleIcons, icon)
        end
      end
      if #visibleIcons > 1 then
        table.sort(visibleIcons, function(a, b)
          local idxA = a.layoutIndex or 0
          local idxB = b.layoutIndex or 0
          return idxA < idxB
        end)
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
        if canReposition and (buffCentered or profile.blizzBarBuffX ~= nil or profile.blizzBarBuffY ~= nil or State.guiIsOpen) then
          buffs:ClearAllPoints()
          SetPointSnapped(buffs, "CENTER", UIParent, "CENTER", buffPosX, buffPosY)
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
        if needsSkinning or State.standaloneBuffLayoutKey ~= buffLayoutKey then
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
    if canReposition then
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
            SkinStandaloneBarIcon(icon, profile)
          end
          icon:SetSize(essentialSize, essentialSize)
          table.insert(visibleIcons, icon)
        end
      end
      if #visibleIcons > 1 then
        table.sort(visibleIcons, function(a, b)
          local idxA = a.layoutIndex or 0
          local idxB = b.layoutIndex or 0
          return idxA < idxB
        end)
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
        if canReposition and (essentialCentered or profile.blizzBarEssentialX ~= nil or profile.blizzBarEssentialY ~= nil or State.guiIsOpen) then
          main:ClearAllPoints()
          SetPointSnapped(main, "CENTER", UIParent, "CENTER", essentialPosX, essentialPosY)
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
        if needsSkinning or State.standaloneEssentialLayoutKey ~= essentialLayoutKey then
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
            layoutMaxRows
          )
          State.standaloneEssentialWidth = layoutWidth or 0
        end
      else
        State.standaloneEssentialWidth = 0
        State.standaloneEssentialLayoutKey = nil
      end
    end
  elseif State.standaloneEssentialOriginals.saved and EssentialCooldownViewer then
    if canReposition then
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
            SkinStandaloneBarIcon(icon, profile)
          end
          icon:SetSize(utilitySize, utilitySize)
          table.insert(visibleIcons, icon)
        end
      end
      if #visibleIcons > 1 then
        table.sort(visibleIcons, function(a, b)
          local idxA = a.layoutIndex or 0
          local idxB = b.layoutIndex or 0
          return idxA < idxB
        end)
      end
      if #visibleIcons > 0 then
        local iconSize = utilitySize
        local iconSpacing = spacing
        if iconSpacing == 0 then
          iconSpacing = -1
        end
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
        if canReposition and (utilityCentered or profile.blizzBarUtilityX ~= nil or profile.blizzBarUtilityY ~= nil or State.guiIsOpen) then
          utility:ClearAllPoints()
          utility:SetPoint("CENTER", UIParent, "CENTER", utilityPosX, utilityPosY)
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
        if needsSkinning or State.standaloneUtilityLayoutKey ~= utilityLayoutKey then
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
    if canReposition then
      RestoreStandaloneBar(UtilityCooldownViewer, State.standaloneUtilityOriginals)
    end
    State.standaloneUtilityLayoutKey = nil
  end
  State.standaloneSkinActive = anyActive
  if needsSkinning then
    State.standaloneNeedsSkinning = false
  end
end
addonTable.UpdateStandaloneBlizzardBars = UpdateStandaloneBlizzardBars
if CooldownViewerSettings and CooldownViewerSettings.RefreshLayout then
  hooksecurefunc(CooldownViewerSettings, "RefreshLayout", function()
    if InCombatLockdown() then return end
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
  end)
end
if EditModeManagerFrame then
  hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
    if InCombatLockdown() then return end
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
  end)
end
local function ClearCustomBarIcons()
  if Masque and MasqueGroups.CustomBar then
    for _, icon in ipairs(State.customBar1Icons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CustomBar)
    end
  end
  for _, icon in ipairs(State.customBar1Icons) do
    icon:Hide()
    icon:SetScript("OnUpdate", nil)
  end
  wipe(State.customBar1Icons)
end
local function ResolveCustomBarAnchorFrame(anchorName)
  local raw = type(anchorName) == "string" and anchorName or ""
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if trimmed == "" then return UIParent, "UIParent" end
  local normalized = trimmed:lower():gsub("_", "")
  if normalized == "uiparent" then return UIParent, "UIParent" end
  State.customBarAnchorCache = State.customBarAnchorCache or {}
  local cache = State.customBarAnchorCache
  local cached = cache[normalized]
  if cached ~= nil then
    return cached, (cached.GetName and cached:GetName()) or trimmed
  end
  local frame = _G[trimmed]
  if not (frame and frame.GetObjectType) then
    for name, obj in pairs(_G) do
      if type(name) == "string" and obj and obj.GetObjectType and name:lower():gsub("_", "") == normalized then
        frame = obj
        break
      end
    end
  end
  if frame and frame.GetObjectType then
    cache[normalized] = frame
    return frame, (frame.GetName and frame:GetName()) or trimmed
  end
  return UIParent, "UIParent"
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
  local entries, entriesEnabled = GetCustomBarSpells()
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
      icon:SetFrameStrata(profile.iconStrata or "TOOLTIP")
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
      icon.Count:SetFont(globalFont, fontSize, globalOutline ~= "" and globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      if icon.isItem then
        local itemIcon = GetItemIcon(icon.actualID) or C_Item.GetItemIconByID(icon.actualID)
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
  if centered then
    x = 0 + x
  end
  if not State.cb1Dragging then
    customBarFrame:ClearAllPoints()
    customBarFrame:SetPoint("CENTER", anchorFrame, "CENTER", x, y)
  end
  customBarFrame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar then
    ReSkinMasqueGroup(MasqueGroups.CustomBar)
  end
end
local function UpdateCustomBar()
  if State.customBar1Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBarEnabled then
    customBarFrame:Hide()
    return
  end
  if not IsShowModeActive(profile.customBarShowMode) then
    customBarFrame:Hide()
    return
  end
  if profile.customBarOutOfCombat == false and not InCombatLockdown() then
    if not customBarFrame.highlightVisible then
      customBarFrame:Hide()
      return
    end
  end
  if #State.customBar1Icons == 0 then
    if not customBarFrame.highlightVisible then
      customBarFrame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBarIconSize) == "number" and profile.customBarIconSize or 30
  local spacing = type(profile.customBarSpacing) == "number" and profile.customBarSpacing or 2
  local growth = profile.customBarGrowth or "DOWN"
  local anchor = profile.customBarAnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBarCdTextScale) == "number" and profile.customBarCdTextScale or 1.0
  local stackTextScale = type(profile.customBarStackTextScale) == "number" and profile.customBarStackTextScale or 1.0
  local centered = profile.customBarCentered == true
  local cooldownMode = profile.customBarCooldownMode or "show"
  local iconsPerRow = type(profile.customBarIconsPerRow) == "number" and profile.customBarIconsPerRow or 20
  local showGCD = profile.customBarShowGCD == true
  wipe(State.customBarVisibleIcons)
  local visibleIcons = State.customBarVisibleIcons
  for originalIdx, icon in ipairs(State.customBar1Icons) do
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
        iconTexture = GetItemIcon(actualID) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(actualID))
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = GetItemCount(actualID, false, true)
      if itemCount == 0 then
        itemCount = C_Item.GetItemCount(actualID, false, true)
      end
      if not itemCount or itemCount <= 0 then
        iconTexture = nil
      end
      cdStart, cdDuration = GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration then
        icon.cooldown:SetCooldown(cdStart, cdDuration)
      else
        icon.cooldown:SetCooldown(0, 0)
      end
      icon.cooldown:SetDrawEdge(false)
      icon.cooldown:SetDrawBling(false)
      local start, duration = icon.cooldown:GetCooldownTimes()
      local startOk = start and IsRealNumber(start)
      local durOk = duration and IsRealNumber(duration)
      if startOk and durOk and start > 0 and duration > 1500 then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID) then
        iconTexture = nil
        icon.cooldown:SetCooldown(0, 0)
      else
        local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
        iconTexture = spellInfo and spellInfo.iconID or nil
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData and issecretvalue and issecretvalue(chargesData.maxCharges) then
          chargesData._secretMax = true
        end
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          icon.cooldown:SetCooldown(cdStart, cdDuration)
          icon.cooldown:SetDrawEdge(false)
          icon.cooldown:SetDrawBling(false)
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
              icon.cooldown:SetCooldown(0, 0)
            else
              icon.cooldown:SetCooldown(cdStart, cdDuration)
            end
            icon.cooldown:SetDrawEdge(false)
            icon.cooldown:SetDrawBling(false)
          else
            icon.cooldown:SetCooldown(0, 0)
          end
        end
        local start, duration = icon.cooldown:GetCooldownTimes()
        local startOk = start and IsRealNumber(start)
        local durOk = duration and IsRealNumber(duration)
        if startOk and durOk then
          if start > 0 and duration > 1500 then
            isOnCooldown = true
          elseif not isChargeSpell then
            isOnCooldown = false
          end
        else
          if not isChargeSpell then
            if icon.cooldown:IsShown() then
              local cdRegion = icon.cooldown:GetRegions()
              if cdRegion and cdRegion.IsShown and cdRegion:IsShown() then
                local alpha = cdRegion:GetAlpha()
                if alpha and alpha > 0.1 then
                  isOnCooldown = true
                end
              end
            end
          end
        end
      end
    end
    local notEnoughResources = false
    if not isItem then
      local usableInfo, insufficientPower = C_Spell.IsSpellUsable(activeSpellID)
      if usableInfo ~= nil then
        notEnoughResources = (not usableInfo) or (insufficientPower == true)
      end
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
    end
      icon._tempData = {
        iconTexture = iconTexture,
        itemCount = itemCount,
        isOnCooldown = isOnCooldown,
        isChargeSpell = isChargeSpell,
        originalIndex = originalIdx,
        notEnoughResources = notEnoughResources,
        chargesData = chargesData
      }
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    if not isChargeSpell then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          shouldShow = false
        elseif notEnoughResources and not isOnCooldown then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      icon:Hide()
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    customBarFrame:Hide()
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
  local layoutKey = table.concat({
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName
  }, "|")
  local layoutChanged = layoutKey ~= State.customBar1LayoutKey
  if layoutChanged then
    State.customBar1LayoutKey = layoutKey
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = isItem and actualID or ResolveTrackedSpellID(actualID)
    icon.icon:SetTexture(iconTexture)
    if layoutChanged then
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
      icon.cooldown:SetScale(cdTextScale)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = (go and go ~= "") and go or "OUTLINE"
      for _, region in ipairs({icon.cooldown:GetRegions()}) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
          local _, sz = region:GetFont()
          if sz then pcall(region.SetFont, region, gf, sz, oFlag) end
        end
      end
    end
    local shouldDesaturate = false
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local isUnavailable = isOnCooldown or notEnoughResources
    if isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(GetChargeSpellDesaturation(activeSpellID))
        else
          icon.icon:SetDesaturated(GetChargeSpellDesaturation(activeSpellID) > 0)
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
      local safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    icon:Show()
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar then
      MasqueGroups.CustomBar:ReSkin()
    end
    if not State.cb1Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBarAnchorFrame)
      customBarFrame:ClearAllPoints()
      customBarFrame:SetPoint("CENTER", anchorFrame, "CENTER", posX, posY)
    end
    customBarFrame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  customBarFrame:Show()
end
local function UpdateCustomBarPosition()
  if State.cb1Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBarX) == "number" and profile.customBarX or 0
  local posY = type(profile.customBarY) == "number" and profile.customBarY or -200
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBarAnchorFrame)
  customBarFrame:ClearAllPoints()
  customBarFrame:SetPoint("CENTER", anchorFrame, "CENTER", posX, posY)
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
    icon:Hide()
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
  local entries, entriesEnabled = GetCustomBar2Spells()
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
      icon:SetFrameStrata(profile.iconStrata or "TOOLTIP")
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
      icon.Count:SetFont(globalFont, fontSize, globalOutline ~= "" and globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      if icon.isItem then
        local itemIcon = GetItemIcon(icon.actualID) or C_Item.GetItemIconByID(icon.actualID)
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
  if centered then
    x = 0 + x
  end
  if not State.cb2Dragging then
    customBar2Frame:ClearAllPoints()
    customBar2Frame:SetPoint("CENTER", anchorFrame, "CENTER", x, y)
  end
  customBar2Frame:Show()
  if Masque and profile.enableMasque and MasqueGroups.CustomBar2 then
    ReSkinMasqueGroup(MasqueGroups.CustomBar2)
  end
end
local function UpdateCustomBar2()
  if State.customBar2Moving then return end
  local profile = addonTable.GetProfile()
  if not profile or not profile.customBar2Enabled then
    customBar2Frame:Hide()
    return
  end
  if not IsShowModeActive(profile.customBar2ShowMode) then
    customBar2Frame:Hide()
    return
  end
  if profile.customBar2OutOfCombat == false and not InCombatLockdown() then
    if not customBar2Frame.highlightVisible then
      customBar2Frame:Hide()
      return
    end
  end
  if #State.customBar2Icons == 0 then
    if not customBar2Frame.highlightVisible then
      customBar2Frame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBar2IconSize) == "number" and profile.customBar2IconSize or 30
  local spacing = type(profile.customBar2Spacing) == "number" and profile.customBar2Spacing or 2
  local growth = profile.customBar2Growth or "DOWN"
  local anchor = profile.customBar2AnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBar2CdTextScale) == "number" and profile.customBar2CdTextScale or 1.0
  local stackTextScale = type(profile.customBar2StackTextScale) == "number" and profile.customBar2StackTextScale or 1.0
  local centered = profile.customBar2Centered == true
  local cooldownMode = profile.customBar2CooldownMode or "show"
  local iconsPerRow = type(profile.customBar2IconsPerRow) == "number" and profile.customBar2IconsPerRow or 20
  local showGCD = profile.customBar2ShowGCD == true
  wipe(State.customBar2VisibleIcons)
  local visibleIcons = State.customBar2VisibleIcons
  for originalIdx, icon in ipairs(State.customBar2Icons) do
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
        iconTexture = GetItemIcon(actualID) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(actualID))
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = GetItemCount(actualID, false, true)
      if itemCount == 0 then
        itemCount = C_Item.GetItemCount(actualID, false, true)
      end
      if not itemCount or itemCount <= 0 then
        iconTexture = nil
      end
      cdStart, cdDuration = GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration then
        icon.cooldown:SetCooldown(cdStart, cdDuration)
      else
        icon.cooldown:SetCooldown(0, 0)
      end
      icon.cooldown:SetDrawEdge(false)
      icon.cooldown:SetDrawBling(false)
      local start, duration = icon.cooldown:GetCooldownTimes()
      local startOk = start and IsRealNumber(start)
      local durOk = duration and IsRealNumber(duration)
      if startOk and durOk and start > 0 and duration > 1500 then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID) then
        iconTexture = nil
        icon.cooldown:SetCooldown(0, 0)
      else
        local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
        iconTexture = spellInfo and spellInfo.iconID or nil
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData and issecretvalue and issecretvalue(chargesData.maxCharges) then
          chargesData._secretMax = true
        end
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          icon.cooldown:SetCooldown(cdStart, cdDuration)
          icon.cooldown:SetDrawEdge(false)
          icon.cooldown:SetDrawBling(false)
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
              icon.cooldown:SetCooldown(0, 0)
            else
              icon.cooldown:SetCooldown(cdStart, cdDuration)
            end
            icon.cooldown:SetDrawEdge(false)
            icon.cooldown:SetDrawBling(false)
          else
            icon.cooldown:SetCooldown(0, 0)
          end
        end
        local start, duration = icon.cooldown:GetCooldownTimes()
        local startOk = start and IsRealNumber(start)
        local durOk = duration and IsRealNumber(duration)
        if startOk and durOk then
          if start > 0 and duration > 1500 then
            isOnCooldown = true
          elseif not isChargeSpell then
            isOnCooldown = false
          end
        else
          if not isChargeSpell then
            if icon.cooldown:IsShown() then
              local cdRegion = icon.cooldown:GetRegions()
              if cdRegion and cdRegion.IsShown and cdRegion:IsShown() then
                local alpha = cdRegion:GetAlpha()
                if alpha and alpha > 0.1 then
                  isOnCooldown = true
                end
              end
            end
          end
        end
      end
    end
    local notEnoughResources = false
    if not isItem then
      local usableInfo, insufficientPower = C_Spell.IsSpellUsable(activeSpellID)
      if usableInfo ~= nil then
        notEnoughResources = (not usableInfo) or (insufficientPower == true)
      end
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
    end
      icon._tempData = {
        iconTexture = iconTexture,
        itemCount = itemCount,
        isOnCooldown = isOnCooldown,
        isChargeSpell = isChargeSpell,
        originalIndex = originalIdx,
        notEnoughResources = notEnoughResources,
        chargesData = chargesData
      }
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    if not isChargeSpell then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          shouldShow = false
        elseif notEnoughResources and not isOnCooldown then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      icon:Hide()
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    customBar2Frame:Hide()
    return
  end
  local totalIcons = #State.customBar2Icons
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
  local posX = type(profile.customBar2X) == "number" and profile.customBar2X or 0
  local posY = type(profile.customBar2Y) == "number" and profile.customBar2Y or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
  local layoutKey = table.concat({
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName
  }, "|")
  local layoutChanged = layoutKey ~= State.customBar2LayoutKey
  if layoutChanged then
    State.customBar2LayoutKey = layoutKey
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = isItem and actualID or ResolveTrackedSpellID(actualID)
    icon.icon:SetTexture(iconTexture)
    if layoutChanged then
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
      icon.cooldown:SetScale(cdTextScale)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = (go and go ~= "") and go or "OUTLINE"
      for _, region in ipairs({icon.cooldown:GetRegions()}) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
          local _, sz = region:GetFont()
          if sz then pcall(region.SetFont, region, gf, sz, oFlag) end
        end
      end
    end
    local shouldDesaturate = false
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local isUnavailable = isOnCooldown or notEnoughResources
    if isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(GetChargeSpellDesaturation(activeSpellID))
        else
          icon.icon:SetDesaturated(GetChargeSpellDesaturation(activeSpellID) > 0)
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
      local safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    icon:Show()
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar2 then
      MasqueGroups.CustomBar2:ReSkin()
    end
    if not State.cb2Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
      customBar2Frame:ClearAllPoints()
      customBar2Frame:SetPoint("CENTER", anchorFrame, "CENTER", posX, posY)
    end
    customBar2Frame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))
  end
  customBar2Frame:Show()
end
local function UpdateCustomBar2Position()
  if State.cb2Dragging then return end
  local profile = addonTable.GetProfile()
  if not profile then return end
  local posX = type(profile.customBar2X) == "number" and profile.customBar2X or 0
  local posY = type(profile.customBar2Y) == "number" and profile.customBar2Y or -250
  local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar2AnchorFrame)
  customBar2Frame:ClearAllPoints()
  customBar2Frame:SetPoint("CENTER", anchorFrame, "CENTER", posX, posY)
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
    icon:Hide()
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
  local entries, entriesEnabled = GetCustomBar3Spells()
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
      icon:SetFrameStrata(profile.iconStrata or "TOOLTIP")
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
      icon.Count:SetFont(globalFont, fontSize, globalOutline ~= "" and globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.entryID = id
      icon.isItem = id < 0
      icon.actualID = math.abs(id)
      if icon.isItem then
        local itemIcon = GetItemIcon(icon.actualID) or C_Item.GetItemIconByID(icon.actualID)
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
  if centered then
    x = 0 + x
  end
  if not State.cb3Dragging then
    customBar3Frame:ClearAllPoints()
    customBar3Frame:SetPoint("CENTER", anchorFrame, "CENTER", x, y)
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
  if not IsShowModeActive(profile.customBar3ShowMode) then
    customBar3Frame:Hide()
    return
  end
  if profile.customBar3OutOfCombat == false and not InCombatLockdown() then
    if not customBar3Frame.highlightVisible then
      customBar3Frame:Hide()
      return
    end
  end
  if #State.customBar3Icons == 0 then
    if not customBar3Frame.highlightVisible then
      customBar3Frame:Hide()
    end
    return
  end
  local iconSize = type(profile.customBar3IconSize) == "number" and profile.customBar3IconSize or 30
  local spacing = type(profile.customBar3Spacing) == "number" and profile.customBar3Spacing or 2
  local growth = profile.customBar3Growth or "DOWN"
  local anchor = profile.customBar3AnchorPoint or "LEFT"
  local cdTextScale = type(profile.customBar3CdTextScale) == "number" and profile.customBar3CdTextScale or 1.0
  local stackTextScale = type(profile.customBar3StackTextScale) == "number" and profile.customBar3StackTextScale or 1.0
  local centered = profile.customBar3Centered == true
  local cooldownMode = profile.customBar3CooldownMode or "show"
  local iconsPerRow = type(profile.customBar3IconsPerRow) == "number" and profile.customBar3IconsPerRow or 20
  local showGCD = profile.customBar3ShowGCD == true
  wipe(State.customBar3VisibleIcons)
  local visibleIcons = State.customBar3VisibleIcons
  for originalIdx, icon in ipairs(State.customBar3Icons) do
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
        iconTexture = GetItemIcon(actualID) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(actualID))
        if not iconTexture then
          local _, _, _, _, _, _, _, _, _, infoIcon = GetItemInfo(actualID)
          iconTexture = infoIcon
        end
        if iconTexture then
          icon.cachedItemIcon = iconTexture
        end
      end
      itemCount = GetItemCount(actualID, false, true)
      if itemCount == 0 then
        itemCount = C_Item.GetItemCount(actualID, false, true)
      end
      if not itemCount or itemCount <= 0 then
        iconTexture = nil
      end
      cdStart, cdDuration = GetItemCooldown(actualID)
      local shouldShowSwipe = true
      if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
        if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
          shouldShowSwipe = false
        end
      end
      if shouldShowSwipe and cdStart and cdDuration then
        icon.cooldown:SetCooldown(cdStart, cdDuration)
      else
        icon.cooldown:SetCooldown(0, 0)
      end
      icon.cooldown:SetDrawEdge(false)
      icon.cooldown:SetDrawBling(false)
      local start, duration = icon.cooldown:GetCooldownTimes()
      local startOk = start and IsRealNumber(start)
      local durOk = duration and IsRealNumber(duration)
      if startOk and durOk and start > 0 and duration > 1500 then
        isOnCooldown = true
      end
    else
      activeSpellID = ResolveTrackedSpellID(actualID)
      if not IsTrackedEntryAvailable(false, actualID, activeSpellID) then
        iconTexture = nil
        icon.cooldown:SetCooldown(0, 0)
      else
        local spellInfo = C_Spell.GetSpellInfo(activeSpellID)
        iconTexture = spellInfo and spellInfo.iconID or nil
        chargesData = C_Spell.GetSpellCharges(activeSpellID)
        if chargesData and issecretvalue and issecretvalue(chargesData.maxCharges) then
          chargesData._secretMax = true
        end
        if chargesData then
          isChargeSpell = IsRealChargeSpell(chargesData, actualID)
          cdStart, cdDuration = chargesData.cooldownStartTime, chargesData.cooldownDuration
          icon.cooldown:SetCooldown(cdStart, cdDuration)
          icon.cooldown:SetDrawEdge(false)
          icon.cooldown:SetDrawBling(false)
        else
          local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
          if cdInfo then
            cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
            if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
              icon.cooldown:SetCooldown(0, 0)
            else
              icon.cooldown:SetCooldown(cdStart, cdDuration)
            end
            icon.cooldown:SetDrawEdge(false)
            icon.cooldown:SetDrawBling(false)
          else
            icon.cooldown:SetCooldown(0, 0)
          end
        end
        local start, duration = icon.cooldown:GetCooldownTimes()
        local startOk = start and IsRealNumber(start)
        local durOk = duration and IsRealNumber(duration)
        if startOk and durOk then
          if start > 0 and duration > 1500 then
            isOnCooldown = true
          elseif not isChargeSpell then
            isOnCooldown = false
          end
        else
          if not isChargeSpell then
            if icon.cooldown:IsShown() then
              local cdRegion = icon.cooldown:GetRegions()
              if cdRegion and cdRegion.IsShown and cdRegion:IsShown() then
                local alpha = cdRegion:GetAlpha()
                if alpha and alpha > 0.1 then
                  isOnCooldown = true
                end
              end
            end
          end
        end
      end
    end
    local notEnoughResources = false
    if not isItem then
      local usableInfo, insufficientPower = C_Spell.IsSpellUsable(activeSpellID)
      if usableInfo ~= nil then
        notEnoughResources = (not usableInfo) or (insufficientPower == true)
      end
      if notEnoughResources and isOnCooldown then
        notEnoughResources = false
      end
    end
      icon._tempData = {
        iconTexture = iconTexture,
        itemCount = itemCount,
        isOnCooldown = isOnCooldown,
        isChargeSpell = isChargeSpell,
        originalIndex = originalIdx,
        notEnoughResources = notEnoughResources,
        chargesData = chargesData
      }
    local isUnavailable = isOnCooldown or notEnoughResources
    local shouldShow = true
    if not isChargeSpell then
      if cooldownMode == "hideAvailable" then
        if not isUnavailable then
          shouldShow = false
        end
      elseif cooldownMode == "hide" then
        if isOnCooldown then
          shouldShow = false
        elseif notEnoughResources and not isOnCooldown then
          shouldShow = false
        end
      end
    end
    if iconTexture and shouldShow then
      table.insert(visibleIcons, icon)
    else
      icon:Hide()
    end
  end
  local visibleCount = #visibleIcons
  if visibleCount == 0 then
    customBar3Frame:Hide()
    return
  end
  local totalIcons = #State.customBar3Icons
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
  local posX = type(profile.customBar3X) == "number" and profile.customBar3X or 0
  local posY = type(profile.customBar3Y) == "number" and profile.customBar3Y or -200
  local _, anchorFrameName = ResolveCustomBarAnchorFrame(profile.customBar3AnchorFrame)
  local layoutKey = table.concat({
    iconSize, spacing, growth, anchor, centered and 1 or 0, direction, iconsPerRow,
    centered and visibleCount or totalIcons, posX, posY, anchorFrameName
  }, "|")
  local layoutChanged = layoutKey ~= State.customBar3LayoutKey
  if layoutChanged then
    State.customBar3LayoutKey = layoutKey
  end
  for idx, icon in ipairs(visibleIcons) do
    local data = icon._tempData
    local iconTexture = data.iconTexture
    local itemCount = data.itemCount
    local isOnCooldown = data.isOnCooldown
    local isChargeSpell = data.isChargeSpell
    local isItem = icon.isItem
    local actualID = icon.actualID
    local activeSpellID = isItem and actualID or ResolveTrackedSpellID(actualID)
    icon.icon:SetTexture(iconTexture)
    if layoutChanged then
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
      icon.cooldown:SetScale(cdTextScale)
      icon.cooldown._ccmLastScale = cdTextScale
    end
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = (go and go ~= "") and go or "OUTLINE"
      for _, region in ipairs({icon.cooldown:GetRegions()}) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
          local _, sz = region:GetFont()
          if sz then pcall(region.SetFont, region, gf, sz, oFlag) end
        end
      end
    end
    local shouldDesaturate = false
    local notEnoughResources = icon._tempData and icon._tempData.notEnoughResources
    local isUnavailable = isOnCooldown or notEnoughResources
    if isChargeSpell and not isItem then
      if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
        icon:SetAlpha(1)
        if icon.icon.SetDesaturation then
          icon.icon:SetDesaturation(GetChargeSpellDesaturation(activeSpellID))
        else
          icon.icon:SetDesaturated(GetChargeSpellDesaturation(activeSpellID) > 0)
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
      local safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, actualID)
      if safeCharges ~= nil then
        icon.stackText:SetText(tostring(safeCharges))
        icon.stackText:SetScale(stackTextScale)
        icon.stackText:Show()
      else
        icon.stackText:Hide()
      end
    end
    if not (isChargeSpell and not isItem) then
      icon.icon:SetDesaturated(shouldDesaturate)
    end
    icon:Show()
  end
  if layoutChanged then
    if Masque and profile.enableMasque and MasqueGroups.CustomBar3 then
      MasqueGroups.CustomBar3:ReSkin()
    end
    if not State.cb3Dragging then
      local anchorFrame = ResolveCustomBarAnchorFrame(profile.customBar3AnchorFrame)
      customBar3Frame:ClearAllPoints()
      customBar3Frame:SetPoint("CENTER", anchorFrame, "CENTER", posX, posY)
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
  customBar3Frame:ClearAllPoints()
  customBar3Frame:SetPoint("CENTER", anchorFrame, "CENTER", posX, posY)
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
local UpdateSpellIcon
local function ClearIcons()
  if Masque and MasqueGroups.CursorIcons then
    for _, icon in ipairs(State.cursorIcons) do
      RemoveButtonFromMasque(icon, MasqueGroups.CursorIcons)
    end
  end
  for i, icon in ipairs(State.cursorIcons) do
    icon:Hide()
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
  if not profile.trackedSpells then profile.trackedSpells = {} end
  if not profile.spellsEnabled then profile.spellsEnabled = {} end
  local iconSize = type(profile.iconSize) == "number" and profile.iconSize or 30
  local borderSize = type(profile.iconBorderSize) == "number" and profile.iconBorderSize or 1
  for i, entryID in ipairs(profile.trackedSpells) do
    if not profile.spellsEnabled then
      profile.spellsEnabled = {}
    end
    if profile.spellsEnabled[i] == nil then
      profile.spellsEnabled[i] = true
    end
    if profile.spellsEnabled[i] then
      local isItem = entryID < 0
      local actualID = math.abs(entryID)
      local iconStrata = profile.iconStrata or "TOOLTIP"
      local icon = CreateFrame("Button", "CCMIcon" .. i, UIParent, "BackdropTemplate")
      icon:SetFrameStrata(iconStrata)
      icon:SetFrameLevel(200)
      icon:EnableMouse(false)
      icon:SetSize(iconSize, iconSize)
      icon:Hide()
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
      icon.Count:SetFont(globalFont, fontSize, globalOutline ~= "" and globalOutline or "OUTLINE")
      icon.Count:Hide()
      icon.stackText = icon.Count
      icon.spellID = actualID
      icon.isItem = isItem
      icon.spellIndex = i
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
end
addonTable.CreateIcons = CreateIcons
local onUpdateElapsed = 0
local cursorTrackElapsed = 0
local ON_UPDATE_THROTTLE = 0.05
local CURSOR_TRACK_THROTTLE = 0.02
local cachedProfile = nil
local lastProfileCheck = 0
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
  local hasBars = (profile.useBuffBar or profile.useEssentialBar) and profile.disableBlizzCDM ~= true
  return profile.cursorIconsEnabled or hasBars
end
addonTable.ShouldRunMainOnUpdate = function(profile)
  if not profile then return false end
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
  local scale = UIParent:GetEffectiveScale()
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
  if not cursorEnabled then return end
  local baseX = (x / scale) + cache.offsetX + cache.totalBarWidth
  local baseY = (y / scale) + cache.offsetY
  local row, col = 0, 0
  for _, icon in ipairs(State.cursorIcons) do
    if icon:IsShown() then
      local xPos, yPos
      if cache.isHorizontal then
        xPos = baseX + col * (cache.iconSize + cache.iconSpacing)
        yPos = baseY + row * (cache.iconSize + cache.iconSpacing)
        col = col + 1
        if col >= cache.iconsPerRow then
          col = 0
          row = row + 1
          if cache.numColumns > 1 and row >= cache.numColumns then break end
        end
      else
        xPos = baseX + col * (cache.iconSize + cache.iconSpacing)
        yPos = baseY + row * (cache.iconSize + cache.iconSpacing)
        row = row + 1
        if row >= cache.iconsPerRow then
          row = 0
          col = col + 1
          if cache.numColumns > 1 and col >= cache.numColumns then break end
        end
      end
      icon:ClearAllPoints()
      icon:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", xPos, yPos)
    end
  end
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
  local scale = UIParent:GetEffectiveScale()
  local cursorMoved = math.abs(x - State.lastCursorX) > State.cursorMoveThreshold or math.abs(y - State.lastCursorY) > State.cursorMoveThreshold
  local doExpensiveUpdate = (now - State.lastBarUpdateTime) >= State.barUpdateInterval
  if not cursorMoved and not doExpensiveUpdate then
    UpdateRadialCircle()
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
  end
  State.cursorLayoutCache.offsetX = profile.offsetX or 30
  State.cursorLayoutCache.offsetY = profile.offsetY or 45
  State.cursorLayoutCache.iconSize = iconSize or 42
  State.cursorLayoutCache.iconSpacing = iconSpacing or 2
  State.cursorLayoutCache.isHorizontal = isHorizontal
  State.cursorLayoutCache.iconsPerRow = iconsPerRow
  State.cursorLayoutCache.numColumns = numColumns
  State.cursorLayoutCache.totalBarWidth = totalBarWidth
  local masqueEnabled = profile.enableMasque and Masque
  for _, icon in ipairs(State.cursorIcons) do
    if icon:IsShown() then
      if icon._ccmSize ~= iconSize then
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
  UpdateRadialCircle()
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
UpdateSpellIcon = function(icon)
  local profile = addonTable.GetProfile()
  if not profile then return end
  if profile.cursorIconsEnabled == false then
    icon:Hide()
    return
  end
  local spellID = icon.spellID
  local isItem = icon.isItem
  local showGCD = profile.cursorShowGCD == true
  if not IsShowModeActive(profile.showMode) then
    icon:Hide()
    return
  end
  if (profile.iconsCombatOnly or profile.showInCombatOnly) and not UnitAffectingCombat("player") then
    icon:Hide()
    return
  end
  if isItem then
    local itemIcon = icon.cachedItemIcon
    if not itemIcon then
      itemIcon = GetItemIcon(spellID) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(spellID))
      if not itemIcon then
        local _, _, _, _, _, _, _, _, _, infoIcon = GetItemInfo(spellID)
        itemIcon = infoIcon
      end
      if itemIcon then
        icon.cachedItemIcon = itemIcon
      end
    end
    if not itemIcon then
      C_Item.RequestLoadItemDataByID(spellID)
      icon:Show()
      icon.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      return
    end
    icon:Show()
    icon.icon:SetTexture(itemIcon)
    icon.icon:SetVertexColor(1, 1, 1)
    icon.icon:SetDesaturated(false)
    if icon.cdText then icon.cdText:Hide() end
    local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
    icon.cooldown:SetScale(cdTextScale)
    if not icon.cooldown._ccmFontApplied then
      icon.cooldown._ccmFontApplied = true
      local gf, go = GetGlobalFont()
      local oFlag = (go and go ~= "") and go or "OUTLINE"
      for _, region in ipairs({icon.cooldown:GetRegions()}) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
          local _, sz = region:GetFont()
          if sz then pcall(region.SetFont, region, gf, sz, oFlag) end
        end
      end
    end
    local cdStart, cdDuration = GetItemCooldown(spellID)
    local shouldShowSwipe = true
    if cdStart and cdDuration and cdStart > 0 and cdDuration > 0 then
      if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
        shouldShowSwipe = false
      end
    end
    if shouldShowSwipe and cdStart and cdDuration and cdDuration > 1.5 then
      icon.cooldown:SetCooldown(cdStart, cdDuration)
      icon.cooldown:SetHideCountdownNumbers(false)
    else
      icon.cooldown:Clear()
    end
    local isItemOnCooldown = cdStart and cdDuration and cdStart > 0 and cdDuration > 1.5
    local cooldownMode = profile.cooldownIconMode or "show"
    if cooldownMode == "hideAvailable" then
      if not isItemOnCooldown then
        icon:Hide()
        return
      end
      icon.icon:SetDesaturated(false)
    elseif cooldownMode == "hide" and isItemOnCooldown then
      icon:Hide()
      return
    elseif cooldownMode == "desaturate" then
      icon.icon:SetDesaturated(isItemOnCooldown)
    else
      icon.icon:SetDesaturated(false)
    end
    local itemCount = GetItemCount(spellID, false, true)
    if not itemCount or itemCount <= 0 then
      icon:Hide()
      return
    end
    if itemCount and itemCount > 1 then
      icon.stackText:SetText(itemCount)
      local stackTextScale = type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0
      icon.stackText:SetScale(stackTextScale)
      icon.stackText:Show()
    elseif itemCount == 0 then
      icon.stackText:SetText("0")
      icon.stackText:Show()
    else
      icon.stackText:Hide()
    end
    return
  end
  local activeSpellID = ResolveTrackedSpellID(spellID)
  if not IsTrackedEntryAvailable(false, spellID, activeSpellID) then
    icon:Hide()
    return
  end
  local info = C_Spell.GetSpellInfo(activeSpellID)
  if not info or not info.iconID then
    icon:Hide()
    return
  end
  icon:Show()
  icon.icon:SetTexture(info.iconID)
  icon.icon:SetVertexColor(1, 1, 1)
  if icon.cdText then
    icon.cdText:Hide()
  end
  local cdTextScale = type(profile.cdTextScale) == "number" and profile.cdTextScale or 1.0
  icon.cooldown:SetScale(cdTextScale)
  if not icon.cooldown._ccmFontApplied then
    icon.cooldown._ccmFontApplied = true
    local gf, go = GetGlobalFont()
    local oFlag = (go and go ~= "") and go or "OUTLINE"
    for _, region in ipairs({icon.cooldown:GetRegions()}) do
      if region and region.GetObjectType and region:GetObjectType() == "FontString" then
        local _, sz = region:GetFont()
        if sz then pcall(region.SetFont, region, gf, sz, oFlag) end
      end
    end
  end
  local charges = C_Spell.GetSpellCharges(activeSpellID)
  if charges and issecretvalue and issecretvalue(charges.maxCharges) then
    charges._secretMax = true
  end
  local safeCharges = GetSafeCurrentCharges(charges, activeSpellID, icon.cooldown, spellID)
  if safeCharges ~= nil then
    icon.stackText:SetText(tostring(safeCharges))
    icon.stackText:Show()
    local stackTextScale = type(profile.stackTextScale) == "number" and profile.stackTextScale or 1.0
    icon.stackText:SetScale(stackTextScale)
    local cdStart, cdDuration
    if charges then
      cdStart, cdDuration = charges.cooldownStartTime, charges.cooldownDuration
    else
      local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
      if cdInfo then
        cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
      end
    end
    local shouldShowSwipe = true
    if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
      shouldShowSwipe = false
    end
    if shouldShowSwipe and cdStart and cdDuration then
      pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration)
      icon.cooldown:SetHideCountdownNumbers(false)
      icon.cooldown:SetDrawEdge(false)
    else
      icon.cooldown:Clear()
    end
  else
    icon.stackText:Hide()
    local cdInfo = C_Spell.GetSpellCooldown(activeSpellID)
    if cdInfo then
      local cdStart, cdDuration = cdInfo.startTime, cdInfo.duration
      local shouldShowSwipe = true
      if not showGCD and IsOnlyGCD(cdStart, cdDuration) then
        shouldShowSwipe = false
      end
      if shouldShowSwipe then
        pcall(icon.cooldown.SetCooldown, icon.cooldown, cdStart, cdDuration)
      else
        icon.cooldown:Clear()
      end
      icon.cooldown:SetHideCountdownNumbers(false)
      icon.cooldown:SetDrawEdge(false)
    else
      icon.cooldown:Clear()
    end
  end
  local isOnCooldown = false
  local isChargeSpell = IsRealChargeSpell(charges, spellID)
  local start, duration = icon.cooldown:GetCooldownTimes()
  local startOk = start and IsRealNumber(start)
  local durOk = duration and IsRealNumber(duration)
  if startOk and durOk then
    if start > 0 and duration > 1500 then
      isOnCooldown = true
    else
      isOnCooldown = false
    end
  else
    if not isChargeSpell then
      if icon.cooldown:IsShown() then
        local cdRegion = icon.cooldown:GetRegions()
        if cdRegion and cdRegion.IsShown and cdRegion:IsShown() then
          local alpha = cdRegion:GetAlpha()
          if alpha and alpha > 0.1 then
            isOnCooldown = true
          end
        end
      end
    end
  end
  local isUsable, notEnoughResources = false, false
  local usableInfo, insufficientPower = C_Spell.IsSpellUsable(activeSpellID)
  if usableInfo ~= nil then
    isUsable = usableInfo and not insufficientPower
    notEnoughResources = (not usableInfo) or (insufficientPower == true)
  end
  if notEnoughResources and isOnCooldown then
    notEnoughResources = false
  end
  local isUnavailable = isOnCooldown or notEnoughResources
  local cooldownMode = profile.cooldownIconMode or "show"
  if isChargeSpell then
    if cooldownMode == "hide" or cooldownMode == "hideAvailable" or cooldownMode == "desaturate" then
      icon:SetAlpha(1)
      if icon.icon.SetDesaturation then
        icon.icon:SetDesaturation(GetChargeSpellDesaturation(activeSpellID))
      else
        icon.icon:SetDesaturated(GetChargeSpellDesaturation(activeSpellID) > 0)
      end
    else
      icon:SetAlpha(1)
      icon.icon:SetDesaturated(false)
    end
  else
    icon:SetAlpha(1)
    if cooldownMode == "hideAvailable" then
      if not isUnavailable then
        icon:Hide()
        return
      end
      icon.icon:SetDesaturated(false)
    elseif cooldownMode == "hide" then
      if isOnCooldown then
        icon:Hide()
        return
      end
      if notEnoughResources and not isOnCooldown then
        icon:Hide()
        return
      end
      icon.icon:SetDesaturated(false)
    elseif cooldownMode == "desaturate" then
      icon.icon:SetDesaturated(isUnavailable)
    else
      icon.icon:SetDesaturated(false)
    end
  end
end
local function UpdateAllIcons()
  for _, icon in ipairs(State.cursorIcons) do
    UpdateSpellIcon(icon)
  end
end
addonTable.UpdateAllIcons = UpdateAllIcons
local UpdateGCD
addonTable.UpdateEnabledCustomBars = function(profile, force)
  if not profile then return false end
  local now = GetTime()
  local hasPending = false
  if profile.customBarEnabled then
    local interval = State.customBar1UpdateInterval or 0.08
    if force or (now - (State.lastCustomBar1Update or 0)) >= interval then
      UpdateCustomBar()
      State.lastCustomBar1Update = now
    else
      hasPending = true
    end
  end
  if profile.customBar2Enabled then
    local interval = State.customBar2UpdateInterval or 0.12
    if force or (now - (State.lastCustomBar2Update or 0)) >= interval then
      UpdateCustomBar2()
      State.lastCustomBar2Update = now
    else
      hasPending = true
    end
  end
  if profile.customBar3Enabled then
    local interval = State.customBar3UpdateInterval or 0.12
    if force or (now - (State.lastCustomBar3Update or 0)) >= interval then
      UpdateCustomBar3()
      State.lastCustomBar3Update = now
    else
      hasPending = true
    end
  end
  State.customBarsDirty = hasPending
  return not hasPending
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
  local minInterval = math.min(
    State.customBar1UpdateInterval or 0.08,
    State.customBar2UpdateInterval or 0.12,
    State.customBar3UpdateInterval or 0.12
  )
  C_Timer.After(minInterval, function()
    State.customBarUpdatePending = false
    local profile = GetProfile()
    addonTable.UpdateEnabledCustomBars(profile, false)
  end)
end
addonTable.RequestStandaloneBuffRelayout = function()
  if State.standaloneAuraRelayoutPending then return end
  State.standaloneAuraRelayoutPending = true
  State.standaloneFastUntil = GetTime() + 0.6
  State.lastStandaloneTick = 0
  C_Timer.After(0, function()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
  end)
  C_Timer.After(0.06, function()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
  end)
  C_Timer.After(0.12, function()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
    State.standaloneAuraRelayoutPending = false
  end)
end
addonTable.MainTickerTick = function()
  State.tickerProfile = GetProfile()
  if not State.tickerProfile then return end
  local now = GetTime()
  if State.tickerProfile.showRadialCircle and State.tickerProfile.showGCD then
    UpdateGCD()
  end
  if State.customBarsDirty and not State.customBarUpdatePending then
    addonTable.UpdateEnabledCustomBars(State.tickerProfile, false)
  end
  if State.tickerProfile.standaloneSkinBuff or State.tickerProfile.standaloneSkinEssential or State.tickerProfile.standaloneSkinUtility or State.tickerProfile.standaloneBuffCentered or State.tickerProfile.standaloneEssentialCentered or State.tickerProfile.standaloneUtilityCentered then
    local fast = State.standaloneFastUntil and now < State.standaloneFastUntil
    local interval = fast and 0.25 or 1.0
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
    elseif profile.customBarEnabled or profile.customBar2Enabled or profile.customBar3Enabled then
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
  if not profile or not profile.showGCD then
    State.gcdStartTime = 0
    State.gcdDuration = 0
    return
  end
  if profile.trackedSpells then
    for _, spellID in ipairs(profile.trackedSpells) do
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
CCM:RegisterEvent("PLAYER_TARGET_CHANGED")
CCM:RegisterEvent("PLAYER_FOCUS_CHANGED")
CCM:RegisterEvent("PLAYER_ENTERING_WORLD")
CCM:RegisterEvent("MERCHANT_SHOW")
CCM:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
CCM:RegisterUnitEvent("UNIT_AURA", "player")
local function GetCharacterSpecKey()
  local playerName = UnitName("player")
  local realmName = GetRealmName()
  local specID = GetSpecialization() or 0
  if playerName and realmName then
    return playerName .. "-" .. realmName .. "-" .. specID
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
CCM:SetScript("OnEvent", function(self, event, arg1, _, spellID)
  if event == "ADDON_LOADED" and arg1 == addonName then
    ApplyDefaults()
    InitCurves()
    InitMasque()
    if CCM.RegisterMedia then CCM:RegisterMedia() end
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    UpdateStandaloneBlizzardBars()
    if addonTable.ShowMinimapButton then addonTable.ShowMinimapButton() end
    print("|cff00ff00CooldownCursorManager loaded!|r Type /ccm to configure")
    if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.SetupTooltipIDHooks then addonTable.SetupTooltipIDHooks() end
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
    if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
    if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  elseif event == "PLAYER_LOGIN" then
    ApplyCharacterProfile()
    MigrateOldCustomBarData()
    MigrateRenamedProfileKeys()
    local profile = addonTable.GetProfile()
    if profile then
      if profile.uiScaleMode ~= "disabled" and profile.uiScale then
        SetCVar("uiScale", profile.uiScale)
        UIParent:SetScale(profile.uiScale)
      end
    end
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    UpdateStandaloneBlizzardBars()
    C_Timer.After(1, function() State.standaloneNeedsSkinning = true UpdateStandaloneBlizzardBars() end)
    C_Timer.After(3, function() State.standaloneNeedsSkinning = true UpdateStandaloneBlizzardBars() end)
    if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if profile and profile.usePersonalResourceBar then
      if addonTable.StartPRBTicker then addonTable.StartPRBTicker() end
    end
    if profile and profile.useCastbar then
      if addonTable.SetBlizzardCastbarVisibility then
        addonTable.SetBlizzardCastbarVisibility(false)
      end
      if addonTable.SetupCastbarEvents then
        addonTable.SetupCastbarEvents()
      end
    else
      if castbarFrame then
        castbarFrame:Hide()
      end
    end
    if profile and profile.useFocusCastbar then
      if addonTable.SetupFocusCastbarEvents then
        addonTable.SetupFocusCastbarEvents()
      end
    else
      if addonTable.FocusCastbarFrame then
        addonTable.FocusCastbarFrame:Hide()
      end
    end
    if profile and profile.enablePlayerDebuffs then
      if addonTable.ApplyPlayerDebuffsSkinning then
        addonTable.ApplyPlayerDebuffsSkinning()
      end
    end
    if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.SetupTooltipIDHooks then addonTable.SetupTooltipIDHooks() end
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
    if addonTable.SetCombatTimerActive then addonTable.SetCombatTimerActive(UnitAffectingCombat("player") == true) end
    if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
    if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  elseif event == "PLAYER_ENTERING_WORLD" then
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
    if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  elseif event == "MERCHANT_SHOW" then
    if addonTable.TryAutoRepair then addonTable.TryAutoRepair() end
  elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
    UpdateGCD()
    addonTable.RequestIconUpdate()
    State.iconsDirty = false
    State.customBarsDirty = true
    State.lastIconUpdate = GetTime()
    addonTable.RequestCustomBarUpdate()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
    C_Timer.After(0.01, UpdateGCD)
    State.iconsDirty = true
    State.customBarsDirty = true
    addonTable.RequestIconUpdate()
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
    addonTable.RequestIconUpdate()
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
        if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
        addonTable.ConfigFrame:Show()
      end
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    addonTable.RequestIconUpdate()
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
      addonTable.ConfigFrame:Hide()
      if addonTable.SetGUIOpen then addonTable.SetGUIOpen(false) end
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
    ApplyCharacterProfile()
    CreateIcons()
    CreateCustomBarIcons()
    CreateCustomBar2Icons()
    CreateCustomBar3Icons()
    UpdateAllIcons()
    UpdateCustomBar()
    UpdateCustomBar2()
    UpdateCustomBar3()
    State.standaloneNeedsSkinning = true
    UpdateStandaloneBlizzardBars()
    if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if addonTable.ConfigFrame and addonTable.ConfigFrame:IsShown() then
      if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
    end
    if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
    if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
  elseif event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
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
      addonTable.RequestIconUpdate()
      addonTable.RequestCustomBarUpdate()
      if addonTable.RefreshCRTimerText then addonTable.RefreshCRTimerText() end
    end
  end
end)
if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
