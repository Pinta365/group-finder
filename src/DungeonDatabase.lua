--[[
    PintaGroupFinder - Dungeon Database Module
    
    Maps challenge mode IDs to dungeon metadata and provides lookup functions.
]]

local addonName, PGF = ...

---@class DungeonInfo
---@field challengeModeID number
---@field name string
---@field shortName string
---@field timeLimit number
---@field texture number
---@field backgroundTexture number
---@field mapID number

---@class DungeonListEntry
---@field activityID number
---@field challengeModeID number
---@field groupID number
---@field name string
---@field shortName string

local challengeModeCache = {}
local activityToChallengeModeCache = {}

---Get challenge mode ID from activity ID.
---@param activityID number
---@return number? challengeModeID
function PGF.GetChallengeModeIDFromActivity(activityID)
    if not activityID then return nil end
    
    if activityToChallengeModeCache[activityID] then
        return activityToChallengeModeCache[activityID]
    end
    
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    if not activityInfo or not activityInfo.fullName then
        return nil
    end
    
    if not activityInfo.isMythicPlusActivity then
        activityToChallengeModeCache[activityID] = false
        return nil
    end
    
    local activityName = activityInfo.fullName:gsub("%s*%(.*%)%s*$", ""):lower()
    
    local cmIDs = C_ChallengeMode.GetMapTable()
    if not cmIDs then return nil end
    
    for _, cmID in ipairs(cmIDs) do
        local mapName = C_ChallengeMode.GetMapUIInfo(cmID)
        if mapName and activityName:find(mapName:lower(), 1, true) then
            activityToChallengeModeCache[activityID] = cmID
            return cmID
        end
    end
    
    activityToChallengeModeCache[activityID] = false
    return nil
end

---Get dungeon info from challenge mode ID.
---@param challengeModeID number
---@return DungeonInfo? dungeonInfo
function PGF.GetDungeonInfo(challengeModeID)
    if not challengeModeID then return nil end
    
    if challengeModeCache[challengeModeID] then
        return challengeModeCache[challengeModeID]
    end
    
    local name, id, timeLimit, texture, backgroundTexture, mapID = 
        C_ChallengeMode.GetMapUIInfo(challengeModeID)
    
    if not name then
        return nil
    end
    
    local info = {
        challengeModeID = challengeModeID,
        name = name,
        shortName = name,
        timeLimit = timeLimit,
        texture = texture,
        backgroundTexture = backgroundTexture,
        mapID = mapID,
    }
    
    challengeModeCache[challengeModeID] = info
    return info
end

