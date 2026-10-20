--[[ PintaGroupFinder - Regions Module

    Region/language tags derived from a character's realm (see RealmDatabase.lua),
    used for the flags on listings and applicants and for the Regions filter.
]]

local addonName, PGF = ...

local REGION_TAG_COLORS = {
    US = "4da6ff", EN = "4da6ff", OCE = "33cc99",
    BR = "66cc33", PT = "66cc33", LA = "ff9933", ES = "ff6633",
    DE = "ffcc00", FR = "6699ff", IT = "33cc66", RU = "cc6666",
}

local REGION_TAG_FLAGS = {
    US = "us", EN = "gb", OCE = "au", BR = "br", PT = "pt", LA = "mx",
    ES = "es", DE = "de", FR = "fr", IT = "it", RU = "ru",
}
local FLAG_TEXTURE_FORMAT = "|TInterface\\AddOns\\" .. addonName .. "\\Textures\\Flags\\%s:10:16|t"

---Tags shown in the Regions filter, per game region.
local REGION_TAG_ORDER = {
    US = { "US", "OCE", "BR", "LA" },
    EU = { "EN", "DE", "FR", "ES", "IT", "RU", "PT" },
}

local GAME_REGION_KEYS = { [1] = "US", [3] = "EU" }

---@return string|nil regionKey "US" or "EU", nil for regions without realm data
local function GetGameRegionKey()
    return GAME_REGION_KEYS[GetCurrentRegion()]
end

---Region/language tag for a character's realm, e.g. "OCE", "BR", "DE".
---@param fullName string|nil "Name-Realm", or "Name" for characters on the player's realm
---@return string|nil tag
function PGF.GetRealmTag(fullName)
    if not fullName or (issecretvalue and issecretvalue(fullName)) then return nil end

    local regionKey = GetGameRegionKey()
    local tags = regionKey and PGF.REALM_TAGS and PGF.REALM_TAGS[regionKey]
    if not tags then return nil end

    local realm = fullName:match("^[^-]+%-(.+)$") or GetNormalizedRealmName()
    if not realm then return nil end

    return tags[realm:lower():gsub("[%s%-]", "")]
end

---Flag icon plus colored tag text, e.g. "<flag> OCE".
---@param tag string
---@param flagOnly boolean? Return just the flag when one exists
---@return string
function PGF.FormatRegionTag(tag, flagOnly)
    local flag = REGION_TAG_FLAGS[tag]
    local text = string.format("|cff%s%s|r", REGION_TAG_COLORS[tag] or "aaaaaa", tag)
    if flag and flagOnly then
        return FLAG_TEXTURE_FORMAT:format(flag)
    end
    return flag and (FLAG_TEXTURE_FORMAT:format(flag) .. " " .. text) or text
end

---Tags available in the Regions filter for the player's game region.
---@return string[]
function PGF.GetRegionFilterTags()
    return REGION_TAG_ORDER[GetGameRegionKey()] or {}
end
