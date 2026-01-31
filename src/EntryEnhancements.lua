--[[
    PintaGroupFinder - Entry Enhancements Module
    
    Enhances group list entries with class colors, leader rating, and missing roles.
]]

local addonName, PGF = ...

local roleIndicators = {}
local classSpecIndicators = {}

local playerClassFile = nil
local playerSpecID = nil
local playerSpecIcon = nil
local playerSpecNamesToIcon = {}
local playerSpecOrder = {}
local playerSpecNameToRole = {}

---Update player's class and spec info
local function UpdatePlayerClassSpec()
    local _, classFile = UnitClass("player")
    playerClassFile = classFile
    
    local specIndex = GetSpecialization()
    if specIndex then
        local specID, _, _, icon = GetSpecializationInfo(specIndex)
        playerSpecID = specID
        playerSpecIcon = icon
    end
    
    playerSpecOrder = {}
    playerSpecNamesToIcon = {}
    playerSpecNameToRole = {}
    for i = 1, GetNumSpecializations() do
        local _, name, _, icon, role = GetSpecializationInfo(i)
        if name and name ~= "" then
            table.insert(playerSpecOrder, name)
            playerSpecNamesToIcon[name] = icon
            playerSpecNameToRole[name] = (role == "TANK" or role == "HEALER" or role == "DAMAGER") and role or "DAMAGER"
        end
    end
    playerSpecNamesToIcon["?"] = playerSpecIcon
    playerSpecNameToRole["?"] = "DAMAGER"
end

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
    local db = PintaGroupFinderDB
    if not (db.ui and db.ui.showMissingRoles) then
        return
    end

    local categoryID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    if categoryID ~= PGF.DUNGEON_CATEGORY_ID then
        local frames = roleIndicators[entry]
        if frames then
            for i = 1, #frames do
                if frames[i] then
                    frames[i]:Hide()
                    frames[i].missingRole:Hide()
                end
            end
        end
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

    local _, appStatus = C_LFGList.GetApplicationInfo(resultID)
    local isApplied = appStatus and appStatus ~= "none"

    if isApplied then
        local ROW_GAP = 2
        local anchor = (entry.PendingLabel and entry.PendingLabel:IsShown()) and entry.PendingLabel or entry
        local prevAnchor = anchor
        local prevPoint = "BOTTOMLEFT"
        local prevX = (anchor == entry) and 100 or 20
        local prevY = (anchor == entry.PendingLabel) and -27 or -5
        for i, role in ipairs(missingRoles) do
            local frame = frames[i]
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOMLEFT", prevAnchor, prevPoint, prevX, prevY)
                frame:Show()
                frame.missingRole:Show()
                frame.missingRole:SetAtlas(ROLE_ATLAS[role])
                frame.missingRole:SetDesaturated(true)
                frame.missingRole:SetAlpha(0.5)
                prevAnchor = frame
                prevPoint = "BOTTOMRIGHT"
                prevX = ROW_GAP
                prevY = 0
            end
        end
    else
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
end

---Add leader rating to group name.
---@param entry Frame Search entry frame
---@param resultID number
---@param searchResultInfo LfgSearchResultData
local function AddLeaderRating(entry, resultID, searchResultInfo)
    local db = PintaGroupFinderDB
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

---Get or create class/spec indicator
---@param entry Frame The search entry frame
---@return Frame indicator The indicator frame
local function GetOrCreateClassSpecIndicator(entry)
    local indicator = classSpecIndicators[entry]
    if indicator and not indicator.slots then
        classSpecIndicators[entry] = nil
        indicator = nil
    end
    if indicator == nil then
        indicator = CreateFrame("Frame", nil, entry)
        indicator:SetSize(1, 1)
        indicator.slots = {}
        for _, role in ipairs(ROLE_ORDER) do
            local t = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            t:SetTextColor(1, 1, 1, 0.9)
            local tex = indicator:CreateTexture(nil, "ARTWORK")
            tex:SetSize(14, 14)
            tex:SetPoint("LEFT", t, "RIGHT", 2, 0)
            indicator.slots[role] = { text = t, icon = tex }
        end
        classSpecIndicators[entry] = indicator
    end
    return indicator
end

---Add class/spec match indicators for raid groups.
---@param entry Frame Search entry frame
---@param resultID number
---@param searchResultInfo LfgSearchResultData
local function AddClassSpecIndicators(entry, resultID, searchResultInfo)
    local categoryID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    
    local indicator = classSpecIndicators[entry]
    if categoryID ~= PGF.RAID_CATEGORY_ID then
        if indicator then
            indicator:Hide()
        end
        return
    end
    
    if not playerClassFile then
        UpdatePlayerClassSpec()
    end
    if not playerClassFile then
        if indicator then indicator:Hide() end
        return
    end
    
    local numMembers = searchResultInfo.numMembers or 0
    local specCounts = {}
    for i = 1, numMembers do
        local info = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
        if info and info.classFilename and info.classFilename == playerClassFile then
            local key = (info.specName and info.specName ~= "") and info.specName or "?"
            specCounts[key] = (specCounts[key] or 0) + 1
        end
    end
    
    if not next(specCounts) then
        if indicator then indicator:Hide() end
        return
    end
    
    local roleCounts = {}
    local roleIcon = {}
    local roleBestCount = {}
    for specName, count in pairs(specCounts) do
        local role = (playerSpecNameToRole or {})[specName] or "DAMAGER"
        roleCounts[role] = (roleCounts[role] or 0) + count
        if (roleBestCount[role] or 0) < count then
            roleBestCount[role] = count
            roleIcon[role] = (playerSpecNamesToIcon or {})[specName] or playerSpecIcon
        end
    end
    
    indicator = GetOrCreateClassSpecIndicator(entry)
    indicator:ClearAllPoints()
    local rc = entry.DataDisplay and entry.DataDisplay.RoleCount
    local roleCountAnchors = rc and {
        TANK = rc.TankCount,
        HEALER = rc.HealerCount,
        DAMAGER = rc.DamagerCount,
    } or {}
    local roleIconAnchors = rc and {
        TANK = rc.TankIcon,
        HEALER = rc.HealerIcon,
        DAMAGER = rc.DamagerIcon,
    } or {}
    
    if rc then
        indicator:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, 0)
        for _, role in ipairs(ROLE_ORDER) do
            local count = roleCounts[role] or 0
            local slot = indicator.slots[role]
            local countAnchor = roleCountAnchors[role]
            local iconAnchor = roleIconAnchors[role]
            if count > 0 and countAnchor and iconAnchor then
                slot.text:ClearAllPoints()
                slot.text:SetText(count)
                slot.text:SetPoint("TOPLEFT", countAnchor, "BOTTOMLEFT", 4, -5)
                slot.text:Show()
                slot.icon:ClearAllPoints()
                slot.icon:SetPoint("TOPLEFT", iconAnchor, "BOTTOMLEFT", 0, -2)
                if roleIcon[role] then
                    slot.icon:SetTexture(roleIcon[role])
                    slot.icon:Show()
                else
                    slot.icon:Hide()
                end
            else
                slot.text:Hide()
                slot.icon:Hide()
            end
        end
    else
        indicator:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", -5, 2)
        local prev
        for _, role in ipairs(ROLE_ORDER) do
            local count = roleCounts[role] or 0
            local slot = indicator.slots[role]
            if count > 0 then
                slot.text:ClearAllPoints()
                slot.text:SetPoint("LEFT", prev or indicator, prev and "RIGHT" or "LEFT", prev and 4 or 0, 0)
                slot.text:SetText(count)
                slot.text:Show()
                if roleIcon[role] then
                    slot.icon:SetTexture(roleIcon[role])
                    slot.icon:Show()
                else
                    slot.icon:Hide()
                end
                prev = slot.icon
            else
                slot.text:Hide()
                slot.icon:Hide()
            end
        end
    end
    indicator:Show()
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
    AddClassSpecIndicators(self, resultID, searchResultInfo)
end

---Initialize entry enhancements.
function PGF.InitializeEntryEnhancements()
    hooksecurefunc("LFGListSearchEntry_Update", OnEntryUpdate)

    UpdatePlayerClassSpec()
    
    local specFrame = CreateFrame("Frame")
    specFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    specFrame:RegisterEvent("PLAYER_LOGIN")
    specFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" or (event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player") then
            UpdatePlayerClassSpec()
        end
    end)
    
    PGF.Debug("Entry enhancements initialized")
end
