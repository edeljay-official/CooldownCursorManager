--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_wizard.lua
-- First-install setup wizard and manual installer UI
--------------------------------------------------------------------------------
local _, addonTable = ...

local WizardFrame = nil
local WizardStepTitle = nil
local WizardStepBody = nil
local WizardProgress = nil
local WizardBackBtn = nil
local WizardNextBtn = nil
local WizardFinishBtn = nil
local WizardCloseBtn = nil
local WizardCustomBarsSlider = nil
local WizardUiScaleDD = nil
local WizardReviewSummary = nil
local WizardReviewScrollFrame = nil
local WizardReviewScrollChild = nil
local WizardFinishPopup = nil
local WizardFinishNameBox = nil
local WizardFinishSharedCB = nil
local StepContainers = {}
local CurrentStep = 1
local DeferredOpenAfterCombat = false

local function GetProfile()
  return addonTable.GetProfile and addonTable.GetProfile() or nil
end

local function CreateStyledPanel(parent)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  f:SetBackdropColor(0.1, 0.1, 0.13, 0.97)
  f:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  return f
end

local function CreateScrollableStepContainer(parent, contentHeight)
  local outer = CreateFrame("Frame", nil, parent)
  outer:SetAllPoints()
  local scroll = CreateFrame("ScrollFrame", nil, outer)
  scroll:SetPoint("TOPLEFT", outer, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", outer, "BOTTOMRIGHT", -18, 0)
  scroll:EnableMouseWheel(true)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
  child:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
  child:SetHeight(contentHeight or 640)
  scroll:SetScrollChild(child)
  local bar = CreateFrame("Slider", nil, outer, "BackdropTemplate")
  bar:SetPoint("TOPRIGHT", outer, "TOPRIGHT", 0, -2)
  bar:SetPoint("BOTTOMRIGHT", outer, "BOTTOMRIGHT", 0, 2)
  bar:SetWidth(10)
  bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  bar:SetBackdropColor(0.1, 0.1, 0.12, 1)
  bar:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  bar:SetOrientation("VERTICAL")
  bar:SetMinMaxValues(0, 0)
  bar:SetValue(0)
  local thumb = bar:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
  thumb:SetSize(8, 40)
  bar:SetThumbTexture(thumb)
  local function UpdateScrollRange()
    local max = math.max(0, (child:GetHeight() or 0) - (scroll:GetHeight() or 0))
    bar:SetMinMaxValues(0, max)
    if max <= 0 then
      bar:SetValue(0)
      bar:Hide()
    else
      bar:Show()
      if bar:GetValue() > max then bar:SetValue(max) end
      local visibleRatio = scroll:GetHeight() / (child:GetHeight() or 1)
      local th = math.max(24, math.floor((scroll:GetHeight() * visibleRatio) + 0.5))
      thumb:SetHeight(th)
    end
  end
  bar:SetScript("OnValueChanged", function(_, v)
    scroll:SetVerticalScroll(v or 0)
  end)
  scroll:SetScript("OnMouseWheel", function(_, delta)
    local cur = bar:GetValue() or 0
    local mn, mx = bar:GetMinMaxValues()
    local nextV = cur - ((delta or 0) * 30)
    if nextV < mn then nextV = mn end
    if nextV > mx then nextV = mx end
    bar:SetValue(nextV)
  end)
  outer:SetScript("OnShow", function()
    UpdateScrollRange()
    bar:SetValue(0)
  end)
  scroll:SetScript("OnSizeChanged", function()
    UpdateScrollRange()
  end)
  child._updateScrollRange = UpdateScrollRange
  return outer, child, scroll
end

local function CreateStyledCheckbox(parent, label)
  local cb = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
  cb:SetSize(18, 18)
  cb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cb:SetBackdropColor(0.12, 0.12, 0.14, 1)
  cb:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  cb.check = cb:CreateTexture(nil, "OVERLAY")
  cb.check:SetSize(12, 12)
  cb.check:SetPoint("CENTER")
  cb.check:SetColorTexture(1, 0.82, 0, 1)
  cb.check:Hide()
  cb.label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 8, 0)
  cb.label:SetText(label or "")
  cb.label:SetTextColor(0.9, 0.9, 0.9)
  cb.SetChecked = function(self, v)
    if v then self.check:Show() else self.check:Hide() end
    self.checked = v and true or false
  end
  cb.GetChecked = function(self)
    return self.check:IsShown()
  end
  cb:SetScript("OnClick", function(self)
    self:SetChecked(not self:GetChecked())
    if self.customOnClick then self.customOnClick(self) end
  end)
  return cb
end

local function CreateWizardFinishPopup()
  if WizardFinishPopup then return WizardFinishPopup end
  local p = CreateFrame("Frame", "CCMInstallWizardFinishPopup", UIParent, "BackdropTemplate")
  p:SetSize(430, 210)
  p:SetPoint("CENTER")
  p:SetFrameStrata("TOOLTIP")
  p:SetFrameLevel(3000)
  p:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  p:SetBackdropColor(0.08, 0.08, 0.10, 0.98)
  p:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  p:EnableMouse(true)
  p:SetMovable(true)
  p:RegisterForDrag("LeftButton")
  p:SetScript("OnDragStart", p.StartMoving)
  p:SetScript("OnDragStop", p.StopMovingOrSizing)
  p:Hide()

  local t = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -12)
  t:SetTextColor(1, 0.82, 0)
  t:SetText("Create Wizard Profile")

  local sub = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  sub:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
  sub:SetTextColor(0.75, 0.75, 0.8)
  sub:SetText("Choose a new profile name. Existing profiles are not overwritten.")

  local nameLbl = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameLbl:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
  nameLbl:SetTextColor(0.9, 0.9, 0.9)
  nameLbl:SetText("Profile Name")

  local nameBox = CreateFrame("EditBox", nil, p, "BackdropTemplate")
  nameBox:SetSize(300, 24)
  nameBox:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -6)
  nameBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  nameBox:SetBackdropColor(0.05, 0.05, 0.07, 1)
  nameBox:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  nameBox:SetFontObject("GameFontHighlight")
  nameBox:SetAutoFocus(true)
  nameBox:SetTextInsets(6, 6, 0, 0)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  WizardFinishNameBox = nameBox

  local sharedCB = CreateStyledCheckbox(p, "Shared Profile (all classes)")
  sharedCB:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -12)
  sharedCB:SetChecked(true)
  WizardFinishSharedCB = sharedCB

  local cancelBtn = addonTable.CreateStyledButton and addonTable.CreateStyledButton(p, "Cancel", 100, 24)
  cancelBtn:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -14, 14)
  cancelBtn:SetScript("OnClick", function() p:Hide() end)

  local applyBtn = addonTable.CreateStyledButton and addonTable.CreateStyledButton(p, "Create + Apply", 130, 24)
  applyBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -8, 0)
  p.applyBtn = applyBtn

  p.errorText = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  p.errorText:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 14, 20)
  p.errorText:SetTextColor(1, 0.4, 0.4)
  p.errorText:SetText("")

  WizardFinishPopup = p
  return p
end

local function CreateStyledSlider(parent, label, minVal, maxVal, defaultVal, step)
  if addonTable.Slider then
    return addonTable.Slider(parent, label, 0, 0, minVal, maxVal, defaultVal, step)
  end
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetSize(220, 16)
  s:SetMinMaxValues(minVal, maxVal)
  s:SetValue(defaultVal or minVal)
  s:SetValueStep(step or 1)
  s:SetObeyStepOnDrag(true)
  s.label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  s.label:SetText(label or "")
  s.valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  s.valueText:SetPoint("LEFT", s, "RIGHT", 10, 0)
  return s
end

local WizardState = {
  cursorIconsEnabled = true,
  useBlizzCDM = true,
  blizzSkinning = true,
  blizzCentered = false,
  usePersonalResourceBar = false,
  prbShowHealth = false,
  prbShowPower = false,
  prbShowClassPower = false,
  useCastbar = false,
  useFocusCastbar = false,
  useTargetCastbar = false,
  enablePlayerDebuffs = false,
  enableUnitFrameCustomization = true,
  ufUseBiggerHealthbars = true,
  ufAbsorbTracking = true,
  ufClassColor = true,
  ufBossFrames = false,
  enableCustomBars = true,
  customBarsCount = 1,
  useSpellGlows = false,
  trackBuffs = false,
  showGCD = true,
  combatTimerEnabled = false,
  crTimerEnabled = false,
  combatStatusEnabled = false,
  selfHighlightEnabled = false,
  noTargetAlertEnabled = false,
  lowHealthWarningEnabled = false,
  showRadialCircle = true,
  chatCopyButton = true,
  chatUrlDetection = true,
  autoRepair = false,
  autoSellJunk = false,
  skyridingEnabled = false,
  skyridingShowVigor = true,
  skyridingShowCooldowns = true,
  uiScaleMode = "disabled",
}

local function PopulateStateFromProfile()
  local p = GetProfile()
  if not p then return end
  WizardState.cursorIconsEnabled = p.cursorIconsEnabled ~= false
  WizardState.useBlizzCDM = p.useBlizzCDM ~= false
  WizardState.blizzSkinning = p.blizzardBarSkinning ~= false
  WizardState.blizzCentered = (p.standaloneBuffCentered == true) or (p.standaloneEssentialCentered == true) or (p.standaloneUtilityCentered == true)
  WizardState.usePersonalResourceBar = p.usePersonalResourceBar == true
  WizardState.prbShowHealth = p.prbShowHealth == true
  WizardState.prbShowPower = p.prbShowPower == true
  WizardState.prbShowClassPower = p.prbShowClassPower == true
  WizardState.useCastbar = p.useCastbar == true
  WizardState.useFocusCastbar = p.useFocusCastbar == true
  WizardState.useTargetCastbar = p.useTargetCastbar == true
  WizardState.enablePlayerDebuffs = p.enablePlayerDebuffs == true
  WizardState.enableUnitFrameCustomization = p.enableUnitFrameCustomization ~= false
  WizardState.ufUseBiggerHealthbars = (p.ufBigHBPlayerEnabled == true) or (p.ufBigHBTargetEnabled == true) or (p.ufBigHBFocusEnabled == true)
  WizardState.ufAbsorbTracking =
    (p.ufBigHBPlayerHealAbsorb or "on") ~= "off" or
    (p.ufBigHBPlayerDmgAbsorb or "bar_glow") ~= "off" or
    (p.ufBigHBTargetHealAbsorb or "off") ~= "off" or
    (p.ufBigHBTargetDmgAbsorb or "off") ~= "off" or
    (p.ufBigHBFocusHealAbsorb or "off") ~= "off" or
    (p.ufBigHBFocusDmgAbsorb or "off") ~= "off"
  WizardState.ufClassColor = p.ufClassColor == true
  WizardState.ufBossFrames = p.ufBossFramesEnabled == true
  WizardState.customBarsCount = math.max(0, math.min(5, tonumber(p.customBarsCount) or 1))
  WizardState.enableCustomBars = WizardState.customBarsCount > 0
  WizardState.useSpellGlows = p.useSpellGlows == true
  WizardState.trackBuffs = p.trackBuffs == true
  WizardState.showGCD = p.showGCD == true
  WizardState.combatTimerEnabled = p.combatTimerEnabled == true
  WizardState.crTimerEnabled = p.crTimerEnabled == true
  WizardState.combatStatusEnabled = p.combatStatusEnabled == true
  WizardState.selfHighlightEnabled = (p.selfHighlightShape or "off") ~= "off"
  WizardState.noTargetAlertEnabled = p.noTargetAlertEnabled == true
  WizardState.lowHealthWarningEnabled = p.lowHealthWarningEnabled == true
  WizardState.showRadialCircle = p.showRadialCircle ~= false
  WizardState.chatCopyButton = p.chatCopyButton == true
  WizardState.chatUrlDetection = p.chatUrlDetection == true
  WizardState.autoRepair = p.autoRepair == true
  WizardState.autoSellJunk = p.autoSellJunk == true
  WizardState.skyridingEnabled = p.skyridingEnabled == true
  WizardState.skyridingShowVigor = p.skyridingVigorBar ~= false
  WizardState.skyridingShowCooldowns = p.skyridingCooldowns ~= false
  WizardState.uiScaleMode = p.uiScaleMode or "disabled"
  if WizardCustomBarsSlider then
    WizardCustomBarsSlider._updating = true
    WizardCustomBarsSlider:SetValue(WizardState.customBarsCount or 0)
    WizardCustomBarsSlider._updating = false
    if WizardCustomBarsSlider.valueText then
      WizardCustomBarsSlider.valueText:SetText(tostring(WizardState.customBarsCount or 0))
    end
  end
  if WizardUiScaleDD and WizardUiScaleDD.SetValue then
    WizardUiScaleDD:SetValue(WizardState.uiScaleMode or "disabled")
  end
end

local function ApplyWizardToProfile()
  local p = GetProfile()
  if not p then return end
  p.cursorIconsEnabled = WizardState.cursorIconsEnabled == true
  p.useBlizzCDM = WizardState.useBlizzCDM == true
  p.blizzardBarSkinning = WizardState.blizzSkinning == true
  p.standaloneSkinBuff = WizardState.blizzSkinning == true
  p.standaloneSkinEssential = WizardState.blizzSkinning == true
  p.standaloneSkinUtility = WizardState.blizzSkinning == true
  p.standaloneBuffCentered = WizardState.blizzCentered == true
  p.standaloneEssentialCentered = WizardState.blizzCentered == true
  p.standaloneUtilityCentered = WizardState.blizzCentered == true
  p.usePersonalResourceBar = WizardState.usePersonalResourceBar == true
  p.prbShowHealth = (WizardState.usePersonalResourceBar == true) and (WizardState.prbShowHealth == true) or false
  p.prbShowPower = (WizardState.usePersonalResourceBar == true) and (WizardState.prbShowPower == true) or false
  p.prbShowClassPower = (WizardState.usePersonalResourceBar == true) and (WizardState.prbShowClassPower == true) or false
  p.useCastbar = WizardState.useCastbar == true
  p.useFocusCastbar = WizardState.useFocusCastbar == true
  p.useTargetCastbar = WizardState.useTargetCastbar == true
  p.enablePlayerDebuffs = WizardState.enablePlayerDebuffs == true
  p.enableUnitFrameCustomization = WizardState.enableUnitFrameCustomization == true
  p.ufClassColor = WizardState.ufClassColor == true
  p.ufBigHBPlayerEnabled = WizardState.ufUseBiggerHealthbars == true
  p.ufBigHBTargetEnabled = WizardState.ufUseBiggerHealthbars == true
  p.ufBigHBFocusEnabled = WizardState.ufUseBiggerHealthbars == true
  p.ufBossFramesEnabled = WizardState.ufBossFrames == true
  if WizardState.ufAbsorbTracking == true then
    p.ufBigHBPlayerHealAbsorb = "on"
    p.ufBigHBPlayerDmgAbsorb = "bar_glow"
    p.ufBigHBPlayerHealPred = "on"
    p.ufBigHBPlayerAbsorbStripes = true
    p.ufBigHBTargetHealAbsorb = "on"
    p.ufBigHBTargetDmgAbsorb = "bar_glow"
    p.ufBigHBTargetHealPred = "on"
    p.ufBigHBTargetAbsorbStripes = true
    p.ufBigHBFocusHealAbsorb = "on"
    p.ufBigHBFocusDmgAbsorb = "bar_glow"
    p.ufBigHBFocusHealPred = "on"
    p.ufBigHBFocusAbsorbStripes = true
  else
    p.ufBigHBPlayerHealAbsorb = "off"
    p.ufBigHBPlayerDmgAbsorb = "off"
    p.ufBigHBPlayerHealPred = "off"
    p.ufBigHBPlayerAbsorbStripes = false
    p.ufBigHBTargetHealAbsorb = "off"
    p.ufBigHBTargetDmgAbsorb = "off"
    p.ufBigHBTargetHealPred = "off"
    p.ufBigHBTargetAbsorbStripes = false
    p.ufBigHBFocusHealAbsorb = "off"
    p.ufBigHBFocusDmgAbsorb = "off"
    p.ufBigHBFocusHealPred = "off"
    p.ufBigHBFocusAbsorbStripes = false
  end
  p.customBarsCount = math.max(0, math.min(5, tonumber(WizardState.customBarsCount) or 0))
  if WizardState.enableCustomBars ~= true then
    p.customBarsCount = 0
  elseif p.customBarsCount <= 0 then
    p.customBarsCount = 1
  end
  p.customBarEnabled = p.customBarsCount >= 1
  p.customBar2Enabled = p.customBarsCount >= 2
  p.customBar3Enabled = p.customBarsCount >= 3
  p.customBar4Enabled = p.customBarsCount >= 4
  p.customBar5Enabled = p.customBarsCount >= 5
  p.useSpellGlows = WizardState.useSpellGlows == true
  if WizardState.useBlizzCDM ~= true then
    WizardState.trackBuffs = false
  end
  p.trackBuffs = WizardState.trackBuffs == true
  p.showGCD = WizardState.showGCD == true
  p.combatTimerEnabled = WizardState.combatTimerEnabled == true
  p.crTimerEnabled = WizardState.crTimerEnabled == true
  p.combatStatusEnabled = WizardState.combatStatusEnabled == true
  p.selfHighlightShape = (WizardState.selfHighlightEnabled == true) and (p.selfHighlightShape ~= "off" and p.selfHighlightShape or "cross") or "off"
  p.noTargetAlertEnabled = WizardState.noTargetAlertEnabled == true
  p.lowHealthWarningEnabled = WizardState.lowHealthWarningEnabled == true
  p.showRadialCircle = WizardState.showRadialCircle == true
  p.chatCopyButton = WizardState.chatCopyButton == true
  p.chatUrlDetection = WizardState.chatUrlDetection == true
  p.autoRepair = WizardState.autoRepair == true
  p.autoSellJunk = WizardState.autoSellJunk == true
  p.skyridingEnabled = WizardState.skyridingEnabled == true
  p.skyridingVigorBar = WizardState.skyridingShowVigor == true
  p.skyridingCooldowns = WizardState.skyridingShowCooldowns == true
  p.uiScaleMode = WizardState.uiScaleMode or "disabled"
  if p.uiScaleMode == "1080p" then
    p.uiScale = 0.71111
    SetCVar("uiScale", p.uiScale)
    UIParent:SetScale(p.uiScale)
  elseif p.uiScaleMode == "1440p" then
    p.uiScale = 0.53333
    SetCVar("uiScale", p.uiScale)
    UIParent:SetScale(p.uiScale)
  else
    p.uiScale = nil
  end

  if CooldownCursorManagerDB then
    CooldownCursorManagerDB.wizardCompleted = true
    CooldownCursorManagerDB.wizardCompletedVersion = "7.3.2"
  end

  if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
  if addonTable.CreateIcons then addonTable.CreateIcons() end
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
  if addonTable.UpdatePRB then addonTable.UpdatePRB() end
  if addonTable.SetupChatCopyButton then addonTable.SetupChatCopyButton() end
  if addonTable.SetupChatUrlDetection then addonTable.SetupChatUrlDetection() end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  if addonTable.UpdateNoTargetAlert then addonTable.UpdateNoTargetAlert() end
  if addonTable.UpdateLowHealthWarning then addonTable.UpdateLowHealthWarning() end
  if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
  if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
  if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
end

local function CreateWizardProfileAndApply()
  local popup = CreateWizardFinishPopup()
  local nameRaw = WizardFinishNameBox and WizardFinishNameBox:GetText() or ""
  local name = strtrim(nameRaw or "")
  if name == "" then
    popup.errorText:SetText("Please enter a profile name.")
    return
  end
  if not CooldownCursorManagerDB then
    popup.errorText:SetText("Profile database not available.")
    return
  end
  CooldownCursorManagerDB.profiles = CooldownCursorManagerDB.profiles or {}
  if CooldownCursorManagerDB.profiles[name] then
    popup.errorText:SetText("Profile name already exists. Please choose a different name.")
    return
  end
  CooldownCursorManagerDB.profiles[name] = {}
  CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
  if WizardFinishSharedCB and WizardFinishSharedCB:GetChecked() then
    CooldownCursorManagerDB.profileClasses[name] = nil
  else
    local _, englishClass = UnitClass("player")
    CooldownCursorManagerDB.profileClasses[name] = englishClass
  end
  CooldownCursorManagerDB.currentProfile = name
  if addonTable.SaveCurrentProfileForSpec then
    addonTable.SaveCurrentProfileForSpec()
  end

  CooldownCursorManagerDB._moduleStatesMigrated71 = true
  if type(CooldownCursorManagerDB.moduleStates) ~= "table" then
    CooldownCursorManagerDB.moduleStates = {}
  end
  local ms = CooldownCursorManagerDB.moduleStates
  ms.blizzcdm = WizardState.useBlizzCDM == true
  ms.prb = WizardState.usePersonalResourceBar == true
  ms.castbars = WizardState.useCastbar == true
    or WizardState.useFocusCastbar == true or WizardState.useTargetCastbar == true
  ms.debuffs = WizardState.enablePlayerDebuffs == true
  ms.unitframes = WizardState.enableUnitFrameCustomization == true
  ms.custombars = WizardState.enableCustomBars == true
  ms.qol = WizardState.chatCopyButton == true or WizardState.chatUrlDetection == true
    or WizardState.combatTimerEnabled == true or WizardState.crTimerEnabled == true
    or WizardState.combatStatusEnabled == true or WizardState.noTargetAlertEnabled == true
    or WizardState.lowHealthWarningEnabled == true
  if addonTable.SetModuleEnabled then
    for _, key in ipairs({"blizzcdm","prb","castbars","debuffs","unitframes","custombars","qol"}) do
      addonTable.SetModuleEnabled(key, ms[key])
    end
  end

  if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
  if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
  ApplyWizardToProfile()
  popup:Hide()
  if WizardFrame then WizardFrame:Hide() end
  if addonTable.ShowReloadPrompt then
    addonTable.ShowReloadPrompt("Installer profile '" .. name .. "' created and applied.\n\nReload UI now?", "Reload", "Later")
  end
  print("|cff00ff00CCM:|r Installer applied to profile '" .. name .. "'.")
end

local Steps = {
  { title = "Welcome", desc = "Quick overview of the most important CCM features." },
  { title = "UI Scale", desc = "Select a recommended UI scale preset." },
  { title = "Core Modules", desc = "Enable or disable the main CCM modules for your setup." },
  { title = "Display Behavior", desc = "Choose how cooldown icons should behave." },
  { title = "Quality of Life Features", desc = "Toggle combat and utility QoL features." },
  { title = "Review", desc = "Apply the wizard settings now." },
}

local function HideAllSteps()
  for i = 1, #StepContainers do
    StepContainers[i]:Hide()
  end
end

local function UpdateStepButtons()
  local total = #Steps
  WizardBackBtn:SetEnabled(CurrentStep > 1)
  local canNext = CurrentStep < total
  WizardNextBtn:SetEnabled(canNext)
  if WizardNextBtn then
    WizardNextBtn:SetAlpha(canNext and 1 or 0.45)
  end
  WizardFinishBtn:SetEnabled(CurrentStep == total)
  if WizardFinishBtn then
    WizardFinishBtn:SetAlpha((CurrentStep == total) and 1 or 0.45)
  end
  WizardProgress:SetText(string.format("Step %d/%d", CurrentStep, total))
end

local function BuildStep1(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  local ACCENT_R, ACCENT_G, ACCENT_B = 1, 0.82, 0
  local function AddHeader(anchor, text, yOff)
    local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    if anchor then
      h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff or -14)
    else
      h:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -10)
    end
    h:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
    h:SetText(text)
    return h
  end
  local function AddBody(anchor, text)
    local b = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    b:SetWidth(620)
    b:SetJustifyH("LEFT")
    b:SetJustifyV("TOP")
    b:SetTextColor(0.9, 0.9, 0.9)
    b:SetText(text)
    return b
  end

  local h1 = AddHeader(nil, "What CCM Does")
  local b1 = AddBody(h1, "Track and display your own cooldowns and buffs with clean, fast, highly customizable visuals.")

  local h2 = AddHeader(b1, "Core Features", -18)
  local b2 = AddBody(h2, table.concat({
    "- Cursor CDM: Track spells/buffs directly at your cursor.",
    "- Blizz CDM: Skin Blizzard cooldown bars and center standalone icons.",
    "- Custom Bars 1-5: Cooldowns + buff tracking with on-cooldown logic.",
    "- Per-Bar Control: Each Custom Bar is fully independent and configurable.",
  }, "\n"))

  local h3 = AddHeader(b2, "Combat UI", -18)
  local b3 = AddBody(h3, table.concat({
    "- Castbars: Custom player/focus/target castbars.",
    "- Unit Frames: Bigger healthbars, absorbs, class color, boss frames.",
    "- Combat widgets: Combat timer, CR timer, combat status, self highlight.",
  }, "\n"))

  local h4 = AddHeader(b3, "Quality of Life", -18)
  AddBody(h4, "- Chat improvements, auto repair, auto sell junk, and additional utility options.")
  return f
end

local function AddOption(parent, anchor, text, getValue, setValue)
  local cb = CreateStyledCheckbox(parent, text)
  cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  cb:SetChecked(getValue() == true)
  cb.customOnClick = function(self)
    setValue(self:GetChecked() == true)
  end
  return cb
end

local function BuildStep2(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()

  local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 0)
  if scroll.ScrollBar then
    scroll.ScrollBar:Hide()
    scroll.ScrollBar.Show = function() end
  end

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(640, 760)
  scroll:SetScrollChild(content)

  local bar = CreateFrame("Slider", nil, f, "BackdropTemplate")
  bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -2)
  bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 2)
  bar:SetWidth(10)
  bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  bar:SetBackdropColor(0.1, 0.1, 0.12, 1)
  bar:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  bar:SetOrientation("VERTICAL")
  bar:SetMinMaxValues(0, 0)
  bar:SetValue(0)
  local thumb = bar:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
  thumb:SetSize(8, 40)
  bar:SetThumbTexture(thumb)

  local function UpdateScrollRange()
    local max = math.max(0, (content:GetHeight() or 0) - (scroll:GetHeight() or 0))
    bar:SetMinMaxValues(0, max)
    if max <= 0 then
      bar:SetValue(0)
      bar:Hide()
    else
      bar:Show()
      if bar:GetValue() > max then bar:SetValue(max) end
      local visibleRatio = scroll:GetHeight() / (content:GetHeight() or 1)
      thumb:SetHeight(math.max(24, math.floor((scroll:GetHeight() * visibleRatio) + 0.5)))
    end
  end

  bar:SetScript("OnValueChanged", function(_, v)
    scroll:SetVerticalScroll(v or 0)
  end)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = bar:GetValue() or 0
    local nextV = cur - ((delta or 0) * 30)
    if nextV < 0 then nextV = 0 end
    local max = math.max(0, (content:GetHeight() or 0) - (scroll:GetHeight() or 0))
    if nextV > max then nextV = max end
    bar:SetValue(nextV)
  end)
  scroll:SetScript("OnSizeChanged", function()
    UpdateScrollRange()
  end)
  f:SetScript("OnShow", function()
    UpdateScrollRange()
    bar:SetValue(0)
  end)

  local COL1_X = 0
  local COL2_X = 320
  local SUB_INDENT = 22
  local ACCENT_R, ACCENT_G, ACCENT_B = 1, 0.82, 0
  local function AddHeader(x, y, text)
    local h = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    h:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    h:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
    h:SetText(text)
    return h
  end
  local function AddOptionAt(x, y, text, getValue, setValue)
    local cb = CreateStyledCheckbox(content, text)
    cb:ClearAllPoints()
    cb:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    cb:SetChecked(getValue() == true)
    cb.customOnClick = function(self)
      setValue(self:GetChecked() == true)
    end
    return cb
  end

  AddHeader(COL1_X, -6, "Cooldown Tracking")
  AddHeader(COL2_X, -6, "Castbars")

  AddOptionAt(COL1_X, -32, "Use Cursor CDM", function() return WizardState.cursorIconsEnabled end, function(v) WizardState.cursorIconsEnabled = v end)
  local c2 = AddOptionAt(COL1_X, -60, "Use Blizz CDM", function() return WizardState.useBlizzCDM end, function(v) WizardState.useBlizzCDM = v end)
  local c2a = AddOptionAt(COL1_X + SUB_INDENT, -88, "Blizz CDM: Skin standalone bars", function() return WizardState.blizzSkinning end, function(v) WizardState.blizzSkinning = v end)
  local c2b = AddOptionAt(COL1_X + SUB_INDENT, -116, "Blizz CDM: Center standalone bars", function() return WizardState.blizzCentered end, function(v) WizardState.blizzCentered = v end)

  AddOptionAt(COL2_X, -32, "Use Custom Castbar", function() return WizardState.useCastbar end, function(v) WizardState.useCastbar = v end)
  AddOptionAt(COL2_X, -60, "Use Focus Castbar", function() return WizardState.useFocusCastbar end, function(v) WizardState.useFocusCastbar = v end)
  AddOptionAt(COL2_X, -88, "Use Target Castbar", function() return WizardState.useTargetCastbar end, function(v) WizardState.useTargetCastbar = v end)

  local function UpdateBlizzSubOptions()
    local enabled = WizardState.useBlizzCDM == true
    c2a:SetEnabled(enabled)
    c2b:SetEnabled(enabled)
    c2a:SetAlpha(enabled and 1 or 0.45)
    c2b:SetAlpha(enabled and 1 or 0.45)
  end
  c2.customOnClick = function(self)
    WizardState.useBlizzCDM = self:GetChecked() == true
    UpdateBlizzSubOptions()
  end
  UpdateBlizzSubOptions()

  AddHeader(COL1_X, -170, "Resources")
  AddHeader(COL2_X, -170, "Unit Frames")

  local c3 = AddOptionAt(COL1_X, -196, "Enable Custom Bars", function() return WizardState.enableCustomBars end, function(v) WizardState.enableCustomBars = v end)
  local c3b = AddOptionAt(COL1_X, -224, "Use Personal Resource Bar", function() return WizardState.usePersonalResourceBar end, function(v) WizardState.usePersonalResourceBar = v end)
  local c3c = AddOptionAt(COL1_X + SUB_INDENT, -252, "PRB: Show Health", function() return WizardState.prbShowHealth end, function(v) WizardState.prbShowHealth = v end)
  local c3d = AddOptionAt(COL1_X + SUB_INDENT, -280, "PRB: Show Power", function() return WizardState.prbShowPower end, function(v) WizardState.prbShowPower = v end)
  local c3e = AddOptionAt(COL1_X + SUB_INDENT, -308, "PRB: Show Class Power", function() return WizardState.prbShowClassPower end, function(v) WizardState.prbShowClassPower = v end)
  AddOptionAt(COL1_X, -336, "Enable Player Debuffs", function() return WizardState.enablePlayerDebuffs end, function(v) WizardState.enablePlayerDebuffs = v end)

  local c8 = AddOptionAt(COL2_X, -196, "Enable Unit Frame Customization", function() return WizardState.enableUnitFrameCustomization end, function(v) WizardState.enableUnitFrameCustomization = v end)
  local c8a = AddOptionAt(COL2_X + SUB_INDENT, -224, "UF: Use Bigger Healthbars (Player/Target/Focus)", function() return WizardState.ufUseBiggerHealthbars end, function(v) WizardState.ufUseBiggerHealthbars = v end)
  local c8b = AddOptionAt(COL2_X + SUB_INDENT, -252, "UF: Absorb Tracking", function() return WizardState.ufAbsorbTracking end, function(v) WizardState.ufAbsorbTracking = v end)
  local c8c = AddOptionAt(COL2_X + SUB_INDENT, -280, "UF: Use Class Color", function() return WizardState.ufClassColor end, function(v) WizardState.ufClassColor = v end)
  local c8d = AddOptionAt(COL2_X + SUB_INDENT, -308, "UF: Boss Frames", function() return WizardState.ufBossFrames end, function(v) WizardState.ufBossFrames = v end)

  local function UpdateUFSubOptions()
    local ufEnabled = WizardState.enableUnitFrameCustomization == true
    local biggerHB = WizardState.ufUseBiggerHealthbars == true
    c8a:SetEnabled(ufEnabled)
    c8b:SetEnabled(ufEnabled and biggerHB)
    c8c:SetEnabled(ufEnabled)
    c8d:SetEnabled(ufEnabled)
    c8a:SetAlpha(ufEnabled and 1 or 0.45)
    c8b:SetAlpha((ufEnabled and biggerHB) and 1 or 0.45)
    c8c:SetAlpha(ufEnabled and 1 or 0.45)
    c8d:SetAlpha(ufEnabled and 1 or 0.45)
  end
  c8.customOnClick = function(self)
    WizardState.enableUnitFrameCustomization = self:GetChecked() == true
    UpdateUFSubOptions()
  end
  c8a.customOnClick = function(self)
    WizardState.ufUseBiggerHealthbars = self:GetChecked() == true
    UpdateUFSubOptions()
  end

  local function UpdatePRBSubOptions()
    local prbEnabled = WizardState.usePersonalResourceBar == true
    c3c:SetEnabled(prbEnabled)
    c3d:SetEnabled(prbEnabled)
    c3e:SetEnabled(prbEnabled)
    c3c:SetAlpha(prbEnabled and 1 or 0.45)
    c3d:SetAlpha(prbEnabled and 1 or 0.45)
    c3e:SetAlpha(prbEnabled and 1 or 0.45)
  end
  c3b.customOnClick = function(self)
    WizardState.usePersonalResourceBar = self:GetChecked() == true
    UpdatePRBSubOptions()
  end

  c3.customOnClick = function(self)
    local enabled = self:GetChecked() == true
    WizardState.enableCustomBars = enabled
    if enabled then
      if (tonumber(WizardState.customBarsCount) or 0) <= 0 then
        WizardState.customBarsCount = 1
      end
    else
      WizardState.customBarsCount = 0
    end
    if WizardCustomBarsSlider then
      WizardCustomBarsSlider._updating = true
      WizardCustomBarsSlider:SetValue(WizardState.customBarsCount)
      WizardCustomBarsSlider._updating = false
      if WizardCustomBarsSlider.valueText then
        WizardCustomBarsSlider.valueText:SetText(tostring(WizardState.customBarsCount))
      end
    end
  end
  UpdatePRBSubOptions()
  UpdateUFSubOptions()
  return f
end

local function BuildStep3(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  local anchor = CreateFrame("Frame", nil, f)
  anchor:SetSize(1, 1)
  anchor:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -6)
  local note = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  note:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
  note:SetWidth(500)
  note:SetJustifyH("LEFT")
  note:SetJustifyV("TOP")
  note:SetTextColor(0.9, 0.9, 0.9)
  note:SetText("|cffff4d4dNote|r: Add the spells/buffs you want in the spell list afterwards. Click the |cffffffffOpen Buff Tracker|r button on the right.")
  local openBuffBtn = addonTable.CreateStyledButton and addonTable.CreateStyledButton(f, "Open Buff Tracker", 130, 20) or nil
  if openBuffBtn then
    openBuffBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -4)
    openBuffBtn:SetScript("OnClick", function()
      local cfg = addonTable.ConfigFrame
      if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      end
      if not CooldownViewerSettings then return end
      CooldownViewerSettings:Show()
      C_Timer.After(0.1, function()
        if CooldownViewerSettings and CooldownViewerSettings.BuffsButton then
          CooldownViewerSettings.BuffsButton:Click()
        end
      end)
    end)
  end
  local c1 = AddOption(f, anchor, "Track Buffs", function() return WizardState.trackBuffs end, function(v) WizardState.trackBuffs = v end)
  c1:ClearAllPoints()
  c1:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -12)
  local c2 = AddOption(f, c1, "Use Spell Glows", function() return WizardState.useSpellGlows end, function(v) WizardState.useSpellGlows = v end)
  AddOption(f, c2, "Show GCD", function() return WizardState.showGCD end, function(v) WizardState.showGCD = v end)
  local slider = CreateStyledSlider(f, "Custom Bars (0 = Off)", 0, 5, WizardState.customBarsCount or 1, 1)
  slider.label:ClearAllPoints()
  slider.label:SetPoint("TOPLEFT", c2, "BOTTOMLEFT", 0, -40)
  slider:ClearAllPoints()
  slider:SetPoint("TOPLEFT", slider.label, "BOTTOMLEFT", 0, -8)
  slider:SetValue(WizardState.customBarsCount or 1)
  if slider.valueText then
    slider.valueText:SetText(tostring(WizardState.customBarsCount or 1))
  end
  slider:SetScript("OnValueChanged", function(_, v)
    if slider._updating then return end
    local n = math.floor((tonumber(v) or 0) + 0.5)
    if n < 0 then n = 0 end
    if n > 5 then n = 5 end
    WizardState.customBarsCount = n
    WizardState.enableCustomBars = n > 0
    if slider.valueText then
      slider.valueText:SetText(tostring(n))
    end
  end)
  WizardCustomBarsSlider = slider
  return f
end

local function BuildStep4(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  local function AddOptionAt(x, y, text, getValue, setValue)
    local cb = CreateStyledCheckbox(f, text)
    cb:ClearAllPoints()
    cb:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    cb:SetChecked(getValue() == true)
    cb.customOnClick = function(self)
      setValue(self:GetChecked() == true)
    end
    return cb
  end
  local colW = 320
  local rowH = 28
  local x0 = 0
  local y0 = -8
  local c1  = AddOptionAt(x0 + (0 * colW), y0 - (0 * rowH), "No Target Alert", function() return WizardState.noTargetAlertEnabled end, function(v) WizardState.noTargetAlertEnabled = v end)
  local c2  = AddOptionAt(x0 + (0 * colW), y0 - (1 * rowH), "Low Health Warn", function() return WizardState.lowHealthWarningEnabled end, function(v) WizardState.lowHealthWarningEnabled = v end)
  local c3  = AddOptionAt(x0 + (0 * colW), y0 - (2 * rowH), "Radial Circle", function() return WizardState.showRadialCircle end, function(v) WizardState.showRadialCircle = v end)
  local c4  = AddOptionAt(x0 + (0 * colW), y0 - (3 * rowH), "Combat Timer", function() return WizardState.combatTimerEnabled end, function(v) WizardState.combatTimerEnabled = v end)
  local c5  = AddOptionAt(x0 + (0 * colW), y0 - (4 * rowH), "Timer for CR", function() return WizardState.crTimerEnabled end, function(v) WizardState.crTimerEnabled = v end)
  local c6  = AddOptionAt(x0 + (0 * colW), y0 - (5 * rowH), "Combat Status", function() return WizardState.combatStatusEnabled end, function(v) WizardState.combatStatusEnabled = v end)
  local c7  = AddOptionAt(x0 + (1 * colW), y0 - (0 * rowH), "Self Highlight", function() return WizardState.selfHighlightEnabled end, function(v) WizardState.selfHighlightEnabled = v end)
  local c8  = AddOptionAt(x0 + (1 * colW), y0 - (1 * rowH), "Copy Chat Btn", function() return WizardState.chatCopyButton end, function(v) WizardState.chatCopyButton = v end)
  local c9  = AddOptionAt(x0 + (1 * colW), y0 - (2 * rowH), "Clickable URLs", function() return WizardState.chatUrlDetection end, function(v) WizardState.chatUrlDetection = v end)
  local c10 = AddOptionAt(x0 + (1 * colW), y0 - (3 * rowH), "Auto Repair", function() return WizardState.autoRepair end, function(v) WizardState.autoRepair = v end)
  local c11 = AddOptionAt(x0 + (1 * colW), y0 - (4 * rowH), "Auto Sell Junk", function() return WizardState.autoSellJunk end, function(v) WizardState.autoSellJunk = v end)
  local c12 = AddOptionAt(x0 + (1 * colW), y0 - (5 * rowH), "Skyriding UI", function() return WizardState.skyridingEnabled end, function(v) WizardState.skyridingEnabled = v end)
  local c12a = AddOptionAt(x0 + (1 * colW) + 22, y0 - (6 * rowH), "Sky: Charge Bar", function() return WizardState.skyridingShowVigor end, function(v) WizardState.skyridingShowVigor = v end)
  local c12b = AddOptionAt(x0 + (1 * colW) + 22, y0 - (7 * rowH), "Sky: Ability CDs", function() return WizardState.skyridingShowCooldowns end, function(v) WizardState.skyridingShowCooldowns = v end)
  local function UpdateSkyridingSubOptions()
    local enabled = WizardState.skyridingEnabled == true
    c12a:SetEnabled(enabled)
    c12b:SetEnabled(enabled)
    c12a:SetAlpha(enabled and 1 or 0.45)
    c12b:SetAlpha(enabled and 1 or 0.45)
  end
  c12.customOnClick = function(self)
    WizardState.skyridingEnabled = self:GetChecked() == true
    UpdateSkyridingSubOptions()
  end
  UpdateSkyridingSubOptions()
  return f
end

local function BuildStep5(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  local label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -8)
  label:SetTextColor(0.8, 0.8, 0.85)
  label:SetText("Choose your UI scale preset:")
  if addonTable.StyledDropdown then
    local dd = addonTable.StyledDropdown(f, nil, 0, 0, 180)
    dd:ClearAllPoints()
    dd:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -12)
    dd:SetOptions({
      { text = "Disabled", value = "disabled" },
      { text = "1080p (0.71)", value = "1080p" },
      { text = "1440p (0.53)", value = "1440p" },
    })
    dd.keepOpenOnSelect = false
    dd.onSelect = function(v)
      WizardState.uiScaleMode = v or "disabled"
    end
    dd:SetValue(WizardState.uiScaleMode or "disabled")
    WizardUiScaleDD = dd
  else
    local c1 = AddOption(f, label, "Disabled", function() return WizardState.uiScaleMode == "disabled" end, function(v) if v then WizardState.uiScaleMode = "disabled" end end)
    local c2 = AddOption(f, c1, "1080p (0.71)", function() return WizardState.uiScaleMode == "1080p" end, function(v) if v then WizardState.uiScaleMode = "1080p" end end)
    AddOption(f, c2, "1440p (0.53)", function() return WizardState.uiScaleMode == "1440p" end, function(v) if v then WizardState.uiScaleMode = "1440p" end end)
  end
  return f
end

local function BuildStep6(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  local anchor = CreateFrame("Frame", nil, f)
  anchor:SetSize(1, 1)
  anchor:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -6)
  local c1 = AddOption(f, anchor, "Copy Chat Button", function() return WizardState.chatCopyButton end, function(v) WizardState.chatCopyButton = v end)
  local c2 = AddOption(f, c1, "Clickable URLs", function() return WizardState.chatUrlDetection end, function(v) WizardState.chatUrlDetection = v end)
  local c3 = AddOption(f, c2, "Auto Repair", function() return WizardState.autoRepair end, function(v) WizardState.autoRepair = v end)
  local c4 = AddOption(f, c3, "Auto Sell Junk", function() return WizardState.autoSellJunk end, function(v) WizardState.autoSellJunk = v end)
  local c5 = AddOption(f, c4, "Enable Skyriding UI", function() return WizardState.skyridingEnabled end, function(v) WizardState.skyridingEnabled = v end)
  local c5a = AddOption(f, c5, "Skyriding: Charge Bar", function() return WizardState.skyridingShowVigor end, function(v) WizardState.skyridingShowVigor = v end)
  local c5b = AddOption(f, c5a, "Skyriding: Ability Cooldowns", function() return WizardState.skyridingShowCooldowns end, function(v) WizardState.skyridingShowCooldowns = v end)
  c5a:ClearAllPoints()
  c5a:SetPoint("TOPLEFT", c5, "BOTTOMLEFT", 22, -10)
  c5b:ClearAllPoints()
  c5b:SetPoint("TOPLEFT", c5a, "BOTTOMLEFT", 0, -10)
  local function UpdateSkyridingSubOptions()
    local enabled = WizardState.skyridingEnabled == true
    c5a:SetEnabled(enabled)
    c5b:SetEnabled(enabled)
    c5a:SetAlpha(enabled and 1 or 0.45)
    c5b:SetAlpha(enabled and 1 or 0.45)
  end
  c5.customOnClick = function(self)
    WizardState.skyridingEnabled = self:GetChecked() == true
    UpdateSkyridingSubOptions()
  end
  UpdateSkyridingSubOptions()
  return f
end

local function BuildStep7(parent)
  local f, content, scroll = CreateScrollableStepContainer(parent, 820)
  local summary = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  summary:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -8)
  summary:SetWidth(620)
  summary:SetJustifyH("LEFT")
  summary:SetJustifyV("TOP")
  summary:SetTextColor(0.85, 0.85, 0.9)
  summary:SetText("Ready to apply your setup.")
  WizardReviewSummary = summary
  WizardReviewScrollFrame = scroll
  WizardReviewScrollChild = content
  return f
end

local function BuildReviewSummaryText()
  local function onoff(v) return v and "On" or "Off" end
  local lines = {
    "Selected settings:",
    string.format("- Cursor CDM: %s", onoff(WizardState.cursorIconsEnabled)),
    string.format("- Blizz CDM: %s", onoff(WizardState.useBlizzCDM)),
  }
  if WizardState.useBlizzCDM then
    lines[#lines + 1] = string.format("- Blizz CDM Skinning: %s", onoff(WizardState.blizzSkinning))
    lines[#lines + 1] = string.format("- Blizz CDM Centered: %s", onoff(WizardState.blizzCentered))
  end
  lines[#lines + 1] = string.format("- Personal Resource Bar: %s", onoff(WizardState.usePersonalResourceBar))
  if WizardState.usePersonalResourceBar then
    lines[#lines + 1] = string.format("- PRB Show Health: %s", onoff(WizardState.prbShowHealth))
    lines[#lines + 1] = string.format("- PRB Show Power: %s", onoff(WizardState.prbShowPower))
    lines[#lines + 1] = string.format("- PRB Show Class Power: %s", onoff(WizardState.prbShowClassPower))
  end
  lines[#lines + 1] = string.format("- Custom Castbar: %s", onoff(WizardState.useCastbar))
  lines[#lines + 1] = string.format("- Focus Castbar: %s", onoff(WizardState.useFocusCastbar))
  lines[#lines + 1] = string.format("- Target Castbar: %s", onoff(WizardState.useTargetCastbar))
  lines[#lines + 1] = string.format("- Player Debuffs: %s", onoff(WizardState.enablePlayerDebuffs))
  lines[#lines + 1] = string.format("- Unit Frame Customization: %s", onoff(WizardState.enableUnitFrameCustomization))
  if WizardState.enableUnitFrameCustomization then
    lines[#lines + 1] = string.format("- UF Bigger Healthbars: %s", onoff(WizardState.ufUseBiggerHealthbars))
    lines[#lines + 1] = string.format("- UF Absorb Tracking: %s", onoff(WizardState.ufAbsorbTracking))
    lines[#lines + 1] = string.format("- UF Class Color: %s", onoff(WizardState.ufClassColor))
    lines[#lines + 1] = string.format("- UF Boss Frames: %s", onoff(WizardState.ufBossFrames))
  end
  lines[#lines + 1] = string.format("- Track Buffs: %s", onoff(WizardState.trackBuffs))
  lines[#lines + 1] = string.format("- Use Spell Glows: %s", onoff(WizardState.useSpellGlows))
  lines[#lines + 1] = string.format("- Show GCD: %s", onoff(WizardState.showGCD))
  lines[#lines + 1] = string.format("- Custom Bars Enabled: %s", onoff(WizardState.enableCustomBars))
  lines[#lines + 1] = string.format("- Custom Bars Count: %d", tonumber(WizardState.customBarsCount) or 0)
  lines[#lines + 1] = string.format("- Combat Timer: %s", onoff(WizardState.combatTimerEnabled))
  lines[#lines + 1] = string.format("- Timer for CR: %s", onoff(WizardState.crTimerEnabled))
  lines[#lines + 1] = string.format("- Combat Status: %s", onoff(WizardState.combatStatusEnabled))
  lines[#lines + 1] = string.format("- Self Highlight: %s", onoff(WizardState.selfHighlightEnabled))
  lines[#lines + 1] = string.format("- No Target Alert: %s", onoff(WizardState.noTargetAlertEnabled))
  lines[#lines + 1] = string.format("- Low Health Warning: %s", onoff(WizardState.lowHealthWarningEnabled))
  lines[#lines + 1] = string.format("- Radial Circle: %s", onoff(WizardState.showRadialCircle))
  lines[#lines + 1] = string.format("- UI Scale Mode: %s", WizardState.uiScaleMode or "disabled")
  lines[#lines + 1] = string.format("- Copy Chat Button: %s", onoff(WizardState.chatCopyButton))
  lines[#lines + 1] = string.format("- Clickable URLs: %s", onoff(WizardState.chatUrlDetection))
  lines[#lines + 1] = string.format("- Auto Repair: %s", onoff(WizardState.autoRepair))
  lines[#lines + 1] = string.format("- Auto Sell Junk: %s", onoff(WizardState.autoSellJunk))
  lines[#lines + 1] = string.format("- Skyriding UI: %s", onoff(WizardState.skyridingEnabled))
  if WizardState.skyridingEnabled then
    lines[#lines + 1] = string.format("- Skyriding Charge Bar: %s", onoff(WizardState.skyridingShowVigor))
    lines[#lines + 1] = string.format("- Skyriding Ability Cooldowns: %s", onoff(WizardState.skyridingShowCooldowns))
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Click |cffffff00Finish|r to apply and then reload."
  lines[#lines + 1] = "You can rerun this installer via Profile tab or /ccminstall."
  return table.concat(lines, "\n")
end

local function RefreshStep()
  HideAllSteps()
  local step = Steps[CurrentStep]
  if not step then return end
  WizardStepTitle:SetText(step.title)
  WizardStepBody:SetText(step.desc)
  if CurrentStep == #Steps and WizardReviewSummary then
    WizardReviewSummary:SetText(BuildReviewSummaryText())
    if WizardReviewScrollChild and WizardReviewSummary.GetStringHeight then
      local needed = math.max(820, math.floor(WizardReviewSummary:GetStringHeight() + 70))
      WizardReviewScrollChild:SetHeight(needed)
      if WizardReviewScrollChild._updateScrollRange then
        WizardReviewScrollChild._updateScrollRange()
      end
    end
    if WizardReviewScrollFrame then
      WizardReviewScrollFrame:SetVerticalScroll(0)
    end
  end
  if StepContainers[CurrentStep] then
    StepContainers[CurrentStep]:Show()
  end
  UpdateStepButtons()
end

local function EnsureWizardFrame()
  if WizardFrame then return WizardFrame end
  local f = CreateFrame("Frame", "CCMInstallWizard", UIParent, "BackdropTemplate")
  f:SetSize(700, 470)
  f:SetPoint("CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetFrameLevel(2000)
  f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
  f:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
  f:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()

  local top = CreateStyledPanel(f)
  top:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
  top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
  top:SetHeight(34)
  top:SetBackdropColor(0.15, 0.15, 0.18, 1)
  local title = top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("CENTER", top, "CENTER", 0, 0)
  title:SetText("Cooldown Cursor Manager Installer")
  title:SetTextColor(1, 0.82, 0)

  WizardCloseBtn = addonTable.CreateStyledButton
    and addonTable.CreateStyledButton(top, "X", 24, 24)
    or CreateFrame("Button", nil, top)
  WizardCloseBtn:SetPoint("RIGHT", top, "RIGHT", -6, 0)
  WizardCloseBtn:SetScript("OnClick", function() f:Hide() end)

  local content = CreateStyledPanel(f)
  content:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 10, -10)
  content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 58)
  content:SetBackdropColor(0.09, 0.09, 0.12, 0.95)

  WizardProgress = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  WizardProgress:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, -12)
  WizardProgress:SetTextColor(0.65, 0.65, 0.7)
  WizardProgress:SetText("Step 1/6")

  WizardStepTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  WizardStepTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 12, -10)
  WizardStepTitle:SetTextColor(1, 0.82, 0)

  WizardStepBody = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  WizardStepBody:SetPoint("TOPLEFT", WizardStepTitle, "BOTTOMLEFT", 0, -8)
  WizardStepBody:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, -38)
  WizardStepBody:SetJustifyH("LEFT")
  WizardStepBody:SetJustifyV("TOP")
  WizardStepBody:SetWordWrap(true)
  WizardStepBody:SetTextColor(0.8, 0.8, 0.85)

  local bodyHost = CreateFrame("Frame", nil, content)
  bodyHost:SetPoint("TOPLEFT", WizardStepBody, "BOTTOMLEFT", 0, -8)
  bodyHost:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -12, 12)

  StepContainers[1] = BuildStep1(bodyHost)
  StepContainers[2] = BuildStep5(bodyHost)
  StepContainers[3] = BuildStep2(bodyHost)
  StepContainers[4] = BuildStep3(bodyHost)
  StepContainers[5] = BuildStep4(bodyHost)
  StepContainers[6] = BuildStep7(bodyHost)

  WizardBackBtn = addonTable.CreateStyledButton and addonTable.CreateStyledButton(f, "Back", 90, 26)
  WizardBackBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 16)
  WizardBackBtn:SetScript("OnClick", function()
    if CurrentStep > 1 then
      CurrentStep = CurrentStep - 1
      RefreshStep()
    end
  end)

  WizardNextBtn = addonTable.CreateStyledButton and addonTable.CreateStyledButton(f, "Next", 90, 26)
  WizardNextBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -110, 16)
  WizardNextBtn:SetScript("OnClick", function()
    if CurrentStep < #Steps then
      CurrentStep = CurrentStep + 1
      RefreshStep()
    end
  end)

  WizardFinishBtn = addonTable.CreateStyledButton and addonTable.CreateStyledButton(f, "Finish", 90, 26)
  WizardFinishBtn:SetPoint("LEFT", WizardNextBtn, "RIGHT", 8, 0)
  WizardFinishBtn:SetScript("OnClick", function()
    local popup = CreateWizardFinishPopup()
    popup.errorText:SetText("")
    if WizardFinishNameBox then
      local existing = (CooldownCursorManagerDB and CooldownCursorManagerDB.currentProfile) or ""
      local defaultName = (existing and existing ~= "" and existing .. "_Wizard") or "WizardProfile"
      WizardFinishNameBox:SetText(defaultName)
      WizardFinishNameBox:SetFocus()
      WizardFinishNameBox:HighlightText()
      WizardFinishNameBox:SetScript("OnEnterPressed", function()
        CreateWizardProfileAndApply()
      end)
    end
    if popup.applyBtn then
      popup.applyBtn:SetScript("OnClick", function()
        CreateWizardProfileAndApply()
      end)
    end
    popup:Show()
  end)

  WizardFrame = f
  return f
end

addonTable.OpenInstallWizard = function()
  PopulateStateFromProfile()
  local frame = EnsureWizardFrame()
  CurrentStep = 1
  RefreshStep()
  frame:Show()
end

local wizardEventFrame = CreateFrame("Frame")
local wizardAutoStartDone = false
wizardEventFrame:RegisterEvent("PLAYER_LOGIN")
wizardEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
wizardEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
wizardEventFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    if wizardAutoStartDone then return end
    if CooldownCursorManagerDB and CooldownCursorManagerDB.wizardCompleted ~= true then
      wizardAutoStartDone = true
      if InCombatLockdown() then
        DeferredOpenAfterCombat = true
      else
        C_Timer.After(0.8, function()
          if addonTable.OpenInstallWizard then addonTable.OpenInstallWizard() end
        end)
      end
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if DeferredOpenAfterCombat and not InCombatLockdown() then
      DeferredOpenAfterCombat = false
      if addonTable.OpenInstallWizard then addonTable.OpenInstallWizard() end
    end
  end
end)

