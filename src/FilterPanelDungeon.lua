--[[
    PintaGroupFinder - Dungeon Filter Panel Module
    
    Filter panel for dungeon category with accordion-style collapsible sections.
]]

local addonName, PGF = ...

local dungeonPanel = nil
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local HEADER_HEIGHT = 24
local CONTENT_PADDING = 8

local sections = {}

---Check if a section is expanded.
---@param sectionID string
---@return boolean
local function IsSectionExpanded(sectionID)
    return PintaGroupFinderDB.filter.dungeonAccordionState[sectionID]
end

---Set accordion state for a section.
---@param sectionID string
---@param expanded boolean
local function SetAccordionState(sectionID, expanded)
    PintaGroupFinderDB.filter.dungeonAccordionState[sectionID] = expanded
end

---Recalculate content height and reposition all sections.
local function RecalculateLayout()
    if not dungeonPanel or not dungeonPanel.scrollContent then return end
    
    local yOffset = 0
    
    for _, section in ipairs(sections) do
        -- Position header
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", dungeonPanel.scrollContent, "TOPLEFT", 0, -yOffset)
        section.header:SetPoint("TOPRIGHT", dungeonPanel.scrollContent, "TOPRIGHT", 0, -yOffset)
        
        yOffset = yOffset + HEADER_HEIGHT
        
        -- Position and show/hide content
        if IsSectionExpanded(section.id) then
            section.content:ClearAllPoints()
            section.content:SetPoint("TOPLEFT", dungeonPanel.scrollContent, "TOPLEFT", 0, -yOffset)
            section.content:SetPoint("TOPRIGHT", dungeonPanel.scrollContent, "TOPRIGHT", 0, -yOffset)
            section.content:Show()
            yOffset = yOffset + section.content:GetHeight()
            section.header.arrow:SetText("-")
        else
            section.content:Hide()
            section.header.arrow:SetText("+")
        end
        
        -- Small gap between sections
        yOffset = yOffset + 2
    end
    
    -- Update scroll content height
    dungeonPanel.scrollContent:SetHeight(math.max(1, yOffset))
    
    -- Update scrollbar visibility and range
    if dungeonPanel.scrollBar then
        local scrollFrame = dungeonPanel.scrollFrame
        local visibleHeight = scrollFrame:GetHeight()
        local contentHeight = dungeonPanel.scrollContent:GetHeight()
        
        if contentHeight > visibleHeight then
            dungeonPanel.scrollBar:Show()
            dungeonPanel.scrollBar:SetMinMaxValues(0, contentHeight - visibleHeight)
        else
            dungeonPanel.scrollBar:Hide()
            scrollFrame:SetVerticalScroll(0)
        end
    end
end

---Create a minimal/modern style scrollbar.
---@param parent Frame The scroll frame to attach to
---@return Slider scrollBar
local function CreateMinimalScrollBar(parent)
    local scrollBar = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    scrollBar:SetWidth(8)
    scrollBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 2)
    
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.4, 0.4, 0.4, 0.8)
    thumb:SetSize(8, 40)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript("OnEnter", function(self)
        thumb:SetVertexColor(0.6, 0.6, 0.6, 1)
    end)
    scrollBar:SetScript("OnLeave", function(self)
        thumb:SetVertexColor(0.4, 0.4, 0.4, 0.8)
    end)
    
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetValueStep(1)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        parent:SetVerticalScroll(value)
    end)
    
    return scrollBar
end

---Create an accordion section header.
---@param parent Frame Parent frame (scroll content)
---@param sectionID string Unique section identifier
---@param title string Section title text
---@return Frame header The header frame
local function CreateAccordionHeader(parent, sectionID, title)
    local header = CreateFrame("Button", nil, parent, "BackdropTemplate")
    header:SetHeight(HEADER_HEIGHT)
    
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    header:SetBackdropColor(0.2, 0.2, 0.2, 1)
    header:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local arrow = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    arrow:SetPoint("LEFT", header, "LEFT", 8, 0)
    arrow:SetText(IsSectionExpanded(sectionID) and "-" or "+")
    header.arrow = arrow
    
    local titleText = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
    titleText:SetText(title)
    titleText:SetTextColor(1, 0.82, 0) -- Gold color
    
    header:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.3, 1)
    end)
    header:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 1)
    end)
    
    header:SetScript("OnClick", function(self)
        local newState = not IsSectionExpanded(sectionID)
        SetAccordionState(sectionID, newState)
        RecalculateLayout()
    end)
    
    return header
end

---Create an accordion section content container.
---@param parent Frame Parent frame (scroll content)
---@return Frame content The content frame
local function CreateAccordionContent(parent)
    local content = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    content:SetBackdropColor(0.15, 0.15, 0.15, 1)
    
    return content
end

--------------------------------------------------------------------------------
-- Section 1: Activities (Dungeon List)
--------------------------------------------------------------------------------

---Check if dungeon group has activities matching difficulty filters.
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

---Sort activity groups alphabetically by name.
---@param groupIDs table Array of group IDs
---@return table sortedGroupIDs
local function SortGroupsAlphabetically(groupIDs)
    local sorted = {}
    for _, groupID in ipairs(groupIDs) do
        local name = C_LFGList.GetActivityGroupInfo(groupID) or ""
        table.insert(sorted, { groupID = groupID, name = name })
    end
    
    table.sort(sorted, function(a, b)
        return a.name < b.name
    end)
    
    local result = {}
    for _, entry in ipairs(sorted) do
        table.insert(result, entry.groupID)
    end
    return result
end

---Get difficulty suffix for a dungeon group (e.g., "(N/H/M/M+)").
---@param categoryID number
---@param groupID number
---@return string suffix The difficulty suffix or empty string
local function GetDifficultySuffix(categoryID, groupID)
    local activities = C_LFGList.GetAvailableActivities(categoryID, groupID)
    if not activities then return "" end
    
    local hasNormal = false
    local hasHeroic = false
    local hasMythic = false
    local hasMythicPlus = false
    
    for _, activityID in ipairs(activities) do
        local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
        if activityInfo then
            if activityInfo.isNormalActivity then hasNormal = true end
            if activityInfo.isHeroicActivity then hasHeroic = true end
            if activityInfo.isMythicActivity then hasMythic = true end
            if activityInfo.isMythicPlusActivity then hasMythicPlus = true end
        end
    end
    
    local parts = {}
    if hasNormal then table.insert(parts, "N") end
    if hasHeroic then table.insert(parts, "H") end
    if hasMythic then table.insert(parts, "M") end
    if hasMythicPlus then table.insert(parts, "M+") end
    
    if #parts == 0 then return "" end
    return " |cff888888(" .. table.concat(parts, "/") .. ")|r"
end

---Update dungeon list based on current filters.
local function UpdateDungeonList()
    if not dungeonPanel or not dungeonPanel.activityContent then
        return
    end
    
    local categoryID = PGF.DUNGEON_CATEGORY_ID
    local content = dungeonPanel.activityContent
    local checkboxes = dungeonPanel.activityCheckboxes or {}
    
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
    dungeonPanel.activityCheckboxes = checkboxes
    
    local advancedFilter = C_LFGList.GetAdvancedFilter()
    local showMythicPlus = advancedFilter and advancedFilter.difficultyMythicPlus ~= false
    local showMythic = advancedFilter and advancedFilter.difficultyMythic ~= false
    local showHeroic = advancedFilter and advancedFilter.difficultyHeroic ~= false
    local showNormal = advancedFilter and advancedFilter.difficultyNormal ~= false
    
    local db = PintaGroupFinderDB
    local allowAllDungeons = (db.filter and db.filter.dungeonActivities) == nil
    local selectedGroupIDs = (db.filter and db.filter.dungeonActivities) or {}
    
    local buttonsHeight = dungeonPanel.activityButtonsHeight or 0
    local yPos = CONTENT_PADDING + buttonsHeight
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

    seasonGroupIDs = SortGroupsAlphabetically(seasonGroupIDs)
    expansionGroupIDs = SortGroupsAlphabetically(expansionGroupIDs)

    local seasonCount = 0
    for _, groupID in ipairs(seasonGroupIDs) do
        if GroupHasMatchingDifficulty(categoryID, groupID, showMythicPlus, showMythic, showHeroic, showNormal) then
            local name = C_LFGList.GetActivityGroupInfo(groupID)
            if name then
                local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                checkbox:SetSize(16, 16)
                checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
                
                local suffix = GetDifficultySuffix(categoryID, groupID)
                local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
                label:SetText(name .. suffix)
                label:SetWidth(PANEL_WIDTH - 50)
                label:SetJustifyH("LEFT")
                
                checkbox:SetChecked(allowAllDungeons or selectedGroupIDs[groupID] == true)
                
                checkbox:SetScript("OnClick", function(self)
                    local db = PintaGroupFinderDB
                    if not db.filter then db.filter = {} end
                    
                    local isChecked = self:GetChecked()
                    
                    if isChecked then
                        if not db.filter.dungeonActivities then db.filter.dungeonActivities = {} end
                        db.filter.dungeonActivities[groupID] = true
                    else
                        if db.filter.dungeonActivities == nil then
                            db.filter.dungeonActivities = {}
                            for _, cb in ipairs(dungeonPanel.activityCheckboxes or {}) do
                                if cb.groupID then db.filter.dungeonActivities[cb.groupID] = true end
                            end
                        end
                        db.filter.dungeonActivities[groupID] = nil
                    end
                    
                    PGF.RefilterResults()
                end)
                
                table.insert(checkboxes, { frame = checkbox, label = label, groupID = groupID })
                yPos = yPos + checkboxHeight + spacing
                seasonCount = seasonCount + 1
            end
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
            separator:SetSize(PANEL_WIDTH - 30, 8)
            separator:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
            separator:SetVertexColor(0.5, 0.5, 0.5, 0.5)
            
            table.insert(checkboxes, { separator = separator })
            yPos = yPos + separatorHeight
        end
    end
    
    for _, groupID in ipairs(expansionGroupIDs) do
        if GroupHasMatchingDifficulty(categoryID, groupID, showMythicPlus, showMythic, showHeroic, showNormal) then
            local name = C_LFGList.GetActivityGroupInfo(groupID)
            if name then
                local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                checkbox:SetSize(16, 16)
                checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
                
                local suffix = GetDifficultySuffix(categoryID, groupID)
                local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
                label:SetText(name .. suffix)
                label:SetWidth(PANEL_WIDTH - 50)
                label:SetJustifyH("LEFT")
                
                checkbox:SetChecked(allowAllDungeons or selectedGroupIDs[groupID] == true)
                
                checkbox:SetScript("OnClick", function(self)
                    local db = PintaGroupFinderDB
                    if not db.filter then db.filter = {} end
                    
                    local isChecked = self:GetChecked()
                    
                    if isChecked then
                        if not db.filter.dungeonActivities then db.filter.dungeonActivities = {} end
                        db.filter.dungeonActivities[groupID] = true
                    else
                        if db.filter.dungeonActivities == nil then
                            db.filter.dungeonActivities = {}
                            for _, cb in ipairs(dungeonPanel.activityCheckboxes or {}) do
                                if cb.groupID then db.filter.dungeonActivities[cb.groupID] = true end
                            end
                        end
                        db.filter.dungeonActivities[groupID] = nil
                    end
                    
                    PGF.RefilterResults()
                end)
                
                table.insert(checkboxes, { frame = checkbox, label = label, groupID = groupID })
                yPos = yPos + checkboxHeight + spacing
            end
        end
    end
    
    content:SetHeight(math.max(1, yPos + CONTENT_PADDING))
    
    RecalculateLayout()
end

---Create Activities section.
local function CreateActivitiesSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "activities", PGF.L("SECTION_ACTIVITIES") or "ACTIVITIES")
    local content = CreateAccordionContent(scrollContent)
    
    content:SetHeight(150)
    
    local selectAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    selectAllBtn:SetText(PGF.L("SELECT_ALL") or "Select All")
    selectAllBtn:GetFontString():SetFont(selectAllBtn:GetFontString():GetFont(), 10)
    local selectWidth = selectAllBtn:GetFontString():GetStringWidth() + 16
    selectAllBtn:SetSize(selectWidth, 18)
    selectAllBtn:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    
    local deselectAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    deselectAllBtn:SetText(PGF.L("DESELECT_ALL") or "Deselect All")
    deselectAllBtn:GetFontString():SetFont(deselectAllBtn:GetFontString():GetFont(), 10)
    local deselectWidth = deselectAllBtn:GetFontString():GetStringWidth() + 16
    deselectAllBtn:SetSize(deselectWidth, 18)
    deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 4, 0)
    
    selectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.dungeonActivities = {}
        
        local checkboxes = dungeonPanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.groupID then
                db.filter.dungeonActivities[cb.groupID] = true
                if cb.frame then cb.frame:SetChecked(true) end
            end
        end
        
        PGF.RefilterResults()
    end)
    
    deselectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.dungeonActivities = {}
        
        local checkboxes = dungeonPanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.frame then cb.frame:SetChecked(false) end
        end
        
        PGF.RefilterResults()
    end)
    
    dungeonPanel.activityContent = content
    dungeonPanel.activityCheckboxes = {}
    dungeonPanel.activityButtonsHeight = 18 + CONTENT_PADDING
    
    table.insert(sections, {
        id = "activities",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 2: Difficulty
--------------------------------------------------------------------------------

---Create Difficulty section.
local function CreateDifficultySection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "difficulty", PGF.L("SECTION_DIFFICULTY") or "DIFFICULTY")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    local difficultyCheckboxes = {}
    
    local difficulties = {
        { key = "normal", label = PGF.GetLocalizedDifficultyName("normal"), blizzKey = "difficultyNormal", tooltip = PGF.L("DIFFICULTY_NORMAL_DESC") },
        { key = "heroic", label = PGF.GetLocalizedDifficultyName("heroic"), blizzKey = "difficultyHeroic", tooltip = PGF.L("DIFFICULTY_HEROIC_DESC") },
        { key = "mythic", label = PGF.GetLocalizedDifficultyName("mythic"), blizzKey = "difficultyMythic", tooltip = PGF.L("DIFFICULTY_MYTHIC_DESC") },
        { key = "mythicplus", label = PGF.GetLocalizedDifficultyName("mythicplus"), blizzKey = "difficultyMythicPlus", tooltip = PGF.L("DIFFICULTY_MYTHICPLUS_DESC") },
    }
    
    for _, diff in ipairs(difficulties) do
        local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
        
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(diff.label)
        
        checkbox:SetScript("OnClick", function(self)
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter[diff.blizzKey] = self:GetChecked()
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.difficulty then db.filter.difficulty = {} end
            db.filter.difficulty[diff.key] = self:GetChecked()
            
            UpdateDungeonList()
            
            local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
            if searchPanel and LFGListSearchPanel_DoSearch then
                LFGListSearchPanel_DoSearch(searchPanel)
            end
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(diff.label)
            GameTooltip:AddLine(diff.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        difficultyCheckboxes[diff.key] = checkbox
        y = y + 22
    end
    
    dungeonPanel.difficultyCheckboxes = difficultyCheckboxes
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "difficulty",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 3: Playstyle
--------------------------------------------------------------------------------

---Create Playstyle section.
local function CreatePlaystyleSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "playstyle", PGF.L("SECTION_PLAYSTYLE") or "PLAYSTYLE")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    local playstyleCheckboxes = {}
    
    local playstyles = {
        { blizzKey = "generalPlaystyle1", label = _G["GROUP_FINDER_GENERAL_PLAYSTYLE1"] or "Learning", tooltip = PGF.L("PLAYSTYLE_LEARNING_DESC") },
        { blizzKey = "generalPlaystyle2", label = _G["GROUP_FINDER_GENERAL_PLAYSTYLE2"] or "Relaxed", tooltip = PGF.L("PLAYSTYLE_RELAXED_DESC") },
        { blizzKey = "generalPlaystyle3", label = _G["GROUP_FINDER_GENERAL_PLAYSTYLE3"] or "Competitive", tooltip = PGF.L("PLAYSTYLE_COMPETITIVE_DESC") },
        { blizzKey = "generalPlaystyle4", label = _G["GROUP_FINDER_GENERAL_PLAYSTYLE4"] or "Carry Offered", tooltip = PGF.L("PLAYSTYLE_CARRY_DESC") },
    }
    
    for _, playstyle in ipairs(playstyles) do
        local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
        
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(playstyle.label)
        
        checkbox:SetScript("OnClick", function(self)
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter[playstyle.blizzKey] = self:GetChecked()
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            
            local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
            if searchPanel and LFGListSearchPanel_DoSearch then
                LFGListSearchPanel_DoSearch(searchPanel)
            end
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(playstyle.label)
            GameTooltip:AddLine(playstyle.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        playstyleCheckboxes[playstyle.blizzKey] = { frame = checkbox, label = label }
        y = y + 22
    end
    
    dungeonPanel.playstyleCheckboxes = playstyleCheckboxes
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "playstyle",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 4: Misc (Min Rating + Has Role)
--------------------------------------------------------------------------------

---Create Misc section.
local function CreateMiscSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "misc", PGF.L("SECTION_MISC") or "MISC")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    
    -- Min Rating
    local ratingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    ratingLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    ratingLabel:SetText(PGF.L("MIN_RATING"))
    
    local ratingBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    ratingBox:SetSize(60, 20)
    ratingBox:SetPoint("LEFT", ratingLabel, "RIGHT", 10, 0)
    ratingBox:SetAutoFocus(false)
    ratingBox:SetNumeric(true)
    ratingBox:SetMaxLetters(5)
    
    ratingBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("MIN_RATING_TITLE"))
        GameTooltip:AddLine(PGF.L("MIN_RATING_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ratingBox:SetScript("OnLeave", GameTooltip_Hide)
    
    ratingBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.minRating = tonumber(self:GetText()) or 0
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            advancedFilter.minimumRating = db.filter.minRating
            C_LFGList.SaveAdvancedFilter(advancedFilter)
        end
        PGF.RefilterResults()
    end)
    ratingBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ratingBox:SetScript("OnEditFocusLost", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.minRating = tonumber(self:GetText()) or 0
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            advancedFilter.minimumRating = db.filter.minRating
            C_LFGList.SaveAdvancedFilter(advancedFilter)
        end
    end)
    
    dungeonPanel.ratingBox = ratingBox
    
    y = y + 28
    
    local roleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    roleLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    roleLabel:SetText(PGF.L("HAS_ROLE"))
    y = y + 16
    
    local roleCheckboxes = {}
    local roles = {
        { key = "tank", label = PGF.L("HAS_TANK"), blizzKey = "hasTank", tooltip = PGF.L("HAS_TANK_DESC") },
        { key = "healer", label = PGF.L("HAS_HEALER"), blizzKey = "hasHealer", tooltip = PGF.L("HAS_HEALER_DESC") },
    }
    
    for _, role in ipairs(roles) do
        local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
        
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(role.label)
        
        checkbox:SetScript("OnClick", function(self)
            local advancedFilter = C_LFGList.GetAdvancedFilter()
            if advancedFilter then
                advancedFilter[role.blizzKey] = self:GetChecked()
                C_LFGList.SaveAdvancedFilter(advancedFilter)
            end
            
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.hasRole then db.filter.hasRole = {} end
            db.filter.hasRole[role.key] = self:GetChecked()
            
            local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
            if searchPanel and LFGListSearchPanel_DoSearch then
                LFGListSearchPanel_DoSearch(searchPanel)
            end
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(role.label)
            GameTooltip:AddLine(role.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        roleCheckboxes[role.key] = { frame = checkbox, label = label }
        y = y + 22
    end
    
    dungeonPanel.roleCheckboxes = roleCheckboxes
    
    y = y + 5
    
    -- Hide incompatible groups
    local hideIncompatibleCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    hideIncompatibleCheckbox:SetSize(20, 20)
    hideIncompatibleCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    
    local hideIncompatibleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hideIncompatibleLabel:SetPoint("LEFT", hideIncompatibleCheckbox, "RIGHT", 5, 0)
    hideIncompatibleLabel:SetText(PGF.L("HIDE_INCOMPATIBLE_GROUPS"))
    
    hideIncompatibleCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.hideIncompatibleGroups = self:GetChecked()
        PGF.RefilterResults()
    end)
    
    hideIncompatibleCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("HIDE_INCOMPATIBLE_GROUPS"))
        GameTooltip:AddLine(PGF.L("HIDE_INCOMPATIBLE_GROUPS_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    hideIncompatibleCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    
    dungeonPanel.hideIncompatibleGroupsCheckbox = hideIncompatibleCheckbox
    
    y = y + 22
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "misc",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 5: Quick Apply
--------------------------------------------------------------------------------

---Create Quick Apply section.
local function CreateQuickApplySection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "quickApply", PGF.L("SECTION_QUICK_APPLY") or "QUICK APPLY")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    
    local quickApplyEnable = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    quickApplyEnable:SetSize(20, 20)
    quickApplyEnable:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    
    local enableLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    enableLabel:SetPoint("LEFT", quickApplyEnable, "RIGHT", 5, 0)
    enableLabel:SetText(PGF.L("ENABLE"))
    
    quickApplyEnable:SetScript("OnClick", function(self)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        charDB.quickApply.enabled = self:GetChecked()
    end)
    
    quickApplyEnable:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("ENABLE_QUICK_APPLY"))
        GameTooltip:AddLine(PGF.L("ENABLE_QUICK_APPLY_DESC"), 1, 1, 1, true)
        GameTooltip:AddLine(PGF.L("ENABLE_QUICK_APPLY_SHIFT"), 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    quickApplyEnable:SetScript("OnLeave", GameTooltip_Hide)
    
    y = y + 24
    
    local rolesLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rolesLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    rolesLabel:SetText(PGF.L("ROLES"))
    
    local quickApplyRoleCheckboxes = {}
    local roleButtons = {
        { key = "tank", label = "T" },
        { key = "healer", label = "H" },
        { key = "damage", label = "D" },
    }
    
    local roleX = 55
    for _, role in ipairs(roleButtons) do
        local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        checkbox:SetSize(16, 16)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", roleX, -y)
        
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
        label:SetText(role.label)
        
        checkbox:SetScript("OnClick", function(self)
            local charDB = PintaGroupFinderCharDB or PGF.charDefaults
            if not charDB.quickApply then charDB.quickApply = {} end
            if not charDB.quickApply.roles then charDB.quickApply.roles = {} end
            charDB.quickApply.roles[role.key] = self:GetChecked()
            
            local leader = false
            local tank = charDB.quickApply.roles.tank == true
            local healer = charDB.quickApply.roles.healer == true
            local dps = charDB.quickApply.roles.damage == true
            SetLFGRoles(leader, tank, healer, dps)
        end)
        
        quickApplyRoleCheckboxes[role.key] = checkbox
        roleX = roleX + 35
    end
    
    y = y + 24
    
    local noteLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    noteLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    noteLabel:SetText(PGF.L("NOTE"))
    
    local noteBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    noteBox:SetSize(PANEL_WIDTH - 70, 20)
    noteBox:SetPoint("LEFT", noteLabel, "RIGHT", 10, 0)
    noteBox:SetAutoFocus(false)
    noteBox:SetMaxLetters(60)
    
    noteBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        charDB.quickApply.note = self:GetText()
    end)
    
    noteBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    noteBox:SetScript("OnEditFocusLost", function(self)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        charDB.quickApply.note = self:GetText()
    end)
    
    noteBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(PGF.L("APPLICATION_NOTE"))
        GameTooltip:AddLine(PGF.L("APPLICATION_NOTE_DESC"), 1, 1, 1, true)
        GameTooltip:AddLine(PGF.L("APPLICATION_NOTE_PERSIST"), 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    noteBox:SetScript("OnLeave", GameTooltip_Hide)
    
    y = y + 24
    
    local autoAcceptCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    autoAcceptCheckbox:SetSize(20, 20)
    autoAcceptCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    
    local autoAcceptLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    autoAcceptLabel:SetPoint("LEFT", autoAcceptCheckbox, "RIGHT", 5, 0)
    autoAcceptLabel:SetText(PGF.L("AUTO_ACCEPT_PARTY"))
    
    autoAcceptCheckbox:SetScript("OnClick", function(self)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        charDB.quickApply.autoAcceptParty = self:GetChecked()
    end)
    
    autoAcceptCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("AUTO_ACCEPT_PARTY_TITLE"))
        GameTooltip:AddLine(PGF.L("AUTO_ACCEPT_PARTY_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    autoAcceptCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    
    y = y + 24
    
    dungeonPanel.quickApplyEnable = quickApplyEnable
    dungeonPanel.quickApplyRoleCheckboxes = quickApplyRoleCheckboxes
    dungeonPanel.quickApplyNoteBox = noteBox
    dungeonPanel.quickApplyAutoAccept = autoAcceptCheckbox
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "quickApply",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 6: Settings
--------------------------------------------------------------------------------

local dungeonSortOptions = {
    { value = "age", label = PGF.L("SORT_AGE") },
    { value = "rating", label = PGF.L("SORT_RATING") },
    { value = "ilvl", label = PGF.L("SORT_ILVL") },
    { value = "name", label = PGF.L("SORT_NAME") },
}

local function GetSortSettings()
    local db = PintaGroupFinderDB
    return db.filter and db.filter.dungeonSortSettings or PGF.defaults.filter.dungeonSortSettings
end

---Create Settings section.
local function CreateSettingsSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "settings", PGF.L("SECTION_SETTINGS") or "SETTINGS")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    local ui = PintaGroupFinderDB.ui or PGF.defaults.ui

    -- Show Leader Icon Checkbox
    local showLeaderIconCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    showLeaderIconCheckbox:SetSize(20, 20)
    showLeaderIconCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    local showLeaderIconLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    showLeaderIconLabel:SetPoint("LEFT", showLeaderIconCheckbox, "RIGHT", 5, 0)
    showLeaderIconLabel:SetText(PGF.L("SHOW_LEADER_ICON"))
    showLeaderIconCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.ui then db.ui = {} end
        for k, v in pairs(PGF.defaults.ui) do
            if db.ui[k] == nil then db.ui[k] = v end
        end
        db.ui.showLeaderIcon = self:GetChecked()
        PGF.RefilterResults()
    end)
    showLeaderIconCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("SHOW_LEADER_ICON"))
        GameTooltip:AddLine(PGF.L("SHOW_LEADER_ICON_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showLeaderIconCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    showLeaderIconCheckbox:SetChecked(ui.showLeaderIcon ~= false)
    dungeonPanel.showLeaderIconCheckbox = showLeaderIconCheckbox
    y = y + 24

    -- Show Dungeon Spec Icons Checkbox
    local showDungeonSpecIconsCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    showDungeonSpecIconsCheckbox:SetSize(20, 20)
    showDungeonSpecIconsCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    local showDungeonSpecIconsLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    showDungeonSpecIconsLabel:SetPoint("LEFT", showDungeonSpecIconsCheckbox, "RIGHT", 5, 0)
    showDungeonSpecIconsLabel:SetText(PGF.L("SHOW_DUNGEON_SPEC_ICONS"))
    showDungeonSpecIconsCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.ui then db.ui = {} end
        for k, v in pairs(PGF.defaults.ui) do
            if db.ui[k] == nil then db.ui[k] = v end
        end
        db.ui.showDungeonSpecIcons = self:GetChecked()
        PGF.RefilterResults()
    end)
    showDungeonSpecIconsCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("SHOW_DUNGEON_SPEC_ICONS"))
        GameTooltip:AddLine(PGF.L("SHOW_DUNGEON_SPEC_ICONS_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showDungeonSpecIconsCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    showDungeonSpecIconsCheckbox:SetChecked(ui.showDungeonSpecIcons ~= false)
    dungeonPanel.showDungeonSpecIconsCheckbox = showDungeonSpecIconsCheckbox
    y = y + 24

    -- Show Leader Rating Checkbox
    local showLeaderRatingCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    showLeaderRatingCheckbox:SetSize(20, 20)
    showLeaderRatingCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    local showLeaderRatingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    showLeaderRatingLabel:SetPoint("LEFT", showLeaderRatingCheckbox, "RIGHT", 5, 0)
    showLeaderRatingLabel:SetText(PGF.L("SHOW_LEADER_RATING"))
    showLeaderRatingCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.ui then db.ui = {} end
        for k, v in pairs(PGF.defaults.ui) do
            if db.ui[k] == nil then db.ui[k] = v end
        end
        db.ui.showLeaderRating = self:GetChecked()
        PGF.RefilterResults()
    end)
    showLeaderRatingCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("SHOW_LEADER_RATING"))
        GameTooltip:AddLine(PGF.L("SHOW_LEADER_RATING_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showLeaderRatingCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    showLeaderRatingCheckbox:SetChecked(ui.showLeaderRating ~= false)
    dungeonPanel.showLeaderRatingCheckbox = showLeaderRatingCheckbox
    y = y + 24

    -- Disable Custom Sorting Checkbox
    local disableCustomSortingCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    disableCustomSortingCheckbox:SetSize(20, 20)
    disableCustomSortingCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

    local disableCustomSortingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    disableCustomSortingLabel:SetPoint("LEFT", disableCustomSortingCheckbox, "RIGHT", 5, 0)
    disableCustomSortingLabel:SetText(PGF.L("DISABLE_CUSTOM_SORTING"))

    local function UpdateDropdownStates()
        local settings = GetSortSettings()
        local disabled = settings.disableCustomSorting == true

        if dungeonPanel.primarySortDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(dungeonPanel.primarySortDropdown)
            else
                UIDropDownMenu_EnableDropDown(dungeonPanel.primarySortDropdown)
            end
        end

        if dungeonPanel.primaryDirDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(dungeonPanel.primaryDirDropdown)
            else
                UIDropDownMenu_EnableDropDown(dungeonPanel.primaryDirDropdown)
            end
        end

        if dungeonPanel.secondarySortDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(dungeonPanel.secondarySortDropdown)
            else
                UIDropDownMenu_EnableDropDown(dungeonPanel.secondarySortDropdown)
            end
        end

        if dungeonPanel.secondaryDirDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(dungeonPanel.secondaryDirDropdown)
            else
                UIDropDownMenu_EnableDropDown(dungeonPanel.secondaryDirDropdown)
            end
        end
    end

    dungeonPanel.UpdateDropdownStates = UpdateDropdownStates

    disableCustomSortingCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.dungeonSortSettings then
            db.filter.dungeonSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.dungeonSortSettings) do
                db.filter.dungeonSortSettings[k] = v
            end
        end
        db.filter.dungeonSortSettings.disableCustomSorting = self:GetChecked()
        UpdateDropdownStates()
        PGF.RefilterResults()
    end)

    disableCustomSortingCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("DISABLE_CUSTOM_SORTING"))
        GameTooltip:AddLine(PGF.L("DISABLE_CUSTOM_SORTING_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    disableCustomSortingCheckbox:SetScript("OnLeave", GameTooltip_Hide)

    local settings = GetSortSettings()
    disableCustomSortingCheckbox:SetChecked(settings.disableCustomSorting ~= false)

    dungeonPanel.disableCustomSortingCheckbox = disableCustomSortingCheckbox

    y = y + 24
    
    -- Primary Sort
    local primarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    primarySortLabel:SetText(PGF.L("SORT_PRIMARY"))
    
    local primarySortDropdown = CreateFrame("Frame", "PGFDungeonPrimarySortDropdown", content, "UIDropDownMenuTemplate")
    primarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    UIDropDownMenu_SetWidth(primarySortDropdown, 120)
    
    local function SetPrimarySort(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.dungeonSortSettings then
            db.filter.dungeonSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.dungeonSortSettings) do
                db.filter.dungeonSortSettings[k] = v
            end
        end
        db.filter.dungeonSortSettings.primarySort = value
        PGF.RefilterResults()
    end
    
    local function PrimarySortOnClick(self, arg1)
        SetPrimarySort(arg1)
        UIDropDownMenu_SetSelectedValue(primarySortDropdown, arg1)
        for _, opt in ipairs(dungeonSortOptions) do
            if opt.value == arg1 then
                UIDropDownMenu_SetText(primarySortDropdown, opt.label)
                break
            end
        end
    end
    
    UIDropDownMenu_Initialize(primarySortDropdown, function(self, level)
        local settings = GetSortSettings()
        local currentSort = settings.primarySort or "age"
        
        for _, opt in ipairs(dungeonSortOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.label
            info.value = opt.value
            info.arg1 = opt.value
            info.func = PrimarySortOnClick
            info.checked = currentSort == opt.value
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local settings = GetSortSettings()
    local currentPrimarySort = settings.primarySort or "age"
    UIDropDownMenu_SetSelectedValue(primarySortDropdown, currentPrimarySort)
    for _, opt in ipairs(dungeonSortOptions) do
        if opt.value == currentPrimarySort then
            UIDropDownMenu_SetText(primarySortDropdown, opt.label)
            break
        end
    end
    
    dungeonPanel.primarySortDropdown = primarySortDropdown
    
    -- Primary Sort Direction
    local primaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    primaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))
    
    local primaryDirDropdown = CreateFrame("Frame", "PGFDungeonPrimaryDirDropdown", content, "UIDropDownMenuTemplate")
    primaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 135, -y - 14)
    UIDropDownMenu_SetWidth(primaryDirDropdown, 80)
    
    local function SetPrimarySortDirection(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.dungeonSortSettings then
            db.filter.dungeonSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.dungeonSortSettings) do
                db.filter.dungeonSortSettings[k] = v
            end
        end
        db.filter.dungeonSortSettings.primarySortDirection = value
        PGF.RefilterResults()
    end
    
    local function PrimaryDirOnClick(self, arg1)
        SetPrimarySortDirection(arg1)
        UIDropDownMenu_SetSelectedValue(primaryDirDropdown, arg1)
        UIDropDownMenu_SetText(primaryDirDropdown, arg1 == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end
    
    UIDropDownMenu_Initialize(primaryDirDropdown, function(self, level)
        local settings = GetSortSettings()
        local currentDir = settings.primarySortDirection or "asc"
        
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_ASC")
        info.value = "asc"
        info.arg1 = "asc"
        info.func = PrimaryDirOnClick
        info.checked = currentDir == "asc"
        UIDropDownMenu_AddButton(info)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_DESC")
        info.value = "desc"
        info.arg1 = "desc"
        info.func = PrimaryDirOnClick
        info.checked = currentDir == "desc"
        UIDropDownMenu_AddButton(info)
    end)
    
    local currentPrimaryDir = settings.primarySortDirection or "asc"
    UIDropDownMenu_SetSelectedValue(primaryDirDropdown, currentPrimaryDir)
    UIDropDownMenu_SetText(primaryDirDropdown, currentPrimaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    
    dungeonPanel.primaryDirDropdown = primaryDirDropdown
    
    y = y + 50
    
    -- Secondary Sort
    local secondarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    secondarySortLabel:SetText(PGF.L("SORT_SECONDARY"))
    
    local secondarySortDropdown = CreateFrame("Frame", "PGFDungeonSecondarySortDropdown", content, "UIDropDownMenuTemplate")
    secondarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    UIDropDownMenu_SetWidth(secondarySortDropdown, 120)
    
    local function SetSecondarySort(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.dungeonSortSettings then
            db.filter.dungeonSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.dungeonSortSettings) do
                db.filter.dungeonSortSettings[k] = v
            end
        end
        db.filter.dungeonSortSettings.secondarySort = value ~= "none" and value or nil
        PGF.RefilterResults()
    end
    
    local function SecondarySortOnClick(self, arg1)
        SetSecondarySort(arg1)
        UIDropDownMenu_SetSelectedValue(secondarySortDropdown, arg1)
        if arg1 == "none" then
            UIDropDownMenu_SetText(secondarySortDropdown, PGF.L("SORT_NONE"))
        else
            for _, opt in ipairs(dungeonSortOptions) do
                if opt.value == arg1 then
                    UIDropDownMenu_SetText(secondarySortDropdown, opt.label)
                    break
                end
            end
        end
    end
    
    UIDropDownMenu_Initialize(secondarySortDropdown, function(self, level)
        local settings = GetSortSettings()
        local currentSort = settings.secondarySort
        
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_NONE")
        info.value = "none"
        info.arg1 = "none"
        info.func = SecondarySortOnClick
        info.checked = not settings.secondarySort
        UIDropDownMenu_AddButton(info)
        
        for _, opt in ipairs(dungeonSortOptions) do
            info = UIDropDownMenu_CreateInfo()
            info.text = opt.label
            info.value = opt.value
            info.arg1 = opt.value
            info.func = SecondarySortOnClick
            info.checked = currentSort == opt.value
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local currentSecondarySort = settings.secondarySort
    UIDropDownMenu_SetSelectedValue(secondarySortDropdown, currentSecondarySort or "none")
        if currentSecondarySort then
            for _, opt in ipairs(dungeonSortOptions) do
                if opt.value == currentSecondarySort then
                    UIDropDownMenu_SetText(secondarySortDropdown, opt.label)
                    break
                end
            end
        else
            UIDropDownMenu_SetText(secondarySortDropdown, PGF.L("SORT_NONE"))
        end
    
    dungeonPanel.secondarySortDropdown = secondarySortDropdown
    
    -- Secondary Sort Direction
    local secondaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    secondaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))
    
    local secondaryDirDropdown = CreateFrame("Frame", "PGFDungeonSecondaryDirDropdown", content, "UIDropDownMenuTemplate")
    secondaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 135, -y - 14)
    UIDropDownMenu_SetWidth(secondaryDirDropdown, 80)
    
    local function SetSecondarySortDirection(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.dungeonSortSettings then
            db.filter.dungeonSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.dungeonSortSettings) do
                db.filter.dungeonSortSettings[k] = v
            end
        end
        db.filter.dungeonSortSettings.secondarySortDirection = value
        PGF.RefilterResults()
    end
    
    local function SecondaryDirOnClick(self, arg1)
        SetSecondarySortDirection(arg1)
        UIDropDownMenu_SetSelectedValue(secondaryDirDropdown, arg1)
        UIDropDownMenu_SetText(secondaryDirDropdown, arg1 == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end
    
    UIDropDownMenu_Initialize(secondaryDirDropdown, function(self, level)
        local settings = GetSortSettings()
        local currentDir = settings.secondarySortDirection or "desc"
        
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_ASC")
        info.value = "asc"
        info.arg1 = "asc"
        info.func = SecondaryDirOnClick
        info.checked = currentDir == "asc"
        UIDropDownMenu_AddButton(info)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_DESC")
        info.value = "desc"
        info.arg1 = "desc"
        info.func = SecondaryDirOnClick
        info.checked = currentDir == "desc"
        UIDropDownMenu_AddButton(info)
    end)
    
    local currentSecondaryDir = settings.secondarySortDirection or "desc"
    UIDropDownMenu_SetSelectedValue(secondaryDirDropdown, currentSecondaryDir)
    UIDropDownMenu_SetText(secondaryDirDropdown, currentSecondaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    
    dungeonPanel.secondaryDirDropdown = secondaryDirDropdown
    
    y = y + 50
    
    -- Set initial dropdown states
    UpdateDropdownStates()
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "settings",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Main Panel Creation
--------------------------------------------------------------------------------

---Create the dungeon filter panel.
local function CreateDungeonFilterPanel()
    if dungeonPanel then
        return dungeonPanel
    end
    
    local parent = PVEFrame
    if not parent then
        return nil
    end
    
    dungeonPanel = CreateFrame("Frame", "PGDungeonFilterPanel", parent, "BackdropTemplate")
    dungeonPanel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    
    if LFGListFrame then
        dungeonPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
    else
        dungeonPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -75)
    end
    
    dungeonPanel:SetFrameStrata("HIGH")
    dungeonPanel:SetFrameLevel(100)
    
    dungeonPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dungeonPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dungeonPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local scrollFrameContainer = CreateFrame("Frame", nil, dungeonPanel)
    scrollFrameContainer:SetPoint("TOPLEFT", dungeonPanel, "TOPLEFT", 8, -8)
    scrollFrameContainer:SetPoint("BOTTOMRIGHT", dungeonPanel, "BOTTOMRIGHT", -4, 8)
    scrollFrameContainer:SetClipsChildren(true)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer)
    scrollFrame:SetAllPoints()
    dungeonPanel.scrollFrame = scrollFrame
    
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(PANEL_WIDTH - 20)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)
    dungeonPanel.scrollContent = scrollContent
    
    local scrollBar = CreateMinimalScrollBar(scrollFrame)
    dungeonPanel.scrollBar = scrollBar
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 20
        
        local newValue = current - (delta * step)
        newValue = math.max(min, math.min(max, newValue))
        scrollBar:SetValue(newValue)
    end)
    
    scrollContent:EnableMouseWheel(true)
    scrollContent:SetScript("OnMouseWheel", function(self, delta)
        scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta)
    end)
    
    wipe(sections)
    CreateActivitiesSection(scrollContent)
    CreateDifficultySection(scrollContent)
    CreatePlaystyleSection(scrollContent)
    CreateMiscSection(scrollContent)
    CreateQuickApplySection(scrollContent)
    CreateSettingsSection(scrollContent)
    
    RecalculateLayout()
    
    return dungeonPanel
end

---Update panel UI from saved settings.
function PGF.UpdateDungeonPanel()
    if not dungeonPanel then
        return
    end
    
    if dungeonPanel.difficultyCheckboxes then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            local mapping = {
                difficultyNormal = "normal",
                difficultyHeroic = "heroic",
                difficultyMythic = "mythic",
                difficultyMythicPlus = "mythicplus",
            }
            
            for blizzKey, ourKey in pairs(mapping) do
                local checkbox = dungeonPanel.difficultyCheckboxes[ourKey]
                if checkbox then
                    checkbox:SetChecked(advancedFilter[blizzKey] ~= false)
                end
            end
        end
    end
    
    if dungeonPanel.playstyleCheckboxes then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            for blizzKey, checkboxData in pairs(dungeonPanel.playstyleCheckboxes) do
                if checkboxData and checkboxData.frame then
                    checkboxData.frame:SetChecked(advancedFilter[blizzKey] == true)
                end
            end
        end
    end
    
    if dungeonPanel.roleCheckboxes then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            local mapping = { hasTank = "tank", hasHealer = "healer" }
            for blizzKey, ourKey in pairs(mapping) do
                local checkboxData = dungeonPanel.roleCheckboxes[ourKey]
                if checkboxData and checkboxData.frame then
                    checkboxData.frame:SetChecked(advancedFilter[blizzKey] == true)
                end
            end
        end
    end
    
    if dungeonPanel.ratingBox then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        local db = PintaGroupFinderDB
        local filter = db.filter or {}
        if advancedFilter and advancedFilter.minimumRating then
            dungeonPanel.ratingBox:SetText(advancedFilter.minimumRating > 0 and tostring(advancedFilter.minimumRating) or "")
        else
            dungeonPanel.ratingBox:SetText(filter.minRating and filter.minRating > 0 and tostring(filter.minRating) or "")
        end
    end
    
    if dungeonPanel.hideIncompatibleGroupsCheckbox then
        local db = PintaGroupFinderDB
        local filter = db.filter or {}
        dungeonPanel.hideIncompatibleGroupsCheckbox:SetChecked(filter.hideIncompatibleGroups == true)
    end
    
    UpdateDungeonList()
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
    
    if dungeonPanel.quickApplyEnable then
        dungeonPanel.quickApplyEnable:SetChecked(quickApply.enabled == true)
    end
    
    if dungeonPanel.quickApplyRoleCheckboxes then
        local _, tank, healer, dps = GetLFGRoles()
        local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
        
        if dungeonPanel.quickApplyRoleCheckboxes.tank then
            dungeonPanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
            if availTank then dungeonPanel.quickApplyRoleCheckboxes.tank:SetChecked(tank) end
        end
        if dungeonPanel.quickApplyRoleCheckboxes.healer then
            dungeonPanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
            if availHealer then dungeonPanel.quickApplyRoleCheckboxes.healer:SetChecked(healer) end
        end
        if dungeonPanel.quickApplyRoleCheckboxes.damage then
            dungeonPanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
            if availDPS then dungeonPanel.quickApplyRoleCheckboxes.damage:SetChecked(dps) end
        end
    end
    
    if dungeonPanel.quickApplyNoteBox then
        dungeonPanel.quickApplyNoteBox:SetText(quickApply.note or "")
    end
    
    if dungeonPanel.quickApplyAutoAccept then
        dungeonPanel.quickApplyAutoAccept:SetChecked(quickApply.autoAcceptParty ~= false)
    end

    if dungeonPanel.disableCustomSortingCheckbox then
        local settings = GetSortSettings()
        dungeonPanel.disableCustomSortingCheckbox:SetChecked(settings.disableCustomSorting ~= false)
    end

    if dungeonPanel.UpdateDropdownStates then
        dungeonPanel.UpdateDropdownStates()
    end

    if dungeonPanel.primarySortDropdown then
        local settings = GetSortSettings()
        local currentPrimarySort = settings.primarySort or "age"
        UIDropDownMenu_SetSelectedValue(dungeonPanel.primarySortDropdown, currentPrimarySort)
        for _, opt in ipairs(dungeonSortOptions) do
            if opt.value == currentPrimarySort then
                UIDropDownMenu_SetText(dungeonPanel.primarySortDropdown, opt.label)
                break
            end
        end
    end
    
    if dungeonPanel.primaryDirDropdown then
        local settings = GetSortSettings()
        local currentPrimaryDir = settings.primarySortDirection or "asc"
        UIDropDownMenu_SetSelectedValue(dungeonPanel.primaryDirDropdown, currentPrimaryDir)
        UIDropDownMenu_SetText(dungeonPanel.primaryDirDropdown, currentPrimaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end
    
    if dungeonPanel.secondarySortDropdown then
        local settings = GetSortSettings()
        local currentSecondarySort = settings.secondarySort
        UIDropDownMenu_SetSelectedValue(dungeonPanel.secondarySortDropdown, currentSecondarySort or "none")
        if currentSecondarySort then
            for _, opt in ipairs(dungeonSortOptions) do
                if opt.value == currentSecondarySort then
                    UIDropDownMenu_SetText(dungeonPanel.secondarySortDropdown, opt.label)
                    break
                end
            end
        else
            UIDropDownMenu_SetText(dungeonPanel.secondarySortDropdown, PGF.L("SORT_NONE"))
        end
    end
    
    if dungeonPanel.secondaryDirDropdown then
        local settings = GetSortSettings()
        local currentSecondaryDir = settings.secondarySortDirection or "desc"
        UIDropDownMenu_SetSelectedValue(dungeonPanel.secondaryDirDropdown, currentSecondaryDir)
        UIDropDownMenu_SetText(dungeonPanel.secondaryDirDropdown, currentSecondaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end
    
    RecalculateLayout()
end

---Show or hide the dungeon panel.
---@param show boolean
function PGF.ShowDungeonPanel(show)
    if show then
        if not dungeonPanel then
            CreateDungeonFilterPanel()
        end
        if dungeonPanel then
            dungeonPanel:Show()
            PGF.UpdateDungeonPanel()
        end
    else
        if dungeonPanel then
            dungeonPanel:Hide()
        end
    end
end

---Get the dungeon panel frame.
---@return Frame?
function PGF.GetDungeonPanel()
    return dungeonPanel
end

---Initialize the dungeon filter panel.
function PGF.InitializeDungeonPanel()
    CreateDungeonFilterPanel()
end
