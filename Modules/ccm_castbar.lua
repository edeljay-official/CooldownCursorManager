local _, addonTable = ...
local State = addonTable.State
local GetClassColor = addonTable.GetClassColor
local GetGlobalFont = addonTable.GetGlobalFont
local FitTextToBar = addonTable.FitTextToBar
local castbarFrame = CreateFrame("Frame", "CCMCastbar", UIParent, "BackdropTemplate")
castbarFrame:SetSize(250, 20)
castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
castbarFrame:SetFrameStrata("MEDIUM")
castbarFrame:SetClampedToScreen(true)
castbarFrame:SetMovable(false)
castbarFrame:EnableMouse(true)
castbarFrame:RegisterForDrag("LeftButton")
castbarFrame:Hide()
addonTable.CastbarFrame = castbarFrame
castbarFrame.bar = CreateFrame("StatusBar", nil, castbarFrame)
castbarFrame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
castbarFrame.bar:SetStatusBarColor(1, 0.7, 0)
castbarFrame.bar:SetAllPoints()
castbarFrame.bg = castbarFrame.bar:CreateTexture(nil, "BACKGROUND")
castbarFrame.bg:SetAllPoints()
castbarFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
castbarFrame.textOverlay = CreateFrame("Frame", nil, castbarFrame)
castbarFrame.textOverlay:SetAllPoints()
castbarFrame.textOverlay:SetFrameLevel(castbarFrame:GetFrameLevel() + 10)
castbarFrame.spellText = castbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5, 0)
castbarFrame.spellText:SetTextColor(1, 1, 1)
castbarFrame.spellText:SetJustifyH("LEFT")
castbarFrame.timeText = castbarFrame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5, 0)
castbarFrame.timeText:SetTextColor(1, 1, 1)
castbarFrame.timeText:SetJustifyH("RIGHT")
castbarFrame.icon = CreateFrame("Frame", nil, castbarFrame)
castbarFrame.icon:SetSize(24, 24)
castbarFrame.icon:SetPoint("RIGHT", castbarFrame, "LEFT", -4, 0)
castbarFrame.icon.texture = castbarFrame.icon:CreateTexture(nil, "ARTWORK")
castbarFrame.icon.texture:SetAllPoints()
castbarFrame.icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
castbarFrame.border = CreateFrame("Frame", nil, castbarFrame, "BackdropTemplate")
castbarFrame.border:SetFrameLevel(castbarFrame:GetFrameLevel() + 20)
castbarFrame.border:SetAllPoints()
castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
castbarFrame.ticks = {}
for i = 1, 10 do
  local tick = castbarFrame.bar:CreateTexture(nil, "OVERLAY")
  tick:SetColorTexture(1, 1, 1, 0.8)
  tick:SetSize(2, 1)
  tick:Hide()
  castbarFrame.ticks[i] = tick
end
castbarFrame:SetScript("OnDragStart", function(self)
  if not State.guiIsOpen then return end
  if addonTable.activeTab and addonTable.activeTab() ~= 8 then
    if addonTable.SwitchToTab then addonTable.SwitchToTab(8) end
  end
  State.castbarDragging = true
  self:StartMoving()
end)
castbarFrame:SetScript("OnDragStop", function(self)
  if not State.castbarDragging then return end
  self:StopMovingOrSizing()
  local centerX, centerY = UIParent:GetCenter()
  local frameX, frameY = self:GetCenter()
  local newX = math.floor(frameX - centerX + 0.5)
  local newY = math.floor(frameY - centerY + 0.5)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if profile then
    profile.castbarX = newX
    profile.castbarY = newY
    if addonTable.UpdateCastbarSliders then addonTable.UpdateCastbarSliders(newX, newY) end
  end
  State.castbarDragging = false
end)
castbarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and not State.castbarDragging then
    if addonTable.GetGUIOpen and addonTable.GetGUIOpen() then
      if addonTable.SwitchToTab then addonTable.SwitchToTab(8) end
    end
  end
end)
local castbarTextures = {
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
State.castbarActive = false
State.castbarChanneling = false
State.castbarStartTime = 0
State.castbarEndTime = 0
State.castbarDragging = false
State.castbarPreviewMode = false
local channelTickData = {
  [234153] = 6,
  [198590] = 6,
  [755] = 5,
  [5740] = 8,
  [5143] = 5,
  [12051] = 3,
  [205021] = 10,
  [64843] = 4,
  [47540] = 2,
  [204197] = 2,
  [15407] = 4,
  [263165] = 4,
  [48045] = 5,
  [205065] = 4,
  [740] = 4,
  [16914] = 10,
  [61295] = 3,
  [115175] = 8,
  [191837] = 3,
  [382614] = 4,
  [355936] = 3,
  [356995] = 4,
  [361469] = 3,
  [382411] = 4,
  [120360] = 15,
  [257044] = 4,
  [206930] = 3,
  [198013] = 2,
  [258920] = 2,
}
local function UpdateCastbar()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useCastbar then
    if not State.castbarPreviewMode then
      castbarFrame:Hide()
    end
    return
  end
  if State.castbarPreviewMode then
    local width = type(profile.castbarWidth) == "number" and profile.castbarWidth or 250
    local borderSize = type(profile.castbarBorderSize) == "number" and profile.castbarBorderSize or 1
    local autoWidthSource = profile.castbarAutoWidthSource or "off"
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
          width = widthFromEss
          if width < 20 then width = 20 end
        end
      elseif autoWidthSource == "utility" then
        local widthFromUtility = 0
        local utilityBar = UtilityCooldownViewer
        if utilityBar and utilityBar:IsShown() then
          local w = utilityBar:GetWidth()
          if w and w > 0 then
            local scale = utilityBar.GetEffectiveScale and utilityBar:GetEffectiveScale() or 1
            local parentScale = UIParent:GetEffectiveScale()
            if parentScale and parentScale > 0 then
              widthFromUtility = w * (scale / parentScale)
            else
              widthFromUtility = w
            end
          end
        end
        if widthFromUtility > 0 then
          width = widthFromUtility
          if width < 20 then width = 20 end
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
          width = (cbarWidth * cbarCount) + (cbarSpacing * (cbarCount - 1))
          if width < 20 then width = 20 end
        end
      elseif autoWidthSource == "prbhealth" or autoWidthSource == "prbpower" then
        local prbWidth = profile.prbWidth or 220
        local prbAutoWidth = profile.prbAutoWidthSource or "off"
        if prbAutoWidth ~= "off" then
          local essBar = EssentialCooldownViewer
          if essBar and essBar:IsShown() then
            local childCount = addonTable.CollectChildren(essBar, State.tmpChildren)
            local minX, maxX = nil, nil
            for i = 1, childCount do
              local child = State.tmpChildren[i]
              if child and child:IsShown() and child:GetWidth() > 5 then
                local left = child:GetLeft()
                local right = child:GetRight()
                if left and right then
                  if not minX or left < minX then minX = left end
                  if not maxX or right > maxX then maxX = right end
                end
              end
            end
            if minX and maxX then
              prbWidth = (maxX - minX) - (borderSize * 2)
              if prbWidth < 20 then prbWidth = 20 end
            end
          end
        end
        width = prbWidth
      end
    end
    local height = type(profile.castbarHeight) == "number" and profile.castbarHeight or 20
    local centered = profile.castbarCentered == true
    local showIcon = profile.castbarShowIcon ~= false
    local iconSize = height
    local posX
    if centered then
      posX = showIcon and (iconSize / 2) or 0
    else
      posX = type(profile.castbarX) == "number" and profile.castbarX or 0
    end
    local posY = type(profile.castbarY) == "number" and profile.castbarY or -250
    if autoWidthSource ~= "off" and showIcon then
      width = width - iconSize
      if width < 20 then width = 20 end
    end
    width = math.floor(width)
    local bgAlpha = (type(profile.castbarBgAlpha) == "number" and profile.castbarBgAlpha or 70) / 100
    local showTime = profile.castbarShowTime ~= false
    local showSpellName = profile.castbarShowSpellName ~= false
    local timeScale = type(profile.castbarTimeScale) == "number" and profile.castbarTimeScale or 1.0
    local spellNameScale = type(profile.castbarSpellNameScale) == "number" and profile.castbarSpellNameScale or 1.0
    local spellNameX = type(profile.castbarSpellNameXOffset) == "number" and profile.castbarSpellNameXOffset or 0
    local spellNameY = type(profile.castbarSpellNameYOffset) == "number" and profile.castbarSpellNameYOffset or 0
    local timeX = type(profile.castbarTimeXOffset) == "number" and profile.castbarTimeXOffset or 0
    local timeY = type(profile.castbarTimeYOffset) == "number" and profile.castbarTimeYOffset or 0
    local timePrecision = profile.castbarTimePrecision or "1"
    local textR = profile.castbarTextColorR or 1
    local textG = profile.castbarTextColorG or 1
    local textB = profile.castbarTextColorB or 1
    local texturePath = castbarTextures[profile.castbarTexture] or castbarTextures.solid
    castbarFrame.bar:SetStatusBarTexture(texturePath)
    local r, g, b
    if profile.castbarUseClassColor then
      r, g, b = GetClassColor()
    else
      r = profile.castbarColorR or 1
      g = profile.castbarColorG or 0.7
      b = profile.castbarColorB or 0
    end
    castbarFrame.bar:SetStatusBarColor(r, g, b)
    PixelUtil.SetSize(castbarFrame, width, height)
    if not State.castbarDragging then
      castbarFrame:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame, "CENTER", UIParent, "CENTER", posX, posY)
    end
    local bgR = profile.castbarBgColorR or 0.1
    local bgG = profile.castbarBgColorG or 0.1
    local bgB = profile.castbarBgColorB or 0.1
    castbarFrame.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
    if showIcon then
      PixelUtil.SetSize(castbarFrame.icon, iconSize, iconSize)
      castbarFrame.icon:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame.icon, "RIGHT", castbarFrame, "LEFT", 0, 0)
      castbarFrame.icon:Show()
    else
      castbarFrame.icon:Hide()
    end
    if borderSize > 0 then
      castbarFrame.border:ClearAllPoints()
      if showIcon then
        castbarFrame.border:SetPoint("TOPLEFT", castbarFrame.icon, "TOPLEFT", 0, 0)
        castbarFrame.border:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 0, 0)
      else
        castbarFrame.border:SetAllPoints(castbarFrame)
      end
      castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
      castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
      castbarFrame.border:Show()
    else
      castbarFrame.border:Hide()
    end
    local globalFont, globalOutline = GetGlobalFont()
    if showSpellName then
      castbarFrame.spellText:ClearAllPoints()
      castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5 + spellNameX, spellNameY)
      castbarFrame.spellText:SetTextColor(textR, textG, textB)
      castbarFrame.spellText:SetScale(spellNameScale)
      castbarFrame.spellText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
      castbarFrame.spellText:Show()
    else
      castbarFrame.spellText:Hide()
    end
    if showTime then
      castbarFrame.timeText:ClearAllPoints()
      castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5 + timeX, timeY)
      local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
      castbarFrame.timeText:SetText(string.format(timeFormat, 1.5))
      castbarFrame.timeText:SetTextColor(textR, textG, textB)
      castbarFrame.timeText:SetScale(timeScale)
      castbarFrame.timeText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
      castbarFrame.timeText:Show()
    else
      castbarFrame.timeText:Hide()
    end
    for i = 1, 10 do
      castbarFrame.ticks[i]:Hide()
    end
    return
  end
  local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo("player")
  local isChanneling = false
  if not name then
    name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellID = UnitChannelInfo("player")
    isChanneling = name ~= nil
  end
  if not name then
    castbarFrame:Hide()
    State.castbarActive = false
    State.castbarTickKey = nil
    castbarFrame._fallbackSpellID = nil
    castbarFrame._fallbackChanneling = nil
    castbarFrame._fallbackStart = nil
    castbarFrame._fallbackDuration = nil
    castbarFrame.spellText._lastText = nil
    castbarFrame.icon.texture._lastTexture = nil
    for i = 1, 10 do
      castbarFrame.ticks[i]:Hide()
    end
    return
  end
  local width = type(profile.castbarWidth) == "number" and profile.castbarWidth or 250
  local borderSize = type(profile.castbarBorderSize) == "number" and profile.castbarBorderSize or 1
  local autoWidthSource = profile.castbarAutoWidthSource or "off"
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
        width = widthFromEss
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "utility" then
      local widthFromUtility = 0
      local utilityBar = UtilityCooldownViewer
      if utilityBar and utilityBar:IsShown() then
        local w = utilityBar:GetWidth()
        if w and w > 0 then
          local scale = utilityBar.GetEffectiveScale and utilityBar:GetEffectiveScale() or 1
          local parentScale = UIParent:GetEffectiveScale()
          if parentScale and parentScale > 0 then
            widthFromUtility = w * (scale / parentScale)
          else
            widthFromUtility = w
          end
        end
      end
      if widthFromUtility > 0 then
        width = widthFromUtility
        if width < 20 then width = 20 end
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
        width = (cbarWidth * cbarCount) + (cbarSpacing * (cbarCount - 1))
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "prbhealth" or autoWidthSource == "prbpower" then
      local prbWidth = profile.prbWidth or 220
      local prbAutoWidth = profile.prbAutoWidthSource or "off"
      if prbAutoWidth ~= "off" then
        local essBar = EssentialCooldownViewer
        if essBar and essBar:IsShown() then
          local childCount = addonTable.CollectChildren(essBar, State.tmpChildren)
          local minX, maxX = nil, nil
          for i = 1, childCount do
            local child = State.tmpChildren[i]
            if child and child:IsShown() and child:GetWidth() > 5 then
              local left = child:GetLeft()
              local right = child:GetRight()
              if left and right then
                if not minX or left < minX then minX = left end
                if not maxX or right > maxX then maxX = right end
              end
            end
          end
          if minX and maxX then
            prbWidth = (maxX - minX) - (borderSize * 2)
            if prbWidth < 20 then prbWidth = 20 end
          end
        end
      end
      width = prbWidth
    end
  end
  local height = type(profile.castbarHeight) == "number" and profile.castbarHeight or 20
  local centered = profile.castbarCentered == true
  local showIcon = profile.castbarShowIcon ~= false
  local iconSize = height
  local posX
  if centered then
    posX = showIcon and (iconSize / 2) or 0
  else
    posX = type(profile.castbarX) == "number" and profile.castbarX or 0
  end
  local posY = type(profile.castbarY) == "number" and profile.castbarY or -250
  if autoWidthSource ~= "off" and showIcon then
    width = width - iconSize
    if width < 20 then width = 20 end
  end
  width = math.floor(width)
  local bgAlpha = (type(profile.castbarBgAlpha) == "number" and profile.castbarBgAlpha or 70) / 100
  local showTime = profile.castbarShowTime ~= false
  local showSpellName = profile.castbarShowSpellName ~= false
  local timeScale = type(profile.castbarTimeScale) == "number" and profile.castbarTimeScale or 1.0
  local spellNameScale = type(profile.castbarSpellNameScale) == "number" and profile.castbarSpellNameScale or 1.0
  local spellNameX = type(profile.castbarSpellNameXOffset) == "number" and profile.castbarSpellNameXOffset or 0
  local spellNameY = type(profile.castbarSpellNameYOffset) == "number" and profile.castbarSpellNameYOffset or 0
  local timeX = type(profile.castbarTimeXOffset) == "number" and profile.castbarTimeXOffset or 0
  local timeY = type(profile.castbarTimeYOffset) == "number" and profile.castbarTimeYOffset or 0
  local timePrecision = profile.castbarTimePrecision or "1"
  local textR = profile.castbarTextColorR or 1
  local textG = profile.castbarTextColorG or 1
  local textB = profile.castbarTextColorB or 1
  local texturePath = castbarTextures[profile.castbarTexture] or castbarTextures.solid
  local castIconShown = showIcon and texture
  local r, g, b
  if profile.castbarUseClassColor then
    r, g, b = GetClassColor()
  else
    r = profile.castbarColorR or 1
    g = profile.castbarColorG or 0.7
    b = profile.castbarColorB or 0
  end
  local bgR = profile.castbarBgColorR or 0.1
  local bgG = profile.castbarBgColorG or 0.1
  local bgB = profile.castbarBgColorB or 0.1
  local layoutKey = table.concat({
    width, height, posX, posY, autoWidthSource, borderSize, castIconShown and 1 or 0, iconSize,
    texturePath, r, g, b, bgR, bgG, bgB, bgAlpha,
    showSpellName and 1 or 0, spellNameScale, spellNameX, spellNameY,
    showTime and 1 or 0, timeScale, timeX, timeY, timePrecision, textR, textG, textB
  }, "|")
  if State.castbarLayoutKey ~= layoutKey then
    State.castbarLayoutKey = layoutKey
    castbarFrame.bar:SetStatusBarTexture(texturePath)
    castbarFrame.bar:SetStatusBarColor(r, g, b)
    PixelUtil.SetSize(castbarFrame, width, height)
    if not State.castbarDragging then
      castbarFrame:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame, "CENTER", UIParent, "CENTER", posX, posY)
    end
    castbarFrame.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
    if castIconShown then
      PixelUtil.SetSize(castbarFrame.icon, iconSize, iconSize)
      castbarFrame.icon:ClearAllPoints()
      PixelUtil.SetPoint(castbarFrame.icon, "RIGHT", castbarFrame, "LEFT", 0, 0)
      castbarFrame.icon:Show()
    else
      castbarFrame.icon:Hide()
    end
    if borderSize > 0 then
      castbarFrame.border:ClearAllPoints()
      if castIconShown then
        castbarFrame.border:SetPoint("TOPLEFT", castbarFrame.icon, "TOPLEFT", 0, 0)
        castbarFrame.border:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 0, 0)
      else
        castbarFrame.border:SetAllPoints(castbarFrame)
      end
      castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
      castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
      castbarFrame.border:Show()
    else
      castbarFrame.border:Hide()
    end
    local globalFont, globalOutline = GetGlobalFont()
    if showSpellName then
      castbarFrame.spellText:ClearAllPoints()
      castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5 + spellNameX, spellNameY)
      castbarFrame.spellText:SetTextColor(textR, textG, textB)
      castbarFrame.spellText:SetScale(spellNameScale)
      castbarFrame.spellText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
      castbarFrame.spellText:Show()
    else
      castbarFrame.spellText:Hide()
    end
    if showTime then
      castbarFrame.timeText:ClearAllPoints()
      castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5 + timeX, timeY)
      castbarFrame.timeText:SetTextColor(textR, textG, textB)
      castbarFrame.timeText:SetScale(timeScale)
      castbarFrame.timeText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
      castbarFrame.timeText:Show()
    else
      castbarFrame.timeText:Hide()
    end
  end
  if castIconShown and castbarFrame.icon.texture._lastTexture ~= texture then
    castbarFrame.icon.texture:SetTexture(texture)
    castbarFrame.icon.texture._lastTexture = texture
  end
  local okStart, startTime = pcall(function() return startTimeMS / 1000 end)
  local okEnd, endTime = pcall(function() return endTimeMS / 1000 end)
  if not okStart or not okEnd then
    local now = GetTime()
    local fallbackDuration = castbarFrame._fallbackDuration or 1.5
    local fallbackElapsed = castbarFrame._fallbackStart and (now - castbarFrame._fallbackStart) or 0
    if (not castbarFrame._fallbackStart) or (castbarFrame._fallbackChanneling ~= isChanneling) or (fallbackElapsed > (fallbackDuration + 0.05)) then
      castbarFrame._fallbackChanneling = isChanneling
      castbarFrame._fallbackStart = now
      castbarFrame._fallbackDuration = 1.5
    end
    local duration = castbarFrame._fallbackDuration or 1.5
    local elapsed = math.max(0, now - (castbarFrame._fallbackStart or now))
    local progress = isChanneling and (1 - (elapsed / duration)) or (elapsed / duration)
    progress = math.max(0, math.min(1, progress))
    castbarFrame.bar:SetMinMaxValues(0, 1)
    castbarFrame.bar:SetValue(progress)
    if showSpellName and name then castbarFrame.spellText:SetText(name) end
    if showTime then
      local remaining = math.max(0, duration - elapsed)
      local timeDirection = profile.castbarTimeDirection or "remaining"
      local timeValue = timeDirection == "elapsed" and elapsed or remaining
      local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
      castbarFrame.timeText:SetText(string.format(timeFormat, timeValue))
      castbarFrame.timeText:Show()
    else
      castbarFrame.timeText:Hide()
    end
    castbarFrame:Show()
    State.castbarActive = true
    return
  end
  castbarFrame._fallbackSpellID = nil
  castbarFrame._fallbackChanneling = nil
  castbarFrame._fallbackStart = nil
  castbarFrame._fallbackDuration = nil
  local currentTime = GetTime()
  local duration = endTime - startTime
  local elapsed = currentTime - startTime
  local progress
  if isChanneling then
    progress = (endTime - currentTime) / duration
  else
    progress = elapsed / duration
  end
  progress = math.max(0, math.min(1, progress))
  castbarFrame.bar:SetMinMaxValues(0, 1)
  castbarFrame.bar:SetValue(progress)
  if showSpellName then
    castbarFrame.spellText:SetText(name)
  else
    castbarFrame.spellText:Hide()
  end
  if showTime then
    local remaining = math.max(0, endTime - currentTime)
    local elapsedTime = math.max(0, currentTime - startTime)
    local timeDirection = profile.castbarTimeDirection or "remaining"
    local timeValue = timeDirection == "elapsed" and elapsedTime or remaining
    local timeFormat = timePrecision == "0" and "%.0f" or (timePrecision == "2" and "%.2f" or "%.1f")
    castbarFrame.timeText:SetText(string.format(timeFormat, timeValue))
  else
    castbarFrame.timeText:Hide()
  end
  local showTicks = profile.castbarShowTicks ~= false
  if isChanneling and showTicks and spellID and channelTickData[spellID] then
    local numTicks = channelTickData[spellID]
    local barWidth = castbarFrame:GetWidth()
    local barHeight = castbarFrame:GetHeight()
    local tickKey = table.concat({spellID, numTicks, barWidth, barHeight}, "|")
    if State.castbarTickKey ~= tickKey then
      State.castbarTickKey = tickKey
      for i = 1, 10 do
        if i <= numTicks then
          local tickPos = (i / numTicks) * barWidth
          castbarFrame.ticks[i]:ClearAllPoints()
          castbarFrame.ticks[i]:SetPoint("LEFT", castbarFrame.bar, "LEFT", tickPos - 1, 0)
          castbarFrame.ticks[i]:SetSize(2, barHeight)
          castbarFrame.ticks[i]:SetColorTexture(1, 1, 1, 0.7)
          castbarFrame.ticks[i]:Show()
        else
          castbarFrame.ticks[i]:Hide()
        end
      end
    end
  else
    if State.castbarTickKey ~= nil then
      State.castbarTickKey = nil
      for i = 1, 10 do
        castbarFrame.ticks[i]:Hide()
      end
    end
  end
  State.castbarActive = true
  castbarFrame:Show()
end
addonTable.UpdateCastbar = UpdateCastbar
local function SetBlizzardCastbarVisibility(show)
  local castingBar = PlayerCastingBarFrame
  if not castingBar then return end
  if show then
    castingBar:RegisterEvent("UNIT_SPELLCAST_START")
    castingBar:RegisterEvent("UNIT_SPELLCAST_STOP")
    castingBar:RegisterEvent("UNIT_SPELLCAST_FAILED")
    castingBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castingBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    castingBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    castingBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    castingBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castingBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    castingBar:Show()
  else
    castingBar:UnregisterEvent("UNIT_SPELLCAST_START")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_STOP")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_FAILED")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castingBar:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    castingBar:Hide()
  end
end
addonTable.SetBlizzardCastbarVisibility = SetBlizzardCastbarVisibility
local function StartCastbarTicker()
  if State.castbarTicker then return end
  SetBlizzardCastbarVisibility(false)
  State.castbarTicker = C_Timer.NewTicker(0.02, UpdateCastbar)
end
local function StopCastbarTicker()
  local newCastName = UnitCastingInfo("player")
  if not newCastName then
    newCastName = UnitChannelInfo("player")
  end
  if newCastName then
    return
  end
  local hadTicker = State.castbarTicker ~= nil
  if State.castbarTicker then
    State.castbarTicker:Cancel()
    State.castbarTicker = nil
  end
  State.castbarActive = false
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if State.castbarPreviewMode then
    C_Timer.After(0.1, function()
      if State.castbarPreviewMode and not State.castbarActive then
        addonTable.ShowCastbarPreview()
      end
    end)
  else
    castbarFrame:Hide()
  end
  if hadTicker and (not profile or not profile.useCastbar) then
    SetBlizzardCastbarVisibility(true)
  end
end
addonTable.StartCastbarTicker = StartCastbarTicker
addonTable.StopCastbarTicker = StopCastbarTicker
local castbarEventFrame = CreateFrame("Frame")
local function SetupCastbarEvents()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useCastbar then
    castbarEventFrame:UnregisterAllEvents()
    return
  end
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
  castbarEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
end
castbarEventFrame:SetScript("OnEvent", function(self, event, unit, ...)
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.useCastbar then return end
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
    StartCastbarTicker()
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or
         event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or
         event == "UNIT_SPELLCAST_EMPOWER_STOP" then
    C_Timer.After(0.05, function()
      local castName = UnitCastingInfo("player")
      if not castName then castName = UnitChannelInfo("player") end
      if not castName then
        StopCastbarTicker()
      end
    end)
  end
end)
addonTable.SetupCastbarEvents = SetupCastbarEvents
local function ShowCastbarPreview()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  State.castbarPreviewMode = true
  local width = type(profile.castbarWidth) == "number" and profile.castbarWidth or 250
  local borderSize = type(profile.castbarBorderSize) == "number" and profile.castbarBorderSize or 1
  local autoWidthSource = profile.castbarAutoWidthSource or "off"
  if autoWidthSource ~= "off" then
    if autoWidthSource == "essential" then
      local essBar = EssentialCooldownViewer
      if essBar and essBar:IsShown() then
        local childCount = addonTable.CollectChildren(essBar, State.tmpChildren)
        local minX, maxX = nil, nil
        for i = 1, childCount do
          local child = State.tmpChildren[i]
          if child and child:IsShown() and child:GetWidth() > 5 then
            local left = child:GetLeft()
            local right = child:GetRight()
            if left and right then
              if not minX or left < minX then minX = left end
              if not maxX or right > maxX then maxX = right end
            end
          end
        end
        if minX and maxX then
          width = (maxX - minX)
          if width < 20 then width = 20 end
        end
      end
    elseif autoWidthSource == "utility" then
      local utilityBar = UtilityCooldownViewer
      if utilityBar and utilityBar:IsShown() then
        local childCount = addonTable.CollectChildren(utilityBar, State.tmpChildren)
        local minX, maxX = nil, nil
        for i = 1, childCount do
          local child = State.tmpChildren[i]
          if child and child:IsShown() and child:GetWidth() > 5 then
            local left = child:GetLeft()
            local right = child:GetRight()
            if left and right then
              if not minX or left < minX then minX = left end
              if not maxX or right > maxX then maxX = right end
            end
          end
        end
        if minX and maxX then
          width = (maxX - minX)
          if width < 20 then width = 20 end
        end
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
        width = (cbarWidth * cbarCount) + (cbarSpacing * (cbarCount - 1))
        if width < 20 then width = 20 end
      end
    elseif autoWidthSource == "prbhealth" or autoWidthSource == "prbpower" then
      local prbWidth = profile.prbWidth or 220
      local prbAutoWidth = profile.prbAutoWidthSource or "off"
        if prbAutoWidth ~= "off" then
          local essBar = EssentialCooldownViewer
          if essBar and essBar:IsShown() then
            local childCount = addonTable.CollectChildren(essBar, State.tmpChildren)
            local minX, maxX = nil, nil
            for i = 1, childCount do
              local child = State.tmpChildren[i]
              if child and child:IsShown() and child:GetWidth() > 5 then
                local left = child:GetLeft()
                local right = child:GetRight()
              if left and right then
                if not minX or left < minX then minX = left end
                if not maxX or right > maxX then maxX = right end
              end
            end
          end
          if minX and maxX then
            prbWidth = (maxX - minX) - (borderSize * 2)
            if prbWidth < 20 then prbWidth = 20 end
          end
        end
      end
      width = prbWidth
    end
  end
  local height = type(profile.castbarHeight) == "number" and profile.castbarHeight or 20
  local showIcon = profile.castbarShowIcon ~= false
  local iconSize = height
  local posX
  if profile.castbarCentered then
    posX = showIcon and (iconSize / 2) or 0
  else
    posX = type(profile.castbarX) == "number" and profile.castbarX or 0
  end
  local posY = type(profile.castbarY) == "number" and profile.castbarY or -250
  if autoWidthSource ~= "off" and showIcon then
    width = width - iconSize
    if width < 20 then width = 20 end
  end
  width = math.floor(width)
  local bgAlpha = (type(profile.castbarBgAlpha) == "number" and profile.castbarBgAlpha or 70) / 100
  local showTime = profile.castbarShowTime ~= false
  local showSpellName = profile.castbarShowSpellName ~= false
  local timeScale = type(profile.castbarTimeScale) == "number" and profile.castbarTimeScale or 1.0
  local spellNameScale = type(profile.castbarSpellNameScale) == "number" and profile.castbarSpellNameScale or 1.0
  local spellNameX = type(profile.castbarSpellNameXOffset) == "number" and profile.castbarSpellNameXOffset or 0
  local spellNameY = type(profile.castbarSpellNameYOffset) == "number" and profile.castbarSpellNameYOffset or 0
  local timeX = type(profile.castbarTimeXOffset) == "number" and profile.castbarTimeXOffset or 0
  local timeY = type(profile.castbarTimeYOffset) == "number" and profile.castbarTimeYOffset or 0
  local timePrecision = profile.castbarTimePrecision or "1"
  local textR = profile.castbarTextColorR or 1
  local textG = profile.castbarTextColorG or 1
  local textB = profile.castbarTextColorB or 1
  local texturePath = castbarTextures[profile.castbarTexture] or castbarTextures.solid
  castbarFrame.bar:SetStatusBarTexture(texturePath)
  local r, g, b
  if profile.castbarUseClassColor then
    r, g, b = GetClassColor()
  else
    r = profile.castbarColorR or 1
    g = profile.castbarColorG or 0.7
    b = profile.castbarColorB or 0
  end
  castbarFrame.bar:SetStatusBarColor(r, g, b)
  PixelUtil.SetSize(castbarFrame, width, height)
  castbarFrame:ClearAllPoints()
  PixelUtil.SetPoint(castbarFrame, "CENTER", UIParent, "CENTER", posX, posY)
  local bgR = profile.castbarBgColorR or 0.1
  local bgG = profile.castbarBgColorG or 0.1
  local bgB = profile.castbarBgColorB or 0.1
  castbarFrame.bg:SetColorTexture(bgR, bgG, bgB, bgAlpha)
  if showIcon then
    PixelUtil.SetSize(castbarFrame.icon, iconSize, iconSize)
    castbarFrame.icon.texture:SetTexture(136116)
    castbarFrame.icon:ClearAllPoints()
    PixelUtil.SetPoint(castbarFrame.icon, "RIGHT", castbarFrame, "LEFT", 0, 0)
    castbarFrame.icon:Show()
  else
    castbarFrame.icon:Hide()
  end
  if borderSize > 0 then
    castbarFrame.border:ClearAllPoints()
    if showIcon then
      castbarFrame.border:SetPoint("TOPLEFT", castbarFrame.icon, "TOPLEFT", 0, 0)
      castbarFrame.border:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 0, 0)
    else
      castbarFrame.border:SetAllPoints(castbarFrame)
    end
    castbarFrame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize})
    castbarFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
    castbarFrame.border:Show()
  else
    castbarFrame.border:Hide()
  end
  castbarFrame.bar:SetMinMaxValues(0, 1)
  castbarFrame.bar:SetValue(0.65)
  local globalFont, globalOutline = GetGlobalFont()
  if showSpellName then
    castbarFrame.spellText:ClearAllPoints()
    castbarFrame.spellText:SetPoint("LEFT", castbarFrame, "LEFT", 5 + spellNameX, spellNameY)
    castbarFrame.spellText:SetText("Preview Spell")
    castbarFrame.spellText:SetTextColor(textR, textG, textB)
    castbarFrame.spellText:SetScale(spellNameScale)
    castbarFrame.spellText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
    castbarFrame.spellText:Show()
  else
    castbarFrame.spellText:Hide()
  end
  if showTime then
    castbarFrame.timeText:ClearAllPoints()
    castbarFrame.timeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -5 + timeX, timeY)
    local timeFormat = timePrecision == "0" and "1" or (timePrecision == "2" and "1.50" or "1.5")
    castbarFrame.timeText:SetText(timeFormat)
    castbarFrame.timeText:SetTextColor(textR, textG, textB)
    castbarFrame.timeText:SetScale(timeScale)
    castbarFrame.timeText:SetFont(globalFont, 12, globalOutline or "OUTLINE")
    castbarFrame.timeText:Show()
  else
    castbarFrame.timeText:Hide()
  end
  castbarFrame:Show()
end
local function StopCastbarPreview()
  State.castbarPreviewMode = false
  if State.castbarPreviewTimer then
    State.castbarPreviewTimer:Cancel()
    State.castbarPreviewTimer = nil
  end
  if not State.castbarActive then
    castbarFrame:Hide()
  end
end
addonTable.ShowCastbarPreview = ShowCastbarPreview
addonTable.StopCastbarPreview = StopCastbarPreview
addonTable.castbarTextures = castbarTextures
addonTable.channelTickData = channelTickData
