--[[
    PintaGroupFinder - Filter Core Module
    
    Main filtering logic and hooks for search results.
]]

local addonName, PGF = ...

local filterInProgress = false

---Get fixed role counts from party members only (party1..party4). Player is excluded.
---@return number fixedTanks
---@return number fixedHealers
---@return number fixedDps
local function GetFixedPartyRoleCounts()
    local fixedTanks, fixedHealers, fixedDps = 0, 0, 0
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local role = UnitGroupRolesAssigned(unit)
            if role == "TANK" then
                fixedTanks = fixedTanks + 1
            elseif role == "HEALER" then
                fixedHealers = fixedHealers + 1
            elseif role == "DAMAGER" then
                fixedDps = fixedDps + 1
            end
        end
    end
    return fixedTanks, fixedHealers, fixedDps
end

---Get all possible "party role vectors" for compatibility. Only the player can have multiple
---roles; party members have one role each. Each vector is { tanks, healers, dps } representing
---one way the full party could fill roles (player picks one of their selected roles per vector).
---@return table[] vectors Array of { tanks, healers, dps } (1–3 elements)
local function GetPossiblePartyRoleVectors()
    local fixedTanks, fixedHealers, fixedDps = GetFixedPartyRoleCounts()
    local _, wantTank, wantHealer, wantDps = GetLFGRoles()
    local vectors = {}
    if wantTank then
        table.insert(vectors, { fixedTanks + 1, fixedHealers, fixedDps })
    end
    if wantHealer then
        table.insert(vectors, { fixedTanks, fixedHealers + 1, fixedDps })
    end
    if wantDps then
        table.insert(vectors, { fixedTanks, fixedHealers, fixedDps + 1 })
    end
    return vectors
end

---Compare a value using an operator.
---@param actual number The actual value
---@param operator string The comparison operator (">=", "<=", "=")
---@param expected number The expected value
---@return boolean matches True if the comparison passes
local function CompareValue(actual, operator, expected)
    if operator == ">=" then
        return actual >= expected
    elseif operator == "<=" then
        return actual <= expected
    elseif operator == "=" then
        return actual == expected
    end
    return true
end

---Check if an activity belongs to any of the selected activity groups.
---@param activityID number The activity ID to check
---@param categoryID number The category ID
---@param selectedGroupIDs table Array of selected group IDs
---@return boolean matches True if activity matches one of the selected groups
local function ActivityMatchesSelectedGroups(activityID, categoryID, selectedGroupIDs)
    if not activityID then
        return false
    end
    
    if not selectedGroupIDs or #selectedGroupIDs == 0 then
        return false
    end

    for _, groupID in ipairs(selectedGroupIDs) do
        local activities = C_LFGList.GetAvailableActivities(categoryID, groupID)
        if activities then
            for _, actID in ipairs(activities) do
                if actID == activityID then
                    return true
                end
            end
        end
    end
    
    return false
end

---Check if result passes filter criteria.
---@param resultID number
---@param context FilterContext Filter context
---@return boolean passes
local function PassesFilter(resultID, context)
    local db = PintaGroupFinderDB
    local filter = db.filter or {}
    local advancedFilter = C_LFGList.GetAdvancedFilter()
    
    -- Activities, difficulty, role presence, playstyle, and minimum rating filtering
    -- are handled automatically by Blizzard's advanced filter when we set the corresponding properties
    if not advancedFilter then
        local difficulty = filter.difficulty or {}
        if not difficulty[context.difficulty] then
            return false
        end
        
        local hasRole = filter.hasRole or {}
        if hasRole.tank and context.tanks == 0 then
            return false
        end
        if hasRole.healer and context.healers == 0 then
            return false
        end
        
        if filter.minRating and filter.minRating > 0 then
            if context.mythicplus and context.mprating < filter.minRating then
                return false
            end
        end
    end
    
    if context.categoryID == PGF.DUNGEON_CATEGORY_ID then
        local dungeonActivities = filter.dungeonActivities
        if dungeonActivities ~= nil then
            local selectedGroupIDs = {}
            for k, v in pairs(dungeonActivities) do
                if v and type(k) == "number" and k > 0 then
                    table.insert(selectedGroupIDs, k)
                end
            end
            if #selectedGroupIDs == 0 then
                return false
            end
            if not ActivityMatchesSelectedGroups(context.activityID, context.categoryID, selectedGroupIDs) then
                return false
            end
        end
        
        if filter.hideIncompatibleGroups then
            local vectors = GetPossiblePartyRoleVectors()
            if #vectors > 0 then
                local tankNeeded = context.tankNeeded or 0
                local healerNeeded = context.healerNeeded or 0
                local dpsNeeded = context.dpsNeeded or 0
                local anyFits = false
                for _, v in ipairs(vectors) do
                    if tankNeeded >= v[1] and healerNeeded >= v[2] and dpsNeeded >= v[3] then
                        anyFits = true
                        break
                    end
                end
                if not anyFits then
                    return false
                end
            end
        end
    end
    
    -- Raid-specific filtering
    if context.categoryID == PGF.RAID_CATEGORY_ID then
        local raidDifficulty = filter.raidDifficulty or {}
        
        local showNormal = raidDifficulty.normal ~= false
        local showHeroic = raidDifficulty.heroic ~= false
        local showMythic = raidDifficulty.mythic ~= false
        
        local hasFilter = (raidDifficulty.normal == false) or 
                          (raidDifficulty.heroic == false) or 
                          (raidDifficulty.mythic == false)
        
        if hasFilter then
            local difficultyMatch = false
            
            if context.difficulty == "normal" and showNormal then
                difficultyMatch = true
            elseif context.difficulty == "heroic" and showHeroic then
                difficultyMatch = true
            elseif context.difficulty == "mythic" and showMythic then
                difficultyMatch = true
            elseif context.difficulty == "unknown" then
                -- Activities without standard difficulty (World Bosses)
                difficultyMatch = true
            end
            
            if not difficultyMatch then
                return false
            end
        end

        local raidHasRole = filter.raidHasRole or {}
        if raidHasRole.tank and context.tanks == 0 then
            return false
        end
        if raidHasRole.healer and context.healers == 0 then
            return false
        end
        
        -- Role requirements (>= X healers, etc.)
        local roleReqs = filter.raidRoleRequirements or {}
        for role, req in pairs(roleReqs) do
            if req and req.enabled then
                local count = 0
                if role == "tank" then
                    count = context.tanks or 0
                elseif role == "healer" then
                    count = context.healers or 0
                elseif role == "dps" then
                    count = context.dps or 0
                end
                
                local operator = req.operator or ">="
                local value = req.value or 0
                
                if not CompareValue(count, operator, value) then
                    return false
                end
            end
        end
        
        -- generalPlaystyle: 1=Learning, 2=Relaxed, 3=Competitive, 4=Carry Offered
        local raidPlaystyle = filter.raidPlaystyle or {}
        local playstyleMapping = {
            [1] = "generalPlaystyle1",
            [2] = "generalPlaystyle2",
            [3] = "generalPlaystyle3",
            [4] = "generalPlaystyle4",
        }

        local hasPlaystyleFilter = (raidPlaystyle.generalPlaystyle1 == false) or
                                   (raidPlaystyle.generalPlaystyle2 == false) or
                                   (raidPlaystyle.generalPlaystyle3 == false) or
                                   (raidPlaystyle.generalPlaystyle4 == false)
        
        if hasPlaystyleFilter and context.generalPlaystyle and context.generalPlaystyle > 0 then
            local blizzKey = playstyleMapping[context.generalPlaystyle]
            if blizzKey and raidPlaystyle[blizzKey] == false then
                return false
            end
        end

        if filter.raidActivities ~= nil then
            local raidActivities = filter.raidActivities
            local selectedGroupIDs = {}
            local selectedStandaloneIDs = {}
            for key, selected in pairs(raidActivities) do
                if selected then
                    if key > 0 then
                        table.insert(selectedGroupIDs, key)
                    else
                        table.insert(selectedStandaloneIDs, -key)
                    end
                end
            end

            local activityMatches = false
            
            if #selectedGroupIDs > 0 then
                activityMatches = ActivityMatchesSelectedGroups(context.activityID, context.categoryID, selectedGroupIDs)
            end
            
            if not activityMatches and #selectedStandaloneIDs > 0 then
                for _, actID in ipairs(selectedStandaloneIDs) do
                    if actID == context.activityID then
                        activityMatches = true
                        break
                    end
                end
            end
            
            if #selectedGroupIDs == 0 and #selectedStandaloneIDs == 0 then
                return false
            end
            
            if not activityMatches then
                return false
            end
        end

        local bossFilter = filter.raidBossFilter or "any"
        if bossFilter ~= "any" then
            local encounterInfo = C_LFGList.GetSearchResultEncounterInfo(resultID)
            local defeatedCount = encounterInfo and #encounterInfo or 0
            
            if bossFilter == "fresh" and defeatedCount > 0 then
                return false
            elseif bossFilter == "partial" and defeatedCount == 0 then
                return false
            end
        end
    end
    
    return true
end

---Filter search results based on user criteria.
---@param results number[] Array of resultIDs
---@return number[] filteredResults
function PGF.FilterResults(results)
    if not results or #results == 0 then
        return results
    end
    
    local filtered = {}
    
    for _, resultID in ipairs(results) do
        if C_LFGList.HasSearchResultInfo(resultID) then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            if searchResultInfo then
                local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
                if memberCounts then
                    local context = PGF.BuildFilterContext(resultID, searchResultInfo, memberCounts)
                    if PassesFilter(resultID, context) then
                        table.insert(filtered, resultID)
                    end
                end
            end
        end
    end
    
    return filtered
end

---Get sort value for a context based on sort type.
---@param context FilterContext
---@param sortType string
---@return number|string|nil value
local function GetSortValue(context, sortType)
    if sortType == "age" then
        return context.ageSecs or context.age * 60 or 0
    elseif sortType == "rating" then
        return context.mprating or 0
    elseif sortType == "groupSize" then
        return context.members or 0
    elseif sortType == "ilvl" then
        return context.ilvl or 0
    elseif sortType == "name" then
        return context.leaderName or ""
    end
    return 0
end

---Compare two values based on sort direction.
---@param valueA number|string
---@param valueB number|string
---@param direction string "asc"|"desc"
---@return boolean aLessThanB
local function CompareSortValues(valueA, valueB, direction)
    local isLess
    if type(valueA) == "string" and type(valueB) == "string" then
        isLess = valueA < valueB
    else
        isLess = valueA < valueB
    end
    
    if direction == "desc" then
        return not isLess
    end
    return isLess
end

---@param results table Array of resultIDs
---@return table sortedResults
function PGF.SortResults(results)
    if not results or #results <= 1 then
        return results
    end
    
    local db = PintaGroupFinderDB
    
    local categoryID = nil
    if #results > 0 then
        local firstResultID = results[1]
        if C_LFGList.HasSearchResultInfo(firstResultID) then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(firstResultID)
            if searchResultInfo then
                local activityID = searchResultInfo.activityIDs and searchResultInfo.activityIDs[1] or searchResultInfo.activityID
                local activityInfo = activityID and C_LFGList.GetActivityInfoTable(activityID) or nil
                if activityInfo then
                    categoryID = activityInfo.categoryID
                end
            end
        end
    end

    local sortSettings
    if categoryID == PGF.RAID_CATEGORY_ID then
        sortSettings = (db.filter and db.filter.raidSortSettings) or PGF.defaults.filter.raidSortSettings
    else
        sortSettings = (db.filter and db.filter.dungeonSortSettings) or PGF.defaults.filter.dungeonSortSettings
    end

    if sortSettings.disableCustomSorting == true then
        PGF.Debug("Sort: using Blizzard default")
        return results
    end

    local primarySort = sortSettings.primarySort or "age"
    local primaryDir = sortSettings.primarySortDirection or "asc"
    local secondarySort = sortSettings.secondarySort
    local secondaryDir = sortSettings.secondarySortDirection or "desc"
    PGF.Debug("Sort:", primarySort, primaryDir, secondarySort and ("+ " .. secondarySort .. " " .. secondaryDir) or "")
    
    local resultCache = {}
    for _, resultID in ipairs(results) do
        if C_LFGList.HasSearchResultInfo(resultID) then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
            if searchResultInfo and memberCounts then
                resultCache[resultID] = {
                    searchResultInfo = searchResultInfo,
                    memberCounts = memberCounts,
                }
            end
        end
    end
    
    table.sort(results, function(a, b)
        local infoA = resultCache[a]
        local infoB = resultCache[b]
        
        if not infoA or not infoB then
            return false
        end
        
        local contextA = PGF.BuildFilterContext(a, infoA.searchResultInfo, infoA.memberCounts)
        local contextB = PGF.BuildFilterContext(b, infoB.searchResultInfo, infoB.memberCounts)
        
        if contextA.isApplied ~= contextB.isApplied then
            return contextA.isApplied
        end
        
        local valueA = GetSortValue(contextA, primarySort)
        local valueB = GetSortValue(contextB, primarySort)
        
        if valueA ~= valueB then
            return CompareSortValues(valueA, valueB, primaryDir)
        end

        if secondarySort then
            valueA = GetSortValue(contextA, secondarySort)
            valueB = GetSortValue(contextB, secondarySort)
            
            if valueA ~= valueB then
                return CompareSortValues(valueA, valueB, secondaryDir)
            end
        end
        
        return a < b
    end)
    
    return results
end

---Intercept and process search result updates.
local function InterceptResultUpdates()
    local updateHandler = function(searchPanel)
        if filterInProgress then
            return
        end
        
        local categoryID = searchPanel.categoryID or (LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID)
        local isSupportedCategory = (categoryID == PGF.DUNGEON_CATEGORY_ID) or (categoryID == PGF.RAID_CATEGORY_ID)
        
        if not isSupportedCategory then
            return
        end
        
        local _, resultIDs = C_LFGList.GetSearchResults()
        if not resultIDs or #resultIDs == 0 then
            return
        end
        
        filterInProgress = true
        local totalBefore = #resultIDs
        local processedResults = PGF.FilterResults(resultIDs)
        local totalAfterFilter = #processedResults
        processedResults = PGF.SortResults(processedResults)
        PGF.Debug("Filter:", totalBefore, "->", totalAfterFilter, "results")

        if searchPanel.results then
            searchPanel.results = processedResults
            searchPanel.totalResults = #processedResults
        end

        if LFGListSearchPanel_UpdateResults then
            LFGListSearchPanel_UpdateResults(searchPanel)
        end

        filterInProgress = false
    end
    
    hooksecurefunc("LFGListSearchPanel_UpdateResultList", updateHandler)
end

---Initialize filtering system.
function PGF.InitializeFilterCore()
    local function attemptSetup()
        if LFGListFrame and LFGListFrame.SearchPanel then
            InterceptResultUpdates()
        else
            C_Timer.After(1, function()
                if LFGListFrame and LFGListFrame.SearchPanel then
                    InterceptResultUpdates()
                end
            end)
        end
    end
    
    attemptSetup()
end

---Trigger a re-filter of current results.
function PGF.RefilterResults()
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    if panel and panel.results then
        if LFGListSearchPanel_UpdateResultList then
            LFGListSearchPanel_UpdateResultList(panel)
        end
    end
end
