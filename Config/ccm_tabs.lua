--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_tabs.lua
-- Configuration UI tab layouts and widgets
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
local addonTable = CCM
local function BuildTextureOptions()
  local options = {}
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local lsmBars = LSM:HashTable("statusbar")
    if lsmBars then
      local names = {}
      for name in pairs(lsmBars) do
        if type(name) == "string" and name ~= "" then
          names[#names + 1] = name
        end
      end
      table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
      end)
      for _, name in ipairs(names) do
        options[#options + 1] = {text = name, value = "lsm:" .. name}
      end
    end
  end
  if #options == 0 then
    options[#options + 1] = {text = "No LSM Statusbars Found", value = "", disabled = true}
  end
  return options
end
local textureOptions = BuildTextureOptions()
addonTable.GetTextureOptions = BuildTextureOptions
local function ApplyTextureOptionsToDropdown(dd)
  if not dd or not dd.SetOptions then return end
  dd:SetOptions(textureOptions)
  dd.keepOpenOnSelect = true
  dd.refreshOptions = function(self)
    self:SetOptions((addonTable.GetTextureOptions and addonTable.GetTextureOptions()) or textureOptions)
  end
end
local function RefreshTextureDropdownOptions()
  textureOptions = BuildTextureOptions()
  if addonTable.prb then
    ApplyTextureOptionsToDropdown(addonTable.prb.healthTextureDD)
    ApplyTextureOptionsToDropdown(addonTable.prb.powerTextureDD)
    ApplyTextureOptionsToDropdown(addonTable.prb.manaTextureDD)
  end
  if addonTable.castbar then
    ApplyTextureOptionsToDropdown(addonTable.castbar.textureDD)
  end
  if addonTable.focusCastbar then
    ApplyTextureOptionsToDropdown(addonTable.focusCastbar.textureDD)
  end
  if addonTable.targetCastbar then
    ApplyTextureOptionsToDropdown(addonTable.targetCastbar.textureDD)
  end
  ApplyTextureOptionsToDropdown(addonTable.ufHealthTextureDD)
  ApplyTextureOptionsToDropdown(addonTable.skyridingTextureDD)
end
addonTable.RefreshTextureDropdownOptions = RefreshTextureDropdownOptions
local function BuildFontOptions()
  local options = {}
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  local preferredFont = "Friz Quadrata TT"
  if LSM then
    local lsmFonts = LSM:HashTable("font")
    if lsmFonts then
      local names = {}
      for name in pairs(lsmFonts) do
        if type(name) == "string" and name ~= "" then
          names[#names + 1] = name
        end
      end
      table.sort(names, function(a, b)
        if a == preferredFont and b ~= preferredFont then return true end
        if b == preferredFont and a ~= preferredFont then return false end
        return string.lower(a) < string.lower(b)
      end)
      for _, name in ipairs(names) do
        options[#options + 1] = {text = name, value = "lsm:" .. name}
      end
    end
  end
  if #options == 0 then
    options[#options + 1] = {text = "No LSM Fonts Found", value = "", disabled = true}
  end
  return options
end
local fontOptions = BuildFontOptions()
addonTable.GetFontOptions = BuildFontOptions
local function ApplyFontOptionsToDropdown(dd)
  if not dd or not dd.SetOptions then return end
  dd:SetOptions(fontOptions)
  dd.keepOpenOnSelect = true
  dd.refreshOptions = function(self)
    self:SetOptions((addonTable.GetFontOptions and addonTable.GetFontOptions()) or fontOptions)
  end
end
local function RefreshFontDropdownOptions()
  fontOptions = BuildFontOptions()
  ApplyFontOptionsToDropdown(addonTable.fontDD)
end
addonTable.RefreshFontDropdownOptions = RefreshFontDropdownOptions
local function BuildSoundOptions()
  local options = {{text = "None", value = "None"}}
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local sounds = LSM:List("sound")
    if sounds then
      for _, name in ipairs(sounds) do
        if name ~= "None" then
          table.insert(options, {text = name, value = name})
        end
      end
    end
  end
  return options
end
local soundOptions = BuildSoundOptions()
addonTable.GetSoundOptions = BuildSoundOptions
local function ApplySoundOptionsToDropdown(dd)
  if not dd or not dd.SetOptions then return end
  dd:SetOptions(soundOptions)
  dd.keepOpenOnSelect = true
  dd.refreshOptions = function(self)
    self:SetOptions((addonTable.GetSoundOptions and addonTable.GetSoundOptions()) or soundOptions)
  end
end
do
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM and LSM.RegisterCallback and not addonTable._ccmLsmStatusbarRegistered then
    addonTable._ccmLsmStatusbarRegistered = true
    LSM.RegisterCallback(addonTable, "LibSharedMedia_Registered", function(_, mediaType)
      if mediaType == "statusbar" then
        RefreshTextureDropdownOptions()
      elseif mediaType == "font" then
        RefreshFontDropdownOptions()
      elseif mediaType == "sound" then
        soundOptions = BuildSoundOptions()
        if addonTable.lowHealthWarningSoundDD then ApplySoundOptionsToDropdown(addonTable.lowHealthWarningSoundDD) end
      end
    end)
  end
end
local function SetSmoothScroll(scrollFrame, step)
  step = step or 30
  if scrollFrame and scrollFrame.GetName then
    local name = scrollFrame:GetName()
    if name then
      local bar = _G[name .. "ScrollBar"]
      if bar then
        bar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, -16)
        bar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 16)
        bar:SetWidth(10)
        local thumb = bar:GetThumbTexture()
        if thumb then
          thumb:SetColorTexture(0.4, 0.4, 0.45, 0.85)
          thumb:SetSize(8, 40)
        end
        local up = _G[name .. "ScrollBarScrollUpButton"]
        local down = _G[name .. "ScrollBarScrollDownButton"]
        if up then up:SetAlpha(0); up:EnableMouse(false) end
        if down then down:SetAlpha(0); down:EnableMouse(false) end
      end
    end
  end
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local name = self.GetName and self:GetName()
    if not name then return end
    local bar = _G[name .. "ScrollBar"]
    if not bar then return end
    local cur = bar:GetValue()
    local mn, mx = bar:GetMinMaxValues()
    local newVal = cur - (delta * step)
    if newVal < mn then newVal = mn end
    if newVal > mx then newVal = mx end
    bar:SetValue(newVal)
  end)
end
local function InitTabs()
  local tabFrames = addonTable.tabFrames
  local Section = addonTable.Section
  local Slider = addonTable.Slider
  local Checkbox = addonTable.Checkbox
  local StyledDropdown = addonTable.StyledDropdown
  local CreateStyledButton = addonTable.CreateStyledButton
  local function CreateHighlightToggle(parent)
    local btn = CreateStyledButton(parent, "Highlight Off", 90, 20)
    btn:SetScript("OnClick", function()
      if addonTable.ToggleHighlights then addonTable.ToggleHighlights() end
    end)
    table.insert(addonTable.highlightToggleBtns, btn)
    return btn
  end
  if not tabFrames then return end
  local tab1 = tabFrames[1]
  local generalScrollFrame = CreateFrame("ScrollFrame", "CCMGeneralScrollFrame", tab1, "UIPanelScrollFrameTemplate")
  generalScrollFrame:SetPoint("TOPLEFT", tab1, "TOPLEFT", 0, 0)
  generalScrollFrame:SetPoint("BOTTOMRIGHT", tab1, "BOTTOMRIGHT", -22, 0)
  local generalScrollChild = CreateFrame("Frame", "CCMGeneralScrollChild", generalScrollFrame)
  generalScrollChild:SetSize(490, 580)
  generalScrollFrame:SetScrollChild(generalScrollChild)
  local scrollBar = _G["CCMGeneralScrollFrameScrollBar"]
  if scrollBar then
    scrollBar:SetPoint("TOPLEFT", generalScrollFrame, "TOPRIGHT", 6, -16)
    scrollBar:SetPoint("BOTTOMLEFT", generalScrollFrame, "BOTTOMRIGHT", 6, 16)
    local thumb = scrollBar:GetThumbTexture()
    if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
    local up = _G["CCMGeneralScrollFrameScrollBarScrollUpButton"]
    local down = _G["CCMGeneralScrollFrameScrollBarScrollDownButton"]
    if up then up:SetAlpha(0); up:EnableMouse(false) end
    if down then down:SetAlpha(0); down:EnableMouse(false) end
  end
  SetSmoothScroll(generalScrollFrame)
  local gc = generalScrollChild
  addonTable.fontDD, addonTable.fontLbl = StyledDropdown(gc, "Global Font", 15, -15, 260)
  ApplyFontOptionsToDropdown(addonTable.fontDD)
  addonTable.outlineDD, addonTable.outlineLbl = StyledDropdown(gc, "Outline", 280, -15, 120)
  addonTable.outlineDD:SetOptions({
    {text = "None", value = ""},
    {text = "Outline", value = "OUTLINE"},
    {text = "Thick Outline", value = "THICKOUTLINE"},
    {text = "Monochrome", value = "MONOCHROME"},
  })
  addonTable.audioChannelDD, addonTable.audioChannelLbl = StyledDropdown(gc, "Audio Channel", 15, -60, 150)
  addonTable.audioChannelDD:SetOptions({
    {text = "Master", value = "Master"},
    {text = "SFX", value = "SFX"},
    {text = "Music", value = "Music"},
    {text = "Ambience", value = "Ambience"},
    {text = "Dialog", value = "Dialog"},
  })
  addonTable.minimapCB = Checkbox(gc, "Minimap Icon", 200, -80)
  local gcScaleSec = Section(gc, "UI Scale", -110)
  addonTable.uiScaleDD = StyledDropdown(gc, nil, 15, -135, 150)
  addonTable.uiScaleDD:ClearAllPoints()
  addonTable.uiScaleDD:SetPoint("TOPLEFT", gcScaleSec, "BOTTOMLEFT", 0, -12)
  addonTable.uiScaleDD:SetOptions({
    {text = "Disabled", value = "disabled"},
    {text = "1080p (0.71)", value = "1080p"},
    {text = "1440p (0.53)", value = "1440p"},
    {text = "Custom", value = "custom"},
  })
  addonTable.uiScaleSlider = Slider(gc, "Custom Scale", 200, -128, 0.4, 1.0, 0.71, 0.01)
  addonTable.uiScaleSlider.label:ClearAllPoints()
  addonTable.uiScaleSlider.label:SetPoint("LEFT", addonTable.uiScaleDD, "RIGHT", 35, 0)
  addonTable.uiScaleSlider:ClearAllPoints()
  addonTable.uiScaleSlider:SetPoint("TOPLEFT", addonTable.uiScaleSlider.label, "BOTTOMLEFT", 0, -8)
  local gcIconSec = Section(gc, "Icon Appearance", -193)
  addonTable.iconBorderSlider = Slider(gc, "Icon Border Size (0-3)", 15, -218, 0, 3, 1, 1)
  addonTable.iconBorderSlider.label:ClearAllPoints()
  addonTable.iconBorderSlider.label:SetPoint("TOPLEFT", gcIconSec, "BOTTOMLEFT", 0, -12)
  addonTable.iconBorderSlider:ClearAllPoints()
  addonTable.iconBorderSlider:SetPoint("TOPLEFT", addonTable.iconBorderSlider.label, "BOTTOMLEFT", 0, -8)
  addonTable.strataDD, addonTable.strataLbl = StyledDropdown(gc, "Frame Strata", 280, -218, 120)
  addonTable.strataDD:ClearAllPoints()
  addonTable.strataDD:SetPoint("TOPLEFT", gcIconSec, "BOTTOMLEFT", 265, -12)
  if addonTable.strataLbl then addonTable.strataLbl:ClearAllPoints(); addonTable.strataLbl:SetPoint("BOTTOMLEFT", addonTable.strataDD, "TOPLEFT", 0, 4) end
  addonTable.strataDD:SetOptions({
    {text = "Background", value = "BACKGROUND"},
    {text = "Low", value = "LOW"},
    {text = "Medium", value = "MEDIUM"},
    {text = "High", value = "HIGH"},
    {text = "Dialog", value = "DIALOG"},
    {text = "Fullscreen", value = "FULLSCREEN"},
    {text = "Fullscreen Dialog", value = "FULLSCREEN_DIALOG"},
    {text = "Tooltip", value = "TOOLTIP"},
  })
  local gcModSec = Section(gc, "Modules", -296)
  addonTable.cursorCDMCB = Checkbox(gc, "Use Cursor CDM", 15, -322)
  addonTable.cursorCDMCB:ClearAllPoints()
  addonTable.cursorCDMCB:SetPoint("TOPLEFT", gcModSec, "BOTTOMLEFT", 0, -12)
  addonTable.disableBlizzCDMCB = Checkbox(gc, "Use Blizz CDM", 280, -322)
  addonTable.disableBlizzCDMCB:ClearAllPoints()
  addonTable.disableBlizzCDMCB:SetPoint("TOPLEFT", gcModSec, "BOTTOMLEFT", 265, -12)
  addonTable.prbCB = Checkbox(gc, "Use Personal Resource Bar", 15, -354)
  addonTable.prbCB:ClearAllPoints()
  addonTable.prbCB:SetPoint("TOPLEFT", addonTable.cursorCDMCB, "BOTTOMLEFT", 0, -10)
  addonTable.castbarCB = Checkbox(gc, "Use Custom Castbar", 280, -354)
  addonTable.castbarCB:ClearAllPoints()
  addonTable.castbarCB:SetPoint("TOPLEFT", addonTable.disableBlizzCDMCB, "BOTTOMLEFT", 0, -10)
  addonTable.focusCastbarCB = Checkbox(gc, "Use Custom Focus Castbar", 15, -386)
  addonTable.focusCastbarCB:ClearAllPoints()
  addonTable.focusCastbarCB:SetPoint("TOPLEFT", addonTable.prbCB, "BOTTOMLEFT", 0, -10)
  addonTable.targetCastbarCB = Checkbox(gc, "Use Custom Target Castbar", 280, -386)
  addonTable.targetCastbarCB:ClearAllPoints()
  addonTable.targetCastbarCB:SetPoint("TOPLEFT", addonTable.castbarCB, "BOTTOMLEFT", 0, -10)
  addonTable.playerDebuffsCB = Checkbox(gc, "Enable Player Debuffs Skinning", 15, -418)
  addonTable.playerDebuffsCB:ClearAllPoints()
  addonTable.playerDebuffsCB:SetPoint("TOPLEFT", addonTable.focusCastbarCB, "BOTTOMLEFT", 0, -10)
  addonTable.unitFrameCustomizationCB = Checkbox(gc, "Enable Unit Frame Customization", 280, -418)
  addonTable.unitFrameCustomizationCB:ClearAllPoints()
  addonTable.unitFrameCustomizationCB:SetPoint("TOPLEFT", addonTable.targetCastbarCB, "BOTTOMLEFT", 0, -10)
  addonTable.customBarsCountSlider = Slider(gc, "Custom Bars (0 = Off)", 15, -450, 0, 5, 3, 1)
  addonTable.customBarsCountSlider.label:ClearAllPoints()
  addonTable.customBarsCountSlider.label:SetPoint("TOPLEFT", addonTable.playerDebuffsCB, "BOTTOMLEFT", 0, -18)
  addonTable.customBarsCountSlider:ClearAllPoints()
  addonTable.customBarsCountSlider:SetPoint("TOPLEFT", addonTable.customBarsCountSlider.label, "BOTTOMLEFT", 0, -8)
  local ccmLinkPopup = CreateFrame("Frame", "CCMLinkPopup", UIParent, "BackdropTemplate")
  ccmLinkPopup:SetSize(420, 100)
  ccmLinkPopup:SetPoint("CENTER")
  ccmLinkPopup:SetFrameStrata("DIALOG")
  ccmLinkPopup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  ccmLinkPopup:SetBackdropColor(0.1, 0.1, 0.12, 0.95)
  ccmLinkPopup:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  ccmLinkPopup:EnableMouse(true)
  ccmLinkPopup:SetMovable(true)
  ccmLinkPopup:RegisterForDrag("LeftButton")
  ccmLinkPopup:SetScript("OnDragStart", ccmLinkPopup.StartMoving)
  ccmLinkPopup:SetScript("OnDragStop", ccmLinkPopup.StopMovingOrSizing)
  ccmLinkPopup:Hide()
  local popupTitle = ccmLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  popupTitle:SetPoint("TOP", ccmLinkPopup, "TOP", 0, -12)
  popupTitle:SetTextColor(1, 0.82, 0)
  local popupEditBox = CreateFrame("EditBox", nil, ccmLinkPopup, "BackdropTemplate")
  popupEditBox:SetSize(380, 24)
  popupEditBox:SetPoint("CENTER", ccmLinkPopup, "CENTER", 0, 2)
  popupEditBox:SetFontObject(ChatFontNormal)
  popupEditBox:SetAutoFocus(false)
  popupEditBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  popupEditBox:SetBackdropColor(0.05, 0.05, 0.07, 1)
  popupEditBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
  popupEditBox:SetTextInsets(6, 6, 0, 0)
  popupEditBox:SetScript("OnEscapePressed", function() ccmLinkPopup:Hide() end)
  popupEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  local popupClose = CreateStyledButton(ccmLinkPopup, "Close", 80, 22)
  popupClose:SetPoint("BOTTOM", ccmLinkPopup, "BOTTOM", 0, 8)
  popupClose:SetScript("OnClick", function() ccmLinkPopup:Hide() end)
  local function ShowLinkPopup(title, url)
    popupTitle:SetText(title)
    popupEditBox:SetText(url)
    ccmLinkPopup:Show()
    popupEditBox:SetFocus()
    popupEditBox:HighlightText()
  end
  local function CreateLinkButton(parent, label, title, url, xOff, yOff, iconColor)
    local btn = CreateStyledButton(parent, label, 120, 28)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    local indicator = btn:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(8, 8)
    indicator:SetPoint("LEFT", btn, "LEFT", 8, 0)
    indicator:SetColorTexture(iconColor.r, iconColor.g, iconColor.b, 1)
    local fs = btn:GetFontString()
    if fs then fs:SetPoint("CENTER", btn, "CENTER", 4, 0) end
    btn:SetScript("OnClick", function() ShowLinkPopup(title, url) end)
    return btn
  end
  CreateLinkButton(gc, "Discord", "Discord", "https://discord.gg/a7MhAssVWU", 15, -520, {r=0.44, g=0.55, b=0.85})
  CreateLinkButton(gc, "Bug Report", "Bug Report", "https://github.com/edeljay-official/CooldownCursorManager/issues/new?template=bug_report.md", 145, -520, {r=0.9, g=0.4, b=0.4})
  CreateLinkButton(gc, "Request", "Feature Request", "https://github.com/edeljay-official/CooldownCursorManager/issues/new?template=feature_request.md", 275, -520, {r=0.4, g=0.9, b=0.4})
  local tab2 = tabFrames[2]
  addonTable.cursor = {}
  local cur = addonTable.cursor
  local curTabSF = CreateFrame("ScrollFrame", "CCMCursorTabSF", tab2, "UIPanelScrollFrameTemplate")
  curTabSF:SetPoint("TOPLEFT", tab2, "TOPLEFT", 0, 0)
  curTabSF:SetPoint("BOTTOMRIGHT", tab2, "BOTTOMRIGHT", -22, 0)
  local curTabSC = CreateFrame("Frame", "CCMCursorTabSC", curTabSF)
  curTabSC:SetSize(490, 830)
  curTabSF:SetScrollChild(curTabSC)
  local curTabBar = _G["CCMCursorTabSFScrollBar"]
  if curTabBar then
    curTabBar:SetPoint("TOPLEFT", curTabSF, "TOPRIGHT", 6, -16)
    curTabBar:SetPoint("BOTTOMLEFT", curTabSF, "BOTTOMRIGHT", 6, 16)
    local ctThumb = curTabBar:GetThumbTexture()
    if ctThumb then ctThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); ctThumb:SetSize(8, 40) end
    local ctUp = _G["CCMCursorTabSFScrollBarScrollUpButton"]
    local ctDown = _G["CCMCursorTabSFScrollBarScrollDownButton"]
    if ctUp then ctUp:SetAlpha(0); ctUp:EnableMouse(false) end
    if ctDown then ctDown:SetAlpha(0); ctDown:EnableMouse(false) end
  end
  SetSmoothScroll(curTabSF)
  local function SyncCurTabWidth()
    local w = curTabSF:GetWidth()
    if w and w > 1 then curTabSC:SetWidth(w) end
  end
  curTabSF:HookScript("OnSizeChanged", SyncCurTabWidth)
  C_Timer.After(0, SyncCurTabWidth)
  local ct = curTabSC
  local curSettingsSec = Section(ct, "Cursor CDM Settings", -12)
  cur.combatOnlyCB = Checkbox(ct, "Combat Only", 15, -40)
  cur.combatOnlyCB:ClearAllPoints()
  cur.combatOnlyCB:SetPoint("TOPLEFT", curSettingsSec, "BOTTOMLEFT", 0, -14)
  cur.gcdCB = Checkbox(ct, "Show GCD", 150, -40)
  cur.gcdCB:ClearAllPoints()
  cur.gcdCB:SetPoint("LEFT", cur.combatOnlyCB.label, "RIGHT", 15, 0)
  cur.cooldownModeDD, cur.cooldownModeLbl = StyledDropdown(ct, "On Cooldown", 350, -40, 110)
  cur.cooldownModeDD:ClearAllPoints()
  cur.cooldownModeDD:SetPoint("LEFT", cur.gcdCB.label, "RIGHT", 15, 0)
  if cur.cooldownModeLbl then cur.cooldownModeLbl:ClearAllPoints(); cur.cooldownModeLbl:SetPoint("BOTTOMLEFT", cur.cooldownModeDD, "TOPLEFT", 0, 4) end
  cur.cooldownModeDD:SetOptions({{text = "Show", value = "show"}, {text = "Hide", value = "hide"}, {text = "Desaturate", value = "desaturate"}, {text = "Hide Available", value = "hideAvailable"}})
  cur.alwaysShowInCB = Checkbox(ct, "Always Show in", 500, -40)
  cur.alwaysShowInCB:ClearAllPoints()
  cur.alwaysShowInCB:SetPoint("LEFT", cur.cooldownModeDD, "RIGHT", 15, 0)
  cur.alwaysShowInDD, cur.alwaysShowInLbl = StyledDropdown(ct, nil, 500, -50, 100)
  cur.alwaysShowInDD:ClearAllPoints()
  cur.alwaysShowInDD:SetPoint("LEFT", cur.alwaysShowInCB.label, "RIGHT", 5, 0)
  if cur.alwaysShowInLbl then cur.alwaysShowInLbl:Hide() end
  cur.alwaysShowInDD:SetOptions({{text = "Raid", value = "raid"}, {text = "Dungeon", value = "dungeon"}, {text = "Dungeon & Raid", value = "raidanddungeon"}})
  cur.iconSizeSlider = Slider(ct, "Icon Size", 15, -80, 10, 80, 23, 1)
  cur.iconSizeSlider.label:ClearAllPoints()
  cur.iconSizeSlider.label:SetPoint("TOPLEFT", curSettingsSec, "BOTTOMLEFT", 0, -55)
  cur.iconSizeSlider:ClearAllPoints()
  cur.iconSizeSlider:SetPoint("TOPLEFT", cur.iconSizeSlider.label, "BOTTOMLEFT", 0, -8)
  cur.spacingSlider = Slider(ct, "Spacing", 280, -80, -3, 10, 2, 1)
  cur.spacingSlider.label:ClearAllPoints()
  cur.spacingSlider.label:SetPoint("TOPLEFT", curSettingsSec, "BOTTOMLEFT", 265, -55)
  cur.spacingSlider:ClearAllPoints()
  cur.spacingSlider:SetPoint("TOPLEFT", cur.spacingSlider.label, "BOTTOMLEFT", 0, -8)
  cur.offsetXSlider = Slider(ct, "Cursor Offset X", 15, -135, -100, 100, 10, 1)
  cur.offsetXSlider.label:ClearAllPoints()
  cur.offsetXSlider.label:SetPoint("TOPLEFT", cur.iconSizeSlider, "BOTTOMLEFT", 0, -25)
  cur.offsetXSlider:ClearAllPoints()
  cur.offsetXSlider:SetPoint("TOPLEFT", cur.offsetXSlider.label, "BOTTOMLEFT", 0, -8)
  cur.offsetYSlider = Slider(ct, "Cursor Offset Y", 280, -135, -100, 100, 25, 1)
  cur.offsetYSlider.label:ClearAllPoints()
  cur.offsetYSlider.label:SetPoint("TOPLEFT", cur.spacingSlider, "BOTTOMLEFT", 0, -25)
  cur.offsetYSlider:ClearAllPoints()
  cur.offsetYSlider:SetPoint("TOPLEFT", cur.offsetYSlider.label, "BOTTOMLEFT", 0, -8)
  cur.cdTextSlider = Slider(ct, "CD Text Scale", 15, -190, 0, 2.0, 1.0, 0.1)
  cur.cdTextSlider.label:ClearAllPoints()
  cur.cdTextSlider.label:SetPoint("TOPLEFT", cur.offsetXSlider, "BOTTOMLEFT", 0, -25)
  cur.cdTextSlider:ClearAllPoints()
  cur.cdTextSlider:SetPoint("TOPLEFT", cur.cdTextSlider.label, "BOTTOMLEFT", 0, -8)
  cur.cdGradientSlider = Slider(ct, "CD Gradient (sec)", 280, -190, 0, 30, 0, 1)
  cur.cdGradientSlider.label:ClearAllPoints()
  cur.cdGradientSlider.label:SetPoint("TOPLEFT", cur.offsetYSlider, "BOTTOMLEFT", 0, -25)
  cur.cdGradientSlider:ClearAllPoints()
  cur.cdGradientSlider:SetPoint("TOPLEFT", cur.cdGradientSlider.label, "BOTTOMLEFT", 0, -8)
  cur.cdGradientColorSwatch = CreateFrame("Frame", nil, ct, "BackdropTemplate")
  cur.cdGradientColorSwatch:SetSize(20, 20)
  cur.cdGradientColorSwatch:SetPoint("LEFT", cur.cdGradientSlider.valueTextBg, "RIGHT", 26, 0)
  cur.cdGradientColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cur.cdGradientColorSwatch:SetBackdropColor(1, 0, 0, 1)
  cur.cdGradientColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  cur.cdGradientColorSwatch:EnableMouse(true)
  cur.stackTextSlider = Slider(ct, "Stack Text Scale", 15, -245, 0.5, 2.0, 1.0, 0.1)
  cur.stackTextSlider.label:ClearAllPoints()
  cur.stackTextSlider.label:SetPoint("TOPLEFT", cur.cdTextSlider, "BOTTOMLEFT", 0, -25)
  cur.stackTextSlider:ClearAllPoints()
  cur.stackTextSlider:SetPoint("TOPLEFT", cur.stackTextSlider.label, "BOTTOMLEFT", 0, -8)
  cur.stackXSlider = Slider(ct, "Stack Offset X", 280, -245, -20, 20, 0, 1)
  cur.stackXSlider.label:ClearAllPoints()
  cur.stackXSlider.label:SetPoint("TOPLEFT", cur.cdGradientSlider, "BOTTOMLEFT", 0, -25)
  cur.stackXSlider:ClearAllPoints()
  cur.stackXSlider:SetPoint("TOPLEFT", cur.stackXSlider.label, "BOTTOMLEFT", 0, -8)
  cur.stackYSlider = Slider(ct, "Stack Offset Y", 15, -300, -20, 20, 0, 1)
  cur.stackYSlider.label:ClearAllPoints()
  cur.stackYSlider.label:SetPoint("TOPLEFT", cur.stackTextSlider, "BOTTOMLEFT", 0, -25)
  cur.stackYSlider:ClearAllPoints()
  cur.stackYSlider:SetPoint("TOPLEFT", cur.stackYSlider.label, "BOTTOMLEFT", 0, -8)
  cur.iconsPerRowSlider = Slider(ct, "Icons Per Row", 280, -300, 1, 20, 10, 1)
  cur.iconsPerRowSlider.label:ClearAllPoints()
  cur.iconsPerRowSlider.label:SetPoint("TOPLEFT", cur.stackXSlider, "BOTTOMLEFT", 0, -25)
  cur.iconsPerRowSlider:ClearAllPoints()
  cur.iconsPerRowSlider:SetPoint("TOPLEFT", cur.iconsPerRowSlider.label, "BOTTOMLEFT", 0, -8)
  cur.directionDD, cur.directionLbl = StyledDropdown(ct, "Direction", 15, -360, 120)
  cur.directionDD:ClearAllPoints()
  cur.directionDD:SetPoint("TOPLEFT", cur.stackYSlider, "BOTTOMLEFT", 0, -30)
  if cur.directionLbl then cur.directionLbl:ClearAllPoints(); cur.directionLbl:SetPoint("BOTTOMLEFT", cur.directionDD, "TOPLEFT", 0, 4) end
  cur.directionDD:SetOptions({{text = "Horizontal", value = "horizontal"}, {text = "Vertical", value = "vertical"}})
  cur.stackAnchorDD, cur.stackAnchorLbl = StyledDropdown(ct, "Stack Anchor", 170, -360, 120)
  cur.stackAnchorDD:ClearAllPoints()
  cur.stackAnchorDD:SetPoint("LEFT", cur.directionDD, "RIGHT", 15, 0)
  if cur.stackAnchorLbl then cur.stackAnchorLbl:ClearAllPoints(); cur.stackAnchorLbl:SetPoint("BOTTOMLEFT", cur.stackAnchorDD, "TOPLEFT", 0, 4) end
  cur.stackAnchorDD:SetOptions({
    {text = "TOPLEFT", value = "TOPLEFT"}, {text = "TOP", value = "TOP"}, {text = "TOPRIGHT", value = "TOPRIGHT"},
    {text = "LEFT", value = "LEFT"}, {text = "CENTER", value = "CENTER"}, {text = "RIGHT", value = "RIGHT"},
    {text = "BOTTOMLEFT", value = "BOTTOMLEFT"}, {text = "BOTTOM", value = "BOTTOM"}, {text = "BOTTOMRIGHT", value = "BOTTOMRIGHT"},
  })
  local curTrackedSec = Section(ct, "Tracked Spells / Items", -415)
  curTrackedSec:ClearAllPoints()
  curTrackedSec:SetPoint("TOPLEFT", cur.directionDD, "BOTTOMLEFT", 0, -26)
  cur.useGlowsCB = Checkbox(ct, "Use Glows", 15, -440)
  cur.useGlowsCB:ClearAllPoints()
  cur.useGlowsCB:SetPoint("TOPLEFT", curTrackedSec, "BOTTOMLEFT", 0, -12)
  cur.glowSpeedSlider = Slider(ct, "Glow Speed", 100, -440, 0.0, 4.0, 0.0, 0.1)
  cur.glowSpeedSlider:ClearAllPoints()
  cur.glowSpeedSlider:SetSize(100, 10)
  cur.glowSpeedSlider:GetThumbTexture():SetSize(10, 14)
  cur.glowSpeedSlider.Low:Hide()
  cur.glowSpeedSlider.High:Hide()
  cur.glowSpeedSlider.label:ClearAllPoints()
  cur.glowSpeedSlider.label:SetPoint("LEFT", cur.useGlowsCB.label, "RIGHT", 15, 0)
  cur.glowSpeedSlider:SetPoint("LEFT", cur.glowSpeedSlider.label, "RIGHT", 4, 0)
  cur.glowThicknessSlider = Slider(ct, "Glow Thickness", 370, -440, 0.1, 4.0, 1.0, 0.1)
  cur.glowThicknessSlider:ClearAllPoints()
  cur.glowThicknessSlider:SetPoint("LEFT", cur.glowSpeedSlider, "RIGHT", 250, 0)
  cur.glowThicknessSlider:SetSize(100, 10)
  cur.glowThicknessSlider:GetThumbTexture():SetSize(10, 14)
  cur.glowThicknessSlider.Low:Hide()
  cur.glowThicknessSlider.High:Hide()
  cur.glowThicknessSlider.label:ClearAllPoints()
  cur.glowThicknessSlider.label:SetPoint("RIGHT", cur.glowThicknessSlider, "LEFT", -4, 0)
  cur.customHideRevealCB = Checkbox(ct, "Custom Hide Reveal", 15, -470)
  cur.customHideRevealCB:ClearAllPoints()
  cur.customHideRevealCB:SetPoint("TOPLEFT", cur.useGlowsCB, "BOTTOMLEFT", 0, -8)
  cur.trackBuffsCB = Checkbox(ct, "Track Buffs", 410, -470)
  cur.trackBuffsCB:ClearAllPoints()
  cur.trackBuffsCB:SetPoint("LEFT", cur.customHideRevealCB.label, "RIGHT", 15, 0)
  cur.openBlizzBuffBtn = CreateStyledButton(ct, "Open Buff Tracker", 130, 20)
  cur.openBlizzBuffBtn:SetPoint("TOPRIGHT", ct, "TOPRIGHT", -15, -470)
  cur.openBlizzBuffBtn:ClearAllPoints()
  cur.openBlizzBuffBtn:SetPoint("LEFT", cur.trackBuffsCB.label, "RIGHT", 15, 0)
  cur.openBlizzBuffBtn:SetScript("OnClick", function()
    local cfg = addonTable.ConfigFrame
    if cfg then
      cfg:ClearAllPoints()
      cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    if not CooldownViewerSettings then return end
    CooldownViewerSettings:Show()
    C_Timer.After(0.1, function()
      local tab = CooldownViewerSettings and CooldownViewerSettings.AurasTab
      if not tab then return end
      local onMouseUp = tab:GetScript("OnMouseUp")
      if onMouseUp then
        onMouseUp(tab, "LeftButton", true)
      end
    end)
  end)
  cur.spellBg = CreateFrame("Frame", nil, ct, "BackdropTemplate")
  cur.spellBg:SetPoint("TOPLEFT", cur.customHideRevealCB, "BOTTOMLEFT", 0, -8)
  cur.spellBg:SetPoint("RIGHT", ct, "RIGHT", -15, 0)
  cur.spellBg:SetHeight(250)
  cur.spellBg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cur.spellBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
  cur.spellBg:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
  cur.spellScroll = CreateFrame("ScrollFrame", "CCMCursorSpellScroll", cur.spellBg, "UIPanelScrollFrameTemplate")
  cur.spellScroll:SetPoint("TOPLEFT", 4, -4)
  cur.spellScroll:SetPoint("TOPRIGHT", -26, -4)
  cur.spellScroll:SetPoint("BOTTOM", 0, 4)
  cur.spellChild = CreateFrame("Frame", nil, cur.spellScroll)
  cur.spellChild:SetSize(1, 1)
  cur.spellScroll:SetScrollChild(cur.spellChild)
  local function SyncCursorSpellChildWidth()
    local w = cur.spellScroll and cur.spellScroll:GetWidth() or 0
    if w and w > 1 then
      cur.spellChild:SetWidth(w)
    end
  end
  cur.spellScroll:HookScript("OnSizeChanged", SyncCursorSpellChildWidth)
  C_Timer.After(0, SyncCursorSpellChildWidth)
  local cursorSpellScrollBar = _G["CCMCursorSpellScrollScrollBar"]
  if cursorSpellScrollBar then
    cursorSpellScrollBar:SetPoint("TOPLEFT", cur.spellScroll, "TOPRIGHT", 6, -16)
    cursorSpellScrollBar:SetPoint("BOTTOMLEFT", cur.spellScroll, "BOTTOMRIGHT", 6, 16)
    local thumb = cursorSpellScrollBar:GetThumbTexture()
    if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
    local up = _G["CCMCursorSpellScrollScrollBarScrollUpButton"]
    local down = _G["CCMCursorSpellScrollScrollBarScrollDownButton"]
    if up then up:SetAlpha(0); up:EnableMouse(false) end
    if down then down:SetAlpha(0); down:EnableMouse(false) end
  end
  cur.addLbl = ct:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cur.addLbl:SetPoint("TOPLEFT", cur.spellBg, "BOTTOMLEFT", 0, -10)
  cur.addLbl:SetText("Spell/Item ID:")
  cur.addLbl:SetTextColor(0.9, 0.9, 0.9)
  cur.addBox = CreateFrame("EditBox", nil, ct, "BackdropTemplate")
  cur.addBox:SetSize(80, 24)
  cur.addBox:SetPoint("LEFT", cur.addLbl, "RIGHT", 8, 0)
  cur.addBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cur.addBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
  cur.addBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  cur.addBox:SetFontObject("GameFontHighlight")
  cur.addBox:SetAutoFocus(false)
  cur.addBox:SetTextInsets(6, 6, 0, 0)
  cur.addBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
  cur.addSpellBtn = CreateStyledButton(ct, "Add Spell", 70, 24)
  cur.addSpellBtn:SetPoint("LEFT", cur.addBox, "RIGHT", 8, 0)
  cur.addItemBtn = CreateStyledButton(ct, "Add Item", 70, 24)
  cur.addItemBtn:SetPoint("LEFT", cur.addSpellBtn, "RIGHT", 5, 0)
  cur.addSep = ct:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cur.addSep:SetPoint("LEFT", cur.addItemBtn, "RIGHT", 6, 0)
  cur.addSep:SetText("|")
  cur.addSep:SetTextColor(0.4, 0.4, 0.45, 1)
  cur.addTrinketsBtn = CreateStyledButton(ct, "Add Trinkets", 90, 24)
  cur.addTrinketsBtn:SetPoint("LEFT", cur.addSep, "RIGHT", 6, 0)
  cur.addRacialBtn = CreateStyledButton(ct, "Add Racial", 80, 24)
  cur.addRacialBtn:SetPoint("LEFT", cur.addTrinketsBtn, "RIGHT", 5, 0)
  cur.addPotionBtn = CreateStyledButton(ct, "Add Potion", 80, 24)
  cur.addPotionBtn:SetPoint("LEFT", cur.addRacialBtn, "RIGHT", 5, 0)
  cur.addGCSBtn = CreateStyledButton(ct, "Add GCS", 65, 24)
  cur.addGCSBtn:SetPoint("LEFT", cur.addPotionBtn, "RIGHT", 5, 0)
  cur.dragDropHint = ct:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cur.dragDropHint:SetPoint("TOPLEFT", cur.addLbl, "BOTTOMLEFT", 0, -8)
  cur.dragDropHint:SetText("Tip: Drag & drop spells/items directly into this window!")
  cur.dragDropHint:SetTextColor(0.5, 0.5, 0.5)
  local function CreateCustomBarTab(tabFrame, barNum, yOffset)
    local cb = {}
    local cbOuterSF = CreateFrame("ScrollFrame", "CCMCBTabSF" .. barNum, tabFrame, "UIPanelScrollFrameTemplate")
    cbOuterSF:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, 0)
    cbOuterSF:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -22, 0)
    local cbOuterSC = CreateFrame("Frame", "CCMCBTabSC" .. barNum, cbOuterSF)
    cbOuterSC:SetSize(490, 900)
    cbOuterSF:SetScrollChild(cbOuterSC)
    local cbOuterBar = _G["CCMCBTabSF" .. barNum .. "ScrollBar"]
    if cbOuterBar then
      cbOuterBar:SetPoint("TOPLEFT", cbOuterSF, "TOPRIGHT", 6, -16)
      cbOuterBar:SetPoint("BOTTOMLEFT", cbOuterSF, "BOTTOMRIGHT", 6, 16)
      local cbOThumb = cbOuterBar:GetThumbTexture()
      if cbOThumb then cbOThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); cbOThumb:SetSize(8, 40) end
      local cbOUp = _G["CCMCBTabSF" .. barNum .. "ScrollBarScrollUpButton"]
      local cbODown = _G["CCMCBTabSF" .. barNum .. "ScrollBarScrollDownButton"]
      if cbOUp then cbOUp:SetAlpha(0); cbOUp:EnableMouse(false) end
      if cbODown then cbODown:SetAlpha(0); cbODown:EnableMouse(false) end
    end
    SetSmoothScroll(cbOuterSF)
    local function SyncCBTabWidth()
      local w = cbOuterSF:GetWidth()
      if w and w > 1 then cbOuterSC:SetWidth(w) end
    end
    cbOuterSF:HookScript("OnSizeChanged", SyncCBTabWidth)
    C_Timer.After(0, SyncCBTabWidth)
    local tf = cbOuterSC
    local cbHighlightBtn = CreateHighlightToggle(tf)
    local cbSettingsSec = Section(tf, "Custom Bar " .. barNum .. " Settings", -12)
    cb.combatOnlyCB = Checkbox(tf, "Combat Only", 15, -40)
    cb.combatOnlyCB:ClearAllPoints()
    cb.combatOnlyCB:SetPoint("TOPLEFT", cbSettingsSec, "BOTTOMLEFT", 0, -14)
    cb.gcdCB = Checkbox(tf, "Show GCD", 120, -40)
    cb.gcdCB:ClearAllPoints()
    cb.gcdCB:SetPoint("LEFT", cb.combatOnlyCB.label, "RIGHT", 15, 0)
    cb.centeredCB = Checkbox(tf, "Centered", 220, -40)
    cb.centeredCB:ClearAllPoints()
    cb.centeredCB:SetPoint("LEFT", cb.gcdCB.label, "RIGHT", 15, 0)
    cb.cdModeDD, cb.cdModeLbl = StyledDropdown(tf, "On Cooldown", 350, -32, 110)
    cb.cdModeDD:ClearAllPoints()
    cb.cdModeDD:SetPoint("LEFT", cb.centeredCB.label, "RIGHT", 15, 0)
    if cb.cdModeLbl then cb.cdModeLbl:ClearAllPoints(); cb.cdModeLbl:SetPoint("BOTTOMLEFT", cb.cdModeDD, "TOPLEFT", 0, 4) end
    cb.cdModeDD:SetOptions({{text = "Show", value = "show"}, {text = "Hide", value = "hide"}, {text = "Desaturate", value = "desaturate"}, {text = "Hide Available", value = "hideAvailable"}})
    cb.showModeDD, cb.showModeLbl = StyledDropdown(tf, "Show only", 500, -32, 140)
    cb.showModeDD:ClearAllPoints()
    cb.showModeDD:SetPoint("LEFT", cb.cdModeDD, "RIGHT", 15, 0)
    if cb.showModeLbl then cb.showModeLbl:ClearAllPoints(); cb.showModeLbl:SetPoint("BOTTOMLEFT", cb.showModeDD, "TOPLEFT", 0, 4) end
    cb.showModeDD:SetOptions({{text = "Always", value = "always"}, {text = "Raid", value = "raid"}, {text = "Dungeon", value = "dungeon"}, {text = "Dungeon & Raid", value = "raidanddungeon"}})
    cbHighlightBtn:ClearAllPoints()
    cbHighlightBtn:SetPoint("LEFT", cb.showModeDD, "RIGHT", 10, 0)
    cb.iconSizeSlider = Slider(tf, "Icon Size", 15, -80, 10, 80, 30, 1)
    cb.iconSizeSlider.label:ClearAllPoints()
    cb.iconSizeSlider.label:SetPoint("TOPLEFT", cbSettingsSec, "BOTTOMLEFT", 0, -55)
    cb.iconSizeSlider:ClearAllPoints()
    cb.iconSizeSlider:SetPoint("TOPLEFT", cb.iconSizeSlider.label, "BOTTOMLEFT", 0, -8)
    cb.spacingSlider = Slider(tf, "Spacing", 280, -80, -3, 10, 2, 1)
    cb.spacingSlider.label:ClearAllPoints()
    cb.spacingSlider.label:SetPoint("TOPLEFT", cbSettingsSec, "BOTTOMLEFT", 265, -55)
    cb.spacingSlider:ClearAllPoints()
    cb.spacingSlider:SetPoint("TOPLEFT", cb.spacingSlider.label, "BOTTOMLEFT", 0, -8)
    cb.xSlider = Slider(tf, "Bar X Offset", 15, -135, -1000, 1000, 0, 1)
    cb.xSlider.label:ClearAllPoints()
    cb.xSlider.label:SetPoint("TOPLEFT", cb.iconSizeSlider, "BOTTOMLEFT", 0, -25)
    cb.xSlider:ClearAllPoints()
    cb.xSlider:SetPoint("TOPLEFT", cb.xSlider.label, "BOTTOMLEFT", 0, -8)
    cb.ySlider = Slider(tf, "Bar Y Offset", 280, -135, -1000, 1000, yOffset, 1)
    cb.ySlider.label:ClearAllPoints()
    cb.ySlider.label:SetPoint("TOPLEFT", cb.spacingSlider, "BOTTOMLEFT", 0, -25)
    cb.ySlider:ClearAllPoints()
    cb.ySlider:SetPoint("TOPLEFT", cb.ySlider.label, "BOTTOMLEFT", 0, -8)
    cb.cdTextSlider = Slider(tf, "CD Text Scale", 15, -190, 0, 2.0, 1.0, 0.1)
    cb.cdTextSlider.label:ClearAllPoints()
    cb.cdTextSlider.label:SetPoint("TOPLEFT", cb.xSlider, "BOTTOMLEFT", 0, -25)
    cb.cdTextSlider:ClearAllPoints()
    cb.cdTextSlider:SetPoint("TOPLEFT", cb.cdTextSlider.label, "BOTTOMLEFT", 0, -8)
    cb.cdGradientSlider = Slider(tf, "CD Gradient (sec)", 280, -190, 0, 30, 0, 1)
    cb.cdGradientSlider.label:ClearAllPoints()
    cb.cdGradientSlider.label:SetPoint("TOPLEFT", cb.ySlider, "BOTTOMLEFT", 0, -25)
    cb.cdGradientSlider:ClearAllPoints()
    cb.cdGradientSlider:SetPoint("TOPLEFT", cb.cdGradientSlider.label, "BOTTOMLEFT", 0, -8)
    cb.cdGradientColorSwatch = CreateFrame("Frame", nil, tf, "BackdropTemplate")
    cb.cdGradientColorSwatch:SetSize(20, 20)
    cb.cdGradientColorSwatch:SetPoint("LEFT", cb.cdGradientSlider.valueTextBg, "RIGHT", 26, 0)
    cb.cdGradientColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    cb.cdGradientColorSwatch:SetBackdropColor(1, 0, 0, 1)
    cb.cdGradientColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    cb.cdGradientColorSwatch:EnableMouse(true)
    cb.stackTextSlider = Slider(tf, "Stack Text Scale", 15, -245, 0.5, 2.0, 1.0, 0.1)
    cb.stackTextSlider.label:ClearAllPoints()
    cb.stackTextSlider.label:SetPoint("TOPLEFT", cb.cdTextSlider, "BOTTOMLEFT", 0, -25)
    cb.stackTextSlider:ClearAllPoints()
    cb.stackTextSlider:SetPoint("TOPLEFT", cb.stackTextSlider.label, "BOTTOMLEFT", 0, -8)
    cb.stackXSlider = Slider(tf, "Stack Offset X", 280, -245, -20, 20, 0, 1)
    cb.stackXSlider.label:ClearAllPoints()
    cb.stackXSlider.label:SetPoint("TOPLEFT", cb.cdGradientSlider, "BOTTOMLEFT", 0, -25)
    cb.stackXSlider:ClearAllPoints()
    cb.stackXSlider:SetPoint("TOPLEFT", cb.stackXSlider.label, "BOTTOMLEFT", 0, -8)
    cb.stackYSlider = Slider(tf, "Stack Offset Y", 15, -300, -20, 20, 0, 1)
    cb.stackYSlider.label:ClearAllPoints()
    cb.stackYSlider.label:SetPoint("TOPLEFT", cb.stackTextSlider, "BOTTOMLEFT", 0, -25)
    cb.stackYSlider:ClearAllPoints()
    cb.stackYSlider:SetPoint("TOPLEFT", cb.stackYSlider.label, "BOTTOMLEFT", 0, -8)
    cb.iconsPerRowSlider = Slider(tf, "Icons Per Row", 280, -300, 1, 20, 20, 1)
    cb.iconsPerRowSlider.label:ClearAllPoints()
    cb.iconsPerRowSlider.label:SetPoint("TOPLEFT", cb.stackXSlider, "BOTTOMLEFT", 0, -25)
    cb.iconsPerRowSlider:ClearAllPoints()
    cb.iconsPerRowSlider:SetPoint("TOPLEFT", cb.iconsPerRowSlider.label, "BOTTOMLEFT", 0, -8)
    cb.directionDD, cb.directionLbl = StyledDropdown(tf, "Direction", 15, -360, 100)
    cb.directionDD:ClearAllPoints()
    cb.directionDD:SetPoint("TOPLEFT", cb.stackYSlider, "BOTTOMLEFT", 0, -30)
    if cb.directionLbl then cb.directionLbl:ClearAllPoints(); cb.directionLbl:SetPoint("BOTTOMLEFT", cb.directionDD, "TOPLEFT", 0, 4) end
    cb.directionDD:SetOptions({{text = "Horizontal", value = "horizontal"}, {text = "Vertical", value = "vertical"}})
    cb.anchorDD, cb.anchorLbl = StyledDropdown(tf, "Anchor", 150, -360, 80)
    cb.anchorDD:ClearAllPoints()
    cb.anchorDD:SetPoint("LEFT", cb.directionDD, "RIGHT", 15, 0)
    if cb.anchorLbl then cb.anchorLbl:ClearAllPoints(); cb.anchorLbl:SetPoint("BOTTOMLEFT", cb.anchorDD, "TOPLEFT", 0, 4) end
    cb.anchorDD:SetOptions({{text = "Left", value = "LEFT"}, {text = "Right", value = "RIGHT"}})
    cb.growthDD, cb.growthLbl = StyledDropdown(tf, "Growth", 265, -360, 80)
    cb.growthDD:ClearAllPoints()
    cb.growthDD:SetPoint("LEFT", cb.anchorDD, "RIGHT", 15, 0)
    if cb.growthLbl then cb.growthLbl:ClearAllPoints(); cb.growthLbl:SetPoint("BOTTOMLEFT", cb.growthDD, "TOPLEFT", 0, 4) end
    cb.growthDD:SetOptions({{text = "Up", value = "UP"}, {text = "Down", value = "DOWN"}})
    cb.stackAnchorDD, cb.stackAnchorLbl = StyledDropdown(tf, "Stack Anchor", 380, -360, 110)
    cb.stackAnchorDD:ClearAllPoints()
    cb.stackAnchorDD:SetPoint("LEFT", cb.growthDD, "RIGHT", 15, 0)
    if cb.stackAnchorLbl then cb.stackAnchorLbl:ClearAllPoints(); cb.stackAnchorLbl:SetPoint("BOTTOMLEFT", cb.stackAnchorDD, "TOPLEFT", 0, 4) end
    cb.stackAnchorDD:SetOptions({
      {text = "TOPLEFT", value = "TOPLEFT"}, {text = "TOP", value = "TOP"}, {text = "TOPRIGHT", value = "TOPRIGHT"},
      {text = "LEFT", value = "LEFT"}, {text = "CENTER", value = "CENTER"}, {text = "RIGHT", value = "RIGHT"},
      {text = "BOTTOMLEFT", value = "BOTTOMLEFT"}, {text = "BOTTOM", value = "BOTTOM"}, {text = "BOTTOMRIGHT", value = "BOTTOMRIGHT"},
    })
    cb.anchorTargetDD, cb.anchorTargetLbl = StyledDropdown(tf, "Anchor to", 510, -360, 120)
    cb.anchorTargetDD:ClearAllPoints()
    cb.anchorTargetDD:SetPoint("LEFT", cb.stackAnchorDD, "RIGHT", 15, 0)
    if cb.anchorTargetLbl then cb.anchorTargetLbl:ClearAllPoints(); cb.anchorTargetLbl:SetPoint("BOTTOMLEFT", cb.anchorTargetDD, "TOPLEFT", 0, 4) end
    cb.anchorToPointDD, cb.anchorToPointLbl = StyledDropdown(tf, "Point", 510, -400, 120)
    cb.anchorToPointDD:ClearAllPoints()
    cb.anchorToPointDD:SetPoint("TOPLEFT", cb.directionDD, "BOTTOMLEFT", 0, -15)
    if cb.anchorToPointLbl then cb.anchorToPointLbl:ClearAllPoints(); cb.anchorToPointLbl:SetPoint("BOTTOMLEFT", cb.anchorToPointDD, "TOPLEFT", 0, 4) end
    cb.anchorToPointDD:SetOptions({
      {text = "TOPLEFT", value = "TOPLEFT"}, {text = "TOP", value = "TOP"}, {text = "TOPRIGHT", value = "TOPRIGHT"},
      {text = "LEFT", value = "LEFT"}, {text = "CENTER", value = "CENTER"}, {text = "RIGHT", value = "RIGHT"},
      {text = "BOTTOMLEFT", value = "BOTTOMLEFT"}, {text = "BOTTOM", value = "BOTTOM"}, {text = "BOTTOMRIGHT", value = "BOTTOMRIGHT"},
    })
    local cbTrackedSec = Section(tf, "Tracked Spells / Items", -450)
    cbTrackedSec:ClearAllPoints()
    cbTrackedSec:SetPoint("TOPLEFT", cb.anchorToPointDD, "BOTTOMLEFT", 0, -24)
    cb.useGlowsCB = Checkbox(tf, "Use Glows", 15, -475)
    cb.useGlowsCB:ClearAllPoints()
    cb.useGlowsCB:SetPoint("TOPLEFT", cbTrackedSec, "BOTTOMLEFT", 0, -12)
    cb.glowSpeedSlider = Slider(tf, "Glow Speed", 100, -475, 0.0, 4.0, 0.0, 0.1)
    cb.glowSpeedSlider:ClearAllPoints()
    cb.glowSpeedSlider:SetSize(100, 10)
    cb.glowSpeedSlider:GetThumbTexture():SetSize(10, 14)
    cb.glowSpeedSlider.Low:Hide()
    cb.glowSpeedSlider.High:Hide()
    cb.glowSpeedSlider.label:ClearAllPoints()
    cb.glowSpeedSlider.label:SetPoint("LEFT", cb.useGlowsCB.label, "RIGHT", 15, 0)
    cb.glowSpeedSlider:SetPoint("LEFT", cb.glowSpeedSlider.label, "RIGHT", 4, 0)
    cb.glowThicknessSlider = Slider(tf, "Glow Thickness", 370, -475, 0.1, 4.0, 1.0, 0.1)
    cb.glowThicknessSlider:ClearAllPoints()
    cb.glowThicknessSlider:SetPoint("LEFT", cb.glowSpeedSlider, "RIGHT", 250, 0)
    cb.glowThicknessSlider:SetSize(100, 10)
    cb.glowThicknessSlider:GetThumbTexture():SetSize(10, 14)
    cb.glowThicknessSlider.Low:Hide()
    cb.glowThicknessSlider.High:Hide()
    cb.glowThicknessSlider.label:ClearAllPoints()
    cb.glowThicknessSlider.label:SetPoint("RIGHT", cb.glowThicknessSlider, "LEFT", -4, 0)
    cb.customHideRevealCB = Checkbox(tf, "Custom Hide Reveal", 15, -505)
    cb.customHideRevealCB:ClearAllPoints()
    cb.customHideRevealCB:SetPoint("TOPLEFT", cb.useGlowsCB, "BOTTOMLEFT", 0, -8)
    cb.trackBuffsCB = Checkbox(tf, "Track Buffs", 410, -505)
    cb.trackBuffsCB:ClearAllPoints()
    cb.trackBuffsCB:SetPoint("LEFT", cb.customHideRevealCB.label, "RIGHT", 15, 0)
    cb.openBlizzBuffBtn = CreateStyledButton(tf, "Open Buff Tracker", 130, 20)
    cb.openBlizzBuffBtn:ClearAllPoints()
    cb.openBlizzBuffBtn:SetPoint("LEFT", cb.trackBuffsCB.label, "RIGHT", 15, 0)
    cb.openBlizzBuffBtn:SetScript("OnClick", function()
      local cfg = addonTable.ConfigFrame
      if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      end
      if not CooldownViewerSettings then return end
      CooldownViewerSettings:Show()
      C_Timer.After(0.1, function()
        local tab = CooldownViewerSettings and CooldownViewerSettings.AurasTab
        if not tab then return end
        local onMouseUp = tab:GetScript("OnMouseUp")
        if onMouseUp then
          onMouseUp(tab, "LeftButton", true)
        end
      end)
    end)
    cb.spellBg = CreateFrame("Frame", nil, tf, "BackdropTemplate")
    cb.spellBg:SetPoint("TOPLEFT", cb.customHideRevealCB, "BOTTOMLEFT", 0, -8)
    cb.spellBg:SetPoint("RIGHT", tf, "RIGHT", -15, 0)
    cb.spellBg:SetHeight(275)
    cb.spellBg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    cb.spellBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
    cb.spellBg:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    cb.spellScroll = CreateFrame("ScrollFrame", "CCMCustomBar" .. barNum .. "Scroll", cb.spellBg, "UIPanelScrollFrameTemplate")
    cb.spellScroll:SetPoint("TOPLEFT", 4, -4)
    cb.spellScroll:SetPoint("TOPRIGHT", -26, -4)
    cb.spellScroll:SetPoint("BOTTOM", 0, 4)
    cb.spellChild = CreateFrame("Frame", nil, cb.spellScroll)
    cb.spellChild:SetSize(1, 1)
    cb.spellScroll:SetScrollChild(cb.spellChild)
    local function SyncCustomSpellChildWidth()
      local w = cb.spellScroll and cb.spellScroll:GetWidth() or 0
      if w and w > 1 then
        cb.spellChild:SetWidth(w)
      end
    end
    cb.spellScroll:HookScript("OnSizeChanged", SyncCustomSpellChildWidth)
    C_Timer.After(0, SyncCustomSpellChildWidth)
    local cbScrollBar = _G["CCMCustomBar" .. barNum .. "ScrollScrollBar"]
    if cbScrollBar then
      cbScrollBar:SetPoint("TOPLEFT", cb.spellScroll, "TOPRIGHT", 6, -16)
      cbScrollBar:SetPoint("BOTTOMLEFT", cb.spellScroll, "BOTTOMRIGHT", 6, 16)
      local thumb = cbScrollBar:GetThumbTexture()
      if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
      local up = _G["CCMCustomBar" .. barNum .. "ScrollScrollBarScrollUpButton"]
      local down = _G["CCMCustomBar" .. barNum .. "ScrollScrollBarScrollDownButton"]
      if up then up:SetAlpha(0); up:EnableMouse(false) end
      if down then down:SetAlpha(0); down:EnableMouse(false) end
    end
    cb.addLbl = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.addLbl:SetPoint("TOPLEFT", cb.spellBg, "BOTTOMLEFT", 0, -10)
    cb.addLbl:SetText("Spell/Item ID:")
    cb.addLbl:SetTextColor(0.9, 0.9, 0.9)
    cb.addBox = CreateFrame("EditBox", nil, tf, "BackdropTemplate")
    cb.addBox:SetSize(80, 24)
    cb.addBox:SetPoint("LEFT", cb.addLbl, "RIGHT", 8, 0)
    cb.addBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    cb.addBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
    cb.addBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    cb.addBox:SetFontObject("GameFontHighlight")
    cb.addBox:SetAutoFocus(false)
    cb.addBox:SetTextInsets(6, 6, 0, 0)
    cb.addBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    cb.addSpellBtn = CreateStyledButton(tf, "Add Spell", 70, 24)
    cb.addSpellBtn:SetPoint("LEFT", cb.addBox, "RIGHT", 8, 0)
    cb.addItemBtn = CreateStyledButton(tf, "Add Item", 70, 24)
    cb.addItemBtn:SetPoint("LEFT", cb.addSpellBtn, "RIGHT", 5, 0)
    cb.addSep = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.addSep:SetPoint("LEFT", cb.addItemBtn, "RIGHT", 6, 0)
    cb.addSep:SetText("|")
    cb.addSep:SetTextColor(0.4, 0.4, 0.45, 1)
    cb.addTrinketsBtn = CreateStyledButton(tf, "Add Trinkets", 90, 24)
    cb.addTrinketsBtn:SetPoint("LEFT", cb.addSep, "RIGHT", 6, 0)
    cb.addRacialBtn = CreateStyledButton(tf, "Add Racial", 80, 24)
    cb.addRacialBtn:SetPoint("LEFT", cb.addTrinketsBtn, "RIGHT", 5, 0)
    cb.addPotionBtn = CreateStyledButton(tf, "Add Potion", 80, 24)
    cb.addPotionBtn:SetPoint("LEFT", cb.addRacialBtn, "RIGHT", 5, 0)
    cb.addGCSBtn = CreateStyledButton(tf, "Add GCS", 65, 24)
    cb.addGCSBtn:SetPoint("LEFT", cb.addPotionBtn, "RIGHT", 5, 0)
    cb.dragDropHint = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.dragDropHint:SetPoint("TOPLEFT", cb.addLbl, "BOTTOMLEFT", 0, -8)
    cb.dragDropHint:SetText("Tip: Drag & drop spells/items directly into this window!")
    cb.dragDropHint:SetTextColor(0.5, 0.5, 0.5)
    return cb
  end
  addonTable.cb1 = CreateCustomBarTab(tabFrames[3], 1, -200)
  addonTable.cb2 = CreateCustomBarTab(tabFrames[4], 2, -250)
  addonTable.cb3 = CreateCustomBarTab(tabFrames[5], 3, -300)
  addonTable.cb4 = CreateCustomBarTab(tabFrames[20], 4, -350)
  addonTable.cb5 = CreateCustomBarTab(tabFrames[21], 5, -400)
  local tab6 = tabFrames[6]
  local blizzScrollFrame = CreateFrame("ScrollFrame", "CCMBlizzCDMScrollFrame", tab6, "UIPanelScrollFrameTemplate")
  blizzScrollFrame:SetPoint("TOPLEFT", tab6, "TOPLEFT", 0, 0)
  blizzScrollFrame:SetPoint("BOTTOMRIGHT", tab6, "BOTTOMRIGHT", -22, 0)
  local blizzScrollChild = CreateFrame("Frame", "CCMBlizzCDMScrollChild", blizzScrollFrame)
  blizzScrollChild:SetSize(490, 1200)
  blizzScrollFrame:SetScrollChild(blizzScrollChild)
  local blizzBar = _G["CCMBlizzCDMScrollFrameScrollBar"]
  if blizzBar then
    blizzBar:SetPoint("TOPLEFT", blizzScrollFrame, "TOPRIGHT", 6, -16)
    blizzBar:SetPoint("BOTTOMLEFT", blizzScrollFrame, "BOTTOMRIGHT", 6, 16)
    local thumb = blizzBar:GetThumbTexture()
    if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
    local up = _G["CCMBlizzCDMScrollFrameScrollBarScrollUpButton"]
    local down = _G["CCMBlizzCDMScrollFrameScrollBarScrollDownButton"]
    if up then up:SetAlpha(0); up:EnableMouse(false) end
    if down then down:SetAlpha(0); down:EnableMouse(false) end
  end
  SetSmoothScroll(blizzScrollFrame)
  local b6 = blizzScrollChild
  local infoTxt = b6:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  infoTxt:SetPoint("TOPLEFT", b6, "TOPLEFT", 15, -15)
  infoTxt:SetWidth(480)
  infoTxt:SetJustifyH("LEFT")
  infoTxt:SetSpacing(2)
  infoTxt:SetText("|cffff6666Important:|r Disable all other cooldown manager addons when using this tab!\nWhen attaching bars to cursor, set Icon Size to |cffff0000100%|r in Edit Mode!\nEssential Bar must be |cffff0000Always Visible|r in Edit Mode when attached to cursor!")
  infoTxt:SetTextColor(0.9, 0.9, 0.9)
  local b6SkinSec = Section(b6, "Skinning Mode", -125)
  addonTable.skinningModeDD = StyledDropdown(b6, nil, 15, -150, 150)
  addonTable.skinningModeDD:ClearAllPoints()
  addonTable.skinningModeDD:SetPoint("TOPLEFT", b6SkinSec, "BOTTOMLEFT", 0, -12)
  addonTable.skinningModeDD:SetOptions({
    {text = "None", value = "none"},
    {text = "CCM Built-in", value = "ccm"},
    {text = "Masque", value = "masque"},
  })
  addonTable.openBlizzCDMBtn = CreateStyledButton(b6, "Open Blizzard CDM", 145, 22)
  addonTable.openBlizzCDMBtn:SetPoint("LEFT", addonTable.skinningModeDD, "RIGHT", 15, 0)
  addonTable.openEditModeBtn = CreateStyledButton(b6, "Open Edit Mode", 145, 22)
  addonTable.openEditModeBtn:SetPoint("LEFT", addonTable.openBlizzCDMBtn, "RIGHT", 6, 0)
  local b6AttachSec = Section(b6, "Attach to Cursor", -195)
  addonTable.buffBarCB = Checkbox(b6, "Attach Buff Bar", 15, -220)
  addonTable.buffBarCB:ClearAllPoints()
  addonTable.buffBarCB:SetPoint("TOPLEFT", b6AttachSec, "BOTTOMLEFT", 0, -12)
  addonTable.essentialBarCB = Checkbox(b6, "Attach Essential Bar", 15, -250)
  addonTable.essentialBarCB:ClearAllPoints()
  addonTable.essentialBarCB:SetPoint("TOPLEFT", addonTable.buffBarCB, "BOTTOMLEFT", 0, -8)
  local attachNote = b6:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  attachNote:SetPoint("TOPLEFT", addonTable.essentialBarCB, "BOTTOMLEFT", 0, -6)
  attachNote:SetText("|cff888888Note: Icon settings under Cursor CDM if Bars attached.|r")
  addonTable.buffSizeSlider = Slider(b6, "Buff Bar Size Offset", 280, -213, -20, 20, 0, 1)
  addonTable.buffSizeSlider.label:ClearAllPoints()
  addonTable.buffSizeSlider.label:SetPoint("TOPLEFT", b6AttachSec, "BOTTOMLEFT", 265, -5)
  addonTable.buffSizeSlider:ClearAllPoints()
  addonTable.buffSizeSlider:SetPoint("TOPLEFT", addonTable.buffSizeSlider.label, "BOTTOMLEFT", 0, -8)
  local b6StandaloneSec = Section(b6, "Standalone Blizzard Bars", -305)
  addonTable.standalone = {}
  local sa = addonTable.standalone
  sa.skinBuffCB = Checkbox(b6, "Skin Buff Bar", 15, -330)
  sa.skinBuffCB:ClearAllPoints()
  sa.skinBuffCB:SetPoint("TOPLEFT", b6StandaloneSec, "BOTTOMLEFT", 0, -12)
  sa.skinEssentialCB = Checkbox(b6, "Skin Essential Bar", 200, -330)
  sa.skinEssentialCB:ClearAllPoints()
  sa.skinEssentialCB:SetPoint("LEFT", sa.skinBuffCB.label, "RIGHT", 15, 0)
  sa.skinUtilityCB = Checkbox(b6, "Skin Utility Bar", 385, -330)
  sa.skinUtilityCB:ClearAllPoints()
  sa.skinUtilityCB:SetPoint("LEFT", sa.skinEssentialCB.label, "RIGHT", 15, 0)
  sa.buffCenteredCB = Checkbox(b6, "Center Buff", 15, -360)
  sa.buffCenteredCB:ClearAllPoints()
  sa.buffCenteredCB:SetPoint("TOPLEFT", sa.skinBuffCB, "BOTTOMLEFT", 0, -8)
  sa.essentialCenteredCB = Checkbox(b6, "Center Essential", 200, -360)
  sa.essentialCenteredCB:ClearAllPoints()
  sa.essentialCenteredCB:SetPoint("TOPLEFT", sa.skinEssentialCB, "BOTTOMLEFT", 0, -8)
  sa.utilityCenteredCB = Checkbox(b6, "Center Utility", 385, -360)
  sa.utilityCenteredCB:ClearAllPoints()
  sa.utilityCenteredCB:SetPoint("TOPLEFT", sa.skinUtilityCB, "BOTTOMLEFT", 0, -8)
  local b6HighlightBtn = CreateHighlightToggle(b6)
  b6HighlightBtn:ClearAllPoints()
  b6HighlightBtn:SetPoint("LEFT", sa.utilityCenteredCB.label, "RIGHT", 15, 0)
  sa.hideGlowsCB = Checkbox(b6, "Hide Glows", 15, -390)
  sa.hideGlowsCB:ClearAllPoints()
  sa.hideGlowsCB:SetPoint("TOPLEFT", sa.buffCenteredCB, "BOTTOMLEFT", 0, -8)
  sa.spacingSlider = Slider(b6, "Spacing", 15, -410, -3, 10, 0, 1)
  sa.spacingSlider.label:ClearAllPoints()
  sa.spacingSlider.label:SetPoint("TOPLEFT", sa.hideGlowsCB, "BOTTOMLEFT", 0, -20)
  sa.spacingSlider:ClearAllPoints()
  sa.spacingSlider:SetPoint("TOPLEFT", sa.spacingSlider.label, "BOTTOMLEFT", 0, -8)
  sa.borderSizeSlider = Slider(b6, "Border Size", 280, -410, 0, 5, 1, 1)
  sa.borderSizeSlider.label:ClearAllPoints()
  sa.borderSizeSlider.label:SetPoint("TOPLEFT", sa.spacingSlider.label, "TOPLEFT", 265, 0)
  sa.borderSizeSlider:ClearAllPoints()
  sa.borderSizeSlider:SetPoint("TOPLEFT", sa.borderSizeSlider.label, "BOTTOMLEFT", 0, -8)
  sa.cdTextScaleSlider = Slider(b6, "CD Text Scale", 280, -465, 0, 2.0, 1.0, 0.1)
  sa.cdTextScaleSlider.label:ClearAllPoints()
  sa.cdTextScaleSlider.label:SetPoint("TOPLEFT", sa.borderSizeSlider, "BOTTOMLEFT", 0, -25)
  sa.cdTextScaleSlider:ClearAllPoints()
  sa.cdTextScaleSlider:SetPoint("TOPLEFT", sa.cdTextScaleSlider.label, "BOTTOMLEFT", 0, -8)
  local b6BuffSec = Section(b6, "Buff Bar Settings", -520)
  sa.buffRowsDD, sa.buffRowsLbl = StyledDropdown(b6, "Buff Rows", 15, -550, 120)
  sa.buffRowsDD:ClearAllPoints()
  sa.buffRowsDD:SetPoint("TOPLEFT", b6BuffSec, "BOTTOMLEFT", 0, -15)
  if sa.buffRowsLbl then sa.buffRowsLbl:ClearAllPoints(); sa.buffRowsLbl:SetPoint("BOTTOMLEFT", sa.buffRowsDD, "TOPLEFT", 0, 4) end
  sa.buffRowsDD:SetOptions({{text = "1 Row", value = "1"}, {text = "2 Rows", value = "2"}})
  sa.buffGrowDD, sa.buffGrowLbl = StyledDropdown(b6, "Buff Grow", 150, -550, 120)
  sa.buffGrowDD:ClearAllPoints()
  sa.buffGrowDD:SetPoint("LEFT", sa.buffRowsDD, "RIGHT", 15, 0)
  if sa.buffGrowLbl then sa.buffGrowLbl:ClearAllPoints(); sa.buffGrowLbl:SetPoint("BOTTOMLEFT", sa.buffGrowDD, "TOPLEFT", 0, 4) end
  sa.buffGrowDD:SetOptions({{text = "Right", value = "right"}, {text = "Left", value = "left"}})
  sa.buffRowGrowDD, sa.buffRowGrowLbl = StyledDropdown(b6, "Buff Up/Down", 280, -550, 120)
  sa.buffRowGrowDD:ClearAllPoints()
  sa.buffRowGrowDD:SetPoint("LEFT", sa.buffGrowDD, "RIGHT", 15, 0)
  if sa.buffRowGrowLbl then sa.buffRowGrowLbl:ClearAllPoints(); sa.buffRowGrowLbl:SetPoint("BOTTOMLEFT", sa.buffRowGrowDD, "TOPLEFT", 0, 4) end
  sa.buffRowGrowDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
  sa.buffSizeSlider = Slider(b6, "Buff Size", 15, -610, 20, 80, 45, 0.5)
  sa.buffSizeSlider.label:ClearAllPoints()
  sa.buffSizeSlider.label:SetPoint("TOPLEFT", sa.buffRowsDD, "BOTTOMLEFT", 0, -25)
  sa.buffSizeSlider:ClearAllPoints()
  sa.buffSizeSlider:SetPoint("TOPLEFT", sa.buffSizeSlider.label, "BOTTOMLEFT", 0, -8)
  sa.buffCdTextSlider = Slider(b6, "Buff CD Text Scale", 15, -660, 0, 4.0, 1.0, 0.1)
  sa.buffCdTextSlider.label:ClearAllPoints()
  sa.buffCdTextSlider.label:SetPoint("TOPLEFT", sa.buffSizeSlider, "BOTTOMLEFT", 0, -25)
  sa.buffCdTextSlider:ClearAllPoints()
  sa.buffCdTextSlider:SetPoint("TOPLEFT", sa.buffCdTextSlider.label, "BOTTOMLEFT", 0, -8)
  sa.buffYSlider = Slider(b6, "Buff Y", 280, -610, -800, 800, 0, 0.5)
  sa.buffYSlider.label:ClearAllPoints()
  sa.buffYSlider.label:SetPoint("TOPLEFT", sa.buffSizeSlider.label, "TOPLEFT", 265, 0)
  sa.buffYSlider:ClearAllPoints()
  sa.buffYSlider:SetPoint("TOPLEFT", sa.buffYSlider.label, "BOTTOMLEFT", 0, -8)
  sa.buffXSlider = Slider(b6, "Buff X", 280, -660, -800, 800, -150, 0.5)
  sa.buffXSlider.label:ClearAllPoints()
  sa.buffXSlider.label:SetPoint("TOPLEFT", sa.buffYSlider, "BOTTOMLEFT", 0, -25)
  sa.buffXSlider:ClearAllPoints()
  sa.buffXSlider:SetPoint("TOPLEFT", sa.buffXSlider.label, "BOTTOMLEFT", 0, -8)
  sa.buffIconsPerRowSlider = Slider(b6, "Buff Icons/Row", 280, -710, 0, 20, 0, 1)
  sa.buffIconsPerRowSlider.label:ClearAllPoints()
  sa.buffIconsPerRowSlider.label:SetPoint("TOPLEFT", sa.buffXSlider, "BOTTOMLEFT", 0, -25)
  sa.buffIconsPerRowSlider:ClearAllPoints()
  sa.buffIconsPerRowSlider:SetPoint("TOPLEFT", sa.buffIconsPerRowSlider.label, "BOTTOMLEFT", 0, -8)
  local b6EssentialSec = Section(b6, "Essential Bar Settings", -770)
  sa.essentialRowsDD, sa.essentialRowsLbl = StyledDropdown(b6, "Essential Rows", 15, -800, 120)
  sa.essentialRowsDD:ClearAllPoints()
  sa.essentialRowsDD:SetPoint("TOPLEFT", b6EssentialSec, "BOTTOMLEFT", 0, -15)
  if sa.essentialRowsLbl then sa.essentialRowsLbl:ClearAllPoints(); sa.essentialRowsLbl:SetPoint("BOTTOMLEFT", sa.essentialRowsDD, "TOPLEFT", 0, 4) end
  sa.essentialRowsDD:SetOptions({{text = "1 Row", value = "1"}, {text = "2 Rows", value = "2"}})
  sa.essentialGrowDD, sa.essentialGrowLbl = StyledDropdown(b6, "Essential Grow", 150, -800, 120)
  sa.essentialGrowDD:ClearAllPoints()
  sa.essentialGrowDD:SetPoint("LEFT", sa.essentialRowsDD, "RIGHT", 15, 0)
  if sa.essentialGrowLbl then sa.essentialGrowLbl:ClearAllPoints(); sa.essentialGrowLbl:SetPoint("BOTTOMLEFT", sa.essentialGrowDD, "TOPLEFT", 0, 4) end
  sa.essentialGrowDD:SetOptions({{text = "Right", value = "right"}, {text = "Left", value = "left"}})
  sa.essentialRowGrowDD, sa.essentialRowGrowLbl = StyledDropdown(b6, "Essential Up/Down", 280, -800, 120)
  sa.essentialRowGrowDD:ClearAllPoints()
  sa.essentialRowGrowDD:SetPoint("LEFT", sa.essentialGrowDD, "RIGHT", 15, 0)
  if sa.essentialRowGrowLbl then sa.essentialRowGrowLbl:ClearAllPoints(); sa.essentialRowGrowLbl:SetPoint("BOTTOMLEFT", sa.essentialRowGrowDD, "TOPLEFT", 0, 4) end
  sa.essentialRowGrowDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
  sa.essentialSizeSlider = Slider(b6, "Essential Size", 15, -860, 20, 80, 45, 0.5)
  sa.essentialSizeSlider.label:ClearAllPoints()
  sa.essentialSizeSlider.label:SetPoint("TOPLEFT", sa.essentialRowsDD, "BOTTOMLEFT", 0, -25)
  sa.essentialSizeSlider:ClearAllPoints()
  sa.essentialSizeSlider:SetPoint("TOPLEFT", sa.essentialSizeSlider.label, "BOTTOMLEFT", 0, -8)
  sa.essentialYSlider = Slider(b6, "Essential Y", 280, -860, -800, 800, 50, 0.5)
  sa.essentialYSlider.label:ClearAllPoints()
  sa.essentialYSlider.label:SetPoint("TOPLEFT", sa.essentialSizeSlider.label, "TOPLEFT", 265, 0)
  sa.essentialYSlider:ClearAllPoints()
  sa.essentialYSlider:SetPoint("TOPLEFT", sa.essentialYSlider.label, "BOTTOMLEFT", 0, -8)
  sa.essentialSecondRowSizeSlider = Slider(b6, "Essential Row 2 Size", 15, -910, 20, 80, 45, 0.5)
  sa.essentialSecondRowSizeSlider.label:ClearAllPoints()
  sa.essentialSecondRowSizeSlider.label:SetPoint("TOPLEFT", sa.essentialSizeSlider, "BOTTOMLEFT", 0, -25)
  sa.essentialSecondRowSizeSlider:ClearAllPoints()
  sa.essentialSecondRowSizeSlider:SetPoint("TOPLEFT", sa.essentialSecondRowSizeSlider.label, "BOTTOMLEFT", 0, -8)
  sa.essentialCdTextSlider = Slider(b6, "Essential CD Text Scale", 15, -960, 0, 4.0, 1.0, 0.1)
  sa.essentialCdTextSlider.label:ClearAllPoints()
  sa.essentialCdTextSlider.label:SetPoint("TOPLEFT", sa.essentialSecondRowSizeSlider, "BOTTOMLEFT", 0, -25)
  sa.essentialCdTextSlider:ClearAllPoints()
  sa.essentialCdTextSlider:SetPoint("TOPLEFT", sa.essentialCdTextSlider.label, "BOTTOMLEFT", 0, -8)
  sa.essentialXSlider = Slider(b6, "Essential X", 280, -910, -800, 800, 0, 0.5)
  sa.essentialXSlider.label:ClearAllPoints()
  sa.essentialXSlider.label:SetPoint("TOPLEFT", sa.essentialYSlider, "BOTTOMLEFT", 0, -25)
  sa.essentialXSlider:ClearAllPoints()
  sa.essentialXSlider:SetPoint("TOPLEFT", sa.essentialXSlider.label, "BOTTOMLEFT", 0, -8)
  sa.essentialIconsPerRowSlider = Slider(b6, "Essential Icons/Row", 280, -960, 0, 20, 0, 1)
  sa.essentialIconsPerRowSlider.label:ClearAllPoints()
  sa.essentialIconsPerRowSlider.label:SetPoint("TOPLEFT", sa.essentialXSlider, "BOTTOMLEFT", 0, -25)
  sa.essentialIconsPerRowSlider:ClearAllPoints()
  sa.essentialIconsPerRowSlider:SetPoint("TOPLEFT", sa.essentialIconsPerRowSlider.label, "BOTTOMLEFT", 0, -8)
  local b6UtilitySec = Section(b6, "Utility Bar Settings", -1020)
  local utilitySectionLine = b6:CreateTexture(nil, "OVERLAY")
  utilitySectionLine:SetHeight(2)
  utilitySectionLine:SetPoint("LEFT", b6UtilitySec, "RIGHT", 8, 0)
  utilitySectionLine:SetPoint("RIGHT", b6, "RIGHT", -15, 0)
  utilitySectionLine:SetColorTexture(0.4, 0.4, 0.45, 1)
  utilitySectionLine:SetSnapToPixelGrid(true)
  utilitySectionLine:SetTexelSnappingBias(0)
  sa.utilityRowsDD, sa.utilityRowsLbl = StyledDropdown(b6, "Utility Rows", 15, -1050, 120)
  sa.utilityRowsDD:ClearAllPoints()
  sa.utilityRowsDD:SetPoint("TOPLEFT", b6UtilitySec, "BOTTOMLEFT", 0, -15)
  if sa.utilityRowsLbl then sa.utilityRowsLbl:ClearAllPoints(); sa.utilityRowsLbl:SetPoint("BOTTOMLEFT", sa.utilityRowsDD, "TOPLEFT", 0, 4) end
  sa.utilityRowsDD:SetOptions({{text = "1 Row", value = "1"}, {text = "2 Rows", value = "2"}})
  sa.utilityGrowDD, sa.utilityGrowLbl = StyledDropdown(b6, "Utility Grow", 150, -1050, 120)
  sa.utilityGrowDD:ClearAllPoints()
  sa.utilityGrowDD:SetPoint("LEFT", sa.utilityRowsDD, "RIGHT", 15, 0)
  if sa.utilityGrowLbl then sa.utilityGrowLbl:ClearAllPoints(); sa.utilityGrowLbl:SetPoint("BOTTOMLEFT", sa.utilityGrowDD, "TOPLEFT", 0, 4) end
  sa.utilityGrowDD:SetOptions({{text = "Right", value = "right"}, {text = "Left", value = "left"}})
  sa.utilityRowGrowDD, sa.utilityRowGrowLbl = StyledDropdown(b6, "Utility Up/Down", 280, -1050, 120)
  sa.utilityRowGrowDD:ClearAllPoints()
  sa.utilityRowGrowDD:SetPoint("LEFT", sa.utilityGrowDD, "RIGHT", 15, 0)
  if sa.utilityRowGrowLbl then sa.utilityRowGrowLbl:ClearAllPoints(); sa.utilityRowGrowLbl:SetPoint("BOTTOMLEFT", sa.utilityRowGrowDD, "TOPLEFT", 0, 4) end
  sa.utilityRowGrowDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
  sa.utilityAutoWidthDD, sa.utilityAutoWidthLbl = StyledDropdown(b6, "Utility Auto Width", 410, -1050, 120)
  sa.utilityAutoWidthDD:ClearAllPoints()
  sa.utilityAutoWidthDD:SetPoint("LEFT", sa.utilityRowGrowDD, "RIGHT", 15, 0)
  if sa.utilityAutoWidthLbl then sa.utilityAutoWidthLbl:ClearAllPoints(); sa.utilityAutoWidthLbl:SetPoint("BOTTOMLEFT", sa.utilityAutoWidthDD, "TOPLEFT", 0, 4) end
  sa.utilitySizeSlider = Slider(b6, "Utility Size", 15, -1110, 20, 80, 45, 0.5)
  sa.utilitySizeSlider.label:ClearAllPoints()
  sa.utilitySizeSlider.label:SetPoint("TOPLEFT", sa.utilityRowsDD, "BOTTOMLEFT", 0, -25)
  sa.utilitySizeSlider:ClearAllPoints()
  sa.utilitySizeSlider:SetPoint("TOPLEFT", sa.utilitySizeSlider.label, "BOTTOMLEFT", 0, -8)
  sa.utilityCdTextSlider = Slider(b6, "Utility CD Text Scale", 15, -1160, 0, 4.0, 1.0, 0.1)
  sa.utilityCdTextSlider.label:ClearAllPoints()
  sa.utilityCdTextSlider.label:SetPoint("TOPLEFT", sa.utilitySizeSlider, "BOTTOMLEFT", 0, -25)
  sa.utilityCdTextSlider:ClearAllPoints()
  sa.utilityCdTextSlider:SetPoint("TOPLEFT", sa.utilityCdTextSlider.label, "BOTTOMLEFT", 0, -8)
  sa.utilityYSlider = Slider(b6, "Utility Y", 280, -1110, -800, 800, -50, 0.5)
  sa.utilityYSlider.label:ClearAllPoints()
  sa.utilityYSlider.label:SetPoint("TOPLEFT", sa.utilitySizeSlider.label, "TOPLEFT", 265, 0)
  sa.utilityYSlider:ClearAllPoints()
  sa.utilityYSlider:SetPoint("TOPLEFT", sa.utilityYSlider.label, "BOTTOMLEFT", 0, -8)
  sa.utilityXSlider = Slider(b6, "Utility X", 280, -1160, -800, 800, 150, 0.5)
  sa.utilityXSlider.label:ClearAllPoints()
  sa.utilityXSlider.label:SetPoint("TOPLEFT", sa.utilityYSlider, "BOTTOMLEFT", 0, -25)
  sa.utilityXSlider:ClearAllPoints()
  sa.utilityXSlider:SetPoint("TOPLEFT", sa.utilityXSlider.label, "BOTTOMLEFT", 0, -8)
  sa.utilityIconsPerRowSlider = Slider(b6, "Utility Icons/Row", 280, -1210, 0, 20, 0, 1)
  sa.utilityIconsPerRowSlider.label:ClearAllPoints()
  sa.utilityIconsPerRowSlider.label:SetPoint("TOPLEFT", sa.utilityXSlider, "BOTTOMLEFT", 0, -25)
  sa.utilityIconsPerRowSlider:ClearAllPoints()
  sa.utilityIconsPerRowSlider:SetPoint("TOPLEFT", sa.utilityIconsPerRowSlider.label, "BOTTOMLEFT", 0, -8)
  sa.utilityAutoWidthDD:SetOptions({
    {text = "Off", value = "off"},
    {text = "Essential Bar", value = "essential"},
    {text = "CBar 1", value = "cbar1"},
    {text = "CBar 2", value = "cbar2"},
    {text = "CBar 3", value = "cbar3"},
    {text = "CBar 4", value = "cbar4"},
    {text = "CBar 5", value = "cbar5"},
  })
  blizzScrollChild:SetHeight(1380)
  local tab7 = tabFrames[7]
  if tab7 then
    local prbScrollFrame = CreateFrame("ScrollFrame", "CCMPRBScrollFrame", tab7, "UIPanelScrollFrameTemplate")
    prbScrollFrame:SetPoint("TOPLEFT", tab7, "TOPLEFT", 0, 0)
    prbScrollFrame:SetPoint("BOTTOMRIGHT", tab7, "BOTTOMRIGHT", -22, 0)
    local prbScrollChild = CreateFrame("Frame", "CCMPRBScrollChild", prbScrollFrame)
    prbScrollChild:SetSize(490, 1200)
    prbScrollFrame:SetScrollChild(prbScrollChild)
    local scrollBar = _G["CCMPRBScrollFrameScrollBar"]
    if scrollBar then
      scrollBar:SetPoint("TOPLEFT", prbScrollFrame, "TOPRIGHT", 6, -16)
      scrollBar:SetPoint("BOTTOMLEFT", prbScrollFrame, "BOTTOMRIGHT", 6, 16)
      local thumb = scrollBar:GetThumbTexture()
      if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
      local up = _G["CCMPRBScrollFrameScrollBarScrollUpButton"]
      local down = _G["CCMPRBScrollFrameScrollBarScrollDownButton"]
      if up then up:SetAlpha(0); up:EnableMouse(false) end
      if down then down:SetAlpha(0); down:EnableMouse(false) end
    end
    SetSmoothScroll(prbScrollFrame)
    addonTable.prb = {}
    local prb = addonTable.prb
    local pc = prbScrollChild
    local COL1, COL2 = 15, 270
    local y = -5
    local function PRBSection(txt)
      local l = pc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      l:SetPoint("TOPLEFT", pc, "TOPLEFT", 15, y)
      l:SetText(txt)
      l:SetTextColor(1, 0.82, 0)
      local ln = pc:CreateTexture(nil, "ARTWORK")
      ln:SetHeight(1)
      ln:SetPoint("LEFT", l, "RIGHT", 8, 0)
      ln:SetPoint("RIGHT", pc, "RIGHT", -15, 0)
      ln:SetColorTexture(0.3, 0.3, 0.35, 1)
      ln:SetSnapToPixelGrid(true)
      ln:SetTexelSnappingBias(0)
      y = y - 25
      return l, ln
    end
    local function ColorBtn(label, x, yPos, r, g, b)
      local btn = CreateStyledButton(pc, label, 70, 22)
      btn:SetPoint("TOPLEFT", pc, "TOPLEFT", x, yPos)
      local swatch = CreateFrame("Frame", nil, pc, "BackdropTemplate")
      swatch:SetSize(22, 22)
      swatch:SetPoint("LEFT", btn, "RIGHT", 4, 0)
      swatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      swatch:SetBackdropColor(r, g, b, 1)
      swatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      return btn, swatch
    end
    local prbHighlightBtn = CreateHighlightToggle(pc)
    PRBSection("General")
    prb.clampBarsCB = Checkbox(pc, "Clamp Bars", COL1, y)
    prb.centeredCB = Checkbox(pc, "Center", 120, y)
    prb.centeredCB:ClearAllPoints()
    prb.centeredCB:SetPoint("LEFT", prb.clampBarsCB.label, "RIGHT", 15, 0)
    prb.showHealthCB = Checkbox(pc, "Health", 200, y)
    prb.showHealthCB:ClearAllPoints()
    prb.showHealthCB:SetPoint("LEFT", prb.centeredCB.label, "RIGHT", 15, 0)
    prb.showPowerCB = Checkbox(pc, "Power", 275, y)
    prb.showPowerCB:ClearAllPoints()
    prb.showPowerCB:SetPoint("LEFT", prb.showHealthCB.label, "RIGHT", 15, 0)
    prb.showClassPowerCB = Checkbox(pc, "Class Power", 355, y)
    prb.showClassPowerCB:ClearAllPoints()
    prb.showClassPowerCB:SetPoint("LEFT", prb.showPowerCB.label, "RIGHT", 15, 0)
    y = y - 30
    prb.showModeDD, prb.showModeLbl = StyledDropdown(pc, "Show", COL1, y, 120)
    prb.showModeDD:SetOptions({{text = "Always", value = "always"}, {text = "In Combat", value = "combat"}})
    prb.anchorDD, prb.anchorLbl = StyledDropdown(pc, "Clamp Anchor", COL1 + 130, y, 120)
    prb.anchorDD:ClearAllPoints()
    prb.anchorDD:SetPoint("LEFT", prb.showModeDD, "RIGHT", 15, 0)
    if prb.anchorLbl then prb.anchorLbl:ClearAllPoints(); prb.anchorLbl:SetPoint("BOTTOMLEFT", prb.anchorDD, "TOPLEFT", 0, 4) end
    prb.anchorDD:SetOptions({{text = "Top", value = "top"}, {text = "Bottom", value = "bottom"}})
    prb.autoWidthDD, prb.autoWidthLbl = StyledDropdown(pc, "Auto Width", COL2 + 6, y, 140)
    prb.autoWidthDD:SetOptions({{text = "Off", value = "off"}, {text = "CBar 1", value = "cbar1"}, {text = "CBar 2", value = "cbar2"}, {text = "CBar 3", value = "cbar3"}, {text = "CBar 4", value = "cbar4"}, {text = "CBar 5", value = "cbar5"}, {text = "Essential Bar", value = "essential"}})
    prb.bgColorBtn, prb.bgColorSwatch = ColorBtn("BG Color", COL2 + 160, y - 17, 0.1, 0.1, 0.1)
    prbHighlightBtn:ClearAllPoints()
    prbHighlightBtn:SetPoint("TOPLEFT", prb.bgColorBtn, "BOTTOMLEFT", 0, -8)
    y = y - 50
    prb.widthSlider = Slider(pc, "Bar Width", COL1, y, 50, 600, 220, 1)
    y = y - 50
    prb.xSlider = Slider(pc, "X Offset", COL1, y, -1000, 1000, 0, 1)
    prb.ySlider = Slider(pc, "Y Offset", COL2 + 6, y, -1000, 1000, -180, 0.5)
    y = y - 50
    prb.spacingSlider = Slider(pc, "Bar Spacing", COL1, y, -3, 10, 0, 1)
    prb.borderSlider = Slider(pc, "Border", COL2 + 6, y, 0, 3, 1, 1)
    y = y - 55
    prb.healthHeader, prb.healthLine = PRBSection("Health Bar")
    prb.healthHeightSlider = Slider(pc, "Height", COL1, y, 5, 40, 18, 1)
    prb.healthYOffsetSlider = Slider(pc, "Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    prb.healthTextScaleSlider = Slider(pc, "Text Scale", COL1, y, 0.5, 2, 1, 0.1)
    prb.healthTextYSlider = Slider(pc, "Text Y", COL2 + 6, y, -20, 20, 0, 1)
    y = y - 50
    prb.healthTextureDD, prb.healthTextureLbl = StyledDropdown(pc, "Texture", COL1, y, 140)
    ApplyTextureOptionsToDropdown(prb.healthTextureDD)
    prb.healthTextDD, prb.healthTextLbl = StyledDropdown(pc, "Text", 170, y, 105)
    prb.healthTextDD:SetOptions({{text = "Hidden", value = "hidden"}, {text = "Percent", value = "percent"}, {text = "Percent #", value = "percentnumber"}, {text = "Value", value = "value"}, {text = "Both", value = "both"}})
    y = y - 50
    prb.healthColorBtn, prb.healthColorSwatch = ColorBtn("Bar Color", COL1, y, 0, 1, 0)
    prb.healthTextColorBtn, prb.healthTextColorSwatch = ColorBtn("Text Color", 170, y, 1, 1, 1)
    prb.useClassColorCB = Checkbox(pc, "Use Class Color", 295, y)
    y = y - 40
    prb.showAbsorbCB = Checkbox(pc, "Show Absorb", COL1, y)
    prb.healAbsorbCB = Checkbox(pc, "Heal Absorb", 150, y)
    prb.healAbsorbCB:ClearAllPoints()
    prb.healAbsorbCB:SetPoint("LEFT", prb.showAbsorbCB.label, "RIGHT", 15, 0)
    prb.healPredCB = Checkbox(pc, "Heal Prediction", 295, y)
    prb.healPredCB:ClearAllPoints()
    prb.healPredCB:SetPoint("LEFT", prb.healAbsorbCB.label, "RIGHT", 15, 0)
    y = y - 26
    prb.absorbStripesCB = Checkbox(pc, "Absorb Stripes", COL1, y)
    prb.overAbsorbBarCB = Checkbox(pc, "Overabsorb", 150, y)
    prb.overAbsorbBarCB:ClearAllPoints()
    prb.overAbsorbBarCB:SetPoint("LEFT", prb.absorbStripesCB.label, "RIGHT", 15, 0)
    y = y - 40
    prb.lowHealthColorCB = Checkbox(pc, "Low Health Color", COL1, y - 8)
    prb.lowHealthColorBtn, prb.lowHealthColorSwatch = ColorBtn("Color", 160, y - 8, 1, 0, 0)
    prb.lowHealthThresholdSlider = Slider(pc, "Threshold %", COL2 + 6, y, 10, 80, 50, 5)
    y = y - 55
    prb.healthElements = {
      prb.healthHeader, prb.healthLine,
      prb.healthHeightSlider, prb.healthHeightSlider.label, prb.healthHeightSlider.valueText, prb.healthHeightSlider.valueTextBg, prb.healthHeightSlider.upBtn, prb.healthHeightSlider.downBtn,
      prb.healthYOffsetSlider, prb.healthYOffsetSlider.label, prb.healthYOffsetSlider.valueText, prb.healthYOffsetSlider.valueTextBg, prb.healthYOffsetSlider.upBtn, prb.healthYOffsetSlider.downBtn,
      prb.healthTextScaleSlider, prb.healthTextScaleSlider.label, prb.healthTextScaleSlider.valueText, prb.healthTextScaleSlider.valueTextBg, prb.healthTextScaleSlider.upBtn, prb.healthTextScaleSlider.downBtn,
      prb.healthTextureDD, prb.healthTextureLbl,
      prb.healthTextDD, prb.healthTextLbl,
      prb.healAbsorbCB, prb.healAbsorbCB.label,
      prb.healPredCB, prb.healPredCB.label,
      prb.absorbStripesCB, prb.absorbStripesCB.label,
      prb.overAbsorbBarCB, prb.overAbsorbBarCB.label,
      prb.showAbsorbCB, prb.showAbsorbCB.label,
      prb.healthTextYSlider, prb.healthTextYSlider.label, prb.healthTextYSlider.valueText, prb.healthTextYSlider.valueTextBg, prb.healthTextYSlider.upBtn, prb.healthTextYSlider.downBtn,
      prb.healthColorBtn, prb.healthColorSwatch, prb.healthTextColorBtn, prb.healthTextColorSwatch,
      prb.useClassColorCB, prb.useClassColorCB.label,
      prb.lowHealthColorCB, prb.lowHealthColorCB.label, prb.lowHealthColorBtn, prb.lowHealthColorSwatch,
      prb.lowHealthThresholdSlider, prb.lowHealthThresholdSlider.label, prb.lowHealthThresholdSlider.valueText, prb.lowHealthThresholdSlider.valueTextBg, prb.lowHealthThresholdSlider.upBtn, prb.lowHealthThresholdSlider.downBtn,
    }
    prb.powerHeader, prb.powerLine = PRBSection("Power Bar")
    prb.powerHeightSlider = Slider(pc, "Height", COL1, y, 3, 30, 8, 1)
    prb.powerYOffsetSlider = Slider(pc, "Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    prb.powerTextScaleSlider = Slider(pc, "Text Scale", COL1, y, 0.5, 2, 1, 0.1)
    prb.powerTextYSlider = Slider(pc, "Text Y", COL2 + 6, y, -20, 20, 0, 1)
    y = y - 50
    prb.powerTextureDD, prb.powerTextureLbl = StyledDropdown(pc, "Texture", COL1, y, 140)
    ApplyTextureOptionsToDropdown(prb.powerTextureDD)
    prb.powerTextDD, prb.powerTextLbl = StyledDropdown(pc, "Text", 170, y, 105)
    prb.powerTextDD:SetOptions({{text = "Hidden", value = "hidden"}, {text = "Percent", value = "percent"}, {text = "Percent #", value = "percentnumber"}, {text = "Value", value = "value"}, {text = "Both", value = "both"}})
    y = y - 50
    prb.powerColorBtn, prb.powerColorSwatch = ColorBtn("Bar Color", COL1, y, 0, 0.5, 1)
    prb.powerTextColorBtn, prb.powerTextColorSwatch = ColorBtn("Text Color", 170, y, 1, 1, 1)
    prb.usePowerTypeColorCB = Checkbox(pc, "Use Power Type Color", COL2 + 6, y)
    y = y - 40
    prb.lowPowerColorCB = Checkbox(pc, "Low Power Color", COL1, y - 8)
    prb.lowPowerColorBtn, prb.lowPowerColorSwatch = ColorBtn("Color", 160, y - 8, 1, 0.5, 0)
    prb.lowPowerThresholdSlider = Slider(pc, "Threshold %", COL2 + 6, y, 10, 80, 30, 5)
    y = y - 55
    prb.powerElements = {
      prb.powerHeader, prb.powerLine,
      prb.powerHeightSlider, prb.powerHeightSlider.label, prb.powerHeightSlider.valueText, prb.powerHeightSlider.valueTextBg, prb.powerHeightSlider.upBtn, prb.powerHeightSlider.downBtn,
      prb.powerYOffsetSlider, prb.powerYOffsetSlider.label, prb.powerYOffsetSlider.valueText, prb.powerYOffsetSlider.valueTextBg, prb.powerYOffsetSlider.upBtn, prb.powerYOffsetSlider.downBtn,
      prb.powerTextScaleSlider, prb.powerTextScaleSlider.label, prb.powerTextScaleSlider.valueText, prb.powerTextScaleSlider.valueTextBg, prb.powerTextScaleSlider.upBtn, prb.powerTextScaleSlider.downBtn,
      prb.powerTextureDD, prb.powerTextureLbl,
      prb.powerTextYSlider, prb.powerTextYSlider.label, prb.powerTextYSlider.valueText, prb.powerTextYSlider.valueTextBg, prb.powerTextYSlider.upBtn, prb.powerTextYSlider.downBtn,
      prb.powerColorBtn, prb.powerColorSwatch, prb.powerTextColorBtn, prb.powerTextColorSwatch,
      prb.powerTextDD, prb.powerTextLbl,
      prb.usePowerTypeColorCB, prb.usePowerTypeColorCB.label,
      prb.lowPowerColorCB, prb.lowPowerColorCB.label, prb.lowPowerColorBtn, prb.lowPowerColorSwatch,
      prb.lowPowerThresholdSlider, prb.lowPowerThresholdSlider.label, prb.lowPowerThresholdSlider.valueText, prb.lowPowerThresholdSlider.valueTextBg, prb.lowPowerThresholdSlider.upBtn, prb.lowPowerThresholdSlider.downBtn,
    }
    local _, playerClass = UnitClass("player")
    local names = {PALADIN = "Holy Power", ROGUE = "Combo Points", DRUID = "Combo Points", WARLOCK = "Soul Shards", MONK = "Chi", MAGE = "Arcane Charges", EVOKER = "Essence", DEATHKNIGHT = "Runes", PRIEST = "Insanity"}
    local classPowerName = names[playerClass] or "Resource"
    if playerClass == "SHAMAN" then
      local specIndex = GetSpecialization()
      local specID = specIndex and GetSpecializationInfo(specIndex)
      if specID == 263 then
        classPowerName = "Maelstrom Weapon"
      elseif specID == 262 then
        classPowerName = "Maelstrom"
      end
    end
    prb.classPowerHeader, prb.classPowerLine = PRBSection("Class Power (" .. classPowerName .. ")")
    prb.classPowerHeightSlider = Slider(pc, "Height", COL1, y, 3, 20, 6, 1)
    prb.classPowerYSlider = Slider(pc, "Y Offset", COL2 + 6, y, -100, 100, 20, 1)
    y = y - 50
    prb.classPowerColorBtn, prb.classPowerColorSwatch = ColorBtn("Color", COL1, y, 1, 0.82, 0)
    y = y - 35
    prb.classPowerElements = {
      prb.classPowerHeader, prb.classPowerLine,
      prb.classPowerHeightSlider, prb.classPowerHeightSlider.label, prb.classPowerHeightSlider.valueText, prb.classPowerHeightSlider.valueTextBg, prb.classPowerHeightSlider.upBtn, prb.classPowerHeightSlider.downBtn,
      prb.classPowerYSlider, prb.classPowerYSlider.label, prb.classPowerYSlider.valueText, prb.classPowerYSlider.valueTextBg, prb.classPowerYSlider.upBtn, prb.classPowerYSlider.downBtn,
      prb.classPowerColorBtn, prb.classPowerColorSwatch,
    }
    prb.manaHeader, prb.manaLine = PRBSection("Mana Bar (when not main resource)")
    prb.showManaBarCB = Checkbox(pc, "Show Mana Bar", COL1, y)
    y = y - 30
    prb.manaHeightSlider = Slider(pc, "Height", COL1, y, 3, 20, 6, 1)
    prb.manaYOffsetSlider = Slider(pc, "Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    prb.manaTextScaleSlider = Slider(pc, "Text Scale", COL1, y, 0.5, 2, 1, 0.1)
    prb.manaTextYSlider = Slider(pc, "Text Y", COL2 + 6, y, -20, 20, 0, 1)
    y = y - 50
    prb.manaTextureDD, prb.manaTextureLbl = StyledDropdown(pc, "Texture", COL1, y, 140)
    ApplyTextureOptionsToDropdown(prb.manaTextureDD)
    y = y - 50
    prb.manaTextDD, prb.manaTextLbl = StyledDropdown(pc, "Text", COL2 + 6, y - 4, 100)
    prb.manaTextDD:SetOptions({{text = "Hidden", value = "hidden"}, {text = "Percent", value = "percent"}, {text = "Percent #", value = "percentnumber"}, {text = "Value", value = "value"}, {text = "Both", value = "both"}})
    prb.manaColorBtn, prb.manaColorSwatch = ColorBtn("Bar Color", COL1, y - 22, 0, 0.4, 0.9)
    prb.manaTextColorBtn, prb.manaTextColorSwatch = ColorBtn("Text Color", COL1 + 110, y - 22, 1, 1, 1)
    y = y - 55
    prb.manaElements = {
      prb.manaHeader, prb.manaLine, prb.showManaBarCB, prb.showManaBarCB.label,
      prb.manaHeightSlider, prb.manaHeightSlider.label, prb.manaHeightSlider.valueText, prb.manaHeightSlider.valueTextBg, prb.manaHeightSlider.upBtn, prb.manaHeightSlider.downBtn,
      prb.manaYOffsetSlider, prb.manaYOffsetSlider.label, prb.manaYOffsetSlider.valueText, prb.manaYOffsetSlider.valueTextBg, prb.manaYOffsetSlider.upBtn, prb.manaYOffsetSlider.downBtn,
      prb.manaTextScaleSlider, prb.manaTextScaleSlider.label, prb.manaTextScaleSlider.valueText, prb.manaTextScaleSlider.valueTextBg, prb.manaTextScaleSlider.upBtn, prb.manaTextScaleSlider.downBtn,
      prb.manaTextureDD, prb.manaTextureLbl,
      prb.manaTextYSlider, prb.manaTextYSlider.label, prb.manaTextYSlider.valueText, prb.manaTextYSlider.valueTextBg, prb.manaTextYSlider.upBtn, prb.manaTextYSlider.downBtn,
      prb.manaColorBtn, prb.manaColorSwatch, prb.manaTextColorBtn, prb.manaTextColorSwatch,
      prb.manaTextDD, prb.manaTextLbl,
    }
    prb.UpdateSectionVisibility = function()
      local p = addonTable.GetProfile and addonTable.GetProfile()
      local showHealth = p and p.prbShowHealth
      local showPower = p and p.prbShowPower
      local showClassPower = p and p.prbShowClassPower
      local dmgAbsorbMode = (p and p.prbDmgAbsorb) or "bar"
      local showOverAbsorbOption = showHealth and dmgAbsorbMode ~= "off"
      local cpConfig = addonTable.GetClassPowerConfig and addonTable.GetClassPowerConfig(true)
      local isRedundant = addonTable.IsClassPowerRedundant and addonTable.IsClassPowerRedundant()
      local noClassPower = cpConfig == nil or isRedundant
      local _, playerClass = UnitClass("player")
      local hasManaPool = (playerClass ~= "WARRIOR" and playerClass ~= "ROGUE" and playerClass ~= "DEATHKNIGHT" and playerClass ~= "DEMONHUNTER")
      local currentPowerType = UnitPowerType("player") or 0
      local hasSecondaryMana = hasManaPool and currentPowerType ~= 0
      local hasMana = hasSecondaryMana
      if prb.showClassPowerCB then
        prb.showClassPowerCB:SetEnabled(not noClassPower)
        prb.showClassPowerCB:SetAlpha(noClassPower and 0.4 or 1)
        if noClassPower then
          prb.showClassPowerCB:SetChecked(false)
          showClassPower = false
        end
      end
      local function SetSectionEnabled(elements, enabled)
        for _, elem in ipairs(elements) do
          if elem then
            if elem.SetEnabled then elem:SetEnabled(enabled) end
            if elem.SetAlpha then elem:SetAlpha(enabled and 1 or 0.4) end
          end
        end
      end
      SetSectionEnabled(prb.healthElements, showHealth)
      SetSectionEnabled(prb.powerElements, showPower)
      SetSectionEnabled(prb.manaElements, hasMana)
      SetSectionEnabled(prb.classPowerElements, showClassPower and not noClassPower)
      if prb.overAbsorbBarCB then
        if showOverAbsorbOption then
          if prb.overAbsorbBarCB.Show then prb.overAbsorbBarCB:Show() end
          if prb.overAbsorbBarCB.label and prb.overAbsorbBarCB.label.Show then prb.overAbsorbBarCB.label:Show() end
        else
          if prb.overAbsorbBarCB.Hide then prb.overAbsorbBarCB:Hide() end
          if prb.overAbsorbBarCB.label and prb.overAbsorbBarCB.label.Hide then prb.overAbsorbBarCB.label:Hide() end
        end
      end
      if prb.absorbStripesCB then
        if showOverAbsorbOption then
          if prb.absorbStripesCB.Show then prb.absorbStripesCB:Show() end
          if prb.absorbStripesCB.label and prb.absorbStripesCB.label.Show then prb.absorbStripesCB.label:Show() end
        else
          if prb.absorbStripesCB.Hide then prb.absorbStripesCB:Hide() end
          if prb.absorbStripesCB.label and prb.absorbStripesCB.label.Hide then prb.absorbStripesCB.label:Hide() end
        end
      end
      if not hasMana then
        for _, elem in ipairs(prb.manaElements) do
          if elem and elem.Hide then elem:Hide() end
        end
      else
        for _, elem in ipairs(prb.manaElements) do
          if elem and elem.Show then elem:Show() end
        end
      end
    end
    addonTable.UpdatePRBSectionVisibility = prb.UpdateSectionVisibility
    tab7:SetScript("OnShow", function() C_Timer.After(0.05, function() if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end; if prb.UpdateSectionVisibility then prb.UpdateSectionVisibility() end end) end)
    prbScrollChild:SetHeight(math.abs(y) + 30)
  end
  local tab8 = tabFrames[8]
  if tab8 then
    local castbarScrollFrame = CreateFrame("ScrollFrame", "CCMCastbarScrollFrame", tab8, "UIPanelScrollFrameTemplate")
    castbarScrollFrame:SetPoint("TOPLEFT", tab8, "TOPLEFT", 0, 0)
    castbarScrollFrame:SetPoint("BOTTOMRIGHT", tab8, "BOTTOMRIGHT", -22, 0)
    local castbarScrollChild = CreateFrame("Frame", "CCMCastbarScrollChild", castbarScrollFrame)
    castbarScrollChild:SetSize(490, 825)
    castbarScrollFrame:SetScrollChild(castbarScrollChild)
    local scrollBar = _G["CCMCastbarScrollFrameScrollBar"]
    if scrollBar then
      scrollBar:SetPoint("TOPLEFT", castbarScrollFrame, "TOPRIGHT", 6, -16)
      scrollBar:SetPoint("BOTTOMLEFT", castbarScrollFrame, "BOTTOMRIGHT", 6, 16)
      local thumb = scrollBar:GetThumbTexture()
      if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
      local up = _G["CCMCastbarScrollFrameScrollBarScrollUpButton"]
      local down = _G["CCMCastbarScrollFrameScrollBarScrollDownButton"]
      if up then up:SetAlpha(0); up:EnableMouse(false) end
      if down then down:SetAlpha(0); down:EnableMouse(false) end
    end
    SetSmoothScroll(castbarScrollFrame)
    addonTable.castbar = {}
    local cbar = addonTable.castbar
    local cc = castbarScrollChild
    local COL1, COL2 = 15, 270
    Section(cc, "Player Castbar Settings", -5)
    local y = -30
    local function CastbarSection(txt)
      local l = cc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      l:SetPoint("TOPLEFT", cc, "TOPLEFT", 15, y)
      l:SetText(txt)
      l:SetTextColor(1, 0.82, 0)
      local ln = cc:CreateTexture(nil, "ARTWORK")
      ln:SetHeight(1)
      ln:SetPoint("LEFT", l, "RIGHT", 8, 0)
      ln:SetPoint("RIGHT", cc, "RIGHT", -15, 0)
      ln:SetColorTexture(0.3, 0.3, 0.35, 1)
      ln:SetSnapToPixelGrid(true)
      ln:SetTexelSnappingBias(0)
      y = y - 25
      return l, ln
    end
    local function ColorBtn(label, x, yPos, r, g, b)
      local btn = CreateStyledButton(cc, label, 70, 22)
      btn:SetPoint("TOPLEFT", cc, "TOPLEFT", x, yPos)
      local swatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
      swatch:SetSize(22, 22)
      swatch:SetPoint("LEFT", btn, "RIGHT", 4, 0)
      swatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      swatch:SetBackdropColor(r, g, b, 1)
      swatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      return btn, swatch
    end
    CastbarSection("General")
    cbar.centeredCB = Checkbox(cc, "Center Horizontally", COL1, y)
    local castbarHighlightBtn = CreateHighlightToggle(cc)
    castbarHighlightBtn:ClearAllPoints()
    castbarHighlightBtn:SetPoint("LEFT", cbar.centeredCB.label, "RIGHT", 15, 0)
    y = y - 30
    cbar.widthSlider = Slider(cc, "Bar Width", COL1, y, 50, 500, 250, 1)
    cbar.autoWidthDD, cbar.autoWidthLbl = StyledDropdown(cc, "Auto Width", COL2 + 6, y, 140)
    cbar.autoWidthDD:SetOptions({{text = "Off", value = "off"}, {text = "CBar 1", value = "cbar1"}, {text = "CBar 2", value = "cbar2"}, {text = "CBar 3", value = "cbar3"}, {text = "CBar 4", value = "cbar4"}, {text = "CBar 5", value = "cbar5"}, {text = "Essential Bar", value = "essential"}, {text = "Utility Bar", value = "utility"}, {text = "PRB Health", value = "prbhealth"}, {text = "PRB Power", value = "prbpower"}})
    y = y - 50
    cbar.heightSlider = Slider(cc, "Bar Height", COL1, y, 5, 50, 20, 1)
    y = y - 50
    cbar.xSlider = Slider(cc, "X Offset", COL1, y, -1000, 1000, 0, 1)
    cbar.ySlider = Slider(cc, "Y Offset", COL2 + 6, y, -1000, 1000, -250, 0.5)
    y = y - 50
    cbar.bgAlphaSlider = Slider(cc, "BG Alpha %", COL1, y, 0, 100, 70, 1)
    cbar.borderSlider = Slider(cc, "Border Size", COL2 + 6, y, 0, 5, 1, 1)
    y = y - 50
    cbar.textureDD, cbar.textureLbl = StyledDropdown(cc, "Texture", COL1, y, 140)
    ApplyTextureOptionsToDropdown(cbar.textureDD)
    cbar.bgColorBtn, cbar.bgColorSwatch = ColorBtn("BG Color", COL2 + 6, y - 17, 0.1, 0.1, 0.1)
    y = y - 55
    CastbarSection("Bar Color")
    cbar.useClassColorCB = Checkbox(cc, "Use Class Color", COL1, y)
    cbar.showIconCB = Checkbox(cc, "Show Spell Icon", COL2 + 6, y)
    y = y - 30
    cbar.barColorBtn, cbar.barColorSwatch = ColorBtn("Bar Color", COL1, y, 1, 0.7, 0)
    cbar.textColorBtn, cbar.textColorSwatch = ColorBtn("Text Color", COL1 + 110, y, 1, 1, 1)
    y = y - 55
    CastbarSection("Text Display")
    cbar.showSpellNameCB = Checkbox(cc, "Show Spell Name", COL1, y)
    cbar.showTimeCB = Checkbox(cc, "Show Cast Time", COL2 + 6, y)
    y = y - 30
    cbar.spellNameScaleSlider = Slider(cc, "Name Scale", COL1, y, 0.5, 2, 1, 0.1)
    cbar.timeScaleSlider = Slider(cc, "Time Scale", COL2 + 6, y, 0.5, 2, 1, 0.1)
    y = y - 50
    cbar.spellNameXSlider = Slider(cc, "Name X Offset", COL1, y, -100, 100, 0, 1)
    cbar.spellNameYSlider = Slider(cc, "Name Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    cbar.timeXSlider = Slider(cc, "Time X Offset", COL1, y, -100, 100, 0, 1)
    cbar.timeYSlider = Slider(cc, "Time Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    cbar.timePrecisionDD, cbar.timePrecisionLbl = StyledDropdown(cc, "Time Precision", COL1, y, 100)
    cbar.timePrecisionDD:SetOptions({{text = "0 Decimals", value = "0"}, {text = "1 Decimal", value = "1"}, {text = "2 Decimals", value = "2"}})
    cbar.timeDirectionDD, cbar.timeDirectionLbl = StyledDropdown(cc, "Time Direction", COL2 + 6, y, 130)
    cbar.timeDirectionDD:SetOptions({{text = "Remaining", value = "remaining"}, {text = "Elapsed", value = "elapsed"}})
    y = y - 55
    CastbarSection("Channel Options")
    cbar.showTicksCB = Checkbox(cc, "Show Channel Ticks", COL1, y)
    y = y - 35
    castbarScrollChild:SetHeight(math.abs(y) + 30)
    tab8:SetScript("OnShow", function()
      C_Timer.After(0.05, function()
        if addonTable.LoadCastbarValues then addonTable.LoadCastbarValues() end
      end)
    end)
  end
  local tab9 = tabFrames[9]
  if tab9 then
    local focusCastbarScrollFrame = CreateFrame("ScrollFrame", "CCMFocusCastbarScrollFrame", tab9, "UIPanelScrollFrameTemplate")
    focusCastbarScrollFrame:SetPoint("TOPLEFT", tab9, "TOPLEFT", 0, 0)
    focusCastbarScrollFrame:SetPoint("BOTTOMRIGHT", tab9, "BOTTOMRIGHT", -22, 0)
    local focusCastbarScrollChild = CreateFrame("Frame", "CCMFocusCastbarScrollChild", focusCastbarScrollFrame)
    focusCastbarScrollChild:SetSize(490, 825)
    focusCastbarScrollFrame:SetScrollChild(focusCastbarScrollChild)
    local scrollBar = _G["CCMFocusCastbarScrollFrameScrollBar"]
    if scrollBar then
      scrollBar:SetPoint("TOPLEFT", focusCastbarScrollFrame, "TOPRIGHT", 6, -16)
      scrollBar:SetPoint("BOTTOMLEFT", focusCastbarScrollFrame, "BOTTOMRIGHT", 6, 16)
      local thumb = scrollBar:GetThumbTexture()
      if thumb then thumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb:SetSize(8, 40) end
      local up = _G["CCMFocusCastbarScrollFrameScrollBarScrollUpButton"]
      local down = _G["CCMFocusCastbarScrollFrameScrollBarScrollDownButton"]
      if up then up:SetAlpha(0); up:EnableMouse(false) end
      if down then down:SetAlpha(0); down:EnableMouse(false) end
    end
    SetSmoothScroll(focusCastbarScrollFrame)
    addonTable.focusCastbar = {}
    local cbar = addonTable.focusCastbar
    local cc = focusCastbarScrollChild
    local COL1, COL2 = 15, 270
    Section(cc, "Focus Castbar Settings", -5)
    local y = -30
    local function CastbarSection(txt)
      local l = cc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      l:SetPoint("TOPLEFT", cc, "TOPLEFT", 15, y)
      l:SetText(txt)
      l:SetTextColor(1, 0.82, 0)
      local ln = cc:CreateTexture(nil, "ARTWORK")
      ln:SetHeight(1)
      ln:SetPoint("LEFT", l, "RIGHT", 8, 0)
      ln:SetPoint("RIGHT", cc, "RIGHT", -15, 0)
      ln:SetColorTexture(0.3, 0.3, 0.35, 1)
      ln:SetSnapToPixelGrid(true)
      ln:SetTexelSnappingBias(0)
      y = y - 25
      return l, ln
    end
    local function ColorBtn(label, x, yPos, r, g, b)
      local btn = CreateStyledButton(cc, label, 70, 22)
      btn:SetPoint("TOPLEFT", cc, "TOPLEFT", x, yPos)
      local swatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
      swatch:SetSize(22, 22)
      swatch:SetPoint("LEFT", btn, "RIGHT", 4, 0)
      swatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      swatch:SetBackdropColor(r, g, b, 1)
      swatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      return btn, swatch
    end
    CastbarSection("General")
    cbar.centeredCB = Checkbox(cc, "Center Horizontally", COL1, y)
    local fcastbarHighlightBtn = CreateHighlightToggle(cc)
    fcastbarHighlightBtn:ClearAllPoints()
    fcastbarHighlightBtn:SetPoint("LEFT", cbar.centeredCB.label, "RIGHT", 15, 0)
    y = y - 30
    cbar.widthSlider = Slider(cc, "Bar Width", COL1, y, 50, 500, 250, 1)
    y = y - 50
    cbar.heightSlider = Slider(cc, "Bar Height", COL1, y, 5, 50, 20, 1)
    y = y - 50
    cbar.xSlider = Slider(cc, "X Offset", COL1, y, -1000, 1000, 0, 1)
    cbar.ySlider = Slider(cc, "Y Offset", COL2 + 6, y, -1000, 1000, -250, 0.5)
    y = y - 50
    cbar.bgAlphaSlider = Slider(cc, "BG Alpha %", COL1, y, 0, 100, 70, 1)
    cbar.borderSlider = Slider(cc, "Border Size", COL2 + 6, y, 0, 5, 1, 1)
    y = y - 50
    cbar.textureDD, cbar.textureLbl = StyledDropdown(cc, "Texture", COL1, y, 140)
    ApplyTextureOptionsToDropdown(cbar.textureDD)
    cbar.bgColorBtn, cbar.bgColorSwatch = ColorBtn("BG Color", COL2 + 6, y - 17, 0.1, 0.1, 0.1)
    y = y - 55
    CastbarSection("Bar Color")
    cbar.showIconCB = Checkbox(cc, "Show Spell Icon", COL2 + 6, y)
    y = y - 30
    cbar.barColorBtn, cbar.barColorSwatch = ColorBtn("Bar Color", COL1, y, 1, 0.7, 0)
    cbar.textColorBtn, cbar.textColorSwatch = ColorBtn("Text Color", COL1 + 110, y, 1, 1, 1)
    y = y - 55
    CastbarSection("Text Display")
    cbar.showSpellNameCB = Checkbox(cc, "Show Spell Name", COL1, y)
    cbar.showTimeCB = Checkbox(cc, "Show Cast Time", COL2 + 6, y)
    y = y - 30
    cbar.spellNameScaleSlider = Slider(cc, "Name Scale", COL1, y, 0.5, 2, 1, 0.1)
    cbar.timeScaleSlider = Slider(cc, "Time Scale", COL2 + 6, y, 0.5, 2, 1, 0.1)
    y = y - 50
    cbar.spellNameXSlider = Slider(cc, "Name X Offset", COL1, y, -100, 100, 0, 1)
    cbar.spellNameYSlider = Slider(cc, "Name Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    cbar.timeXSlider = Slider(cc, "Time X Offset", COL1, y, -100, 100, 0, 1)
    cbar.timeYSlider = Slider(cc, "Time Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    cbar.timePrecisionDD, cbar.timePrecisionLbl = StyledDropdown(cc, "Time Precision", COL1, y, 100)
    cbar.timePrecisionDD:SetOptions({{text = "0 Decimals", value = "0"}, {text = "1 Decimal", value = "1"}, {text = "2 Decimals", value = "2"}})
    cbar.timeDirectionDD, cbar.timeDirectionLbl = StyledDropdown(cc, "Time Direction", COL2 + 6, y, 130)
    cbar.timeDirectionDD:SetOptions({{text = "Remaining", value = "remaining"}, {text = "Elapsed", value = "elapsed"}})
    y = y - 55
    CastbarSection("Channel Options")
    cbar.showTicksCB = Checkbox(cc, "Show Channel Ticks", COL1, y)
    y = y - 35
    focusCastbarScrollChild:SetHeight(math.abs(y) + 30)
    tab9:SetScript("OnShow", function()
      C_Timer.After(0.05, function()
        if addonTable.LoadFocusCastbarValues then addonTable.LoadFocusCastbarValues() end
      end)
    end)
  end
  local tab13 = tabFrames[13]
  if tab13 then
    local targetCastbarScrollFrame = CreateFrame("ScrollFrame", "CCMTargetCastbarScrollFrame", tab13, "UIPanelScrollFrameTemplate")
    targetCastbarScrollFrame:SetPoint("TOPLEFT", tab13, "TOPLEFT", 0, 0)
    targetCastbarScrollFrame:SetPoint("BOTTOMRIGHT", tab13, "BOTTOMRIGHT", -22, 0)
    local targetCastbarScrollChild = CreateFrame("Frame", "CCMTargetCastbarScrollChild", targetCastbarScrollFrame)
    targetCastbarScrollChild:SetSize(490, 825)
    targetCastbarScrollFrame:SetScrollChild(targetCastbarScrollChild)
    local scrollBarTC = _G["CCMTargetCastbarScrollFrameScrollBar"]
    if scrollBarTC then
      scrollBarTC:SetPoint("TOPLEFT", targetCastbarScrollFrame, "TOPRIGHT", 6, -16)
      scrollBarTC:SetPoint("BOTTOMLEFT", targetCastbarScrollFrame, "BOTTOMRIGHT", 6, 16)
      local thumbTC = scrollBarTC:GetThumbTexture()
      if thumbTC then thumbTC:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumbTC:SetSize(8, 40) end
      local upTC = _G["CCMTargetCastbarScrollFrameScrollBarScrollUpButton"]
      local downTC = _G["CCMTargetCastbarScrollFrameScrollBarScrollDownButton"]
      if upTC then upTC:SetAlpha(0); upTC:EnableMouse(false) end
      if downTC then downTC:SetAlpha(0); downTC:EnableMouse(false) end
    end
    SetSmoothScroll(targetCastbarScrollFrame)
    addonTable.targetCastbar = {}
    local tcbar = addonTable.targetCastbar
    local tcc = targetCastbarScrollChild
    local COL1, COL2 = 15, 270
    Section(tcc, "Target Castbar Settings", -5)
    local y = -30
    local function TCastbarSection(txt)
      local l = tcc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      l:SetPoint("TOPLEFT", tcc, "TOPLEFT", 15, y)
      l:SetText(txt)
      l:SetTextColor(1, 0.82, 0)
      local ln = tcc:CreateTexture(nil, "ARTWORK")
      ln:SetHeight(1)
      ln:SetPoint("LEFT", l, "RIGHT", 8, 0)
      ln:SetPoint("RIGHT", tcc, "RIGHT", -15, 0)
      ln:SetColorTexture(0.3, 0.3, 0.35, 1)
      ln:SetSnapToPixelGrid(true)
      ln:SetTexelSnappingBias(0)
      y = y - 25
      return l, ln
    end
    local function TCColorBtn(label, x, yPos, r, g, b)
      local btn = CreateStyledButton(tcc, label, 70, 22)
      btn:SetPoint("TOPLEFT", tcc, "TOPLEFT", x, yPos)
      local swatch = CreateFrame("Frame", nil, tcc, "BackdropTemplate")
      swatch:SetSize(22, 22)
      swatch:SetPoint("LEFT", btn, "RIGHT", 4, 0)
      swatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
      swatch:SetBackdropColor(r, g, b, 1)
      swatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      return btn, swatch
    end
    TCastbarSection("General")
    tcbar.centeredCB = Checkbox(tcc, "Center Horizontally", COL1, y)
    local tcastbarHighlightBtn = CreateHighlightToggle(tcc)
    tcastbarHighlightBtn:ClearAllPoints()
    tcastbarHighlightBtn:SetPoint("LEFT", tcbar.centeredCB.label, "RIGHT", 15, 0)
    y = y - 30
    tcbar.widthSlider = Slider(tcc, "Bar Width", COL1, y, 50, 500, 250, 1)
    y = y - 50
    tcbar.heightSlider = Slider(tcc, "Bar Height", COL1, y, 5, 50, 20, 1)
    y = y - 50
    tcbar.xSlider = Slider(tcc, "X Offset", COL1, y, -1000, 1000, 0, 1)
    tcbar.ySlider = Slider(tcc, "Y Offset", COL2 + 6, y, -1000, 1000, -250, 0.5)
    y = y - 50
    tcbar.bgAlphaSlider = Slider(tcc, "BG Alpha %", COL1, y, 0, 100, 70, 1)
    tcbar.borderSlider = Slider(tcc, "Border Size", COL2 + 6, y, 0, 5, 1, 1)
    y = y - 50
    tcbar.textureDD, tcbar.textureLbl = StyledDropdown(tcc, "Texture", COL1, y, 140)
    ApplyTextureOptionsToDropdown(tcbar.textureDD)
    tcbar.bgColorBtn, tcbar.bgColorSwatch = TCColorBtn("BG Color", COL2 + 6, y - 17, 0.1, 0.1, 0.1)
    y = y - 55
    TCastbarSection("Bar Color")
    tcbar.showIconCB = Checkbox(tcc, "Show Spell Icon", COL2 + 6, y)
    y = y - 30
    tcbar.barColorBtn, tcbar.barColorSwatch = TCColorBtn("Bar Color", COL1, y, 1, 0.7, 0)
    tcbar.textColorBtn, tcbar.textColorSwatch = TCColorBtn("Text Color", COL1 + 110, y, 1, 1, 1)
    y = y - 55
    TCastbarSection("Text Display")
    tcbar.showSpellNameCB = Checkbox(tcc, "Show Spell Name", COL1, y)
    tcbar.showTimeCB = Checkbox(tcc, "Show Cast Time", COL2 + 6, y)
    y = y - 30
    tcbar.spellNameScaleSlider = Slider(tcc, "Name Scale", COL1, y, 0.5, 2, 1, 0.1)
    tcbar.timeScaleSlider = Slider(tcc, "Time Scale", COL2 + 6, y, 0.5, 2, 1, 0.1)
    y = y - 50
    tcbar.spellNameXSlider = Slider(tcc, "Name X Offset", COL1, y, -100, 100, 0, 1)
    tcbar.spellNameYSlider = Slider(tcc, "Name Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    tcbar.timeXSlider = Slider(tcc, "Time X Offset", COL1, y, -100, 100, 0, 1)
    tcbar.timeYSlider = Slider(tcc, "Time Y Offset", COL2 + 6, y, -50, 50, 0, 1)
    y = y - 50
    tcbar.timePrecisionDD, tcbar.timePrecisionLbl = StyledDropdown(tcc, "Time Precision", COL1, y, 100)
    tcbar.timePrecisionDD:SetOptions({{text = "0 Decimals", value = "0"}, {text = "1 Decimal", value = "1"}, {text = "2 Decimals", value = "2"}})
    tcbar.timeDirectionDD, tcbar.timeDirectionLbl = StyledDropdown(tcc, "Time Direction", COL2 + 6, y, 130)
    tcbar.timeDirectionDD:SetOptions({{text = "Remaining", value = "remaining"}, {text = "Elapsed", value = "elapsed"}})
    y = y - 55
    TCastbarSection("Channel Options")
    tcbar.showTicksCB = Checkbox(tcc, "Show Channel Ticks", COL1, y)
    y = y - 35
    targetCastbarScrollChild:SetHeight(math.abs(y) + 30)
    tab13:SetScript("OnShow", function()
      C_Timer.After(0.05, function()
        if addonTable.LoadTargetCastbarValues then addonTable.LoadTargetCastbarValues() end
      end)
    end)
  end
  local tab10 = tabFrames[10]
  if tab10 then
    local debuffsScrollFrame = CreateFrame("ScrollFrame", "CCMDebuffsScrollFrame", tab10, "UIPanelScrollFrameTemplate")
    debuffsScrollFrame:SetPoint("TOPLEFT", tab10, "TOPLEFT", 0, 0)
    debuffsScrollFrame:SetPoint("BOTTOMRIGHT", tab10, "BOTTOMRIGHT", -22, 0)
    local debuffsScrollChild = CreateFrame("Frame", "CCMDebuffsScrollChild", debuffsScrollFrame)
    debuffsScrollChild:SetSize(490, 400)
    debuffsScrollFrame:SetScrollChild(debuffsScrollChild)
    local scrollBar9 = _G["CCMDebuffsScrollFrameScrollBar"]
    if scrollBar9 then
      scrollBar9:SetPoint("TOPLEFT", debuffsScrollFrame, "TOPRIGHT", 6, -16)
      scrollBar9:SetPoint("BOTTOMLEFT", debuffsScrollFrame, "BOTTOMRIGHT", 6, 16)
      local thumb9 = scrollBar9:GetThumbTexture()
      if thumb9 then thumb9:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb9:SetSize(8, 40) end
      local up9 = _G["CCMDebuffsScrollFrameScrollBarScrollUpButton"]
      local down9 = _G["CCMDebuffsScrollFrameScrollBarScrollDownButton"]
      if up9 then up9:SetAlpha(0); up9:EnableMouse(false) end
      if down9 then down9:SetAlpha(0); down9:EnableMouse(false) end
    end
    SetSmoothScroll(debuffsScrollFrame)
    local dc = debuffsScrollChild
    local debuffsHighlightBtn = CreateHighlightToggle(dc)
    debuffsHighlightBtn:ClearAllPoints()
    debuffsHighlightBtn:SetPoint("TOPRIGHT", dc, "TOPRIGHT", -15, -12)
    addonTable.debuffs = {}
    local db = addonTable.debuffs
    local dbSec = Section(dc, "Player Debuffs Skinning", -12, -230)
    db.sizeSlider = Slider(dc, "Icon Size", 15, -52, 16, 100, 32, 1)
    db.sizeSlider.label:ClearAllPoints()
    db.sizeSlider.label:SetPoint("TOPLEFT", dbSec, "BOTTOMLEFT", 0, -25)
    db.sizeSlider:ClearAllPoints()
    db.sizeSlider:SetPoint("TOPLEFT", db.sizeSlider.label, "BOTTOMLEFT", 0, -8)
    db.spacingSlider = Slider(dc, "Spacing", 280, -52, 0, 20, 2, 1)
    db.spacingSlider.label:ClearAllPoints()
    db.spacingSlider.label:SetPoint("TOPLEFT", db.sizeSlider.label, "TOPLEFT", 265, 0)
    db.spacingSlider:ClearAllPoints()
    db.spacingSlider:SetPoint("TOPLEFT", db.spacingSlider.label, "BOTTOMLEFT", 0, -8)
    db.xSlider = Slider(dc, "X Offset", 15, -107, -1000, 1000, 0, 1)
    db.xSlider.label:ClearAllPoints()
    db.xSlider.label:SetPoint("TOPLEFT", db.sizeSlider, "BOTTOMLEFT", 0, -25)
    db.xSlider:ClearAllPoints()
    db.xSlider:SetPoint("TOPLEFT", db.xSlider.label, "BOTTOMLEFT", 0, -8)
    db.ySlider = Slider(dc, "Y Offset", 280, -107, -1000, 1000, 0, 1)
    db.ySlider.label:ClearAllPoints()
    db.ySlider.label:SetPoint("TOPLEFT", db.spacingSlider, "BOTTOMLEFT", 0, -25)
    db.ySlider:ClearAllPoints()
    db.ySlider:SetPoint("TOPLEFT", db.ySlider.label, "BOTTOMLEFT", 0, -8)
    db.iconsPerRowSlider = Slider(dc, "Icons Per Row", 15, -162, 1, 20, 10, 1)
    db.iconsPerRowSlider.label:ClearAllPoints()
    db.iconsPerRowSlider.label:SetPoint("TOPLEFT", db.xSlider, "BOTTOMLEFT", 0, -25)
    db.iconsPerRowSlider:ClearAllPoints()
    db.iconsPerRowSlider:SetPoint("TOPLEFT", db.iconsPerRowSlider.label, "BOTTOMLEFT", 0, -8)
    db.borderSizeSlider = Slider(dc, "Border Size", 280, -155, 0, 5, 1, 1)
    db.borderSizeSlider.label:ClearAllPoints()
    db.borderSizeSlider.label:SetPoint("TOPLEFT", db.ySlider, "BOTTOMLEFT", 0, -25)
    db.borderSizeSlider:ClearAllPoints()
    db.borderSizeSlider:SetPoint("TOPLEFT", db.borderSizeSlider.label, "BOTTOMLEFT", 0, -8)
    db.sortDirectionDD, db.sortDirectionLbl = StyledDropdown(dc, "Sort Direction", 15, -217, 120)
    db.sortDirectionDD:ClearAllPoints()
    db.sortDirectionDD:SetPoint("TOPLEFT", db.iconsPerRowSlider, "BOTTOMLEFT", 0, -35)
    if db.sortDirectionLbl then db.sortDirectionLbl:ClearAllPoints(); db.sortDirectionLbl:SetPoint("BOTTOMLEFT", db.sortDirectionDD, "TOPLEFT", 0, 4) end
    db.sortDirectionDD:SetOptions({{text = "Left to Right", value = "right"}, {text = "Right to Left", value = "left"}})
    db.growDirectionDD, db.growDirectionLbl = StyledDropdown(dc, "Row Growth", 280, -217, 120)
    db.growDirectionDD:ClearAllPoints()
    db.growDirectionDD:SetPoint("TOPLEFT", db.borderSizeSlider, "BOTTOMLEFT", 0, -35)
    if db.growDirectionLbl then db.growDirectionLbl:ClearAllPoints(); db.growDirectionLbl:SetPoint("BOTTOMLEFT", db.growDirectionDD, "TOPLEFT", 0, 4) end
    db.growDirectionDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
    debuffsScrollChild:SetSize(490, 280)
    tab10:SetScript("OnShow", function()
      C_Timer.After(0.05, function()
        if addonTable.LoadPlayerDebuffsValues then addonTable.LoadPlayerDebuffsValues() end
      end)
    end)
  end
  local tab11 = tabFrames[11]
  if tab11 then
    local ufScrollFrame = CreateFrame("ScrollFrame", "CCMUFScrollFrame", tab11, "UIPanelScrollFrameTemplate")
    ufScrollFrame:SetPoint("TOPLEFT", tab11, "TOPLEFT", 0, 0)
    ufScrollFrame:SetPoint("BOTTOMRIGHT", tab11, "BOTTOMRIGHT", -22, 0)
    local ufScrollChild = CreateFrame("Frame", "CCMUFScrollChild", ufScrollFrame)
    ufScrollChild:SetSize(490, 1325)
    ufScrollFrame:SetScrollChild(ufScrollChild)
    local ufScrollBar = _G["CCMUFScrollFrameScrollBar"]
    if ufScrollBar then
      ufScrollBar:SetPoint("TOPLEFT", ufScrollFrame, "TOPRIGHT", 6, -16)
      ufScrollBar:SetPoint("BOTTOMLEFT", ufScrollFrame, "BOTTOMRIGHT", 6, 16)
      local ufThumb = ufScrollBar:GetThumbTexture()
      if ufThumb then ufThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); ufThumb:SetSize(8, 40) end
      local ufUp = _G["CCMUFScrollFrameScrollBarScrollUpButton"]
      local ufDown = _G["CCMUFScrollFrameScrollBarScrollDownButton"]
      if ufUp then ufUp:SetAlpha(0); ufUp:EnableMouse(false) end
      if ufDown then ufDown:SetAlpha(0); ufDown:EnableMouse(false) end
    end
    SetSmoothScroll(ufScrollFrame)
    local uc = ufScrollChild
    local ufMainSec = Section(uc, "Unit Frame Customization", -12)
    addonTable.useCustomBorderColorCB = Checkbox(uc, "Custom Border Color", 15, -37)
    addonTable.useCustomBorderColorCB:ClearAllPoints()
    addonTable.useCustomBorderColorCB:SetPoint("TOPLEFT", ufMainSec, "BOTTOMLEFT", 0, -12)
    addonTable.ufClassColorCB = Checkbox(uc, "Use class color", 280, -37)
    addonTable.ufClassColorCB:ClearAllPoints()
    addonTable.ufClassColorCB:SetPoint("TOPLEFT", ufMainSec, "BOTTOMLEFT", 265, -12)
    addonTable.ufDisableGlowsCB = Checkbox(uc, "Disable Frame Glows", 15, -62)
    addonTable.ufDisableGlowsCB:ClearAllPoints()
    addonTable.ufDisableGlowsCB:SetPoint("TOPLEFT", addonTable.useCustomBorderColorCB, "BOTTOMLEFT", 0, -3)
    addonTable.ufUseCustomTexturesCB = Checkbox(uc, "Use Custom Textures", 280, -62)
    addonTable.ufUseCustomTexturesCB:ClearAllPoints()
    addonTable.ufUseCustomTexturesCB:SetPoint("TOPLEFT", addonTable.ufClassColorCB, "BOTTOMLEFT", 0, -3)
    addonTable.disableTargetBuffsCB = Checkbox(uc, "Disable Target Buffs", 15, -87)
    addonTable.disableTargetBuffsCB:ClearAllPoints()
    addonTable.disableTargetBuffsCB:SetPoint("TOPLEFT", addonTable.ufDisableGlowsCB, "BOTTOMLEFT", 0, -3)
    addonTable.hideEliteTextureCB = Checkbox(uc, "Hide Elite Texture", 280, -87)
    addonTable.hideEliteTextureCB:ClearAllPoints()
    addonTable.hideEliteTextureCB:SetPoint("TOPLEFT", addonTable.ufUseCustomTexturesCB, "BOTTOMLEFT", 0, -3)
    addonTable.ufDisableCombatTextCB = Checkbox(uc, "Disable Player Combat Text", 15, -112)
    addonTable.ufDisableCombatTextCB:ClearAllPoints()
    addonTable.ufDisableCombatTextCB:SetPoint("TOPLEFT", addonTable.disableTargetBuffsCB, "BOTTOMLEFT", 0, -3)
    addonTable.ufUseCustomNameColorCB = Checkbox(uc, "Use Custom Name Color", 280, -112)
    addonTable.ufUseCustomNameColorCB:ClearAllPoints()
    addonTable.ufUseCustomNameColorCB:SetPoint("TOPLEFT", addonTable.hideEliteTextureCB, "BOTTOMLEFT", 0, -3)
    addonTable.ufHideGroupIndicatorCB = Checkbox(uc, "Hide Group Indicator", 15, -137)
    addonTable.ufHideGroupIndicatorCB:ClearAllPoints()
    addonTable.ufHideGroupIndicatorCB:SetPoint("TOPLEFT", addonTable.ufDisableCombatTextCB, "BOTTOMLEFT", 0, -3)
    addonTable.ufBorderColorBtn = CreateStyledButton(uc, "Border Color", 100, 22)
    addonTable.ufBorderColorBtn:SetPoint("TOPLEFT", addonTable.ufHideGroupIndicatorCB, "BOTTOMLEFT", 0, -12)
    addonTable.ufBorderColorSwatch = CreateFrame("Frame", nil, uc, "BackdropTemplate")
    addonTable.ufBorderColorSwatch:SetSize(22, 22)
    addonTable.ufBorderColorSwatch:SetPoint("LEFT", addonTable.ufBorderColorBtn, "RIGHT", 4, 0)
    addonTable.ufBorderColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.ufBorderColorSwatch:SetBackdropColor(0, 0, 0, 1)
    addonTable.ufBorderColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.ufHealthTextureDD = StyledDropdown(uc, nil, 280, -172, 115)
    ApplyTextureOptionsToDropdown(addonTable.ufHealthTextureDD)
    addonTable.ufHealthTextureDD:SetEnabled(true)
    addonTable.ufHealthTextureLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufHealthTextureLbl:SetPoint("BOTTOMLEFT", addonTable.ufHealthTextureDD, "TOPLEFT", 0, 4)
    addonTable.ufHealthTextureLbl:SetText("Texture")
    addonTable.ufHealthTextureLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufNameColorBtn = CreateStyledButton(uc, "Name Color", 90, 22)
    addonTable.ufNameColorBtn:SetPoint("LEFT", addonTable.ufHealthTextureDD, "RIGHT", 10, 0)

    addonTable.ufNameColorSwatch = CreateFrame("Frame", nil, uc, "BackdropTemplate")
    addonTable.ufNameColorSwatch:SetSize(22, 22)
    addonTable.ufNameColorSwatch:SetPoint("LEFT", addonTable.ufNameColorBtn, "RIGHT", 4, 0)
    addonTable.ufNameColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.ufNameColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.ufNameColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

    local ufBigHBSec = Section(uc, "Use Bigger Healthbars", -215)
    addonTable.ufBigHBPlayerCB = Checkbox(uc, "Player", 15, -240)
    addonTable.ufBigHBPlayerCB:ClearAllPoints()
    addonTable.ufBigHBPlayerCB:SetPoint("TOPLEFT", ufBigHBSec, "BOTTOMLEFT", 0, -12)
    addonTable.ufBigHBTargetCB = Checkbox(uc, "Target", 90, -240)
    addonTable.ufBigHBTargetCB:ClearAllPoints()
    addonTable.ufBigHBTargetCB:SetPoint("LEFT", addonTable.ufBigHBPlayerCB.label, "RIGHT", 15, 0)
    addonTable.ufBigHBFocusCB = Checkbox(uc, "Focus", 165, -240)
    addonTable.ufBigHBFocusCB:ClearAllPoints()
    addonTable.ufBigHBFocusCB:SetPoint("LEFT", addonTable.ufBigHBTargetCB.label, "RIGHT", 15, 0)
    addonTable.ufBigHBHideRealmCB = Checkbox(uc, "Hide Realm", 240, -240)
    addonTable.ufBigHBHideRealmCB:ClearAllPoints()
    addonTable.ufBigHBHideRealmCB:SetPoint("LEFT", addonTable.ufBigHBFocusCB.label, "RIGHT", 15, 0)

    local UF_BIG_SECTION_START_Y = -267
    local UF_BIG_SECTION_STEP_Y = 320
    local UF_BIG_COL1_X = 15
    local UF_BIG_COL2_X = 175
    local UF_BIG_COL3_X = 335
    local UF_BIG_DD_W = 140
    local UF_BIG_STRIPE_X = UF_BIG_COL3_X + UF_BIG_DD_W + 8
    local UF_BIG_ROW1_OFF = -30
    local UF_BIG_ROW2_OFF = -82
    local UF_BIG_STRIPE_OFF = UF_BIG_ROW2_OFF - 16
    local UF_BIG_SLIDER1_OFF = -145
    local UF_BIG_SLIDER2_OFF = -205
    local UF_BIG_SLIDER3_OFF = -265
    local playerSecY = UF_BIG_SECTION_START_Y
    local targetSecY = playerSecY - UF_BIG_SECTION_STEP_Y
    local focusSecY = targetSecY - UF_BIG_SECTION_STEP_Y
    local trimSecY = focusSecY - UF_BIG_SECTION_STEP_Y

    Section(uc, "Player", playerSecY)
    addonTable.ufBigHBHidePlayerNameCB = Checkbox(uc, "Hide Name", UF_BIG_COL1_X, playerSecY + UF_BIG_ROW1_OFF)
    addonTable.ufBigHBPlayerNameAnchorDD = StyledDropdown(uc, nil, UF_BIG_COL2_X, playerSecY + UF_BIG_ROW1_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBPlayerNameAnchorDD:SetOptions({{text = "Left", value = "left"}, {text = "Center", value = "center"}, {text = "Right", value = "right"}})
    addonTable.ufBigHBPlayerNameAnchorLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufBigHBPlayerNameAnchorLbl:SetPoint("BOTTOMLEFT", addonTable.ufBigHBPlayerNameAnchorDD, "TOPLEFT", 0, 4)
    addonTable.ufBigHBPlayerNameAnchorLbl:SetText("Name Anchor")
    addonTable.ufBigHBPlayerNameAnchorLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufBigHBPlayerLevelDD = StyledDropdown(uc, nil, UF_BIG_COL3_X, playerSecY + UF_BIG_ROW1_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBPlayerLevelDD:SetOptions({{text = "Level: Always", value = "always"}, {text = "Level: Hide", value = "hide"}, {text = "Level: Hide Max", value = "hidemax"}})
    addonTable.ufBigHBPlayerLevelLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufBigHBPlayerLevelLbl:SetPoint("BOTTOMLEFT", addonTable.ufBigHBPlayerLevelDD, "TOPLEFT", 0, 4)
    addonTable.ufBigHBPlayerLevelLbl:SetText("Level")
    addonTable.ufBigHBPlayerLevelLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufBigHBPlayerHealAbsorbDD = StyledDropdown(uc, "Heal Absorb", UF_BIG_COL1_X, playerSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBPlayerHealAbsorbDD:SetOptions({{text = "On", value = "on"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBPlayerDmgAbsorbDD = StyledDropdown(uc, "Absorb Shield", UF_BIG_COL2_X, playerSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBPlayerDmgAbsorbDD:SetOptions({{text = "Bar + Glow", value = "bar_glow"}, {text = "Bar Only", value = "bar"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBPlayerHealPredDD = StyledDropdown(uc, "Heal Prediction", UF_BIG_COL3_X, playerSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBPlayerHealPredDD:SetOptions({{text = "On", value = "on"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBPlayerAbsorbStripesCB = Checkbox(uc, "Absorb Stripes", UF_BIG_STRIPE_X, playerSecY + UF_BIG_STRIPE_OFF)
    addonTable.ufBigHBPlayerNameXSlider = Slider(uc, "Name X", UF_BIG_COL1_X, playerSecY + UF_BIG_SLIDER1_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBPlayerNameYSlider = Slider(uc, "Name Y", 280, playerSecY + UF_BIG_SLIDER1_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBPlayerLevelXSlider = Slider(uc, "Level X", UF_BIG_COL1_X, playerSecY + UF_BIG_SLIDER2_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBPlayerLevelYSlider = Slider(uc, "Level Y", 280, playerSecY + UF_BIG_SLIDER2_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBPlayerNameTextScaleSlider = Slider(uc, "Name Text Scale", UF_BIG_COL1_X, playerSecY + UF_BIG_SLIDER3_OFF, 0.50, 3.00, 1.00, 0.05)
    addonTable.ufBigHBPlayerLevelTextScaleSlider = Slider(uc, "Level Text Scale", 280, playerSecY + UF_BIG_SLIDER3_OFF, 0.50, 3.00, 1.00, 0.05)

    Section(uc, "Target", targetSecY)
    addonTable.ufBigHBHideTargetNameCB = Checkbox(uc, "Hide Name", UF_BIG_COL1_X, targetSecY + UF_BIG_ROW1_OFF)
    addonTable.ufBigHBTargetNameAnchorDD = StyledDropdown(uc, nil, UF_BIG_COL2_X, targetSecY + UF_BIG_ROW1_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBTargetNameAnchorDD:SetOptions({{text = "Left", value = "left"}, {text = "Center", value = "center"}, {text = "Right", value = "right"}})
    addonTable.ufBigHBTargetNameAnchorLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufBigHBTargetNameAnchorLbl:SetPoint("BOTTOMLEFT", addonTable.ufBigHBTargetNameAnchorDD, "TOPLEFT", 0, 4)
    addonTable.ufBigHBTargetNameAnchorLbl:SetText("Name Anchor")
    addonTable.ufBigHBTargetNameAnchorLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufBigHBTargetLevelDD = StyledDropdown(uc, nil, UF_BIG_COL3_X, targetSecY + UF_BIG_ROW1_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBTargetLevelDD:SetOptions({{text = "Always", value = "always"}, {text = "Hide", value = "hide"}, {text = "Hide Max", value = "hidemax"}})
    addonTable.ufBigHBTargetLevelLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufBigHBTargetLevelLbl:SetPoint("BOTTOMLEFT", addonTable.ufBigHBTargetLevelDD, "TOPLEFT", 0, 4)
    addonTable.ufBigHBTargetLevelLbl:SetText("Level")
    addonTable.ufBigHBTargetLevelLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufBigHBTargetHealAbsorbDD = StyledDropdown(uc, "Heal Absorb", UF_BIG_COL1_X, targetSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBTargetHealAbsorbDD:SetOptions({{text = "On", value = "on"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBTargetDmgAbsorbDD = StyledDropdown(uc, "Absorb Shield", UF_BIG_COL2_X, targetSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBTargetDmgAbsorbDD:SetOptions({{text = "Bar + Glow", value = "bar_glow"}, {text = "Bar Only", value = "bar"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBTargetHealPredDD = StyledDropdown(uc, "Heal Prediction", UF_BIG_COL3_X, targetSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBTargetHealPredDD:SetOptions({{text = "On", value = "on"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBTargetAbsorbStripesCB = Checkbox(uc, "Absorb Stripes", UF_BIG_STRIPE_X, targetSecY + UF_BIG_STRIPE_OFF)
    addonTable.ufBigHBTargetNameXSlider = Slider(uc, "Name X", UF_BIG_COL1_X, targetSecY + UF_BIG_SLIDER1_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBTargetNameYSlider = Slider(uc, "Name Y", 280, targetSecY + UF_BIG_SLIDER1_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBTargetLevelXSlider = Slider(uc, "Level X", UF_BIG_COL1_X, targetSecY + UF_BIG_SLIDER2_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBTargetLevelYSlider = Slider(uc, "Level Y", 280, targetSecY + UF_BIG_SLIDER2_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBTargetNameTextScaleSlider = Slider(uc, "Name Text Scale", UF_BIG_COL1_X, targetSecY + UF_BIG_SLIDER3_OFF, 0.50, 3.00, 1.00, 0.05)
    addonTable.ufBigHBTargetLevelTextScaleSlider = Slider(uc, "Level Text Scale", 280, targetSecY + UF_BIG_SLIDER3_OFF, 0.50, 3.00, 1.00, 0.05)

    Section(uc, "Focus", focusSecY)
    addonTable.ufBigHBHideFocusNameCB = Checkbox(uc, "Hide Name", UF_BIG_COL1_X, focusSecY + UF_BIG_ROW1_OFF)
    addonTable.ufBigHBFocusNameAnchorDD = StyledDropdown(uc, nil, UF_BIG_COL2_X, focusSecY + UF_BIG_ROW1_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBFocusNameAnchorDD:SetOptions({{text = "Left", value = "left"}, {text = "Center", value = "center"}, {text = "Right", value = "right"}})
    addonTable.ufBigHBFocusNameAnchorLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufBigHBFocusNameAnchorLbl:SetPoint("BOTTOMLEFT", addonTable.ufBigHBFocusNameAnchorDD, "TOPLEFT", 0, 4)
    addonTable.ufBigHBFocusNameAnchorLbl:SetText("Name Anchor")
    addonTable.ufBigHBFocusNameAnchorLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufBigHBFocusLevelDD = StyledDropdown(uc, nil, UF_BIG_COL3_X, focusSecY + UF_BIG_ROW1_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBFocusLevelDD:SetOptions({{text = "Level: Always", value = "always"}, {text = "Level: Hide", value = "hide"}, {text = "Level: Hide Max", value = "hidemax"}})
    addonTable.ufBigHBFocusLevelLbl = uc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.ufBigHBFocusLevelLbl:SetPoint("BOTTOMLEFT", addonTable.ufBigHBFocusLevelDD, "TOPLEFT", 0, 4)
    addonTable.ufBigHBFocusLevelLbl:SetText("Level")
    addonTable.ufBigHBFocusLevelLbl:SetTextColor(0.9, 0.9, 0.9)
    addonTable.ufBigHBFocusHealAbsorbDD = StyledDropdown(uc, "Heal Absorb", UF_BIG_COL1_X, focusSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBFocusHealAbsorbDD:SetOptions({{text = "On", value = "on"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBFocusDmgAbsorbDD = StyledDropdown(uc, "Absorb Shield", UF_BIG_COL2_X, focusSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBFocusDmgAbsorbDD:SetOptions({{text = "Bar + Glow", value = "bar_glow"}, {text = "Bar Only", value = "bar"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBFocusHealPredDD = StyledDropdown(uc, "Heal Prediction", UF_BIG_COL3_X, focusSecY + UF_BIG_ROW2_OFF, UF_BIG_DD_W)
    addonTable.ufBigHBFocusHealPredDD:SetOptions({{text = "On", value = "on"}, {text = "Off", value = "off"}})
    addonTable.ufBigHBFocusAbsorbStripesCB = Checkbox(uc, "Absorb Stripes", UF_BIG_STRIPE_X, focusSecY + UF_BIG_STRIPE_OFF)
    addonTable.ufBigHBFocusNameXSlider = Slider(uc, "Name X", UF_BIG_COL1_X, focusSecY + UF_BIG_SLIDER1_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBFocusNameYSlider = Slider(uc, "Name Y", 280, focusSecY + UF_BIG_SLIDER1_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBFocusLevelXSlider = Slider(uc, "Level X", UF_BIG_COL1_X, focusSecY + UF_BIG_SLIDER2_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBFocusLevelYSlider = Slider(uc, "Level Y", 280, focusSecY + UF_BIG_SLIDER2_OFF, -200, 200, 0, 1)
    addonTable.ufBigHBFocusNameTextScaleSlider = Slider(uc, "Name Text Scale", UF_BIG_COL1_X, focusSecY + UF_BIG_SLIDER3_OFF, 0.50, 3.00, 1.00, 0.05)
    addonTable.ufBigHBFocusLevelTextScaleSlider = Slider(uc, "Level Text Scale", 280, focusSecY + UF_BIG_SLIDER3_OFF, 0.50, 3.00, 1.00, 0.05)

    Section(uc, "Name Trim", trimSecY)
    addonTable.ufBigHBNameMaxCharsSlider = Slider(uc, "Name Max Chars (0=Off)", 15, trimSecY + UF_BIG_ROW1_OFF, 0, 40, 0, 1)

  end

  local tab12 = tabFrames[12]
  if tab12 then
    local alertSF = CreateFrame("ScrollFrame", "CCMAlertScrollFrame", tab12, "UIPanelScrollFrameTemplate")
    alertSF:SetPoint("TOPLEFT", tab12, "TOPLEFT", 0, 0)
    alertSF:SetPoint("BOTTOMRIGHT", tab12, "BOTTOMRIGHT", -22, 0)
    local alertSC = CreateFrame("Frame", "CCMAlertScrollChild", alertSF)
    alertSC:SetSize(490, 680)
    alertSF:SetScrollChild(alertSC)
    local alertBar = _G["CCMAlertScrollFrameScrollBar"]
    if alertBar then
      alertBar:SetPoint("TOPLEFT", alertSF, "TOPRIGHT", 6, -16)
      alertBar:SetPoint("BOTTOMLEFT", alertSF, "BOTTOMRIGHT", 6, 16)
      local alertThumb = alertBar:GetThumbTexture()
      if alertThumb then alertThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); alertThumb:SetSize(8, 40) end
      local alertUp = _G["CCMAlertScrollFrameScrollBarScrollUpButton"]
      local alertDown = _G["CCMAlertScrollFrameScrollBarScrollDownButton"]
      if alertUp then alertUp:SetAlpha(0); alertUp:EnableMouse(false) end
      if alertDown then alertDown:SetAlpha(0); alertDown:EnableMouse(false) end
    end
    SetSmoothScroll(alertSF)
    local ac = alertSC
    local alertNoTargetSec = Section(ac, "No Target Alert", -12)
    addonTable.noTargetAlertCB = Checkbox(ac, "Enable No Target Alert", 15, -37)
    addonTable.noTargetAlertCB:ClearAllPoints()
    addonTable.noTargetAlertCB:SetPoint("TOPLEFT", alertNoTargetSec, "BOTTOMLEFT", 0, -12)
    addonTable.noTargetAlertFlashCB = Checkbox(ac, "Flash Text", 220, -37)
    addonTable.noTargetAlertFlashCB:ClearAllPoints()
    addonTable.noTargetAlertFlashCB:SetPoint("LEFT", addonTable.noTargetAlertCB.label, "RIGHT", 15, 0)
    addonTable.noTargetAlertFlashCB:SetEnabled(false)
    addonTable.noTargetAlertPreviewOnBtn = CreateStyledButton(ac, "Show Preview", 90, 22)
    addonTable.noTargetAlertPreviewOnBtn:SetPoint("LEFT", addonTable.noTargetAlertFlashCB.label, "RIGHT", 15, 0)
    addonTable.noTargetAlertPreviewOffBtn = CreateStyledButton(ac, "Hide Preview", 90, 22)
    addonTable.noTargetAlertPreviewOffBtn:SetPoint("LEFT", addonTable.noTargetAlertPreviewOnBtn, "RIGHT", 5, 0)
    addonTable.noTargetAlertXSlider = Slider(ac, "X Offset", 15, -77, -500, 500, 0, 1)
    addonTable.noTargetAlertXSlider.label:ClearAllPoints()
    addonTable.noTargetAlertXSlider.label:SetPoint("TOPLEFT", addonTable.noTargetAlertCB, "BOTTOMLEFT", 0, -18)
    addonTable.noTargetAlertXSlider:ClearAllPoints()
    addonTable.noTargetAlertXSlider:SetPoint("TOPLEFT", addonTable.noTargetAlertXSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.noTargetAlertXSlider:SetEnabled(false)
    addonTable.noTargetAlertYSlider = Slider(ac, "Y Offset", 280, -77, -500, 500, 100, 1)
    addonTable.noTargetAlertYSlider.label:ClearAllPoints()
    addonTable.noTargetAlertYSlider.label:SetPoint("TOPLEFT", addonTable.noTargetAlertXSlider.label, "TOPLEFT", 265, 0)
    addonTable.noTargetAlertYSlider:ClearAllPoints()
    addonTable.noTargetAlertYSlider:SetPoint("TOPLEFT", addonTable.noTargetAlertYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.noTargetAlertYSlider:SetEnabled(false)
    addonTable.noTargetAlertFontSizeSlider = Slider(ac, "Font Size", 15, -132, 12, 72, 36, 1)
    addonTable.noTargetAlertFontSizeSlider.label:ClearAllPoints()
    addonTable.noTargetAlertFontSizeSlider.label:SetPoint("TOPLEFT", addonTable.noTargetAlertXSlider, "BOTTOMLEFT", 0, -25)
    addonTable.noTargetAlertFontSizeSlider:ClearAllPoints()
    addonTable.noTargetAlertFontSizeSlider:SetPoint("TOPLEFT", addonTable.noTargetAlertFontSizeSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.noTargetAlertFontSizeSlider:SetEnabled(false)
    addonTable.noTargetAlertColorBtn = CreateStyledButton(ac, "Color", 60, 22)
    addonTable.noTargetAlertColorBtn:SetPoint("TOPLEFT", addonTable.noTargetAlertFontSizeSlider, "TOPRIGHT", 85, 3)
    addonTable.noTargetAlertColorBtn:SetEnabled(false)
    addonTable.noTargetAlertColorSwatch = CreateFrame("Frame", nil, ac, "BackdropTemplate")
    addonTable.noTargetAlertColorSwatch:SetSize(22, 22)
    addonTable.noTargetAlertColorSwatch:SetPoint("LEFT", addonTable.noTargetAlertColorBtn, "RIGHT", 4, 0)
    addonTable.noTargetAlertColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.noTargetAlertColorSwatch:SetBackdropColor(1, 0, 0, 1)
    addonTable.noTargetAlertColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    local alertLowHealthSec = Section(ac, "Low Health Warning", -204)
    addonTable.lowHealthWarningCB = Checkbox(ac, "Enable Low Health Warning", 15, -229)
    addonTable.lowHealthWarningCB:ClearAllPoints()
    addonTable.lowHealthWarningCB:SetPoint("TOPLEFT", alertLowHealthSec, "BOTTOMLEFT", 0, -12)
    addonTable.lowHealthWarningFlashCB = Checkbox(ac, "Flash Text", 220, -229)
    addonTable.lowHealthWarningFlashCB:ClearAllPoints()
    addonTable.lowHealthWarningFlashCB:SetPoint("LEFT", addonTable.lowHealthWarningCB.label, "RIGHT", 15, 0)
    addonTable.lowHealthWarningFlashCB:SetEnabled(false)
    addonTable.lowHealthWarningPreviewOnBtn = CreateStyledButton(ac, "Show Preview", 90, 22)
    addonTable.lowHealthWarningPreviewOnBtn:SetPoint("LEFT", addonTable.lowHealthWarningFlashCB.label, "RIGHT", 15, 0)
    addonTable.lowHealthWarningPreviewOffBtn = CreateStyledButton(ac, "Hide Preview", 90, 22)
    addonTable.lowHealthWarningPreviewOffBtn:SetPoint("LEFT", addonTable.lowHealthWarningPreviewOnBtn, "RIGHT", 5, 0)
    addonTable.lowHealthWarningTextBox = CreateFrame("EditBox", nil, ac, "InputBoxTemplate")
    addonTable.lowHealthWarningTextBox:SetSize(200, 22)
    addonTable.lowHealthWarningTextBox:SetPoint("TOPLEFT", addonTable.lowHealthWarningCB, "BOTTOMLEFT", 40, -12)
    addonTable.lowHealthWarningTextBox:SetAutoFocus(false)
    addonTable.lowHealthWarningTextBox:SetMaxLetters(30)
    addonTable.lowHealthWarningTextBox:SetText("LOW HEALTH")
    addonTable.lowHealthWarningTextBox:SetEnabled(false)
    local lhwTextLbl = ac:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lhwTextLbl:SetPoint("RIGHT", addonTable.lowHealthWarningTextBox, "LEFT", -4, 0)
    lhwTextLbl:SetText("Text:")
    addonTable.lowHealthWarningFontSizeSlider = Slider(ac, "Font Size", 280, -269, 12, 72, 36, 1)
    addonTable.lowHealthWarningFontSizeSlider.label:ClearAllPoints()
    addonTable.lowHealthWarningFontSizeSlider.label:SetPoint("LEFT", addonTable.lowHealthWarningTextBox, "RIGHT", 15, 0)
    addonTable.lowHealthWarningFontSizeSlider:ClearAllPoints()
    addonTable.lowHealthWarningFontSizeSlider:SetPoint("TOPLEFT", addonTable.lowHealthWarningFontSizeSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.lowHealthWarningFontSizeSlider:SetEnabled(false)
    addonTable.lowHealthWarningXSlider = Slider(ac, "X Offset", 15, -324, -500, 500, 0, 1)
    addonTable.lowHealthWarningXSlider.label:ClearAllPoints()
    addonTable.lowHealthWarningXSlider.label:SetPoint("TOPLEFT", addonTable.lowHealthWarningTextBox, "BOTTOMLEFT", -40, -25)
    addonTable.lowHealthWarningXSlider:ClearAllPoints()
    addonTable.lowHealthWarningXSlider:SetPoint("TOPLEFT", addonTable.lowHealthWarningXSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.lowHealthWarningXSlider:SetEnabled(false)
    addonTable.lowHealthWarningYSlider = Slider(ac, "Y Offset", 280, -324, -500, 500, 200, 1)
    addonTable.lowHealthWarningYSlider.label:ClearAllPoints()
    addonTable.lowHealthWarningYSlider.label:SetPoint("TOPLEFT", addonTable.lowHealthWarningXSlider.label, "TOPLEFT", 265, 0)
    addonTable.lowHealthWarningYSlider:ClearAllPoints()
    addonTable.lowHealthWarningYSlider:SetPoint("TOPLEFT", addonTable.lowHealthWarningYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.lowHealthWarningYSlider:SetEnabled(false)
    addonTable.lowHealthWarningSoundDD, addonTable.lowHealthWarningSoundLbl = StyledDropdown(ac, "Sound", 15, -379, 180)
    addonTable.lowHealthWarningSoundDD:ClearAllPoints()
    addonTable.lowHealthWarningSoundDD:SetPoint("TOPLEFT", addonTable.lowHealthWarningXSlider, "BOTTOMLEFT", 0, -35)
    if addonTable.lowHealthWarningSoundLbl then addonTable.lowHealthWarningSoundLbl:ClearAllPoints(); addonTable.lowHealthWarningSoundLbl:SetPoint("BOTTOMLEFT", addonTable.lowHealthWarningSoundDD, "TOPLEFT", 0, 4) end
    ApplySoundOptionsToDropdown(addonTable.lowHealthWarningSoundDD)
    addonTable.lowHealthWarningSoundDD:SetValue("None")
    addonTable.lowHealthWarningSoundDD:SetEnabled(false)
    addonTable.lowHealthWarningSoundDD.onButtonRendered = function(btn, opt, _)
      if not opt then
        if btn._playBtn then btn._playBtn:Hide() end
        return
      end
      if not btn._playBtn then
        local pb = CreateFrame("Button", nil, btn)
        pb:SetSize(20, 20)
        pb:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        pb.tex = pb:CreateTexture(nil, "ARTWORK")
        pb.tex:SetSize(14, 14)
        pb.tex:SetPoint("CENTER")
        pb.tex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        pb.tex:SetVertexColor(0.9, 0.9, 0.9, 0.85)
        pb:SetScript("OnEnter", function(self)
          self.tex:SetVertexColor(1, 0.82, 0, 1)
          local onEnter = btn:GetScript("OnEnter")
          if onEnter then onEnter(btn) end
        end)
        pb:SetScript("OnLeave", function(self)
          self.tex:SetVertexColor(0.9, 0.9, 0.9, 0.85)
          local onLeave = btn:GetScript("OnLeave")
          if onLeave then onLeave(btn) end
        end)
        btn._playBtn = pb
      end
      if opt.value == "None" then
        btn._playBtn:Hide()
      else
        btn._playBtn:Show()
        btn._playBtn:SetScript("OnClick", function()
          local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
          if LSM then
            local soundFile = LSM:Fetch("sound", opt.value)
            if soundFile and type(soundFile) == "string" then
              local profile = addonTable.GetProfile and addonTable.GetProfile()
              local channel = (profile and profile.audioChannel) or "Master"
              PlaySoundFile(soundFile, channel)
            end
          end
        end)
      end
    end
    addonTable.lowHealthWarningColorBtn = CreateStyledButton(ac, "Color", 60, 22)
    addonTable.lowHealthWarningColorBtn:SetPoint("LEFT", addonTable.lowHealthWarningSoundDD, "RIGHT", 85, 0)
    addonTable.lowHealthWarningColorBtn:SetEnabled(false)
    addonTable.lowHealthWarningColorSwatch = CreateFrame("Frame", nil, ac, "BackdropTemplate")
    addonTable.lowHealthWarningColorSwatch:SetSize(22, 22)
    addonTable.lowHealthWarningColorSwatch:SetPoint("LEFT", addonTable.lowHealthWarningColorBtn, "RIGHT", 4, 0)
    addonTable.lowHealthWarningColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.lowHealthWarningColorSwatch:SetBackdropColor(1, 0, 0, 1)
    addonTable.lowHealthWarningColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  end
  local tab14 = tabFrames[14]
  if tab14 then
    local abSF = CreateFrame("ScrollFrame", "CCMActionBarsScrollFrame", tab14, "UIPanelScrollFrameTemplate")
    abSF:SetPoint("TOPLEFT", tab14, "TOPLEFT", 0, 0)
    abSF:SetPoint("BOTTOMRIGHT", tab14, "BOTTOMRIGHT", -22, 0)
    local abSC = CreateFrame("Frame", "CCMActionBarsScrollChild", abSF)
    abSC:SetSize(490, 500)
    abSF:SetScrollChild(abSC)
    local abBar = _G["CCMActionBarsScrollFrameScrollBar"]
    if abBar then
      abBar:SetPoint("TOPLEFT", abSF, "TOPRIGHT", 6, -16)
      abBar:SetPoint("BOTTOMLEFT", abSF, "BOTTOMRIGHT", 6, 16)
      local abThumb = abBar:GetThumbTexture()
      if abThumb then abThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); abThumb:SetSize(8, 40) end
      local abUp = _G["CCMActionBarsScrollFrameScrollBarScrollUpButton"]
      local abDown = _G["CCMActionBarsScrollFrameScrollBarScrollDownButton"]
      if abUp then abUp:SetAlpha(0); abUp:EnableMouse(false) end
      if abDown then abDown:SetAlpha(0); abDown:EnableMouse(false) end
    end
    SetSmoothScroll(abSF)
    local abc = abSC
    local abSec = Section(abc, "Action Bar Enhancement", -12)
    local abNote = abc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abNote:SetPoint("TOPLEFT", abSec, "BOTTOMLEFT", 0, -10)
    abNote:SetText("|cff888888Note: Action Bars have to be set in Edit Mode to Always Visible.|r")
    local AB_LABEL_X, AB_DD_X, AB_DD_W = 15, 280, 205
    local AB_ROW_H = 30
    local AB_GLOBAL_OPTIONS = {
      {text = "Per Bar (Custom)", value = "custom"},
      {text = "Off", value = "off"},
      {text = "Hide in Combat", value = "combat"},
      {text = "Hide in Combat + Mouseover", value = "combat_mouseover"},
      {text = "Hide Always", value = "always"},
      {text = "Hide Always + Mouseover", value = "always_mouseover"},
    }
    local AB_MODE_OPTIONS = {
      {text = "Off", value = "off"},
      {text = "Hide in Combat", value = "combat"},
      {text = "Hide in Combat + Mouseover", value = "combat_mouseover"},
      {text = "Hide Always", value = "always"},
      {text = "Hide Always + Mouseover", value = "always_mouseover"},
    }
    local lastABRow
    local function CreateABModeRow(rowKey, labelText)
      local lbl = abc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      if lastABRow then
        lbl:SetPoint("TOPLEFT", lastABRow, "BOTTOMLEFT", 0, -16)
      else
        lbl:SetPoint("TOPLEFT", abNote, "BOTTOMLEFT", 0, -12)
      end
      lbl:SetText(labelText)
      addonTable[rowKey .. "ModeLabel"] = lbl
      local dd = StyledDropdown(abc, nil, AB_DD_X, 0, AB_DD_W)
      dd:ClearAllPoints()
      dd:SetPoint("LEFT", lbl, "LEFT", 265, 0)
      dd:SetOptions(AB_MODE_OPTIONS)
      dd:SetValue("off")
      addonTable[rowKey .. "ModeDD"] = dd
      lastABRow = lbl
    end
    addonTable.actionBarGlobalModeLabel = abc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.actionBarGlobalModeLabel:SetPoint("TOPLEFT", abNote, "BOTTOMLEFT", 0, -12)
    addonTable.actionBarGlobalModeLabel:SetText("All Bars")
    addonTable.actionBarGlobalModeDD = StyledDropdown(abc, nil, AB_DD_X, 0, AB_DD_W)
    addonTable.actionBarGlobalModeDD:ClearAllPoints()
    addonTable.actionBarGlobalModeDD:SetPoint("LEFT", addonTable.actionBarGlobalModeLabel, "LEFT", 265, 0)
    addonTable.actionBarGlobalModeDD:SetOptions(AB_GLOBAL_OPTIONS)
    addonTable.actionBarGlobalModeDD:SetValue("custom")
    lastABRow = addonTable.actionBarGlobalModeLabel
    CreateABModeRow("actionBar1", "Action Bar 1")
    for n = 2, 8 do
      CreateABModeRow("actionBar" .. n, "Action Bar " .. n)
    end
    CreateABModeRow("stanceBar", "Stance Bar")
    CreateABModeRow("petBar", "Pet Bar")
    addonTable.fadeMicroMenuCB = Checkbox(abc, "Fade Micro Menu", 15, -397)
    addonTable.fadeMicroMenuCB:ClearAllPoints()
    addonTable.fadeMicroMenuCB:SetPoint("TOPLEFT", lastABRow, "BOTTOMLEFT", 0, -15)
    addonTable.hideABGlowsCB = Checkbox(abc, "Hide Glows", AB_DD_X, -397)
    addonTable.hideABGlowsCB:ClearAllPoints()
    addonTable.hideABGlowsCB:SetPoint("TOPLEFT", addonTable.fadeMicroMenuCB, "TOPLEFT", 265, 0)
    addonTable.fadeObjectiveTrackerCB = Checkbox(abc, "Fade Objective Tracker", 15, -422)
    addonTable.fadeObjectiveTrackerCB:ClearAllPoints()
    addonTable.fadeObjectiveTrackerCB:SetPoint("TOPLEFT", addonTable.fadeMicroMenuCB, "BOTTOMLEFT", 0, -5)
    addonTable.hideABBordersCB = Checkbox(abc, "Action Bar Skinning", AB_DD_X, -422)
    addonTable.hideABBordersCB:ClearAllPoints()
    addonTable.hideABBordersCB:SetPoint("TOPLEFT", addonTable.hideABGlowsCB, "BOTTOMLEFT", 0, -5)
    addonTable.fadeBagBarCB = Checkbox(abc, "Fade Bag Bar", 15, -447)
    addonTable.fadeBagBarCB:ClearAllPoints()
    addonTable.fadeBagBarCB:SetPoint("TOPLEFT", addonTable.fadeObjectiveTrackerCB, "BOTTOMLEFT", 0, -5)
    addonTable.abSkinSpacingSlider = Slider(abc, "Skinning Spacing", AB_DD_X, -465, 0, 10, 2, 1)
    addonTable.abSkinSpacingSlider.label:ClearAllPoints()
    addonTable.abSkinSpacingSlider.label:SetPoint("TOPLEFT", addonTable.hideABBordersCB, "BOTTOMLEFT", 0, -8)
    addonTable.abSkinSpacingSlider:ClearAllPoints()
    addonTable.abSkinSpacingSlider:SetPoint("TOPLEFT", addonTable.abSkinSpacingSlider.label, "BOTTOMLEFT", 0, -8)
  end
  local tab15 = tabFrames[15]
  if tab15 then
    local chatSF = CreateFrame("ScrollFrame", "CCMChatScrollFrame", tab15, "UIPanelScrollFrameTemplate")
    chatSF:SetPoint("TOPLEFT", tab15, "TOPLEFT", 0, 0)
    chatSF:SetPoint("BOTTOMRIGHT", tab15, "BOTTOMRIGHT", -22, 0)
    local chatSC = CreateFrame("Frame", "CCMChatScrollChild", chatSF)
    chatSC:SetSize(490, 460)
    chatSF:SetScrollChild(chatSC)
    local chatBar = _G["CCMChatScrollFrameScrollBar"]
    if chatBar then
      chatBar:SetPoint("TOPLEFT", chatSF, "TOPRIGHT", 6, -16)
      chatBar:SetPoint("BOTTOMLEFT", chatSF, "BOTTOMRIGHT", 6, 16)
      local chatThumb = chatBar:GetThumbTexture()
      if chatThumb then chatThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); chatThumb:SetSize(8, 40) end
      local chatUp = _G["CCMChatScrollFrameScrollBarScrollUpButton"]
      local chatDown = _G["CCMChatScrollFrameScrollBarScrollDownButton"]
      if chatUp then chatUp:SetAlpha(0); chatUp:EnableMouse(false) end
      if chatDown then chatDown:SetAlpha(0); chatDown:EnableMouse(false) end
    end
    SetSmoothScroll(chatSF)
    local chc = chatSC
    local chatSec = Section(chc, "Chat Enhancement", -12)
    addonTable.chatClassColorCB = Checkbox(chc, "Class-Colored Names", 15, -37)
    addonTable.chatClassColorCB:ClearAllPoints()
    addonTable.chatClassColorCB:SetPoint("TOPLEFT", chatSec, "BOTTOMLEFT", 0, -12)
    addonTable.chatUrlDetectionCB = Checkbox(chc, "Clickable URLs", 250, -37)
    addonTable.chatUrlDetectionCB:ClearAllPoints()
    addonTable.chatUrlDetectionCB:SetPoint("TOPLEFT", addonTable.chatClassColorCB, "TOPLEFT", 265, 0)
    addonTable.chatHideButtonsCB = Checkbox(chc, "Hide Chat Buttons", 15, -62)
    addonTable.chatHideButtonsCB:ClearAllPoints()
    addonTable.chatHideButtonsCB:SetPoint("TOPLEFT", addonTable.chatClassColorCB, "BOTTOMLEFT", 0, -5)
    addonTable.chatTabFlashCB = Checkbox(chc, "Disable Tab Flash", 250, -62)
    addonTable.chatTabFlashCB:ClearAllPoints()
    addonTable.chatTabFlashCB:SetPoint("TOPLEFT", addonTable.chatHideButtonsCB, "TOPLEFT", 265, 0)
    addonTable.chatEditBoxStyledCB = Checkbox(chc, "Style Edit Box", 15, -97)
    addonTable.chatEditBoxStyledCB:ClearAllPoints()
    addonTable.chatEditBoxStyledCB:SetPoint("TOPLEFT", addonTable.chatHideButtonsCB, "BOTTOMLEFT", 0, -18)
    addonTable.chatEditBoxDD, addonTable.chatEditBoxLbl = StyledDropdown(chc, "Edit Box Position", 250, -87, 150)
    addonTable.chatEditBoxDD:ClearAllPoints()
    addonTable.chatEditBoxDD:SetPoint("TOPLEFT", addonTable.chatEditBoxStyledCB, "TOPLEFT", 259, 0)
    if addonTable.chatEditBoxLbl then addonTable.chatEditBoxLbl:ClearAllPoints(); addonTable.chatEditBoxLbl:SetPoint("BOTTOMLEFT", addonTable.chatEditBoxDD, "TOPLEFT", 0, 4) end
    addonTable.chatEditBoxDD:SetOptions({{text = "Bottom", value = "bottom"}, {text = "Top", value = "top"}})
    addonTable.chatTimestampsCB = Checkbox(chc, "Timestamps", 15, -147)
    addonTable.chatTimestampsCB:ClearAllPoints()
    addonTable.chatTimestampsCB:SetPoint("TOPLEFT", addonTable.chatEditBoxStyledCB, "BOTTOMLEFT", 0, -28)
    addonTable.chatTimestampFormatDD, addonTable.chatTimestampFormatLbl = StyledDropdown(chc, "Format", 250, -137, 150)
    addonTable.chatTimestampFormatDD:ClearAllPoints()
    addonTable.chatTimestampFormatDD:SetPoint("TOPLEFT", addonTable.chatTimestampsCB, "TOPLEFT", 259, 0)
    if addonTable.chatTimestampFormatLbl then addonTable.chatTimestampFormatLbl:ClearAllPoints(); addonTable.chatTimestampFormatLbl:SetPoint("BOTTOMLEFT", addonTable.chatTimestampFormatDD, "TOPLEFT", 0, 4) end
    addonTable.chatTimestampFormatDD:SetOptions({{text = "HH:MM", value = "HH:MM"}, {text = "HH:MM:SS", value = "HH:MM:SS"}, {text = "12h AM/PM", value = "12h"}})
    addonTable.chatCopyButtonCB = Checkbox(chc, "Copy Chat Button", 15, -207)
    addonTable.chatCopyButtonCB:ClearAllPoints()
    addonTable.chatCopyButtonCB:SetPoint("TOPLEFT", addonTable.chatTimestampsCB, "BOTTOMLEFT", 0, -28)
    addonTable.chatCopyButtonCornerDD, addonTable.chatCopyButtonCornerLbl = StyledDropdown(chc, "Corner", 250, -197, 150)
    addonTable.chatCopyButtonCornerDD:ClearAllPoints()
    addonTable.chatCopyButtonCornerDD:SetPoint("TOPLEFT", addonTable.chatCopyButtonCB, "TOPLEFT", 259, 0)
    if addonTable.chatCopyButtonCornerLbl then addonTable.chatCopyButtonCornerLbl:ClearAllPoints(); addonTable.chatCopyButtonCornerLbl:SetPoint("BOTTOMLEFT", addonTable.chatCopyButtonCornerDD, "TOPLEFT", 0, 4) end
    addonTable.chatCopyButtonCornerDD:SetOptions({{text = "Top Left", value = "TOPLEFT"}, {text = "Top Right", value = "TOPRIGHT"}, {text = "Bottom Left", value = "BOTTOMLEFT"}, {text = "Bottom Right", value = "BOTTOMRIGHT"}})
    addonTable.chatBackgroundCB = Checkbox(chc, "Custom Chat Background", 15, -292)
    addonTable.chatBackgroundCB:ClearAllPoints()
    addonTable.chatBackgroundCB:SetPoint("TOPLEFT", addonTable.chatCopyButtonCB, "BOTTOMLEFT", 0, -28)
    addonTable.chatHideTabsDD, addonTable.chatHideTabsLbl = StyledDropdown(chc, "Chat Tabs", 250, -247, 150)
    addonTable.chatHideTabsDD:ClearAllPoints()
    addonTable.chatHideTabsDD:SetPoint("TOPLEFT", addonTable.chatBackgroundCB, "TOPLEFT", 259, 0)
    if addonTable.chatHideTabsLbl then addonTable.chatHideTabsLbl:ClearAllPoints(); addonTable.chatHideTabsLbl:SetPoint("BOTTOMLEFT", addonTable.chatHideTabsDD, "TOPLEFT", 0, 4) end
    addonTable.chatHideTabsDD:SetOptions({{text = "Show", value = "off"}, {text = "Hide", value = "hide"}, {text = "Mouseover", value = "mouseover"}})
    addonTable.chatBgAlphaSlider = Slider(chc, "Background Opacity", 15, -322, 0, 100, 40, 5)
    addonTable.chatBgAlphaSlider.label:ClearAllPoints()
    addonTable.chatBgAlphaSlider.label:SetPoint("TOPLEFT", addonTable.chatBackgroundCB, "BOTTOMLEFT", 0, -8)
    addonTable.chatBgAlphaSlider:ClearAllPoints()
    addonTable.chatBgAlphaSlider:SetPoint("TOPLEFT", addonTable.chatBgAlphaSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.chatBgColorBtn = CreateStyledButton(chc, "BG Color", 65, 22)
    addonTable.chatBgColorBtn:SetPoint("LEFT", addonTable.chatBgAlphaSlider.valueTextBg, "RIGHT", 26, 0)
    addonTable.chatBgColorSwatch = CreateFrame("Frame", nil, chc, "BackdropTemplate")
    addonTable.chatBgColorSwatch:SetSize(22, 22)
    addonTable.chatBgColorSwatch:SetPoint("LEFT", addonTable.chatBgColorBtn, "RIGHT", 4, 0)
    addonTable.chatBgColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.chatBgColorSwatch:SetBackdropColor(0, 0, 0, 1)
    addonTable.chatBgColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.chatFadeToggleCB = Checkbox(chc, "Custom Chat Fading", 15, -377)
    addonTable.chatFadeToggleCB:ClearAllPoints()
    addonTable.chatFadeToggleCB:SetPoint("TOPLEFT", addonTable.chatBgAlphaSlider, "BOTTOMLEFT", 0, -18)
    addonTable.chatFadeDelaySlider = Slider(chc, "Fade Delay (sec)", 15, -407, 5, 120, 20, 5)
    addonTable.chatFadeDelaySlider.label:ClearAllPoints()
    addonTable.chatFadeDelaySlider.label:SetPoint("TOPLEFT", addonTable.chatFadeToggleCB, "BOTTOMLEFT", 0, -8)
    addonTable.chatFadeDelaySlider:ClearAllPoints()
    addonTable.chatFadeDelaySlider:SetPoint("TOPLEFT", addonTable.chatFadeDelaySlider.label, "BOTTOMLEFT", 0, -8)
  end
  local tab16 = tabFrames[16]
  if tab16 then
    local skySF = CreateFrame("ScrollFrame", "CCMSkyridingScrollFrame", tab16, "UIPanelScrollFrameTemplate")
    skySF:SetPoint("TOPLEFT", tab16, "TOPLEFT", 0, 0)
    skySF:SetPoint("BOTTOMRIGHT", tab16, "BOTTOMRIGHT", -22, 0)
    local skySC = CreateFrame("Frame", "CCMSkyridingScrollChild", skySF)
    skySC:SetSize(490, 500)
    skySF:SetScrollChild(skySC)
    local skyBar = _G["CCMSkyridingScrollFrameScrollBar"]
    if skyBar then
      skyBar:SetPoint("TOPLEFT", skySF, "TOPRIGHT", 6, -16)
      skyBar:SetPoint("BOTTOMLEFT", skySF, "BOTTOMRIGHT", 6, 16)
      local skyThumb = skyBar:GetThumbTexture()
      if skyThumb then skyThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); skyThumb:SetSize(8, 40) end
      local skyUp = _G["CCMSkyridingScrollFrameScrollBarScrollUpButton"]
      local skyDown = _G["CCMSkyridingScrollFrameScrollBarScrollDownButton"]
      if skyUp then skyUp:SetAlpha(0); skyUp:EnableMouse(false) end
      if skyDown then skyDown:SetAlpha(0); skyDown:EnableMouse(false) end
    end
    SetSmoothScroll(skySF)
    local skc = skySC
    local skySec = Section(skc, "Skyriding Enhancement", -12)
    addonTable.skyridingEnabledCB = Checkbox(skc, "Enable Skyriding UI", 15, -42)
    addonTable.skyridingEnabledCB:ClearAllPoints()
    addonTable.skyridingEnabledCB:SetPoint("TOPLEFT", skySec, "BOTTOMLEFT", 0, -15)
    addonTable.skyridingHideCDMCB = Checkbox(skc, "Hide CDM / Bars", 250, -42)
    addonTable.skyridingHideCDMCB:ClearAllPoints()
    addonTable.skyridingHideCDMCB:SetPoint("TOPLEFT", skySec, "BOTTOMLEFT", 235, -15)
    addonTable.skyridingVigorBarCB = Checkbox(skc, "Charge Bar", 15, -72)
    addonTable.skyridingVigorBarCB:ClearAllPoints()
    addonTable.skyridingVigorBarCB:SetPoint("TOPLEFT", addonTable.skyridingEnabledCB, "BOTTOMLEFT", 22, -8)
    addonTable.skyridingCenteredCB = Checkbox(skc, "Center", 250, -72)
    addonTable.skyridingCenteredCB:ClearAllPoints()
    addonTable.skyridingCenteredCB:SetPoint("TOPLEFT", addonTable.skyridingHideCDMCB, "BOTTOMLEFT", 0, -8)
    addonTable.skyridingCooldownsCB = Checkbox(skc, "Ability Cooldowns", 15, -102)
    addonTable.skyridingCooldownsCB:ClearAllPoints()
    addonTable.skyridingCooldownsCB:SetPoint("TOPLEFT", addonTable.skyridingVigorBarCB, "BOTTOMLEFT", 0, -8)
    addonTable.skyridingSpeedFxCB = Checkbox(skc, "Speed Effects", 15, -132)
    addonTable.skyridingSpeedFxCB:ClearAllPoints()
    addonTable.skyridingSpeedFxCB:SetPoint("TOPLEFT", addonTable.skyridingCooldownsCB, "BOTTOMLEFT", 0, -8)
    addonTable.skyridingScreenFxCB = Checkbox(skc, "Screen Effects", 15, -162)
    addonTable.skyridingScreenFxCB:ClearAllPoints()
    addonTable.skyridingScreenFxCB:SetPoint("TOPLEFT", addonTable.skyridingSpeedFxCB, "BOTTOMLEFT", 0, -8)
    local cbd = {bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1}
    local function SkyColorPicker(name, x, y, dr, dg, db)
      local btn = CreateStyledButton(skc, name, 55, 22)
      btn:SetPoint("TOPLEFT", skc, "TOPLEFT", x, y)
      local sw = CreateFrame("Frame", nil, skc, "BackdropTemplate")
      sw:SetSize(22, 22)
      sw:SetPoint("LEFT", btn, "RIGHT", 4, 0)
      sw:SetBackdrop(cbd)
      sw:SetBackdropColor(dr, dg, db, 1)
      sw:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      return btn, sw
    end
    addonTable.skyridingVigorColorBtn, addonTable.skyridingVigorColorSwatch = SkyColorPicker("Charge", 15, -202, 0.2, 0.8, 0.2)
    addonTable.skyridingVigorColorBtn:ClearAllPoints()
    addonTable.skyridingVigorColorBtn:SetPoint("TOPLEFT", addonTable.skyridingScreenFxCB, "BOTTOMLEFT", 0, -18)
    addonTable.skyridingSurgeColorBtn, addonTable.skyridingSurgeColorSwatch = SkyColorPicker("Surge", 130, -202, 0.85, 0.65, 0.1)
    addonTable.skyridingSurgeColorBtn:ClearAllPoints()
    addonTable.skyridingSurgeColorBtn:SetPoint("LEFT", addonTable.skyridingVigorColorSwatch, "RIGHT", 15, 0)
    addonTable.skyridingRechargeColorBtn, addonTable.skyridingRechargeColorSwatch = SkyColorPicker("Recharge", 245, -202, 0.85, 0.65, 0.1)
    addonTable.skyridingRechargeColorBtn:ClearAllPoints()
    addonTable.skyridingRechargeColorBtn:SetPoint("LEFT", addonTable.skyridingSurgeColorSwatch, "RIGHT", 15, 0)
    addonTable.skyridingWindColorBtn, addonTable.skyridingWindColorSwatch = SkyColorPicker("Wind", 360, -202, 0.2, 0.8, 0.2)
    addonTable.skyridingWindColorBtn:ClearAllPoints()
    addonTable.skyridingWindColorBtn:SetPoint("LEFT", addonTable.skyridingRechargeColorSwatch, "RIGHT", 15, 0)
    addonTable.skyridingEmptyColorBtn, addonTable.skyridingEmptyColorSwatch = SkyColorPicker("BG", 15, -238, 0.15, 0.15, 0.15)
    addonTable.skyridingEmptyColorBtn:ClearAllPoints()
    addonTable.skyridingEmptyColorBtn:SetPoint("TOPLEFT", addonTable.skyridingVigorColorBtn, "BOTTOMLEFT", 0, -12)
    addonTable.skyridingTextureDD, addonTable.skyridingTextureLbl = StyledDropdown(skc, "Texture", 15, -278, 140)
    addonTable.skyridingTextureDD:ClearAllPoints()
    addonTable.skyridingTextureDD:SetPoint("TOPLEFT", addonTable.skyridingEmptyColorBtn, "BOTTOMLEFT", 0, -18)
    if addonTable.skyridingTextureLbl then addonTable.skyridingTextureLbl:ClearAllPoints(); addonTable.skyridingTextureLbl:SetPoint("BOTTOMLEFT", addonTable.skyridingTextureDD, "TOPLEFT", 0, 4) end
    ApplyTextureOptionsToDropdown(addonTable.skyridingTextureDD)
    addonTable.skyridingScaleSlider = Slider(skc, "Scale", 15, -338, 50, 200, 100, 5)
    addonTable.skyridingScaleSlider.label:ClearAllPoints()
    addonTable.skyridingScaleSlider.label:SetPoint("TOPLEFT", addonTable.skyridingTextureDD, "BOTTOMLEFT", 0, -25)
    addonTable.skyridingScaleSlider:ClearAllPoints()
    addonTable.skyridingScaleSlider:SetPoint("TOPLEFT", addonTable.skyridingScaleSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.skyridingXSlider = Slider(skc, "X Position", 15, -398, -800, 800, 0, 5)
    addonTable.skyridingXSlider.label:ClearAllPoints()
    addonTable.skyridingXSlider.label:SetPoint("TOPLEFT", addonTable.skyridingScaleSlider, "BOTTOMLEFT", 0, -25)
    addonTable.skyridingXSlider:ClearAllPoints()
    addonTable.skyridingXSlider:SetPoint("TOPLEFT", addonTable.skyridingXSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.skyridingYSlider = Slider(skc, "Y Position", 280, -398, -800, 800, -200, 5)
    addonTable.skyridingYSlider.label:ClearAllPoints()
    addonTable.skyridingYSlider.label:SetPoint("TOPLEFT", addonTable.skyridingXSlider.label, "TOPLEFT", 265, 0)
    addonTable.skyridingYSlider:ClearAllPoints()
    addonTable.skyridingYSlider:SetPoint("TOPLEFT", addonTable.skyridingYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.skyridingPreviewOnBtn = CreateStyledButton(skc, "Show Preview", 90, 22)
    addonTable.skyridingPreviewOnBtn:SetPoint("TOPLEFT", addonTable.skyridingXSlider, "BOTTOMLEFT", 0, -25)
    addonTable.skyridingPreviewOffBtn = CreateStyledButton(skc, "Hide Preview", 90, 22)
    addonTable.skyridingPreviewOffBtn:SetPoint("LEFT", addonTable.skyridingPreviewOnBtn, "RIGHT", 5, 0)
  end
  local TAB_COMBAT = addonTable.TAB_COMBAT or 19
  local tab19 = tabFrames[TAB_COMBAT]
  if tab19 then
    local combSF = CreateFrame("ScrollFrame", "CCMCombatScrollFrame", tab19, "UIPanelScrollFrameTemplate")
    combSF:SetPoint("TOPLEFT", tab19, "TOPLEFT", 0, 0)
    combSF:SetPoint("BOTTOMRIGHT", tab19, "BOTTOMRIGHT", -22, 0)
    local combSC = CreateFrame("Frame", "CCMCombatScrollChild", combSF)
    combSC:SetSize(490, 1100)
    combSF:SetScrollChild(combSC)
    local combBar = _G["CCMCombatScrollFrameScrollBar"]
    if combBar then
      combBar:SetPoint("TOPLEFT", combSF, "TOPRIGHT", 6, -16)
      combBar:SetPoint("BOTTOMLEFT", combSF, "BOTTOMRIGHT", 6, 16)
      local combThumb = combBar:GetThumbTexture()
      if combThumb then combThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); combThumb:SetSize(8, 40) end
      local combUp = _G["CCMCombatScrollFrameScrollBarScrollUpButton"]
      local combDown = _G["CCMCombatScrollFrameScrollBarScrollDownButton"]
      if combUp then combUp:SetAlpha(0); combUp:EnableMouse(false) end
      if combDown then combDown:SetAlpha(0); combDown:EnableMouse(false) end
    end
    SetSmoothScroll(combSF)
    local cc = combSC
    local combSelfSec = Section(cc, "Self Highlight", -12)
    addonTable.selfHighlightCB = Checkbox(cc, "Enable Self Highlight", 15, -37)
    addonTable.selfHighlightCB:ClearAllPoints()
    addonTable.selfHighlightCB:SetPoint("TOPLEFT", combSelfSec, "BOTTOMLEFT", 0, -12)
    addonTable.selfHighlightVisibilityDD, addonTable.selfHighlightVisibilityLbl = StyledDropdown(cc, "Visibility", 170, -37, 130)
    addonTable.selfHighlightVisibilityDD:ClearAllPoints()
    addonTable.selfHighlightVisibilityDD:SetPoint("TOPLEFT", addonTable.selfHighlightCB, "TOPLEFT", 229, 0)
    if addonTable.selfHighlightVisibilityLbl then addonTable.selfHighlightVisibilityLbl:ClearAllPoints(); addonTable.selfHighlightVisibilityLbl:SetPoint("BOTTOMLEFT", addonTable.selfHighlightVisibilityDD, "TOPLEFT", 0, 4) end
    addonTable.selfHighlightVisibilityDD:SetOptions({{text = "Always", value = "always"}, {text = "Only in Combat", value = "combat"}})
    addonTable.selfHighlightVisibilityDD:SetEnabled(false)
    addonTable.selfHighlightSizeSlider = Slider(cc, "Size", 15, -94, 5, 100, 20, 1)
    addonTable.selfHighlightSizeSlider.label:ClearAllPoints()
    addonTable.selfHighlightSizeSlider.label:SetPoint("TOPLEFT", addonTable.selfHighlightCB, "BOTTOMLEFT", 0, -25)
    addonTable.selfHighlightSizeSlider:ClearAllPoints()
    addonTable.selfHighlightSizeSlider:SetPoint("TOPLEFT", addonTable.selfHighlightSizeSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.selfHighlightSizeSlider:SetEnabled(false)
    addonTable.selfHighlightYSlider = Slider(cc, "Y Offset", 280, -94, -200, 200, 0, 1)
    addonTable.selfHighlightYSlider.label:ClearAllPoints()
    addonTable.selfHighlightYSlider.label:SetPoint("TOPLEFT", addonTable.selfHighlightSizeSlider.label, "TOPLEFT", 265, 0)
    addonTable.selfHighlightYSlider:ClearAllPoints()
    addonTable.selfHighlightYSlider:SetPoint("TOPLEFT", addonTable.selfHighlightYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.selfHighlightYSlider:SetEnabled(false)
    addonTable.selfHighlightThicknessDD, addonTable.selfHighlightThicknessLbl = StyledDropdown(cc, "Thickness", 15, -149, 100)
    addonTable.selfHighlightThicknessDD:ClearAllPoints()
    addonTable.selfHighlightThicknessDD:SetPoint("TOPLEFT", addonTable.selfHighlightSizeSlider, "BOTTOMLEFT", 0, -33)
    if addonTable.selfHighlightThicknessLbl then addonTable.selfHighlightThicknessLbl:ClearAllPoints(); addonTable.selfHighlightThicknessLbl:SetPoint("BOTTOMLEFT", addonTable.selfHighlightThicknessDD, "TOPLEFT", 0, 4) end
    addonTable.selfHighlightThicknessDD:SetOptions({{text = "Thin", value = "thin"}, {text = "Medium", value = "medium"}, {text = "Thick", value = "thick"}})
    addonTable.selfHighlightThicknessDD:SetEnabled(false)
    addonTable.selfHighlightOutlineCB = Checkbox(cc, "Outline", 170, -167)
    addonTable.selfHighlightOutlineCB:ClearAllPoints()
    addonTable.selfHighlightOutlineCB:SetPoint("LEFT", addonTable.selfHighlightThicknessDD, "RIGHT", 15, 0)
    addonTable.selfHighlightOutlineCB:SetEnabled(false)
    addonTable.selfHighlightColorBtn = CreateStyledButton(cc, "Color", 60, 22)
    addonTable.selfHighlightColorBtn:SetPoint("LEFT", addonTable.selfHighlightOutlineCB.label, "RIGHT", 15, 0)
    addonTable.selfHighlightColorBtn:SetEnabled(false)
    addonTable.selfHighlightColorSwatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
    addonTable.selfHighlightColorSwatch:SetSize(22, 22)
    addonTable.selfHighlightColorSwatch:SetPoint("LEFT", addonTable.selfHighlightColorBtn, "RIGHT", 4, 0)
    addonTable.selfHighlightColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.selfHighlightColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.selfHighlightColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    local combTimerSec = Section(cc, "Combat Timer", -230)
    addonTable.combatTimerCB = Checkbox(cc, "Enable Combat Timer", 15, -242)
    addonTable.combatTimerCB:ClearAllPoints()
    addonTable.combatTimerCB:SetPoint("TOPLEFT", combTimerSec, "BOTTOMLEFT", 0, -12)
    addonTable.combatTimerStyleDD, addonTable.combatTimerStyleLbl = StyledDropdown(cc, "Timer Style", 15, -277, 170)
    addonTable.combatTimerStyleDD:ClearAllPoints()
    addonTable.combatTimerStyleDD:SetPoint("TOPLEFT", addonTable.combatTimerCB, "BOTTOMLEFT", 0, -26)
    if addonTable.combatTimerStyleLbl then addonTable.combatTimerStyleLbl:ClearAllPoints(); addonTable.combatTimerStyleLbl:SetPoint("BOTTOMLEFT", addonTable.combatTimerStyleDD, "TOPLEFT", 0, 4) end
    addonTable.combatTimerStyleDD:SetOptions({
      {text = "Boxed", value = "boxed"},
      {text = "Minimal", value = "minimal"},
    })
    addonTable.combatTimerModeDD, addonTable.combatTimerModeLbl = StyledDropdown(cc, "Timer Visibility", 280, -277, 170)
    addonTable.combatTimerModeDD:ClearAllPoints()
    addonTable.combatTimerModeDD:SetPoint("TOPLEFT", addonTable.combatTimerCB, "BOTTOMLEFT", 265, -26)
    if addonTable.combatTimerModeLbl then addonTable.combatTimerModeLbl:ClearAllPoints(); addonTable.combatTimerModeLbl:SetPoint("BOTTOMLEFT", addonTable.combatTimerModeDD, "TOPLEFT", 0, 4) end
    addonTable.combatTimerModeDD:SetOptions({
      {text = "Show Always", value = "always"},
      {text = "Only In Combat", value = "combat"},
    })
    addonTable.combatTimerXSlider = Slider(cc, "X Offset", 15, -324, -1500, 1500, 0, 1)
    addonTable.combatTimerXSlider.label:ClearAllPoints()
    addonTable.combatTimerXSlider.label:SetPoint("TOPLEFT", addonTable.combatTimerStyleDD, "BOTTOMLEFT", 0, -18)
    addonTable.combatTimerXSlider:ClearAllPoints()
    addonTable.combatTimerXSlider:SetPoint("TOPLEFT", addonTable.combatTimerXSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.combatTimerYSlider = Slider(cc, "Y Offset", 280, -324, -1500, 1500, 200, 1)
    addonTable.combatTimerYSlider.label:ClearAllPoints()
    addonTable.combatTimerYSlider.label:SetPoint("TOPLEFT", addonTable.combatTimerXSlider.label, "TOPLEFT", 265, 0)
    addonTable.combatTimerYSlider:ClearAllPoints()
    addonTable.combatTimerYSlider:SetPoint("TOPLEFT", addonTable.combatTimerYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.combatTimerScaleSlider = Slider(cc, "Scale", 15, -384, 0.2, 2.0, 1.0, 0.05)
    addonTable.combatTimerScaleSlider.label:ClearAllPoints()
    addonTable.combatTimerScaleSlider.label:SetPoint("TOPLEFT", addonTable.combatTimerXSlider, "BOTTOMLEFT", 0, -25)
    addonTable.combatTimerScaleSlider:ClearAllPoints()
    addonTable.combatTimerScaleSlider:SetPoint("TOPLEFT", addonTable.combatTimerScaleSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.combatTimerCenteredCB = Checkbox(cc, "Center X", 280, -399)
    addonTable.combatTimerCenteredCB:ClearAllPoints()
    addonTable.combatTimerCenteredCB:SetPoint("TOPLEFT", addonTable.combatTimerScaleSlider, "TOPLEFT", 265, -2)
    local ctbd = {bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1}
    addonTable.combatTimerTextColorBtn = CreateStyledButton(cc, "Text Color", 80, 22)
    addonTable.combatTimerTextColorBtn:SetPoint("TOPLEFT", addonTable.combatTimerScaleSlider, "BOTTOMLEFT", 0, -18)
    addonTable.combatTimerTextColorSwatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
    addonTable.combatTimerTextColorSwatch:SetSize(22, 22)
    addonTable.combatTimerTextColorSwatch:SetPoint("LEFT", addonTable.combatTimerTextColorBtn, "RIGHT", 4, 0)
    addonTable.combatTimerTextColorSwatch:SetBackdrop(ctbd)
    addonTable.combatTimerTextColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.combatTimerTextColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.combatTimerBgColorBtn = CreateStyledButton(cc, "Background", 80, 22)
    addonTable.combatTimerBgColorBtn:SetPoint("LEFT", addonTable.combatTimerTextColorSwatch, "RIGHT", 80, 0)
    addonTable.combatTimerBgColorSwatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
    addonTable.combatTimerBgColorSwatch:SetSize(22, 22)
    addonTable.combatTimerBgColorSwatch:SetPoint("LEFT", addonTable.combatTimerBgColorBtn, "RIGHT", 4, 0)
    addonTable.combatTimerBgColorSwatch:SetBackdrop(ctbd)
    addonTable.combatTimerBgColorSwatch:SetBackdropColor(0.12, 0.12, 0.12, 1)
    addonTable.combatTimerBgColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    local combCRSec = Section(cc, "Timer for CR", -540)
    addonTable.crTimerCB = Checkbox(cc, "Enable Timer for CR", 15, -526)
    addonTable.crTimerCB:ClearAllPoints()
    addonTable.crTimerCB:SetPoint("TOPLEFT", combCRSec, "BOTTOMLEFT", 0, -12)
    addonTable.crTimerModeDD, addonTable.crTimerModeLbl = StyledDropdown(cc, "Visibility", 15, -561, 170)
    addonTable.crTimerModeDD:ClearAllPoints()
    addonTable.crTimerModeDD:SetPoint("TOPLEFT", addonTable.crTimerCB, "BOTTOMLEFT", 0, -26)
    if addonTable.crTimerModeLbl then addonTable.crTimerModeLbl:ClearAllPoints(); addonTable.crTimerModeLbl:SetPoint("BOTTOMLEFT", addonTable.crTimerModeDD, "TOPLEFT", 0, 4) end
    addonTable.crTimerModeDD:SetOptions({
      {text = "Show Always", value = "always"},
      {text = "Only In Combat", value = "combat"},
    })
    addonTable.crTimerLayoutDD, addonTable.crTimerLayoutLbl = StyledDropdown(cc, "Layout", 280, -561, 170)
    addonTable.crTimerLayoutDD:ClearAllPoints()
    addonTable.crTimerLayoutDD:SetPoint("TOPLEFT", addonTable.crTimerCB, "BOTTOMLEFT", 265, -26)
    if addonTable.crTimerLayoutLbl then addonTable.crTimerLayoutLbl:ClearAllPoints(); addonTable.crTimerLayoutLbl:SetPoint("BOTTOMLEFT", addonTable.crTimerLayoutDD, "TOPLEFT", 0, 4) end
    addonTable.crTimerLayoutDD:SetOptions({
      {text = "Vertical", value = "vertical"},
      {text = "Horizontal", value = "horizontal"},
    })
    addonTable.crTimerDisplayDD, addonTable.crTimerDisplayLbl = StyledDropdown(cc, "Display", 15, -601, 170)
    addonTable.crTimerDisplayDD:ClearAllPoints()
    addonTable.crTimerDisplayDD:SetPoint("TOPLEFT", addonTable.crTimerModeDD, "BOTTOMLEFT", 0, -33)
    if addonTable.crTimerDisplayLbl then addonTable.crTimerDisplayLbl:ClearAllPoints(); addonTable.crTimerDisplayLbl:SetPoint("BOTTOMLEFT", addonTable.crTimerDisplayDD, "TOPLEFT", 0, 4) end
    addonTable.crTimerDisplayDD:SetOptions({
      {text = "Charges + Timer", value = "timer"},
      {text = "Charges Only", value = "count"},
    })
    addonTable.crTimerXSlider = Slider(cc, "X Offset", 15, -646, -1500, 1500, 0, 1)
    addonTable.crTimerXSlider.label:ClearAllPoints()
    addonTable.crTimerXSlider.label:SetPoint("TOPLEFT", addonTable.crTimerDisplayDD, "BOTTOMLEFT", 0, -18)
    addonTable.crTimerXSlider:ClearAllPoints()
    addonTable.crTimerXSlider:SetPoint("TOPLEFT", addonTable.crTimerXSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.crTimerYSlider = Slider(cc, "Y Offset", 280, -646, -1500, 1500, 150, 1)
    addonTable.crTimerYSlider.label:ClearAllPoints()
    addonTable.crTimerYSlider.label:SetPoint("TOPLEFT", addonTable.crTimerXSlider.label, "TOPLEFT", 265, 0)
    addonTable.crTimerYSlider:ClearAllPoints()
    addonTable.crTimerYSlider:SetPoint("TOPLEFT", addonTable.crTimerYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.crTimerScaleSlider = Slider(cc, "Scale", 15, -706, 0.2, 2.0, 1.0, 0.05)
    addonTable.crTimerScaleSlider.label:ClearAllPoints()
    addonTable.crTimerScaleSlider.label:SetPoint("TOPLEFT", addonTable.crTimerXSlider, "BOTTOMLEFT", 0, -25)
    addonTable.crTimerScaleSlider:ClearAllPoints()
    addonTable.crTimerScaleSlider:SetPoint("TOPLEFT", addonTable.crTimerScaleSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.crTimerCenteredCB = Checkbox(cc, "Center X", 280, -721)
    addonTable.crTimerCenteredCB:ClearAllPoints()
    addonTable.crTimerCenteredCB:SetPoint("TOPLEFT", addonTable.crTimerScaleSlider, "TOPLEFT", 265, -2)
    local combStatusSec = Section(cc, "Combat Status", -870)
    addonTable.combatStatusCB = Checkbox(cc, "Enable Combat Status", 15, -806)
    addonTable.combatStatusCB:ClearAllPoints()
    addonTable.combatStatusCB:SetPoint("TOPLEFT", combStatusSec, "BOTTOMLEFT", 0, -12)
    addonTable.combatStatusPreviewOnBtn = CreateStyledButton(cc, "Show Preview", 90, 22)
    addonTable.combatStatusPreviewOnBtn:ClearAllPoints()
    addonTable.combatStatusPreviewOnBtn:SetPoint("LEFT", addonTable.combatStatusCB.label, "RIGHT", 15, 0)
    addonTable.combatStatusPreviewOffBtn = CreateStyledButton(cc, "Hide Preview", 90, 22)
    addonTable.combatStatusPreviewOffBtn:SetPoint("LEFT", addonTable.combatStatusPreviewOnBtn, "RIGHT", 5, 0)
    addonTable.combatStatusXSlider = Slider(cc, "X Offset", 15, -841, -1500, 1500, 0, 1)
    addonTable.combatStatusXSlider.label:ClearAllPoints()
    addonTable.combatStatusXSlider.label:SetPoint("TOPLEFT", addonTable.combatStatusCB, "BOTTOMLEFT", 0, -25)
    addonTable.combatStatusXSlider:ClearAllPoints()
    addonTable.combatStatusXSlider:SetPoint("TOPLEFT", addonTable.combatStatusXSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.combatStatusYSlider = Slider(cc, "Y Offset", 280, -841, -1500, 1500, 280, 1)
    addonTable.combatStatusYSlider.label:ClearAllPoints()
    addonTable.combatStatusYSlider.label:SetPoint("TOPLEFT", addonTable.combatStatusXSlider.label, "TOPLEFT", 265, 0)
    addonTable.combatStatusYSlider:ClearAllPoints()
    addonTable.combatStatusYSlider:SetPoint("TOPLEFT", addonTable.combatStatusYSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.combatStatusScaleSlider = Slider(cc, "Scale", 15, -901, 0.6, 2.0, 1.0, 0.05)
    addonTable.combatStatusScaleSlider.label:ClearAllPoints()
    addonTable.combatStatusScaleSlider.label:SetPoint("TOPLEFT", addonTable.combatStatusXSlider, "BOTTOMLEFT", 0, -25)
    addonTable.combatStatusScaleSlider:ClearAllPoints()
    addonTable.combatStatusScaleSlider:SetPoint("TOPLEFT", addonTable.combatStatusScaleSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.combatStatusCenteredCB = Checkbox(cc, "Center X", 280, -916)
    addonTable.combatStatusCenteredCB:ClearAllPoints()
    addonTable.combatStatusCenteredCB:SetPoint("TOPLEFT", addonTable.combatStatusScaleSlider, "TOPLEFT", 265, -2)
    local csbd = {bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1}
    addonTable.combatStatusEnterColorBtn = CreateStyledButton(cc, "Enter Color", 90, 22)
    addonTable.combatStatusEnterColorBtn:ClearAllPoints()
    addonTable.combatStatusEnterColorBtn:SetPoint("TOPLEFT", addonTable.combatStatusScaleSlider, "BOTTOMLEFT", 0, -15)
    addonTable.combatStatusEnterColorSwatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
    addonTable.combatStatusEnterColorSwatch:SetSize(22, 22)
    addonTable.combatStatusEnterColorSwatch:SetPoint("LEFT", addonTable.combatStatusEnterColorBtn, "RIGHT", 4, 0)
    addonTable.combatStatusEnterColorSwatch:SetBackdrop(csbd)
    addonTable.combatStatusEnterColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.combatStatusEnterColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.combatStatusLeaveColorBtn = CreateStyledButton(cc, "Leave Color", 90, 22)
    addonTable.combatStatusLeaveColorBtn:ClearAllPoints()
    addonTable.combatStatusLeaveColorBtn:SetPoint("LEFT", addonTable.combatStatusEnterColorSwatch, "RIGHT", 15, 0)
    addonTable.combatStatusLeaveColorSwatch = CreateFrame("Frame", nil, cc, "BackdropTemplate")
    addonTable.combatStatusLeaveColorSwatch:SetSize(22, 22)
    addonTable.combatStatusLeaveColorSwatch:SetPoint("LEFT", addonTable.combatStatusLeaveColorBtn, "RIGHT", 4, 0)
    addonTable.combatStatusLeaveColorSwatch:SetBackdrop(csbd)
    addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.combatStatusLeaveColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  end
  local tab18 = tabFrames[18]
  if tab18 then
    local featSF = CreateFrame("ScrollFrame", "CCMFeaturesScrollFrame", tab18, "UIPanelScrollFrameTemplate")
    featSF:SetPoint("TOPLEFT", tab18, "TOPLEFT", 0, 0)
    featSF:SetPoint("BOTTOMRIGHT", tab18, "BOTTOMRIGHT", -22, 0)
    local featSC = CreateFrame("Frame", "CCMFeaturesScrollChild", featSF)
    featSC:SetSize(490, 500)
    featSF:SetScrollChild(featSC)
    local featBar = _G["CCMFeaturesScrollFrameScrollBar"]
    if featBar then
      featBar:SetPoint("TOPLEFT", featSF, "TOPRIGHT", 6, -16)
      featBar:SetPoint("BOTTOMLEFT", featSF, "BOTTOMRIGHT", 6, 16)
      local featThumb = featBar:GetThumbTexture()
      if featThumb then featThumb:SetColorTexture(0.4, 0.4, 0.45, 0.8); featThumb:SetSize(8, 40) end
      local featUp = _G["CCMFeaturesScrollFrameScrollBarScrollUpButton"]
      local featDown = _G["CCMFeaturesScrollFrameScrollBarScrollDownButton"]
      if featUp then featUp:SetAlpha(0); featUp:EnableMouse(false) end
      if featDown then featDown:SetAlpha(0); featDown:EnableMouse(false) end
    end
    SetSmoothScroll(featSF)
    local fc = featSC
    local featRadialSec = Section(fc, "Radial Circle", -12)
    addonTable.radialCB = Checkbox(fc, "Enable Radial Circle", 15, -37)
    addonTable.radialCB:ClearAllPoints()
    addonTable.radialCB:SetPoint("TOPLEFT", featRadialSec, "BOTTOMLEFT", 0, -12)
    addonTable.radialCombatCB = Checkbox(fc, "Combat Only", 200, -37)
    addonTable.radialCombatCB:ClearAllPoints()
    addonTable.radialCombatCB:SetPoint("LEFT", addonTable.radialCB.label, "RIGHT", 15, 0)
    addonTable.radialGcdCB = Checkbox(fc, "Show GCD on Radial", 350, -37)
    addonTable.radialGcdCB:ClearAllPoints()
    addonTable.radialGcdCB:SetPoint("LEFT", addonTable.radialCombatCB.label, "RIGHT", 15, 0)
    addonTable.radiusSlider = Slider(fc, "Radius", 15, -77, 10, 60, 30, 1)
    addonTable.radiusSlider.label:ClearAllPoints()
    addonTable.radiusSlider.label:SetPoint("TOPLEFT", addonTable.radialCB, "BOTTOMLEFT", 0, -25)
    addonTable.radiusSlider:ClearAllPoints()
    addonTable.radiusSlider:SetPoint("TOPLEFT", addonTable.radiusSlider.label, "BOTTOMLEFT", 0, -8)
    addonTable.radialThicknessDD, addonTable.radialThicknessLbl = StyledDropdown(fc, "Thickness", 280, -77, 180)
    addonTable.radialThicknessDD:ClearAllPoints()
    addonTable.radialThicknessDD:SetPoint("TOPLEFT", addonTable.radiusSlider, "TOPLEFT", 265, 5)
    if addonTable.radialThicknessLbl then addonTable.radialThicknessLbl:ClearAllPoints(); addonTable.radialThicknessLbl:SetPoint("BOTTOMLEFT", addonTable.radialThicknessDD, "TOPLEFT", 0, 4) end
    addonTable.radialThicknessDD:SetOptions({
      { text = "Thin", value = "thin" },
      { text = "Middle", value = "middle" },
      { text = "Thick", value = "thick" },
    })
    addonTable.radialThicknessDD:SetValue("middle")
    addonTable.colorBtn = CreateStyledButton(fc, "Ring Color", 80, 24)
    addonTable.colorBtn:ClearAllPoints()
    addonTable.colorBtn:SetPoint("TOPLEFT", addonTable.radiusSlider, "BOTTOMLEFT", 0, -15)
    addonTable.colorSwatch = CreateFrame("Frame", nil, fc, "BackdropTemplate")
    addonTable.colorSwatch:SetSize(24, 24)
    addonTable.colorSwatch:SetPoint("LEFT", addonTable.colorBtn, "RIGHT", 8, 0)
    addonTable.colorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.colorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.colorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.colorBtn:SetScript("OnClick", function()
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if not profile then return end
      local r = profile.radialColorR or 1
      local g = profile.radialColorG or 1
      local b = profile.radialColorB or 1
      local a = profile.radialAlpha or 0.8
      local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = ColorPickerFrame:GetColorAlpha() or 1
        profile.radialColorR = newR
        profile.radialColorG = newG
        profile.radialColorB = newB
        profile.radialAlpha = newA
        addonTable.colorSwatch:SetBackdropColor(newR, newG, newB, 1)
        if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end
      end
      local function OnCancel(prevValues)
        profile.radialColorR = prevValues.r
        profile.radialColorG = prevValues.g
        profile.radialColorB = prevValues.b
        profile.radialAlpha = a
        addonTable.colorSwatch:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, 1)
        if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end
      end
      if addonTable.ShowColorPicker then
        addonTable.ShowColorPicker({
          r = r, g = g, b = b,
          opacity = a, hasOpacity = true,
          swatchFunc = OnColorChanged,
          opacityFunc = OnColorChanged,
          cancelFunc = OnCancel,
        })
      else
        ColorPickerFrame:SetupColorPickerAndShow({
          r = r, g = g, b = b,
          opacity = a, hasOpacity = true,
          swatchFunc = OnColorChanged,
          opacityFunc = OnColorChanged,
          cancelFunc = OnCancel,
        })
      end
    end)
    local featUsefulSec = Section(fc, "Useful Features", -195)
    addonTable.autoRepairCB = Checkbox(fc, "Auto Repair (Guild > Gold)", 15, -220)
    addonTable.autoRepairCB:ClearAllPoints()
    addonTable.autoRepairCB:SetPoint("TOPLEFT", featUsefulSec, "BOTTOMLEFT", 0, -12)
    addonTable.showTooltipIDsCB = Checkbox(fc, "Show Spell/Item IDs in Tooltip", 280, -220)
    addonTable.showTooltipIDsCB:ClearAllPoints()
    addonTable.showTooltipIDsCB:SetPoint("TOPLEFT", addonTable.autoRepairCB, "TOPLEFT", 265, 0)
    addonTable.compactMinimapIconsCB = Checkbox(fc, "Compact Minimap Icons", 15, -245)
    addonTable.compactMinimapIconsCB:ClearAllPoints()
    addonTable.compactMinimapIconsCB:SetPoint("TOPLEFT", addonTable.autoRepairCB, "BOTTOMLEFT", 0, -5)
    addonTable.enhancedTooltipCB = Checkbox(fc, "Enhanced Tooltip", 280, -245)
    addonTable.enhancedTooltipCB:ClearAllPoints()
    addonTable.enhancedTooltipCB:SetPoint("TOPLEFT", addonTable.showTooltipIDsCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoQuestCB = Checkbox(fc, "Auto Quest Accept/Turn-in", 15, -270)
    addonTable.autoQuestCB:ClearAllPoints()
    addonTable.autoQuestCB:SetPoint("TOPLEFT", addonTable.compactMinimapIconsCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoSellJunkCB = Checkbox(fc, "Auto Sell Junk", 280, -270)
    addonTable.autoSellJunkCB:ClearAllPoints()
    addonTable.autoSellJunkCB:SetPoint("TOPLEFT", addonTable.enhancedTooltipCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoQuestExcludeDailyCB = Checkbox(fc, "Exclude Daily", 35, -295)
    addonTable.autoQuestExcludeDailyCB:ClearAllPoints()
    addonTable.autoQuestExcludeDailyCB:SetPoint("TOPLEFT", addonTable.autoQuestCB, "BOTTOMLEFT", 20, -5)
    addonTable.autoFillDeleteCB = Checkbox(fc, "Auto-fill DELETE", 280, -295)
    addonTable.autoFillDeleteCB:ClearAllPoints()
    addonTable.autoFillDeleteCB:SetPoint("TOPLEFT", addonTable.autoSellJunkCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoQuestExcludeWeeklyCB = Checkbox(fc, "Exclude Weekly", 35, -320)
    addonTable.autoQuestExcludeWeeklyCB:ClearAllPoints()
    addonTable.autoQuestExcludeWeeklyCB:SetPoint("TOPLEFT", addonTable.autoQuestExcludeDailyCB, "BOTTOMLEFT", 0, -5)
    addonTable.quickRoleSignupCB = Checkbox(fc, "Quick Role Signup", 280, -320)
    addonTable.quickRoleSignupCB:ClearAllPoints()
    addonTable.quickRoleSignupCB:SetPoint("TOPLEFT", addonTable.autoFillDeleteCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoQuestExcludeTrivialCB = Checkbox(fc, "Exclude Trivial", 35, -345)
    addonTable.autoQuestExcludeTrivialCB:ClearAllPoints()
    addonTable.autoQuestExcludeTrivialCB:SetPoint("TOPLEFT", addonTable.autoQuestExcludeWeeklyCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoQuestExcludeCompletedCB = Checkbox(fc, "Exclude Completed", 35, -370)
    addonTable.autoQuestExcludeCompletedCB:ClearAllPoints()
    addonTable.autoQuestExcludeCompletedCB:SetPoint("TOPLEFT", addonTable.autoQuestExcludeTrivialCB, "BOTTOMLEFT", 0, -5)
    addonTable.autoQuestRewardDD, addonTable.autoQuestRewardLbl = StyledDropdown(fc, "Multi-Reward", 280, -360, 150)
    addonTable.autoQuestRewardDD:ClearAllPoints()
    addonTable.autoQuestRewardDD:SetPoint("TOPLEFT", addonTable.autoQuestExcludeCompletedCB, "TOPLEFT", 245, 0)
    if addonTable.autoQuestRewardLbl then addonTable.autoQuestRewardLbl:ClearAllPoints(); addonTable.autoQuestRewardLbl:SetPoint("BOTTOMLEFT", addonTable.autoQuestRewardDD, "TOPLEFT", 0, 4) end
    addonTable.autoQuestRewardDD:SetOptions({{text = "Skip (Manual)", value = "skip"}, {text = "Best Gold Value", value = "gold"}})
    local featCharSec = Section(fc, "Character Panel Enhancement", -428)
    addonTable.betterItemLevelCB = Checkbox(fc, "Better Item Level (2 Decimals)", 15, -453)
    addonTable.betterItemLevelCB:ClearAllPoints()
    addonTable.betterItemLevelCB:SetPoint("TOPLEFT", featCharSec, "BOTTOMLEFT", 0, -12)
    addonTable.showEquipDetailsCB = Checkbox(fc, "Show Equipment Details", 280, -453)
    addonTable.showEquipDetailsCB:ClearAllPoints()
    addonTable.showEquipDetailsCB:SetPoint("TOPLEFT", addonTable.betterItemLevelCB, "TOPLEFT", 265, 0)
    local equipSubLbl = fc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    equipSubLbl:SetPoint("TOPLEFT", addonTable.showEquipDetailsCB.label, "BOTTOMLEFT", 0, -2)
    equipSubLbl:SetText("(sockets / icon ilvl / enhancements)")
    equipSubLbl:SetTextColor(0.5, 0.5, 0.5)
  end
end
C_Timer.After(0, InitTabs)
