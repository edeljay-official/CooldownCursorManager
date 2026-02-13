--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_tcastbar.lua
-- Target castbar customization and updates
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, addonTable = ...
local State = addonTable.State
local GetGlobalFont = addonTable.GetGlobalFont
local FitTextToBar = addonTable.FitTextToBar
local castbarTextures = addonTable.castbarTextures
local channelTickData = addonTable.channelTickData
addonTable.TargetCastbarFrame = CreateFrame("Frame", "CCMTargetCastbar", UIParent, "BackdropTemplate")
addonTable.TargetCastbarFrame:SetSize(250, 20)
addonTable.TargetCastbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
addonTable.TargetCastbarFrame:SetFrameStrata("MEDIUM")
addonTable.TargetCastbarFrame:SetClampedToScreen(true)
addonTable.TargetCastbarFrame:SetMovable(false)
addonTable.TargetCastbarFrame:EnableMouse(true)
addonTable.TargetCastbarFrame:RegisterForDrag("LeftButton")
addonTable.TargetCastbarFrame:Hide()
addonTable.TargetCastbarFrame.bar = CreateFrame("StatusBar", nil, addonTable.TargetCastbarFrame)
addonTable.TargetCastbarFrame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
addonTable.TargetCastbarFrame.bar:SetStatusBarColor(1, 0.7, 0)
addonTable.TargetCastbarFrame.bar:SetAllPoints()
addonTable.TargetCastbarFrame.bg = addonTable.TargetCastbarFrame.bar:CreateTexture(nil, "BACKGROUND")
addonTable.TargetCastbarFrame.bg:SetAllPoints()
addonTable.TargetCastbarFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
addonTable.TargetCastbarFrame.textOverlay = CreateFrame("Frame", nil, addonTable.TargetCastbarFrame)
addonTable.TargetCastbarFrame.textOverlay:SetAllPoints()
addonTable.TargetCastbarFrame.textOverlay:SetFrameLevel(addonTable.TargetCastbarFrame:GetFrameLevel() + 10)
addonTable.TargetCastbarFrame.spellText = addonTable.TargetCastbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addonTable.TargetCastbarFrame.spellText:SetPoint("LEFT", addonTable.TargetCastbarFrame, "LEFT", 5, 0)
addonTable.TargetCastbarFrame.timeText = addonTable.TargetCastbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addonTable.TargetCastbarFrame.timeText:SetPoint("RIGHT", addonTable.TargetCastbarFrame, "RIGHT", -5, 0)
addonTable.TargetCastbarFrame.icon = CreateFrame("Frame", nil, addonTable.TargetCastbarFrame)
addonTable.TargetCastbarFrame.icon:SetSize(24, 24)
addonTable.TargetCastbarFrame.icon:SetPoint("RIGHT", addonTable.TargetCastbarFrame, "LEFT", -4, 0)
addonTable.TargetCastbarFrame.icon.texture = addonTable.TargetCastbarFrame.icon:CreateTexture(nil, "ARTWORK")
addonTable.TargetCastbarFrame.icon.texture:SetAllPoints()
addonTable.TargetCastbarFrame.icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
addonTable.TargetCastbarFrame.border = CreateFrame("Frame", nil, addonTable.TargetCastbarFrame, "BackdropTemplate")
addonTable.TargetCastbarFrame.border:SetFrameLevel(addonTable.TargetCastbarFrame:GetFrameLevel() + 20)
addonTable.TargetCastbarFrame.border:SetAllPoints()
addonTable.TargetCastbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
addonTable.TargetCastbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
addonTable.TargetCastbarFrame.ticks = {}
for i = 1, 10 do
  local tick = addonTable.TargetCastbarFrame.bar:CreateTexture(nil, "OVERLAY")
  tick:SetColorTexture(1, 1, 1, 0.7)
  tick:SetSize(2, 1)
  tick:Hide()
  addonTable.TargetCastbarFrame.ticks[i] = tick
end
addonTable.TargetCastbarFrame:SetScript("OnDragStart", function(self)
  if not addonTable.GetGUIOpen or not addonTable.GetGUIOpen() then return end
  self:StartMoving()
  State.targetCastbarDragging = true
end)
addonTable.TargetCastbarFrame:SetScript("OnDragStop", function(self)
  if not State.targetCastbarDragging then return end
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    local _, _, _, newX, newY = self:GetPoint(1)
    profile.targetCastbarX = newX
    profile.targetCastbarY = newY
    if addonTable.UpdateTargetCastbarSliders then addonTable.UpdateTargetCastbarSliders(newX, newY) end
  end
  State.targetCastbarDragging = false
end)
addonTable.TargetCastbarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.targetCastbarDragging then
    self:StopMovingOrSizing()
    State.targetCastbarDragging = false
  end
end)
local function SetBlizzardTargetCastbarVisibility(show)
  if TargetFrameSpellBar then
    if show then
      TargetFrameSpellBar:SetAlpha(1)
      TargetFrameSpellBar:Show()
      if TargetFrameSpellBar.Border then TargetFrameSpellBar.Border:Show() end
      if TargetFrameSpellBar.Text then TargetFrameSpellBar.Text:Show() end
      if TargetFrameSpellBar.TextBorder then TargetFrameSpellBar.TextBorder:Show() end
    else
      TargetFrameSpellBar:SetAlpha(0)
      if TargetFrameSpellBar.Border then TargetFrameSpellBar.Border:Hide() end
      if TargetFrameSpellBar.Text then TargetFrameSpellBar.Text:Hide() end
      if TargetFrameSpellBar.TextBorder then TargetFrameSpellBar.TextBorder:Hide() end
      TargetFrameSpellBar:Hide()
    end
  end
  if TargetCastingBarFrame then
    if show then
      TargetCastingBarFrame:SetAlpha(1)
      TargetCastingBarFrame:Show()
    else
      TargetCastingBarFrame:SetAlpha(0)
      TargetCastingBarFrame:Hide()
    end
  end
end
addonTable.SetBlizzardTargetCastbarVisibility = SetBlizzardTargetCastbarVisibility
local function ShouldHideDefaultTargetCastbar()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  return profile and profile.useTargetCastbar == true
end
if TargetFrameSpellBar and not TargetFrameSpellBar._ccmHideHooked then
  TargetFrameSpellBar:HookScript("OnShow", function(self)
    if ShouldHideDefaultTargetCastbar() then
      self:SetAlpha(0)
      if self.Border then self.Border:Hide() end
      if self.Text then self.Text:Hide() end
      if self.TextBorder then self.TextBorder:Hide() end
      self:Hide()
    end
  end)
  TargetFrameSpellBar._ccmHideHooked = true
end
if TargetCastingBarFrame and not TargetCastingBarFrame._ccmHideHooked then
  TargetCastingBarFrame:HookScript("OnShow", function(self)
    if ShouldHideDefaultTargetCastbar() then
      self:SetAlpha(0)
      self:Hide()
    end
  end)
  TargetCastingBarFrame._ccmHideHooked = true
end
addonTable.UpdateTargetCastbar = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local frame = addonTable.TargetCastbarFrame
  if not frame then return end
  if not profile or not profile.useTargetCastbar then
    frame:Hide()
    State.targetCastbarActive = false
    SetBlizzardTargetCastbarVisibility(true)
    return
  end
  SetBlizzardTargetCastbarVisibility(false)
  local name, text, texture, startTimeMS, endTimeMS, _, _, _, spellID = UnitCastingInfo("target")
  local isChanneling = false
  if not name then
    name, text, texture, startTimeMS, endTimeMS, _, _, spellID = UnitChannelInfo("target")
    isChanneling = name ~= nil
  end
  if name and addonTable.StartTargetCastbarTicker then
    addonTable.StartTargetCastbarTicker()
  end
  if not name and not State.targetCastbarPreviewMode then
    frame:Hide()
    State.targetCastbarActive = false
    State.targetCastbarTickCache = nil
    frame._fallbackSpellID = nil
    frame._fallbackChanneling = nil
    frame._fallbackStart = nil
    frame._fallbackDuration = nil
    return
  end
  local width = type(profile.targetCastbarWidth) == "number" and profile.targetCastbarWidth or 250
  local borderSize = type(profile.targetCastbarBorderSize) == "number" and profile.targetCastbarBorderSize or 1
  width = math.max(20, math.floor(width))
  local height = type(profile.targetCastbarHeight) == "number" and profile.targetCastbarHeight or 20
  local showIcon = profile.targetCastbarShowIcon ~= false
  local iconSize = height
  local posX = type(profile.targetCastbarX) == "number" and profile.targetCastbarX or 0
  local posY = type(profile.targetCastbarY) == "number" and profile.targetCastbarY or -250
  if profile.targetCastbarCentered then
    posX = showIcon and (iconSize / 2) or 0
  end
  local bgAlpha = (type(profile.targetCastbarBgAlpha) == "number" and profile.targetCastbarBgAlpha or 70) / 100
  local showTime = profile.targetCastbarShowTime ~= false
  local showSpellName = profile.targetCastbarShowSpellName ~= false
  local timeScale = type(profile.targetCastbarTimeScale) == "number" and profile.targetCastbarTimeScale or 1.0
  local spellNameScale = type(profile.targetCastbarSpellNameScale) == "number" and profile.targetCastbarSpellNameScale or 1.0
  local spellNameX = type(profile.targetCastbarSpellNameXOffset) == "number" and profile.targetCastbarSpellNameXOffset or 0
  local spellNameY = type(profile.targetCastbarSpellNameYOffset) == "number" and profile.targetCastbarSpellNameYOffset or 0
  local timeX = type(profile.targetCastbarTimeXOffset) == "number" and profile.targetCastbarTimeXOffset or 0
  local timeY = type(profile.targetCastbarTimeYOffset) == "number" and profile.targetCastbarTimeYOffset or 0
  local timePrecision = profile.targetCastbarTimePrecision or "1"
  local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
  local function FormatTargetTimeValue(rawValue)
    local num = tonumber(rawValue)
    if num then return string.format(timeFormat, num) end
    return tostring(rawValue or "")
  end
  local textR = profile.targetCastbarTextColorR or 1
  local textG = profile.targetCastbarTextColorG or 1
  local textB = profile.targetCastbarTextColorB or 1
  frame.bar:SetStatusBarTexture(addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(profile.targetCastbarTexture) or castbarTextures[profile.targetCastbarTexture] or castbarTextures.solid)
  local r = profile.targetCastbarColorR or 1
  local g = profile.targetCastbarColorG or 0.7
  local b = profile.targetCastbarColorB or 0
  frame.bar:SetStatusBarColor(r, g, b)
  PixelUtil.SetSize(frame, width, height)
  if not State.targetCastbarDragging then
    frame:ClearAllPoints()
    PixelUtil.SetPoint(frame, "CENTER", UIParent, "CENTER", posX, posY)
  end
  frame.bg:SetColorTexture(profile.targetCastbarBgColorR or 0.1, profile.targetCastbarBgColorG or 0.1, profile.targetCastbarBgColorB or 0.1, bgAlpha)
  local iconTexture = texture or (State.targetCastbarPreviewMode and 136116) or nil
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
    frame.spellText:SetText(name or "Target Cast")
    frame.spellText:Show()
  else
    frame.spellText:Hide()
  end
  local durationObject = nil
  if name then
    if isChanneling and UnitChannelDuration then
      local okDur, durObj = pcall(UnitChannelDuration, "target")
      if okDur then durationObject = durObj end
    elseif UnitCastingDuration then
      local okDur, durObj = pcall(UnitCastingDuration, "target")
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
        local timeDirection = profile.targetCastbarTimeDirection or "remaining"
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
          frame.timeText:SetText(FormatTargetTimeValue(timeValue))
          frame.timeText:Show()
        else
          frame.timeText:Hide()
        end
      else
        frame.timeText:Hide()
      end
      local showTicks = profile.targetCastbarShowTicks ~= false
      local numTicks
      if isChanneling and showTicks and spellID then
        local okTick, tickVal = pcall(function() return channelTickData[spellID] end)
        if okTick then numTicks = tickVal end
      end
      if numTicks then
        local barWidth = frame:GetWidth()
        local barHeight = frame:GetHeight()
        local ftk = State.targetCastbarTickCache
        local fTickChanged = not ftk or ftk.n ~= numTicks or ftk.w ~= barWidth or ftk.h ~= barHeight
        if fTickChanged then
          if not ftk then State.targetCastbarTickCache = {} end
          ftk = State.targetCastbarTickCache
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
        State.targetCastbarTickCache = nil
        for i = 1, 10 do frame.ticks[i]:Hide() end
      end
      frame:Show()
      State.targetCastbarActive = true
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
        local timeDirection = profile.targetCastbarTimeDirection or "remaining"
        local timeValue = timeDirection == "elapsed" and elapsedFromBar or remaining
        frame.timeText:SetText(FormatTargetTimeValue(timeValue))
        frame.timeText:Show()
      else
        frame.timeText:Hide()
      end
      frame:Show()
      State.targetCastbarActive = true
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
      local timeDirection = profile.targetCastbarTimeDirection or "remaining"
      local timeValue = timeDirection == "elapsed" and elapsedFromBar or remaining
      frame.timeText:SetText(FormatTargetTimeValue(timeValue))
      frame.timeText:Show()
    else
      frame.timeText:Hide()
    end
    local showTicks = profile.targetCastbarShowTicks ~= false
    local numTicks
    if isChanneling and showTicks and spellID then
      local okTick, tickVal = pcall(function() return channelTickData[spellID] end)
      if okTick then numTicks = tickVal end
    end
    if numTicks then
      local barWidth = frame:GetWidth()
      local barHeight = frame:GetHeight()
      local ftk = State.targetCastbarTickCache
      local fTickChanged = not ftk or ftk.n ~= numTicks or ftk.w ~= barWidth or ftk.h ~= barHeight
      if fTickChanged then
        if not ftk then State.targetCastbarTickCache = {} end
        ftk = State.targetCastbarTickCache
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
      State.targetCastbarTickCache = nil
      for i = 1, 10 do frame.ticks[i]:Hide() end
    end
  else
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(0.65)
    if showTime then
      frame.timeText:SetText(FormatTargetTimeValue(1.5))
      frame.timeText:Show()
    else
      frame.timeText:Hide()
    end
    for i = 1, 10 do frame.ticks[i]:Hide() end
  end
  State.targetCastbarActive = true
  frame:Show()
end
addonTable.StartTargetCastbarTicker = function()
  if State.targetCastbarTicker then return end
  SetBlizzardTargetCastbarVisibility(false)
  State.targetCastbarTicker = C_Timer.NewTicker(0.02, addonTable.UpdateTargetCastbar)
end
addonTable.StopTargetCastbarTicker = function()
  local castName = UnitCastingInfo("target")
  if not castName then castName = UnitChannelInfo("target") end
  if castName then return end
  if State.targetCastbarTicker then
    State.targetCastbarTicker:Cancel()
    State.targetCastbarTicker = nil
  end
  State.targetCastbarActive = false
  State.targetCastbarTickCache = nil
  if not State.targetCastbarPreviewMode and addonTable.TargetCastbarFrame then
    addonTable.TargetCastbarFrame:Hide()
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useTargetCastbar then
    SetBlizzardTargetCastbarVisibility(true)
  end
end
local targetCastbarEventFrame = CreateFrame("Frame")
addonTable.SetupTargetCastbarEvents = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useTargetCastbar then
    targetCastbarEventFrame:UnregisterAllEvents()
    return
  end
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "target")
  targetCastbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "target")
end
targetCastbarEventFrame:SetScript("OnEvent", function(_, event)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useTargetCastbar then return end
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
    addonTable.StartTargetCastbarTicker()
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
    C_Timer.After(0.05, function()
      local castName = UnitCastingInfo("target")
      if not castName then castName = UnitChannelInfo("target") end
      if not castName then addonTable.StopTargetCastbarTicker() end
    end)
  end
end)
addonTable.ShowTargetCastbarPreview = function()
  State.targetCastbarPreviewMode = true
  addonTable.UpdateTargetCastbar()
end
addonTable.StopTargetCastbarPreview = function()
  State.targetCastbarPreviewMode = false
  State.targetCastbarTickCache = nil
  if addonTable.TargetCastbarFrame then
    for i = 1, 10 do addonTable.TargetCastbarFrame.ticks[i]:Hide() end
  end
  local castName = UnitCastingInfo("target")
  if not castName then castName = UnitChannelInfo("target") end
  if not castName and addonTable.TargetCastbarFrame then
    addonTable.TargetCastbarFrame:Hide()
  end
end
