--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_debuffs.lua
-- Player debuff icon skinning and layout
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, addonTable = ...
local State = addonTable.State
local AddIconBorder = addonTable.AddIconBorder
local GetGlobalFont = addonTable.GetGlobalFont
local debuffIcons = {}
local debuffFrame = nil
local function CreateDebuffIcon(parent, index)
  local size = 32
  local icon = CreateFrame("Button", "CCMDebuffIcon"..index, parent, "BackdropTemplate")
  icon:SetSize(size, size)
  icon:EnableMouse(false)
  icon:Hide()
  icon.icon = icon:CreateTexture(nil, "ARTWORK")
  icon.icon:SetAllPoints()
  icon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon.border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
  icon.border:SetAllPoints()
  icon.border:SetFrameLevel(icon:GetFrameLevel() + 1)
  icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
  icon.cooldown:SetAllPoints()
  icon.cooldown:SetDrawEdge(false)
  icon.cooldown:SetDrawBling(false)
  icon.cooldown:SetDrawSwipe(true)
  icon.cooldown:SetReverse(true)
  icon.cooldown:SetHideCountdownNumbers(false)
  return icon
end
local function CreateDebuffFrame()
  if debuffFrame then return debuffFrame end
  debuffFrame = CreateFrame("Frame", "CCMPlayerDebuffFrame", UIParent)
  debuffFrame:SetSize(400, 50)
  debuffFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
  debuffFrame:SetFrameStrata("MEDIUM")
  debuffFrame:SetMovable(true)
  debuffFrame:EnableMouse(true)
  debuffFrame:RegisterForDrag("LeftButton")
  debuffFrame:SetScript("OnDragStart", function(self)
    if State.debuffPreviewMode then
      local profile = addonTable.GetProfile and addonTable.GetProfile()
      if profile then
        State.debuffDragStartX = profile.playerDebuffX or 0
        State.debuffDragStartY = profile.playerDebuffY or 0
      end
      State.debuffDragStartCX, State.debuffDragStartCY = self:GetCenter()
      self:StartMoving()
      State.debuffDragging = true
    end
  end)
  debuffFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if State.debuffPreviewMode then
      local startCX, startCY = State.debuffDragStartCX, State.debuffDragStartCY
      local curCX, curCY = self:GetCenter()
      if startCX and startCY and curCX and curCY then
        local deltaX = curCX - startCX
        local deltaY = curCY - startCY
        local baseX = State.debuffDragStartX or 0
        local baseY = State.debuffDragStartY or 0
        local newX = math.floor((baseX + deltaX) + 0.5)
        local newY = math.floor((baseY + deltaY) + 0.5)
        local profile = addonTable.GetProfile and addonTable.GetProfile()
        if profile then
          profile.playerDebuffX = newX
          profile.playerDebuffY = newY
          if addonTable.debuffs then
            if addonTable.debuffs.xSlider then
              addonTable.debuffs.xSlider._updating = true
              addonTable.debuffs.xSlider:SetValue(newX)
              addonTable.debuffs.xSlider._updating = false
              addonTable.debuffs.xSlider.valueText:SetText(newX)
            end
            if addonTable.debuffs.ySlider then
              addonTable.debuffs.ySlider._updating = true
              addonTable.debuffs.ySlider:SetValue(newY)
              addonTable.debuffs.ySlider._updating = false
              addonTable.debuffs.ySlider.valueText:SetText(newY)
            end
          end
          self:ClearAllPoints()
          self:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", newX, newY)
        end
      end
    end
    State.debuffDragging = false
    State.debuffDragStartX, State.debuffDragStartY = nil, nil
    State.debuffDragStartCX, State.debuffDragStartCY = nil, nil
  end)
  for i = 1, 16 do
    debuffIcons[i] = CreateDebuffIcon(debuffFrame, i)
  end
  return debuffFrame
end
local function UpdateDebuffIconStyle(icon, profile)
  local borderSize = profile.playerDebuffBorderSize or 1
  local iconSize = profile.playerDebuffSize or 32
  icon:SetSize(iconSize, iconSize)
  if borderSize > 0 then
    icon.border:SetBackdrop({
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = borderSize,
    })
    icon.border:SetBackdropBorderColor(0.8, 0, 0, 1)
    icon.border:Show()
  else
    icon.border:Hide()
  end
end
local function UpdatePlayerDebuffs()
  if State.debuffPreviewMode then
    return
  end
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.enablePlayerDebuffs or profile.enableUnitFrameCustomization == false then
    if debuffFrame then debuffFrame:Hide() end
    return
  end
  if not debuffFrame then
    CreateDebuffFrame()
  end
  local iconSize = profile.playerDebuffSize or 32
  local spacing = profile.playerDebuffSpacing or 2
  local iconsPerRow = profile.playerDebuffIconsPerRow or 10
  local sortDirection = profile.playerDebuffSortDirection or "right"
  local rowGrowth = profile.playerDebuffRowGrowDirection or "down" 
  local debuffFilter = "HARMFUL"
  local continuationToken, slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8,
        slot9, slot10, slot11, slot12, slot13, slot14, slot15, slot16 = C_UnitAuras.GetAuraSlots("player", debuffFilter)
  local slots = {slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8,
                 slot9, slot10, slot11, slot12, slot13, slot14, slot15, slot16}
  local visibleCount = 0
  for i = 1, 16 do
    local slot = slots[i]
    if slot then
      local data = C_UnitAuras.GetAuraDataBySlot("player", slot)
      if data then
        visibleCount = visibleCount + 1
        local icon = debuffIcons[visibleCount]
        if icon then
          if data.icon then
            icon.icon:SetTexture(data.icon)
          end
          if data.auraInstanceID then
            local durationObj = C_UnitAuras.GetAuraDuration("player", data.auraInstanceID)
            if durationObj then
              icon.cooldown:SetCooldownFromDurationObject(durationObj)
              icon.cooldown:Show()
            else
              icon.cooldown:Hide()
            end
          end
          UpdateDebuffIconStyle(icon, profile)
          local index = visibleCount - 1
          local col = index % iconsPerRow
          local row = math.floor(index / iconsPerRow)
          local xPos
          if sortDirection == "left" then
            xPos = -col * (iconSize + spacing)
          else 
            xPos = col * (iconSize + spacing)
          end
          local yPos
          if rowGrowth == "up" then
            yPos = row * (iconSize + spacing)
          else 
            yPos = -row * (iconSize + spacing)
          end
          icon:ClearAllPoints()
          icon:SetPoint("TOPLEFT", debuffFrame, "TOPLEFT", xPos, yPos)
          icon:Show()
        end
      end
    end
  end
  for i = visibleCount + 1, 16 do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
  local numRows = math.ceil(visibleCount / iconsPerRow)
  local iconsInFirstRow = math.min(visibleCount, iconsPerRow)
  local totalWidth = iconsInFirstRow * iconSize + math.max(0, iconsInFirstRow - 1) * spacing
  local totalHeight = numRows * iconSize + math.max(0, numRows - 1) * spacing
  debuffFrame:SetSize(math.max(totalWidth, 1), math.max(totalHeight, 1))
  local xOffset = profile.playerDebuffX or 0
  local yOffset = profile.playerDebuffY or 0
  debuffFrame:ClearAllPoints()
  debuffFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", xOffset, yOffset)
  debuffFrame:Show()
end
local function StartPlayerDebuffsTicker()
  if State.debuffUpdateTicker then return end
  if not debuffFrame then CreateDebuffFrame() end
  debuffFrame:RegisterUnitEvent("UNIT_AURA", "player")
  debuffFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
      UpdatePlayerDebuffs()
    end
  end)
  State.debuffUpdateTicker = true
  UpdatePlayerDebuffs()
end
local function StopPlayerDebuffsTicker()
  if State.debuffUpdateTicker then
    if type(State.debuffUpdateTicker) == "table" and State.debuffUpdateTicker.Cancel then
      State.debuffUpdateTicker:Cancel()
    end
    State.debuffUpdateTicker = nil
  end
  if debuffFrame then
    debuffFrame:UnregisterAllEvents()
    debuffFrame:SetScript("OnEvent", nil)
  end
end
local function ShowDebuffPreview()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  if not debuffFrame then
    CreateDebuffFrame()
  end
  State.debuffPreviewMode = true
  local iconSize = profile.playerDebuffSize or 32
  local spacing = profile.playerDebuffSpacing or 2
  local sortDirection = profile.playerDebuffSortDirection or "right"
  local iconsPerRow = profile.playerDebuffIconsPerRow or 10
  local rowGrowth = profile.playerDebuffRowGrowDirection or "down"
  local previewTextures = {
    136122,
    135849,
    136139,
  }
  for i = 1, 3 do
    local icon = debuffIcons[i]
    if icon then
      icon.icon:SetTexture(previewTextures[i])
      local startTime = GetTime()
      local duration = 5 + i * 2
      icon.cooldown:SetCooldown(startTime, duration)
      icon.cooldown:Show()
      UpdateDebuffIconStyle(icon, profile)
      local index = i - 1
      local col = index % iconsPerRow
      local row = math.floor(index / iconsPerRow)
      local xPos
      if sortDirection == "left" then
        xPos = -col * (iconSize + spacing)
      else
        xPos = col * (iconSize + spacing)
      end
      local yPos
      if rowGrowth == "up" then
        yPos = row * (iconSize + spacing)
      else
        yPos = -row * (iconSize + spacing)
      end
      icon:ClearAllPoints()
      icon:SetPoint("TOPLEFT", debuffFrame, "TOPLEFT", xPos, yPos)
      icon:Show()
    end
  end
  for i = 4, 16 do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
  local numRows = math.ceil(3 / iconsPerRow)
  local iconsInFirstRow = math.min(3, iconsPerRow)
  local totalWidth = iconsInFirstRow * iconSize + math.max(0, iconsInFirstRow - 1) * spacing
  local totalHeight = numRows * iconSize + math.max(0, numRows - 1) * spacing
  debuffFrame:SetSize(math.max(totalWidth, 1), math.max(totalHeight, 1))
  if not State.debuffDragging then
    local xOffset = profile.playerDebuffX or 0
    local yOffset = profile.playerDebuffY or 0
    debuffFrame:ClearAllPoints()
    debuffFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", xOffset, yOffset)
  end
  debuffFrame:Show()
end
local function StopDebuffPreview()
  State.debuffPreviewMode = false
  if debuffFrame then
    debuffFrame:Hide()
  end
  for i = 1, 16 do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
end
local function RestorePlayerDebuffs()
  StopPlayerDebuffsTicker()
  if debuffFrame then
    debuffFrame:Hide()
  end
  for i = 1, 16 do
    if debuffIcons[i] then
      debuffIcons[i]:Hide()
    end
  end
  State.debuffSkinningActive = false
end
local function ApplyPlayerDebuffsSkinning()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile or not profile.enablePlayerDebuffs then
    RestorePlayerDebuffs()
    return
  end
  StartPlayerDebuffsTicker()
  UpdatePlayerDebuffs()
  State.debuffSkinningActive = true
end
addonTable.DebuffFrame = debuffFrame
addonTable.DebuffIcons = debuffIcons
addonTable.ShowDebuffPreview = ShowDebuffPreview
addonTable.StopDebuffPreview = StopDebuffPreview
addonTable.ApplyPlayerDebuffsSkinning = ApplyPlayerDebuffsSkinning
addonTable.RestorePlayerDebuffs = RestorePlayerDebuffs
addonTable.UpdatePlayerDebuffs = UpdatePlayerDebuffs
