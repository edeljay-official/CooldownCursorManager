local _, addonTable = ...
local State = addonTable.State
local GetGlobalFont = addonTable.GetGlobalFont
local selfHighlightFrame = CreateFrame("Frame", "CCMSelfHighlight", UIParent)
selfHighlightFrame:SetSize(40, 40)
selfHighlightFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
selfHighlightFrame:SetFrameStrata("TOOLTIP")
selfHighlightFrame:SetFrameLevel(1000)
selfHighlightFrame:Hide()
local function SnapToPixel(v)
  if addonTable.SnapToPixel then return addonTable:SnapToPixel(v, UIParent) end
  local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
  if scale == 0 then scale = 1 end
  local pixel = 1 / scale
  return math.floor((v / pixel) + 0.5) * pixel
end
local function SnapSize(v, minPixels)
  if addonTable.SnapSize then return addonTable:SnapSize(v, UIParent, minPixels) end
  local snapped = SnapToPixel(v)
  local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
  if scale == 0 then scale = 1 end
  local pixel = 1 / scale
  local minSize = pixel * ((type(minPixels) == "number" and minPixels > 0) and minPixels or 1)
  if snapped < minSize then snapped = minSize end
  return snapped
end
local function SetPointSnapped(frame, point, relativeTo, relativePoint, xOfs, yOfs)
  local sx = SnapToPixel(xOfs or 0)
  local sy = SnapToPixel(yOfs or 0)
  if PixelUtil and PixelUtil.SetPoint then
    PixelUtil.SetPoint(frame, point, relativeTo, relativePoint, sx, sy)
  else
    frame:SetPoint(point, relativeTo, relativePoint, sx, sy)
  end
end
selfHighlightFrame.lines = {}
for i = 1, 4 do
  local tex = selfHighlightFrame:CreateTexture(nil, "OVERLAY")
  tex:SetTexture("Interface\\Buttons\\WHITE8X8")
  if tex.SetSnapToPixelGrid then tex:SetSnapToPixelGrid(true) end
  if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0) end
  tex:SetColorTexture(1, 1, 1, 1)
  selfHighlightFrame.lines[i] = tex
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
  size = SnapSize(size, 2)
  yOffset = SnapToPixel(yOffset)
  selfHighlightFrame:SetSize(size, size)
  selfHighlightFrame:ClearAllPoints()
  SetPointSnapped(selfHighlightFrame, "CENTER", UIParent, "CENTER", 0, yOffset)
  if shape == "cross" then
    local lineThickness = thickness == "thin" and 2 or (thickness == "thick" and 6 or 3)
    lineThickness = SnapSize(lineThickness, 1)
    local horizontal = selfHighlightFrame.lines[1]
    local vertical = selfHighlightFrame.lines[2]
    local outlineH = selfHighlightFrame.lines[3]
    local outlineV = selfHighlightFrame.lines[4]
    horizontal:ClearAllPoints()
    vertical:ClearAllPoints()
    outlineH:ClearAllPoints()
    outlineV:ClearAllPoints()
    if outline then
      local outlineThickness = SnapSize(lineThickness + 2, 1)
      outlineH:SetPoint("CENTER", selfHighlightFrame, "CENTER", 0, 0)
      outlineH:SetSize(size, outlineThickness)
      outlineH:SetColorTexture(0, 0, 0, a)
      outlineH:SetDrawLayer("OVERLAY", 0)
      outlineH:Show()
      outlineV:SetPoint("CENTER", selfHighlightFrame, "CENTER", 0, 0)
      outlineV:SetSize(outlineThickness, size)
      outlineV:SetColorTexture(0, 0, 0, a)
      outlineV:SetDrawLayer("OVERLAY", 0)
      outlineV:Show()
    else
      outlineH:Hide()
      outlineV:Hide()
    end
    horizontal:SetPoint("CENTER", selfHighlightFrame, "CENTER", 0, 0)
    horizontal:SetSize(size, lineThickness)
    horizontal:SetColorTexture(r, g, b, a)
    horizontal:SetDrawLayer("OVERLAY", 1)
    horizontal:Show()
    vertical:SetPoint("CENTER", selfHighlightFrame, "CENTER", 0, 0)
    vertical:SetSize(lineThickness, size)
    vertical:SetColorTexture(r, g, b, a)
    vertical:SetDrawLayer("OVERLAY", 1)
    vertical:Show()
    selfHighlightFrame:Show()
  end
end
addonTable.UpdateSelfHighlight = UpdateSelfHighlight
local function StartSelfHighlightTicker()
  if State.selfHighlightTicker then return end
  State.selfHighlightTicker = C_Timer.NewTicker(0.1, function()
    if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
  end)
end
local function StopSelfHighlightTicker()
  if State.selfHighlightTicker then
    State.selfHighlightTicker:Cancel()
    State.selfHighlightTicker = nil
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
  local qolTab = addonTable.TAB_QOL or 12
  if not guiOpen or activeTab ~= qolTab then return end
  self:StartMoving()
end)
addonTable.CombatTimerFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local scale = self:GetScale() or 1
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local rx = centerX * scale - parentCenterX
    local ry = centerY * scale - parentCenterY
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
  frame:SetSize(128, 44)
  if style == "minimal" then
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", 34, "OUTLINE")
    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER")
  else
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
  frame:SetScale(scale)
  frame:SetPoint("CENTER", UIParent, "CENTER", (centered and 0 or x) / scale, y / scale)
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
  if shouldShow or draggable then
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
  State.combatTimerTicker = C_Timer.NewTicker(0.1, function()
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
  local qolTab = addonTable.TAB_QOL or 12
  if not guiOpen or activeTab ~= qolTab then return end
  self:StartMoving()
end)
addonTable.crTimerFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local scale = self:GetScale() or 1
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local rx = centerX * scale - parentCenterX
    local ry = centerY * scale - parentCenterY
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
  local qolTab = addonTable.TAB_QOL or 12
  if not guiOpen or activeTab ~= qolTab then return end
  self:StartMoving()
end)
addonTable.CombatStatusFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local scale = self:GetScale() or 1
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local rx = centerX * scale - parentCenterX
    local ry = centerY * scale - parentCenterY
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
  local csScale = type(profile.combatStatusScale) == "number" and profile.combatStatusScale or 1
  frame:ClearAllPoints()
  frame:SetScale(csScale)
  local csX = profile.combatStatusCentered == true and 0 or (profile.combatStatusX or 0)
  local csY = profile.combatStatusY or 280
  frame:SetPoint("CENTER", UIParent, "CENTER", csX / csScale, csY / csScale)
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
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local displayMode = profile and profile.crTimerDisplay or "timer"
  local isVertical = (profile and profile.crTimerLayout ~= "horizontal")
  if displayMode == "count" then
    frame.crText:SetText(string.format("CR: |cffFFFFFF%d|r", charges))
    if frame.blText then frame.blText:Hide() end
  elseif isVertical and frame.blText then
    frame.crText:SetText(string.format("CR: |cffFFFFFF%d|r", charges))
    frame.blText:SetText(string.format("|cffFFFFFF%s|r", crTimeText))
    frame.blText:Show()
  else
    frame.crText:SetText(string.format("CR: |cffFFFFFF%d|r / |cffFFFFFF%s|r", charges, crTimeText))
    if frame.blText then frame.blText:Hide() end
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
  local qolTab = addonTable.TAB_QOL or 11
  local draggable = (addonTable.GetGUIOpen and addonTable.GetGUIOpen()) and (addonTable.activeTab and addonTable.activeTab() == qolTab)
  local mode = profile.crTimerMode == "always" and "always" or "combat"
  local shouldShow = (mode == "always") or UnitAffectingCombat("player")
  if not shouldShow and not draggable then
    frame:Hide()
    if addonTable.StopCRTimerTicker then addonTable.StopCRTimerTicker() end
    return
  end
  local scale = type(profile.crTimerScale) == "number" and profile.crTimerScale or 1
  frame:ClearAllPoints()
  frame:SetScale(scale)
  local centered = profile.crTimerCentered == true
  local ox = centered and 0 or (profile.crTimerX or 0)
  local oy = profile.crTimerY or 150
  frame:SetPoint("CENTER", UIParent, "CENTER", ox / scale, oy / scale)
  local displayMode = profile.crTimerDisplay or "timer"
  local vertical = (displayMode ~= "count") and (profile.crTimerLayout ~= "horizontal")
  frame.crText:ClearAllPoints()
  if frame.blText then
    frame.blText:ClearAllPoints()
    frame.blText:Hide()
  end
  if displayMode == "count" then
    frame.crText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame:SetSize(120, 26)
  elseif vertical then
    frame.crText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    if frame.blText then
      frame.blText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -22)
    end
    frame:SetSize(140, 48)
  else
    frame.crText:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame:SetSize(190, 26)
  end
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
  noTargetAlertFrame.text:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
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
  noTargetAlertFrame.text:SetFont(globalFont, fontSize, globalOutline or "OUTLINE")
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
local actionBarHideFrame = CreateFrame("Frame", "CCMActionBarHideFrame", UIParent)
actionBarHideFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
actionBarHideFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
actionBarHideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
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
local AB_BAR_FRAMES = {
  [2] = "MultiBarBottomLeft", [3] = "MultiBarBottomRight",
  [4] = "MultiBarRight", [5] = "MultiBarLeft",
  [6] = "MultiBar5", [7] = "MultiBar6", [8] = "MultiBar7",
}
local function SetABAlpha(barNum, alpha)
  local name = AB_BAR_FRAMES[barNum]
  if name then local bar = _G[name]; if bar and bar.SetAlpha then bar:SetAlpha(alpha) end end
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
local function IsMouseOverABBar(barNum)
  local name = AB_BAR_FRAMES[barNum]
  if not name then return false end
  local bar = _G[name]
  if bar and bar:IsShown() and bar:IsMouseOver() then return true end
  local df = ab2to8DetectionFrames[name]
  if df and df:IsShown() and df:IsMouseOver() then return true end
  return false
end
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
    local ab1Always = profile.hideActionBar1Always == true
    local stanceAlways = profile.hideStanceBarAlways == true
    local petAlways = profile.hidePetBarAlways == true
    local anyABAlways = false
    for n = 2, 8 do if profile["hideAB"..n.."Always"] then anyABAlways = true; break end end
    local anyAlways = ab1Always or anyABAlways or stanceAlways or petAlways
    local inCombat = InCombatLockdown()
    if not inCombat then
      if State.actionBar1Hidden and not ab1Always then
        SetActionBar1Alpha(1); State.actionBar1Hidden = false
      end
      for n = 2, 8 do
        if State["actionBar"..n.."Hidden"] and not (profile["hideAB"..n.."Always"] == true) then
          SetABAlpha(n, 1); State["actionBar"..n.."Hidden"] = false
        end
      end
      if State.stanceBarHidden and not stanceAlways then
        SetStanceBarAlpha(1); State.stanceBarHidden = false
      end
      if State.petBarHidden and not petAlways then
        SetPetBarAlpha(1); State.petBarHidden = false
      end
      if not anyAlways then return end
    end
    local mouseOverAB1 = false
    local mouseOverAB = {}
    local mouseOverStance = false
    local mouseOverPet = false
    local ab1Mouseover = profile.hideActionBar1Mouseover == true
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
        mouseOverCCMFrames = true; break
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
    if not mouseOverCCMFrames then
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
        local anyABMouseOver = false
        for n = 2, 8 do
          if IsMouseOverABBar(n) then
            mouseOverAB[n] = true; anyABMouseOver = true
          end
        end
        if not anyABMouseOver then
          for _, btn in ipairs(GetActionButtons()) do
            if btn and btn:IsShown() and btn:IsMouseOver() then
              mouseOverAB1 = true; break
            end
          end
        end
        if not mouseOverAB1 and ab1MouseoverFrame and ab1MouseoverFrame:IsMouseOver() then
          mouseOverAB1 = true
        end
        for _, btn in ipairs(GetStanceButtons()) do
          if btn and btn:IsShown() and btn:IsMouseOver() then
            mouseOverStance = true; break
          end
        end
        for _, f in ipairs(GetStanceBarFrames()) do
          if f and f:IsShown() and f:IsMouseOver() then
            mouseOverStance = true; break
          end
        end
        if not mouseOverStance and stanceMouseoverFrame and stanceMouseoverFrame:IsMouseOver() then
          mouseOverStance = true
        end
        for _, btn in ipairs(GetPetButtons()) do
          if btn and btn:IsShown() and btn:IsMouseOver() then
            mouseOverPet = true; break
          end
        end
        if not mouseOverPet then
          for _, f in ipairs(GetPetBarFrames()) do
            if f and f:IsShown() and f:IsMouseOver() then
              mouseOverPet = true; break
            end
          end
        end
      end
    end
    local ab1ShouldHide = (inCombat and profile.hideActionBar1InCombat) or ab1Always
    local stanceShouldHide = (inCombat and profile.hideStanceBarInCombat) or stanceAlways
    local petShouldHide = (inCombat and profile.hidePetBarInCombat) or petAlways
    local mouseOverAnyHiddenBar = false
    if ab1ShouldHide and ab1Mouseover and mouseOverAB1 then mouseOverAnyHiddenBar = true end
    for n = 2, 8 do
      local abAlways = profile["hideAB"..n.."Always"] == true
      local abShouldHide = (inCombat and profile["hideAB"..n.."InCombat"]) or abAlways
      local abMouseover = profile["hideAB"..n.."Mouseover"] == true
      if abShouldHide and abMouseover and mouseOverAB[n] then mouseOverAnyHiddenBar = true end
    end
    if stanceShouldHide and stanceMouseover and mouseOverStance then mouseOverAnyHiddenBar = true end
    if petShouldHide and petMouseover and mouseOverPet then mouseOverAnyHiddenBar = true end
    local ab1HiddenByBlizz = false
    local stanceHiddenByBlizz = false
    local petHiddenByBlizz = false
    local mainBar = _G["MainMenuBar"]
    if mainBar and (not mainBar:IsShown() or mainBar:GetAlpha() < 0.1) then
      ab1HiddenByBlizz = true
    end
    if ab1Mouseover and mouseOverAB1 and ab1HiddenByBlizz then mouseOverAnyHiddenBar = true end
    for n = 2, 8 do
      local name = AB_BAR_FRAMES[n]
      local bar = _G[name]
      local abMouseover = profile["hideAB"..n.."Mouseover"] == true
      local hiddenByBlizz = bar and (not bar:IsShown() or bar:GetAlpha() < 0.1)
      if abMouseover and mouseOverAB[n] and hiddenByBlizz then mouseOverAnyHiddenBar = true end
    end
    local stanceBar = _G["StanceBar"]
    if stanceBar and (not stanceBar:IsShown() or stanceBar:GetAlpha() < 0.1) then
      stanceHiddenByBlizz = true
    end
    local petBar = _G["PetActionBarFrame"] or _G["PetActionBar"]
    if petBar and (not petBar:IsShown() or petBar:GetAlpha() < 0.1) then
      petHiddenByBlizz = true
    end
    if stanceMouseover and mouseOverStance and stanceHiddenByBlizz then mouseOverAnyHiddenBar = true end
    if petMouseover and mouseOverPet and petHiddenByBlizz then mouseOverAnyHiddenBar = true end
    if ab1ShouldHide or ab1HiddenByBlizz then
      if mouseOverAnyHiddenBar then
        if State.actionBar1Hidden or ab1HiddenByBlizz then
          SetActionBar1Alpha(1); State.actionBar1Hidden = false
        end
      else
        if ab1ShouldHide and not State.actionBar1Hidden then
          SetActionBar1Alpha(0); State.actionBar1Hidden = true
        end
      end
    end
    for n = 2, 8 do
      local name = AB_BAR_FRAMES[n]
      local bar = _G[name]
      local abAlways = profile["hideAB"..n.."Always"] == true
      local abShouldHide = (inCombat and profile["hideAB"..n.."InCombat"]) or abAlways
      local hiddenByBlizz = bar and (not bar:IsShown() or bar:GetAlpha() < 0.1)
      if abShouldHide or hiddenByBlizz then
        if mouseOverAnyHiddenBar then
          if State["actionBar"..n.."Hidden"] or hiddenByBlizz then
            SetABAlpha(n, 1); State["actionBar"..n.."Hidden"] = false
          end
        else
          if abShouldHide and not State["actionBar"..n.."Hidden"] then
            SetABAlpha(n, 0); State["actionBar"..n.."Hidden"] = true
          end
        end
      end
    end
    if stanceShouldHide or stanceHiddenByBlizz then
      if mouseOverAnyHiddenBar then
        if State.stanceBarHidden or stanceHiddenByBlizz then
          SetStanceBarAlpha(1); State.stanceBarHidden = false
        end
      else
        if stanceShouldHide and not State.stanceBarHidden then
          SetStanceBarAlpha(0); State.stanceBarHidden = true
        end
      end
    end
    if petShouldHide or petHiddenByBlizz then
      if mouseOverAnyHiddenBar then
        if State.petBarHidden or petHiddenByBlizz then
          SetPetBarAlpha(1); State.petBarHidden = false
        end
      else
        if petShouldHide and not State.petBarHidden then
          SetPetBarAlpha(0); State.petBarHidden = true
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
  if profile.hideActionBars2to8InCombat ~= nil or profile.hideActionBars2to8Mouseover ~= nil or profile.hideActionBars2to8Always ~= nil then
    for n = 2, 8 do
      if profile.hideActionBars2to8InCombat then profile["hideAB"..n.."InCombat"] = true end
      if profile.hideActionBars2to8Mouseover then profile["hideAB"..n.."Mouseover"] = true end
      if profile.hideActionBars2to8Always then profile["hideAB"..n.."Always"] = true end
    end
    profile.hideActionBars2to8InCombat = nil
    profile.hideActionBars2to8Mouseover = nil
    profile.hideActionBars2to8Always = nil
  end
  local hideAB1 = profile.hideActionBar1InCombat == true
  local hideStance = profile.hideStanceBarInCombat == true
  local hidePet = profile.hidePetBarInCombat == true
  local ab1Always = profile.hideActionBar1Always == true
  local stanceAlways = profile.hideStanceBarAlways == true
  local petAlways = profile.hidePetBarAlways == true
  local anyABHide, anyABAlways, anyABMouseover = false, false, false
  for n = 2, 8 do
    if profile["hideAB"..n.."InCombat"] then anyABHide = true end
    if profile["hideAB"..n.."Always"] then anyABAlways = true end
    if profile["hideAB"..n.."Mouseover"] then anyABMouseover = true end
  end
  local anyAlways = ab1Always or anyABAlways or stanceAlways or petAlways
  local anyMouseover = profile.hideActionBar1Mouseover or anyABMouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
  local anyHide = hideAB1 or anyABHide or hideStance or hidePet or anyAlways
  if anyHide or anyMouseover then
    if anyAlways or InCombatLockdown() then
      StartMouseCheck()
    end
    if ab1Always and not State.actionBar1Hidden then
      SetActionBar1Alpha(0); State.actionBar1Hidden = true
    end
    for n = 2, 8 do
      if profile["hideAB"..n.."Always"] and not State["actionBar"..n.."Hidden"] then
        SetABAlpha(n, 0); State["actionBar"..n.."Hidden"] = true
      end
    end
    if stanceAlways and not State.stanceBarHidden then
      SetStanceBarAlpha(0); State.stanceBarHidden = true
    end
    if petAlways and not State.petBarHidden then
      SetPetBarAlpha(0); State.petBarHidden = true
    end
    if InCombatLockdown() then
      if hideAB1 and not State.actionBar1Hidden then
        SetActionBar1Alpha(0); State.actionBar1Hidden = true
      end
      for n = 2, 8 do
        if profile["hideAB"..n.."InCombat"] and not State["actionBar"..n.."Hidden"] then
          SetABAlpha(n, 0); State["actionBar"..n.."Hidden"] = true
        end
      end
      if hideStance and not State.stanceBarHidden then
        SetStanceBarAlpha(0); State.stanceBarHidden = true
      end
      if hidePet and not State.petBarHidden then
        SetPetBarAlpha(0); State.petBarHidden = true
      end
    end
  else
    StopMouseCheck()
    if State.actionBar1Hidden then
      SetActionBar1Alpha(1); State.actionBar1Hidden = false
    end
    for n = 2, 8 do
      if State["actionBar"..n.."Hidden"] then
        SetABAlpha(n, 1); State["actionBar"..n.."Hidden"] = false
      end
    end
    if State.stanceBarHidden then
      SetStanceBarAlpha(1); State.stanceBarHidden = false
    end
    if State.petBarHidden then
      SetPetBarAlpha(1); State.petBarHidden = false
    end
  end
end
addonTable.SetupActionBarHiding = SetupActionBarHiding
local function UpdateActionBarVisibility()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local inCombat = InCombatLockdown()
  local ab1Always = profile.hideActionBar1Always == true
  local stanceAlways = profile.hideStanceBarAlways == true
  local petAlways = profile.hidePetBarAlways == true
  local ab1Hide = (inCombat and profile.hideActionBar1InCombat) or ab1Always
  local stanceHide = (inCombat and profile.hideStanceBarInCombat) or stanceAlways
  local petHide = (inCombat and profile.hidePetBarInCombat) or petAlways
  if ab1Hide then
    if not State.actionBar1Hidden then SetActionBar1Alpha(0); State.actionBar1Hidden = true end
  else
    if State.actionBar1Hidden then SetActionBar1Alpha(1); State.actionBar1Hidden = false end
  end
  local anyABHide = false
  local anyABAlways = false
  local anyABMouseover = false
  for n = 2, 8 do
    local abAlways = profile["hideAB"..n.."Always"] == true
    local abHide = (inCombat and profile["hideAB"..n.."InCombat"]) or abAlways
    if abHide then
      if not State["actionBar"..n.."Hidden"] then SetABAlpha(n, 0); State["actionBar"..n.."Hidden"] = true end
      anyABHide = true
    else
      if State["actionBar"..n.."Hidden"] then SetABAlpha(n, 1); State["actionBar"..n.."Hidden"] = false end
    end
    if abAlways then anyABAlways = true end
    if profile["hideAB"..n.."Mouseover"] then anyABMouseover = true end
  end
  if stanceHide then
    if not State.stanceBarHidden then SetStanceBarAlpha(0); State.stanceBarHidden = true end
  else
    if State.stanceBarHidden then SetStanceBarAlpha(1); State.stanceBarHidden = false end
  end
  if petHide then
    if not State.petBarHidden then SetPetBarAlpha(0); State.petBarHidden = true end
  else
    if State.petBarHidden then SetPetBarAlpha(1); State.petBarHidden = false end
  end
  local anyAlways = ab1Always or anyABAlways or stanceAlways or petAlways
  local anyHide = ab1Hide or anyABHide or stanceHide or petHide
  local anyMouseover = profile.hideActionBar1Mouseover or anyABMouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
  if anyHide or anyMouseover or anyAlways then
    StartMouseCheck()
  else
    StopMouseCheck()
  end
end
addonTable.UpdateActionBarVisibility = UpdateActionBarVisibility
actionBarHideFrame:SetScript("OnEvent", function(self, event)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if event == "PLAYER_REGEN_DISABLED" then
    if addonTable.HideBlizzBarPreviews then addonTable.HideBlizzBarPreviews() end
    if UpdateMouseoverDetectionFrames then UpdateMouseoverDetectionFrames() end
    local anyABHideInCombat = false
    local anyABMouseover = false
    for n = 2, 8 do
      if profile["hideAB"..n.."InCombat"] then anyABHideInCombat = true end
      if profile["hideAB"..n.."Mouseover"] then anyABMouseover = true end
    end
    local anyHideInCombat = profile.hideActionBar1InCombat or anyABHideInCombat or profile.hideStanceBarInCombat or profile.hidePetBarInCombat
    local anyMouseover = profile.hideActionBar1Mouseover or anyABMouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
    if anyHideInCombat or anyMouseover then
      StartMouseCheck()
    end
    if profile.hideActionBar1InCombat then
      SetActionBar1Alpha(0); State.actionBar1Hidden = true
    end
    for n = 2, 8 do
      if profile["hideAB"..n.."InCombat"] then
        SetABAlpha(n, 0); State["actionBar"..n.."Hidden"] = true
      end
    end
    if profile.hideStanceBarInCombat then
      SetStanceBarAlpha(0); State.stanceBarHidden = true
    end
    if profile.hidePetBarInCombat then
      SetPetBarAlpha(0); State.petBarHidden = true
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    local ab1Always = profile.hideActionBar1Always == true
    local stanceAlways = profile.hideStanceBarAlways == true
    local petAlways = profile.hidePetBarAlways == true
    local anyABAlways = false
    for n = 2, 8 do if profile["hideAB"..n.."Always"] then anyABAlways = true; break end end
    local anyAlways = ab1Always or anyABAlways or stanceAlways or petAlways
    if State.actionBar1Hidden and not ab1Always then
      SetActionBar1Alpha(1); State.actionBar1Hidden = false
    end
    for n = 2, 8 do
      if State["actionBar"..n.."Hidden"] and not (profile["hideAB"..n.."Always"] == true) then
        SetABAlpha(n, 1); State["actionBar"..n.."Hidden"] = false
      end
    end
    if State.stanceBarHidden and not stanceAlways then
      SetStanceBarAlpha(1); State.stanceBarHidden = false
    end
    if State.petBarHidden and not petAlways then
      SetPetBarAlpha(1); State.petBarHidden = false
    end
    if anyAlways then
      StartMouseCheck()
    else
      StopMouseCheck()
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

-- ============================================================
-- Fade Micro Menu
-- ============================================================
local microMenuFadeTimer = nil
local microMenuFaded = false

local function FadeMicroMenuIn()
  local mm = MicroMenuContainer or MicroMenu
  if not mm then return end
  microMenuFaded = false
  UIFrameFadeIn(mm, 0.3, mm:GetAlpha(), 1)
end

local function FadeMicroMenuOut()
  local mm = MicroMenuContainer or MicroMenu
  if not mm then return end
  microMenuFaded = true
  UIFrameFadeOut(mm, 0.5, mm:GetAlpha(), 0)
end

local function StartMicroMenuFadeTimer()
  if microMenuFadeTimer then microMenuFadeTimer:Cancel() end
  microMenuFadeTimer = C_Timer.NewTimer(5, FadeMicroMenuOut)
end

addonTable.SetupFadeMicroMenu = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.fadeMicroMenu then
    if microMenuFadeTimer then microMenuFadeTimer:Cancel(); microMenuFadeTimer = nil end
    if State.microMenuTicker then State.microMenuTicker:Cancel(); State.microMenuTicker = nil end
    FadeMicroMenuIn()
    return
  end
  if State.microMenuTicker then return end
  StartMicroMenuFadeTimer()
  State.microMenuTicker = C_Timer.NewTicker(0.15, function()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or not p.fadeMicroMenu then return end
    local mm = MicroMenuContainer or MicroMenu
    if not mm then return end
    local isOver = mm:IsMouseOver()
    if isOver and microMenuFaded then
      FadeMicroMenuIn()
      if microMenuFadeTimer then microMenuFadeTimer:Cancel(); microMenuFadeTimer = nil end
    elseif not isOver and not microMenuFaded and not microMenuFadeTimer then
      StartMicroMenuFadeTimer()
    end
  end)
end
C_Timer.After(2, function() if addonTable.SetupFadeMicroMenu then addonTable.SetupFadeMicroMenu() end end)

-- ============================================================
-- Hide Action Bar Borders / Skin Action Bars
-- ============================================================
local abSkinState = {}
local cachedCursorPlacement = nil
local cachedCursorFrame = 0
local function IsActionPlacementCursorActive()
  local frame = GetTime()
  if cachedCursorFrame == frame then return cachedCursorPlacement end
  cachedCursorFrame = frame
  cachedCursorPlacement = false
  if GetCursorInfo then
    local cursorType = select(1, GetCursorInfo())
    if cursorType == "spell" or cursorType == "item" or cursorType == "macro"
      or cursorType == "mount" or cursorType == "companion" or cursorType == "flyout"
      or cursorType == "petaction" or cursorType == "equipmentset" or cursorType == "action" then
      cachedCursorPlacement = true
      return true
    end
  end
  if CursorHasSpell and CursorHasSpell() then cachedCursorPlacement = true; return true end
  if CursorHasItem and CursorHasItem() then cachedCursorPlacement = true; return true end
  if CursorHasMacro and CursorHasMacro() then cachedCursorPlacement = true; return true end
  return false
end
local function UpdateSkinnedButtonTexts(btn, hasAction, st)
  if not btn then return end
  local has = hasAction
  if has == nil then
    has = btn.HasAction and btn:HasAction() or (btn.action and HasAction(btn.action))
  end
  if has then
    if btn.HotKey then btn.HotKey:SetAlpha(1) end
    if btn.Name then btn.Name:SetAlpha(1) end
    if st then st.emptyHidden = false end
  else
    local showEmptyHotKey = IsActionPlacementCursorActive()
    if btn.HotKey then btn.HotKey:SetAlpha(showEmptyHotKey and 1 or 0) end
    if btn.Name then btn.Name:SetAlpha(0) end
    if st then st.emptyHidden = true end
  end
end

local function ApplyButtonSkin(btn)
  local iconTex = btn.icon or btn.Icon
  local cooldownFrame = btn.cooldown or btn.Cooldown or (btn.GetName and _G[btn:GetName() .. "Cooldown"])
  if btn.NormalTexture then btn.NormalTexture:SetTexture(); btn.NormalTexture:Hide(); btn.NormalTexture:SetAlpha(0) end
  local nt = btn:GetNormalTexture()
  if nt then nt:SetTexture(); nt:Hide(); nt:SetAlpha(0) end
  if btn.FloatingBG then btn.FloatingBG:Hide() end
  if btn.IconBorder then btn.IconBorder:SetAlpha(0) end
  if btn.SlotArt then btn.SlotArt:Hide() end
  if btn.SlotBackground then btn.SlotBackground:Hide() end
  if iconTex then
    iconTex:ClearAllPoints()
    iconTex:SetAllPoints(btn)
    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    iconTex:SetAlpha(1)
    if not btn._ccmMasksRemoved and iconTex.GetMaskTexture then
      btn._ccmMasksRemoved = true
      local mask = iconTex:GetMaskTexture(1)
      while mask do
        iconTex:RemoveMaskTexture(mask)
        mask = iconTex:GetMaskTexture(1)
      end
    end
    if cooldownFrame then
      cooldownFrame:ClearAllPoints()
      cooldownFrame:SetAllPoints(btn)
    end
  end
end

local function SkinActionButton(btn, hide)
  if not btn then return end
  local key = btn:GetName() or tostring(btn)
  local iconTex = btn.icon or btn.Icon
  local cooldownFrame = btn.cooldown or btn.Cooldown or (btn.GetName and _G[btn:GetName() .. "Cooldown"])
  if hide then
    if not abSkinState[key] then
      abSkinState[key] = { skinned = false }
    end
    local s = abSkinState[key]
    if not s.skinned then
      s.skinned = true
      if iconTex and iconTex.GetTexCoord then
        s.origTexCoords = {iconTex:GetTexCoord()}
      end
      if iconTex and iconTex.GetNumPoints and iconTex:GetNumPoints() > 0 then
        s.origIconPoints = {}
        for i = 1, iconTex:GetNumPoints() do
          s.origIconPoints[i] = {iconTex:GetPoint(i)}
        end
      end
      if cooldownFrame and cooldownFrame.GetNumPoints and cooldownFrame:GetNumPoints() > 0 then
        s.origCooldownPoints = {}
        for i = 1, cooldownFrame:GetNumPoints() do
          s.origCooldownPoints[i] = {cooldownFrame:GetPoint(i)}
        end
      end
      if iconTex and iconTex.GetMaskTexture then
        s.origMasks = {}
        local idx = 1
        local mask = iconTex:GetMaskTexture(idx)
        while mask do
          s.origMasks[idx] = mask
          idx = idx + 1
          mask = iconTex:GetMaskTexture(idx)
        end
      end
    end
    ApplyButtonSkin(btn)
    local hasAction = btn.HasAction and btn:HasAction() or (btn.action and HasAction(btn.action))
    UpdateSkinnedButtonTexts(btn, hasAction, s)
    btn._ccmSkinned = true
  else
    local s = abSkinState[key]
    if s then s.skinned = false; s.emptyHidden = false end
    btn._ccmSkinned = nil
    btn._ccmMasksRemoved = nil
    if btn.HotKey then btn.HotKey:SetAlpha(1) end
    if btn.Name then btn.Name:SetAlpha(1) end
    if btn.NormalTexture then btn.NormalTexture:SetAlpha(1) end
    local nt = btn:GetNormalTexture()
    if nt then nt:SetAlpha(1) end
    if btn.FloatingBG then btn.FloatingBG:Show() end
    if btn.IconBorder then btn.IconBorder:SetAlpha(1) end
    if btn.SlotArt then btn.SlotArt:Show() end
    if btn.SlotBackground then btn.SlotBackground:Show() end
    if iconTex and s and s.origTexCoords then
      iconTex:SetTexCoord(unpack(s.origTexCoords))
    elseif iconTex then
      iconTex:SetTexCoord(0, 1, 0, 1)
    end
    if iconTex and s and s.origIconPoints then
      iconTex:ClearAllPoints()
      for _, pt in ipairs(s.origIconPoints) do
        iconTex:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5])
      end
    end
    if iconTex and s and s.origMasks and iconTex.AddMaskTexture then
      for _, mask in ipairs(s.origMasks) do
        iconTex:AddMaskTexture(mask)
      end
    end
    if cooldownFrame then
      cooldownFrame:ClearAllPoints()
      if s and s.origCooldownPoints and #s.origCooldownPoints > 0 then
        for _, pt in ipairs(s.origCooldownPoints) do
          cooldownFrame:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5])
        end
      else
        cooldownFrame:SetAllPoints(btn)
      end
    end
    if btn.UpdateButtonArt then
      pcall(btn.UpdateButtonArt, btn)
    end
  end
end

local function GetBarEditModeSettings(bar)
  local settings = { numRows = 1, numIcons = 12, isVertical = false, iconPadding = 0 }
  if not bar or not Enum or not Enum.EditModeActionBarSetting then return settings end
  if not bar.GetSettingValue then return settings end
  pcall(function()
    local orient = bar:GetSettingValue(Enum.EditModeActionBarSetting.Orientation)
    settings.isVertical = (orient == 1)
    settings.numRows = bar:GetSettingValue(Enum.EditModeActionBarSetting.NumRows) or 1
    settings.numIcons = bar:GetSettingValue(Enum.EditModeActionBarSetting.NumIcons) or 12
    settings.iconPadding = bar:GetSettingValue(Enum.EditModeActionBarSetting.IconPadding) or 0
  end)
  if settings.numRows < 1 then settings.numRows = 1 end
  if settings.numIcons < 1 then settings.numIcons = 12 end
  return settings
end

local function SkinBarButtons(barName, prefix, hide, numButtons)
  local bar = _G[barName]
  if not bar then return end
  numButtons = numButtons or 12
  if bar.BorderArt then bar.BorderArt:SetShown(not hide) end
  local emSettings = GetBarEditModeSettings(bar)
  for i = 1, numButtons do
    local btn = _G[prefix .. i]
    if btn then
      btn._ccmIndex = i
      btn._ccmPrefix = prefix
      btn._ccmNumButtons = numButtons
    end
    SkinActionButton(btn, hide)
  end
  if not InCombatLockdown() then
    local btn1 = _G[prefix .. "1"]
    if not btn1 then return end
    local isVertical = emSettings.isVertical
    local emNumRows = emSettings.numRows
    local emNumIcons = emSettings.numIcons
    if emNumIcons > numButtons then emNumIcons = numButtons end
    local iconsPerRow = math.ceil(emNumIcons / emNumRows)
    if iconsPerRow < 1 then iconsPerRow = 1 end
    if hide then
      local btnWidth = btn1:GetWidth()
      local btnHeight = btn1:GetHeight()
      for i = 1, numButtons do
        local btn = _G[prefix .. i]
        if btn then
          if not btn._ccmOrigPoint then
            local point, relativeTo, relativePoint, ofsx, ofsy = btn:GetPoint(1)
            if point then
              btn._ccmOrigPoint = {point, relativeTo, relativePoint, ofsx, ofsy}
            end
          end
          local col = (i - 1) % iconsPerRow
          local row = math.floor((i - 1) / iconsPerRow)
          btn:ClearAllPoints()
          if isVertical then
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", row * btnWidth, -col * btnHeight)
          else
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", col * btnWidth, -row * btnHeight)
          end
        end
      end
    else
      for i = 1, numButtons do
        local btn = _G[prefix .. i]
        if btn and btn._ccmOrigPoint then
          btn:ClearAllPoints()
          btn:SetPoint(btn._ccmOrigPoint[1], btn._ccmOrigPoint[2], btn._ccmOrigPoint[3], btn._ccmOrigPoint[4], btn._ccmOrigPoint[5])
          btn._ccmOrigPoint = nil
        end
      end
    end
  end
end

local abSkinEverApplied = false

local function RestoreAllActionBars()
  local mainBar = MainMenuBar
  if mainBar and mainBar.EndCaps then
    if mainBar.EndCaps.LeftEndCap then mainBar.EndCaps.LeftEndCap:SetShown(true) end
    if mainBar.EndCaps.RightEndCap then mainBar.EndCaps.RightEndCap:SetShown(true) end
  end
  local mainActionBar = _G["MainActionBar"]
  if mainActionBar and mainActionBar ~= mainBar and mainActionBar.EndCaps then
    if mainActionBar.EndCaps.LeftEndCap then mainActionBar.EndCaps.LeftEndCap:SetShown(true) end
    if mainActionBar.EndCaps.RightEndCap then mainActionBar.EndCaps.RightEndCap:SetShown(true) end
  end
  local bar1Name = mainActionBar and "MainActionBar" or "MainMenuBar"
  SkinBarButtons(bar1Name, "ActionButton", false, 12)
  SkinBarButtons("MultiBarBottomLeft", "MultiBarBottomLeftButton", false, 12)
  SkinBarButtons("MultiBarBottomRight", "MultiBarBottomRightButton", false, 12)
  SkinBarButtons("MultiBarRight", "MultiBarRightButton", false, 12)
  SkinBarButtons("MultiBarLeft", "MultiBarLeftButton", false, 12)
  SkinBarButtons("MultiBar5", "MultiBar5Button", false, 12)
  SkinBarButtons("MultiBar6", "MultiBar6Button", false, 12)
  SkinBarButtons("MultiBar7", "MultiBar7Button", false, 12)
  SkinBarButtons("StanceBar", "StanceButton", false, 10)
  local petBarName = PetActionBar and "PetActionBar" or "PetActionBarFrame"
  SkinBarButtons(petBarName, "PetActionButton", false, 10)
end

addonTable.SetupHideABBorders = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local hide = profile.hideActionBarBorders == true
  if not hide then
    if abSkinEverApplied then
      abSkinEverApplied = false
      RestoreAllActionBars()
    end
    return
  end
  abSkinEverApplied = true
  local mainBar = MainMenuBar
  if mainBar and mainBar.EndCaps then
    if mainBar.EndCaps.LeftEndCap then mainBar.EndCaps.LeftEndCap:SetShown(false) end
    if mainBar.EndCaps.RightEndCap then mainBar.EndCaps.RightEndCap:SetShown(false) end
  end
  local mainActionBar = _G["MainActionBar"]
  if mainActionBar and mainActionBar ~= mainBar and mainActionBar.EndCaps then
    if mainActionBar.EndCaps.LeftEndCap then mainActionBar.EndCaps.LeftEndCap:SetShown(false) end
    if mainActionBar.EndCaps.RightEndCap then mainActionBar.EndCaps.RightEndCap:SetShown(false) end
  end
  local bar1Name = mainActionBar and "MainActionBar" or "MainMenuBar"
  SkinBarButtons(bar1Name, "ActionButton", true, 12)
  SkinBarButtons("MultiBarBottomLeft", "MultiBarBottomLeftButton", true, 12)
  SkinBarButtons("MultiBarBottomRight", "MultiBarBottomRightButton", true, 12)
  SkinBarButtons("MultiBarRight", "MultiBarRightButton", true, 12)
  SkinBarButtons("MultiBarLeft", "MultiBarLeftButton", true, 12)
  SkinBarButtons("MultiBar5", "MultiBar5Button", true, 12)
  SkinBarButtons("MultiBar6", "MultiBar6Button", true, 12)
  SkinBarButtons("MultiBar7", "MultiBar7Button", true, 12)
  SkinBarButtons("StanceBar", "StanceButton", true, 10)
  local petBarName = PetActionBar and "PetActionBar" or "PetActionBarFrame"
  SkinBarButtons(petBarName, "PetActionButton", true, 10)
end
local function UpdateAllSkinnedActionButtonHotkeys()
  local p = addonTable.GetProfile and addonTable.GetProfile()
  if not p or not p.hideActionBarBorders then return end
  local function UpdatePrefix(prefix, numButtons)
    for i = 1, (numButtons or 12) do
      local btn = _G[prefix .. i]
      if btn then
        local key = btn:GetName() or tostring(btn)
        local st = abSkinState[key]
        if st and st.skinned then
          local has = btn.HasAction and btn:HasAction() or (btn.action and HasAction(btn.action))
          UpdateSkinnedButtonTexts(btn, has, st)
        end
      end
    end
  end
  UpdatePrefix("ActionButton", 12)
  UpdatePrefix("MultiBarBottomLeftButton", 12)
  UpdatePrefix("MultiBarBottomRightButton", 12)
  UpdatePrefix("MultiBarRightButton", 12)
  UpdatePrefix("MultiBarLeftButton", 12)
  UpdatePrefix("MultiBar5Button", 12)
  UpdatePrefix("MultiBar6Button", 12)
  UpdatePrefix("MultiBar7Button", 12)
  UpdatePrefix("StanceButton", 10)
  UpdatePrefix("PetActionButton", 10)
end

local function RefreshAllSkinnedActionButtonBorders()
  local p = addonTable.GetProfile and addonTable.GetProfile()
  if not p or not p.hideActionBarBorders then return end
  local function RefreshPrefix(prefix, numButtons)
    for i = 1, (numButtons or 12) do
      local btn = _G[prefix .. i]
      if btn then
        local key = btn:GetName() or tostring(btn)
        local st = abSkinState[key]
        if st and st.skinned then
          ApplyButtonSkin(btn)
        end
      end
    end
  end
  RefreshPrefix("ActionButton", 12)
  RefreshPrefix("MultiBarBottomLeftButton", 12)
  RefreshPrefix("MultiBarBottomRightButton", 12)
  RefreshPrefix("MultiBarRightButton", 12)
  RefreshPrefix("MultiBarLeftButton", 12)
  RefreshPrefix("MultiBar5Button", 12)
  RefreshPrefix("MultiBar6Button", 12)
  RefreshPrefix("MultiBar7Button", 12)
  RefreshPrefix("StanceButton", 10)
  RefreshPrefix("PetActionButton", 10)
end
do
  local cursorHotkeyFrame = CreateFrame("Frame")
  cursorHotkeyFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  cursorHotkeyFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  cursorHotkeyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  cursorHotkeyFrame:SetScript("OnEvent", function()
    UpdateAllSkinnedActionButtonHotkeys()
    RefreshAllSkinnedActionButtonBorders()
  end)
end
C_Timer.After(2, function()
  local p = addonTable.GetProfile and addonTable.GetProfile()
  if p and p.hideActionBarBorders then
    if addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end
  end
end)

do
  local petSkinFrame = CreateFrame("Frame")
  petSkinFrame:RegisterEvent("PET_BAR_UPDATE")
  petSkinFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
  petSkinFrame:SetScript("OnEvent", function()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or not p.hideActionBarBorders then return end
    local petBarName = PetActionBar and "PetActionBar" or "PetActionBarFrame"
    local bar = _G[petBarName]
    if not bar then return end
    SkinBarButtons(petBarName, "PetActionButton", true, 10)
  end)
end
do
  local stanceSkinFrame = CreateFrame("Frame")
  stanceSkinFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
  stanceSkinFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
  stanceSkinFrame:SetScript("OnEvent", function()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or not p.hideActionBarBorders then return end
    local bar = _G["StanceBar"]
    if not bar then return end
    SkinBarButtons("StanceBar", "StanceButton", true, 10)
  end)
end

-- ============================================================
-- Fade Objective Tracker
-- ============================================================
local objTrackerFadeTimer = nil
local objTrackerFaded = false

local function FadeObjTrackerIn()
  local ot = ObjectiveTrackerFrame
  if not ot then return end
  objTrackerFaded = false
  UIFrameFadeIn(ot, 0.3, ot:GetAlpha(), 1)
end

local function FadeObjTrackerOut()
  local ot = ObjectiveTrackerFrame
  if not ot then return end
  objTrackerFaded = true
  UIFrameFadeOut(ot, 0.5, ot:GetAlpha(), 0)
end

local function StartObjTrackerFadeTimer()
  if objTrackerFadeTimer then objTrackerFadeTimer:Cancel() end
  objTrackerFadeTimer = C_Timer.NewTimer(5, FadeObjTrackerOut)
end

addonTable.SetupFadeObjectiveTracker = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.fadeObjectiveTracker then
    if objTrackerFadeTimer then objTrackerFadeTimer:Cancel(); objTrackerFadeTimer = nil end
    if State.objTrackerTicker then State.objTrackerTicker:Cancel(); State.objTrackerTicker = nil end
    FadeObjTrackerIn()
    return
  end
  if State.objTrackerTicker then return end
  StartObjTrackerFadeTimer()
  State.objTrackerTicker = C_Timer.NewTicker(0.15, function()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or not p.fadeObjectiveTracker then return end
    local ot = ObjectiveTrackerFrame
    if not ot then return end
    local isOver = ot:IsMouseOver()
    if isOver and objTrackerFaded then
      FadeObjTrackerIn()
      if objTrackerFadeTimer then objTrackerFadeTimer:Cancel(); objTrackerFadeTimer = nil end
    elseif not isOver and not objTrackerFaded and not objTrackerFadeTimer then
      StartObjTrackerFadeTimer()
    end
  end)
end
C_Timer.After(2, function() if addonTable.SetupFadeObjectiveTracker then addonTable.SetupFadeObjectiveTracker() end end)

-- ============================================================
-- Fade Bag Bar
-- ============================================================
local bagBarFadeTimer = nil
local bagBarFaded = false

local function FadeBagBarIn()
  local bb = BagsBar
  if not bb then return end
  bagBarFaded = false
  UIFrameFadeIn(bb, 0.3, bb:GetAlpha(), 1)
end

local function FadeBagBarOut()
  local bb = BagsBar
  if not bb then return end
  bagBarFaded = true
  UIFrameFadeOut(bb, 0.5, bb:GetAlpha(), 0)
end

local function StartBagBarFadeTimer()
  if bagBarFadeTimer then bagBarFadeTimer:Cancel() end
  bagBarFadeTimer = C_Timer.NewTimer(5, FadeBagBarOut)
end

addonTable.SetupFadeBagBar = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.fadeBagBar then
    if bagBarFadeTimer then bagBarFadeTimer:Cancel(); bagBarFadeTimer = nil end
    if State.bagBarTicker then State.bagBarTicker:Cancel(); State.bagBarTicker = nil end
    FadeBagBarIn()
    return
  end
  if State.bagBarTicker then return end
  StartBagBarFadeTimer()
  State.bagBarTicker = C_Timer.NewTicker(0.15, function()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or not p.fadeBagBar then return end
    local bb = BagsBar
    if not bb then return end
    local isOver = bb:IsMouseOver()
    if isOver and bagBarFaded then
      FadeBagBarIn()
      if bagBarFadeTimer then bagBarFadeTimer:Cancel(); bagBarFadeTimer = nil end
    elseif not isOver and not bagBarFaded and not bagBarFadeTimer then
      StartBagBarFadeTimer()
    end
  end)
end
C_Timer.After(2, function() if addonTable.SetupFadeBagBar then addonTable.SetupFadeBagBar() end end)

-- ============================================================
-- Character Panel Enhancement
-- ============================================================

local scanTip = CreateFrame("GameTooltip", "CCMCharScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local EQUIP_SLOTS = {
  {"CharacterHeadSlot", 1, "left", false},
  {"CharacterNeckSlot", 2, "left", false},
  {"CharacterShoulderSlot", 3, "left", false},
  {"CharacterBackSlot", 15, "left", true},
  {"CharacterChestSlot", 5, "left", true},
  {"CharacterWristSlot", 9, "left", true},
  {"CharacterHandsSlot", 10, "right", false},
  {"CharacterWaistSlot", 6, "right", false},
  {"CharacterLegsSlot", 7, "right", true},
  {"CharacterFeetSlot", 8, "right", true},
  {"CharacterFinger0Slot", 11, "right", true},
  {"CharacterFinger1Slot", 12, "right", true},
  {"CharacterTrinket0Slot", 13, "right", false},
  {"CharacterTrinket1Slot", 14, "right", false},
  {"CharacterMainHandSlot", 16, "bottom", true},
  {"CharacterSecondaryHandSlot", 17, "bottom", true},
}

local QUALITY_COLORS = {
  [0] = {0.62, 0.62, 0.62}, [1] = {1, 1, 1}, [2] = {0.12, 1, 0},
  [3] = {0, 0.44, 0.87}, [4] = {0.64, 0.21, 0.93}, [5] = {1, 0.5, 0},
  [6] = {0.9, 0.8, 0.5}, [7] = {0, 0.8, 1}, [8] = {0, 0.8, 1},
}

local slotOverlays = {}
local gemPanel = nil

local function GetEnchantText(slotID)
  scanTip:ClearLines()
  scanTip:SetInventoryItem("player", slotID)
  for i = 2, scanTip:NumLines() do
    local line = _G["CCMCharScanTipTextLeft" .. i]
    if line then
      local text = line:GetText()
      if text then
        local name = text:match("Enchanted:%s*(.+)") or text:match("Verzaubert:%s*(.+)")
        if name then
          name = name:gsub("%s*|.+$", "")
          return name
        end
      end
    end
  end
  return nil
end

local function HasEnchant(itemLink)
  if not itemLink then return false end
  local parts = {strsplit(":", itemLink:match("item:([%-?%d:]+)") or "")}
  return (tonumber(parts[2]) or 0) > 0
end

local ALWAYS_ENCHANTABLE = {
  [5] = true, [7] = true, [8] = true, [9] = true,
  [11] = true, [12] = true, [15] = true, [16] = true,
}

local function CanItemBeEnchanted(slotID)
  if ALWAYS_ENCHANTABLE[slotID] then return true end
  if slotID == 17 then
    local itemID = GetInventoryItemID("player", slotID)
    if itemID then
      local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
      return classID == 2
    end
  end
  return false
end

local function GetSocketInfo(itemLink, slotID)
  if not itemLink then return 0, 0 end
  local parts = {strsplit(":", itemLink:match("item:([%-?%d:]+)") or "")}
  local filled = 0
  for i = 3, 6 do
    if (tonumber(parts[i]) or 0) > 0 then filled = filled + 1 end
  end
  local empty = 0
  if slotID then
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotID)
    for i = 2, scanTip:NumLines() do
      local line = _G["CCMCharScanTipTextLeft" .. i]
      if line then
        local text = line:GetText()
        if text and text:match("[Ss]ocket") and not text:match("Socketed") then
          local r, g, b = line:GetTextColor()
          if r and r < 0.7 and g < 0.7 and b < 0.7 then
            empty = empty + 1
          end
        end
      end
    end
  end
  return filled + empty, filled
end


local function CreateSlotOverlay(slotFrame, side)
  local overlay = CreateFrame("Frame", nil, slotFrame)
  overlay:SetSize(140, 40)
  overlay:SetFrameStrata("HIGH")
  if side == "left" then
    overlay:SetPoint("LEFT", slotFrame, "RIGHT", 2, 0)
  elseif side == "right" then
    overlay:SetPoint("RIGHT", slotFrame, "LEFT", -2, 0)
  else
    overlay:SetPoint("TOP", slotFrame, "BOTTOM", 0, -2)
  end
  overlay.side = side
  local justify = (side == "right") and "RIGHT" or "LEFT"
  local anchor = (side == "right") and "TOPRIGHT" or "TOPLEFT"
  overlay.ilvlText = slotFrame:CreateFontString(nil, "OVERLAY")
  overlay.ilvlText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
  overlay.ilvlText:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
  overlay.ilvlText:SetJustifyH("CENTER")
  overlay.enchantText = overlay:CreateFontString(nil, "OVERLAY")
  overlay.enchantText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
  local enchantXOff = (side == "right") and -5 or 5
  overlay.enchantText:SetPoint(anchor, overlay, anchor, enchantXOff, 0)
  overlay.enchantText:SetJustifyH(justify)
  overlay.socketIcons = {}
  for i = 1, 3 do
    local btn = CreateFrame("Button", nil, overlay)
    btn:SetSize(18, 18)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if self.gemID then
        GameTooltip:SetItemByID(self.gemID)
      else
        GameTooltip:SetText("Drop gem to socket", 1, 1, 1)
      end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnReceiveDrag", function(self)
      if self.slotID and not InCombatLockdown() then SocketInventoryItem(self.slotID) end
    end)
    btn:Hide()
    overlay.socketIcons[i] = btn
  end
  overlay:Hide()
  return overlay
end

local function UpdateSlotOverlay(slotInfo)
  local frameName, slotID, side = slotInfo[1], slotInfo[2], slotInfo[3]
  local slotFrame = _G[frameName]
  if not slotFrame then return end
  if not slotOverlays[slotID] then
    slotOverlays[slotID] = CreateSlotOverlay(slotFrame, side)
  end
  local ov = slotOverlays[slotID]
  local itemLink = GetInventoryItemLink("player", slotID)
  if not itemLink then
    ov:Hide()
    if ov.ilvlText then ov.ilvlText:Hide() end
    return
  end
  local ilvl
  if GetDetailedItemLevelInfo then
    ilvl = GetDetailedItemLevelInfo(itemLink)
  end
  local quality = GetInventoryItemQuality("player", slotID) or 1
  local qc = QUALITY_COLORS[quality] or QUALITY_COLORS[1]
  if ilvl then
    ov.ilvlText:SetText(tostring(ilvl))
    ov.ilvlText:SetTextColor(qc[1], qc[2], qc[3])
  else
    ov.ilvlText:SetText("")
  end
  if CanItemBeEnchanted(slotID) then
    if HasEnchant(itemLink) then
      local enchName = GetEnchantText(slotID) or "Enchanted"
      if #enchName > 22 then enchName = enchName:sub(1, 20) .. ".." end
      ov.enchantText:SetText(enchName)
      ov.enchantText:SetTextColor(0, 1, 0)
    else
      ov.enchantText:SetText("Enchant Missing")
      ov.enchantText:SetTextColor(1, 0, 0)
    end
    ov.enchantText:Show()
  else
    ov.enchantText:SetText("")
    ov.enchantText:Hide()
  end
  local totalSockets, filledGems = GetSocketInfo(itemLink, slotID)
  if totalSockets > 0 then
    local parts = {strsplit(":", itemLink:match("item:([%-?%d:]+)") or "")}
    local sockets = {}
    for i = 3, 6 do
      local gid = tonumber(parts[i]) or 0
      if gid > 0 then table.insert(sockets, gid) end
    end
    local emptyCount = totalSockets - filledGems
    for i = 1, emptyCount do table.insert(sockets, 0) end
    local n = #sockets
    local isRight = (ov.side == "right")
    local iconSize = 18
    local pad = 2
    local socketY = 0
    if ov.enchantText:IsShown() and ov.enchantText:GetText() ~= "" then
      socketY = -(ov.enchantText:GetStringHeight() + 3)
    end
    for i = 1, math.min(n, 3) do
      local btn = ov.socketIcons[i]
      btn:ClearAllPoints()
      local xOff = (i - 1) * (iconSize + pad)
      if isRight then
        btn:SetPoint("TOPRIGHT", ov, "TOPRIGHT", -xOff - 10, socketY)
      else
        btn:SetPoint("TOPLEFT", ov, "TOPLEFT", xOff + 10, socketY)
      end
      local gid = sockets[i]
      btn.slotID = slotID
      btn:SetScript("OnClick", function(self)
        if not InCombatLockdown() then SocketInventoryItem(self.slotID) end
      end)
      if gid > 0 then
        local _, _, _, _, texID = C_Item.GetItemInfoInstant(gid)
        btn.icon:SetTexture(texID)
        btn.gemID = gid
      else
        btn.icon:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
        btn.gemID = nil
      end
      btn:Show()
    end
    for i = n + 1, 3 do ov.socketIcons[i]:Hide() end
  else
    for i = 1, 3 do ov.socketIcons[i]:Hide() end
  end
  if ov.ilvlText then ov.ilvlText:Show() end
  ov:Show()
end

local function UpdateAllSlotOverlays()
  for _, slotInfo in ipairs(EQUIP_SLOTS) do
    UpdateSlotOverlay(slotInfo)
  end
end

local function HideAllSlotOverlays()
  for _, ov in pairs(slotOverlays) do
    ov:Hide()
    if ov.ilvlText then ov.ilvlText:Hide() end
  end
end

-- ===== Bag Gems Panel =====
local function ScanBagsForGems()
  local gems = {}
  for bag = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID then
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(info.itemID)
        if classID == 3 then
          table.insert(gems, {
            bag = bag, slot = slot, itemID = info.itemID,
            icon = info.iconFileID, link = info.hyperlink,
            count = info.stackCount or 1,
          })
        end
      end
    end
  end
  return gems
end

local function CreateGemPanel()
  if gemPanel then return gemPanel end
  gemPanel = CreateFrame("Frame", "CCMGemPanel", CharacterFrame, "BackdropTemplate")
  gemPanel:SetPoint("TOPRIGHT", CharacterFrame, "BOTTOMRIGHT", 0, -2)
  gemPanel:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  gemPanel:SetBackdropColor(0.05, 0.05, 0.07, 0.9)
  gemPanel:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  gemPanel:SetFrameStrata("HIGH")
  gemPanel.title = gemPanel:CreateFontString(nil, "OVERLAY")
  gemPanel.title:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
  gemPanel.title:SetPoint("TOPLEFT", 6, -5)
  gemPanel.title:SetText("|cffaaaaaaAvailable Gems|r")
  gemPanel.icons = {}
  gemPanel:Hide()
  return gemPanel
end

local function UpdateGemPanel()
  local panel = CreateGemPanel()
  local gems = ScanBagsForGems()
  for _, btn in ipairs(panel.icons) do btn:Hide() end
  if #gems == 0 then panel:Hide(); return end
  local iconSize, pad, maxPerRow = 24, 2, 10
  local rows = math.ceil(math.min(#gems, 30) / maxPerRow)
  panel:SetSize(6 * 2 + math.min(#gems, maxPerRow) * (iconSize + pad), 18 + rows * (iconSize + pad) + 4)
  for i = 1, math.min(#gems, 30) do
    local gem = gems[i]
    if not panel.icons[i] then
      local btn = CreateFrame("Button", nil, panel)
      btn:SetSize(iconSize, iconSize)
      btn.icon = btn:CreateTexture(nil, "ARTWORK")
      btn.icon:SetAllPoints()
      btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      btn.count = btn:CreateFontString(nil, "OVERLAY")
      btn.count:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
      btn.count:SetPoint("BOTTOMRIGHT", -1, 1)
      btn:SetScript("OnEnter", function(self)
        if self.gemLink then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetHyperlink(self.gemLink)
          GameTooltip:Show()
        end
      end)
      btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
      btn:SetScript("OnClick", function(self)
        if self.gemBag and self.gemSlot then
          C_Container.PickupContainerItem(self.gemBag, self.gemSlot)
        end
      end)
      panel.icons[i] = btn
    end
    local btn = panel.icons[i]
    local row = math.floor((i - 1) / maxPerRow)
    local col = (i - 1) % maxPerRow
    btn:SetPoint("TOPLEFT", panel, "TOPLEFT", 6 + col * (iconSize + pad), -18 - row * (iconSize + pad))
    btn.icon:SetTexture(gem.icon)
    btn.gemLink = gem.link
    btn.gemBag = gem.bag
    btn.gemSlot = gem.slot
    btn.count:SetText(gem.count > 1 and gem.count or "")
    btn:Show()
  end
  panel:Show()
end

-- ===== Better Item Level =====
addonTable.SetupBetterItemLevel = function()
  if not addonTable._betterIlvlHooked and PaperDollFrame_SetItemLevel then
    addonTable._betterIlvlHooked = true
    hooksecurefunc("PaperDollFrame_SetItemLevel", function(statFrame, unit)
      if unit ~= "player" then return end
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if not profile or not profile.betterItemLevel then return end
      local _, avgEquipped = GetAverageItemLevel()
      if statFrame and statFrame.Value then
        statFrame.Value:SetText(format("%.2f", avgEquipped))
      end
    end)
  end
  if CharacterFrame and CharacterFrame:IsShown() and PaperDollFrame_UpdateStats then
    pcall(PaperDollFrame_UpdateStats)
  end
end

-- ===== Equipment Details Setup =====
addonTable.SetupEquipmentDetails = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.showEquipmentDetails then
    HideAllSlotOverlays()
    if gemPanel then gemPanel:Hide() end
    return
  end
  if CharacterFrame and CharacterFrame:IsShown() then
    UpdateAllSlotOverlays()
    UpdateGemPanel()
  end
end

-- ===== Events & Hooks =====
local charPanelFrame = CreateFrame("Frame")
charPanelFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
charPanelFrame:RegisterEvent("BAG_UPDATE")
charPanelFrame:RegisterEvent("SOCKET_INFO_UPDATE")
charPanelFrame:SetScript("OnEvent", function(self, event)
  if not CharacterFrame or not CharacterFrame:IsShown() then return end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if profile.showEquipmentDetails then
    UpdateAllSlotOverlays()
    if event == "BAG_UPDATE" then UpdateGemPanel() end
  end
end)

C_Timer.After(2, function()
  if addonTable.SetupBetterItemLevel then addonTable.SetupBetterItemLevel() end
  if CharacterFrame then
    CharacterFrame:HookScript("OnShow", function()
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if not profile then return end
      if profile.betterItemLevel and PaperDollFrame_UpdateStats then
        pcall(PaperDollFrame_UpdateStats)
      end
      if profile.showEquipmentDetails then
        C_Timer.After(0.1, function()
          UpdateAllSlotOverlays()
          UpdateGemPanel()
        end)
      end
    end)
    CharacterFrame:HookScript("OnHide", function()
      HideAllSlotOverlays()
      if gemPanel then gemPanel:Hide() end
    end)
  end
end)

-- ============================================================
-- Auto Quest Accept / Turn-in
-- ============================================================

local autoQuestFrame
local questFreqCache = {}

local FREQ_DAILY = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Daily or 1
local FREQ_WEEKLY = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Weekly or 2

local function CacheGossipFrequencies()
  if C_GossipInfo then
    if C_GossipInfo.GetAvailableQuests then
      for _, q in ipairs(C_GossipInfo.GetAvailableQuests()) do
        if q.questID and q.frequency then questFreqCache[q.questID] = q.frequency end
      end
    end
    if C_GossipInfo.GetActiveQuests then
      for _, q in ipairs(C_GossipInfo.GetActiveQuests()) do
        if q.questID and q.frequency then questFreqCache[q.questID] = q.frequency end
      end
    end
  end
end

local function CacheGreetingFrequencies()
  local numAvail = GetNumAvailableQuests and GetNumAvailableQuests() or 0
  for i = 1, numAvail do
    local title, _, _, frequency = GetAvailableQuestInfo(i)
    if title and frequency then questFreqCache["t:" .. title] = frequency end
  end
  local numActive = GetNumActiveQuests and GetNumActiveQuests() or 0
  for i = 1, numActive do
    local title, _, _, _, _, frequency = GetActiveQuestInfo and GetActiveQuestInfo(i)
    if title and frequency then questFreqCache["t:" .. title] = frequency end
  end
end

local function DetectQuestFrequency(questID)
  if questFreqCache[questID] and questFreqCache[questID] > 0 then return questFreqCache[questID] end
  local title = GetTitleText and GetTitleText()
  if title and questFreqCache["t:" .. title] and questFreqCache["t:" .. title] > 0 then return questFreqCache["t:" .. title] end
  if QuestIsDaily and QuestIsDaily() then return FREQ_DAILY end
  if QuestIsWeekly and QuestIsWeekly() then return FREQ_WEEKLY end
  if GetQuestFrequency then
    local f = GetQuestFrequency()
    if f and type(f) == "number" and f > 0 then return f end
  end
  if questID and questID > 0 and C_QuestLog and C_QuestLog.GetQuestTagInfo then
    local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
    if tagInfo and tagInfo.frequency and tagInfo.frequency > 0 then return tagInfo.frequency end
  end
  return 0
end

local function ShouldSkipQuest(profile, questID)
  if not questID or questID == 0 then return false end

  if profile.autoQuestExcludeDaily or profile.autoQuestExcludeWeekly then
    local freq = DetectQuestFrequency(questID)
    if profile.autoQuestExcludeDaily and (freq == FREQ_DAILY or freq == 1) then return true end
    if profile.autoQuestExcludeWeekly and freq >= 2 then return true end
  end

  if profile.autoQuestExcludeTrivial then
    local questLevel = GetQuestLevel and GetQuestLevel() or 0
    if questLevel <= 0 and C_QuestLog and C_QuestLog.GetQuestDifficultyLevel then
      questLevel = C_QuestLog.GetQuestDifficultyLevel(questID) or 0
    end
    if questLevel > 0 then
      local playerLevel = UnitLevel("player") or 1
      local greenRange = GetQuestGreenRange and GetQuestGreenRange() or 0
      if questLevel < (playerLevel - greenRange) then return true end
    end
  end

  if profile.autoQuestExcludeCompleted then
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questID) then return true end
  end

  return false
end

local function GetBestGoldRewardIndex()
  local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
  if numChoices <= 1 then return numChoices end
  local bestIndex, bestPrice = 1, 0
  for i = 1, numChoices do
    local link = GetQuestItemLink and GetQuestItemLink("choice", i)
    if link then
      local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(link)
      if sellPrice and sellPrice > bestPrice then
        bestPrice = sellPrice
        bestIndex = i
      end
    end
  end
  return bestIndex
end

addonTable.SetupAutoQuest = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local enabled = profile and profile.autoQuest

  if not autoQuestFrame then
    autoQuestFrame = CreateFrame("Frame")
    autoQuestFrame:SetScript("OnEvent", function(_, event)
      if event == "GOSSIP_SHOW" then CacheGossipFrequencies(); return end
      if event == "QUEST_GREETING" then CacheGreetingFrequencies(); return end

      local p = addonTable.GetProfile and addonTable.GetProfile()
      if not p or not p.autoQuest then return end
      local questID = GetQuestID and GetQuestID() or 0

      if event == "QUEST_DETAIL" then
        if QuestGetAutoAccept and QuestGetAutoAccept() then return end
        if ShouldSkipQuest(p, questID) then return end
        if AcceptQuest then AcceptQuest() end

      elseif event == "QUEST_PROGRESS" then
        if not IsQuestCompletable or not IsQuestCompletable() then return end
        if ShouldSkipQuest(p, questID) then return end
        if CompleteQuest then CompleteQuest() end

      elseif event == "QUEST_COMPLETE" then
        if ShouldSkipQuest(p, questID) then return end
        local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
        if numChoices <= 1 then
          if GetQuestReward then GetQuestReward(1) end
        else
          local mode = p.autoQuestRewardMode or "skip"
          if mode == "gold" then
            local idx = GetBestGoldRewardIndex()
            if idx > 0 and GetQuestReward then GetQuestReward(idx) end
          end
        end

      elseif event == "QUEST_ACCEPT_CONFIRM" then
        if ShouldSkipQuest(p, questID) then return end
        if ConfirmAcceptQuest then ConfirmAcceptQuest() end
      end
    end)
  end

  autoQuestFrame:RegisterEvent("GOSSIP_SHOW")
  autoQuestFrame:RegisterEvent("QUEST_GREETING")

  if enabled then
    autoQuestFrame:RegisterEvent("QUEST_DETAIL")
    autoQuestFrame:RegisterEvent("QUEST_PROGRESS")
    autoQuestFrame:RegisterEvent("QUEST_COMPLETE")
    autoQuestFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
  else
    autoQuestFrame:UnregisterEvent("QUEST_DETAIL")
    autoQuestFrame:UnregisterEvent("QUEST_PROGRESS")
    autoQuestFrame:UnregisterEvent("QUEST_COMPLETE")
    autoQuestFrame:UnregisterEvent("QUEST_ACCEPT_CONFIRM")
  end
end

-- ============================================================
-- Auto Sell Junk
-- ============================================================

addonTable.TryAutoSellJunk = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.autoSellJunk then return end
  if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then return end
  local totalPrice = 0
  local count = 0
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    local slots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.quality == Enum.ItemQuality.Poor then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(info.itemID)
        if sellPrice then
          totalPrice = totalPrice + sellPrice * (info.stackCount or 1)
        end
        C_Container.UseContainerItem(bag, slot)
        count = count + 1
      end
    end
  end
  if count > 0 then
    local coinStr = GetCoinTextureString and GetCoinTextureString(totalPrice) or (totalPrice .. "c")
    print("|cFF00CCFFCooldownCursorManager:|r Sold " .. count .. " junk item" .. (count > 1 and "s" or "") .. " for " .. coinStr)
  end
end

-- ============================================================
-- Auto-fill DELETE Confirmation
-- ============================================================

local deleteHookInstalled = false

addonTable.SetupAutoFillDelete = function()
  if deleteHookInstalled then return end
  deleteHookInstalled = true

  hooksecurefunc("StaticPopup_Show", function(which)
    local profile = addonTable.GetProfile and addonTable.GetProfile()
    if not profile or not profile.autoFillDelete then return end
    if not which or not which:find("DELETE") then return end
    C_Timer.After(0, function()
      for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local dialog = _G["StaticPopup" .. i]
        if dialog and dialog:IsShown() and dialog.which == which then
          local eb = dialog.editBox or _G["StaticPopup" .. i .. "EditBox"]
          if eb and eb:IsShown() then
            eb:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
          end
          break
        end
      end
    end)
  end)
end

-- ============================================================
-- Quick Role Signup
-- ============================================================

local quickRoleFrame
local appDialogHooked = false

local function GetSpecRole()
  local specIndex = GetSpecialization and GetSpecialization()
  if not specIndex then return nil end
  return GetSpecializationRole and GetSpecializationRole(specIndex)
end

local function HookApplicationDialog()
  if appDialogHooked then return end
  local dialog = LFGListApplicationDialog
  if not dialog or not dialog.SignUpButton then return end
  appDialogHooked = true

  dialog.SignUpButton:HookScript("OnShow", function(self)
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or not p.quickRoleSignup then return end
    if IsShiftKeyDown() then return end
    self:Click()
  end)
end

addonTable.SetupQuickRoleSignup = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  local enabled = profile and profile.quickRoleSignup

  if not quickRoleFrame then
    quickRoleFrame = CreateFrame("Frame")
    quickRoleFrame:SetScript("OnEvent", function(_, event)
      local p = addonTable.GetProfile and addonTable.GetProfile()
      if not p or not p.quickRoleSignup then return end

      if event == "LFG_ROLE_CHECK_SHOW" then
        local role = GetSpecRole()
        if role and SetLFGRoles then
          SetLFGRoles(false, role == "TANK", role == "HEALER", role == "DAMAGER")
        end
        if CompleteLFGRoleCheck then CompleteLFGRoleCheck(true) end
      elseif event == "ROLE_POLL_BEGIN" then
        local role = GetSpecRole()
        if role and UnitSetRole then
          UnitSetRole("player", role)
        end
      elseif event == "ADDON_LOADED" then
        HookApplicationDialog()
        if appDialogHooked then
          quickRoleFrame:UnregisterEvent("ADDON_LOADED")
        end
      end
    end)
  end

  HookApplicationDialog()

  if enabled then
    quickRoleFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
    quickRoleFrame:RegisterEvent("ROLE_POLL_BEGIN")
    if not appDialogHooked then
      quickRoleFrame:RegisterEvent("ADDON_LOADED")
    end
  else
    quickRoleFrame:UnregisterAllEvents()
  end
end
