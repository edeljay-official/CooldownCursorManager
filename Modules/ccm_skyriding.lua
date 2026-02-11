--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_skyriding.lua
-- Skyriding Enhancement: charge bar, speed display, ability cooldowns
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, addonTable = ...

local GetProfile = addonTable.GetProfile
local GetGlobalFont = addonTable.GetGlobalFont

local CHARGE_SPELL_IDS = {372608, 372610}
local SEGMENT_GAP = 2
local BAR_HEIGHT = 14
local SPEED_BAR_HEIGHT = 14
local CD_ICON_SIZE = 28
local BASE_MOVEMENT_SPEED = 7

local SKYRIDING_CD_SPELLS = {
  {id = 361584, vigorConsumer = true},
  {id = 425782},
}

local mainFrame, vigorContainer, speedContainer, speedBar, speedText
local vigorSegments = {}
local cdIcons = {}
local cdSpells = {}
local eventFrame, onUpdateFrame
local blizzVigorHooked = false
local prevX, prevY, prevTime
local smoothSpeed = 0
local chargeSpellID
local previewActive = false
local speedFontDirty = true
local colorsDirty = true
local cdLayoutDirty = true
local lastSpeedText
local lastSpeedColorTier = 0
local lastVigorFull, lastVigorTotal = -1, -1
local cachedColors = {}
local UpdatePreviewButtonState

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local string_format = string.format

-- ============================================================
-- Charge Data (12.0 spell charges system)
-- ============================================================

local function FindChargeSpell()
  if chargeSpellID then
    local info = C_Spell.GetSpellCharges(chargeSpellID)
    if info and info.maxCharges and info.maxCharges > 0 then return chargeSpellID end
  end
  for _, id in ipairs(CHARGE_SPELL_IDS) do
    local info = C_Spell.GetSpellCharges(id)
    if info and info.maxCharges and info.maxCharges > 0 then
      chargeSpellID = id
      return id
    end
  end
  return nil
end

local function IsOnSkyridingMount()
  if not IsMounted() then return false end
  local _, canGlide = C_PlayerInfo.GetGlidingInfo()
  if not canGlide then return false end
  return FindChargeSpell() ~= nil
end

local function InvalidateColors()
  colorsDirty = true
end
addonTable.InvalidateSkyridingColors = InvalidateColors

local function RefreshCachedColors(profile)
  if not colorsDirty then return end
  colorsDirty = false
  cachedColors.fullR = profile.skyridingVigorColorR or 0.2
  cachedColors.fullG = profile.skyridingVigorColorG or 0.8
  cachedColors.fullB = profile.skyridingVigorColorB or 0.2
  cachedColors.emptyR = profile.skyridingVigorEmptyColorR or 0.15
  cachedColors.emptyG = profile.skyridingVigorEmptyColorG or 0.15
  cachedColors.emptyB = profile.skyridingVigorEmptyColorB or 0.15
  cachedColors.rechargeR = profile.skyridingVigorRechargeColorR or 0.85
  cachedColors.rechargeG = profile.skyridingVigorRechargeColorG or 0.65
  cachedColors.rechargeB = profile.skyridingVigorRechargeColorB or 0.1
  cachedColors.speedR = profile.skyridingSpeedColorR or 0.3
  cachedColors.speedG = profile.skyridingSpeedColorG or 0.6
  cachedColors.speedB = profile.skyridingSpeedColorB or 1.0
end

-- ============================================================
-- Frame Creation
-- ============================================================

local ApplyFrameLayout

local function CreateMainFrame()
  if mainFrame then return end

  mainFrame = CreateFrame("Frame", "CCMSkyridingFrame", UIParent)
  mainFrame:SetSize(250, BAR_HEIGHT + 4)
  mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
  mainFrame:SetFrameStrata("MEDIUM")
  mainFrame:SetFrameLevel(10)
  mainFrame:SetClampedToScreen(true)
  mainFrame:SetMovable(true)
  mainFrame:EnableMouse(true)
  mainFrame:RegisterForDrag("LeftButton")
  mainFrame:Hide()

  mainFrame:SetScript("OnDragStart", function(self)
    local qolTab = addonTable.TAB_QOL or 12
    local guiOpen = addonTable.GetGUIOpen and addonTable.GetGUIOpen()
    local onTab = addonTable.activeTab and addonTable.activeTab() == qolTab
    if not guiOpen or not onTab then return end
    self.isDragging = true
    self:StartMoving()
  end)
  mainFrame:SetScript("OnDragStop", function(self)
    if not self.isDragging then return end
    self:StopMovingOrSizing()
    self.isDragging = false
    local profile = GetProfile and GetProfile()
    if profile then
      local s = self:GetScale()
      local cx, cy = UIParent:GetCenter()
      local fx, fy = self:GetCenter()
      local rawY = fy * s - cy
      if not profile.skyridingCentered then
        profile.skyridingX = math_floor(fx * s - cx + 0.5)
      end
      profile.skyridingY = math_floor(rawY + 0.5)
      if profile.skyridingCentered then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, rawY)
      end
    end
  end)

  vigorContainer = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
  vigorContainer:SetHeight(BAR_HEIGHT + 4)
  vigorContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
  vigorContainer:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
  vigorContainer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
  vigorContainer:SetBackdropColor(0.05, 0.05, 0.07, 0.85)

  speedContainer = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
  speedContainer:SetHeight(SPEED_BAR_HEIGHT + 4)
  speedContainer:SetPoint("TOPLEFT", vigorContainer, "BOTTOMLEFT", 0, 0)
  speedContainer:SetPoint("TOPRIGHT", vigorContainer, "BOTTOMRIGHT", 0, 0)
  speedContainer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
  speedContainer:SetBackdropColor(0.05, 0.05, 0.07, 0.85)
  speedContainer:Hide()

  speedBar = CreateFrame("StatusBar", nil, speedContainer)
  speedBar:SetPoint("TOPLEFT", speedContainer, "TOPLEFT", 2, -2)
  speedBar:SetPoint("BOTTOMRIGHT", speedContainer, "BOTTOMRIGHT", -2, 2)
  speedBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  speedBar:SetMinMaxValues(0, 1000)
  speedBar:SetValue(0)
  speedBar:GetStatusBarTexture():SetVertexColor(0.3, 0.6, 1.0, 0.9)

  speedBar.bg = speedBar:CreateTexture(nil, "BACKGROUND", nil, -4)
  speedBar.bg:SetAllPoints()
  speedBar.bg:SetColorTexture(0.08, 0.08, 0.10, 1)

  speedText = speedBar:CreateFontString(nil, "OVERLAY")
  speedText:SetPoint("CENTER", speedBar, "CENTER", 0, 0)
  speedText:SetTextColor(0.9, 0.9, 0.9, 1)
  local fontPath, fontOutline
  if GetGlobalFont then fontPath, fontOutline = GetGlobalFont() end
  speedText:SetFont(fontPath or "Fonts\\FRIZQT__.TTF", 10, fontOutline or "OUTLINE")
  speedFontDirty = false
end

local function CreateVigorSegments(count)
  for i = 1, #vigorSegments do
    vigorSegments[i]:Hide()
  end

  local innerWidth = mainFrame:GetWidth() - 4
  local totalGaps = (count - 1) * SEGMENT_GAP
  local segWidth = (innerWidth - totalGaps) / count

  for i = 1, count do
    if not vigorSegments[i] then
      local bar = CreateFrame("StatusBar", nil, vigorContainer)
      bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      bar:SetMinMaxValues(0, 1)
      bar:SetValue(1)

      bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -4)
      bar.bg:SetAllPoints()
      bar.bg:SetColorTexture(0.15, 0.15, 0.15, 1)

      vigorSegments[i] = bar
    end

    local bar = vigorSegments[i]
    bar:SetSize(segWidth, BAR_HEIGHT)
    bar:ClearAllPoints()
    local xOff = 2 + (i - 1) * (segWidth + SEGMENT_GAP)
    bar:SetPoint("LEFT", vigorContainer, "LEFT", xOff, 0)
    bar:Show()
  end
  lastVigorFull, lastVigorTotal = -1, -1
end

local function CreateCooldownIcon(index)
  if cdIcons[index] then return cdIcons[index] end

  local icon = CreateFrame("Frame", nil, mainFrame)
  icon:SetSize(CD_ICON_SIZE, CD_ICON_SIZE)

  icon.tex = icon:CreateTexture(nil, "ARTWORK")
  icon.tex:SetAllPoints()
  icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
  icon.cd:SetAllPoints()
  icon.cd:SetDrawEdge(true)
  icon.cd:SetHideCountdownNumbers(false)

  icon.border = icon:CreateTexture(nil, "BACKGROUND", nil, -1)
  icon.border:SetPoint("TOPLEFT", -1, 1)
  icon.border:SetPoint("BOTTOMRIGHT", 1, -1)
  icon.border:SetColorTexture(0.2, 0.2, 0.2, 0.8)

  icon.stacks = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  icon.stacks:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
  icon.stacks:SetJustifyH("RIGHT")
  icon.stacks:Hide()

  if GetGlobalFont then
    local fontPath, fontOutline = GetGlobalFont()
    local _, stackSize = icon.stacks:GetFont()
    icon.stacks:SetFont(fontPath, stackSize, fontOutline or "OUTLINE")
    for j = 1, select("#", icon.cd:GetRegions()) do
      local region = select(j, icon.cd:GetRegions())
      if region and region.GetObjectType and region:GetObjectType() == "FontString" then
        local _, cdSize = region:GetFont()
        if cdSize then region:SetFont(fontPath, cdSize, fontOutline or "OUTLINE") end
      end
    end
  end

  icon:Hide()
  cdIcons[index] = icon
  return icon
end

-- ============================================================
-- Layout
-- ============================================================

local function UpdateLayout()
  if not mainFrame then return end
  local profile = GetProfile and GetProfile()
  if not profile then return end

  local showVigor = profile.skyridingVigorBar
  local showSpeed = profile.skyridingSpeedDisplay

  vigorContainer:ClearAllPoints()
  vigorContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
  vigorContainer:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)

  speedContainer:ClearAllPoints()
  if showVigor then
    vigorContainer:Show()
    speedContainer:SetPoint("TOPLEFT", vigorContainer, "BOTTOMLEFT", 0, 0)
    speedContainer:SetPoint("TOPRIGHT", vigorContainer, "BOTTOMRIGHT", 0, 0)
  else
    vigorContainer:Hide()
    for i = 1, #vigorSegments do vigorSegments[i]:Hide() end
    speedContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    speedContainer:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
  end

  if showSpeed then
    speedContainer:Show()
  else
    speedContainer:Hide()
  end

  local totalHeight = 0
  if showVigor then totalHeight = totalHeight + BAR_HEIGHT + 4 end
  if showSpeed then totalHeight = totalHeight + SPEED_BAR_HEIGHT + 4 end
  if totalHeight == 0 then totalHeight = BAR_HEIGHT + 4 end
  mainFrame:SetHeight(totalHeight)

  cdLayoutDirty = true
end

local function LayoutCooldownIcons(profile)
  cdLayoutDirty = false

  if #cdSpells == 0 then
    for _, spell in ipairs(SKYRIDING_CD_SPELLS) do
      local name = C_Spell.GetSpellName(spell.id)
      if name then
        local tex = C_Spell.GetSpellTexture(spell.id)
        tinsert(cdSpells, {id = spell.id, name = name, icon = tex, vigorConsumer = spell.vigorConsumer})
      end
    end
  end

  if not profile.skyridingCooldowns then
    for _, icon in ipairs(cdIcons) do icon:Hide() end
    return
  end

  local pos = profile.skyridingCooldownPosition or "below"
  local iconSize = profile.skyridingCooldownSize or CD_ICON_SIZE
  local bottomAnchor = speedContainer:IsShown() and speedContainer or vigorContainer:IsShown() and vigorContainer or mainFrame
  local topAnchor = vigorContainer:IsShown() and vigorContainer or speedContainer:IsShown() and speedContainer or mainFrame
  local count = #cdSpells
  local step = iconSize + 4

  for i, spell in ipairs(cdSpells) do
    local icon = CreateCooldownIcon(i)
    icon:SetSize(iconSize, iconSize)
    icon.tex:SetTexture(spell.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    icon:ClearAllPoints()
    local centerOff = ((i - 1) * step) - ((math_min(count, 4) - 1) * step / 2)
    if pos == "above" then
      icon:SetPoint("BOTTOM", topAnchor, "TOP", centerOff, 3)
    elseif pos == "left" then
      icon:SetPoint("RIGHT", mainFrame, "LEFT", -3, -centerOff)
    elseif pos == "right" then
      icon:SetPoint("LEFT", mainFrame, "RIGHT", 3, -centerOff)
    else
      icon:SetPoint("TOP", bottomAnchor, "BOTTOM", centerOff, -3)
    end
    icon:Show()
  end

  for i = #cdSpells + 1, #cdIcons do
    cdIcons[i]:Hide()
  end
end

-- ============================================================
-- Update Functions
-- ============================================================

local function UpdateVigorBar(profile)
  if not profile.skyridingVigorBar then return end

  if not chargeSpellID then FindChargeSpell() end
  if not chargeSpellID then return end
  local data = C_Spell.GetSpellCharges(chargeSpellID)
  if not data then return end

  local total = data.maxCharges or 6
  local full = data.currentCharges or 0

  if #vigorSegments < total or (#vigorSegments > 0 and not vigorSegments[1]:IsShown()) then
    CreateVigorSegments(total)
  end

  local c = cachedColors
  local chargesChanged = full ~= lastVigorFull or total ~= lastVigorTotal
  lastVigorFull, lastVigorTotal = full, total

  for i = 1, total do
    local bar = vigorSegments[i]
    if not bar then break end

    if i <= full then
      if chargesChanged or colorsDirty then
        bar:GetStatusBarTexture():SetVertexColor(c.fullR, c.fullG, c.fullB, 1)
        bar:SetValue(1)
        bar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
      end
    elseif i == full + 1 and full < total then
      bar:GetStatusBarTexture():SetVertexColor(c.rechargeR, c.rechargeG, c.rechargeB, 1)
      local progress = 0
      if data.cooldownDuration and data.cooldownDuration > 0 and data.cooldownStartTime then
        local elapsed = GetTime() - data.cooldownStartTime
        progress = elapsed / data.cooldownDuration
      end
      bar:SetValue(math_max(0, math_min(1, progress)))
      bar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
    else
      if chargesChanged or colorsDirty then
        bar:GetStatusBarTexture():SetVertexColor(c.emptyR, c.emptyG, c.emptyB, 0)
        bar:SetValue(0)
        bar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
      end
    end
  end
end

local function UpdateSpeedDisplay(profile)
  if not profile.skyridingSpeedDisplay then return end

  local speed = GetUnitSpeed("player") or 0
  local speedPercent = 0

  if speed > 0 then
    speedPercent = (speed / BASE_MOVEMENT_SPEED) * 100
    smoothSpeed = speedPercent
  else
    local _, isGliding = C_PlayerInfo.GetGlidingInfo()
    if isGliding and UnitPosition then
      local x, y = UnitPosition("player")
      local now = GetTime()
      if x and y and prevX and prevY and prevTime then
        local dt = now - prevTime
        if dt > 0.01 then
          local dx = x - prevX
          local dy = y - prevY
          local dist = math_sqrt(dx * dx + dy * dy)
          local rawSpeed = dist / dt
          speedPercent = (rawSpeed / BASE_MOVEMENT_SPEED) * 100
          smoothSpeed = smoothSpeed + (speedPercent - smoothSpeed) * 0.3
          speedPercent = smoothSpeed
        end
      end
      prevX, prevY, prevTime = x, y, now
    else
      smoothSpeed = smoothSpeed * 0.85
      speedPercent = smoothSpeed
      if speedPercent < 1 then speedPercent = 0; smoothSpeed = 0 end
      prevX, prevY, prevTime = nil, nil, nil
    end
  end

  local c = cachedColors
  if colorsDirty then
    speedBar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
  end

  if profile.skyridingSpeedBar then
    speedBar:SetValue(math_min(1000, speedPercent))
    if colorsDirty then
      speedBar:GetStatusBarTexture():SetVertexColor(c.speedR, c.speedG, c.speedB, 0.9)
    end
  else
    speedBar:SetValue(0)
  end

  local unit = profile.skyridingSpeedUnit or "percent"
  local txt
  if unit == "yds" then
    local ydsPerSec = (speedPercent / 100) * BASE_MOVEMENT_SPEED
    txt = string_format("%.0f yds/s", ydsPerSec)
  else
    txt = string_format("%.0f%%", speedPercent)
  end
  if txt ~= lastSpeedText then
    lastSpeedText = txt
    speedText:SetText(txt)
  end

  local tier = speedPercent >= 830 and 3 or speedPercent >= 650 and 2 or 1
  if tier ~= lastSpeedColorTier then
    lastSpeedColorTier = tier
    if tier == 3 then
      speedText:SetTextColor(1, 0.2, 0.2)
    elseif tier == 2 then
      speedText:SetTextColor(0.3, 0.6, 1.0)
    else
      speedText:SetTextColor(0.9, 0.9, 0.9)
    end
  end

  if speedFontDirty and GetGlobalFont then
    local fontPath, fontOutline = GetGlobalFont()
    local _, size = speedText:GetFont()
    speedText:SetFont(fontPath, size or 10, fontOutline or "OUTLINE")
    speedFontDirty = false
  end
  speedText:Show()
end

local function UpdateCooldowns(profile)
  if not profile.skyridingCooldowns then return end

  for i, spell in ipairs(cdSpells) do
    local icon = cdIcons[i]
    if not icon then break end

    local chargeInfo
    if not spell.vigorConsumer then
      chargeInfo = C_Spell.GetSpellCharges(spell.id)
    end

    local cdInfo = C_Spell.GetSpellCooldown(spell.id)
    if cdInfo and cdInfo.startTime and cdInfo.duration and cdInfo.duration > 1.5 then
      icon.cd:SetCooldown(cdInfo.startTime, cdInfo.duration)
    elseif chargeInfo and chargeInfo.cooldownStartTime and chargeInfo.cooldownDuration and chargeInfo.cooldownDuration > 0 then
      icon.cd:SetCooldown(chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration)
    else
      icon.cd:Clear()
    end

    if chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
      icon.stacks:SetText(chargeInfo.currentCharges)
      icon.stacks:Show()
    else
      icon.stacks:Hide()
    end
  end
end

local function ApplySkyridingFonts()
  if not GetGlobalFont then return end
  local fontPath, fontOutline = GetGlobalFont()

  if speedText then
    local _, size = speedText:GetFont()
    speedText:SetFont(fontPath, size or 10, fontOutline or "OUTLINE")
    speedFontDirty = false
  end

  for _, icon in ipairs(cdIcons) do
    if icon.stacks then
      local _, stackSize = icon.stacks:GetFont()
      icon.stacks:SetFont(fontPath, stackSize, fontOutline or "OUTLINE")
    end
    if icon.cd then
      for j = 1, select("#", icon.cd:GetRegions()) do
        local region = select(j, icon.cd:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
          local _, cdSize = region:GetFont()
          if cdSize then region:SetFont(fontPath, cdSize, fontOutline or "OUTLINE") end
        end
      end
    end
  end
end
addonTable.ApplySkyridingFonts = ApplySkyridingFonts
addonTable.MarkSkyridingFontDirty = function() speedFontDirty = true end

-- ============================================================
-- Blizzard UI Hiding
-- ============================================================

local function HideBlizzardVigor()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.skyridingEnabled or not profile.skyridingHideBlizzard then return end

  local barFrame = UIWidgetPowerBarContainerFrame
  if not barFrame then return end

  if not blizzVigorHooked then
    blizzVigorHooked = true
    barFrame:Hide()
    hooksecurefunc(barFrame, "Show", function(self)
      local p = GetProfile and GetProfile()
      if p and p.skyridingEnabled and p.skyridingHideBlizzard then
        self:Hide()
      end
    end)
  else
    barFrame:Hide()
  end
end

local function ShowBlizzardVigor()
  local barFrame = UIWidgetPowerBarContainerFrame
  if barFrame then barFrame:Show() end
end

local blizzCDMHooked = false
local prbHooked = false
local cbarHooked = {}
local CDM_BAR_NAMES = {"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer"}
local CBAR_KEYS = {"CustomBarFrame", "CustomBar2Frame", "CustomBar3Frame"}

local function HideBlizzardCDM()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.skyridingEnabled or not profile.skyridingHideCDM then return end

  for _, name in ipairs(CDM_BAR_NAMES) do
    local bar = _G[name]
    if bar then
      bar:Hide()
      if not blizzCDMHooked then
        hooksecurefunc(bar, "Show", function(self)
          local p = GetProfile and GetProfile()
          if p and p.skyridingEnabled and p.skyridingHideCDM and (IsOnSkyridingMount() or previewActive) then
            self:Hide()
          end
        end)
      end
    end
  end
  blizzCDMHooked = true

  local prb = addonTable.PRBFrame
  if prb then
    prb:Hide()
    if not prbHooked then
      prbHooked = true
      hooksecurefunc(prb, "Show", function(self)
        local p = GetProfile and GetProfile()
        if p and p.skyridingEnabled and p.skyridingHideCDM and (IsOnSkyridingMount() or previewActive) then
          self:Hide()
        end
      end)
    end
  end

  for _, key in ipairs(CBAR_KEYS) do
    local cb = addonTable[key]
    if cb then
      cb:Hide()
      if not cbarHooked[key] then
        cbarHooked[key] = true
        hooksecurefunc(cb, "Show", function(self)
          local p = GetProfile and GetProfile()
          if p and p.skyridingEnabled and p.skyridingHideCDM and (IsOnSkyridingMount() or previewActive) then
            self:Hide()
          end
        end)
      end
    end
  end
end

local function ShowBlizzardCDM()
  for _, name in ipairs(CDM_BAR_NAMES) do
    local bar = _G[name]
    if bar then bar:Show() end
  end
  if addonTable.UpdatePRB then addonTable.UpdatePRB() end
  if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
  if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
  if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
end

-- ============================================================
-- Visibility
-- ============================================================

ApplyFrameLayout = function()
  if not mainFrame then return end
  local profile = GetProfile and GetProfile()
  if not profile then return end

  local scale = (profile.skyridingScale or 100) / 100
  mainFrame:SetScale(math_max(0.5, math_min(2, scale)))

  if not mainFrame.isDragging then
    mainFrame:ClearAllPoints()
    local xPos = profile.skyridingCentered and 0 or (profile.skyridingX or 0)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", xPos, profile.skyridingY or -200)
  end
end

local function UpdateVisibility()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.skyridingEnabled then
    if not previewActive then
      if mainFrame then mainFrame:Hide() end
      if onUpdateFrame then onUpdateFrame:Hide() end
    end
    return
  end

  if previewActive then return end

  if IsOnSkyridingMount() then
    if not mainFrame then CreateMainFrame() end
    ApplyFrameLayout()
    UpdateLayout()
    mainFrame:Show()
    if not onUpdateFrame then
      onUpdateFrame = CreateFrame("Frame")
      onUpdateFrame.elapsed = 0
      onUpdateFrame:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed < 0.066 then return end
        self.elapsed = 0
        if not mainFrame or not mainFrame:IsShown() then self:Hide(); return end
        local p = GetProfile and GetProfile()
        if not p then return end
        RefreshCachedColors(p)
        if cdLayoutDirty then LayoutCooldownIcons(p) end
        UpdateVigorBar(p)
        UpdateSpeedDisplay(p)
        UpdateCooldowns(p)
        colorsDirty = false
      end)
    end
    onUpdateFrame:Show()
    colorsDirty = true
    cdLayoutDirty = true
    local p = GetProfile and GetProfile()
    if p then
      RefreshCachedColors(p)
      LayoutCooldownIcons(p)
      UpdateVigorBar(p)
      UpdateSpeedDisplay(p)
      UpdateCooldowns(p)
      colorsDirty = false
    end
    ApplySkyridingFonts()
    HideBlizzardVigor()
    HideBlizzardCDM()
    UpdatePreviewButtonState()
  else
    if mainFrame then mainFrame:Hide() end
    if onUpdateFrame then onUpdateFrame:Hide() end
    smoothSpeed = 0
    prevX, prevY, prevTime = nil, nil, nil
    lastSpeedText = nil
    lastSpeedColorTier = 0
    lastVigorFull, lastVigorTotal = -1, -1
    ShowBlizzardCDM()
    UpdatePreviewButtonState()
  end
end

-- ============================================================
-- Master Setup
-- ============================================================

addonTable.SetupSkyriding = function()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.skyridingEnabled then
    if mainFrame then mainFrame:Hide() end
    if onUpdateFrame then onUpdateFrame:Hide() end
    if not profile or not profile.skyridingHideBlizzard then
      ShowBlizzardVigor()
    end
    ShowBlizzardCDM()
    return
  end

  if not mainFrame then CreateMainFrame() end
  ApplyFrameLayout()
  UpdateLayout()

  if not eventFrame then
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:SetScript("OnEvent", function(self, event)
      local p = GetProfile and GetProfile()
      if not p or not p.skyridingEnabled then return end
      if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        C_Timer.After(0.2, UpdateVisibility)
      elseif event == "SPELL_UPDATE_CHARGES" or event == "SPELL_UPDATE_COOLDOWN" then
        if mainFrame and mainFrame:IsShown() then
          RefreshCachedColors(p)
          UpdateVigorBar(p)
          UpdateCooldowns(p)
        end
      end
    end)
  end

  UpdateVisibility()
end

-- ============================================================
-- Preview
-- ============================================================

local function ShowSkyridingPreview()
  local profile = GetProfile and GetProfile()
  if not profile then return end
  previewActive = true
  if not mainFrame then CreateMainFrame() end
  ApplyFrameLayout()
  UpdateLayout()
  mainFrame:Show()
  HideBlizzardCDM()

  RefreshCachedColors(profile)
  local c = cachedColors

  local total = 6
  if #vigorSegments < total then
    CreateVigorSegments(total)
  end
  for i = 1, total do
    local bar = vigorSegments[i]
    if not bar then break end
    if i <= 4 then
      bar:GetStatusBarTexture():SetVertexColor(c.fullR, c.fullG, c.fullB, 1)
      bar:SetValue(1)
      bar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
    elseif i == 5 then
      bar:GetStatusBarTexture():SetVertexColor(c.rechargeR, c.rechargeG, c.rechargeB, 1)
      bar:SetValue(0.6)
      bar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
    else
      bar:GetStatusBarTexture():SetVertexColor(c.emptyR, c.emptyG, c.emptyB, 0)
      bar:SetValue(0)
      bar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
    end
  end

  if profile.skyridingSpeedDisplay then
    speedBar.bg:SetColorTexture(c.emptyR, c.emptyG, c.emptyB, 1)
    if profile.skyridingSpeedBar then
      speedBar:SetValue(420)
      speedBar:GetStatusBarTexture():SetVertexColor(c.speedR, c.speedG, c.speedB, 0.9)
    else
      speedBar:SetValue(0)
    end
    local unit = profile.skyridingSpeedUnit or "percent"
    if unit == "yds" then
      speedText:SetText("29 yds/s")
    else
      speedText:SetText("420%")
    end
    speedText:SetTextColor(0.9, 0.9, 0.9)
    speedText:Show()
  end

  LayoutCooldownIcons(profile)
  if profile.skyridingCooldowns then
    for i = 1, #cdSpells do
      local icon = cdIcons[i]
      if icon then
        icon.cd:Clear()
        icon.stacks:Hide()
      end
    end
  end
  ApplySkyridingFonts()
end
addonTable.ShowSkyridingPreview = ShowSkyridingPreview

local function StopSkyridingPreview()
  if not previewActive then return end
  previewActive = false
  UpdateVisibility()
end
addonTable.StopSkyridingPreview = StopSkyridingPreview

local function UpdateSkyridingPreviewIfActive()
  if previewActive then
    ShowSkyridingPreview()
  end
end
addonTable.UpdateSkyridingPreviewIfActive = UpdateSkyridingPreviewIfActive

UpdatePreviewButtonState = function()
  local btn = addonTable.skyridingPreviewOnBtn
  if not btn then return end
  if IsOnSkyridingMount() then
    btn:Disable()
    btn:SetAlpha(0.4)
  else
    btn:Enable()
    btn:SetAlpha(1)
  end
end
addonTable.UpdatePreviewButtonState = UpdatePreviewButtonState
