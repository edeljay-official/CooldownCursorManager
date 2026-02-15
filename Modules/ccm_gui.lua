--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_gui.lua
-- Reusable GUI widget factories and UI component builders
-- Author: Edeljay
--------------------------------------------------------------------------------
local _, CCM = ...
local addonTable = CCM
local _activeDropdownList = nil
local _dropdownClickCatcher = nil

local function CreateStyledButton(parent, text, w, h)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn._ccmControlType = "button"
  btn:SetSize(w, h)
  btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
  btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local t = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  t:SetPoint("CENTER")
  t:SetText(text)
  t:SetTextColor(0.9, 0.9, 0.9)
  btn.text = t
  btn:SetScript("OnEnter", function()
    btn:SetBackdropColor(0.22, 0.22, 0.28, 1)
    btn:SetBackdropBorderColor(0.45, 0.45, 0.5, 1)
    t:SetTextColor(1, 1, 1)
  end)
  btn:SetScript("OnLeave", function()
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    t:SetTextColor(0.9, 0.9, 0.9)
  end)
  return btn
end

local function Section(p, txt, y, rightOffset)
  local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  l:SetPoint("TOPLEFT", p, "TOPLEFT", 15, y)
  l:SetText(txt)
  l:SetTextColor(1, 0.82, 0)
  local ln = p:CreateTexture(nil, "ARTWORK")
  ln:SetHeight(1)
  ln:SetPoint("LEFT", l, "RIGHT", 10, 0)
  ln:SetPoint("RIGHT", p, "RIGHT", rightOffset or -15, 0)
  ln:SetColorTexture(0.35, 0.35, 0.40, 1)
  ln:SetSnapToPixelGrid(true)
  ln:SetTexelSnappingBias(0)
  return l
end

local function Slider(p, txt, x, y, mn, mx, df, st)
  local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  l:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
  l:SetText(txt)
  l:SetTextColor(0.9, 0.9, 0.9)
  local s = CreateFrame("Slider", nil, p, "BackdropTemplate")
  s._ccmControlType = "slider"
  s:SetPoint("TOPLEFT", l, "BOTTOMLEFT", 0, -8)
  s:SetSize(180, 16)
  s:SetOrientation("HORIZONTAL")
  s:SetMinMaxValues(mn, mx)
  s:SetValue(df)
  s:SetValueStep(st)
  s:SetObeyStepOnDrag(true)
  s:EnableMouse(true)
  s:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  s:SetBackdropColor(0.08, 0.08, 0.10, 1)
  s:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  local thumb = s:CreateTexture(nil, "ARTWORK")
  thumb:SetSize(14, 18)
  thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
  s:SetThumbTexture(thumb)
  local lowText = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lowText:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -2)
  lowText:SetText(mn)
  lowText:SetTextColor(0.58, 0.58, 0.62)
  s.Low = lowText
  local highText = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  highText:SetPoint("TOPRIGHT", s, "BOTTOMRIGHT", 0, -2)
  highText:SetText(mx)
  highText:SetTextColor(0.58, 0.58, 0.62)
  s.High = highText
  s.Text = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  s.Text:SetText("")
  local vtBg = CreateFrame("Frame", nil, p, "BackdropTemplate")
  vtBg:SetSize(50, 20)
  vtBg:SetPoint("LEFT", s, "RIGHT", 8, 0)
  vtBg:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  vtBg:SetBackdropColor(0.05, 0.05, 0.07, 1)
  vtBg:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  local vt = CreateFrame("EditBox", nil, vtBg)
  vt:SetSize(46, 18)
  vt:SetPoint("CENTER", vtBg, "CENTER", 0, 0)
  vt:SetFontObject("GameFontHighlight")
  vt:SetJustifyH("CENTER")
  vt:SetAutoFocus(false)
  vt:SetText(df)
  vt:SetTextColor(1, 1, 1)
  s.valueText = vt
  s.valueTextBg = vtBg
  s.step = st
  s.minVal = mn
  s.maxVal = mx
  s._updating = false
  local function ApplyEditBoxValue()
    if s._updating then return end
    local text = vt:GetText()
    local num = tonumber(text)
    if num then
      local step = s.step or 1
      num = math.floor(num / step + 0.5) * step
      if num < s.minVal then num = s.minVal end
      if num > s.maxVal then num = s.maxVal end
      s._updating = true
      s:SetValue(num)
      s._updating = false
      if step < 1 then
        vt:SetText(string.format("%.2f", num))
      else
        vt:SetText(math.floor(num))
      end
    else
      local cur = s:GetValue()
      local step = s.step or 1
      if step < 1 then
        vt:SetText(string.format("%.2f", cur))
      else
        vt:SetText(math.floor(cur))
      end
    end
    vt:ClearFocus()
  end
  vt:SetScript("OnEnterPressed", ApplyEditBoxValue)
  vt:SetScript("OnEscapePressed", function()
    local cur = s:GetValue()
    local step = s.step or 1
    if step < 1 then
      vt:SetText(string.format("%.2f", cur))
    else
      vt:SetText(math.floor(cur))
    end
    vt:ClearFocus()
  end)
  vt:SetScript("OnEditFocusLost", ApplyEditBoxValue)
  s:SetScript("OnValueChanged", function(self, value)
    if self._updating then return end
    if self._ccmDisabled then
      self._updating = true
      self:SetValue(self._ccmDisabledValue or value)
      self._updating = false
      return
    end
    local step = self.step or 1
    local rounded = math.floor(value / step + 0.5) * step
    if math.abs(value - rounded) > 0.001 then
      self._updating = true
      self:SetValue(rounded)
      self._updating = false
      return
    end
    if not self.valueText:HasFocus() then
      if step < 1 then
        self.valueText:SetText(string.format("%.2f", rounded))
      else
        self.valueText:SetText(math.floor(rounded))
      end
    end
  end)
  s:SetScript("OnEnter", function() thumb:SetColorTexture(0.5, 0.5, 0.55, 1) end)
  s:SetScript("OnLeave", function() thumb:SetColorTexture(0.4, 0.4, 0.45, 1) end)
  s:EnableMouseWheel(false)
  s:SetScript("OnMouseWheel", nil)
  local upBtn = CreateFrame("Button", nil, vtBg)
  upBtn:SetSize(16, 10)
  upBtn:SetPoint("BOTTOMLEFT", vtBg, "BOTTOMRIGHT", 2, 10)
  local upTex = upBtn:CreateTexture(nil, "ARTWORK")
  upTex:SetAllPoints()
  upTex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_up.tga")
  upBtn:SetScript("OnClick", function()
    local step = s.step or s:GetValueStep() or 1
    local _, maxVal = s:GetMinMaxValues()
    local currentVal = s:GetValue()
    local newVal = currentVal + step
    if newVal > maxVal then newVal = maxVal end
    s:SetValue(newVal)
  end)
  upBtn:SetScript("OnEnter", function() upTex:SetVertexColor(1, 0.82, 0, 1) end)
  upBtn:SetScript("OnLeave", function() upTex:SetVertexColor(1, 1, 1, 1) end)
  local downBtn = CreateFrame("Button", nil, vtBg)
  downBtn:SetSize(16, 10)
  downBtn:SetPoint("TOPLEFT", vtBg, "TOPRIGHT", 2, -10)
  local downTex = downBtn:CreateTexture(nil, "ARTWORK")
  downTex:SetAllPoints()
  downTex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down.tga")
  downBtn:SetScript("OnClick", function()
    local step = s.step or s:GetValueStep() or 1
    local minVal = s:GetMinMaxValues()
    local currentVal = s:GetValue()
    local newVal = currentVal - step
    if newVal < minVal then newVal = minVal end
    s:SetValue(newVal)
  end)
  downBtn:SetScript("OnEnter", function() downTex:SetVertexColor(1, 0.82, 0, 1) end)
  downBtn:SetScript("OnLeave", function() downTex:SetVertexColor(1, 1, 1, 1) end)
  s.upBtn = upBtn
  s.downBtn = downBtn
  s.label = l
  s.SetEnabled = function(self, enabled)
    self._ccmDisabled = not enabled
    if not enabled then self._ccmDisabledValue = self:GetValue() end
    if enabled then
      self:Enable()
      self:EnableMouse(true)
      l:SetTextColor(0.9, 0.9, 0.9)
      self:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
      thumb:SetColorTexture(0.4, 0.4, 0.45, 1)
      vt:SetTextColor(1, 1, 1)
      vt:EnableMouse(true)
      upBtn:Enable()
      upBtn:EnableMouse(true)
      downBtn:Enable()
      downBtn:EnableMouse(true)
    else
      self:Disable()
      self:EnableMouse(false)
      l:SetTextColor(0.4, 0.4, 0.4)
      self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
      thumb:SetColorTexture(0.25, 0.25, 0.28, 1)
      vt:SetTextColor(0.4, 0.4, 0.4)
      vt:EnableMouse(false)
      upBtn:Disable()
      upBtn:EnableMouse(false)
      downBtn:Disable()
      downBtn:EnableMouse(false)
    end
  end
  return s
end

local function Checkbox(p, txt, x, y)
  local cb = CreateFrame("CheckButton", nil, p, "BackdropTemplate")
  cb._ccmControlType = "checkbox"
  cb:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
  cb:SetSize(18, 18)
  cb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  cb:SetBackdropColor(0.08, 0.08, 0.10, 1)
  cb:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local check = cb:CreateTexture(nil, "ARTWORK")
  check:SetSize(10, 10)
  check:SetPoint("CENTER")
  check:SetColorTexture(1, 0.82, 0, 1)
  check:Hide()
  cb.check = check
  cb:SetChecked(false)
  local function UpdateCheckState()
    if cb:GetChecked() then
      check:Show()
      cb:SetBackdropColor(0.15, 0.15, 0.18, 1)
    else
      check:Hide()
      cb:SetBackdropColor(0.08, 0.08, 0.10, 1)
    end
  end
  cb:SetScript("OnClick", function()
    UpdateCheckState()
    if cb.customOnClick then cb.customOnClick(cb) end
  end)
  local origSetChecked = cb.SetChecked
  cb.SetChecked = function(self, checked)
    origSetChecked(self, checked)
    UpdateCheckState()
  end
  cb:SetScript("OnEnter", function()
    if not cb:GetChecked() then
      cb:SetBackdropColor(0.12, 0.12, 0.15, 1)
    end
    cb:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
  end)
  cb:SetScript("OnLeave", function()
    if not cb:GetChecked() then
      cb:SetBackdropColor(0.08, 0.08, 0.10, 1)
    end
    cb:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  end)
  local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  l:SetPoint("LEFT", cb, "RIGHT", 8, 0)
  l:SetText(txt)
  l:SetTextColor(0.9, 0.9, 0.9)
  cb.label = l
  cb.SetEnabled = function(self, enabled)
    if enabled then
      self:Enable()
      l:SetTextColor(0.9, 0.9, 0.9)
      self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    else
      self:Disable()
      l:SetTextColor(0.4, 0.4, 0.4)
      self:SetBackdropBorderColor(0.2, 0.2, 0.22, 1)
      self:SetBackdropColor(0.05, 0.05, 0.06, 1)
    end
  end
  return cb, l
end

local function HideActiveDropdownList()
  if _activeDropdownList and _activeDropdownList.Hide then
    _activeDropdownList:Hide()
  end
  _activeDropdownList = nil
  if _dropdownClickCatcher and _dropdownClickCatcher.Hide then
    _dropdownClickCatcher:Hide()
  end
end

local function EnsureDropdownClickCatcher()
  if _dropdownClickCatcher then return end
  local catcher = CreateFrame("Button", nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:EnableMouse(true)
  catcher:RegisterForClicks("AnyDown")
  catcher:SetScript("OnClick", function()
    HideActiveDropdownList()
  end)
  catcher:Hide()
  _dropdownClickCatcher = catcher
end

local function StyledDropdown(p, labelTxt, x, y, w)
  local lbl = nil
  local dd = CreateFrame("Frame", nil, p, "BackdropTemplate")
  dd._ccmControlType = "dropdown"
  dd:SetSize(w, 24)
  if labelTxt then
    lbl = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    lbl:SetText(labelTxt)
    lbl:SetTextColor(0.9, 0.9, 0.9)
    dd:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -4)
  else
    dd:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
  end
  dd:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  dd:SetBackdropColor(0.12, 0.12, 0.14, 1)
  dd:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
  local txt = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  txt:SetPoint("LEFT", dd, "LEFT", 8, 0)
  txt:SetPoint("RIGHT", dd, "RIGHT", -20, 0)
  txt:SetJustifyH("LEFT")
  txt:SetTextColor(0.9, 0.9, 0.9)
  dd.text = txt
  local arrow = dd:CreateTexture(nil, "ARTWORK")
  arrow:SetSize(10, 10)
  arrow:SetPoint("RIGHT", dd, "RIGHT", -8, 0)
  arrow:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down")
  arrow:SetVertexColor(0.6, 0.6, 0.6)
  local list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  list:SetWidth(w)
  list:SetFrameStrata("TOOLTIP")
  list:SetFrameLevel(math.max((dd:GetFrameLevel() or 1) + 200, 2000))
  list._ccmBackdropReady = false
  list:Hide()
  list:SetScript("OnHide", function()
    if _activeDropdownList == list then
      _activeDropdownList = nil
      if _dropdownClickCatcher then _dropdownClickCatcher:Hide() end
    end
  end)
  dd.list = list
  dd.label = lbl
  dd.options = {}
  dd.value = nil
  dd.keepOpenOnSelect = true
  dd._scrollOffset = 0
  dd._maxVisibleOptions = 12
  dd._buttons = {}
  dd._moreIndicator = nil
  dd._effectiveWidth = w
  list:EnableMouseWheel(true)
  local RenderDropdownOptions
  local function ScrollDropdownBy(delta)
    local total = #(dd.options or {})
    local maxVisible = dd._maxVisibleOptions or 12
    local maxOffset = math.max(0, total - maxVisible)
    local curOffset = dd._scrollOffset or 0
    local nextOffset = curOffset - (delta or 0)
    if nextOffset < 0 then nextOffset = 0 end
    if nextOffset > maxOffset then nextOffset = maxOffset end
    if nextOffset ~= curOffset then
      dd._scrollOffset = nextOffset
      RenderDropdownOptions()
    end
  end
  RenderDropdownOptions = function()
    local opts = dd.options or {}
    local total = #opts
    local maxVisible = dd._maxVisibleOptions or 12
    local offset = dd._scrollOffset or 0
    local maxOffset = math.max(0, total - maxVisible)
    if offset > maxOffset then
      offset = maxOffset
      dd._scrollOffset = offset
    end
    if offset < 0 then
      offset = 0
      dd._scrollOffset = 0
    end
    local hasMoreBelow = offset < maxOffset
    local optionSlots = maxVisible
    if hasMoreBelow and optionSlots > 0 then
      optionSlots = optionSlots - 1
    end
    local visibleCount = math.min(optionSlots, total - offset)
    if visibleCount < 0 then visibleCount = 0 end
    local listW = dd._effectiveWidth or w
    local buttonWidth = listW - 2
    list:SetWidth(listW)
    for i = 1, maxVisible do
      local btn = dd._buttons[i]
      if not btn then
        btn = CreateFrame("Button", nil, list, "BackdropTemplate")
        btn:SetSize(buttonWidth, 22)
        btn:SetPoint("TOPLEFT", list, "TOPLEFT", 1, -((i - 1) * 22) - 1)
        btn:SetFrameStrata(list:GetFrameStrata())
        btn:SetFrameLevel(list:GetFrameLevel() + 1)
        btn:EnableMouseWheel(true)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        btn:SetScript("OnMouseWheel", function(_, delta)
          ScrollDropdownBy(delta)
        end)
        dd._buttons[i] = btn
      else
        btn:SetWidth(buttonWidth)
      end
      local optIndex = offset + i
      local opt = (i <= visibleCount) and opts[optIndex] or nil
      if opt then
        btn.optValue = opt.value
        btn.text:SetText(opt.text)
        if opt.disabled then
          btn.text:SetTextColor(0.4, 0.4, 0.4)
          btn:SetScript("OnEnter", nil)
          btn:SetScript("OnLeave", nil)
          btn:SetScript("OnClick", function() end)
        else
          btn.text:SetTextColor(0.9, 0.9, 0.9)
          btn:SetScript("OnEnter", function(self)
            self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            self:SetBackdropColor(0.25, 0.25, 0.3, 1)
          end)
          btn:SetScript("OnLeave", function(self)
            self:SetBackdrop(nil)
          end)
          btn:SetScript("OnClick", function()
            dd.value = opt.value
            txt:SetText(opt.text)
            if not dd.keepOpenOnSelect then list:Hide() end
            if dd.onSelect then dd.onSelect(opt.value) end
          end)
        end
        if dd.onButtonRendered then dd.onButtonRendered(btn, opt, i) end
        btn:Show()
      else
        if dd.onButtonRendered then dd.onButtonRendered(btn, nil, i) end
        btn:Hide()
      end
    end
    if not dd._moreIndicator then
      local hint = CreateFrame("Button", nil, list, "BackdropTemplate")
      hint:SetSize(buttonWidth, 22)
      hint:SetFrameStrata(list:GetFrameStrata())
      hint:SetFrameLevel(list:GetFrameLevel() + 1)
      hint:EnableMouseWheel(true)
      hint.tex = hint:CreateTexture(nil, "ARTWORK")
      hint.tex:SetSize(12, 12)
      hint.tex:SetPoint("CENTER", hint, "CENTER", 0, 0)
      hint.tex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down.tga")
      hint.tex:SetVertexColor(0.95, 0.95, 0.95, 0.95)
      hint:SetScript("OnEnter", function(self)
        self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        self:SetBackdropColor(0.22, 0.22, 0.27, 0.9)
        if self.tex then self.tex:SetVertexColor(1, 0.82, 0, 1) end
      end)
      hint:SetScript("OnLeave", function(self)
        self:SetBackdrop(nil)
        if self.tex then self.tex:SetVertexColor(0.95, 0.95, 0.95, 0.95) end
      end)
      hint:SetScript("OnClick", function()
        local nextOffset = (dd._scrollOffset or 0) + 1
        local maxOff = math.max(0, #(dd.options or {}) - (dd._maxVisibleOptions or 12))
        if nextOffset > maxOff then nextOffset = maxOff end
        if nextOffset ~= dd._scrollOffset then
          dd._scrollOffset = nextOffset
          RenderDropdownOptions()
        end
      end)
      hint:SetScript("OnMouseWheel", function(_, delta)
        ScrollDropdownBy(delta)
      end)
      dd._moreIndicator = hint
    end
    if dd._moreIndicator then dd._moreIndicator:SetWidth(buttonWidth) end
    local listRows = visibleCount
    if hasMoreBelow and dd._moreIndicator then
      dd._moreIndicator:ClearAllPoints()
      dd._moreIndicator:SetPoint("TOPLEFT", list, "TOPLEFT", 1, -((visibleCount) * 22) - 1)
      dd._moreIndicator:Show()
      listRows = listRows + 1
    elseif dd._moreIndicator then
      dd._moreIndicator:Hide()
    end
    list:SetHeight((listRows * 22) + 2)
  end
  dd.RenderOptions = RenderDropdownOptions
  list:SetScript("OnMouseWheel", function(_, delta)
    ScrollDropdownBy(delta)
  end)
  function dd:SetOptions(opts)
    dd.options = opts or {}
    dd._scrollOffset = 0
    local maxTextW = 0
    local oldText = txt:GetText()
    for _, opt in ipairs(dd.options) do
      txt:SetText(opt.text)
      local tw = txt:GetStringWidth()
      if tw > maxTextW then maxTextW = tw end
    end
    txt:SetText(oldText or "")
    local neededW = math.max(w, maxTextW + 30)
    dd._effectiveWidth = neededW
    RenderDropdownOptions()
    if dd.value ~= nil then
      dd:SetValue(dd.value)
    end
  end
  function dd:SetValue(val)
    dd.value = val
    for _, opt in ipairs(dd.options) do
      if opt.value == val then txt:SetText(opt.text); return end
    end
    txt:SetText(val or "")
  end
  function dd:SetEnabled(enabled)
    if enabled then
      dd:EnableMouse(true)
      dd:SetAlpha(1)
      if lbl then lbl:SetTextColor(0.9, 0.9, 0.9) end
    else
      dd:EnableMouse(false)
      dd:SetAlpha(0.5)
      if lbl then lbl:SetTextColor(0.4, 0.4, 0.4) end
    end
  end
  dd:SetScript("OnMouseDown", function()
    if list:IsShown() then
      list:Hide()
    else
      if _activeDropdownList and _activeDropdownList ~= list then
        _activeDropdownList:Hide()
      end
      if dd.refreshOptions then
        pcall(dd.refreshOptions, dd)
      end
      dd._scrollOffset = 0
      RenderDropdownOptions()
      if not list._ccmBackdropReady then
        list._ccmBackdropReady = true
        list:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        list:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
        list:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
      end
      list:ClearAllPoints()
      list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
      list:SetFrameStrata("TOOLTIP")
      list:SetFrameLevel(math.max((dd:GetFrameLevel() or 1) + 200, 2000))
      list:Show()
      _activeDropdownList = list
      EnsureDropdownClickCatcher()
      if _dropdownClickCatcher then
        _dropdownClickCatcher:SetFrameStrata(list:GetFrameStrata())
        _dropdownClickCatcher:SetFrameLevel(math.max((list:GetFrameLevel() or 2) - 1, 1))
        _dropdownClickCatcher:Show()
      end
    end
  end)
  dd:SetScript("OnEnter", function() dd:SetBackdropColor(0.18, 0.18, 0.22, 1) end)
  dd:SetScript("OnLeave", function() dd:SetBackdropColor(0.12, 0.12, 0.14, 1) end)
  return dd, lbl
end

local function FitConfigToScreen(frame)
  if not frame or not UIParent then return end
  if frame._ccmFitting then return end
  frame._ccmFitting = true
  local uiW = UIParent:GetWidth() or 0
  local uiH = UIParent:GetHeight() or 0
  local frameW = frame:GetWidth() or 0
  local frameH = frame:GetHeight() or 0
  if uiW <= 0 or uiH <= 0 or frameW <= 0 or frameH <= 0 then
    frame._ccmFitting = false
    return
  end
  local margin = 40
  local maxW = math.max(200, uiW - margin)
  local maxH = math.max(200, uiH - margin)
  local scale = 1
  if frameW > maxW or frameH > maxH then
    scale = math.min(maxW / frameW, maxH / frameH)
    if scale < 0.60 then scale = 0.60 end
  end
  frame:SetScale(scale)
  local compactFonts = scale < 0.88
  if frame._ccmCompactFonts ~= compactFonts then
    frame._ccmCompactFonts = compactFonts
    if addonTable.ApplyConfigCompactFonts then
      addonTable.ApplyConfigCompactFonts(frame, compactFonts)
    end
  end
  frame._ccmFitting = false
end

local function ApplyConfigCompactFonts(frame, compact)
  if not frame then return end
  local buttonFont = compact and "GameFontNormalSmall" or "GameFontHighlight"
  local labelFont = compact and "GameFontNormalSmall" or "GameFontNormal"
  local valueFont = compact and "GameFontHighlightSmall" or "GameFontHighlight"
  local function Walk(node)
    if not node then return end
    local t = node._ccmControlType
    if t == "button" then
      if node.text and node.text.SetFontObject then
        node.text:SetFontObject(buttonFont)
      end
    elseif t == "sidebarbtn" then
      if node.text and node.text.SetFontObject then
        node.text:SetFontObject(compact and "GameFontNormalSmall" or "GameFontNormal")
      end
      if node.arrow and node.arrow.SetFont then
        node.arrow:SetFont("Fonts\\FRIZQT__.TTF", compact and 9 or 10)
      end
    elseif t == "checkbox" then
      if node.label and node.label.SetFontObject then
        node.label:SetFontObject(labelFont)
      end
    elseif t == "slider" then
      if node.label and node.label.SetFontObject then node.label:SetFontObject(labelFont) end
      if node.Low and node.Low.SetFontObject then node.Low:SetFontObject("GameFontNormalSmall") end
      if node.High and node.High.SetFontObject then node.High:SetFontObject("GameFontNormalSmall") end
      if node.valueText and node.valueText.SetFontObject then node.valueText:SetFontObject(valueFont) end
    elseif t == "dropdown" then
      if node.text and node.text.SetFontObject then node.text:SetFontObject(labelFont) end
      if node.label and node.label.SetFontObject then node.label:SetFontObject(labelFont) end
      if node._buttons then
        for i = 1, #node._buttons do
          local b = node._buttons[i]
          if b and b.text and b.text.SetFontObject then
            b.text:SetFontObject(labelFont)
          end
        end
      end
    end
    if node.GetChildren then
      local children = {node:GetChildren()}
      for i = 1, #children do
        Walk(children[i])
      end
    end
  end
  Walk(frame)
end

local function SetStyledSliderShown(slider, shown)
  if not slider then return end
  slider:SetShown(shown)
  if slider.label then slider.label:SetShown(shown) end
  if slider.valueTextBg then slider.valueTextBg:SetShown(shown) end
  if slider.upBtn then slider.upBtn:SetShown(shown) end
  if slider.downBtn then slider.downBtn:SetShown(shown) end
end

local function SetStyledCheckboxShown(cb, shown)
  if not cb then return end
  cb:SetShown(shown)
  if cb.Text then cb.Text:SetShown(shown) end
  if cb.label then cb.label:SetShown(shown) end
end

local function AttachCheckboxTooltip(cb, text, opts)
  if not cb then return end
  opts = opts or {}
  cb:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, opts.anchor or "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(text, 1, 1, 1, true)
    if opts.minWidth then
      GameTooltip:SetMinimumWidth(opts.minWidth)
    end
    GameTooltip:Show()
  end)
  cb:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
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
    local cpWidget = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker
    if cpWidget and cpWidget.GetColorAlphaTexture then
      local alphaTex = cpWidget:GetColorAlphaTexture()
      if alphaTex then
        alphaTex:SetTexCoord(0, 1, 1, 0)
        hooksecurefunc(alphaTex, "SetTexCoord", function(self, a1, a2, a3, a4)
          if a4 and a3 < a4 then self:SetTexCoord(a1, a2, a4, a3) end
        end)
      end
    end
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
    local ok = (ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton) or _G.ColorPickerOkayButton
    local cancel = (ColorPickerFrame.Footer and ColorPickerFrame.Footer.CancelButton) or _G.ColorPickerCancelButton
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
  if params.opacity == nil then
    params.opacity = 1
  end
  ColorPickerFrame:SetupColorPickerAndShow(params)
end

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

local SPELL_GLOW_TYPE_OPTIONS = {
  { text = "Off", value = "off" },
  { text = "Blizzard", value = "blizzard" },
  { text = "Pixel", value = "pixel" },
  { text = "Auto Cast", value = "autocast" },
  { text = "Proc", value = "proc" },
}

local function CreateSpellRow(parent, idx, entryID, isEnabled, onToggle, onDelete, onMoveUp, onMoveDown, onReorder, isGlobalGlowEnabled, spellGlowType, onGlowTypeSelect, isChargeSpell, isHideRevealBlocked, hasRealCooldown, useCustomHideReveal, hideRevealThreshold, onHideRevealChange, isPureBuffDisabled, isPureBuffEntry)
  local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
  local rowY = -4 - (idx - 1) * 34
  row:SetHeight(32)
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
  local isNotSkilled = false
  if isItem then
    iconTexture = C_Item.GetItemIconByID(actualID)
    local itemName = C_Item.GetItemInfo(actualID)
    nameText = itemName or "Loading..."
    idText = " |cff888888(" .. actualID .. ")|r"
  else
    local resolvedID = actualID
    if addonTable.ResolveTrackedSpellID then
      local rid = addonTable.ResolveTrackedSpellID(actualID)
      if type(rid) == "number" and rid > 0 then
        resolvedID = rid
      end
    end
    local spellInfo = C_Spell.GetSpellInfo(resolvedID) or C_Spell.GetSpellInfo(actualID)
    iconTexture = spellInfo and spellInfo.iconID
    nameText = spellInfo and spellInfo.name or "Loading..."
    idText = " |cff888888(" .. actualID .. ")|r"
    if addonTable.IsSpellKnownByPlayer then
      isNotSkilled = not addonTable.IsSpellKnownByPlayer(resolvedID) and not addonTable.IsSpellKnownByPlayer(actualID)
    end
    if isNotSkilled then
      local knownBuffs = addonTable.GetCdmKnownBuffSpellIDs and addonTable.GetCdmKnownBuffSpellIDs()
      local pureBuffs = addonTable.GetCdmPureBuffSpellIDs and addonTable.GetCdmPureBuffSpellIDs()
      local isCdmBuff = (type(knownBuffs) == "table" and (knownBuffs[resolvedID] or knownBuffs[actualID])) or
                        (type(pureBuffs) == "table" and (pureBuffs[resolvedID] or pureBuffs[actualID]))
      if isCdmBuff then
        isNotSkilled = false
      end
    end
    if isNotSkilled then
      idText = idText .. " |cffff6666(not skilled)|r"
    end
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
  if isNotSkilled then
    name:SetTextColor(0.75, 0.75, 0.75)
  else
    name:SetTextColor(0.9, 0.9, 0.9)
  end
  if isNotSkilled then
    row:SetAlpha(0.55)
    cb:SetChecked(false)
    cb:Disable()
  end
  local delBtn = CreateDeleteButton(row, 20, 20)
  delBtn:SetPoint("RIGHT", row, "RIGHT", -1, 0)
  delBtn:SetScript("OnClick", function() onDelete(idx) end)
  local downBtn = CreateArrowButton(row, "down", 20, 20)
  downBtn:SetPoint("RIGHT", delBtn, "LEFT", -2, 0)
  downBtn:SetScript("OnClick", function() onMoveDown(idx) end)
  local upBtn = CreateArrowButton(row, "up", 20, 20)
  upBtn:SetPoint("RIGHT", downBtn, "LEFT", -2, 0)
  upBtn:SetScript("OnClick", function() onMoveUp(idx) end)
  local glowDD = StyledDropdown(row, nil, 0, 0, 105)
  glowDD:ClearAllPoints()
  glowDD:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
  glowDD:SetOptions(SPELL_GLOW_TYPE_OPTIONS)
  local initialGlowType = type(spellGlowType) == "string" and string.lower(spellGlowType) or "off"
  glowDD:SetValue(initialGlowType)
  glowDD.keepOpenOnSelect = false
  if onGlowTypeSelect then
    glowDD.onSelect = function(value)
      onGlowTypeSelect(idx, value)
    end
  end
  local hrFrame = CreateFrame("Frame", nil, row)
  hrFrame:SetSize(148, 20)
  local hrSlider = CreateFrame("Slider", nil, hrFrame, "BackdropTemplate")
  hrSlider:SetPoint("LEFT", hrFrame, "LEFT", 0, 0)
  hrSlider:SetSize(80, 16)
  hrSlider:SetOrientation("HORIZONTAL")
  hrSlider:SetMinMaxValues(0, 10)
  hrSlider:SetValueStep(0.5)
  hrSlider:SetObeyStepOnDrag(true)
  hrSlider:EnableMouse(true)
  hrSlider:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  hrSlider:SetBackdropColor(0.08, 0.08, 0.10, 1)
  hrSlider:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  local hrThumb = hrSlider:CreateTexture(nil, "ARTWORK")
  hrThumb:SetSize(10, 18)
  hrThumb:SetColorTexture(0.4, 0.4, 0.45, 1)
  hrSlider:SetThumbTexture(hrThumb)
  hrSlider:SetScript("OnEnter", function() hrThumb:SetColorTexture(0.5, 0.5, 0.55, 1) end)
  hrSlider:SetScript("OnLeave", function() hrThumb:SetColorTexture(0.4, 0.4, 0.45, 1) end)
  hrSlider:EnableMouseWheel(false)
  local hrBox = CreateFrame("EditBox", nil, hrFrame, "BackdropTemplate")
  hrBox:SetSize(40, 20)
  hrBox:SetPoint("LEFT", hrSlider, "RIGHT", 4, 0)
  hrBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  hrBox:SetBackdropColor(0.05, 0.05, 0.07, 1)
  hrBox:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
  hrBox:SetFontObject("GameFontHighlightSmall")
  hrBox:SetAutoFocus(false)
  hrBox:SetTextInsets(4, 4, 0, 0)
  hrBox:SetJustifyH("CENTER")
  local hrVal = (type(hideRevealThreshold) == "number" and hideRevealThreshold > 0) and hideRevealThreshold or 0
  local hrUpBtn = CreateFrame("Button", nil, hrFrame)
  hrUpBtn:SetSize(14, 10)
  hrUpBtn:SetPoint("BOTTOMLEFT", hrBox, "BOTTOMRIGHT", 2, 10)
  local hrUpTex = hrUpBtn:CreateTexture(nil, "ARTWORK")
  hrUpTex:SetAllPoints()
  hrUpTex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_up.tga")
  hrUpTex:SetVertexColor(0.7, 0.7, 0.7)
  hrUpBtn:SetScript("OnClick", function()
    local cur = hrSlider:GetValue()
    local newVal = cur + 0.5
    if newVal > 10 then newVal = 10 end
    hrSlider:SetValue(newVal)
  end)
  hrUpBtn:SetScript("OnEnter", function() hrUpTex:SetVertexColor(1, 0.82, 0, 1) end)
  hrUpBtn:SetScript("OnLeave", function() hrUpTex:SetVertexColor(0.7, 0.7, 0.7) end)
  local hrDownBtn = CreateFrame("Button", nil, hrFrame)
  hrDownBtn:SetSize(14, 10)
  hrDownBtn:SetPoint("TOPLEFT", hrBox, "TOPRIGHT", 2, -10)
  local hrDownTex = hrDownBtn:CreateTexture(nil, "ARTWORK")
  hrDownTex:SetAllPoints()
  hrDownTex:SetTexture("Interface\\AddOns\\CooldownCursorManager\\media\\arrow_down.tga")
  hrDownTex:SetVertexColor(0.7, 0.7, 0.7)
  hrDownBtn:SetScript("OnClick", function()
    local cur = hrSlider:GetValue()
    local newVal = cur - 0.5
    if newVal < 0 then newVal = 0 end
    hrSlider:SetValue(newVal)
  end)
  hrDownBtn:SetScript("OnEnter", function() hrDownTex:SetVertexColor(1, 0.82, 0, 1) end)
  hrDownBtn:SetScript("OnLeave", function() hrDownTex:SetVertexColor(0.7, 0.7, 0.7) end)
  local hrUpdating = false
  local function HRFormatText(val)
    return val > 0 and string.format("%.1f", val) or "0"
  end
  hrSlider:SetValue(hrVal)
  hrBox:SetText(HRFormatText(hrVal))
  hrSlider:SetScript("OnValueChanged", function(self, value)
    if hrUpdating then return end
    local rounded = math.floor(value * 2 + 0.5) / 2
    if math.abs(value - rounded) > 0.001 then
      hrUpdating = true
      self:SetValue(rounded)
      hrUpdating = false
      return
    end
    if not hrBox:HasFocus() then
      hrBox:SetText(HRFormatText(rounded))
    end
    if onHideRevealChange then onHideRevealChange(idx, rounded) end
  end)
  local function HRApplyEditBox()
    if hrUpdating then return end
    local val = tonumber(hrBox:GetText()) or 0
    if addonTable.NormalizeHideRevealThresholdValue then val = addonTable.NormalizeHideRevealThresholdValue(val) end
    hrBox:SetText(HRFormatText(val))
    hrBox:ClearFocus()
    hrUpdating = true
    hrSlider:SetValue(val)
    hrUpdating = false
    if onHideRevealChange then onHideRevealChange(idx, val) end
  end
  hrBox:SetScript("OnEnterPressed", HRApplyEditBox)
  hrBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
  hrBox:SetScript("OnEditFocusLost", HRApplyEditBox)
  local showGlow = isGlobalGlowEnabled == true and not isChargeSpell and not isHideRevealBlocked
  local showHR = useCustomHideReveal == true and hasRealCooldown == true and not isChargeSpell and not isHideRevealBlocked
  glowDD:SetShown(showGlow)
  glowDD:SetEnabled(showGlow)
  hrFrame:SetShown(showHR)
  glowDD:ClearAllPoints()
  glowDD:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
  if showHR then
    if showGlow then
      hrFrame:ClearAllPoints()
      hrFrame:SetPoint("RIGHT", glowDD, "LEFT", -4, 0)
      name:SetPoint("RIGHT", hrFrame, "LEFT", -6, 0)
    else
      hrFrame:ClearAllPoints()
      hrFrame:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
      name:SetPoint("RIGHT", hrFrame, "LEFT", -6, 0)
    end
  elseif showGlow then
    name:SetPoint("RIGHT", glowDD, "LEFT", -6, 0)
  else
    name:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
  end
  local function forwardDrop()
    local parentHandler = parent:GetScript("OnReceiveDrag")
    if parentHandler then parentHandler(parent) end
  end
  row:SetScript("OnReceiveDrag", forwardDrop)
  row:HookScript("OnMouseUp", forwardDrop)
  if isPureBuffDisabled then
    row:SetAlpha(0.45)
    cb:Disable()
    glowDD:SetEnabled(false)
    hrFrame:Hide()
    upBtn:Disable()
    downBtn:Disable()
    delBtn:Disable()
    name:ClearAllPoints()
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    local hint = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("LEFT", name, "RIGHT", 6, 0)
    hint:SetTextColor(1, 0.5, 0.1)
    hint:SetText("Enable Track Buffs")
  end
  if useCustomHideReveal == true and isHideRevealBlocked then
    local hrHint = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hrHint:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
    hrHint:SetJustifyH("RIGHT")
    hrHint:SetTextColor(1, 0.5, 0.1)
    hrHint:SetText("(no hide reveal & no glow for this spell)")
    name:ClearAllPoints()
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    name:SetPoint("RIGHT", hrHint, "LEFT", -6, 0)
  end
  if useCustomHideReveal == true and isPureBuffEntry and (not showHR) and (not isHideRevealBlocked) then
    local buffHint = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if showGlow then
      buffHint:SetPoint("RIGHT", glowDD, "LEFT", -6, 0)
    else
      buffHint:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
    end
    buffHint:SetJustifyH("RIGHT")
    buffHint:SetTextColor(1, 0.5, 0.1)
    buffHint:SetText("(no hide reveal for this buff)")
    name:ClearAllPoints()
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    name:SetPoint("RIGHT", buffHint, "LEFT", -6, 0)
  end
  return row
end

addonTable.CreateStyledButton = CreateStyledButton
addonTable.Section = Section
addonTable.Slider = Slider
addonTable.Checkbox = Checkbox
addonTable.HideActiveDropdownList = HideActiveDropdownList
addonTable.StyledDropdown = StyledDropdown
addonTable.FitConfigToScreen = FitConfigToScreen
addonTable.ApplyConfigCompactFonts = ApplyConfigCompactFonts
addonTable.SetStyledSliderShown = SetStyledSliderShown
addonTable.SetStyledCheckboxShown = SetStyledCheckboxShown
addonTable.AttachCheckboxTooltip = AttachCheckboxTooltip
addonTable.SetButtonHighlighted = SetButtonHighlighted
addonTable.ShowColorPicker = ShowColorPicker
addonTable.CreateArrowButton = CreateArrowButton
addonTable.CreateDeleteButton = CreateDeleteButton
addonTable.CreateSpellRow = CreateSpellRow
