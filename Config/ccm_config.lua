--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_config.lua
-- Configuration UI main frame and panel management
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
local addonTable = CCM
local function GetProfile() return addonTable.GetProfile and addonTable.GetProfile() end
local function CreateIcons() if addonTable.CreateIcons then addonTable.CreateIcons() end end
local function UpdateAllIcons() if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end
local function SetGUIOpen(v) if addonTable.SetGUIOpen then addonTable.SetGUIOpen(v) end end
addonTable.ConfigGetProfile = GetProfile
addonTable.ConfigCreateIcons = CreateIcons
addonTable.ConfigSetGUIOpen = SetGUIOpen
local function CreateStyledButton(parent, text, w, h)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(w, h)
  btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
  btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  t:SetPoint("CENTER")
  t:SetText(text)
  t:SetTextColor(0.9, 0.9, 0.9)
  btn.text = t
  btn:SetScript("OnEnter", function() btn:SetBackdropColor(0.25, 0.25, 0.3, 1); t:SetTextColor(1, 1, 1) end)
  btn:SetScript("OnLeave", function() btn:SetBackdropColor(0.15, 0.15, 0.18, 1); t:SetTextColor(0.9, 0.9, 0.9) end)
  return btn
end
addonTable.CreateStyledButton = CreateStyledButton
local cfg = CreateFrame("Frame", "CCMConfig", UIParent, "BackdropTemplate")
cfg:SetSize(714, 938)
cfg:SetPoint("CENTER")
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:SetClampedToScreen(true)
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
end)
cfg:SetScript("OnHide", function()
  SetGUIOpen(false)
  if addonTable.StopCursorIconPreview then
    addonTable.StopCursorIconPreview()
  end
  if addonTable.StopCastbarPreview then
    addonTable.StopCastbarPreview()
  end
  if addonTable.StopFocusCastbarPreview then
    addonTable.StopFocusCastbarPreview()
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
  if addonTable.ResetAllPreviewHighlights then
    addonTable.ResetAllPreviewHighlights()
  end
end)
cfg:Hide()
cfg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
cfg:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
cfg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
local titleBar = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
titleBar:SetHeight(32)
titleBar:SetPoint("TOPLEFT", cfg, "TOPLEFT", 2, -2)
titleBar:SetPoint("TOPRIGHT", cfg, "TOPRIGHT", -2, -2)
titleBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
titleBar:SetBackdropColor(0.15, 0.15, 0.18, 1)
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
titleText:SetText("Cooldown Cursor Manager")
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
local minimapBtn = CreateFrame("CheckButton", nil, profileBar, "BackdropTemplate")
minimapBtn:SetSize(20, 20)
minimapBtn:SetPoint("LEFT", copyProfileBtn, "RIGHT", 15, 0)
minimapBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
minimapBtn:SetBackdropColor(0.08, 0.08, 0.10, 1)
minimapBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
local minimapCheck = minimapBtn:CreateTexture(nil, "ARTWORK")
minimapCheck:SetSize(12, 12)
minimapCheck:SetPoint("CENTER")
minimapCheck:SetColorTexture(1, 0.82, 0, 1)
minimapCheck:Hide()
minimapBtn.check = minimapCheck
minimapBtn:SetChecked(false)
local function UpdateMinimapCheckState()
  if minimapBtn:GetChecked() then
    minimapCheck:Show()
    minimapBtn:SetBackdropColor(0.15, 0.15, 0.18, 1)
  else
    minimapCheck:Hide()
    minimapBtn:SetBackdropColor(0.08, 0.08, 0.10, 1)
  end
end
minimapBtn:SetScript("OnClick", function()
  UpdateMinimapCheckState()
  if minimapBtn.customOnClick then minimapBtn.customOnClick(minimapBtn) end
end)
local origMinimapSetChecked = minimapBtn.SetChecked
minimapBtn.SetChecked = function(self, checked)
  origMinimapSetChecked(self, checked)
  UpdateMinimapCheckState()
end
minimapBtn:SetScript("OnEnter", function()
  if not minimapBtn:GetChecked() then
    minimapBtn:SetBackdropColor(0.12, 0.12, 0.15, 1)
  end
  minimapBtn:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
end)
minimapBtn:SetScript("OnLeave", function()
  if not minimapBtn:GetChecked() then
    minimapBtn:SetBackdropColor(0.08, 0.08, 0.10, 1)
  end
  minimapBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
end)
minimapBtn.label = profileBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
minimapBtn.label:SetPoint("LEFT", minimapBtn, "RIGHT", 6, 0)
minimapBtn.label:SetText("Minimap Icon")
minimapBtn.label:SetTextColor(0.9, 0.9, 0.9)
addonTable.minimapCB = minimapBtn
addonTable.profileDropdown = profileDropdown
addonTable.profileText = profileText
addonTable.profileList = profileList
addonTable.newProfileBtn = newProfileBtn
addonTable.deleteProfileBtn = deleteProfileBtn
addonTable.exportBtn = expBtn
addonTable.importBtn = impBtn
addonTable.copyProfileBtn = copyProfileBtn
local exportImportPopup = CreateFrame("Frame", "CCMExportImportDialog", UIParent, "BackdropTemplate")
exportImportPopup:SetSize(500, 420)
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
exportImportScrollFrame:SetPoint("TOPLEFT", exportImportPopup, "TOPLEFT", 15, -205)
exportImportScrollFrame:SetSize(420, 130)
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
local generateExportBtn = CreateStyledButton(exportImportPopup, "Generate", 100, 26)
generateExportBtn:SetPoint("BOTTOM", exportImportPopup, "BOTTOM", -55, 15)
local exportImportOkBtn = CreateStyledButton(exportImportPopup, "Import", 100, 26)
exportImportOkBtn:SetPoint("BOTTOM", exportImportPopup, "BOTTOM", -55, 15)
local exportImportCancelBtn = CreateStyledButton(exportImportPopup, "Close", 100, 26)
exportImportCancelBtn:SetPoint("BOTTOM", exportImportPopup, "BOTTOM", 55, 15)
exportImportCancelBtn:SetScript("OnClick", function() exportImportPopup:Hide() end)
addonTable.exportImportPopup = exportImportPopup
addonTable.exportImportTitle = exportImportTitle
addonTable.importExportBox = exportImportEditBox
addonTable.exportImportOkBtn = exportImportOkBtn
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
local tabContainer = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
tabContainer:SetHeight(30)
tabContainer:SetPoint("TOPLEFT", profileBar, "BOTTOMLEFT", 0, -1)
tabContainer:SetPoint("TOPRIGHT", profileBar, "BOTTOMRIGHT", 0, -1)
tabContainer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
tabContainer:SetBackdropColor(0.12, 0.12, 0.14, 1)
local contentContainer = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
contentContainer:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 0, 0)
contentContainer:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -2, 2)
contentContainer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
contentContainer:SetBackdropColor(0.10, 0.10, 0.12, 1)
local tabs, tabFrames, activeTab = {}, {}, nil
local MAX_TABS = 12
local TAB_UF = 11
local TAB_QOL = 12
local function CreateTab(idx, txt, w)
  local t = CreateFrame("Button", nil, tabContainer, "BackdropTemplate")
  t:SetSize(w, 26)
  t:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
  local tx = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tx:SetPoint("CENTER")
  tx:SetText(txt)
  t.text = tx
  local function Upd()
    if activeTab == idx then t:SetBackdropColor(0.10,0.10,0.12,1); tx:SetTextColor(1,0.82,0)
    else t:SetBackdropColor(0.15,0.15,0.18,1); tx:SetTextColor(0.6,0.6,0.6) end
  end
  t:SetScript("OnEnter", function() if activeTab ~= idx then t:SetBackdropColor(0.18,0.18,0.22,1); tx:SetTextColor(0.9,0.9,0.9) end end)
  t:SetScript("OnLeave", Upd)
  t:SetScript("OnClick", function()
    if activeTab ~= idx then
      if activeTab == 2 and addonTable.StopCursorIconPreview then
        addonTable.StopCursorIconPreview()
      end
      if activeTab == 8 and addonTable.StopCastbarPreview then
        addonTable.StopCastbarPreview()
      end
      if activeTab == 9 and addonTable.StopFocusCastbarPreview then
        addonTable.StopFocusCastbarPreview()
      end
      if activeTab == 10 and addonTable.StopDebuffPreview then
        addonTable.StopDebuffPreview()
      end
      if activeTab == 1 and addonTable.StopNoTargetAlertPreview then
        addonTable.StopNoTargetAlertPreview()
      end
      if activeTab == TAB_QOL and addonTable.StopCombatStatusPreview then
        addonTable.StopCombatStatusPreview()
      end
      if activeTab == TAB_QOL and addonTable.StopSkyridingPreview then
        addonTable.StopSkyridingPreview()
      end
      if addonTable.ResetAllPreviewHighlights then
        addonTable.ResetAllPreviewHighlights()
      end
      activeTab = idx
      for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
      if tabFrames[idx] then tabFrames[idx]:Show() end
      Upd()
      if idx == 2 and addonTable.ShowCursorIconPreview then
        addonTable.ShowCursorIconPreview()
      elseif idx == 8 and addonTable.ShowCastbarPreview then
        addonTable.ShowCastbarPreview()
      elseif idx == 9 and addonTable.ShowFocusCastbarPreview then
        addonTable.ShowFocusCastbarPreview()
      elseif idx == 10 and addonTable.ShowDebuffPreview then
        addonTable.ShowDebuffPreview()
      end
    end
    if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
    if addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(idx) end
  end)
  t.Upd = Upd
  return t
end
tabs[1] = CreateTab(1, "General", 60); tabs[1]:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 5, -2)
tabs[2] = CreateTab(2, "Cursor CDM", 75); tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", 2, 0)
tabs[3] = CreateTab(3, "CBar 1", 50); tabs[3]:SetPoint("LEFT", tabs[2], "RIGHT", 2, 0)
tabs[4] = CreateTab(4, "CBar 2", 50); tabs[4]:SetPoint("LEFT", tabs[3], "RIGHT", 2, 0)
tabs[5] = CreateTab(5, "CBar 3", 50); tabs[5]:SetPoint("LEFT", tabs[4], "RIGHT", 2, 0)
tabs[6] = CreateTab(6, "Blizz CDM", 70); tabs[6]:SetPoint("LEFT", tabs[5], "RIGHT", 2, 0)
tabs[7] = CreateTab(7, "PRB", 35); tabs[7]:SetPoint("LEFT", tabs[6], "RIGHT", 2, 0); tabs[7]:Hide()
tabs[8] = CreateTab(8, "Castbar", 55); tabs[8]:SetPoint("LEFT", tabs[7], "RIGHT", 2, 0); tabs[8]:Hide()
tabs[9] = CreateTab(9, "FCastbar", 62); tabs[9]:SetPoint("LEFT", tabs[8], "RIGHT", 2, 0); tabs[9]:Hide()
tabs[10] = CreateTab(10, "Debuffs", 55); tabs[10]:SetPoint("LEFT", tabs[9], "RIGHT", 2, 0); tabs[10]:Hide()
tabs[TAB_UF] = CreateTab(TAB_UF, "UF", 35); tabs[TAB_UF]:SetPoint("LEFT", tabs[10], "RIGHT", 2, 0); tabs[TAB_UF]:Show()
tabs[TAB_QOL] = CreateTab(TAB_QOL, "QOL", 40); tabs[TAB_QOL]:SetPoint("LEFT", tabs[TAB_UF], "RIGHT", 2, 0)
for i=1,MAX_TABS do
  tabFrames[i] = CreateFrame("Frame", nil, contentContainer)
  tabFrames[i]:SetAllPoints()
  tabFrames[i]:Hide()
end
local function UpdateTabVisibility()
  local profile = GetProfile()
  local barsCount = profile and profile.customBarsCount or 0
  local usePRB = profile and profile.usePersonalResourceBar or false
  local useCastbar = profile and profile.useCastbar or false
  local useFocusCastbar = profile and profile.useFocusCastbar or false
  local useDebuffs = profile and profile.enablePlayerDebuffs or false
  local useUF = profile == nil or profile.enableUnitFrameCustomization ~= false
  tabs[3]:SetShown(barsCount >= 1)
  tabs[4]:SetShown(barsCount >= 2)
  tabs[5]:SetShown(barsCount >= 3)
  tabs[7]:SetShown(usePRB)
  tabs[8]:SetShown(useCastbar)
  tabs[9]:SetShown(useFocusCastbar)
  tabs[10]:SetShown(useDebuffs)
  tabs[TAB_UF]:SetShown(useUF)
  local lastTab = tabs[2]
  if barsCount >= 1 then lastTab = tabs[3] end
  if barsCount >= 2 then lastTab = tabs[4] end
  if barsCount >= 3 then lastTab = tabs[5] end
  tabs[6]:ClearAllPoints()
  tabs[6]:SetPoint("LEFT", lastTab, "RIGHT", 2, 0)
  tabs[2]:ClearAllPoints()
  tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", 2, 0)
  tabs[7]:ClearAllPoints()
  tabs[7]:SetPoint("LEFT", tabs[6], "RIGHT", 2, 0)
  tabs[8]:ClearAllPoints()
  tabs[8]:SetPoint("LEFT", tabs[7]:IsShown() and tabs[7] or tabs[6], "RIGHT", 2, 0)
  tabs[9]:ClearAllPoints()
  tabs[9]:SetPoint("LEFT", tabs[8]:IsShown() and tabs[8] or (tabs[7]:IsShown() and tabs[7] or tabs[6]), "RIGHT", 2, 0)
  tabs[10]:ClearAllPoints()
  local debuffAnchor = tabs[9]:IsShown() and tabs[9] or (tabs[8]:IsShown() and tabs[8] or (tabs[7]:IsShown() and tabs[7] or tabs[6]))
  tabs[10]:SetPoint("LEFT", debuffAnchor, "RIGHT", 2, 0)
  tabs[TAB_UF]:ClearAllPoints()
  tabs[TAB_UF]:SetPoint("LEFT", tabs[10]:IsShown() and tabs[10] or debuffAnchor, "RIGHT", 2, 0)
  tabs[TAB_QOL]:ClearAllPoints()
  tabs[TAB_QOL]:SetPoint("LEFT", tabs[TAB_UF]:IsShown() and tabs[TAB_UF] or (tabs[10]:IsShown() and tabs[10] or debuffAnchor), "RIGHT", 2, 0)
  if activeTab and activeTab >= 3 and activeTab <= 5 then
    local tabVisible = (activeTab == 3 and barsCount >= 1) or (activeTab == 4 and barsCount >= 2) or (activeTab == 5 and barsCount >= 3)
    if not tabVisible then
      activeTab = 1
      for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
      tabFrames[1]:Show()
    end
  end
  if activeTab == 7 and not usePRB then
    activeTab = 1
    for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
    tabFrames[1]:Show()
  end
  if activeTab == 8 and not useCastbar then
    activeTab = 1
    for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
    tabFrames[1]:Show()
  end
  if activeTab == 9 and not useFocusCastbar then
    activeTab = 1
    for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
    tabFrames[1]:Show()
  end
  if activeTab == 10 and not useDebuffs then
    activeTab = 1
    for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
    tabFrames[1]:Show()
  end
  if activeTab == TAB_UF and not useUF then
    activeTab = 1
    for i=1,MAX_TABS do if tabFrames[i] then tabFrames[i]:Hide() end; if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
    tabFrames[1]:Show()
  end
end
local function Section(p, txt, y, rightOffset)
  local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  l:SetPoint("TOPLEFT", p, "TOPLEFT", 15, y)
  l:SetText(txt)
  l:SetTextColor(1, 0.82, 0)
  local ln = p:CreateTexture(nil, "ARTWORK")
  ln:SetHeight(1)
  ln:SetPoint("LEFT", l, "RIGHT", 8, 0)
  ln:SetPoint("RIGHT", p, "RIGHT", rightOffset or -15, 0)
  ln:SetColorTexture(0.3, 0.3, 0.35, 1)
  return l
end
local function Slider(p, txt, x, y, mn, mx, df, st)
  local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  l:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
  l:SetText(txt)
  l:SetTextColor(0.9, 0.9, 0.9)
  local s = CreateFrame("Slider", nil, p, "BackdropTemplate")
  s:SetPoint("TOPLEFT", l, "BOTTOMLEFT", 0, -8)
  s:SetSize(180, 16)
  s:SetOrientation("HORIZONTAL")
  s:SetMinMaxValues(mn, mx)
  s:SetValue(df)
  s:SetValueStep(st)
  s:SetObeyStepOnDrag(true)
  s:EnableMouse(true)
  s:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  s:SetBackdropColor(0.08, 0.08, 0.10, 1)
  s:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  local thumb = s:CreateTexture(nil, "ARTWORK")
  thumb:SetSize(14, 18)
  thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
  s:SetThumbTexture(thumb)
  local lowText = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lowText:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -2)
  lowText:SetText(mn)
  lowText:SetTextColor(0.5, 0.5, 0.5)
  s.Low = lowText
  local highText = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  highText:SetPoint("TOPRIGHT", s, "BOTTOMRIGHT", 0, -2)
  highText:SetText(mx)
  highText:SetTextColor(0.5, 0.5, 0.5)
  s.High = highText
  s.Text = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  s.Text:SetText("")
  local vtBg = CreateFrame("Frame", nil, p, "BackdropTemplate")
  vtBg:SetSize(50, 20)
  vtBg:SetPoint("LEFT", s, "RIGHT", 8, 0)
  vtBg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  vtBg:SetBackdropColor(0.05, 0.05, 0.07, 1)
  vtBg:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  local vt = CreateFrame("EditBox", nil, vtBg)
  vt:SetSize(46, 18)
  vt:SetPoint("CENTER", vtBg, "CENTER", 0, 0)
  vt:SetFontObject("GameFontHighlightSmall")
  vt:SetJustifyH("CENTER")
  vt:SetAutoFocus(false)
  vt:SetText(df)
  vt:SetTextColor(1, 1, 1)
  s.valueText = vt
  s.valueTextBg = vtBg
  s.step = st
  s.minVal = mn
  s.maxVal = mx
  s._updating = false
  local function ApplyEditBoxValue()
    if s._updating then return end
    local text = vt:GetText()
    local num = tonumber(text)
    if num then
      local step = s.step or 1
      num = math.floor(num / step + 0.5) * step
      if num < s.minVal then num = s.minVal end
      if num > s.maxVal then num = s.maxVal end
      s._updating = true
      s:SetValue(num)
      s._updating = false
      if step < 1 then
        vt:SetText(string.format("%.2f", num))
      else
        vt:SetText(math.floor(num))
      end
    else
      local cur = s:GetValue()
      local step = s.step or 1
      if step < 1 then
        vt:SetText(string.format("%.2f", cur))
      else
        vt:SetText(math.floor(cur))
      end
    end
    vt:ClearFocus()
  end
  vt:SetScript("OnEnterPressed", ApplyEditBoxValue)
  vt:SetScript("OnEscapePressed", function()
    local cur = s:GetValue()
    local step = s.step or 1
    if step < 1 then
      vt:SetText(string.format("%.2f", cur))
    else
      vt:SetText(math.floor(cur))
    end
    vt:ClearFocus()
  end)
  vt:SetScript("OnEditFocusLost", ApplyEditBoxValue)
  s:SetScript("OnValueChanged", function(self, value)
    if self._updating then return end
    local step = self.step or 1
    local rounded = math.floor(value / step + 0.5) * step
    if math.abs(value - rounded) > 0.001 then
      self._updating = true
      self:SetValue(rounded)
      self._updating = false
      return
    end
    if not self.valueText:HasFocus() then
      if step < 1 then
        self.valueText:SetText(string.format("%.2f", rounded))
      else
        self.valueText:SetText(math.floor(rounded))
      end
    end
  end)
  s:SetScript("OnEnter", function() thumb:SetColorTexture(0.5, 0.5, 0.55, 1) end)
  s:SetScript("OnLeave", function() thumb:SetColorTexture(0.4, 0.4, 0.45, 1) end)
  s:EnableMouseWheel(false)
  s:SetScript("OnMouseWheel", nil)
  local upBtn = CreateFrame("Button", nil, vtBg)
  upBtn:SetSize(16, 10)
  upBtn:SetPoint("BOTTOMLEFT", vtBg, "BOTTOMRIGHT", 2, 10)
  local upTex = upBtn:CreateTexture(nil, "ARTWORK")
  upTex:SetAllPoints()
  upTex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_up.tga")
  upBtn:SetScript("OnClick", function()
    local step = s.step or 1
    local minVal, maxVal = s:GetMinMaxValues()
    local currentVal = s:GetValue()
    local newVal = currentVal + step
    if newVal > maxVal then newVal = maxVal end
    s:SetValue(newVal)
  end)
  upBtn:SetScript("OnEnter", function() upTex:SetVertexColor(1, 0.82, 0, 1) end)
  upBtn:SetScript("OnLeave", function() upTex:SetVertexColor(1, 1, 1, 1) end)
  local downBtn = CreateFrame("Button", nil, vtBg)
  downBtn:SetSize(16, 10)
  downBtn:SetPoint("TOPLEFT", vtBg, "TOPRIGHT", 2, -10)
  local downTex = downBtn:CreateTexture(nil, "ARTWORK")
  downTex:SetAllPoints()
  downTex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down.tga")
  downBtn:SetScript("OnClick", function()
    local step = s.step or 1
    local minVal, maxVal = s:GetMinMaxValues()
    local currentVal = s:GetValue()
    local newVal = currentVal - step
    if newVal < minVal then newVal = minVal end
    s:SetValue(newVal)
  end)
  downBtn:SetScript("OnEnter", function() downTex:SetVertexColor(1, 0.82, 0, 1) end)
  downBtn:SetScript("OnLeave", function() downTex:SetVertexColor(1, 1, 1, 1) end)
  s.upBtn = upBtn
  s.downBtn = downBtn
  s.label = l
  s.SetEnabled = function(self, enabled)
    if enabled then
      self:Enable()
      l:SetTextColor(0.9, 0.9, 0.9)
      self:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
      thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
      vt:SetTextColor(1, 1, 1)
      vt:EnableMouse(true)
      upBtn:Enable()
      downBtn:Enable()
    else
      self:Disable()
      l:SetTextColor(0.4, 0.4, 0.4)
      self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
      thumb:SetColorTexture(0.25, 0.25, 0.28, 1)
      vt:SetTextColor(0.4, 0.4, 0.4)
      vt:EnableMouse(false)
      upBtn:Disable()
      downBtn:Disable()
    end
  end
  return s
end
local function Checkbox(p, txt, x, y)
  local cb = CreateFrame("CheckButton", nil, p, "BackdropTemplate")
  cb:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
  cb:SetSize(20, 20)
  cb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cb:SetBackdropColor(0.08, 0.08, 0.10, 1)
  cb:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local check = cb:CreateTexture(nil, "ARTWORK")
  check:SetSize(12, 12)
  check:SetPoint("CENTER")
  check:SetColorTexture(1, 0.82, 0, 1)
  check:Hide()
  cb.check = check
  cb:SetChecked(false)
  local function UpdateCheckState()
    if cb:GetChecked() then
      check:Show()
      cb:SetBackdropColor(0.15, 0.15, 0.18, 1)
    else
      check:Hide()
      cb:SetBackdropColor(0.08, 0.08, 0.10, 1)
    end
  end
  cb:SetScript("OnClick", function()
    UpdateCheckState()
    if cb.customOnClick then cb.customOnClick(cb) end
  end)
  local origSetChecked = cb.SetChecked
  cb.SetChecked = function(self, checked)
    origSetChecked(self, checked)
    UpdateCheckState()
  end
  cb:SetScript("OnEnter", function()
    if not cb:GetChecked() then
      cb:SetBackdropColor(0.12, 0.12, 0.15, 1)
    end
    cb:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
  end)
  cb:SetScript("OnLeave", function()
    if not cb:GetChecked() then
      cb:SetBackdropColor(0.08, 0.08, 0.10, 1)
    end
    cb:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  end)
  local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  l:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  l:SetText(txt)
  l:SetTextColor(0.9, 0.9, 0.9)
  cb.label = l
  cb.SetEnabled = function(self, enabled)
    if enabled then
      self:Enable()
      l:SetTextColor(0.9, 0.9, 0.9)
      self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    else
      self:Disable()
      l:SetTextColor(0.4, 0.4, 0.4)
      self:SetBackdropBorderColor(0.2, 0.2, 0.22, 1)
      self:SetBackdropColor(0.05, 0.05, 0.06, 1)
    end
  end
  return cb, l
end
local function StyledDropdown(p, labelTxt, x, y, w)
  local lbl = nil
  local dd = CreateFrame("Frame", nil, p, "BackdropTemplate")
  dd:SetSize(w, 24)
  if labelTxt then
    lbl = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    lbl:SetText(labelTxt)
    lbl:SetTextColor(0.9, 0.9, 0.9)
    dd:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -4)
  else
    dd:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
  end
  dd:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  dd:SetBackdropColor(0.12, 0.12, 0.14, 1)
  dd:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local txt = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  txt:SetPoint("LEFT", dd, "LEFT", 8, 0)
  txt:SetPoint("RIGHT", dd, "RIGHT", -20, 0)
  txt:SetJustifyH("LEFT")
  txt:SetTextColor(0.9, 0.9, 0.9)
  dd.text = txt
  local arrow = dd:CreateTexture(nil, "ARTWORK")
  arrow:SetSize(10, 10)
  arrow:SetPoint("RIGHT", dd, "RIGHT", -8, 0)
  arrow:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down")
  arrow:SetVertexColor(0.6, 0.6, 0.6)
  local list = CreateFrame("Frame", nil, dd, "BackdropTemplate")
  list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  list:SetWidth(w)
  list:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  list:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
  list:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  list:SetFrameStrata("TOOLTIP")
  list:SetFrameLevel(math.max((dd:GetFrameLevel() or 1) + 200, 2000))
  list:Hide()
  dd.list = list
  dd.options = {}
  dd.value = nil
  dd._scrollOffset = 0
  dd._maxVisibleOptions = 12
  dd._buttons = {}
  dd._moreIndicator = nil
  list:EnableMouseWheel(true)
  local RenderDropdownOptions
  local function ScrollDropdownBy(delta)
    local total = #(dd.options or {})
    local maxVisible = dd._maxVisibleOptions or 12
    local maxOffset = math.max(0, total - maxVisible)
    local curOffset = dd._scrollOffset or 0
    local nextOffset = curOffset - (delta or 0)
    if nextOffset < 0 then nextOffset = 0 end
    if nextOffset > maxOffset then nextOffset = maxOffset end
    if nextOffset ~= curOffset then
      dd._scrollOffset = nextOffset
      RenderDropdownOptions()
    end
  end
  RenderDropdownOptions = function()
    local opts = dd.options or {}
    local total = #opts
    local maxVisible = dd._maxVisibleOptions or 12
    local offset = dd._scrollOffset or 0
    local maxOffset = math.max(0, total - maxVisible)
    if offset > maxOffset then
      offset = maxOffset
      dd._scrollOffset = offset
    end
    if offset < 0 then
      offset = 0
      dd._scrollOffset = 0
    end
    local hasMoreBelow = offset < maxOffset
    local optionSlots = maxVisible
    if hasMoreBelow and optionSlots > 0 then
      optionSlots = optionSlots - 1
    end
    local visibleCount = math.min(optionSlots, total - offset)
    if visibleCount < 0 then visibleCount = 0 end
    local buttonWidth = w - 2
    for i = 1, maxVisible do
      local btn = dd._buttons[i]
      if not btn then
        btn = CreateFrame("Button", nil, list, "BackdropTemplate")
        btn:SetSize(buttonWidth, 22)
        btn:SetPoint("TOPLEFT", list, "TOPLEFT", 1, -((i - 1) * 22) - 1)
        btn:SetFrameStrata(list:GetFrameStrata())
        btn:SetFrameLevel(list:GetFrameLevel() + 1)
        btn:EnableMouseWheel(true)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        btn:SetScript("OnMouseWheel", function(_, delta)
          ScrollDropdownBy(delta)
        end)
        dd._buttons[i] = btn
      end
      local optIndex = offset + i
      local opt = (i <= visibleCount) and opts[optIndex] or nil
      if opt then
        btn.optValue = opt.value
        btn.text:SetText(opt.text)
        if opt.disabled then
          btn.text:SetTextColor(0.4, 0.4, 0.4)
          btn:SetScript("OnEnter", nil)
          btn:SetScript("OnLeave", nil)
          btn:SetScript("OnClick", function() end)
        else
          btn.text:SetTextColor(0.9, 0.9, 0.9)
          btn:SetScript("OnEnter", function(self)
            self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            self:SetBackdropColor(0.25, 0.25, 0.3, 1)
          end)
          btn:SetScript("OnLeave", function(self)
            self:SetBackdrop(nil)
          end)
          btn:SetScript("OnClick", function()
            dd.value = opt.value
            txt:SetText(opt.text)
            list:Hide()
            if dd.onSelect then dd.onSelect(opt.value) end
          end)
        end
        btn:Show()
      else
        btn:Hide()
      end
    end
    if not dd._moreIndicator then
      local hint = CreateFrame("Button", nil, list, "BackdropTemplate")
      hint:SetSize(buttonWidth, 22)
      hint:SetFrameStrata(list:GetFrameStrata())
      hint:SetFrameLevel(list:GetFrameLevel() + 1)
      hint:EnableMouseWheel(true)
      hint.tex = hint:CreateTexture(nil, "ARTWORK")
      hint.tex:SetSize(12, 12)
      hint.tex:SetPoint("CENTER", hint, "CENTER", 0, 0)
      hint.tex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down.tga")
      hint.tex:SetVertexColor(0.95, 0.95, 0.95, 0.95)
      hint:SetScript("OnEnter", function(self)
        self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        self:SetBackdropColor(0.22, 0.22, 0.27, 0.9)
        if self.tex then self.tex:SetVertexColor(1, 0.82, 0, 1) end
      end)
      hint:SetScript("OnLeave", function(self)
        self:SetBackdrop(nil)
        if self.tex then self.tex:SetVertexColor(0.95, 0.95, 0.95, 0.95) end
      end)
      hint:SetScript("OnClick", function()
        local nextOffset = (dd._scrollOffset or 0) + 1
        local maxOff = math.max(0, #(dd.options or {}) - (dd._maxVisibleOptions or 12))
        if nextOffset > maxOff then nextOffset = maxOff end
        if nextOffset ~= dd._scrollOffset then
          dd._scrollOffset = nextOffset
          RenderDropdownOptions()
        end
      end)
      hint:SetScript("OnMouseWheel", function(_, delta)
        ScrollDropdownBy(delta)
      end)
      dd._moreIndicator = hint
    end
    local listRows = visibleCount
    if hasMoreBelow and dd._moreIndicator then
      dd._moreIndicator:ClearAllPoints()
      dd._moreIndicator:SetPoint("TOPLEFT", list, "TOPLEFT", 1, -((visibleCount) * 22) - 1)
      dd._moreIndicator:Show()
      listRows = listRows + 1
    elseif dd._moreIndicator then
      dd._moreIndicator:Hide()
    end
    list:SetHeight((listRows * 22) + 2)
  end
  dd.RenderOptions = RenderDropdownOptions
  list:SetScript("OnMouseWheel", function(_, delta)
    ScrollDropdownBy(delta)
  end)
  function dd:SetOptions(opts)
    dd.options = opts or {}
    dd._scrollOffset = 0
    RenderDropdownOptions()
    if dd.value ~= nil then
      dd:SetValue(dd.value)
    end
  end
  function dd:SetValue(val)
    dd.value = val
    for _, opt in ipairs(dd.options) do
      if opt.value == val then txt:SetText(opt.text); return end
    end
    txt:SetText(val or "")
  end
  function dd:SetEnabled(enabled)
    if enabled then
      dd:EnableMouse(true)
      dd:SetAlpha(1)
      if lbl then lbl:SetTextColor(0.9, 0.9, 0.9) end
    else
      dd:EnableMouse(false)
      dd:SetAlpha(0.5)
      if lbl then lbl:SetTextColor(0.4, 0.4, 0.4) end
    end
  end
  dd:SetScript("OnMouseDown", function()
    if list:IsShown() then
      list:Hide()
    else
      if dd.refreshOptions then
        pcall(dd.refreshOptions, dd)
      end
      dd._scrollOffset = 0
      RenderDropdownOptions()
      list:SetFrameLevel(math.max((dd:GetFrameLevel() or 1) + 200, 2000))
      list:Show()
    end
  end)
  dd:SetScript("OnEnter", function() dd:SetBackdropColor(0.18, 0.18, 0.22, 1) end)
  dd:SetScript("OnLeave", function() dd:SetBackdropColor(0.12, 0.12, 0.14, 1) end)
  return dd, lbl
end
addonTable.ConfigFrame = cfg
addonTable.tabFrames = tabFrames
addonTable.tabs = tabs
addonTable.MAX_TABS = MAX_TABS
addonTable.TAB_UF = TAB_UF
addonTable.TAB_QOL = TAB_QOL
addonTable.activeTab = function() return activeTab end
addonTable.setActiveTab = function(idx) activeTab = idx end
addonTable.UpdateTabVisibility = UpdateTabVisibility
addonTable.SwitchToTab = function(idx)
  if not cfg:IsShown() then return end
  if idx < 1 or idx > MAX_TABS then return end
  if tabs[idx] and not tabs[idx]:IsShown() then return end
  activeTab = idx
  for i=1,MAX_TABS do
    if tabFrames[i] then tabFrames[i]:Hide() end
    if tabs[i] and tabs[i].Upd then tabs[i].Upd() end
  end
  if tabFrames[idx] then tabFrames[idx]:Show() end
  if addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(idx) end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateBLCRTimer then addonTable.UpdateBLCRTimer() end
end
addonTable.Section = Section
addonTable.Slider = Slider
addonTable.Checkbox = Checkbox
addonTable.StyledDropdown = StyledDropdown
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
for i=1,MAX_TABS do if tabs[i] and tabs[i].Upd then tabs[i].Upd() end end
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
    if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
    if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
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
      if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
      if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
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
  if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
  if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
  if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
end
