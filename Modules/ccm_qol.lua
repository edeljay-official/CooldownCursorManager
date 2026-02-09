local _, addonTable = ...
local State = addonTable.State
local GetGlobalFont = addonTable.GetGlobalFont
local selfHighlightFrame = CreateFrame("Frame", "CCMSelfHighlight", UIParent)
selfHighlightFrame:SetSize(40, 40)
selfHighlightFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
selfHighlightFrame:SetFrameStrata("TOOLTIP")
selfHighlightFrame:SetFrameLevel(1000)
selfHighlightFrame:Hide()
selfHighlightFrame.lines = {}
for i = 1, 4 do
  selfHighlightFrame.lines[i] = selfHighlightFrame:CreateLine(nil, "OVERLAY")
  selfHighlightFrame.lines[i]:SetColorTexture(1, 1, 1, 1)
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
  selfHighlightFrame:SetSize(size, size)
  selfHighlightFrame:ClearAllPoints()
  selfHighlightFrame:SetPoint("CENTER", UIParent, "CENTER", 0, yOffset)
  if shape == "cross" then
    local lineThickness = thickness == "thin" and 1 or (thickness == "thick" and 6 or 3)
    local halfSize = size / 2
    if outline then
      local outlineThickness = lineThickness + 2
      selfHighlightFrame.lines[3]:SetStartPoint("CENTER", -halfSize, 0)
      selfHighlightFrame.lines[3]:SetEndPoint("CENTER", halfSize, 0)
      selfHighlightFrame.lines[3]:SetThickness(outlineThickness)
      selfHighlightFrame.lines[3]:SetColorTexture(0, 0, 0, a)
      selfHighlightFrame.lines[3]:SetDrawLayer("OVERLAY", 0)
      selfHighlightFrame.lines[3]:Show()
      selfHighlightFrame.lines[4]:SetStartPoint("CENTER", 0, -halfSize)
      selfHighlightFrame.lines[4]:SetEndPoint("CENTER", 0, halfSize)
      selfHighlightFrame.lines[4]:SetThickness(outlineThickness)
      selfHighlightFrame.lines[4]:SetColorTexture(0, 0, 0, a)
      selfHighlightFrame.lines[4]:SetDrawLayer("OVERLAY", 0)
      selfHighlightFrame.lines[4]:Show()
    else
      selfHighlightFrame.lines[3]:Hide()
      selfHighlightFrame.lines[4]:Hide()
    end
    selfHighlightFrame.lines[1]:SetStartPoint("CENTER", -halfSize, 0)
    selfHighlightFrame.lines[1]:SetEndPoint("CENTER", halfSize, 0)
    selfHighlightFrame.lines[1]:SetThickness(lineThickness)
    selfHighlightFrame.lines[1]:SetColorTexture(r, g, b, a)
    selfHighlightFrame.lines[1]:SetDrawLayer("OVERLAY", 1)
    selfHighlightFrame.lines[1]:Show()
    selfHighlightFrame.lines[2]:SetStartPoint("CENTER", 0, -halfSize)
    selfHighlightFrame.lines[2]:SetEndPoint("CENTER", 0, halfSize)
    selfHighlightFrame.lines[2]:SetThickness(lineThickness)
    selfHighlightFrame.lines[2]:SetColorTexture(r, g, b, a)
    selfHighlightFrame.lines[2]:SetDrawLayer("OVERLAY", 1)
    selfHighlightFrame.lines[2]:Show()
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
  if not guiOpen or activeTab ~= 11 then return end
  self:StartMoving()
end)
addonTable.CombatTimerFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local scale = UIParent:GetEffectiveScale() or 1
    local rx = (centerX - parentCenterX) * scale
    local ry = (centerY - parentCenterY) * scale
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
  if style == "minimal" then
    frame:SetSize(128, 44)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", 34, "OUTLINE")
    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER")
  else
    frame:SetSize(96, 34)
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
  frame:SetPoint("CENTER", UIParent, "CENTER", centered and 0 or x, y)
  frame:SetScale(scale)
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
  if shouldShow then
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
  State.combatTimerTicker = C_Timer.NewTicker(0.05, function()
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
  if not guiOpen or activeTab ~= 11 then return end
  self:StartMoving()
end)
addonTable.crTimerFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local scale = UIParent:GetEffectiveScale() or 1
    local rx = (centerX - parentCenterX) * scale
    local ry = (centerY - parentCenterY) * scale
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
  if not guiOpen or activeTab ~= 11 then return end
  self:StartMoving()
end)
addonTable.CombatStatusFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local centerX, centerY = self:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
    local scale = UIParent:GetEffectiveScale() or 1
    local rx = (centerX - parentCenterX) * scale
    local ry = (centerY - parentCenterY) * scale
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
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", profile.combatStatusCentered == true and 0 or (profile.combatStatusX or 0), profile.combatStatusY or 280)
  frame:SetScale(type(profile.combatStatusScale) == "number" and profile.combatStatusScale or 1)
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
  frame.crText:SetText(string.format("CR: |cffFFFFFF%d|r / |cffFFFFFF%s|r", charges, crTimeText))
  if frame.blText then
    frame.blText:Hide()
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
  local mode = profile.crTimerMode == "always" and "always" or "combat"
  local shouldShow = (mode == "always") or UnitAffectingCombat("player")
  if not shouldShow then
    frame:Hide()
    if addonTable.StopCRTimerTicker then addonTable.StopCRTimerTicker() end
    return
  end
  local scale = type(profile.crTimerScale) == "number" and profile.crTimerScale or 1
  frame:SetScale(scale)
  frame:ClearAllPoints()
  local centered = profile.crTimerCentered == true
  local ox = centered and 0 or (profile.crTimerX or 0)
  local oy = profile.crTimerY or 150
  frame:SetPoint("CENTER", UIParent, "CENTER", ox / scale, oy / scale)
  local vertical = profile.crTimerLayout ~= "horizontal"
  frame.crText:ClearAllPoints()
  if frame.blText then
    frame.blText:ClearAllPoints()
    frame.blText:Hide()
  end
  if vertical then
    frame.crText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame:SetSize(190, 26)
  else
    frame.crText:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame:SetSize(190, 26)
  end
  local qolTab = addonTable.TAB_QOL or 11
  local draggable = (addonTable.GetGUIOpen and addonTable.GetGUIOpen()) and (addonTable.activeTab and addonTable.activeTab() == qolTab)
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
local function SetActionBars2to8Alpha(alpha)
  local barNames = {
    "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
    "MultiBar5", "MultiBar6", "MultiBar7",
  }
  for _, name in ipairs(barNames) do
    local bar = _G[name]
    if bar and bar.SetAlpha then bar:SetAlpha(alpha) end
  end
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
local function IsMouseOverAB2to8DetectionFrames()
  for _, df in pairs(ab2to8DetectionFrames) do
    if df and df:IsShown() and df:IsMouseOver() then
      return true
    end
  end
  return false
end
local ab2to8BarsConst = {
  "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
  "MultiBar5", "MultiBar6", "MultiBar7",
}
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
    if not InCombatLockdown() then
      if State.actionBar1Hidden then
        SetActionBar1Alpha(1)
        State.actionBar1Hidden = false
      end
      if State.actionBars2to8Hidden then
        SetActionBars2to8Alpha(1)
        State.actionBars2to8Hidden = false
      end
      if State.stanceBarHidden then
        SetStanceBarAlpha(1)
        State.stanceBarHidden = false
      end
      if State.petBarHidden then
        SetPetBarAlpha(1)
        State.petBarHidden = false
      end
      return
    end
    local mouseOverAB1 = false
    local mouseOverAB2to8 = false
    local mouseOverStance = false
    local mouseOverPet = false
    local ab1Mouseover = profile.hideActionBar1Mouseover == true
    local ab2to8Mouseover = profile.hideActionBars2to8Mouseover == true
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
        mouseOverCCMFrames = true
        break
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
    if mouseOverCCMFrames then
      mouseOverAB1 = false
      mouseOverAB2to8 = false
      mouseOverStance = false
    else
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
        for _, name in ipairs(ab2to8BarsConst) do
          local bar = _G[name]
          if bar and bar:IsShown() and bar:IsMouseOver() then
            mouseOverAB2to8 = true
            break
          end
        end
        if not mouseOverAB2to8 and IsMouseOverAB2to8DetectionFrames() then
          mouseOverAB2to8 = true
        end
        if not mouseOverAB2to8 then
          for _, btn in ipairs(GetActionButtons()) do
            if btn and btn:IsShown() and btn:IsMouseOver() then
              mouseOverAB1 = true
              break
            end
          end
        end
        if not mouseOverAB1 and ab1MouseoverFrame and ab1MouseoverFrame:IsMouseOver() then
          mouseOverAB1 = true
        end
        for _, btn in ipairs(GetStanceButtons()) do
          if btn and btn:IsShown() and btn:IsMouseOver() then
            mouseOverStance = true
            break
          end
        end
        for _, f in ipairs(GetStanceBarFrames()) do
          if f and f:IsShown() and f:IsMouseOver() then
            mouseOverStance = true
            break
          end
        end
        if not mouseOverStance and stanceMouseoverFrame and stanceMouseoverFrame:IsMouseOver() then
          mouseOverStance = true
        end
        for _, btn in ipairs(GetPetButtons()) do
          if btn and btn:IsShown() and btn:IsMouseOver() then
            mouseOverPet = true
            break
          end
        end
        if not mouseOverPet then
          for _, f in ipairs(GetPetBarFrames()) do
            if f and f:IsShown() and f:IsMouseOver() then
              mouseOverPet = true
              break
            end
          end
        end
      end
    end
    local mouseOverAnyHiddenBar = false
    if profile.hideActionBar1InCombat and ab1Mouseover and mouseOverAB1 then mouseOverAnyHiddenBar = true end
    if profile.hideActionBars2to8InCombat and ab2to8Mouseover and mouseOverAB2to8 then mouseOverAnyHiddenBar = true end
    if profile.hideStanceBarInCombat and stanceMouseover and mouseOverStance then mouseOverAnyHiddenBar = true end
    if profile.hidePetBarInCombat and petMouseover and mouseOverPet then mouseOverAnyHiddenBar = true end
    local ab1HiddenByBlizz = false
    local ab2to8HiddenByBlizz = false
    local stanceHiddenByBlizz = false
    local petHiddenByBlizz = false
    local mainBar = _G["MainMenuBar"]
    if mainBar and (not mainBar:IsShown() or mainBar:GetAlpha() < 0.1) then
      ab1HiddenByBlizz = true
    end
    for _, name in ipairs(ab2to8BarsConst) do
      local bar = _G[name]
      if bar and (not bar:IsShown() or bar:GetAlpha() < 0.1) then
        ab2to8HiddenByBlizz = true
        break
      end
    end
    local stanceBar = _G["StanceBar"]
    if stanceBar and (not stanceBar:IsShown() or stanceBar:GetAlpha() < 0.1) then
      stanceHiddenByBlizz = true
    end
    local petBar = _G["PetActionBarFrame"] or _G["PetActionBar"]
    if petBar and (not petBar:IsShown() or petBar:GetAlpha() < 0.1) then
      petHiddenByBlizz = true
    end
    if ab1Mouseover and mouseOverAB1 and ab1HiddenByBlizz then mouseOverAnyHiddenBar = true end
    if ab2to8Mouseover and mouseOverAB2to8 and ab2to8HiddenByBlizz then mouseOverAnyHiddenBar = true end
    if stanceMouseover and mouseOverStance and stanceHiddenByBlizz then mouseOverAnyHiddenBar = true end
    if petMouseover and mouseOverPet and petHiddenByBlizz then mouseOverAnyHiddenBar = true end
    if profile.hideActionBar1InCombat or ab1HiddenByBlizz then
      local showAB1 = mouseOverAnyHiddenBar
      if showAB1 then
        if State.actionBar1Hidden or ab1HiddenByBlizz then
          SetActionBar1Alpha(1)
          State.actionBar1Hidden = false
        end
      else
        if profile.hideActionBar1InCombat and not State.actionBar1Hidden then
          SetActionBar1Alpha(0)
          State.actionBar1Hidden = true
        end
      end
    end
    if profile.hideActionBars2to8InCombat or ab2to8HiddenByBlizz then
      local showAB2to8 = mouseOverAnyHiddenBar
      if showAB2to8 then
        if State.actionBars2to8Hidden or ab2to8HiddenByBlizz then
          SetActionBars2to8Alpha(1)
          State.actionBars2to8Hidden = false
        end
      else
        if profile.hideActionBars2to8InCombat and not State.actionBars2to8Hidden then
          SetActionBars2to8Alpha(0)
          State.actionBars2to8Hidden = true
        end
      end
    end
    if profile.hideStanceBarInCombat or stanceHiddenByBlizz then
      local showStance = mouseOverAnyHiddenBar
      if showStance then
        if State.stanceBarHidden or stanceHiddenByBlizz then
          SetStanceBarAlpha(1)
          State.stanceBarHidden = false
        end
      else
        if profile.hideStanceBarInCombat and not State.stanceBarHidden then
          SetStanceBarAlpha(0)
          State.stanceBarHidden = true
        end
      end
    end
    if profile.hidePetBarInCombat or petHiddenByBlizz then
      local showPet = mouseOverAnyHiddenBar
      if showPet then
        if State.petBarHidden or petHiddenByBlizz then
          SetPetBarAlpha(1)
          State.petBarHidden = false
        end
      else
        if profile.hidePetBarInCombat and not State.petBarHidden then
          SetPetBarAlpha(0)
          State.petBarHidden = true
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
  local hideAB1 = profile.hideActionBar1InCombat == true
  local hideAB2to8 = profile.hideActionBars2to8InCombat == true
  local hideStance = profile.hideStanceBarInCombat == true
  local hidePet = profile.hidePetBarInCombat == true
  local anyMouseover = profile.hideActionBar1Mouseover or profile.hideActionBars2to8Mouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
  if hideAB1 or hideAB2to8 or hideStance or hidePet or anyMouseover then
    if InCombatLockdown() then
      StartMouseCheck()
      if hideAB1 then
        SetActionBar1Alpha(0)
        State.actionBar1Hidden = true
      end
      if hideAB2to8 then
        SetActionBars2to8Alpha(0)
        State.actionBars2to8Hidden = true
      end
      if hideStance then
        SetStanceBarAlpha(0)
        State.stanceBarHidden = true
      end
      if hidePet then
        SetPetBarAlpha(0)
        State.petBarHidden = true
      end
    end
  else
    StopMouseCheck()
    if State.actionBar1Hidden then
      SetActionBar1Alpha(1)
      State.actionBar1Hidden = false
    end
    if State.actionBars2to8Hidden then
      SetActionBars2to8Alpha(1)
      State.actionBars2to8Hidden = false
    end
    if State.stanceBarHidden then
      SetStanceBarAlpha(1)
      State.stanceBarHidden = false
    end
    if State.petBarHidden then
      SetPetBarAlpha(1)
      State.petBarHidden = false
    end
  end
end
addonTable.SetupActionBarHiding = SetupActionBarHiding
local function UpdateActionBarVisibility()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local inCombat = InCombatLockdown()
  if inCombat then
    if profile.hideActionBar1InCombat then
      if not State.actionBar1Hidden then
        SetActionBar1Alpha(0)
        State.actionBar1Hidden = true
      end
    else
      if State.actionBar1Hidden then
        SetActionBar1Alpha(1)
        State.actionBar1Hidden = false
      end
    end
    if profile.hideActionBars2to8InCombat then
      if not State.actionBars2to8Hidden then
        SetActionBars2to8Alpha(0)
        State.actionBars2to8Hidden = true
      end
    else
      if State.actionBars2to8Hidden then
        SetActionBars2to8Alpha(1)
        State.actionBars2to8Hidden = false
      end
    end
    if profile.hideStanceBarInCombat then
      if not State.stanceBarHidden then
        SetStanceBarAlpha(0)
        State.stanceBarHidden = true
      end
    else
      if State.stanceBarHidden then
        SetStanceBarAlpha(1)
        State.stanceBarHidden = false
      end
    end
    if profile.hidePetBarInCombat then
      if not State.petBarHidden then
        SetPetBarAlpha(0)
        State.petBarHidden = true
      end
    else
      if State.petBarHidden then
        SetPetBarAlpha(1)
        State.petBarHidden = false
      end
    end
    local anyHideInCombat = profile.hideActionBar1InCombat or profile.hideActionBars2to8InCombat or profile.hideStanceBarInCombat or profile.hidePetBarInCombat
    local anyMouseover = profile.hideActionBar1Mouseover or profile.hideActionBars2to8Mouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
    if anyHideInCombat or anyMouseover then
      StartMouseCheck()
    else
      StopMouseCheck()
    end
  else
    SetActionBar1Alpha(1)
    SetActionBars2to8Alpha(1)
    SetStanceBarAlpha(1)
    SetPetBarAlpha(1)
    State.actionBar1Hidden = false
    State.actionBars2to8Hidden = false
    State.stanceBarHidden = false
    State.petBarHidden = false
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
    local anyHideInCombat = profile.hideActionBar1InCombat or profile.hideActionBars2to8InCombat or profile.hideStanceBarInCombat or profile.hidePetBarInCombat
    local anyMouseover = profile.hideActionBar1Mouseover or profile.hideActionBars2to8Mouseover or profile.hideStanceBarMouseover or profile.hidePetBarMouseover
    if anyHideInCombat or anyMouseover then
      StartMouseCheck()
    end
    if profile.hideActionBar1InCombat then
      SetActionBar1Alpha(0)
      State.actionBar1Hidden = true
    end
    if profile.hideActionBars2to8InCombat then
      SetActionBars2to8Alpha(0)
      State.actionBars2to8Hidden = true
    end
    if profile.hideStanceBarInCombat then
      SetStanceBarAlpha(0)
      State.stanceBarHidden = true
    end
    if profile.hidePetBarInCombat then
      SetPetBarAlpha(0)
      State.petBarHidden = true
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    StopMouseCheck()
    if State.actionBar1Hidden then
      SetActionBar1Alpha(1)
      State.actionBar1Hidden = false
    end
    if State.actionBars2to8Hidden then
      SetActionBars2to8Alpha(1)
      State.actionBars2to8Hidden = false
    end
    if State.stanceBarHidden then
      SetStanceBarAlpha(1)
      State.stanceBarHidden = false
    end
    if State.petBarHidden then
      SetPetBarAlpha(1)
      State.petBarHidden = false
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
