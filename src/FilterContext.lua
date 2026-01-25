--[[
    PintaGroupFinder - Filter Context Module
    
    Builds filterable properties for each search result.
]]

local addonName, PGF = ...

---@class FilterContext
---@field activityID number
---@field activityName string
---@field categoryID number
---@field difficulty string
---@field mythicplus boolean?
---@field mythic boolean?
---@field heroic boolean?
---@field normal boolean?
---@field challengeModeID number?
---@field dungeonID number?
---@field dungeonName string?
---@field tanks number
---@field healers number
---@field dps number
---@field members number
---@field maxMembers number
---@field tankNeeded number
---@field healerNeeded number
---@field dpsNeeded number
---@field mprating number
---@field age number
---@field ageSecs number
---@field leaderName string
---@field myRealm boolean
---@field friends number
---@field ilvl number
---@field hlvl number
---@field dungeonScore number
---@field isDelisted boolean
---@field autoAccept boolean
---@field warmode boolean
---@field hasSelf boolean
---@field appStatus string
---@field isApplied boolean
---@field playstyle number? 0=None, 1=Standard/Competitive, 2=Learning/Casual, 3=Hardcore, 4=Carry Offered?

---Build filter context for a search result.
---@param resultID number
---@param searchResultInfo LfgSearchResultData
---@param memberCounts table
---@return FilterContext context Filter context
function PGF.BuildFilterContext(resultID, searchResultInfo, memberCounts)
    local context = {}
    
    local activityID = searchResultInfo.activityIDs and searchResultInfo.activityIDs[1] or searchResultInfo.activityID
    local activityInfo = activityID and C_LFGList.GetActivityInfoTable(activityID) or nil
    
    if not activityInfo then
        return context
    end
    
    -- Currently used fields
    context.activityID = activityID
    context.categoryID = activityInfo.categoryID
    
    context.difficulty = "unknown"
    if activityInfo.isMythicPlusActivity then
        context.difficulty = "mythicplus"
        context.mythicplus = true
    elseif activityInfo.isMythicActivity then
        context.difficulty = "mythic"
    elseif activityInfo.isHeroicActivity then
        context.difficulty = "heroic"
    elseif activityInfo.isNormalActivity then
        context.difficulty = "normal"
    end
    
    context.tanks = memberCounts.TANK or 0
    context.healers = memberCounts.HEALER or 0
    
    context.mprating = searchResultInfo.leaderOverallDungeonScore or 0
    context.age = math.floor((searchResultInfo.age or 0) / 60)
    
    local _, appStatus = C_LFGList.GetApplicationInfo(resultID)
    context.appStatus = appStatus or "none"
    context.isApplied = appStatus and appStatus ~= "none" or false
    
    -- Fields for future filtering/sorting features (commented out for now)
    --[[
    context.activityName = activityInfo.fullName and activityInfo.fullName:lower() or ""
    context.mythic = activityInfo.isMythicActivity or false
    context.heroic = activityInfo.isHeroicActivity or false
    context.normal = activityInfo.isNormalActivity or false
    context.dps = (memberCounts.DAMAGER or 0) + (memberCounts.NOROLE or 0)
    context.members = searchResultInfo.numMembers or 0
    context.maxMembers = activityInfo.maxNumPlayers or 5
    
    context.challengeModeID = nil
    context.dungeonID = nil
    if context.mythicplus then
        context.challengeModeID = PGF.GetChallengeModeIDFromActivity(activityID)
        context.dungeonID = context.challengeModeID
        if context.challengeModeID then
            local dungeonInfo = PGF.GetDungeonInfo(context.challengeModeID)
            if dungeonInfo then
                context.dungeonName = dungeonInfo.name:lower()
            end
        end
    end
    
    context.tankNeeded = memberCounts.TANK_REMAINING or 0
    context.healerNeeded = memberCounts.HEALER_REMAINING or 0
    context.dpsNeeded = memberCounts.DAMAGER_REMAINING or 0
    context.ageSecs = searchResultInfo.age or 0
    
    context.leaderName = searchResultInfo.leaderName and searchResultInfo.leaderName:lower() or ""
    context.myRealm = searchResultInfo.leaderName and not searchResultInfo.leaderName:find("-") or false
    context.friends = (searchResultInfo.numBNetFriends or 0) + 
                  (searchResultInfo.numCharFriends or 0) + 
                  (searchResultInfo.numGuildMates or 0)
    
    context.ilvl = searchResultInfo.requiredItemLevel or 0
    context.hlvl = searchResultInfo.requiredHonorLevel or 0
    context.dungeonScore = searchResultInfo.requiredDungeonScore or 0
    
    context.isDelisted = searchResultInfo.isDelisted or false
    context.autoAccept = searchResultInfo.autoAccept or false
    context.warmode = searchResultInfo.isWarMode or false
    context.hasSelf = searchResultInfo.hasSelf or false
    
    -- Playstyle: 0=None, 1=Standard/Competitive, 2=Learning/Casual, 3=Hardcore, 4=Carry Offered?
    context.playstyle = searchResultInfo.playstyle or 0
    --]]
    
    return context
end
