local _, addonTable = ...
local State = addonTable.State
local GetClassColor = addonTable.GetClassColor
local GetGlobalFont = addonTable.GetGlobalFont
local FitTextToBar = addonTable.FitTextToBar
local IsRealNumber = addonTable.IsRealNumber
local GetClassPowerConfig = addonTable.GetClassPowerConfig
local IsClassPowerRedundant = addonTable.IsClassPowerRedundant
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
  local useCustomTex = ufEnabled and profile.ufUseCustomTextures == true
  local selectedTexture = useCustomTex and (profile.ufHealthTexture or "solid") or "blizzard"
  local selectedTexturePath = texturePaths[selectedTexture] or texturePaths.blizzard
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
  local function GetStatusBarUnitToken(statusBar, fallbackUnit)
    if type(fallbackUnit) == "string" and fallbackUnit ~= "" then
      return fallbackUnit
    end
    if statusBar and type(statusBar.unit) == "string" and statusBar.unit ~= "" then
      return statusBar.unit
    end
    local uf = statusBar and statusBar.unitFrame
    if uf and type(uf.unit) == "string" and uf.unit ~= "" then
      return uf.unit
    end
    return nil
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
    return p.ufDisableGlows == true
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

  ApplyPlayerHealthColor()
  local disableGlows = ufEnabled and (profile.ufDisableGlows == true or profile.ufBigHBPlayerEnabled == true)
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
  local function TrimUFBigHBName(name, maxChars)
    if type(name) ~= "string" or name == "" then return name end
    if type(maxChars) ~= "number" or maxChars <= 0 then return name end
    local charCount = nil
    if type(utf8len) == "function" then
      charCount = utf8len(name)
    end
    if type(charCount) ~= "number" then
      charCount = string.len(name)
    end
    if charCount <= maxChars then return name end
    local base
    if type(utf8sub) == "function" then
      base = utf8sub(name, 1, maxChars)
    else
      base = string.sub(name, 1, maxChars)
    end
    return (base or name) .. "..."
  end
  local function ApplyUFBigHBNameTransforms(name, unitToken, prof)
    if type(name) ~= "string" or name == "" then return name end
    if not prof then return name end
    if unitToken ~= "target" and unitToken ~= "focus" then return name end
    if prof.ufBigHBHideRealm then
      local dashPos = name:find("-")
      if dashPos then
        name = name:sub(1, dashPos - 1)
      end
    end
    return name
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
    if o.dmgAbsorbFrame then
      if o.dmgAbsorbFrame.SetFrameStrata then o.dmgAbsorbFrame:SetFrameStrata(hfStrata) end
      if o.dmgAbsorbFrame.SetFrameLevel then o.dmgAbsorbFrame:SetFrameLevel(dmgAbsorbLevel) end
    end
    if o.fullDmgAbsorbFrame then
      if o.fullDmgAbsorbFrame.SetFrameStrata then o.fullDmgAbsorbFrame:SetFrameStrata(hfStrata) end
      if o.fullDmgAbsorbFrame.SetFrameLevel then o.fullDmgAbsorbFrame:SetFrameLevel(dmgAbsorbLevel) end
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
          o.dmgAbsorbFrame:SetPoint("TOPLEFT", statusTex, "TOPRIGHT", healOff, 0)
          o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff, 0)
        else
          local offsetPx = visW * ratio + healOff
          o.dmgAbsorbFrame:ClearAllPoints()
          o.dmgAbsorbFrame:SetPoint("TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
          o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
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
    local function ShowDmgAbsorb(dmgAbsorbPx, fillRatio)
      if not dmgAbsorbPx or dmgAbsorbPx < 1 then
        HideDmgAbsorb(true)
        return
      end
      local statusTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or nil
      local ratio = Clamp01(fillRatio)
      local healOff2 = o.healPredTotalPx or 0
      local remainingVis = nil
      if statusTex and statusTex.GetWidth then
        local texW = SafeNumeric(statusTex:GetWidth())
        if texW and w then
          remainingVis = w - texW - healOff2
        end
      end
      if remainingVis == nil then
        remainingVis = visW * (1 - ratio) - healOff2
      end
      if remainingVis < 0 then remainingVis = 0 end
      if remainingVis <= 1 then
        HideDmgAbsorb(true)
        return
      end
      if dmgAbsorbPx > remainingVis then dmgAbsorbPx = remainingVis end
      if dmgAbsorbPx < 1 then
        HideDmgAbsorb(true)
        return
      end
      o.dmgAbsorbFrame:ClearAllPoints()
      if statusTex then
        local capRightRef = o.healthFrame
        if o.bgFrame and o.bgFrame.GetRight and o.healthFrame.GetRight then
          local bgRight = SafeNumeric(o.bgFrame:GetRight())
          local hpRight = SafeNumeric(o.healthFrame:GetRight())
          if bgRight and hpRight and bgRight < hpRight then
            capRightRef = o.bgFrame
          end
        end
        local hardCap = nil
        if statusTex.GetRight and capRightRef.GetRight then
          local leftEdge = SafeNumeric(statusTex:GetRight())
          local rightEdge = SafeNumeric(capRightRef:GetRight())
          if leftEdge and rightEdge then
            hardCap = rightEdge - leftEdge - healOff2
          end
        end
        if not hardCap or hardCap <= 0 then
          hardCap = remainingVis
        end
        if not hardCap or hardCap <= 1 then
          HideDmgAbsorb(true)
          return
        end
        if dmgAbsorbPx > hardCap then dmgAbsorbPx = hardCap end
        if dmgAbsorbPx < 1 then
          HideDmgAbsorb(true)
          return
        end
        o.dmgAbsorbFrame:SetPoint("TOPLEFT", statusTex, "TOPRIGHT", healOff2, 0)
        o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff2, 0)
        o.dmgAbsorbFrame:SetSize(hardCap, h)
        o.dmgAbsorbFrame:SetMinMaxValues(0, hardCap)
        o.dmgAbsorbFrame:SetValue(dmgAbsorbPx)
      else
        local offsetPx = visW * ratio + healOff2
        o.dmgAbsorbFrame:SetPoint("TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
        o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
        o.dmgAbsorbFrame:SetSize(math.max(1, remainingVis), h)
        o.dmgAbsorbFrame:SetMinMaxValues(0, math.max(1, remainingVis))
        o.dmgAbsorbFrame:SetValue(dmgAbsorbPx)
      end
      if o.dmgAbsorbFrame.SetReverseFill then o.dmgAbsorbFrame:SetReverseFill(false) end
      o.dmgAbsorbFrame:Show()
      if o.fullDmgAbsorbFrame then o.fullDmgAbsorbFrame:Hide() end
    end
    local function ShowFullDmgAbsorb(dmgAbsorbPx)
      if not o.fullDmgAbsorbFrame or not o.fullDmgAbsorbTex then
        return false
      end
      if not dmgAbsorbPx or dmgAbsorbPx < 1 then
        o.fullDmgAbsorbFrame:Hide()
        return false
      end
      local maxW = visW
      if maxW <= 1 then
        o.fullDmgAbsorbFrame:Hide()
        return false
      end
      if dmgAbsorbPx > maxW then dmgAbsorbPx = maxW end
      o.fullDmgAbsorbFrame:ClearAllPoints()
      o.fullDmgAbsorbFrame:SetPoint("TOPRIGHT", o.healthFrame, "TOPRIGHT", 0, 0)
      o.fullDmgAbsorbFrame:SetPoint("BOTTOMRIGHT", o.healthFrame, "BOTTOMRIGHT", 0, 0)
      o.fullDmgAbsorbFrame:SetWidth(dmgAbsorbPx)
      if o.fullDmgAbsorbTex.SetTexCoord then
        local left = 1 - (dmgAbsorbPx / maxW)
        if left < 0 then left = 0 end
        if left > 1 then left = 1 end
        o.fullDmgAbsorbTex:SetTexCoord(left, 1, 0, 1)
      end
      o.fullDmgAbsorbFrame:Show()
      if o.dmgAbsorbFrame then o.dmgAbsorbFrame:Hide() end
      return true
    end
    local function ShowDmgAbsorbFromBarValues(srcDmgAbsorbBar)
      if not srcDmgAbsorbBar or not srcDmgAbsorbBar.GetMinMaxValues or not srcDmgAbsorbBar.GetValue then return false end
      local okMM, minV, maxV = pcall(srcDmgAbsorbBar.GetMinMaxValues, srcDmgAbsorbBar)
      local okV, curV = pcall(srcDmgAbsorbBar.GetValue, srcDmgAbsorbBar)
      if not okMM or not okV then return false end
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
        o.dmgAbsorbFrame:SetPoint("TOPLEFT", statusTex, "TOPRIGHT", healOff3, 0)
        o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff3, 0)
      else
        local offsetPx = visW * Clamp01(fillRatio) + healOff3
        o.dmgAbsorbFrame:SetPoint("TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
        o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
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
          local ulx, uly, llx, lly, urx, ury, lrx, lry = tex:GetTexCoord()
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
    if hpMin and hpMax and hpMax > hpMin then
      maxHealth = hpMax - hpMin
    else
      maxHealth = SafeNumeric(UnitHealthMax and UnitHealthMax(unit) or nil)
    end
    if not maxHealth or maxHealth <= 0 then
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
    local missing = (1 - Clamp01(fillRatio)) * maxHealth
    if currentHealth and currentHealth >= 0 and currentHealth <= maxHealth then
      missing = maxHealth - currentHealth
    end
    if missing < 0 then missing = 0 end

    local dmgAbsorbTotalRaw = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or nil
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
          o.dmgAbsorbFrame:SetPoint("TOPLEFT", statusTex, "TOPRIGHT", healOff4, 0)
          o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", statusTex, "BOTTOMRIGHT", healOff4, 0)
        else
          local offsetPx = visW * ratio + healOff4
          o.dmgAbsorbFrame:ClearAllPoints()
          o.dmgAbsorbFrame:SetPoint("TOPLEFT", o.healthFrame, "TOPLEFT", offsetPx, 0)
          o.dmgAbsorbFrame:SetPoint("BOTTOMLEFT", o.healthFrame, "BOTTOMLEFT", offsetPx, 0)
        end
        o.dmgAbsorbFrame:SetSize(math.max(1, hardCap), h)
        if o.dmgAbsorbFrame.SetMinMaxValues then
          pcall(o.dmgAbsorbFrame.SetMinMaxValues, o.dmgAbsorbFrame, 0, maxHealth or 1)
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
    if healPredMode == "off" and healAbsorbMode == "off" then HideAllHealPred(); return end
    local w = SafeNum(o.healthFrame.GetWidth and o.healthFrame:GetWidth() or nil)
    local h = SafeNum(o.healthFrame.GetHeight and o.healthFrame:GetHeight() or nil)
    if not w or not h or w <= 0 or h <= 0 then HideAllHealPred(); return end
    local statusTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or nil
    local maxHealthRaw = nil
    if o.origHP.GetMinMaxValues then
      local okMM, minV, maxV = pcall(o.origHP.GetMinMaxValues, o.origHP)
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
    local altPowerTex = (key == "player" and PlayerFrame and PlayerFrame.PlayerFrameContainer and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture) or nil
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
      if altPowerTex and existing and existing.altPowerTexSaved then
        if existing.altPowerTexParent and altPowerTex.SetParent then
          altPowerTex:SetParent(existing.altPowerTexParent)
        end
        if existing.altPowerTexPoints and altPowerTex.ClearAllPoints and altPowerTex.SetPoint then
          altPowerTex:ClearAllPoints()
          for i = 1, #existing.altPowerTexPoints do
            local pt = existing.altPowerTexPoints[i]
            if pt and type(pt[1]) == "string" then
              pcall(altPowerTex.SetPoint, altPowerTex, pt[1], pt[2], pt[3], pt[4], pt[5])
            end
          end
        end
        if existing.altPowerTexStrata and altPowerTex.SetFrameStrata then altPowerTex:SetFrameStrata(existing.altPowerTexStrata) end
        if existing.altPowerTexLevel ~= nil and altPowerTex.SetFrameLevel then altPowerTex:SetFrameLevel(existing.altPowerTexLevel) end
        if existing.altPowerTexDrawLayer and altPowerTex.SetDrawLayer then
          altPowerTex:SetDrawLayer(existing.altPowerTexDrawLayer, existing.altPowerTexDrawSubLevel or 0)
        end
        if existing.altPowerTexHost and existing.altPowerTexHost.Hide then
          existing.altPowerTexHost:Hide()
        end
      end
      if (key == "target" or key == "focus") and bigHBRoot and bigHBRoot.ReputationColor and existing and existing.repColorSaved then
        if existing.repColorShown and bigHBRoot.ReputationColor.Show then bigHBRoot.ReputationColor:Show() end
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
    local healthPath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_health_player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_health_other"
    local bgPath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_bg_player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_bg_other"
    local dmgAbsorbPathPrimary = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_other"
    local dmgAbsorbPathLegacy = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\absorb player"
      or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\absorb other"
    local hX, hY, hW, hH, bX, bY, bW, bH, hScalePct, bScalePct, mX, mY, mW, mH, mScalePct
    if isPlayerFrame then
      hW = -1.0; hH = 11.5; hX = -0.5; hY = 8.0; hScalePct = 0.0
      bW = 16.0; bH = 32.5; bX = -4.5; bY = 3.0; bScalePct = 0.0
      mW = 18.0; mH = -12.5; mX = -10.0; mY = 4.5; mScalePct = 0.5
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
    if isPlayerFrame and altPowerTex and altPowerTex.IsShown and altPowerTex:IsShown() then
      bgH2 = bgH2 + 10
      bY = bY - 5
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
    if portraitAnchor then
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
      if altPowerTex then
        if not o.altPowerTexSaved then
          o.altPowerTexSaved = true
          o.altPowerTexParent = altPowerTex.GetParent and altPowerTex:GetParent() or nil
          o.altPowerTexStrata = altPowerTex.GetFrameStrata and altPowerTex:GetFrameStrata() or nil
          o.altPowerTexLevel = altPowerTex.GetFrameLevel and altPowerTex:GetFrameLevel() or nil
          o.altPowerTexShown = altPowerTex.IsShown and altPowerTex:IsShown() or false
          o.altPowerTexPoints = {}
          if altPowerTex.GetNumPoints and altPowerTex.GetPoint then
            local n = altPowerTex:GetNumPoints() or 0
            for i = 1, n do
              local p, rel, rp, x, y = altPowerTex:GetPoint(i)
              if type(p) == "string" then
                o.altPowerTexPoints[#o.altPowerTexPoints + 1] = {p, rel, rp, x, y}
              end
            end
          end
          if altPowerTex.GetDrawLayer then
            o.altPowerTexDrawLayer, o.altPowerTexDrawSubLevel = altPowerTex:GetDrawLayer()
          end
        end
        if altPowerTex.SetFrameStrata then altPowerTex:SetFrameStrata("BACKGROUND") end
        if altPowerTex.SetFrameLevel then altPowerTex:SetFrameLevel(0) end
        if not o.altPowerTexHost then
          o.altPowerTexHost = CreateFrame("Frame", nil, UIParent)
        end
        if o.altPowerTexHost then
          if o.altPowerTexHost.SetFrameStrata then o.altPowerTexHost:SetFrameStrata("BACKGROUND") end
          if o.altPowerTexHost.SetFrameLevel then o.altPowerTexHost:SetFrameLevel(0) end
          if o.altPowerTexParent and o.altPowerTexHost.SetParent then
            o.altPowerTexHost:SetParent(o.altPowerTexParent)
          end
          if o.altPowerTexParent and o.altPowerTexHost.ClearAllPoints and o.altPowerTexHost.SetPoint then
            o.altPowerTexHost:ClearAllPoints()
            o.altPowerTexHost:SetPoint("TOPLEFT", o.altPowerTexParent, "TOPLEFT", 0, 0)
            o.altPowerTexHost:SetPoint("BOTTOMRIGHT", o.altPowerTexParent, "BOTTOMRIGHT", 0, 0)
          end
          if altPowerTex.SetParent and altPowerTex.GetParent and altPowerTex:GetParent() ~= o.altPowerTexHost then
            altPowerTex:SetParent(o.altPowerTexHost)
          end
          if altPowerTex.ClearAllPoints and altPowerTex.SetPoint then
            altPowerTex:ClearAllPoints()
            local restored = false
            if o.altPowerTexPoints and #o.altPowerTexPoints > 0 then
              for i = 1, #o.altPowerTexPoints do
                local pt = o.altPowerTexPoints[i]
                if pt and type(pt[1]) == "string" then
                  pcall(altPowerTex.SetPoint, altPowerTex, pt[1], pt[2], pt[3], pt[4], pt[5])
                  restored = true
                end
              end
            end
            if (not restored) and altPowerTex.SetAllPoints then
              altPowerTex:SetAllPoints(o.altPowerTexHost)
            end
          end
          if o.altPowerTexShown then
            if o.altPowerTexHost.Show then o.altPowerTexHost:Show() end
          else
            if o.altPowerTexHost.Hide then o.altPowerTexHost:Hide() end
          end
        end
        if altPowerTex.SetDrawLayer then
          altPowerTex:SetDrawLayer("BACKGROUND", -8)
        end
        if o.altPowerTexShown then
          if altPowerTex.Show then altPowerTex:Show() end
        end
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
    o.maskFixFrame:SetFrameLevel(math.max(1, healthLevel + 1))
    if (key == "target" or key == "focus") and portrait and portrait.SetFrameStrata and portrait.SetFrameLevel then
      portrait:SetFrameStrata(strata)
      portrait:SetFrameLevel(math.max(1, healthLevel + 2))
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
    o.healthTex:SetTexture(healthPath)
    if o.healthFrame.SetStatusBarTexture then
      o.healthFrame:SetStatusBarTexture(healthPath)
    end
    if o.dmgAbsorbTex then
      if o.dmgAbsorbFrame and o.dmgAbsorbFrame.SetStatusBarTexture then
        o.dmgAbsorbFrame:SetStatusBarTexture(dmgAbsorbPathPrimary)
        if not (o.dmgAbsorbFrame.GetStatusBarTexture and o.dmgAbsorbFrame:GetStatusBarTexture()) then
          o.dmgAbsorbFrame:SetStatusBarTexture(dmgAbsorbPathLegacy)
        end
        if not (o.dmgAbsorbFrame.GetStatusBarTexture and o.dmgAbsorbFrame:GetStatusBarTexture()) then
          o.dmgAbsorbFrame:SetStatusBarTexture(healthPath)
        end
      end
      o.dmgAbsorbTex = o.dmgAbsorbFrame and o.dmgAbsorbFrame.GetStatusBarTexture and o.dmgAbsorbFrame:GetStatusBarTexture() or o.dmgAbsorbTex
      o.dmgAbsorbTex:SetTexture(dmgAbsorbPathPrimary)
      if not (o.dmgAbsorbFrame and o.dmgAbsorbFrame.GetStatusBarTexture and o.dmgAbsorbFrame:GetStatusBarTexture()) then
        o.dmgAbsorbTex:SetTexture(dmgAbsorbPathLegacy)
      end
      if not (o.dmgAbsorbFrame and o.dmgAbsorbFrame.GetStatusBarTexture and o.dmgAbsorbFrame:GetStatusBarTexture()) then
        o.dmgAbsorbTex:SetTexture(healthPath)
      end
      if o.dmgAbsorbTex.SetTexCoord then
        o.dmgAbsorbTex:SetTexCoord(0, 1, 0, 1)
      end
      o.dmgAbsorbTex:SetVertexColor(0.65, 0.85, 1.00, 0.90)
      if o.dmgAbsorbTex.SetBlendMode then
        o.dmgAbsorbTex:SetBlendMode("ADD")
      end
    end
    if o.fullDmgAbsorbTex then
      local fullPath = isPlayerFrame and "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\suf_absorb_player_full"
        or "Interface\\AddOns\\CooldownCursorManager\\media\\textures\\uf_absorb_other"
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
        if not (o.healAbsorbFrame.GetStatusBarTexture and o.healAbsorbFrame:GetStatusBarTexture()) then
          o.healAbsorbFrame:SetStatusBarTexture(healthPath)
        end
      end
      o.healAbsorbTex = o.healAbsorbFrame.GetStatusBarTexture and o.healAbsorbFrame:GetStatusBarTexture() or o.healAbsorbTex
      if o.healAbsorbTex.SetTexCoord then
        o.healAbsorbTex:SetTexCoord(0, 1, 0, 1)
      end
      o.healAbsorbTex:SetVertexColor(1.0, 0.0, 0.0, 1.0)
      if o.healAbsorbTex.SetBlendMode then
        o.healAbsorbTex:SetBlendMode("ADD")
      end
    end
    o.healthTex = o.healthFrame.GetStatusBarTexture and o.healthFrame:GetStatusBarTexture() or o.healthTex
    if o.healthTex and o.healthTex.SetDrawLayer then
      o.healthTex:SetDrawLayer("ARTWORK", 2)
    end
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
      if srcBar.Hide then hooksecurefunc(srcBar, "Hide", function()
        local ov = State.ufBigHBOverlays[hookKey]
        if ov and ov.dmgAbsorbFrame then ov.dmgAbsorbFrame:Hide() end
      end) end
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
    local maxNameChars = tonumber(profile.ufBigHBNameMaxChars) or 0
    local function ApplyUFBigHBScaledFont(fontString, baseFont, baseSize, baseFlags, scale)
      if not fontString or not fontString.SetFont then return end
      local fontPath = baseFont
      local fontSize = baseSize
      local fontFlags = baseFlags
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
          local targetName = TrimUFBigHBName(ApplyUFBigHBNameTransforms(GetUFBigHBUnitName("target"), "target", profile), maxNameChars)
          if targetName and nameEl.SetText then nameEl:SetText(targetName) end
          ApplyUFBigHBScaledFont(nameEl, o.targetNameFont, o.targetNameFontSize, o.targetNameFontFlags, profile.ufBigHBTargetNameTextScale or profile.ufBigHBTargetTextScale)
        end
        if not o.targetNameSetTextHooked and nameEl.SetText and type(hooksecurefunc) == "function" then
          o.targetNameSetTextHooked = true
          hooksecurefunc(nameEl, "SetText", function(self, text)
            if o.targetNameTrimming then return end
            local p = addonTable.GetProfile and addonTable.GetProfile()
            if not p or p.ufBigHBHideTargetName then return end
            local mc = tonumber(p.ufBigHBNameMaxChars) or 0
            if mc <= 0 then return end
            local trimmed = TrimUFBigHBName(ApplyUFBigHBNameTransforms(text, "target", p), mc)
            if trimmed and trimmed ~= text then
              o.targetNameTrimming = true
              self:SetText(trimmed)
              o.targetNameTrimming = nil
            end
          end)
        end
        local nx = (profile.ufBigHBTargetNameX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.target.nameX
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
            nameEl:SetPoint("CENTER", o.healthFrame, "CENTER", nx, ny)
            if nameEl.SetJustifyH then nameEl:SetJustifyH("CENTER") end
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
        if profile.ufBigHBHideTargetLevel then
          if levelEl.Hide then levelEl:Hide() end
        else
          if levelEl.Show then levelEl:Show() end
          if levelEl.SetTextColor then
            levelEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          ApplyUFBigHBScaledFont(levelEl, o.targetLevelFont, o.targetLevelFontSize, o.targetLevelFontFlags, profile.ufBigHBTargetLevelTextScale or profile.ufBigHBTargetTextScale)
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
          local focusName = TrimUFBigHBName(ApplyUFBigHBNameTransforms(GetUFBigHBUnitName("focus"), "focus", profile), maxNameChars)
          if focusName and nameEl.SetText then nameEl:SetText(focusName) end
          ApplyUFBigHBScaledFont(nameEl, o.nameOrigFont, o.nameOrigFontSize, o.nameOrigFontFlags, profile.ufBigHBFocusNameTextScale or profile.ufBigHBFocusTextScale)
        end
        if not o.focusNameSetTextHooked and nameEl.SetText and type(hooksecurefunc) == "function" then
          o.focusNameSetTextHooked = true
          hooksecurefunc(nameEl, "SetText", function(self, text)
            if o.focusNameTrimming then return end
            local p = addonTable.GetProfile and addonTable.GetProfile()
            if not p or p.ufBigHBHideFocusName then return end
            local mc = tonumber(p.ufBigHBNameMaxChars) or 0
            if mc <= 0 then return end
            local trimmed = TrimUFBigHBName(ApplyUFBigHBNameTransforms(text, "focus", p), mc)
            if trimmed and trimmed ~= text then
              o.focusNameTrimming = true
              self:SetText(trimmed)
              o.focusNameTrimming = nil
            end
          end)
        end
        local nx = (profile.ufBigHBFocusNameX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.focus.nameX
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
            nameEl:SetPoint("CENTER", o.healthFrame, "CENTER", nx, ny)
            if nameEl.SetJustifyH then nameEl:SetJustifyH("CENTER") end
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
        if profile.ufBigHBHideFocusLevel then
          if levelEl.Hide then levelEl:Hide() end
        else
          if levelEl.Show then levelEl:Show() end
          if levelEl.SetTextColor then
            levelEl:SetTextColor(profile.ufNameColorR or 1, profile.ufNameColorG or 1, profile.ufNameColorB or 1)
          end
          ApplyUFBigHBScaledFont(levelEl, o.levelOrigFont, o.levelOrigFontSize, o.levelOrigFontFlags, profile.ufBigHBFocusLevelTextScale or profile.ufBigHBFocusTextScale)
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
          local playerName = TrimUFBigHBName(GetUFBigHBUnitName("player"), maxNameChars)
          if playerName and nameEl.SetText then nameEl:SetText(playerName) end
          ApplyUFBigHBScaledFont(nameEl, o.nameOrigFont, o.nameOrigFontSize, o.nameOrigFontFlags, profile.ufBigHBPlayerNameTextScale or profile.ufBigHBPlayerTextScale)
        end
        local nx = (profile.ufBigHBPlayerNameX or 0) + addonTable.UF_BIG_HB_TEXT_BASE.player.nameX
        local ny = (profile.ufBigHBPlayerNameY or 0) + addonTable.UF_BIG_HB_TEXT_BASE.player.nameY
        if nameEl.ClearAllPoints and nameEl.SetPoint and o.namePoint then
          nameEl:ClearAllPoints()
          nameEl:SetPoint(o.namePoint, o.nameRelTo, o.nameRelPt, (o.nameOrigX or 0) + nx, (o.nameOrigY or 0) + ny)
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
        if profile.ufBigHBHidePlayerLevel then
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
      C_Timer.After(0.5, function()
        local ov = State.ufBigHBOverlays and State.ufBigHBOverlays["player"]
        if not ov or not ov.healthFrame then return end
        local pRoot = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
        local pHC = pRoot and pRoot.HealthBarsContainer
        local pHP = pHC and pHC.HealthBar
        if not pHP then return end
        SyncUFBigHBOverlayValue(ov, pHP)
        ApplyUFBigHBOverlayHealthColor(ov, pHP, "player")
      end)
    end
  end
  if not orig.ufFontHooked then
    orig.ufFontHooked = true
    orig.ufFontObjects = orig.ufFontObjects or {}
    local function GetOrCreateFontObject(size)
      local key = math.floor(size + 0.5)
      if not orig.ufFontObjects[key] then
        orig.ufFontObjects[key] = CreateFont("CCM_UFFont_" .. key)
      end
      local gf, go = GetGlobalFont()
      local oFlag = go or ""
      orig.ufFontObjects[key]:SetFont(gf, key, oFlag)
      return orig.ufFontObjects[key]
    end
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
