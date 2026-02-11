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
do
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM and LSM.RegisterCallback and not addonTable._ccmLsmStatusbarRegistered then
    addonTable._ccmLsmStatusbarRegistered = true
    LSM.RegisterCallback(addonTable, "LibSharedMedia_Registered", function(_, mediaType)
      if mediaType == "statusbar" then
        RefreshTextureDropdownOptions()
      elseif mediaType == "font" then
        RefreshFontDropdownOptions()
      end
    end)
  end
end
local function SetSmoothScroll(scrollFrame, step)
  step = step or 20
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local bar = _G[self:GetName() .. "ScrollBar"]
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
  Section(gc, "UI Scale", -60)
  addonTable.uiScaleDD = StyledDropdown(gc, nil, 15, -85, 150)
  addonTable.uiScaleDD:SetOptions({
    {text = "Disabled", value = "disabled"},
    {text = "1080p (0.71)", value = "1080p"},
    {text = "1440p (0.53)", value = "1440p"},
    {text = "Custom", value = "custom"},
  })
  addonTable.uiScaleSlider = Slider(gc, "Custom Scale", 200, -78, 0.4, 1.0, 0.71, 0.01)
  Section(gc, "Custom Bars", -143)
  addonTable.customBarsCountSlider = Slider(gc, "Number of Custom Bars (0-3)", 15, -169, 0, 3, 0, 1)
  Section(gc, "Icon Appearance", -246)
  addonTable.iconBorderSlider = Slider(gc, "Icon Border Size (0-3)", 15, -271, 0, 3, 1, 1)
  addonTable.strataDD, addonTable.strataLbl = StyledDropdown(gc, "Frame Strata", 280, -271, 120)
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
  Section(gc, "Personal Resource Bar", -328)
  addonTable.prbCB = Checkbox(gc, "Use Personal Resource Bar", 15, -353)
  Section(gc, "Castbar", -383)
  addonTable.castbarCB = Checkbox(gc, "Use Custom Castbar", 15, -408)
  addonTable.focusCastbarCB = Checkbox(gc, "Use Custom Focus Castbar", 280, -408)
  Section(gc, "Player Debuffs", -438)
  addonTable.playerDebuffsCB = Checkbox(gc, "Enable Player Debuffs Skinning", 15, -463)
  Section(gc, "Unit Frame Customization", -488)
  addonTable.unitFrameCustomizationCB = Checkbox(gc, "Enable Unit Frame Customization", 15, -513)
  Section(gc, "Example Profiles", -548)
  local exampleDesc = gc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  exampleDesc:SetPoint("TOPLEFT", gc, "TOPLEFT", 15, -578)
  exampleDesc:SetText("|cff888888Load a preset profile optimized for your role. This will overwrite your current profile settings.|r")
  exampleDesc:SetJustifyH("LEFT")
  exampleDesc:SetWidth(500)
  local function CreateExampleProfileButton(parent, label, role, xOff, yOff, iconColor)
    local btn = CreateStyledButton(parent, label, 120, 28)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    btn.role = role
    local indicator = btn:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(8, 8)
    indicator:SetPoint("LEFT", btn, "LEFT", 8, 0)
    indicator:SetColorTexture(iconColor.r, iconColor.g, iconColor.b, 1)
    local fs = btn:GetFontString()
    if fs then fs:SetPoint("CENTER", btn, "CENTER", 4, 0) end
    return btn
  end
  addonTable.exampleProfileDPSBtn = CreateExampleProfileButton(gc, "DPS", "DPS", 15, -608, {r=1, g=0.3, b=0.3})
  addonTable.exampleProfileTankBtn = CreateExampleProfileButton(gc, "Tank", "Tank", 145, -608, {r=0.3, g=0.5, b=1})
  addonTable.exampleProfileHealerBtn = CreateExampleProfileButton(gc, "Healer", "Healer", 275, -608, {r=0.3, g=1, b=0.5})
  local exampleNote = gc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  exampleNote:SetPoint("TOPLEFT", gc, "TOPLEFT", 15, -648)
  exampleNote:SetText("|cffFFD100Note:|r After loading, customize the profile to your needs and add spells to the Custom Bars.")
  exampleNote:SetJustifyH("LEFT")
  exampleNote:SetWidth(500)
  exampleNote:SetTextColor(0.7, 0.7, 0.7)
  local tab2 = tabFrames[2]
  addonTable.cursor = {}
  local cur = addonTable.cursor
  Section(tab2, "Cursor CDM Settings", -12)
  cur.enabledCB = Checkbox(tab2, "Enable", 15, -40)
  cur.combatOnlyCB = Checkbox(tab2, "Combat Only", 100, -40)
  cur.gcdCB = Checkbox(tab2, "Show GCD", 230, -40)
  cur.cooldownModeDD, cur.cooldownModeLbl = StyledDropdown(tab2, "On Cooldown", 350, -32, 110)
  cur.cooldownModeDD:SetOptions({{text = "Show", value = "show"}, {text = "Hide", value = "hide"}, {text = "Desaturate", value = "desaturate"}, {text = "Hide Available", value = "hideAvailable"}})
  cur.showModeDD, cur.showModeLbl = StyledDropdown(tab2, "Show", 500, -32, 140)
  cur.showModeDD:SetOptions({{text = "Always", value = "always"}, {text = "Raid", value = "raid"}, {text = "Dungeon", value = "dungeon"}, {text = "Dungeon & Raid", value = "raidanddungeon"}})
  cur.iconSizeSlider = Slider(tab2, "Icon Size", 15, -80, 10, 80, 23, 1)
  cur.spacingSlider = Slider(tab2, "Spacing", 280, -80, -3, 10, 2, 1)
  cur.offsetXSlider = Slider(tab2, "Cursor Offset X", 15, -135, -100, 100, 10, 1)
  cur.offsetYSlider = Slider(tab2, "Cursor Offset Y", 280, -135, -100, 100, 25, 1)
  cur.cdTextSlider = Slider(tab2, "CD Text Scale", 15, -190, 0, 2.0, 1.0, 0.1)
  cur.stackTextSlider = Slider(tab2, "Stack Text Scale", 15, -245, 0.5, 2.0, 1.0, 0.1)
  cur.stackXSlider = Slider(tab2, "Stack Offset X", 280, -245, -20, 20, 0, 1)
  cur.stackYSlider = Slider(tab2, "Stack Offset Y", 15, -300, -20, 20, 0, 1)
  cur.iconsPerRowSlider = Slider(tab2, "Icons Per Row", 280, -300, 1, 20, 10, 1)
  cur.directionDD, cur.directionLbl = StyledDropdown(tab2, "Direction", 15, -360, 120)
  cur.directionDD:SetOptions({{text = "Horizontal", value = "horizontal"}, {text = "Vertical", value = "vertical"}})
  cur.stackAnchorDD, cur.stackAnchorLbl = StyledDropdown(tab2, "Stack Anchor", 170, -360, 120)
  cur.stackAnchorDD:SetOptions({
    {text = "TOPLEFT", value = "TOPLEFT"}, {text = "TOP", value = "TOP"}, {text = "TOPRIGHT", value = "TOPRIGHT"},
    {text = "LEFT", value = "LEFT"}, {text = "CENTER", value = "CENTER"}, {text = "RIGHT", value = "RIGHT"},
    {text = "BOTTOMLEFT", value = "BOTTOMLEFT"}, {text = "BOTTOM", value = "BOTTOM"}, {text = "BOTTOMRIGHT", value = "BOTTOMRIGHT"},
  })
  cur.buffOverlayCB = Checkbox(tab2, "Damage Reduction Buff Overlay", 320, -380)
  Section(tab2, "Tracked Spells / Items", -420)
  cur.spellBg = CreateFrame("Frame", nil, tab2, "BackdropTemplate")
  cur.spellBg:SetPoint("TOPLEFT", tab2, "TOPLEFT", 15, -455)
  cur.spellBg:SetPoint("BOTTOMRIGHT", tab2, "BOTTOMRIGHT", -15, 70)
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
  cur.addLbl = tab2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cur.addLbl:SetPoint("BOTTOMLEFT", tab2, "BOTTOMLEFT", 15, 38)
  cur.addLbl:SetText("Spell/Item ID:")
  cur.addLbl:SetTextColor(0.9, 0.9, 0.9)
  cur.addBox = CreateFrame("EditBox", nil, tab2, "BackdropTemplate")
  cur.addBox:SetSize(80, 24)
  cur.addBox:SetPoint("LEFT", cur.addLbl, "RIGHT", 8, 0)
  cur.addBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cur.addBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
  cur.addBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  cur.addBox:SetFontObject("GameFontHighlight")
  cur.addBox:SetAutoFocus(false)
  cur.addBox:SetTextInsets(6, 6, 0, 0)
  cur.addBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
  cur.addSpellBtn = CreateStyledButton(tab2, "Add Spell", 70, 24)
  cur.addSpellBtn:SetPoint("LEFT", cur.addBox, "RIGHT", 8, 0)
  cur.addItemBtn = CreateStyledButton(tab2, "Add Item", 70, 24)
  cur.addItemBtn:SetPoint("LEFT", cur.addSpellBtn, "RIGHT", 5, 0)
  cur.addSep = tab2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cur.addSep:SetPoint("LEFT", cur.addItemBtn, "RIGHT", 6, 0)
  cur.addSep:SetText("|")
  cur.addSep:SetTextColor(0.4, 0.4, 0.45, 1)
  cur.addTrinketsBtn = CreateStyledButton(tab2, "Add Trinkets", 90, 24)
  cur.addTrinketsBtn:SetPoint("LEFT", cur.addSep, "RIGHT", 6, 0)
  cur.addRacialBtn = CreateStyledButton(tab2, "Add Racial", 80, 24)
  cur.addRacialBtn:SetPoint("LEFT", cur.addTrinketsBtn, "RIGHT", 5, 0)
  cur.addPotionBtn = CreateStyledButton(tab2, "Add Potion", 80, 24)
  cur.addPotionBtn:SetPoint("LEFT", cur.addRacialBtn, "RIGHT", 5, 0)
  cur.addGCSBtn = CreateStyledButton(tab2, "Add GCS", 65, 24)
  cur.addGCSBtn:SetPoint("LEFT", cur.addPotionBtn, "RIGHT", 5, 0)
  cur.dragDropHint = tab2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cur.dragDropHint:SetPoint("BOTTOMLEFT", tab2, "BOTTOMLEFT", 15, 16)
  cur.dragDropHint:SetText("Tip: Drag & drop spells/items directly into this window!")
  cur.dragDropHint:SetTextColor(0.5, 0.5, 0.5)
  local function CreateCustomBarTab(tabFrame, barNum, yOffset)
    local cb = {}
    Section(tabFrame, "Custom Bar " .. barNum .. " Settings", -12)
    cb.outOfCombatCB = Checkbox(tabFrame, "Show Out of Combat", 15, -40)
    cb.gcdCB = Checkbox(tabFrame, "Show GCD", 180, -40)
    cb.centeredCB = Checkbox(tabFrame, "Centered", 300, -40)
    cb.cdModeDD, cb.cdModeLbl = StyledDropdown(tabFrame, "On Cooldown", 400, -32, 110)
    cb.cdModeDD:SetOptions({{text = "Show", value = "show"}, {text = "Hide", value = "hide"}, {text = "Desaturate", value = "desaturate"}, {text = "Hide Available", value = "hideAvailable"}})
    cb.showModeDD, cb.showModeLbl = StyledDropdown(tabFrame, "Show", 550, -32, 140)
    cb.showModeDD:SetOptions({{text = "Always", value = "always"}, {text = "Raid", value = "raid"}, {text = "Dungeon", value = "dungeon"}, {text = "Dungeon & Raid", value = "raidanddungeon"}})
    cb.iconSizeSlider = Slider(tabFrame, "Icon Size", 15, -80, 10, 80, 30, 1)
    cb.spacingSlider = Slider(tabFrame, "Spacing", 280, -80, -3, 10, 2, 1)
    cb.xSlider = Slider(tabFrame, "Bar X Offset", 15, -135, -500, 500, 0, 1)
    cb.ySlider = Slider(tabFrame, "Bar Y Offset", 280, -135, -500, 500, yOffset, 1)
    cb.cdTextSlider = Slider(tabFrame, "CD Text Scale", 15, -190, 0, 2.0, 1.0, 0.1)
    cb.stackTextSlider = Slider(tabFrame, "Stack Text Scale", 280, -190, 0.5, 2.0, 1.0, 0.1)
    cb.stackXSlider = Slider(tabFrame, "Stack Offset X", 15, -245, -20, 20, 0, 1)
    cb.stackYSlider = Slider(tabFrame, "Stack Offset Y", 280, -245, -20, 20, 0, 1)
    cb.iconsPerRowSlider = Slider(tabFrame, "Icons Per Row", 15, -300, 1, 20, 20, 1)
    cb.buffOverlayCB = Checkbox(tabFrame, "Damage Reduction Buff Overlay", 280, -320)
    cb.directionDD, cb.directionLbl = StyledDropdown(tabFrame, "Direction", 15, -360, 100)
    cb.directionDD:SetOptions({{text = "Horizontal", value = "horizontal"}, {text = "Vertical", value = "vertical"}})
    cb.anchorDD, cb.anchorLbl = StyledDropdown(tabFrame, "Anchor", 150, -360, 80)
    cb.anchorDD:SetOptions({{text = "Left", value = "LEFT"}, {text = "Right", value = "RIGHT"}})
    cb.growthDD, cb.growthLbl = StyledDropdown(tabFrame, "Growth", 265, -360, 80)
    cb.growthDD:SetOptions({{text = "Up", value = "UP"}, {text = "Down", value = "DOWN"}})
    cb.stackAnchorDD, cb.stackAnchorLbl = StyledDropdown(tabFrame, "Stack Anchor", 370, -360, 110)
    cb.stackAnchorDD:SetOptions({
      {text = "TOPLEFT", value = "TOPLEFT"}, {text = "TOP", value = "TOP"}, {text = "TOPRIGHT", value = "TOPRIGHT"},
      {text = "LEFT", value = "LEFT"}, {text = "CENTER", value = "CENTER"}, {text = "RIGHT", value = "RIGHT"},
      {text = "BOTTOMLEFT", value = "BOTTOMLEFT"}, {text = "BOTTOM", value = "BOTTOM"}, {text = "BOTTOMRIGHT", value = "BOTTOMRIGHT"},
    })
    cb.anchorTargetLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.anchorTargetLbl:SetPoint("BOTTOMLEFT", cb.stackAnchorDD, "TOPRIGHT", 10, 2)
    cb.anchorTargetLbl:SetText("Anchor To")
    cb.anchorTargetLbl:SetTextColor(0.9, 0.9, 0.9)
    cb.anchorTargetBox = CreateFrame("EditBox", nil, tabFrame, "BackdropTemplate")
    cb.anchorTargetBox:SetSize(100, 24)
    cb.anchorTargetBox:SetPoint("TOPLEFT", cb.stackAnchorDD, "TOPRIGHT", 10, 0)
    cb.anchorTargetBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    cb.anchorTargetBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
    cb.anchorTargetBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    cb.anchorTargetBox:SetFontObject("GameFontHighlight")
    cb.anchorTargetBox:SetAutoFocus(false)
    cb.anchorTargetBox:SetTextInsets(6, 6, 0, 0)
    cb.anchorTargetBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    Section(tabFrame, "Tracked Spells / Items", -420)
    cb.spellBg = CreateFrame("Frame", nil, tabFrame, "BackdropTemplate")
    cb.spellBg:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 15, -455)
    cb.spellBg:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -15, 70)
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
    cb.addLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.addLbl:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 15, 38)
    cb.addLbl:SetText("Spell/Item ID:")
    cb.addLbl:SetTextColor(0.9, 0.9, 0.9)
    cb.addBox = CreateFrame("EditBox", nil, tabFrame, "BackdropTemplate")
    cb.addBox:SetSize(80, 24)
    cb.addBox:SetPoint("LEFT", cb.addLbl, "RIGHT", 8, 0)
    cb.addBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    cb.addBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
    cb.addBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    cb.addBox:SetFontObject("GameFontHighlight")
    cb.addBox:SetAutoFocus(false)
    cb.addBox:SetTextInsets(6, 6, 0, 0)
    cb.addBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    cb.addSpellBtn = CreateStyledButton(tabFrame, "Add Spell", 70, 24)
    cb.addSpellBtn:SetPoint("LEFT", cb.addBox, "RIGHT", 8, 0)
    cb.addItemBtn = CreateStyledButton(tabFrame, "Add Item", 70, 24)
    cb.addItemBtn:SetPoint("LEFT", cb.addSpellBtn, "RIGHT", 5, 0)
    cb.addSep = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.addSep:SetPoint("LEFT", cb.addItemBtn, "RIGHT", 6, 0)
    cb.addSep:SetText("|")
    cb.addSep:SetTextColor(0.4, 0.4, 0.45, 1)
    cb.addTrinketsBtn = CreateStyledButton(tabFrame, "Add Trinkets", 90, 24)
    cb.addTrinketsBtn:SetPoint("LEFT", cb.addSep, "RIGHT", 6, 0)
    cb.addRacialBtn = CreateStyledButton(tabFrame, "Add Racial", 80, 24)
    cb.addRacialBtn:SetPoint("LEFT", cb.addTrinketsBtn, "RIGHT", 5, 0)
    cb.addPotionBtn = CreateStyledButton(tabFrame, "Add Potion", 80, 24)
    cb.addPotionBtn:SetPoint("LEFT", cb.addRacialBtn, "RIGHT", 5, 0)
    cb.addGCSBtn = CreateStyledButton(tabFrame, "Add GCS", 65, 24)
    cb.addGCSBtn:SetPoint("LEFT", cb.addPotionBtn, "RIGHT", 5, 0)
    cb.dragDropHint = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.dragDropHint:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 15, 16)
    cb.dragDropHint:SetText("Tip: Drag & drop spells/items directly into this window!")
    cb.dragDropHint:SetTextColor(0.5, 0.5, 0.5)
    return cb
  end
  addonTable.cb1 = CreateCustomBarTab(tabFrames[3], 1, -200)
  addonTable.cb2 = CreateCustomBarTab(tabFrames[4], 2, -250)
  addonTable.cb3 = CreateCustomBarTab(tabFrames[5], 3, -300)
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
  Section(b6, "Skinning Mode", -125)
  addonTable.skinningModeDD = StyledDropdown(b6, nil, 15, -150, 150)
  addonTable.skinningModeDD:SetOptions({
    {text = "None", value = "none"},
    {text = "CCM Built-in", value = "ccm"},
    {text = "Masque", value = "masque"},
  })
  addonTable.disableBlizzCDMCB = Checkbox(b6, "Disable Blizz CDM", 195, -150)
  addonTable.openBlizzCDMBtn = CreateStyledButton(b6, "Open Blizzard CDM", 145, 22)
  addonTable.openBlizzCDMBtn:SetPoint("TOPLEFT", b6, "TOPLEFT", 360, -150)
  addonTable.openEditModeBtn = CreateStyledButton(b6, "Open Edit Mode", 145, 22)
  addonTable.openEditModeBtn:SetPoint("LEFT", addonTable.openBlizzCDMBtn, "RIGHT", 6, 0)
  Section(b6, "Attach to Cursor", -195)
  addonTable.buffBarCB = Checkbox(b6, "Attach Buff Bar", 15, -220)
  addonTable.essentialBarCB = Checkbox(b6, "Attach Essential Bar", 15, -250)
  local attachNote = b6:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  attachNote:SetPoint("TOPLEFT", b6, "TOPLEFT", 15, -275)
  attachNote:SetText("|cff888888Note: Icon settings under Cursor CDM if Bars attached.|r")
  addonTable.buffSizeSlider = Slider(b6, "Buff Bar Size Offset", 280, -213, -20, 20, 0, 1)
  Section(b6, "Standalone Blizzard Bars", -305)
  addonTable.standalone = {}
  local sa = addonTable.standalone
  sa.skinBuffCB = Checkbox(b6, "Skin Buff Bar", 15, -330)
  sa.skinEssentialCB = Checkbox(b6, "Skin Essential Bar", 200, -330)
  sa.skinUtilityCB = Checkbox(b6, "Skin Utility Bar", 385, -330)
  sa.buffCenteredCB = Checkbox(b6, "Center Buff", 15, -360)
  sa.essentialCenteredCB = Checkbox(b6, "Center Essential", 200, -360)
  sa.utilityCenteredCB = Checkbox(b6, "Center Utility", 385, -360)
  sa.spacingSlider = Slider(b6, "Spacing", 15, -410, -3, 10, 0, 1)
  sa.borderSizeSlider = Slider(b6, "Border Size", 280, -410, 0, 5, 1, 1)
  Section(b6, "Buff Bar Settings", -460)
  sa.buffRowsDD, sa.buffRowsLbl = StyledDropdown(b6, "Buff Rows", 15, -490, 120)
  sa.buffRowsDD:SetOptions({{text = "1 Row", value = "1"}, {text = "2 Rows", value = "2"}})
  sa.buffGrowDD, sa.buffGrowLbl = StyledDropdown(b6, "Buff Grow", 150, -490, 120)
  sa.buffGrowDD:SetOptions({{text = "Right", value = "right"}, {text = "Left", value = "left"}})
  sa.buffRowGrowDD, sa.buffRowGrowLbl = StyledDropdown(b6, "Buff Up/Down", 280, -490, 120)
  sa.buffRowGrowDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
  sa.buffSizeSlider = Slider(b6, "Buff Size", 15, -550, 20, 80, 45, 0.5)
  sa.buffYSlider = Slider(b6, "Buff Y", 280, -550, -800, 800, 0, 0.5)
  sa.buffXSlider = Slider(b6, "Buff X", 280, -600, -800, 800, -150, 0.5)
  sa.buffIconsPerRowSlider = Slider(b6, "Buff Icons/Row", 280, -650, 0, 20, 0, 1)
  Section(b6, "Essential Bar Settings", -710)
  sa.essentialRowsDD, sa.essentialRowsLbl = StyledDropdown(b6, "Essential Rows", 15, -740, 120)
  sa.essentialRowsDD:SetOptions({{text = "1 Row", value = "1"}, {text = "2 Rows", value = "2"}})
  sa.essentialGrowDD, sa.essentialGrowLbl = StyledDropdown(b6, "Essential Grow", 150, -740, 120)
  sa.essentialGrowDD:SetOptions({{text = "Right", value = "right"}, {text = "Left", value = "left"}})
  sa.essentialRowGrowDD, sa.essentialRowGrowLbl = StyledDropdown(b6, "Essential Up/Down", 280, -740, 120)
  sa.essentialRowGrowDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
  sa.essentialSizeSlider = Slider(b6, "Essential Size", 15, -800, 20, 80, 45, 0.5)
  sa.essentialYSlider = Slider(b6, "Essential Y", 280, -800, -800, 800, 50, 0.5)
  sa.essentialSecondRowSizeSlider = Slider(b6, "Essential Row 2 Size", 15, -850, 20, 80, 45, 0.5)
  sa.essentialXSlider = Slider(b6, "Essential X", 280, -850, -800, 800, 0, 0.5)
  sa.essentialIconsPerRowSlider = Slider(b6, "Essential Icons/Row", 280, -900, 0, 20, 0, 1)
  local utilitySectionLbl = Section(b6, "Utility Bar Settings", -960)
  local utilitySectionLine = b6:CreateTexture(nil, "OVERLAY")
  utilitySectionLine:SetHeight(2)
  utilitySectionLine:SetPoint("TOPLEFT", b6, "TOPLEFT", 150, -960)
  utilitySectionLine:SetPoint("TOPRIGHT", b6, "TOPRIGHT", -15, -960)
  utilitySectionLine:SetColorTexture(0.4, 0.4, 0.45, 1)
  sa.utilityRowsDD, sa.utilityRowsLbl = StyledDropdown(b6, "Utility Rows", 15, -990, 120)
  sa.utilityRowsDD:SetOptions({{text = "1 Row", value = "1"}, {text = "2 Rows", value = "2"}})
  sa.utilityGrowDD, sa.utilityGrowLbl = StyledDropdown(b6, "Utility Grow", 150, -990, 120)
  sa.utilityGrowDD:SetOptions({{text = "Right", value = "right"}, {text = "Left", value = "left"}})
  sa.utilityRowGrowDD, sa.utilityRowGrowLbl = StyledDropdown(b6, "Utility Up/Down", 280, -990, 120)
  sa.utilityRowGrowDD:SetOptions({{text = "Down", value = "down"}, {text = "Up", value = "up"}})
  sa.utilityAutoWidthDD, sa.utilityAutoWidthLbl = StyledDropdown(b6, "Utility Auto Width", 410, -990, 120)
  sa.utilitySizeSlider = Slider(b6, "Utility Size", 15, -1050, 20, 80, 45, 0.5)
  sa.utilityYSlider = Slider(b6, "Utility Y", 280, -1050, -800, 800, -50, 0.5)
  sa.utilityXSlider = Slider(b6, "Utility X", 280, -1100, -800, 800, 150, 0.5)
  sa.utilityIconsPerRowSlider = Slider(b6, "Utility Icons/Row", 280, -1150, 0, 20, 0, 1)
  sa.utilityAutoWidthDD:SetOptions({
    {text = "Off", value = "off"},
    {text = "Essential Bar", value = "essential"},
    {text = "CBar 1", value = "cbar1"},
    {text = "CBar 2", value = "cbar2"},
    {text = "CBar 3", value = "cbar3"},
  })
  blizzScrollChild:SetHeight(1320)
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
    PRBSection("General")
    prb.clampBarsCB = Checkbox(pc, "Clamp Bars", COL1, y)
    prb.centeredCB = Checkbox(pc, "Center", 120, y)
    prb.showHealthCB = Checkbox(pc, "Health", 200, y)
    prb.showPowerCB = Checkbox(pc, "Power", 275, y)
    prb.showClassPowerCB = Checkbox(pc, "Class Power", 355, y)
    y = y - 30
    prb.showModeDD, prb.showModeLbl = StyledDropdown(pc, "Show", COL1, y, 120)
    prb.showModeDD:SetOptions({{text = "Always", value = "always"}, {text = "In Combat", value = "combat"}})
    prb.anchorDD, prb.anchorLbl = StyledDropdown(pc, "Clamp Anchor", COL1 + 130, y, 120)
    prb.anchorDD:SetOptions({{text = "Top", value = "top"}, {text = "Bottom", value = "bottom"}})
    prb.autoWidthDD, prb.autoWidthLbl = StyledDropdown(pc, "Auto Width", COL2 + 6, y, 140)
    prb.autoWidthDD:SetOptions({{text = "Off", value = "off"}, {text = "CBar 1", value = "cbar1"}, {text = "CBar 2", value = "cbar2"}, {text = "CBar 3", value = "cbar3"}, {text = "Essential Bar", value = "essential"}})
    prb.bgColorBtn, prb.bgColorSwatch = ColorBtn("BG Color", COL2 + 160, y - 17, 0.1, 0.1, 0.1)
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
    prb.absorbModeDD, prb.absorbModeLbl = StyledDropdown(pc, "Absorb", 295, y, 130)
    prb.absorbModeDD:SetOptions({
      {text = "Off", value = "off"},
      {text = "Shield", value = "shield"},
    })
    y = y - 50
    prb.absorbStripesCB = Checkbox(pc, "Absorb Stripes", COL1, y)
    prb.healAbsorbCB = Checkbox(pc, "Heal Absorb", 170, y)
    prb.overAbsorbBarCB = Checkbox(pc, "Overabsorb", 295, y)
    prb.healPredCB = Checkbox(pc, "Heal Prediction", 420, y)
    y = y - 25
    prb.healthColorBtn, prb.healthColorSwatch = ColorBtn("Bar Color", COL1, y - 22, 0, 0.8, 0)
    prb.healthTextColorBtn, prb.healthTextColorSwatch = ColorBtn("Text Color", COL1 + 110, y - 22, 1, 1, 1)
    prb.useClassColorCB = Checkbox(pc, "Use Class Color", COL1 + 220, y - 22)
    y = y - 50
    prb.healthElements = {
      prb.healthHeader, prb.healthLine,
      prb.healthHeightSlider, prb.healthHeightSlider.label, prb.healthHeightSlider.valueText, prb.healthHeightSlider.valueTextBg, prb.healthHeightSlider.upBtn, prb.healthHeightSlider.downBtn,
      prb.healthYOffsetSlider, prb.healthYOffsetSlider.label, prb.healthYOffsetSlider.valueText, prb.healthYOffsetSlider.valueTextBg, prb.healthYOffsetSlider.upBtn, prb.healthYOffsetSlider.downBtn,
      prb.healthTextScaleSlider, prb.healthTextScaleSlider.label, prb.healthTextScaleSlider.valueText, prb.healthTextScaleSlider.valueTextBg, prb.healthTextScaleSlider.upBtn, prb.healthTextScaleSlider.downBtn,
      prb.healthTextureDD, prb.healthTextureLbl,
      prb.healthTextDD, prb.healthTextLbl,
      prb.healAbsorbCB, prb.healAbsorbCB.label,
      prb.absorbModeDD, prb.absorbModeLbl,
      prb.absorbStripesCB, prb.absorbStripesCB.label,
      prb.healPredCB, prb.healPredCB.label,
      prb.overAbsorbBarCB, prb.overAbsorbBarCB.label,
      prb.healthTextYSlider, prb.healthTextYSlider.label, prb.healthTextYSlider.valueText, prb.healthTextYSlider.valueTextBg, prb.healthTextYSlider.upBtn, prb.healthTextYSlider.downBtn,
      prb.healthColorBtn, prb.healthColorSwatch, prb.healthTextColorBtn, prb.healthTextColorSwatch,
      prb.useClassColorCB, prb.useClassColorCB.label,
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
    y = y - 50
    prb.powerTextDD, prb.powerTextLbl = StyledDropdown(pc, "Text", COL2 + 6, y - 4, 100)
    prb.powerTextDD:SetOptions({{text = "Hidden", value = "hidden"}, {text = "Percent", value = "percent"}, {text = "Percent #", value = "percentnumber"}, {text = "Value", value = "value"}, {text = "Both", value = "both"}})
    prb.powerColorBtn, prb.powerColorSwatch = ColorBtn("Bar Color", COL1, y - 22, 0, 0.5, 1)
    prb.powerTextColorBtn, prb.powerTextColorSwatch = ColorBtn("Text Color", COL1 + 110, y - 22, 1, 1, 1)
    y = y - 50
    prb.usePowerTypeColorCB = Checkbox(pc, "Use Power Type Color", COL1, y)
    y = y - 35
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
      local cpConfig = addonTable.GetClassPowerConfig and addonTable.GetClassPowerConfig()
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
    castbarScrollChild:SetSize(490, 800)
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
    local y = -5
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
    y = y - 30
    cbar.widthSlider = Slider(cc, "Bar Width", COL1, y, 50, 500, 250, 1)
    cbar.autoWidthDD, cbar.autoWidthLbl = StyledDropdown(cc, "Auto Width", COL2 + 6, y, 140)
    cbar.autoWidthDD:SetOptions({{text = "Off", value = "off"}, {text = "CBar 1", value = "cbar1"}, {text = "CBar 2", value = "cbar2"}, {text = "CBar 3", value = "cbar3"}, {text = "Essential Bar", value = "essential"}, {text = "Utility Bar", value = "utility"}, {text = "PRB Health", value = "prbhealth"}, {text = "PRB Power", value = "prbpower"}})
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
    focusCastbarScrollChild:SetSize(490, 800)
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
    local y = -5
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
    addonTable.debuffs = {}
    local db = addonTable.debuffs
    Section(dc, "Player Debuffs Skinning", -12, -230)
    db.sizeSlider = Slider(dc, "Icon Size", 15, -52, 16, 100, 32, 1)
    db.spacingSlider = Slider(dc, "Spacing", 280, -52, 0, 20, 2, 1)
    db.xSlider = Slider(dc, "X Offset", 15, -107, -1000, 1000, 0, 1)
    db.ySlider = Slider(dc, "Y Offset", 280, -107, -1000, 1000, 0, 1)
    db.iconsPerRowSlider = Slider(dc, "Icons Per Row", 15, -162, 1, 20, 10, 1)
    db.borderSizeSlider = Slider(dc, "Border Size", 280, -155, 0, 5, 1, 1)
    db.sortDirectionDD, db.sortDirectionLbl = StyledDropdown(dc, "Sort Direction", 15, -217, 120)
    db.sortDirectionDD:SetOptions({{text = "Left to Right", value = "right"}, {text = "Right to Left", value = "left"}})
    db.growDirectionDD, db.growDirectionLbl = StyledDropdown(dc, "Row Growth", 280, -217, 120)
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
    ufScrollChild:SetSize(490, 1300)
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
    Section(uc, "Unit Frame Customization", -12)
    addonTable.useCustomBorderColorCB = Checkbox(uc, "Custom Border Color", 15, -37)
    addonTable.ufClassColorCB = Checkbox(uc, "Use class color", 280, -37)
    addonTable.ufDisableGlowsCB = Checkbox(uc, "Disable Frame Glows", 15, -62)
    addonTable.ufUseCustomTexturesCB = Checkbox(uc, "Use Custom Textures", 280, -62)
    addonTable.disableTargetBuffsCB = Checkbox(uc, "Disable Target Buffs", 15, -87)
    addonTable.hideEliteTextureCB = Checkbox(uc, "Hide Elite Texture", 280, -87)
    addonTable.ufDisableCombatTextCB = Checkbox(uc, "Disable Player Combat Text", 15, -112)
    addonTable.ufUseCustomNameColorCB = Checkbox(uc, "Use Custom Name Color", 280, -112)
    addonTable.ufBorderColorBtn = CreateStyledButton(uc, "Border Color", 100, 22)
    addonTable.ufBorderColorBtn:SetPoint("TOPLEFT", uc, "TOPLEFT", 15, -147)
    addonTable.ufBorderColorSwatch = CreateFrame("Frame", nil, uc, "BackdropTemplate")
    addonTable.ufBorderColorSwatch:SetSize(22, 22)
    addonTable.ufBorderColorSwatch:SetPoint("LEFT", addonTable.ufBorderColorBtn, "RIGHT", 4, 0)
    addonTable.ufBorderColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.ufBorderColorSwatch:SetBackdropColor(0, 0, 0, 1)
    addonTable.ufBorderColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.ufHealthTextureDD = StyledDropdown(uc, nil, 280, -147, 115)
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

    Section(uc, "Use Bigger Healthbars", -190)
    addonTable.ufBigHBPlayerCB = Checkbox(uc, "Player", 15, -215)
    addonTable.ufBigHBTargetCB = Checkbox(uc, "Target", 90, -215)
    addonTable.ufBigHBFocusCB = Checkbox(uc, "Focus", 165, -215)
    addonTable.ufBigHBHideRealmCB = Checkbox(uc, "Hide Realm", 240, -215)

    local UF_BIG_SECTION_START_Y = -242
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
    local qolScrollFrame = CreateFrame("ScrollFrame", "CCMQOLScrollFrame", tab12, "UIPanelScrollFrameTemplate")
    qolScrollFrame:SetPoint("TOPLEFT", tab12, "TOPLEFT", 0, 0)
    qolScrollFrame:SetPoint("BOTTOMRIGHT", tab12, "BOTTOMRIGHT", -22, 0)
    local qolScrollChild = CreateFrame("Frame", "CCMQOLScrollChild", qolScrollFrame)
    qolScrollChild:SetSize(490, 3040)
    qolScrollFrame:SetScrollChild(qolScrollChild)
    local scrollBar10 = _G["CCMQOLScrollFrameScrollBar"]
    if scrollBar10 then
      scrollBar10:SetPoint("TOPLEFT", qolScrollFrame, "TOPRIGHT", 6, -16)
      scrollBar10:SetPoint("BOTTOMLEFT", qolScrollFrame, "BOTTOMRIGHT", 6, 16)
      local thumb10 = scrollBar10:GetThumbTexture()
      if thumb10 then thumb10:SetColorTexture(0.4, 0.4, 0.45, 0.8); thumb10:SetSize(8, 40) end
      local up10 = _G["CCMQOLScrollFrameScrollBarScrollUpButton"]
      local down10 = _G["CCMQOLScrollFrameScrollBarScrollDownButton"]
      if up10 then up10:SetAlpha(0); up10:EnableMouse(false) end
      if down10 then down10:SetAlpha(0); down10:EnableMouse(false) end
    end
    SetSmoothScroll(qolScrollFrame)
    local qcTop = qolScrollChild
    local qc = CreateFrame("Frame", nil, qolScrollChild)
    qc:SetSize(490, 3130)
    qc:SetPoint("TOPLEFT", qolScrollChild, "TOPLEFT", 0, -170)
    Section(qc, "Self Highlight", -12)
    addonTable.selfHighlightCB = Checkbox(qc, "Enable Self Highlight", 15, -37)
    addonTable.selfHighlightVisibilityDD, addonTable.selfHighlightVisibilityLbl = StyledDropdown(qc, "Visibility", 170, -37, 130)
    addonTable.selfHighlightVisibilityDD:SetOptions({{text = "Always", value = "always"}, {text = "Only in Combat", value = "combat"}})
    addonTable.selfHighlightVisibilityDD:SetEnabled(false)
    addonTable.selfHighlightSizeSlider = Slider(qc, "Size", 15, -94, 5, 100, 20, 1)
    addonTable.selfHighlightSizeSlider:SetEnabled(false)
    addonTable.selfHighlightYSlider = Slider(qc, "Y Offset", 280, -94, -200, 200, 0, 1)
    addonTable.selfHighlightYSlider:SetEnabled(false)
    addonTable.selfHighlightThicknessDD, addonTable.selfHighlightThicknessLbl = StyledDropdown(qc, "Thickness", 15, -149, 100)
    addonTable.selfHighlightThicknessDD:SetOptions({{text = "Thin", value = "thin"}, {text = "Medium", value = "medium"}, {text = "Thick", value = "thick"}})
    addonTable.selfHighlightThicknessDD:SetEnabled(false)
    addonTable.selfHighlightOutlineCB = Checkbox(qc, "Outline", 170, -167)
    addonTable.selfHighlightOutlineCB:SetEnabled(false)
    addonTable.selfHighlightColorBtn = CreateStyledButton(qc, "Color", 60, 22)
    addonTable.selfHighlightColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 280, -167)
    addonTable.selfHighlightColorBtn:SetEnabled(false)
    addonTable.selfHighlightColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.selfHighlightColorSwatch:SetSize(22, 22)
    addonTable.selfHighlightColorSwatch:SetPoint("LEFT", addonTable.selfHighlightColorBtn, "RIGHT", 4, 0)
    addonTable.selfHighlightColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.selfHighlightColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.selfHighlightColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    Section(qc, "No Target Alert", -234)
    addonTable.noTargetAlertCB = Checkbox(qc, "Enable No Target Alert", 15, -259)
    addonTable.noTargetAlertFlashCB = Checkbox(qc, "Flash Text", 220, -259)
    addonTable.noTargetAlertFlashCB:SetEnabled(false)
    addonTable.noTargetAlertPreviewOnBtn = CreateStyledButton(qc, "Show Preview", 90, 22)
    addonTable.noTargetAlertPreviewOnBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 320, -259)
    addonTable.noTargetAlertPreviewOffBtn = CreateStyledButton(qc, "Hide Preview", 90, 22)
    addonTable.noTargetAlertPreviewOffBtn:SetPoint("LEFT", addonTable.noTargetAlertPreviewOnBtn, "RIGHT", 5, 0)
    addonTable.noTargetAlertXSlider = Slider(qc, "X Offset", 15, -299, -500, 500, 0, 1)
    addonTable.noTargetAlertXSlider:SetEnabled(false)
    addonTable.noTargetAlertYSlider = Slider(qc, "Y Offset", 280, -299, -500, 500, 100, 1)
    addonTable.noTargetAlertYSlider:SetEnabled(false)
    addonTable.noTargetAlertFontSizeSlider = Slider(qc, "Font Size", 15, -354, 12, 72, 36, 1)
    addonTable.noTargetAlertFontSizeSlider:SetEnabled(false)
    addonTable.noTargetAlertColorBtn = CreateStyledButton(qc, "Color", 60, 22)
    addonTable.noTargetAlertColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 280, -364)
    addonTable.noTargetAlertColorBtn:SetEnabled(false)
    addonTable.noTargetAlertColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.noTargetAlertColorSwatch:SetSize(22, 22)
    addonTable.noTargetAlertColorSwatch:SetPoint("LEFT", addonTable.noTargetAlertColorBtn, "RIGHT", 4, 0)
    addonTable.noTargetAlertColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.noTargetAlertColorSwatch:SetBackdropColor(1, 0, 0, 1)
    addonTable.noTargetAlertColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    Section(qc, "Action Bar Enhancement", -409)
    local abNote = qc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abNote:SetPoint("TOPLEFT", qc, "TOPLEFT", 15, -432)
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
    local function CreateABModeRow(rowKey, labelText, y)
      local lbl = qc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      lbl:SetPoint("TOPLEFT", qc, "TOPLEFT", AB_LABEL_X, y - 4)
      lbl:SetText(labelText)
      addonTable[rowKey .. "ModeLabel"] = lbl
      local dd = StyledDropdown(qc, nil, AB_DD_X, y, AB_DD_W)
      dd:SetOptions(AB_MODE_OPTIONS)
      dd:SetValue("off")
      addonTable[rowKey .. "ModeDD"] = dd
    end
    local abRowY = -454
    addonTable.actionBarGlobalModeLabel = qc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addonTable.actionBarGlobalModeLabel:SetPoint("TOPLEFT", qc, "TOPLEFT", AB_LABEL_X, abRowY - 4)
    addonTable.actionBarGlobalModeLabel:SetText("All Bars")
    addonTable.actionBarGlobalModeDD = StyledDropdown(qc, nil, AB_DD_X, abRowY, AB_DD_W)
    addonTable.actionBarGlobalModeDD:SetOptions(AB_GLOBAL_OPTIONS)
    addonTable.actionBarGlobalModeDD:SetValue("custom")
    abRowY = abRowY - AB_ROW_H
    CreateABModeRow("actionBar1", "Action Bar 1", abRowY)
    for n = 2, 8 do
      abRowY = abRowY - AB_ROW_H
      CreateABModeRow("actionBar" .. n, "Action Bar " .. n, abRowY)
    end
    abRowY = abRowY - AB_ROW_H
    CreateABModeRow("stanceBar", "Stance Bar", abRowY)
    abRowY = abRowY - AB_ROW_H
    CreateABModeRow("petBar", "Pet Bar", abRowY)
    addonTable.fadeMicroMenuCB = Checkbox(qc, "Fade Micro Menu", 15, -794)
    addonTable.hideABBordersCB = Checkbox(qc, "Action Bar Skinning", AB_DD_X, -794)
    addonTable.fadeObjectiveTrackerCB = Checkbox(qc, "Fade Objective Tracker", 15, -819)
    addonTable.fadeBagBarCB = Checkbox(qc, "Fade Bag Bar", AB_DD_X, -819)
    addonTable.abSkinSpacingSlider = Slider(qc, "Skinning Spacing", AB_DD_X, -846, 0, 10, 2, 1)
    Section(qcTop, "Radial Circle", -12)
    addonTable.radialCB = Checkbox(qcTop, "Enable Radial Circle", 15, -37)
    addonTable.radialCombatCB = Checkbox(qcTop, "Combat Only", 200, -37)
    addonTable.radialGcdCB = Checkbox(qcTop, "Show GCD on Radial", 350, -37)
    addonTable.radiusSlider = Slider(qcTop, "Radius", 15, -77, 10, 60, 30, 1)
    addonTable.radialThicknessDD, addonTable.radialThicknessLbl = StyledDropdown(qcTop, "Thickness", 280, -77, 180)
    addonTable.radialThicknessDD:SetOptions({
      { text = "Thin", value = "thin" },
      { text = "Middle", value = "middle" },
      { text = "Thick", value = "thick" },
    })
    addonTable.radialThicknessDD:SetValue("middle")
    addonTable.colorBtn = CreateStyledButton(qcTop, "Ring Color", 80, 24)
    addonTable.colorBtn:SetPoint("TOPLEFT", qcTop, "TOPLEFT", 15, -152)
    addonTable.colorSwatch = CreateFrame("Frame", nil, qcTop, "BackdropTemplate")
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
          r = r,
          g = g,
          b = b,
          opacity = a,
          hasOpacity = true,
          swatchFunc = OnColorChanged,
          opacityFunc = OnColorChanged,
          cancelFunc = OnCancel,
        })
      else
        ColorPickerFrame:SetupColorPickerAndShow({
          r = r,
          g = g,
          b = b,
          opacity = a,
          hasOpacity = true,
          swatchFunc = OnColorChanged,
          opacityFunc = OnColorChanged,
          cancelFunc = OnCancel,
        })
      end
    end)
    local qcAfterAB = CreateFrame("Frame", nil, qc)
    qcAfterAB:SetSize(490, 3140)
    qcAfterAB:SetPoint("TOPLEFT", qc, "TOPLEFT", 0, 115)
    qc = qcAfterAB
    Section(qc, "Useful Features", -1003)
    addonTable.autoRepairCB = Checkbox(qc, "Auto Repair (Guild > Gold)", 15, -1028)
    addonTable.showTooltipIDsCB = Checkbox(qc, "Show Spell/Item IDs in Tooltip", 280, -1028)
    addonTable.compactMinimapIconsCB = Checkbox(qc, "Compact Minimap Icons", 15, -1053)
    addonTable.enhancedTooltipCB = Checkbox(qc, "Enhanced Tooltip", 280, -1053)
    addonTable.autoQuestCB = Checkbox(qc, "Auto Quest Accept/Turn-in", 15, -1078)
    addonTable.autoSellJunkCB = Checkbox(qc, "Auto Sell Junk", 280, -1078)
    addonTable.autoQuestExcludeDailyCB = Checkbox(qc, "Exclude Daily", 35, -1103)
    addonTable.autoFillDeleteCB = Checkbox(qc, "Auto-fill DELETE", 280, -1103)
    addonTable.autoQuestExcludeWeeklyCB = Checkbox(qc, "Exclude Weekly", 35, -1128)
    addonTable.quickRoleSignupCB = Checkbox(qc, "Quick Role Signup", 280, -1128)
    addonTable.autoQuestExcludeTrivialCB = Checkbox(qc, "Exclude Trivial", 35, -1153)
    addonTable.autoQuestExcludeCompletedCB = Checkbox(qc, "Exclude Completed", 35, -1178)
    addonTable.autoQuestRewardDD, addonTable.autoQuestRewardLbl = StyledDropdown(qc, "Multi-Reward", 280, -1168, 150)
    addonTable.autoQuestRewardDD:SetOptions({{text = "Skip (Manual)", value = "skip"}, {text = "Best Gold Value", value = "gold"}})
    Section(qc, "Combat Timer", -1233)
    addonTable.combatTimerCB = Checkbox(qc, "Enable Combat Timer", 15, -1258)
    addonTable.combatTimerStyleDD, addonTable.combatTimerStyleLbl = StyledDropdown(qc, "Timer Style", 15, -1293, 170)
    addonTable.combatTimerStyleDD:SetOptions({
      {text = "Boxed", value = "boxed"},
      {text = "Minimal", value = "minimal"},
    })
    addonTable.combatTimerModeDD, addonTable.combatTimerModeLbl = StyledDropdown(qc, "Timer Visibility", 280, -1293, 170)
    addonTable.combatTimerModeDD:SetOptions({
      {text = "Show Always", value = "always"},
      {text = "Only In Combat", value = "combat"},
    })
    addonTable.combatTimerXSlider = Slider(qc, "X Offset", 15, -1340, -1500, 1500, 0, 1)
    addonTable.combatTimerYSlider = Slider(qc, "Y Offset", 280, -1340, -1500, 1500, 200, 1)
    addonTable.combatTimerScaleSlider = Slider(qc, "Scale", 15, -1400, 0.2, 2.0, 1.0, 0.05)
    addonTable.combatTimerCenteredCB = Checkbox(qc, "Center X", 280, -1415)
    local ctbd = {bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1}
    addonTable.combatTimerTextColorBtn = CreateStyledButton(qc, "Text Color", 80, 22)
    addonTable.combatTimerTextColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 15, -1455)
    addonTable.combatTimerTextColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.combatTimerTextColorSwatch:SetSize(22, 22)
    addonTable.combatTimerTextColorSwatch:SetPoint("LEFT", addonTable.combatTimerTextColorBtn, "RIGHT", 4, 0)
    addonTable.combatTimerTextColorSwatch:SetBackdrop(ctbd)
    addonTable.combatTimerTextColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.combatTimerTextColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.combatTimerBgColorBtn = CreateStyledButton(qc, "Background", 80, 22)
    addonTable.combatTimerBgColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 250, -1455)
    addonTable.combatTimerBgColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.combatTimerBgColorSwatch:SetSize(22, 22)
    addonTable.combatTimerBgColorSwatch:SetPoint("LEFT", addonTable.combatTimerBgColorBtn, "RIGHT", 4, 0)
    addonTable.combatTimerBgColorSwatch:SetBackdrop(ctbd)
    addonTable.combatTimerBgColorSwatch:SetBackdropColor(0.12, 0.12, 0.12, 1)
    addonTable.combatTimerBgColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    Section(qc, "Timer for CR", -1535)
    addonTable.crTimerCB = Checkbox(qc, "Enable Timer for CR", 15, -1560)
    addonTable.crTimerModeDD, addonTable.crTimerModeLbl = StyledDropdown(qc, "Visibility", 15, -1595, 170)
    addonTable.crTimerModeDD:SetOptions({
      {text = "Show Always", value = "always"},
      {text = "Only In Combat", value = "combat"},
    })
    addonTable.crTimerLayoutDD, addonTable.crTimerLayoutLbl = StyledDropdown(qc, "Layout", 280, -1595, 170)
    addonTable.crTimerLayoutDD:SetOptions({
      {text = "Vertical", value = "vertical"},
      {text = "Horizontal", value = "horizontal"},
    })
    addonTable.crTimerDisplayDD, addonTable.crTimerDisplayLbl = StyledDropdown(qc, "Display", 15, -1635, 170)
    addonTable.crTimerDisplayDD:SetOptions({
      {text = "Charges + Timer", value = "timer"},
      {text = "Charges Only", value = "count"},
    })
    addonTable.crTimerXSlider = Slider(qc, "X Offset", 15, -1680, -1500, 1500, 0, 1)
    addonTable.crTimerYSlider = Slider(qc, "Y Offset", 280, -1680, -1500, 1500, 150, 1)
    addonTable.crTimerScaleSlider = Slider(qc, "Scale", 15, -1740, 0.2, 2.0, 1.0, 0.05)
    addonTable.crTimerCenteredCB = Checkbox(qc, "Center X", 280, -1755)
    Section(qc, "Combat Status", -1855)
    addonTable.combatStatusCB = Checkbox(qc, "Enable Combat Status", 15, -1880)
    addonTable.combatStatusPreviewOnBtn = CreateStyledButton(qc, "Show Preview", 90, 22)
    addonTable.combatStatusPreviewOnBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 250, -1880)
    addonTable.combatStatusPreviewOffBtn = CreateStyledButton(qc, "Hide Preview", 90, 22)
    addonTable.combatStatusPreviewOffBtn:SetPoint("LEFT", addonTable.combatStatusPreviewOnBtn, "RIGHT", 5, 0)
    addonTable.combatStatusXSlider = Slider(qc, "X Offset", 15, -1915, -1500, 1500, 0, 1)
    addonTable.combatStatusYSlider = Slider(qc, "Y Offset", 280, -1915, -1500, 1500, 280, 1)
    addonTable.combatStatusScaleSlider = Slider(qc, "Scale", 15, -1975, 0.6, 2.0, 1.0, 0.05)
    addonTable.combatStatusCenteredCB = Checkbox(qc, "Center X", 280, -1990)
    local csbd = {bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1}
    addonTable.combatStatusEnterColorBtn = CreateStyledButton(qc, "Enter Color", 90, 22)
    addonTable.combatStatusEnterColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 15, -2030)
    addonTable.combatStatusEnterColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.combatStatusEnterColorSwatch:SetSize(22, 22)
    addonTable.combatStatusEnterColorSwatch:SetPoint("LEFT", addonTable.combatStatusEnterColorBtn, "RIGHT", 4, 0)
    addonTable.combatStatusEnterColorSwatch:SetBackdrop(csbd)
    addonTable.combatStatusEnterColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.combatStatusEnterColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    addonTable.combatStatusLeaveColorBtn = CreateStyledButton(qc, "Leave Color", 90, 22)
    addonTable.combatStatusLeaveColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 250, -2030)
    addonTable.combatStatusLeaveColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.combatStatusLeaveColorSwatch:SetSize(22, 22)
    addonTable.combatStatusLeaveColorSwatch:SetPoint("LEFT", addonTable.combatStatusLeaveColorBtn, "RIGHT", 4, 0)
    addonTable.combatStatusLeaveColorSwatch:SetBackdrop(csbd)
    addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(1, 1, 1, 1)
    addonTable.combatStatusLeaveColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    Section(qc, "Character Panel Enhancement", -2110)
    addonTable.betterItemLevelCB = Checkbox(qc, "Better Item Level (2 Decimals)", 15, -2135)
    addonTable.showEquipDetailsCB = Checkbox(qc, "Show Equipment Details (sockets / icon ilvl / enhancements)", 280, -2135)
    Section(qc, "Chat Enhancement", -2215)

    addonTable.chatClassColorCB = Checkbox(qc, "Class-Colored Names", 15, -2240)
    addonTable.chatUrlDetectionCB = Checkbox(qc, "Clickable URLs", 250, -2240)
    addonTable.chatHideButtonsCB = Checkbox(qc, "Hide Chat Buttons", 15, -2265)
    addonTable.chatTabFlashCB = Checkbox(qc, "Disable Tab Flash", 250, -2265)

    addonTable.chatEditBoxStyledCB = Checkbox(qc, "Style Edit Box", 15, -2300)
    addonTable.chatEditBoxDD, addonTable.chatEditBoxLbl = StyledDropdown(qc, "Edit Box Position", 250, -2290, 150)
    addonTable.chatEditBoxDD:SetOptions({{text = "Bottom", value = "bottom"}, {text = "Top", value = "top"}})

    addonTable.chatTimestampsCB = Checkbox(qc, "Timestamps", 15, -2340)
    addonTable.chatTimestampFormatDD, addonTable.chatTimestampFormatLbl = StyledDropdown(qc, "Format", 250, -2330, 150)
    addonTable.chatTimestampFormatDD:SetOptions({{text = "HH:MM", value = "HH:MM"}, {text = "HH:MM:SS", value = "HH:MM:SS"}, {text = "12h AM/PM", value = "12h"}})

    addonTable.chatCopyButtonCB = Checkbox(qc, "Copy Chat Button", 15, -2380)
    addonTable.chatCopyButtonCornerDD, addonTable.chatCopyButtonCornerLbl = StyledDropdown(qc, "Corner", 250, -2370, 150)
    addonTable.chatCopyButtonCornerDD:SetOptions({{text = "Top Left", value = "TOPLEFT"}, {text = "Top Right", value = "TOPRIGHT"}, {text = "Bottom Left", value = "BOTTOMLEFT"}, {text = "Bottom Right", value = "BOTTOMRIGHT"}})

    addonTable.chatHideTabsDD, addonTable.chatHideTabsLbl = StyledDropdown(qc, "Chat Tabs", 250, -2410, 150)
    addonTable.chatHideTabsDD:SetOptions({{text = "Show", value = "off"}, {text = "Hide", value = "hide"}, {text = "Mouseover", value = "mouseover"}})

    addonTable.chatBackgroundCB = Checkbox(qc, "Custom Chat Background", 15, -2455)
    addonTable.chatBgAlphaSlider = Slider(qc, "Background Opacity", 15, -2485, 0, 100, 40, 5)
    addonTable.chatBgColorBtn = CreateStyledButton(qc, "BG Color", 65, 22)
    addonTable.chatBgColorBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 280, -2500)
    addonTable.chatBgColorSwatch = CreateFrame("Frame", nil, qc, "BackdropTemplate")
    addonTable.chatBgColorSwatch:SetSize(22, 22)
    addonTable.chatBgColorSwatch:SetPoint("LEFT", addonTable.chatBgColorBtn, "RIGHT", 4, 0)
    addonTable.chatBgColorSwatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    addonTable.chatBgColorSwatch:SetBackdropColor(0, 0, 0, 1)
    addonTable.chatBgColorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

    addonTable.chatFadeToggleCB = Checkbox(qc, "Custom Chat Fading", 15, -2540)
    addonTable.chatFadeDelaySlider = Slider(qc, "Fade Delay (sec)", 15, -2570, 5, 120, 20, 5)

    Section(qc, "Skyriding Enhancement", -2690)

    addonTable.skyridingEnabledCB = Checkbox(qc, "Enable Skyriding UI", 15, -2715)
    addonTable.skyridingHideCDMCB = Checkbox(qc, "Hide CDM / Bars", 200, -2715)

    addonTable.skyridingVigorBarCB = Checkbox(qc, "Skyriding Bar", 15, -2755)
    addonTable.skyridingSpeedDisplayCB = Checkbox(qc, "Speed Display", 200, -2755)
    addonTable.skyridingCooldownsCB = Checkbox(qc, "Ability Cooldowns", 400, -2755)

    addonTable.skyridingSpeedBarCB = Checkbox(qc, "Speed Bar", 15, -2780)
    addonTable.skyridingCenteredCB = Checkbox(qc, "Center", 200, -2780)

    addonTable.skyridingScreenFxCB = Checkbox(qc, "Screen Effects", 15, -2805)
    addonTable.skyridingSpeedFxCB = Checkbox(qc, "Speed Effects", 200, -2805)

    local cbd = {bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1}
    local function ColorPicker(name, x, y, dr, dg, db)
      local btn = CreateStyledButton(qc, name, 55, 22)
      btn:SetPoint("TOPLEFT", qc, "TOPLEFT", x, y)
      local sw = CreateFrame("Frame", nil, qc, "BackdropTemplate")
      sw:SetSize(22, 22)
      sw:SetPoint("LEFT", btn, "RIGHT", 4, 0)
      sw:SetBackdrop(cbd)
      sw:SetBackdropColor(dr, dg, db, 1)
      sw:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      return btn, sw
    end

    addonTable.skyridingVigorColorBtn, addonTable.skyridingVigorColorSwatch = ColorPicker("Vigor", 15, -2844, 0.2, 0.8, 0.2)
    addonTable.skyridingSpeedColorBtn, addonTable.skyridingSpeedColorSwatch = ColorPicker("Speed", 130, -2844, 0.3, 0.6, 1.0)
    addonTable.skyridingSurgeColorBtn, addonTable.skyridingSurgeColorSwatch = ColorPicker("Surge", 245, -2844, 0.85, 0.65, 0.1)
    addonTable.skyridingWindColorBtn, addonTable.skyridingWindColorSwatch = ColorPicker("Wind", 360, -2844, 0.2, 0.8, 0.2)

    addonTable.skyridingEmptyColorBtn, addonTable.skyridingEmptyColorSwatch = ColorPicker("BG", 15, -2880, 0.15, 0.15, 0.15)
    addonTable.skyridingRechargeColorBtn, addonTable.skyridingRechargeColorSwatch = ColorPicker("Recharge", 130, -2880, 0.85, 0.65, 0.1)

    addonTable.skyridingTextureDD, addonTable.skyridingTextureLbl = StyledDropdown(qc, "Texture", 15, -2920, 140)
    addonTable.skyridingSpeedUnitDD, addonTable.skyridingSpeedUnitLbl = StyledDropdown(qc, "Speed Unit", 310, -2920, 130)
    addonTable.skyridingSpeedUnitDD:SetOptions({{text = "Percent", value = "percent"}, {text = "Yards/s", value = "yds"}})
    ApplyTextureOptionsToDropdown(addonTable.skyridingTextureDD)

    addonTable.skyridingScaleSlider = Slider(qc, "Scale", 15, -2980, 50, 200, 100, 5)
    addonTable.skyridingXSlider = Slider(qc, "X Position", 15, -3040, -800, 800, 0, 5)
    addonTable.skyridingYSlider = Slider(qc, "Y Position", 280, -3040, -800, 800, -200, 5)
    addonTable.skyridingPreviewOnBtn = CreateStyledButton(qc, "Show Preview", 90, 22)
    addonTable.skyridingPreviewOnBtn:SetPoint("TOPLEFT", qc, "TOPLEFT", 15, -3100)
    addonTable.skyridingPreviewOffBtn = CreateStyledButton(qc, "Hide Preview", 90, 22)
    addonTable.skyridingPreviewOffBtn:SetPoint("LEFT", addonTable.skyridingPreviewOnBtn, "RIGHT", 5, 0)
  end
end
C_Timer.After(0, InitTabs)



