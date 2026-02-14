--[[ PintaGroupFinder - Entry Enhancements Module ]]

local addonName, PGF = ...

local roleIndicators = {}
local classSpecIndicators = {}
local leaderIconFrames = {}
local dungeonSpecFrames = {}
local specNameToTexture = {}
local specNameCacheBuilt = false

local playerClassFile = nil
local playerSpecID = nil
local playerSpecIcon = nil
local playerSpecNamesToIcon = {}
local playerSpecOrder = {}
local playerSpecNameToRole = {}

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

local CACHE_KEY_SEP = "\1"
local debugFirstEntry = false

---@return nil
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

---Build (classFilename+specName) -> icon cache for all classes/specs.
local function BuildSpecNameCache()
    if specNameCacheBuilt then return end
    specNameCacheBuilt = true
    for classID = 1, 20 do
        local _, classFilename = GetClassInfo(classID)
        if not classFilename then break end
        for sex = 1, 2 do
            for specIndex = 1, 5 do
                local specId, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(specIndex, false, false, nil, sex, nil, classID)
                if name and name ~= "" and icon and icon ~= 0 then
                    specNameToTexture[classFilename .. CACHE_KEY_SEP .. name] = icon
                end
            end
        end
    end
end

---@param specName string
---@param classFilename string|nil
---@return number|nil icon
local function GetSpecTextureBySpecNameAndClass(specName, classFilename)
    if not specName or specName == "" then return nil end
    return specNameToTexture[(classFilename or "") .. CACHE_KEY_SEP .. specName]
end

---@param rating number
---@return number r, number g, number b
local function GetRatingColor(rating)
    local tiers = PGF.SCORE_COLORS
    if not tiers then return 0.5, 0.5, 0.5 end
    for _, tier in ipairs(tiers) do
        if rating >= tier[1] then return tier[2], tier[3], tier[4] end
    end
    return 0.5, 0.5, 0.5
end

---@param entry Frame
---@param numIcons number
---@return Frame[]
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

---@param entry Frame
---@return Frame
local function GetOrCreateLeaderIconFrame(entry)
    local frame = leaderIconFrames[entry]
    if not frame then
        frame = CreateFrame("Frame", nil, entry)
        frame:Hide()
        frame:SetFrameStrata("HIGH")
        frame:SetSize(14, 9)
        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetAtlas("groupfinder-icon-leader")
        frame.texture = tex
        leaderIconFrames[entry] = frame
    end
    return frame
end

---@param entry Frame
---@return Frame[]
local function GetOrCreateDungeonSpecFrames(entry)
    local frames = dungeonSpecFrames[entry]
    if not frames then
        frames = {}
        for i = 1, 5 do
            local frame = CreateFrame("Frame", nil, entry)
            frame:Hide()
            frame:SetFrameStrata("HIGH")
            frame:SetSize(14, 14)
            local tex = frame:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            frame.texture = tex
            frames[i] = frame
        end
        dungeonSpecFrames[entry] = frames
    end
    return frames
end

---@param entry Frame
---@return Frame
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

---@param entry Frame
---@param resultID number
---@param searchResultInfo table
local function AddMissingRoles(entry, resultID, searchResultInfo)
    local db = PintaGroupFinderDB
    if not (db.ui and db.ui.showMissingRoles) then return end

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
    if not activityInfo or activityInfo.displayType ~= Enum.LFGListDisplayType.RoleEnumerate then return end

    local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
    if not memberCounts then return end

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
            if slotIndex > numIcons then break end
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

---@param entry Frame
---@param resultID number
---@param searchResultInfo table
local function AddLeaderRating(entry, resultID, searchResultInfo)
    local db = PintaGroupFinderDB
    if not (db.ui and db.ui.showLeaderRating) then return end

    local categoryID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    if categoryID ~= PGF.DUNGEON_CATEGORY_ID then return end
    if not entry.Name then return end

    local rating = searchResultInfo.leaderOverallDungeonScore or 0
    if rating > 0 then
        local r, g, b = GetRatingColor(rating)
        local colorHex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
        local ratingText = string.format(" |cFF%s[%d]|r", colorHex, rating)
        local originalText = entry.Name:GetText() or ""
        if not originalText:find("%[%d+%]") then
            entry.Name:SetText(originalText .. ratingText)
        end
    end
end

---@param entry Frame
---@param resultID number
---@param searchResultInfo table
local function AddClassSpecIndicators(entry, resultID, searchResultInfo)
    local categoryID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    local indicator = classSpecIndicators[entry]

    if categoryID ~= PGF.RAID_CATEGORY_ID then
        if indicator then indicator:Hide() end
        return
    end

    if not playerClassFile then UpdatePlayerClassSpec() end
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
        TANK = rc.TankCount, HEALER = rc.HealerCount, DAMAGER = rc.DamagerCount,
    } or {}
    local roleIconAnchors = rc and {
        TANK = rc.TankIcon, HEALER = rc.HealerIcon, DAMAGER = rc.DamagerIcon,
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

---Map members to icon indices by role group (T,H,D). Icons[1]=rightmost, Icons[numIcons]=leftmost.
---@param resultID number
---@param searchResultInfo table
---@param numIcons number
---@return table|nil playerData
local function GetDungeonEntryPlayerData(resultID, searchResultInfo, numIcons)
    local numMembers = searchResultInfo.numMembers or 0
    if numMembers == 0 then return nil end

    local tanks, healers, dps = {}, {}, {}
    local memberInfo = {}
    for i = 1, numMembers do
        local info = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
        if info then
            memberInfo[i] = info
            local role = info.assignedRole
            if role == "TANK" then tanks[#tanks + 1] = i
            elseif role == "HEALER" then healers[#healers + 1] = i
            else dps[#dps + 1] = i end
        end
    end

    local memberToIconIndex = {}
    local filledSlot = 0
    for _, bucket in ipairs({tanks, healers, dps}) do
        for _, idx in ipairs(bucket) do
            filledSlot = filledSlot + 1
            memberToIconIndex[idx] = numIcons + 1 - filledSlot
        end
    end

    if debugFirstEntry then
        debugFirstEntry = false
        print("--- PGF DEBUG: GetDungeonEntryPlayerData ---")
        print("  resultID=" .. tostring(resultID) .. " numMembers=" .. numMembers .. " numIcons=" .. numIcons)
        for i = 1, numMembers do
            local info = memberInfo[i]
            if info then
                print(string.format("  member[%d]: role=%s class=%s spec=%s isLeader=%s",
                    i, tostring(info.assignedRole), tostring(info.classFilename),
                    tostring(info.specName), tostring(info.isLeader)))
            else
                print(string.format("  member[%d]: nil", i))
            end
        end
        print("  tanks: " .. table.concat(tanks, ","))
        print("  healers: " .. table.concat(healers, ","))
        print("  dps: " .. table.concat(dps, ","))
        local parts = {}
        for idx, iconIdx in pairs(memberToIconIndex) do
            parts[#parts + 1] = string.format("member%d->icon%d", idx, iconIdx)
        end
        print("  memberToIconIndex: " .. table.concat(parts, ", "))
    end

    return {
        numMembers = numMembers,
        memberToIconIndex = memberToIconIndex,
        memberInfo = memberInfo,
    }
end

---@param entry Frame
---@param icons table
---@param playerData table
local function AddDungeonLeaderIcon(entry, icons, playerData)
    for i = 1, playerData.numMembers do
        local info = playerData.memberInfo[i]
        if info and info.isLeader then
            local iconIndex = playerData.memberToIconIndex[i]
            local icon = iconIndex and icons[iconIndex]
            if icon then
                local frame = GetOrCreateLeaderIconFrame(entry)
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOM", icon, "TOP", 0, 0)
                frame:Show()
                return
            end
        end
    end
    local frame = leaderIconFrames[entry]
    if frame then frame:Hide() end
end

---@param entry Frame
---@param icons table
---@param playerData table
local function AddDungeonSpecIcons(entry, icons, playerData)
    local frames = GetOrCreateDungeonSpecFrames(entry)
    local numIcons = #icons

    for i = 1, #frames do frames[i]:Hide() end

    for memberIndex = 1, playerData.numMembers do
        local iconIndex = playerData.memberToIconIndex[memberIndex]
        if iconIndex and iconIndex >= 1 and iconIndex <= numIcons then
            local info = playerData.memberInfo[memberIndex]
            local icon = icons[iconIndex]
            if info and icon then
                local tex = GetSpecTextureBySpecNameAndClass(info.specName, info.classFilename)
                if tex then
                    local frame = frames[iconIndex]
                    if frame then
                        frame.texture:SetTexture(tex)
                        frame.texture:Show()
                        frame:ClearAllPoints()
                        frame:SetPoint("TOP", icon, "BOTTOM", 0, -2)
                        frame:Show()
                    end
                end
            end
        end
    end
end

---@param entry Frame
local function HideDungeonOverlays(entry)
    local frame = leaderIconFrames[entry]
    if frame then frame:Hide() end
    local specFrames = dungeonSpecFrames[entry]
    if specFrames then
        for i = 1, #specFrames do specFrames[i]:Hide() end
    end
end

---@param self Frame
local function OnEntryUpdate(self)
    local resultID = self.resultID
    if not resultID or not C_LFGList.HasSearchResultInfo(resultID) then return end

    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
    if not searchResultInfo then return end

    local categoryID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    local db = PintaGroupFinderDB

    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        local showLeader = db.ui and db.ui.showLeaderIcon
        local showSpecs = db.ui and db.ui.showDungeonSpecIcons

        if (showLeader or showSpecs) and (searchResultInfo.numMembers or 0) > 0 then
            local activityID = searchResultInfo.activityIDs and searchResultInfo.activityIDs[1] or searchResultInfo.activityID
            local activityInfo = activityID and C_LFGList.GetActivityInfoTable(activityID) or nil

            if activityInfo and activityInfo.displayType == Enum.LFGListDisplayType.RoleEnumerate then
                local icons = self.DataDisplay and self.DataDisplay.Enumerate and self.DataDisplay.Enumerate.Icons
                if icons and #icons > 0 then
                    if debugFirstEntry then
                        print("--- PGF DEBUG: Blizzard Icons (1=rightmost, " .. #icons .. "=leftmost) ---")
                        for i = 1, #icons do
                            local ic = icons[i]
                            if ic and ic:IsShown() then
                                local atlas = "?"
                                local tex = "?"
                                if ic.Icon then
                                    if ic.Icon.GetAtlas then atlas = tostring(ic.Icon:GetAtlas()) end
                                    if ic.Icon.GetTexture then tex = tostring(ic.Icon:GetTexture()) end
                                end
                                print(string.format("  Icons[%d]: shown=true atlas=%s tex=%s", i, atlas, tex))
                            else
                                print(string.format("  Icons[%d]: shown=false", i))
                            end
                        end
                    end
                    local playerData = GetDungeonEntryPlayerData(resultID, searchResultInfo, #icons)
                    if playerData then
                        if showLeader then
                            AddDungeonLeaderIcon(self, icons, playerData)
                        else
                            local frame = leaderIconFrames[self]
                            if frame then frame:Hide() end
                        end
                        if showSpecs then
                            AddDungeonSpecIcons(self, icons, playerData)
                        else
                            local specFrames = dungeonSpecFrames[self]
                            if specFrames then
                                for i = 1, #specFrames do specFrames[i]:Hide() end
                            end
                        end
                    else
                        HideDungeonOverlays(self)
                    end
                else
                    HideDungeonOverlays(self)
                end
            else
                HideDungeonOverlays(self)
            end
        else
            HideDungeonOverlays(self)
        end
    else
        HideDungeonOverlays(self)
    end

    AddMissingRoles(self, resultID, searchResultInfo)
    AddLeaderRating(self, resultID, searchResultInfo)
    AddClassSpecIndicators(self, resultID, searchResultInfo)
end

function PGF.InitializeEntryEnhancements()
    hooksecurefunc("LFGListSearchEntry_Update", OnEntryUpdate)
    UpdatePlayerClassSpec()
    BuildSpecNameCache()

    local debugFrame = CreateFrame("Frame")
    debugFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
    debugFrame:SetScript("OnEvent", function()
        debugFirstEntry = true
    end)

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
