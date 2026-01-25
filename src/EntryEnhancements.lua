--[[
    PintaGroupFinder - Entry Enhancements Module
    
    Enhances group list entries with class colors, leader rating, and missing roles.
]]

local addonName, PGF = ...

local roleIndicators = {}

local ROLE_ATLAS = {
    TANK = "UI-LFG-RoleIcon-Tank",
    HEALER = "UI-LFG-RoleIcon-Healer",
    DAMAGER = "UI-LFG-RoleIcon-DPS",
}

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }

local REMAINING_KEYS = {
    TANK = "TANK_REMAINING",
    HEALER = "HEALER_REMAINING",
    DAMAGER = "DAMAGER_REMAINING",
}

---Get or create role indicator frames for an entry.
---@param entry Frame The search entry frame
---@param numIcons number Number of role icons needed
---@return Frame[] frames Array of indicator frames
local function GetOrCreateRoleIndicators(entry, numIcons)
    local frames = roleIndicators[entry]
    if frames == nil then
        frames = {}
        for i = 1, numIcons do
            local frame = CreateFrame("Frame", nil, entry)
            frame:Hide()
            frame:SetFrameStrata("HIGH")
            frame:SetSize(18, 35)
            frame:SetPoint("CENTER", 0, 1)
            
            if entry.DataDisplay and entry.DataDisplay.Enumerate then
                local icons = entry.DataDisplay.Enumerate.Icons
                if icons and icons[i] then
                    frame:SetPoint("CENTER", icons[i], "CENTER", 0, 0)
                end
            end
            
            frame.missingRole = frame:CreateTexture(nil, "ARTWORK")
            frame.missingRole:SetSize(16, 16)
            frame.missingRole:SetPoint("CENTER", 0, 0)
            frame.missingRole:Hide()
            
            frames[i] = frame
        end
        roleIndicators[entry] = frames
    end
    return frames
end

---Get color for M+ rating (uses Raider.IO color tiers).
---@param rating number
---@return number r Red component (0-1)
---@return number g Green component (0-1)
---@return number b Blue component (0-1)
local function GetRatingColor(rating)
    local tiers = PGF.SCORE_COLORS
    if not tiers then
        return 0.5, 0.5, 0.5
    end
    
    for _, tier in ipairs(tiers) do
        if rating >= tier[1] then
            return tier[2], tier[3], tier[4]
        end
    end
    
    return 0.5, 0.5, 0.5
end

---Add missing role indicators.
---@param entry Frame Search entry frame
---@param resultID number
---@param searchResultInfo LfgSearchResultData
local function AddMissingRoles(entry, resultID, searchResultInfo)
    local db = PintaGroupFinderDB or PGF.defaults
    if not (db.ui and db.ui.showMissingRoles) then
        return
    end
    
    local activityID = searchResultInfo.activityIDs and searchResultInfo.activityIDs[1] or searchResultInfo.activityID
    local activityInfo = activityID and C_LFGList.GetActivityInfoTable(activityID) or nil
    
    if not activityInfo or activityInfo.displayType ~= Enum.LFGListDisplayType.RoleEnumerate then
        return
    end
    
    local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
    if not memberCounts then
        return
    end
    
    local icons = entry.DataDisplay and entry.DataDisplay.Enumerate and entry.DataDisplay.Enumerate.Icons
    local numIcons = icons and #icons or 5
    
    local frames = GetOrCreateRoleIndicators(entry, numIcons)
    for i = 1, numIcons do
        if frames[i] then
            frames[i]:Hide()
            frames[i].missingRole:Hide()
        end
    end
    
    local numMembers = searchResultInfo.numMembers or 0
    if numMembers == 0 then
        numMembers = (memberCounts.TANK or 0) + (memberCounts.HEALER or 0) + (memberCounts.DAMAGER or 0)
    end
    
    local missingRoles = {}
    for _, role in ipairs(ROLE_ORDER) do
        local remaining = memberCounts[REMAINING_KEYS[role]] or 0
        for _ = 1, remaining do
            table.insert(missingRoles, role)
        end
    end
    
    local slotIndex = numMembers + 1
    for _, role in ipairs(missingRoles) do
        if slotIndex > numIcons then
            break
        end
        
        local iconIndex = numIcons + 1 - slotIndex
        local frame = frames[slotIndex]
        local icon = icons and icons[iconIndex]
        
        if frame and icon then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", icon, "CENTER", 0, 0)
            frame:Show()
            frame.missingRole:Show()
            frame.missingRole:SetAtlas(ROLE_ATLAS[role])
            frame.missingRole:SetDesaturated(true)
            frame.missingRole:SetAlpha(0.5)
        end
        
        slotIndex = slotIndex + 1
    end
end

---Add leader rating to group name.
---@param entry Frame Search entry frame
---@param resultID number
---@param searchResultInfo LfgSearchResultData
local function AddLeaderRating(entry, resultID, searchResultInfo)
    local db = PintaGroupFinderDB or PGF.defaults
    if not (db.ui and db.ui.showLeaderRating) then
        return
    end
    
    local categoryID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    if categoryID ~= PGF.DUNGEON_CATEGORY_ID then
        return
    end
    
    if not entry.Name then
        return
    end
    
    local rating = 0
    local ratingText = ""
    
    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        rating = searchResultInfo.leaderOverallDungeonScore or 0
        if rating > 0 then
            local r, g, b = GetRatingColor(rating)
            local colorHex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
            ratingText = string.format(" |cFF%s[%d]|r", colorHex, rating)
        end
    end
    
    if ratingText ~= "" then
        local originalText = entry.Name:GetText() or ""
        if not originalText:find("%[%d+%]") then
            entry.Name:SetText(originalText .. ratingText)
        end
    end
end

---Hook into entry update.
---@param self Frame Search entry frame
local function OnEntryUpdate(self)
    local resultID = self.resultID
    if not resultID or not C_LFGList.HasSearchResultInfo(resultID) then
        return
    end
    
    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
    if not searchResultInfo then
        return
    end
    
    AddMissingRoles(self, resultID, searchResultInfo)
    AddLeaderRating(self, resultID, searchResultInfo)
end

---Initialize entry enhancements.
function PGF.InitializeEntryEnhancements()
    hooksecurefunc("LFGListSearchEntry_Update", OnEntryUpdate)
    PGF.Debug("Entry enhancements initialized")
end
