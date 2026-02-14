--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_prb.lua
-- Personal resource bar customization and updates
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, addonTable = ...
local State = addonTable.State
local GetClassColor = addonTable.GetClassColor
local GetGlobalFont = addonTable.GetGlobalFont
local FitTextToBar = addonTable.FitTextToBar
local IsRealNumber = addonTable.IsRealNumber
local GetClassPowerConfig = addonTable.GetClassPowerConfig
local IsClassPowerRedundant = addonTable.IsClassPowerRedundant
local SetBlizzardPlayerPowerBarsVisibility = addonTable.SetBlizzardPlayerPowerBarsVisibility
local PRB_OVERLAY_TEX_NORM = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\normTex.tga"
local PRB_OVERLAY_TEX_STRIPE_PRB = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\stripe_overlay"
local function SafeNum(v)
  if type(v) ~= "number" then return nil end
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end
local function HasPositiveValue(v)
  if v == nil then return false end
  if issecretvalue and issecretvalue(v) then return true end
  return type(v) == "number" and v > 0
end
local function GetPRBAbsorbTexturePath(profile)
  return PRB_OVERLAY_TEX_NORM
end
local function GetPRBStripeOverlayPath()
  return PRB_OVERLAY_TEX_STRIPE_PRB
end
local function SetStatusBarValuePixelPerfect(statusBar, value)
  if not statusBar then return end
  if PixelUtil and PixelUtil.SetStatusBarValue then
    PixelUtil.SetStatusBarValue(statusBar, value or 0)
  else
    statusBar:SetValue(value or 0)
  end
end
local function ApplyConsistentFontShadow(fontString, outlineFlag)
  if not fontString then return end
  local hasOutline = type(outlineFlag) == "string" and outlineFlag ~= ""
  if fontString.SetShadowOffset then
    if hasOutline then
      pcall(fontString.SetShadowOffset, fontString, 1, -1)
    else
      pcall(fontString.SetShadowOffset, fontString, 0, 0)
    end
  end
  if fontString.SetShadowColor then
    if hasOutline then
      pcall(fontString.SetShadowColor, fontString, 0, 0, 0, 1)
    else
      pcall(fontString.SetShadowColor, fontString, 0, 0, 0, 0)
    end
  end
end
local TEXTURE_PATHS = {
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
local PRB_LowHealthAlphaCurve
local PRB_LowHealthAlphaCurveKey = ""
local PRB_LowHealthThreshold = 50
local function RebuildLowHealthAlphaCurve(thresholdPct)
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return end
  local t = (thresholdPct or 50) / 100
  if t < 0.10 then t = 0.10 end
  if t > 0.80 then t = 0.80 end
  local key = string.format("%.2f", t)
  if PRB_LowHealthAlphaCurveKey == key then return end
  PRB_LowHealthAlphaCurveKey = key
  PRB_LowHealthAlphaCurve = C_CurveUtil.CreateCurve()
  PRB_LowHealthAlphaCurve:SetType(Enum.LuaCurveType.Step)
  PRB_LowHealthAlphaCurve:AddPoint(0.0, 1.0)
  PRB_LowHealthAlphaCurve:AddPoint(t, 0.0)
  PRB_LowHealthAlphaCurve:AddPoint(1.0, 0.0)
end
local function RebuildLowHealthCurve(thresholdPct)
  PRB_LowHealthThreshold = thresholdPct or 50
  PRB_LowHealthAlphaCurveKey = ""
  RebuildLowHealthAlphaCurve(thresholdPct)
end
addonTable.RebuildLowHealthCurve = RebuildLowHealthCurve
RebuildLowHealthCurve(50)

local PRB_LowPowerAlphaCurve
local PRB_LowPowerAlphaCurveKey = ""
local PRB_LowPowerThreshold = 30
local function RebuildLowPowerAlphaCurve(thresholdPct)
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return end
  local t = (thresholdPct or 30) / 100
  if t < 0.10 then t = 0.10 end
  if t > 0.80 then t = 0.80 end
  local key = string.format("%.2f", t)
  if PRB_LowPowerAlphaCurveKey == key then return end
  PRB_LowPowerAlphaCurveKey = key
  PRB_LowPowerAlphaCurve = C_CurveUtil.CreateCurve()
  PRB_LowPowerAlphaCurve:SetType(Enum.LuaCurveType.Step)
  PRB_LowPowerAlphaCurve:AddPoint(0.0, 1.0)
  PRB_LowPowerAlphaCurve:AddPoint(t, 0.0)
  PRB_LowPowerAlphaCurve:AddPoint(1.0, 0.0)
end
local function RebuildLowPowerCurve(thresholdPct)
  PRB_LowPowerThreshold = thresholdPct or 30
  PRB_LowPowerAlphaCurveKey = ""
  RebuildLowPowerAlphaCurve(thresholdPct)
end
addonTable.RebuildLowPowerCurve = RebuildLowPowerCurve
RebuildLowPowerCurve(30)
local prbBarOrder = {}
local prbBarEntries = {
  {type = "health", order = 1},
  {type = "power", order = 2},
  {type = "mana", order = 3},
  {type = "classpower", order = 4},
}
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
if prbFrame.healthBar.SetClipsChildren then prbFrame.healthBar:SetClipsChildren(true) end
prbFrame.healthBar.lowHealthOverlay = CreateFrame("StatusBar", nil, prbFrame.healthBar)
prbFrame.healthBar.lowHealthOverlay:SetAllPoints(prbFrame.healthBar)
prbFrame.healthBar.lowHealthOverlay:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.healthBar.lowHealthOverlay:SetStatusBarColor(1, 0, 0)
prbFrame.healthBar.lowHealthOverlay:SetFrameLevel(prbFrame.healthBar:GetFrameLevel() + 1)
prbFrame.healthBar.lowHealthOverlay:SetAlpha(0)
prbFrame.healthBar.lowHealthOverlay:Hide()
if prbFrame.healthBar.lowHealthOverlay.SetClipsChildren then prbFrame.healthBar.lowHealthOverlay:SetClipsChildren(true) end
prbFrame.healthBar.bg = prbFrame.healthBar:CreateTexture(nil, "BACKGROUND")
prbFrame.healthBar.bg:SetAllPoints()
prbFrame.healthBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
prbFrame.healthBar.border = CreateFrame("Frame", nil, prbFrame, "BackdropTemplate")
prbFrame.healthBar.border:SetFrameLevel(prbFrame.healthBar:GetFrameLevel() + 5)
prbFrame.healthBar.border:SetPoint("TOPLEFT", prbFrame.healthBar, "TOPLEFT", 0, 0)
prbFrame.healthBar.border:SetPoint("BOTTOMRIGHT", prbFrame.healthBar, "BOTTOMRIGHT", 0, 0)
prbFrame.healthBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
prbFrame.healthBar.border:SetBackdropBorderColor(0, 0, 0, 1)
prbFrame.healthBar.text = prbFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
prbFrame.healthBar.text:SetPoint("CENTER")
prbFrame.healthBar.text:SetTextColor(1, 1, 1)
prbFrame.healthBar.dmgAbsorbFrame = CreateFrame("StatusBar", nil, prbFrame.healthBar)
prbFrame.healthBar.dmgAbsorbFrame:SetStatusBarTexture(PRB_OVERLAY_TEX_NORM)
prbFrame.healthBar.dmgAbsorbFrame:SetMinMaxValues(0, 1)
prbFrame.healthBar.dmgAbsorbFrame:SetValue(0)
if prbFrame.healthBar.dmgAbsorbFrame.SetClipsChildren then prbFrame.healthBar.dmgAbsorbFrame:SetClipsChildren(true) end
if prbFrame.healthBar.dmgAbsorbFrame.SetReverseFill then prbFrame.healthBar.dmgAbsorbFrame:SetReverseFill(false) end
prbFrame.healthBar.dmgAbsorbTex = prbFrame.healthBar.dmgAbsorbFrame:GetStatusBarTexture()
if prbFrame.healthBar.dmgAbsorbTex then
  prbFrame.healthBar.dmgAbsorbTex:SetTexture(PRB_OVERLAY_TEX_NORM)
  prbFrame.healthBar.dmgAbsorbTex:SetVertexColor(0.65, 0.85, 1.00, 0.90)
  if prbFrame.healthBar.dmgAbsorbTex.SetBlendMode then prbFrame.healthBar.dmgAbsorbTex:SetBlendMode("ADD") end
end
prbFrame.healthBar.dmgAbsorbStripe = prbFrame.healthBar.dmgAbsorbFrame:CreateTexture(nil, "OVERLAY", nil, 1)
prbFrame.healthBar.dmgAbsorbStripe:SetTexture(PRB_OVERLAY_TEX_STRIPE_PRB, "REPEAT", "REPEAT")
if prbFrame.healthBar.dmgAbsorbTex then
  prbFrame.healthBar.dmgAbsorbStripe:SetAllPoints(prbFrame.healthBar.dmgAbsorbTex)
else
  prbFrame.healthBar.dmgAbsorbStripe:SetAllPoints(prbFrame.healthBar.dmgAbsorbFrame)
end
prbFrame.healthBar.dmgAbsorbStripe:SetVertexColor(1, 1, 1, 0.38)
if prbFrame.healthBar.dmgAbsorbStripe.SetHorizTile then prbFrame.healthBar.dmgAbsorbStripe:SetHorizTile(true) end
if prbFrame.healthBar.dmgAbsorbStripe.SetVertTile then prbFrame.healthBar.dmgAbsorbStripe:SetVertTile(true) end
prbFrame.healthBar.dmgAbsorbStripe:Hide()
prbFrame.healthBar.dmgAbsorbFrame:Hide()
prbFrame.healthBar.fullDmgAbsorbFrame = CreateFrame("StatusBar", nil, prbFrame.healthBar)
prbFrame.healthBar.fullDmgAbsorbFrame:SetStatusBarTexture(PRB_OVERLAY_TEX_NORM)
prbFrame.healthBar.fullDmgAbsorbFrame:SetMinMaxValues(0, 1)
prbFrame.healthBar.fullDmgAbsorbFrame:SetValue(0)
if prbFrame.healthBar.fullDmgAbsorbFrame.SetClipsChildren then prbFrame.healthBar.fullDmgAbsorbFrame:SetClipsChildren(true) end
if prbFrame.healthBar.fullDmgAbsorbFrame.SetReverseFill then prbFrame.healthBar.fullDmgAbsorbFrame:SetReverseFill(false) end
prbFrame.healthBar.fullDmgAbsorbTex = prbFrame.healthBar.fullDmgAbsorbFrame:GetStatusBarTexture()
if prbFrame.healthBar.fullDmgAbsorbTex then
  prbFrame.healthBar.fullDmgAbsorbTex:SetTexture(PRB_OVERLAY_TEX_NORM)
  prbFrame.healthBar.fullDmgAbsorbTex:SetVertexColor(0.70, 0.90, 1.00, 1.00)
  if prbFrame.healthBar.fullDmgAbsorbTex.SetBlendMode then prbFrame.healthBar.fullDmgAbsorbTex:SetBlendMode("ADD") end
end
prbFrame.healthBar.fullDmgAbsorbFrame:Hide()
prbFrame.healthBar.dmgAbsorbGlow = prbFrame.healthBar:CreateTexture(nil, "OVERLAY")
prbFrame.healthBar.dmgAbsorbGlow:SetTexture(PRB_OVERLAY_TEX_NORM)
prbFrame.healthBar.dmgAbsorbGlow:SetVertexColor(0.70, 0.90, 1.00, 1.00)
if prbFrame.healthBar.dmgAbsorbGlow.SetBlendMode then prbFrame.healthBar.dmgAbsorbGlow:SetBlendMode("ADD") end
prbFrame.healthBar.dmgAbsorbGlow:Hide()
prbFrame.healthBar.myHealPredFrame = CreateFrame("StatusBar", nil, prbFrame.healthBar)
prbFrame.healthBar.myHealPredFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.healthBar.myHealPredFrame:SetMinMaxValues(0, 1)
prbFrame.healthBar.myHealPredFrame:SetValue(0)
if prbFrame.healthBar.myHealPredFrame.SetClipsChildren then prbFrame.healthBar.myHealPredFrame:SetClipsChildren(true) end
prbFrame.healthBar.myHealPredTex = prbFrame.healthBar.myHealPredFrame:GetStatusBarTexture()
if prbFrame.healthBar.myHealPredTex then prbFrame.healthBar.myHealPredTex:SetVertexColor(0, 0.827, 0, 0.4) end
prbFrame.healthBar.myHealPredFrame:Hide()
prbFrame.healthBar.otherHealPredFrame = CreateFrame("StatusBar", nil, prbFrame.healthBar)
prbFrame.healthBar.otherHealPredFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.healthBar.otherHealPredFrame:SetMinMaxValues(0, 1)
prbFrame.healthBar.otherHealPredFrame:SetValue(0)
if prbFrame.healthBar.otherHealPredFrame.SetClipsChildren then prbFrame.healthBar.otherHealPredFrame:SetClipsChildren(true) end
prbFrame.healthBar.otherHealPredTex = prbFrame.healthBar.otherHealPredFrame:GetStatusBarTexture()
if prbFrame.healthBar.otherHealPredTex then prbFrame.healthBar.otherHealPredTex:SetVertexColor(0, 0.631, 0.557, 0.4) end
prbFrame.healthBar.otherHealPredFrame:Hide()
prbFrame.healthBar.healAbsorbFrame = CreateFrame("StatusBar", nil, prbFrame.healthBar)
prbFrame.healthBar.healAbsorbFrame:SetStatusBarTexture(PRB_OVERLAY_TEX_NORM)
prbFrame.healthBar.healAbsorbFrame:SetMinMaxValues(0, 1)
prbFrame.healthBar.healAbsorbFrame:SetValue(0)
if prbFrame.healthBar.healAbsorbFrame.SetClipsChildren then prbFrame.healthBar.healAbsorbFrame:SetClipsChildren(true) end
if prbFrame.healthBar.healAbsorbFrame.SetReverseFill then prbFrame.healthBar.healAbsorbFrame:SetReverseFill(true) end
prbFrame.healthBar.healAbsorbTex = prbFrame.healthBar.healAbsorbFrame:GetStatusBarTexture()
if prbFrame.healthBar.healAbsorbTex then
  prbFrame.healthBar.healAbsorbTex:SetTexture(PRB_OVERLAY_TEX_NORM)
  prbFrame.healthBar.healAbsorbTex:SetVertexColor(1.0, 0.0, 0.0, 1.0)
  if prbFrame.healthBar.healAbsorbTex.SetBlendMode then prbFrame.healthBar.healAbsorbTex:SetBlendMode("ADD") end
end
prbFrame.healthBar.healAbsorbStripe = prbFrame.healthBar.healAbsorbFrame:CreateTexture(nil, "OVERLAY", nil, 1)
prbFrame.healthBar.healAbsorbStripe:SetTexture(PRB_OVERLAY_TEX_STRIPE_PRB, "REPEAT", "REPEAT")
if prbFrame.healthBar.healAbsorbTex then
  prbFrame.healthBar.healAbsorbStripe:SetAllPoints(prbFrame.healthBar.healAbsorbTex)
else
  prbFrame.healthBar.healAbsorbStripe:SetAllPoints(prbFrame.healthBar.healAbsorbFrame)
end
prbFrame.healthBar.healAbsorbStripe:SetVertexColor(1, 1, 1, 0.38)
if prbFrame.healthBar.healAbsorbStripe.SetHorizTile then prbFrame.healthBar.healAbsorbStripe:SetHorizTile(true) end
if prbFrame.healthBar.healAbsorbStripe.SetVertTile then prbFrame.healthBar.healAbsorbStripe:SetVertTile(true) end
prbFrame.healthBar.healAbsorbStripe:Hide()
prbFrame.healthBar.healAbsorbFrame:Hide()
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
prbFrame.powerBar.lowPowerOverlay = CreateFrame("StatusBar", nil, prbFrame.powerBar)
prbFrame.powerBar.lowPowerOverlay:SetAllPoints(prbFrame.powerBar)
prbFrame.powerBar.lowPowerOverlay:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
prbFrame.powerBar.lowPowerOverlay:SetStatusBarColor(1, 0.5, 0)
prbFrame.powerBar.lowPowerOverlay:SetFrameLevel(prbFrame.powerBar:GetFrameLevel() + 1)
prbFrame.powerBar.lowPowerOverlay:SetAlpha(0)
prbFrame.powerBar.lowPowerOverlay:Hide()
if prbFrame.powerBar.lowPowerOverlay.SetClipsChildren then prbFrame.powerBar.lowPowerOverlay:SetClipsChildren(true) end
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
  local selfScale = self:GetEffectiveScale()
  local uiScale = UIParent:GetEffectiveScale()
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor((frameX * selfScale - centerX * uiScale) / selfScale + 0.5)
  local newY = math.floor((frameY * selfScale - centerY * uiScale) / selfScale + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.prbX = newX
    profile.prbY = newY
    if addonTable.UpdatePRBSliders then addonTable.UpdatePRBSliders(newX, newY) end
  end
  State.prbDragging = false
  self:ClearAllPoints()
  self:SetPoint("CENTER", UIParent, "CENTER", newX, newY)
end)
prbFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.prbDragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(7) end
    end
  end
end)
local function HidePRBHealthOverlays()
  if prbFrame.healthBar.dmgAbsorbFrame then prbFrame.healthBar.dmgAbsorbFrame:Hide() end
  if prbFrame.healthBar.fullDmgAbsorbFrame then prbFrame.healthBar.fullDmgAbsorbFrame:Hide() end
  if prbFrame.healthBar.dmgAbsorbGlow then prbFrame.healthBar.dmgAbsorbGlow:Hide() end
  if prbFrame.healthBar.dmgAbsorbStripe then prbFrame.healthBar.dmgAbsorbStripe:Hide() end
  if prbFrame.healthBar.myHealPredFrame then prbFrame.healthBar.myHealPredFrame:Hide() end
  if prbFrame.healthBar.otherHealPredFrame then prbFrame.healthBar.otherHealPredFrame:Hide() end
  if prbFrame.healthBar.healAbsorbFrame then prbFrame.healthBar.healAbsorbFrame:Hide() end
  if prbFrame.healthBar.healAbsorbStripe then prbFrame.healthBar.healAbsorbStripe:Hide() end
end
local function UpdatePRBHealthOverlays(width, height)
  local hb = prbFrame.healthBar
  if not hb or not hb:IsShown() then HidePRBHealthOverlays(); return end
  if hb.SetClipsChildren then hb:SetClipsChildren(true) end
  if hb.dmgAbsorbFrame and hb.dmgAbsorbFrame.SetClipsChildren then hb.dmgAbsorbFrame:SetClipsChildren(true) end
  if hb.fullDmgAbsorbFrame and hb.fullDmgAbsorbFrame.SetClipsChildren then hb.fullDmgAbsorbFrame:SetClipsChildren(true) end
  if hb.myHealPredFrame and hb.myHealPredFrame.SetClipsChildren then hb.myHealPredFrame:SetClipsChildren(true) end
  if hb.otherHealPredFrame and hb.otherHealPredFrame.SetClipsChildren then hb.otherHealPredFrame:SetClipsChildren(true) end
  if hb.healAbsorbFrame and hb.healAbsorbFrame.SetClipsChildren then hb.healAbsorbFrame:SetClipsChildren(true) end
  local srcMain = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
  local srcHC = srcMain and srcMain.HealthBarsContainer
  local srcHP = PlayerFrameHealthBar or (srcHC and srcHC.HealthBar)
  if not srcHP then
    HidePRBHealthOverlays()
    return
  end

  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local dmgAbsorbMode = (profile and profile.prbDmgAbsorb) or "bar"
  if dmgAbsorbMode == "bar_glow" then
    dmgAbsorbMode = "bar"
  end
  if dmgAbsorbMode ~= "bar" and dmgAbsorbMode ~= "off" then
    dmgAbsorbMode = "bar"
  end
  local healPredMode = (profile and profile.prbHealPred) or "on"
  if healPredMode ~= "on" and healPredMode ~= "off" then
    healPredMode = "on"
  end
  local healAbsorbMode = (profile and profile.prbHealAbsorb) or "on"
  if healAbsorbMode ~= "on" and healAbsorbMode ~= "off" then
    healAbsorbMode = "on"
  end
  local showOverAbsorbBar = not profile or profile.prbOverAbsorbBar ~= false
  local stripesOn = profile and profile.prbAbsorbStripes == true
  local overlayTexPath = GetPRBAbsorbTexturePath(profile)
  local stripeTexPath = GetPRBStripeOverlayPath()
  local w = math.max(1, SafeNum(width) or SafeNum(hb.GetWidth and hb:GetWidth() or nil) or 1)

  if hb.myHealPredFrame and hb.myHealPredFrame.SetStatusBarTexture then hb.myHealPredFrame:SetStatusBarTexture(overlayTexPath) end
  if hb.otherHealPredFrame and hb.otherHealPredFrame.SetStatusBarTexture then hb.otherHealPredFrame:SetStatusBarTexture(overlayTexPath) end
  if hb.dmgAbsorbFrame and hb.dmgAbsorbFrame.SetStatusBarTexture then hb.dmgAbsorbFrame:SetStatusBarTexture(overlayTexPath) end
  if hb.healAbsorbFrame and hb.healAbsorbFrame.SetStatusBarTexture then hb.healAbsorbFrame:SetStatusBarTexture(overlayTexPath) end
  if hb.fullDmgAbsorbFrame and hb.fullDmgAbsorbFrame.SetStatusBarTexture then hb.fullDmgAbsorbFrame:SetStatusBarTexture(PRB_OVERLAY_TEX_NORM) end
  if hb.dmgAbsorbGlow and hb.dmgAbsorbGlow.SetTexture then hb.dmgAbsorbGlow:SetTexture(PRB_OVERLAY_TEX_NORM) end
  if hb.dmgAbsorbStripe and hb.dmgAbsorbStripe.SetTexture then hb.dmgAbsorbStripe:SetTexture(stripeTexPath, "REPEAT", "REPEAT") end
  if hb.healAbsorbStripe and hb.healAbsorbStripe.SetTexture then hb.healAbsorbStripe:SetTexture(stripeTexPath, "REPEAT", "REPEAT") end
  if hb.dmgAbsorbFrame and hb.dmgAbsorbFrame.GetStatusBarTexture then
    hb.dmgAbsorbTex = hb.dmgAbsorbFrame:GetStatusBarTexture() or hb.dmgAbsorbTex
  end
  if hb.healAbsorbFrame and hb.healAbsorbFrame.GetStatusBarTexture then
    hb.healAbsorbTex = hb.healAbsorbFrame:GetStatusBarTexture() or hb.healAbsorbTex
  end
  if hb.dmgAbsorbStripe then
    hb.dmgAbsorbStripe:ClearAllPoints()
    hb.dmgAbsorbStripe:SetAllPoints(hb.dmgAbsorbTex or hb.dmgAbsorbFrame)
    if hb.dmgAbsorbStripe.SetHorizTile then hb.dmgAbsorbStripe:SetHorizTile(true) end
    if hb.dmgAbsorbStripe.SetVertTile then hb.dmgAbsorbStripe:SetVertTile(true) end
    hb.dmgAbsorbStripe:SetVertexColor(1, 1, 1, 0.38)
  end
  if hb.healAbsorbStripe then
    hb.healAbsorbStripe:ClearAllPoints()
    hb.healAbsorbStripe:SetAllPoints(hb.healAbsorbTex or hb.healAbsorbFrame)
    if hb.healAbsorbStripe.SetHorizTile then hb.healAbsorbStripe:SetHorizTile(true) end
    if hb.healAbsorbStripe.SetVertTile then hb.healAbsorbStripe:SetVertTile(true) end
    hb.healAbsorbStripe:SetVertexColor(1, 1, 1, 0.38)
  end

  local proxy = hb._ccmUFProxy or {}
  hb._ccmUFProxy = proxy
  proxy.healthFrame = hb
  proxy.bgFrame = hb
  proxy.origHP = srcHP
  proxy.fillScale = 1
  proxy.dmgAbsorbFrame = hb.dmgAbsorbFrame
  proxy.dmgAbsorbTex = hb.dmgAbsorbTex
  proxy.fullDmgAbsorbFrame = hb.fullDmgAbsorbFrame
  proxy.fullDmgAbsorbTex = hb.fullDmgAbsorbTex
  proxy.dmgAbsorbGlow = hb.dmgAbsorbGlow
  proxy.myHealPredFrame = hb.myHealPredFrame
  proxy.myHealPredTex = hb.myHealPredTex or (hb.myHealPredFrame and hb.myHealPredFrame.GetStatusBarTexture and hb.myHealPredFrame:GetStatusBarTexture()) or nil
  proxy.otherHealPredFrame = hb.otherHealPredFrame
  proxy.otherHealPredTex = hb.otherHealPredTex or (hb.otherHealPredFrame and hb.otherHealPredFrame.GetStatusBarTexture and hb.otherHealPredFrame:GetStatusBarTexture()) or nil
  proxy.healAbsorbFrame = hb.healAbsorbFrame
  proxy.healAbsorbTex = hb.healAbsorbTex or (hb.healAbsorbFrame and hb.healAbsorbFrame.GetStatusBarTexture and hb.healAbsorbFrame:GetStatusBarTexture()) or nil
  proxy.dmgAbsorbStripe = hb.dmgAbsorbStripe
  proxy.healAbsorbStripe = hb.healAbsorbStripe
  proxy.dmgAbsorbCalc = hb._ccmPredCalc
  proxy.forceDmgAbsorbMode = dmgAbsorbMode
  proxy.forceHealPredMode = healPredMode
  proxy.forceHealAbsorbMode = healAbsorbMode
  proxy.forceNoSecretDmgAbsorbRaw = false
  proxy.forceNoSecretHealAbsorbRaw = true

  if addonTable.UpdateUFBigHBHealPrediction then
    addonTable.UpdateUFBigHBHealPrediction(proxy, "player")
  end
  if addonTable.UpdateUFBigHBDmgAbsorb then
    addonTable.UpdateUFBigHBDmgAbsorb(proxy, "player")
  end
  hb._ccmPredCalc = proxy.dmgAbsorbCalc

  if hb.dmgAbsorbStripe then
    if stripesOn and hb.dmgAbsorbFrame and hb.dmgAbsorbFrame.IsShown and hb.dmgAbsorbFrame:IsShown() then
      hb.dmgAbsorbStripe:Show()
    else
      hb.dmgAbsorbStripe:Hide()
    end
  end
  if hb.healAbsorbStripe then
    if stripesOn and hb.healAbsorbFrame and hb.healAbsorbFrame.IsShown and hb.healAbsorbFrame:IsShown() then
      hb.healAbsorbStripe:Show()
    else
      hb.healAbsorbStripe:Hide()
    end
  end

  local overAbsorbGlowShown = (srcHP and srcHP.OverAbsorbGlow and srcHP.OverAbsorbGlow.IsShown and srcHP.OverAbsorbGlow:IsShown()) and true or false
  local overAbsorbNumericShown = false
  local absorbRawSignal = nil
  local curHealthSafe = nil
  local maxHealthSafe = nil
  if UnitGetTotalAbsorbs and UnitHealth and UnitHealthMax then
    absorbRawSignal = UnitGetTotalAbsorbs("player")
    local totalAbsorb = SafeNum(absorbRawSignal)
    curHealthSafe = SafeNum(UnitHealth("player"))
    maxHealthSafe = SafeNum(UnitHealthMax("player"))
    if totalAbsorb and curHealthSafe and maxHealthSafe and maxHealthSafe > 0 then
      local missing = maxHealthSafe - curHealthSafe
      if missing < 0 then missing = 0 end
      if totalAbsorb > missing then
        overAbsorbNumericShown = true
      end
    end
  end
  local atFullHealth = false
  if curHealthSafe and maxHealthSafe and maxHealthSafe > 0 then
    atFullHealth = curHealthSafe >= (maxHealthSafe - 0.5)
  end
  if (not overAbsorbNumericShown) and atFullHealth and HasPositiveValue(absorbRawSignal) then
    overAbsorbNumericShown = true
  end
  local overAbsorbShown = overAbsorbGlowShown or overAbsorbNumericShown
  if showOverAbsorbBar and not overAbsorbShown and hb.fullDmgAbsorbFrame and hb.fullDmgAbsorbFrame.IsShown and hb.fullDmgAbsorbFrame:IsShown() then
    overAbsorbShown = true
  end
  if dmgAbsorbMode == "off" or not showOverAbsorbBar then
    overAbsorbShown = false
  end

  if hb.fullDmgAbsorbFrame then
    if overAbsorbShown and dmgAbsorbMode ~= "off" then
      hb.fullDmgAbsorbFrame:ClearAllPoints()
      hb.fullDmgAbsorbFrame:SetPoint("TOPRIGHT", hb, "TOPRIGHT", 0, 0)
      hb.fullDmgAbsorbFrame:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 0, 0)
      local overW = math.max(1, math.floor((w * 0.04) + 0.5))
      overW = math.max(0, math.min(w, overW))
      hb.fullDmgAbsorbFrame:SetWidth(overW)
      pcall(hb.fullDmgAbsorbFrame.SetMinMaxValues, hb.fullDmgAbsorbFrame, 0, math.max(1, overW))
      pcall(hb.fullDmgAbsorbFrame.SetValue, hb.fullDmgAbsorbFrame, overW)
      if hb.fullDmgAbsorbFrame.SetReverseFill then hb.fullDmgAbsorbFrame:SetReverseFill(false) end
      if hb.fullDmgAbsorbTex and hb.fullDmgAbsorbTex.SetTexCoord then hb.fullDmgAbsorbTex:SetTexCoord(0, 1, 0, 1) end
      hb.fullDmgAbsorbFrame:SetAlpha(1)
      if hb.fullDmgAbsorbTex then
        hb.fullDmgAbsorbTex:SetAlpha(1)
        if hb.fullDmgAbsorbTex.SetVertexColor then
          hb.fullDmgAbsorbTex:SetVertexColor(0.70, 0.90, 1.00, 1.00)
        end
      end
      hb.fullDmgAbsorbFrame:Show()
    else
      hb.fullDmgAbsorbFrame:Hide()
    end
  end

  if hb.dmgAbsorbGlow then hb.dmgAbsorbGlow:Hide() end

  local hbLevel = hb:GetFrameLevel() or 1
  if hb.dmgAbsorbFrame then hb.dmgAbsorbFrame:SetFrameLevel(hbLevel + 1) end
  if hb.myHealPredFrame then hb.myHealPredFrame:SetFrameLevel(hbLevel + 2) end
  if hb.otherHealPredFrame then hb.otherHealPredFrame:SetFrameLevel(hbLevel + 2) end
  if hb.healAbsorbFrame then hb.healAbsorbFrame:SetFrameLevel(hbLevel + 3) end
  if hb.fullDmgAbsorbFrame then hb.fullDmgAbsorbFrame:SetFrameLevel(hbLevel + 4) end
  if hb.border then hb.border:SetFrameLevel(hbLevel + 5) end
end
local function UpdatePRB(force)
  if not force then
    local nowTs = (GetTime and GetTime()) or 0
    local lastTs = State.prbLastUpdateTs or 0
    if type(nowTs) ~= "number" then nowTs = 0 end
    if type(lastTs) ~= "number" then lastTs = 0 end
    if (nowTs - lastTs) < 0.06 then
      return
    end
    State.prbLastUpdateTs = nowTs
  else
    local nowTs = (GetTime and GetTime()) or 0
    if type(nowTs) ~= "number" then nowTs = 0 end
    State.prbLastUpdateTs = nowTs
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.usePersonalResourceBar then
    HidePRBHealthOverlays()
    prbFrame:Hide()
    SetBlizzardPlayerPowerBarsVisibility(false, false)
    return
  end
  local showMode = profile.prbShowMode or "always"
  if showMode == "combat" and not InCombatLockdown() then
    HidePRBHealthOverlays()
    prbFrame:Hide()
    return
  end
  local width = profile.prbWidth or 220
  local rawBorder = profile.prbBorderSize or 1
  local borderSize = rawBorder
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
    local healthTexturePath = addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(healthTexture) or TEXTURE_PATHS[healthTexture] or TEXTURE_PATHS.solid
    local powerTexturePath = addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(powerTexture) or TEXTURE_PATHS[powerTexture] or TEXTURE_PATHS.solid
    local manaTexturePath = addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(manaTexture) or TEXTURE_PATHS[manaTexture] or TEXTURE_PATHS.solid
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
    local barOrder = prbBarOrder
    local clampTotalHeight = nil
    if clampBars then
      for i = 1, #barOrder do barOrder[i] = nil end
      prbBarEntries[1].priority = healthYOffset; prbBarEntries[1].height = healthHeight; prbBarEntries[1].active = showHealth; prbBarEntries[1].yPos = nil
      prbBarEntries[2].priority = powerYOffset; prbBarEntries[2].height = powerHeight; prbBarEntries[2].active = showPower; prbBarEntries[2].yPos = nil
      prbBarEntries[3].priority = manaYOffset; prbBarEntries[3].height = manaHeight; prbBarEntries[3].active = showManaBar; prbBarEntries[3].yPos = nil
      prbBarEntries[4].priority = cpYOffset; prbBarEntries[4].height = cpHeight; prbBarEntries[4].active = (showClassPower and hasClassPower); prbBarEntries[4].yPos = nil
      barOrder[1] = prbBarEntries[1]; barOrder[2] = prbBarEntries[2]; barOrder[3] = prbBarEntries[3]; barOrder[4] = prbBarEntries[4]
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
      prbFrame.healthBar:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", 0, -healthY)
      prbFrame.healthBar:SetPoint("RIGHT", prbFrame, "RIGHT")
      prbFrame.healthBar:SetHeight(healthHeight)
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
      local overlay = prbFrame.healthBar.lowHealthOverlay
      if profile.prbUseLowHealthColor and overlay and PRB_LowHealthAlphaCurve and UnitHealthPercent then
        RebuildLowHealthAlphaCurve(PRB_LowHealthThreshold)
        local lr = profile.prbLowHealthColorR or 1
        local lg = profile.prbLowHealthColorG or 0
        local lb = profile.prbLowHealthColorB or 0
        overlay:SetStatusBarTexture(healthTexturePath)
        overlay:SetStatusBarColor(lr, lg, lb)
        overlay:SetMinMaxValues(0, UnitHealthMax("player") or 1)
        overlay:SetValue(UnitHealth("player") or 0)
        overlay:Show()
        local alpha = UnitHealthPercent("player", false, PRB_LowHealthAlphaCurve)
        if alpha ~= nil then
          pcall(overlay.SetAlpha, overlay, alpha)
        else
          overlay:SetAlpha(0)
        end
      elseif overlay then
        overlay:Hide()
        overlay:SetAlpha(0)
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
      prbFrame.healthBar.text:SetFont(globalFont, 12, globalOutline or "")
      ApplyConsistentFontShadow(prbFrame.healthBar.text, globalOutline)
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
          local raw = UnitHealth("player")
          healthText = SafeNum(raw) and AbbreviateNumbers(raw) or tostring(raw)
        elseif healthTextMode == "both" then
          local raw = UnitHealth("player")
          local valStr = SafeNum(raw) and AbbreviateNumbers(raw) or tostring(raw)
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
      UpdatePRBHealthOverlays(width, healthHeight)
      if showPower then
        yOff = yOff + healthHeight + spacing
      else
        yOff = yOff + healthHeight
      end
    else
      prbFrame.healthBar:Hide()
      prbFrame.healthBar.text:Hide()
      prbFrame.healthBar.border:Hide()
      HidePRBHealthOverlays()
    end
    if showPower then
      prbFrame.powerBar:Show()
      prbFrame.powerBar:SetStatusBarTexture(powerTexturePath)
      prbFrame.powerBar:ClearAllPoints()
      local powerY = clampBars and GetBarYPos("power", 0, 0) or (yOff - powerYOffset)
      if clampBars then
        powerYPosForClamp = powerY
      end
      prbFrame.powerBar:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", 0, -powerY)
      prbFrame.powerBar:SetPoint("RIGHT", prbFrame, "RIGHT")
      prbFrame.powerBar:SetHeight(powerHeight)
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
      local powerOverlay = prbFrame.powerBar.lowPowerOverlay
      if profile.prbUseLowPowerColor and powerOverlay and PRB_LowPowerAlphaCurve and UnitPowerPercent then
        RebuildLowPowerAlphaCurve(PRB_LowPowerThreshold)
        local lpr = profile.prbLowPowerColorR or 1
        local lpg = profile.prbLowPowerColorG or 0.5
        local lpb = profile.prbLowPowerColorB or 0
        powerOverlay:SetStatusBarTexture(powerTexturePath)
        powerOverlay:SetStatusBarColor(lpr, lpg, lpb)
        powerOverlay:SetMinMaxValues(0, UnitPowerMax("player") or 1)
        powerOverlay:SetValue(UnitPower("player") or 0)
        powerOverlay:Show()
        local pAlpha = UnitPowerPercent("player", powerType, false, PRB_LowPowerAlphaCurve)
        if pAlpha ~= nil then
          pcall(powerOverlay.SetAlpha, powerOverlay, pAlpha)
        else
          powerOverlay:SetAlpha(0)
        end
      elseif powerOverlay then
        powerOverlay:Hide()
        powerOverlay:SetAlpha(0)
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
      prbFrame.powerBar.text:SetFont(globalFont, 12, globalOutline or "")
      ApplyConsistentFontShadow(prbFrame.powerBar.text, globalOutline)
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
          local raw = UnitPower("player", powerType)
          powerText = SafeNum(raw) and AbbreviateNumbers(raw) or tostring(raw)
        elseif powerTextMode == "both" then
          local raw = UnitPower("player", powerType)
          local valStr = SafeNum(raw) and AbbreviateNumbers(raw) or tostring(raw)
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
        prbFrame.manaBar:SetPoint("RIGHT", prbFrame, "RIGHT")
      else
        prbFrame.manaBar:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", 0, -manaY)
        prbFrame.manaBar:SetPoint("RIGHT", prbFrame, "RIGHT")
      end
      prbFrame.manaBar:SetHeight(manaHeight)
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
      prbFrame.manaBar.text:SetFont(globalFont, 12, globalOutline or "")
      ApplyConsistentFontShadow(prbFrame.manaBar.text, globalOutline)
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
          local raw = UnitPower("player", 0)
          manaText = SafeNum(raw) and AbbreviateNumbers(raw) or tostring(raw)
        elseif manaTextMode == "both" then
          local raw = UnitPower("player", 0)
          local valStr = SafeNum(raw) and AbbreviateNumbers(raw) or tostring(raw)
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
        prbFrame.classPowerBar:ClearAllPoints()
        if clampBars then
          local classPowerYPos = GetBarYPos("classpower", 0, 0)
          prbFrame.classPowerBar:SetPoint("TOPLEFT", prbFrame, "TOPLEFT", 0, -classPowerYPos)
          prbFrame.classPowerBar:SetPoint("RIGHT", prbFrame, "RIGHT")
          prbFrame.classPowerBar:SetHeight(cpHeight)
        elseif profile.prbCentered then
          prbFrame.classPowerBar:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", 0, cpY)
          prbFrame.classPowerBar:SetPoint("RIGHT", prbFrame, "RIGHT")
          prbFrame.classPowerBar:SetHeight(cpHeight)
        else
          prbFrame.classPowerBar:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", cpX, cpY)
          prbFrame.classPowerBar:SetSize(width, cpHeight)
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
  UpdatePRB(true)
end
addonTable.UpdatePRBFonts = UpdatePRBFonts
local PRB_TICK_INTERVAL = 0.20
local StartPRBTicker
local function StopPRBTicker()
  if State.prbTicker then
    State.prbTicker:Cancel()
    State.prbTicker = nil
  end
end
StartPRBTicker = function()
  if State.prbTicker then return end
  State.prbTicker = C_Timer.NewTicker(PRB_TICK_INTERVAL, function()
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if not profile or not profile.usePersonalResourceBar then
      StopPRBTicker()
      return
    end
    local showMode = profile.prbShowMode or "always"
    if showMode == "combat" and not InCombatLockdown() then
      return
    end
    UpdatePRB(false)
  end)
end
addonTable.StartPRBTicker = StartPRBTicker
addonTable.StopPRBTicker = StopPRBTicker
addonTable.EvaluatePRBTicker = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.usePersonalResourceBar then
    StopPRBTicker()
    return
  end
  local showMode = profile.prbShowMode or "always"
  if showMode == "combat" then
    if InCombatLockdown() then
      StartPRBTicker()
      UpdatePRB(true)
    end
  else
    StartPRBTicker()
  end
end
