--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_config.lua
-- Configuration UI main frame and panel management
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
local addonTable = CCM
local function GetProfile() return addonTable.GetProfile and addonTable.GetProfile() end
local function CreateIcons() if addonTable.CreateIcons then addonTable.CreateIcons() end end
local function SetGUIOpen(v) if addonTable.SetGUIOpen then addonTable.SetGUIOpen(v) end end
local HideActiveDropdownList = addonTable.HideActiveDropdownList
addonTable.ConfigGetProfile = GetProfile
addonTable.ConfigCreateIcons = CreateIcons
addonTable.ConfigSetGUIOpen = SetGUIOpen
local CreateStyledButton = addonTable.CreateStyledButton
local cfg = CreateFrame("Frame", "CCMConfig", UIParent, "BackdropTemplate")
cfg:SetSize(710, 630)
cfg:SetPoint("CENTER")
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:SetClampedToScreen(true)
cfg:SetResizable(true)
cfg:SetResizeBounds(710, 400, 870, 1200)
cfg:SetFrameStrata("FULLSCREEN_DIALOG")
cfg:SetFrameLevel(1000)
cfg:SetToplevel(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop", cfg.StopMovingOrSizing)
cfg:SetScript("OnShow", function(self)
  self:SetFrameStrata("FULLSCREEN_DIALOG")
  self:SetFrameLevel(1000)
  self:Raise()
  if CooldownCursorManagerDB and CooldownCursorManagerDB.guiHeight then
    self:SetHeight(CooldownCursorManagerDB.guiHeight)
  end
  if addonTable.FitConfigToScreen then
    addonTable.FitConfigToScreen(self)
  end
end)
cfg:SetScript("OnHide", function()
  if HideActiveDropdownList then HideActiveDropdownList() end
  SetGUIOpen(false)
  if addonTable.StopCursorIconPreview then
    addonTable.StopCursorIconPreview()
  end
  if addonTable.ClearConfigPreviewCountdowns then
    addonTable.ClearConfigPreviewCountdowns()
  end
  if addonTable.StopCastbarPreview then
    addonTable.StopCastbarPreview()
  end
  if addonTable.StopFocusCastbarPreview then
    addonTable.StopFocusCastbarPreview()
  end
  if addonTable.StopTargetCastbarPreview then
    addonTable.StopTargetCastbarPreview()
  end
  if addonTable.StopDebuffPreview then
    addonTable.StopDebuffPreview()
  end
  if addonTable.StopNoTargetAlertPreview then
    addonTable.StopNoTargetAlertPreview()
  end
  if addonTable.StopCombatStatusPreview then
    addonTable.StopCombatStatusPreview()
  end
  if addonTable.StopSkyridingPreview then
    addonTable.StopSkyridingPreview()
  end
  if addonTable.StopLowHealthWarningPreview then
    addonTable.StopLowHealthWarningPreview()
  end
  if addonTable.StopUFBossPreview then
    addonTable.StopUFBossPreview()
  end
  if addonTable.ResetAllPreviewHighlights then
    addonTable.ResetAllPreviewHighlights()
  end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
end)
cfg:Hide()
cfg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
cfg:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
cfg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
cfg:SetScript("OnSizeChanged", function(self)
  if self:IsShown() and addonTable.FitConfigToScreen then
    addonTable.FitConfigToScreen(self)
  end
end)
local cfgFitEvent = CreateFrame("Frame")
cfgFitEvent:RegisterEvent("DISPLAY_SIZE_CHANGED")
cfgFitEvent:RegisterEvent("UI_SCALE_CHANGED")
cfgFitEvent:SetScript("OnEvent", function()
  if cfg and cfg:IsShown() and addonTable.FitConfigToScreen then
    addonTable.FitConfigToScreen(cfg)
  end
end)
local titleBar = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
titleBar:SetHeight(32)
titleBar:SetPoint("TOPLEFT", cfg, "TOPLEFT", 2, -2)
titleBar:SetPoint("TOPRIGHT", cfg, "TOPRIGHT", -2, -2)
titleBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
titleBar:SetBackdropColor(0.15, 0.15, 0.18, 1)
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
titleText:SetText("Cooldown Cursor Manager v7.3.0")
titleText:SetTextColor(1, 0.82, 0)
local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
closeBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
closeBtn:SetBackdropColor(0.15, 0.15, 0.18, 1)
closeBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY")
closeBtnText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
closeBtnText:SetPoint("CENTER", 0, 0)
closeBtnText:SetText("X")
closeBtnText:SetTextColor(0.9, 0.9, 0.9)
closeBtn:SetScript("OnEnter", function() closeBtn:SetBackdropColor(0.4, 0.15, 0.15, 1); closeBtnText:SetTextColor(1, 1, 1) end)
closeBtn:SetScript("OnLeave", function() closeBtn:SetBackdropColor(0.15, 0.15, 0.18, 1); closeBtnText:SetTextColor(0.9, 0.9, 0.9) end)
closeBtn:SetScript("OnClick", function() cfg:Hide(); SetGUIOpen(false) end)
local profileBar = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
profileBar:SetHeight(36)
profileBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -1)
profileBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -1)
profileBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
profileBar:SetBackdropColor(0.12, 0.12, 0.14, 1)
local profileLabel = profileBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profileLabel:SetPoint("LEFT", profileBar, "LEFT", 12, 0)
profileLabel:SetText("Profile:")
profileLabel:SetTextColor(0.7, 0.7, 0.7)
local profileDropdown = CreateFrame("Frame", nil, profileBar, "BackdropTemplate")
profileDropdown:SetSize(110, 24)
profileDropdown:SetPoint("LEFT", profileLabel, "RIGHT", 8, 0)
profileDropdown:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
profileDropdown:SetBackdropColor(0.12, 0.12, 0.14, 1)
profileDropdown:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
local profileText = profileDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profileText:SetPoint("LEFT", profileDropdown, "LEFT", 8, 0)
profileText:SetPoint("RIGHT", profileDropdown, "RIGHT", -20, 0)
profileText:SetJustifyH("LEFT")
profileText:SetTextColor(0.9, 0.9, 0.9)
profileText:SetText("Default")
local profileArrow = profileDropdown:CreateTexture(nil, "ARTWORK")
profileArrow:SetSize(10, 10)
profileArrow:SetPoint("RIGHT", profileDropdown, "RIGHT", -8, 0)
profileArrow:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down")
profileArrow:SetVertexColor(0.6, 0.6, 0.6)
local profileList = CreateFrame("Frame", nil, profileDropdown, "BackdropTemplate")
profileList:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 0, -2)
profileList:SetWidth(110)
profileList:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
profileList:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
profileList:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
profileList:SetFrameStrata("TOOLTIP")
profileList:SetFrameLevel(math.max((profileDropdown:GetFrameLevel() or 1) + 200, 2000))
profileList:Hide()
profileDropdown:SetScript("OnEnter", function() profileDropdown:SetBackdropColor(0.18, 0.18, 0.22, 1) end)
profileDropdown:SetScript("OnLeave", function() profileDropdown:SetBackdropColor(0.12, 0.12, 0.14, 1) end)
local newProfileBtn = CreateStyledButton(profileBar, "New", 45, 22)
newProfileBtn:SetPoint("LEFT", profileDropdown, "RIGHT", 8, 0)
local deleteProfileBtn = CreateStyledButton(profileBar, "Delete", 50, 22)
deleteProfileBtn:SetPoint("LEFT", newProfileBtn, "RIGHT", 4, 0)
local expBtn = CreateStyledButton(profileBar, "Export", 50, 22)
expBtn:SetPoint("LEFT", deleteProfileBtn, "RIGHT", 15, 0)
local impBtn = CreateStyledButton(profileBar, "Import", 50, 22)
impBtn:SetPoint("LEFT", expBtn, "RIGHT", 4, 0)
local copyProfileBtn = CreateStyledButton(profileBar, "Copy Profile", 85, 22)
copyProfileBtn:SetPoint("LEFT", impBtn, "RIGHT", 4, 0)
-- Search field
local searchBg = CreateFrame("Frame", nil, profileBar, "BackdropTemplate")
searchBg:SetSize(120, 22)
searchBg:SetPoint("LEFT", copyProfileBtn, "RIGHT", 15, 0)
searchBg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
searchBg:SetBackdropColor(0.05, 0.05, 0.07, 1)
searchBg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
local searchIcon = searchBg:CreateTexture(nil, "OVERLAY")
searchIcon:SetSize(14, 14)
searchIcon:SetPoint("LEFT", searchBg, "LEFT", 5, 0)
searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
searchIcon:SetVertexColor(0.6, 0.6, 0.65)
local searchBox = CreateFrame("EditBox", nil, searchBg)
searchBox:SetSize(90, 20)
searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
searchBox:SetFontObject("GameFontHighlightSmall")
searchBox:SetAutoFocus(false)
searchBox:SetTextColor(1, 1, 1)
searchBox:SetMaxLetters(40)
local searchPlaceholder = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchPlaceholder:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
searchPlaceholder:SetText("Search settings")
searchPlaceholder:SetTextColor(0.4, 0.4, 0.45)
searchBox:SetScript("OnTextChanged", function(self, userInput)
  local txt = strtrim(self:GetText())
  if txt == "" then searchPlaceholder:Show() else searchPlaceholder:Hide() end
  if addonTable._searchUpdate then addonTable._searchUpdate(txt) end
end)
searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
searchBg:SetScript("OnMouseDown", function() searchBox:SetFocus() end)
addonTable.searchBox = searchBox
addonTable.profileDropdown = profileDropdown
addonTable.profileText = profileText
addonTable.profileList = profileList
addonTable.newProfileBtn = newProfileBtn
addonTable.deleteProfileBtn = deleteProfileBtn
addonTable.exportBtn = expBtn
addonTable.importBtn = impBtn
addonTable.copyProfileBtn = copyProfileBtn
local exportImportPopup = CreateFrame("Frame", "CCMExportImportDialog", UIParent, "BackdropTemplate")
exportImportPopup:SetSize(500, 470)
exportImportPopup:SetPoint("CENTER")
exportImportPopup:SetFrameStrata("TOOLTIP")
exportImportPopup:SetFrameLevel(2000)
exportImportPopup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
exportImportPopup:SetBackdropColor(0.08, 0.08, 0.10, 0.98)
exportImportPopup:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
exportImportPopup:EnableMouse(true)
exportImportPopup:SetMovable(true)
exportImportPopup:SetToplevel(true)
exportImportPopup:RegisterForDrag("LeftButton")
exportImportPopup:SetScript("OnDragStart", exportImportPopup.StartMoving)
exportImportPopup:SetScript("OnDragStop", exportImportPopup.StopMovingOrSizing)
exportImportPopup:SetScript("OnShow", function(self) self:Raise() end)
exportImportPopup:Hide()
local exportImportTitle = exportImportPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
exportImportTitle:SetPoint("TOP", exportImportPopup, "TOP", 0, -15)
exportImportTitle:SetTextColor(1, 0.82, 0)
local exportCategories = {}
local categoryDefs = {
  {key = "cursor", label = "Cursor CDM Settings", y = -45},
  {key = "blizzcdm", label = "Blizz CDM Settings", y = -65},
  {key = "prb", label = "Personal Resource Bar Settings", y = -85},
  {key = "castbar", label = "Castbar Settings", y = -105},
  {key = "focuscastbar", label = "Focus Castbar Settings", y = -125},
  {key = "debuffs", label = "Player Debuffs Settings", y = -145},
  {key = "uf", label = "Unit Frame Settings", y = -165},
}
local generalAlwaysLbl = exportImportPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalAlwaysLbl:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 280, -45)
generalAlwaysLbl:SetText("|cff888888General and Custom Bar\nsettings are always included.\nNote: Tracked Spells/Items\nare not exported.|r")
addonTable.generalAlwaysLbl = generalAlwaysLbl
local function CreateExportCheckbox(parent, label, x, y)
  local cb = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
  cb:SetSize(18, 18)
  cb:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", x, y)
  cb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cb:SetBackdropColor(0.12, 0.12, 0.14, 1)
  cb:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  cb.check = cb:CreateTexture(nil, "OVERLAY")
  cb.check:SetSize(12, 12)
  cb.check:SetPoint("CENTER")
  cb.check:SetColorTexture(1, 0.82, 0, 1)
  cb.check:Hide()
  cb:SetScript("OnClick", function(s)
    s:SetChecked(not s:GetChecked())
    if s:GetChecked() then s.check:Show() else s.check:Hide() end
  end)
  cb.SetChecked = function(s, v) if v then s.check:Show() else s.check:Hide() end; s.checked = v end
  cb.GetChecked = function(s) return s.check:IsShown() end
  local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  lbl:SetText(label)
  lbl:SetTextColor(0.9, 0.9, 0.9)
  cb.label = lbl
  return cb
end
local exportCheckboxContainer = CreateFrame("Frame", nil, exportImportPopup)
exportCheckboxContainer:SetAllPoints()
generalAlwaysLbl:SetParent(exportCheckboxContainer)
for _, def in ipairs(categoryDefs) do
  exportCategories[def.key] = CreateExportCheckbox(exportCheckboxContainer, def.label, 20, def.y)
  exportCategories[def.key]:SetChecked(true)
end
local selectAllBtn = CreateStyledButton(exportCheckboxContainer, "Select All", 80, 20)
selectAllBtn:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 20, -192)
selectAllBtn:SetScript("OnClick", function()
  for _, cb in pairs(exportCategories) do cb:SetChecked(true) end
end)
local deselectAllBtn = CreateStyledButton(exportCheckboxContainer, "Deselect All", 80, 20)
deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 5, 0)
deselectAllBtn:SetScript("OnClick", function()
  for _, cb in pairs(exportCategories) do cb:SetChecked(false) end
end)
local exportImportScrollFrame = CreateFrame("ScrollFrame", nil, exportImportPopup)
exportImportScrollFrame:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 15, -220)
exportImportScrollFrame:SetSize(420, 235)
local exportImportEditBox = CreateFrame("EditBox", nil, exportImportScrollFrame)
exportImportEditBox:SetMultiLine(true)
exportImportEditBox:SetAutoFocus(false)
exportImportEditBox:SetFontObject("GameFontHighlight")
exportImportEditBox:SetWidth(400)
exportImportEditBox:SetHeight(400)
exportImportEditBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
exportImportEditBox:SetTextInsets(8, 8, 8, 8)
exportImportScrollFrame:SetScrollChild(exportImportEditBox)
exportImportScrollFrame:EnableMouse(true)
exportImportScrollFrame:SetScript("OnMouseDown", function()
  exportImportEditBox:SetFocus()
end)
exportImportEditBox:SetScript("OnTextChanged", function(self)
  local scrollFrame = self:GetParent()
  local scrollBar = scrollFrame.scrollBar
  if scrollBar then
    local _, maxVal = scrollBar:GetMinMaxValues()
    if maxVal > 0 then
      scrollBar:Show()
    else
      scrollBar:Hide()
    end
  end
end)
exportImportEditBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
  local scrollFrame = self:GetParent()
  local vs = scrollFrame:GetVerticalScroll()
  local height = scrollFrame:GetHeight()
  y = -y
  if y < vs then
    scrollFrame:SetVerticalScroll(y)
  elseif y + h > vs + height then
    scrollFrame:SetVerticalScroll(y + h - height)
  end
end)
local scrollBar = CreateFrame("Slider", nil, exportImportScrollFrame, "BackdropTemplate")
scrollBar:SetPoint("TOPRIGHT", exportImportScrollFrame, "TOPRIGHT", 20, 0)
scrollBar:SetPoint("BOTTOMRIGHT", exportImportScrollFrame, "BOTTOMRIGHT", 20, 0)
scrollBar:SetWidth(8)
scrollBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
scrollBar:SetBackdropColor(0.1, 0.1, 0.12, 1)
scrollBar:SetOrientation("VERTICAL")
scrollBar:SetMinMaxValues(0, 1)
scrollBar:SetValue(0)
scrollBar:SetValueStep(1)
scrollBar:EnableMouseWheel(false)
scrollBar.thumb = scrollBar:CreateTexture(nil, "OVERLAY")
scrollBar.thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
scrollBar.thumb:SetSize(8, 40)
scrollBar:SetThumbTexture(scrollBar.thumb)
scrollBar:SetScript("OnValueChanged", function(self, value)
  exportImportScrollFrame:SetVerticalScroll(value)
end)
scrollBar:SetScript("OnMouseWheel", nil)
exportImportScrollFrame:SetScript("OnMouseWheel", nil)
exportImportScrollFrame:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
  local max = yrange or 0
  scrollBar:SetMinMaxValues(0, max)
  if max > 0 then
    scrollBar:Show()
    local visibleRatio = self:GetHeight() / (self:GetHeight() + max)
    local thumbHeight = math.max(30, visibleRatio * self:GetHeight())
    scrollBar.thumb:SetHeight(thumbHeight)
  else
    scrollBar:Hide()
  end
end)
exportImportScrollFrame.scrollBar = scrollBar
scrollBar:Hide()
local editBoxBg = CreateFrame("Frame", nil, exportImportPopup, "BackdropTemplate")
editBoxBg:SetPoint("TOPLEFT", exportImportScrollFrame, "TOPLEFT", -5, 5)
editBoxBg:SetPoint("BOTTOMRIGHT", exportImportScrollFrame, "BOTTOMRIGHT", 15, -5)
editBoxBg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
editBoxBg:SetBackdropColor(0.08, 0.08, 0.10, 1)
editBoxBg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
editBoxBg:SetFrameLevel(exportImportScrollFrame:GetFrameLevel() - 1)
editBoxBg:EnableMouse(true)
editBoxBg:SetScript("OnMouseDown", function()
  exportImportEditBox:SetFocus()
end)
editBoxBg:SetScript("OnMouseWheel", nil)
local importContainer = CreateFrame("Frame", nil, exportImportPopup)
importContainer:SetAllPoints()
importContainer:Hide()
local importProfileLbl = importContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
importProfileLbl:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 15, -50)
importProfileLbl:SetText("New Profile Name:")
importProfileLbl:SetTextColor(0.9, 0.9, 0.9)
local importProfileNameBox = CreateFrame("EditBox", nil, importContainer, "BackdropTemplate")
importProfileNameBox:SetSize(200, 24)
importProfileNameBox:SetPoint("LEFT", importProfileLbl, "RIGHT", 10, 0)
importProfileNameBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
importProfileNameBox:SetBackdropColor(0.08, 0.08, 0.10, 1)
importProfileNameBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
importProfileNameBox:SetFontObject("GameFontHighlight")
importProfileNameBox:SetAutoFocus(false)
importProfileNameBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
importProfileNameBox:SetScript("OnEnterPressed", function(s) s:ClearFocus() end)
importProfileNameBox:SetTextInsets(6, 6, 0, 0)
local requiredLbl = importContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
requiredLbl:SetPoint("LEFT", importProfileNameBox, "RIGHT", 5, 0)
requiredLbl:SetText("|cffff6666*|r")
local importSharedCB = CreateFrame("CheckButton", nil, importContainer, "BackdropTemplate")
importSharedCB:SetSize(18, 18)
importSharedCB:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 15, -80)
importSharedCB:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
importSharedCB:SetBackdropColor(0.12, 0.12, 0.14, 1)
importSharedCB:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
importSharedCB.check = importSharedCB:CreateTexture(nil, "OVERLAY")
importSharedCB.check:SetSize(12, 12)
importSharedCB.check:SetPoint("CENTER")
importSharedCB.check:SetColorTexture(1, 0.82, 0, 1)
importSharedCB.check:Show()
importSharedCB:SetScript("OnClick", function(s)
  s:SetChecked(not s:GetChecked())
  if s:GetChecked() then s.check:Show() else s.check:Hide() end
end)
importSharedCB.SetChecked = function(s, v) if v then s.check:Show() else s.check:Hide() end; s.checked = v end
importSharedCB.GetChecked = function(s) return s.check:IsShown() end
importSharedCB:SetChecked(true)
local importSharedLbl = importContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
importSharedLbl:SetPoint("LEFT", importSharedCB, "RIGHT", 6, 0)
importSharedLbl:SetText("Shared Profile (available for all classes)")
importSharedLbl:SetTextColor(0.9, 0.9, 0.9)
addonTable.importSharedCB = importSharedCB
local generateExportBtn = CreateStyledButton(exportImportPopup, "Generate", 85, 20)
generateExportBtn:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 290, -192)
local exportImportOkBtn = CreateStyledButton(exportImportPopup, "Import", 85, 20)
exportImportOkBtn:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 290, -192)
local exportImportCancelBtn = CreateStyledButton(exportImportPopup, "Close", 85, 20)
exportImportCancelBtn:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 380, -192)
exportImportCancelBtn:SetScript("OnClick", function() exportImportPopup:Hide() end)
addonTable.exportImportPopup = exportImportPopup
addonTable.exportImportTitle = exportImportTitle
addonTable.importExportBox = exportImportEditBox
addonTable.exportImportOkBtn = exportImportOkBtn
addonTable.exportImportCancelBtn = exportImportCancelBtn
addonTable.exportCategories = exportCategories
addonTable.exportCheckboxContainer = exportCheckboxContainer
addonTable.generateExportBtn = generateExportBtn
addonTable.exportImportScrollFrame = exportImportScrollFrame
addonTable.editBoxBg = editBoxBg
addonTable.importContainer = importContainer
addonTable.importProfileNameBox = importProfileNameBox
local reloadPopup = CreateFrame("Frame", "CCMReloadPrompt", UIParent, "BackdropTemplate")
reloadPopup:SetSize(360, 170)
reloadPopup:SetPoint("CENTER")
reloadPopup:SetFrameStrata("TOOLTIP")
reloadPopup:SetFrameLevel(2000)
reloadPopup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
reloadPopup:SetBackdropColor(0.08, 0.08, 0.10, 0.98)
reloadPopup:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
reloadPopup:EnableMouse(true)
reloadPopup:SetMovable(true)
reloadPopup:SetToplevel(true)
reloadPopup:RegisterForDrag("LeftButton")
reloadPopup:SetScript("OnDragStart", reloadPopup.StartMoving)
reloadPopup:SetScript("OnDragStop", reloadPopup.StopMovingOrSizing)
reloadPopup:SetScript("OnShow", function(self) self:Raise() end)
reloadPopup:Hide()
local reloadTitle = reloadPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
reloadTitle:SetPoint("TOP", reloadPopup, "TOP", 0, -12)
reloadTitle:SetTextColor(1, 0.82, 0)
reloadTitle:SetText("Reload Required")
local reloadText = reloadPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
reloadText:SetPoint("TOPLEFT", reloadPopup, "TOPLEFT", 16, -38)
reloadText:SetPoint("TOPRIGHT", reloadPopup, "TOPRIGHT", -16, -38)
reloadText:SetJustifyH("LEFT")
reloadText:SetJustifyV("TOP")
reloadText:SetTextColor(0.9, 0.9, 0.9)
reloadText:SetSpacing(2)
reloadText:SetText("")
local reloadOkBtn = CreateStyledButton(reloadPopup, "Reload", 100, 26)
reloadOkBtn:SetPoint("BOTTOM", reloadPopup, "BOTTOM", -55, 15)
local reloadCancelBtn = CreateStyledButton(reloadPopup, "Later", 100, 26)
reloadCancelBtn:SetPoint("BOTTOM", reloadPopup, "BOTTOM", 55, 15)
reloadCancelBtn:SetScript("OnClick", function() reloadPopup:Hide() end)
addonTable.ShowReloadPrompt = function(message, okText, cancelText)
  reloadText:SetText(message or "A reload is recommended.")
  reloadOkBtn.text:SetText(okText or "Reload")
  reloadCancelBtn.text:SetText(cancelText or "Later")
  reloadOkBtn:SetScript("OnClick", function()
    reloadPopup:Hide()
    ReloadUI()
  end)
  reloadPopup:Show()
end
addonTable.reloadPopup = reloadPopup
addonTable.reloadPopupText = reloadText
local popupFrame = CreateFrame("Frame", "CCMPopupDialog", UIParent, "BackdropTemplate")
popupFrame:SetSize(300, 205)
popupFrame:SetPoint("CENTER")
popupFrame:SetFrameStrata("TOOLTIP")
popupFrame:SetFrameLevel(2000)
popupFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
popupFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.98)
popupFrame:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
popupFrame:EnableMouse(true)
popupFrame:SetMovable(true)
popupFrame:SetToplevel(true)
popupFrame:RegisterForDrag("LeftButton")
popupFrame:SetScript("OnDragStart", popupFrame.StartMoving)
popupFrame:SetScript("OnDragStop", popupFrame.StopMovingOrSizing)
popupFrame:SetScript("OnShow", function(self) self:Raise() end)
popupFrame:Hide()
local popupTitle = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
popupTitle:SetPoint("TOP", popupFrame, "TOP", 0, -15)
popupTitle:SetTextColor(1, 0.82, 0)
local popupEditBox = CreateFrame("EditBox", nil, popupFrame, "BackdropTemplate")
popupEditBox:SetSize(250, 28)
popupEditBox:SetPoint("TOP", popupTitle, "BOTTOM", 0, -15)
popupEditBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
popupEditBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
popupEditBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
popupEditBox:SetFontObject("GameFontHighlight")
popupEditBox:SetAutoFocus(true)
popupEditBox:SetTextInsets(8, 8, 0, 0)
local popupSourceLbl = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
popupSourceLbl:SetPoint("TOPLEFT", popupEditBox, "BOTTOMLEFT", 0, -10)
popupSourceLbl:SetText("Source Profile")
popupSourceLbl:SetTextColor(0.7, 0.7, 0.7)
local popupSourceDD = CreateFrame("Frame", nil, popupFrame, "BackdropTemplate")
popupSourceDD:SetSize(250, 24)
popupSourceDD:SetPoint("TOPLEFT", popupSourceLbl, "BOTTOMLEFT", 0, -4)
popupSourceDD:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
popupSourceDD:SetBackdropColor(0.12, 0.12, 0.14, 1)
popupSourceDD:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
local popupSourceTxt = popupSourceDD:CreateFontString(nil, "OVERLAY", "GameFontNormal")
popupSourceTxt:SetPoint("LEFT", popupSourceDD, "LEFT", 8, 0)
popupSourceTxt:SetPoint("RIGHT", popupSourceDD, "RIGHT", -20, 0)
popupSourceTxt:SetJustifyH("LEFT")
popupSourceTxt:SetTextColor(0.9, 0.9, 0.9)
local popupSourceArrow = popupSourceDD:CreateTexture(nil, "ARTWORK")
popupSourceArrow:SetSize(10, 10)
popupSourceArrow:SetPoint("RIGHT", popupSourceDD, "RIGHT", -8, 0)
popupSourceArrow:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down")
popupSourceArrow:SetVertexColor(0.6, 0.6, 0.6)
local popupSourceList = CreateFrame("Frame", nil, popupSourceDD, "BackdropTemplate")
popupSourceList:SetPoint("TOPLEFT", popupSourceDD, "BOTTOMLEFT", 0, -2)
popupSourceList:SetWidth(250)
popupSourceList:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
popupSourceList:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
popupSourceList:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
popupSourceList:SetFrameStrata("TOOLTIP")
popupSourceList:Hide()
popupSourceDD.options = {}
popupSourceDD.value = nil
function popupSourceDD:SetOptions(opts)
  popupSourceDD.options = opts or {}
  for _, child in ipairs({popupSourceList:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local yOff = 0
  for _, opt in ipairs(popupSourceDD.options) do
    local btn = CreateFrame("Button", nil, popupSourceList, "BackdropTemplate")
    btn:SetSize(248, 22)
    btn:SetPoint("TOPLEFT", popupSourceList, "TOPLEFT", 1, -yOff - 1)
    local btxt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btxt:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btxt:SetText(opt.text)
    btxt:SetTextColor(0.9, 0.9, 0.9)
    btn:SetScript("OnEnter", function() btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"}); btn:SetBackdropColor(0.25, 0.25, 0.3, 1) end)
    btn:SetScript("OnLeave", function() btn:SetBackdrop(nil) end)
    btn:SetScript("OnClick", function()
      popupSourceDD.value = opt.value
      popupSourceTxt:SetText(opt.text)
      popupSourceList:Hide()
    end)
    yOff = yOff + 22
  end
  popupSourceList:SetHeight(yOff + 2)
end
function popupSourceDD:SetValue(val)
  popupSourceDD.value = val
  for _, opt in ipairs(popupSourceDD.options) do
    if opt.value == val then popupSourceTxt:SetText(opt.text); return end
  end
  popupSourceTxt:SetText(val or "")
end
function popupSourceDD:GetValue()
  return popupSourceDD.value
end
popupSourceDD:SetScript("OnMouseDown", function()
  if popupSourceList:IsShown() then popupSourceList:Hide() else popupSourceList:Show() end
end)
popupSourceDD:SetScript("OnEnter", function() popupSourceDD:SetBackdropColor(0.18, 0.18, 0.22, 1) end)
popupSourceDD:SetScript("OnLeave", function() popupSourceDD:SetBackdropColor(0.12, 0.12, 0.14, 1) end)
popupSourceLbl:Hide()
popupSourceDD:Hide()
local popupSharedCB = CreateFrame("CheckButton", nil, popupFrame, "BackdropTemplate")
popupSharedCB:SetSize(18, 18)
popupSharedCB:SetPoint("TOPLEFT", popupEditBox, "BOTTOMLEFT", 0, -8)
popupSharedCB:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
popupSharedCB:SetBackdropColor(0.12, 0.12, 0.14, 1)
popupSharedCB:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
popupSharedCB.check = popupSharedCB:CreateTexture(nil, "OVERLAY")
popupSharedCB.check:SetSize(12, 12)
popupSharedCB.check:SetPoint("CENTER")
popupSharedCB.check:SetColorTexture(1, 0.82, 0, 1)
popupSharedCB.check:Hide()
popupSharedCB:SetScript("OnClick", function(s)
  if s.check:IsShown() then s.check:Hide() else s.check:Show() end
end)
popupSharedCB.GetChecked = function(s) return s.check:IsShown() end
popupSharedCB.SetChecked = function(s, v) if v then s.check:Show() else s.check:Hide() end end
local popupSharedLbl = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
popupSharedLbl:SetPoint("LEFT", popupSharedCB, "RIGHT", 6, 0)
popupSharedLbl:SetText("Shared profile (visible on all classes)")
popupSharedLbl:SetTextColor(0.7, 0.7, 0.7)
local popupOkBtn = CreateStyledButton(popupFrame, "OK", 80, 26)
popupOkBtn:SetPoint("BOTTOMRIGHT", popupFrame, "BOTTOM", -5, 15)
local popupCancelBtn = CreateStyledButton(popupFrame, "Cancel", 80, 26)
popupCancelBtn:SetPoint("BOTTOMLEFT", popupFrame, "BOTTOM", 5, 15)
popupCancelBtn:SetScript("OnClick", function() popupFrame:Hide() end)
popupEditBox:SetScript("OnEscapePressed", function() popupFrame:Hide() end)
popupEditBox:SetScript("OnEnterPressed", function() popupOkBtn:Click() end)
addonTable.popupFrame = popupFrame
addonTable.popupTitle = popupTitle
addonTable.popupEditBox = popupEditBox
addonTable.popupOkBtn = popupOkBtn
addonTable.popupSharedCB = popupSharedCB
addonTable.popupSharedLbl = popupSharedLbl
addonTable.popupSourceLbl = popupSourceLbl
addonTable.popupSourceDD = popupSourceDD
local examplePopup = CreateFrame("Frame", "CCMExampleProfilePopup", UIParent, "BackdropTemplate")
examplePopup:SetSize(320, 150)
examplePopup:SetPoint("CENTER")
examplePopup:SetFrameStrata("TOOLTIP")
examplePopup:SetFrameLevel(2000)
examplePopup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
examplePopup:SetBackdropColor(0.08, 0.08, 0.10, 0.98)
examplePopup:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
examplePopup:EnableMouse(true)
examplePopup:SetMovable(true)
examplePopup:SetToplevel(true)
examplePopup:RegisterForDrag("LeftButton")
examplePopup:SetScript("OnDragStart", examplePopup.StartMoving)
examplePopup:SetScript("OnDragStop", examplePopup.StopMovingOrSizing)
examplePopup:SetScript("OnShow", function(self) self:Raise() end)
examplePopup:Hide()
local examplePopupTitle = examplePopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
examplePopupTitle:SetPoint("TOP", examplePopup, "TOP", 0, -15)
examplePopupTitle:SetTextColor(1, 0.82, 0)
local examplePopupDesc = examplePopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
examplePopupDesc:SetPoint("TOP", examplePopupTitle, "BOTTOM", 0, -8)
examplePopupDesc:SetTextColor(0.7, 0.7, 0.7)
examplePopupDesc:SetText("Enter a name for the new profile:")
local examplePopupEditBox = CreateFrame("EditBox", nil, examplePopup, "BackdropTemplate")
examplePopupEditBox:SetSize(280, 28)
examplePopupEditBox:SetPoint("TOP", examplePopupDesc, "BOTTOM", 0, -10)
examplePopupEditBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
examplePopupEditBox:SetBackdropColor(0.12, 0.12, 0.14, 1)
examplePopupEditBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
examplePopupEditBox:SetFontObject("GameFontHighlight")
examplePopupEditBox:SetAutoFocus(true)
examplePopupEditBox:SetTextInsets(8, 8, 0, 0)
local examplePopupOkBtn = CreateStyledButton(examplePopup, "Create", 90, 26)
examplePopupOkBtn:SetPoint("BOTTOMRIGHT", examplePopup, "BOTTOM", -5, 15)
local examplePopupCancelBtn = CreateStyledButton(examplePopup, "Cancel", 90, 26)
examplePopupCancelBtn:SetPoint("BOTTOMLEFT", examplePopup, "BOTTOM", 5, 15)
examplePopupCancelBtn:SetScript("OnClick", function() examplePopup:Hide() end)
examplePopupEditBox:SetScript("OnEscapePressed", function() examplePopup:Hide() end)
examplePopupEditBox:SetScript("OnEnterPressed", function() examplePopupOkBtn:Click() end)
addonTable.examplePopup = examplePopup
addonTable.examplePopupTitle = examplePopupTitle
addonTable.examplePopupEditBox = examplePopupEditBox
addonTable.examplePopupOkBtn = examplePopupOkBtn
local function SaveCharacterProfile(profileName)
  local playerName = UnitName("player")
  local realmName = GetRealmName()
  if playerName and realmName and CooldownCursorManagerDB then
    local characterKey = playerName .. "-" .. realmName
    CooldownCursorManagerDB.characterProfiles = CooldownCursorManagerDB.characterProfiles or {}
    CooldownCursorManagerDB.characterProfiles[characterKey] = profileName
    local specID = GetSpecialization()
    if specID then
      local specKey = characterKey .. "-" .. specID
      CooldownCursorManagerDB.specProfiles = CooldownCursorManagerDB.specProfiles or {}
      CooldownCursorManagerDB.specProfiles[specKey] = profileName
    end
  end
end
local function DeepCopyProfileTable(orig)
  if type(orig) ~= "table" then return orig end
  local copy = {}
  for k, v in pairs(orig) do
    copy[k] = DeepCopyProfileTable(v)
  end
  return copy
end
local function SetCopySourceVisible(visible)
  popupSourceLbl:SetShown(visible)
  popupSourceDD:SetShown(visible)
  popupSourceList:Hide()
  popupSharedCB:ClearAllPoints()
  if visible then
    popupSharedCB:SetPoint("TOPLEFT", popupSourceDD, "BOTTOMLEFT", 0, -8)
  else
    popupSharedCB:SetPoint("TOPLEFT", popupEditBox, "BOTTOMLEFT", 0, -8)
  end
end
newProfileBtn:SetScript("OnClick", function()
  popupTitle:SetText("Create New Profile")
  popupEditBox:SetText("")
  popupEditBox:Show()
  SetCopySourceVisible(false)
  popupSharedCB:Show()
  popupSharedLbl:Show()
  popupSharedCB:SetChecked(false)
  popupOkBtn:SetScript("OnClick", function()
    local name = popupEditBox:GetText()
    if name and name ~= "" and CooldownCursorManagerDB then
      if not CooldownCursorManagerDB.profiles then
        CooldownCursorManagerDB.profiles = {Default = {}}
      end
      if not CooldownCursorManagerDB.profiles[name] then
        CooldownCursorManagerDB.profiles[name] = {}
        CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
        if popupSharedCB:GetChecked() then
          CooldownCursorManagerDB.profileClasses[name] = nil
        else
          local _, englishClass = UnitClass("player")
          CooldownCursorManagerDB.profileClasses[name] = englishClass
        end
        CooldownCursorManagerDB.currentProfile = name
        SaveCharacterProfile(name)
        profileText:SetText(name)
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if addonTable.CreateIcons then addonTable.CreateIcons() end
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.CreateCustomBar4Icons then addonTable.CreateCustomBar4Icons() end
        if addonTable.CreateCustomBar5Icons then addonTable.CreateCustomBar5Icons() end
      end
    end
    popupFrame:Hide()
  end)
  popupFrame:Show()
  popupEditBox:SetFocus()
end)
deleteProfileBtn:SetScript("OnClick", function()
  local currentName = CooldownCursorManagerDB and CooldownCursorManagerDB.currentProfile
  if currentName and currentName ~= "Default" then
    popupTitle:SetText("Delete '" .. currentName .. "'?")
    popupEditBox:Hide()
    SetCopySourceVisible(false)
    popupSharedCB:Hide()
    popupSharedLbl:Hide()
    popupOkBtn:SetScript("OnClick", function()
      CooldownCursorManagerDB.profiles[currentName] = nil
      if CooldownCursorManagerDB.profileClasses then
        CooldownCursorManagerDB.profileClasses[currentName] = nil
      end
      if CooldownCursorManagerDB.specProfiles then
        for k, v in pairs(CooldownCursorManagerDB.specProfiles) do
          if v == currentName then CooldownCursorManagerDB.specProfiles[k] = nil end
        end
      end
      if CooldownCursorManagerDB.characterProfiles then
        for k, v in pairs(CooldownCursorManagerDB.characterProfiles) do
          if v == currentName then CooldownCursorManagerDB.characterProfiles[k] = nil end
        end
      end
      CooldownCursorManagerDB.currentProfile = "Default"
      SaveCharacterProfile("Default")
      profileText:SetText("Default")
      popupEditBox:Show()
      popupSharedCB:Show()
      popupSharedLbl:Show()
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.CreateIcons then addonTable.CreateIcons() end
      if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
      if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
      if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
      popupFrame:Hide()
    end)
    popupFrame:Show()
  end
end)
copyProfileBtn:SetScript("OnClick", function()
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then return end
  local currentName = CooldownCursorManagerDB.currentProfile or "Default"
  local opts = {}
  for name in pairs(CooldownCursorManagerDB.profiles) do
    table.insert(opts, {text = name, value = name})
  end
  table.sort(opts, function(a, b) return a.text < b.text end)
  if #opts == 0 then return end
  popupTitle:SetText("Copy Profile")
  popupEditBox:SetText((currentName or "Profile") .. "_copy")
  popupEditBox:Show()
  SetCopySourceVisible(true)
  popupSharedCB:Show()
  popupSharedLbl:Show()
  popupSourceDD:SetOptions(opts)
  popupSourceDD:SetValue(currentName)
  local sourceClass = CooldownCursorManagerDB.profileClasses and CooldownCursorManagerDB.profileClasses[currentName]
  popupSharedCB:SetChecked(sourceClass == nil)
  popupOkBtn:SetScript("OnClick", function()
    local newName = popupEditBox:GetText()
    local sourceName = popupSourceDD:GetValue()
    if not newName or newName == "" or not sourceName or sourceName == "" then return end
    if CooldownCursorManagerDB.profiles[newName] then
      print("|cffff6666CCM:|r Profile '" .. newName .. "' already exists!")
      return
    end
    if not CooldownCursorManagerDB.profiles[sourceName] then
      print("|cffff6666CCM:|r Source profile not found: " .. tostring(sourceName))
      return
    end
    CooldownCursorManagerDB.profiles[newName] = DeepCopyProfileTable(CooldownCursorManagerDB.profiles[sourceName])
    CooldownCursorManagerDB.profiles[newName].trackedSpells = nil
    CooldownCursorManagerDB.profiles[newName].spellsEnabled = nil
    CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
    if popupSharedCB:GetChecked() then
      CooldownCursorManagerDB.profileClasses[newName] = nil
    else
      local _, englishClass = UnitClass("player")
      CooldownCursorManagerDB.profileClasses[newName] = englishClass
    end
    CooldownCursorManagerDB.currentProfile = newName
    SaveCharacterProfile(newName)
    profileText:SetText(newName)
    if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
    if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if addonTable.CreateIcons then addonTable.CreateIcons() end
    if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
    if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
    if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
    if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
    if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
    if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
    if addonTable.UpdatePRB then addonTable.UpdatePRB() end
    if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
    if addonTable.UpdateFocusCastbar then addonTable.UpdateFocusCastbar() end
    if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
    popupFrame:Hide()
  end)
  popupFrame:Show()
  popupEditBox:SetFocus()
  popupEditBox:HighlightText()
end)
profileBar:Hide()
local SIDEBAR_WIDTH = 140
local ACCENT_R, ACCENT_G, ACCENT_B = 1, 0.82, 0
local sidebar = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
sidebar:SetWidth(SIDEBAR_WIDTH)
sidebar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 2, 0)
sidebar:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 2, 26)
sidebar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
sidebar:SetBackdropColor(0.06, 0.06, 0.08, 1)
local sidebarScroll = CreateFrame("ScrollFrame", "CCMSidebarScroll", sidebar)
sidebarScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
sidebarScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
sidebarScroll:EnableMouseWheel(true)
local sidebarChild = CreateFrame("Frame", nil, sidebarScroll)
sidebarChild:SetWidth(SIDEBAR_WIDTH)
sidebarChild:SetHeight(900)
sidebarScroll:SetScrollChild(sidebarChild)
sidebarScroll:SetScript("OnMouseWheel", function(self, delta)
  local cur = self:GetVerticalScroll()
  local max = sidebarChild:GetHeight() - self:GetHeight()
  if max < 0 then max = 0 end
  local newVal = cur - (delta * 20)
  if newVal < 0 then newVal = 0 end
  if newVal > max then newVal = max end
  self:SetVerticalScroll(newVal)
end)
local sidebarDivider = cfg:CreateTexture(nil, "ARTWORK")
sidebarDivider:SetWidth(1)
sidebarDivider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
sidebarDivider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)
sidebarDivider:SetColorTexture(0.2, 0.2, 0.25, 1)
local contentContainer = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
contentContainer:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 1, 0)
contentContainer:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -2, 26)
contentContainer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
contentContainer:SetBackdropColor(0.10, 0.10, 0.12, 1)
local footer = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
footer:SetHeight(24)
footer:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 2, 2)
footer:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -2, 2)
footer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
footer:SetBackdropColor(0.08, 0.08, 0.10, 1)
local footerCredits = footer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
footerCredits:SetPoint("CENTER", footer, "CENTER", 0, 0)
footerCredits:SetText("Made by |cff3399ffEdeljay|r, |cffff8800Alevu|r & |cff9933ffDavidgetter|r")
footerCredits:SetTextColor(0.5, 0.5, 0.5)
local resizeGrip = CreateFrame("Button", nil, cfg)
resizeGrip:SetSize(14, 14)
resizeGrip:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -4, 4)
resizeGrip:SetFrameLevel(cfg:GetFrameLevel() + 10)
local gripColor = {0.4, 0.4, 0.45, 1}
local gripHighlight = {1, 0.82, 0, 1}
local gripDots = {}
local dotSize = 2
local spacing = 4
for row = 0, 2 do
  for col = 0, row do
    local dot = resizeGrip:CreateTexture(nil, "OVERLAY")
    dot:SetColorTexture(gripColor[1], gripColor[2], gripColor[3], gripColor[4])
    dot:SetSize(dotSize, dotSize)
    dot:SetPoint("BOTTOMRIGHT", resizeGrip, "BOTTOMRIGHT", -(row - col) * spacing, col * spacing)
    gripDots[#gripDots + 1] = dot
  end
end
resizeGrip:SetScript("OnEnter", function()
  for _, d in ipairs(gripDots) do d:SetColorTexture(gripHighlight[1], gripHighlight[2], gripHighlight[3], gripHighlight[4]) end
end)
resizeGrip:SetScript("OnLeave", function()
  for _, d in ipairs(gripDots) do d:SetColorTexture(gripColor[1], gripColor[2], gripColor[3], gripColor[4]) end
end)
resizeGrip:SetScript("OnMouseDown", function()
  local _, cursorY = GetCursorPosition()
  local scale = cfg:GetEffectiveScale()
  cfg._resizeCursorStart = cursorY / scale
  cfg._resizeHeightStart = cfg:GetHeight()
  cfg._resizing = true
  cfg:SetScript("OnUpdate", function()
    if not cfg._resizing then return end
    local _, cy = GetCursorPosition()
    local delta = cfg._resizeCursorStart - cy / scale
    local newH = math.max(400, math.min(1200, cfg._resizeHeightStart + delta))
    cfg:SetHeight(newH)
  end)
end)
resizeGrip:SetScript("OnMouseUp", function()
  cfg._resizing = false
  cfg:SetScript("OnUpdate", nil)
  local h = math.floor(cfg:GetHeight() + 0.5)
  if CooldownCursorManagerDB then
    CooldownCursorManagerDB.guiHeight = h
  end
end)
local tabFrames, activeTab = {}, nil
local MAX_TABS = 25
local TAB_UF = 11
local TAB_QOL = 12
local TAB_TCASTBAR = 13
local TAB_ACTIONBARS = 14
local TAB_CHAT = 15
local TAB_SKYRIDING = 16
local TAB_FEATURES = 18
local TAB_COMBAT = 19
local TAB_PROFILES = 17
local TAB_CUSTOMBAR4 = 20
local TAB_CUSTOMBAR5 = 21
local TAB_UF_PLAYER = 22
local TAB_UF_TARGET = 23
local TAB_UF_FOCUS = 24
local TAB_UF_BOSS = 25
for i = 1, MAX_TABS do
  tabFrames[i] = CreateFrame("Frame", nil, contentContainer)
  tabFrames[i]:SetAllPoints()
  tabFrames[i]:Hide()
end
searchBg:SetParent(sidebar)
searchBg:ClearAllPoints()
searchBg:SetSize(SIDEBAR_WIDTH - 12, 22)
searchBg:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -6)
sidebarScroll:ClearAllPoints()
sidebarScroll:SetPoint("TOPLEFT", searchBg, "BOTTOMLEFT", -6, -6)
sidebarScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
profileBar:SetParent(tabFrames[TAB_PROFILES])
profileBar:ClearAllPoints()
profileBar:SetPoint("TOPLEFT", tabFrames[TAB_PROFILES], "TOPLEFT", 0, -40)
profileBar:SetPoint("TOPRIGHT", tabFrames[TAB_PROFILES], "TOPRIGHT", 0, -40)
profileBar:Show()
local profHeader = tabFrames[TAB_PROFILES]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profHeader:SetPoint("TOPLEFT", tabFrames[TAB_PROFILES], "TOPLEFT", 15, -12)
profHeader:SetText("Profile Management")
profHeader:SetTextColor(1, 0.82, 0)
local profHeaderLine = tabFrames[TAB_PROFILES]:CreateTexture(nil, "ARTWORK")
profHeaderLine:SetHeight(1)
profHeaderLine:SetPoint("LEFT", profHeader, "RIGHT", 8, 0)
profHeaderLine:SetPoint("RIGHT", tabFrames[TAB_PROFILES], "RIGHT", -15, 0)
profHeaderLine:SetColorTexture(0.3, 0.3, 0.35, 1)
profHeaderLine:SetSnapToPixelGrid(true)
profHeaderLine:SetTexelSnappingBias(0)
local profTab = tabFrames[TAB_PROFILES]
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
local exProfHeader = profTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
exProfHeader:SetPoint("TOPLEFT", profTab, "TOPLEFT", 15, -90)
exProfHeader:SetText("Example Profiles")
exProfHeader:SetTextColor(1, 0.82, 0)
local exProfLine = profTab:CreateTexture(nil, "ARTWORK")
exProfLine:SetHeight(1)
exProfLine:SetPoint("LEFT", exProfHeader, "RIGHT", 8, 0)
exProfLine:SetPoint("RIGHT", profTab, "RIGHT", -15, 0)
exProfLine:SetColorTexture(0.3, 0.3, 0.35, 1)
exProfLine:SetSnapToPixelGrid(true)
exProfLine:SetTexelSnappingBias(0)
local exampleDesc = profTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
exampleDesc:SetPoint("TOPLEFT", profTab, "TOPLEFT", 15, -108)
exampleDesc:SetText("|cff888888Load a preset profile optimized for your role. This will overwrite your current profile settings.|r")
addonTable.exampleProfileDPSBtn = CreateExampleProfileButton(profTab, "DPS", "DPS", 15, -132, {r=1, g=0.3, b=0.3})
addonTable.exampleProfileTankBtn = CreateExampleProfileButton(profTab, "Tank", "Tank", 155, -132, {r=0.3, g=0.5, b=1})
addonTable.exampleProfileHealerBtn = CreateExampleProfileButton(profTab, "Healer", "Healer", 295, -132, {r=0.3, g=1, b=0.5})
local exampleNote = profTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
exampleNote:SetPoint("TOPLEFT", profTab, "TOPLEFT", 15, -170)
exampleNote:SetText("|cffFFD100Note:|r After loading, customize the profile to your needs and add spells to the Custom Bars.")
exampleNote:SetJustifyH("LEFT")
exampleNote:SetTextColor(0.7, 0.7, 0.7)
addonTable.installWizardBtn = CreateStyledButton(profTab, "Run Installer", 150, 24)
addonTable.installWizardBtn:SetPoint("TOP", addonTable.exampleProfileTankBtn, "BOTTOM", 0, -38)
local installWizardNote = profTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
installWizardNote:SetPoint("TOP", addonTable.installWizardBtn, "BOTTOM", 0, -6)
installWizardNote:SetTextColor(0.6, 0.6, 0.65)
installWizardNote:SetText("or type /ccminstall")
local sidebarButtons = {}
local expandState = {custombars = true, castbars = true, unitframes = true, qol = true}
local sidebarSep = sidebarChild:CreateTexture(nil, "ARTWORK")
sidebarSep:SetHeight(1)
sidebarSep:SetColorTexture(0.2, 0.2, 0.25, 0.6)
sidebarSep:Hide()
local function StopAllPreviews()
  if addonTable.StopCursorIconPreview then addonTable.StopCursorIconPreview() end
  if addonTable.ClearConfigPreviewCountdowns then addonTable.ClearConfigPreviewCountdowns() end
  if addonTable.StopCastbarPreview then addonTable.StopCastbarPreview() end
  if addonTable.StopFocusCastbarPreview then addonTable.StopFocusCastbarPreview() end
  if addonTable.StopTargetCastbarPreview then addonTable.StopTargetCastbarPreview() end
  if addonTable.StopDebuffPreview then addonTable.StopDebuffPreview() end
  if addonTable.StopNoTargetAlertPreview then addonTable.StopNoTargetAlertPreview() end
  if addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end
  if addonTable.StopSkyridingPreview then addonTable.StopSkyridingPreview() end
  if addonTable.StopLowHealthWarningPreview then addonTable.StopLowHealthWarningPreview() end
  if addonTable.StopUFBossPreview then addonTable.StopUFBossPreview() end
  if addonTable.ResetAllPreviewHighlights then addonTable.ResetAllPreviewHighlights() end
end
local TAB_WIDTHS = {
  [1] = 710, [2] = 870, [3] = 870, [4] = 870, [5] = 870,
  [6] = 720, [7] = 710, [8] = 710, [9] = 710, [10] = 710,
  [TAB_UF] = 800, [TAB_QOL] = 710, [TAB_TCASTBAR] = 710,
  [TAB_UF_PLAYER] = 800, [TAB_UF_TARGET] = 800, [TAB_UF_FOCUS] = 800, [TAB_UF_BOSS] = 800,
  [TAB_ACTIONBARS] = 710, [TAB_CHAT] = 710, [TAB_SKYRIDING] = 710,
  [TAB_PROFILES] = 710, [TAB_FEATURES] = 710, [TAB_COMBAT] = 710,
  [TAB_CUSTOMBAR4] = 870, [TAB_CUSTOMBAR5] = 870,
}
local function ActivateTab(idx, force)
  if activeTab == idx and not force then return end
  StopAllPreviews()
  activeTab = idx
  local w = TAB_WIDTHS[idx] or 680
  cfg:SetWidth(w)
  cfg:SetResizeBounds(w, 400, w, 1200)
  if addonTable.FitConfigToScreen then
    addonTable.FitConfigToScreen(cfg)
  end
  for i = 1, MAX_TABS do
    if tabFrames[i] then tabFrames[i]:Hide() end
  end
  if tabFrames[idx] then tabFrames[idx]:Show() end
  if idx == 2 and addonTable.ShowCursorIconPreview then addonTable.ShowCursorIconPreview() end
  if idx == 8 and addonTable.ShowCastbarPreview then addonTable.ShowCastbarPreview() end
  if idx == 9 and addonTable.ShowFocusCastbarPreview then addonTable.ShowFocusCastbarPreview() end
  if idx == TAB_TCASTBAR and addonTable.ShowTargetCastbarPreview then addonTable.ShowTargetCastbarPreview() end
  if idx == 10 and addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
  if idx == 2 and addonTable.RefreshCursorSpellList then addonTable.RefreshCursorSpellList() end
  if idx == 3 and addonTable.RefreshCB1SpellList then addonTable.RefreshCB1SpellList() end
  if idx == 4 and addonTable.RefreshCB2SpellList then addonTable.RefreshCB2SpellList() end
  if idx == 5 and addonTable.RefreshCB3SpellList then addonTable.RefreshCB3SpellList() end
  if idx == TAB_CUSTOMBAR4 and addonTable.RefreshCB4SpellList then addonTable.RefreshCB4SpellList() end
  if idx == TAB_CUSTOMBAR5 and addonTable.RefreshCB5SpellList then addonTable.RefreshCB5SpellList() end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  if addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(idx) end
  for _, sb in ipairs(sidebarButtons) do
    if sb.UpdateVisual then sb:UpdateVisual() end
  end
end
local function RebuildSidebar()
  for _, sb in ipairs(sidebarButtons) do sb:Hide() end
  wipe(sidebarButtons)
  local profile = GetProfile()
  local barsCount = profile and profile.customBarsCount or 0
  local usePRB = profile and profile.usePersonalResourceBar or false
  local useCastbar = profile and profile.useCastbar or false
  local useFocusCastbar = profile and profile.useFocusCastbar or false
  local useTargetCastbar = profile and profile.useTargetCastbar or false
  local useDebuffs = profile and profile.enablePlayerDebuffs or false
  local useUF = profile == nil or profile.enableUnitFrameCustomization ~= false
  local ufBigMaster
  if profile then
    ufBigMaster = (profile.ufBigHBPlayerEnabled == true) or (profile.ufBigHBTargetEnabled == true) or (profile.ufBigHBFocusEnabled == true)
  else
    ufBigMaster = true
  end
  local useCursorCDM = profile and profile.cursorIconsEnabled ~= false
  local disableBlizzCDM = profile and profile.disableBlizzCDM == true
  local yOff = -6
  local BTN_H = 26
  local SUB_H = 24
  local function CreateSidebarBtn(tabIdx, label, isSubTab, offState, isExpander, expandKey, offTextKind)
    local btn = CreateFrame("Button", nil, sidebarChild, "BackdropTemplate")
    btn._ccmControlType = "sidebarbtn"
    local h = isSubTab and SUB_H or BTN_H
    btn:SetSize(SIDEBAR_WIDTH, h)
    btn:SetPoint("TOPLEFT", sidebarChild, "TOPLEFT", 0, yOff)
    btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    local stripe = btn:CreateTexture(nil, "ARTWORK")
    stripe:SetSize(3, h)
    stripe:SetPoint("LEFT", btn, "LEFT", 0, 0)
    stripe:SetColorTexture(0, 0, 0, 0)
    btn.stripe = stripe
    local textX = isSubTab and 20 or 10
    local tx = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tx:SetPoint("LEFT", btn, "LEFT", textX, 0)
    tx:SetText(label)
    tx:SetTextColor(0.7, 0.7, 0.7)
    tx:SetJustifyH("LEFT")
    btn.text = tx
    btn.tabIdx = tabIdx
    btn.offState = offState
    btn.isSubTab = isSubTab
    local offLabel = nil
    if offState then
      offLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      offLabel:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
      offLabel:SetText(offTextKind == "disabled" and "(Disabled)" or "(off)")
      offLabel:SetTextColor(0.85, 0.75, 0.2)
      offLabel:SetFont("Fonts\\FRIZQT__.TTF", 11)
      offLabel:Hide()
    end
    btn.offLabel = offLabel
    local arrow = nil
    if isExpander then
      arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      arrow:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
      if expandState[expandKey] then arrow:SetText("v") else arrow:SetText(">") end
      arrow:SetTextColor(0.5, 0.5, 0.5)
      arrow:SetFont("Fonts\\FRIZQT__.TTF", 10)
    end
    btn.arrow = arrow
    btn.expandKey = expandKey
    function btn:UpdateVisual()
      if self.tabIdx and activeTab == self.tabIdx then
        self.stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 1)
        self.text:SetTextColor(1, 1, 1)
        self:SetBackdropColor(0.10, 0.10, 0.12, 1)
      else
        self.stripe:SetColorTexture(0, 0, 0, 0)
        if self.offState then
          self.text:SetTextColor(0.4, 0.4, 0.4)
        else
          self.text:SetTextColor(0.7, 0.7, 0.7)
        end
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
      end
      if self.offLabel then
        self.offLabel:SetShown(self.offState == true)
      end
    end
    btn:SetScript("OnEnter", function(self)
      if activeTab ~= self.tabIdx then
        self:SetBackdropColor(0.10, 0.12, 0.10, 1)
        self.text:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
      end
    end)
    btn:SetScript("OnLeave", function(self) self:UpdateVisual() end)
    btn:SetScript("OnClick", function(self)
      if self.expandKey then
        expandState[self.expandKey] = not expandState[self.expandKey]
        if self.arrow then
          self.arrow:SetText(expandState[self.expandKey] and "v" or ">")
        end
        RebuildSidebar()
        return
      end
      if self.tabIdx then
        ActivateTab(self.tabIdx)
      end
    end)
    btn:UpdateVisual()
    sidebarButtons[#sidebarButtons + 1] = btn
    yOff = yOff - h
    return btn
  end
  local isModuleEnabled = addonTable.IsModuleEnabled
  local moduleCustomBars = (not isModuleEnabled) or isModuleEnabled("custombars")
  local moduleBlizzCDM = (not isModuleEnabled) or isModuleEnabled("blizzcdm")
  local modulePRB = (not isModuleEnabled) or isModuleEnabled("prb")
  local moduleCastbars = (not isModuleEnabled) or isModuleEnabled("castbars")
  local moduleDebuffs = (not isModuleEnabled) or isModuleEnabled("debuffs")
  local moduleUnitFrames = (not isModuleEnabled) or isModuleEnabled("unitframes")
  local moduleQOL = (not isModuleEnabled) or isModuleEnabled("qol")
  CreateSidebarBtn(1, "General")
  CreateSidebarBtn(2, "Cursor CDM", false, not useCursorCDM)
  CreateSidebarBtn(nil, "Custom Bars", false, (not moduleCustomBars) or (barsCount == 0), true, "custombars", (not moduleCustomBars) and "disabled" or nil)
  if expandState.custombars then
    if barsCount >= 1 then CreateSidebarBtn(3, "Bar 1", true, not moduleCustomBars, nil, nil, (not moduleCustomBars) and "disabled" or nil) end
    if barsCount >= 2 then CreateSidebarBtn(4, "Bar 2", true, not moduleCustomBars, nil, nil, (not moduleCustomBars) and "disabled" or nil) end
    if barsCount >= 3 then CreateSidebarBtn(5, "Bar 3", true, not moduleCustomBars, nil, nil, (not moduleCustomBars) and "disabled" or nil) end
    if barsCount >= 4 then CreateSidebarBtn(TAB_CUSTOMBAR4, "Bar 4", true, not moduleCustomBars, nil, nil, (not moduleCustomBars) and "disabled" or nil) end
    if barsCount >= 5 then CreateSidebarBtn(TAB_CUSTOMBAR5, "Bar 5", true, not moduleCustomBars, nil, nil, (not moduleCustomBars) and "disabled" or nil) end
  end
  CreateSidebarBtn(6, "Blizz CDM", false, (not moduleBlizzCDM) or disableBlizzCDM, nil, nil, (not moduleBlizzCDM) and "disabled" or nil)
  CreateSidebarBtn(7, "PRB", false, (not modulePRB) or (not usePRB), nil, nil, (not modulePRB) and "disabled" or nil)
  local anyCastbar = useCastbar or useFocusCastbar or useTargetCastbar
  CreateSidebarBtn(nil, "Castbars", false, (not moduleCastbars) or (not anyCastbar), true, "castbars", (not moduleCastbars) and "disabled" or nil)
  if expandState.castbars then
    CreateSidebarBtn(8, "Player", true, (not moduleCastbars) or (not useCastbar), nil, nil, (not moduleCastbars) and "disabled" or nil)
    CreateSidebarBtn(9, "Focus", true, (not moduleCastbars) or (not useFocusCastbar), nil, nil, (not moduleCastbars) and "disabled" or nil)
    CreateSidebarBtn(TAB_TCASTBAR, "Target", true, (not moduleCastbars) or (not useTargetCastbar), nil, nil, (not moduleCastbars) and "disabled" or nil)
  end
  CreateSidebarBtn(10, "Debuffs", false, (not moduleDebuffs) or (not useDebuffs), nil, nil, (not moduleDebuffs) and "disabled" or nil)
  local unitframesBaseOff = (not moduleUnitFrames) or (not useUF and useUF ~= nil)
  CreateSidebarBtn(nil, "Unit Frames", false, unitframesBaseOff, true, "unitframes", (not moduleUnitFrames) and "disabled" or nil)
  if expandState.unitframes then
    CreateSidebarBtn(TAB_UF, "Main", true, unitframesBaseOff, nil, nil, (not moduleUnitFrames) and "disabled" or nil)
    CreateSidebarBtn(TAB_UF_PLAYER, "Player", true, unitframesBaseOff or (not ufBigMaster) or (profile and profile.ufBigHBPlayerEnabled ~= true), nil, nil, (not moduleUnitFrames) and "disabled" or nil)
    CreateSidebarBtn(TAB_UF_TARGET, "Target", true, unitframesBaseOff or (not ufBigMaster) or (profile and profile.ufBigHBTargetEnabled ~= true), nil, nil, (not moduleUnitFrames) and "disabled" or nil)
    CreateSidebarBtn(TAB_UF_FOCUS, "Focus", true, unitframesBaseOff or (not ufBigMaster) or (profile and profile.ufBigHBFocusEnabled ~= true), nil, nil, (not moduleUnitFrames) and "disabled" or nil)
    CreateSidebarBtn(TAB_UF_BOSS, "Boss", true, unitframesBaseOff or (profile and profile.ufBossFramesEnabled ~= true), nil, nil, (not moduleUnitFrames) and "disabled" or nil)
  end
  CreateSidebarBtn(nil, "QoL", false, not moduleQOL, true, "qol", (not moduleQOL) and "disabled" or nil)
  if expandState.qol then
    CreateSidebarBtn(TAB_QOL, "Alerts", true, not moduleQOL, nil, nil, (not moduleQOL) and "disabled" or nil)
    CreateSidebarBtn(TAB_FEATURES, "Features", true, not moduleQOL, nil, nil, (not moduleQOL) and "disabled" or nil)
    CreateSidebarBtn(TAB_COMBAT, "Combat", true, not moduleQOL, nil, nil, (not moduleQOL) and "disabled" or nil)
    CreateSidebarBtn(TAB_ACTIONBARS, "Action Bars", true, not moduleQOL, nil, nil, (not moduleQOL) and "disabled" or nil)
    CreateSidebarBtn(TAB_CHAT, "Chat", true, not moduleQOL, nil, nil, (not moduleQOL) and "disabled" or nil)
    CreateSidebarBtn(TAB_SKYRIDING, "Skyriding", true, not moduleQOL, nil, nil, (not moduleQOL) and "disabled" or nil)
  end
  yOff = yOff - 10
  sidebarSep:ClearAllPoints()
  sidebarSep:SetPoint("TOPLEFT", sidebarChild, "TOPLEFT", 8, yOff)
  sidebarSep:SetPoint("TOPRIGHT", sidebarChild, "TOPRIGHT", -8, yOff)
  sidebarSep:Show()
  yOff = yOff - 6
  CreateSidebarBtn(TAB_PROFILES, "Profiles")
  sidebarChild:SetHeight(math.abs(yOff) + 20)
end
local function UpdateTabVisibility()
  RebuildSidebar()
  local profile = GetProfile()
  local barsCount = profile and profile.customBarsCount or 0
  if activeTab and ((activeTab >= 3 and activeTab <= 5) or activeTab == TAB_CUSTOMBAR4 or activeTab == TAB_CUSTOMBAR5) then
    local tabVisible = (activeTab == 3 and barsCount >= 1) or (activeTab == 4 and barsCount >= 2) or (activeTab == 5 and barsCount >= 3) or (activeTab == TAB_CUSTOMBAR4 and barsCount >= 4) or (activeTab == TAB_CUSTOMBAR5 and barsCount >= 5)
    if not tabVisible then ActivateTab(1) end
  end
end
-- Search logic: highlight tabs containing matching labels
local function CollectFrameLabels(frame)
  local results = {}
  local function ScanRecursive(f)
    for _, region in pairs({f:GetRegions()}) do
      if region.GetText and region:GetText() and region:GetText() ~= "" then
        tinsert(results, strlower(region:GetText()))
      end
    end
    if f.GetChildren then
      for _, child in pairs({f:GetChildren()}) do
        ScanRecursive(child)
      end
    end
    if f.GetScrollChild then
      local sc = f:GetScrollChild()
      if sc then ScanRecursive(sc) end
    end
  end
  ScanRecursive(frame)
  return results
end
-- Highlight / reset matching FontStrings inside a tab frame
local function HighlightMatchingInFrame(frame, query)
  if not frame then return end
  local function ProcessRecursive(f)
    for _, region in pairs({f:GetRegions()}) do
      if region.GetText and region:GetText() and region:GetText() ~= "" then
        if not region._searchOrigR then
          region._searchOrigR, region._searchOrigG, region._searchOrigB, region._searchOrigA = region:GetTextColor()
        end
        if query ~= "" and strfind(strlower(region:GetText()), query, 1, true) then
          region:SetTextColor(0, 1, 0.5, 1)
        else
          region:SetTextColor(region._searchOrigR, region._searchOrigG, region._searchOrigB, region._searchOrigA or 1)
        end
      end
    end
    if f.GetChildren then
      for _, child in pairs({f:GetChildren()}) do
        ProcessRecursive(child)
      end
    end
    if f.GetScrollChild then
      local sc = f:GetScrollChild()
      if sc then ProcessRecursive(sc) end
    end
  end
  ProcessRecursive(frame)
end
local function ResetFrameHighlights(frame)
  if not frame then return end
  local function ResetRecursive(f)
    for _, region in pairs({f:GetRegions()}) do
      if region._searchOrigR then
        region:SetTextColor(region._searchOrigR, region._searchOrigG, region._searchOrigB, region._searchOrigA or 1)
        region._searchOrigR = nil; region._searchOrigG = nil; region._searchOrigB = nil; region._searchOrigA = nil
      end
    end
    if f.GetChildren then
      for _, child in pairs({f:GetChildren()}) do
        ResetRecursive(child)
      end
    end
    if f.GetScrollChild then
      local sc = f:GetScrollChild()
      if sc then ResetRecursive(sc) end
    end
  end
  ResetRecursive(frame)
end
addonTable._searchUpdate = function(query)
  query = strlower(strtrim(query))
  for i = 1, MAX_TABS do
    if tabFrames[i] then
      if query == "" then
        ResetFrameHighlights(tabFrames[i])
      else
        if activeTab == i then
          HighlightMatchingInFrame(tabFrames[i], query)
        else
          ResetFrameHighlights(tabFrames[i])
        end
      end
    end
  end
  for _, sb in ipairs(sidebarButtons) do
    if sb.tabIdx and query ~= "" then
      local found = false
      if sb.text:GetText() and strfind(strlower(sb.text:GetText()), query, 1, true) then found = true end
      if not found and tabFrames[sb.tabIdx] then
        local labels = CollectFrameLabels(tabFrames[sb.tabIdx])
        for _, lbl in ipairs(labels) do
          if strfind(lbl, query, 1, true) then found = true; break end
        end
      end
      if found then
        sb.text:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
      else
        sb:UpdateVisual()
      end
    elseif query == "" then
      sb:UpdateVisual()
    end
  end
end
addonTable.ConfigFrame = cfg
addonTable.tabFrames = tabFrames
addonTable.MAX_TABS = MAX_TABS
addonTable.TAB_UF = TAB_UF
addonTable.TAB_UF_PLAYER = TAB_UF_PLAYER
addonTable.TAB_UF_TARGET = TAB_UF_TARGET
addonTable.TAB_UF_FOCUS = TAB_UF_FOCUS
addonTable.TAB_UF_BOSS = TAB_UF_BOSS
addonTable.TAB_QOL = TAB_QOL
addonTable.TAB_ACTIONBARS = TAB_ACTIONBARS
addonTable.TAB_CHAT = TAB_CHAT
addonTable.TAB_SKYRIDING = TAB_SKYRIDING
addonTable.TAB_FEATURES = TAB_FEATURES
addonTable.TAB_COMBAT = TAB_COMBAT
addonTable.TAB_PROFILES = TAB_PROFILES
addonTable.activeTab = function() return activeTab end
addonTable.setActiveTab = function(idx) activeTab = idx end
addonTable.UpdateTabVisibility = UpdateTabVisibility
addonTable.RebuildSidebar = RebuildSidebar
addonTable.ActivateTab = ActivateTab
addonTable.SwitchToTab = function(idx)
  if not cfg:IsShown() then return end
  if idx < 1 or idx > MAX_TABS then return end
  ActivateTab(idx)
end
addonTable.profileText = profileText
addonTable.profileDropdown = profileDropdown
addonTable.profileList = profileList
addonTable.newProfileBtn = newProfileBtn
addonTable.deleteProfileBtn = deleteProfileBtn
addonTable.expBtn = expBtn
addonTable.impBtn = impBtn
addonTable.copyProfileBtn = copyProfileBtn
activeTab = 1
tabFrames[1]:Show()
RebuildSidebar()
SLASH_CCM1 = "/ccm"
SlashCmdList["CCM"] = function()
  if InCombatLockdown() then
    if addonTable.SetOpenAfterCombat then addonTable.SetOpenAfterCombat(true) end
    print("|cff00ff00CCM:|r Settings will open after combat.")
    return
  end
  if cfg:IsShown() then
    cfg:Hide()
    SetGUIOpen(false)
  else
    SetGUIOpen(true)
    if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
    if addonTable.MaybeShowUpdateChangelogOnConfigOpen then
      addonTable.MaybeShowUpdateChangelogOnConfigOpen()
    end
    cfg:Show()
  end
end
SLASH_BLIZZCM1 = "/cm"
SlashCmdList["BLIZZCM"] = function()
  if InCombatLockdown() then
    print("|cff00ff00CCM:|r Cannot open settings in combat.")
    return
  end
  if CooldownViewerSettings then
    if CooldownViewerSettings:IsShown() then
      CooldownViewerSettings:Hide()
    else
      CooldownViewerSettings:Show()
    end
  else
    print("|cff00ff00CCM:|r CooldownViewerSettings not available.")
  end
end
SLASH_CCMEDITMODE1 = "/em"
SlashCmdList["CCMEDITMODE"] = function()
  if InCombatLockdown() then
    print("|cff00ff00CCM:|r Cannot open Edit Mode in combat.")
    return
  end
  if EditModeManagerFrame and EditModeManagerFrame.Show then
    EditModeManagerFrame:Show()
  end
end
SLASH_CCMDEBUG1 = "/ccmdebug"
SlashCmdList["CCMDEBUG"] = function(msg)
  local trimmed = type(msg) == "string" and msg:match("^%s*(.-)%s*$") or ""
  if trimmed == "stop" then
    if addonTable.StopCCMDebugProfile then
      addonTable.StopCCMDebugProfile()
    else
      print("|cff00ff00CCM Debug:|r profiler not available.")
    end
    return
  end
  local seconds = tonumber(trimmed) or 10
  if addonTable.StartCCMDebugProfile then
    addonTable.StartCCMDebugProfile(seconds)
  else
    print("|cff00ff00CCM Debug:|r profiler not available.")
  end
end
SLASH_CCMINSTALL1 = "/ccminstall"
SlashCmdList["CCMINSTALL"] = function()
  if InCombatLockdown() then
    print("|cff00ff00CCM:|r Cannot open installer in combat.")
    return
  end
  if addonTable.OpenInstallWizard then
    addonTable.OpenInstallWizard()
  else
    print("|cff00ff00CCM:|r Installer not available.")
  end
end
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, ev, arg)
  if ev == "ADDON_LOADED" and arg == addonName then
    C_Timer.After(0.1, function()
      if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
      if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    end)
    local optionsPanel = CreateFrame("Frame")
    optionsPanel.name = "Cooldown Cursor Manager"
    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Cooldown Cursor Manager")
    local desc = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Display spell cooldowns near your cursor")
    local openBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    openBtn:SetSize(200, 30)
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    openBtn:SetText("Open Settings")
    openBtn:SetScript("OnClick", function()
      if InCombatLockdown() then
        print("|cffff6666CCM:|r Cannot open settings during combat!")
        return
      end
      HideUIPanel(SettingsPanel)
      SetGUIOpen(true)
      if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
      cfg:Show()
    end)
    local slashInfo = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slashInfo:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -15)
    slashInfo:SetText("|cff888888Slash command: /ccm|r")
    local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
    Settings.RegisterAddOnCategory(category)
  end
end)
addonTable.RefreshConfigOnShow = function()
  if activeTab == 3 or activeTab == 4 or activeTab == 5 then
    ActivateTab(1)
  else
    ActivateTab(activeTab, true)
  end
  if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
  if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
  if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
  RebuildSidebar()
end

