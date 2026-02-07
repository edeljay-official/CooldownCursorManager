--------------------------------------------------------------------------------
-- CooldownCursorManager - ccm_globals.lua
-- Addon namespace, constants, and performance-optimized local references
-- Author: Edeljay
--------------------------------------------------------------------------------
local addonName, CCM = ...
CCM.math_floor = math.floor
CCM.math_ceil = math.ceil
CCM.math_min = math.min
CCM.math_max = math.max
CCM.math_abs = math.abs
CCM.string_format = string.format
CCM.string_match = string.match
CCM.string_gsub = string.gsub
CCM.string_sub = string.sub
CCM.string_lower = string.lower
CCM.string_upper = string.upper
CCM.table_insert = table.insert
CCM.table_remove = table.remove
CCM.table_sort = table.sort
CCM.table_wipe = table.wipe or wipe
CCM.GetTime = GetTime
CCM.CreateFrame = CreateFrame
CCM.UIParent = UIParent
CCM.InCombatLockdown = InCombatLockdown
CCM.UnitExists = UnitExists
CCM.UnitAffectingCombat = UnitAffectingCombat
CCM.UnitClass = UnitClass
CCM.UnitName = UnitName
CCM.GetSpellInfo = C_Spell.GetSpellInfo
CCM.GetSpellCooldown = C_Spell.GetSpellCooldown
CCM.GetSpellTexture = C_Spell.GetSpellTexture
CCM.IsSpellKnown = IsSpellKnown
CCM.GetSpecialization = GetSpecialization
CCM.GetSpecializationInfo = GetSpecializationInfo
CCM.C_UnitAuras = C_UnitAuras
CCM.C_Timer = C_Timer
CCM.After = C_Timer.After
CCM.NewTicker = C_Timer.NewTicker
CCM.LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
CCM.ADDON_NAME = addonName
CCM.ADDON_TITLE = C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName
CCM.ADDON_VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0"
CCM.ADDON_AUTHOR = C_AddOns.GetAddOnMetadata(addonName, "Author") or "Edeljay"
CCM.MEDIA_PATH = "Interface\\AddOns\\" .. addonName .. "\\media\\"
CCM.TEXTURES_PATH = CCM.MEDIA_PATH .. "textures\\"
CCM.BACKDROP_SOLID = {
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
CCM.BACKDROP_EDGE_ONLY = {
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  edgeSize = 1,
}
CCM.State = {
  inCombat = false,
  playerClass = nil,
  playerSpec = nil,
  initialized = false,
}
CCM.Modules = {}
function CCM:RegisterModule(name, module)
  if self.Modules[name] then
    self:Print("Module already registered: " .. name)
    return
  end
  self.Modules[name] = module
end
function CCM:GetModule(name)
  return self.Modules[name]
end
function CCM:Print(msg)
  print("|cFF00CCFFCooldownCursorManager|r: " .. tostring(msg))
end
function CCM:Debug(msg)
  if CCM.db and CCM.db.debug then
    print("|cFFFFCC00[CCM Debug]|r: " .. tostring(msg))
  end
end
function CCM:GetProfile()
  if not CCM.db then return nil end
  local profileName = CCM.db.currentProfile or "Default"
  return CCM.db.profiles and CCM.db.profiles[profileName]
end
function CCM:GetPlayerClass()
  if not self.State.playerClass then
    local _, class = UnitClass("player")
    self.State.playerClass = class
  end
  return self.State.playerClass
end
function CCM:GetPlayerSpec()
  local spec = GetSpecialization()
  if spec then
    local specID = GetSpecializationInfo(spec)
    self.State.playerSpec = specID
  end
  return self.State.playerSpec
end
function CCM:IsInCombat()
  return self.State.inCombat or InCombatLockdown()
end
function CCM:RegisterMedia()
  if not self.LSM then return end
  local fontPath = self.MEDIA_PATH .. "Fonts\\"
  local texPath = self.TEXTURES_PATH
  self.LSM:Register("font", "Expressway", fontPath .. "Expressway.ttf")
  self.LSM:Register("font", "Avante", fontPath .. "Avante.ttf")
  self.LSM:Register("font", "AvantGarde Book", fontPath .. "AvantGarde\\Book.ttf")
  self.LSM:Register("font", "AvantGarde BookOblique", fontPath .. "AvantGarde\\BookOblique.ttf")
  self.LSM:Register("font", "AvantGarde Demi", fontPath .. "AvantGarde\\Demi.ttf")
  self.LSM:Register("font", "AvantGarde Regular", fontPath .. "AvantGarde\\Regular.ttf")
  self.LSM:Register("statusbar", "Smooth", texPath .. "normTex.tga")
  self.LSM:Register("statusbar", "Gloss", texPath .. "Gloss.tga")
  self.LSM:Register("statusbar", "Melli", texPath .. "Melli.tga")
  self.LSM:Register("statusbar", "MelliDark", texPath .. "MelliDark.tga")
  self.LSM:Register("statusbar", "BetterBlizzard", texPath .. "BetterBlizzard.blp")
  self.LSM:Register("statusbar", "Skyline", texPath .. "Skyline.tga")
  self.LSM:Register("statusbar", "Dragonflight", texPath .. "Dragonflight.tga")
end
function CCM:GetPixelPerfectScale()
  local _, screenHeight = GetPhysicalScreenSize()
  return 768 / screenHeight
end
function CCM:GetEffectiveScale()
  return UIParent:GetEffectiveScale()
end
function CCM:HexToRGB(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16) / 255,
         tonumber(hex:sub(3, 4), 16) / 255,
         tonumber(hex:sub(5, 6), 16) / 255
end
function CCM:RGBToHex(r, g, b)
  return string.format("%02X%02X%02X", r * 255, g * 255, b * 255)
end
function CCM:GetClassColor(class)
  local color = RAID_CLASS_COLORS[class]
  if color then
    return color.r, color.g, color.b
  end
  return 1, 1, 1
end
function CCM:CreateBackdrop(frame, bgColor, borderColor, borderSize)
  if not frame.SetBackdrop then
    Mixin(frame, BackdropTemplateMixin)
  end
  borderSize = borderSize or 1
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = borderSize,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  })
  if bgColor then
    frame:SetBackdropColor(bgColor.r or bgColor[1] or 0,
                           bgColor.g or bgColor[2] or 0,
                           bgColor.b or bgColor[3] or 0,
                           bgColor.a or bgColor[4] or 1)
  end
  if borderColor then
    frame:SetBackdropBorderColor(borderColor.r or borderColor[1] or 0,
                                  borderColor.g or borderColor[2] or 0,
                                  borderColor.b or borderColor[3] or 0,
                                  borderColor.a or borderColor[4] or 1)
  end
end
_G.CCM = CCM
