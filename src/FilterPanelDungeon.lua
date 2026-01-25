--[[
    PintaGroupFinder - Filter Panel Dungeon Module
    
    Dungeon-specific filtering logic.
]]

local addonName, PGF = ...

local PANEL_WIDTH = 280

---Check if dungeon group has activities matching difficulty filters.
---@param categoryID number
---@param groupID number Activity group ID
---@param showMythicPlus boolean
---@param showMythic boolean
---@param showHeroic boolean
---@param showNormal boolean
---@return boolean
local function GroupHasMatchingDifficulty(categoryID, groupID, showMythicPlus, showMythic, showHeroic, showNormal)
    local activities = C_LFGList.GetAvailableActivities(categoryID, groupID)
    if not activities then return false end
    
    for _, activityID in ipairs(activities) do
        local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
        if activityInfo then
            if (showMythicPlus and activityInfo.isMythicPlusActivity) or
               (showMythic and activityInfo.isMythicActivity) or
               (showHeroic and activityInfo.isHeroicActivity) or
               (showNormal and activityInfo.isNormalActivity) then
                return true
            end
        end
    end
    return false
end

---Create dungeon checkbox in scroll content.
---@param filterPanel Frame Filter panel frame
---@param content Frame Scroll content frame
---@param groupID number Activity group ID
---@param yPos number Y position
---@param selectedGroupIDs table Map of selected group IDs
---@param checkboxHeight number
---@param spacing number
---@return number New Y position
local function CreateDungeonCheckbox(filterPanel, content, groupID, yPos, selectedGroupIDs, checkboxHeight, spacing)
    if not groupID then return yPos end
    local name = C_LFGList.GetActivityGroupInfo(groupID)
    if not name then return yPos end
    
    local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    checkbox:SetSize(16, 16)
    checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -yPos)
    
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(name)
    label:SetWidth(PANEL_WIDTH - 35)
    label:SetJustifyH("LEFT")
    
    checkbox:SetChecked(selectedGroupIDs[groupID] == true)
    
    checkbox:SetScript("OnClick", function(self)
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if not advancedFilter then return end
        
        local isChecked = self:GetChecked()
        local activities = advancedFilter.activities or {}
        
        if isChecked then
            local found = false
            for _, id in ipairs(activities) do
                if id == groupID then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(activities, groupID)
            end
        else
            for i = #activities, 1, -1 do
                if activities[i] == groupID then
                    table.remove(activities, i)
                end
            end
        end
        
        advancedFilter.activities = activities
        C_LFGList.SaveAdvancedFilter(advancedFilter)
        
        local panel = LFGListFrame and LFGListFrame.SearchPanel
        if panel and LFGListSearchPanel_DoSearch then
            LFGListSearchPanel_DoSearch(panel)
        end
    end)
    
    if filterPanel and filterPanel.activityCheckboxes then
        table.insert(filterPanel.activityCheckboxes, {
            frame = checkbox,
            label = label,
            groupID = groupID,
        })
    end
    
    return yPos + checkboxHeight + spacing
end

---Update dungeon list based on current filters.
---@param filterPanel Frame Filter panel frame
---@param categoryID number
function PGF.UpdateDungeonFilterPanel(filterPanel, categoryID)
    if not filterPanel or not filterPanel.activityContent then
        return
    end
    
    local content = filterPanel.activityContent
    local checkboxes = filterPanel.activityCheckboxes or {}
    
    for i = 1, #checkboxes do
        local checkbox = checkboxes[i]
        if checkbox then
            if checkbox.frame then
                checkbox.frame:Hide()
                checkbox.frame:ClearAllPoints()
            end
            if checkbox.label then
                checkbox.label:Hide()
                checkbox.label:ClearAllPoints()
            end
            if checkbox.separator then
                checkbox.separator:Hide()
                checkbox.separator:ClearAllPoints()
            end
        end
    end
    wipe(checkboxes)
    filterPanel.activityCheckboxes = checkboxes
    
    content:SetHeight(1)
    if filterPanel.activityScrollFrame then
        filterPanel.activityScrollFrame:SetVerticalScroll(0)
    end
    
    local advancedFilter = C_LFGList.GetAdvancedFilter()
    local showMythicPlus = advancedFilter and advancedFilter.difficultyMythicPlus ~= false
    local showMythic = advancedFilter and advancedFilter.difficultyMythic ~= false
    local showHeroic = advancedFilter and advancedFilter.difficultyHeroic ~= false
    local showNormal = advancedFilter and advancedFilter.difficultyNormal ~= false
    
    local selectedGroupIDs = {}
    if advancedFilter and advancedFilter.activities then
        for _, groupID in ipairs(advancedFilter.activities) do
            selectedGroupIDs[groupID] = true
        end
    end
    
    local yPos = 0
    local checkboxHeight = 20
    local spacing = 2
    local separatorHeight = 10
    
    local seasonFilter = Enum.LFGListFilter.CurrentSeason
    if bit and bit.bor then
        seasonFilter = bit.bor(Enum.LFGListFilter.CurrentSeason, Enum.LFGListFilter.PvE)
    end
    local seasonGroupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, seasonFilter) or {}
    
    local expansionFilter = Enum.LFGListFilter.CurrentExpansion
    if bit and bit.bor then
        expansionFilter = bit.bor(Enum.LFGListFilter.CurrentExpansion, Enum.LFGListFilter.NotCurrentSeason, Enum.LFGListFilter.PvE)
    end
    local expansionGroupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, expansionFilter) or {}
    
    local seasonCount = 0
    for _, groupID in ipairs(seasonGroupIDs) do
        if GroupHasMatchingDifficulty(categoryID, groupID, showMythicPlus, showMythic, showHeroic, showNormal) then
            yPos = CreateDungeonCheckbox(filterPanel, content, groupID, yPos, selectedGroupIDs, checkboxHeight, spacing)
            seasonCount = seasonCount + 1
        end
    end
    
    if seasonCount > 0 and #expansionGroupIDs > 0 then
        local hasExpansionMatches = false
        for _, groupID in ipairs(expansionGroupIDs) do
            if GroupHasMatchingDifficulty(categoryID, groupID, showMythicPlus, showMythic, showHeroic, showNormal) then
                hasExpansionMatches = true
                break
            end
        end
        
        if hasExpansionMatches then
            local separator = content:CreateTexture(nil, "ARTWORK")
            separator:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
            separator:SetSize(PANEL_WIDTH - 20, 8)
            separator:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yPos)
            separator:SetVertexColor(0.5, 0.5, 0.5, 0.5)
            
            table.insert(checkboxes, { separator = separator })
            yPos = yPos + separatorHeight
        end
    end
    
    for _, groupID in ipairs(expansionGroupIDs) do
        if GroupHasMatchingDifficulty(categoryID, groupID, showMythicPlus, showMythic, showHeroic, showNormal) then
            yPos = CreateDungeonCheckbox(filterPanel, content, groupID, yPos, selectedGroupIDs, checkboxHeight, spacing)
        end
    end
    
    content:SetHeight(math.max(1, yPos))
    
    if filterPanel.activityScrollFrame then
        local scrollFrame = filterPanel.activityScrollFrame
        local scrollBar = scrollFrame.ScrollBar
        local visibleHeight = scrollFrame:GetHeight()
        local contentHeight = content:GetHeight()
        
        if scrollBar then
            scrollBar:SetShown(contentHeight > visibleHeight)
        end
    end
end

---Get rating label text for dungeons.
---@return string
function PGF.GetDungeonRatingLabel()
    return "Min Rating:"
end

---Get rating tooltip text for dungeons.
---@return string, string
function PGF.GetDungeonRatingTooltip()
    return "Minimum Leader Rating", "Only show groups where the leader has at least this M+ rating.\nSet to 0 or leave empty to disable."
end

---Get difficulty options for dungeons.
---@return table[]
function PGF.GetDungeonDifficulties()
    return {
        { 
            key = "normal", 
            label = PGF.GetLocalizedDifficultyName("normal"), 
            blizzKey = "difficultyNormal", 
            tooltip = "Show Normal difficulty dungeons." 
        },
        { 
            key = "heroic", 
            label = PGF.GetLocalizedDifficultyName("heroic"), 
            blizzKey = "difficultyHeroic", 
            tooltip = "Show Heroic difficulty dungeons." 
        },
        { 
            key = "mythic", 
            label = PGF.GetLocalizedDifficultyName("mythic"), 
            blizzKey = "difficultyMythic", 
            tooltip = "Show Mythic (non-keystone) dungeons." 
        },
        { 
            key = "mythicplus", 
            label = PGF.GetLocalizedDifficultyName("mythicplus"), 
            blizzKey = "difficultyMythicPlus", 
            tooltip = "Show Mythic+ keystone dungeons." 
        },
    }
end

---Create dungeon-specific filter UI elements.
---@param filterPanel Frame The filter panel frame
---@param panelWidth number Width of the panel
---@return number yOffset Final Y offset after creating all elements
function PGF.CreateDungeonFilterSection(filterPanel, panelWidth)
    if not filterPanel then
        return -10
    end
    
    PANEL_WIDTH = panelWidth or PANEL_WIDTH
    
    local yOffset = -10
    local spacing = 10
    local headerSpacing = 12
    
    -- Activity scroll frame (dungeon list)
    local activityScrollTop = yOffset
    local activityScrollFrame = CreateFrame("ScrollFrame", nil, filterPanel, "UIPanelScrollFrameTemplate")
    activityScrollFrame:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, activityScrollTop)
    activityScrollFrame:SetWidth(PANEL_WIDTH - 20)
    
    local activityContent = CreateFrame("Frame", nil, activityScrollFrame)
    activityContent:SetWidth(PANEL_WIDTH - 20)
    activityContent:SetHeight(1)
    activityScrollFrame:SetScrollChild(activityContent)
    
    filterPanel.activityScrollFrame = activityScrollFrame
    filterPanel.activityContent = activityContent
    filterPanel.activityCheckboxes = {}
    
    local estimatedActivityHeight = 170
    yOffset = yOffset - estimatedActivityHeight - spacing
    
    -- Min Rating input
    local ratingLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    ratingLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    ratingLabel:SetText(PGF.GetDungeonRatingLabel())
    filterPanel.ratingLabel = ratingLabel
    
    local ratingBox = CreateFrame("EditBox", nil, filterPanel, "InputBoxTemplate")
    ratingBox:SetSize(60, 20)
    ratingBox:SetPoint("LEFT", ratingLabel, "RIGHT", 10, 0)
    ratingBox:SetAutoFocus(false)
    ratingBox:SetNumeric(true)
    ratingBox:SetMaxLetters(5)
    
    ratingBox:SetScript("OnEnter", function(self)
        local title, text = PGF.GetDungeonRatingTooltip()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(text, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ratingBox:SetScript("OnLeave", GameTooltip_Hide)
    
    local minRatingBottom = yOffset - 5 - spacing - 5
    activityScrollFrame:SetPoint("BOTTOMRIGHT", filterPanel, "BOTTOMRIGHT", -30, filterPanel:GetHeight() + minRatingBottom + 30)
    
    -- Difficulty section    
    local difficultyLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    difficultyLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", PANEL_WIDTH / 2 + 10, yOffset)
    difficultyLabel:SetText("Difficulty:")
    
    local difficultyStartY = yOffset - headerSpacing
    
    local difficultyCheckboxes = {}
    filterPanel.difficultyCheckboxes = difficultyCheckboxes
    filterPanel.difficultyLabel = difficultyLabel
    filterPanel.difficultyStartY = difficultyStartY
    
    local difficulties = PGF.GetDungeonDifficulties()
    local difficultyY = difficultyStartY
    for _, diff in ipairs(difficulties) do
        local checkbox = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", PANEL_WIDTH / 2 + 10, difficultyY)
        
        local label = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(diff.label)
        label:SetWidth(PANEL_WIDTH / 2 - 45)
        label:SetJustifyH("LEFT")
        
        checkbox:SetScript("OnClick", function(self)
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter[diff.blizzKey] = self:GetChecked()
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            
            local panel = LFGListFrame and LFGListFrame.SearchPanel
            local currentCategoryID = panel and panel.categoryID
            
            local db = PintaGroupFinderDB or PGF.defaults
            if not db.filter then db.filter = {} end
            if not db.filter.difficulty then db.filter.difficulty = {} end
            db.filter.difficulty[diff.key] = self:GetChecked()
            
            if currentCategoryID then
                PGF.UpdateDungeonFilterPanel(filterPanel, currentCategoryID)
            end
            
            if panel and LFGListSearchPanel_DoSearch then
                LFGListSearchPanel_DoSearch(panel)
            end
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(diff.label .. " Difficulty")
            GameTooltip:AddLine(diff.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        difficultyCheckboxes[diff.key] = checkbox
        difficultyY = difficultyY - 20
    end
    
    yOffset = yOffset - spacing - 10
    
    local playstyleLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    playstyleLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    playstyleLabel:SetText("Playstyle:")
    filterPanel.playstyleLabel = playstyleLabel
    
    local playstyleStartY = yOffset - headerSpacing
    local playstyleCheckboxes = {}

    local playstyle1Name = _G["GROUP_FINDER_GENERAL_PLAYSTYLE1"] or "Learning"
    local playstyle2Name = _G["GROUP_FINDER_GENERAL_PLAYSTYLE2"] or "Relaxed"
    local playstyle3Name = _G["GROUP_FINDER_GENERAL_PLAYSTYLE3"] or "Competitive"
    local playstyle4Name = _G["GROUP_FINDER_GENERAL_PLAYSTYLE4"] or "Carry Offered"
    
    local playstyles = {
        { blizzKey = "generalPlaystyle1", label = playstyle1Name, tooltip = "Show groups with Learning playstyle." },
        { blizzKey = "generalPlaystyle2", label = playstyle2Name, tooltip = "Show groups with Relaxed playstyle." },
        { blizzKey = "generalPlaystyle3", label = playstyle3Name, tooltip = "Show groups with Competitive playstyle." },
        { blizzKey = "generalPlaystyle4", label = playstyle4Name, tooltip = "Show groups offering carries." },
    }
    
    local playstyleY = playstyleStartY
    local playstyleX = 10
    
    for i, playstyle in ipairs(playstyles) do
        local checkbox = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
        checkbox:SetSize(16, 16)
        checkbox:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", playstyleX, playstyleY)
        
        local label = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 3, 0)
        label:SetText(playstyle.label)
        label:SetWidth(PANEL_WIDTH / 2 - 35)
        label:SetJustifyH("LEFT")
        
        checkbox:SetScript("OnClick", function(self)
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter[playstyle.blizzKey] = self:GetChecked()
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            
            local panel = LFGListFrame and LFGListFrame.SearchPanel
            if panel and LFGListSearchPanel_DoSearch then
                LFGListSearchPanel_DoSearch(panel)
            end
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(playstyle.label)
            GameTooltip:AddLine(playstyle.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        playstyleCheckboxes[playstyle.blizzKey] = {
            frame = checkbox,
            label = label,
        }
        playstyleY = playstyleY - 18
    end

    local difficultyHeight = 4 * 20
    local difficultyBottomY = difficultyStartY - difficultyHeight

    local roleYOffset = difficultyBottomY - spacing - 5
    local roleLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    roleLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", PANEL_WIDTH / 2 + 30, roleYOffset)
    roleLabel:SetText("Has Role:")
    filterPanel.roleLabel = roleLabel
    
    local roleStartY = roleYOffset - headerSpacing
    
    local roleCheckboxes = {}
    local roles = {
        { key = "tank", label = "Has Tank", blizzKey = "hasTank", tooltip = "Only show groups that already have a tank." },
        { key = "healer", label = "Has Healer", blizzKey = "hasHealer", tooltip = "Only show groups that already have a healer." },
    }
    
    local roleY = roleStartY
    for _, role in ipairs(roles) do
        local checkbox = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", PANEL_WIDTH / 2 + 30, roleY)
        
        local label = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(role.label)
        
        checkbox:SetScript("OnClick", function(self)
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter[role.blizzKey] = self:GetChecked()
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            
            local db = PintaGroupFinderDB or PGF.defaults
            if not db.filter then db.filter = {} end
            if not db.filter.hasRole then db.filter.hasRole = {} end
            db.filter.hasRole[role.key] = self:GetChecked()
            
            local panel = LFGListFrame and LFGListFrame.SearchPanel
            if panel and LFGListSearchPanel_DoSearch then
                LFGListSearchPanel_DoSearch(panel)
            end
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(role.label)
            GameTooltip:AddLine(role.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        roleCheckboxes[role.key] = {
            frame = checkbox,
            label = label,
        }
        roleY = roleY - 20
    end
    
    filterPanel.playstyleCheckboxes = playstyleCheckboxes
    filterPanel.roleCheckboxes = roleCheckboxes
    
    local function OnEnterPressed(self)
        self:ClearFocus()
        local db = PintaGroupFinderDB or PGF.defaults
        if not db.filter then db.filter = {} end
        
        if self == ratingBox then
            db.filter.minRating = tonumber(self:GetText()) or 0
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter.minimumRating = db.filter.minRating
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            PGF.RefilterResults()
        end
    end
    
    ratingBox:SetScript("OnEnterPressed", OnEnterPressed)
    ratingBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    filterPanel.ratingBox = ratingBox
    filterPanel.roleCheckboxes = roleCheckboxes
    
    local bottomY = math.min(roleY, playstyleY)
    return bottomY - 5
end

