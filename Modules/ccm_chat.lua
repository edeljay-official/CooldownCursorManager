--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_chat.lua
-- Chat Enhancement: class colors, timestamps, copy, URLs, background, fade
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, addonTable = ...

local GetProfile = addonTable.GetProfile

local CHAT_MSG_EVENTS = {
  "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
  "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
  "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_CHANNEL",
  "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
}

-- ============================================================
-- Class-Colored Names
-- ============================================================

local classColorFilterInstalled = false
local classColorCache = {}

local function ClassColorFilter(self, event, msg, sender, ...)
  local profile = GetProfile and GetProfile()
  if not profile or not profile.chatClassColorNames then return false end
  local guid = select(10, ...)
  if not guid or guid == "" then return false end
  local cachedColor = classColorCache[guid]
  if cachedColor == nil then
    local _, englishClass = GetPlayerInfoByGUID(guid)
    if englishClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[englishClass] then
      local c = RAID_CLASS_COLORS[englishClass]
      cachedColor = string.format("|cFF%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
      classColorCache[guid] = cachedColor
    else
      classColorCache[guid] = false
    end
  end
  if not cachedColor then return false end
  local coloredMsg = msg:gsub("(|Hplayer:[^|]-|h%[)([^%]]+)(%]|h)", function(pre, name, post)
    return pre .. cachedColor .. name .. "|r" .. post
  end)
  if coloredMsg ~= msg then
    return false, coloredMsg, sender, ...
  end
  return false
end

addonTable.SetupChatClassColorNames = function()
  if classColorFilterInstalled then return end
  classColorFilterInstalled = true
  for _, event in ipairs(CHAT_MSG_EVENTS) do
    ChatFrame_AddMessageEventFilter(event, ClassColorFilter)
  end
end

-- ============================================================
-- Timestamps
-- ============================================================

local TIMESTAMP_FORMATS = {
  ["HH:MM"] = "%H:%M ",
  ["HH:MM:SS"] = "%H:%M:%S ",
  ["12h"] = "%I:%M %p ",
}

addonTable.SetupChatTimestamps = function()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.chatTimestamps then
    if SetCVar then pcall(SetCVar, "showTimestamps", "none") end
    return
  end
  local fmt = TIMESTAMP_FORMATS[profile.chatTimestampFormat] or "%H:%M "
  if SetCVar then pcall(SetCVar, "showTimestamps", fmt) end
end

-- ============================================================
-- Copy Chat Button
-- ============================================================

local copyFrame = nil
local copyButtons = {}

local function StripColors(text)
  if not text then return "" end
  text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
  text = text:gsub("|r", "")
  text = text:gsub("|H[^|]-|h", "")
  text = text:gsub("|h", "")
  text = text:gsub("|T[^|]-|t", "")
  text = text:gsub("|A[^|]-|a", "")
  return text
end

local function ShowCopyFrame(chatFrame)
  if not copyFrame then
    copyFrame = CreateFrame("Frame", "CCMChatCopyFrame", UIParent, "BackdropTemplate")
    copyFrame:SetSize(500, 400)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    copyFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    copyFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    copyFrame:SetFrameStrata("DIALOG")
    copyFrame:SetMovable(true)
    copyFrame:EnableMouse(true)
    copyFrame:RegisterForDrag("LeftButton")
    copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
    copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)

    local closeBtn = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", 2, 2)

    local scrollFrame = CreateFrame("ScrollFrame", "CCMChatCopyScroll", copyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local editBox = CreateFrame("EditBox", "CCMChatCopyEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(440)
    editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
    scrollFrame:SetScrollChild(editBox)

    copyFrame.editBox = editBox
  end

  local lines = {}
  local numMessages = chatFrame:GetNumMessages()
  for i = 1, numMessages do
    local text = chatFrame:GetMessageInfo(i)
    if text then
      table.insert(lines, StripColors(text))
    end
  end

  copyFrame.editBox:SetText(table.concat(lines, "\n"))
  copyFrame:Show()
  copyFrame.editBox:HighlightText()
  copyFrame.editBox:SetFocus()
end

local function UpdateCopyButtonPosition(btn, chatFrame, corner)
  btn:ClearAllPoints()
  if corner == "TOPLEFT" then
    btn:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", 2, -2)
  elseif corner == "BOTTOMLEFT" then
    btn:SetPoint("BOTTOMLEFT", chatFrame, "BOTTOMLEFT", 2, 2)
  elseif corner == "BOTTOMRIGHT" then
    btn:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -2, 2)
  else
    btn:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -2, -2)
  end
end

addonTable.SetupChatCopyButton = function()
  local profile = GetProfile and GetProfile()
  local enabled = profile and profile.chatCopyButton
  local corner = profile and profile.chatCopyButtonCorner or "TOPRIGHT"

  for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    if chatFrame then
      if not copyButtons[i] then
        local btn = CreateFrame("Button", nil, chatFrame)
        btn:SetSize(20, 20)
        btn:SetFrameStrata("HIGH")
        btn:SetIgnoreParentAlpha(true)
        btn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        btn:SetAlpha(0.6)
        btn:SetScript("OnClick", function()
          ShowCopyFrame(chatFrame)
        end)
        btn:SetScript("OnEnter", function(self)
          self:SetAlpha(1)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText("Copy Chat")
          GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
          self:SetAlpha(0.6)
          GameTooltip:Hide()
        end)
        copyButtons[i] = btn
      end
      if enabled then
        UpdateCopyButtonPosition(copyButtons[i], chatFrame, corner)
        copyButtons[i]:Show()
      else
        copyButtons[i]:Hide()
      end
    end
  end
end

-- ============================================================
-- URL Detection
-- ============================================================

local urlFilterInstalled = false
local urlPopup = nil

local URL_PATTERNS = {
  "(https?://[%w%.%-_~:/%?#@!%$&'%(%)%*%+,;%%=]+)",
  "(www%.[%w%.%-]+%.[%a][%a]+[%w%.%-_~:/%?#@!%$&'%(%)%*%+,;%%=]*)",
}

local function IsInsideLink(msg, startPos)
  local searchPos = 1
  while true do
    local hStart, hEnd = msg:find("|H[^|]-|h[^|]-|h", searchPos)
    if not hStart then break end
    if startPos >= hStart and startPos <= hEnd then return true end
    searchPos = hEnd + 1
  end
  return false
end

local function UrlFilter(self, event, msg, ...)
  local profile = GetProfile and GetProfile()
  if not profile or not profile.chatUrlDetection then return false end
  local modified = msg
  for _, pattern in ipairs(URL_PATTERNS) do
    modified = modified:gsub(pattern, function(url)
      local startPos = msg:find(url, 1, true)
      if startPos and IsInsideLink(msg, startPos) then return url end
      return "|cFF33BBFF|Hurl:" .. url .. "|h[" .. url .. "]|h|r"
    end)
  end
  if modified ~= msg then
    return false, modified, ...
  end
  return false
end

local function ShowUrlPopup(url)
  if not urlPopup then
    urlPopup = CreateFrame("Frame", "CCMUrlPopup", UIParent, "BackdropTemplate")
    urlPopup:SetSize(450, 50)
    urlPopup:SetPoint("CENTER", 0, 200)
    urlPopup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    urlPopup:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    urlPopup:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    urlPopup:SetFrameStrata("DIALOG")

    local eb = CreateFrame("EditBox", nil, urlPopup)
    eb:SetPoint("TOPLEFT", 10, -10)
    eb:SetPoint("BOTTOMRIGHT", -10, 10)
    eb:SetFontObject(ChatFontNormal)
    eb:SetAutoFocus(true)
    eb:SetScript("OnEscapePressed", function() urlPopup:Hide() end)
    eb:SetScript("OnEditFocusLost", function() urlPopup:Hide() end)
    urlPopup.editBox = eb
  end
  urlPopup.editBox:SetText(url)
  urlPopup:Show()
  urlPopup.editBox:HighlightText()
end

addonTable.SetupChatUrlDetection = function()
  if urlFilterInstalled then return end
  urlFilterInstalled = true
  for _, event in ipairs(CHAT_MSG_EVENTS) do
    ChatFrame_AddMessageEventFilter(event, UrlFilter)
  end
  hooksecurefunc("SetItemRef", function(link)
    if link and link:sub(1, 4) == "url:" then
      ShowUrlPopup(link:sub(5))
    end
  end)
end

-- ============================================================
-- Chat Background
-- ============================================================

addonTable.SetupChatBackground = function()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.chatBackground then
    for i = 1, NUM_CHAT_WINDOWS do
      local cf = _G["ChatFrame" .. i]
      if cf then
        pcall(FCF_SetWindowColor, cf, 0, 0, 0)
        pcall(FCF_SetWindowAlpha, cf, 0.25)
      end
    end
    return
  end
  local r = profile.chatBackgroundColorR or 0
  local g = profile.chatBackgroundColorG or 0
  local b = profile.chatBackgroundColorB or 0
  local a = (profile.chatBackgroundAlpha or 40) / 100
  for i = 1, NUM_CHAT_WINDOWS do
    local cf = _G["ChatFrame" .. i]
    if cf then
      pcall(FCF_SetWindowColor, cf, r, g, b)
      pcall(FCF_SetWindowAlpha, cf, a)
    end
  end
end

-- ============================================================
-- Hide Chat Buttons
-- ============================================================

local chatButtonsHooked = false
local chatButtonsHidden = {}

local function HideAndHook(frame, key)
  if not frame then return end
  if chatButtonsHidden[key] then return end
  chatButtonsHidden[key] = true
  frame:Hide()
  hooksecurefunc(frame, "Show", function(self)
    local profile = GetProfile and GetProfile()
    if profile and profile.chatHideButtons then
      self:Hide()
    end
  end)
end

addonTable.SetupChatHideButtons = function()
  local profile = GetProfile and GetProfile()
  local enabled = profile and profile.chatHideButtons

  if enabled and not chatButtonsHooked then
    chatButtonsHooked = true
    HideAndHook(ChatFrameMenuButton, "menu")
    HideAndHook(ChatFrameChannelButton, "channel")
    HideAndHook(QuickJoinToastButton, "quickjoin")
    for i = 1, NUM_CHAT_WINDOWS do
      local bf = _G["ChatFrame" .. i .. "ButtonFrame"]
      HideAndHook(bf, "bf" .. i)
    end
  end

  if enabled then
    if ChatFrameMenuButton then ChatFrameMenuButton:Hide() end
    if ChatFrameChannelButton then ChatFrameChannelButton:Hide() end
    if QuickJoinToastButton then QuickJoinToastButton:Hide() end
    for i = 1, NUM_CHAT_WINDOWS do
      local bf = _G["ChatFrame" .. i .. "ButtonFrame"]
      if bf then bf:Hide() end
    end
  else
    if ChatFrameMenuButton then ChatFrameMenuButton:Show() end
    if ChatFrameChannelButton then ChatFrameChannelButton:Show() end
    if QuickJoinToastButton then QuickJoinToastButton:Show() end
    for i = 1, NUM_CHAT_WINDOWS do
      local bf = _G["ChatFrame" .. i .. "ButtonFrame"]
      if bf then bf:Show() end
    end
  end
end

-- ============================================================
-- Chat Fade
-- ============================================================

addonTable.SetupChatFade = function()
  local profile = GetProfile and GetProfile()
  if not profile or not profile.chatFadeToggle then
    for i = 1, NUM_CHAT_WINDOWS do
      local cf = _G["ChatFrame" .. i]
      if cf then
        cf:SetFading(true)
        if cf.SetTimeVisible then cf:SetTimeVisible(120) end
        if cf.SetFadeDuration then cf:SetFadeDuration(3) end
      end
    end
    return
  end
  local fadeDelay = profile.chatFadeDelay or 20
  for i = 1, NUM_CHAT_WINDOWS do
    local cf = _G["ChatFrame" .. i]
    if cf then
      cf:SetFading(true)
      if cf.SetTimeVisible then cf:SetTimeVisible(fadeDelay) end
      if cf.SetFadeDuration then cf:SetFadeDuration(3) end
    end
  end
end

-- ============================================================
-- Edit Box Position
-- ============================================================

addonTable.SetupChatEditBoxPosition = function()
  local profile = GetProfile and GetProfile()
  local position = profile and profile.chatEditBoxPosition or "bottom"
  for i = 1, NUM_CHAT_WINDOWS do
    local editBox = _G["ChatFrame" .. i .. "EditBox"]
    local chatFrame = _G["ChatFrame" .. i]
    if editBox and chatFrame then
      editBox:ClearAllPoints()
      if position == "top" then
        editBox:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 0, 0)
        editBox:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", 0, 0)
      else
        editBox:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", 0, 0)
        editBox:SetPoint("TOPRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
      end
    end
  end
end

-- ============================================================
-- Edit Box Style
-- ============================================================

addonTable.SetupChatEditBoxStyle = function()
  local profile = GetProfile and GetProfile()
  local styled = profile and profile.chatEditBoxStyled

  local bgR, bgG, bgB, bgA = 0.06, 0.06, 0.08, 0.9
  if profile and profile.chatBackground then
    bgR = profile.chatBackgroundColorR or 0
    bgG = profile.chatBackgroundColorG or 0
    bgB = profile.chatBackgroundColorB or 0
    bgA = (profile.chatBackgroundAlpha or 40) / 100
  end

  for i = 1, NUM_CHAT_WINDOWS do
    local eb = _G["ChatFrame" .. i .. "EditBox"]
    local cf = _G["ChatFrame" .. i]
    if not eb or not cf then break end

    if not eb.ccmStyleInit then
      eb.ccmStyleInit = true
      eb.ccmOrigInsets = {eb:GetTextInsets()}

      eb.ccmBg = eb:CreateTexture(nil, "BACKGROUND", nil, -8)
      eb.ccmBg:SetPoint("LEFT", cf, "LEFT", 0, 0)
      eb.ccmBg:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
      eb.ccmBg:SetPoint("TOP", eb, "TOP", 0, 0)
      eb.ccmBg:SetPoint("BOTTOM", eb, "BOTTOM", 0, 0)
      eb.ccmBg:Hide()

      eb.ccmBlizzTextures = {}
      for j = 1, select("#", eb:GetRegions()) do
        local region = select(j, eb:GetRegions())
        if region and region ~= eb.ccmBg and region.IsObjectType and region:IsObjectType("Texture") then
          tinsert(eb.ccmBlizzTextures, region)
        end
      end

      eb.ccmChildren = {}
      for j = 1, select("#", eb:GetChildren()) do
        local child = select(j, eb:GetChildren())
        if child then tinsert(eb.ccmChildren, child) end
      end

      for _, tex in ipairs(eb.ccmBlizzTextures) do
        tex.ccmOrigAlpha = tex:GetAlpha()
        if tex.Show then
          hooksecurefunc(tex, "Show", function(self)
            local p = GetProfile and GetProfile()
            if p and p.chatEditBoxStyled then self:Hide(); self:SetAlpha(0) end
          end)
        end
        if tex.SetAlpha then
          hooksecurefunc(tex, "SetAlpha", function(self, a)
            local p = GetProfile and GetProfile()
            if p and p.chatEditBoxStyled and a > 0 then self:Hide(); self:SetAlpha(0) end
          end)
        end
      end

      for _, child in ipairs(eb.ccmChildren) do
        child.ccmOrigAlpha = child:GetAlpha()
        if child.Show then
          hooksecurefunc(child, "Show", function(self)
            local p = GetProfile and GetProfile()
            if p and p.chatEditBoxStyled then self:Hide(); self:SetAlpha(0) end
          end)
        end
        if child.SetAlpha then
          hooksecurefunc(child, "SetAlpha", function(self, a)
            local p = GetProfile and GetProfile()
            if p and p.chatEditBoxStyled and a > 0 then self:Hide(); self:SetAlpha(0) end
          end)
        end
      end
    end

    if not eb.ccmFocusHooked then
      eb.ccmFocusHooked = true
      eb:HookScript("OnEditFocusGained", function(self)
        local p = GetProfile and GetProfile()
        if p and p.chatEditBoxStyled then self:SetAlpha(1) end
      end)
      eb:HookScript("OnEditFocusLost", function(self)
        local p = GetProfile and GetProfile()
        if p and p.chatEditBoxStyled then self:SetAlpha(0) end
      end)
      hooksecurefunc(eb, "SetAlpha", function(self, a)
        local p = GetProfile and GetProfile()
        if p and p.chatEditBoxStyled and a > 0 and not self:HasFocus() then
          self:SetAlpha(0)
        end
      end)
    end

    if styled then
      eb.ccmBg:SetColorTexture(bgR, bgG, bgB, bgA)
      eb.ccmBg:Show()
      for _, tex in ipairs(eb.ccmBlizzTextures) do tex:Hide(); tex:SetAlpha(0) end
      for _, child in ipairs(eb.ccmChildren) do child:Hide(); child:SetAlpha(0) end
      eb:ClearAllPoints()
      local position = profile and profile.chatEditBoxPosition or "bottom"
      if position == "top" then
        eb:SetPoint("BOTTOMLEFT", cf, "TOPLEFT", 0, 5)
        eb:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", 0, 5)
      else
        eb:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", 0, -5)
        eb:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", 0, -5)
      end
      eb:SetTextInsets(8, 8, 0, 0)
      if eb:HasFocus() then eb:SetAlpha(1) else eb:SetAlpha(0) end
    else
      eb.ccmBg:Hide()
      eb:SetAlpha(1)
      for _, tex in ipairs(eb.ccmBlizzTextures) do tex:SetAlpha(tex.ccmOrigAlpha or 1); tex:Show() end
      for _, child in ipairs(eb.ccmChildren) do child:SetAlpha(child.ccmOrigAlpha or 1); child:Show() end
      if eb.ccmOrigInsets then
        eb:SetTextInsets(unpack(eb.ccmOrigInsets))
      end
      eb:ClearAllPoints()
      local position = profile and profile.chatEditBoxPosition or "bottom"
      if position == "top" then
        eb:SetPoint("BOTTOMLEFT", cf, "TOPLEFT", 0, 0)
        eb:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", 0, 0)
      else
        eb:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", 0, 0)
        eb:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", 0, 0)
      end
    end
  end
end

-- ============================================================
-- Disable Tab Flash
-- ============================================================

local tabFlashHooked = false

addonTable.SetupChatTabFlash = function()
  if tabFlashHooked or not FCF_StartAlertFlash then return end
  tabFlashHooked = true
  hooksecurefunc("FCF_StartAlertFlash", function(chatFrame)
    local p = GetProfile and GetProfile()
    if p and p.chatTabFlash and FCF_StopAlertFlash then
      FCF_StopAlertFlash(chatFrame)
    end
  end)
end

-- ============================================================
-- Hide/Mouseover Chat Tabs
-- ============================================================

local chatTabsHooked = false
local chatTabMouseoverFrame = nil
local chatTabOrigVisible = {}

local function IsChatTabActive(i)
  local cf = _G["ChatFrame" .. i]
  if not cf then return false end
  if cf.isDocked or (GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.DOCKED and GENERAL_CHAT_DOCK.DOCKED[cf]) then return true end
  if cf:IsShown() then return true end
  return false
end

local function SaveTabVisibility()
  if next(chatTabOrigVisible) then return end
  for i = 1, NUM_CHAT_WINDOWS do
    local tab = _G["ChatFrame" .. i .. "Tab"]
    chatTabOrigVisible[i] = tab and tab:IsShown() and IsChatTabActive(i)
  end
end

addonTable.SetupChatHideTabs = function()
  local profile = GetProfile and GetProfile()
  local mode = profile and profile.chatHideTabs or "off"

  SaveTabVisibility()

  if not chatTabsHooked and mode ~= "off" then
    chatTabsHooked = true
    for i = 1, NUM_CHAT_WINDOWS do
      local tab = _G["ChatFrame" .. i .. "Tab"]
      if tab then
        hooksecurefunc(tab, "Show", function(self)
          if not chatTabOrigVisible[i] then return end
          local p = GetProfile and GetProfile()
          local m = p and p.chatHideTabs or "off"
          if m == "hide" then
            self:Hide()
          elseif m == "mouseover" then
            self:SetAlpha(0)
          end
        end)
      end
    end
  end

  for i = 1, NUM_CHAT_WINDOWS do
    if chatTabOrigVisible[i] then
      local tab = _G["ChatFrame" .. i .. "Tab"]
      if tab then
        if mode == "hide" then
          tab:Hide()
        elseif mode == "mouseover" then
          tab:Show()
          tab:SetAlpha(0)
        else
          tab:Show()
          tab:SetAlpha(1)
        end
      end
    end
  end

  if mode == "mouseover" then
    if not chatTabMouseoverFrame then
      chatTabMouseoverFrame = CreateFrame("Frame")
      local elapsed = 0
      chatTabMouseoverFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local p = GetProfile and GetProfile()
        if not p or p.chatHideTabs ~= "mouseover" then
          for i = 1, NUM_CHAT_WINDOWS do
            if chatTabOrigVisible[i] then
              local tab = _G["ChatFrame" .. i .. "Tab"]
              if tab then tab:SetAlpha(1) end
            end
          end
          self:Hide()
          return
        end
        local mx, my = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        local show = false
        for i = 1, NUM_CHAT_WINDOWS do
          if chatTabOrigVisible[i] then
            local tab = _G["ChatFrame" .. i .. "Tab"]
            if tab and tab:IsShown() then
              local l, b, w, h = tab:GetRect()
              if l and mx >= l - 10 and mx <= l + w + 10 and my >= b - 10 and my <= b + h + 10 then
                show = true
                break
              end
            end
          end
        end
        for i = 1, NUM_CHAT_WINDOWS do
          if chatTabOrigVisible[i] then
            local tab = _G["ChatFrame" .. i .. "Tab"]
            if tab then tab:SetAlpha(show and 1 or 0) end
          end
        end
      end)
    end
    chatTabMouseoverFrame:Show()
  elseif chatTabMouseoverFrame then
    chatTabMouseoverFrame:Hide()
  end
end

-- ============================================================
-- Master Setup
-- ============================================================

addonTable.SetupChatEnhancements = function()
  addonTable.SetupChatClassColorNames()
  addonTable.SetupChatTimestamps()
  addonTable.SetupChatCopyButton()
  addonTable.SetupChatUrlDetection()
  addonTable.SetupChatBackground()
  addonTable.SetupChatHideButtons()
  addonTable.SetupChatFade()
  addonTable.SetupChatEditBoxPosition()
  addonTable.SetupChatEditBoxStyle()
  addonTable.SetupChatTabFlash()
  addonTable.SetupChatHideTabs()
end
