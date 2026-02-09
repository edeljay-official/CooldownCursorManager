local _, addonTable = ...
local State = addonTable.State
local GetClassColor = addonTable.GetClassColor
local GetGlobalFont = addonTable.GetGlobalFont
local FitTextToBar = addonTable.FitTextToBar
local IsRealNumber = addonTable.IsRealNumber
local GetClassPowerConfig = addonTable.GetClassPowerConfig
local IsClassPowerRedundant = addonTable.IsClassPowerRedundant
local SetBlizzardPlayerPowerBarsVisibility = addonTable.SetBlizzardPlayerPowerBarsVisibility
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
prbFrame.healthBar.bg = prbFrame.healthBar:CreateTexture(nil, "BACKGROUND")
prbFrame.healthBar.bg:SetAllPoints()
prbFrame.healthBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
prbFrame.healthBar.border = CreateFrame("Frame", nil, prbFrame.healthBar, "BackdropTemplate")
prbFrame.healthBar.border:SetPoint("TOPLEFT", prbFrame.healthBar, "TOPLEFT", 0, 0)
prbFrame.healthBar.border:SetPoint("BOTTOMRIGHT", prbFrame.healthBar, "BOTTOMRIGHT", 0, 0)
prbFrame.healthBar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
prbFrame.healthBar.border:SetBackdropBorderColor(0, 0, 0, 1)
prbFrame.healthBar.text = prbFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
prbFrame.healthBar.text:SetPoint("CENTER")
prbFrame.healthBar.text:SetTextColor(1, 1, 1)
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
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.prbX = newX
    profile.prbY = newY
    if addonTable.UpdatePRBSliders then addonTable.UpdatePRBSliders(newX, newY) end
  end
  State.prbDragging = false
end)
prbFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.prbDragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(7) end
    end
  end
end)
local function UpdatePRB()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.usePersonalResourceBar then
    prbFrame:Hide()
    SetBlizzardPlayerPowerBarsVisibility(false, false)
    return
  end
  local showMode = profile.prbShowMode or "always"
  if showMode == "combat" and not InCombatLockdown() then
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
    elseif autoWidthSource == "cbar1" or autoWidthSource == "cbar2" or autoWidthSource == "cbar3" then
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
    local texturePaths = {
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
    local healthTexturePath = texturePaths[healthTexture] or texturePaths.solid
    local powerTexturePath = texturePaths[powerTexture] or texturePaths.solid
    local manaTexturePath = texturePaths[manaTexture] or texturePaths.solid
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
    local barOrder = {}
    local clampTotalHeight = nil
    if clampBars then
      table.insert(barOrder, {type = "health", priority = healthYOffset, height = healthHeight, order = 1, active = showHealth})
      table.insert(barOrder, {type = "power", priority = powerYOffset, height = powerHeight, order = 2, active = showPower})
      table.insert(barOrder, {type = "mana", priority = manaYOffset, height = manaHeight, order = 3, active = showManaBar})
      table.insert(barOrder, {type = "classpower", priority = cpYOffset, height = cpHeight, order = 4, active = (showClassPower and hasClassPower)})
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
      PixelUtil.SetPoint(prbFrame.healthBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -healthY)
      PixelUtil.SetSize(prbFrame.healthBar, width, healthHeight)
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
      local fontSize = 12 * healthTextScale
      prbFrame.healthBar.text:SetFont(globalFont, 12, globalOutline or "OUTLINE")
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
          healthText = AbbreviateNumbers(UnitHealth("player"))
        elseif healthTextMode == "both" then
          local valStr = AbbreviateNumbers(UnitHealth("player"))
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
      if showPower then
        yOff = yOff + healthHeight + spacing
      else
        yOff = yOff + healthHeight
      end
    else
      prbFrame.healthBar:Hide()
      prbFrame.healthBar.text:Hide()
    end
    if showPower then
      prbFrame.powerBar:Show()
      prbFrame.powerBar:SetStatusBarTexture(powerTexturePath)
      prbFrame.powerBar:ClearAllPoints()
      local powerY = clampBars and GetBarYPos("power", 0, 0) or (yOff - powerYOffset)
      if clampBars then
        powerYPosForClamp = powerY
      end
      PixelUtil.SetPoint(prbFrame.powerBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -powerY)
      PixelUtil.SetSize(prbFrame.powerBar, width, powerHeight)
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
      prbFrame.powerBar.text:SetFont(globalFont, 12, globalOutline or "OUTLINE")
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
          powerText = AbbreviateNumbers(UnitPower("player", powerType))
        elseif powerTextMode == "both" then
          local valStr = AbbreviateNumbers(UnitPower("player", powerType))
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
      else
        PixelUtil.SetPoint(prbFrame.manaBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -manaY)
      end
      PixelUtil.SetSize(prbFrame.manaBar, width, manaHeight)
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
      prbFrame.manaBar.text:SetFont(globalFont, 12, globalOutline or "OUTLINE")
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
          manaText = AbbreviateNumbers(UnitPower("player", 0))
        elseif manaTextMode == "both" then
          local valStr = AbbreviateNumbers(UnitPower("player", 0))
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
        PixelUtil.SetSize(prbFrame.classPowerBar, width, cpHeight)
        prbFrame.classPowerBar:ClearAllPoints()
        if clampBars then
          local classPowerYPos = GetBarYPos("classpower", 0, 0)
          PixelUtil.SetPoint(prbFrame.classPowerBar, "TOPLEFT", prbFrame, "TOPLEFT", 0, -classPowerYPos)
        elseif profile.prbCentered then
          prbFrame.classPowerBar:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", 0, cpY)
        else
          prbFrame.classPowerBar:SetPoint("BOTTOMLEFT", prbFrame, "TOPLEFT", cpX, cpY)
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
  UpdatePRB()
end
addonTable.UpdatePRBFonts = UpdatePRBFonts
local function StartPRBTicker()
  if State.prbTicker then return end
  State.prbTicker = C_Timer.NewTicker(0.1, UpdatePRB)
end
local function StopPRBTicker()
  if State.prbTicker then
    State.prbTicker:Cancel()
    State.prbTicker = nil
  end
end
addonTable.StartPRBTicker = StartPRBTicker
addonTable.StopPRBTicker = StopPRBTicker
