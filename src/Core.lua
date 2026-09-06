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

---Ensure db.filter exists, initializing it from defaults if absent.
---@param db table The account-wide saved variables table (PintaGroupFinderDB)
function PGF.EnsureFilter(db)
    if not db.filter then
        db.filter = CopyTable(PGF.defaults.filter)
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

-- Maps "CLASSFILE\1LocalizedSpecName" to a numeric specialization ID.
-- C_LFGList.GetSearchResultPlayerInfo only exposes a localized spec name (the returned
-- LfgSearchResultPlayerInfo has no spec ID), so any spec comparison has to go through this
-- table to behave the same on non-English clients.
local SPEC_CACHE_KEY_SEP = "\1"
local specNameToID = {}
local specNameToIDBuilt = false

---Build the localized spec name lookup. Runs once; stays unbuilt while the specialization
---API returns nothing so it can retry (data may be missing before PLAYER_LOGIN).
local function BuildSpecNameToIDCache()
    if specNameToIDBuilt then return end

    local GetSpecForClass = GetSpecializationInfoForClassID
        or (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoForClassID)
    if not GetSpecForClass then return end

    local entries = 0
    for classID = 1, 20 do
        local _, classFilename = GetClassInfo(classID)
        if classFilename then
            for specIndex = 1, 5 do
                for sex = 1, 3 do
                    local specID, specName = GetSpecForClass(classID, specIndex, sex)
                    if specID and specName and specName ~= "" then
                        specNameToID[classFilename .. SPEC_CACHE_KEY_SEP .. specName] = specID
                        entries = entries + 1
                    end
                end
            end
        end
    end

    if entries > 0 then
        specNameToIDBuilt = true
    end
end

---Resolve a localized specialization name to its numeric specialization ID.
---@param specName string? Localized spec name, e.g. from GetSearchResultPlayerInfo
---@param classFilename string? Locale-independent class token, e.g. "EVOKER"
---@return number? specID nil if the name could not be resolved
function PGF.GetSpecIDByNameAndClass(specName, classFilename)
    if not specName or specName == "" or not classFilename then
        return nil
    end
    BuildSpecNameToIDCache()
    return specNameToID[classFilename .. SPEC_CACHE_KEY_SEP .. specName]
end
