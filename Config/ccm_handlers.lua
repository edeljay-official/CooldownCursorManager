--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_handlers.lua
-- Configuration UI event handlers and callbacks
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
local addonTable = CCM
local function GetProfile() return addonTable.GetProfile and addonTable.GetProfile() end
local function CreateIcons() if addonTable.CreateIcons then addonTable.CreateIcons() end end
local function ResolveLSMFontValueFromPath(path)
  if type(path) ~= "string" or path == "" then return nil end
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if not LSM then return nil end
  local lsmFonts = LSM:HashTable("font")
  if not lsmFonts then return nil end
  for name, fontPath in pairs(lsmFonts) do
    if fontPath == path then
      return "lsm:" .. name
    end
  end
  return nil
end
local function NormalizeGlobalFontSelection(profile)
  if not profile then return "lsm:Friz Quadrata TT" end
  local sel = profile.cdFont
  if type(sel) == "string" and sel:sub(1, 4) == "lsm:" then
    profile.globalFont = sel
    return sel
  end
  if type(profile.globalFont) == "string" and profile.globalFont:sub(1, 4) == "lsm:" then
    profile.cdFont = profile.globalFont
    return profile.globalFont
  end
  local fromPath = ResolveLSMFontValueFromPath(profile.globalFont)
  if fromPath then
    profile.globalFont = fromPath
    profile.cdFont = fromPath
    return fromPath
  end
  profile.globalFont = "lsm:Friz Quadrata TT"
  profile.cdFont = "lsm:Friz Quadrata TT"
  return profile.globalFont
end
local function RoundToHalf(v)
  return math.floor((tonumber(v) or 0) * 2 + 0.5) / 2
end
local function FormatHalf(v)
  local n = tonumber(v) or 0
  if n == math.floor(n) then
    return tostring(math.floor(n))
  end
  return string.format("%.1f", n)
end
local function SetButtonHighlighted(btn, highlighted)
  if not btn then return end
  if highlighted then
    btn:SetBackdropColor(0.1, 0.4, 0.1, 1)
    btn:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)
    if btn.text then btn.text:SetTextColor(0.2, 1, 0.2) end
    btn._highlighted = true
    btn:SetScript("OnEnter", function()
      btn:SetBackdropColor(0.15, 0.5, 0.15, 1)
      if btn.text then btn.text:SetTextColor(0.3, 1, 0.3) end
    end)
    btn:SetScript("OnLeave", function()
      btn:SetBackdropColor(0.1, 0.4, 0.1, 1)
      if btn.text then btn.text:SetTextColor(0.2, 1, 0.2) end
    end)
  else
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    if btn.text then btn.text:SetTextColor(0.9, 0.9, 0.9) end
    btn._highlighted = false
    btn:SetScript("OnEnter", function()
      btn:SetBackdropColor(0.25, 0.25, 0.3, 1)
      if btn.text then btn.text:SetTextColor(1, 1, 1) end
    end)
    btn:SetScript("OnLeave", function()
      btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
      if btn.text then btn.text:SetTextColor(0.9, 0.9, 0.9) end
    end)
  end
end
addonTable.SetButtonHighlighted = SetButtonHighlighted
local function ShowColorPicker(params)
  if ColorPickerFrame and not ColorPickerFrame._ccmStyled then
    local bg = CreateFrame("Frame", nil, ColorPickerFrame, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", -2, 2)
    bg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    bg:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
    bg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    bg:SetFrameLevel(ColorPickerFrame:GetFrameLevel() - 1)
    ColorPickerFrame._ccmBg = bg
    local title = ColorPickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", ColorPickerFrame, "TOP", 0, -10)
    title:SetText("Color Picker")
    title:SetTextColor(1, 0.82, 0)
    ColorPickerFrame._ccmTitle = title
    ColorPickerFrame._ccmStyled = true
    if ColorPickerFrame.Border then ColorPickerFrame.Border:SetAlpha(0) end
    if ColorPickerFrame.Header then ColorPickerFrame.Header:SetAlpha(0) end
    if ColorPickerFrame.DragBar then ColorPickerFrame.DragBar:SetAlpha(0) end
    if ColorPickerFrame.NineSlice then ColorPickerFrame.NineSlice:Hide() end
    if ColorPickerFrame.Bg then ColorPickerFrame.Bg:SetAlpha(0) end
    if ColorPickerFrame.Background then ColorPickerFrame.Background:SetAlpha(0) end
  end
  if ColorPickerFrame then
    local function StyleBtn(btn)
      if not btn or btn._ccmStyled then return end
      if not btn._ccmBg then
        local bg = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        bg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        bg:SetBackdropColor(0.12, 0.12, 0.14, 1)
        bg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        bg:SetFrameLevel((btn:GetFrameLevel() or 1) - 1)
        btn._ccmBg = bg
      end
      if btn.Left then btn.Left:SetAlpha(0) end
      if btn.Middle then btn.Middle:SetAlpha(0) end
      if btn.Right then btn.Right:SetAlpha(0) end
      if btn.SetNormalTexture then btn:SetNormalTexture("Interface\\Buttons\\WHITE8x8") end
      if btn.SetHighlightTexture then btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8") end
      if btn.SetPushedTexture then btn:SetPushedTexture("Interface\\Buttons\\WHITE8x8") end
      if btn.SetDisabledTexture then btn:SetDisabledTexture("Interface\\Buttons\\WHITE8x8") end
      local function ZeroAlpha(tex)
        if tex and tex.SetVertexColor then tex:SetVertexColor(1, 1, 1, 0) end
      end
      ZeroAlpha(btn:GetNormalTexture())
      ZeroAlpha(btn:GetHighlightTexture())
      ZeroAlpha(btn:GetPushedTexture())
      ZeroAlpha(btn:GetDisabledTexture())
      local fs = btn.GetFontString and btn:GetFontString()
      if fs then fs:SetTextColor(0.9, 0.9, 0.9) end
      btn._ccmStyled = true
    end
    local function StyleEditBox(box)
      if not box or box._ccmStyled then return end
      if not box._ccmBg then
        local bg = CreateFrame("Frame", nil, box, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", box, "TOPLEFT", -2, 2)
        bg:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 2, -2)
        bg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        bg:SetBackdropColor(0.12, 0.12, 0.14, 1)
        bg:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        bg:SetFrameLevel((box:GetFrameLevel() or 1) - 1)
        box._ccmBg = bg
      end
      if box.Left then box.Left:SetAlpha(0) end
      if box.Middle then box.Middle:SetAlpha(0) end
      if box.Right then box.Right:SetAlpha(0) end
      if box.SetTextColor then box:SetTextColor(0.9, 0.9, 0.9) end
      box._ccmStyled = true
    end
    local ok = (ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton) or _G.ColorPickerOkayButton or _G.ColorPickerOkayButton
    local cancel = (ColorPickerFrame.Footer and ColorPickerFrame.Footer.CancelButton) or _G.ColorPickerCancelButton or _G.ColorPickerCancelButton
    local hexBox = (ColorPickerFrame.Content and ColorPickerFrame.Content.HexBox) or _G.ColorPickerHexBox
    StyleBtn(ok)
    StyleBtn(cancel)
    StyleEditBox(hexBox)
    for _, child in ipairs({ColorPickerFrame:GetChildren()}) do
      if child and child.GetObjectType and child:GetObjectType() == "Button" then
        StyleBtn(child)
      elseif child and child.GetObjectType and child:GetObjectType() == "EditBox" then
        StyleEditBox(child)
      end
    end
    if ColorPickerFrame.Content then
      for _, child in ipairs({ColorPickerFrame.Content:GetChildren()}) do
        if child and child.GetObjectType then
          local t = child:GetObjectType()
          if t == "Button" then
            StyleBtn(child)
          elseif t == "EditBox" then
            StyleEditBox(child)
          end
        end
      end
    end
    ColorPickerFrame._ccmButtonsStyled = true
  end
  if ColorPickerFrame then
    ColorPickerFrame:SetFrameStrata("TOOLTIP")
    ColorPickerFrame:SetFrameLevel(5000)
    if ColorPickerFrame.Footer then
      ColorPickerFrame.Footer:SetAlpha(1)
    end
  end
  ColorPickerFrame:SetupColorPickerAndShow(params)
end
addonTable.ShowColorPicker = ShowColorPicker
local function GetRingPreviewTexture(thickness)
  local t = math.floor(tonumber(thickness) or 1)
  if t < 1 then t = 1 end
  if t > 5 then t = 5 end
  return "Interface\\AddOns\\CooldownCursorManager\\media\\Ring_32_T" .. t .. ".png"
end
local function RadialThicknessToPreset(thickness)
  local t = tonumber(thickness)
  if not t then return "middle" end
  if t <= 2 then return "thin" end
  if t >= 4 then return "thick" end
  return "middle"
end
local function PresetToRadialThickness(preset)
  if preset == "thin" then return 2 end
  if preset == "thick" then return 5 end
  return 3
end
local function ABFlagsToMode(inCombat, mouseover, always)
  if always then
    return mouseover and "always_mouseover" or "always"
  end
  if inCombat then
    return mouseover and "combat_mouseover" or "combat"
  end
  return "off"
end
local function ApplyABModeToProfile(profile, inCombatKey, mouseoverKey, alwaysKey, mode)
  if not profile then return end
  local m = mode or "off"
  profile[inCombatKey] = (m == "combat" or m == "combat_mouseover")
  profile[alwaysKey] = (m == "always" or m == "always_mouseover")
  profile[mouseoverKey] = (m == "combat_mouseover" or m == "always_mouseover")
end
local function ForEachABModeDropdown(fn)
  if type(fn) ~= "function" then return end
  if addonTable.actionBar1ModeDD then fn(addonTable.actionBar1ModeDD) end
  for n = 2, 8 do
    local dd = addonTable["actionBar" .. n .. "ModeDD"]
    if dd then fn(dd) end
  end
  if addonTable.stanceBarModeDD then fn(addonTable.stanceBarModeDD) end
  if addonTable.petBarModeDD then fn(addonTable.petBarModeDD) end
end
local function SetABModeDropdownsEnabled(enabled)
  ForEachABModeDropdown(function(dd) dd:SetEnabled(enabled) end)
end
local function ApplyABModeToAllBars(profile, mode)
  if not profile then return end
  ApplyABModeToProfile(profile, "hideActionBar1InCombat", "hideActionBar1Mouseover", "hideActionBar1Always", mode)
  for n = 2, 8 do
    ApplyABModeToProfile(profile, "hideAB"..n.."InCombat", "hideAB"..n.."Mouseover", "hideAB"..n.."Always", mode)
  end
  ApplyABModeToProfile(profile, "hideStanceBarInCombat", "hideStanceBarMouseover", "hideStanceBarAlways", mode)
  ApplyABModeToProfile(profile, "hidePetBarInCombat", "hidePetBarMouseover", "hidePetBarAlways", mode)
end
local function ShowReloadPrompt(text, okText, cancelText)
  if addonTable.ShowReloadPrompt then
    addonTable.ShowReloadPrompt(text, okText, cancelText)
    return
  end
  StaticPopupDialogs["CCM_RELOAD_FALLBACK"] = {
    text = text or "A UI reload is recommended.",
    button1 = okText or "Reload",
    button2 = cancelText or "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show("CCM_RELOAD_FALLBACK")
end
local function ResetAllPreviewHighlights()
  if addonTable.noTargetAlertPreviewOnBtn then
    SetButtonHighlighted(addonTable.noTargetAlertPreviewOnBtn, false)
  end
  if addonTable.castbar and addonTable.castbar.previewOnBtn then
    SetButtonHighlighted(addonTable.castbar.previewOnBtn, false)
  end
  if addonTable.debuffs and addonTable.debuffs.previewOnBtn then
    SetButtonHighlighted(addonTable.debuffs.previewOnBtn, false)
  end
  if addonTable.combatStatusPreviewOnBtn then
    SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, false)
  end
  if addonTable.skyridingPreviewOnBtn then
    SetButtonHighlighted(addonTable.skyridingPreviewOnBtn, false)
  end
end
addonTable.ResetAllPreviewHighlights = ResetAllPreviewHighlights
local function CreateArrowButton(parent, direction, w, h)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(w, h)
  btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
  btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local arrow = btn:CreateTexture(nil, "ARTWORK")
  arrow:SetSize(12, 12)
  arrow:SetPoint("CENTER")
  if direction == "up" then
    arrow:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_up")
  elseif direction == "down" then
    arrow:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down")
  end
  arrow:SetVertexColor(0.7, 0.7, 0.7)
  btn:SetScript("OnEnter", function() btn:SetBackdropColor(0.25, 0.25, 0.3, 1); arrow:SetVertexColor(1, 0.82, 0) end)
  btn:SetScript("OnLeave", function() btn:SetBackdropColor(0.15, 0.15, 0.18, 1); arrow:SetVertexColor(0.7, 0.7, 0.7) end)
  return btn
end
local function CreateDeleteButton(parent, w, h)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(w, h)
  btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  btn:SetBackdropColor(0.25, 0.1, 0.1, 1)
  btn:SetBackdropBorderColor(0.4, 0.2, 0.2, 1)
  local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  t:SetPoint("CENTER")
  t:SetText("X")
  t:SetTextColor(1, 0.4, 0.4)
  btn:SetScript("OnEnter", function() btn:SetBackdropColor(0.4, 0.15, 0.15, 1); t:SetTextColor(1, 0.6, 0.6) end)
  btn:SetScript("OnLeave", function() btn:SetBackdropColor(0.25, 0.1, 0.1, 1); t:SetTextColor(1, 0.4, 0.4) end)
  return btn
end
local function CreateSpellRow(parent, idx, entryID, isEnabled, onToggle, onDelete, onMoveUp, onMoveDown, onReorder)
  local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
  local rowY = -4 - (idx - 1) * 30
  row:SetHeight(28)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, rowY)
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, rowY)
  row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
  row:SetBackdropColor(0.08, 0.08, 0.10, 1)
  row._ccmIdx = idx
  if onReorder then
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function(self)
      parent._ccmDragSource = idx
      parent._ccmDragTarget = nil
      self:SetBackdropColor(0.20, 0.40, 0.20, 1)
    end)
    row:SetScript("OnDragStop", function()
      local sourceIdx = parent._ccmDragSource
      local targetIdx = parent._ccmDragTarget
      parent._ccmDragSource = nil
      parent._ccmDragTarget = nil
      for _, child in ipairs({parent:GetChildren()}) do
        if child.SetBackdropColor then child:SetBackdropColor(0.08, 0.08, 0.10, 1) end
      end
      if sourceIdx and targetIdx and sourceIdx ~= targetIdx then
        onReorder(sourceIdx, targetIdx)
      end
    end)
    row:SetScript("OnEnter", function(self)
      if parent._ccmDragSource and parent._ccmDragSource ~= idx then
        parent._ccmDragTarget = idx
        self:SetBackdropColor(0.15, 0.30, 0.45, 1)
      end
    end)
    row:SetScript("OnLeave", function(self)
      if parent._ccmDragSource then
        if parent._ccmDragTarget == idx then parent._ccmDragTarget = nil end
        if parent._ccmDragSource ~= idx then
          self:SetBackdropColor(0.08, 0.08, 0.10, 1)
        end
      end
    end)
  end
  local isItem = entryID < 0
  local actualID = math.abs(entryID)
  local iconTexture, nameText, idText
  if isItem then
    iconTexture = C_Item.GetItemIconByID(actualID) or GetItemIcon(actualID)
    local itemName = C_Item.GetItemInfo(actualID)
    nameText = itemName or "Loading..."
    idText = " |cff888888(" .. actualID .. ")|r"
  else
    local spellInfo = C_Spell.GetSpellInfo(actualID)
    iconTexture = spellInfo and spellInfo.iconID
    nameText = spellInfo and spellInfo.name or "Loading..."
    idText = " |cff888888(" .. actualID .. ")|r"
  end
  local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  cb:SetPoint("LEFT", row, "LEFT", 2, 0)
  cb:SetSize(20, 20)
  cb:SetChecked(isEnabled ~= false)
  cb:SetScript("OnClick", function(s) onToggle(idx, s:GetChecked()) end)
  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(22, 22)
  icon:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  name:SetJustifyH("LEFT")
  name:SetText(nameText .. idText)
  name:SetTextColor(0.9, 0.9, 0.9)
  local delBtn = CreateDeleteButton(row, 20, 20)
  delBtn:SetPoint("RIGHT", row, "RIGHT", -1, 0)
  delBtn:SetScript("OnClick", function() onDelete(idx) end)
  local downBtn = CreateArrowButton(row, "down", 20, 20)
  downBtn:SetPoint("RIGHT", delBtn, "LEFT", -2, 0)
  downBtn:SetScript("OnClick", function() onMoveDown(idx) end)
  local upBtn = CreateArrowButton(row, "up", 20, 20)
  upBtn:SetPoint("RIGHT", downBtn, "LEFT", -2, 0)
  upBtn:SetScript("OnClick", function() onMoveUp(idx) end)
  name:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
  return row
end
local function UpdateSpellListHeight(spellChild, count)
  local rowHeight = 30
  local padding = 16
  local contentHeight = count * rowHeight + padding
  spellChild:SetHeight(math.max(1, contentHeight - 8))
end
local function RefreshCursorSpellList()
  local cur = addonTable.cursor
  if not cur or not cur.spellChild then return end
  for _, child in ipairs({cur.spellChild:GetChildren()}) do
    child:Hide()
    child:SetParent(nil)
  end
  if not addonTable.GetSpellList then return end
  local spellList, spellEnabled = addonTable.GetSpellList()
  if not spellList then return end
  local function onToggle(idx, checked)
    spellEnabled[idx] = checked
    addonTable.SetSpellList(spellList, spellEnabled)
    CreateIcons()
  end
  local function onDelete(idx)
    table.remove(spellList, idx)
    table.remove(spellEnabled, idx)
    addonTable.SetSpellList(spellList, spellEnabled)
    RefreshCursorSpellList()
    CreateIcons()
  end
  local function onMoveUp(idx)
    if idx > 1 then
      spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]
      spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]
      addonTable.SetSpellList(spellList, spellEnabled)
      RefreshCursorSpellList()
      CreateIcons()
    end
  end
  local function onMoveDown(idx)
    if idx < #spellList then
      spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]
      spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]
      addonTable.SetSpellList(spellList, spellEnabled)
      RefreshCursorSpellList()
      CreateIcons()
    end
  end
  local function onReorder(sourceIdx, targetIdx)
    local entry = table.remove(spellList, sourceIdx)
    local en = table.remove(spellEnabled, sourceIdx)
    table.insert(spellList, targetIdx, entry)
    table.insert(spellEnabled, targetIdx, en)
    addonTable.SetSpellList(spellList, spellEnabled)
    RefreshCursorSpellList()
    CreateIcons()
  end
  for i, eID in ipairs(spellList) do
    CreateSpellRow(cur.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder)
  end
  UpdateSpellListHeight(cur.spellChild, #spellList)
end
local function RefreshCB1SpellList()
  local cb = addonTable.cb1
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBarSpells then return end
  local spellList, spellEnabled = addonTable.GetCustomBarSpells()
  if not spellList then return end
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBarSpells(spellList, spellEnabled); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); addonTable.SetCustomBarSpells(spellList, spellEnabled); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; addonTable.SetCustomBarSpells(spellList, spellEnabled); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; addonTable.SetCustomBarSpells(spellList, spellEnabled); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); addonTable.SetCustomBarSpells(spellList, spellEnabled); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end
  for i, eID in ipairs(spellList) do CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function RefreshCB2SpellList()
  local cb = addonTable.cb2
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBar2Spells then return end
  local spellList, spellEnabled = addonTable.GetCustomBar2Spells()
  if not spellList then return end
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBar2Spells(spellList, spellEnabled); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); addonTable.SetCustomBar2Spells(spellList, spellEnabled); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; addonTable.SetCustomBar2Spells(spellList, spellEnabled); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; addonTable.SetCustomBar2Spells(spellList, spellEnabled); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); addonTable.SetCustomBar2Spells(spellList, spellEnabled); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end
  for i, eID in ipairs(spellList) do CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function RefreshCB3SpellList()
  local cb = addonTable.cb3
  if not cb or not cb.spellChild then return end
  for _, child in ipairs({cb.spellChild:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  if not addonTable.GetCustomBar3Spells then return end
  local spellList, spellEnabled = addonTable.GetCustomBar3Spells()
  if not spellList then return end
  local function onToggle(idx, checked) spellEnabled[idx] = checked; addonTable.SetCustomBar3Spells(spellList, spellEnabled); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  local function onDelete(idx) table.remove(spellList, idx); table.remove(spellEnabled, idx); addonTable.SetCustomBar3Spells(spellList, spellEnabled); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  local function onMoveUp(idx) if idx > 1 then spellList[idx], spellList[idx-1] = spellList[idx-1], spellList[idx]; spellEnabled[idx], spellEnabled[idx-1] = spellEnabled[idx-1], spellEnabled[idx]; addonTable.SetCustomBar3Spells(spellList, spellEnabled); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end
  local function onMoveDown(idx) if idx < #spellList then spellList[idx], spellList[idx+1] = spellList[idx+1], spellList[idx]; spellEnabled[idx], spellEnabled[idx+1] = spellEnabled[idx+1], spellEnabled[idx]; addonTable.SetCustomBar3Spells(spellList, spellEnabled); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end
  local function onReorder(sourceIdx, targetIdx) local entry = table.remove(spellList, sourceIdx); local en = table.remove(spellEnabled, sourceIdx); table.insert(spellList, targetIdx, entry); table.insert(spellEnabled, targetIdx, en); addonTable.SetCustomBar3Spells(spellList, spellEnabled); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end
  for i, eID in ipairs(spellList) do CreateSpellRow(cb.spellChild, i, eID, spellEnabled[i], onToggle, onDelete, onMoveUp, onMoveDown, onReorder) end
  UpdateSpellListHeight(cb.spellChild, #spellList)
end
local function SetupDragDrop(tabFrame, getSpellsFunc, setSpellsFunc, refreshFunc, createIconsFunc, updateFunc)
  tabFrame:SetScript("OnReceiveDrag", function()
    local infoType, info1, info2, info3 = GetCursorInfo()
    if infoType == "spell" then
      local spellID = info3 or info1
      if not info3 and info1 and info2 then
        local spellInfo = C_SpellBook.GetSpellBookItemInfo(info1, Enum.SpellBookSpellBank.Player)
        if spellInfo and spellInfo.spellID then spellID = spellInfo.spellID end
      end
      if spellID and getSpellsFunc and setSpellsFunc then
        local spells, enabled = getSpellsFunc()
        table.insert(spells, spellID)
        table.insert(enabled, true)
        setSpellsFunc(spells, enabled)
        refreshFunc()
        if createIconsFunc then createIconsFunc() end
        if updateFunc then updateFunc() end
      end
      ClearCursor()
    elseif infoType == "item" then
      local itemID = info1
      if itemID and getSpellsFunc and setSpellsFunc then
        local spells, enabled = getSpellsFunc()
        table.insert(spells, -itemID)
        table.insert(enabled, true)
        setSpellsFunc(spells, enabled)
        refreshFunc()
        if createIconsFunc then createIconsFunc() end
        if updateFunc then updateFunc() end
      end
      ClearCursor()
    end
  end)
  tabFrame:SetScript("OnMouseUp", tabFrame:GetScript("OnReceiveDrag"))
end
addonTable.RefreshCursorSpellList = RefreshCursorSpellList
addonTable.RefreshCB1SpellList = RefreshCB1SpellList
addonTable.RefreshCB2SpellList = RefreshCB2SpellList
addonTable.RefreshCB3SpellList = RefreshCB3SpellList
local function UpdateAllControls()
  local profile = GetProfile()
  if not profile then return end
  local function num(val, default) return type(val) == "number" and val or default end
  local currentScale = profile.uiScale or tonumber(GetCVar("uiScale")) or UIParent:GetScale() or 0.71
  local currentMode = profile.uiScaleMode or "disabled"
  if addonTable.uiScaleDD then
    addonTable.uiScaleDD:SetValue(currentMode)
  end
  if addonTable.uiScaleSlider then
    addonTable.uiScaleSlider._updating = true
    addonTable.uiScaleSlider:SetValue(currentScale)
    addonTable.uiScaleSlider._updating = false
    addonTable.uiScaleSlider.valueText:SetText(string.format("%.2f", currentScale))
    if currentMode == "custom" then
      addonTable.uiScaleSlider:Enable()
      addonTable.uiScaleSlider:SetAlpha(1)
    else
      addonTable.uiScaleSlider:Disable()
      addonTable.uiScaleSlider:SetAlpha(0.5)
    end
  end
  if addonTable.customBarsCountSlider then addonTable.customBarsCountSlider:SetValue(num(profile.customBarsCount, 0)); addonTable.customBarsCountSlider.valueText:SetText(math.floor(num(profile.customBarsCount, 0))) end
  if addonTable.iconBorderSlider then addonTable.iconBorderSlider:SetValue(num(profile.iconBorderSize, 1)); addonTable.iconBorderSlider.valueText:SetText(math.floor(num(profile.iconBorderSize, 1))) end
  if addonTable.strataDD then addonTable.strataDD:SetValue(profile.iconStrata or "FULLSCREEN") end
  if addonTable.fontDD then addonTable.fontDD:SetValue(NormalizeGlobalFontSelection(profile)) end
  if addonTable.outlineDD then addonTable.outlineDD:SetValue(profile.globalOutline or "OUTLINE") end
  if addonTable.actionBar1ModeDD then
    addonTable.actionBar1ModeDD:SetValue(ABFlagsToMode(profile.hideActionBar1InCombat == true, profile.hideActionBar1Mouseover == true, profile.hideActionBar1Always == true))
  end
  for n = 2, 8 do
    local dd = addonTable["actionBar"..n.."ModeDD"]
    if dd then
      dd:SetValue(ABFlagsToMode(profile["hideAB"..n.."InCombat"] == true, profile["hideAB"..n.."Mouseover"] == true, profile["hideAB"..n.."Always"] == true))
    end
  end
  if addonTable.stanceBarModeDD then
    addonTable.stanceBarModeDD:SetValue(ABFlagsToMode(profile.hideStanceBarInCombat == true, profile.hideStanceBarMouseover == true, profile.hideStanceBarAlways == true))
  end
  if addonTable.petBarModeDD then
    addonTable.petBarModeDD:SetValue(ABFlagsToMode(profile.hidePetBarInCombat == true, profile.hidePetBarMouseover == true, profile.hidePetBarAlways == true))
  end
  local globalABMode = profile.actionBarGlobalMode or "custom"
  if addonTable.actionBarGlobalModeDD then
    addonTable.actionBarGlobalModeDD:SetValue(globalABMode)
  end
  SetABModeDropdownsEnabled(globalABMode ~= "off")
  if addonTable.hideAB1CB then addonTable.hideAB1CB:SetChecked(profile.hideActionBar1InCombat == true) end
  if addonTable.hideAB1MouseoverCB then addonTable.hideAB1MouseoverCB:SetChecked(profile.hideActionBar1Mouseover == true) end
  if addonTable.hideAB1AlwaysCB then addonTable.hideAB1AlwaysCB:SetChecked(profile.hideActionBar1Always == true) end
  for n = 2, 8 do
    if addonTable["hideAB"..n.."CB"] then addonTable["hideAB"..n.."CB"]:SetChecked(profile["hideAB"..n.."InCombat"] == true) end
    if addonTable["hideAB"..n.."MouseoverCB"] then addonTable["hideAB"..n.."MouseoverCB"]:SetChecked(profile["hideAB"..n.."Mouseover"] == true) end
    if addonTable["hideAB"..n.."AlwaysCB"] then addonTable["hideAB"..n.."AlwaysCB"]:SetChecked(profile["hideAB"..n.."Always"] == true) end
  end
  if addonTable.hideStanceBarCB then addonTable.hideStanceBarCB:SetChecked(profile.hideStanceBarInCombat == true) end
  if addonTable.hideStanceBarMouseoverCB then addonTable.hideStanceBarMouseoverCB:SetChecked(profile.hideStanceBarMouseover == true) end
  if addonTable.hideStanceBarAlwaysCB then addonTable.hideStanceBarAlwaysCB:SetChecked(profile.hideStanceBarAlways == true) end
  if addonTable.hidePetBarCB then addonTable.hidePetBarCB:SetChecked(profile.hidePetBarInCombat == true) end
  if addonTable.hidePetBarMouseoverCB then addonTable.hidePetBarMouseoverCB:SetChecked(profile.hidePetBarMouseover == true) end
  if addonTable.hidePetBarAlwaysCB then addonTable.hidePetBarAlwaysCB:SetChecked(profile.hidePetBarAlways == true) end
  if addonTable.fadeMicroMenuCB then addonTable.fadeMicroMenuCB:SetChecked(profile.fadeMicroMenu == true) end
  if addonTable.hideABBordersCB then addonTable.hideABBordersCB:SetChecked(profile.hideActionBarBorders == true) end
  local abSkinOn = profile.hideActionBarBorders == true
  if addonTable.abSkinSpacingSlider then addonTable.abSkinSpacingSlider:SetValue(profile.abSkinSpacing or 2); addonTable.abSkinSpacingSlider:SetEnabled(abSkinOn); addonTable.abSkinSpacingSlider:SetAlpha(abSkinOn and 1 or 0.4) end
  if addonTable.fadeObjectiveTrackerCB then addonTable.fadeObjectiveTrackerCB:SetChecked(profile.fadeObjectiveTracker == true) end
  if addonTable.fadeBagBarCB then addonTable.fadeBagBarCB:SetChecked(profile.fadeBagBar == true) end
  if addonTable.betterItemLevelCB then addonTable.betterItemLevelCB:SetChecked(profile.betterItemLevel == true) end
  if addonTable.showEquipDetailsCB then addonTable.showEquipDetailsCB:SetChecked(profile.showEquipmentDetails == true) end
  if addonTable.chatClassColorCB then addonTable.chatClassColorCB:SetChecked(profile.chatClassColorNames == true) end
  if addonTable.chatTimestampsCB then addonTable.chatTimestampsCB:SetChecked(profile.chatTimestamps == true) end
  if addonTable.chatTimestampFormatDD then addonTable.chatTimestampFormatDD:SetValue(profile.chatTimestampFormat or "HH:MM") end
  local chatTsEnabled = profile.chatTimestamps == true
  if addonTable.chatTimestampFormatDD then addonTable.chatTimestampFormatDD:SetEnabled(chatTsEnabled) end
  if addonTable.chatTimestampFormatLbl then addonTable.chatTimestampFormatLbl:SetTextColor(chatTsEnabled and 0.9 or 0.4, chatTsEnabled and 0.9 or 0.4, chatTsEnabled and 0.9 or 0.4) end
  if addonTable.chatCopyButtonCB then addonTable.chatCopyButtonCB:SetChecked(profile.chatCopyButton == true) end
  local chatCopyEnabled = profile.chatCopyButton == true
  if addonTable.chatCopyButtonCornerDD then addonTable.chatCopyButtonCornerDD:SetValue(profile.chatCopyButtonCorner or "TOPRIGHT"); addonTable.chatCopyButtonCornerDD:SetEnabled(chatCopyEnabled) end
  if addonTable.chatCopyButtonCornerLbl then addonTable.chatCopyButtonCornerLbl:SetTextColor(chatCopyEnabled and 0.9 or 0.4, chatCopyEnabled and 0.9 or 0.4, chatCopyEnabled and 0.9 or 0.4) end
  if addonTable.chatUrlDetectionCB then addonTable.chatUrlDetectionCB:SetChecked(profile.chatUrlDetection == true) end
  if addonTable.chatBackgroundCB then addonTable.chatBackgroundCB:SetChecked(profile.chatBackground == true) end
  local chatBgEnabled = profile.chatBackground == true
  if addonTable.chatBgAlphaSlider then addonTable.chatBgAlphaSlider:SetValue(num(profile.chatBackgroundAlpha, 40)); addonTable.chatBgAlphaSlider.valueText:SetText(math.floor(num(profile.chatBackgroundAlpha, 40))); addonTable.chatBgAlphaSlider:SetEnabled(chatBgEnabled) end
  if addonTable.chatBgColorBtn then addonTable.chatBgColorBtn:SetEnabled(chatBgEnabled); addonTable.chatBgColorBtn:SetAlpha(chatBgEnabled and 1 or 0.4) end
  if addonTable.chatBgColorSwatch then addonTable.chatBgColorSwatch:SetBackdropColor(num(profile.chatBackgroundColorR, 0), num(profile.chatBackgroundColorG, 0), num(profile.chatBackgroundColorB, 0), 1); addonTable.chatBgColorSwatch:SetAlpha(chatBgEnabled and 1 or 0.4) end
  if addonTable.chatHideButtonsCB then addonTable.chatHideButtonsCB:SetChecked(profile.chatHideButtons == true) end
  if addonTable.chatFadeToggleCB then addonTable.chatFadeToggleCB:SetChecked(profile.chatFadeToggle == true) end
  local chatFadeOn = profile.chatFadeToggle == true
  if addonTable.chatFadeDelaySlider then addonTable.chatFadeDelaySlider:SetValue(num(profile.chatFadeDelay, 20)); addonTable.chatFadeDelaySlider.valueText:SetText(math.floor(num(profile.chatFadeDelay, 20))); addonTable.chatFadeDelaySlider:SetEnabled(chatFadeOn) end
  if addonTable.chatEditBoxDD then addonTable.chatEditBoxDD:SetValue(profile.chatEditBoxPosition or "bottom") end
  if addonTable.chatEditBoxStyledCB then addonTable.chatEditBoxStyledCB:SetChecked(profile.chatEditBoxStyled == true) end
  if addonTable.chatTabFlashCB then addonTable.chatTabFlashCB:SetChecked(profile.chatTabFlash == true) end
  if addonTable.chatHideTabsDD then addonTable.chatHideTabsDD:SetValue(profile.chatHideTabs or "off") end
  if addonTable.skyridingEnabledCB then addonTable.skyridingEnabledCB:SetChecked(profile.skyridingEnabled == true) end
  if addonTable.skyridingHideCDMCB then addonTable.skyridingHideCDMCB:SetChecked(profile.skyridingHideCDM == true) end
  if addonTable.skyridingVigorBarCB then addonTable.skyridingVigorBarCB:SetChecked(profile.skyridingVigorBar ~= false) end
  if addonTable.skyridingSpeedDisplayCB then addonTable.skyridingSpeedDisplayCB:SetChecked(profile.skyridingSpeedDisplay ~= false) end
  if addonTable.skyridingSpeedBarCB then addonTable.skyridingSpeedBarCB:SetChecked(profile.skyridingSpeedBar == true) end
  if addonTable.skyridingCooldownsCB then addonTable.skyridingCooldownsCB:SetChecked(profile.skyridingCooldowns ~= false) end
  if addonTable.skyridingSpeedUnitDD then addonTable.skyridingSpeedUnitDD:SetValue(profile.skyridingSpeedUnit or "percent") end
  if addonTable.skyridingScaleSlider then addonTable.skyridingScaleSlider:SetValue(num(profile.skyridingScale, 100)); addonTable.skyridingScaleSlider.valueText:SetText(math.floor(num(profile.skyridingScale, 100))) end
  if addonTable.skyridingCenteredCB then addonTable.skyridingCenteredCB:SetChecked(profile.skyridingCentered == true) end
  if addonTable.skyridingXSlider then addonTable.skyridingXSlider:SetValue(num(profile.skyridingX, 0)); addonTable.skyridingXSlider.valueText:SetText(math.floor(num(profile.skyridingX, 0))); local cen = profile.skyridingCentered == true; addonTable.skyridingXSlider:SetEnabled(not cen); addonTable.skyridingXSlider:SetAlpha(cen and 0.4 or 1) end
  if addonTable.skyridingYSlider then addonTable.skyridingYSlider:SetValue(num(profile.skyridingY, -200)); addonTable.skyridingYSlider.valueText:SetText(math.floor(num(profile.skyridingY, -200))) end
  if addonTable.skyridingScreenFxCB then local d = C_CVar and C_CVar.GetCVar("DisableAdvancedFlyingFullScreenEffects"); addonTable.skyridingScreenFxCB:SetChecked(d ~= "1") end
  if addonTable.skyridingSpeedFxCB then local d = C_CVar and C_CVar.GetCVar("DisableAdvancedFlyingVelocityVFX"); addonTable.skyridingSpeedFxCB:SetChecked(d ~= "1") end
  if addonTable.skyridingVigorColorSwatch then addonTable.skyridingVigorColorSwatch:SetBackdropColor(num(profile.skyridingVigorColorR, 0.2), num(profile.skyridingVigorColorG, 0.8), num(profile.skyridingVigorColorB, 0.2), 1) end
  if addonTable.skyridingEmptyColorSwatch then addonTable.skyridingEmptyColorSwatch:SetBackdropColor(num(profile.skyridingVigorEmptyColorR, 0.15), num(profile.skyridingVigorEmptyColorG, 0.15), num(profile.skyridingVigorEmptyColorB, 0.15), 1) end
  if addonTable.skyridingRechargeColorSwatch then addonTable.skyridingRechargeColorSwatch:SetBackdropColor(num(profile.skyridingVigorRechargeColorR, 0.85), num(profile.skyridingVigorRechargeColorG, 0.65), num(profile.skyridingVigorRechargeColorB, 0.1), 1) end
  if addonTable.skyridingSpeedColorSwatch then addonTable.skyridingSpeedColorSwatch:SetBackdropColor(num(profile.skyridingSpeedColorR, 0.3), num(profile.skyridingSpeedColorG, 0.6), num(profile.skyridingSpeedColorB, 1.0), 1) end
  if addonTable.skyridingSurgeColorSwatch then addonTable.skyridingSurgeColorSwatch:SetBackdropColor(num(profile.skyridingWhirlingSurgeColorR, 0.85), num(profile.skyridingWhirlingSurgeColorG, 0.65), num(profile.skyridingWhirlingSurgeColorB, 0.1), 1) end
  if addonTable.skyridingWindColorSwatch then addonTable.skyridingWindColorSwatch:SetBackdropColor(num(profile.skyridingSecondWindColorR, 0.2), num(profile.skyridingSecondWindColorG, 0.8), num(profile.skyridingSecondWindColorB, 0.2), 1) end
  if addonTable.skyridingTextureDD then addonTable.skyridingTextureDD:SetValue(profile.skyridingTexture or "solid") end
  if addonTable.prbCB then addonTable.prbCB:SetChecked(profile.usePersonalResourceBar == true) end
  if addonTable.castbarCB then addonTable.castbarCB:SetChecked(profile.useCastbar == true) end
  if addonTable.focusCastbarCB then addonTable.focusCastbarCB:SetChecked(profile.useFocusCastbar == true) end
  if addonTable.playerDebuffsCB then addonTable.playerDebuffsCB:SetChecked(profile.enablePlayerDebuffs == true) end
  if addonTable.unitFrameCustomizationCB then addonTable.unitFrameCustomizationCB:SetChecked(profile.enableUnitFrameCustomization == true) end
  local ufOn = profile.enableUnitFrameCustomization == true
  if addonTable.radialCB then addonTable.radialCB:SetChecked(profile.showRadialCircle == true) end
  if addonTable.radialCombatCB then addonTable.radialCombatCB:SetChecked(profile.cursorCombatOnly == true) end
  if addonTable.radialGcdCB then addonTable.radialGcdCB:SetChecked(profile.showGCD == true) end
  if addonTable.ufClassColorCB then
    local classColorOn = ufOn and profile.ufUseCustomTextures == true
    addonTable.ufClassColorCB:SetChecked(profile.ufClassColor == true)
    addonTable.ufClassColorCB:SetEnabled(classColorOn)
    addonTable.ufClassColorCB:SetAlpha(classColorOn and 1 or 0.5)
  end
  local bigHBPlayerOn = ufOn and profile.ufBigHBPlayerEnabled == true
  if addonTable.ufDisableGlowsCB then
    if bigHBPlayerOn then
      addonTable.ufDisableGlowsCB:SetChecked(true)
      addonTable.ufDisableGlowsCB:SetEnabled(false)
      if addonTable.ufDisableGlowsCB.SetAlpha then addonTable.ufDisableGlowsCB:SetAlpha(0.5) end
    else
      addonTable.ufDisableGlowsCB:SetChecked(profile.ufDisableGlows == true)
      addonTable.ufDisableGlowsCB:SetEnabled(ufOn)
      if addonTable.ufDisableGlowsCB.SetAlpha then addonTable.ufDisableGlowsCB:SetAlpha(ufOn and 1 or 0.5) end
    end
  end
  if addonTable.ufDisableCombatTextCB then
    addonTable.ufDisableCombatTextCB:SetChecked(profile.ufDisableCombatText == true)
    addonTable.ufDisableCombatTextCB:SetEnabled(ufOn)
    if addonTable.ufDisableCombatTextCB.SetAlpha then
      addonTable.ufDisableCombatTextCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  if addonTable.disableTargetBuffsCB then
    addonTable.disableTargetBuffsCB:SetChecked(profile.disableTargetBuffs == true)
    addonTable.disableTargetBuffsCB:SetEnabled(ufOn)
    if addonTable.disableTargetBuffsCB.SetAlpha then
      addonTable.disableTargetBuffsCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  if addonTable.hideEliteTextureCB then
    addonTable.hideEliteTextureCB:SetChecked(profile.hideEliteTexture == true)
    addonTable.hideEliteTextureCB:SetEnabled(ufOn)
    if addonTable.hideEliteTextureCB.SetAlpha then
      addonTable.hideEliteTextureCB:SetAlpha(ufOn and 1 or 0.5)
    end
  end
  local bigHBOn = ufOn and (profile.ufBigHBPlayerEnabled == true or profile.ufBigHBTargetEnabled == true or profile.ufBigHBFocusEnabled == true)
  if addonTable.ufUseCustomTexturesCB then
    addonTable.ufUseCustomTexturesCB:SetChecked(profile.ufUseCustomTextures == true)
    addonTable.ufUseCustomTexturesCB:SetEnabled(ufOn)
    if addonTable.ufUseCustomTexturesCB.SetAlpha then addonTable.ufUseCustomTexturesCB:SetAlpha(ufOn and 1 or 0.5) end
  end
  local texOn = ufOn and profile.ufUseCustomTextures == true
  if addonTable.ufHealthTextureDD then
    addonTable.ufHealthTextureDD:SetValue(profile.ufHealthTexture or "lsm:Clean")
    addonTable.ufHealthTextureDD:SetEnabled(texOn)
    if addonTable.ufHealthTextureDD.SetAlpha then
      addonTable.ufHealthTextureDD:SetAlpha(texOn and 1 or 0.5)
    end
    if addonTable.ufHealthTextureLbl then
      addonTable.ufHealthTextureLbl:SetTextColor(texOn and 0.9 or 0.4, texOn and 0.9 or 0.4, texOn and 0.9 or 0.4)
    end
  end
  if addonTable.useCustomBorderColorCB then
    if bigHBOn then
      addonTable.useCustomBorderColorCB:SetChecked(true)
      addonTable.useCustomBorderColorCB:SetEnabled(false)
    else
      addonTable.useCustomBorderColorCB:SetChecked(profile.useCustomBorderColor == true)
      addonTable.useCustomBorderColorCB:SetEnabled(ufOn)
    end
  end
  if addonTable.ufBorderColorBtn then addonTable.ufBorderColorBtn:SetEnabled(bigHBOn or (ufOn and profile.useCustomBorderColor == true)) end
  if addonTable.ufBorderColorSwatch then
    addonTable.ufBorderColorSwatch:SetBackdropColor(num(profile.ufCustomBorderColorR, 0), num(profile.ufCustomBorderColorG, 0), num(profile.ufCustomBorderColorB, 0), 1)
  end
  if addonTable.ufUseCustomNameColorCB then
    if bigHBOn then
      addonTable.ufUseCustomNameColorCB:SetChecked(true)
      addonTable.ufUseCustomNameColorCB:SetEnabled(false)
      if addonTable.ufUseCustomNameColorCB.SetAlpha then addonTable.ufUseCustomNameColorCB:SetAlpha(0.5) end
    else
      addonTable.ufUseCustomNameColorCB:SetChecked(profile.ufUseCustomNameColor == true)
      addonTable.ufUseCustomNameColorCB:SetEnabled(ufOn)
      if addonTable.ufUseCustomNameColorCB.SetAlpha then addonTable.ufUseCustomNameColorCB:SetAlpha(ufOn and 1 or 0.5) end
    end
  end
  local nameColorOn = ufOn and (bigHBOn or profile.ufUseCustomNameColor == true)
  if addonTable.ufNameColorBtn then
    addonTable.ufNameColorBtn:SetEnabled(nameColorOn)
    if addonTable.ufNameColorBtn.SetAlpha then
      addonTable.ufNameColorBtn:SetAlpha(nameColorOn and 1 or 0.5)
    end
  end
  if addonTable.ufNameColorSwatch then
    addonTable.ufNameColorSwatch:SetBackdropColor(num(profile.ufNameColorR, 1), num(profile.ufNameColorG, 1), num(profile.ufNameColorB, 1), 1)
    if addonTable.ufNameColorSwatch.SetAlpha then
      addonTable.ufNameColorSwatch:SetAlpha(nameColorOn and 1 or 0.5)
    end
  end
  local ufBigPlayer = profile.ufBigHBPlayerEnabled == true
  local ufBigTarget = profile.ufBigHBTargetEnabled == true
  local ufBigFocus = profile.ufBigHBFocusEnabled == true
  local ufBigNameMaxChars = num(profile.ufBigHBNameMaxChars, 0)
  if addonTable.ufBigHBPlayerCB then addonTable.ufBigHBPlayerCB:SetChecked(ufBigPlayer); addonTable.ufBigHBPlayerCB:SetEnabled(ufOn) end
  if addonTable.ufBigHBTargetCB then addonTable.ufBigHBTargetCB:SetChecked(ufBigTarget); addonTable.ufBigHBTargetCB:SetEnabled(ufOn) end
  if addonTable.ufBigHBFocusCB then addonTable.ufBigHBFocusCB:SetChecked(ufBigFocus); addonTable.ufBigHBFocusCB:SetEnabled(ufOn) end
  if addonTable.ufBigHBHideRealmCB then addonTable.ufBigHBHideRealmCB:SetChecked(profile.ufBigHBHideRealm == true); addonTable.ufBigHBHideRealmCB:SetEnabled(bigHBOn and (ufBigTarget or ufBigFocus)) end

  local function ApplyUFBigSlider(slider, value, enabled, fmt)
    if not slider then return end
    slider:SetValue(value)
    if slider.valueText then
      if fmt then slider.valueText:SetText(string.format(fmt, value)) else slider.valueText:SetText(math.floor(value + 0.5)) end
    end
    slider:SetEnabled(enabled)
  end
  ApplyUFBigSlider(addonTable.ufBigHBNameMaxCharsSlider, ufBigNameMaxChars, bigHBOn and (ufBigPlayer or ufBigTarget or ufBigFocus))
  local playerGroupEnabled = bigHBOn and ufBigPlayer
  local targetGroupEnabled = bigHBOn and ufBigTarget
  local focusGroupEnabled = bigHBOn and ufBigFocus
  if addonTable.ufBigHBHidePlayerNameCB then addonTable.ufBigHBHidePlayerNameCB:SetChecked(profile.ufBigHBHidePlayerName == true); addonTable.ufBigHBHidePlayerNameCB:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerLevelDD then addonTable.ufBigHBPlayerLevelDD:SetValue(profile.ufBigHBPlayerLevelMode or "always"); addonTable.ufBigHBPlayerLevelDD:SetEnabled(playerGroupEnabled) end
  local playerNameEnabled = playerGroupEnabled and (profile.ufBigHBHidePlayerName ~= true)
  local playerLevelEnabled = playerGroupEnabled and ((profile.ufBigHBPlayerLevelMode or "always") ~= "hide")
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameXSlider, num(profile.ufBigHBPlayerNameX, 0), playerNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameYSlider, num(profile.ufBigHBPlayerNameY, 0), playerNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerLevelXSlider, num(profile.ufBigHBPlayerLevelX, 0), playerLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerLevelYSlider, num(profile.ufBigHBPlayerLevelY, 0), playerLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBPlayerNameTextScaleSlider, num(profile.ufBigHBPlayerNameTextScale or profile.ufBigHBPlayerTextScale, 1), playerNameEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBigHBPlayerLevelTextScaleSlider, num(profile.ufBigHBPlayerLevelTextScale or profile.ufBigHBPlayerTextScale, 1), playerLevelEnabled, "%.2f")
  if addonTable.ufBigHBPlayerHealAbsorbDD then addonTable.ufBigHBPlayerHealAbsorbDD:SetValue(profile.ufBigHBPlayerHealAbsorb or "on"); addonTable.ufBigHBPlayerHealAbsorbDD:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerDmgAbsorbDD then addonTable.ufBigHBPlayerDmgAbsorbDD:SetValue(profile.ufBigHBPlayerDmgAbsorb or "bar_glow"); addonTable.ufBigHBPlayerDmgAbsorbDD:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerHealPredDD then addonTable.ufBigHBPlayerHealPredDD:SetValue(profile.ufBigHBPlayerHealPred or "on"); addonTable.ufBigHBPlayerHealPredDD:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBPlayerAbsorbStripesCB then addonTable.ufBigHBPlayerAbsorbStripesCB:SetChecked(profile.ufBigHBPlayerAbsorbStripes ~= false); addonTable.ufBigHBPlayerAbsorbStripesCB:SetEnabled(playerGroupEnabled) end
  if addonTable.ufBigHBHideTargetNameCB then addonTable.ufBigHBHideTargetNameCB:SetChecked(profile.ufBigHBHideTargetName == true); addonTable.ufBigHBHideTargetNameCB:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetLevelDD then addonTable.ufBigHBTargetLevelDD:SetValue(profile.ufBigHBTargetLevelMode or "always"); addonTable.ufBigHBTargetLevelDD:SetEnabled(targetGroupEnabled) end
  local targetNameEnabled = targetGroupEnabled and (profile.ufBigHBHideTargetName ~= true)
  local targetLevelEnabled = targetGroupEnabled and ((profile.ufBigHBTargetLevelMode or "always") ~= "hide")
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameXSlider, num(profile.ufBigHBTargetNameX, 0), targetNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameYSlider, num(profile.ufBigHBTargetNameY, 0), targetNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetLevelXSlider, num(profile.ufBigHBTargetLevelX, 0), targetLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetLevelYSlider, num(profile.ufBigHBTargetLevelY, 0), targetLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBTargetNameTextScaleSlider, num(profile.ufBigHBTargetNameTextScale or profile.ufBigHBTargetTextScale, 1), targetNameEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBigHBTargetLevelTextScaleSlider, num(profile.ufBigHBTargetLevelTextScale or profile.ufBigHBTargetTextScale, 1), targetLevelEnabled, "%.2f")
  if addonTable.ufBigHBTargetHealAbsorbDD then addonTable.ufBigHBTargetHealAbsorbDD:SetValue(profile.ufBigHBTargetHealAbsorb or "on"); addonTable.ufBigHBTargetHealAbsorbDD:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetDmgAbsorbDD then addonTable.ufBigHBTargetDmgAbsorbDD:SetValue(profile.ufBigHBTargetDmgAbsorb or "bar_glow"); addonTable.ufBigHBTargetDmgAbsorbDD:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetHealPredDD then addonTable.ufBigHBTargetHealPredDD:SetValue(profile.ufBigHBTargetHealPred or "on"); addonTable.ufBigHBTargetHealPredDD:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBTargetAbsorbStripesCB then addonTable.ufBigHBTargetAbsorbStripesCB:SetChecked(profile.ufBigHBTargetAbsorbStripes ~= false); addonTable.ufBigHBTargetAbsorbStripesCB:SetEnabled(targetGroupEnabled) end
  if addonTable.ufBigHBHideFocusNameCB then addonTable.ufBigHBHideFocusNameCB:SetChecked(profile.ufBigHBHideFocusName == true); addonTable.ufBigHBHideFocusNameCB:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusLevelDD then addonTable.ufBigHBFocusLevelDD:SetValue(profile.ufBigHBFocusLevelMode or "always"); addonTable.ufBigHBFocusLevelDD:SetEnabled(focusGroupEnabled) end
  local focusNameEnabled = focusGroupEnabled and (profile.ufBigHBHideFocusName ~= true)
  local focusLevelEnabled = focusGroupEnabled and ((profile.ufBigHBFocusLevelMode or "always") ~= "hide")
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameXSlider, num(profile.ufBigHBFocusNameX, 0), focusNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameYSlider, num(profile.ufBigHBFocusNameY, 0), focusNameEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusLevelXSlider, num(profile.ufBigHBFocusLevelX, 0), focusLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusLevelYSlider, num(profile.ufBigHBFocusLevelY, 0), focusLevelEnabled)
  ApplyUFBigSlider(addonTable.ufBigHBFocusNameTextScaleSlider, num(profile.ufBigHBFocusNameTextScale or profile.ufBigHBFocusTextScale, 1), focusNameEnabled, "%.2f")
  ApplyUFBigSlider(addonTable.ufBigHBFocusLevelTextScaleSlider, num(profile.ufBigHBFocusLevelTextScale or profile.ufBigHBFocusTextScale, 1), focusLevelEnabled, "%.2f")
  if addonTable.ufBigHBFocusHealAbsorbDD then addonTable.ufBigHBFocusHealAbsorbDD:SetValue(profile.ufBigHBFocusHealAbsorb or "on"); addonTable.ufBigHBFocusHealAbsorbDD:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusDmgAbsorbDD then addonTable.ufBigHBFocusDmgAbsorbDD:SetValue(profile.ufBigHBFocusDmgAbsorb or "bar_glow"); addonTable.ufBigHBFocusDmgAbsorbDD:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusHealPredDD then addonTable.ufBigHBFocusHealPredDD:SetValue(profile.ufBigHBFocusHealPred or "on"); addonTable.ufBigHBFocusHealPredDD:SetEnabled(focusGroupEnabled) end
  if addonTable.ufBigHBFocusAbsorbStripesCB then addonTable.ufBigHBFocusAbsorbStripesCB:SetChecked(profile.ufBigHBFocusAbsorbStripes ~= false); addonTable.ufBigHBFocusAbsorbStripesCB:SetEnabled(focusGroupEnabled) end
  if addonTable.autoRepairCB then addonTable.autoRepairCB:SetChecked(profile.autoRepair == true) end
  if addonTable.showTooltipIDsCB then addonTable.showTooltipIDsCB:SetChecked(profile.showTooltipIDs == true) end
  if addonTable.compactMinimapIconsCB then addonTable.compactMinimapIconsCB:SetChecked(profile.compactMinimapIcons == true) end
  if addonTable.enhancedTooltipCB then addonTable.enhancedTooltipCB:SetChecked(profile.enhancedTooltip == true) end
  if addonTable.autoQuestCB then addonTable.autoQuestCB:SetChecked(profile.autoQuest == true) end
  if addonTable.autoQuestExcludeDailyCB then addonTable.autoQuestExcludeDailyCB:SetChecked(profile.autoQuestExcludeDaily == true) end
  if addonTable.autoQuestExcludeWeeklyCB then addonTable.autoQuestExcludeWeeklyCB:SetChecked(profile.autoQuestExcludeWeekly == true) end
  if addonTable.autoQuestExcludeTrivialCB then addonTable.autoQuestExcludeTrivialCB:SetChecked(profile.autoQuestExcludeTrivial == true) end
  if addonTable.autoQuestExcludeCompletedCB then addonTable.autoQuestExcludeCompletedCB:SetChecked(profile.autoQuestExcludeCompleted == true) end
  if addonTable.autoQuestRewardDD then addonTable.autoQuestRewardDD:SetValue(profile.autoQuestRewardMode or "skip") end
  local aqEnabled = profile.autoQuest == true
  local aqAlpha = aqEnabled and 1 or 0.4
  if addonTable.autoQuestExcludeDailyCB then addonTable.autoQuestExcludeDailyCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeDailyCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestExcludeWeeklyCB then addonTable.autoQuestExcludeWeeklyCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeWeeklyCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestExcludeTrivialCB then addonTable.autoQuestExcludeTrivialCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeTrivialCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestExcludeCompletedCB then addonTable.autoQuestExcludeCompletedCB:SetAlpha(aqAlpha); addonTable.autoQuestExcludeCompletedCB:SetEnabled(aqEnabled) end
  if addonTable.autoQuestRewardDD then addonTable.autoQuestRewardDD:SetAlpha(aqAlpha) end
  if addonTable.autoSellJunkCB then addonTable.autoSellJunkCB:SetChecked(profile.autoSellJunk == true) end
  if addonTable.autoFillDeleteCB then addonTable.autoFillDeleteCB:SetChecked(profile.autoFillDelete == true) end
  if addonTable.quickRoleSignupCB then addonTable.quickRoleSignupCB:SetChecked(profile.quickRoleSignup == true) end
  if addonTable.combatTimerCB then addonTable.combatTimerCB:SetChecked(profile.combatTimerEnabled == true) end
  if addonTable.combatTimerModeDD then addonTable.combatTimerModeDD:SetValue(profile.combatTimerMode or "combat") end
  if addonTable.combatTimerStyleDD then addonTable.combatTimerStyleDD:SetValue(profile.combatTimerStyle or "boxed") end
  if addonTable.combatTimerCenteredCB then addonTable.combatTimerCenteredCB:SetChecked(profile.combatTimerCentered == true) end
  local combatTimerEnabled = profile.combatTimerEnabled == true
  if addonTable.combatTimerModeDD then addonTable.combatTimerModeDD:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerModeLbl then addonTable.combatTimerModeLbl:SetTextColor(combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4) end
  if addonTable.combatTimerStyleDD then addonTable.combatTimerStyleDD:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerStyleLbl then addonTable.combatTimerStyleLbl:SetTextColor(combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4, combatTimerEnabled and 0.9 or 0.4) end
  local combatTimerCentered = profile.combatTimerCentered == true
  if addonTable.combatTimerXSlider then addonTable.combatTimerXSlider:SetValue(num(profile.combatTimerX, 0)); addonTable.combatTimerXSlider.valueText:SetText(math.floor(num(profile.combatTimerX, 0))); addonTable.combatTimerXSlider:SetEnabled(combatTimerEnabled and (not combatTimerCentered)) end
  if addonTable.combatTimerYSlider then addonTable.combatTimerYSlider:SetValue(num(profile.combatTimerY, 200)); addonTable.combatTimerYSlider.valueText:SetText(math.floor(num(profile.combatTimerY, 200))); addonTable.combatTimerYSlider:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerScaleSlider then addonTable.combatTimerScaleSlider:SetValue(num(profile.combatTimerScale, 1)); addonTable.combatTimerScaleSlider.valueText:SetText(string.format("%.2f", num(profile.combatTimerScale, 1))); addonTable.combatTimerScaleSlider:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerTextColorBtn then addonTable.combatTimerTextColorBtn:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerBgColorBtn then addonTable.combatTimerBgColorBtn:SetEnabled(combatTimerEnabled) end
  if addonTable.combatTimerTextColorSwatch then addonTable.combatTimerTextColorSwatch:SetBackdropColor(num(profile.combatTimerTextColorR, 1), num(profile.combatTimerTextColorG, 1), num(profile.combatTimerTextColorB, 1), 1) end
  if addonTable.combatTimerBgColorSwatch then addonTable.combatTimerBgColorSwatch:SetBackdropColor(num(profile.combatTimerBgColorR, 0.12), num(profile.combatTimerBgColorG, 0.12), num(profile.combatTimerBgColorB, 0.12), 1) end
  local crEnabled = profile.crTimerEnabled == true
  if addonTable.crTimerCB then addonTable.crTimerCB:SetChecked(crEnabled) end
  if addonTable.crTimerModeDD then addonTable.crTimerModeDD:SetValue(profile.crTimerMode or "combat"); addonTable.crTimerModeDD:SetEnabled(crEnabled) end
  if addonTable.crTimerModeLbl then addonTable.crTimerModeLbl:SetTextColor(crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4) end
  local crDisplayMode = profile.crTimerDisplay or "timer"
  if addonTable.crTimerDisplayDD then addonTable.crTimerDisplayDD:SetValue(crDisplayMode); addonTable.crTimerDisplayDD:SetEnabled(crEnabled) end
  if addonTable.crTimerDisplayLbl then addonTable.crTimerDisplayLbl:SetTextColor(crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4, crEnabled and 0.9 or 0.4) end
  local layoutEnabled = crEnabled and (crDisplayMode ~= "count")
  if addonTable.crTimerLayoutDD then addonTable.crTimerLayoutDD:SetValue(profile.crTimerLayout or "vertical"); addonTable.crTimerLayoutDD:SetEnabled(layoutEnabled) end
  if addonTable.crTimerLayoutLbl then addonTable.crTimerLayoutLbl:SetTextColor(layoutEnabled and 0.9 or 0.4, layoutEnabled and 0.9 or 0.4, layoutEnabled and 0.9 or 0.4) end
  local crCentered = profile.crTimerCentered == true
  if addonTable.crTimerCenteredCB then addonTable.crTimerCenteredCB:SetChecked(crCentered); addonTable.crTimerCenteredCB:SetEnabled(crEnabled) end
  if addonTable.crTimerXSlider then addonTable.crTimerXSlider:SetValue(num(profile.crTimerX, 0)); addonTable.crTimerXSlider.valueText:SetText(math.floor(num(profile.crTimerX, 0))); addonTable.crTimerXSlider:SetEnabled(crEnabled and (not crCentered)) end
  if addonTable.crTimerYSlider then addonTable.crTimerYSlider:SetValue(num(profile.crTimerY, 150)); addonTable.crTimerYSlider.valueText:SetText(math.floor(num(profile.crTimerY, 150))); addonTable.crTimerYSlider:SetEnabled(crEnabled) end
  if addonTable.crTimerScaleSlider then addonTable.crTimerScaleSlider:SetValue(num(profile.crTimerScale, 1)); addonTable.crTimerScaleSlider.valueText:SetText(string.format("%.2f", num(profile.crTimerScale, 1))); addonTable.crTimerScaleSlider:SetEnabled(crEnabled) end
  local combatStatusEnabled = profile.combatStatusEnabled == true
  if addonTable.combatStatusCB then addonTable.combatStatusCB:SetChecked(combatStatusEnabled) end
  local combatStatusCentered = profile.combatStatusCentered == true
  if addonTable.combatStatusCenteredCB then addonTable.combatStatusCenteredCB:SetChecked(combatStatusCentered); addonTable.combatStatusCenteredCB:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusXSlider then addonTable.combatStatusXSlider:SetValue(num(profile.combatStatusX, 0)); addonTable.combatStatusXSlider.valueText:SetText(math.floor(num(profile.combatStatusX, 0))); addonTable.combatStatusXSlider:SetEnabled(combatStatusEnabled and (not combatStatusCentered)) end
  if addonTable.combatStatusYSlider then addonTable.combatStatusYSlider:SetValue(num(profile.combatStatusY, 280)); addonTable.combatStatusYSlider.valueText:SetText(math.floor(num(profile.combatStatusY, 280))); addonTable.combatStatusYSlider:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusScaleSlider then addonTable.combatStatusScaleSlider:SetValue(num(profile.combatStatusScale, 1)); addonTable.combatStatusScaleSlider.valueText:SetText(string.format("%.2f", num(profile.combatStatusScale, 1))); addonTable.combatStatusScaleSlider:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusEnterColorBtn then addonTable.combatStatusEnterColorBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusLeaveColorBtn then addonTable.combatStatusLeaveColorBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusPreviewOnBtn then addonTable.combatStatusPreviewOnBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusPreviewOffBtn then addonTable.combatStatusPreviewOffBtn:SetEnabled(combatStatusEnabled) end
  if addonTable.combatStatusEnterColorSwatch then addonTable.combatStatusEnterColorSwatch:SetBackdropColor(num(profile.combatStatusEnterColorR, 1), num(profile.combatStatusEnterColorG, 1), num(profile.combatStatusEnterColorB, 1), 1) end
  if addonTable.combatStatusLeaveColorSwatch then addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(num(profile.combatStatusLeaveColorR, 1), num(profile.combatStatusLeaveColorG, 1), num(profile.combatStatusLeaveColorB, 1), 1) end
  if addonTable.minimapCB then
    local compact = profile.compactMinimapIcons == true
    if compact then
      profile.showMinimapButton = true
      addonTable.minimapCB:SetChecked(true)
    else
      addonTable.minimapCB:SetChecked(profile.showMinimapButton ~= false)
    end
    if addonTable.minimapCB.SetEnabled then addonTable.minimapCB:SetEnabled(not compact) end
    if addonTable.minimapCB.SetAlpha then addonTable.minimapCB:SetAlpha(compact and 0.5 or 1) end
    if addonTable.minimapCB.label then
      addonTable.minimapCB.label:SetTextColor(compact and 0.5 or 0.9, compact and 0.5 or 0.9, compact and 0.5 or 0.9)
    end
  end
  if addonTable.radiusSlider then addonTable.radiusSlider:SetValue(num(profile.radialRadius, 30)); addonTable.radiusSlider.valueText:SetText(math.floor(num(profile.radialRadius, 30))) end
  if addonTable.radialThicknessDD then addonTable.radialThicknessDD:SetValue(RadialThicknessToPreset(profile.radialThickness)) end
  if addonTable.colorSwatch then addonTable.colorSwatch:SetBackdropColor(num(profile.radialColorR, 1), num(profile.radialColorG, 1), num(profile.radialColorB, 1), 1) end
  if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end
  local shapeEnabled = (profile.selfHighlightShape or "off") ~= "off"
  if addonTable.selfHighlightCB then addonTable.selfHighlightCB:SetChecked(shapeEnabled) end
  if addonTable.selfHighlightVisibilityDD then addonTable.selfHighlightVisibilityDD:SetValue(profile.selfHighlightCombatOnly and "combat" or "always"); addonTable.selfHighlightVisibilityDD:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightSizeSlider then addonTable.selfHighlightSizeSlider:SetValue(num(profile.selfHighlightSize, 20)); addonTable.selfHighlightSizeSlider.valueText:SetText(math.floor(num(profile.selfHighlightSize, 20))); addonTable.selfHighlightSizeSlider:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightYSlider then addonTable.selfHighlightYSlider:SetValue(num(profile.selfHighlightY, 0)); addonTable.selfHighlightYSlider.valueText:SetText(math.floor(num(profile.selfHighlightY, 0))); addonTable.selfHighlightYSlider:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightThicknessDD then addonTable.selfHighlightThicknessDD:SetValue(profile.selfHighlightThickness or "medium"); addonTable.selfHighlightThicknessDD:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightThicknessLbl then addonTable.selfHighlightThicknessLbl:SetTextColor(shapeEnabled and 0.9 or 0.4, shapeEnabled and 0.9 or 0.4, shapeEnabled and 0.9 or 0.4) end
  if addonTable.selfHighlightOutlineCB then addonTable.selfHighlightOutlineCB:SetChecked(profile.selfHighlightOutline ~= false); addonTable.selfHighlightOutlineCB:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightColorBtn then addonTable.selfHighlightColorBtn:SetEnabled(shapeEnabled) end
  if addonTable.selfHighlightColorSwatch then addonTable.selfHighlightColorSwatch:SetBackdropColor(num(profile.selfHighlightColorR, 1), num(profile.selfHighlightColorG, 1), num(profile.selfHighlightColorB, 1), 1) end
  local ntaEnabled = profile.noTargetAlertEnabled == true
  if addonTable.noTargetAlertCB then addonTable.noTargetAlertCB:SetChecked(ntaEnabled) end
  if addonTable.noTargetAlertFlashCB then addonTable.noTargetAlertFlashCB:SetChecked(profile.noTargetAlertFlash == true); addonTable.noTargetAlertFlashCB:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertXSlider then addonTable.noTargetAlertXSlider:SetValue(num(profile.noTargetAlertX, 0)); addonTable.noTargetAlertXSlider.valueText:SetText(math.floor(num(profile.noTargetAlertX, 0))); addonTable.noTargetAlertXSlider:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertYSlider then addonTable.noTargetAlertYSlider:SetValue(num(profile.noTargetAlertY, 100)); addonTable.noTargetAlertYSlider.valueText:SetText(math.floor(num(profile.noTargetAlertY, 100))); addonTable.noTargetAlertYSlider:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertFontSizeSlider then addonTable.noTargetAlertFontSizeSlider:SetValue(num(profile.noTargetAlertFontSize, 36)); addonTable.noTargetAlertFontSizeSlider.valueText:SetText(math.floor(num(profile.noTargetAlertFontSize, 36))); addonTable.noTargetAlertFontSizeSlider:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertColorBtn then addonTable.noTargetAlertColorBtn:SetEnabled(ntaEnabled) end
  if addonTable.noTargetAlertColorSwatch then addonTable.noTargetAlertColorSwatch:SetBackdropColor(num(profile.noTargetAlertColorR, 1), num(profile.noTargetAlertColorG, 0), num(profile.noTargetAlertColorB, 0), 1) end
  if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
  if addonTable.UpdateNoTargetAlert then addonTable.UpdateNoTargetAlert() end
  if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
  if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end
  if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
  local cur = addonTable.cursor
  if cur then
    if cur.enabledCB then cur.enabledCB:SetChecked(profile.cursorIconsEnabled ~= false) end
    if cur.combatOnlyCB then cur.combatOnlyCB:SetChecked(profile.iconsCombatOnly == true) end
    if cur.gcdCB then cur.gcdCB:SetChecked(profile.cursorShowGCD == true) end
    if cur.iconSizeSlider then cur.iconSizeSlider:SetValue(num(profile.iconSize, 23)); cur.iconSizeSlider.valueText:SetText(math.floor(num(profile.iconSize, 23))) end
    if cur.spacingSlider then cur.spacingSlider:SetValue(num(profile.iconSpacing, 2)); cur.spacingSlider.valueText:SetText(math.floor(num(profile.iconSpacing, 2))) end
    if cur.cdTextSlider then cur.cdTextSlider:SetValue(num(profile.cdTextScale, 1.0)); cur.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.cdTextScale, 1.0))) end
    if cur.stackTextSlider then cur.stackTextSlider:SetValue(num(profile.stackTextScale, 1.0)); cur.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.stackTextScale, 1.0))) end
    if cur.iconsPerRowSlider then cur.iconsPerRowSlider:SetValue(num(profile.iconsPerRow, 10)); cur.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.iconsPerRow, 10))) end
    if cur.cooldownModeDD then cur.cooldownModeDD:SetValue(profile.cooldownIconMode or "show") end
    if cur.showModeDD then cur.showModeDD:SetValue(profile.showMode or "always") end
    if cur.offsetXSlider then cur.offsetXSlider:SetValue(num(profile.offsetX, 10)); cur.offsetXSlider.valueText:SetText(math.floor(num(profile.offsetX, 10))) end
    if cur.offsetYSlider then cur.offsetYSlider:SetValue(num(profile.offsetY, 25)); cur.offsetYSlider.valueText:SetText(math.floor(num(profile.offsetY, 25))) end
    if cur.directionDD then cur.directionDD:SetValue(profile.layoutDirection or "horizontal") end
    if cur.stackAnchorDD then cur.stackAnchorDD:SetValue(profile.stackTextPosition or "BOTTOMRIGHT") end
    if cur.buffOverlayCB then cur.buffOverlayCB:SetChecked(profile.useBuffOverlay ~= false) end
    if cur.stackXSlider then cur.stackXSlider:SetValue(num(profile.stackTextOffsetX, 0)); cur.stackXSlider.valueText:SetText(math.floor(num(profile.stackTextOffsetX, 0))) end
    if cur.stackYSlider then cur.stackYSlider:SetValue(num(profile.stackTextOffsetY, 0)); cur.stackYSlider.valueText:SetText(math.floor(num(profile.stackTextOffsetY, 0))) end
  end
  local cb1 = addonTable.cb1
  if cb1 then
    if cb1.outOfCombatCB then cb1.outOfCombatCB:SetChecked(profile.customBarOutOfCombat ~= false) end
    if cb1.gcdCB then cb1.gcdCB:SetChecked(profile.customBarShowGCD == true) end
    if cb1.buffOverlayCB then cb1.buffOverlayCB:SetChecked(profile.customBarUseBuffOverlay ~= false) end
    if cb1.centeredCB then cb1.centeredCB:SetChecked(profile.customBarCentered == true) end
    if cb1.iconSizeSlider then cb1.iconSizeSlider:SetValue(num(profile.customBarIconSize, 30)); cb1.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBarIconSize, 30))) end
    if cb1.spacingSlider then cb1.spacingSlider:SetValue(num(profile.customBarSpacing, 2)); cb1.spacingSlider.valueText:SetText(math.floor(num(profile.customBarSpacing, 2))) end
    if cb1.cdTextSlider then cb1.cdTextSlider:SetValue(num(profile.customBarCdTextScale, 1.0)); cb1.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBarCdTextScale, 1.0))) end
    if cb1.stackTextSlider then cb1.stackTextSlider:SetValue(num(profile.customBarStackTextScale, 1.0)); cb1.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBarStackTextScale, 1.0))) end
    if cb1.iconsPerRowSlider then cb1.iconsPerRowSlider:SetValue(num(profile.customBarIconsPerRow, 20)); cb1.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBarIconsPerRow, 20))) end
    if cb1.cdModeDD then cb1.cdModeDD:SetValue(profile.customBarCooldownMode or "show") end
    if cb1.showModeDD then cb1.showModeDD:SetValue(profile.customBarShowMode or "always") end
    if cb1.xSlider then cb1.xSlider:SetValue(num(profile.customBarX, 0)); cb1.xSlider.valueText:SetText(math.floor(num(profile.customBarX, 0))) end
    if cb1.ySlider then cb1.ySlider:SetValue(num(profile.customBarY, -200)); cb1.ySlider.valueText:SetText(math.floor(num(profile.customBarY, -200))) end
    if cb1.directionDD then cb1.directionDD:SetValue(profile.customBarDirection or "horizontal") end
    if cb1.anchorDD then cb1.anchorDD:SetValue(profile.customBarAnchorPoint or "LEFT") end
    if cb1.growthDD then cb1.growthDD:SetValue(profile.customBarGrowth or "DOWN") end
    if cb1.anchorTargetBox then cb1.anchorTargetBox:SetText(profile.customBarAnchorFrame or "UIParent") end
    if cb1.stackAnchorDD then cb1.stackAnchorDD:SetValue(profile.customBarStackTextPosition or "BOTTOMRIGHT") end
    if cb1.stackXSlider then cb1.stackXSlider:SetValue(num(profile.customBarStackTextOffsetX, 0)); cb1.stackXSlider.valueText:SetText(math.floor(num(profile.customBarStackTextOffsetX, 0))) end
    if cb1.stackYSlider then cb1.stackYSlider:SetValue(num(profile.customBarStackTextOffsetY, 0)); cb1.stackYSlider.valueText:SetText(math.floor(num(profile.customBarStackTextOffsetY, 0))) end
  end
  local cb2 = addonTable.cb2
  if cb2 then
    if cb2.outOfCombatCB then cb2.outOfCombatCB:SetChecked(profile.customBar2OutOfCombat ~= false) end
    if cb2.gcdCB then cb2.gcdCB:SetChecked(profile.customBar2ShowGCD == true) end
    if cb2.buffOverlayCB then cb2.buffOverlayCB:SetChecked(profile.customBar2UseBuffOverlay ~= false) end
    if cb2.centeredCB then cb2.centeredCB:SetChecked(profile.customBar2Centered == true) end
    if cb2.iconSizeSlider then cb2.iconSizeSlider:SetValue(num(profile.customBar2IconSize, 30)); cb2.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBar2IconSize, 30))) end
    if cb2.spacingSlider then cb2.spacingSlider:SetValue(num(profile.customBar2Spacing, 2)); cb2.spacingSlider.valueText:SetText(math.floor(num(profile.customBar2Spacing, 2))) end
    if cb2.cdTextSlider then cb2.cdTextSlider:SetValue(num(profile.customBar2CdTextScale, 1.0)); cb2.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar2CdTextScale, 1.0))) end
    if cb2.stackTextSlider then cb2.stackTextSlider:SetValue(num(profile.customBar2StackTextScale, 1.0)); cb2.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar2StackTextScale, 1.0))) end
    if cb2.iconsPerRowSlider then cb2.iconsPerRowSlider:SetValue(num(profile.customBar2IconsPerRow, 20)); cb2.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBar2IconsPerRow, 20))) end
    if cb2.cdModeDD then cb2.cdModeDD:SetValue(profile.customBar2CooldownMode or "show") end
    if cb2.showModeDD then cb2.showModeDD:SetValue(profile.customBar2ShowMode or "always") end
    if cb2.xSlider then cb2.xSlider:SetValue(num(profile.customBar2X, 0)); cb2.xSlider.valueText:SetText(math.floor(num(profile.customBar2X, 0))) end
    if cb2.ySlider then cb2.ySlider:SetValue(num(profile.customBar2Y, -250)); cb2.ySlider.valueText:SetText(math.floor(num(profile.customBar2Y, -250))) end
    if cb2.directionDD then cb2.directionDD:SetValue(profile.customBar2Direction or "horizontal") end
    if cb2.anchorDD then cb2.anchorDD:SetValue(profile.customBar2AnchorPoint or "LEFT") end
    if cb2.growthDD then cb2.growthDD:SetValue(profile.customBar2Growth or "DOWN") end
    if cb2.anchorTargetBox then cb2.anchorTargetBox:SetText(profile.customBar2AnchorFrame or "UIParent") end
    if cb2.stackAnchorDD then cb2.stackAnchorDD:SetValue(profile.customBar2StackTextPosition or "BOTTOMRIGHT") end
    if cb2.stackXSlider then cb2.stackXSlider:SetValue(num(profile.customBar2StackTextOffsetX, 0)); cb2.stackXSlider.valueText:SetText(math.floor(num(profile.customBar2StackTextOffsetX, 0))) end
    if cb2.stackYSlider then cb2.stackYSlider:SetValue(num(profile.customBar2StackTextOffsetY, 0)); cb2.stackYSlider.valueText:SetText(math.floor(num(profile.customBar2StackTextOffsetY, 0))) end
  end
  local cb3 = addonTable.cb3
  if cb3 then
    if cb3.outOfCombatCB then cb3.outOfCombatCB:SetChecked(profile.customBar3OutOfCombat ~= false) end
    if cb3.gcdCB then cb3.gcdCB:SetChecked(profile.customBar3ShowGCD == true) end
    if cb3.buffOverlayCB then cb3.buffOverlayCB:SetChecked(profile.customBar3UseBuffOverlay ~= false) end
    if cb3.centeredCB then cb3.centeredCB:SetChecked(profile.customBar3Centered == true) end
    if cb3.iconSizeSlider then cb3.iconSizeSlider:SetValue(num(profile.customBar3IconSize, 30)); cb3.iconSizeSlider.valueText:SetText(math.floor(num(profile.customBar3IconSize, 30))) end
    if cb3.spacingSlider then cb3.spacingSlider:SetValue(num(profile.customBar3Spacing, 2)); cb3.spacingSlider.valueText:SetText(math.floor(num(profile.customBar3Spacing, 2))) end
    if cb3.cdTextSlider then cb3.cdTextSlider:SetValue(num(profile.customBar3CdTextScale, 1.0)); cb3.cdTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar3CdTextScale, 1.0))) end
    if cb3.stackTextSlider then cb3.stackTextSlider:SetValue(num(profile.customBar3StackTextScale, 1.0)); cb3.stackTextSlider.valueText:SetText(string.format("%.1f", num(profile.customBar3StackTextScale, 1.0))) end
    if cb3.iconsPerRowSlider then cb3.iconsPerRowSlider:SetValue(num(profile.customBar3IconsPerRow, 20)); cb3.iconsPerRowSlider.valueText:SetText(math.floor(num(profile.customBar3IconsPerRow, 20))) end
    if cb3.cdModeDD then cb3.cdModeDD:SetValue(profile.customBar3CooldownMode or "show") end
    if cb3.showModeDD then cb3.showModeDD:SetValue(profile.customBar3ShowMode or "always") end
    if cb3.xSlider then cb3.xSlider:SetValue(num(profile.customBar3X, 0)); cb3.xSlider.valueText:SetText(math.floor(num(profile.customBar3X, 0))) end
    if cb3.ySlider then cb3.ySlider:SetValue(num(profile.customBar3Y, -300)); cb3.ySlider.valueText:SetText(math.floor(num(profile.customBar3Y, -300))) end
    if cb3.directionDD then cb3.directionDD:SetValue(profile.customBar3Direction or "horizontal") end
    if cb3.anchorDD then cb3.anchorDD:SetValue(profile.customBar3AnchorPoint or "LEFT") end
    if cb3.growthDD then cb3.growthDD:SetValue(profile.customBar3Growth or "DOWN") end
    if cb3.anchorTargetBox then cb3.anchorTargetBox:SetText(profile.customBar3AnchorFrame or "UIParent") end
    if cb3.stackAnchorDD then cb3.stackAnchorDD:SetValue(profile.customBar3StackTextPosition or "BOTTOMRIGHT") end
    if cb3.stackXSlider then cb3.stackXSlider:SetValue(num(profile.customBar3StackTextOffsetX, 0)); cb3.stackXSlider.valueText:SetText(math.floor(num(profile.customBar3StackTextOffsetX, 0))) end
    if cb3.stackYSlider then cb3.stackYSlider:SetValue(num(profile.customBar3StackTextOffsetY, 0)); cb3.stackYSlider.valueText:SetText(math.floor(num(profile.customBar3StackTextOffsetY, 0))) end
  end
  if addonTable.skinningModeDD then
    local skinMode = "none"
    if profile.enableMasque then skinMode = "masque"
    elseif profile.blizzardBarSkinning ~= false then skinMode = "ccm" end
    addonTable.skinningModeDD:SetValue(skinMode)
  end
  if addonTable.disableBlizzCDMCB then addonTable.disableBlizzCDMCB:SetChecked(profile.disableBlizzCDM == true) end
  if addonTable.buffBarCB then addonTable.buffBarCB:SetChecked(profile.useBuffBar == true) end
  if addonTable.essentialBarCB then addonTable.essentialBarCB:SetChecked(profile.useEssentialBar == true) end
  if addonTable.buffSizeSlider then addonTable.buffSizeSlider:SetValue(num(profile.buffBarIconSizeOffset, 0)); addonTable.buffSizeSlider.valueText:SetText(math.floor(num(profile.buffBarIconSizeOffset, 0))) end
  local sa = addonTable.standalone
  if sa then
    if sa.skinBuffCB then sa.skinBuffCB:SetChecked(profile.standaloneSkinBuff == true) end
    if sa.skinEssentialCB then sa.skinEssentialCB:SetChecked(profile.standaloneSkinEssential == true) end
    if sa.skinUtilityCB then sa.skinUtilityCB:SetChecked(profile.standaloneSkinUtility == true) end
    if sa.buffCenteredCB then sa.buffCenteredCB:SetChecked(profile.standaloneBuffCentered == true) end
    if sa.essentialCenteredCB then sa.essentialCenteredCB:SetChecked(profile.standaloneEssentialCentered == true) end
    if sa.utilityCenteredCB then sa.utilityCenteredCB:SetChecked(profile.standaloneUtilityCentered == true) end
    if sa.spacingSlider then sa.spacingSlider:SetValue(num(profile.standaloneSpacing, 0)); sa.spacingSlider.valueText:SetText(math.floor(num(profile.standaloneSpacing, 0))) end
    if sa.borderSizeSlider then sa.borderSizeSlider:SetValue(num(profile.standaloneIconBorderSize, 1)); sa.borderSizeSlider.valueText:SetText(math.floor(num(profile.standaloneIconBorderSize, 1))) end
    if sa.buffSizeSlider then sa.buffSizeSlider:SetValue(num(profile.standaloneBuffSize, 45)); sa.buffSizeSlider.valueText:SetText(num(profile.standaloneBuffSize, 45)) end
    if sa.buffYSlider then local yVal = profile.blizzBarBuffY or profile.standaloneBuffY or 0; local n = RoundToHalf(num(yVal, 0)); sa.buffYSlider:SetValue(n); sa.buffYSlider.valueText:SetText(FormatHalf(n)) end
    if sa.buffXSlider then local xVal = profile.blizzBarBuffX or -150; local n = RoundToHalf(num(xVal, -150)); sa.buffXSlider:SetValue(n); sa.buffXSlider.valueText:SetText(FormatHalf(n)) end
    if sa.buffIconsPerRowSlider then sa.buffIconsPerRowSlider:SetValue(num(profile.standaloneBuffIconsPerRow, 0)); sa.buffIconsPerRowSlider.valueText:SetText(math.floor(num(profile.standaloneBuffIconsPerRow, 0))) end
    if sa.buffRowsDD then sa.buffRowsDD:SetValue(tostring(math.max(1, math.min(2, math.floor(num(profile.standaloneBuffMaxRows, 2)))))) end
    if sa.buffGrowDD then sa.buffGrowDD:SetValue(profile.standaloneBuffGrowDirection or "right") end
    if sa.buffRowGrowDD then sa.buffRowGrowDD:SetValue(profile.standaloneBuffRowGrowDirection or "down") end
    if sa.essentialSizeSlider then sa.essentialSizeSlider:SetValue(num(profile.standaloneEssentialSize, 45)); sa.essentialSizeSlider.valueText:SetText(num(profile.standaloneEssentialSize, 45)) end
    if sa.essentialSecondRowSizeSlider then sa.essentialSecondRowSizeSlider:SetValue(num(profile.standaloneEssentialSecondRowSize, num(profile.standaloneEssentialSize, 45))); sa.essentialSecondRowSizeSlider.valueText:SetText(num(profile.standaloneEssentialSecondRowSize, num(profile.standaloneEssentialSize, 45))) end
    if sa.essentialIconsPerRowSlider then sa.essentialIconsPerRowSlider:SetValue(num(profile.standaloneEssentialIconsPerRow, 0)); sa.essentialIconsPerRowSlider.valueText:SetText(math.floor(num(profile.standaloneEssentialIconsPerRow, 0))) end
    if sa.essentialRowsDD then sa.essentialRowsDD:SetValue(tostring(math.max(1, math.min(2, math.floor(num(profile.standaloneEssentialMaxRows, 2)))))) end
    if sa.essentialGrowDD then sa.essentialGrowDD:SetValue(profile.standaloneEssentialGrowDirection or "right") end
    if sa.essentialRowGrowDD then sa.essentialRowGrowDD:SetValue(profile.standaloneEssentialRowGrowDirection or "down") end
    if sa.essentialYSlider then local yVal = profile.blizzBarEssentialY or profile.standaloneEssentialY or 50; local n = RoundToHalf(num(yVal, 50)); sa.essentialYSlider:SetValue(n); sa.essentialYSlider.valueText:SetText(FormatHalf(n)) end
    if sa.essentialXSlider then local xVal = profile.blizzBarEssentialX or 0; local n = RoundToHalf(num(xVal, 0)); sa.essentialXSlider:SetValue(n); sa.essentialXSlider.valueText:SetText(FormatHalf(n)) end
    if sa.utilitySizeSlider then sa.utilitySizeSlider:SetValue(num(profile.standaloneUtilitySize, 45)); sa.utilitySizeSlider.valueText:SetText(num(profile.standaloneUtilitySize, 45)) end
    if sa.utilityIconsPerRowSlider then sa.utilityIconsPerRowSlider:SetValue(num(profile.standaloneUtilityIconsPerRow, 0)); sa.utilityIconsPerRowSlider.valueText:SetText(math.floor(num(profile.standaloneUtilityIconsPerRow, 0))) end
    if sa.utilityRowsDD then sa.utilityRowsDD:SetValue(tostring(math.max(1, math.min(2, math.floor(num(profile.standaloneUtilityMaxRows, 2)))))) end
    if sa.utilityGrowDD then sa.utilityGrowDD:SetValue(profile.standaloneUtilityGrowDirection or "right") end
    if sa.utilityRowGrowDD then sa.utilityRowGrowDD:SetValue(profile.standaloneUtilityRowGrowDirection or "down") end
    if sa.utilityAutoWidthDD then sa.utilityAutoWidthDD:SetValue(profile.standaloneUtilityAutoWidth or "off") end
    if sa.utilityYSlider then local yVal = profile.blizzBarUtilityY or profile.standaloneUtilityY or -50; local n = RoundToHalf(num(yVal, -50)); sa.utilityYSlider:SetValue(n); sa.utilityYSlider.valueText:SetText(FormatHalf(n)) end
    if sa.utilityXSlider then local xVal = profile.blizzBarUtilityX or 150; local n = RoundToHalf(num(xVal, 150)); sa.utilityXSlider:SetValue(n); sa.utilityXSlider.valueText:SetText(FormatHalf(n)) end
  end
  if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
  if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
  if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
  NormalizeGlobalFontSelection(profile)
  RefreshCursorSpellList()
  RefreshCB1SpellList()
  RefreshCB2SpellList()
  RefreshCB3SpellList()
  if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end
end
local function UpdateProfileDisplay()
  if CooldownCursorManagerDB and CooldownCursorManagerDB.currentProfile and addonTable.profileText then
    addonTable.profileText:SetText(CooldownCursorManagerDB.currentProfile)
  end
end
local function UpdateProfileList()
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then return end
  local profileDropdown = addonTable.profileDropdown
  local profileList = addonTable.profileList
  local profileText = addonTable.profileText
  if not profileDropdown or not profileList then return end
  profileDropdown:SetScript("OnMouseDown", function()
    if profileList:IsShown() then profileList:Hide() return end
    for _, child in ipairs({profileList:GetChildren()}) do child:Hide() end
    local yOff = 0
    local _, playerClass = UnitClass("player")
    local profileClasses = CooldownCursorManagerDB.profileClasses or {}
    local function CreateProfileButton(name)
      local btn = CreateFrame("Button", nil, profileList, "BackdropTemplate")
      btn:SetSize(108, 22)
      btn:SetPoint("TOPLEFT", profileList, "TOPLEFT", 1, -yOff - 1)
      local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
      btnText:SetText(name)
      if name == CooldownCursorManagerDB.currentProfile then btnText:SetTextColor(1, 0.82, 0) else btnText:SetTextColor(0.9, 0.9, 0.9) end
      btn:SetScript("OnEnter", function() btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"}); btn:SetBackdropColor(0.25, 0.25, 0.3, 1) end)
      btn:SetScript("OnLeave", function() btn:SetBackdrop(nil) end)
      btn:SetScript("OnClick", function()
        CooldownCursorManagerDB.currentProfile = name
        if addonTable.SaveCurrentProfileForSpec then
          addonTable.SaveCurrentProfileForSpec()
        else
          local playerName = UnitName("player")
          local realmName = GetRealmName()
          if playerName and realmName then
            local characterKey = playerName .. "-" .. realmName
            CooldownCursorManagerDB.characterProfiles = CooldownCursorManagerDB.characterProfiles or {}
            CooldownCursorManagerDB.characterProfiles[characterKey] = name
          end
        end
        profileText:SetText(name)
        profileList:Hide()
        UpdateAllControls()
        CreateIcons()
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
        ShowReloadPrompt("Profile switched to '" .. name .. "'.\n\nA UI reload is recommended for all changes to take effect. Reload now?", "Reload", "Later")
      end)
      yOff = yOff + 22
    end
    local sharedProfiles = {}
    local classProfiles = {}
    for name in pairs(CooldownCursorManagerDB.profiles) do
      local profClass = profileClasses[name]
      if name == "Default" or profClass == nil then
        table.insert(sharedProfiles, name)
      elseif profClass == playerClass then
        table.insert(classProfiles, name)
      end
    end
    table.sort(sharedProfiles)
    table.sort(classProfiles)
    for _, name in ipairs(sharedProfiles) do
      CreateProfileButton(name)
    end
    if #classProfiles > 0 then
      local sep = profileList:CreateTexture(nil, "ARTWORK")
      sep:SetHeight(1)
      sep:SetPoint("TOPLEFT", profileList, "TOPLEFT", 4, -yOff - 4)
      sep:SetPoint("TOPRIGHT", profileList, "TOPRIGHT", -4, -yOff - 4)
      sep:SetColorTexture(1, 0.82, 0, 1)
      yOff = yOff + 8
      for _, name in ipairs(classProfiles) do
        CreateProfileButton(name)
      end
    end
    profileList:SetHeight(yOff + 2)
    profileList:SetFrameLevel(math.max((profileDropdown:GetFrameLevel() or 1) + 200, 2000))
    profileList:Show()
  end)
end
addonTable.UpdateAllControls = UpdateAllControls
addonTable.UpdateProfileDisplay = UpdateProfileDisplay
addonTable.UpdateProfileList = UpdateProfileList
local function InitHandlers()
  local tabFrames = addonTable.tabFrames
  local function RecreateAllIcons()
    CreateIcons()
    if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
    if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
    if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
    if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end
    if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
    if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
    if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
    if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
  end
  local function ApplyUIScale(scale)
    SetCVar("uiScale", scale)
    UIParent:SetScale(scale)
  end
  local function UpdateSliderEnabled(mode)
    if addonTable.uiScaleSlider then
      if mode == "custom" then
        addonTable.uiScaleSlider:Enable()
        addonTable.uiScaleSlider:SetAlpha(1)
      else
        addonTable.uiScaleSlider:Disable()
        addonTable.uiScaleSlider:SetAlpha(0.5)
      end
    end
  end
  if addonTable.uiScaleDD then
    addonTable.uiScaleDD.onSelect = function(v)
      local p = GetProfile()
      if not p then return end
      p.uiScaleMode = v
      UpdateSliderEnabled(v)
      if v == "disabled" then
        ShowReloadPrompt("UI Scale disabled. A reload is recommended to restore WoW defaults.", "Reload Now", "Later")
        return
      end
      local scale
      if v == "1080p" then
        scale = 0.71111
        if addonTable.uiScaleSlider then
          addonTable.uiScaleSlider:SetValue(scale)
          addonTable.uiScaleSlider.valueText:SetText(string.format("%.2f", scale))
        end
      elseif v == "1440p" then
        scale = 0.53333
        if addonTable.uiScaleSlider then
          addonTable.uiScaleSlider:SetValue(scale)
          addonTable.uiScaleSlider.valueText:SetText(string.format("%.2f", scale))
        end
      else
        scale = addonTable.uiScaleSlider and addonTable.uiScaleSlider:GetValue() or 0.71
      end
      p.uiScale = scale
      ApplyUIScale(scale)
      print("|cff00ff00CCM:|r UI Scale set to " .. string.format("%.2f", scale))
    end
  end
  if addonTable.uiScaleSlider then
    addonTable.uiScaleSlider:SetScript("OnValueChanged", function(s, v)
      if s._updating then return end
      local p = GetProfile()
      if p then
        local scale = math.floor(v * 100 + 0.5) / 100
        s.valueText:SetText(string.format("%.2f", scale))
        local currentMode = p.uiScaleMode or "disabled"
        if currentMode == "disabled" then return end
        p.uiScale = scale
        if addonTable.uiScaleDD then
          if currentMode ~= "custom" then
            if math.abs(scale - 0.71111) < 0.01 then
              p.uiScaleMode = "1080p"
              addonTable.uiScaleDD:SetValue("1080p")
            elseif math.abs(scale - 0.53333) < 0.01 then
              p.uiScaleMode = "1440p"
              addonTable.uiScaleDD:SetValue("1440p")
            else
              p.uiScaleMode = "custom"
              addonTable.uiScaleDD:SetValue("custom")
            end
          end
        end
      end
    end)
    addonTable.uiScaleSlider:SetScript("OnMouseUp", function()
      local p = GetProfile()
      if p and p.uiScale then
        ApplyUIScale(p.uiScale)
        print("|cff00ff00CCM:|r UI Scale set to " .. string.format("%.2f", p.uiScale))
      end
    end)
  end
  if addonTable.customBarsCountSlider then
    addonTable.customBarsCountSlider:SetScript("OnValueChanged", function(s, v)
      local p = GetProfile()
      if p then
        local count = math.floor(v)
        p.customBarsCount = count
        s.valueText:SetText(count)
        local wasBar1Enabled = p.customBarEnabled
        local wasBar2Enabled = p.customBar2Enabled
        local wasBar3Enabled = p.customBar3Enabled
        p.customBarEnabled = (count >= 1)
        p.customBar2Enabled = (count >= 2)
        p.customBar3Enabled = (count >= 3)
        if p.customBarEnabled and not wasBar1Enabled then
          if p.customBarCentered == nil then p.customBarCentered = true end
          if p.customBarX == nil then p.customBarX = 0 end
        end
        if p.customBar2Enabled and not wasBar2Enabled then
          if p.customBar2Centered == nil then p.customBar2Centered = true end
          if p.customBar2X == nil then p.customBar2X = 0 end
        end
        if p.customBar3Enabled and not wasBar3Enabled then
          if p.customBar3Centered == nil then p.customBar3Centered = true end
          if p.customBar3X == nil then p.customBar3X = 0 end
        end
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end
        if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end
        if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
        if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      end
    end)
  end
  if addonTable.iconBorderSlider then
    addonTable.iconBorderSlider:SetScript("OnValueChanged", function(s, v)
      local p = GetProfile()
      if p then
        p.iconBorderSize = math.floor(v)
        s.valueText:SetText(math.floor(v))
        RecreateAllIcons()
        if p.hideActionBarBorders and addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end
      end
    end)
  end
  if addonTable.strataDD then
    addonTable.strataDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.iconStrata = v
        RecreateAllIcons()
      end
    end
  end
  if addonTable.fontDD then
    addonTable.fontDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        if type(v) ~= "string" or v:sub(1, 4) ~= "lsm:" then
          return
        end
        p.cdFont = v
        p.globalFont = v
        RecreateAllIcons()
        if addonTable.UpdatePRBFonts then addonTable.UpdatePRBFonts() end
        if addonTable.UpdatePRB then addonTable.UpdatePRB() end
        if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
        if addonTable.UpdateFocusCastbar then addonTable.UpdateFocusCastbar() end
        if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end
        if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if addonTable.MarkSkyridingFontDirty then addonTable.MarkSkyridingFontDirty() end
        if addonTable.ApplySkyridingFonts then addonTable.ApplySkyridingFonts() end
      end
    end
  end
  if addonTable.outlineDD then
    addonTable.outlineDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.globalOutline = v
        RecreateAllIcons()
        if addonTable.UpdatePRBFonts then addonTable.UpdatePRBFonts() end
        if addonTable.UpdatePRB then addonTable.UpdatePRB() end
        if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
        if addonTable.UpdateFocusCastbar then addonTable.UpdateFocusCastbar() end
        if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end
        if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if addonTable.MarkSkyridingFontDirty then addonTable.MarkSkyridingFontDirty() end
        if addonTable.ApplySkyridingFonts then addonTable.ApplySkyridingFonts() end
      end
    end
  end
  if addonTable.actionBar1ModeDD then
    addonTable.actionBar1ModeDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.actionBarGlobalMode = "custom"
        if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
        SetABModeDropdownsEnabled(true)
        ApplyABModeToProfile(p, "hideActionBar1InCombat", "hideActionBar1Mouseover", "hideActionBar1Always", v)
        if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
      end
    end
  end
  if addonTable.actionBarGlobalModeDD then
    addonTable.actionBarGlobalModeDD.onSelect = function(v)
      local p = GetProfile()
      if not p then return end
      p.actionBarGlobalMode = v or "custom"
      if v == "custom" then
        SetABModeDropdownsEnabled(true)
      elseif v == "off" then
        ApplyABModeToAllBars(p, "off")
        SetABModeDropdownsEnabled(false)
      else
        ApplyABModeToAllBars(p, v)
        SetABModeDropdownsEnabled(true)
      end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
    end
  end
  for n = 2, 8 do
    local dd = addonTable["actionBar"..n.."ModeDD"]
    if dd then
      dd.onSelect = function(v)
        local p = GetProfile()
        if p then
          p.actionBarGlobalMode = "custom"
          if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
          SetABModeDropdownsEnabled(true)
          ApplyABModeToProfile(p, "hideAB"..n.."InCombat", "hideAB"..n.."Mouseover", "hideAB"..n.."Always", v)
          if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
        end
      end
    end
  end
  if addonTable.stanceBarModeDD then
    addonTable.stanceBarModeDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.actionBarGlobalMode = "custom"
        if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
        SetABModeDropdownsEnabled(true)
        ApplyABModeToProfile(p, "hideStanceBarInCombat", "hideStanceBarMouseover", "hideStanceBarAlways", v)
        if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
      end
    end
  end
  if addonTable.petBarModeDD then
    addonTable.petBarModeDD.onSelect = function(v)
      local p = GetProfile()
      if p then
        p.actionBarGlobalMode = "custom"
        if addonTable.actionBarGlobalModeDD then addonTable.actionBarGlobalModeDD:SetValue("custom") end
        SetABModeDropdownsEnabled(true)
        ApplyABModeToProfile(p, "hidePetBarInCombat", "hidePetBarMouseover", "hidePetBarAlways", v)
        if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end
      end
    end
  end
  if addonTable.hideAB1CB then addonTable.hideAB1CB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBar1InCombat = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideAB1MouseoverCB then addonTable.hideAB1MouseoverCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBar1Mouseover = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideAB1AlwaysCB then addonTable.hideAB1AlwaysCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideActionBar1Always = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  for n = 2, 8 do
    if addonTable["hideAB"..n.."CB"] then addonTable["hideAB"..n.."CB"].customOnClick = function(s) local p = GetProfile(); if p then p["hideAB"..n.."InCombat"] = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
    if addonTable["hideAB"..n.."MouseoverCB"] then addonTable["hideAB"..n.."MouseoverCB"].customOnClick = function(s) local p = GetProfile(); if p then p["hideAB"..n.."Mouseover"] = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
    if addonTable["hideAB"..n.."AlwaysCB"] then addonTable["hideAB"..n.."AlwaysCB"].customOnClick = function(s) local p = GetProfile(); if p then p["hideAB"..n.."Always"] = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  end
  if addonTable.hideStanceBarCB then addonTable.hideStanceBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideStanceBarInCombat = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideStanceBarMouseoverCB then addonTable.hideStanceBarMouseoverCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideStanceBarMouseover = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hideStanceBarAlwaysCB then addonTable.hideStanceBarAlwaysCB.customOnClick = function(s) local p = GetProfile(); if p then p.hideStanceBarAlways = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hidePetBarCB then addonTable.hidePetBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.hidePetBarInCombat = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hidePetBarMouseoverCB then addonTable.hidePetBarMouseoverCB.customOnClick = function(s) local p = GetProfile(); if p then p.hidePetBarMouseover = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.hidePetBarAlwaysCB then addonTable.hidePetBarAlwaysCB.customOnClick = function(s) local p = GetProfile(); if p then p.hidePetBarAlways = s:GetChecked(); if addonTable.UpdateActionBarVisibility then addonTable.UpdateActionBarVisibility() end end end end
  if addonTable.fadeMicroMenuCB then addonTable.fadeMicroMenuCB.customOnClick = function(s) local p = GetProfile(); if p then p.fadeMicroMenu = s:GetChecked(); if addonTable.SetupFadeMicroMenu then addonTable.SetupFadeMicroMenu() end end end end
  if addonTable.hideABBordersCB then addonTable.hideABBordersCB.customOnClick = function(s) local p = GetProfile(); if p then local was = p.hideActionBarBorders; p.hideActionBarBorders = s:GetChecked(); if addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end; if was and not s:GetChecked() then ShowReloadPrompt("Disabling Action Bar Skinning requires a UI reload for best results. Reload now?", "Reload", "Later") end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end end end end
  if addonTable.abSkinSpacingSlider then addonTable.abSkinSpacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.abSkinSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.SetupHideABBorders then addonTable.SetupHideABBorders() end end end) end
  if addonTable.fadeObjectiveTrackerCB then addonTable.fadeObjectiveTrackerCB.customOnClick = function(s) local p = GetProfile(); if p then p.fadeObjectiveTracker = s:GetChecked(); if addonTable.SetupFadeObjectiveTracker then addonTable.SetupFadeObjectiveTracker() end end end end
  if addonTable.fadeBagBarCB then addonTable.fadeBagBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.fadeBagBar = s:GetChecked(); if addonTable.SetupFadeBagBar then addonTable.SetupFadeBagBar() end end end end
  if addonTable.betterItemLevelCB then addonTable.betterItemLevelCB.customOnClick = function(s) local p = GetProfile(); if p then p.betterItemLevel = s:GetChecked(); if addonTable.SetupBetterItemLevel then addonTable.SetupBetterItemLevel() end end end end
  if addonTable.showEquipDetailsCB then addonTable.showEquipDetailsCB.customOnClick = function(s) local p = GetProfile(); if p then p.showEquipmentDetails = s:GetChecked(); if addonTable.SetupEquipmentDetails then addonTable.SetupEquipmentDetails() end end end end
  if addonTable.chatClassColorCB then addonTable.chatClassColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatClassColorNames = s:GetChecked() end; if addonTable.SetupChatClassColorNames then addonTable.SetupChatClassColorNames() end end end
  if addonTable.chatTimestampsCB then addonTable.chatTimestampsCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatTimestamps = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatTimestamps then addonTable.SetupChatTimestamps() end end end
  if addonTable.chatTimestampFormatDD then addonTable.chatTimestampFormatDD.onSelect = function(v) local p = GetProfile(); if p then p.chatTimestampFormat = v end; if addonTable.SetupChatTimestamps then addonTable.SetupChatTimestamps() end end end
  if addonTable.chatCopyButtonCB then addonTable.chatCopyButtonCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatCopyButton = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatCopyButton then addonTable.SetupChatCopyButton() end end end
  if addonTable.chatCopyButtonCornerDD then addonTable.chatCopyButtonCornerDD.onSelect = function(v) local p = GetProfile(); if p then p.chatCopyButtonCorner = v end; if addonTable.SetupChatCopyButton then addonTable.SetupChatCopyButton() end end end
  if addonTable.chatUrlDetectionCB then addonTable.chatUrlDetectionCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatUrlDetection = s:GetChecked() end; if addonTable.SetupChatUrlDetection then addonTable.SetupChatUrlDetection() end end end
  if addonTable.chatBackgroundCB then addonTable.chatBackgroundCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatBackground = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end; if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end end end
  if addonTable.chatBgAlphaSlider then addonTable.chatBgAlphaSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.chatBackgroundAlpha = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end; if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end end end) end
  if addonTable.chatBgColorBtn then
    addonTable.chatBgColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.chatBackgroundColorR or 0
      local g = p.chatBackgroundColorG or 0
      local b = p.chatBackgroundColorB or 0
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.chatBackgroundColorR = nr
        p.chatBackgroundColorG = ng
        p.chatBackgroundColorB = nb
        if addonTable.chatBgColorSwatch then addonTable.chatBgColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end
        if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end
      end
      local function OnCancel(prev)
        p.chatBackgroundColorR = prev.r
        p.chatBackgroundColorG = prev.g
        p.chatBackgroundColorB = prev.b
        if addonTable.chatBgColorSwatch then addonTable.chatBgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.SetupChatBackground then addonTable.SetupChatBackground() end
        if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end
      end
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.chatHideButtonsCB then addonTable.chatHideButtonsCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatHideButtons = s:GetChecked() end; if addonTable.SetupChatHideButtons then addonTable.SetupChatHideButtons() end end end
  if addonTable.chatFadeToggleCB then addonTable.chatFadeToggleCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatFadeToggle = s:GetChecked() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.SetupChatFade then addonTable.SetupChatFade() end end end
  if addonTable.chatFadeDelaySlider then addonTable.chatFadeDelaySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.chatFadeDelay = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.SetupChatFade then addonTable.SetupChatFade() end end end) end
  if addonTable.chatEditBoxDD then addonTable.chatEditBoxDD.onSelect = function(v) local p = GetProfile(); if p then p.chatEditBoxPosition = v end; if addonTable.SetupChatEditBoxPosition then addonTable.SetupChatEditBoxPosition() end end end
  if addonTable.chatEditBoxStyledCB then addonTable.chatEditBoxStyledCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatEditBoxStyled = s:GetChecked() end; if addonTable.SetupChatEditBoxStyle then addonTable.SetupChatEditBoxStyle() end end end
  if addonTable.chatTabFlashCB then addonTable.chatTabFlashCB.customOnClick = function(s) local p = GetProfile(); if p then p.chatTabFlash = s:GetChecked() end end end
  if addonTable.chatHideTabsDD then addonTable.chatHideTabsDD.onSelect = function(v) local p = GetProfile(); if p then p.chatHideTabs = v end; if addonTable.SetupChatHideTabs then addonTable.SetupChatHideTabs() end end end
  if addonTable.skyridingEnabledCB then addonTable.skyridingEnabledCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingEnabled = s:GetChecked() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingHideCDMCB then addonTable.skyridingHideCDMCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingHideCDM = s:GetChecked() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingVigorBarCB then addonTable.skyridingVigorBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingVigorBar = s:GetChecked() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingSpeedDisplayCB then addonTable.skyridingSpeedDisplayCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingSpeedDisplay = s:GetChecked() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingSpeedBarCB then addonTable.skyridingSpeedBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingSpeedBar = s:GetChecked() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingCooldownsCB then addonTable.skyridingCooldownsCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingCooldowns = s:GetChecked() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingSpeedUnitDD then addonTable.skyridingSpeedUnitDD.onSelect = function(v) local p = GetProfile(); if p then p.skyridingSpeedUnit = v end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end end end
  if addonTable.skyridingScreenFxCB then addonTable.skyridingScreenFxCB.customOnClick = function(s) if C_CVar then C_CVar.SetCVar("DisableAdvancedFlyingFullScreenEffects", s:GetChecked() and "0" or "1") end end end
  if addonTable.skyridingSpeedFxCB then addonTable.skyridingSpeedFxCB.customOnClick = function(s) if C_CVar then C_CVar.SetCVar("DisableAdvancedFlyingVelocityVFX", s:GetChecked() and "0" or "1") end end end
  if addonTable.skyridingPreviewOnBtn then
    addonTable.skyridingPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowSkyridingPreview then addonTable.ShowSkyridingPreview() end
      SetButtonHighlighted(addonTable.skyridingPreviewOnBtn, true)
    end)
  end
  if addonTable.skyridingPreviewOffBtn then
    addonTable.skyridingPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopSkyridingPreview then addonTable.StopSkyridingPreview() end
      SetButtonHighlighted(addonTable.skyridingPreviewOnBtn, false)
    end)
  end
  if addonTable.skyridingTextureDD then addonTable.skyridingTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.skyridingTexture = v end; if addonTable.InvalidateSkyridingTexture then addonTable.InvalidateSkyridingTexture() end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end end end
  if addonTable.skyridingScaleSlider then addonTable.skyridingScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.skyridingScale = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end) end
  if addonTable.skyridingCenteredCB then addonTable.skyridingCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.skyridingCentered = s:GetChecked(); if s:GetChecked() then p.skyridingX = 0 end end; local cen = s:GetChecked(); if addonTable.skyridingXSlider then addonTable.skyridingXSlider:SetEnabled(not cen); addonTable.skyridingXSlider:SetAlpha(cen and 0.4 or 1); if cen then addonTable.skyridingXSlider:SetValue(0); addonTable.skyridingXSlider.valueText:SetText("0") end end; if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end
  if addonTable.skyridingXSlider then addonTable.skyridingXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.skyridingX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end) end
  if addonTable.skyridingYSlider then addonTable.skyridingYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.skyridingY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end; if addonTable.SetupSkyriding then addonTable.SetupSkyriding() end end end) end
  if addonTable.skyridingVigorColorBtn then
    addonTable.skyridingVigorColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingVigorColorR or 0.2, p.skyridingVigorColorG or 0.8, p.skyridingVigorColorB or 0.2
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingVigorColorR = nr; p.skyridingVigorColorG = ng; p.skyridingVigorColorB = nb
        if addonTable.skyridingVigorColorSwatch then addonTable.skyridingVigorColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingVigorColorR = prev.r; p.skyridingVigorColorG = prev.g; p.skyridingVigorColorB = prev.b
        if addonTable.skyridingVigorColorSwatch then addonTable.skyridingVigorColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingEmptyColorBtn then
    addonTable.skyridingEmptyColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingVigorEmptyColorR or 0.15, p.skyridingVigorEmptyColorG or 0.15, p.skyridingVigorEmptyColorB or 0.15
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingVigorEmptyColorR = nr; p.skyridingVigorEmptyColorG = ng; p.skyridingVigorEmptyColorB = nb
        if addonTable.skyridingEmptyColorSwatch then addonTable.skyridingEmptyColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingVigorEmptyColorR = prev.r; p.skyridingVigorEmptyColorG = prev.g; p.skyridingVigorEmptyColorB = prev.b
        if addonTable.skyridingEmptyColorSwatch then addonTable.skyridingEmptyColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingRechargeColorBtn then
    addonTable.skyridingRechargeColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingVigorRechargeColorR or 0.85, p.skyridingVigorRechargeColorG or 0.65, p.skyridingVigorRechargeColorB or 0.1
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingVigorRechargeColorR = nr; p.skyridingVigorRechargeColorG = ng; p.skyridingVigorRechargeColorB = nb
        if addonTable.skyridingRechargeColorSwatch then addonTable.skyridingRechargeColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingVigorRechargeColorR = prev.r; p.skyridingVigorRechargeColorG = prev.g; p.skyridingVigorRechargeColorB = prev.b
        if addonTable.skyridingRechargeColorSwatch then addonTable.skyridingRechargeColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingSpeedColorBtn then
    addonTable.skyridingSpeedColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingSpeedColorR or 0.3, p.skyridingSpeedColorG or 0.6, p.skyridingSpeedColorB or 1.0
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingSpeedColorR = nr; p.skyridingSpeedColorG = ng; p.skyridingSpeedColorB = nb
        if addonTable.skyridingSpeedColorSwatch then addonTable.skyridingSpeedColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingSpeedColorR = prev.r; p.skyridingSpeedColorG = prev.g; p.skyridingSpeedColorB = prev.b
        if addonTable.skyridingSpeedColorSwatch then addonTable.skyridingSpeedColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingSurgeColorBtn then
    addonTable.skyridingSurgeColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingWhirlingSurgeColorR or 0.85, p.skyridingWhirlingSurgeColorG or 0.65, p.skyridingWhirlingSurgeColorB or 0.1
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingWhirlingSurgeColorR = nr; p.skyridingWhirlingSurgeColorG = ng; p.skyridingWhirlingSurgeColorB = nb
        if addonTable.skyridingSurgeColorSwatch then addonTable.skyridingSurgeColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingWhirlingSurgeColorR = prev.r; p.skyridingWhirlingSurgeColorG = prev.g; p.skyridingWhirlingSurgeColorB = prev.b
        if addonTable.skyridingSurgeColorSwatch then addonTable.skyridingSurgeColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.skyridingWindColorBtn then
    addonTable.skyridingWindColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r, g, b = p.skyridingSecondWindColorR or 0.2, p.skyridingSecondWindColorG or 0.8, p.skyridingSecondWindColorB or 0.2
      ShowColorPicker({r = r, g = g, b = b, swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.skyridingSecondWindColorR = nr; p.skyridingSecondWindColorG = ng; p.skyridingSecondWindColorB = nb
        if addonTable.skyridingWindColorSwatch then addonTable.skyridingWindColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end, cancelFunc = function(prev)
        p.skyridingSecondWindColorR = prev.r; p.skyridingSecondWindColorG = prev.g; p.skyridingSecondWindColorB = prev.b
        if addonTable.skyridingWindColorSwatch then addonTable.skyridingWindColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.InvalidateSkyridingColors then addonTable.InvalidateSkyridingColors() end
        if addonTable.UpdateSkyridingPreviewIfActive then addonTable.UpdateSkyridingPreviewIfActive() end
      end})
    end)
  end
  if addonTable.radialCB then addonTable.radialCB.customOnClick = function(s) local p = GetProfile(); if p then p.showRadialCircle = s:GetChecked(); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
  if addonTable.radialCombatCB then addonTable.radialCombatCB.customOnClick = function(s) local p = GetProfile(); if p then p.cursorCombatOnly = s:GetChecked(); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end end end end
  if addonTable.radialGcdCB then addonTable.radialGcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.showGCD = s:GetChecked(); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
  if addonTable.ufClassColorCB then addonTable.ufClassColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufClassColor = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end end end
  if addonTable.ufDisableGlowsCB then
    addonTable.ufDisableGlowsCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.ufDisableGlows = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.ufDisableCombatTextCB then
    addonTable.ufDisableCombatTextCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.ufDisableCombatText = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.disableTargetBuffsCB then
    addonTable.disableTargetBuffsCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.disableTargetBuffs = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.hideEliteTextureCB then
    addonTable.hideEliteTextureCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.hideEliteTexture = s:GetChecked(); if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end
    end
  end
  if addonTable.ufUseCustomTexturesCB then
    addonTable.ufUseCustomTexturesCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.ufUseCustomTextures = s:GetChecked()
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if not s:GetChecked() then ShowReloadPrompt("Disabling custom textures requires a reload to fully restore default textures.") end
      end
    end
  end
  if addonTable.ufHealthTextureDD then addonTable.ufHealthTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.ufHealthTexture = v; if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end end end end
  if addonTable.useCustomBorderColorCB then
    addonTable.useCustomBorderColorCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.useCustomBorderColor = s:GetChecked()
        if addonTable.ufBorderColorBtn then addonTable.ufBorderColorBtn:SetEnabled(s:GetChecked()) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
    end
  end
  if addonTable.ufBorderColorBtn then
    addonTable.ufBorderColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.ufCustomBorderColorR or 1
      local g = p.ufCustomBorderColorG or 1
      local b = p.ufCustomBorderColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.ufCustomBorderColorR, p.ufCustomBorderColorG, p.ufCustomBorderColorB = nr, ng, nb
        if addonTable.ufBorderColorSwatch then addonTable.ufBorderColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      local function OnCancel(prev)
        p.ufCustomBorderColorR, p.ufCustomBorderColorG, p.ufCustomBorderColorB = prev.r, prev.g, prev.b
        if addonTable.ufBorderColorSwatch then addonTable.ufBorderColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.ufUseCustomNameColorCB then
    addonTable.ufUseCustomNameColorCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.ufUseCustomNameColor = s:GetChecked()
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
        if not s:GetChecked() then ShowReloadPrompt("Disabling custom name color requires a reload to fully restore default colors.") end
      end
    end
  end
  if addonTable.ufNameColorBtn then
    addonTable.ufNameColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.ufNameColorR or 1
      local g = p.ufNameColorG or 1
      local b = p.ufNameColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.ufNameColorR, p.ufNameColorG, p.ufNameColorB = nr, ng, nb
        if addonTable.ufNameColorSwatch then addonTable.ufNameColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      local function OnCancel(prev)
        p.ufNameColorR, p.ufNameColorG, p.ufNameColorB = prev.r, prev.g, prev.b
        if addonTable.ufNameColorSwatch then addonTable.ufNameColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  local function ApplyUFBigHealthbarChanges()
    local p = GetProfile()
    if p and (p.ufBigHBPlayerEnabled == true or p.ufBigHBTargetEnabled == true or p.ufBigHBFocusEnabled == true) then
      p.useCustomBorderColor = true
      p.ufUseCustomNameColor = true
      if (p.ufCustomBorderColorR or 0) == 0 and (p.ufCustomBorderColorG or 0) == 0 and (p.ufCustomBorderColorB or 0) == 0 then
      elseif not p.useCustomBorderColor then
        p.ufCustomBorderColorR = 0; p.ufCustomBorderColorG = 0; p.ufCustomBorderColorB = 0
      end
    end
    if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
    if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
  end
  if addonTable.ufBigHBPlayerCB then addonTable.ufBigHBPlayerCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBPlayerEnabled = s:GetChecked(); ApplyUFBigHealthbarChanges(); ShowReloadPrompt("Toggling Bigger Healthbars requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBigHBTargetCB then addonTable.ufBigHBTargetCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBTargetEnabled = s:GetChecked(); ApplyUFBigHealthbarChanges(); ShowReloadPrompt("Toggling Bigger Healthbars requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBigHBFocusCB then addonTable.ufBigHBFocusCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBFocusEnabled = s:GetChecked(); ApplyUFBigHealthbarChanges(); ShowReloadPrompt("Toggling Bigger Healthbars requires a reload for full effect.", "Reload", "Later") end end end
  if addonTable.ufBigHBHideRealmCB then addonTable.ufBigHBHideRealmCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHideRealm = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end

  if addonTable.ufBigHBNameMaxCharsSlider then addonTable.ufBigHBNameMaxCharsSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBNameMaxChars = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBHidePlayerNameCB then addonTable.ufBigHBHidePlayerNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHidePlayerName = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerLevelDD then addonTable.ufBigHBPlayerLevelDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBPlayerLevelMode = v; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBHideTargetNameCB then addonTable.ufBigHBHideTargetNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHideTargetName = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetLevelDD then addonTable.ufBigHBTargetLevelDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBTargetLevelMode = v; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBHideFocusNameCB then addonTable.ufBigHBHideFocusNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBHideFocusName = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusLevelDD then addonTable.ufBigHBFocusLevelDD.onSelect = function(v) local p = GetProfile(); if p then p.ufBigHBFocusLevelMode = v; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerNameXSlider then addonTable.ufBigHBPlayerNameXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerNameX = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBPlayerNameYSlider then addonTable.ufBigHBPlayerNameYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerNameY = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBPlayerLevelXSlider then addonTable.ufBigHBPlayerLevelXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerLevelX = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBPlayerLevelYSlider then addonTable.ufBigHBPlayerLevelYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerLevelY = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBPlayerNameTextScaleSlider then addonTable.ufBigHBPlayerNameTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerNameTextScale = math.floor(v * 100 + 0.5) / 100; s.valueText:SetText(string.format("%.2f", p.ufBigHBPlayerNameTextScale)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBPlayerLevelTextScaleSlider then addonTable.ufBigHBPlayerLevelTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBPlayerLevelTextScale = math.floor(v * 100 + 0.5) / 100; s.valueText:SetText(string.format("%.2f", p.ufBigHBPlayerLevelTextScale)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetNameXSlider then addonTable.ufBigHBTargetNameXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetNameX = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetNameYSlider then addonTable.ufBigHBTargetNameYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetNameY = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetLevelXSlider then addonTable.ufBigHBTargetLevelXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetLevelX = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetLevelYSlider then addonTable.ufBigHBTargetLevelYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetLevelY = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetNameTextScaleSlider then addonTable.ufBigHBTargetNameTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetNameTextScale = math.floor(v * 100 + 0.5) / 100; s.valueText:SetText(string.format("%.2f", p.ufBigHBTargetNameTextScale)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBTargetLevelTextScaleSlider then addonTable.ufBigHBTargetLevelTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBTargetLevelTextScale = math.floor(v * 100 + 0.5) / 100; s.valueText:SetText(string.format("%.2f", p.ufBigHBTargetLevelTextScale)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusNameXSlider then addonTable.ufBigHBFocusNameXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusNameX = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusNameYSlider then addonTable.ufBigHBFocusNameYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusNameY = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusLevelXSlider then addonTable.ufBigHBFocusLevelXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusLevelX = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusLevelYSlider then addonTable.ufBigHBFocusLevelYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusLevelY = math.floor(v + 0.5); s.valueText:SetText(math.floor(v + 0.5)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusNameTextScaleSlider then addonTable.ufBigHBFocusNameTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusNameTextScale = math.floor(v * 100 + 0.5) / 100; s.valueText:SetText(string.format("%.2f", p.ufBigHBFocusNameTextScale)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBFocusLevelTextScaleSlider then addonTable.ufBigHBFocusLevelTextScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.ufBigHBFocusLevelTextScale = math.floor(v * 100 + 0.5) / 100; s.valueText:SetText(string.format("%.2f", p.ufBigHBFocusLevelTextScale)); ApplyUFBigHealthbarChanges() end end) end
  if addonTable.ufBigHBPlayerHealAbsorbDD then addonTable.ufBigHBPlayerHealAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBPlayerHealAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerDmgAbsorbDD then addonTable.ufBigHBPlayerDmgAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBPlayerDmgAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerHealPredDD then addonTable.ufBigHBPlayerHealPredDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBPlayerHealPred = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetHealAbsorbDD then addonTable.ufBigHBTargetHealAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBTargetHealAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetDmgAbsorbDD then addonTable.ufBigHBTargetDmgAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBTargetDmgAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetHealPredDD then addonTable.ufBigHBTargetHealPredDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBTargetHealPred = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusHealAbsorbDD then addonTable.ufBigHBFocusHealAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBFocusHealAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusDmgAbsorbDD then addonTable.ufBigHBFocusDmgAbsorbDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBFocusDmgAbsorb = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusHealPredDD then addonTable.ufBigHBFocusHealPredDD.onSelect = function(val) local p = GetProfile(); if p then p.ufBigHBFocusHealPred = val; ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBPlayerAbsorbStripesCB then addonTable.ufBigHBPlayerAbsorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBPlayerAbsorbStripes = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBTargetAbsorbStripesCB then addonTable.ufBigHBTargetAbsorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBTargetAbsorbStripes = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.ufBigHBFocusAbsorbStripesCB then addonTable.ufBigHBFocusAbsorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.ufBigHBFocusAbsorbStripes = s:GetChecked(); ApplyUFBigHealthbarChanges() end end end
  if addonTable.autoRepairCB then addonTable.autoRepairCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoRepair = s:GetChecked() end end end
  if addonTable.showTooltipIDsCB then addonTable.showTooltipIDsCB.customOnClick = function(s) local p = GetProfile(); if p then p.showTooltipIDs = s:GetChecked() end; if addonTable.SetupTooltipIDHooks then addonTable.SetupTooltipIDHooks() end end end
  if addonTable.compactMinimapIconsCB then addonTable.compactMinimapIconsCB.customOnClick = function(s) local p = GetProfile(); if p then p.compactMinimapIcons = s:GetChecked(); if p.compactMinimapIcons then p.showMinimapButton = true; if addonTable.minimapCB then addonTable.minimapCB:SetChecked(true) end; if addonTable.ShowMinimapButton then addonTable.ShowMinimapButton() end end; if addonTable.ApplyCompactMinimapIcons then addonTable.ApplyCompactMinimapIcons() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end end end end
  if addonTable.enhancedTooltipCB then addonTable.enhancedTooltipCB.customOnClick = function(s) local p = GetProfile(); if p then p.enhancedTooltip = s:GetChecked() end; if addonTable.SetupEnhancedTooltipHook then addonTable.SetupEnhancedTooltipHook() end end end
  if addonTable.autoQuestCB then addonTable.autoQuestCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuest = s:GetChecked() end; if addonTable.SetupAutoQuest then addonTable.SetupAutoQuest() end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end end end
  if addonTable.autoQuestExcludeDailyCB then addonTable.autoQuestExcludeDailyCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeDaily = s:GetChecked() end end end
  if addonTable.autoQuestExcludeWeeklyCB then addonTable.autoQuestExcludeWeeklyCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeWeekly = s:GetChecked() end end end
  if addonTable.autoQuestExcludeTrivialCB then addonTable.autoQuestExcludeTrivialCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeTrivial = s:GetChecked() end end end
  if addonTable.autoQuestExcludeCompletedCB then addonTable.autoQuestExcludeCompletedCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoQuestExcludeCompleted = s:GetChecked() end end end
  if addonTable.autoQuestRewardDD then addonTable.autoQuestRewardDD.onSelect = function(v) local p = GetProfile(); if p then p.autoQuestRewardMode = v end end end
  if addonTable.autoSellJunkCB then addonTable.autoSellJunkCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoSellJunk = s:GetChecked() end end end
  if addonTable.autoFillDeleteCB then addonTable.autoFillDeleteCB.customOnClick = function(s) local p = GetProfile(); if p then p.autoFillDelete = s:GetChecked() end end end
  if addonTable.quickRoleSignupCB then addonTable.quickRoleSignupCB.customOnClick = function(s) local p = GetProfile(); if p then p.quickRoleSignup = s:GetChecked() end; if addonTable.SetupQuickRoleSignup then addonTable.SetupQuickRoleSignup() end end end
  if addonTable.combatTimerCB then
    addonTable.combatTimerCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local wasOff = p.combatTimerEnabled ~= true
        p.combatTimerEnabled = s:GetChecked()
        if wasOff and p.combatTimerEnabled then p.combatTimerMode = "always" end
      end
      if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
      if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
    end
  end
  if addonTable.combatTimerModeDD then addonTable.combatTimerModeDD.onSelect = function(v) local p = GetProfile(); if p then p.combatTimerMode = v end; if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end
  if addonTable.combatTimerStyleDD then addonTable.combatTimerStyleDD.onSelect = function(v) local p = GetProfile(); if p then p.combatTimerStyle = v end; if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end
  if addonTable.combatTimerCenteredCB then addonTable.combatTimerCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.combatTimerCentered = s:GetChecked(); if p.combatTimerCentered then p.combatTimerX = 0 end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end
  if addonTable.combatTimerXSlider then addonTable.combatTimerXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatTimerX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end) end
  if addonTable.combatTimerYSlider then addonTable.combatTimerYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatTimerY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end) end
  if addonTable.combatTimerScaleSlider then addonTable.combatTimerScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatTimerScale = v; s.valueText:SetText(string.format("%.2f", v)); if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end end end) end
  addonTable.UpdateCombatTimerSliders = function(x, y)
    if addonTable.combatTimerXSlider then addonTable.combatTimerXSlider:SetValue(x or 0); addonTable.combatTimerXSlider.valueText:SetText(math.floor(x or 0)) end
    if addonTable.combatTimerYSlider then addonTable.combatTimerYSlider:SetValue(y or 200); addonTable.combatTimerYSlider.valueText:SetText(math.floor(y or 200)) end
  end
  if addonTable.combatTimerTextColorBtn then
    addonTable.combatTimerTextColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatTimerTextColorR or 1
      local g = p.combatTimerTextColorG or 1
      local b = p.combatTimerTextColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.combatTimerTextColorR = nr
        p.combatTimerTextColorG = ng
        p.combatTimerTextColorB = nb
        if addonTable.combatTimerTextColorSwatch then addonTable.combatTimerTextColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      local function OnCancel(prev)
        p.combatTimerTextColorR = prev.r
        p.combatTimerTextColorG = prev.g
        p.combatTimerTextColorB = prev.b
        if addonTable.combatTimerTextColorSwatch then addonTable.combatTimerTextColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.combatTimerBgColorBtn then
    addonTable.combatTimerBgColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatTimerBgColorR or 0.12
      local g = p.combatTimerBgColorG or 0.12
      local b = p.combatTimerBgColorB or 0.12
      local a = p.combatTimerBgAlpha or 0.85
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local na = ColorPickerFrame:GetColorAlpha() or 1
        p.combatTimerBgColorR = nr
        p.combatTimerBgColorG = ng
        p.combatTimerBgColorB = nb
        p.combatTimerBgAlpha = na
        if addonTable.combatTimerBgColorSwatch then addonTable.combatTimerBgColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      local function OnCancel(prev)
        p.combatTimerBgColorR = prev.r
        p.combatTimerBgColorG = prev.g
        p.combatTimerBgColorB = prev.b
        p.combatTimerBgAlpha = a
        if addonTable.combatTimerBgColorSwatch then addonTable.combatTimerBgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatTimer then addonTable.UpdateCombatTimer() end
      end
      ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnColorChanged, opacityFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.crTimerCB then addonTable.crTimerCB.customOnClick = function(s) local p = GetProfile(); if p then local wasOff = p.crTimerEnabled ~= true; p.crTimerEnabled = s:GetChecked(); if wasOff and p.crTimerEnabled then p.crTimerMode = "always" end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerModeDD then addonTable.crTimerModeDD.onSelect = function(v) local p = GetProfile(); if p then p.crTimerMode = v end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerLayoutDD then addonTable.crTimerLayoutDD.onSelect = function(v) local p = GetProfile(); if p then p.crTimerLayout = v end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerDisplayDD then addonTable.crTimerDisplayDD.onSelect = function(v) local p = GetProfile(); if p then p.crTimerDisplay = v end; local enableLayout = v ~= "count"; if addonTable.crTimerLayoutDD then addonTable.crTimerLayoutDD:SetEnabled(enableLayout) end; if addonTable.crTimerLayoutLbl then addonTable.crTimerLayoutLbl:SetTextColor(enableLayout and 0.9 or 0.4, enableLayout and 0.9 or 0.4, enableLayout and 0.9 or 0.4) end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerCenteredCB then addonTable.crTimerCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.crTimerCentered = s:GetChecked(); if p.crTimerCentered then p.crTimerX = 0 end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end
  if addonTable.crTimerXSlider then addonTable.crTimerXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.crTimerX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end) end
  if addonTable.crTimerYSlider then addonTable.crTimerYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.crTimerY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end) end
  if addonTable.crTimerScaleSlider then addonTable.crTimerScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.crTimerScale = v; s.valueText:SetText(string.format("%.2f", v)); if addonTable.UpdateCRTimer then addonTable.UpdateCRTimer() end end end) end
  addonTable.UpdateCRTimerSliders = function(x, y)
    if addonTable.crTimerXSlider then addonTable.crTimerXSlider:SetValue(x or 0); addonTable.crTimerXSlider.valueText:SetText(math.floor(x or 0)) end
    if addonTable.crTimerYSlider then addonTable.crTimerYSlider:SetValue(y or 150); addonTable.crTimerYSlider.valueText:SetText(math.floor(y or 150)) end
  end
  if addonTable.combatStatusCB then addonTable.combatStatusCB.customOnClick = function(s) local p = GetProfile(); if p then p.combatStatusEnabled = s:GetChecked() end; if not s:GetChecked() and addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end; if addonTable.combatStatusPreviewOnBtn then SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, false) end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end
  if addonTable.combatStatusCenteredCB then addonTable.combatStatusCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then p.combatStatusCentered = s:GetChecked(); if p.combatStatusCentered then p.combatStatusX = 0 end end; if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end; if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end
  if addonTable.combatStatusXSlider then addonTable.combatStatusXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatStatusX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end) end
  if addonTable.combatStatusYSlider then addonTable.combatStatusYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatStatusY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end) end
  if addonTable.combatStatusScaleSlider then addonTable.combatStatusScaleSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.combatStatusScale = v; s.valueText:SetText(string.format("%.2f", v)); if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end end end) end
  addonTable.UpdateCombatStatusSliders = function(x, y)
    if addonTable.combatStatusXSlider then addonTable.combatStatusXSlider:SetValue(x or 0); addonTable.combatStatusXSlider.valueText:SetText(math.floor(x or 0)) end
    if addonTable.combatStatusYSlider then addonTable.combatStatusYSlider:SetValue(y or 280); addonTable.combatStatusYSlider.valueText:SetText(math.floor(y or 280)) end
  end
  if addonTable.combatStatusEnterColorBtn then
    addonTable.combatStatusEnterColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatStatusEnterColorR or 1
      local g = p.combatStatusEnterColorG or 1
      local b = p.combatStatusEnterColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.combatStatusEnterColorR = nr
        p.combatStatusEnterColorG = ng
        p.combatStatusEnterColorB = nb
        if addonTable.combatStatusEnterColorSwatch then addonTable.combatStatusEnterColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      local function OnCancel(prev)
        p.combatStatusEnterColorR = prev.r
        p.combatStatusEnterColorG = prev.g
        p.combatStatusEnterColorB = prev.b
        if addonTable.combatStatusEnterColorSwatch then addonTable.combatStatusEnterColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.combatStatusLeaveColorBtn then
    addonTable.combatStatusLeaveColorBtn:SetScript("OnClick", function()
      local p = GetProfile()
      if not p then return end
      local r = p.combatStatusLeaveColorR or 1
      local g = p.combatStatusLeaveColorG or 1
      local b = p.combatStatusLeaveColorB or 1
      local function OnColorChanged()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        p.combatStatusLeaveColorR = nr
        p.combatStatusLeaveColorG = ng
        p.combatStatusLeaveColorB = nb
        if addonTable.combatStatusLeaveColorSwatch then addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(nr, ng, nb, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      local function OnCancel(prev)
        p.combatStatusLeaveColorR = prev.r
        p.combatStatusLeaveColorG = prev.g
        p.combatStatusLeaveColorB = prev.b
        if addonTable.combatStatusLeaveColorSwatch then addonTable.combatStatusLeaveColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end
        if addonTable.UpdateCombatStatus then addonTable.UpdateCombatStatus() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.combatStatusPreviewOnBtn then
    addonTable.combatStatusPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowCombatStatusPreview then addonTable.ShowCombatStatusPreview() end
      SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, true)
    end)
  end
  if addonTable.combatStatusPreviewOffBtn then
    addonTable.combatStatusPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopCombatStatusPreview then addonTable.StopCombatStatusPreview() end
      SetButtonHighlighted(addonTable.combatStatusPreviewOnBtn, false)
    end)
  end
  if addonTable.minimapCB then addonTable.minimapCB.customOnClick = function(s) local p = GetProfile(); if p then if p.compactMinimapIcons == true then s:SetChecked(true); p.showMinimapButton = true; if addonTable.ShowMinimapButton then addonTable.ShowMinimapButton() end; return end; p.showMinimapButton = s:GetChecked(); if s:GetChecked() then addonTable.ShowMinimapButton() else addonTable.HideMinimapButton() end end end end
  if addonTable.radiusSlider then addonTable.radiusSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.radialRadius = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end end end) end
  if addonTable.radialThicknessDD then addonTable.radialThicknessDD.onSelect = function(v) local p = GetProfile(); if p then p.radialThickness = PresetToRadialThickness(v); if addonTable.UpdateRadialCircle then addonTable.UpdateRadialCircle() end end end end
  if addonTable.selfHighlightCB then
    addonTable.selfHighlightCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        local enabled = s:GetChecked()
        p.selfHighlightShape = enabled and "cross" or "off"
        if addonTable.selfHighlightVisibilityDD then addonTable.selfHighlightVisibilityDD:SetEnabled(enabled) end
        if addonTable.selfHighlightSizeSlider then addonTable.selfHighlightSizeSlider:SetEnabled(enabled) end
        if addonTable.selfHighlightYSlider then addonTable.selfHighlightYSlider:SetEnabled(enabled) end
        if addonTable.selfHighlightThicknessDD then addonTable.selfHighlightThicknessDD:SetEnabled(enabled) end
        if addonTable.selfHighlightThicknessLbl then addonTable.selfHighlightThicknessLbl:SetTextColor(enabled and 0.9 or 0.4, enabled and 0.9 or 0.4, enabled and 0.9 or 0.4) end
        if addonTable.selfHighlightOutlineCB then addonTable.selfHighlightOutlineCB:SetEnabled(enabled) end
        if addonTable.selfHighlightColorBtn then addonTable.selfHighlightColorBtn:SetEnabled(enabled) end
        if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
      end
    end
  end
  if addonTable.selfHighlightVisibilityDD then addonTable.selfHighlightVisibilityDD.onSelect = function(v) local p = GetProfile(); if p then p.selfHighlightCombatOnly = (v == "combat"); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end end
  if addonTable.selfHighlightSizeSlider then addonTable.selfHighlightSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.selfHighlightSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end) end
  if addonTable.selfHighlightYSlider then addonTable.selfHighlightYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.selfHighlightY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end) end
  if addonTable.selfHighlightThicknessDD then addonTable.selfHighlightThicknessDD.onSelect = function(v) local p = GetProfile(); if p then p.selfHighlightThickness = v; if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end end
  if addonTable.selfHighlightOutlineCB then addonTable.selfHighlightOutlineCB.customOnClick = function(s) local p = GetProfile(); if p then p.selfHighlightOutline = s:GetChecked(); if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end end end end
  if addonTable.selfHighlightColorBtn then
    addonTable.selfHighlightColorBtn:SetScript("OnClick", function()
      local profile = GetProfile()
      if not profile then return end
      local r = profile.selfHighlightColorR or 1
      local g = profile.selfHighlightColorG or 1
      local b = profile.selfHighlightColorB or 1
      local a = profile.selfHighlightAlpha or 1
      local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = ColorPickerFrame:GetColorAlpha() or 1
        profile.selfHighlightColorR = newR
        profile.selfHighlightColorG = newG
        profile.selfHighlightColorB = newB
        profile.selfHighlightAlpha = newA
        if addonTable.selfHighlightColorSwatch then addonTable.selfHighlightColorSwatch:SetBackdropColor(newR, newG, newB, 1) end
        if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
      end
      local function OnCancel(prevValues)
        profile.selfHighlightColorR = prevValues.r
        profile.selfHighlightColorG = prevValues.g
        profile.selfHighlightColorB = prevValues.b
        profile.selfHighlightAlpha = a
        if addonTable.selfHighlightColorSwatch then addonTable.selfHighlightColorSwatch:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, 1) end
        if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
      end
      ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnColorChanged, opacityFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  if addonTable.noTargetAlertCB then
    addonTable.noTargetAlertCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.noTargetAlertEnabled = s:GetChecked()
        local enabled = s:GetChecked()
        if addonTable.noTargetAlertFlashCB then addonTable.noTargetAlertFlashCB:SetEnabled(enabled) end
        if addonTable.noTargetAlertXSlider then addonTable.noTargetAlertXSlider:SetEnabled(enabled) end
        if addonTable.noTargetAlertYSlider then addonTable.noTargetAlertYSlider:SetEnabled(enabled) end
        if addonTable.noTargetAlertFontSizeSlider then addonTable.noTargetAlertFontSizeSlider:SetEnabled(enabled) end
        if addonTable.noTargetAlertColorBtn then addonTable.noTargetAlertColorBtn:SetEnabled(enabled) end
        if addonTable.UpdateNoTargetAlert then addonTable.UpdateNoTargetAlert() end
      end
    end
  end
  if addonTable.noTargetAlertFlashCB then
    addonTable.noTargetAlertFlashCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.noTargetAlertFlash = s:GetChecked()
        if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end
      end
    end
  end
  if addonTable.noTargetAlertPreviewOnBtn then
    addonTable.noTargetAlertPreviewOnBtn:SetScript("OnClick", function()
      if addonTable.ShowNoTargetAlertPreview then addonTable.ShowNoTargetAlertPreview() end
      SetButtonHighlighted(addonTable.noTargetAlertPreviewOnBtn, true)
    end)
  end
  if addonTable.noTargetAlertPreviewOffBtn then
    addonTable.noTargetAlertPreviewOffBtn:SetScript("OnClick", function()
      if addonTable.StopNoTargetAlertPreview then addonTable.StopNoTargetAlertPreview() end
      SetButtonHighlighted(addonTable.noTargetAlertPreviewOnBtn, false)
    end)
  end
  if addonTable.noTargetAlertXSlider then addonTable.noTargetAlertXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.noTargetAlertX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end end end) end
  if addonTable.noTargetAlertYSlider then addonTable.noTargetAlertYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.noTargetAlertY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end end end) end
  if addonTable.noTargetAlertFontSizeSlider then addonTable.noTargetAlertFontSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.noTargetAlertFontSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end end end) end
  if addonTable.noTargetAlertColorBtn then
    addonTable.noTargetAlertColorBtn:SetScript("OnClick", function()
      local profile = GetProfile()
      if not profile then return end
      local r = profile.noTargetAlertColorR or 1
      local g = profile.noTargetAlertColorG or 0
      local b = profile.noTargetAlertColorB or 0
      local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        profile.noTargetAlertColorR = newR
        profile.noTargetAlertColorG = newG
        profile.noTargetAlertColorB = newB
        if addonTable.noTargetAlertColorSwatch then addonTable.noTargetAlertColorSwatch:SetBackdropColor(newR, newG, newB, 1) end
        if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end
      end
      local function OnCancel(prevValues)
        profile.noTargetAlertColorR = prevValues.r
        profile.noTargetAlertColorG = prevValues.g
        profile.noTargetAlertColorB = prevValues.b
        if addonTable.noTargetAlertColorSwatch then addonTable.noTargetAlertColorSwatch:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, 1) end
        if addonTable.UpdateNoTargetAlertPreviewIfActive then addonTable.UpdateNoTargetAlertPreviewIfActive() end
      end
      ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnColorChanged, cancelFunc = OnCancel})
    end)
  end
  local function CreateExampleProfile(role, profileName)
    local exampleProfiles = CCM and CCM.Defaults and CCM.Defaults.exampleProfiles
    if not exampleProfiles or not exampleProfiles[role] then
      print("|cffff6666CCM:|r Example profile '" .. role .. "' not found!")
      return
    end
    if CooldownCursorManagerDB.profiles[profileName] then
      print("|cffff6666CCM:|r Profile '" .. profileName .. "' already exists!")
      return
    end
    local defaults = CCM and CCM.Defaults and CCM.Defaults.profiles and CCM.Defaults.profiles.Default
    CooldownCursorManagerDB.profiles[profileName] = {}
    local newProfile = CooldownCursorManagerDB.profiles[profileName]
    if defaults then
      for key, value in pairs(defaults) do
        if type(value) == "table" then
          newProfile[key] = {}
          for k, v in pairs(value) do newProfile[key][k] = v end
        else
          newProfile[key] = value
        end
      end
    end
    for key, value in pairs(exampleProfiles[role]) do
      newProfile[key] = value
    end
    CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
    CooldownCursorManagerDB.profileClasses[profileName] = nil
    CooldownCursorManagerDB.currentProfile = profileName
    if addonTable.SaveCurrentProfileForSpec then
      addonTable.SaveCurrentProfileForSpec()
    end
    UpdateProfileList()
    UpdateProfileDisplay()
    UpdateAllControls()
    CreateIcons()
    if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
    if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
    if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
    if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
    if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
    if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
    if addonTable.UpdatePRB then addonTable.UpdatePRB() end
    if addonTable.UpdateCastbar then addonTable.UpdateCastbar() end
    if addonTable.UpdateSelfHighlight then addonTable.UpdateSelfHighlight() end
    if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
    if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end
    if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end
    print("|cff00ff00CCM:|r Created example profile: " .. profileName)
    ShowReloadPrompt("Example profile '" .. profileName .. "' created.\n\nA UI reload is recommended. Reload now?", "Reload", "Later")
  end
  local function ShowExampleProfileDialog(role, roleColor)
    local popup = addonTable.examplePopup
    local title = addonTable.examplePopupTitle
    local editBox = addonTable.examplePopupEditBox
    local okBtn = addonTable.examplePopupOkBtn
    if not popup then return end
    title:SetText("Create |cff" .. roleColor .. role .. "|r Profile")
    editBox:SetText(role)
    okBtn:SetScript("OnClick", function()
      local name = editBox:GetText()
      if name and name ~= "" then
        CreateExampleProfile(role, name)
        popup:Hide()
      end
    end)
    popup:Show()
    editBox:SetFocus()
    editBox:HighlightText()
  end
  if addonTable.exampleProfileDPSBtn then
    addonTable.exampleProfileDPSBtn:SetScript("OnClick", function()
      ShowExampleProfileDialog("DPS", "ff4444")
    end)
  end
  if addonTable.exampleProfileTankBtn then
    addonTable.exampleProfileTankBtn:SetScript("OnClick", function()
      ShowExampleProfileDialog("Tank", "4488ff")
    end)
  end
  if addonTable.exampleProfileHealerBtn then
    addonTable.exampleProfileHealerBtn:SetScript("OnClick", function()
      ShowExampleProfileDialog("Healer", "44ff88")
    end)
  end
  local cur = addonTable.cursor
  if cur then
    if cur.enabledCB then cur.enabledCB.customOnClick = function(s) local p = GetProfile(); if p then p.cursorIconsEnabled = s:GetChecked(); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.combatOnlyCB then cur.combatOnlyCB.customOnClick = function(s) local p = GetProfile(); if p then p.iconsCombatOnly = s:GetChecked(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.gcdCB then cur.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.cursorShowGCD = s:GetChecked(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.iconSizeSlider then cur.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.iconSize = math.floor(v); s.valueText:SetText(math.floor(v)); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.spacingSlider then cur.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.iconSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.cdTextSlider then cur.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.cdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.stackTextSlider then cur.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.stackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.iconsPerRowSlider then cur.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.iconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.cooldownModeDD then cur.cooldownModeDD.onSelect = function(v)
      local p = GetProfile(); if p then p.cooldownIconMode = v; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end
    end end
    if cur.showModeDD then cur.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.showMode = v; if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.offsetXSlider then cur.offsetXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.offsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.offsetYSlider then cur.offsetYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.offsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end) end
    if cur.directionDD then cur.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.layoutDirection = v; CreateIcons(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.addSpellBtn then
      cur.addSpellBtn:SetScript("OnClick", function()
        local id = tonumber(cur.addBox:GetText())
        if id and addonTable.GetSpellList then
          local s,e = addonTable.GetSpellList()
          table.insert(s, id)
          addonTable.SetSpellList(s,e)
          cur.addBox:SetText("")
          RefreshCursorSpellList()
          CreateIcons()
        end
      end)
    end
    if cur.addItemBtn then
      cur.addItemBtn:SetScript("OnClick", function()
        local id = tonumber(cur.addBox:GetText())
        if id and addonTable.GetSpellList then
          local s,e = addonTable.GetSpellList()
          table.insert(s, -id)
          addonTable.SetSpellList(s,e)
          cur.addBox:SetText("")
          RefreshCursorSpellList()
          CreateIcons()
        end
      end)
    end
    if cur.addTrinketsBtn then
      cur.addTrinketsBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local added = 0
        for _, slot in ipairs({13, 14}) do
          local trinketID = GetInventoryItemID("player", slot)
          if trinketID then
            local spellName = GetItemSpell(trinketID)
            if spellName then
              local exists = false
              for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end
              if not exists then table.insert(s, -trinketID); added = added + 1 end
            end
          end
        end
        if added > 0 then addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
      end)
    end
    if cur.addRacialBtn then
      cur.addRacialBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local added = 0
        local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}
        for _, spellID in ipairs(racialSpells) do
          if IsPlayerSpell(spellID) then
            local exists = false
            for _, id in ipairs(s) do if id == spellID then exists = true; break end end
            if not exists then table.insert(s, spellID); added = added + 1 end
          end
        end
        if added > 0 then addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
      end)
    end
    if cur.addPotionBtn then
      cur.addPotionBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local added = 0
        for bag = 0, 4 do
          local numSlots = C_Container.GetContainerNumSlots(bag)
          for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
              local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
              if classID == 0 and subClassID == 1 then
                local spellName = GetItemSpell(itemID)
                if spellName then
                  local exists = false
                  for _, id in ipairs(s) do if id == -itemID then exists = true; break end end
                  if not exists then table.insert(s, -itemID); added = added + 1 end
                end
              end
            end
          end
        end
        local _, _, playerClassID = UnitClass("player")
        local hsID = playerClassID == 9 and 224464 or 5512
        local hsExists = false
        for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end
        if not hsExists then table.insert(s, -hsID); added = added + 1 end
        if added > 0 then addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
      end)
    end
    if cur.addGCSBtn then
      cur.addGCSBtn:SetScript("OnClick", function()
        if not addonTable.GetSpellList then return end
        local s, e = addonTable.GetSpellList()
        local gcsID = 188152
        local found = false
        for bag = 0, 4 do
          local numSlots = C_Container.GetContainerNumSlots(bag)
          for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID == gcsID then found = true; break end
          end
          if found then break end
        end
        if found then
          local exists = false
          for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end
          if not exists then table.insert(s, -gcsID); addonTable.SetSpellList(s, e); RefreshCursorSpellList(); CreateIcons() end
        end
      end)
    end
    if cur.addBox then
      cur.addBox:SetScript("OnEnterPressed", function()
        if cur.addSpellBtn then cur.addSpellBtn:Click() end
        cur.addBox:ClearFocus()
      end)
    end
    if cur.stackAnchorDD then cur.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.stackTextPosition = v; if addonTable.UpdateStackTextPositions then addonTable.UpdateStackTextPositions() end end end end
    if cur.buffOverlayCB then cur.buffOverlayCB.customOnClick = function(s) local p = GetProfile(); if p then p.useBuffOverlay = s:GetChecked(); if addonTable.UpdateAllIcons then addonTable.UpdateAllIcons() end end end end
    if cur.stackXSlider then cur.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.stackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStackTextPositions then addonTable.UpdateStackTextPositions() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if cur.stackYSlider then cur.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.stackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStackTextPositions then addonTable.UpdateStackTextPositions() end; if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if tabFrames and tabFrames[2] then
      SetupDragDrop(tabFrames[2], addonTable.GetSpellList, addonTable.SetSpellList, RefreshCursorSpellList, CreateIcons)
    end
  end
  local cb1 = addonTable.cb1
  if cb1 then
    if cb1.outOfCombatCB then cb1.outOfCombatCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBarOutOfCombat = s:GetChecked(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.gcdCB then cb1.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBarShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.buffOverlayCB then cb1.buffOverlayCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBarUseBuffOverlay = s:GetChecked(); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.centeredCB then cb1.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBarCentered = s:GetChecked()
        if s:GetChecked() then
          p.customBarX = 0
          if cb1.xSlider then cb1.xSlider:SetValue(0); cb1.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      end
    end end
    if cb1.iconSizeSlider then cb1.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarIconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.spacingSlider then cb1.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.cdTextSlider then cb1.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarCdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.stackTextSlider then cb1.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarStackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.iconsPerRowSlider then cb1.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.cdModeDD then cb1.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarCooldownMode = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.showModeDD then cb1.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarShowMode = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.xSlider then cb1.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.ySlider then cb1.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.directionDD then cb1.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarDirection = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.anchorDD then cb1.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarAnchorPoint = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.growthDD then cb1.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarGrowth = v; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end
    if cb1.anchorTargetBox then
      local function ApplyCB1AnchorTarget()
        local p = GetProfile()
        if not p then return end
        local txt = cb1.anchorTargetBox:GetText() or ""
        txt = txt:gsub("^%s+", ""):gsub("%s+$", "")
        if txt == "" then txt = "UIParent" end
        p.customBarAnchorFrame = txt
        cb1.anchorTargetBox:SetText(txt)
        if addonTable.UpdateCustomBarPosition then addonTable.UpdateCustomBarPosition() end
        if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end
      end
      cb1.anchorTargetBox:SetScript("OnEnterPressed", function(s) ApplyCB1AnchorTarget(); s:ClearFocus() end)
      cb1.anchorTargetBox:SetScript("OnEditFocusLost", function() ApplyCB1AnchorTarget() end)
    end
    if cb1.stackAnchorDD then cb1.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBarStackTextPosition = v; if addonTable.UpdateCustomBarStackTextPositions then addonTable.UpdateCustomBarStackTextPositions() end end end end
    if cb1.stackXSlider then cb1.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarStackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarStackTextPositions then addonTable.UpdateCustomBarStackTextPositions() end end end) end
    if cb1.stackYSlider then cb1.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBarStackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBarStackTextPositions then addonTable.UpdateCustomBarStackTextPositions() end end end) end
    if cb1.addSpellBtn then cb1.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb1.addBox:GetText()); if id and addonTable.GetCustomBarSpells then local s,e = addonTable.GetCustomBarSpells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBarSpells(s,e); cb1.addBox:SetText(""); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addItemBtn then cb1.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb1.addBox:GetText()); if id and addonTable.GetCustomBarSpells then local s,e = addonTable.GetCustomBarSpells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBarSpells(s,e); cb1.addBox:SetText(""); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addTrinketsBtn then cb1.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addRacialBtn then cb1.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if IsPlayerSpell(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addPotionBtn then cb1.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end) end
    if cb1.addGCSBtn then cb1.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBarSpells then return end; local s,e = addonTable.GetCustomBarSpells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBarSpells(s,e); RefreshCB1SpellList(); if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end; if addonTable.UpdateCustomBar then addonTable.UpdateCustomBar() end end end end) end
    if cb1.addBox then cb1.addBox:SetScript("OnEnterPressed", function() if cb1.addSpellBtn then cb1.addSpellBtn:Click() end; cb1.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[3] then SetupDragDrop(tabFrames[3], addonTable.GetCustomBarSpells, addonTable.SetCustomBarSpells, RefreshCB1SpellList, addonTable.CreateCustomBarIcons, addonTable.UpdateCustomBar) end
  end
  local cb2 = addonTable.cb2
  if cb2 then
    if cb2.outOfCombatCB then cb2.outOfCombatCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar2OutOfCombat = s:GetChecked(); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.gcdCB then cb2.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar2ShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.buffOverlayCB then cb2.buffOverlayCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar2UseBuffOverlay = s:GetChecked(); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.centeredCB then cb2.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar2Centered = s:GetChecked()
        if s:GetChecked() then
          p.customBar2X = 0
          if cb2.xSlider then cb2.xSlider:SetValue(0); cb2.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      end
    end end
    if cb2.iconSizeSlider then cb2.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2IconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.spacingSlider then cb2.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2Spacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.cdTextSlider then cb2.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2CdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.stackTextSlider then cb2.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2StackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.iconsPerRowSlider then cb2.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2IconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.cdModeDD then cb2.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2CooldownMode = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.showModeDD then cb2.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2ShowMode = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.xSlider then cb2.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2X = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.ySlider then cb2.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2Y = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.directionDD then cb2.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2Direction = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.anchorDD then cb2.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2AnchorPoint = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.growthDD then cb2.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2Growth = v; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end
    if cb2.anchorTargetBox then
      local function ApplyCB2AnchorTarget()
        local p = GetProfile()
        if not p then return end
        local txt = cb2.anchorTargetBox:GetText() or ""
        txt = txt:gsub("^%s+", ""):gsub("%s+$", "")
        if txt == "" then txt = "UIParent" end
        p.customBar2AnchorFrame = txt
        cb2.anchorTargetBox:SetText(txt)
        if addonTable.UpdateCustomBar2Position then addonTable.UpdateCustomBar2Position() end
        if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end
      end
      cb2.anchorTargetBox:SetScript("OnEnterPressed", function(s) ApplyCB2AnchorTarget(); s:ClearFocus() end)
      cb2.anchorTargetBox:SetScript("OnEditFocusLost", function() ApplyCB2AnchorTarget() end)
    end
    if cb2.stackAnchorDD then cb2.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar2StackTextPosition = v; if addonTable.UpdateCustomBar2StackTextPositions then addonTable.UpdateCustomBar2StackTextPositions() end end end end
    if cb2.stackXSlider then cb2.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2StackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2StackTextPositions then addonTable.UpdateCustomBar2StackTextPositions() end end end) end
    if cb2.stackYSlider then cb2.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar2StackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar2StackTextPositions then addonTable.UpdateCustomBar2StackTextPositions() end end end) end
    if cb2.addSpellBtn then cb2.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb2.addBox:GetText()); if id and addonTable.GetCustomBar2Spells then local s,e = addonTable.GetCustomBar2Spells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBar2Spells(s,e); cb2.addBox:SetText(""); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addItemBtn then cb2.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb2.addBox:GetText()); if id and addonTable.GetCustomBar2Spells then local s,e = addonTable.GetCustomBar2Spells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBar2Spells(s,e); cb2.addBox:SetText(""); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addTrinketsBtn then cb2.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addRacialBtn then cb2.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if IsPlayerSpell(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addPotionBtn then cb2.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end) end
    if cb2.addGCSBtn then cb2.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar2Spells then return end; local s,e = addonTable.GetCustomBar2Spells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBar2Spells(s,e); RefreshCB2SpellList(); if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end; if addonTable.UpdateCustomBar2 then addonTable.UpdateCustomBar2() end end end end) end
    if cb2.addBox then cb2.addBox:SetScript("OnEnterPressed", function() if cb2.addSpellBtn then cb2.addSpellBtn:Click() end; cb2.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[4] then SetupDragDrop(tabFrames[4], addonTable.GetCustomBar2Spells, addonTable.SetCustomBar2Spells, RefreshCB2SpellList, addonTable.CreateCustomBar2Icons, addonTable.UpdateCustomBar2) end
  end
  local cb3 = addonTable.cb3
  if cb3 then
    if cb3.outOfCombatCB then cb3.outOfCombatCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar3OutOfCombat = s:GetChecked(); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.gcdCB then cb3.gcdCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar3ShowGCD = s:GetChecked(); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.buffOverlayCB then cb3.buffOverlayCB.customOnClick = function(s) local p = GetProfile(); if p then p.customBar3UseBuffOverlay = s:GetChecked(); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.centeredCB then cb3.centeredCB.customOnClick = function(s)
      local p = GetProfile()
      if p then
        p.customBar3Centered = s:GetChecked()
        if s:GetChecked() then
          p.customBar3X = 0
          if cb3.xSlider then cb3.xSlider:SetValue(0); cb3.xSlider.valueText:SetText("0") end
        end
        if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      end
    end end
    if cb3.iconSizeSlider then cb3.iconSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3IconSize = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.spacingSlider then cb3.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3Spacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.cdTextSlider then cb3.cdTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3CdTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.stackTextSlider then cb3.stackTextSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3StackTextScale = v; s.valueText:SetText(string.format("%.1f", v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.iconsPerRowSlider then cb3.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3IconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.cdModeDD then cb3.cdModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3CooldownMode = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.showModeDD then cb3.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3ShowMode = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.xSlider then cb3.xSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3X = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.ySlider then cb3.ySlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3Y = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.directionDD then cb3.directionDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3Direction = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.anchorDD then cb3.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3AnchorPoint = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.growthDD then cb3.growthDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3Growth = v; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end
    if cb3.anchorTargetBox then
      local function ApplyCB3AnchorTarget()
        local p = GetProfile()
        if not p then return end
        local txt = cb3.anchorTargetBox:GetText() or ""
        txt = txt:gsub("^%s+", ""):gsub("%s+$", "")
        if txt == "" then txt = "UIParent" end
        p.customBar3AnchorFrame = txt
        cb3.anchorTargetBox:SetText(txt)
        if addonTable.UpdateCustomBar3Position then addonTable.UpdateCustomBar3Position() end
        if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end
      end
      cb3.anchorTargetBox:SetScript("OnEnterPressed", function(s) ApplyCB3AnchorTarget(); s:ClearFocus() end)
      cb3.anchorTargetBox:SetScript("OnEditFocusLost", function() ApplyCB3AnchorTarget() end)
    end
    if cb3.stackAnchorDD then cb3.stackAnchorDD.onSelect = function(v) local p = GetProfile(); if p then p.customBar3StackTextPosition = v; if addonTable.UpdateCustomBar3StackTextPositions then addonTable.UpdateCustomBar3StackTextPositions() end end end end
    if cb3.stackXSlider then cb3.stackXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3StackTextOffsetX = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3StackTextPositions then addonTable.UpdateCustomBar3StackTextPositions() end end end) end
    if cb3.stackYSlider then cb3.stackYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then p.customBar3StackTextOffsetY = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateCustomBar3StackTextPositions then addonTable.UpdateCustomBar3StackTextPositions() end end end) end
    if cb3.addSpellBtn then cb3.addSpellBtn:SetScript("OnClick", function() local id = tonumber(cb3.addBox:GetText()); if id and addonTable.GetCustomBar3Spells then local s,e = addonTable.GetCustomBar3Spells(); table.insert(s, id); table.insert(e, true); addonTable.SetCustomBar3Spells(s,e); cb3.addBox:SetText(""); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addItemBtn then cb3.addItemBtn:SetScript("OnClick", function() local id = tonumber(cb3.addBox:GetText()); if id and addonTable.GetCustomBar3Spells then local s,e = addonTable.GetCustomBar3Spells(); table.insert(s, -id); table.insert(e, true); addonTable.SetCustomBar3Spells(s,e); cb3.addBox:SetText(""); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addTrinketsBtn then cb3.addTrinketsBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local added = 0; for _, slot in ipairs({13, 14}) do local trinketID = GetInventoryItemID("player", slot); if trinketID then local spellName = GetItemSpell(trinketID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -trinketID then exists = true; break end end; if not exists then table.insert(s, -trinketID); table.insert(e, true); added = added + 1 end end end end; if added > 0 then addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addRacialBtn then cb3.addRacialBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local added = 0; local racialSpells = {59752,20594,58984,20589,28880,68992,256948,255647,265221,287712,312924,20572,33697,33702,7744,20577,20549,26297,28730,25046,50613,69179,80483,129597,155145,202719,232633,69041,69070,107079,260364,255654,274738,291944,281954,312411,368970,357214,436717}; for _, spellID in ipairs(racialSpells) do if IsPlayerSpell(spellID) then local exists = false; for _, id in ipairs(s) do if id == spellID then exists = true; break end end; if not exists then table.insert(s, spellID); table.insert(e, true); added = added + 1 end end end; if added > 0 then addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addPotionBtn then cb3.addPotionBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local added = 0; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID then local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID); if classID == 0 and subClassID == 1 then local spellName = GetItemSpell(itemID); if spellName then local exists = false; for _, id in ipairs(s) do if id == -itemID then exists = true; break end end; if not exists then table.insert(s, -itemID); table.insert(e, true); added = added + 1 end end end end end end; local _, _, pClassID = UnitClass("player"); local hsID = pClassID == 9 and 224464 or 5512; local hsExists = false; for _, id in ipairs(s) do if id == -hsID then hsExists = true; break end end; if not hsExists then table.insert(s, -hsID); table.insert(e, true); added = added + 1 end; if added > 0 then addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end) end
    if cb3.addGCSBtn then cb3.addGCSBtn:SetScript("OnClick", function() if not addonTable.GetCustomBar3Spells then return end; local s,e = addonTable.GetCustomBar3Spells(); local gcsID = 188152; local found = false; for bag = 0, 4 do local numSlots = C_Container.GetContainerNumSlots(bag); for slot = 1, numSlots do local itemID = C_Container.GetContainerItemID(bag, slot); if itemID == gcsID then found = true; break end end; if found then break end end; if found then local exists = false; for _, id in ipairs(s) do if id == -gcsID then exists = true; break end end; if not exists then table.insert(s, -gcsID); table.insert(e, true); addonTable.SetCustomBar3Spells(s,e); RefreshCB3SpellList(); if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end; if addonTable.UpdateCustomBar3 then addonTable.UpdateCustomBar3() end end end end) end
    if cb3.addBox then cb3.addBox:SetScript("OnEnterPressed", function() if cb3.addSpellBtn then cb3.addSpellBtn:Click() end; cb3.addBox:ClearFocus() end) end
    if tabFrames and tabFrames[5] then SetupDragDrop(tabFrames[5], addonTable.GetCustomBar3Spells, addonTable.SetCustomBar3Spells, RefreshCB3SpellList, addonTable.CreateCustomBar3Icons, addonTable.UpdateCustomBar3) end
  end
  local function UpdateStandaloneControlsState()
    local p = GetProfile()
    local sa = addonTable.standalone
    if not p or not sa then return end
    local function SC(c, en)
      if not c then return end
      if c.SetEnabled then c:SetEnabled(en) end
      if c.SetAlpha then c:SetAlpha(en and 1 or 0.45) end
    end
    local buffAttached = p.useBuffBar == true
    local essentialAttached = p.useEssentialBar == true
    if sa.skinBuffCB then
      SC(sa.skinBuffCB, not buffAttached)
      if buffAttached then
        sa.skinBuffCB:SetChecked(true)
        p.standaloneSkinBuff = false
      end
    end
    if sa.skinEssentialCB then
      SC(sa.skinEssentialCB, not essentialAttached)
      if essentialAttached then
        sa.skinEssentialCB:SetChecked(true)
        p.standaloneSkinEssential = false
      end
    end
    SC(sa.skinUtilityCB, true)
    local anyAttached = buffAttached or essentialAttached
    if sa.centeredCB then
      SC(sa.centeredCB, not anyAttached)
      if anyAttached then
        sa.centeredCB:SetChecked(false)
        p.standaloneCentered = false
      end
    end
    if sa.buffCenteredCB then
      SC(sa.buffCenteredCB, not buffAttached)
      if buffAttached then sa.buffCenteredCB:SetChecked(false); p.standaloneBuffCentered = false end
    end
    if sa.essentialCenteredCB then
      SC(sa.essentialCenteredCB, not essentialAttached)
      if essentialAttached then sa.essentialCenteredCB:SetChecked(false); p.standaloneEssentialCentered = false end
    end
    SC(sa.utilityCenteredCB, true)
    SC(sa.buffSizeSlider, not buffAttached)
    SC(sa.buffRowsDD, not buffAttached)
    SC(sa.buffGrowDD, (not buffAttached) and (not p.standaloneBuffCentered))
    SC(sa.buffRowGrowDD, not buffAttached)
    SC(sa.buffIconsPerRowSlider, not buffAttached)
    SC(sa.buffYSlider, not buffAttached)
    SC(sa.buffXSlider, not buffAttached and not p.standaloneBuffCentered)
    SC(sa.essentialSizeSlider, not essentialAttached)
    if sa.essentialSecondRowSizeSlider then
      local essentialRows = type(p.standaloneEssentialMaxRows) == "number" and p.standaloneEssentialMaxRows or 2
      SC(sa.essentialSecondRowSizeSlider, (not essentialAttached) and (essentialRows > 1))
    end
    SC(sa.essentialRowsDD, not essentialAttached)
    SC(sa.essentialGrowDD, (not essentialAttached) and (not p.standaloneEssentialCentered))
    SC(sa.essentialRowGrowDD, not essentialAttached)
    SC(sa.essentialIconsPerRowSlider, not essentialAttached)
    SC(sa.essentialYSlider, not essentialAttached)
    SC(sa.essentialXSlider, not essentialAttached and not p.standaloneEssentialCentered)
    local utilityAuto = (p.standaloneUtilityAutoWidth or "off") ~= "off"
    if sa.utilitySizeSlider then
      SC(sa.utilitySizeSlider, not utilityAuto)
      if sa.utilitySizeSlider.label then
        sa.utilitySizeSlider.label:SetTextColor(utilityAuto and 0.5 or 1, utilityAuto and 0.5 or 1, utilityAuto and 0.5 or 1)
      end
    end
    SC(sa.utilityRowsDD, true)
    SC(sa.utilityGrowDD, not p.standaloneUtilityCentered)
    SC(sa.utilityRowGrowDD, true)
    SC(sa.utilityIconsPerRowSlider, true)
    SC(sa.utilityYSlider, true)
    SC(sa.utilityXSlider, not p.standaloneUtilityCentered)
    if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
  end
  addonTable.UpdateStandaloneControlsState = UpdateStandaloneControlsState
  local function UpdateBlizzCDMDisabledState()
    local p = GetProfile()
    if not p then return end
    local disabled = p.disableBlizzCDM == true
    local buffAttached = p.useBuffBar == true
    local essentialAttached = p.useEssentialBar == true
    local function SetControlEnabled(control, enabled)
      if not control then return end
      if control.SetEnabled then control:SetEnabled(enabled) end
      if control.SetAlpha then control:SetAlpha(enabled and 1 or 0.45) end
    end
    SetControlEnabled(addonTable.skinningModeDD, not disabled)
    SetControlEnabled(addonTable.buffBarCB, not disabled)
    SetControlEnabled(addonTable.essentialBarCB, not disabled)
    SetControlEnabled(addonTable.buffSizeSlider, not disabled)
    local sa = addonTable.standalone
    if sa then
      local buffOK = not disabled and not buffAttached
      local essentialOK = not disabled and not essentialAttached
      SetControlEnabled(sa.skinBuffCB, buffOK)
      SetControlEnabled(sa.skinEssentialCB, essentialOK)
      SetControlEnabled(sa.skinUtilityCB, not disabled)
      SetControlEnabled(sa.buffCenteredCB, buffOK)
      SetControlEnabled(sa.essentialCenteredCB, essentialOK)
      SetControlEnabled(sa.utilityCenteredCB, not disabled)
      SetControlEnabled(sa.spacingSlider, not disabled)
      SetControlEnabled(sa.borderSizeSlider, not disabled)
      SetControlEnabled(sa.buffSizeSlider, buffOK)
      SetControlEnabled(sa.buffRowsDD, buffOK)
      SetControlEnabled(sa.buffGrowDD, buffOK and (not p.standaloneBuffCentered))
      SetControlEnabled(sa.buffRowGrowDD, buffOK)
      SetControlEnabled(sa.buffIconsPerRowSlider, buffOK)
      SetControlEnabled(sa.buffYSlider, buffOK)
      SetControlEnabled(sa.buffXSlider, buffOK and not p.standaloneBuffCentered)
      SetControlEnabled(sa.essentialSizeSlider, essentialOK)
      SetControlEnabled(sa.essentialSecondRowSizeSlider, essentialOK)
      SetControlEnabled(sa.essentialIconsPerRowSlider, essentialOK)
      SetControlEnabled(sa.essentialRowsDD, essentialOK)
      SetControlEnabled(sa.essentialGrowDD, essentialOK and (not p.standaloneEssentialCentered))
      SetControlEnabled(sa.essentialRowGrowDD, essentialOK)
      SetControlEnabled(sa.essentialYSlider, essentialOK)
      SetControlEnabled(sa.essentialXSlider, essentialOK and not p.standaloneEssentialCentered)
      SetControlEnabled(sa.utilityAutoWidthDD, not disabled)
      local utilityAuto = (p.standaloneUtilityAutoWidth or "off") ~= "off"
      SetControlEnabled(sa.utilitySizeSlider, (not disabled) and (not utilityAuto))
      SetControlEnabled(sa.utilityIconsPerRowSlider, not disabled)
      SetControlEnabled(sa.utilityRowsDD, not disabled)
      SetControlEnabled(sa.utilityGrowDD, (not disabled) and (not p.standaloneUtilityCentered))
      SetControlEnabled(sa.utilityRowGrowDD, not disabled)
      SetControlEnabled(sa.utilityYSlider, not disabled)
      SetControlEnabled(sa.utilityXSlider, not disabled)
    end
  end
  addonTable.UpdateBlizzCDMDisabledState = UpdateBlizzCDMDisabledState
  local function UpdateSkinCheckboxes()
    local p = GetProfile()
    local sa = addonTable.standalone
    if not p or not sa then return end
    local enabled = (p.blizzardBarSkinning ~= false) or (p.enableMasque == true)
    if sa.skinBuffCB and sa.skinBuffCB.SetEnabled then sa.skinBuffCB:SetEnabled(enabled) end
    if sa.skinEssentialCB and sa.skinEssentialCB.SetEnabled then sa.skinEssentialCB:SetEnabled(enabled) end
    if sa.skinUtilityCB and sa.skinUtilityCB.SetEnabled then sa.skinUtilityCB:SetEnabled(enabled) end
  end
  local Masque = LibStub and LibStub("Masque", true)
  if addonTable.skinningModeDD then
    addonTable.skinningModeDD:SetOptions({
      {text = "None", value = "none"},
      {text = "CCM Built-in", value = "ccm"},
      {text = Masque and "Masque" or "Masque (not installed)", value = "masque", disabled = not Masque},
    })
    addonTable.skinningModeDD.onSelect = function(v)
      local p = GetProfile(); if not p then return end
      if p.disableBlizzCDM == true then return end
      local wasEnabled = p.enableMasque or p.blizzardBarSkinning
      if v == "masque" then
        p.enableMasque = true; p.blizzardBarSkinning = false
      elseif v == "ccm" then
        p.enableMasque = false; p.blizzardBarSkinning = true
      else
        p.enableMasque = false; p.blizzardBarSkinning = false
        if wasEnabled then
          ShowReloadPrompt("Disabling skinning mode requires a UI reload to fully remove skin effects. Reload now?", "Reload", "Later")
        end
      end
      UpdateSkinCheckboxes()
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
    end
  end
  if addonTable.disableBlizzCDMCB then
    addonTable.disableBlizzCDMCB.customOnClick = function(s)
      local p = GetProfile(); if not p then return end
      local wasDisabled = p.disableBlizzCDM == true
      p.disableBlizzCDM = s:GetChecked() == true
      if p.disableBlizzCDM then
        if addonTable.ResetBlizzardBarSkinning then addonTable.ResetBlizzardBarSkinning() end
        if addonTable.RestoreBuffBarPosition then addonTable.RestoreBuffBarPosition() end
        if addonTable.RestoreEssentialBarPosition then addonTable.RestoreEssentialBarPosition() end
      end
      if addonTable.State then addonTable.State.standaloneNeedsSkinning = true end
      if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end
      if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end
      if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end
      if addonTable.UpdateBlizzCDMDisabledState then addonTable.UpdateBlizzCDMDisabledState() end
      if p.disableBlizzCDM and not wasDisabled then
        ShowReloadPrompt("Disabling Blizz CDM is safest after a UI reload. Reload now?", "Reload", "Later")
      end
    end
  end
  if addonTable.openBlizzCDMBtn then
    addonTable.openBlizzCDMBtn:SetScript("OnClick", function()
      local cfg = addonTable.ConfigFrame
      if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      end
      local opened = false
      if SlashCmdList and SlashCmdList.BLIZZCM then
        local ok = pcall(SlashCmdList.BLIZZCM, "")
        opened = ok == true
      end
      if not opened and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
        if SlashCmdList and SlashCmdList.BLIZZCM then
          pcall(SlashCmdList.BLIZZCM, "")
          opened = true
        end
      end
      if not opened and addonTable.ShowMessagePopup then
        addonTable.ShowMessagePopup("Blizzard CDM konnte nicht geoeffnet werden.", "OK")
      end
    end)
  end
  if addonTable.openEditModeBtn then
    addonTable.openEditModeBtn:SetScript("OnClick", function()
      local cfg = addonTable.ConfigFrame
      if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      end
      local opened = false
      if SlashCmdList and SlashCmdList.CCMEDITMODE then
        local ok = pcall(SlashCmdList.CCMEDITMODE, "")
        opened = ok == true
      end
      if not opened and EditModeManagerFrame and EditModeManagerFrame.Show then
        local ok = pcall(EditModeManagerFrame.Show, EditModeManagerFrame)
        opened = ok == true
      end
      if not opened and addonTable.ShowMessagePopup then
        addonTable.ShowMessagePopup("Edit Mode konnte nicht geoeffnet werden.", "OK")
      end
    end)
  end
  if addonTable.buffBarCB then addonTable.buffBarCB.customOnClick = function(s) 
    local p = GetProfile()
    if p and p.disableBlizzCDM == true then s:SetChecked(false); return end
    if p then 
      local wasAttached = p.useBuffBar
      p.useBuffBar = s:GetChecked()
      UpdateStandaloneControlsState()
      if s:GetChecked() and not wasAttached then
        ShowReloadPrompt("Attaching Blizzard bars to cursor requires a UI reload for best results. Reload now?", "Reload", "Later")
      end
    end 
  end end
  if addonTable.essentialBarCB then addonTable.essentialBarCB.customOnClick = function(s) 
    local p = GetProfile()
    if p and p.disableBlizzCDM == true then s:SetChecked(false); return end
    if p then 
      local wasAttached = p.useEssentialBar
      p.useEssentialBar = s:GetChecked()
      UpdateStandaloneControlsState()
      if s:GetChecked() and not wasAttached then
        ShowReloadPrompt("Attaching Blizzard bars to cursor requires a UI reload for best results. Reload now?", "Reload", "Later")
      end
    end 
  end end
  if addonTable.buffSizeSlider then addonTable.buffSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.buffBarIconSizeOffset = math.floor(v); s.valueText:SetText(math.floor(v)) end end) end
  local sa = addonTable.standalone
  if sa then
    local function ShowReloadPromptLocal(was)
      if was then
        ShowReloadPrompt("Disabling standalone bar skinning requires a UI reload. Reload now?", "Reload", "Later")
      end
    end
    if sa.skinBuffCB then sa.skinBuffCB.customOnClick = function(s) local p = GetProfile(); if p and p.disableBlizzCDM == true then s:SetChecked(false); return end; if p then local was = p.standaloneSkinBuff; p.standaloneSkinBuff = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPromptLocal(true) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.skinEssentialCB then sa.skinEssentialCB.customOnClick = function(s) local p = GetProfile(); if p and p.disableBlizzCDM == true then s:SetChecked(false); return end; if p then local was = p.standaloneSkinEssential; p.standaloneSkinEssential = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPromptLocal(true) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.skinUtilityCB then sa.skinUtilityCB.customOnClick = function(s) local p = GetProfile(); if p and p.disableBlizzCDM == true then s:SetChecked(false); return end; if p then local was = p.standaloneSkinUtility; p.standaloneSkinUtility = s:GetChecked(); if was and not s:GetChecked() then ShowReloadPromptLocal(true) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.buffCenteredCB then sa.buffCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true then s:SetChecked(p.standaloneBuffCentered == true); return end; p.standaloneBuffCentered = s:GetChecked(); if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.essentialCenteredCB then sa.essentialCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true then s:SetChecked(p.standaloneEssentialCentered == true); return end; p.standaloneEssentialCentered = s:GetChecked(); if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.utilityCenteredCB then sa.utilityCenteredCB.customOnClick = function(s) local p = GetProfile(); if p then if p.disableBlizzCDM == true then s:SetChecked(p.standaloneUtilityCentered == true); return end; p.standaloneUtilityCentered = s:GetChecked(); if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end; if addonTable.EvaluateMainTicker then addonTable.EvaluateMainTicker() end end end end
    if sa.spacingSlider then sa.spacingSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneSpacing = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end end end) end
    if sa.borderSizeSlider then sa.borderSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneIconBorderSize = math.floor(v); s.valueText:SetText(math.floor(v)); addonTable.State.standaloneNeedsSkinning = true; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end end end) end
    if sa.buffSizeSlider then sa.buffSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffSize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.buffIconsPerRowSlider then sa.buffIconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.buffRowsDD then sa.buffRowsDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffMaxRows = tonumber(v) or 2; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.buffGrowDD then sa.buffGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffGrowDirection = v or "right"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.buffRowGrowDD then sa.buffRowGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneBuffRowGrowDirection = v or "down"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.buffYSlider then sa.buffYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarBuffY = n; p.standaloneBuffY = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.buffXSlider then sa.buffXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarBuffX = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.essentialSizeSlider then sa.essentialSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialSize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.essentialSecondRowSizeSlider then sa.essentialSecondRowSizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialSecondRowSize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.essentialIconsPerRowSlider then sa.essentialIconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.essentialRowsDD then sa.essentialRowsDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialMaxRows = tonumber(v) or 2; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.essentialGrowDD then sa.essentialGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialGrowDirection = v or "right"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.essentialRowGrowDD then sa.essentialRowGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneEssentialRowGrowDirection = v or "down"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.essentialYSlider then sa.essentialYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarEssentialY = n; p.standaloneEssentialY = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.essentialXSlider then sa.essentialXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarEssentialX = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.utilitySizeSlider then sa.utilitySizeSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilitySize = v; s.valueText:SetText(v); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.utilityIconsPerRowSlider then sa.utilityIconsPerRowSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityIconsPerRow = math.floor(v); s.valueText:SetText(math.floor(v)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end) end
    if sa.utilityRowsDD then sa.utilityRowsDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityMaxRows = tonumber(v) or 2; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.utilityGrowDD then sa.utilityGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityGrowDirection = v or "right"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.utilityRowGrowDD then sa.utilityRowGrowDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityRowGrowDirection = v or "down"; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end end end end
    if sa.utilityAutoWidthDD then sa.utilityAutoWidthDD.onSelect = function(v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; p.standaloneUtilityAutoWidth = v; if addonTable.UpdateStandaloneControlsState then addonTable.UpdateStandaloneControlsState() end; if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(6) end end end end
    if sa.utilityYSlider then sa.utilityYSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarUtilityY = n; p.standaloneUtilityY = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
    if sa.utilityXSlider then sa.utilityXSlider:SetScript("OnValueChanged", function(s, v) local p = GetProfile(); if p then if p.disableBlizzCDM == true then return end; local n = RoundToHalf(v); p.blizzBarUtilityX = n; s.valueText:SetText(FormatHalf(n)); if addonTable.UpdateStandaloneBlizzardBars then addonTable.UpdateStandaloneBlizzardBars() end; if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.ShowBlizzBarDragOverlays then addonTable.ShowBlizzBarDragOverlays(true) end end end) end
  end
  local exportCategoryKeys = {
    general = {"iconBorderSize", "iconStrata", "enableMasque", "showMinimapButton", "minimapButtonAngle",
               "customBarsCount", "uiScale", "uiScaleMode", "blizzardBarSkinning",
               "cdFont", "globalFont", "globalOutline",
               "customBarIconSize", "customBarSpacing", "customBarCdTextScale",
               "customBarStackTextScale", "customBarDirection", "customBarGrowth", "customBarAnchorPoint", "customBarAnchorFrame",
               "customBarX", "customBarY", "customBarCentered", "customBarCooldownMode", "customBarShowMode", "customBarIconsPerRow",
               "customBarOutOfCombat", "customBarShowGCD", "customBarUseBuffOverlay", "customBarStackTextPosition",
               "customBarStackTextOffsetX", "customBarStackTextOffsetY",
               "customBar2IconSize", "customBar2Spacing", "customBar2CdTextScale",
               "customBar2StackTextScale", "customBar2Direction", "customBar2Growth", "customBar2AnchorPoint", "customBar2AnchorFrame",
               "customBar2X", "customBar2Y", "customBar2Centered", "customBar2CooldownMode", "customBar2ShowMode", "customBar2IconsPerRow",
               "customBar2OutOfCombat", "customBar2ShowGCD", "customBar2UseBuffOverlay", "customBar2StackTextPosition",
               "customBar2StackTextOffsetX", "customBar2StackTextOffsetY",
               "customBar3IconSize", "customBar3Spacing", "customBar3CdTextScale",
               "customBar3StackTextScale", "customBar3Direction", "customBar3Growth", "customBar3AnchorPoint", "customBar3AnchorFrame",
               "customBar3X", "customBar3Y", "customBar3Centered", "customBar3CooldownMode", "customBar3ShowMode", "customBar3IconsPerRow",
               "customBar3OutOfCombat", "customBar3ShowGCD", "customBar3UseBuffOverlay", "customBar3StackTextPosition",
               "customBar3StackTextOffsetX", "customBar3StackTextOffsetY"},
    qol = {"selfHighlightShape", "selfHighlightVisibility", "selfHighlightSize", "selfHighlightY",
           "selfHighlightThickness", "selfHighlightOutline", "selfHighlightColorR", "selfHighlightColorG", "selfHighlightColorB",
           "noTargetAlertEnabled", "noTargetAlertFlash", "noTargetAlertX", "noTargetAlertY", "noTargetAlertFontSize",
           "noTargetAlertColorR", "noTargetAlertColorG", "noTargetAlertColorB",
              "hideActionBar1InCombat", "hideActionBar1Mouseover", "hideActionBar1Always",
               "hideAB2InCombat", "hideAB2Mouseover", "hideAB2Always",
               "hideAB3InCombat", "hideAB3Mouseover", "hideAB3Always",
               "hideAB4InCombat", "hideAB4Mouseover", "hideAB4Always",
               "hideAB5InCombat", "hideAB5Mouseover", "hideAB5Always",
               "hideAB6InCombat", "hideAB6Mouseover", "hideAB6Always",
               "hideAB7InCombat", "hideAB7Mouseover", "hideAB7Always",
               "hideAB8InCombat", "hideAB8Mouseover", "hideAB8Always",
                "hideStanceBarInCombat", "hideStanceBarMouseover", "hideStanceBarAlways",
                "hidePetBarInCombat", "hidePetBarMouseover", "hidePetBarAlways",
                "actionBarGlobalMode", "fadeMicroMenu", "hideActionBarBorders", "abSkinSpacing", "fadeObjectiveTracker", "fadeBagBar",
               "betterItemLevel", "showEquipmentDetails",
               "chatClassColorNames", "chatTimestamps", "chatTimestampFormat", "chatCopyButton", "chatCopyButtonCorner",
               "chatUrlDetection", "chatBackground", "chatBackgroundAlpha", "chatBackgroundColorR", "chatBackgroundColorG", "chatBackgroundColorB",
               "chatHideButtons", "chatFadeToggle", "chatFadeDelay", "chatEditBoxPosition", "chatEditBoxStyled", "chatTabFlash", "chatHideTabs",
               "skyridingEnabled", "skyridingScale", "skyridingCentered", "skyridingX", "skyridingY",
               "skyridingVigorBar", "skyridingVigorColorR", "skyridingVigorColorG", "skyridingVigorColorB",
               "skyridingVigorEmptyColorR", "skyridingVigorEmptyColorG", "skyridingVigorEmptyColorB",
               "skyridingVigorRechargeColorR", "skyridingVigorRechargeColorG", "skyridingVigorRechargeColorB",
               "skyridingSpeedDisplay", "skyridingSpeedBar", "skyridingSpeedUnit", "skyridingSpeedColorR", "skyridingSpeedColorG", "skyridingSpeedColorB",
               "skyridingWhirlingSurgeColorR", "skyridingWhirlingSurgeColorG", "skyridingWhirlingSurgeColorB",
               "skyridingSecondWindColorR", "skyridingSecondWindColorG", "skyridingSecondWindColorB",
               "skyridingTexture", "skyridingCooldowns", "skyridingHideCDM",
                "showRadialCircle", "radialRadius", "radialColorR", "radialColorG", "radialColorB",
             "autoRepair", "showTooltipIDs", "compactMinimapIcons", "enhancedTooltip",
             "autoQuest", "autoQuestExcludeDaily", "autoQuestExcludeWeekly", "autoQuestExcludeTrivial", "autoQuestExcludeCompleted", "autoQuestRewardMode",
             "autoSellJunk", "autoFillDelete", "quickRoleSignup",
             "combatTimerEnabled", "combatTimerMode", "combatTimerStyle", "combatTimerCentered",
             "combatTimerX", "combatTimerY", "combatTimerScale",
              "combatTimerTextColorR", "combatTimerTextColorG", "combatTimerTextColorB",
              "combatTimerBgColorR", "combatTimerBgColorG", "combatTimerBgColorB", "combatTimerBgAlpha",
              "crTimerEnabled", "crTimerMode", "crTimerDisplay", "crTimerLayout", "crTimerCentered", "crTimerX", "crTimerY", "crTimerScale",
              "combatStatusEnabled", "combatStatusCentered", "combatStatusX", "combatStatusY", "combatStatusScale",
              "combatStatusEnterColorR", "combatStatusEnterColorG", "combatStatusEnterColorB",
              "combatStatusLeaveColorR", "combatStatusLeaveColorG", "combatStatusLeaveColorB",
                "radialAlpha", "radialThickness", "radialCombatOnly", "radialShowGCD"},
    cursor = {"iconSize", "iconSpacing", "offsetX", "offsetY", "cdTextScale", "stackTextScale",
              "layoutDirection", "growDirection", "iconsPerRow",
              "numColumns", "showGCD", "cursorShowGCD", "iconsCombatOnly", "cursorCombatOnly",
              "stackTextPosition", "stackTextOffsetX", "stackTextOffsetY", "useBuffOverlay", "cooldownIconMode", "showMode",
              "glowWhenReady", "showInCombatOnly"},
    blizzcdm = {"disableBlizzCDM", "useBuffBar", "useEssentialBar",
                "essentialBarSpacing", "standaloneIconBorderSize", "standaloneSkinBuff", "standaloneSkinEssential", "standaloneSkinUtility",
                "standaloneCentered", "standaloneBuffCentered", "standaloneEssentialCentered", "standaloneUtilityCentered",
                "standaloneSpacing", "standaloneBuffSize", "standaloneBuffIconsPerRow", "standaloneBuffMaxRows", "standaloneBuffGrowDirection", "standaloneBuffRowGrowDirection", "standaloneBuffY", "standaloneBuffX",
                "standaloneEssentialSize", "standaloneEssentialSecondRowSize", "standaloneEssentialIconsPerRow", "standaloneEssentialMaxRows", "standaloneEssentialGrowDirection", "standaloneEssentialRowGrowDirection", "standaloneEssentialY", "standaloneEssentialX",
                "standaloneUtilitySize", "standaloneUtilitySecondRowSize", "standaloneUtilityIconsPerRow", "standaloneUtilityMaxRows", "standaloneUtilityGrowDirection", "standaloneUtilityRowGrowDirection", "standaloneUtilityY", "standaloneUtilityX", "standaloneUtilityAutoWidth",
                "blizzBarBuffX", "blizzBarBuffY", "blizzBarEssentialX", "blizzBarEssentialY",
                "blizzBarUtilityX", "blizzBarUtilityY"},
    prb = {"usePersonalResourceBar", "prbWidth", "prbX", "prbY", "prbCentered", "prbShowMode", "prbAutoWidthSource",
           "prbSpacing", "prbBorderSize", "prbBackgroundAlpha", "prbClampBars", "prbClampAnchor",
           "prbBgColorR", "prbBgColorG", "prbBgColorB",
           "prbShowHealth", "prbShowPower", "prbShowClassPower",
           "prbHealthHeight", "prbHealthYOffset", "prbHealthTexture", "prbAbsorbTexture", "prbHealAbsorb", "prbDmgAbsorb", "prbHealPred", "prbAbsorbStripes", "prbOverAbsorbBar", "prbHealthTextMode", "prbHealthTextScale", "prbHealthTextY",
           "prbHealthColorR", "prbHealthColorG", "prbHealthColorB",
           "prbHealthTextColorR", "prbHealthTextColorG", "prbHealthTextColorB", "prbUseClassColor",
           "prbPowerHeight", "prbPowerYOffset", "prbPowerTexture", "prbPowerTextMode", "prbPowerTextScale", "prbPowerTextY",
           "prbPowerColorR", "prbPowerColorG", "prbPowerColorB",
           "prbPowerTextColorR", "prbPowerTextColorG", "prbPowerTextColorB", "prbUsePowerTypeColor",
           "prbManaHeight", "prbManaYOffset", "prbManaTexture", "prbManaTextMode", "prbManaTextScale", "prbManaTextY",
           "prbManaColorR", "prbManaColorG", "prbManaColorB",
           "prbManaTextColorR", "prbManaTextColorG", "prbManaTextColorB", "prbShowManaBar",
           "prbClassPowerHeight", "prbClassPowerY", "prbClassPowerX",
           "prbClassPowerColorR", "prbClassPowerColorG", "prbClassPowerColorB"},
    castbar = {"useCastbar",
               "castbarWidth", "castbarHeight", "castbarX", "castbarY", "castbarCentered",
               "castbarTexture", "castbarBorderSize", "castbarBgAlpha", "castbarAutoWidthSource",
               "castbarColorR", "castbarColorG", "castbarColorB",
               "castbarBgColorR", "castbarBgColorG", "castbarBgColorB",
               "castbarTextColorR", "castbarTextColorG", "castbarTextColorB",
               "castbarUseClassColor", "castbarShowIcon", "castbarIconSize",
               "castbarShowTime", "castbarTimeScale",
               "castbarShowSpellName", "castbarSpellNameScale"},
    focuscastbar = {"useFocusCastbar",
               "focusCastbarWidth", "focusCastbarHeight", "focusCastbarX", "focusCastbarY", "focusCastbarCentered",
               "focusCastbarTexture", "focusCastbarBorderSize", "focusCastbarBgAlpha",
               "focusCastbarColorR", "focusCastbarColorG", "focusCastbarColorB",
               "focusCastbarBgColorR", "focusCastbarBgColorG", "focusCastbarBgColorB",
               "focusCastbarTextColorR", "focusCastbarTextColorG", "focusCastbarTextColorB",
               "focusCastbarShowIcon", "focusCastbarIconSize",
               "focusCastbarShowTime", "focusCastbarTimeScale",
               "focusCastbarShowSpellName", "focusCastbarSpellNameScale",
               "focusCastbarShowTicks", "focusCastbarSpellNameXOffset", "focusCastbarSpellNameYOffset",
               "focusCastbarTimeXOffset", "focusCastbarTimeYOffset", "focusCastbarTimePrecision", "focusCastbarTimeDirection"},
    debuffs = {"playerDebuffSize", "playerDebuffSpacing", "playerDebuffX", "playerDebuffY",
               "playerDebuffSortDirection", "playerDebuffIconsPerRow", "playerDebuffRowGrowDirection",
               "playerDebuffBorderSize"},
    uf = {"enablePlayerDebuffs",
               "ufClassColor", "ufUseCustomTextures", "ufHealthTexture",
               "ufDisableGlows", "ufDisableCombatText",
               "disableTargetBuffs", "hideEliteTexture",
               "useCustomBorderColor", "ufCustomBorderColorR", "ufCustomBorderColorG", "ufCustomBorderColorB",
               "ufUseCustomNameColor", "ufNameColorR", "ufNameColorG", "ufNameColorB",
               "ufBigHBPlayerEnabled", "ufBigHBTargetEnabled", "ufBigHBFocusEnabled",
               "ufBigHBPlayerHealAbsorb", "ufBigHBPlayerDmgAbsorb", "ufBigHBPlayerHealPred", "ufBigHBPlayerAbsorbStripes",
               "ufBigHBTargetHealAbsorb", "ufBigHBTargetDmgAbsorb", "ufBigHBTargetHealPred", "ufBigHBTargetAbsorbStripes",
               "ufBigHBFocusHealAbsorb", "ufBigHBFocusDmgAbsorb", "ufBigHBFocusHealPred", "ufBigHBFocusAbsorbStripes",
               "ufBigHBHidePlayerName", "ufBigHBPlayerLevelMode",
               "ufBigHBPlayerNameX", "ufBigHBPlayerNameY", "ufBigHBPlayerLevelX", "ufBigHBPlayerLevelY",
               "ufBigHBPlayerNameTextScale", "ufBigHBPlayerLevelTextScale",
               "ufBigHBHideTargetName", "ufBigHBTargetLevelMode",
               "ufBigHBTargetNameX", "ufBigHBTargetNameY", "ufBigHBTargetLevelX", "ufBigHBTargetLevelY",
               "ufBigHBTargetNameTextScale", "ufBigHBTargetLevelTextScale",
               "ufBigHBHideFocusName", "ufBigHBFocusLevelMode",
               "ufBigHBFocusNameX", "ufBigHBFocusNameY", "ufBigHBFocusLevelX", "ufBigHBFocusLevelY",
               "ufBigHBFocusNameTextScale", "ufBigHBFocusLevelTextScale",
               "ufBigHBNameMaxChars",
               "ufBigHBHideRealm",
               "ufBigHBPlayerMaskFixWidth", "ufBigHBPlayerMaskFixHeight", "ufBigHBPlayerMaskFixXOffset", "ufBigHBPlayerMaskFixYOffset", "ufBigHBPlayerMaskFixScale",
               "ufBigHBPlayerMaskFixColorR", "ufBigHBPlayerMaskFixColorG", "ufBigHBPlayerMaskFixColorB", "ufBigHBPlayerMaskFixColorA",
               "ufBigHBOtherMaskFixWidth", "ufBigHBOtherMaskFixHeight", "ufBigHBOtherMaskFixXOffset", "ufBigHBOtherMaskFixYOffset", "ufBigHBOtherMaskFixScale",
               "ufBigHBOtherMaskFixColorR", "ufBigHBOtherMaskFixColorG", "ufBigHBOtherMaskFixColorB", "ufBigHBOtherMaskFixColorA",
               },
  }
  local keyToCategory = {}
  for cat, keys in pairs(exportCategoryKeys) do
    for _, k in ipairs(keys) do
      keyToCategory[k] = cat
    end
  end
  if addonTable.importBtn then
    addonTable.importBtn:SetScript("OnClick", function()
      if addonTable.exportImportPopup then
        addonTable.exportImportTitle:SetText("Import Profile Settings")
        addonTable.importExportBox:SetText("")
        addonTable.exportCheckboxContainer:Hide()
        addonTable.generateExportBtn:Hide()
        addonTable.exportImportOkBtn:Show()
        addonTable.exportImportPopup:SetSize(480, 315)
        addonTable.exportImportScrollFrame:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 15, -110)
        addonTable.exportImportScrollFrame:SetSize(420, 145)
        addonTable.importExportBox:SetWidth(400)
        addonTable.importExportBox:SetHeight(200)
        if addonTable.editBoxBg then
          addonTable.editBoxBg:SetPoint("TOPLEFT", addonTable.exportImportScrollFrame, "TOPLEFT", -5, 5)
          addonTable.editBoxBg:SetPoint("BOTTOMRIGHT", addonTable.exportImportScrollFrame, "BOTTOMRIGHT", 15, -5)
        end
        if addonTable.importContainer then addonTable.importContainer:Show() end
        if addonTable.importProfileNameBox then addonTable.importProfileNameBox:SetText("") end
        if addonTable.importSharedCB then addonTable.importSharedCB:SetChecked(true) end
        local function DoImport()
          local str = addonTable.importExportBox:GetText()
          local profileName = addonTable.importProfileNameBox and addonTable.importProfileNameBox:GetText() or ""
          if profileName == "" or profileName:match("^%s*$") then
            print("|cffff6666CCM:|r Please enter a profile name!")
            if addonTable.importProfileNameBox then
              addonTable.importProfileNameBox:SetBackdropBorderColor(1, 0.3, 0.3, 1)
              addonTable.importProfileNameBox:SetFocus()
              C_Timer.After(2, function()
                if addonTable.importProfileNameBox then
                  addonTable.importProfileNameBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                end
              end)
            end
            return
          end
          if not str or str == "" then
            print("|cffff6666CCM:|r Please paste an import string!")
            addonTable.importExportBox:SetFocus()
            return
          end
          if str and (str:match("^CCM:") or str:match("^CCM2:")) then
            local origName, data = str:match("^CCM2?:([^:]+):(.+)$")
            if origName and data then
              local baseName = profileName
              local counter = 1
              while CooldownCursorManagerDB.profiles[profileName] do
                profileName = baseName .. "_" .. counter
                counter = counter + 1
              end
              CooldownCursorManagerDB.profiles[profileName] = {}
              CooldownCursorManagerDB.currentProfile = profileName
              local isShared = addonTable.importSharedCB and addonTable.importSharedCB:GetChecked()
              if not isShared then
                local _, playerClass = UnitClass("player")
                if playerClass then
                  CooldownCursorManagerDB.profileClasses = CooldownCursorManagerDB.profileClasses or {}
                  CooldownCursorManagerDB.profileClasses[profileName] = playerClass
                end
              end
              if addonTable.SaveCurrentProfileForSpec then
                addonTable.SaveCurrentProfileForSpec()
              else
                local playerName = UnitName("player")
                local realmName = GetRealmName()
                if playerName and realmName then
                  local characterKey = playerName .. "-" .. realmName
                  CooldownCursorManagerDB.characterProfiles = CooldownCursorManagerDB.characterProfiles or {}
                  CooldownCursorManagerDB.characterProfiles[characterKey] = profileName
                end
              end
              local profile = GetProfile()
              if profile then
                for k, v in data:gmatch("([%w_]+)=([^;]+);") do
                  if v:match("^\"(.*)\"$") then
                    profile[k] = v:match("^\"(.*)\"$")
                  elseif tonumber(v) then
                    local num = tonumber(v)
                    if num == 0 or num == 1 then
                      local boolKeys = {
                        showRadialCircle = true, showGCD = true, cursorShowGCD = true, showInCombatOnly = true,
                        iconsCombatOnly = true, cursorCombatOnly = true, glowWhenReady = true,
                        customBarOutOfCombat = true, customBarShowGCD = true, customBarCentered = true,
                        customBar2OutOfCombat = true, customBar2ShowGCD = true, customBar2Centered = true,
                        customBar3OutOfCombat = true, customBar3ShowGCD = true, customBar3Centered = true,
                        useBuffBar = true, useEssentialBar = true, blizzardBarSkinning = true, enableMasque = true, showMinimapButton = true,
                        standaloneSkinBuff = true, standaloneSkinEssential = true, standaloneSkinUtility = true,
                        standaloneCentered = true, standaloneBuffCentered = true, standaloneEssentialCentered = true, standaloneUtilityCentered = true,
                        usePersonalResourceBar = true, prbCentered = true, prbShowHealth = true, prbShowPower = true,
                        prbShowClassPower = true, prbUseClassColor = true, prbUsePowerTypeColor = true, prbShowManaBar = true, prbClampBars = true,
                        hideActionBar1InCombat = true, hideActionBar1Mouseover = true, hideActionBar1Always = true,
                        hideAB2InCombat = true, hideAB2Mouseover = true, hideAB2Always = true,
                        hideAB3InCombat = true, hideAB3Mouseover = true, hideAB3Always = true,
                        hideAB4InCombat = true, hideAB4Mouseover = true, hideAB4Always = true,
                        hideAB5InCombat = true, hideAB5Mouseover = true, hideAB5Always = true,
                        hideAB6InCombat = true, hideAB6Mouseover = true, hideAB6Always = true,
                        hideAB7InCombat = true, hideAB7Mouseover = true, hideAB7Always = true,
                        hideAB8InCombat = true, hideAB8Mouseover = true, hideAB8Always = true,
                        hideStanceBarInCombat = true, hideStanceBarMouseover = true, hideStanceBarAlways = true,
                        hidePetBarInCombat = true, hidePetBarMouseover = true, hidePetBarAlways = true,
                        fadeMicroMenu = true, hideActionBarBorders = true, fadeObjectiveTracker = true, fadeBagBar = true, betterItemLevel = true, showEquipmentDetails = true,
                        chatClassColorNames = true, chatTimestamps = true, chatCopyButton = true, chatUrlDetection = true, chatBackground = true, chatHideButtons = true, chatFadeToggle = true, chatEditBoxStyled = true, chatTabFlash = true,
                        skyridingEnabled = true, skyridingHideCDM = true, skyridingVigorBar = true, skyridingSpeedDisplay = true, skyridingSpeedBar = true, skyridingCooldowns = true, skyridingCentered = true,
                        autoRepair = true, showTooltipIDs = true, compactMinimapIcons = true, enhancedTooltip = true,
                        autoQuest = true, autoQuestExcludeDaily = true, autoQuestExcludeWeekly = true, autoQuestExcludeTrivial = true, autoQuestExcludeCompleted = true,
                        autoSellJunk = true, autoFillDelete = true, quickRoleSignup = true,
                        combatTimerEnabled = true, combatTimerCentered = true, crTimerEnabled = true, crTimerMode = "combat",
                        crTimerCentered = true, combatStatusEnabled = true, combatStatusCentered = true,
                        useCastbar = true, useFocusCastbar = true,
                        castbarCentered = true, castbarUseClassColor = true,
                        castbarShowIcon = true, castbarShowTime = true, castbarShowSpellName = true,
                        focusCastbarCentered = true,
                        focusCastbarShowIcon = true, focusCastbarShowTime = true, focusCastbarShowSpellName = true, focusCastbarShowTicks = true,
                        enablePlayerDebuffs = true,
                        ufClassColor = true, ufUseCustomTextures = true, ufUseCustomNameColor = true, ufDisableGlows = true, ufDisableCombatText = true,
                        disableTargetBuffs = true, hideEliteTexture = true, useCustomBorderColor = true,
                        ufBigHBPlayerEnabled = true, ufBigHBTargetEnabled = true, ufBigHBFocusEnabled = true,
                        ufBigHBHidePlayerName = true, ufBigHBHideTargetName = true, ufBigHBHideFocusName = true, ufBigHBHideRealm = true,
                        ufBigHBPlayerAbsorbStripes = true, ufBigHBTargetAbsorbStripes = true, ufBigHBFocusAbsorbStripes = true,
                        useBiggerPlayerHealthframe = true, useBiggerPlayerHealthframeClassColor = true,
                        useBiggerPlayerHealthframeDisableGlows = true, useBiggerPlayerHealthframeDisableCombatText = true,
                      }
                      if boolKeys[k] then
                        profile[k] = (num == 1)
                      else
                        profile[k] = num
                      end
                    else
                      profile[k] = num
                    end
                  end
                end
                local renamedKeys = {
                  useBiggerPlayerHealthframeClassColor = "ufClassColor",
                  useBiggerPlayerHealthframeTexture = "ufHealthTexture",
                  useBiggerPlayerHealthframeDisableGlows = "ufDisableGlows",
                  useBiggerPlayerHealthframeDisableCombatText = "ufDisableCombatText",
                }
                for oldK, newK in pairs(renamedKeys) do
                  if profile[oldK] ~= nil and profile[newK] == nil then
                    profile[newK] = profile[oldK]
                  end
                  profile[oldK] = nil
                end
                local count = profile.customBarsCount or 0
                profile.customBarEnabled = (count >= 1)
                profile.customBar2Enabled = (count >= 2)
                profile.customBar3Enabled = (count >= 3)
                if addonTable.profileText then addonTable.profileText:SetText(profileName) end
                if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
                UpdateAllControls()
                C_Timer.After(0.1, function()
                  if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end
                  if addonTable.UpdatePRB then addonTable.UpdatePRB() end
                  if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end
                end)
                CreateIcons()
                if addonTable.CreateCustomBarIcons then addonTable.CreateCustomBarIcons() end
                if addonTable.CreateCustomBar2Icons then addonTable.CreateCustomBar2Icons() end
                if addonTable.CreateCustomBar3Icons then addonTable.CreateCustomBar3Icons() end
                if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
                if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
                print("|cff00ff00CCM:|r Imported settings to new profile: " .. profileName)
                ShowReloadPrompt("Profile '" .. profileName .. "' imported successfully.\n\nA UI reload is recommended for all changes to take effect. Reload now?", "Reload", "Later")
              end
            end
          else
            print("|cffff6666CCM:|r Invalid import string! Must start with CCM: or CCM2:")
          end
          addonTable.exportImportPopup:Hide()
        end
        addonTable.exportImportOkBtn:SetScript("OnClick", DoImport)
        addonTable.importExportBox:SetScript("OnEnterPressed", function()
          DoImport()
        end)
        if addonTable.importProfileNameBox then
          addonTable.importProfileNameBox:SetScript("OnEnterPressed", function(s)
            s:ClearFocus()
            DoImport()
          end)
        end
        addonTable.exportImportPopup:Show()
        addonTable.importProfileNameBox:SetFocus()
      end
    end)
  end
  if addonTable.exportBtn then
    addonTable.exportBtn:SetScript("OnClick", function()
      if addonTable.exportImportPopup then
        addonTable.exportImportTitle:SetText("Export Profile Settings")
        addonTable.importExportBox:SetText("")
        addonTable.exportCheckboxContainer:Show()
        addonTable.generateExportBtn:Show()
        addonTable.exportImportOkBtn:Hide()
        if addonTable.importContainer then addonTable.importContainer:Hide() end
        addonTable.exportImportPopup:SetSize(500, 360)
        addonTable.exportImportScrollFrame:SetPoint("TOPLEFT", addonTable.exportImportPopup, "TOPLEFT", 15, -205)
        addonTable.exportImportScrollFrame:SetSize(420, 130)
        addonTable.importExportBox:SetWidth(400)
        if addonTable.editBoxBg then
          addonTable.editBoxBg:SetPoint("TOPLEFT", addonTable.exportImportScrollFrame, "TOPLEFT", -5, 5)
          addonTable.editBoxBg:SetPoint("BOTTOMRIGHT", addonTable.exportImportScrollFrame, "BOTTOMRIGHT", 15, -5)
        end
        addonTable.importExportBox:SetScript("OnTextChanged", nil)
        for _, cb in pairs(addonTable.exportCategories) do
          cb:SetChecked(true)
        end
        addonTable.generateExportBtn:SetScript("OnClick", function()
          local profile = GetProfile()
          if profile then
            local str = "CCM2:" .. (CooldownCursorManagerDB.currentProfile or "Default") .. ":"
            local selectedCategories = {general = true, qol = true}
            for cat, cb in pairs(addonTable.exportCategories) do
              if cb:GetChecked() then
                selectedCategories[cat] = true
              end
            end
            for k, v in pairs(profile) do
              local cat = keyToCategory[k]
              if cat and selectedCategories[cat] then
                if type(v) == "boolean" then
                  str = str .. k .. "=" .. (v and "1" or "0") .. ";"
                elseif type(v) == "number" then
                  str = str .. k .. "=" .. v .. ";"
                elseif type(v) == "string" then
                  str = str .. k .. "=\"" .. v .. "\";"
                end
              end
            end
            addonTable.importExportBox:SetText(str)
            addonTable.importExportBox:HighlightText()
            addonTable.importExportBox:SetFocus()
          end
        end)
        addonTable.exportImportPopup:Show()
      end
    end)
  end
  C_Timer.After(0.2, UpdateSkinCheckboxes)
  if addonTable.prbCB then
    addonTable.prbCB.customOnClick = function(s)
      local p = GetProfile(); if p then p.usePersonalResourceBar = s:GetChecked()
      if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
      if addonTable.UpdatePRB then addonTable.UpdatePRB() end
      if s:GetChecked() and addonTable.SwitchToTab then addonTable.SwitchToTab(7) end
      if s:GetChecked() then C_Timer.After(0.1, function() if addonTable.LoadPRBValues then addonTable.LoadPRBValues() end; if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end) end end
    end
  end
  local prb = addonTable.prb
  if prb then
    local function UpdatePRB() if addonTable.UpdatePRB then C_Timer.After(0, addonTable.UpdatePRB) end end
    local function num(v, d) return tonumber(v) or d end
    local function LoadPRBValues()
      local p = GetProfile(); if not p then return end
      if prb.centeredCB then prb.centeredCB:SetChecked(p.prbCentered == true) end
      if prb.showModeDD then prb.showModeDD:SetValue(p.prbShowMode or "always") end
      if prb.anchorDD then prb.anchorDD:SetValue(p.prbClampAnchor or "top") end
      if prb.autoWidthDD then prb.autoWidthDD:SetValue(p.prbAutoWidthSource or "off") end
      local isAuto = (p.prbAutoWidthSource or "off") ~= "off"
      local isCentered = p.prbCentered == true
      if prb.widthSlider then prb.widthSlider:SetValue(num(p.prbWidth, 220)); prb.widthSlider.valueText:SetText(math.floor(num(p.prbWidth, 220))); prb.widthSlider:SetEnabled(not isAuto); if prb.widthSlider.label then prb.widthSlider.label:SetTextColor(isAuto and 0.5 or 1, isAuto and 0.5 or 1, isAuto and 0.5 or 1) end end
      if prb.xSlider then prb.xSlider:SetValue(num(p.prbX, 0)); prb.xSlider.valueText:SetText(math.floor(num(p.prbX, 0))); prb.xSlider:SetEnabled(not isCentered); if prb.xSlider.label then prb.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1) end end
      if prb.ySlider then local yVal = num(p.prbY, -180); prb.ySlider:SetValue(yVal); prb.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if prb.spacingSlider then prb.spacingSlider:SetValue(num(p.prbSpacing, 0)); prb.spacingSlider.valueText:SetText(math.floor(num(p.prbSpacing, 0))) end
      if prb.borderSlider then prb.borderSlider:SetValue(num(p.prbBorderSize, 1)); prb.borderSlider.valueText:SetText(math.floor(num(p.prbBorderSize, 1))) end
      if prb.bgColorSwatch then prb.bgColorSwatch:SetBackdropColor(p.prbBgColorR or 0.1, p.prbBgColorG or 0.1, p.prbBgColorB or 0.1, 1) end
      if prb.clampBarsCB then prb.clampBarsCB:SetChecked(p.prbClampBars == true) end
      if prb.showHealthCB then prb.showHealthCB:SetChecked(p.prbShowHealth == true) end
      if prb.showPowerCB then prb.showPowerCB:SetChecked(p.prbShowPower == true) end
      if prb.healthHeightSlider then prb.healthHeightSlider:SetValue(num(p.prbHealthHeight, 18)); prb.healthHeightSlider.valueText:SetText(math.floor(num(p.prbHealthHeight, 18))) end
      if prb.healthYOffsetSlider then prb.healthYOffsetSlider:SetValue(num(p.prbHealthYOffset, 0)); prb.healthYOffsetSlider.valueText:SetText(math.floor(num(p.prbHealthYOffset, 0))) end
      if prb.healthTextureDD then prb.healthTextureDD:SetValue(p.prbHealthTexture or "solid") end
      if prb.healAbsorbCB then prb.healAbsorbCB:SetChecked((p.prbHealAbsorb or "on") ~= "off") end
      if prb.absorbModeDD then
        local dmgMode = p.prbDmgAbsorb or "bar"
        prb.absorbModeDD:SetValue((dmgMode == "bar" or dmgMode == "bar_glow") and "shield" or "off")
      end
      if prb.absorbStripesCB then prb.absorbStripesCB:SetChecked(p.prbAbsorbStripes == true) end
      if prb.healPredCB then prb.healPredCB:SetChecked((p.prbHealPred or "on") ~= "off") end
      if prb.overAbsorbBarCB then prb.overAbsorbBarCB:SetChecked(p.prbOverAbsorbBar ~= false) end
      if prb.healthTextDD then prb.healthTextDD:SetValue(p.prbHealthTextMode or "hidden") end
      if prb.healthTextScaleSlider then prb.healthTextScaleSlider:SetValue(num(p.prbHealthTextScale, 1)); prb.healthTextScaleSlider.valueText:SetText(string.format("%.1f", num(p.prbHealthTextScale, 1))) end
      if prb.healthTextYSlider then prb.healthTextYSlider:SetValue(num(p.prbHealthTextY, 0)); prb.healthTextYSlider.valueText:SetText(math.floor(num(p.prbHealthTextY, 0))) end
      if prb.useClassColorCB then prb.useClassColorCB:SetChecked(p.prbUseClassColor == true) end
      local useClassColor = p.prbUseClassColor == true
      if prb.healthColorBtn then prb.healthColorBtn:SetEnabled(not useClassColor); prb.healthColorBtn:SetAlpha(useClassColor and 0.5 or 1) end
      if prb.healthColorSwatch then prb.healthColorSwatch:SetBackdropColor(p.prbHealthColorR or 0, p.prbHealthColorG or 0.8, p.prbHealthColorB or 0, 1); prb.healthColorSwatch:SetAlpha(useClassColor and 0.5 or 1) end
      if prb.healthTextColorSwatch then prb.healthTextColorSwatch:SetBackdropColor(p.prbHealthTextColorR or 1, p.prbHealthTextColorG or 1, p.prbHealthTextColorB or 1, 1) end
      if prb.powerHeightSlider then prb.powerHeightSlider:SetValue(num(p.prbPowerHeight, 8)); prb.powerHeightSlider.valueText:SetText(math.floor(num(p.prbPowerHeight, 8))) end
      if prb.powerYOffsetSlider then prb.powerYOffsetSlider:SetValue(num(p.prbPowerYOffset, 0)); prb.powerYOffsetSlider.valueText:SetText(math.floor(num(p.prbPowerYOffset, 0))) end
      if prb.powerTextureDD then prb.powerTextureDD:SetValue(p.prbPowerTexture or "solid") end
      if prb.powerTextDD then prb.powerTextDD:SetValue(p.prbPowerTextMode or "hidden") end
      if prb.powerTextScaleSlider then prb.powerTextScaleSlider:SetValue(num(p.prbPowerTextScale, 1)); prb.powerTextScaleSlider.valueText:SetText(string.format("%.1f", num(p.prbPowerTextScale, 1))) end
      if prb.powerTextYSlider then prb.powerTextYSlider:SetValue(num(p.prbPowerTextY, 0)); prb.powerTextYSlider.valueText:SetText(math.floor(num(p.prbPowerTextY, 0))) end
      if prb.usePowerTypeColorCB then prb.usePowerTypeColorCB:SetChecked(p.prbUsePowerTypeColor ~= false) end
      local usePowerTypeColor = p.prbUsePowerTypeColor ~= false
      if prb.powerColorBtn then prb.powerColorBtn:SetEnabled(not usePowerTypeColor); prb.powerColorBtn:SetAlpha(usePowerTypeColor and 0.5 or 1) end
      if prb.powerColorSwatch then prb.powerColorSwatch:SetBackdropColor(p.prbPowerColorR or 0, p.prbPowerColorG or 0.5, p.prbPowerColorB or 1, 1); prb.powerColorSwatch:SetAlpha(usePowerTypeColor and 0.5 or 1) end
      if prb.powerTextColorSwatch then prb.powerTextColorSwatch:SetBackdropColor(p.prbPowerTextColorR or 1, p.prbPowerTextColorG or 1, p.prbPowerTextColorB or 1, 1) end
      if prb.showManaBarCB then prb.showManaBarCB:SetChecked(p.prbShowManaBar == true) end
      if prb.manaHeightSlider then prb.manaHeightSlider:SetValue(num(p.prbManaHeight, 6)); prb.manaHeightSlider.valueText:SetText(math.floor(num(p.prbManaHeight, 6))) end
      if prb.manaYOffsetSlider then prb.manaYOffsetSlider:SetValue(num(p.prbManaYOffset, 0)); prb.manaYOffsetSlider.valueText:SetText(math.floor(num(p.prbManaYOffset, 0))) end
      if prb.manaTextureDD then prb.manaTextureDD:SetValue(p.prbManaTexture or "solid") end
      if prb.manaTextDD then prb.manaTextDD:SetValue(p.prbManaTextMode or "hidden") end
      if prb.manaTextScaleSlider then prb.manaTextScaleSlider:SetValue(num(p.prbManaTextScale, 1)); prb.manaTextScaleSlider.valueText:SetText(string.format("%.1f", num(p.prbManaTextScale, 1))) end
      if prb.manaTextYSlider then prb.manaTextYSlider:SetValue(num(p.prbManaTextY, 0)); prb.manaTextYSlider.valueText:SetText(math.floor(num(p.prbManaTextY, 0))) end
      if prb.manaColorSwatch then prb.manaColorSwatch:SetBackdropColor(p.prbManaColorR or 0, p.prbManaColorG or 0.4, p.prbManaColorB or 0.9, 1) end
      if prb.manaTextColorSwatch then prb.manaTextColorSwatch:SetBackdropColor(p.prbManaTextColorR or 1, p.prbManaTextColorG or 1, p.prbManaTextColorB or 1, 1) end
      if prb.showClassPowerCB then prb.showClassPowerCB:SetChecked(p.prbShowClassPower == true) end
      if prb.classPowerHeightSlider then prb.classPowerHeightSlider:SetValue(num(p.prbClassPowerHeight, 6)); prb.classPowerHeightSlider.valueText:SetText(math.floor(num(p.prbClassPowerHeight, 6))) end
      if prb.classPowerYSlider then prb.classPowerYSlider:SetValue(num(p.prbClassPowerY, 20)); prb.classPowerYSlider.valueText:SetText(math.floor(num(p.prbClassPowerY, 20))) end
      if prb.classPowerColorSwatch then prb.classPowerColorSwatch:SetBackdropColor(p.prbClassPowerColorR or 1, p.prbClassPowerColorG or 0.82, p.prbClassPowerColorB or 0, 1) end
    end
    addonTable.LoadPRBValues = LoadPRBValues
    C_Timer.After(0.3, LoadPRBValues)
    C_Timer.After(0.35, function() if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end)
    local function UpdatePRBAndHighlight() UpdatePRB(); if addonTable.GetGUIOpen and addonTable.GetGUIOpen() and addonTable.HighlightCustomBar then addonTable.HighlightCustomBar(7) end end
    if prb.centeredCB then prb.centeredCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbCentered = s:GetChecked(); UpdatePRBAndHighlight(); local isCentered = s:GetChecked(); if prb.xSlider then prb.xSlider:SetEnabled(not isCentered); if prb.xSlider.label then prb.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1) end end end end end
    if prb.showModeDD then prb.showModeDD.onSelect = function(v) local p = GetProfile(); if p then p.prbShowMode = v; UpdatePRBAndHighlight() end end end
    if prb.anchorDD then prb.anchorDD.onSelect = function(v) local p = GetProfile(); if p then p.prbClampAnchor = v; UpdatePRBAndHighlight() end end end
    if prb.widthSlider then prb.widthSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbWidth = r; UpdatePRBAndHighlight() end end) end
    if prb.autoWidthDD then prb.autoWidthDD.onSelect = function(v) local p = GetProfile(); if p then p.prbAutoWidthSource = v; UpdatePRBAndHighlight(); local isAuto = (v ~= "off"); if prb.widthSlider then prb.widthSlider:SetEnabled(not isAuto); if prb.widthSlider.label then prb.widthSlider.label:SetTextColor(isAuto and 0.5 or 1, isAuto and 0.5 or 1, isAuto and 0.5 or 1) end end end end end
    if prb.xSlider then prb.xSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.prbX = r; UpdatePRBAndHighlight() end end) end
    if prb.ySlider then prb.ySlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 2 + 0.5) / 2; s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end; local p = GetProfile(); if p then p.prbY = r; UpdatePRBAndHighlight() end end) end
    if prb.spacingSlider then prb.spacingSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbSpacing = r; UpdatePRBAndHighlight() end end) end
    if prb.borderSlider then prb.borderSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbBorderSize = r; UpdatePRBAndHighlight() end end) end
    if prb.bgColorBtn then prb.bgColorBtn:SetScript("OnClick", function()
      local p = GetProfile(); if not p then return end
      local r, g, b = p.prbBgColorR or 0.1, p.prbBgColorG or 0.1, p.prbBgColorB or 0.1
      local a = (p.prbBackgroundAlpha or 80) / 100
      local function OnChange()
        local nR, nG, nB = ColorPickerFrame:GetColorRGB()
        local nA = ColorPickerFrame:GetColorAlpha() or 1
        p.prbBgColorR, p.prbBgColorG, p.prbBgColorB = nR, nG, nB
        p.prbBackgroundAlpha = math.floor(nA * 100)
        prb.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1)
        UpdatePRB()
      end
      local function OnCancel(prev)
        p.prbBgColorR, p.prbBgColorG, p.prbBgColorB = prev.r, prev.g, prev.b
        p.prbBackgroundAlpha = math.floor(prev.a * 100)
        prb.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
        UpdatePRB()
      end
      ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnChange, opacityFunc = OnChange, cancelFunc = OnCancel})
    end) end
    if prb.showHealthCB then prb.showHealthCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowHealth = s:GetChecked(); UpdatePRBAndHighlight(); if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end end end
    if prb.showPowerCB then prb.showPowerCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowPower = s:GetChecked(); UpdatePRBAndHighlight(); if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end end end
    if prb.healthHeightSlider then prb.healthHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbHealthHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.healthYOffsetSlider then prb.healthYOffsetSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbHealthYOffset = r; UpdatePRBAndHighlight() end end) end
    if prb.healthTextureDD then prb.healthTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.prbHealthTexture = v; UpdatePRBAndHighlight() end end end
    if prb.healAbsorbCB then prb.healAbsorbCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbHealAbsorb = s:GetChecked() and "on" or "off"; UpdatePRBAndHighlight() end end end
    if prb.absorbModeDD then prb.absorbModeDD.onSelect = function(v)
      local p = GetProfile(); if not p then return end
      p.prbDmgAbsorb = (v == "shield") and "bar" or "off"
      UpdatePRBAndHighlight()
      if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end
    end end
    if prb.absorbStripesCB then prb.absorbStripesCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbAbsorbStripes = s:GetChecked() and true or false; UpdatePRBAndHighlight() end end end
    if prb.healPredCB then prb.healPredCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbHealPred = s:GetChecked() and "on" or "off"; UpdatePRBAndHighlight() end end end
    if prb.overAbsorbBarCB then prb.overAbsorbBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbOverAbsorbBar = s:GetChecked(); UpdatePRBAndHighlight() end end end
    if prb.healthTextDD then prb.healthTextDD.onSelect = function(v) local p = GetProfile(); if p then p.prbHealthTextMode = v; UpdatePRBAndHighlight() end end end
    if prb.healthTextScaleSlider then prb.healthTextScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.prbHealthTextScale = r; UpdatePRBAndHighlight() end end) end
    if prb.healthTextYSlider then prb.healthTextYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbHealthTextY = r; UpdatePRBAndHighlight() end end) end
    if prb.useClassColorCB then prb.useClassColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbUseClassColor = s:GetChecked(); local uc = s:GetChecked(); if prb.healthColorBtn then prb.healthColorBtn:SetEnabled(not uc); prb.healthColorBtn:SetAlpha(uc and 0.5 or 1) end; if prb.healthColorSwatch then prb.healthColorSwatch:SetAlpha(uc and 0.5 or 1) end; UpdatePRBAndHighlight() end end end
    if prb.powerHeightSlider then prb.powerHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbPowerHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.powerYOffsetSlider then prb.powerYOffsetSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbPowerYOffset = r; UpdatePRBAndHighlight() end end) end
    if prb.powerTextureDD then prb.powerTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.prbPowerTexture = v; UpdatePRBAndHighlight() end end end
    if prb.powerTextDD then prb.powerTextDD.onSelect = function(v) local p = GetProfile(); if p then p.prbPowerTextMode = v; UpdatePRBAndHighlight() end end end
    if prb.powerTextScaleSlider then prb.powerTextScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.prbPowerTextScale = r; UpdatePRBAndHighlight() end end) end
    if prb.powerTextYSlider then prb.powerTextYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbPowerTextY = r; UpdatePRBAndHighlight() end end) end
    if prb.usePowerTypeColorCB then prb.usePowerTypeColorCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbUsePowerTypeColor = s:GetChecked(); local up = s:GetChecked(); if prb.powerColorBtn then prb.powerColorBtn:SetEnabled(not up); prb.powerColorBtn:SetAlpha(up and 0.5 or 1) end; if prb.powerColorSwatch then prb.powerColorSwatch:SetAlpha(up and 0.5 or 1) end; UpdatePRBAndHighlight() end end end
    if prb.clampBarsCB then prb.clampBarsCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbClampBars = s:GetChecked(); UpdatePRBAndHighlight() end end end
    if prb.showManaBarCB then prb.showManaBarCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowManaBar = s:GetChecked(); UpdatePRBAndHighlight() end end end
    if prb.manaHeightSlider then prb.manaHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbManaHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.manaYOffsetSlider then prb.manaYOffsetSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbManaYOffset = r; UpdatePRBAndHighlight() end end) end
    if prb.manaTextureDD then prb.manaTextureDD.onSelect = function(v) local p = GetProfile(); if p then p.prbManaTexture = v; UpdatePRBAndHighlight() end end end
    if prb.manaTextDD then prb.manaTextDD.onSelect = function(v) local p = GetProfile(); if p then p.prbManaTextMode = v; UpdatePRBAndHighlight() end end end
    if prb.manaTextScaleSlider then prb.manaTextScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.prbManaTextScale = r; UpdatePRBAndHighlight() end end) end
    if prb.manaTextYSlider then prb.manaTextYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbManaTextY = r; UpdatePRBAndHighlight() end end) end
    if prb.showClassPowerCB then prb.showClassPowerCB.customOnClick = function(s) local p = GetProfile(); if p then p.prbShowClassPower = s:GetChecked(); UpdatePRBAndHighlight(); if addonTable.UpdatePRBSectionVisibility then addonTable.UpdatePRBSectionVisibility() end end end end
    if prb.classPowerHeightSlider then prb.classPowerHeightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.prbClassPowerHeight = r; UpdatePRBAndHighlight() end end) end
    if prb.classPowerYSlider then prb.classPowerYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.prbClassPowerY = r; UpdatePRBAndHighlight() end end) end
    local function SetupColorBtn(btn, swatch, rKey, gKey, bKey)
      if btn then btn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p[rKey] or 1, p[gKey] or 1, p[bKey] or 1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p[rKey], p[gKey], p[bKey] = nR, nG, nB; swatch:SetBackdropColor(nR, nG, nB, 1); UpdatePRB() end
        local function OnCancel(prev) p[rKey], p[gKey], p[bKey] = prev.r, prev.g, prev.b; swatch:SetBackdropColor(prev.r, prev.g, prev.b, 1); UpdatePRB() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end) end
    end
    SetupColorBtn(prb.healthColorBtn, prb.healthColorSwatch, "prbHealthColorR", "prbHealthColorG", "prbHealthColorB")
    SetupColorBtn(prb.healthTextColorBtn, prb.healthTextColorSwatch, "prbHealthTextColorR", "prbHealthTextColorG", "prbHealthTextColorB")
    SetupColorBtn(prb.powerColorBtn, prb.powerColorSwatch, "prbPowerColorR", "prbPowerColorG", "prbPowerColorB")
    SetupColorBtn(prb.powerTextColorBtn, prb.powerTextColorSwatch, "prbPowerTextColorR", "prbPowerTextColorG", "prbPowerTextColorB")
    SetupColorBtn(prb.manaColorBtn, prb.manaColorSwatch, "prbManaColorR", "prbManaColorG", "prbManaColorB")
    SetupColorBtn(prb.manaTextColorBtn, prb.manaTextColorSwatch, "prbManaTextColorR", "prbManaTextColorG", "prbManaTextColorB")
    SetupColorBtn(prb.classPowerColorBtn, prb.classPowerColorSwatch, "prbClassPowerColorR", "prbClassPowerColorG", "prbClassPowerColorB")
  end
  if addonTable.castbarCB then
    addonTable.castbarCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        local wasEnabled = p.useCastbar
        p.useCastbar = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          if addonTable.SetBlizzardCastbarVisibility then
            addonTable.SetBlizzardCastbarVisibility(false)
          end
          if addonTable.SwitchToTab then addonTable.SwitchToTab(8) end
          C_Timer.After(0.1, function()
            if addonTable.LoadCastbarValues then addonTable.LoadCastbarValues() end
          end)
          if not wasEnabled then
            ShowReloadPrompt("Enabling the custom castbar requires a reload for full effect.", "Reload Now", "Later")
          end
        else
          if addonTable.StopCastbarTicker then addonTable.StopCastbarTicker() end
          if addonTable.StopCastbarPreview then addonTable.StopCastbarPreview() end
          if wasEnabled then
            ShowReloadPrompt("Reload UI recommended to properly restore the default castbar.\n\nThis ensures compatibility with other castbar addons.", "Reload Now", "Later")
          end
        end
      end
    end
  end
  if addonTable.focusCastbarCB then
    addonTable.focusCastbarCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.useFocusCastbar = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          if addonTable.SetBlizzardFocusCastbarVisibility then addonTable.SetBlizzardFocusCastbarVisibility(false) end
          if addonTable.SetupFocusCastbarEvents then addonTable.SetupFocusCastbarEvents() end
          if addonTable.SwitchToTab then addonTable.SwitchToTab(9) end
          C_Timer.After(0.1, function()
            if addonTable.LoadFocusCastbarValues then addonTable.LoadFocusCastbarValues() end
          end)
        else
          if addonTable.StopFocusCastbarTicker then addonTable.StopFocusCastbarTicker() end
          if addonTable.StopFocusCastbarPreview then addonTable.StopFocusCastbarPreview() end
          if addonTable.SetBlizzardFocusCastbarVisibility then addonTable.SetBlizzardFocusCastbarVisibility(true) end
        end
      end
    end
  end
  if addonTable.playerDebuffsCB then
    addonTable.playerDebuffsCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.enablePlayerDebuffs = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if s:GetChecked() then
          if addonTable.SwitchToTab then addonTable.SwitchToTab(10) end
          C_Timer.After(0.1, function()
            if addonTable.LoadPlayerDebuffsValues then addonTable.LoadPlayerDebuffsValues() end
            if addonTable.ApplyPlayerDebuffsSkinning then addonTable.ApplyPlayerDebuffsSkinning() end
          end)
        else
          if addonTable.RestorePlayerDebuffs then addonTable.RestorePlayerDebuffs() end
        end
      end
    end
  end
  if addonTable.unitFrameCustomizationCB then
    addonTable.unitFrameCustomizationCB.customOnClick = function(s)
      local p = GetProfile(); if p then
        p.enableUnitFrameCustomization = s:GetChecked()
        if addonTable.UpdateTabVisibility then addonTable.UpdateTabVisibility() end
        if addonTable.UpdateAllControls then addonTable.UpdateAllControls() end
        if s:GetChecked() and addonTable.SwitchToTab then
          addonTable.SwitchToTab(addonTable.TAB_UF or 11)
        end
        ShowReloadPrompt("Unit Frame Customization changed. A UI reload is recommended.", "Reload", "Later")
      end
    end
  end
  local cbar = addonTable.castbar
  if cbar then
    local function UpdateCastbar()
      if addonTable.UpdateCastbar then C_Timer.After(0, addonTable.UpdateCastbar) end
    end
    local function num(v, d) return tonumber(v) or d end
    local function UpdateCenteredState()
      local p = GetProfile()
      local isCentered = p and p.castbarCentered
      if cbar.xSlider then
        cbar.xSlider:SetEnabled(not isCentered)
        if cbar.xSlider.label then
          cbar.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1)
        end
        if isCentered then
          cbar.xSlider:SetValue(0)
          cbar.xSlider.valueText:SetText("0")
        end
      end
    end
    local function UpdateAutoWidthState()
      local p = GetProfile()
      local isAuto = p and (p.castbarAutoWidthSource or "off") ~= "off"
      if cbar.widthSlider then
        cbar.widthSlider:SetEnabled(not isAuto)
        if cbar.widthSlider.label then
          cbar.widthSlider.label:SetTextColor(isAuto and 0.5 or 1, isAuto and 0.5 or 1, isAuto and 0.5 or 1)
        end
      end
    end
    local function LoadCastbarValues()
      local p = GetProfile(); if not p then return end
      if cbar.centeredCB then cbar.centeredCB:SetChecked(p.castbarCentered == true) end
      if cbar.autoWidthDD then cbar.autoWidthDD:SetValue(p.castbarAutoWidthSource or "off") end
      if cbar.widthSlider then cbar.widthSlider:SetValue(num(p.castbarWidth, 250)); cbar.widthSlider.valueText:SetText(math.floor(num(p.castbarWidth, 250))) end
      if cbar.heightSlider then cbar.heightSlider:SetValue(num(p.castbarHeight, 20)); cbar.heightSlider.valueText:SetText(math.floor(num(p.castbarHeight, 20))) end
      if cbar.xSlider then cbar.xSlider:SetValue(num(p.castbarX, 0)); cbar.xSlider.valueText:SetText(math.floor(num(p.castbarX, 0))) end
      if cbar.ySlider then local yVal = num(p.castbarY, -250); cbar.ySlider:SetValue(yVal); cbar.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if cbar.bgAlphaSlider then cbar.bgAlphaSlider:SetValue(num(p.castbarBgAlpha, 70)); cbar.bgAlphaSlider.valueText:SetText(math.floor(num(p.castbarBgAlpha, 70))) end
      if cbar.bgColorSwatch then cbar.bgColorSwatch:SetBackdropColor(p.castbarBgColorR or 0.1, p.castbarBgColorG or 0.1, p.castbarBgColorB or 0.1, 1) end
      if cbar.borderSlider then cbar.borderSlider:SetValue(num(p.castbarBorderSize, 1)); cbar.borderSlider.valueText:SetText(math.floor(num(p.castbarBorderSize, 1))) end
      if cbar.textureDD then cbar.textureDD:SetValue(p.castbarTexture or "solid") end
      if cbar.useClassColorCB then cbar.useClassColorCB:SetChecked(p.castbarUseClassColor ~= false) end
      local useClassColor = p.castbarUseClassColor ~= false
      if cbar.barColorBtn then cbar.barColorBtn:SetEnabled(not useClassColor); cbar.barColorBtn:SetAlpha(useClassColor and 0.5 or 1) end
      if cbar.barColorSwatch then cbar.barColorSwatch:SetBackdropColor(p.castbarColorR or 1, p.castbarColorG or 0.7, p.castbarColorB or 0, 1); cbar.barColorSwatch:SetAlpha(useClassColor and 0.5 or 1) end
      if cbar.showIconCB then cbar.showIconCB:SetChecked(p.castbarShowIcon ~= false) end
      if cbar.showSpellNameCB then cbar.showSpellNameCB:SetChecked(p.castbarShowSpellName ~= false) end
      if cbar.showTimeCB then cbar.showTimeCB:SetChecked(p.castbarShowTime ~= false) end
      if cbar.showTicksCB then cbar.showTicksCB:SetChecked(p.castbarShowTicks ~= false) end
      if cbar.spellNameScaleSlider then cbar.spellNameScaleSlider:SetValue(num(p.castbarSpellNameScale, 1)); cbar.spellNameScaleSlider.valueText:SetText(string.format("%.1f", num(p.castbarSpellNameScale, 1))) end
      if cbar.timeScaleSlider then cbar.timeScaleSlider:SetValue(num(p.castbarTimeScale, 1)); cbar.timeScaleSlider.valueText:SetText(string.format("%.1f", num(p.castbarTimeScale, 1))) end
      if cbar.spellNameXSlider then cbar.spellNameXSlider:SetValue(num(p.castbarSpellNameXOffset, 0)); cbar.spellNameXSlider.valueText:SetText(math.floor(num(p.castbarSpellNameXOffset, 0))) end
      if cbar.spellNameYSlider then cbar.spellNameYSlider:SetValue(num(p.castbarSpellNameYOffset, 0)); cbar.spellNameYSlider.valueText:SetText(math.floor(num(p.castbarSpellNameYOffset, 0))) end
      if cbar.timeXSlider then cbar.timeXSlider:SetValue(num(p.castbarTimeXOffset, 0)); cbar.timeXSlider.valueText:SetText(math.floor(num(p.castbarTimeXOffset, 0))) end
      if cbar.timeYSlider then cbar.timeYSlider:SetValue(num(p.castbarTimeYOffset, 0)); cbar.timeYSlider.valueText:SetText(math.floor(num(p.castbarTimeYOffset, 0))) end
      if cbar.timePrecisionDD then cbar.timePrecisionDD:SetValue(p.castbarTimePrecision or "1") end
      if cbar.timeDirectionDD then cbar.timeDirectionDD:SetValue(p.castbarTimeDirection or "remaining") end
      if cbar.textColorSwatch then cbar.textColorSwatch:SetBackdropColor(p.castbarTextColorR or 1, p.castbarTextColorG or 1, p.castbarTextColorB or 1, 1) end
      UpdateCenteredState()
      UpdateAutoWidthState()
    end
    addonTable.LoadCastbarValues = LoadCastbarValues
    C_Timer.After(0.3, LoadCastbarValues)
    addonTable.UpdateCastbarSliders = function(x, y)
      if cbar.xSlider then cbar.xSlider:SetValue(x); cbar.xSlider.valueText:SetText(math.floor(x)) end
      if cbar.ySlider then cbar.ySlider:SetValue(y); cbar.ySlider.valueText:SetText(math.floor(y)) end
    end
    if cbar.autoWidthDD then
      cbar.autoWidthDD.onSelect = function(v)
        local p = GetProfile()
        if p then
          p.castbarAutoWidthSource = v
          UpdateAutoWidthState()
          UpdateCastbar()
        end
      end
    end
    if cbar.centeredCB then
      cbar.centeredCB.customOnClick = function(s)
        local p = GetProfile()
        if p then
          p.castbarCentered = s:GetChecked()
          if p.castbarCentered then
            p.castbarX = 0
          end
          UpdateCenteredState()
          UpdateCastbar()
        end
      end
    end
    if cbar.previewOnBtn then
      cbar.previewOnBtn:SetScript("OnClick", function()
        if addonTable.ShowCastbarPreview then
          addonTable.ShowCastbarPreview()
        end
        SetButtonHighlighted(cbar.previewOnBtn, true)
      end)
    end
    if cbar.previewOffBtn then
      cbar.previewOffBtn:SetScript("OnClick", function()
        if addonTable.StopCastbarPreview then
          addonTable.StopCastbarPreview()
        end
        SetButtonHighlighted(cbar.previewOnBtn, false)
      end)
    end
    if cbar.widthSlider then
      cbar.widthSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarWidth = r; UpdateCastbar() end
      end)
    end
    if cbar.heightSlider then
      cbar.heightSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarHeight = r; UpdateCastbar() end
      end)
    end
    if cbar.xSlider then
      cbar.xSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        if not s.valueText:HasFocus() then s.valueText:SetText(r) end
        local p = GetProfile(); if p then p.castbarX = r; UpdateCastbar() end
      end)
    end
    if cbar.ySlider then
      cbar.ySlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v * 2 + 0.5) / 2
        s._updating = true; s:SetValue(r); s._updating = false
        if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end
        local p = GetProfile(); if p then p.castbarY = r; UpdateCastbar() end
      end)
    end
    if cbar.bgAlphaSlider then
      cbar.bgAlphaSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarBgAlpha = r; UpdateCastbar() end
      end)
    end
    if cbar.bgColorBtn then
      cbar.bgColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.castbarBgColorR or 0.1, p.castbarBgColorG or 0.1, p.castbarBgColorB or 0.1
        local a = (p.castbarBgAlpha or 80) / 100
        local function OnChange()
          local nR, nG, nB = ColorPickerFrame:GetColorRGB()
          local nA = ColorPickerFrame:GetColorAlpha() or 1
          p.castbarBgColorR, p.castbarBgColorG, p.castbarBgColorB = nR, nG, nB
          p.castbarBgAlpha = math.floor(nA * 100)
          cbar.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1)
          if cbar.bgAlphaSlider then cbar.bgAlphaSlider:SetValue(p.castbarBgAlpha); cbar.bgAlphaSlider.valueText:SetText(p.castbarBgAlpha) end
          UpdateCastbar()
        end
        local function OnCancel(prev)
          p.castbarBgColorR, p.castbarBgColorG, p.castbarBgColorB = prev.r, prev.g, prev.b
          p.castbarBgAlpha = math.floor(a * 100)
          cbar.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
          if cbar.bgAlphaSlider then cbar.bgAlphaSlider:SetValue(p.castbarBgAlpha); cbar.bgAlphaSlider.valueText:SetText(p.castbarBgAlpha) end
          UpdateCastbar()
        end
        ShowColorPicker({r = r, g = g, b = b, opacity = a, hasOpacity = true, swatchFunc = OnChange, opacityFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if cbar.borderSlider then
      cbar.borderSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarBorderSize = r; UpdateCastbar() end
      end)
    end
    if cbar.textureDD then
      cbar.textureDD.onSelect = function(v)
        local p = GetProfile(); if p then p.castbarTexture = v; UpdateCastbar() end
      end
    end
    if cbar.useClassColorCB then
      cbar.useClassColorCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarUseClassColor = s:GetChecked(); local uc = s:GetChecked(); if cbar.barColorBtn then cbar.barColorBtn:SetEnabled(not uc); cbar.barColorBtn:SetAlpha(uc and 0.5 or 1) end; if cbar.barColorSwatch then cbar.barColorSwatch:SetAlpha(uc and 0.5 or 1) end; UpdateCastbar() end
      end
    end
    if cbar.barColorBtn then
      cbar.barColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.castbarColorR or 1, p.castbarColorG or 0.7, p.castbarColorB or 0
        local function OnChange()
          local nR, nG, nB = ColorPickerFrame:GetColorRGB()
          p.castbarColorR, p.castbarColorG, p.castbarColorB = nR, nG, nB
          cbar.barColorSwatch:SetBackdropColor(nR, nG, nB, 1)
          UpdateCastbar()
        end
        local function OnCancel(prev)
          p.castbarColorR, p.castbarColorG, p.castbarColorB = prev.r, prev.g, prev.b
          cbar.barColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
          UpdateCastbar()
        end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if cbar.showIconCB then
      cbar.showIconCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowIcon = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.showSpellNameCB then
      cbar.showSpellNameCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowSpellName = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.showTimeCB then
      cbar.showTimeCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowTime = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.showTicksCB then
      cbar.showTicksCB.customOnClick = function(s)
        local p = GetProfile(); if p then p.castbarShowTicks = s:GetChecked(); UpdateCastbar() end
      end
    end
    if cbar.spellNameScaleSlider then
      cbar.spellNameScaleSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v * 10 + 0.5) / 10
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(string.format("%.1f", r))
        local p = GetProfile(); if p then p.castbarSpellNameScale = r; UpdateCastbar() end
      end)
    end
    if cbar.timeScaleSlider then
      cbar.timeScaleSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v * 10 + 0.5) / 10
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(string.format("%.1f", r))
        local p = GetProfile(); if p then p.castbarTimeScale = r; UpdateCastbar() end
      end)
    end
    if cbar.spellNameXSlider then
      cbar.spellNameXSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarSpellNameXOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.spellNameYSlider then
      cbar.spellNameYSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarSpellNameYOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.timeXSlider then
      cbar.timeXSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarTimeXOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.timeYSlider then
      cbar.timeYSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.castbarTimeYOffset = r; UpdateCastbar() end
      end)
    end
    if cbar.timePrecisionDD then
      cbar.timePrecisionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.castbarTimePrecision = v; UpdateCastbar() end
      end
    end
    if cbar.timeDirectionDD then
      cbar.timeDirectionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.castbarTimeDirection = v; UpdateCastbar() end
      end
    end
    if cbar.textColorBtn then
      cbar.textColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.castbarTextColorR or 1, p.castbarTextColorG or 1, p.castbarTextColorB or 1
        local function OnChange()
          local nR, nG, nB = ColorPickerFrame:GetColorRGB()
          p.castbarTextColorR, p.castbarTextColorG, p.castbarTextColorB = nR, nG, nB
          cbar.textColorSwatch:SetBackdropColor(nR, nG, nB, 1)
          UpdateCastbar()
        end
        local function OnCancel(prev)
          p.castbarTextColorR, p.castbarTextColorG, p.castbarTextColorB = prev.r, prev.g, prev.b
          cbar.textColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
          UpdateCastbar()
        end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
  end
  local fcbar = addonTable.focusCastbar
  if fcbar then
    local function UpdateFocusCastbar()
      if addonTable.UpdateFocusCastbar then C_Timer.After(0, addonTable.UpdateFocusCastbar) end
    end
    local function num(v, d) return tonumber(v) or d end
    local function UpdateCenteredState()
      local p = GetProfile()
      local isCentered = p and p.focusCastbarCentered
      if fcbar.xSlider then
        fcbar.xSlider:SetEnabled(not isCentered)
        if fcbar.xSlider.label then
          fcbar.xSlider.label:SetTextColor(isCentered and 0.5 or 1, isCentered and 0.5 or 1, isCentered and 0.5 or 1)
        end
        if isCentered then
          fcbar.xSlider:SetValue(0)
          fcbar.xSlider.valueText:SetText("0")
        end
      end
    end
    local function LoadFocusCastbarValues()
      local p = GetProfile(); if not p then return end
      if fcbar.centeredCB then fcbar.centeredCB:SetChecked(p.focusCastbarCentered == true) end
      if fcbar.widthSlider then fcbar.widthSlider:SetValue(num(p.focusCastbarWidth, 250)); fcbar.widthSlider.valueText:SetText(math.floor(num(p.focusCastbarWidth, 250))) end
      if fcbar.heightSlider then fcbar.heightSlider:SetValue(num(p.focusCastbarHeight, 20)); fcbar.heightSlider.valueText:SetText(math.floor(num(p.focusCastbarHeight, 20))) end
      if fcbar.xSlider then fcbar.xSlider:SetValue(num(p.focusCastbarX, 0)); fcbar.xSlider.valueText:SetText(math.floor(num(p.focusCastbarX, 0))) end
      if fcbar.ySlider then local yVal = num(p.focusCastbarY, -210); fcbar.ySlider:SetValue(yVal); fcbar.ySlider.valueText:SetText(yVal % 1 == 0 and tostring(math.floor(yVal)) or string.format("%.1f", yVal)) end
      if fcbar.bgAlphaSlider then fcbar.bgAlphaSlider:SetValue(num(p.focusCastbarBgAlpha, 70)); fcbar.bgAlphaSlider.valueText:SetText(math.floor(num(p.focusCastbarBgAlpha, 70))) end
      if fcbar.bgColorSwatch then fcbar.bgColorSwatch:SetBackdropColor(p.focusCastbarBgColorR or 0.1, p.focusCastbarBgColorG or 0.1, p.focusCastbarBgColorB or 0.1, 1) end
      if fcbar.borderSlider then fcbar.borderSlider:SetValue(num(p.focusCastbarBorderSize, 1)); fcbar.borderSlider.valueText:SetText(math.floor(num(p.focusCastbarBorderSize, 1))) end
      if fcbar.textureDD then fcbar.textureDD:SetValue(p.focusCastbarTexture or "solid") end
      if fcbar.barColorBtn then fcbar.barColorBtn:SetEnabled(true); fcbar.barColorBtn:SetAlpha(1) end
      if fcbar.barColorSwatch then fcbar.barColorSwatch:SetBackdropColor(p.focusCastbarColorR or 1, p.focusCastbarColorG or 0.7, p.focusCastbarColorB or 0, 1); fcbar.barColorSwatch:SetAlpha(1) end
      if fcbar.showIconCB then fcbar.showIconCB:SetChecked(p.focusCastbarShowIcon ~= false) end
      if fcbar.showSpellNameCB then fcbar.showSpellNameCB:SetChecked(p.focusCastbarShowSpellName ~= false) end
      if fcbar.showTimeCB then fcbar.showTimeCB:SetChecked(p.focusCastbarShowTime ~= false) end
      if fcbar.showTicksCB then fcbar.showTicksCB:SetChecked(p.focusCastbarShowTicks ~= false) end
      if fcbar.spellNameScaleSlider then fcbar.spellNameScaleSlider:SetValue(num(p.focusCastbarSpellNameScale, 1)); fcbar.spellNameScaleSlider.valueText:SetText(string.format("%.1f", num(p.focusCastbarSpellNameScale, 1))) end
      if fcbar.timeScaleSlider then fcbar.timeScaleSlider:SetValue(num(p.focusCastbarTimeScale, 1)); fcbar.timeScaleSlider.valueText:SetText(string.format("%.1f", num(p.focusCastbarTimeScale, 1))) end
      if fcbar.spellNameXSlider then fcbar.spellNameXSlider:SetValue(num(p.focusCastbarSpellNameXOffset, 0)); fcbar.spellNameXSlider.valueText:SetText(math.floor(num(p.focusCastbarSpellNameXOffset, 0))) end
      if fcbar.spellNameYSlider then fcbar.spellNameYSlider:SetValue(num(p.focusCastbarSpellNameYOffset, 0)); fcbar.spellNameYSlider.valueText:SetText(math.floor(num(p.focusCastbarSpellNameYOffset, 0))) end
      if fcbar.timeXSlider then fcbar.timeXSlider:SetValue(num(p.focusCastbarTimeXOffset, 0)); fcbar.timeXSlider.valueText:SetText(math.floor(num(p.focusCastbarTimeXOffset, 0))) end
      if fcbar.timeYSlider then fcbar.timeYSlider:SetValue(num(p.focusCastbarTimeYOffset, 0)); fcbar.timeYSlider.valueText:SetText(math.floor(num(p.focusCastbarTimeYOffset, 0))) end
      if fcbar.timePrecisionDD then fcbar.timePrecisionDD:SetValue(p.focusCastbarTimePrecision or "1") end
      if fcbar.timeDirectionDD then fcbar.timeDirectionDD:SetValue(p.focusCastbarTimeDirection or "remaining") end
      if fcbar.textColorSwatch then fcbar.textColorSwatch:SetBackdropColor(p.focusCastbarTextColorR or 1, p.focusCastbarTextColorG or 1, p.focusCastbarTextColorB or 1, 1) end
      UpdateCenteredState()
    end
    addonTable.LoadFocusCastbarValues = LoadFocusCastbarValues
    C_Timer.After(0.3, LoadFocusCastbarValues)
    addonTable.UpdateFocusCastbarSliders = function(x, y)
      if fcbar.xSlider then fcbar.xSlider:SetValue(x); fcbar.xSlider.valueText:SetText(math.floor(x)) end
      if fcbar.ySlider then fcbar.ySlider:SetValue(y); fcbar.ySlider.valueText:SetText(math.floor(y)) end
    end
    if fcbar.centeredCB then fcbar.centeredCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarCentered = s:GetChecked(); if p.focusCastbarCentered then p.focusCastbarX = 0 end; UpdateCenteredState(); UpdateFocusCastbar() end end end
    if fcbar.widthSlider then fcbar.widthSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarWidth = r; UpdateFocusCastbar() end end) end
    if fcbar.heightSlider then fcbar.heightSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarHeight = r; UpdateFocusCastbar() end end) end
    if fcbar.xSlider then fcbar.xSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r) end; local p = GetProfile(); if p then p.focusCastbarX = r; UpdateFocusCastbar() end end) end
    if fcbar.ySlider then fcbar.ySlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 2 + 0.5) / 2; s._updating = true; s:SetValue(r); s._updating = false; if not s.valueText:HasFocus() then s.valueText:SetText(r % 1 == 0 and tostring(math.floor(r)) or string.format("%.1f", r)) end; local p = GetProfile(); if p then p.focusCastbarY = r; UpdateFocusCastbar() end end) end
    if fcbar.bgAlphaSlider then fcbar.bgAlphaSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarBgAlpha = r; UpdateFocusCastbar() end end) end
    if fcbar.borderSlider then fcbar.borderSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarBorderSize = r; UpdateFocusCastbar() end end) end
    if fcbar.textureDD then fcbar.textureDD.onSelect = function(v) local p = GetProfile(); if p then p.focusCastbarTexture = v; UpdateFocusCastbar() end end end

    if fcbar.showIconCB then fcbar.showIconCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowIcon = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.showSpellNameCB then fcbar.showSpellNameCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowSpellName = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.showTimeCB then fcbar.showTimeCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowTime = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.showTicksCB then fcbar.showTicksCB.customOnClick = function(s) local p = GetProfile(); if p then p.focusCastbarShowTicks = s:GetChecked(); UpdateFocusCastbar() end end end
    if fcbar.spellNameScaleSlider then fcbar.spellNameScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.focusCastbarSpellNameScale = r; UpdateFocusCastbar() end end) end
    if fcbar.timeScaleSlider then fcbar.timeScaleSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v * 10 + 0.5) / 10; s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(string.format("%.1f", r)); local p = GetProfile(); if p then p.focusCastbarTimeScale = r; UpdateFocusCastbar() end end) end
    if fcbar.spellNameXSlider then fcbar.spellNameXSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarSpellNameXOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.spellNameYSlider then fcbar.spellNameYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarSpellNameYOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.timeXSlider then fcbar.timeXSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarTimeXOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.timeYSlider then fcbar.timeYSlider:SetScript("OnValueChanged", function(s, v) if s._updating then return end; local r = math.floor(v); s._updating = true; s:SetValue(r); s._updating = false; s.valueText:SetText(r); local p = GetProfile(); if p then p.focusCastbarTimeYOffset = r; UpdateFocusCastbar() end end) end
    if fcbar.timePrecisionDD then fcbar.timePrecisionDD.onSelect = function(v) local p = GetProfile(); if p then p.focusCastbarTimePrecision = v; UpdateFocusCastbar() end end end
    if fcbar.timeDirectionDD then fcbar.timeDirectionDD.onSelect = function(v) local p = GetProfile(); if p then p.focusCastbarTimeDirection = v; UpdateFocusCastbar() end end end
    if fcbar.bgColorBtn then
      fcbar.bgColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.focusCastbarBgColorR or 0.1, p.focusCastbarBgColorG or 0.1, p.focusCastbarBgColorB or 0.1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.focusCastbarBgColorR, p.focusCastbarBgColorG, p.focusCastbarBgColorB = nR, nG, nB; if fcbar.bgColorSwatch then fcbar.bgColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateFocusCastbar() end
        local function OnCancel(prev) p.focusCastbarBgColorR, p.focusCastbarBgColorG, p.focusCastbarBgColorB = prev.r, prev.g, prev.b; if fcbar.bgColorSwatch then fcbar.bgColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateFocusCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if fcbar.barColorBtn then
      fcbar.barColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.focusCastbarColorR or 1, p.focusCastbarColorG or 0.7, p.focusCastbarColorB or 0
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.focusCastbarColorR, p.focusCastbarColorG, p.focusCastbarColorB = nR, nG, nB; if fcbar.barColorSwatch then fcbar.barColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateFocusCastbar() end
        local function OnCancel(prev) p.focusCastbarColorR, p.focusCastbarColorG, p.focusCastbarColorB = prev.r, prev.g, prev.b; if fcbar.barColorSwatch then fcbar.barColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateFocusCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
    if fcbar.textColorBtn then
      fcbar.textColorBtn:SetScript("OnClick", function()
        local p = GetProfile(); if not p then return end
        local r, g, b = p.focusCastbarTextColorR or 1, p.focusCastbarTextColorG or 1, p.focusCastbarTextColorB or 1
        local function OnChange() local nR, nG, nB = ColorPickerFrame:GetColorRGB(); p.focusCastbarTextColorR, p.focusCastbarTextColorG, p.focusCastbarTextColorB = nR, nG, nB; if fcbar.textColorSwatch then fcbar.textColorSwatch:SetBackdropColor(nR, nG, nB, 1) end; UpdateFocusCastbar() end
        local function OnCancel(prev) p.focusCastbarTextColorR, p.focusCastbarTextColorG, p.focusCastbarTextColorB = prev.r, prev.g, prev.b; if fcbar.textColorSwatch then fcbar.textColorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1) end; UpdateFocusCastbar() end
        ShowColorPicker({r = r, g = g, b = b, hasOpacity = false, swatchFunc = OnChange, cancelFunc = OnCancel})
      end)
    end
  end
  local db = addonTable.debuffs
  if db then
    local function UpdateDebuffs()
      if addonTable.State and addonTable.State.debuffPreviewMode then
        if addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
      else
        if addonTable.ApplyPlayerDebuffsSkinning then C_Timer.After(0, addonTable.ApplyPlayerDebuffsSkinning) end
      end
      if addonTable.activeTab and addonTable.activeTab() == 10 and addonTable.HighlightCustomBar then
        addonTable.HighlightCustomBar(10)
      end
    end
    local function num(v, d) return tonumber(v) or d end
    local function LoadPlayerDebuffsValues()
      local p = GetProfile(); if not p then return end
      if db.sizeSlider then db.sizeSlider:SetValue(num(p.playerDebuffSize, 32)); db.sizeSlider.valueText:SetText(math.floor(num(p.playerDebuffSize, 32))) end
      if db.spacingSlider then db.spacingSlider:SetValue(num(p.playerDebuffSpacing, 2)); db.spacingSlider.valueText:SetText(math.floor(num(p.playerDebuffSpacing, 2))) end
      if db.xSlider then db.xSlider:SetValue(num(p.playerDebuffX, 0)); db.xSlider.valueText:SetText(math.floor(num(p.playerDebuffX, 0))) end
      if db.ySlider then db.ySlider:SetValue(num(p.playerDebuffY, 0)); db.ySlider.valueText:SetText(math.floor(num(p.playerDebuffY, 0))) end
      if db.iconsPerRowSlider then db.iconsPerRowSlider:SetValue(num(p.playerDebuffIconsPerRow, 10)); db.iconsPerRowSlider.valueText:SetText(math.floor(num(p.playerDebuffIconsPerRow, 10))) end
      if db.sortDirectionDD then db.sortDirectionDD:SetValue(p.playerDebuffSortDirection or "right") end
      if db.growDirectionDD then db.growDirectionDD:SetValue(p.playerDebuffRowGrowDirection or "down") end
      if db.borderSizeSlider then db.borderSizeSlider:SetValue(num(p.playerDebuffBorderSize, 1)); db.borderSizeSlider.valueText:SetText(math.floor(num(p.playerDebuffBorderSize, 1))) end
    end
    addonTable.LoadPlayerDebuffsValues = LoadPlayerDebuffsValues
    C_Timer.After(0.3, LoadPlayerDebuffsValues)
    if db.sizeSlider then
      db.sizeSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffSize = r; UpdateDebuffs() end
      end)
    end
    if db.spacingSlider then
      db.spacingSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffSpacing = r; UpdateDebuffs() end
      end)
    end
    if db.xSlider then
      db.xSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffX = r; UpdateDebuffs() end
      end)
    end
    if db.ySlider then
      db.ySlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffY = r; UpdateDebuffs() end
      end)
    end
    if db.iconsPerRowSlider then
      db.iconsPerRowSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffIconsPerRow = r; UpdateDebuffs() end
      end)
    end
    if db.sortDirectionDD then
      db.sortDirectionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.playerDebuffSortDirection = v; UpdateDebuffs() end
      end
    end
    if db.growDirectionDD then
      db.growDirectionDD.onSelect = function(v)
        local p = GetProfile(); if p then p.playerDebuffRowGrowDirection = v; UpdateDebuffs() end
      end
    end
    if db.borderSizeSlider then
      db.borderSizeSlider:SetScript("OnValueChanged", function(s, v)
        if s._updating then return end
        local r = math.floor(v)
        s._updating = true; s:SetValue(r); s._updating = false
        s.valueText:SetText(r)
        local p = GetProfile(); if p then p.playerDebuffBorderSize = r; UpdateDebuffs() end
      end)
    end
    if db.previewOnBtn then
      db.previewOnBtn:SetScript("OnClick", function()
        if addonTable.ShowDebuffPreview then addonTable.ShowDebuffPreview() end
        SetButtonHighlighted(db.previewOnBtn, true)
      end)
    end
    if db.previewOffBtn then
      db.previewOffBtn:SetScript("OnClick", function()
        if addonTable.StopDebuffPreview then addonTable.StopDebuffPreview() end
        SetButtonHighlighted(db.previewOnBtn, false)
      end)
    end
  end
end
C_Timer.After(0.1, InitHandlers)





