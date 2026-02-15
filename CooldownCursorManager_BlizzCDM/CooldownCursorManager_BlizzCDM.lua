local _, CCM = ...
if type(CCM) ~= "table" then return end
CCM._companionModules = CCM._companionModules or {}
CCM._companionModules["blizzcdm"] = true

