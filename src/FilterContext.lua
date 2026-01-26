--[[
    PintaGroupFinder - Filter Context Module
    
    Builds filterable properties for each search result.
]]

local addonName, PGF = ...

---@class FilterContext
--- Core fields (always populated)
---@field activityID number Activity ID for this listing
---@field categoryID number 2=Dungeons, 3=Raids
---@field difficulty string "normal"|"heroic"|"mythic"|"mythicplus"|"unknown"
---@field mythicplus boolean? True if M+ dungeon
---@field tanks number Number of tanks in group
---@field healers number Number of healers in group
---@field mprating number Leader's M+ score
---@field age number Listing age in minutes
---@field appStatus string Application status ("none", "applied", etc.)
---@field isApplied boolean True if you've applied to this group
---@field generalPlaystyle number Playstyle for raids: 1=Learning, 2=Relaxed, 3=Competitive, 4=Carry
---@field playstyle number Playstyle for dungeons (0 for raids)
--- Raid-specific fields
---@field defeatedBosses string[]? Array of defeated boss names (raids only)
---@field defeatedBossCount number? Number of bosses defeated (raids only)
---@field defeatedBossLookup table<string,boolean>? Lookup table for boss names (raids only)
--- Future fields
---@field activityName string?
---@field mythic boolean?
---@field heroic boolean?
---@field normal boolean?
---@field dps number?
---@field members number?
---@field maxMembers number?
---@field challengeModeID number?
---@field dungeonID number?
---@field dungeonName string?
---@field tankNeeded number?
---@field healerNeeded number?
---@field dpsNeeded number?
---@field ageSecs number?
---@field leaderName string?
---@field myRealm boolean?
---@field friends number?
---@field ilvl number?
---@field hlvl number?
---@field dungeonScore number?
---@field isDelisted boolean?
---@field autoAccept boolean?
---@field warmode boolean?
---@field hasSelf boolean?

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

    if activityInfo.categoryID == PGF.RAID_CATEGORY_ID then
        local difficultyID = activityInfo.difficultyID
        if difficultyID == 14 then
            context.difficulty = "normal"
        elseif difficultyID == 15 then
            context.difficulty = "heroic"
        elseif difficultyID == 16 then
            context.difficulty = "mythic"
        end
    elseif activityInfo.isMythicPlusActivity then
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
    context.dps = (memberCounts.DAMAGER or 0) + (memberCounts.NOROLE or 0)
    
    context.mprating = searchResultInfo.leaderOverallDungeonScore or 0
    context.age = math.floor((searchResultInfo.age or 0) / 60)
    
    context.generalPlaystyle = searchResultInfo.generalPlaystyle or 0
    context.playstyle = searchResultInfo.playstyle or 0
    
    local _, appStatus = C_LFGList.GetApplicationInfo(resultID)
    context.appStatus = appStatus or "none"
    context.isApplied = appStatus and appStatus ~= "none" or false
    
    -- Raid-specific fields
    if context.categoryID == PGF.RAID_CATEGORY_ID then
        local encounterInfo = C_LFGList.GetSearchResultEncounterInfo(resultID)
        context.defeatedBosses = encounterInfo or {}
        context.defeatedBossCount = encounterInfo and #encounterInfo or 0
        
        context.defeatedBossLookup = {}
        if encounterInfo then
            for _, bossName in ipairs(encounterInfo) do
                context.defeatedBossLookup[bossName:lower()] = true
                context.defeatedBossLookup[bossName] = true
            end
        end
    end
    
    -- Fields for future filtering/sorting features (commented out for now)
    --[[
    context.activityName = activityInfo.fullName and activityInfo.fullName:lower() or ""
    context.mythic = activityInfo.isMythicActivity or false
    context.heroic = activityInfo.isHeroicActivity or false
    context.normal = activityInfo.isNormalActivity or false
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
    
    --]]
    
    return context
end
