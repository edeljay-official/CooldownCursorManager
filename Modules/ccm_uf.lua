--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_uf.lua
-- Unit frame customization and big healthbar overlays
-- Author: Edeljay
--------------------------------------------------------------------------------
if C_AddOns and C_AddOns.GetAddOnEnableState and C_AddOns.GetAddOnEnableState("CooldownCursorManager_UnitFrames") == 0 then return end

local _, addonTable = ...
local State = addonTable.State
local GetGlobalFont = addonTable.GetGlobalFont
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
local texturePaths = {
  solid = "Interface\\Buttons\\WHITE8x8",
  flat = "Interface\\Buttons\\WHITE8x8",
  blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
  blizzraid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
  normtex = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\normTex",
  gloss = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Gloss",
  melli = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Melli",
  mellidark = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\MelliDark",
  betterblizzard = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\BetterBlizzard",
  skyline = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Skyline",
  dragonflight = "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\Dragonflight",
}
local function SetBlizzardPlayerPowerBarsVisibility(showPower, showClassPower)
  local classPowerFrames = {
    ClassPowerBar,
    ComboPointPowerBar,
    PaladinPowerBar,
    PaladinPowerBarFrame,
    WarlockPowerBar,
    WarlockPowerFrame,
    MonkHarmonyBar,
    MonkHarmonyBarFrame,
    MageArcaneChargesFrame,
    RuneFrame,
    TotemFrame,
    EssencePlayerFrame,
  }
  for _, frame in ipairs(classPowerFrames) do
    if frame and frame.SetAlpha then
      if showClassPower then
        frame:SetAlpha(0)
        if frame.UnregisterAllEvents then
          pcall(function() frame:UnregisterAllEvents() end)
        end
      else
        frame:SetAlpha(1)
      end
    end
  end
  if PlayerFrameBottomManagedFramesContainer and PlayerFrameBottomManagedFramesContainer.SetAlpha then
    if showClassPower then
      PlayerFrameBottomManagedFramesContainer:SetAlpha(0)
    else
      PlayerFrameBottomManagedFramesContainer:SetAlpha(1)
    end
  end
  if ClassNameplateBar and ClassNameplateBar.SetAlpha then
    if showClassPower then
      ClassNameplateBar:SetAlpha(0)
      if ClassNameplateBar.UnregisterAllEvents then
        pcall(function() ClassNameplateBar:UnregisterAllEvents() end)
      end
    else
      ClassNameplateBar:SetAlpha(1)
    end
  end
end
addonTable.SetBlizzardPlayerPowerBarsVisibility = SetBlizzardPlayerPowerBarsVisibility

local function CCM_IsSecret(v)
  return issecretvalue and issecretvalue(v) or false
end

local function CCM_SetBarValuesSafe(bar, minValue, maxValue, value)
  if not bar then return end
  local mn = minValue
  local mx = maxValue
  local vv = value
  if type(mn) ~= "number" then mn = 0 end
  if type(mx) ~= "number" then mx = 1 end
  if type(vv) ~= "number" then vv = mn end
  if not CCM_IsSecret(mn) and not CCM_IsSecret(mx) and mx <= mn then
    mx = mn + 1
  end
  pcall(bar.SetMinMaxValues, bar, mn, mx)
  pcall(bar.SetValue, bar, vv)
end

local function CCM_FormatCompactNumber(v)
  local n = tonumber(v)
  if type(n) ~= "number" then return "" end
  local abs = math.abs(n)
  local fmt
  if abs >= 1000000000 then
    fmt = string.format("%.1fB", n / 1000000000)
  elseif abs >= 1000000 then
    fmt = string.format("%.1fM", n / 1000000)
  elseif abs >= 1000 then
    fmt = string.format("%.1fK", n / 1000)
  else
    fmt = string.format("%d", n)
  end
  fmt = fmt:gsub("%.0([KMB])", "%1")
  return fmt
end

local function CCM_FormatBossTextSafe(v)
  if type(v) ~= "number" then return "" end
  if CCM_IsSecret(v) then
    if AbbreviateLargeNumbers then
      local ok, text = pcall(AbbreviateLargeNumbers, v)
      if ok and type(text) == "string" then return text end
    end
    return v
  end
  return CCM_FormatCompactNumber(v)
end

local function CCM_SafePercent(unit)
  if not unit then return nil end
  local ok, pct = pcall(function()
    if UnitHealthPercent then
      local s100 = CurveConstants and CurveConstants.ScaleTo100
      return UnitHealthPercent(unit, false, s100)
    end
    return nil
  end)
  if ok and type(pct) == "number" then return string.format("%.0f%%", pct) end
  return nil
end

local function CCM_SafeAbbrevValue(v)
  if CCM_IsSecret(v) then
    if AbbreviateLargeNumbers then
      local vOk, vText = pcall(AbbreviateLargeNumbers, v)
      if vOk and type(vText) == "string" then return vText end
    end
    return nil
  end
  return CCM_FormatCompactNumber(v)
end

local function CCM_FormatBossHealthTextSafe(cur, unit, fmt)
  if type(cur) ~= "number" then return "" end
  fmt = fmt or "percent"
  if fmt == "value" then
    return CCM_SafeAbbrevValue(cur) or ""
  elseif fmt == "value_percent" then
    local valStr = CCM_SafeAbbrevValue(cur)
    local pctStr = CCM_SafePercent(unit)
    if valStr and pctStr then return valStr .. " | " .. pctStr end
    return valStr or pctStr or ""
  else
    return CCM_SafePercent(unit) or ""
  end
end


local _ccmBossHiddenParent = CreateFrame("Frame", nil, UIParent)
_ccmBossHiddenParent:SetAllPoints()
_ccmBossHiddenParent:Hide()

local _ccmBossOrigParents = {}
local _ccmBossLooseFrames = {}

local _ccmBossWatcher = CreateFrame("Frame")
_ccmBossWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
_ccmBossWatcher:SetScript("OnEvent", function()
  for frame in next, _ccmBossLooseFrames do
    frame:SetParent(_ccmBossHiddenParent)
  end
  table.wipe(_ccmBossLooseFrames)
end)

local function CCM_DisableBlizzBossFrame(f)
  if not f then return end
  if not _ccmBossOrigParents[f] then
    _ccmBossOrigParents[f] = f:GetParent()
  end
  f:UnregisterAllEvents()
  f:Hide()
  if InCombatLockdown() and f:IsProtected() then
    _ccmBossLooseFrames[f] = true
  else
    f:SetParent(_ccmBossHiddenParent)
  end
  if not f._ccmReParentHooked then
    f._ccmReParentHooked = true
    hooksecurefunc(f, "SetParent", function(self, parent)
      if not self._ccmBossDisabled then return end
      if parent ~= _ccmBossHiddenParent then
        if InCombatLockdown() and self:IsProtected() then
          _ccmBossLooseFrames[self] = true
        else
          self:SetParent(_ccmBossHiddenParent)
        end
      end
    end)
  end
  f._ccmBossDisabled = true
  local health = f.healthBar or f.healthbar or f.HealthBar or (f.HealthBarsContainer and f.HealthBarsContainer.healthBar)
  if health then health:UnregisterAllEvents() end
  local power = f.manabar or f.ManaBar
  if power then power:UnregisterAllEvents() end
  local castbar = f.castBar or f.spellbar or f.CastingBarFrame
  if castbar then castbar:UnregisterAllEvents() end
  local altpower = f.powerBarAlt or f.PowerBarAlt
  if altpower then altpower:UnregisterAllEvents() end
  local buffs = f.BuffFrame or f.AurasFrame
  if buffs then buffs:UnregisterAllEvents() end
end

local function CCM_EnableBlizzBossFrame(f)
  if not f then return end
  f._ccmBossDisabled = false
  _ccmBossLooseFrames[f] = nil
  local origParent = _ccmBossOrigParents[f]
  if origParent and not InCombatLockdown() then
    f:SetParent(origParent)
  end
end

local function CCM_ApplyBossBlizzardVisibility(enabled)
  if enabled then
    if BossTargetFrameContainer then
      CCM_DisableBlizzBossFrame(BossTargetFrameContainer)
    end
  end
  for i = 1, 8 do
    local f = _G["Boss" .. i .. "TargetFrame"]
    if f then
      if enabled then
        CCM_DisableBlizzBossFrame(f)
      else
        CCM_EnableBlizzBossFrame(f)
      end
    end
  end
end

local function CCM_EnsureCustomBossFrames()
  State.customBoss = State.customBoss or {}
  local st = State.customBoss
  if st.holder and st.rows then return st end

  st.holder = CreateFrame("Frame", "CCMCustomBossHolder", UIParent)
  st.holder:SetFrameStrata("MEDIUM")
  st.rows = {}
  st.elapsed = 0

  for i = 1, 8 do
    local row = CreateFrame("Button", "CCMCustomBossFrame" .. i, st.holder, "SecureUnitButtonTemplate,BackdropTemplate")
    row:SetAttribute("unit", "boss" .. i)
    row:RegisterForClicks("AnyUp")
    row:SetAttribute("*type1", "target")
    row:SetAttribute("*type2", "togglemenu")
    row:HookScript("OnEnter", function(self)
      local unit = self:GetAttribute("unit")
      if unit and UnitExists(unit) then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetUnit(unit)
        GameTooltip:Show()
      end
    end)
    row:HookScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    RegisterUnitWatch(row)

    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

    row.portraitBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.portraitBg:SetSize(36, 36)
    row.portraitBg:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -4)
    row.portraitBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    row.portraitBg:SetBackdropColor(0.10, 0.10, 0.12, 1)
    row.portrait = row.portraitBg:CreateTexture(nil, "ARTWORK")
    row.portrait:SetAllPoints(row.portraitBg)
    row.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local baseLevel = row:GetFrameLevel()

    row.hpBg = CreateFrame("StatusBar", nil, row)
    row.hpBg:SetFrameLevel(baseLevel + 1)
    row.hpBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.hpBg:SetStatusBarColor(0, 0, 0, 0.45)

    row.hp = CreateFrame("StatusBar", nil, row)
    row.hp:SetFrameLevel(baseLevel + 2)
    row.hp:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.hp:SetClipsChildren(true)
    row.absorb = CreateFrame("StatusBar", nil, row.hp)
    row.absorb:SetFrameLevel(row.hp:GetFrameLevel() + 1)
    row.absorb:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.absorb:SetStatusBarColor(0.85, 0.95, 1.00, 0.28)

    row.barBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.barBorder:SetFrameLevel(baseLevel + 4)
    row.barBorder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    row.barBorder:SetBackdropColor(0, 0, 0, 0)
    row.barBorder:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

    row.ppBg = CreateFrame("StatusBar", nil, row)
    row.ppBg:SetFrameLevel(baseLevel + 1)
    row.ppBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.ppBg:SetStatusBarColor(0, 0, 0, 0.45)

    row.pp = CreateFrame("StatusBar", nil, row)
    row.pp:SetFrameLevel(baseLevel + 2)
    row.pp:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")

    row.textOverlay = CreateFrame("Frame", nil, row)
    row.textOverlay:SetAllPoints(row)
    row.textOverlay:SetFrameLevel(row:GetFrameLevel() + 10)
    row.name = row.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetJustifyH("LEFT")
    row.hpText = row.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hpText:SetJustifyH("RIGHT")
    row.ppText = row.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.ppText:SetJustifyH("RIGHT")
    row.level = row.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.level:SetJustifyH("RIGHT")

    row.castHolder = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.castHolder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    row.castHolder:SetBackdropColor(0, 0, 0, 0)
    row.castHolder:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

    local castBaseLevel = row.castHolder:GetFrameLevel()
    row.castBg = CreateFrame("StatusBar", nil, row.castHolder)
    row.castBg:SetFrameLevel(castBaseLevel + 1)
    row.castBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.castBg:SetStatusBarColor(0, 0, 0, 0.45)
    row.castBg:SetAllPoints(row.castHolder)
    row.castBg:SetMinMaxValues(0, 1)
    row.castBg:SetValue(1)

    row.cast = CreateFrame("StatusBar", nil, row.castHolder)
    row.cast:SetFrameLevel(castBaseLevel + 2)
    row.cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.cast:SetMinMaxValues(0, 1)
    row.cast:SetValue(0.5)
    row.cast:SetAllPoints(row.castHolder)

    row.castTextOverlay = CreateFrame("Frame", nil, row.castHolder)
    row.castTextOverlay:SetAllPoints(row.castHolder)
    row.castTextOverlay:SetFrameLevel(row.cast:GetFrameLevel() + 5)
    row.castText = row.castTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.castText:SetPoint("LEFT", row.castHolder, "LEFT", 4, 0)
    row.castText:SetJustifyH("LEFT")
    row.castTime = row.castTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.castTime:SetPoint("RIGHT", row.castHolder, "RIGHT", -4, 0)
    row.castTime:SetJustifyH("RIGHT")
    row.castIcon = row.castHolder:CreateTexture(nil, "ARTWORK")
    row.castIcon:SetTexture("Interface\\Icons\\spell_arcane_portalstormwind")
    row.castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.castHolder:Hide()

    st.rows[i] = row
  end

  st._castState = {}
  for i = 1, 8 do
    st._castState[i] = { casting = false, channeling = false }
  end
  local castEventFrame = CreateFrame("Frame")
  for i = 1, 8 do
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "boss" .. i)
    castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "boss" .. i)
  end
  castEventFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if not unit then return end
    local idx = unit:match("^boss(%d+)$")
    if not idx then return end
    idx = tonumber(idx)
    if not idx or not st._castState[idx] then return end
    local cs = st._castState[idx]
    if event == "UNIT_SPELLCAST_START" then
      cs.casting = true
      cs.channeling = false
      local info = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
      cs.spellName = info and info.name or nil
      cs.spellIcon = info and info.iconID or nil
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
      cs.channeling = true
      cs.casting = false
      local info = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
      cs.spellName = info and info.name or nil
      cs.spellIcon = info and info.iconID or nil
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
      cs.casting = false
      if not cs.channeling then cs.spellName = nil; cs.spellIcon = nil end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
      cs.channeling = false
      if not cs.casting then cs.spellName = nil; cs.spellIcon = nil end
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
      cs.notInterruptible = (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    end
  end)

  st.holder:SetScript("OnUpdate", function(_, elapsed)
    st.elapsed = (st.elapsed or 0) + (elapsed or 0)
    if st.elapsed < 0.04 then return end
    st.elapsed = 0
    if not st.enabled then return end
    for i = 1, #st.rows do
      local row = st.rows[i]
      local unit = "boss" .. i
      if UnitExists(unit) then
        if not InCombatLockdown() then row:Show() end
        local hpMax = UnitHealthMax(unit)
        local hpCur = UnitHealth(unit)
        CCM_SetBarValuesSafe(row.hp, 0, hpMax, hpCur)
        local r, g, b = 1, 0.1, 0.1
        if addonTable.GetProfile and (addonTable.GetProfile().ufClassColor == true) and UnitIsPlayer(unit) then
          local _, classToken = UnitClass(unit)
          local cc = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
          if cc then r, g, b = cc.r, cc.g, cc.b end
        end
        row.hp:SetStatusBarColor(r, g, b, 1)
        local pMax = UnitPowerMax(unit)
        local pCur = UnitPower(unit)
        CCM_SetBarValuesSafe(row.pp, 0, pMax, pCur)
        local pType, pToken = UnitPowerType(unit)
        local pc = (pToken and PowerBarColor and PowerBarColor[pToken]) or (pType and PowerBarColor and PowerBarColor[pType])
        row.pp:SetStatusBarColor((pc and pc.r) or 0.35, (pc and pc.g) or 0.35, (pc and pc.b) or 0.95, 1)
        local unitName = UnitName(unit)
        if unitName then
          pcall(row.name.SetText, row.name, unitName)
        else
          row.name:SetText("Boss " .. i)
        end
        row.name:Show()
        if row._showHealthText then
          local hText = CCM_FormatBossHealthTextSafe(hpCur, unit, row._healthTextFormat)
          if hText then pcall(row.hpText.SetText, row.hpText, hText) end
          row.hpText:Show()
        else
          row.hpText:Hide()
        end
        if row._showPowerText then
          local pText = CCM_FormatBossTextSafe(pCur)
          if pText then pcall(row.ppText.SetText, row.ppText, pText) end
          row.ppText:Show()
        else
          row.ppText:Hide()
        end
        if row._showLevel then
          local lv = UnitLevel(unit)
          local lvOk, lvStr = pcall(function()
            if type(lv) == "number" and lv > 0 then return tostring(lv) end
            return "??"
          end)
          row.level:SetText((lvOk and lvStr) or "??")
          row.level:Show()
        else
          row.level:Hide()
        end
        if row._hidePortrait then
          row.portraitBg:Hide()
        else
          row.portraitBg:Show()
          SetPortraitTexture(row.portrait, unit)
        end
        if row._showAbsorb then
          local absorb = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0
          if CCM_IsSecret(absorb) or CCM_IsSecret(hpMax) then
            CCM_SetBarValuesSafe(row.absorb, 0, hpMax, absorb)
            row.absorb:Show()
          else
            local absOk, absShow = pcall(function()
              if type(absorb) == "number" and absorb > 0 then return true end
              return false
            end)
            if absOk and absShow then
              CCM_SetBarValuesSafe(row.absorb, 0, hpMax, absorb)
              row.absorb:Show()
            else
              row.absorb:Hide()
            end
          end
        else
          row.absorb:Hide()
        end

        local cs = st._castState[i]
        local showingCast = cs.casting or cs.channeling
        if showingCast then
          local durationObject = nil
          if cs.casting and UnitCastingDuration then
            local okDur, durObj = pcall(UnitCastingDuration, unit)
            if okDur then durationObject = durObj end
          elseif cs.channeling and UnitChannelDuration then
            local okDur, durObj = pcall(UnitChannelDuration, unit)
            if okDur then durationObject = durObj end
          end
          if durationObject and row.cast.SetTimerDuration then
            local interp = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or nil
            local dir = cs.casting and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime
            pcall(row.cast.SetTimerDuration, row.cast, durationObject, interp, dir)
          end
          if cs.notInterruptible then
            row.cast:SetStatusBarColor(0.50, 0.50, 0.50, 1)
          else
            row.cast:SetStatusBarColor(cs.casting and 1.00 or 0.34, cs.casting and 0.72 or 0.58, cs.casting and 0.12 or 1.00, 1)
          end
          if cs.spellName then row.castText:SetText(cs.spellName) end
          if cs.spellIcon and row.castIcon then row.castIcon:SetTexture(cs.spellIcon) end
          if durationObject then
            local okRem, remaining = pcall(function() return durationObject:GetRemainingDuration() end)
            if okRem and remaining ~= nil then
              row.castTime:SetText(string.format("%.1f", remaining))
            end
          end
        end
        if row.castIcon then
          row.castIcon:SetShown(showingCast and row._castbarIconEnabled == true)
        end
        row.castHolder:SetShown(showingCast)
      else
        if not InCombatLockdown() then row:Hide() end
      end
    end
  end)

  return st
end

local function CCM_ApplyCustomBossFrames(profile, ufEnabled, useCustomTex, selectedTexturePath)
  local st = CCM_EnsureCustomBossFrames()
  local enabled = ufEnabled and profile and profile.ufBossFramesEnabled == true
  st.enabled = enabled == true
  if not profile then
    if st.holder then st.holder:Hide() end
    CCM_ApplyBossBlizzardVisibility(false)
    return
  end

  if not enabled then
    if st.holder then st.holder:Hide() end
    CCM_ApplyBossBlizzardVisibility(false)
    return
  end

  local anchor = profile.ufBossFrameAnchor or "TOPRIGHT"
  local x = tonumber(profile.ufBossFrameX) or -245
  local y = tonumber(profile.ufBossFrameY) or -280
  local scale = tonumber(profile.ufBossFrameScale) or 1
  local spacing = tonumber(profile.ufBossFrameSpacing) or 36
  local width = tonumber(profile.ufBossFrameWidth) or 168
  local healthH = tonumber(profile.ufBossFrameHealthHeight) or 20
  local powerH = tonumber(profile.ufBossFramePowerHeight) or 8
  local showLevel = profile.ufBossFrameShowLevel ~= false
  local hidePortrait = profile.ufBossFrameHidePortrait == true
  local borderSize = math.max(0, math.min(3, math.floor((tonumber(profile.ufBossFrameBorderSize) or ((profile.ufBossFrameUseBorder == true) and 1 or 0)) + 0.5)))
  local useBorder = borderSize > 0
  local castbarClamped = profile.ufBossCastbarClamped ~= false
  local castbarAnchor = profile.ufBossCastbarAnchor or "bottom"
  local castbarIconEnabled = profile.ufBossCastbarIcon ~= false
  local castbarHeight = tonumber(profile.ufBossCastbarHeight) or 12
  local castbarWidthOverride = tonumber(profile.ufBossCastbarWidth) or 0
  local castbarSpacing = castbarClamped and 0 or (tonumber(profile.ufBossCastbarSpacing) or 2)
  local castbarOffX = tonumber(profile.ufBossCastbarX) or 0
  local castbarOffY = tonumber(profile.ufBossCastbarY) or 0
  local showHealthText = profile.ufBossFrameShowHealthText ~= false
  local healthTextFormat = profile.ufBossHealthTextFormat or "percent"
  local showPowerText = profile.ufBossFrameShowPowerText ~= false
  local healthTextX = tonumber(profile.ufBossHealthTextX) or -4
  local healthTextY = tonumber(profile.ufBossHealthTextY) or 0
  local powerTextX = tonumber(profile.ufBossPowerTextX) or -4
  local powerTextY = tonumber(profile.ufBossPowerTextY) or 0
  local healthTextScale = tonumber(profile.ufBossHealthTextScale) or 1
  local powerTextScale = tonumber(profile.ufBossPowerTextScale) or 1
  local castbarTextScale = tonumber(profile.ufBossCastbarTextScale) or 1
  local showAbsorb = profile.ufBossFrameShowAbsorb == true
  local absorbR = tonumber(profile.ufBossAbsorbColorR) or 0.85
  local absorbG = tonumber(profile.ufBossAbsorbColorG) or 0.95
  local absorbB = tonumber(profile.ufBossAbsorbColorB) or 1.00
  local absorbA = tonumber(profile.ufBossAbsorbColorA) or 0.28
  local bossTexKey = profile.ufBossBarTexture or "lsm:Blizzard"
  local bossTexResolved = (addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(bossTexKey)) or texturePaths[bossTexKey] or texturePaths.blizzard
  local barBgAlpha = tonumber(profile.ufBossFrameBarBgAlpha) or 0.45
  if barBgAlpha < 0 then barBgAlpha = 0 end
  if barBgAlpha > 1 then barBgAlpha = 1 end
  local borderOn = profile.useCustomBorderColor == true
  local borderR = borderOn and (profile.ufCustomBorderColorR or 0.22) or 0.22
  local borderG = borderOn and (profile.ufCustomBorderColorG or 0.22) or 0.22
  local borderB = borderOn and (profile.ufCustomBorderColorB or 0.26) or 0.26
  local useNameColor = profile.ufUseCustomNameColor == true
  local nameR = useNameColor and (profile.ufNameColorR or 1) or 1
  local nameG = useNameColor and (profile.ufNameColorG or 1) or 1
  local nameB = useNameColor and (profile.ufNameColorB or 1) or 1
  local bossBarTexturePath = bossTexResolved or "Interface\\Buttons\\WHITE8x8"

  local gf, go
  if addonTable.GetGlobalFont then
    gf, go = addonTable.GetGlobalFont()
  end
  gf = gf or "Fonts\\FRIZQT__.TTF"
  go = go or ""
  local PU = PixelUtil
  st.holder:ClearAllPoints()
  st.holder:SetPoint(anchor, UIParent, anchor, x, y)
  st.holder:SetScale(scale)
  st.holder:Show()
  st.holder:SetFrameStrata("MEDIUM")

  local totalH = healthH + powerH + 7
  local rowStride = totalH + 16 + spacing
  PU.SetSize(st.holder, width + 64, (rowStride * 8) + 24)

  for i = 1, #st.rows do
    local row = st.rows[i]
    local portraitSize = healthH + powerH
    local leftInset = hidePortrait and 5 or (portraitSize + 5)
    row:ClearAllPoints()
    PU.SetPoint(row, "TOPLEFT", st.holder, "TOPLEFT", 14, -(i - 1) * rowStride - 18)
    PU.SetSize(row, width + 46, totalH + 22)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(borderR, borderG, borderB, 0)
    row._showLevel = showLevel
    row._hidePortrait = hidePortrait
    row._castbarIconEnabled = castbarIconEnabled
    row._showHealthText = showHealthText
    row._healthTextFormat = healthTextFormat
    row._showPowerText = showPowerText
    row._healthTextX = healthTextX
    row._healthTextY = healthTextY
    row._powerTextX = powerTextX
    row._powerTextY = powerTextY
    row._showAbsorb = showAbsorb

    row.hpBg:ClearAllPoints()
    PU.SetPoint(row.hpBg, "TOPLEFT", row, "TOPLEFT", leftInset, -4)
    PU.SetPoint(row.hpBg, "TOPRIGHT", row, "TOPRIGHT", -5, -4)
    PU.SetHeight(row.hpBg, healthH)
    row.hpBg:SetMinMaxValues(0, 1)
    row.hpBg:SetValue(1)
    row.hpBg:SetStatusBarColor(0, 0, 0, barBgAlpha)

    row.hp:ClearAllPoints()
    PU.SetPoint(row.hp, "TOPLEFT", row.hpBg, "TOPLEFT", 0, 0)
    PU.SetPoint(row.hp, "TOPRIGHT", row.hpBg, "TOPRIGHT", 0, 0)
    PU.SetHeight(row.hp, healthH)
    pcall(row.hp.SetStatusBarTexture, row.hp, bossBarTexturePath)

    row.ppBg:ClearAllPoints()
    PU.SetPoint(row.ppBg, "TOPLEFT", row.hp, "BOTTOMLEFT", 0, 0)
    PU.SetPoint(row.ppBg, "TOPRIGHT", row.hp, "BOTTOMRIGHT", 0, 0)
    PU.SetHeight(row.ppBg, powerH)
    row.ppBg:SetMinMaxValues(0, 1)
    row.ppBg:SetValue(1)
    row.ppBg:SetStatusBarColor(0, 0, 0, barBgAlpha)

    row.pp:ClearAllPoints()
    PU.SetPoint(row.pp, "TOPLEFT", row.hp, "BOTTOMLEFT", 0, 0)
    PU.SetPoint(row.pp, "TOPRIGHT", row.hp, "BOTTOMRIGHT", 0, 0)
    PU.SetHeight(row.pp, powerH)
    pcall(row.pp.SetStatusBarTexture, row.pp, bossBarTexturePath)

    if row.barBorder then
      row.barBorder:ClearAllPoints()
      local borderLeft = hidePortrait and row.hpBg or row.portraitBg
      PU.SetPoint(row.barBorder, "TOPLEFT", borderLeft, "TOPLEFT", -borderSize, borderSize)
      PU.SetPoint(row.barBorder, "BOTTOMRIGHT", row.ppBg, "BOTTOMRIGHT", borderSize, -borderSize)
      row.barBorder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = math.max(1, borderSize) })
      row.barBorder:SetBackdropColor(0, 0, 0, 0)
      row.barBorder:SetBackdropBorderColor(borderR, borderG, borderB, useBorder and 1 or 0)
    end

    row.name:ClearAllPoints()
    PU.SetPoint(row.name, "LEFT", row.hp, "LEFT", 4, 0)
    if row.name.SetFont then pcall(row.name.SetFont, row.name, gf, 11, go or "") end
    row.name:SetTextColor(nameR, nameG, nameB)
    row.hpText:ClearAllPoints()
    PU.SetPoint(row.hpText, "RIGHT", row.hp, "RIGHT", healthTextX, healthTextY)
    if row.hpText.SetFont then pcall(row.hpText.SetFont, row.hpText, gf, math.max(6, math.floor(10 * healthTextScale + 0.5)), go or "") end
    row.hpText:SetTextColor(nameR, nameG, nameB)
    row.ppText:ClearAllPoints()
    PU.SetPoint(row.ppText, "RIGHT", row.pp, "RIGHT", powerTextX, powerTextY)
    if row.ppText.SetFont then pcall(row.ppText.SetFont, row.ppText, gf, math.max(6, math.floor(10 * powerTextScale + 0.5)), go or "") end
    row.ppText:SetTextColor(nameR, nameG, nameB)

    row.level:ClearAllPoints()
    PU.SetPoint(row.level, "RIGHT", row.hp, "RIGHT", -4, 0)
    if row.level.SetFont then pcall(row.level.SetFont, row.level, gf, 10, go or "") end
    row.level:SetTextColor(nameR, nameG, nameB)

    if row.portraitBg then
      row.portraitBg:ClearAllPoints()
      if hidePortrait then
        row.portraitBg:Hide()
      else
        PU.SetSize(row.portraitBg, portraitSize, portraitSize)
        PU.SetPoint(row.portraitBg, "TOPRIGHT", row.hp, "TOPLEFT", 0, 0)
        row.portraitBg:Show()
      end
    end

    local barBorderLeft = hidePortrait and row.hpBg or row.portraitBg
    local useCustomWidth = castbarWidthOverride > 0
    row.castHolder:ClearAllPoints()
    if castbarAnchor == "top" then
      if useCustomWidth then
        PU.SetPoint(row.castHolder, "BOTTOM", row.hpBg, "TOP", castbarOffX, castbarSpacing + castbarOffY)
        PU.SetSize(row.castHolder, castbarWidthOverride + borderSize * 2, castbarHeight + borderSize * 2)
      else
        PU.SetPoint(row.castHolder, "BOTTOMLEFT", barBorderLeft, "TOPLEFT", -borderSize + castbarOffX, castbarSpacing + castbarOffY)
        PU.SetPoint(row.castHolder, "BOTTOMRIGHT", row.hpBg, "TOPRIGHT", borderSize + castbarOffX, castbarSpacing + castbarOffY)
        PU.SetHeight(row.castHolder, castbarHeight + borderSize * 2)
      end
    elseif castbarAnchor == "left" then
      PU.SetPoint(row.castHolder, "RIGHT", barBorderLeft, "LEFT", -castbarSpacing + castbarOffX, castbarOffY)
      local castW = (useCustomWidth and castbarWidthOverride or width) + borderSize * 2
      PU.SetSize(row.castHolder, castW, castbarHeight + borderSize * 2)
    elseif castbarAnchor == "right" then
      PU.SetPoint(row.castHolder, "LEFT", row.hpBg, "RIGHT", castbarSpacing + castbarOffX, castbarOffY)
      local castW = (useCustomWidth and castbarWidthOverride or width) + borderSize * 2
      PU.SetSize(row.castHolder, castW, castbarHeight + borderSize * 2)
    else
      if useCustomWidth then
        PU.SetPoint(row.castHolder, "TOP", row.ppBg, "BOTTOM", castbarOffX, -castbarSpacing + castbarOffY)
        PU.SetSize(row.castHolder, castbarWidthOverride + borderSize * 2, castbarHeight + borderSize * 2)
      else
        PU.SetPoint(row.castHolder, "TOPLEFT", row.ppBg, "BOTTOMLEFT", -(hidePortrait and 0 or portraitSize) - borderSize + castbarOffX, -castbarSpacing + castbarOffY)
        PU.SetPoint(row.castHolder, "TOPRIGHT", row.ppBg, "BOTTOMRIGHT", borderSize + castbarOffX, -castbarSpacing + castbarOffY)
        PU.SetHeight(row.castHolder, castbarHeight + borderSize * 2)
      end
    end
    row.castHolder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = math.max(1, borderSize) })
    row.castHolder:SetBackdropColor(0, 0, 0, 0)
    row.castHolder:SetBackdropBorderColor(borderR, borderG, borderB, useBorder and 1 or 0)
    local castIconVisible = castbarIconEnabled and not hidePortrait
    local iconSpace = castIconVisible and castbarHeight or 0
    if row.castIcon then
      row.castIcon:ClearAllPoints()
      PU.SetSize(row.castIcon, castbarHeight, castbarHeight)
      PU.SetPoint(row.castIcon, "TOPLEFT", row.castHolder, "TOPLEFT", borderSize, -borderSize)
      row.castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      row.castIcon:SetShown(castIconVisible)
    end
    if row.castBg then
      row.castBg:ClearAllPoints()
      PU.SetPoint(row.castBg, "TOPLEFT", row.castHolder, "TOPLEFT", borderSize + iconSpace, -borderSize)
      PU.SetPoint(row.castBg, "BOTTOMRIGHT", row.castHolder, "BOTTOMRIGHT", -borderSize, borderSize)
      pcall(row.castBg.SetStatusBarTexture, row.castBg, bossBarTexturePath)
      row.castBg:SetStatusBarColor(0, 0, 0, barBgAlpha)
    end
    if row.cast then
      row.cast:ClearAllPoints()
      PU.SetPoint(row.cast, "TOPLEFT", row.castHolder, "TOPLEFT", borderSize + iconSpace, -borderSize)
      PU.SetPoint(row.cast, "BOTTOMRIGHT", row.castHolder, "BOTTOMRIGHT", -borderSize, borderSize)
    end
    pcall(row.cast.SetStatusBarTexture, row.cast, bossBarTexturePath)
    if row.castTextOverlay then
      row.castTextOverlay:ClearAllPoints()
      PU.SetPoint(row.castTextOverlay, "TOPLEFT", row.castHolder, "TOPLEFT", borderSize + iconSpace, -borderSize)
      PU.SetPoint(row.castTextOverlay, "BOTTOMRIGHT", row.castHolder, "BOTTOMRIGHT", -borderSize, borderSize)
    end
    local castFontSize = math.max(6, math.floor(10 * castbarTextScale + 0.5))
    if row.castText then
      row.castText:ClearAllPoints()
      PU.SetPoint(row.castText, "LEFT", row.castTextOverlay or row.cast, "LEFT", 4, 0)
      if row.castText.SetFont then pcall(row.castText.SetFont, row.castText, gf, castFontSize, go or "") end
      row.castText:SetTextColor(nameR, nameG, nameB)
    end
    if row.castTime then
      row.castTime:ClearAllPoints()
      PU.SetPoint(row.castTime, "RIGHT", row.castTextOverlay or row.cast, "RIGHT", -4, 0)
      if row.castTime.SetFont then pcall(row.castTime.SetFont, row.castTime, gf, castFontSize, go or "") end
      row.castTime:SetTextColor(nameR, nameG, nameB)
    end
    row.absorb:ClearAllPoints()
    local hpTex = row.hp:GetStatusBarTexture()
    PU.SetPoint(row.absorb, "TOPLEFT", hpTex, "TOPRIGHT", 0, 0)
    PU.SetPoint(row.absorb, "BOTTOMLEFT", hpTex, "BOTTOMRIGHT", 0, 0)
    row.absorb:SetWidth(row.hp:GetWidth() or width)
    row.absorb:SetStatusBarTexture(bossBarTexturePath)
    row.absorb:SetStatusBarColor(absorbR, absorbG, absorbB, absorbA)
  end

  CCM_ApplyBossBlizzardVisibility(true)
end

addonTable.ApplyUnitFrameCustomization = function()
  local profile = addonTable.GetProfile and addonTable.GetProfile()
  if not profile then return end
  local ufEnabled = profile.enableUnitFrameCustomization ~= false
  local function GetPlayerObjects()
    local pf = PlayerFrame
    local main = pf and pf.PlayerFrameContent and pf.PlayerFrameContent.PlayerFrameContentMain
    local hContainer = main and main.HealthBarsContainer
    local mArea = main and main.ManaBarArea
    local hp = PlayerFrameHealthBar or (hContainer and hContainer.HealthBar)
    local mp = PlayerFrameManaBar or (mArea and mArea.ManaBar)
    return {
      healthBar = hp,
      powerBar = mp,
    }
  end
  local function ResolveUnitHealthColorSafe(unitToken, useClassColor)
    local r, g, b
    if useClassColor and unitToken and UnitExists(unitToken) and UnitIsPlayer(unitToken) then
      local _, classToken = UnitClass(unitToken)
      local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
      if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
      end
    end
    if not r then
      if unitToken == "player" then
        r, g, b = 0, 1, 0
      elseif unitToken and UnitExists(unitToken) then
        if UnitIsFriend("player", unitToken) then
          r, g, b = 0, 1, 0
        elseif UnitCanAttack("player", unitToken) then
          r, g, b = 1, 0, 0
        else
          r, g, b = 1, 1, 0
        end
      end
    end
    if not r then
      r, g, b = 0, 1, 0
    end
    return r, g, b
  end
  local function ApplyHealthColorSafe(bar, unitToken, useClassColor)
    if not bar then return end
    local r, g, b = ResolveUnitHealthColorSafe(unitToken, useClassColor)
    bar:SetStatusBarColor(r, g, b)
    if bar.AnimatedLossBar and bar.AnimatedLossBar.SetStatusBarColor then
      bar.AnimatedLossBar:SetStatusBarColor(r, g, b)
    end
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if tex then
      tex:SetAlpha(1)
      tex:SetVertexColor(r, g, b, 1)
    end
  end
  local function ApplyUnitFrameClassColorsOnly()
    local prof = addonTable.GetProfile and addonTable.GetProfile()
    if not prof or not prof.ufClassColor then return end
    if prof.enableUnitFrameCustomization == false then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local objs = GetPlayerObjects()
    if objs and objs.healthBar then
      ApplyHealthColorSafe(objs.healthBar, "player", true)
    end
    local tMain = TargetFrame and TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
    local targetBar = tMain and tMain.HealthBarsContainer and tMain.HealthBarsContainer.HealthBar
    if targetBar then
      ApplyHealthColorSafe(targetBar, "target", true)
    end
    local fMain = FocusFrame and FocusFrame.TargetFrameContent and FocusFrame.TargetFrameContent.TargetFrameContentMain
    local focusBar = fMain and fMain.HealthBarsContainer and fMain.HealthBarsContainer.HealthBar
    if focusBar then
      ApplyHealthColorSafe(focusBar, "focus", true)
    end
  end
  addonTable.ApplyUnitFrameClassColorsOnly = ApplyUnitFrameClassColorsOnly
  if InCombatLockdown and InCombatLockdown() then
    State.unitFrameCustomizationPending = true
    return
  end
  State.unitFrameCustomizationPending = false
  local player = GetPlayerObjects()
  local healthBar = player.healthBar
  local powerBar = player.powerBar
  if not healthBar or not powerBar then return end
  addonTable.ApplyUnitFrameStatusTexts = nil
  local function ApplyBorderTextureColor(frameObj, r, g, b)
    if not frameObj then return end
    local texSeen = {}
    local function applyTex(tex)
      if not tex or not tex.SetVertexColor then return end
      if texSeen[tex] then return end
      texSeen[tex] = true
      tex:SetVertexColor(r or 1, g or 1, b or 1, 1)
    end

    local playerContainer = frameObj.PlayerFrameContainer
    local targetContainer = frameObj.TargetFrameContainer

    applyTex(playerContainer and playerContainer.FrameTexture)
    applyTex(playerContainer and playerContainer.AlternatePowerFrameTexture)
    applyTex(targetContainer and targetContainer.FrameTexture)
    applyTex(frameObj.FrameTexture)
  end
  if ufEnabled then
    local useCustomBorder = profile.useCustomBorderColor
    local borderR = useCustomBorder and (profile.ufCustomBorderColorR or 0) or 1
    local borderG = useCustomBorder and (profile.ufCustomBorderColorG or 0) or 1
    local borderB = useCustomBorder and (profile.ufCustomBorderColorB or 0) or 1
    ApplyBorderTextureColor(PlayerFrame, borderR, borderG, borderB)
    ApplyBorderTextureColor(TargetFrame, borderR, borderG, borderB)
    ApplyBorderTextureColor(FocusFrame, borderR, borderG, borderB)
    local tMain = TargetFrame and TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
    if tMain and tMain.ReputationColor and tMain.ReputationColor.SetVertexColor then
      tMain.ReputationColor:SetVertexColor(borderR, borderG, borderB, 1)
    end
    local fMain = FocusFrame and FocusFrame.TargetFrameContent and FocusFrame.TargetFrameContent.TargetFrameContentMain
    if fMain and fMain.ReputationColor and fMain.ReputationColor.SetVertexColor then
      fMain.ReputationColor:SetVertexColor(borderR, borderG, borderB, 1)
    end
    ApplyBorderTextureColor(_G.TargetFrameToT, borderR, borderG, borderB)
    ApplyBorderTextureColor(_G.TargetFrameToTFrame, borderR, borderG, borderB)
    ApplyBorderTextureColor(_G.FocusFrameToT, borderR, borderG, borderB)
    ApplyBorderTextureColor(_G.PetFrame, borderR, borderG, borderB)
    local petFrameTex = _G["PetFrameTexture"]
    if petFrameTex and petFrameTex.SetVertexColor then
      petFrameTex:SetVertexColor(borderR, borderG, borderB, 1)
    end
    for i = 1, 5 do
      ApplyBorderTextureColor(_G["Boss" .. i .. "TargetFrame"], borderR, borderG, borderB)
    end
  end
  State.playerFrameOriginal = State.playerFrameOriginal or {}
  local orig = State.playerFrameOriginal
  local useCustomTex = ufEnabled and profile.ufUseCustomTextures == true
  local selectedTexture = useCustomTex and (profile.ufHealthTexture or "lsm:Clean") or "blizzard"
  local selectedTexturePath = addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(selectedTexture) or texturePaths[selectedTexture] or texturePaths.blizzard
  local function CollectPoints(frameObj)
    local points = {}
    if not frameObj or not frameObj.GetNumPoints or not frameObj.GetPoint then return points end
    local n = frameObj:GetNumPoints() or 0
    for i = 1, n do
      local p, rel, rp, x, y = frameObj:GetPoint(i)
      if type(p) == "string" then
        points[#points + 1] = {p, rel, rp, x, y}
      end
    end
    return points
  end
  local function RestorePoints(frameObj, points)
    if not frameObj or not frameObj.ClearAllPoints or not frameObj.SetPoint then return end
    frameObj:ClearAllPoints()
    if type(points) ~= "table" or #points == 0 then return end
    for i = 1, #points do
      local pt = points[i]
      if pt and type(pt[1]) == "string" then
        pcall(frameObj.SetPoint, frameObj, pt[1], pt[2], pt[3], pt[4], pt[5])
      end
    end
  end
  local function ResolveBossPowerColor(unitToken)
    local pType, pToken = UnitPowerType(unitToken)
    local color
    if pToken and PowerBarColor and PowerBarColor[pToken] then
      color = PowerBarColor[pToken]
    elseif pType and PowerBarColor and PowerBarColor[pType] then
      color = PowerBarColor[pType]
    end
    if type(color) == "table" then
      return color.r or 0.35, color.g or 0.35, color.b or 0.95
    end
    return 0.35, 0.35, 0.95
  end
  local function ApplyBossFrameCustomization()
    CCM_ApplyCustomBossFrames(profile, ufEnabled, useCustomTex, selectedTexturePath)
    if false then
    local enabled = ufEnabled and profile.ufBossFramesEnabled == true
    orig.bossFrames = orig.bossFrames or {}
    local anchor = profile.ufBossFrameAnchor or "TOPRIGHT"
    local x = tonumber(profile.ufBossFrameX) or -245
    local y = tonumber(profile.ufBossFrameY) or -280
    local scale = tonumber(profile.ufBossFrameScale) or 1
    local spacing = tonumber(profile.ufBossFrameSpacing) or 36
    local width = tonumber(profile.ufBossFrameWidth) or 168
    local healthH = tonumber(profile.ufBossFrameHealthHeight) or 20
    local powerH = tonumber(profile.ufBossFramePowerHeight) or 8
    local showLevel = profile.ufBossFrameShowLevel ~= false
    local hidePortrait = profile.ufBossFrameHidePortrait == true
    local useBorder = profile.ufBossFrameUseBorder == true
    local blizzCastTextScale = tonumber(profile.ufBossCastbarTextScale) or 1
    local bossBarTexturePath = (useCustomTex and type(selectedTexturePath) == "string" and selectedTexturePath ~= "") and selectedTexturePath or "Interface\\Buttons\\WHITE8x8"
    local borderOn = profile.useCustomBorderColor == true
    local borderR = borderOn and (profile.ufCustomBorderColorR or 0.22) or 0.22
    local borderG = borderOn and (profile.ufCustomBorderColorG or 0.22) or 0.22
    local borderB = borderOn and (profile.ufCustomBorderColorB or 0.26) or 0.26
    local useNameColor = profile.ufUseCustomNameColor == true
    local nameR = useNameColor and (profile.ufNameColorR or 1) or 1
    local nameG = useNameColor and (profile.ufNameColorG or 1) or 1
    local nameB = useNameColor and (profile.ufNameColorB or 1) or 1
    local list = {}
    local function ResolveBossSpellBar(frameObj, index)
      if not frameObj then return nil end
      return frameObj.spellbar or frameObj.castBar or frameObj.CastingBarFrame or _G["Boss" .. tostring(index or "") .. "TargetFrameSpellBar"]
    end
    local function SaveAndHideVisual(st, obj)
      if not st or not obj then return end
      st.hiddenDefaults = st.hiddenDefaults or {}
      local rec = st.hiddenDefaults[obj]
      if not rec then
        rec = {
          alpha = obj.GetAlpha and obj:GetAlpha() or nil,
          shown = obj.IsShown and obj:IsShown() or nil,
        }
        st.hiddenDefaults[obj] = rec
      end
      if obj.SetAlpha then obj:SetAlpha(0) end
      if obj.Hide then obj:Hide() end
      if obj.HookScript and not rec.hookInstalled then
        rec.hookInstalled = true
        obj:HookScript("OnShow", function(self)
          local p = addonTable.GetProfile and addonTable.GetProfile()
          if not p or p.enableUnitFrameCustomization == false or p.ufBossFramesEnabled ~= true then return end
          if self.SetAlpha then self:SetAlpha(0) end
          if self.Hide then self:Hide() end
        end)
      end
    end
    local function HideAllRegions(st, frameObj)
      if not st or not frameObj or not frameObj.GetRegions then return end
      local regions = {frameObj:GetRegions()}
      for i = 1, #regions do
        local reg = regions[i]
        if reg then
          SaveAndHideVisual(st, reg)
        end
      end
    end
    local function RestoreHiddenVisuals(st)
      if not st or type(st.hiddenDefaults) ~= "table" then return end
      for obj, rec in pairs(st.hiddenDefaults) do
        if obj and rec then
          if obj.SetAlpha and rec.alpha ~= nil then obj:SetAlpha(rec.alpha) end
          if rec.shown == true and obj.Show then
            obj:Show()
          elseif rec.shown == false and obj.Hide then
            obj:Hide()
          end
        end
      end
    end
    local ApplyBossHealthColor
    local function UpdateCustomBossCastbar(st, unitToken)
      if not st or not st.castHolder or not st.castBar then return end
      local bar = st.castBar
      local bossIdx = tonumber(unitToken:match("^boss(%d+)$"))
      local csTable = State.customBoss and State.customBoss._castState
      local cs = bossIdx and csTable and csTable[bossIdx]
      if not cs then
        st.castHolder:Hide()
        return
      end
      local showing = cs.casting or cs.channeling
      if showing then
        local durationObject = nil
        if cs.casting and UnitCastingDuration then
          local okDur, durObj = pcall(UnitCastingDuration, unitToken)
          if okDur then durationObject = durObj end
        elseif cs.channeling and UnitChannelDuration then
          local okDur, durObj = pcall(UnitChannelDuration, unitToken)
          if okDur then durationObject = durObj end
        end
        if durationObject and bar.SetTimerDuration then
          local interp = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or nil
          local dir = cs.casting and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime
          pcall(bar.SetTimerDuration, bar, durationObject, interp, dir)
        end
        if st.castTime and durationObject then
          local okRem, rem = pcall(function() return durationObject:GetRemainingDuration() end)
          if okRem and rem ~= nil then st.castTime:SetText(string.format("%.1f", rem)) end
        end
        if cs.notInterruptible then
          bar:SetStatusBarColor(0.50, 0.50, 0.50, 1)
        else
          bar:SetStatusBarColor(cs.casting and 1.00 or 0.34, cs.casting and 0.72 or 0.58, cs.casting and 0.12 or 1.00, 1)
        end
        if cs.spellName and st.castText then st.castText:SetText(cs.spellName) end
      end
      st.castHolder:SetShown(showing)
    end
    local function UpdateCustomBossResourceBars(st, unitToken)
      if not st or not st.customHP or not st.customMP then return end
      local function IsSecret(v)
        return issecretvalue and issecretvalue(v) or false
      end
      local function SafeNum(v)
        if type(v) ~= "number" then return nil end
        if IsSecret(v) then return nil end
        return v
      end
      local hpMaxRaw = UnitHealthMax(unitToken)
      local hpCurRaw = UnitHealth(unitToken)
      if IsSecret(hpMaxRaw) or IsSecret(hpCurRaw) then
        if hpMaxRaw ~= nil then pcall(st.customHP.SetMinMaxValues, st.customHP, 0, hpMaxRaw) end
        if hpCurRaw ~= nil then pcall(st.customHP.SetValue, st.customHP, hpCurRaw) end
      else
        local hpMax = SafeNum(hpMaxRaw) or 0
        local hpCur = SafeNum(hpCurRaw) or 0
        if hpMax <= 0 then hpMax = 1 end
        if hpCur < 0 then hpCur = 0 end
        if hpCur > hpMax then hpCur = hpMax end
        st.customHP:SetMinMaxValues(0, hpMax)
        st.customHP:SetValue(hpCur)
      end
      ApplyBossHealthColor(st.customHP, unitToken)
      local pMaxRaw = UnitPowerMax(unitToken)
      local pCurRaw = UnitPower(unitToken)
      if IsSecret(pMaxRaw) or IsSecret(pCurRaw) then
        if pMaxRaw ~= nil then pcall(st.customMP.SetMinMaxValues, st.customMP, 0, pMaxRaw) end
        if pCurRaw ~= nil then pcall(st.customMP.SetValue, st.customMP, pCurRaw) end
      else
        local pMax = SafeNum(pMaxRaw) or 0
        local pCur = SafeNum(pCurRaw) or 0
        if pMax <= 0 then pMax = 1 end
        if pCur < 0 then pCur = 0 end
        if pCur > pMax then pCur = pMax end
        st.customMP:SetMinMaxValues(0, pMax)
        st.customMP:SetValue(pCur)
      end
      local pr, pg, pb = ResolveBossPowerColor(unitToken)
      st.customMP:SetStatusBarColor(pr, pg, pb, 1)
    end
    ApplyBossHealthColor = function(bar, unitToken)
      if not bar then return end
      local r, g, b
      if profile.ufClassColor == true and unitToken and UnitExists(unitToken) and UnitIsPlayer(unitToken) then
        local _, classToken = UnitClass(unitToken)
        local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
        if classColor then
          r, g, b = classColor.r, classColor.g, classColor.b
        end
      end
      if not r then
        if unitToken and UnitExists(unitToken) then
          if UnitIsFriend("player", unitToken) then
            r, g, b = 0, 1, 0
          elseif UnitCanAttack("player", unitToken) then
            r, g, b = 1, 0.1, 0.1
          else
            r, g, b = 1, 1, 0
          end
        else
          r, g, b = 1, 0.1, 0.1
        end
      end
      bar:SetStatusBarColor(r, g, b, 1)
      local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
      if tex then tex:SetVertexColor(r, g, b, 1) end
    end
    for i = 1, 8 do
      local frame = _G["Boss" .. i .. "TargetFrame"]
      if frame then
        list[#list + 1] = frame
      end
    end
    for idx = 1, #list do
      local frame = list[idx]
      local st = orig.bossFrames[idx] or {}
      orig.bossFrames[idx] = st
      local main = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
      local hc = main and main.HealthBarsContainer
      local hasHealthContainer = hc and hc.ClearAllPoints and hc.SetPoint
      local hp = (hc and hc.HealthBar) or frame.healthbar
      local mp = (main and main.ManaBar) or frame.manabar
      local portrait = (main and main.Portrait) or frame.portrait
      local nameFS = (main and main.Name) or frame.name
      local levelFS = (main and main.LevelText) or frame.level
      local frameTexture = frame.TargetFrameContainer and frame.TargetFrameContainer.FrameTexture
      local frameContainer = frame.TargetFrameContainer
      local spellbar = ResolveBossSpellBar(frame, idx)
      if not st.saved then
        st.saved = true
        st.frameScale = frame.GetScale and frame:GetScale() or nil
        st.frameWidth = frame.GetWidth and frame:GetWidth() or nil
        st.frameHeight = frame.GetHeight and frame:GetHeight() or nil
        st.framePoints = CollectPoints(frame)
        if hp then
          st.hpHeight = hp.GetHeight and hp:GetHeight() or nil
          st.hpPoints = CollectPoints(hp)
          st.hpTexture = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
        end
        if hasHealthContainer then
          st.hcPoints = CollectPoints(hc)
          st.hcHeight = hc.GetHeight and hc:GetHeight() or nil
        end
        if mp then
          st.mpHeight = mp.GetHeight and mp:GetHeight() or nil
          st.mpPoints = CollectPoints(mp)
          st.mpTexture = mp.GetStatusBarTexture and mp:GetStatusBarTexture()
        end
        if portrait then
          st.portraitWidth = portrait.GetWidth and portrait:GetWidth() or nil
          st.portraitHeight = portrait.GetHeight and portrait:GetHeight() or nil
          st.portraitShown = portrait.IsShown and portrait:IsShown() or true
        end
        if nameFS then
          st.namePoints = CollectPoints(nameFS)
          if nameFS.GetFont then
            st.nameFont, st.nameFontSize, st.nameFontFlags = nameFS:GetFont()
          end
        end
        if levelFS then
          st.levelPoints = CollectPoints(levelFS)
          st.levelShown = levelFS.IsShown and levelFS:IsShown() or nil
          if levelFS.GetFont then
            st.levelFont, st.levelFontSize, st.levelFontFlags = levelFS:GetFont()
          end
        end
        if frameTexture then
          st.frameTextureAlpha = frameTexture.GetAlpha and frameTexture:GetAlpha() or nil
        end
        if spellbar then
          st.spellbarShown = spellbar.IsShown and spellbar:IsShown() or nil
          st.spellbarAlpha = spellbar.GetAlpha and spellbar:GetAlpha() or nil
          if not st.spellbarHideHooked and spellbar.HookScript then
            st.spellbarHideHooked = true
            spellbar:HookScript("OnShow", function(sb)
              local p = addonTable.GetProfile and addonTable.GetProfile()
              if not p or p.enableUnitFrameCustomization == false or p.ufBossFramesEnabled ~= true then return end
              if sb.SetAlpha then sb:SetAlpha(0) end
              if sb.Hide then sb:Hide() end
            end)
          end
        end
      end
      if enabled then
        frame:ClearAllPoints()
        if idx == 1 then
          frame:SetPoint(anchor, UIParent, anchor, x, y)
        else
          local prev = list[idx - 1]
          if string.find(anchor, "BOTTOM") then
            frame:SetPoint("BOTTOM", prev, "TOP", 0, spacing)
          else
            frame:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
          end
        end
        if frame.SetScale then frame:SetScale(scale) end
        if frame.SetWidth then frame:SetWidth(width + 46) end
        if frame.SetHeight then frame:SetHeight(healthH + powerH + 14) end
        if frameTexture and frameTexture.SetAlpha then
          frameTexture:SetAlpha(0)
        end
        -- Remove Blizzard default visuals (border/flash/status/castbar layers)
        SaveAndHideVisual(st, frameTexture)
        SaveAndHideVisual(st, frameContainer and frameContainer.Flash)
        SaveAndHideVisual(st, frameContainer and frameContainer.FrameFlash)
        SaveAndHideVisual(st, main and main.Flash)
        SaveAndHideVisual(st, main and main.StatusTexture)
        SaveAndHideVisual(st, main and main.AttentionIndicator)
        SaveAndHideVisual(st, portrait and portrait.BossPortraitFrameTexture)
        SaveAndHideVisual(st, hp and (hp.Border or hp.border))
        SaveAndHideVisual(st, mp and (mp.Border or mp.border))
        SaveAndHideVisual(st, spellbar)
        SaveAndHideVisual(st, spellbar and spellbar.Border)
        SaveAndHideVisual(st, spellbar and spellbar.Background)
        SaveAndHideVisual(st, spellbar and spellbar.Icon)
        SaveAndHideVisual(st, spellbar and spellbar.Spark)
        SaveAndHideVisual(st, spellbar and spellbar.Flash)
        SaveAndHideVisual(st, spellbar and spellbar.Shield)
        SaveAndHideVisual(st, spellbar and spellbar.SafeZone)
        SaveAndHideVisual(st, spellbar and spellbar.Text)
        SaveAndHideVisual(st, spellbar and spellbar.Time)
        SaveAndHideVisual(st, nameFS)
        SaveAndHideVisual(st, levelFS)
        HideAllRegions(st, frameContainer)
        HideAllRegions(st, main)
        HideAllRegions(st, hc)
        HideAllRegions(st, hp)
        HideAllRegions(st, mp)
        HideAllRegions(st, spellbar)
        if not st.skin then
          st.skin = CreateFrame("Frame", nil, frame, "BackdropTemplate")
          st.skin:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
          })
        end
        if st.skin then
          st.skin:ClearAllPoints()
          st.skin:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
          st.skin:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
          st.skin:SetBackdropColor(0, 0, 0, 0)
          st.skin:SetBackdropBorderColor(borderR, borderG, borderB, useBorder and 1 or 0)
          st.skin:SetFrameStrata("BACKGROUND")
          st.skin:SetFrameLevel(1)
          st.skin:Show()
        end
        local hpLeftInset = hidePortrait and 5 or 43
        if portrait and portrait.SetSize then
          portrait:SetSize(healthH + powerH + 4, healthH + powerH + 4)
          portrait:ClearAllPoints()
          portrait:SetPoint("LEFT", frame, "LEFT", 3, 0)
          portrait:SetShown(not hidePortrait)
        end
        -- Hide Blizzard resource bars completely (keep only as data source)
        SaveAndHideVisual(st, hc)
        SaveAndHideVisual(st, hp)
        SaveAndHideVisual(st, hp and (hp.Background or hp.background))
        SaveAndHideVisual(st, hp and hp.AnimatedLossBar)
        SaveAndHideVisual(st, mp)
        SaveAndHideVisual(st, mp and (mp.Background or mp.background))
        if not st.customBarsHolder then
          st.customBarsHolder = CreateFrame("Frame", nil, frame)
          st.customBarsHolder:SetFrameStrata("MEDIUM")
          st.customBarsHolder:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 1)
          st.customHPBg = CreateFrame("StatusBar", nil, st.customBarsHolder)
          st.customHPBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
          st.customHPBg:SetStatusBarColor(0, 0, 0, 0.45)
          st.customHP = CreateFrame("StatusBar", nil, st.customBarsHolder)
          st.customHP:SetStatusBarTexture(bossBarTexturePath)
          st.customMPBg = CreateFrame("StatusBar", nil, st.customBarsHolder)
          st.customMPBg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
          st.customMPBg:SetStatusBarColor(0, 0, 0, 0.45)
          st.customMP = CreateFrame("StatusBar", nil, st.customBarsHolder)
          st.customMP:SetStatusBarTexture(bossBarTexturePath)
        end
        if st.customBarsHolder and st.customHP and st.customMP and st.customHPBg and st.customMPBg then
          st.customBarsHolder:ClearAllPoints()
          st.customBarsHolder:SetPoint("TOPLEFT", frame, "TOPLEFT", hpLeftInset, -4)
          st.customBarsHolder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -4)
          st.customBarsHolder:SetHeight(healthH + powerH + 2)
          pcall(st.customHP.SetStatusBarTexture, st.customHP, bossBarTexturePath)
          pcall(st.customMP.SetStatusBarTexture, st.customMP, bossBarTexturePath)
          st.customHPBg:ClearAllPoints()
          st.customHPBg:SetPoint("TOPLEFT", st.customBarsHolder, "TOPLEFT", 0, 0)
          st.customHPBg:SetPoint("TOPRIGHT", st.customBarsHolder, "TOPRIGHT", 0, 0)
          st.customHPBg:SetHeight(healthH)
          st.customHPBg:SetMinMaxValues(0, 1)
          st.customHPBg:SetValue(1)
          st.customHP:ClearAllPoints()
          st.customHP:SetPoint("TOPLEFT", st.customBarsHolder, "TOPLEFT", 0, 0)
          st.customHP:SetPoint("TOPRIGHT", st.customBarsHolder, "TOPRIGHT", 0, 0)
          st.customHP:SetHeight(healthH)
          st.customMPBg:ClearAllPoints()
          st.customMPBg:SetPoint("TOPLEFT", st.customHP, "BOTTOMLEFT", 0, -2)
          st.customMPBg:SetPoint("TOPRIGHT", st.customHP, "BOTTOMRIGHT", 0, -2)
          st.customMPBg:SetHeight(powerH)
          st.customMPBg:SetMinMaxValues(0, 1)
          st.customMPBg:SetValue(1)
          st.customMP:ClearAllPoints()
          st.customMP:SetPoint("TOPLEFT", st.customHP, "BOTTOMLEFT", 0, -2)
          st.customMP:SetPoint("TOPRIGHT", st.customHP, "BOTTOMRIGHT", 0, -2)
          st.customMP:SetHeight(powerH)
          st._resAccum = st._resAccum or 0
          st.customBarsHolder:SetScript("OnUpdate", function(_, elapsed)
            st._resAccum = st._resAccum + (elapsed or 0)
            if st._resAccum < 0.05 then return end
            st._resAccum = 0
            UpdateCustomBossResourceBars(st, "boss" .. idx)
          end)
          UpdateCustomBossResourceBars(st, "boss" .. idx)
          st.customBarsHolder:Show()
        end
        if not st.customName then
          st.customName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
          st.customName:SetJustifyH("LEFT")
        end
        if not st.customLevel then
          st.customLevel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
          st.customLevel:SetJustifyH("RIGHT")
        end
        if st.customName and st.customHP then
          st.customName:ClearAllPoints()
          st.customName:SetPoint("LEFT", st.customHP, "LEFT", 4, 0)
          st.customName:SetTextColor(nameR, nameG, nameB)
        end
        if st.customLevel and st.customHP then
          st.customLevel:ClearAllPoints()
          st.customLevel:SetPoint("RIGHT", st.customHP, "RIGHT", -4, 0)
          st.customLevel:SetTextColor(nameR, nameG, nameB)
          st.customLevel:SetShown(showLevel)
        end
        if not st.castHolder then
          st.castHolder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
          st.castHolder:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
          st.castHolder:SetBackdropColor(0.06, 0.06, 0.08, 0.92)
          st.castHolder:SetBackdropBorderColor(borderR, borderG, borderB, 1)
          st.castHolder:SetFrameStrata("MEDIUM")
          st.castHolder:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 2)
          st.castBar = CreateFrame("StatusBar", nil, st.castHolder)
          st.castBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
          st.castBar:SetMinMaxValues(0, 1)
          st.castBar:SetValue(0.5)
          st.castBg = st.castBar:CreateTexture(nil, "BACKGROUND")
          st.castBg:SetAllPoints(st.castBar)
          st.castBg:SetTexture("Interface\\Buttons\\WHITE8x8")
          st.castBg:SetVertexColor(0, 0, 0, 0.45)
          st.castText = st.castHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
          st.castText:SetPoint("LEFT", st.castBar, "LEFT", 4, 0)
          st.castText:SetJustifyH("LEFT")
          st.castTime = st.castHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
          st.castTime:SetPoint("RIGHT", st.castBar, "RIGHT", -4, 0)
          st.castTime:SetJustifyH("RIGHT")
        end
        if st.castHolder and st.castBar then
          local castLeftInset = hidePortrait and 5 or 43
          st.castHolder:ClearAllPoints()
          st.castHolder:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", castLeftInset, -2)
          st.castHolder:SetSize(width - 2, 12)
          st.castBar:ClearAllPoints()
          st.castBar:SetPoint("TOPLEFT", st.castHolder, "TOPLEFT", 1, -1)
          st.castBar:SetPoint("BOTTOMRIGHT", st.castHolder, "BOTTOMRIGHT", -1, 1)
          pcall(st.castBar.SetStatusBarTexture, st.castBar, bossBarTexturePath)
          local blzCastFS = math.max(6, math.floor(10 * blizzCastTextScale + 0.5))
          if st.castText and st.castText.SetFont then
            pcall(st.castText.SetFont, st.castText, addonTable.GetGlobalFont and select(1, addonTable.GetGlobalFont()) or "Fonts\\FRIZQT__.TTF", blzCastFS, addonTable.GetGlobalFont and select(2, addonTable.GetGlobalFont()) or "")
          end
          if st.castTime and st.castTime.SetFont then
            pcall(st.castTime.SetFont, st.castTime, addonTable.GetGlobalFont and select(1, addonTable.GetGlobalFont()) or "Fonts\\FRIZQT__.TTF", blzCastFS, addonTable.GetGlobalFont and select(2, addonTable.GetGlobalFont()) or "")
          end
          if st.customName and st.customName.SetFont then
            pcall(st.customName.SetFont, st.customName, addonTable.GetGlobalFont and select(1, addonTable.GetGlobalFont()) or "Fonts\\FRIZQT__.TTF", 11, addonTable.GetGlobalFont and select(2, addonTable.GetGlobalFont()) or "")
          end
          if st.customLevel and st.customLevel.SetFont then
            pcall(st.customLevel.SetFont, st.customLevel, addonTable.GetGlobalFont and select(1, addonTable.GetGlobalFont()) or "Fonts\\FRIZQT__.TTF", 10, addonTable.GetGlobalFont and select(2, addonTable.GetGlobalFont()) or "")
          end
          st.castHolder:SetBackdropColor(0, 0, 0, 0)
          st.castHolder:SetBackdropBorderColor(borderR, borderG, borderB, useBorder and 1 or 0)
          st._castAccum = st._castAccum or 0
          if not st._castUpdateFrame then
            st._castUpdateFrame = CreateFrame("Frame")
          end
          st._castUpdateFrame:SetScript("OnUpdate", function(_, elapsed)
            st._castAccum = st._castAccum + (elapsed or 0)
            if st._castAccum < 0.03 then return end
            st._castAccum = 0
            UpdateCustomBossCastbar(st, "boss" .. idx)
          end)
          st._castUpdateFrame:Show()
          if st.customName then
            local n = UnitName("boss" .. idx)
            st.customName:SetText(n or ("Boss " .. idx))
            st.customName:Show()
          end
          if st.customLevel then
            local lv = UnitLevel("boss" .. idx)
            if type(lv) == "number" and lv > 0 then
              st.customLevel:SetText(lv)
            else
              st.customLevel:SetText("??")
            end
            st.customLevel:SetShown(showLevel)
          end
          UpdateCustomBossCastbar(st, "boss" .. idx)
        end
      else
        if st.skin and st.skin.Hide then st.skin:Hide() end
        if st.customBarsHolder then
          st.customBarsHolder:SetScript("OnUpdate", nil)
          st.customBarsHolder:Hide()
        end
        if st._castUpdateFrame then
          st._castUpdateFrame:SetScript("OnUpdate", nil)
          st._castUpdateFrame:Hide()
        end
        if st.castHolder then
          st.castHolder:Hide()
        end
        if st.customName then st.customName:Hide() end
        if st.customLevel then st.customLevel:Hide() end
        RestoreHiddenVisuals(st)
        if spellbar then
          if st.spellbarAlpha ~= nil and spellbar.SetAlpha then spellbar:SetAlpha(st.spellbarAlpha) end
          if st.spellbarShown == true and spellbar.Show then spellbar:Show() end
        end
        if frameTexture and frameTexture.SetAlpha and st.frameTextureAlpha ~= nil then
          frameTexture:SetAlpha(st.frameTextureAlpha)
        end
        if frame.SetScale and st.frameScale then frame:SetScale(st.frameScale) end
        if frame.SetWidth and st.frameWidth then frame:SetWidth(st.frameWidth) end
        if frame.SetHeight and st.frameHeight then frame:SetHeight(st.frameHeight) end
        RestorePoints(frame, st.framePoints)
        if hasHealthContainer then
          if st.hcHeight and hc.SetHeight then hc:SetHeight(st.hcHeight) end
          RestorePoints(hc, st.hcPoints)
        end
        if hp then
          if st.hpHeight and hp.SetHeight then hp:SetHeight(st.hpHeight) end
          RestorePoints(hp, st.hpPoints)
          if st.hpTexture and hp.SetStatusBarTexture then pcall(hp.SetStatusBarTexture, hp, st.hpTexture) end
          local hpLoss = hp.AnimatedLossBar
          if hpLoss then
            if hpLoss.SetAlpha then hpLoss:SetAlpha(1) end
            if hpLoss.Show then hpLoss:Show() end
          end
        end
        if mp then
          if st.mpHeight and mp.SetHeight then mp:SetHeight(st.mpHeight) end
          RestorePoints(mp, st.mpPoints)
          if st.mpTexture and mp.SetStatusBarTexture then pcall(mp.SetStatusBarTexture, mp, st.mpTexture) end
        end
        if portrait and portrait.SetSize and st.portraitWidth and st.portraitHeight then
          portrait:SetSize(st.portraitWidth, st.portraitHeight)
          if st.portraitShown ~= nil then
            portrait:SetShown(st.portraitShown)
          else
            portrait:Show()
          end
        end
        if nameFS then
          RestorePoints(nameFS, st.namePoints)
          if st.nameFont and st.nameFontSize and nameFS.SetFont then
            pcall(nameFS.SetFont, nameFS, st.nameFont, st.nameFontSize, st.nameFontFlags or "")
          end
        end
        if levelFS then
          RestorePoints(levelFS, st.levelPoints)
          if st.levelShown ~= nil then levelFS:SetShown(st.levelShown) end
          if st.levelFont and st.levelFontSize and levelFS.SetFont then
            pcall(levelFS.SetFont, levelFS, st.levelFont, st.levelFontSize, st.levelFontFlags or "")
          end
        end
      end
    end
    end
  end
  local function ResolveUnitHealthColor(unitToken, useClassColor)
    local r, g, b
    if useClassColor and unitToken and UnitExists(unitToken) and UnitIsPlayer(unitToken) then
      local _, classToken = UnitClass(unitToken)
      local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
      if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
      end
    end
    if not r then
      if unitToken == "player" then
        r, g, b = 0, 1, 0
      elseif unitToken and UnitExists(unitToken) then
        if UnitIsFriend("player", unitToken) then
          r, g, b = 0, 1, 0
        elseif UnitCanAttack("player", unitToken) then
          r, g, b = 1, 0, 0
        else
          r, g, b = 1, 1, 0
        end
      end
    end
    if not r then
      r, g, b = 0, 1, 0
    end
    return r, g, b
  end
  local function ApplyUnitHealthColor(bar, unitToken, useClassColor)
    if not bar then return end
    local r, g, b = ResolveUnitHealthColor(unitToken, useClassColor)
    bar:SetStatusBarColor(r, g, b)
    if bar.AnimatedLossBar and bar.AnimatedLossBar.SetStatusBarColor then
      bar.AnimatedLossBar:SetStatusBarColor(r, g, b)
    end
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if tex then
      tex:SetAlpha(1)
      tex:SetVertexColor(r, g, b, 1)
    end
  end
  local function ApplyTargetFocusHealthCustomization(frame, unitToken)
    if not frame then return end
    local main = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
    local hContainer = main and main.HealthBarsContainer
    local hp = hContainer and hContainer.HealthBar
    if not hp then return end
    if useCustomTex then
      pcall(hp.SetStatusBarTexture, hp, selectedTexturePath)
      local st = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
      if st then
        st:ClearAllPoints()
        st:SetAllPoints(hp)
      end
    end
    ApplyUnitHealthColor(hp, unitToken, profile.ufClassColor == true)
  end
  if not orig.saved then
    orig.saved = true
    if healthBar.Background and healthBar.Background.GetAlpha then
      orig.healthBgAlpha = healthBar.Background:GetAlpha()
    end
  end
  local function ApplyPlayerHealthColor()
    if not healthBar or not ufEnabled then return end
    if useCustomTex then
      pcall(healthBar.SetStatusBarTexture, healthBar, selectedTexturePath)
      local statusTex = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
      if statusTex then
        statusTex:ClearAllPoints()
        statusTex:SetAllPoints(healthBar)
        statusTex:SetAlpha(1)
      end
    end
    ApplyUnitHealthColor(healthBar, "player", profile.ufClassColor == true)
    if healthBar.Background then
      healthBar.Background:SetAlpha(orig.healthBgAlpha or 1)
    end
  end
  if not orig.unitHealthColorHooked and type(hooksecurefunc) == "function" and type(UnitFrameHealthBar_Update) == "function" then
    orig.unitHealthColorHooked = true
    hooksecurefunc("UnitFrameHealthBar_Update", function(statusBar, unitToken)
      local p = addonTable.GetProfile and addonTable.GetProfile()
      if not p or not statusBar then return end
      if statusBar.unit then
        local u = statusBar.unit
        if u == "focustarget" or u == "targettarget" then return end
      end
      if p.enableUnitFrameCustomization == false then return end
      local useClassColor = p.ufClassColor == true
      local hasCustomTex = p.ufUseCustomTextures == true
      if not useClassColor and not hasCustomTex then return end
      local tMain = TargetFrame and TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
      local fMain = FocusFrame and FocusFrame.TargetFrameContent and FocusFrame.TargetFrameContent.TargetFrameContentMain
      local targetBar = tMain and tMain.HealthBarsContainer and tMain.HealthBarsContainer.HealthBar
      local focusBar = fMain and fMain.HealthBarsContainer and fMain.HealthBarsContainer.HealthBar
      if healthBar then ApplyUnitHealthColor(healthBar, "player", useClassColor) end
      if targetBar then ApplyUnitHealthColor(targetBar, "target", useClassColor) end
      if focusBar then ApplyUnitHealthColor(focusBar, "focus", useClassColor) end
    end)
  end
  
  local function CollectPlayerGlowTargets()
    local targets = {}
    local seen = {}
    local function add(obj)
      if obj and not seen[obj] then
        seen[obj] = true
        targets[#targets + 1] = obj
      end
    end
    local function addRestedRegions(frame)
      if not frame or not frame.GetRegions then return end
      for _, region in ipairs({frame:GetRegions()}) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.GetTexture then
          local tex = region:GetTexture()
          if type(tex) == "string" then
            local lower = string.lower(tex)
            if string.find(lower, "rest") or string.find(lower, "zzz") or string.find(lower, "sleep") then
              add(region)
            end
          elseif region.GetAtlas then
            local atlas = region:GetAtlas()
            if type(atlas) == "string" then
              local lowerAtlas = string.lower(atlas)
              if string.find(lowerAtlas, "rest") or string.find(lowerAtlas, "sleep") then
                add(region)
              end
            end
          end
        end
      end
    end
    local pf = PlayerFrame
    local pContainer = pf and pf.PlayerFrameContainer
    local content = pf and pf.PlayerFrameContent
    local main = content and content.PlayerFrameContentMain
    local contextual = content and content.PlayerFrameContentContextual
    add(main and main.StatusTexture)
    add(pContainer and pContainer.FrameFlash)
    add(main and main.Flash)
    add(main and main.AttentionIndicator)
    add(main and main.RestingIcon)
    add(contextual and contextual.RestingIcon)
    add(pf and pf.StatusTexture)
    add(pf and pf.RestingIcon)
    add(contextual and contextual.StatusTexture)
    add(main and main.HitIndicator)
    add(main and main.HitIndicator and main.HitIndicator.HitText)
    add(contextual and contextual.PlayerRestLoop)
    add(contextual and contextual.PlayerRestLoop and contextual.PlayerRestLoop.RestTexture)
    add(contextual and contextual.PlayerPortraitCornerIcon)
    addRestedRegions(main)
    addRestedRegions(contextual)
    addRestedRegions(pf)
    add(contextual and contextual.RoleIcon)
    if InsanityBarFrame then
      local pg = InsanityBarFrame.PortraitGlow
      add(pg and pg.Flipbook)
    end
    local function addUnitFrameGlows(unitFrame)
      if not unitFrame then return end
      local tContent = unitFrame.TargetFrameContent
      local tMain = tContent and tContent.TargetFrameContentMain
      local tContextual = tContent and tContent.TargetFrameContentContextual
      local tContainer = unitFrame.TargetFrameContainer
      add(tMain and tMain.StatusTexture)
      add(tMain and tMain.Flash)
      add(tMain and tMain.AttentionIndicator)
      add(tContextual and tContextual.StatusTexture)
      add(tContainer and tContainer.Flash)
      add(tContainer and tContainer.FrameFlash)
      addRestedRegions(tMain)
      addRestedRegions(tContextual)
      addRestedRegions(unitFrame)
      add(tContextual and tContextual.RoleIcon)
    end
    addUnitFrameGlows(TargetFrame)
    addUnitFrameGlows(FocusFrame)
    return targets
  end
  local function IsGlowSuppressionEnabled()
    local p = addonTable.GetProfile and addonTable.GetProfile()
    if not p or p.enableUnitFrameCustomization == false then return false end
    if p.ufDisableGlows == true then return true end
    if p.ufBigHBPlayerEnabled == true then return true end
    if p.ufBigHBTargetEnabled == true then return true end
    if p.ufBigHBFocusEnabled == true then return true end
    return false
  end
  local function ApplyGlowSuppression(enabled)
    orig.glowTargets = orig.glowTargets or CollectPlayerGlowTargets()
    orig.glowStates = orig.glowStates or {}
    for _, obj in ipairs(orig.glowTargets) do
      if not orig.glowStates[obj] then
        orig.glowStates[obj] = {
          alpha = obj.GetAlpha and obj:GetAlpha() or nil,
          shown = obj.IsShown and obj:IsShown() or nil,
        }
      end
      if enabled then
        if obj.HookScript then
          orig.glowHideHooked = orig.glowHideHooked or {}
          if not orig.glowHideHooked[obj] then
            obj:HookScript("OnShow", function(self)
              if IsGlowSuppressionEnabled() then
                if self.SetAlpha then self:SetAlpha(0) end
                if self.Hide then self:Hide() end
              end
            end)
            orig.glowHideHooked[obj] = true
          end
        end
        if obj.Hide then obj:Hide() end
        if obj.SetAlpha then obj:SetAlpha(0) end
      else
        local st = orig.glowStates[obj]
        if st then
          if obj.SetAlpha and st.alpha ~= nil then obj:SetAlpha(st.alpha) end
          if obj.Show and st.shown == true then obj:Show() elseif obj.Hide and st.shown == false then obj:Hide() end
        end
      end
    end
    local frameFlash = PlayerFrame and PlayerFrame.PlayerFrameContainer and PlayerFrame.PlayerFrameContainer.FrameFlash
    if frameFlash and not orig.frameFlashHideHooked then
      frameFlash:HookScript("OnShow", function(self)
        if IsGlowSuppressionEnabled() then
          if self.SetAlpha then self:SetAlpha(0) end
          if self.Hide then self:Hide() end
        end
      end)
      orig.frameFlashHideHooked = true
    end
  end

  local function ApplyCombatTextSuppression(enabled)
    orig.combatTextCvars = orig.combatTextCvars or {}
    local cvars = {
      "floatingCombatTextCombatDamage",
      "floatingCombatTextCombatHealing",
    }
    for _, key in ipairs(cvars) do
      if orig.combatTextCvars[key] == nil then
        orig.combatTextCvars[key] = GetCVar and GetCVar(key)
      end
      if enabled then
        if SetCVar then SetCVar(key, "0") end
      else
        local prev = orig.combatTextCvars[key]
        if prev ~= nil and SetCVar then SetCVar(key, prev) end
      end
    end
    local hitIndicator = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator
    local hitText = hitIndicator and hitIndicator.HitText
    orig.combatTextFrames = orig.combatTextFrames or {}
    if hitIndicator and orig.combatTextFrames.hitIndicatorShown == nil and hitIndicator.IsShown then
      orig.combatTextFrames.hitIndicatorShown = hitIndicator:IsShown()
    end
    if hitText and orig.combatTextFrames.hitTextShown == nil and hitText.IsShown then
      orig.combatTextFrames.hitTextShown = hitText:IsShown()
    end
    if enabled then
      if hitText and hitText.Hide then hitText:Hide() end
      if hitIndicator and hitIndicator.Hide then hitIndicator:Hide() end
    else
      if hitText then
        if orig.combatTextFrames.hitTextShown then hitText:Show() elseif hitText.Hide then hitText:Hide() end
      end
      if hitIndicator then
        if orig.combatTextFrames.hitIndicatorShown then hitIndicator:Show() elseif hitIndicator.Hide then hitIndicator:Hide() end
      end
    end
  end

  local function ApplyTargetBuffSuppression(enabled)
    if not TargetFrame then return end
    if enabled then
      TargetFrame.maxBuffs = 0
      TargetFrame.maxDebuffs = 0
      for i = 1, 40 do
        local buff = _G["TargetFrameBuff" .. i]
        if buff and buff.Hide then buff:Hide() end
        local debuff = _G["TargetFrameDebuff" .. i]
        if debuff and debuff.Hide then debuff:Hide() end
      end
    else
      if TargetFrame.maxBuffs == 0 then TargetFrame.maxBuffs = nil end
      if TargetFrame.maxDebuffs == 0 then TargetFrame.maxDebuffs = nil end
    end
    if not orig.auraTargetHooked and type(hooksecurefunc) == "function" then
      orig.auraTargetHooked = true
      if type(TargetFrame.UpdateAuras) == "function" then
        hooksecurefunc(TargetFrame, "UpdateAuras", function()
          local p = addonTable.GetProfile and addonTable.GetProfile()
          if p and p.enableUnitFrameCustomization ~= false and p.disableTargetBuffs then
            for i = 1, 40 do
              local buff = _G["TargetFrameBuff" .. i]
              if buff and buff.Hide then buff:Hide() end
              local debuff = _G["TargetFrameDebuff" .. i]
              if debuff and debuff.Hide then debuff:Hide() end
            end
          end
        end)
      end
      if type(TargetFrame_UpdateAuras) == "function" then
        hooksecurefunc("TargetFrame_UpdateAuras", function(self)
          if self ~= TargetFrame then return end
          local p = addonTable.GetProfile and addonTable.GetProfile()
          if not p or p.enableUnitFrameCustomization == false or not p.disableTargetBuffs then return end
          for i = 1, 40 do
            local buff = _G["TargetFrameBuff" .. i]
            if buff and buff.Hide then buff:Hide() end
            local debuff = _G["TargetFrameDebuff" .. i]
            if debuff and debuff.Hide then debuff:Hide() end
          end
        end)
      end
    end
  end

  local function ApplyEliteTextureSuppression(enabled)
    local unitFrames = {
      {frame = TargetFrame, key = "targetBoss"},
      {frame = FocusFrame, key = "focusBoss"},
    }
    if not orig.bossTexHooked then orig.bossTexHooked = {} end
    if not orig.bossTexSaved then orig.bossTexSaved = {} end
    for _, uf in ipairs(unitFrames) do
      local container = uf.frame and uf.frame.TargetFrameContainer
      local tex = container and container.BossPortraitFrameTexture
      if tex then
        if not orig.bossTexSaved[uf.key] then
          orig.bossTexSaved[uf.key] = true
          orig.bossTexSaved[uf.key .. "Shown"] = tex.IsShown and tex:IsShown() or nil
        end
        if enabled then
          if tex.Hide then tex:Hide() end
          if not orig.bossTexHooked[uf.key] and type(hooksecurefunc) == "function" then
            orig.bossTexHooked[uf.key] = true
            hooksecurefunc(tex, "Show", function(self)
              local p = addonTable.GetProfile and addonTable.GetProfile()
              if p and p.enableUnitFrameCustomization ~= false and p.hideEliteTexture then self:Hide() end
            end)
          end
        else
          if orig.bossTexSaved[uf.key .. "Shown"] and tex.Show then tex:Show() end
        end
      end
    end
  end

  local function ApplyGroupIndicatorSuppression(enabled)
    local content = PlayerFrame and PlayerFrame.PlayerFrameContent
    local contextual = content and content.PlayerFrameContentContextual
    local groupIndicator = contextual and contextual.GroupIndicator
    if not groupIndicator then return end
    if not orig.groupIndicatorSaved then
      orig.groupIndicatorSaved = true
      orig.groupIndicatorShown = groupIndicator.IsShown and groupIndicator:IsShown() or nil
    end
    if enabled then
      if groupIndicator.Hide then groupIndicator:Hide() end
      if not orig.groupIndicatorHooked and type(hooksecurefunc) == "function" then
        orig.groupIndicatorHooked = true
        hooksecurefunc(groupIndicator, "Show", function(self)
          local p = addonTable.GetProfile and addonTable.GetProfile()
          if p and p.enableUnitFrameCustomization ~= false and p.ufHideGroupIndicator then self:Hide() end
        end)
      end
      local groupText = contextual.PlayerFrameGroupIndicatorText or _G["PlayerFrameGroupIndicatorText"]
      if groupText and groupText.Hide then groupText:Hide() end
    else
      if orig.groupIndicatorShown and groupIndicator.Show then groupIndicator:Show() end
    end
  end

  ApplyPlayerHealthColor()
  local disableGlows = ufEnabled and IsGlowSuppressionEnabled()
  if disableGlows then
    ApplyGlowSuppression(true)
  else
    ApplyGlowSuppression(false)
  end
  local disableCombatText = ufEnabled and profile.ufDisableCombatText == true
  if disableCombatText then
    ApplyCombatTextSuppression(true)
  else
    ApplyCombatTextSuppression(false)
  end
  local disableBuffs = ufEnabled and profile.disableTargetBuffs == true
  if disableBuffs then
    ApplyTargetBuffSuppression(true)
  else
    ApplyTargetBuffSuppression(false)
  end
  local hideElite = ufEnabled and profile.hideEliteTexture == true
  if hideElite then
    ApplyEliteTextureSuppression(true)
  else
    ApplyEliteTextureSuppression(false)
  end
  local hideGroupInd = ufEnabled and profile.ufHideGroupIndicator == true
  if hideGroupInd then
    ApplyGroupIndicatorSuppression(true)
  else
    ApplyGroupIndicatorSuppression(false)
  end
  if ufEnabled then
    ApplyTargetFocusHealthCustomization(TargetFrame, "target")
    ApplyTargetFocusHealthCustomization(FocusFrame, "focus")
  end
  State.ufBigHBOverlays = State.ufBigHBOverlays or {}
  local bigHBBorderR, bigHBBorderG, bigHBBorderB = 0, 0, 0
  if profile.useCustomBorderColor then
    bigHBBorderR = profile.ufCustomBorderColorR or 0
    bigHBBorderG = profile.ufCustomBorderColorG or 0
    bigHBBorderB = profile.ufCustomBorderColorB or 0
  end
  local function SetUFBigHBPlayerTextsHidden(hidden)
    State.ufBigHBPlayerTextState = State.ufBigHBPlayerTextState or {}
    local state = State.ufBigHBPlayerTextState
    local function applyFor(name)
      local fs = _G[name]
      if not fs then return end
      if not state[name] then
        state[name] = {
          shown = fs.IsShown and fs:IsShown() or nil,
          alpha = fs.GetAlpha and fs:GetAlpha() or nil,
        }
      end
      if hidden then
        if fs.SetAlpha then fs:SetAlpha(0) end
        if fs.Hide then fs:Hide() end
      else
        local st = state[name]
        if st then
          if fs.SetAlpha and st.alpha ~= nil then fs:SetAlpha(st.alpha) end
          if st.shown and fs.Show then fs:Show() elseif fs.Hide then fs:Hide() end
        end
      end
    end
    applyFor("PlayerName")
    applyFor("PlayerLevelText")
  end
  local function SetUFBigHBAuxPlayerTextsHidden(auxRootFrame, hidden)
    if not auxRootFrame then return end
    local stateRoot = State.ufBigHBPlayerAuxTextState or {}
    State.ufBigHBPlayerAuxTextState = stateRoot
    local seen = {}
    local candidates = {}
    local function add(fs)
      if not fs or seen[fs] then return end
      if not fs.GetObjectType or fs:GetObjectType() ~= "FontString" then return end
      seen[fs] = true
      candidates[#candidates + 1] = fs
    end
    add(auxRootFrame.Name)
    local pfc = auxRootFrame.PlayerFrameContent
    local main = pfc and pfc.PlayerFrameContentMain
    local ctx = pfc and pfc.PlayerFrameContentContextual
    add(main and main.Name)
    add(ctx and ctx.Name)
    for i = 1, #candidates do
      local fs = candidates[i]
      if fs ~= _G["PlayerName"] and fs ~= _G["PlayerLevelText"] then
        if not stateRoot[fs] then
          stateRoot[fs] = {
            shown = fs.IsShown and fs:IsShown() or nil,
            alpha = fs.GetAlpha and fs:GetAlpha() or nil,
          }
        end
        if hidden then
          if fs.SetAlpha then fs:SetAlpha(0) end
          if fs.Hide then fs:Hide() end
        else
          local st = stateRoot[fs]
          if st then
            if fs.SetAlpha and st.alpha ~= nil then fs:SetAlpha(st.alpha) end
            if st.shown and fs.Show then fs:Show() elseif fs.Hide then fs:Hide() end
          end
        end
      end
    end
  end
  local function HideUFBigHBOverlay(key)
    local o = State.ufBigHBOverlays and State.ufBigHBOverlays[key]
    if not o then return end
    if o.bgFrame then o.bgFrame:Hide() end
    if o.healthFrame then o.healthFrame:Hide() end
    if o.dmgAbsorbFrame then o.dmgAbsorbFrame:Hide() end
    if o.fullDmgAbsorbFrame then o.fullDmgAbsorbFrame:Hide() end
    if o.myHealPredFrame then o.myHealPredFrame:Hide() end
    if o.otherHealPredFrame then o.otherHealPredFrame:Hide() end
    if o.healAbsorbFrame then o.healAbsorbFrame:Hide() end
    if o.maskFixFrame then o.maskFixFrame:Hide() end
  end
  local function SetUFBaseHealthBarCovered(o, hp, covered, container, covRootFrame)
    if not o or not hp then return end
    local mask = container and container.HealthBarMask
    if not mask and hp.GetParent then
      local hpParent = hp:GetParent()
      if hpParent and hpParent.HealthBarMask then
        mask = hpParent.HealthBarMask
      end
    end
    local statusTex = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
    if o.baseHpAlpha == nil and hp.GetAlpha then
      o.baseHpAlpha = hp:GetAlpha()
    end
    if o.baseHpShown == nil and hp.IsShown then
      o.baseHpShown = hp:IsShown()
    end
    if statusTex and o.baseStatusAlpha == nil and statusTex.GetAlpha then
      o.baseStatusAlpha = statusTex:GetAlpha()
    end
    if statusTex and o.baseStatusShown == nil and statusTex.IsShown then
      o.baseStatusShown = statusTex:IsShown()
    end
    local bg = hp.Background
    if bg and o.baseBgAlpha == nil and bg.GetAlpha then
      o.baseBgAlpha = bg:GetAlpha()
    end
    if mask and o.baseMaskAlpha == nil and mask.GetAlpha then
      o.baseMaskAlpha = mask:GetAlpha()
    end
    if mask and o.baseMaskShown == nil and mask.IsShown then
      o.baseMaskShown = mask:IsShown()
    end
    if not o.baseHpVisualStates then
      o.baseHpVisualStates = {}
      local visuals = {
        hp.Background, hp.AnimatedLossBar, hp.MyHealPredictionBar, hp.OtherHealPredictionBar,
        hp.TotalAbsorbBar, hp.HealAbsorbBar, hp.OverAbsorbGlow, hp.OverHealAbsorbGlow,
      }
      for _, v in ipairs(visuals) do
        if v then
          o.baseHpVisualStates[v] = {
            alpha = v.GetAlpha and v:GetAlpha() or nil,
            shown = v.IsShown and v:IsShown() or nil,
          }
        end
      end
      if container and container.GetRegions then
        o.containerTextureStates = o.containerTextureStates or {}
        for _, region in ipairs({container:GetRegions()}) do
          if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            o.containerTextureStates[region] = {
              alpha = region.GetAlpha and region:GetAlpha() or nil,
              shown = region.IsShown and region:IsShown() or nil,
            }
          end
        end
      end
      local tempLoss = covRootFrame and covRootFrame.PlayerFrameTempMaxHealthLoss
      if tempLoss then
        o.tempLossState = {
          alpha = tempLoss.GetAlpha and tempLoss:GetAlpha() or nil,
          shown = tempLoss.IsShown and tempLoss:IsShown() or nil,
        }
      end
    end
    if covered then
      if hp.SetAlpha then hp:SetAlpha(0) end
      if statusTex and statusTex.SetAlpha then statusTex:SetAlpha(0) end
      if statusTex and statusTex.Show then statusTex:Show() end
      if bg and bg.SetAlpha then bg:SetAlpha(0) end
      if mask and mask.SetAlpha then mask:SetAlpha(0) end
      if mask and mask.Hide then mask:Hide() end
      if o.baseHpVisualStates then
        for frameObj in pairs(o.baseHpVisualStates) do
          if frameObj == hp.TotalAbsorbBar
             or frameObj == hp.MyHealPredictionBar or frameObj == hp.OtherHealPredictionBar
             or frameObj == hp.HealAbsorbBar then
            if frameObj.SetAlpha then frameObj:SetAlpha(0) end
            if frameObj.Show then frameObj:Show() end
          elseif frameObj == hp.OverAbsorbGlow or frameObj == hp.OverHealAbsorbGlow then
            if frameObj and frameObj.SetAlpha then frameObj:SetAlpha(0) end
          else
            if frameObj and frameObj.SetAlpha then frameObj:SetAlpha(0) end
            if frameObj and frameObj.Hide then frameObj:Hide() end
          end
        end
      end
      local tabsBar = hp.TotalAbsorbBar
      if tabsBar and tabsBar.Show then tabsBar:Show() end
      if o.containerTextureStates then
        for region in pairs(o.containerTextureStates) do
          if region and region.SetAlpha then region:SetAlpha(0) end
          if region and region.Hide then region:Hide() end
        end
      end
      local tempLoss = covRootFrame and covRootFrame.PlayerFrameTempMaxHealthLoss
      if tempLoss then
        if tempLoss.SetAlpha then tempLoss:SetAlpha(0) end
        if tempLoss.Hide then tempLoss:Hide() end
      end
    else
      if hp.SetAlpha then hp:SetAlpha(o.baseHpAlpha or 1) end
      if statusTex and statusTex.SetAlpha then statusTex:SetAlpha(o.baseStatusAlpha or 1) end
      if statusTex then
        if o.baseStatusShown and statusTex.Show then statusTex:Show() elseif statusTex.Hide then statusTex:Hide() end
      end
      if bg and bg.SetAlpha then bg:SetAlpha(o.baseBgAlpha or 1) end
      if mask and mask.SetAlpha then mask:SetAlpha(o.baseMaskAlpha or 1) end
      if mask then
        if o.baseMaskShown and mask.Show then mask:Show() elseif mask.Hide then mask:Hide() end
      end
      if o.baseHpVisualStates then
        for frameObj, st in pairs(o.baseHpVisualStates) do
          if frameObj and frameObj.SetAlpha and st and st.alpha ~= nil then frameObj:SetAlpha(st.alpha) end
          if frameObj and st then
            if st.shown and frameObj.Show then frameObj:Show() elseif frameObj.Hide then frameObj:Hide() end
          end
        end
      end
      if o.containerTextureStates then
        for region, st in pairs(o.containerTextureStates) do
          if region and region.SetAlpha and st and st.alpha ~= nil then region:SetAlpha(st.alpha) end
          if region and st then
            if st.shown and region.Show then region:Show() elseif region.Hide then region:Hide() end
          end
        end
      end
      local tempLoss = covRootFrame and covRootFrame.PlayerFrameTempMaxHealthLoss
      if tempLoss and o.tempLossState then
        if tempLoss.SetAlpha and o.tempLossState.alpha ~= nil then tempLoss:SetAlpha(o.tempLossState.alpha) end
        if o.tempLossState.shown and tempLoss.Show then tempLoss:Show() elseif tempLoss.Hide then tempLoss:Hide() end
      end
    end
  end
  local function SyncUFBigHBOverlayValue(o, hp)
    if not o or not o.healthFrame or not hp then return end
    local function IsSecret(v)
      return issecretvalue and issecretvalue(v) or false
    end
    local function SafeNumeric(v)
      if type(v) ~= "number" then return nil end
      if issecretvalue and issecretvalue(v) then return nil end
      return v
    end
    local minRaw, maxRaw, curRaw = nil, nil, nil
    if hp.GetMinMaxValues then
      minRaw, maxRaw = hp:GetMinMaxValues()
    end
    if hp.GetValue then
      curRaw = hp:GetValue()
    end
    local hasSecret = IsSecret(minRaw) or IsSecret(maxRaw) or IsSecret(curRaw)
    if hasSecret then
      if o.healthFrame.SetMinMaxValues and minRaw ~= nil and maxRaw ~= nil then
        pcall(o.healthFrame.SetMinMaxValues, o.healthFrame, minRaw, maxRaw)
      end
      if o.healthFrame.SetValue and curRaw ~= nil then
        pcall(o.healthFrame.SetValue, o.healthFrame, curRaw)
      end
      if not o.skipTexCoordSync then
        local srcTex = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
        local dstTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture()
        if srcTex and dstTex and srcTex.GetTexCoord and dstTex.SetTexCoord then
          local ulx, uly, llx, lly, urx, ury, lrx, lry = srcTex:GetTexCoord()
          pcall(dstTex.SetTexCoord, dstTex, ulx, uly, llx, lly, urx, ury, lrx, lry)
        end
      end
      return
    end
    local minValue = SafeNumeric(minRaw)
    local maxValue = SafeNumeric(maxRaw)
    local curValue = SafeNumeric(curRaw)
    local hasValidBounds = (minValue ~= nil and maxValue ~= nil and maxValue > minValue)
    if not hasValidBounds then
      local unit = o.key
      if unit and UnitExists and UnitExists(unit) then
        local unitCur = SafeNumeric(UnitHealth and UnitHealth(unit))
        local unitMax = SafeNumeric(UnitHealthMax and UnitHealthMax(unit))
        if unitMax and unitMax > 0 then
          minValue = 0
          maxValue = unitMax
          curValue = unitCur or curValue
          hasValidBounds = true
        end
      end
    end
    if not hasValidBounds then
      local fallbackCur = curValue or 1
      if fallbackCur < 1 then fallbackCur = 1 end
      minValue = 0
      maxValue = fallbackCur
      curValue = fallbackCur
      hasValidBounds = true
    end
    if curValue == nil then
      curValue = minValue
    end
    if curValue < minValue then curValue = minValue end
    if curValue > maxValue then curValue = maxValue end
    if o.healthFrame.SetMinMaxValues then
      if o.fillScale then
        local span = maxValue - minValue
        if span < 0 then span = 0 end
        pcall(o.healthFrame.SetMinMaxValues, o.healthFrame, minValue, minValue + (span * o.fillScale))
      else
        pcall(o.healthFrame.SetMinMaxValues, o.healthFrame, minValue, maxValue)
      end
    end
    if o.healthFrame.SetValue then
      pcall(o.healthFrame.SetValue, o.healthFrame, curValue)
    end
    if not o.skipTexCoordSync then
      local srcTex = hp.GetStatusBarTexture and hp:GetStatusBarTexture()
      local dstTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture()
      if srcTex and dstTex and srcTex.GetTexCoord and dstTex.SetTexCoord then
        local ulx, uly, llx, lly, urx, ury, lrx, lry = srcTex:GetTexCoord()
        pcall(dstTex.SetTexCoord, dstTex, ulx, uly, llx, lly, urx, ury, lrx, lry)
      end
    end
  end
  addonTable.SyncUFBigHBOverlayValue = SyncUFBigHBOverlayValue
  addonTable.InvalidateUFBigHBPlayerOverlay = function()
    local o = State.ufBigHBOverlays and State.ufBigHBOverlays["player"]
    if not o then return end
    o.fixedHealthBaseX = nil
    o.fixedHealthBaseY = nil
    o.fixedBgBaseX = nil
    o.fixedBgBaseY = nil
  end
  local function GetUFBigHBUnitName(unitToken)
    if not unitToken then return nil end
    if GetUnitName then
      local full = GetUnitName(unitToken, true)
      if full and not (issecretvalue and issecretvalue(full)) and type(full) == "string" and full ~= "" then return full end
    end
    if UnitName then
      local n = UnitName(unitToken)
      if n and not (issecretvalue and issecretvalue(n)) and type(n) == "string" and n ~= "" then return n end
    end
    return nil
  end
  local function SafeUTF8Len(s)
    if strlenutf8 then return strlenutf8(s) end
    local count = 0
    local i = 1
    local len = #s
    while i <= len do
      local b = string.byte(s, i)
      if b < 128 then i = i + 1
      elseif b < 224 then i = i + 2
      elseif b < 240 then i = i + 3
      else i = i + 4 end
      count = count + 1
    end
    return count
  end
  local function SafeUTF8Sub(s, startChar, endChar)
    local i = 1
    local charIdx = 0
    local len = #s
    local startByte, endByte
    while i <= len do
      charIdx = charIdx + 1
      if charIdx == startChar then startByte = i end
      local b = string.byte(s, i)
      if b < 128 then i = i + 1
      elseif b < 224 then i = i + 2
      elseif b < 240 then i = i + 3
      else i = i + 4 end
      if charIdx == endChar then endByte = i - 1; break end
    end
    if not startByte then return "" end
    return string.sub(s, startByte, endByte or len)
  end
  local function TrimUFBigHBName(name, maxChars)
    if type(name) ~= "string" or name == "" then return name end
    if type(maxChars) ~= "number" or maxChars <= 0 then return name end
    local charCount = SafeUTF8Len(name)
    if charCount <= maxChars then return name end
    return SafeUTF8Sub(name, 1, maxChars) .. "..."
  end
  local function ApplyUFBigHBNameTransforms(name, unitToken, prof)
    if type(name) ~= "string" or name == "" then return name end
    if not prof then return name end
    local unitHideRealmKey = (unitToken == "player" and "ufBigHBPlayerHideRealm")
      or (unitToken == "target" and "ufBigHBTargetHideRealm")
      or (unitToken == "focus" and "ufBigHBFocusHideRealm")
    local hideRealm = false
    if unitHideRealmKey then
      hideRealm = (prof[unitHideRealmKey] == true) or (prof.ufBigHBHideRealm == true)
    end
    if hideRealm then
      local dashPos = name:find("-")
      if dashPos then
        name = name:sub(1, dashPos - 1)
      end
    end
    return name
  end
  ApplyBossFrameCustomization()
  local function GetUFBigHBNameMaxChars(prof, unitToken)
    if type(prof) ~= "table" then return 0 end
    local unitMaxKey = (unitToken == "player" and "ufBigHBPlayerNameMaxChars")
      or (unitToken == "target" and "ufBigHBTargetNameMaxChars")
      or (unitToken == "focus" and "ufBigHBFocusNameMaxChars")
    local maxChars = unitMaxKey and tonumber(prof[unitMaxKey]) or nil
    if maxChars == nil then
      maxChars = tonumber(prof.ufBigHBNameMaxChars) or 0
    end
    return maxChars
  end
  local function GetSafeDmgAbsorbBoundsFromBar(srcBar, hpLeftBound, hpRightBound, hpWidthBound)
    if not srcBar then return nil, nil, nil end
    if srcBar.IsShown and not srcBar:IsShown() then return nil, nil, nil end
    local function safeNum(v)
      if type(v) ~= "number" then return nil end
      if issecretvalue and issecretvalue(v) then return nil end
      return v
    end
    local function boundsFromObject(obj)
      if not obj or not obj.GetLeft or not obj.GetRight then return nil, nil, nil end
      local left = safeNum(obj:GetLeft())
      local right = safeNum(obj:GetRight())
      if not left or not right then return nil, nil, nil end
      local width = right - left
      if width and width > 0.5 then
        return left, right, width
      end
      return nil, nil, nil
    end
    local candidates = {}
    local function addCandidate(obj)
      local l, r, w = boundsFromObject(obj)
      if l and r and w then
        candidates[#candidates + 1] = {l = l, r = r, w = w}
      end
    end
    addCandidate(srcBar.GetStatusBarTexture and srcBar:GetStatusBarTexture() or nil)
    addCandidate(srcBar)
    if srcBar.GetChildren then
      local children = {srcBar:GetChildren()}
      for i = 1, #children do
        local c = children[i]
        addCandidate(c)
        if c and c.GetObjectType and c:GetObjectType() == "StatusBar" and c.GetStatusBarTexture then
          addCandidate(c:GetStatusBarTexture())
        end
      end
    end
    if srcBar.GetRegions then
      local regions = {srcBar:GetRegions()}
      for i = 1, #regions do
        local reg = regions[i]
        if reg and reg.GetObjectType and reg:GetObjectType() == "Texture" then
          addCandidate(reg)
        end
      end
    end
    if #candidates == 0 then return nil, nil, nil end
    local best = nil
    local hpW = safeNum(hpWidthBound)
    for i = 1, #candidates do
      local c = candidates[i]
      local insideHP = true
      if hpLeftBound and hpRightBound then
        insideHP = (c.r >= hpLeftBound - 3) and (c.l <= hpRightBound + 3)
      end
      if insideHP then
        local notFull = true
        if hpW and hpW > 1 then
          notFull = c.w <= (hpW * 0.98)
        end
        if notFull then
          if not best or c.w > best.w then best = c end
        end
      end
    end
    if not best then
      for i = 1, #candidates do
        local c = candidates[i]
        local insideHP = true
        if hpLeftBound and hpRightBound then
          insideHP = (c.r >= hpLeftBound - 3) and (c.l <= hpRightBound + 3)
        end
        if insideHP then
          if not best or c.w > best.w then best = c end
        end
      end
    end
    if best then
      return best.l, best.r, best.w
    end
    return nil, nil, nil
  end
  local function UpdateUFBigHBDmgAbsorb(o, unit)
    local function SafeNumeric(v)
      if type(v) ~= "number" then return nil end
      if issecretvalue and issecretvalue(v) then return nil end
      return v
    end
    local function IsSecretValue(v)
      return issecretvalue and issecretvalue(v)
    end
    local function HasPositiveValue(v)
      if v == nil then return false end
      if IsSecretValue(v) then return true end
      return type(v) == "number" and v > 0
    end
    local function Clamp01(v)
      if type(v) ~= "number" then return 0 end
      if v < 0 then return 0 end
      if v > 1 then return 1 end
      return v
    end
    local function HideDmgAbsorb(keepGlow)
      if o and o.dmgAbsorbFrame then o.dmgAbsorbFrame:Hide() end
      if o and o.fullDmgAbsorbFrame then o.fullDmgAbsorbFrame:Hide() end
      if (not keepGlow) and o and o.dmgAbsorbGlow then o.dmgAbsorbGlow:Hide() end
    end
    if not o or not o.dmgAbsorbFrame or not o.healthFrame or not o.origHP then
      HideDmgAbsorb()
      return
    end
    if not unit or not UnitExists or not UnitExists(unit) then
      HideDmgAbsorb()
      return
    end
    local dmgAbsorbMode = "bar_glow"
    local profile = addonTable.GetProfile and addonTable.GetProfile() or nil
    if profile then
      if unit == "player" then dmgAbsorbMode = profile.ufBigHBPlayerDmgAbsorb or "bar_glow"
      elseif unit == "target" then dmgAbsorbMode = profile.ufBigHBTargetDmgAbsorb or "bar_glow"
      elseif unit == "focus" then dmgAbsorbMode = profile.ufBigHBFocusDmgAbsorb or "bar_glow"
      end
    end
    if type(o.forceDmgAbsorbMode) == "string" then
      dmgAbsorbMode = o.forceDmgAbsorbMode
    end
    if dmgAbsorbMode == "off" then
      HideDmgAbsorb()
      return
    end
    local w = SafeNumeric(o.healthFrame.GetWidth and o.healthFrame:GetWidth() or nil)
    local h = SafeNumeric(o.healthFrame.GetHeight and o.healthFrame:GetHeight() or nil)
    if not w or not h or w <= 0 or h <= 0 then
      HideDmgAbsorb()
      return
    end
    local hfStrata = (o.healthFrame.GetFrameStrata and o.healthFrame:GetFrameStrata()) or "LOW"
    local hfLevel = (o.healthFrame.GetFrameLevel and o.healthFrame:GetFrameLevel()) or 2
    local bgLevel = (o.bgFrame and o.bgFrame.GetFrameLevel and o.bgFrame:GetFrameLevel()) or math.max(1, hfLevel - 2)
    local dmgAbsorbLevel = math.max(bgLevel + 1, hfLevel - 1)
    if dmgAbsorbLevel >= hfLevel then
      dmgAbsorbLevel = math.max(1, hfLevel - 1)
    end
    local fullDmgAbsorbLevel = hfLevel + 3
    if o.dmgAbsorbFrame then
      if o.dmgAbsorbFrame.SetFrameStrata then o.dmgAbsorbFrame:SetFrameStrata(hfStrata) end
      if o.dmgAbsorbFrame.SetFrameLevel then o.dmgAbsorbFrame:SetFrameLevel(dmgAbsorbLevel) end
    end
    if o.fullDmgAbsorbFrame then
      if o.fullDmgAbsorbFrame.SetFrameStrata then o.fullDmgAbsorbFrame:SetFrameStrata(hfStrata) end
      if o.fullDmgAbsorbFrame.SetFrameLevel then o.fullDmgAbsorbFrame:SetFrameLevel(fullDmgAbsorbLevel) end
    end
    local visW = w / (o.fillScale or 1)
    if not visW or visW <= 0 then
      HideDmgAbsorb()
      return
    end
    local function ApplyGlow(overDmgAbsorb)
      if not o.dmgAbsorbGlow then return end
      if dmgAbsorbMode ~= "bar_glow" then o.dmgAbsorbGlow:Hide(); return end
      if overDmgAbsorb then
        o.dmgAbsorbGlow:ClearAllPoints()
        o.dmgAbsorbGlow:SetPoint("TOPRIGHT", o.healthFrame, "TOPRIGHT", 2, 0)
        o.dmgAbsorbGlow:SetPoint("BOTTOMRIGHT", o.healthFrame, "BOTTOMRIGHT", 2, 0)
        o.dmgAbsorbGlow:SetWidth(8)
        o.dmgAbsorbGlow:Show()
      else
        o.dmgAbsorbGlow:Hide()
      end
    end
    local function GetDmgAbsorbAnchorAndRemaining(fillRatio)
      local statusTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or nil
      local ratio = Clamp01(fillRatio)
      local healOffset = o.healPredTotalPx or 0
      local remainingVis = nil
      if statusTex and statusTex.GetWidth then
        local texW = SafeNumeric(statusTex:GetWidth())
        if texW and w then
          remainingVis = w - texW - healOffset
        end
      end
      if remainingVis == nil then
        remainingVis = visW * (1 - ratio) - healOffset
      end
      if remainingVis < 0 then remainingVis = 0 end
      return statusTex, remainingVis, ratio, healOffset
    end
    local function setupDmgAbsorbClamp(totalDmgAbsorbPx, fillRatio)
      if not totalDmgAbsorbPx or totalDmgAbsorbPx <= 0 then
        return nil, 0, 0
      end
      local statusTex, remainingVis = GetDmgAbsorbAnchorAndRemaining(fillRatio)
      local clamped = totalDmgAbsorbPx
      if clamped > remainingVis then clamped = remainingVis end
      if clamped < 0 then clamped = 0 end
      local over = totalDmgAbsorbPx - clamped
      if over < 0 then over = 0 end
      return statusTex, clamped, over
    end
    local function setupDmgAbsorbOverShift(statusTex, clampedPx, overPx, totalDmgAbsorbPx, fillRatio)
      if not o.dmgAbsorbFrame then return end
      local _, remainingVis, ratio, healOff = GetDmgAbsorbAnchorAndRemaining(fillRatio)
      if clampedPx and clampedPx >= 1 and remainingVis > 0 then
        local hardCap = remainingVis
        if statusTex then
          o.dmgAbsorbFrame:ClearAllPoints()
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "TOPLEFT", statusTex, "TOPRIGHT", healOff, 0)
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff, 0)
        else
          local offsetPx = visW * ratio + healOff
          o.dmgAbsorbFrame:ClearAllPoints()
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
        end
        o.dmgAbsorbFrame:SetSize(math.max(1, hardCap), h)
        o.dmgAbsorbFrame:SetMinMaxValues(0, math.max(1, hardCap))
        o.dmgAbsorbFrame:SetValue(clampedPx)
        if o.dmgAbsorbFrame.SetReverseFill then o.dmgAbsorbFrame:SetReverseFill(false) end
        o.dmgAbsorbFrame:Show()
      else
        o.dmgAbsorbFrame:Hide()
      end
      if o.fullDmgAbsorbFrame then
        if remainingVis <= 1 and totalDmgAbsorbPx and totalDmgAbsorbPx >= 1 then
          local fullW = totalDmgAbsorbPx
          if fullW > visW then fullW = visW end
          o.fullDmgAbsorbFrame:ClearAllPoints()
          o.fullDmgAbsorbFrame:SetPoint("TOPRIGHT", o.healthFrame, "TOPRIGHT", 0, 0)
          o.fullDmgAbsorbFrame:SetPoint("BOTTOMRIGHT", o.healthFrame, "BOTTOMRIGHT", 0, 0)
          o.fullDmgAbsorbFrame:SetWidth(fullW)
          if o.fullDmgAbsorbTex and o.fullDmgAbsorbTex.SetTexCoord then
            local left = 1 - (fullW / visW)
            if left < 0 then left = 0 end
            if left > 1 then left = 1 end
            o.fullDmgAbsorbTex:SetTexCoord(left, 1, 0, 1)
          end
          o.fullDmgAbsorbFrame:Show()
        else
          o.fullDmgAbsorbFrame:Hide()
        end
      end
      return overPx and overPx > 0
    end
    local function ShowDmgAbsorbFromBarValues(srcDmgAbsorbBar)
      if not srcDmgAbsorbBar or not srcDmgAbsorbBar.GetMinMaxValues or not srcDmgAbsorbBar.GetValue then return false end
      local okMM, minV, maxV = pcall(srcDmgAbsorbBar.GetMinMaxValues, srcDmgAbsorbBar)
      local okV, curV = pcall(srcDmgAbsorbBar.GetValue, srcDmgAbsorbBar)
      if not okMM or not okV then return false end
      if o.forceNoSecretDmgAbsorbRaw then
        minV = SafeNumeric(minV)
        maxV = SafeNumeric(maxV)
        curV = SafeNumeric(curV)
        if not (minV and maxV and curV) then return false end
      end
      local statusTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or nil
      local healOff3 = o.healPredTotalPx or 0
      local remainingVis = nil
      if statusTex and statusTex.GetWidth then
        local texW = SafeNumeric(statusTex:GetWidth())
        if texW and w then
          remainingVis = w - texW - healOff3
        end
      end
      if remainingVis == nil then
        remainingVis = visW * (1 - Clamp01(fillRatio)) - healOff3
      end
      if remainingVis < 0 then remainingVis = 0 end
      if remainingVis <= 1 then return false end
      o.dmgAbsorbFrame:ClearAllPoints()
      local hardCap = nil
      if statusTex then
        local capRightRef = o.healthFrame
        if o.bgFrame and o.bgFrame.GetRight and o.healthFrame.GetRight then
          local bgRight = SafeNumeric(o.bgFrame:GetRight())
          local hpRight = SafeNumeric(o.healthFrame:GetRight())
          if bgRight and hpRight and bgRight < hpRight then
            capRightRef = o.bgFrame
          end
        end
        if statusTex.GetRight and capRightRef.GetRight then
          local leftEdge = SafeNumeric(statusTex:GetRight())
          local rightEdge = SafeNumeric(capRightRef:GetRight())
          if leftEdge and rightEdge then
            hardCap = rightEdge - leftEdge - healOff3
          end
        end
      end
      if not hardCap or hardCap <= 0 then
        hardCap = remainingVis
      end
      if not hardCap or hardCap <= 1 then return false end
      if statusTex then
        PixelUtil.SetPoint(o.dmgAbsorbFrame, "TOPLEFT", statusTex, "TOPRIGHT", healOff3, 0)
        PixelUtil.SetPoint(o.dmgAbsorbFrame, "BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff3, 0)
      else
        local offsetPx = visW * Clamp01(fillRatio) + healOff3
        PixelUtil.SetPoint(o.dmgAbsorbFrame, "TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
        PixelUtil.SetPoint(o.dmgAbsorbFrame, "BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
      end
      o.dmgAbsorbFrame:SetSize(hardCap, h)
      if o.dmgAbsorbFrame.SetMinMaxValues then pcall(o.dmgAbsorbFrame.SetMinMaxValues, o.dmgAbsorbFrame, minV, maxV) end
      if o.dmgAbsorbFrame.SetValue then pcall(o.dmgAbsorbFrame.SetValue, o.dmgAbsorbFrame, curV) end
      if o.dmgAbsorbFrame.SetReverseFill then o.dmgAbsorbFrame:SetReverseFill(false) end
      o.dmgAbsorbFrame:Show()
      if o.fullDmgAbsorbFrame then o.fullDmgAbsorbFrame:Hide() end
      return true
    end
    local function GetBarFillRatio(bar)
      if not bar then return nil end
      local barW = SafeNumeric(bar.GetWidth and bar:GetWidth() or nil)
      local st = bar.GetStatusBarTexture and bar:GetStatusBarTexture() or nil
      local fillW = SafeNumeric(st and st.GetWidth and st:GetWidth() or nil)
      if barW and barW > 0 and fillW then
        return Clamp01(fillW / barW)
      end
      return nil
    end
    local function GetDmgAbsorbPxFromVisual(srcDmgAbsorbBar)
      if not srcDmgAbsorbBar then return nil end
      local hpLeft = SafeNumeric(o.origHP.GetLeft and o.origHP:GetLeft() or nil)
      local hpRight = SafeNumeric(o.origHP.GetRight and o.origHP:GetRight() or nil)
      local hpWidth = nil
      if hpLeft and hpRight and hpRight > hpLeft then
        hpWidth = hpRight - hpLeft
      end
      local _, _, dmgAbsorbW = GetSafeDmgAbsorbBoundsFromBar(srcDmgAbsorbBar, hpLeft, hpRight, hpWidth)
      if (not dmgAbsorbW or dmgAbsorbW <= 0) and srcDmgAbsorbBar.GetStatusBarTexture then
        local tex = srcDmgAbsorbBar:GetStatusBarTexture()
        if tex and tex.GetTexCoord then
          local ulx, _, llx, _, urx, _, lrx = tex:GetTexCoord()
          if type(ulx) == "number" and type(llx) == "number" and type(urx) == "number" and type(lrx) == "number" then
            local minx = math.min(ulx, llx, urx, lrx)
            local maxx = math.max(ulx, llx, urx, lrx)
            local ratio = maxx - minx
            if ratio and ratio > 0 and ratio <= 1 and hpWidth and hpWidth > 0 then
              dmgAbsorbW = ratio * hpWidth
            end
          end
        end
      end
      if (not dmgAbsorbW or dmgAbsorbW <= 0) then
        local hpFillRight = nil
        if o.origHP.GetStatusBarTexture then
          local hpTex = o.origHP:GetStatusBarTexture()
          if hpTex and hpTex.GetRight then
            hpFillRight = SafeNumeric(hpTex:GetRight())
          end
        end
        local farRight = nil
        local function scanCandidate(obj)
          if not obj or not obj.GetLeft or not obj.GetRight then return end
          if obj.IsShown and not obj:IsShown() then return end
          local left = SafeNumeric(obj:GetLeft())
          local right = SafeNumeric(obj:GetRight())
          if not left or not right or right <= left then return end
          if hpFillRight and right <= (hpFillRight + 0.25) then return end
          if hpRight and left > (hpRight + 2) then return end
          if (not farRight) or (right > farRight) then farRight = right end
        end
        scanCandidate(srcDmgAbsorbBar.GetStatusBarTexture and srcDmgAbsorbBar:GetStatusBarTexture() or nil)
        if srcDmgAbsorbBar.Fill then scanCandidate(srcDmgAbsorbBar.Fill) end
        if srcDmgAbsorbBar.TiledFillOverlay then scanCandidate(srcDmgAbsorbBar.TiledFillOverlay) end
        if srcDmgAbsorbBar.GetChildren then
          local children = { srcDmgAbsorbBar:GetChildren() }
          for i = 1, #children do
            local child = children[i]
            if child and child.GetObjectType then
              local typ = child:GetObjectType()
              if typ == "Texture" then
                scanCandidate(child)
              elseif typ == "StatusBar" and child.GetStatusBarTexture then
                scanCandidate(child:GetStatusBarTexture())
              end
            end
          end
        end
        if srcDmgAbsorbBar.GetRegions then
          local regions = { srcDmgAbsorbBar:GetRegions() }
          for i = 1, #regions do
            local region = regions[i]
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
              scanCandidate(region)
            end
          end
        end
        if hpFillRight and farRight and farRight > hpFillRight then
          dmgAbsorbW = farRight - hpFillRight
        end
      end
      if not dmgAbsorbW or dmgAbsorbW <= 0 then return nil end
      local sourceWidth = hpWidth or SafeNumeric(o.origHP.GetWidth and o.origHP:GetWidth() or nil)
      if sourceWidth and sourceWidth > 0 then
        local scaled = (dmgAbsorbW / sourceWidth) * visW
        if scaled and scaled > 0 then return scaled end
      end
      return nil
    end
    local function GetDmgAbsorbPxFromBarValue(srcDmgAbsorbBar)
      if not srcDmgAbsorbBar or not srcDmgAbsorbBar.GetMinMaxValues or not srcDmgAbsorbBar.GetValue then return nil end
      local okMM, minV, maxV = pcall(srcDmgAbsorbBar.GetMinMaxValues, srcDmgAbsorbBar)
      local okV, curV = pcall(srcDmgAbsorbBar.GetValue, srcDmgAbsorbBar)
      if not okMM or not okV then return nil end
      minV = SafeNumeric(minV)
      maxV = SafeNumeric(maxV)
      curV = SafeNumeric(curV)
      if not (minV and maxV and curV) then return nil end
      if maxV <= minV then return nil end
      local ratio = (curV - minV) / (maxV - minV)
      if ratio < 0 then ratio = 0 end
      if ratio > 1 then ratio = 1 end
      return ratio * visW
    end

    local fillRatio = nil
    if o.healthFrame and o.healthFrame.GetMinMaxValues and o.healthFrame.GetValue then
      local okMM, minHF, maxHF = pcall(o.healthFrame.GetMinMaxValues, o.healthFrame)
      local okV, curHF = pcall(o.healthFrame.GetValue, o.healthFrame)
      if okMM and okV then
        minHF = SafeNumeric(minHF)
        maxHF = SafeNumeric(maxHF)
        curHF = SafeNumeric(curHF)
        if minHF and maxHF and curHF and maxHF > minHF then
          fillRatio = Clamp01((curHF - minHF) / (maxHF - minHF))
        end
      end
    end
    if fillRatio == nil then
      fillRatio = GetBarFillRatio(o.healthFrame)
    end
    if fillRatio == nil then
      fillRatio = GetBarFillRatio(o.origHP)
    end
    local hpMin, hpMax = nil, nil
    if o.origHP.GetMinMaxValues then
      local okMM, minV, maxV = pcall(o.origHP.GetMinMaxValues, o.origHP)
      if okMM then
        hpMin = SafeNumeric(minV)
        hpMax = SafeNumeric(maxV)
      end
    end
    if fillRatio == nil and hpMin and hpMax and hpMax > hpMin then
      local cur = nil
      if o.origHP.GetValue then
        local okVal, curV = pcall(o.origHP.GetValue, o.origHP)
        if okVal then cur = SafeNumeric(curV) end
      end
      if cur == nil then
        cur = SafeNumeric(UnitHealth and UnitHealth(unit) or nil)
      end
      if cur ~= nil then
        if cur < hpMin then cur = hpMin end
        if cur > hpMax then cur = hpMax end
        fillRatio = Clamp01((cur - hpMin) / (hpMax - hpMin))
      end
    end
    if fillRatio == nil then fillRatio = 0 end

    local srcBar = o.origHP.TotalAbsorbBar
    local srcStatusBar = nil
    if srcBar then
      if srcBar.GetObjectType and srcBar:GetObjectType() == "StatusBar" then
        srcStatusBar = srcBar
      elseif srcBar.statusBar then
        srcStatusBar = srcBar.statusBar
      elseif srcBar.StatusBar then
        srcStatusBar = srcBar.StatusBar
      end
    end
    local overDmgAbsorb = (o.origHP.OverAbsorbGlow and o.origHP.OverAbsorbGlow.IsShown and o.origHP.OverAbsorbGlow:IsShown()) and true or false

    local maxHealth = nil
    local maxHealthRaw = nil
    if hpMin and hpMax and hpMax > hpMin then
      maxHealth = hpMax - hpMin
      maxHealthRaw = maxHealth
    else
      local mhRaw = UnitHealthMax and UnitHealthMax(unit) or nil
      if mhRaw ~= nil then
        maxHealthRaw = mhRaw
        maxHealth = SafeNumeric(mhRaw)
      end
    end
    if maxHealthRaw == nil then
      HideDmgAbsorb()
      ApplyGlow(overDmgAbsorb)
      return
    end
    local currentHealth = nil
    if o.origHP.GetValue then
      local okVal, curV = pcall(o.origHP.GetValue, o.origHP)
      if okVal then currentHealth = SafeNumeric(curV) end
    end
    if currentHealth == nil then
      currentHealth = SafeNumeric(UnitHealth and UnitHealth(unit) or nil)
    end
    local missing = nil
    if maxHealth then
      missing = (1 - Clamp01(fillRatio)) * maxHealth
      if currentHealth and currentHealth >= 0 and currentHealth <= maxHealth then
        missing = maxHealth - currentHealth
      end
      if missing < 0 then missing = 0 end
    end

    local dmgAbsorbTotalRaw = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or nil
    if o.forceNoSecretDmgAbsorbRaw and IsSecretValue(dmgAbsorbTotalRaw) then
      dmgAbsorbTotalRaw = nil
    end
    local dmgAbsorbTotal = SafeNumeric(dmgAbsorbTotalRaw)
    if (not HasPositiveValue(dmgAbsorbTotalRaw)) and CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
      if not o.dmgAbsorbCalc then
        local okCreate, calc = pcall(CreateUnitHealPredictionCalculator)
        if okCreate then
          o.dmgAbsorbCalc = calc
          if calc.SetIncomingHealClampMode then pcall(calc.SetIncomingHealClampMode, calc, Enum.UnitIncomingHealClampMode.MaximumHealth) end
          if calc.SetDamageAbsorbClampMode then pcall(calc.SetDamageAbsorbClampMode, calc, Enum.UnitDamageAbsorbClampMode.MaximumHealth) end
          if calc.SetHealAbsorbClampMode then pcall(calc.SetHealAbsorbClampMode, calc, Enum.UnitHealAbsorbClampMode.MaximumHealth) end
          if calc.SetHealAbsorbMode then pcall(calc.SetHealAbsorbMode, calc, Enum.UnitHealAbsorbMode.Total) end
        end
      end
      if o.dmgAbsorbCalc then
        pcall(UnitGetDetailedHealPrediction, unit, "player", o.dmgAbsorbCalc)
        if o.dmgAbsorbCalc.GetDamageAbsorbs then
          local okAbs, dmgAbs = pcall(o.dmgAbsorbCalc.GetDamageAbsorbs, o.dmgAbsorbCalc)
          if okAbs then
            if o.forceNoSecretDmgAbsorbRaw and IsSecretValue(dmgAbs) then
              dmgAbs = nil
            end
            dmgAbsorbTotalRaw = dmgAbs
            dmgAbsorbTotal = SafeNumeric(dmgAbs)
          end
        end
      end
    end
    local totalDmgAbsorbPx = nil
    if HasPositiveValue(dmgAbsorbTotalRaw) then
      local statusTex, remainingVis, ratio, healOff4 = GetDmgAbsorbAnchorAndRemaining(fillRatio)
      if remainingVis and remainingVis > 1 then
        local hardCap = remainingVis
        if statusTex then
          o.dmgAbsorbFrame:ClearAllPoints()
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "TOPLEFT", statusTex, "TOPRIGHT", healOff4, 0)
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff4, 0)
        else
          local offsetPx = visW * ratio + healOff4
          o.dmgAbsorbFrame:ClearAllPoints()
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
          PixelUtil.SetPoint(o.dmgAbsorbFrame, "BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
        end
        o.dmgAbsorbFrame:SetSize(math.max(1, hardCap), h)
        if o.dmgAbsorbFrame.SetMinMaxValues then
          pcall(o.dmgAbsorbFrame.SetMinMaxValues, o.dmgAbsorbFrame, 0, maxHealthRaw)
        end
        if o.dmgAbsorbFrame.SetValue then
          pcall(o.dmgAbsorbFrame.SetValue, o.dmgAbsorbFrame, dmgAbsorbTotalRaw)
        end
        if o.dmgAbsorbFrame.SetReverseFill then o.dmgAbsorbFrame:SetReverseFill(false) end
        o.dmgAbsorbFrame:Show()
        if o.fullDmgAbsorbFrame then o.fullDmgAbsorbFrame:Hide() end
        if dmgAbsorbTotal and missing and dmgAbsorbTotal > missing then
          overDmgAbsorb = true
        end
        ApplyGlow(overDmgAbsorb)
        return
      end
    end
    if (not totalDmgAbsorbPx or totalDmgAbsorbPx <= 0) and ShowDmgAbsorbFromBarValues(srcStatusBar or srcBar) then
      ApplyGlow(overDmgAbsorb)
      return
    end
    if not totalDmgAbsorbPx or totalDmgAbsorbPx <= 0 then
      local visualDmgAbsorbPx = GetDmgAbsorbPxFromVisual(srcStatusBar or srcBar)
      if visualDmgAbsorbPx and visualDmgAbsorbPx > 0 then
        totalDmgAbsorbPx = visualDmgAbsorbPx
      else
        totalDmgAbsorbPx = GetDmgAbsorbPxFromBarValue(srcStatusBar or srcBar)
      end
    end
    if not totalDmgAbsorbPx or totalDmgAbsorbPx <= 0 then
      HideDmgAbsorb()
      ApplyGlow(false)
      return
    end
    local statusTex, clampedPx, overflowPx = setupDmgAbsorbClamp(totalDmgAbsorbPx, fillRatio)
    local hasOverflow = setupDmgAbsorbOverShift(statusTex, clampedPx, overflowPx, totalDmgAbsorbPx, fillRatio)
    if dmgAbsorbTotal and missing and dmgAbsorbTotal > missing then
      hasOverflow = true
    end
    ApplyGlow(hasOverflow or overDmgAbsorb)
  end
  local function UpdateUFBigHBHealPrediction(o, unit)
    local function IsSecret(v)
      return issecretvalue and issecretvalue(v) or false
    end
    local function SafeNum(v)
      if type(v) ~= "number" then return nil end
      if IsSecret(v) then return nil end
      return v
    end
    local function HasPositiveValue(v)
      if v == nil then return false end
      if IsSecret(v) then return true end
      return type(v) == "number" and v > 0
    end
    local function GetBarVisualWidth(srcBar)
      if not srcBar then return 0 end
      if srcBar.IsShown and not srcBar:IsShown() then return 0 end
      local tex = srcBar.GetStatusBarTexture and srcBar:GetStatusBarTexture() or nil
      local texW = SafeNum(tex and tex.GetWidth and tex:GetWidth() or nil)
      if texW and texW > 0 then return texW end
      local barW = SafeNum(srcBar.GetWidth and srcBar:GetWidth() or nil)
      local minV, maxV = nil, nil
      local curV = nil
      if srcBar.GetMinMaxValues then
        local okMM, minRaw, maxRaw = pcall(srcBar.GetMinMaxValues, srcBar)
        if okMM then
          minV = SafeNum(minRaw)
          maxV = SafeNum(maxRaw)
        end
      end
      if srcBar.GetValue then
        local okVal, rawVal = pcall(srcBar.GetValue, srcBar)
        if okVal then curV = SafeNum(rawVal) end
      end
      if barW and minV and maxV and maxV > minV and curV then
        if curV < minV then curV = minV end
        if curV > maxV then curV = maxV end
        local ratio = (curV - minV) / (maxV - minV)
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end
        return barW * ratio
      end
      return 0
    end
    local function HideAllHealPred()
      if o.myHealPredFrame then o.myHealPredFrame:Hide() end
      if o.otherHealPredFrame then o.otherHealPredFrame:Hide() end
      if o.healAbsorbFrame then o.healAbsorbFrame:Hide() end
      o.healPredTotalPx = 0
    end
    if not o or not o.healthFrame or not o.origHP then HideAllHealPred(); return end
    if not o.myHealPredFrame or not o.otherHealPredFrame or not o.healAbsorbFrame then return end
    if not unit or not UnitExists or not UnitExists(unit) then HideAllHealPred(); return end
    local healPredMode = "on"
    local healAbsorbMode = "on"
    local hpProfile = addonTable.GetProfile and addonTable.GetProfile() or nil
    if hpProfile then
      if unit == "player" then
        healPredMode = hpProfile.ufBigHBPlayerHealPred or "on"
        healAbsorbMode = hpProfile.ufBigHBPlayerHealAbsorb or "on"
      elseif unit == "target" then
        healPredMode = hpProfile.ufBigHBTargetHealPred or "on"
        healAbsorbMode = hpProfile.ufBigHBTargetHealAbsorb or "on"
      elseif unit == "focus" then
        healPredMode = hpProfile.ufBigHBFocusHealPred or "on"
        healAbsorbMode = hpProfile.ufBigHBFocusHealAbsorb or "on"
      end
    end
    if type(o.forceHealPredMode) == "string" then
      healPredMode = o.forceHealPredMode
    end
    if type(o.forceHealAbsorbMode) == "string" then
      healAbsorbMode = o.forceHealAbsorbMode
    end
    if healPredMode == "off" and healAbsorbMode == "off" then HideAllHealPred(); return end
    local w = SafeNum(o.healthFrame.GetWidth and o.healthFrame:GetWidth() or nil)
    local h = SafeNum(o.healthFrame.GetHeight and o.healthFrame:GetHeight() or nil)
    if not w or not h or w <= 0 or h <= 0 then HideAllHealPred(); return end
    local statusTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or nil
    local maxHealthRaw = nil
    if o.origHP.GetMinMaxValues then
      local okMM, _, maxV = pcall(o.origHP.GetMinMaxValues, o.origHP)
      if okMM and maxV ~= nil then maxHealthRaw = maxV end
    end
    if maxHealthRaw == nil and UnitHealthMax then
      local okMax, mh = pcall(UnitHealthMax, unit)
      if okMax and mh ~= nil then maxHealthRaw = mh end
    end
    if maxHealthRaw == nil then HideAllHealPred(); return end
    local maxHealth = SafeNum(maxHealthRaw) 
    if not o.dmgAbsorbCalc and CreateUnitHealPredictionCalculator then
      local okCreate, calc = pcall(CreateUnitHealPredictionCalculator)
      if okCreate then
        o.dmgAbsorbCalc = calc
        if calc.SetIncomingHealClampMode then pcall(calc.SetIncomingHealClampMode, calc, Enum.UnitIncomingHealClampMode.MaximumHealth) end
        if calc.SetDamageAbsorbClampMode then pcall(calc.SetDamageAbsorbClampMode, calc, Enum.UnitDamageAbsorbClampMode.MaximumHealth) end
        if calc.SetHealAbsorbClampMode then pcall(calc.SetHealAbsorbClampMode, calc, Enum.UnitHealAbsorbClampMode.MaximumHealth) end
        if calc.SetHealAbsorbMode then pcall(calc.SetHealAbsorbMode, calc, Enum.UnitHealAbsorbMode.Total) end
      end
    end
    if o.dmgAbsorbCalc and UnitGetDetailedHealPrediction then
      pcall(UnitGetDetailedHealPrediction, unit, "player", o.dmgAbsorbCalc)
    end
    local myIncomingHealRaw, allIncomingHealRaw, otherIncomingHealRaw = nil, nil, nil
    if UnitGetIncomingHeals then
      local okMy, myH = pcall(UnitGetIncomingHeals, unit, "player")
      if okMy then myIncomingHealRaw = myH end
      local okAll, allH = pcall(UnitGetIncomingHeals, unit)
      if okAll then allIncomingHealRaw = allH end
    end
    if o.dmgAbsorbCalc and o.dmgAbsorbCalc.GetIncomingHeals then
      local ok, allH, playerH, otherH = pcall(o.dmgAbsorbCalc.GetIncomingHeals, o.dmgAbsorbCalc)
      if ok then
        if not HasPositiveValue(myIncomingHealRaw) then myIncomingHealRaw = playerH end
        if not HasPositiveValue(allIncomingHealRaw) then allIncomingHealRaw = allH end
        if not HasPositiveValue(otherIncomingHealRaw) then otherIncomingHealRaw = otherH end
      end
    end
    local myIncomingHeal = SafeNum(myIncomingHealRaw)
    local allIncomingHeal = SafeNum(allIncomingHealRaw)
    local otherIncomingHeal = SafeNum(otherIncomingHealRaw)
    local healAbsorbsRaw = nil
    if UnitGetTotalHealAbsorbs then
      local ok, hAbs = pcall(UnitGetTotalHealAbsorbs, unit)
      if ok then healAbsorbsRaw = hAbs end
    end
    if (not HasPositiveValue(healAbsorbsRaw)) and o.dmgAbsorbCalc and o.dmgAbsorbCalc.GetHealAbsorbs then
      local ok, hAbs = pcall(o.dmgAbsorbCalc.GetHealAbsorbs, o.dmgAbsorbCalc)
      if ok then healAbsorbsRaw = hAbs end
    end
    if type(healAbsorbsRaw) == "number" and (not IsSecret(healAbsorbsRaw)) and healAbsorbsRaw < 0 then
      healAbsorbsRaw = -healAbsorbsRaw
    end
    if (not HasPositiveValue(healAbsorbsRaw)) and o.origHP and o.origHP.HealAbsorbBar and o.origHP.HealAbsorbBar.GetValue then
      local okBarVal, barVal = pcall(o.origHP.HealAbsorbBar.GetValue, o.origHP.HealAbsorbBar)
      if okBarVal and type(barVal) == "number" and (not IsSecret(barVal)) then
        if barVal < 0 then barVal = -barVal end
        if barVal > 0 then
          healAbsorbsRaw = barVal
        end
      end
    end
    local healAbsorbs = SafeNum(healAbsorbsRaw)
    if healAbsorbs and healAbsorbs > 0 then
      local curHealth = SafeNum(o.origHP and o.origHP.GetValue and select(2, pcall(o.origHP.GetValue, o.origHP)) or nil)
      if not curHealth and UnitHealth then curHealth = SafeNum(UnitHealth(unit)) end
      if curHealth and healAbsorbs > curHealth then
        healAbsorbs = curHealth
        healAbsorbsRaw = healAbsorbs
      end
    end
    if maxHealth and maxHealth > 0 and allIncomingHeal then
      local curHealth = SafeNum(o.origHP and o.origHP.GetValue and select(2, pcall(o.origHP.GetValue, o.origHP)) or nil)
        or SafeNum(UnitHealth and UnitHealth(unit) or nil) or 0
      local healAbsForClamp = healAbsorbs or 0
      if curHealth - healAbsForClamp + allIncomingHeal > maxHealth then
        allIncomingHeal = maxHealth - curHealth + healAbsForClamp
      end
      if allIncomingHeal < 0 then allIncomingHeal = 0 end
      allIncomingHealRaw = allIncomingHeal
    end
    if not HasPositiveValue(otherIncomingHealRaw) then
      if allIncomingHeal and myIncomingHeal then
        if allIncomingHeal >= myIncomingHeal then
          otherIncomingHeal = allIncomingHeal - myIncomingHeal
        else
          myIncomingHeal = allIncomingHeal
          otherIncomingHeal = 0
        end
        myIncomingHealRaw = myIncomingHeal
        otherIncomingHealRaw = otherIncomingHeal
      elseif HasPositiveValue(allIncomingHealRaw) and (not HasPositiveValue(myIncomingHealRaw)) then
        otherIncomingHealRaw = allIncomingHealRaw
      end
    end
    local myVisualFallback = 0
    local otherVisualFallback = 0
    local healAbsorbVisualFallback = 0
    if o.origHP then
      myVisualFallback = GetBarVisualWidth(o.origHP.MyHealPredictionBar)
      otherVisualFallback = GetBarVisualWidth(o.origHP.OtherHealPredictionBar)
      healAbsorbVisualFallback = GetBarVisualWidth(o.origHP.HealAbsorbBar)
    end
    local hasMyHealRaw = HasPositiveValue(myIncomingHealRaw)
    local hasOtherHealRaw = HasPositiveValue(otherIncomingHealRaw)
    local hasHealAbsorbRaw = HasPositiveValue(healAbsorbsRaw)
    if o.forceNoSecretHealAbsorbRaw and IsSecret(healAbsorbsRaw) then
      hasHealAbsorbRaw = false
    end
    local hasMyHeal = hasMyHealRaw or (myVisualFallback > 0)
    local hasOtherHeal = hasOtherHealRaw or (otherVisualFallback > 0)
    local hasHealAbsorb = hasHealAbsorbRaw or (healAbsorbVisualFallback > 0)
    if healPredMode == "off" then hasMyHeal = false; hasOtherHeal = false end
    if healAbsorbMode == "off" then hasHealAbsorb = false end
    if hasMyHeal then
      o.myHealPredFrame:ClearAllPoints()
      if statusTex then
        o.myHealPredFrame:SetPoint("TOPLEFT", statusTex, "TOPRIGHT", 0, 0)
        o.myHealPredFrame:SetPoint("BOTTOMLEFT", statusTex, "BOTTOMRIGHT", 0, 0)
      else
        o.myHealPredFrame:SetPoint("TOPLEFT", o.healthFrame, "TOPLEFT", 0, 0)
        o.myHealPredFrame:SetPoint("BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", 0, 0)
      end
      o.myHealPredFrame:SetWidth(w)
      if hasMyHealRaw then
        pcall(o.myHealPredFrame.SetMinMaxValues, o.myHealPredFrame, 0, maxHealthRaw)
        pcall(o.myHealPredFrame.SetValue, o.myHealPredFrame, myIncomingHealRaw)
      else
        pcall(o.myHealPredFrame.SetMinMaxValues, o.myHealPredFrame, 0, w)
        pcall(o.myHealPredFrame.SetValue, o.myHealPredFrame, myVisualFallback)
      end
      o.myHealPredFrame:Show()
    else
      o.myHealPredFrame:Hide()
    end
    if hasOtherHeal then
      o.otherHealPredFrame:ClearAllPoints()
      if hasMyHeal then
        local myTex = o.myHealPredFrame.GetStatusBarTexture and o.myHealPredFrame:GetStatusBarTexture()
        if myTex then
          o.otherHealPredFrame:SetPoint("TOPLEFT", myTex, "TOPRIGHT", 0, 0)
          o.otherHealPredFrame:SetPoint("BOTTOMLEFT", myTex, "BOTTOMRIGHT", 0, 0)
        else
          o.otherHealPredFrame:SetPoint("TOPLEFT", o.myHealPredFrame, "TOPRIGHT", 0, 0)
          o.otherHealPredFrame:SetPoint("BOTTOMLEFT", o.myHealPredFrame, "BOTTOMRIGHT", 0, 0)
        end
      elseif statusTex then
        o.otherHealPredFrame:SetPoint("TOPLEFT", statusTex, "TOPRIGHT", 0, 0)
        o.otherHealPredFrame:SetPoint("BOTTOMLEFT", statusTex, "BOTTOMRIGHT", 0, 0)
      else
        o.otherHealPredFrame:SetPoint("TOPLEFT", o.healthFrame, "TOPLEFT", 0, 0)
        o.otherHealPredFrame:SetPoint("BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", 0, 0)
      end
      o.otherHealPredFrame:SetWidth(w)
      if hasOtherHealRaw then
        pcall(o.otherHealPredFrame.SetMinMaxValues, o.otherHealPredFrame, 0, maxHealthRaw)
        pcall(o.otherHealPredFrame.SetValue, o.otherHealPredFrame, otherIncomingHealRaw)
      else
        pcall(o.otherHealPredFrame.SetMinMaxValues, o.otherHealPredFrame, 0, w)
        pcall(o.otherHealPredFrame.SetValue, o.otherHealPredFrame, otherVisualFallback)
      end
      o.otherHealPredFrame:Show()
    else
      o.otherHealPredFrame:Hide()
    end
    if hasHealAbsorb then
      o.healAbsorbFrame:ClearAllPoints()
      if statusTex then
        o.healAbsorbFrame:SetPoint("TOPRIGHT", statusTex, "TOPRIGHT", 0, 0)
        o.healAbsorbFrame:SetPoint("BOTTOMRIGHT", statusTex, "BOTTOMRIGHT", 0, 0)
      else
        o.healAbsorbFrame:SetPoint("TOPRIGHT", o.healthFrame, "TOPRIGHT", 0, 0)
        o.healAbsorbFrame:SetPoint("BOTTOMRIGHT", o.healthFrame, "BOTTOMRIGHT", 0, 0)
      end
      o.healAbsorbFrame:SetWidth(w)
      if hasHealAbsorbRaw then
        pcall(o.healAbsorbFrame.SetMinMaxValues, o.healAbsorbFrame, 0, maxHealthRaw)
        pcall(o.healAbsorbFrame.SetValue, o.healAbsorbFrame, healAbsorbsRaw)
      else
        pcall(o.healAbsorbFrame.SetMinMaxValues, o.healAbsorbFrame, 0, w)
        pcall(o.healAbsorbFrame.SetValue, o.healAbsorbFrame, healAbsorbVisualFallback)
      end
      o.healAbsorbFrame:Show()
    else
      o.healAbsorbFrame:Hide()
    end
    local healPredPx = 0
    if hasMyHeal and o.myHealPredTex and o.myHealPredTex.GetWidth then
      local pw = SafeNum(o.myHealPredTex:GetWidth())
      if pw and pw > 0 then healPredPx = healPredPx + pw end
    end
    if hasOtherHeal and o.otherHealPredTex and o.otherHealPredTex.GetWidth then
      local pw = SafeNum(o.otherHealPredTex:GetWidth())
      if pw and pw > 0 then healPredPx = healPredPx + pw end
    end
    o.healPredTotalPx = healPredPx
  end
  addonTable.UpdateUFBigHBHealPrediction = UpdateUFBigHBHealPrediction
  addonTable.UpdateUFBigHBDmgAbsorb = UpdateUFBigHBDmgAbsorb
  local function ApplyUFBigHBOverlayHealthColor(o, hp, unit)
    if not o or not o.healthTex then return end
    local r, g, b
    if profile.ufClassColor and unit and UnitExists(unit) and UnitIsPlayer(unit) then
      local _, classToken = UnitClass(unit)
      local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
      if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
      end
    end
    if not r and hp and hp.GetStatusBarColor then
      r, g, b = hp:GetStatusBarColor()
    end
    if (type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number") or (r == 0 and g == 0 and b == 0) then
      r, g, b = ResolveUnitHealthColorSafe(unit, profile.ufClassColor == true)
    end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
      r, g, b = 0, 1, 0
    end
    o.healthTex:SetVertexColor(r, g, b, 1)
    if o.healthFrame.SetStatusBarColor then
      o.healthFrame:SetStatusBarColor(r, g, b, 1)
    end
    local st = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture()
    if st and st.SetVertexColor then
      st:SetVertexColor(r, g, b, 1)
    end
  end
  local function EnsureUFBigHBOverlay(key, parent)
    local o = State.ufBigHBOverlays[key]
    if o and o.healthFrame and o.healthFrame.GetObjectType and o.healthFrame:GetObjectType() ~= "StatusBar" then
      if o.healthFrame.Hide then o.healthFrame:Hide() end
      o.healthFrame = nil
      o.healthTex = nil
    end
    if not o then
      o = {}
      o.bgFrame = CreateFrame("Frame", nil, parent)
      o.bgTex = o.bgFrame:CreateTexture(nil, "ARTWORK")
      o.bgTex:SetAllPoints(o.bgFrame)
      State.ufBigHBOverlays[key] = o
    end
    if not o.maskFixFrame then
      o.maskFixFrame = CreateFrame("Frame", nil, parent)
      o.maskFixTex = o.maskFixFrame:CreateTexture(nil, "ARTWORK")
      o.maskFixTex:SetAllPoints(o.maskFixFrame)
    end
    if not o.healthFrame then
      o.healthFrame = CreateFrame("StatusBar", nil, parent)
      o.healthFrame:SetMinMaxValues(0, 1)
      o.healthFrame:SetValue(1)
      o.healthFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      if o.healthFrame.SetClipsChildren then o.healthFrame:SetClipsChildren(true) end
      o.healthTex = o.healthFrame:GetStatusBarTexture()
    elseif o.healthFrame.SetClipsChildren then
      o.healthFrame:SetClipsChildren(true)
    end
    if o.dmgAbsorbFrame and o.dmgAbsorbFrame.GetObjectType and o.dmgAbsorbFrame:GetObjectType() ~= "StatusBar" then
      if o.dmgAbsorbFrame.Hide then o.dmgAbsorbFrame:Hide() end
      o.dmgAbsorbFrame = nil
      o.dmgAbsorbTex = nil
    end
    if not o.dmgAbsorbFrame then
      o.dmgAbsorbFrame = CreateFrame("StatusBar", "CCMUFBigHBDmgAbsorb_" .. tostring(key), o.healthFrame)
      o.dmgAbsorbFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      o.dmgAbsorbFrame:SetMinMaxValues(0, 1)
      o.dmgAbsorbFrame:SetValue(0)
      if o.dmgAbsorbFrame.SetClipsChildren then o.dmgAbsorbFrame:SetClipsChildren(true) end
      if o.dmgAbsorbFrame.SetOrientation then o.dmgAbsorbFrame:SetOrientation("HORIZONTAL") end
      if o.dmgAbsorbFrame.SetReverseFill then o.dmgAbsorbFrame:SetReverseFill(false) end
      o.dmgAbsorbTex = o.dmgAbsorbFrame:GetStatusBarTexture()
      if o.dmgAbsorbTex then
        o.dmgAbsorbTex:SetVertexColor(0.65, 0.85, 1.00, 0.90)
        if o.dmgAbsorbTex.SetBlendMode then
          o.dmgAbsorbTex:SetBlendMode("ADD")
        end
      end
      o.dmgAbsorbStripe = o.dmgAbsorbFrame:CreateTexture(nil, "OVERLAY", nil, 1)
      o.dmgAbsorbStripe:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\textures\\stripe_overlay", "REPEAT", "REPEAT")
      o.dmgAbsorbStripe:SetAllPoints(o.dmgAbsorbTex)
      o.dmgAbsorbStripe:SetVertexColor(1, 1, 1, 0.35)
      if o.dmgAbsorbStripe.SetHorizTile then o.dmgAbsorbStripe:SetHorizTile(true) end
      if o.dmgAbsorbStripe.SetVertTile then o.dmgAbsorbStripe:SetVertTile(true) end
      o.dmgAbsorbFrame:Hide()
    end
    if not o.dmgAbsorbGlow then
      o.dmgAbsorbGlow = o.healthFrame:CreateTexture("CCMUFBigHBDmgAbsorbGlow_" .. tostring(key), "OVERLAY", nil, 7)
      o.dmgAbsorbGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
      o.dmgAbsorbGlow:SetVertexColor(0.70, 0.90, 1.00, 0.85)
      if o.dmgAbsorbGlow.SetBlendMode then
        o.dmgAbsorbGlow:SetBlendMode("ADD")
      end
      o.dmgAbsorbGlow:Hide()
    end
    if not o.fullDmgAbsorbFrame then
      o.fullDmgAbsorbFrame = CreateFrame("Frame", "CCMUFBigHBDmgAbsorbFull_" .. tostring(key), o.healthFrame)
      o.fullDmgAbsorbTex = o.fullDmgAbsorbFrame:CreateTexture(nil, "ARTWORK", nil, 7)
      o.fullDmgAbsorbTex:SetAllPoints(o.fullDmgAbsorbFrame)
      o.fullDmgAbsorbTex:SetTexture("Interface\\Buttons\\WHITE8x8")
      o.fullDmgAbsorbTex:SetVertexColor(0.70, 0.90, 1.00, 0.90)
      if o.fullDmgAbsorbTex.SetBlendMode then
        o.fullDmgAbsorbTex:SetBlendMode("ADD")
      end
      o.fullDmgAbsorbFrame:Hide()
    end
    if not o.myHealPredFrame then
      o.myHealPredFrame = CreateFrame("StatusBar", nil, o.healthFrame)
      o.myHealPredFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      o.myHealPredFrame:SetMinMaxValues(0, 1)
      o.myHealPredFrame:SetValue(0)
      o.myHealPredTex = o.myHealPredFrame:GetStatusBarTexture()
      if o.myHealPredTex then o.myHealPredTex:SetVertexColor(0, 0.827, 0, 0.4) end
      o.myHealPredFrame:Hide()
    end
    if not o.otherHealPredFrame then
      o.otherHealPredFrame = CreateFrame("StatusBar", nil, o.healthFrame)
      o.otherHealPredFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      o.otherHealPredFrame:SetMinMaxValues(0, 1)
      o.otherHealPredFrame:SetValue(0)
      o.otherHealPredTex = o.otherHealPredFrame:GetStatusBarTexture()
      if o.otherHealPredTex then o.otherHealPredTex:SetVertexColor(0, 0.631, 0.557, 0.4) end
      o.otherHealPredFrame:Hide()
    end
    if not o.healAbsorbFrame then
      o.healAbsorbFrame = CreateFrame("StatusBar", nil, o.healthFrame)
      o.healAbsorbFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
      o.healAbsorbFrame:SetMinMaxValues(0, 1)
      o.healAbsorbFrame:SetValue(0)
      if o.healAbsorbFrame.SetReverseFill then o.healAbsorbFrame:SetReverseFill(true) end
      o.healAbsorbTex = o.healAbsorbFrame:GetStatusBarTexture()
      if o.healAbsorbTex then o.healAbsorbTex:SetVertexColor(1.0, 0.0, 0.0, 1.0) end
      o.healAbsorbStripe = o.healAbsorbFrame:CreateTexture(nil, "OVERLAY", nil, 1)
      o.healAbsorbStripe:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\textures\\stripe_overlay", "REPEAT", "REPEAT")
      o.healAbsorbStripe:SetAllPoints(o.healAbsorbTex)
      o.healAbsorbStripe:SetVertexColor(1, 1, 1, 0.4)
      if o.healAbsorbStripe.SetHorizTile then o.healAbsorbStripe:SetHorizTile(true) end
      if o.healAbsorbStripe.SetVertTile then o.healAbsorbStripe:SetVertTile(true) end
      o.healAbsorbFrame:Hide()
    end
    o.key = key
    if parent and o.bgFrame and o.bgFrame:GetParent() ~= parent then o.bgFrame:SetParent(parent) end
    if parent and o.healthFrame and o.healthFrame:GetParent() ~= parent then o.healthFrame:SetParent(parent) end
    if parent and o.maskFixFrame and o.maskFixFrame:GetParent() ~= parent then o.maskFixFrame:SetParent(parent) end
    return o
  end
  local function ApplyUFBigHBForFrame(key, bigHBRoot, hp, mp, portrait, isPlayerFrame)
    local enabled = ufEnabled
    local frameTex
    if key == "player" then
      frameTex = PlayerFrame and PlayerFrame.PlayerFrameContainer and PlayerFrame.PlayerFrameContainer.FrameTexture
    elseif key == "target" then
      frameTex = TargetFrame and TargetFrame.TargetFrameContainer and TargetFrame.TargetFrameContainer.FrameTexture
    elseif key == "focus" then
      frameTex = FocusFrame and FocusFrame.TargetFrameContainer and FocusFrame.TargetFrameContainer.FrameTexture
    end
    if isPlayerFrame then
      enabled = enabled and profile.ufBigHBPlayerEnabled == true
    elseif key == "target" then
      enabled = enabled and profile.ufBigHBTargetEnabled == true
    elseif key == "focus" then
      enabled = enabled and profile.ufBigHBFocusEnabled == true
    else
      enabled = false
    end
    local contextual = (key == "player" and PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual) or nil
    if not enabled or not bigHBRoot or not hp or not hp.GetWidth then
      local existing = State.ufBigHBOverlays and State.ufBigHBOverlays[key]
      local restoreHP = hp or (existing and existing.origHP) or nil
      if restoreHP and existing then
        SetUFBaseHealthBarCovered(existing, restoreHP, false, bigHBRoot and bigHBRoot.HealthBarsContainer, bigHBRoot)
      end
      if key == "player" then
        SetUFBigHBPlayerTextsHidden(false)
        SetUFBigHBAuxPlayerTextsHidden(bigHBRoot, false)
      end
      if frameTex and existing and existing.frameTexSaved then
        if existing.frameTexParent and frameTex.SetParent then
          frameTex:SetParent(existing.frameTexParent)
        end
        if existing.frameTexPoints and frameTex.ClearAllPoints and frameTex.SetPoint then
          frameTex:ClearAllPoints()
          for i = 1, #existing.frameTexPoints do
            local pt = existing.frameTexPoints[i]
            if pt and type(pt[1]) == "string" then
              pcall(frameTex.SetPoint, frameTex, pt[1], pt[2], pt[3], pt[4], pt[5])
            end
          end
        end
        if existing.frameTexStrata and frameTex.SetFrameStrata then frameTex:SetFrameStrata(existing.frameTexStrata) end
        if existing.frameTexLevel ~= nil and frameTex.SetFrameLevel then frameTex:SetFrameLevel(existing.frameTexLevel) end
        if existing.frameTexDrawLayer and frameTex.SetDrawLayer then
          frameTex:SetDrawLayer(existing.frameTexDrawLayer, existing.frameTexDrawSubLevel or 0)
        end
        if existing.frameTexAlpha ~= nil and frameTex.SetAlpha then frameTex:SetAlpha(existing.frameTexAlpha) end
        if existing.frameTexShown and frameTex.Show then frameTex:Show() elseif frameTex.Hide then frameTex:Hide() end
        if existing.frameTexHost and existing.frameTexHost.Hide then
          existing.frameTexHost:Hide()
        end
      end
      if contextual and existing and existing.contextualSaved then
        if existing.contextualStrata and contextual.SetFrameStrata then contextual:SetFrameStrata(existing.contextualStrata) end
        if existing.contextualLevel ~= nil and contextual.SetFrameLevel then contextual:SetFrameLevel(existing.contextualLevel) end
        if existing.contextualAlpha ~= nil and contextual.SetAlpha then contextual:SetAlpha(existing.contextualAlpha) end
        if existing.contextualShown and contextual.Show then contextual:Show() elseif contextual.Hide then contextual:Hide() end
      end
      if (key == "target" or key == "focus") and bigHBRoot and bigHBRoot.ReputationColor and existing and existing.repColorSaved then
        if existing.repColorShown and bigHBRoot.ReputationColor.Show then bigHBRoot.ReputationColor:Show() end
      end
      if (key == "target" or key == "focus") and existing and existing.targetCtxSaved then
        local contentFrame = bigHBRoot and bigHBRoot.GetParent and bigHBRoot:GetParent()
        local ctxFrame = contentFrame and contentFrame.TargetFrameContentContextual
        if ctxFrame then
          if existing.targetCtxStrata and ctxFrame.SetFrameStrata then ctxFrame:SetFrameStrata(existing.targetCtxStrata) end
          if existing.targetCtxLevel ~= nil and ctxFrame.SetFrameLevel then ctxFrame:SetFrameLevel(existing.targetCtxLevel) end
        end
      end
      if (key == "target" or key == "focus") and portrait and existing and existing.portraitModelSaved then
        local portraitModel = portrait.Portrait
        if portraitModel then
          if existing.portraitModelStrata and portraitModel.SetFrameStrata then portraitModel:SetFrameStrata(existing.portraitModelStrata) end
          if existing.portraitModelLevel ~= nil and portraitModel.SetFrameLevel then portraitModel:SetFrameLevel(existing.portraitModelLevel) end
        end
      end
      if (key == "target" or key == "focus") and portrait and existing and existing.eliteTexSaved then
        local bossTex = portrait.BossPortraitFrameTexture
        if bossTex and existing.eliteTexOrigParent then
          bossTex:SetParent(existing.eliteTexOrigParent)
        end
        if existing.eliteTexHost and existing.eliteTexHost.Hide then existing.eliteTexHost:Hide() end
      end
      if (key == "target" or key == "focus") and bigHBRoot and existing and existing.highLevelTexSaved then
        local contentFrame = bigHBRoot.GetParent and bigHBRoot:GetParent()
        local ctxFrame = contentFrame and contentFrame.TargetFrameContentContextual
        local highLvlTex = ctxFrame and ctxFrame.HighLevelTexture
        if highLvlTex and existing.highLevelTexShown and highLvlTex.Show then highLvlTex:Show() end
      end
      if key == "target" and bigHBRoot and existing then
        if existing.targetNameSaved and bigHBRoot.Name then
          local restoreName = GetUFBigHBUnitName("target")
          if restoreName and bigHBRoot.Name.SetText then bigHBRoot.Name:SetText(restoreName) end
          if existing.targetNameShown and bigHBRoot.Name.Show then bigHBRoot.Name:Show() elseif bigHBRoot.Name.Hide then bigHBRoot.Name:Hide() end
          if bigHBRoot.Name.SetFont and existing.targetNameFont and existing.targetNameFontSize then
            pcall(bigHBRoot.Name.SetFont, bigHBRoot.Name, existing.targetNameFont, existing.targetNameFontSize, existing.targetNameFontFlags or "")
          end
          if bigHBRoot.Name.SetTextColor and existing.targetNameColorR then
            bigHBRoot.Name:SetTextColor(existing.targetNameColorR, existing.targetNameColorG, existing.targetNameColorB)
          end
          if bigHBRoot.Name.SetJustifyH and existing.targetNameJustifyH then
            bigHBRoot.Name:SetJustifyH(existing.targetNameJustifyH)
          end
          if bigHBRoot.Name.SetWidth and existing.targetNameOrigWidth ~= nil then
            bigHBRoot.Name:SetWidth(existing.targetNameOrigWidth)
          end
          if bigHBRoot.Name.SetWordWrap and existing.targetNameOrigWordWrap ~= nil then
            bigHBRoot.Name:SetWordWrap(existing.targetNameOrigWordWrap)
          end
          if bigHBRoot.Name.SetNonSpaceWrap and existing.targetNameOrigNonSpaceWrap ~= nil then
            bigHBRoot.Name:SetNonSpaceWrap(existing.targetNameOrigNonSpaceWrap)
          end
          if existing.targetNamePoint and bigHBRoot.Name.ClearAllPoints and bigHBRoot.Name.SetPoint then
            bigHBRoot.Name:ClearAllPoints()
            bigHBRoot.Name:SetPoint(existing.targetNamePoint, existing.targetNameRelTo, existing.targetNameRelPt, existing.targetNameOrigX or 0, existing.targetNameOrigY or 0)
          end
        end
        if existing.targetLevelSaved and bigHBRoot.LevelText then
          if existing.targetLevelShown and bigHBRoot.LevelText.Show then bigHBRoot.LevelText:Show() elseif bigHBRoot.LevelText.Hide then bigHBRoot.LevelText:Hide() end
          if bigHBRoot.LevelText.SetFont and existing.targetLevelFont and existing.targetLevelFontSize then
            pcall(bigHBRoot.LevelText.SetFont, bigHBRoot.LevelText, existing.targetLevelFont, existing.targetLevelFontSize, existing.targetLevelFontFlags or "")
          end
          if bigHBRoot.LevelText.SetTextColor and existing.targetLevelColorR then
            bigHBRoot.LevelText:SetTextColor(existing.targetLevelColorR, existing.targetLevelColorG, existing.targetLevelColorB)
          end
          if existing.targetLevelPoint and bigHBRoot.LevelText.ClearAllPoints and bigHBRoot.LevelText.SetPoint then
            bigHBRoot.LevelText:ClearAllPoints()
            bigHBRoot.LevelText:SetPoint(existing.targetLevelPoint, existing.targetLevelRelTo, existing.targetLevelRelPt, existing.targetLevelOrigX or 0, existing.targetLevelOrigY or 0)
          end
        end
      end
      if key == "focus" and bigHBRoot and existing then
        if existing.nameColorSaved and bigHBRoot.Name then
          local restoreName = GetUFBigHBUnitName("focus")
          if restoreName and bigHBRoot.Name.SetText then bigHBRoot.Name:SetText(restoreName) end
          if existing.nameOrigShown and bigHBRoot.Name.Show then bigHBRoot.Name:Show() elseif bigHBRoot.Name.Hide then bigHBRoot.Name:Hide() end
          if bigHBRoot.Name.SetFont and existing.nameOrigFont and existing.nameOrigFontSize then
            pcall(bigHBRoot.Name.SetFont, bigHBRoot.Name, existing.nameOrigFont, existing.nameOrigFontSize, existing.nameOrigFontFlags or "")
          end
          if bigHBRoot.Name.SetTextColor and existing.nameOrigColorR then
            bigHBRoot.Name:SetTextColor(existing.nameOrigColorR, existing.nameOrigColorG, existing.nameOrigColorB)
          end
          if bigHBRoot.Name.SetJustifyH and existing.nameOrigJustifyH then
            bigHBRoot.Name:SetJustifyH(existing.nameOrigJustifyH)
          end
          if bigHBRoot.Name.SetWidth and existing.nameOrigWidth ~= nil then
            bigHBRoot.Name:SetWidth(existing.nameOrigWidth)
          end
          if bigHBRoot.Name.SetWordWrap and existing.nameOrigWordWrap ~= nil then
            bigHBRoot.Name:SetWordWrap(existing.nameOrigWordWrap)
          end
          if bigHBRoot.Name.SetNonSpaceWrap and existing.nameOrigNonSpaceWrap ~= nil then
            bigHBRoot.Name:SetNonSpaceWrap(existing.nameOrigNonSpaceWrap)
          end
          if existing.namePoint and bigHBRoot.Name.ClearAllPoints and bigHBRoot.Name.SetPoint then
            bigHBRoot.Name:ClearAllPoints()
            bigHBRoot.Name:SetPoint(existing.namePoint, existing.nameRelTo, existing.nameRelPt, existing.nameOrigX or 0, existing.nameOrigY or 0)
          end
        end
        if existing.levelColorSaved and bigHBRoot.LevelText then
          if existing.levelOrigShown and bigHBRoot.LevelText.Show then bigHBRoot.LevelText:Show() elseif bigHBRoot.LevelText.Hide then bigHBRoot.LevelText:Hide() end
          if bigHBRoot.LevelText.SetFont and existing.levelOrigFont and existing.levelOrigFontSize then
            pcall(bigHBRoot.LevelText.SetFont, bigHBRoot.LevelText, existing.levelOrigFont, existing.levelOrigFontSize, existing.levelOrigFontFlags or "")
          end
          if bigHBRoot.LevelText.SetTextColor and existing.levelOrigColorR then
            bigHBRoot.LevelText:SetTextColor(existing.levelOrigColorR, existing.levelOrigColorG, existing.levelOrigColorB)
          end
          if existing.levelPoint and bigHBRoot.LevelText.ClearAllPoints and bigHBRoot.LevelText.SetPoint then
            bigHBRoot.LevelText:ClearAllPoints()
            bigHBRoot.LevelText:SetPoint(existing.levelPoint, existing.levelRelTo, existing.levelRelPt, existing.levelOrigX or 0, existing.levelOrigY or 0)
          end
        end
      end
      if key == "player" and existing then
        local nameEl = _G["PlayerName"]
        if nameEl and existing.nameColorSaved then
          local restoreName = GetUFBigHBUnitName("player")
          if restoreName and nameEl.SetText then nameEl:SetText(restoreName) end
          if nameEl.SetFont and existing.nameOrigFont and existing.nameOrigFontSize then
            pcall(nameEl.SetFont, nameEl, existing.nameOrigFont, existing.nameOrigFontSize, existing.nameOrigFontFlags or "")
          end
          if nameEl.SetTextColor and existing.nameOrigColorR then
            nameEl:SetTextColor(existing.nameOrigColorR, existing.nameOrigColorG, existing.nameOrigColorB)
          end
          if nameEl.SetJustifyH and existing.nameOrigJustifyH then
            nameEl:SetJustifyH(existing.nameOrigJustifyH)
          end
          if nameEl.SetWidth and existing.nameOrigWidth ~= nil then
            nameEl:SetWidth(existing.nameOrigWidth)
          end
          if nameEl.SetWordWrap and existing.nameOrigWordWrap ~= nil then
            nameEl:SetWordWrap(existing.nameOrigWordWrap)
          end
          if nameEl.SetNonSpaceWrap and existing.nameOrigNonSpaceWrap ~= nil then
            nameEl:SetNonSpaceWrap(existing.nameOrigNonSpaceWrap)
          end
          if existing.namePoint and nameEl.ClearAllPoints and nameEl.SetPoint then
            nameEl:ClearAllPoints()
            nameEl:SetPoint(existing.namePoint, existing.nameRelTo, existing.nameRelPt, existing.nameOrigX or 0, existing.nameOrigY or 0)
          end
        end
        local levelEl = _G["PlayerLevelText"]
        if levelEl and existing.levelColorSaved then
          if levelEl.SetFont and existing.levelOrigFont and existing.levelOrigFontSize then
            pcall(levelEl.SetFont, levelEl, existing.levelOrigFont, existing.levelOrigFontSize, existing.levelOrigFontFlags or "")
          end
          if levelEl.SetTextColor and existing.levelOrigColorR then
            levelEl:SetTextColor(existing.levelOrigColorR, existing.levelOrigColorG, existing.levelOrigColorB)
          end
          if existing.levelPoint and levelEl.ClearAllPoints and levelEl.SetPoint then
            levelEl:ClearAllPoints()
            levelEl:SetPoint(existing.levelPoint, existing.levelRelTo, existing.levelRelPt, existing.levelOrigX or 0, existing.levelOrigY or 0)
          end
        end
      end
      HideUFBigHBOverlay(key)
      return
    end
    local parent
    if key == "player" then
      parent = PlayerFrame and PlayerFrame.PlayerFrameContainer
    else
      if portrait and portrait.Portrait then
        parent = portrait
      else
        parent = (portrait and portrait.GetParent and portrait:GetParent()) or bigHBRoot
      end
    end
    if not parent then
      parent = (bigHBRoot and bigHBRoot.HealthBarsContainer) or bigHBRoot
    end
    local o = EnsureUFBigHBOverlay(key, parent)
    if not o or not o.bgFrame or not o.healthFrame then return end
    if isPlayerFrame then
      if frameTex and o.frameTexSaved then
        if o.frameTexParent and frameTex.SetParent then frameTex:SetParent(o.frameTexParent) end
        if o.frameTexPoints and frameTex.ClearAllPoints and frameTex.SetPoint then
          frameTex:ClearAllPoints()
          for _, pt in ipairs(o.frameTexPoints) do
            if pt and type(pt[1]) == "string" then pcall(frameTex.SetPoint, frameTex, pt[1], pt[2], pt[3], pt[4], pt[5]) end
          end
        end
        if o.frameTexStrata and frameTex.SetFrameStrata then frameTex:SetFrameStrata(o.frameTexStrata) end
        if o.frameTexLevel and frameTex.SetFrameLevel then frameTex:SetFrameLevel(o.frameTexLevel) end
        if o.frameTexDrawLayer and frameTex.SetDrawLayer then frameTex:SetDrawLayer(o.frameTexDrawLayer, o.frameTexDrawSubLevel or 0) end
        if o.frameTexAlpha and frameTex.SetAlpha then frameTex:SetAlpha(o.frameTexAlpha) end
        if o.frameTexHost and o.frameTexHost.Hide then o.frameTexHost:Hide() end
        o.frameTexSaved = nil
      end
      if contextual and o.contextualSaved then
        if o.contextualStrata and contextual.SetFrameStrata then contextual:SetFrameStrata(o.contextualStrata) end
        if o.contextualLevel and contextual.SetFrameLevel then contextual:SetFrameLevel(o.contextualLevel) end
        if o.contextualAlpha and contextual.SetAlpha then contextual:SetAlpha(o.contextualAlpha) end
        o.contextualSaved = nil
      end
    end
    local shapePath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_health_player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_health_other"
    local fillPath = shapePath
    if profile.ufUseCustomTextures and profile.ufHealthTexture then
      local lsmPath = addonTable.FetchLSMStatusBar and addonTable:FetchLSMStatusBar(profile.ufHealthTexture)
      if lsmPath then
        fillPath = lsmPath
      elseif texturePaths[profile.ufHealthTexture] then
        fillPath = texturePaths[profile.ufHealthTexture]
      end
    end
    local bgPath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_bg_player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_bg_other"
    local dmgAbsorbPathPrimary = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_player.tga"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_other.tga"
    local dmgAbsorbPathLegacy = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\absorb player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\absorb other"
    local hX, hY, hW, hH, bX, bY, bW, bH, hScalePct, bScalePct, mX, mY, mW, mH, mScalePct
    if isPlayerFrame then
      hW = -1.0; hH = 11.5; hX = -0.5; hY = 8.0; hScalePct = 0.0
      bW = 16.0; bH = 32.5; bX = -4.5; bY = 3.0; bScalePct = 0.0
      mW = -68.5; mH = -21.0; mX = -10.0; mY = -7.5; mScalePct = 123.5
    else
      hW = 2.5; hH = 11.0; hX = 3.0; hY = 7.0; hScalePct = 0.0
      bW = 19.5; bH = 30.5; bX = 7.0; bY = 1.0; bScalePct = 0.0
      mW = -76.5; mH = 18.5; mX = 84.0; mY = 1.0; mScalePct = -8.5
    end
    local hpW = hp:GetWidth() or 0
    local hpH = hp:GetHeight() or 0
    if issecretvalue and (issecretvalue(hpW) or issecretvalue(hpH)) then return end
    if hpW < 1 then hpW = 1 end
    if hpH < 1 then hpH = 1 end
    local bgSource = hp
    local anchorPower = bgSource
    local mpW = bgSource:GetWidth() or 0
    local mpH = bgSource:GetHeight() or 0
    if issecretvalue and (issecretvalue(mpW) or issecretvalue(mpH)) then mpW = hpW; mpH = hpH end
    if mpW < 1 then mpW = hpW end
    if mpH < 1 then mpH = hpH end
    local healthW2 = hpW + hW
    local healthH2 = hpH + hH
    local hScale = 1 + (hScalePct / 100)
    if hScale < 0.1 then hScale = 0.1 end
    healthW2 = healthW2 * hScale
    healthH2 = healthH2 * hScale
    if healthW2 < 1 then healthW2 = 1 end
    if healthH2 < 1 then healthH2 = 1 end
    local bgW2 = mpW + bW
    local bgH2 = mpH + bH
    local bScale = 1 + (bScalePct / 100)
    if bScale < 0.1 then bScale = 0.1 end
    bgW2 = bgW2 * bScale
    bgH2 = bgH2 * bScale
    if isPlayerFrame then
      local bottomContainer = PlayerFrameBottomManagedFramesContainer
      if bottomContainer and bottomContainer.IsShown and bottomContainer:IsShown() then
        -- Only adjust mask if the container has a real second power bar (StatusBar),
        -- not just class resource indicators (combo points, arcane charges, etc.)
        local hasSecondPowerBar = false
        if bottomContainer.GetChildren then
          for i = 1, select('#', bottomContainer:GetChildren()) do
            local child = select(i, bottomContainer:GetChildren())
            if child and child.IsShown and child:IsShown() and child.IsObjectType then
              local okType, isBar = pcall(child.IsObjectType, child, "StatusBar")
              if okType and isBar then
                hasSecondPowerBar = true
                break
              end
            end
          end
        end
        if hasSecondPowerBar then
          mY = mY - 5
        end
      end
    end
    if bgW2 < 1 then bgW2 = 1 end
    if bgH2 < 1 then bgH2 = 1 end
    local maskFixW = bgW2 + mW
    local maskFixH = bgH2 + mH
    local mScale = 1 + (mScalePct / 100)
    if mScale < 0.1 then mScale = 0.1 end
    maskFixW = maskFixW * mScale
    maskFixH = maskFixH * mScale
    if maskFixW < 1 then maskFixW = 1 end
    if maskFixH < 1 then maskFixH = 1 end
    local portraitAnchor = portrait
    if portraitAnchor and portraitAnchor.Portrait then
      portraitAnchor = portraitAnchor.Portrait
    elseif isPlayerFrame then
      portraitAnchor = PlayerFrame and PlayerFrame.PlayerFrameContainer and (PlayerFrame.PlayerFrameContainer.PlayerPortrait or PlayerFrame.PlayerFrameContainer.Portrait)
    end
    local function GetSafeCenter(frameObj)
      if not frameObj or not frameObj.GetCenter then return nil, nil end
      local cx, cy = frameObj:GetCenter()
      if issecretvalue and (issecretvalue(cx) or issecretvalue(cy)) then
        return nil, nil
      end
      if type(cx) ~= "number" or type(cy) ~= "number" then
        return nil, nil
      end
      return cx, cy
    end
    local healthAnchor = hp
    local bgAnchor = anchorPower
    local healthAnchorX, healthAnchorY = hX, hY
    local bgAnchorX, bgAnchorY = bX, bY
    if portraitAnchor and isPlayerFrame then
      local px, py = GetSafeCenter(portraitAnchor)
      if px and py then
        local hx2, hy2 = GetSafeCenter(hp)
        local ax, ay = GetSafeCenter(bgSource)
        if hx2 and hy2 then
          o.fixedHealthBaseX = (hx2 - px)
          o.fixedHealthBaseY = (hy2 - py)
        else
          o.fixedHealthBaseX = nil
          o.fixedHealthBaseY = nil
        end
        if ax and ay then
          o.fixedBgBaseX = (ax - px)
          o.fixedBgBaseY = (ay - py)
        else
          o.fixedBgBaseX = nil
          o.fixedBgBaseY = nil
        end
        if o.fixedHealthBaseX and o.fixedHealthBaseY then
          healthAnchor = portraitAnchor
          healthAnchorX = o.fixedHealthBaseX + hX
          healthAnchorY = o.fixedHealthBaseY + hY
        end
        if o.fixedBgBaseX and o.fixedBgBaseY then
          bgAnchor = portraitAnchor
          bgAnchorX = o.fixedBgBaseX + bX
          bgAnchorY = o.fixedBgBaseY + bY
        end
      end
    end
    local hLevel = hp.GetFrameLevel and (hp:GetFrameLevel() or 1) or 1
    local pLevel = anchorPower.GetFrameLevel and (anchorPower:GetFrameLevel() or (hLevel + 3)) or (hLevel + 3)
    local frameTexLevel = (frameTex and frameTex.GetFrameLevel and frameTex:GetFrameLevel()) or 0
    local portraitLevel = (portraitAnchor and portraitAnchor.GetFrameLevel and portraitAnchor:GetFrameLevel())
      or (portrait and portrait.GetFrameLevel and portrait:GetFrameLevel())
      or nil
    if pLevel < 3 then pLevel = 3 end
    local ovLevel = pLevel - 1
    local bgLevel = pLevel - 2
    if bgLevel < 1 then bgLevel = 1 end
    if bgLevel < frameTexLevel then bgLevel = frameTexLevel end
    if type(portraitLevel) == "number" then
      local cap = portraitLevel - 1
      if ovLevel > cap then ovLevel = cap end
      if bgLevel > cap then bgLevel = cap end
      if ovLevel < 1 then ovLevel = 1 end
      if bgLevel < 1 then bgLevel = 1 end
      if bgLevel >= ovLevel then bgLevel = math.max(1, ovLevel - 1) end
    end
    if bgLevel < frameTexLevel then bgLevel = frameTexLevel end
    if bgLevel >= ovLevel then
      ovLevel = bgLevel + 1
      if type(portraitLevel) == "number" then
        local cap = portraitLevel - 1
        if ovLevel > cap then ovLevel = cap end
      end
      if ovLevel < 1 then ovLevel = 1 end
      if bgLevel >= ovLevel then
        bgLevel = math.max(1, ovLevel - 1)
      end
    end
    if frameTex and key == "player" then
      if not o.frameTexSaved then
        o.frameTexSaved = true
        o.frameTexParent = frameTex.GetParent and frameTex:GetParent() or nil
        o.frameTexPoints = {}
        if frameTex.GetNumPoints and frameTex.GetPoint then
          local n = frameTex:GetNumPoints() or 0
          for i = 1, n do
            local p, rel, rp, x, y = frameTex:GetPoint(i)
            if type(p) == "string" then
              o.frameTexPoints[#o.frameTexPoints + 1] = {p, rel, rp, x, y}
            end
          end
        end
        o.frameTexStrata = frameTex.GetFrameStrata and frameTex:GetFrameStrata() or nil
        o.frameTexLevel = frameTex.GetFrameLevel and frameTex:GetFrameLevel() or nil
        if frameTex.GetDrawLayer then
          o.frameTexDrawLayer, o.frameTexDrawSubLevel = frameTex:GetDrawLayer()
        end
        o.frameTexAlpha = frameTex.GetAlpha and frameTex:GetAlpha() or nil
        o.frameTexShown = frameTex.IsShown and frameTex:IsShown() or nil
      end
      if frameTex.SetFrameStrata then
        frameTex:SetFrameStrata("BACKGROUND")
      end
      if frameTex.SetFrameLevel then
        frameTex:SetFrameLevel(0)
      end
      if not o.frameTexHost then
        o.frameTexHost = CreateFrame("Frame", nil, UIParent)
      end
      if o.frameTexHost then
        if o.frameTexHost.SetFrameStrata then o.frameTexHost:SetFrameStrata("BACKGROUND") end
        if o.frameTexHost.SetFrameLevel then o.frameTexHost:SetFrameLevel(0) end
        if o.frameTexParent and o.frameTexHost.SetParent then
          o.frameTexHost:SetParent(o.frameTexParent)
        end
        if o.frameTexParent and o.frameTexHost.ClearAllPoints and o.frameTexHost.SetPoint then
          o.frameTexHost:ClearAllPoints()
          o.frameTexHost:SetPoint("TOPLEFT", o.frameTexParent, "TOPLEFT", 0, 0)
          o.frameTexHost:SetPoint("BOTTOMRIGHT", o.frameTexParent, "BOTTOMRIGHT", 0, 0)
        end
        if frameTex.SetParent and frameTex.GetParent and frameTex:GetParent() ~= o.frameTexHost then
          frameTex:SetParent(o.frameTexHost)
        end
        if frameTex.ClearAllPoints and frameTex.SetPoint then
          frameTex:ClearAllPoints()
          local restored = false
          if o.frameTexPoints and #o.frameTexPoints > 0 then
            for i = 1, #o.frameTexPoints do
              local pt = o.frameTexPoints[i]
              if pt and type(pt[1]) == "string" then
                pcall(frameTex.SetPoint, frameTex, pt[1], pt[2], pt[3], pt[4], pt[5])
                restored = true
              end
            end
          end
          if (not restored) and frameTex.SetAllPoints then
            frameTex:SetAllPoints(o.frameTexHost)
          end
        end
        if o.frameTexHost.Show then o.frameTexHost:Show() end
      end
      if contextual then
        if not o.contextualSaved then
          o.contextualSaved = true
          o.contextualStrata = contextual.GetFrameStrata and contextual:GetFrameStrata() or nil
          o.contextualLevel = contextual.GetFrameLevel and contextual:GetFrameLevel() or nil
          o.contextualAlpha = contextual.GetAlpha and contextual:GetAlpha() or nil
          o.contextualShown = contextual.IsShown and contextual:IsShown() or nil
        end
        if contextual.SetFrameStrata then contextual:SetFrameStrata("BACKGROUND") end
        if contextual.SetFrameLevel then contextual:SetFrameLevel(0) end
        if contextual.SetAlpha then contextual:SetAlpha(o.contextualAlpha or 1) end
        if contextual.Show then contextual:Show() end
      end
      if frameTex.SetDrawLayer then
        frameTex:SetDrawLayer("BACKGROUND", -8)
      end
      if frameTex.SetAlpha then frameTex:SetAlpha(o.frameTexAlpha or 1) end
      if frameTex.Show then frameTex:Show() end
    elseif frameTex then
      if not o.frameTexSaved then
        o.frameTexSaved = true
        o.frameTexParent = frameTex.GetParent and frameTex:GetParent() or nil
        o.frameTexPoints = {}
        if frameTex.GetNumPoints and frameTex.GetPoint then
          local n = frameTex:GetNumPoints() or 0
          for i = 1, n do
            local p, rel, rp, x, y = frameTex:GetPoint(i)
            if type(p) == "string" then
              o.frameTexPoints[#o.frameTexPoints + 1] = {p, rel, rp, x, y}
            end
          end
        end
        o.frameTexStrata = frameTex.GetFrameStrata and frameTex:GetFrameStrata() or nil
        o.frameTexLevel = frameTex.GetFrameLevel and frameTex:GetFrameLevel() or nil
        if frameTex.GetDrawLayer then
          o.frameTexDrawLayer, o.frameTexDrawSubLevel = frameTex:GetDrawLayer()
        end
        o.frameTexAlpha = frameTex.GetAlpha and frameTex:GetAlpha() or nil
        o.frameTexShown = frameTex.IsShown and frameTex:IsShown() or nil
      end
      if frameTex.SetFrameStrata then
        frameTex:SetFrameStrata("BACKGROUND")
      end
      if frameTex.SetFrameLevel then
        frameTex:SetFrameLevel(0)
      end
      if not o.frameTexHost then
        o.frameTexHost = CreateFrame("Frame", nil, UIParent)
      end
      if o.frameTexHost then
        if o.frameTexHost.SetFrameStrata then o.frameTexHost:SetFrameStrata("BACKGROUND") end
        if o.frameTexHost.SetFrameLevel then o.frameTexHost:SetFrameLevel(0) end
        if o.frameTexParent and o.frameTexHost.SetParent then
          o.frameTexHost:SetParent(o.frameTexParent)
        end
        if o.frameTexParent and o.frameTexHost.ClearAllPoints and o.frameTexHost.SetPoint then
          o.frameTexHost:ClearAllPoints()
          o.frameTexHost:SetPoint("TOPLEFT", o.frameTexParent, "TOPLEFT", 0, 0)
          o.frameTexHost:SetPoint("BOTTOMRIGHT", o.frameTexParent, "BOTTOMRIGHT", 0, 0)
        end
        if frameTex.SetParent and frameTex.GetParent and frameTex:GetParent() ~= o.frameTexHost then
          frameTex:SetParent(o.frameTexHost)
        end
        if frameTex.ClearAllPoints and frameTex.SetPoint then
          frameTex:ClearAllPoints()
          local restored = false
          if o.frameTexPoints and #o.frameTexPoints > 0 then
            for i = 1, #o.frameTexPoints do
              local pt = o.frameTexPoints[i]
              if pt and type(pt[1]) == "string" then
                pcall(frameTex.SetPoint, frameTex, pt[1], pt[2], pt[3], pt[4], pt[5])
                restored = true
              end
            end
          end
          if (not restored) and frameTex.SetAllPoints then
            frameTex:SetAllPoints(o.frameTexHost)
          end
        end
        if o.frameTexHost.Show then o.frameTexHost:Show() end
      end
      if frameTex.SetDrawLayer then
        frameTex:SetDrawLayer("BACKGROUND", -8)
      end
      if frameTex.SetAlpha then frameTex:SetAlpha(o.frameTexAlpha or 1) end
      if frameTex.Show then frameTex:Show() end
    end
    if key == "player" then
      SetUFBigHBPlayerTextsHidden(true)
      SetUFBigHBAuxPlayerTextsHidden(bigHBRoot, true)
    end
    local strata = (anchorPower and anchorPower.GetFrameStrata and anchorPower:GetFrameStrata()) or "LOW"
    o.bgFrame:SetFrameStrata(strata)
    o.healthFrame:SetFrameStrata(strata)
    o.maskFixFrame:SetFrameStrata(strata)
    o.bgFrame:SetFrameLevel(bgLevel)
    local healthLevel = math.max(bgLevel + 1, ovLevel)
    o.healthFrame:SetFrameLevel(healthLevel)
    if o.dmgAbsorbFrame then
      if healthLevel <= (bgLevel + 1) then
        healthLevel = bgLevel + 2
        o.healthFrame:SetFrameLevel(healthLevel)
      end
      o.dmgAbsorbFrame:SetFrameStrata(strata)
      o.dmgAbsorbFrame:SetFrameLevel(math.max(1, healthLevel - 1))
    end
    if o.fullDmgAbsorbFrame then
      o.fullDmgAbsorbFrame:SetFrameStrata(strata)
      o.fullDmgAbsorbFrame:SetFrameLevel(math.max(1, healthLevel - 1))
    end
    local healPredLevel = math.max(1, healthLevel - 1)
    if o.myHealPredFrame then
      o.myHealPredFrame:SetFrameStrata(strata)
      o.myHealPredFrame:SetFrameLevel(healPredLevel)
    end
    if o.otherHealPredFrame then
      o.otherHealPredFrame:SetFrameStrata(strata)
      o.otherHealPredFrame:SetFrameLevel(healPredLevel)
    end
    if o.healAbsorbFrame then
      o.healAbsorbFrame:SetFrameStrata(strata)
      o.healAbsorbFrame:SetFrameLevel(healthLevel + 1)
    end
    if isPlayerFrame then
      o.maskFixFrame:SetFrameLevel(math.max(1, healthLevel + 5))
    else
      o.maskFixFrame:SetFrameLevel(math.max(1, healthLevel + 3))
    end
    if (key == "target" or key == "focus") and portrait and portrait.SetFrameStrata and portrait.SetFrameLevel then
      portrait:SetFrameStrata(strata)
      portrait:SetFrameLevel(math.max(1, healthLevel + 2))
      local bossTex = portrait.BossPortraitFrameTexture
      if bossTex then
        if not o.eliteTexHost then
          o.eliteTexHost = CreateFrame("Frame", nil, portrait)
          o.eliteTexHost:SetAllPoints(portrait)
        end
        o.eliteTexHost:SetFrameStrata(strata)
        o.eliteTexHost:SetFrameLevel(math.max(1, healthLevel + 4))
        o.eliteTexHost:Show()
        if not o.eliteTexSaved then
          o.eliteTexSaved = true
          o.eliteTexOrigParent = bossTex:GetParent()
        end
        bossTex:SetParent(o.eliteTexHost)
      end
    end
    if (key == "target" or key == "focus") then
      local contentFrame = bigHBRoot and bigHBRoot.GetParent and bigHBRoot:GetParent()
      local ctxFrame = contentFrame and contentFrame.TargetFrameContentContextual
      if ctxFrame and ctxFrame.SetFrameStrata and ctxFrame.SetFrameLevel then
        if not o.targetCtxSaved then
          o.targetCtxSaved = true
          o.targetCtxStrata = ctxFrame.GetFrameStrata and ctxFrame:GetFrameStrata() or nil
          o.targetCtxLevel = ctxFrame.GetFrameLevel and ctxFrame:GetFrameLevel() or nil
        end
        ctxFrame:SetFrameStrata(strata)
        ctxFrame:SetFrameLevel(math.max(1, healthLevel + 5))
      end
    end
    o.bgFrame:ClearAllPoints()
    o.bgFrame:SetPoint("CENTER", bgAnchor, "CENTER", bgAnchorX, bgAnchorY)
    o.bgFrame:SetSize(bgW2, bgH2)
    o.maskFixFrame:ClearAllPoints()
    o.maskFixFrame:SetPoint("CENTER", bgAnchor, "CENTER", bgAnchorX + mX, bgAnchorY + mY)
    o.maskFixFrame:SetSize(maskFixW, maskFixH)
    o.healthFrame:ClearAllPoints()
    o.healthFrame:SetPoint("CENTER", healthAnchor, "CENTER", healthAnchorX, healthAnchorY)
    o.healthFrame:SetSize(healthW2, healthH2)
    o.bgTex:SetTexture(bgPath)
    if o.bgTex.SetDrawLayer then
      o.bgTex:SetDrawLayer("ARTWORK", 1)
    end
    o.bgTex:SetVertexColor(bigHBBorderR, bigHBBorderG, bigHBBorderB, 1)
    o.healthFrame:SetStatusBarTexture(fillPath)
    o.healthTex = o.healthFrame:GetStatusBarTexture() or o.healthTex
    if not o.shapeMask then
      o.shapeMask = o.healthFrame:CreateMaskTexture()
      o.shapeMask:SetAllPoints(o.healthFrame)
    end
    o.shapeMask:SetTexture(shapePath)
    o.healthTex:AddMaskTexture(o.shapeMask)
    if o.dmgAbsorbTex then
      if o.dmgAbsorbFrame and o.dmgAbsorbFrame.SetStatusBarTexture then
        o.dmgAbsorbFrame:SetStatusBarTexture(dmgAbsorbPathPrimary)
      end
      o.dmgAbsorbTex = o.dmgAbsorbFrame and o.dmgAbsorbFrame.GetStatusBarTexture and o.dmgAbsorbFrame:GetStatusBarTexture() or o.dmgAbsorbTex
      o.dmgAbsorbTex:SetTexture(dmgAbsorbPathPrimary)
      if o.dmgAbsorbTex.SetTexCoord then
        o.dmgAbsorbTex:SetTexCoord(0, 1, 0, 1)
      end
      o.dmgAbsorbTex:SetVertexColor(0.65, 0.85, 1.00, 0.90)
      if o.dmgAbsorbTex.SetBlendMode then
        o.dmgAbsorbTex:SetBlendMode("ADD")
      end
    end
    if o.fullDmgAbsorbTex then
      local fullPath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_player_full.tga"
        or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_other.tga"
      o.fullDmgAbsorbTex:SetTexture(fullPath)
      o.fullDmgAbsorbTex:SetVertexColor(0.70, 0.90, 1.00, 0.90)
      if o.fullDmgAbsorbTex.SetBlendMode then
        o.fullDmgAbsorbTex:SetBlendMode("ADD")
      end
      if o.fullDmgAbsorbTex.SetTexCoord then
        o.fullDmgAbsorbTex:SetTexCoord(0, 1, 0, 1)
      end
    end
    if o.dmgAbsorbGlow then
      o.dmgAbsorbGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
      o.dmgAbsorbGlow:SetVertexColor(0.70, 0.90, 1.00, 0.85)
      if o.dmgAbsorbGlow.SetBlendMode then
        o.dmgAbsorbGlow:SetBlendMode("ADD")
      end
    end
    if o.healAbsorbFrame and o.healAbsorbTex then
      if o.healAbsorbFrame.SetStatusBarTexture then
        o.healAbsorbFrame:SetStatusBarTexture(dmgAbsorbPathPrimary)
        if not (o.healAbsorbFrame.GetStatusBarTexture and o.healAbsorbFrame:GetStatusBarTexture()) then
          o.healAbsorbFrame:SetStatusBarTexture(dmgAbsorbPathLegacy)
        end
      end
      o.healAbsorbTex = o.healAbsorbFrame.GetStatusBarTexture and o.healAbsorbFrame:GetStatusBarTexture() or o.healAbsorbTex
      o.healAbsorbTex:SetTexture(dmgAbsorbPathPrimary)
      if not (o.healAbsorbFrame and o.healAbsorbFrame.GetStatusBarTexture and o.healAbsorbFrame:GetStatusBarTexture()) then
        o.healAbsorbTex:SetTexture(dmgAbsorbPathLegacy)
      end
      if o.healAbsorbTex.SetTexCoord then
        o.healAbsorbTex:SetTexCoord(0, 1, 0, 1)
      end
      o.healAbsorbTex:SetVertexColor(1.0, 0.0, 0.0, 1.0)
      if o.healAbsorbTex.SetBlendMode then
        o.healAbsorbTex:SetBlendMode("ADD")
      end
    end
    if o.myHealPredFrame and o.myHealPredTex then
      if o.myHealPredFrame.SetStatusBarTexture then
        o.myHealPredFrame:SetStatusBarTexture(dmgAbsorbPathPrimary)
        if not (o.myHealPredFrame.GetStatusBarTexture and o.myHealPredFrame:GetStatusBarTexture()) then
          o.myHealPredFrame:SetStatusBarTexture(dmgAbsorbPathLegacy)
        end
      end
      o.myHealPredTex = o.myHealPredFrame.GetStatusBarTexture and o.myHealPredFrame:GetStatusBarTexture() or o.myHealPredTex
      if o.myHealPredTex.SetTexCoord then o.myHealPredTex:SetTexCoord(0, 1, 0, 1) end
      o.myHealPredTex:SetVertexColor(0, 0.827, 0, 0.4)
      if o.myHealPredTex.SetBlendMode then o.myHealPredTex:SetBlendMode("ADD") end
    end
    if o.otherHealPredFrame and o.otherHealPredTex then
      if o.otherHealPredFrame.SetStatusBarTexture then
        o.otherHealPredFrame:SetStatusBarTexture(dmgAbsorbPathPrimary)
        if not (o.otherHealPredFrame.GetStatusBarTexture and o.otherHealPredFrame:GetStatusBarTexture()) then
          o.otherHealPredFrame:SetStatusBarTexture(dmgAbsorbPathLegacy)
        end
      end
      o.otherHealPredTex = o.otherHealPredFrame.GetStatusBarTexture and o.otherHealPredFrame:GetStatusBarTexture() or o.otherHealPredTex
      if o.otherHealPredTex.SetTexCoord then o.otherHealPredTex:SetTexCoord(0, 1, 0, 1) end
      o.otherHealPredTex:SetVertexColor(0, 0.631, 0.557, 0.4)
      if o.otherHealPredTex.SetBlendMode then o.otherHealPredTex:SetBlendMode("ADD") end
    end
    o.healthTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or o.healthTex
    if o.healthTex and o.healthTex.SetDrawLayer then
      o.healthTex:SetDrawLayer("ARTWORK", 2)
    end
    local function ApplyStatusBarMask(bar, maskPath)
      if not bar or not bar.GetStatusBarTexture then return end
      local barTex = bar:GetStatusBarTexture()
      if not barTex then return end
      if not maskPath or maskPath == "" then
        if bar._ccmShapeMask and barTex.RemoveMaskTexture then
          pcall(barTex.RemoveMaskTexture, barTex, bar._ccmShapeMask)
        end
        if bar._ccmShapeMask and bar._ccmShapeMask.Hide then
          bar._ccmShapeMask:Hide()
        end
        return
      end
      if not bar._ccmShapeMask then
        bar._ccmShapeMask = bar:CreateMaskTexture()
        bar._ccmShapeMask:SetAllPoints(bar)
      end
      bar._ccmShapeMask:SetTexture(maskPath)
      if bar._ccmShapeMask.Show then
        bar._ccmShapeMask:Show()
      end
      barTex:AddMaskTexture(bar._ccmShapeMask)
    end
    ApplyStatusBarMask(o.dmgAbsorbFrame, dmgAbsorbPathPrimary)
    ApplyStatusBarMask(o.healAbsorbFrame, dmgAbsorbPathPrimary)
    ApplyStatusBarMask(o.myHealPredFrame, shapePath)
    ApplyStatusBarMask(o.otherHealPredFrame, shapePath)
    local maskFixPath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_player_mask_fix"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_other_mask_fix"
    local maskFixR, maskFixG, maskFixB, maskFixA = bigHBBorderR, bigHBBorderG, bigHBBorderB, 1
    if o.maskFixTex then
      o.maskFixTex:SetTexture(maskFixPath)
      if o.maskFixTex.SetDrawLayer then
        o.maskFixTex:SetDrawLayer("ARTWORK", 3)
      end
      if o.maskFixTex.SetVertexColor then
        o.maskFixTex:SetVertexColor(maskFixR, maskFixG, maskFixB, 1)
      end
      if o.maskFixTex.SetAlpha then
        o.maskFixTex:SetAlpha(maskFixA)
      end
    end
    o.shapePath = shapePath
    o.fillPath = fillPath
    o.skipTexCoordSync = not isPlayerFrame
    o.fillScale = nil
    o.origHP = hp
    SyncUFBigHBOverlayValue(o, hp)
    UpdateUFBigHBHealPrediction(o, key)
    UpdateUFBigHBDmgAbsorb(o, key)
    ApplyUFBigHBOverlayHealthColor(o, hp, key)
    if not o.dmgAbsorbHooked and hp.TotalAbsorbBar then
      o.dmgAbsorbHooked = true
      local hookKey = key
      local srcBar = hp.TotalAbsorbBar
      local function syncDmgAbsorb()
        local ov = State.ufBigHBOverlays[hookKey]
        if ov then
          UpdateUFBigHBHealPrediction(ov, hookKey)
          UpdateUFBigHBDmgAbsorb(ov, hookKey)
        end
      end
      if srcBar.SetWidth then hooksecurefunc(srcBar, "SetWidth", syncDmgAbsorb) end
      if srcBar.SetPoint then hooksecurefunc(srcBar, "SetPoint", syncDmgAbsorb) end
      if srcBar.Show then hooksecurefunc(srcBar, "Show", syncDmgAbsorb) end
      if srcBar.Hide then
        hooksecurefunc(srcBar, "Hide", function()
          local ov = State.ufBigHBOverlays[hookKey]
          if ov then
            if ov.dmgAbsorbFrame and ov.dmgAbsorbFrame.Hide then ov.dmgAbsorbFrame:Hide() end
            if ov.fullDmgAbsorbFrame and ov.fullDmgAbsorbFrame.Hide then ov.fullDmgAbsorbFrame:Hide() end
            if ov.dmgAbsorbGlow and ov.dmgAbsorbGlow.Hide then ov.dmgAbsorbGlow:Hide() end
            UpdateUFBigHBHealPrediction(ov, hookKey)
            UpdateUFBigHBDmgAbsorb(ov, hookKey)
          end
        end)
      end
      local overGlow = hp.OverAbsorbGlow
      if overGlow then
        if overGlow.Show then hooksecurefunc(overGlow, "Show", syncDmgAbsorb) end
        if overGlow.Hide then hooksecurefunc(overGlow, "Hide", syncDmgAbsorb) end
      end
    end
    if not o.healPredHooked then
      o.healPredHooked = true
      local hookKey = key
      local function syncHealPred()
        local ov = State.ufBigHBOverlays[hookKey]
        if ov then
          UpdateUFBigHBHealPrediction(ov, hookKey)
          UpdateUFBigHBDmgAbsorb(ov, hookKey)
        end
      end
      local predBars = {hp.MyHealPredictionBar, hp.OtherHealPredictionBar, hp.HealAbsorbBar}
      for _, bar in ipairs(predBars) do
        if bar then
          if bar.SetWidth then hooksecurefunc(bar, "SetWidth", syncHealPred) end
          if bar.SetPoint then hooksecurefunc(bar, "SetPoint", syncHealPred) end
          if bar.Show then hooksecurefunc(bar, "Show", syncHealPred) end
          if bar.SetValue then hooksecurefunc(bar, "SetValue", syncHealPred) end
        end
      end
    end
    if not o.valueHooked and hp.SetValue then
      o.valueHooked = true
      local hookKey = key
      hooksecurefunc(hp, "SetValue", function(self, value)
        local ov = State.ufBigHBOverlays[hookKey]
        if ov then
          SyncUFBigHBOverlayValue(ov, self)
          UpdateUFBigHBHealPrediction(ov, hookKey)
          UpdateUFBigHBDmgAbsorb(ov, hookKey)
        end
      end)
      if hp.SetMinMaxValues then
        hooksecurefunc(hp, "SetMinMaxValues", function(self, minVal, maxVal)
          local ov = State.ufBigHBOverlays[hookKey]
          if ov then
            SyncUFBigHBOverlayValue(ov, self)
          end
        end)
      end
      if hp.SetStatusBarColor then
        hooksecurefunc(hp, "SetStatusBarColor", function(self, r, g, b, a)
          local ov = State.ufBigHBOverlays[hookKey]
          if not ov or not ov.healthTex then return end
          local cr, cg, cb = r, g, b
          local p = addonTable.GetProfile and addonTable.GetProfile()
          if p and p.ufClassColor and hookKey and UnitExists(hookKey) and UnitIsPlayer(hookKey) then
            local _, classToken = UnitClass(hookKey)
            local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
            if classColor then
              cr, cg, cb = classColor.r, classColor.g, classColor.b
            end
          end
          if type(cr) == "number" and type(cg) == "number" and type(cb) == "number" then
            ov.healthTex:SetVertexColor(cr, cg, cb, 1)
            if ov.healthFrame.SetStatusBarColor then
              ov.healthFrame:SetStatusBarColor(cr, cg, cb, 1)
            end
            local st = ov.healthFrame.GetStatusBarTexture and ov.healthFrame:GetStatusBarTexture()
            if st and st.SetVertexColor then
              st:SetVertexColor(cr, cg, cb, 1)
            end
          end
        end)
      end
    end
    if (key == "target" or key == "focus") and hp and o.layoutHookTarget ~= hp then
      o.layoutHookTarget = hp
      local hookKey = key
      local hookRoot = bigHBRoot
      local hookHP = hp
      local hookMP = mp
      local hookPortrait = portrait
      local hookIsPlayer = isPlayerFrame
      local function QueueOverlayReanchor()
        if InCombatLockdown and InCombatLockdown() then
          State.unitFrameCustomizationPending = true
          return
        end
        local ov = State.ufBigHBOverlays and State.ufBigHBOverlays[hookKey]
        if not ov then return end
        ov._ccmAnchorRefreshSeq = (ov._ccmAnchorRefreshSeq or 0) + 1
        local seq = ov._ccmAnchorRefreshSeq
        local function RunReanchor()
          local cur = State.ufBigHBOverlays and State.ufBigHBOverlays[hookKey]
          if not cur or cur._ccmAnchorRefreshSeq ~= seq then return end
          local p = addonTable.GetProfile and addonTable.GetProfile()
          if not p or p.enableUnitFrameCustomization == false then return end
          if hookKey == "target" and p.ufBigHBTargetEnabled ~= true then return end
          if hookKey == "focus" and p.ufBigHBFocusEnabled ~= true then return end
          if InCombatLockdown and InCombatLockdown() then
            State.unitFrameCustomizationPending = true
            return
          end
          ApplyUFBigHBForFrame(hookKey, hookRoot, hookHP, hookMP, hookPortrait, hookIsPlayer)
        end
        if C_Timer and C_Timer.After then
          C_Timer.After(0, RunReanchor)
        else
          RunReanchor()
        end
      end
      if hookHP.SetPoint then hooksecurefunc(hookHP, "SetPoint", QueueOverlayReanchor) end
      if hookHP.SetWidth then hooksecurefunc(hookHP, "SetWidth", QueueOverlayReanchor) end
      if hookHP.SetHeight then hooksecurefunc(hookHP, "SetHeight", QueueOverlayReanchor) end
    end
    SetUFBaseHealthBarCovered(o, hp, true, bigHBRoot and bigHBRoot.HealthBarsContainer, bigHBRoot)
    if (key == "target" or key == "focus") and bigHBRoot and bigHBRoot.ReputationColor then
      if not o.repColorSaved then
        o.repColorSaved = true
        o.repColorShown = bigHBRoot.ReputationColor.IsShown and bigHBRoot.ReputationColor:IsShown() or nil
      end
      if bigHBRoot.ReputationColor.Hide then bigHBRoot.ReputationColor:Hide() end
      if not o.repColorHooked and type(hooksecurefunc) == "function" then
        o.repColorHooked = true
        local repKey = key
        hooksecurefunc(bigHBRoot.ReputationColor, "Show", function(self)
          local ov = State.ufBigHBOverlays[repKey]
          if ov and ov.repColorSaved then
            self:Hide()
          end
        end)
      end
    end
    if (key == "target" or key == "focus") and bigHBRoot then
      local contentFrame = bigHBRoot.GetParent and bigHBRoot:GetParent()
      local ctxFrame = contentFrame and contentFrame.TargetFrameContentContextual
      local highLvlTex = ctxFrame and ctxFrame.HighLevelTexture
      if highLvlTex then
        if not o.highLevelTexSaved then
          o.highLevelTexSaved = true
          o.highLevelTexShown = highLvlTex.IsShown and highLvlTex:IsShown() or nil
        end
        if highLvlTex.Hide then highLvlTex:Hide() end
        if not o.highLevelTexHooked and type(hooksecurefunc) == "function" then
          o.highLevelTexHooked = true
          local hlKey = key
          hooksecurefunc(highLvlTex, "Show", function(self)
            local ov = State.ufBigHBOverlays[hlKey]
            if ov and ov.highLevelTexSaved then
              self:Hide()
            end
          end)
        end
      end
    end
    local targetMaxNameChars = GetUFBigHBNameMaxChars(profile, "target")
    local focusMaxNameChars = GetUFBigHBNameMaxChars(profile, "focus")
    local playerMaxNameChars = GetUFBigHBNameMaxChars(profile, "player")
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
    local function ApplyUFBigHBScaledFont(fontString, baseFont, baseSize, baseFlags, scale)
      if not fontString or not fontString.SetFont then return end
      local gf, go = GetGlobalFont()
      local fontPath = gf or baseFont
      local fontSize = baseSize
      local fontFlags = go or baseFlags
      if (type(fontPath) ~= "string" or fontPath == "") then fontPath = baseFont end
      if (type(fontPath) ~= "string" or fontPath == "") or type(fontSize) ~= "number" or fontSize <= 0 then
        if fontString.GetFont then
          local f, s, fl = fontString:GetFont()
          if type(f) == "string" and f ~= "" then fontPath = f end
          if type(s) == "number" and s > 0 then fontSize = s end
          if type(fl) == "string" then fontFlags = fl end
        end
      end
      if type(fontPath) ~= "string" or fontPath == "" or type(fontSize) ~= "number" or fontSize <= 0 then return end
      local textScale = tonumber(scale) or 1
      if textScale < 0.5 then textScale = 0.5 end
      if textScale > 3 then textScale = 3 end
      pcall(fontString.SetFont, fontString, fontPath, fontSize * textScale, fontFlags or "")
      ApplyConsistentFontShadow(fontString, fontFlags)
    end
    local function GetUFBigHBNameAnchorMode(prof, unitToken)
      if unitToken ~= "target" and unitToken ~= "focus" and unitToken ~= "player" then return "center" end
      if type(prof) ~= "table" then return "center" end
      local key
      if unitToken == "target" then
        key = "ufBigHBTargetNameAnchor"
      elseif unitToken == "focus" then
        key = "ufBigHBFocusNameAnchor"
      elseif unitToken == "player" then
        key = "ufBigHBPlayerNameAnchor"
      end
      local v = key and prof[key] or nil
      v = type(v) == "string" and string.lower(v) or "center"
      if v ~= "left" and v ~= "right" then
        v = "center"
      end
      return v
    end
    local function NormalizeUFBigHBNameXOffset(unitToken, anchorMode, xOff)
      local x = tonumber(xOff) or 0
      if unitToken == "target" then
        if anchorMode == "left" then
          return x + 5
        elseif anchorMode == "right" then
          return x - 1
        else
          return x + 1
        end
      end
      if unitToken == "focus" then
        if anchorMode == "left" then
          return x + 4
        elseif anchorMode == "right" then
          return x + 86
        else
          return x + 45
        end
      end
      if unitToken == "player" then
        if anchorMode == "left" then
          return x - 78
        elseif anchorMode == "right" then
          return x + 8
        else
          return x - 34
        end
      end
      if anchorMode == "left" then
        return x - 3
      elseif anchorMode == "right" then
        return x + 3
      end
      return x
    end

    local function AnchorUFBigHBNameToHealth(nameEl, healthFrame, anchorMode, xOff, yOff)
      if not (nameEl and healthFrame and nameEl.SetPoint and nameEl.SetJustifyH) then return end
      if anchorMode == "left" then
        nameEl:SetPoint("LEFT", healthFrame, "LEFT", 1 + (xOff or 0), yOff or 0)
        nameEl:SetJustifyH("LEFT")
      elseif anchorMode == "right" then
        nameEl:SetPoint("RIGHT", healthFrame, "RIGHT", -1 + (xOff or 0), yOff or 0)
        nameEl:SetJustifyH("RIGHT")
      else
        nameEl:SetPoint("CENTER", healthFrame, "CENTER", xOff or 0, yOff or 0)
        nameEl:SetJustifyH("CENTER")
      end
    end
    if key == "target" and bigHBRoot then
      local nameEl = bigHBRoot.Name
      if nameEl then
        if not o.targetNameSaved then
          o.targetNameSaved = true
          o.targetNameShown = nameEl.IsShown and nameEl:IsShown() or nil
          if nameEl.GetTextColor then
            o.targetNameColorR, o.targetNameColorG, o.targetNameColorB = nameEl:GetTextColor()
          end
          if nameEl.GetWidth then
            o.targetNameOrigWidth = nameEl:GetWidth()
          end
          if nameEl.GetWordWrap then
            o.targetNameOrigWordWrap = nameEl:GetWordWrap()
          end
          if nameEl.GetNonSpaceWrap then
            o.targetNameOrigNonSpaceWrap = nameEl:GetNonSpaceWrap()
          end
          if nameEl.GetJustifyH then
            o.targetNameJustifyH = nameEl:GetJustifyH()
          end
          if nameEl.GetPoint then
            o.targetNamePoint, o.targetNameRelTo, o.targetNameRelPt, o.targetNameOrigX, o.targetNameOrigY = nameEl:GetPoint(1)
          end
          if nameEl.GetFont then
            o.targetNameFont, o.targetNameFontSize, o.targetNameFontFlags = nameEl:GetFont()
          end
        end
        if profile.ufBigHBHideTargetName then
          if nameEl.Hide then nameEl:Hide() end
        else
          if nameEl.Show then nameEl:Show() end
          if nameEl.SetTextColor then
            nameEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          local targetName = TrimUFBigHBName(ApplyUFBigHBNameTransforms(GetUFBigHBUnitName("target"), "target", profile), targetMaxNameChars)
          if targetName and nameEl.SetText then nameEl:SetText(targetName) end
          ApplyUFBigHBScaledFont(nameEl, o.targetNameFont, o.targetNameFontSize, o.targetNameFontFlags, profile.ufBigHBTargetNameTextScale or profile.ufBigHBTargetTextScale)
        end
        if not o.targetNameSetTextHooked and nameEl.SetText and type(hooksecurefunc) == "function" then
          o.targetNameSetTextHooked = true
          hooksecurefunc(nameEl, "SetText", function(self)
            if o.targetNameTrimming then return end
            pcall(function()
              local p = addonTable.GetProfile and addonTable.GetProfile()
              if not p or p.ufBigHBHideTargetName then return end
              local mc = GetUFBigHBNameMaxChars(p, "target")
              if mc <= 0 then return end
              local rawName = UnitName("target")
              if not rawName or rawName == "" then return end
              local trimmed = TrimUFBigHBName(ApplyUFBigHBNameTransforms(rawName, "target", p), mc)
              if trimmed and trimmed ~= rawName then
                o.targetNameTrimming = true
                self:SetText(trimmed)
                o.targetNameTrimming = nil
              end
            end)
          end)
        end
        local nameAnchorMode = GetUFBigHBNameAnchorMode(profile, "target")
        local nx = NormalizeUFBigHBNameXOffset("target", nameAnchorMode, profile.ufBigHBTargetNameX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.target.nameX
        local ny = (profile.ufBigHBTargetNameY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.target.nameY
        if nameEl.ClearAllPoints and nameEl.SetPoint then
          nameEl:ClearAllPoints()
          if o.healthFrame then
            if nameEl.SetWidth and o.healthFrame.GetWidth then
              local w = o.healthFrame:GetWidth()
              if type(w) == "number" and w > 0 then
                nameEl:SetWidth(math.max(1, w - 2))
              end
            end
            if nameEl.SetWordWrap then nameEl:SetWordWrap(false) end
            if nameEl.SetNonSpaceWrap then nameEl:SetNonSpaceWrap(false) end
            AnchorUFBigHBNameToHealth(nameEl, o.healthFrame, nameAnchorMode, nx, ny)
          elseif o.targetNamePoint then
            if nameEl.SetWidth and o.targetNameOrigWidth ~= nil then
              nameEl:SetWidth(o.targetNameOrigWidth)
            end
            if nameEl.SetWordWrap and o.targetNameOrigWordWrap ~= nil then
              nameEl:SetWordWrap(o.targetNameOrigWordWrap)
            end
            if nameEl.SetNonSpaceWrap and o.targetNameOrigNonSpaceWrap ~= nil then
              nameEl:SetNonSpaceWrap(o.targetNameOrigNonSpaceWrap)
            end
            nameEl:SetPoint(o.targetNamePoint, o.targetNameRelTo, o.targetNameRelPt, (o.targetNameOrigX or 0) + nx, (o.targetNameOrigY or 0) + ny)
            if nameEl.SetJustifyH and o.targetNameJustifyH then nameEl:SetJustifyH(o.targetNameJustifyH) end
          end
        end
      end
      local levelEl = bigHBRoot.LevelText
      if levelEl then
        if not o.targetLevelSaved then
          o.targetLevelSaved = true
          o.targetLevelShown = levelEl.IsShown and levelEl:IsShown() or nil
          if levelEl.GetTextColor then
            o.targetLevelColorR, o.targetLevelColorG, o.targetLevelColorB = levelEl:GetTextColor()
          end
          if levelEl.GetPoint then
            o.targetLevelPoint, o.targetLevelRelTo, o.targetLevelRelPt, o.targetLevelOrigX, o.targetLevelOrigY = levelEl:GetPoint(1)
          end
          if levelEl.GetFont then
            o.targetLevelFont, o.targetLevelFontSize, o.targetLevelFontFlags = levelEl:GetFont()
          end
        end
        local targetLevelMode = profile.ufBigHBTargetLevelMode or "always"
        local tLvl = UnitLevel("target")
        local hideTargetLevel = targetLevelMode == "hide" or (targetLevelMode == "hidemax" and (tLvl == -1 or tLvl >= (GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion() or 80)))
        if hideTargetLevel then
          if levelEl.Hide then levelEl:Hide() end
        else
          if levelEl.Show then levelEl:Show() end
          if levelEl.SetTextColor then
            levelEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          ApplyUFBigHBScaledFont(levelEl, o.targetLevelFont, o.targetLevelFontSize, o.targetLevelFontFlags, profile.ufBigHBTargetLevelTextScale or profile.ufBigHBTargetTextScale)
        end
        if not o.targetLevelHooked and type(hooksecurefunc) == "function" then
          o.targetLevelHooked = true
          hooksecurefunc(levelEl, "Show", function(self)
            local ov = State.ufBigHBOverlays["target"]
            if not ov or not ov.targetLevelSaved then return end
            local p = addonTable.GetProfile and addonTable.GetProfile()
            if not p then return end
            local m = p.ufBigHBTargetLevelMode or "always"
            local lv = UnitLevel("target")
            local shouldHide = m == "hide" or (m == "hidemax" and (lv == -1 or lv >= (GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion() or 80)))
            if shouldHide then self:Hide() end
          end)
        end
        local lx = (profile.ufBigHBTargetLevelX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.target.levelX
        local ly = (profile.ufBigHBTargetLevelY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.target.levelY
        if levelEl.ClearAllPoints and levelEl.SetPoint and o.targetLevelPoint then
          levelEl:ClearAllPoints()
          levelEl:SetPoint(o.targetLevelPoint, o.targetLevelRelTo, o.targetLevelRelPt, (o.targetLevelOrigX or 0) + lx, (o.targetLevelOrigY or 0) + ly)
        end
      end
    end
    if key == "focus" and bigHBRoot then
      local nameEl = bigHBRoot.Name
      if nameEl then
        if not o.nameColorSaved then
          o.nameColorSaved = true
          o.nameOrigShown = nameEl.IsShown and nameEl:IsShown() or nil
          if nameEl.GetTextColor then
            o.nameOrigColorR, o.nameOrigColorG, o.nameOrigColorB = nameEl:GetTextColor()
          end
          if nameEl.GetWidth then
            o.nameOrigWidth = nameEl:GetWidth()
          end
          if nameEl.GetWordWrap then
            o.nameOrigWordWrap = nameEl:GetWordWrap()
          end
          if nameEl.GetNonSpaceWrap then
            o.nameOrigNonSpaceWrap = nameEl:GetNonSpaceWrap()
          end
          if nameEl.GetJustifyH then
            o.nameOrigJustifyH = nameEl:GetJustifyH()
          end
          if nameEl.GetPoint then
            o.namePoint, o.nameRelTo, o.nameRelPt, o.nameOrigX, o.nameOrigY = nameEl:GetPoint(1)
          end
          if nameEl.GetFont then
            o.nameOrigFont, o.nameOrigFontSize, o.nameOrigFontFlags = nameEl:GetFont()
          end
        end
        if profile.ufBigHBHideFocusName then
          if nameEl.Hide then nameEl:Hide() end
        else
          if nameEl.Show then nameEl:Show() end
          if nameEl.SetTextColor then
            nameEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          local focusName = TrimUFBigHBName(ApplyUFBigHBNameTransforms(GetUFBigHBUnitName("focus"), "focus", profile), focusMaxNameChars)
          if focusName and nameEl.SetText then nameEl:SetText(focusName) end
          ApplyUFBigHBScaledFont(nameEl, o.nameOrigFont, o.nameOrigFontSize, o.nameOrigFontFlags, profile.ufBigHBFocusNameTextScale or profile.ufBigHBFocusTextScale)
        end
        if not o.focusNameSetTextHooked and nameEl.SetText and type(hooksecurefunc) == "function" then
          o.focusNameSetTextHooked = true
          hooksecurefunc(nameEl, "SetText", function(self)
            if o.focusNameTrimming then return end
            pcall(function()
              local p = addonTable.GetProfile and addonTable.GetProfile()
              if not p or p.ufBigHBHideFocusName then return end
              local mc = GetUFBigHBNameMaxChars(p, "focus")
              if mc <= 0 then return end
              local rawName = UnitName("focus")
              if not rawName or rawName == "" then return end
              local trimmed = TrimUFBigHBName(ApplyUFBigHBNameTransforms(rawName, "focus", p), mc)
              if trimmed and trimmed ~= rawName then
                o.focusNameTrimming = true
                self:SetText(trimmed)
                o.focusNameTrimming = nil
              end
            end)
          end)
        end
        local nameAnchorMode = GetUFBigHBNameAnchorMode(profile, "focus")
        local nx = NormalizeUFBigHBNameXOffset("focus", nameAnchorMode, profile.ufBigHBFocusNameX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.target.nameX
        local ny = (profile.ufBigHBFocusNameY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.focus.nameY
        if nameEl.ClearAllPoints and nameEl.SetPoint then
          nameEl:ClearAllPoints()
          if o.healthFrame then
            if nameEl.SetWidth and o.healthFrame.GetWidth then
              local w = o.healthFrame:GetWidth()
              if type(w) == "number" and w > 0 then
                nameEl:SetWidth(math.max(1, w - 2))
              end
            end
            if nameEl.SetWordWrap then nameEl:SetWordWrap(false) end
            if nameEl.SetNonSpaceWrap then nameEl:SetNonSpaceWrap(false) end
            AnchorUFBigHBNameToHealth(nameEl, o.healthFrame, nameAnchorMode, nx, ny)
          elseif o.namePoint then
            if nameEl.SetWidth and o.nameOrigWidth ~= nil then
              nameEl:SetWidth(o.nameOrigWidth)
            end
            if nameEl.SetWordWrap and o.nameOrigWordWrap ~= nil then
              nameEl:SetWordWrap(o.nameOrigWordWrap)
            end
            if nameEl.SetNonSpaceWrap and o.nameOrigNonSpaceWrap ~= nil then
              nameEl:SetNonSpaceWrap(o.nameOrigNonSpaceWrap)
            end
            nameEl:SetPoint(o.namePoint, o.nameRelTo, o.nameRelPt, (o.nameOrigX or 0) + nx, (o.nameOrigY or 0) + ny)
            if nameEl.SetJustifyH and o.nameOrigJustifyH then nameEl:SetJustifyH(o.nameOrigJustifyH) end
          end
        end
      end
      local levelEl = bigHBRoot.LevelText
      if levelEl then
        if not o.levelColorSaved then
          o.levelColorSaved = true
          o.levelOrigShown = levelEl.IsShown and levelEl:IsShown() or nil
          if levelEl.GetTextColor then
            o.levelOrigColorR, o.levelOrigColorG, o.levelOrigColorB = levelEl:GetTextColor()
          end
          if levelEl.GetPoint then
            o.levelPoint, o.levelRelTo, o.levelRelPt, o.levelOrigX, o.levelOrigY = levelEl:GetPoint(1)
          end
          if levelEl.GetFont then
            o.levelOrigFont, o.levelOrigFontSize, o.levelOrigFontFlags = levelEl:GetFont()
          end
        end
        local focusLevelMode = profile.ufBigHBFocusLevelMode or "always"
        local fLvl = UnitLevel("focus")
        local hideFocusLevel = focusLevelMode == "hide" or (focusLevelMode == "hidemax" and (fLvl == -1 or fLvl >= (GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion() or 80)))
        if hideFocusLevel then
          if levelEl.Hide then levelEl:Hide() end
        else
          if levelEl.Show then levelEl:Show() end
          if levelEl.SetTextColor then
            levelEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          ApplyUFBigHBScaledFont(levelEl, o.levelOrigFont, o.levelOrigFontSize, o.levelOrigFontFlags, profile.ufBigHBFocusLevelTextScale or profile.ufBigHBFocusTextScale)
        end
        if not o.focusLevelHooked and type(hooksecurefunc) == "function" then
          o.focusLevelHooked = true
          hooksecurefunc(levelEl, "Show", function(self)
            local ov = State.ufBigHBOverlays["focus"]
            if not ov or not ov.levelColorSaved then return end
            local p = addonTable.GetProfile and addonTable.GetProfile()
            if not p then return end
            local m = p.ufBigHBFocusLevelMode or "always"
            local lv = UnitLevel("focus")
            local shouldHide = m == "hide" or (m == "hidemax" and (lv == -1 or lv >= (GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion() or 80)))
            if shouldHide then self:Hide() end
          end)
        end
        local lx = (profile.ufBigHBFocusLevelX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.focus.levelX
        local ly = (profile.ufBigHBFocusLevelY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.focus.levelY
        if levelEl.ClearAllPoints and levelEl.SetPoint and o.levelPoint then
          levelEl:ClearAllPoints()
          levelEl:SetPoint(o.levelPoint, o.levelRelTo, o.levelRelPt, (o.levelOrigX or 0) + lx, (o.levelOrigY or 0) + ly)
        end
      end
    end
    if key == "player" then
      local nameEl = _G["PlayerName"]
      if nameEl then
        if not o.nameColorSaved then
          o.nameColorSaved = true
          o.nameOrigAlpha = nameEl.GetAlpha and nameEl:GetAlpha() or nil
          o.nameOrigShown = nameEl.IsShown and nameEl:IsShown() or nil
          if nameEl.GetTextColor then
            o.nameOrigColorR, o.nameOrigColorG, o.nameOrigColorB = nameEl:GetTextColor()
          end
          if nameEl.GetWidth then
            o.nameOrigWidth = nameEl:GetWidth()
          end
          if nameEl.GetWordWrap then
            o.nameOrigWordWrap = nameEl:GetWordWrap()
          end
          if nameEl.GetNonSpaceWrap then
            o.nameOrigNonSpaceWrap = nameEl:GetNonSpaceWrap()
          end
          if nameEl.GetJustifyH then
            o.nameOrigJustifyH = nameEl:GetJustifyH()
          end
          if nameEl.GetPoint then
            o.namePoint, o.nameRelTo, o.nameRelPt, o.nameOrigX, o.nameOrigY = nameEl:GetPoint(1)
          end
          if nameEl.GetFont then
            o.nameOrigFont, o.nameOrigFontSize, o.nameOrigFontFlags = nameEl:GetFont()
          end
        end
        if profile.ufBigHBHidePlayerName then
          if nameEl.SetAlpha then nameEl:SetAlpha(0) end
          if nameEl.Hide then nameEl:Hide() end
        else
          if nameEl.SetAlpha then nameEl:SetAlpha(1) end
          if nameEl.Show then nameEl:Show() end
          if nameEl.SetTextColor then
            nameEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          local playerName = TrimUFBigHBName(ApplyUFBigHBNameTransforms(GetUFBigHBUnitName("player"), "player", profile), playerMaxNameChars)
          if playerName and nameEl.SetText then nameEl:SetText(playerName) end
          ApplyUFBigHBScaledFont(nameEl, o.nameOrigFont, o.nameOrigFontSize, o.nameOrigFontFlags, profile.ufBigHBPlayerNameTextScale or profile.ufBigHBPlayerTextScale)
        end
        local nameAnchorMode = GetUFBigHBNameAnchorMode(profile, "player")
        local nx = NormalizeUFBigHBNameXOffset("player", nameAnchorMode, profile.ufBigHBPlayerNameX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.player.nameX
        local ny = (profile.ufBigHBPlayerNameY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.player.nameY
        if nameEl.ClearAllPoints and nameEl.SetPoint then
          nameEl:ClearAllPoints()
          if o.healthFrame then
            if nameEl.SetWidth and o.healthFrame.GetWidth then
              local w = o.healthFrame:GetWidth()
              if type(w) == "number" and w > 0 then
                nameEl:SetWidth(math.max(1, w - 2))
              end
            end
            if nameEl.SetWordWrap then nameEl:SetWordWrap(false) end
            if nameEl.SetNonSpaceWrap then nameEl:SetNonSpaceWrap(false) end
            AnchorUFBigHBNameToHealth(nameEl, o.healthFrame, nameAnchorMode, nx, ny)
          elseif o.namePoint then
            if nameEl.SetWidth and o.nameOrigWidth ~= nil then
              nameEl:SetWidth(o.nameOrigWidth)
            end
            if nameEl.SetWordWrap and o.nameOrigWordWrap ~= nil then
              nameEl:SetWordWrap(o.nameOrigWordWrap)
            end
            if nameEl.SetNonSpaceWrap and o.nameOrigNonSpaceWrap ~= nil then
              nameEl:SetNonSpaceWrap(o.nameOrigNonSpaceWrap)
            end
            nameEl:SetPoint(o.namePoint, o.nameRelTo, o.nameRelPt, (o.nameOrigX or 0) + nx, (o.nameOrigY or 0) + ny)
            if nameEl.SetJustifyH and o.nameOrigJustifyH then nameEl:SetJustifyH(o.nameOrigJustifyH) end
          end
        end
      end
      local levelEl = _G["PlayerLevelText"]
      if levelEl then
        if not o.levelColorSaved then
          o.levelColorSaved = true
          o.levelOrigAlpha = levelEl.GetAlpha and levelEl:GetAlpha() or nil
          o.levelOrigShown = levelEl.IsShown and levelEl:IsShown() or nil
          if levelEl.GetTextColor then
            o.levelOrigColorR, o.levelOrigColorG, o.levelOrigColorB = levelEl:GetTextColor()
          end
          if levelEl.GetPoint then
            o.levelPoint, o.levelRelTo, o.levelRelPt, o.levelOrigX, o.levelOrigY = levelEl:GetPoint(1)
          end
          if levelEl.GetFont then
            o.levelOrigFont, o.levelOrigFontSize, o.levelOrigFontFlags = levelEl:GetFont()
          end
        end
        local playerLevelMode = profile.ufBigHBPlayerLevelMode or "always"
        local pLvl = UnitLevel("player")
        local hidePlayerLevel = playerLevelMode == "hide" or (playerLevelMode == "hidemax" and (pLvl == -1 or pLvl >= (GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion() or 80)))
        if hidePlayerLevel then
          if levelEl.SetAlpha then levelEl:SetAlpha(0) end
          if levelEl.Hide then levelEl:Hide() end
        else
          if levelEl.SetAlpha then levelEl:SetAlpha(1) end
          if levelEl.Show then levelEl:Show() end
          if levelEl.SetTextColor then
            levelEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          ApplyUFBigHBScaledFont(levelEl, o.levelOrigFont, o.levelOrigFontSize, o.levelOrigFontFlags, profile.ufBigHBPlayerLevelTextScale or profile.ufBigHBPlayerTextScale)
        end
        local lx = (profile.ufBigHBPlayerLevelX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.player.levelX
        local ly = (profile.ufBigHBPlayerLevelY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.player.levelY
        if levelEl.ClearAllPoints and levelEl.SetPoint and o.levelPoint then
          levelEl:ClearAllPoints()
          levelEl:SetPoint(o.levelPoint, o.levelRelTo, o.levelRelPt, (o.levelOrigX or 0) + lx, (o.levelOrigY or 0) + ly)
        end
      end
    end
    local stripesOn = true
    if key == "player" then stripesOn = profile.ufBigHBPlayerAbsorbStripes ~= false
    elseif key == "target" then stripesOn = profile.ufBigHBTargetAbsorbStripes ~= false
    elseif key == "focus" then stripesOn = profile.ufBigHBFocusAbsorbStripes ~= false
    end
    if o.dmgAbsorbStripe then if stripesOn then o.dmgAbsorbStripe:Show() else o.dmgAbsorbStripe:Hide() end end
    if o.healAbsorbStripe then if stripesOn then o.healAbsorbStripe:Show() else o.healAbsorbStripe:Hide() end end
    o.bgFrame:Show()
    o.healthFrame:Show()
    if o.maskFixFrame then o.maskFixFrame:Show() end
  end
  do
    local function ResolveTargetLikeBars(unitFrame)
      if not unitFrame then return nil, nil, nil, nil end
      local main = unitFrame.TargetFrameContent and unitFrame.TargetFrameContent.TargetFrameContentMain
      local hc = main and main.HealthBarsContainer
      local hb = hc and hc.HealthBar
      local mp2 = main and main.ManaBar
      if not hb and unitFrame.healthbar then hb = unitFrame.healthbar end
      if not mp2 and unitFrame.manabar then mp2 = unitFrame.manabar end
      return main or unitFrame, hb, mp2, unitFrame.TargetFrameContainer
    end
    local playerRoot = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
    local playerPortrait = PlayerFrame and PlayerFrame.PlayerFrameContainer
    ApplyUFBigHBForFrame("player", playerRoot or PlayerFrame, healthBar, powerBar, playerPortrait, true)
    local targetRoot, targetHB, targetMP, targetPortrait = ResolveTargetLikeBars(TargetFrame)
    ApplyUFBigHBForFrame("target", targetRoot or TargetFrame, targetHB, targetMP, targetPortrait, false)
    local focusRoot, focusHB, focusMP, focusPortrait = ResolveTargetLikeBars(FocusFrame)
    ApplyUFBigHBForFrame("focus", focusRoot or FocusFrame, focusHB, focusMP, focusPortrait, false)
    if C_Timer and C_Timer.After and profile.ufBigHBPlayerEnabled then
      State.ufBigHBPlayerDeferredSyncSeq = (State.ufBigHBPlayerDeferredSyncSeq or 0) + 1
      local syncSeq = State.ufBigHBPlayerDeferredSyncSeq
      C_Timer.After(0.08, function()
        if syncSeq ~= State.ufBigHBPlayerDeferredSyncSeq then return end
        local ov = State.ufBigHBOverlays and State.ufBigHBOverlays["player"]
        if not ov or not ov.healthFrame then return end
        local pRoot = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
        local pHC = pRoot and pRoot.HealthBarsContainer
        local pHP = pHC and pHC.HealthBar
        if not pHP then return end
        SyncUFBigHBOverlayValue(ov, pHP)
        UpdateUFBigHBHealPrediction(ov, "player")
        UpdateUFBigHBDmgAbsorb(ov, "player")
        ApplyUFBigHBOverlayHealthColor(ov, pHP, "player")
      end)
    end
  end
  if not orig.bossFrameUpdateHooked and type(hooksecurefunc) == "function" and type(BossTargetFrame_Update) == "function" then
    orig.bossFrameUpdateHooked = true
    hooksecurefunc("BossTargetFrame_Update", function()
      local p = addonTable.GetProfile and addonTable.GetProfile()
      if not p or p.enableUnitFrameCustomization == false or p.ufBossFramesEnabled ~= true then return end
      if not C_Timer or not C_Timer.After then return end
      if State.ufBossDeferredApply then return end
      State.ufBossDeferredApply = true
      C_Timer.After(0, function()
        State.ufBossDeferredApply = false
        if addonTable.ApplyUnitFrameCustomization then addonTable.ApplyUnitFrameCustomization() end
      end)
    end)
  end
  if not orig.ufFontHooked then
    orig.ufFontHooked = true
    orig.ufFontObjects = orig.ufFontObjects or {}
    local function ApplyGlobalFontToUFs()
      local ufProf = addonTable.GetProfile and addonTable.GetProfile()
      if not ufProf or ufProf.enableUnitFrameCustomization == false then return end
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      local function afs(fs)
        if not fs or not fs.GetFont or not fs.SetFont then return end
        local _, sz = fs:GetFont()
        if not sz or sz <= 0 then sz = 12 end
        pcall(fs.SetFont, fs, gf, sz, oFlag)
        ApplyConsistentFontShadow(fs, oFlag)
      end
      afs(_G["PlayerName"])
      afs(_G["PlayerLevelText"])
      if healthBar then
        afs(healthBar.TextString)
        afs(healthBar.LeftText)
        afs(healthBar.RightText)
      end
      afs(_G["PlayerFrameHealthBarText"])
      afs(_G["PlayerFrameHealthBarTextLeft"])
      afs(_G["PlayerFrameHealthBarTextRight"])
      afs(_G["PlayerFrameManaBarText"])
      afs(_G["PlayerFrameManaBarTextLeft"])
      afs(_G["PlayerFrameManaBarTextRight"])
      if powerBar then
        afs(powerBar.TextString)
        afs(powerBar.LeftText)
        afs(powerBar.RightText)
      end
      local function afsUnit(unitFrame)
        if not unitFrame then return end
        local tMain = unitFrame.TargetFrameContent and unitFrame.TargetFrameContent.TargetFrameContentMain
        if tMain then
          afs(tMain.Name)
          afs(tMain.LevelText)
        end
        local hc = tMain and tMain.HealthBarsContainer
        local hb = hc and hc.HealthBar
        if hb then afs(hb.TextString); afs(hb.LeftText); afs(hb.RightText) end
        local mb = tMain and tMain.ManaBar
        if mb then afs(mb.TextString); afs(mb.LeftText); afs(mb.RightText) end
      end
      afsUnit(TargetFrame)
      afsUnit(FocusFrame)
      for i = 1, 8 do
        local bf = _G["Boss" .. i .. "TargetFrame"]
        if bf then afsUnit(bf) end
      end
      local prof = addonTable.GetProfile and addonTable.GetProfile()
      if prof and prof.ufUseCustomNameColor == true then
        local nr = prof.ufNameColorR or 1
        local ng = prof.ufNameColorG or 1
        local nb = prof.ufNameColorB or 1
        local function setNameColor(fs)
          if fs and fs.SetTextColor then pcall(fs.SetTextColor, fs, nr, ng, nb) end
        end
        setNameColor(_G["PlayerName"])
        setNameColor(_G["PlayerLevelText"])
        local function setUnitNameColor(unitFrame)
          if not unitFrame then return end
          local tMain = unitFrame.TargetFrameContent and unitFrame.TargetFrameContent.TargetFrameContentMain
          if tMain then
            setNameColor(tMain.Name)
            setNameColor(tMain.LevelText)
          end
        end
        setUnitNameColor(TargetFrame)
        setUnitNameColor(FocusFrame)
        local tot = _G.TargetFrameToT or _G.TargetFrameToTFrame
        if tot then
          local totMain = tot.TargetFrameContent and tot.TargetFrameContent.TargetFrameContentMain
          if totMain then setNameColor(totMain.Name) end
          if tot.Name then setNameColor(tot.Name) end
        end
        local focusTot = _G.FocusFrameToT
        if focusTot then
          local ftMain = focusTot.TargetFrameContent and focusTot.TargetFrameContent.TargetFrameContentMain
          if ftMain then setNameColor(ftMain.Name) end
          if focusTot.Name then setNameColor(focusTot.Name) end
        end
        for i = 1, 5 do
          setUnitNameColor(_G["Boss" .. i .. "TargetFrame"])
        end
        local petFrame = _G.PetFrame
        if petFrame then
          local petMain = petFrame.TargetFrameContent and petFrame.TargetFrameContent.TargetFrameContentMain
          if petMain and petMain.Name then setNameColor(petMain.Name) end
          if petFrame.Name then setNameColor(petFrame.Name) end
        end
        setNameColor(_G["PetName"])
      end
    end
    orig.ApplyGlobalFontToUFs = ApplyGlobalFontToUFs
    hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar)
      if statusbar and statusbar.unit then
        local u = statusbar.unit
        if u == "focustarget" or u == "targettarget" then return end
      end
      ApplyGlobalFontToUFs()
    end)
    local fontEventFrame = CreateFrame("Frame")
    fontEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    fontEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    fontEventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    fontEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    fontEventFrame:SetScript("OnEvent", function() ApplyGlobalFontToUFs() end)
  end
  if orig.ApplyGlobalFontToUFs then orig.ApplyGlobalFontToUFs() end
end
