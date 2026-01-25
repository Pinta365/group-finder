--[[
    PintaGroupFinder - Core Module
    
    Addon namespace and shared utilities.
]]

local addonName, PGF = ...

PGF.name = addonName
PGF.title = C_AddOns.GetAddOnMetadata(addonName, "Title")
PGF.version = C_AddOns.GetAddOnMetadata(addonName, "Version")

PGF.debug = false

---Print message to chat with addon prefix.
---@param ... any Message parts
function PGF.Print(...)
    print("|cff45D388[PGF]|r", ...)
end

---Print debug message if debug mode is enabled.
---@param ... any Message parts
function PGF.Debug(...)
    if PGF.debug then
        print("|cff888888[PGF Debug]|r", ...)
    end
end

---Get localized difficulty name.
---@param difficultyKey string Difficulty key ("normal", "heroic", "mythic", "mythicplus")
---@return string localizedName
function PGF.GetLocalizedDifficultyName(difficultyKey)
    -- Difficulty IDs: 1=Normal, 2=Heroic, 23=Mythic, 8=Mythic+ (Challenge Mode)
    local difficultyIDMap = {
        normal = 1,
        heroic = 2,
        mythic = 23,
        mythicplus = 8,
    }
    
    local difficultyID = difficultyIDMap[difficultyKey]
    if difficultyID then
        local name = GetDifficultyInfo(difficultyID)
        if name then
            return name
        end
    end
    
    -- Fallback to English if API fails
    local fallback = {
        normal = "Normal",
        heroic = "Heroic",
        mythic = "Mythic",
        mythicplus = "Mythic+",
    }
    return fallback[difficultyKey] or difficultyKey
end
