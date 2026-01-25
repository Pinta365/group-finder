--[[
    PintaGroupFinder - Filter Core Module
    
    Main filtering logic and hooks for search results.
]]

local addonName, PGF = ...

local filterInProgress = false

---Check if result passes filter criteria.
---@param resultID number
---@param context FilterContext Filter context
---@return boolean passes
local function PassesFilter(resultID, context)
    local db = PintaGroupFinderDB or PGF.defaults
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

---@param results table Array of resultIDs
---@return table sortedResults
function PGF.SortResults(results)
    if not results or #results <= 1 then
        return results
    end
    
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
        
        if contextA.mythicplus and contextB.mythicplus then
            if contextA.mprating ~= contextB.mprating then
                return contextA.mprating > contextB.mprating
            end
        end
        
        if contextA.age ~= contextB.age then
            return contextA.age < contextB.age
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
        local isSupportedCategory = (categoryID == PGF.DUNGEON_CATEGORY_ID)
        
        if not isSupportedCategory then
            return
        end
        
        local totalResults, resultIDs = C_LFGList.GetSearchResults()
        if not resultIDs or #resultIDs == 0 then
            return
        end
        
        filterInProgress = true
        local processedResults = PGF.FilterResults(resultIDs)
        processedResults = PGF.SortResults(processedResults)
        
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
