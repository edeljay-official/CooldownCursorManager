--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_fcastbar.lua
-- Focus castbar customization and updates
-- Author: Edeljay
--------------------------------------------------------------------------------
if C_AddOns and C_AddOns.GetAddOnEnableState and C_AddOns.GetAddOnEnableState("CooldownCursorManager_Castbars") == 0 then return end

local _, addonTable = ...
local State = addonTable.State
local GetGlobalFont = addonTable.GetGlobalFont
local FitTextToBar = addonTable.FitTextToBar
local castbarTextures = addonTable.castbarTextures
local channelTickData = addonTable.channelTickData
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
  if addonTable.activeTab and addonTable.activeTab() ~= 9 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(9) end
  end
  State.focusCastbarDragging = true
  self:StartMoving()
end)
addonTable.FocusCastbarFrame:SetScript("OnDragStop", function(self)
  if not State.focusCastbarDragging then return end
  self:StopMovingOrSizing()
  local selfScale = self:GetEffectiveScale()
  local uiScale = UIParent:GetEffectiveScale()
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor((frameX * selfScale - centerX * uiScale) / selfScale + 0.5)
  local newY = math.floor((frameY * selfScale - centerY * uiScale) / selfScale + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.focusCastbarX = newX
    profile.focusCastbarY = newY
    if addonTable.UpdateFocusCastbarSliders then addonTable.UpdateFocusCastbarSliders(newX, newY) end
  end
  State.focusCastbarDragging = false
  self:ClearAllPoints()
  self:SetPoint("CENTER", UIParent, "CENTER", newX, newY)
end)
addonTable.FocusCastbarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.focusCastbarDragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(9) end
    end
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
    State.focusCastbarTickCache = nil
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
  local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
  local function FormatFocusTimeValue(rawValue)
    local num = tonumber(rawValue)
    if num then return string.format(timeFormat, num) end
    return tostring(rawValue or "")
  end
  local textR = profile.focusCastbarTextColorR or 1
  local textG = profile.focusCastbarTextColorG or 1
  local textB = profile.focusCastbarTextColorB or 1
  frame.bar:SetStatusBarTexture(addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(profile.focusCastbarTexture) or castbarTextures[profile.focusCastbarTexture] or castbarTextures.solid)
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
  local iconTexture = texture or (State.focusCastbarPreviewMode and 136116) or nil
  if showIcon and iconTexture then
    PixelUtil.SetSize(frame.icon, iconSize, iconSize)
    frame.icon.texture:SetTexture(iconTexture)
    frame.icon:ClearAllPoints()
    PixelUtil.SetPoint(frame.icon, "RIGHT", frame, "LEFT", 0, 0)
    frame.icon:Show()
  else
    frame.icon:Hide()
  end
  local iconShown = showIcon and iconTexture
  if borderSize > 0 then
    frame.border:ClearAllPoints()
    if iconShown then
      frame.border:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -borderSize, borderSize)
      frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderSize, -borderSize)
    else
      frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderSize, borderSize)
      frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderSize, -borderSize)
    end
    frame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize, insets = {left = borderSize, right = borderSize, top = borderSize, bottom = borderSize}})
    frame.border:SetBackdropBorderColor(0, 0, 0, 1)
    frame.border:Show()
  else
    frame.border:Hide()
  end
  local globalFont, globalOutline = GetGlobalFont()
  local fk = frame._textStyleCache
  local styleChanged = not fk
    or fk.sn ~= showSpellName or fk.st ~= showTime
    or fk.sns ~= spellNameScale or fk.snx ~= spellNameX or fk.sny ~= spellNameY
    or fk.ts ~= timeScale or fk.tx ~= timeX or fk.ty ~= timeY
    or fk.tr ~= textR or fk.tg ~= textG or fk.tb ~= textB
    or fk.gf ~= globalFont or fk.go ~= globalOutline
  if styleChanged then
    if not fk then frame._textStyleCache = {} end
    fk = frame._textStyleCache
    fk.sn=showSpellName; fk.st=showTime; fk.sns=spellNameScale; fk.snx=spellNameX; fk.sny=spellNameY
    fk.ts=timeScale; fk.tx=timeX; fk.ty=timeY; fk.tr=textR; fk.tg=textG; fk.tb=textB
    fk.gf=globalFont; fk.go=globalOutline
    frame.spellText:ClearAllPoints()
    frame.spellText:SetPoint("LEFT", frame, "LEFT", 5 + spellNameX, spellNameY)
    frame.spellText:SetTextColor(textR, textG, textB)
    frame.spellText:SetScale(spellNameScale)
    frame.spellText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
    frame.timeText:ClearAllPoints()
    frame.timeText:SetPoint("RIGHT", frame, "RIGHT", -5 + timeX, timeY)
    frame.timeText:SetTextColor(textR, textG, textB)
    frame.timeText:SetScale(timeScale)
    frame.timeText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
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
      local numTicks
      if isChanneling and showTicks and spellID then
        local okTick, tickVal = pcall(function() return channelTickData[spellID] end)
        if okTick then numTicks = tickVal end
      end
      if numTicks then
        local barWidth = frame:GetWidth()
        local barHeight = frame:GetHeight()
        local ftk = State.focusCastbarTickCache
        local fTickChanged = not ftk or ftk.n ~= numTicks or ftk.w ~= barWidth or ftk.h ~= barHeight
        if fTickChanged then
          if not ftk then State.focusCastbarTickCache = {} end
          ftk = State.focusCastbarTickCache
          ftk.n=numTicks; ftk.w=barWidth; ftk.h=barHeight
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
        State.focusCastbarTickCache = nil
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
    local numTicks
    if isChanneling and showTicks and spellID then
      local okTick, tickVal = pcall(function() return channelTickData[spellID] end)
      if okTick then numTicks = tickVal end
    end
    if numTicks then
      local barWidth = frame:GetWidth()
      local barHeight = frame:GetHeight()
      local ftk = State.focusCastbarTickCache
      local fTickChanged = not ftk or ftk.n ~= numTicks or ftk.w ~= barWidth or ftk.h ~= barHeight
      if fTickChanged then
        if not ftk then State.focusCastbarTickCache = {} end
        ftk = State.focusCastbarTickCache
        ftk.n=numTicks; ftk.w=barWidth; ftk.h=barHeight
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
      State.focusCastbarTickCache = nil
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
  State.focusCastbarTickCache = nil
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
  State.focusCastbarTickCache = nil
  if addonTable.FocusCastbarFrame then
    for i = 1, 10 do addonTable.FocusCastbarFrame.ticks[i]:Hide() end
  end
  local castName = UnitCastingInfo("focus")
  if not castName then castName = UnitChannelInfo("focus") end
  if not castName and addonTable.FocusCastbarFrame then
    addonTable.FocusCastbarFrame:Hide()
  end
end
