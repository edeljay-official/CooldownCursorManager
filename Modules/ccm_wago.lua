local addonName, addonTable = ...

local api = {}

local function DeepCopy(orig)
  if type(orig) ~= "table" then return orig end
  local copy = {}
  for k, v in pairs(orig) do
    copy[k] = DeepCopy(v)
  end
  return copy
end

function api:ExportProfile(profileKey)
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then return nil end
  local profileData = CooldownCursorManagerDB.profiles[profileKey]
  if not profileData then return nil end
  local dataCopy = DeepCopy(profileData)
  local ok, serialized = pcall(C_EncodingUtil.SerializeCBOR, dataCopy)
  if not ok or not serialized then return nil end
  local ok2, compressed = pcall(C_EncodingUtil.CompressString, serialized)
  if not ok2 or not compressed then return nil end
  local ok3, encoded = pcall(C_EncodingUtil.EncodeBase64, compressed)
  if not ok3 or not encoded then return nil end
  return encoded
end

function api:ImportProfile(profileString, profileKey)
  if not profileString or profileString == "" then return end
  if not profileKey or profileKey == "" then profileKey = "Imported" end
  if not CooldownCursorManagerDB then return end
  CooldownCursorManagerDB.profiles = CooldownCursorManagerDB.profiles or {}
  local ok1, decoded = pcall(C_EncodingUtil.DecodeBase64, profileString)
  if not ok1 or not decoded then return end
  local ok2, decompressed = pcall(C_EncodingUtil.DecompressString, decoded)
  if not ok2 or not decompressed then return end
  local ok3, deserialized = pcall(C_EncodingUtil.DeserializeCBOR, decompressed)
  if not ok3 or type(deserialized) ~= "table" then return end
  CooldownCursorManagerDB.profiles[profileKey] = deserialized
  CooldownCursorManagerDB.currentProfile = profileKey
  if addonTable.SaveCurrentProfileForSpec then
    addonTable.SaveCurrentProfileForSpec()
  end
  if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
  if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
end

function api:DecodeProfileString(profileString)
  if not profileString or profileString == "" then return nil end
  local ok1, decoded = pcall(C_EncodingUtil.DecodeBase64, profileString)
  if not ok1 or not decoded then return nil end
  local ok2, decompressed = pcall(C_EncodingUtil.DecompressString, decoded)
  if not ok2 or not decompressed then return nil end
  local ok3, deserialized = pcall(C_EncodingUtil.DeserializeCBOR, decompressed)
  if not ok3 or type(deserialized) ~= "table" then return nil end
  return deserialized
end

function api:SetProfile(profileKey)
  if not CooldownCursorManagerDB or not CooldownCursorManagerDB.profiles then return end
  if not profileKey or not CooldownCursorManagerDB.profiles[profileKey] then return end
  CooldownCursorManagerDB.currentProfile = profileKey
  if addonTable.SaveCurrentProfileForSpec then
    addonTable.SaveCurrentProfileForSpec()
  end
  if addonTable.UpdateProfileList then addonTable.UpdateProfileList() end
  if addonTable.UpdateProfileDisplay then addonTable.UpdateProfileDisplay() end
end

function api:GetProfileKeys()
  local keys = {}
  if CooldownCursorManagerDB and CooldownCursorManagerDB.profiles then
    for key in pairs(CooldownCursorManagerDB.profiles) do
      keys[key] = true
    end
  end
  return keys
end

function api:GetCurrentProfileKey()
  if CooldownCursorManagerDB and CooldownCursorManagerDB.currentProfile then
    return CooldownCursorManagerDB.currentProfile
  end
  return "Default"
end

function api:OpenConfig()
  if InCombatLockdown() then return end
  if addonTable.ConfigFrame then
    addonTable.ConfigFrame:Show()
    if addonTable.SetGUIOpen then addonTable.SetGUIOpen(true) end
    if addonTable.RefreshConfigOnShow then addonTable.RefreshConfigOnShow() end
  end
end

function api:CloseConfig()
  if addonTable.ConfigFrame then
    addonTable.ConfigFrame:Hide()
    if addonTable.SetGUIOpen then addonTable.SetGUIOpen(false) end
  end
end

_G.CooldownCursorManagerAPI = api
