--[[
    PintaGroupFinder - Raid Filter Panel Module
    
    Filter panel for raid category with accordion-style collapsible sections.
]]

local addonName, PGF = ...

local raidPanel = nil
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local HEADER_HEIGHT = 24
local CONTENT_PADDING = 8

local sections = {}

---Check if a section is expanded.
---@param sectionID string
---@return boolean
local function IsSectionExpanded(sectionID)
    return PintaGroupFinderDB.filter.raidAccordionState[sectionID]
end

---Set accordion state for a section.
---@param sectionID string
---@param expanded boolean
local function SetAccordionState(sectionID, expanded)
    PintaGroupFinderDB.filter.raidAccordionState[sectionID] = expanded
end

---Recalculate content height and reposition all sections.
local function RecalculateLayout()
    if not raidPanel or not raidPanel.scrollContent then return end
    
    local yOffset = 0
    
    for _, section in ipairs(sections) do
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", raidPanel.scrollContent, "TOPLEFT", 0, -yOffset)
        section.header:SetPoint("TOPRIGHT", raidPanel.scrollContent, "TOPRIGHT", 0, -yOffset)
        
        yOffset = yOffset + HEADER_HEIGHT
        
        if IsSectionExpanded(section.id) then
            section.content:ClearAllPoints()
            section.content:SetPoint("TOPLEFT", raidPanel.scrollContent, "TOPLEFT", 0, -yOffset)
            section.content:SetPoint("TOPRIGHT", raidPanel.scrollContent, "TOPRIGHT", 0, -yOffset)
            section.content:Show()
            yOffset = yOffset + section.content:GetHeight()
            section.header.arrow:SetText("-")
        else
            section.content:Hide()
            section.header.arrow:SetText("+")
        end
        
        yOffset = yOffset + 2
    end
    
    raidPanel.scrollContent:SetHeight(math.max(1, yOffset))
    
    if raidPanel.scrollBar then
        local scrollFrame = raidPanel.scrollFrame
        local visibleHeight = scrollFrame:GetHeight()
        local contentHeight = raidPanel.scrollContent:GetHeight()
        
        if contentHeight > visibleHeight then
            raidPanel.scrollBar:Show()
            raidPanel.scrollBar:SetMinMaxValues(0, contentHeight - visibleHeight)
        else
            raidPanel.scrollBar:Hide()
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
    thumb:SetSize(6, 40)
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

---Check if raid group has activities matching difficulty filters.
---For raids, uses difficultyID (14=Normal, 15=Heroic, 16=Mythic) since boolean flags are always false.
local function GroupHasMatchingDifficulty(categoryID, groupID, showMythic, showHeroic, showNormal)
    local activities = C_LFGList.GetAvailableActivities(categoryID, groupID)
    if not activities or #activities == 0 then 
        return false 
    end

    if not showMythic and not showHeroic and not showNormal then
        return true
    end
    
    for _, activityID in ipairs(activities) do
        local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
        if activityInfo then
            local difficultyID = activityInfo.difficultyID
            if (showNormal and difficultyID == 14) or
               (showHeroic and difficultyID == 15) or
               (showMythic and difficultyID == 16) then
                return true
            end
        end
    end
    return false
end

---Get the max level and highest activity ID for a group (for sorting).
---@param categoryID number
---@param groupID number
---@return number maxLevel
---@return number maxActivityID
local function GetGroupSortInfo(categoryID, groupID)
    local activities = C_LFGList.GetAvailableActivities(categoryID, groupID)
    local maxLevel = 0
    local maxActivityID = 0
    
    if activities then
        for _, activityID in ipairs(activities) do
            local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
            if activityInfo then
                local level = activityInfo.maxLevelSuggestion or activityInfo.minLevel or 0
                if level > maxLevel then
                    maxLevel = level
                end
                if activityID > maxActivityID then
                    maxActivityID = activityID
                end
            end
        end
    end
    
    return maxLevel, maxActivityID
end

---Sort activity groups by level (descending), then by ID (descending).
---@param categoryID number
---@param groupIDs table Array of group IDs
---@return table sortedGroupIDs
local function SortGroupsByLevel(categoryID, groupIDs)
    local sorted = {}
    for _, groupID in ipairs(groupIDs) do
        local maxLevel, maxActivityID = GetGroupSortInfo(categoryID, groupID)
        table.insert(sorted, { groupID = groupID, level = maxLevel, activityID = maxActivityID })
    end
    
    table.sort(sorted, function(a, b)
        if a.level ~= b.level then
            return a.level > b.level
        end
        return a.activityID > b.activityID
    end)
    
    local result = {}
    for _, entry in ipairs(sorted) do
        table.insert(result, entry.groupID)
    end
    return result
end

---Check if current raid category is for current expansion or legacy.
---@return boolean isCurrentExpansion True if Recommended (current expansion), false if NotRecommended (legacy)
local function IsCurrentExpansionCategory()
    local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
    local filters = searchPanel and searchPanel.filters or 0
    
    if bit and bit.band then
        if bit.band(filters, Enum.LFGListFilter.Recommended) ~= 0 then
            return true
        end
        if bit.band(filters, Enum.LFGListFilter.NotRecommended) ~= 0 then
            return false
        end
    end
    
    return true
end

--------------------------------------------------------------------------------
-- Section 1: Activities
--------------------------------------------------------------------------------

---Create raid checkbox for an activity group.
local function CreateRaidGroupCheckbox(content, groupID, yPos, selectedGroupIDs, checkboxHeight, spacing)
    if not groupID then return yPos end
    local name = C_LFGList.GetActivityGroupInfo(groupID)
    if not name then return yPos end
    
    local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    checkbox:SetSize(16, 16)
    checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
    
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(name)
    label:SetWidth(PANEL_WIDTH - 50)
    label:SetJustifyH("LEFT")
    
    checkbox:SetChecked(selectedGroupIDs[groupID] == true)
    
    checkbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.raidActivities then db.filter.raidActivities = {} end
        
        local isChecked = self:GetChecked()
        
        if isChecked then
            db.filter.raidActivities[groupID] = true
        else
            db.filter.raidActivities[groupID] = nil
        end
        
        PGF.RefilterResults()
    end)
    
    if raidPanel and raidPanel.activityCheckboxes then
        table.insert(raidPanel.activityCheckboxes, {
            frame = checkbox,
            label = label,
            groupID = groupID,
        })
    end
    
    return yPos + checkboxHeight + spacing
end

---Create raid checkbox for a standalone activity (like World Bosses).
local function CreateRaidActivityCheckbox(content, activityID, yPos, selectedActivities, checkboxHeight, spacing)
    if not activityID then return yPos end
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    if not activityInfo or not activityInfo.fullName then return yPos end
    
    local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    checkbox:SetSize(16, 16)
    checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
    
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(activityInfo.fullName)
    label:SetWidth(PANEL_WIDTH - 50)
    label:SetJustifyH("LEFT")
    
    local storageKey = -activityID
    checkbox:SetChecked(selectedActivities[storageKey] == true)
    
    checkbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.raidActivities then db.filter.raidActivities = {} end
        
        local isChecked = self:GetChecked()
        
        if isChecked then
            db.filter.raidActivities[storageKey] = true
        else
            db.filter.raidActivities[storageKey] = nil
        end
        
        PGF.RefilterResults()
    end)
    
    if raidPanel and raidPanel.activityCheckboxes then
        table.insert(raidPanel.activityCheckboxes, {
            frame = checkbox,
            label = label,
            activityID = activityID,
            storageKey = storageKey,
        })
    end
    
    return yPos + checkboxHeight + spacing
end

---Update raid list in activities section.
local function UpdateRaidList()
    if not raidPanel or not raidPanel.activityContent then
        return
    end
    
    local categoryID = PGF.RAID_CATEGORY_ID
    local content = raidPanel.activityContent
    local checkboxes = raidPanel.activityCheckboxes or {}
    
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
        end
    end
    wipe(checkboxes)
    raidPanel.activityCheckboxes = checkboxes
    
    if raidPanel.activitySeparator then
        raidPanel.activitySeparator:Hide()
        raidPanel.activitySeparator:ClearAllPoints()
        raidPanel.activitySeparator = nil
    end
    
    local db = PintaGroupFinderDB
    local raidDifficulty = db.filter and db.filter.raidDifficulty or {}
    local showMythic = raidDifficulty.mythic ~= false
    local showHeroic = raidDifficulty.heroic ~= false
    local showNormal = raidDifficulty.normal ~= false
    
    local raidActivities = db.filter and db.filter.raidActivities or {}
    local selectedGroupIDs = raidActivities
    
    local buttonsHeight = raidPanel.activityButtonsHeight or 0
    local yPos = CONTENT_PADDING + buttonsHeight
    local checkboxHeight = 20
    local spacing = 2
    
    local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
    local baseFilters = (searchPanel and searchPanel.preferredFilters) or Enum.LFGListFilter.PvE
    local groupIDs = {}
    
    local isCurrentExpansion = IsCurrentExpansionCategory()
    
    local standaloneActivities = {}
    
    if isCurrentExpansion then
        if Enum.LFGListFilter.Recommended and bit and bit.bor then
            local filter = bit.bor(baseFilters, Enum.LFGListFilter.Recommended)
            groupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, filter) or {}
            standaloneActivities = C_LFGList.GetAvailableActivities(categoryID, 0, filter) or {}
        else
            groupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, baseFilters) or {}
            standaloneActivities = C_LFGList.GetAvailableActivities(categoryID, 0, baseFilters) or {}
        end
    else
        if Enum.LFGListFilter.NotRecommended and bit and bit.bor then
            local filter = bit.bor(baseFilters, Enum.LFGListFilter.NotRecommended)
            groupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, filter) or {}
            standaloneActivities = C_LFGList.GetAvailableActivities(categoryID, 0, filter) or {}
        else
            groupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, baseFilters) or {}
            standaloneActivities = C_LFGList.GetAvailableActivities(categoryID, 0, baseFilters) or {}
        end
    end
    
    groupIDs = SortGroupsByLevel(categoryID, groupIDs)
    
    local groupCount = 0
    for _, groupID in ipairs(groupIDs) do
        if GroupHasMatchingDifficulty(categoryID, groupID, showMythic, showHeroic, showNormal) then
            yPos = CreateRaidGroupCheckbox(content, groupID, yPos, selectedGroupIDs, checkboxHeight, spacing)
            groupCount = groupCount + 1
        end
    end

    if isCurrentExpansion and #standaloneActivities > 0 then
        if groupCount > 0 then
            local separator = content:CreateTexture(nil, "ARTWORK")
            separator:SetHeight(1)
            separator:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
            separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", -CONTENT_PADDING, -yPos)
            separator:SetColorTexture(0.4, 0.4, 0.4, 0.5)
            raidPanel.activitySeparator = separator
            yPos = yPos + 8
        end
        
        for _, activityID in ipairs(standaloneActivities) do
            yPos = CreateRaidActivityCheckbox(content, activityID, yPos, selectedGroupIDs, checkboxHeight, spacing)
        end
    end
    
    content:SetHeight(math.max(CONTENT_PADDING * 2, yPos + CONTENT_PADDING))
    RecalculateLayout()
end

---Create Activities section.
local function CreateActivitiesSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "activities", PGF.L("SECTION_ACTIVITIES") or "ACTIVITIES")
    local content = CreateAccordionContent(scrollContent)
    
    content:SetHeight(CONTENT_PADDING * 2 + 100)    
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
        if not db.filter.raidActivities then db.filter.raidActivities = {} end
        
        local checkboxes = raidPanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.groupID then
                db.filter.raidActivities[cb.groupID] = true
            elseif cb.storageKey then
                db.filter.raidActivities[cb.storageKey] = true
            end
            if cb.frame then cb.frame:SetChecked(true) end
        end
        
        PGF.RefilterResults()
    end)
    
    deselectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.raidActivities = {}
        
        local checkboxes = raidPanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.frame then cb.frame:SetChecked(false) end
        end
        
        PGF.RefilterResults()
    end)
    
    raidPanel.activityContent = content
    raidPanel.activityCheckboxes = {}
    raidPanel.activityButtonsHeight = 18 + CONTENT_PADDING
    
    table.insert(sections, {
        id = "activities",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 2: Boss Filter
--------------------------------------------------------------------------------

---Create Boss Filter section.
local function CreateBossFilterSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "bossFilter", PGF.L("SECTION_BOSS_FILTER") or "BOSS FILTER")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    
    -- Filter type dropdown
    local filterLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    filterLabel:SetText(PGF.L("BOSS_FILTER") or "Filter:")
    
    local dropdown = CreateFrame("Frame", "PGFRaidBossFilterDropdown", content, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    
    UIDropDownMenu_SetWidth(dropdown, 150)
    
    local function GetBossFilter()
        local db = PintaGroupFinderDB
        return (db.filter and db.filter.raidBossFilter) or "any"
    end
    
    local function SetBossFilter(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.raidBossFilter = value
    end
    
    local function BossFilterOnClick(self, arg1)
        SetBossFilter(arg1)
        UIDropDownMenu_SetSelectedValue(dropdown, arg1)
        UIDropDownMenu_SetText(dropdown, 
            arg1 == "fresh" and PGF.L("BOSS_FILTER_FRESH") or
            arg1 == "partial" and PGF.L("BOSS_FILTER_PARTIAL") or
            PGF.L("BOSS_FILTER_ANY"))
        
        PGF.RefilterResults()
    end
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local currentFilter = GetBossFilter()
        
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("BOSS_FILTER_ANY")
        info.value = "any"
        info.arg1 = "any"
        info.func = BossFilterOnClick
        info.checked = currentFilter == "any"
        UIDropDownMenu_AddButton(info)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("BOSS_FILTER_FRESH")
        info.value = "fresh"
        info.arg1 = "fresh"
        info.func = BossFilterOnClick
        info.checked = currentFilter == "fresh"
        UIDropDownMenu_AddButton(info)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("BOSS_FILTER_PARTIAL")
        info.value = "partial"
        info.arg1 = "partial"
        info.func = BossFilterOnClick
        info.checked = currentFilter == "partial"
        UIDropDownMenu_AddButton(info)
    end)
    
    local currentFilter = GetBossFilter()
    UIDropDownMenu_SetSelectedValue(dropdown, currentFilter)
    UIDropDownMenu_SetText(dropdown, 
        currentFilter == "fresh" and PGF.L("BOSS_FILTER_FRESH") or
        currentFilter == "partial" and PGF.L("BOSS_FILTER_PARTIAL") or
        PGF.L("BOSS_FILTER_ANY"))
    
    raidPanel.bossFilterDropdown = dropdown
    
    y = y + 50
    
    -- TODO: Individual boss checkboxes will be added here in future
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "bossFilter",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 3: Difficulty
--------------------------------------------------------------------------------

---Create Difficulty section.
local function CreateDifficultySection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "difficulty", PGF.L("SECTION_DIFFICULTY") or "DIFFICULTY")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    local difficultyCheckboxes = {}
    
    local difficulties = {
        { key = "normal", label = PGF.GetLocalizedDifficultyName("normal"), tooltip = PGF.L("DIFFICULTY_NORMAL_DESC") },
        { key = "heroic", label = PGF.GetLocalizedDifficultyName("heroic"), tooltip = PGF.L("DIFFICULTY_HEROIC_DESC") },
        { key = "mythic", label = PGF.GetLocalizedDifficultyName("mythic"), tooltip = PGF.L("DIFFICULTY_MYTHIC_DESC") },
    }
    
    for _, diff in ipairs(difficulties) do
        local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
        
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(diff.label)
        
        checkbox:SetScript("OnClick", function(self)
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.raidDifficulty then db.filter.raidDifficulty = {} end
            db.filter.raidDifficulty[diff.key] = self:GetChecked()
            
            UpdateRaidList()
            PGF.RefilterResults()
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(diff.label .. " Difficulty")
            GameTooltip:AddLine(diff.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        difficultyCheckboxes[diff.key] = checkbox
        y = y + 22
    end
    
    raidPanel.difficultyCheckboxes = difficultyCheckboxes
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "difficulty",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 4: Playstyle
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
        checkbox:SetSize(16, 16)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
        
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 3, 0)
        label:SetText(playstyle.label)
        
        checkbox:SetScript("OnClick", function(self)
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.raidPlaystyle then db.filter.raidPlaystyle = {} end
            db.filter.raidPlaystyle[playstyle.blizzKey] = self:GetChecked()
            
            PGF.RefilterResults()
        end)
        
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(playstyle.label)
            GameTooltip:AddLine(playstyle.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
        
        playstyleCheckboxes[playstyle.blizzKey] = { frame = checkbox, label = label }
        y = y + 20
    end
    
    raidPanel.playstyleCheckboxes = playstyleCheckboxes
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "playstyle",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 5: Role Filtering
--------------------------------------------------------------------------------

---Create Role Filtering section.
local function CreateRoleFilteringSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "roleFiltering", PGF.L("SECTION_ROLE_FILTERING") or "ROLE FILTERING")
    local content = CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    
    local roleReqLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    roleReqLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    roleReqLabel:SetText(PGF.L("ROLE_REQUIREMENTS"))
    y = y + 16
    
    local roleRequirements = {}
    local roleReqRoles = {
        { key = "tank", label = PGF.L("HAS_TANK") },
        { key = "healer", label = PGF.L("HAS_HEALER") },
        { key = "dps", label = "DPS" },
    }
    
    for _, role in ipairs(roleReqRoles) do
        local enableCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        enableCheckbox:SetSize(20, 20)
        enableCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
        
        local roleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        roleLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 5, 0)
        roleLabel:SetText(role.label)
        
        local valueEditbox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        valueEditbox:SetSize(40, 20)
        valueEditbox:SetPoint("TOPRIGHT", content, "TOPRIGHT", -CONTENT_PADDING, -y)
        
        local operatorDropdown = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
        local contentWidth = PANEL_WIDTH - 20 -- scrollContent width
        local centerX = contentWidth / 2 + 20
        operatorDropdown:SetPoint("TOP", content, "TOPLEFT", centerX, -y +2)
        UIDropDownMenu_SetWidth(operatorDropdown, 50)
        UIDropDownMenu_SetText(operatorDropdown, PGF.L("OP_GTE"))
        
        UIDropDownMenu_Initialize(operatorDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local operators = {
                { value = ">=", label = PGF.L("OP_GTE") },
                { value = "<=", label = PGF.L("OP_LTE") },
                { value = "=", label = PGF.L("OP_EQ") },
            }
            for _, op in ipairs(operators) do
                info.text = op.label
                info.value = op.value
                info.notCheckable = true
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(operatorDropdown, op.value)
                    UIDropDownMenu_SetText(operatorDropdown, op.label)
                    
                    local db = PintaGroupFinderDB
                    if not db.filter then db.filter = {} end
                    if not db.filter.raidRoleRequirements then
                        db.filter.raidRoleRequirements = {}
                        for _, r in ipairs(roleReqRoles) do
                            db.filter.raidRoleRequirements[r.key] = {
                                enabled = false,
                                operator = ">=",
                                value = (r.key == "tank" and 1) or (r.key == "healer" and 2) or 0
                            }
                        end
                    end
                    if not db.filter.raidRoleRequirements[role.key] then
                        db.filter.raidRoleRequirements[role.key] = { enabled = false, operator = ">=", value = 1 }
                    end
                    db.filter.raidRoleRequirements[role.key].operator = op.value
                    PGF.RefilterResults()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        valueEditbox:SetAutoFocus(false)
        valueEditbox:SetNumeric(true)
        valueEditbox:SetMaxLetters(2)
        valueEditbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        valueEditbox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            local value = tonumber(self:GetText()) or 0
            value = math.max(0, math.min(30, value))
            self:SetText(tostring(value))
            
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.raidRoleRequirements then
                db.filter.raidRoleRequirements = {}
                for _, r in ipairs(roleReqRoles) do
                    db.filter.raidRoleRequirements[r.key] = {
                        enabled = false,
                        operator = ">=",
                        value = (r.key == "tank" and 1) or (r.key == "healer" and 2) or 0
                    }
                end
            end
            if not db.filter.raidRoleRequirements[role.key] then
                db.filter.raidRoleRequirements[role.key] = { enabled = false, operator = ">=", value = 1 }
            end
            db.filter.raidRoleRequirements[role.key].value = value
            PGF.RefilterResults()
        end)
        valueEditbox:SetScript("OnEditFocusLost", function(self)
            local value = tonumber(self:GetText()) or 0
            value = math.max(0, math.min(30, value))
            self:SetText(tostring(value))
            
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.raidRoleRequirements then
                db.filter.raidRoleRequirements = {}
                for _, r in ipairs(roleReqRoles) do
                    db.filter.raidRoleRequirements[r.key] = {
                        enabled = false,
                        operator = ">=",
                        value = (r.key == "tank" and 1) or (r.key == "healer" and 2) or 0
                    }
                end
            end
            if not db.filter.raidRoleRequirements[role.key] then
                db.filter.raidRoleRequirements[role.key] = { enabled = false, operator = ">=", value = 1 }
            end
            db.filter.raidRoleRequirements[role.key].value = value
            PGF.RefilterResults()
        end)
        
        enableCheckbox:SetScript("OnClick", function(self)
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.raidRoleRequirements then
                db.filter.raidRoleRequirements = {}
                for _, r in ipairs(roleReqRoles) do
                    db.filter.raidRoleRequirements[r.key] = {
                        enabled = false,
                        operator = ">=",
                        value = (r.key == "tank" and 1) or (r.key == "healer" and 2) or 0
                    }
                end
            end
            if not db.filter.raidRoleRequirements[role.key] then
                db.filter.raidRoleRequirements[role.key] = { enabled = false, operator = ">=", value = 1 }
            end
            db.filter.raidRoleRequirements[role.key].enabled = self:GetChecked()
            PGF.RefilterResults()
        end)
        
        roleRequirements[role.key] = {
            enableCheckbox = enableCheckbox,
            operatorDropdown = operatorDropdown,
            valueEditbox = valueEditbox,
            roleLabel = roleLabel,
        }
        
        y = y + 22
    end
    
    raidPanel.roleRequirements = roleRequirements
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "roleFiltering",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 6: Quick Apply
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
    
    y = y + 26
    
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
    
    raidPanel.quickApplyEnable = quickApplyEnable
    raidPanel.quickApplyRoleCheckboxes = quickApplyRoleCheckboxes
    raidPanel.quickApplyNoteBox = noteBox
    raidPanel.quickApplyAutoAccept = autoAcceptCheckbox
    
    content:SetHeight(y + CONTENT_PADDING)
    
    table.insert(sections, {
        id = "quickApply",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Main Panel Creation
--------------------------------------------------------------------------------

---Create the raid filter panel.
local function CreateRaidFilterPanel()
    if raidPanel then
        return raidPanel
    end
    
    local parent = PVEFrame
    if not parent then
        return nil
    end
    
    raidPanel = CreateFrame("Frame", "PGRaidFilterPanel", parent, "BackdropTemplate")
    raidPanel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    
    if LFGListFrame then
        raidPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
    else
        raidPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -75)
    end
    
    raidPanel:SetFrameStrata("HIGH")
    raidPanel:SetFrameLevel(100)
    
    raidPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    raidPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    raidPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local scrollFrameContainer = CreateFrame("Frame", nil, raidPanel)
    scrollFrameContainer:SetPoint("TOPLEFT", raidPanel, "TOPLEFT", 8, -8)
    scrollFrameContainer:SetPoint("BOTTOMRIGHT", raidPanel, "BOTTOMRIGHT", -4, 8)
    scrollFrameContainer:SetClipsChildren(true)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer)
    scrollFrame:SetAllPoints()
    raidPanel.scrollFrame = scrollFrame
    
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(PANEL_WIDTH - 20)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)
    raidPanel.scrollContent = scrollContent
    
    local scrollBar = CreateMinimalScrollBar(scrollFrame)
    raidPanel.scrollBar = scrollBar
    
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
    CreateBossFilterSection(scrollContent)
    CreateDifficultySection(scrollContent)
    CreatePlaystyleSection(scrollContent)
    CreateRoleFilteringSection(scrollContent)
    CreateQuickApplySection(scrollContent)
    
    RecalculateLayout()
    
    return raidPanel
end

---Update panel UI from saved settings.
function PGF.UpdateRaidPanel()
    if not raidPanel then
        return
    end

    if raidPanel.difficultyCheckboxes then
        local db = PintaGroupFinderDB
        local raidDifficulty = db.filter and db.filter.raidDifficulty or {}
        
        for _, key in ipairs({"normal", "heroic", "mythic"}) do
            local checkbox = raidPanel.difficultyCheckboxes[key]
            if checkbox then
                checkbox:SetChecked(raidDifficulty[key] ~= false)
            end
        end
    end
    
    if raidPanel.playstyleCheckboxes then
        local db = PintaGroupFinderDB
        local raidPlaystyle = db.filter and db.filter.raidPlaystyle or {}
        
        for blizzKey, checkboxData in pairs(raidPanel.playstyleCheckboxes) do
            if checkboxData and checkboxData.frame then
                checkboxData.frame:SetChecked(raidPlaystyle[blizzKey] ~= false)
            end
        end
    end

    if raidPanel.roleRequirements then
        local db = PintaGroupFinderDB
        local roleReqs = db.filter and db.filter.raidRoleRequirements or {}
        
        for role, reqData in pairs(raidPanel.roleRequirements) do
            local req = roleReqs[role]
            if req then
                if reqData.enableCheckbox then
                    reqData.enableCheckbox:SetChecked(req.enabled == true)
                end
                if reqData.operatorDropdown and req.operator then
                    local opLabel = (req.operator == ">=" and PGF.L("OP_GTE")) or
                                   (req.operator == "<=" and PGF.L("OP_LTE")) or
                                   (req.operator == "=" and PGF.L("OP_EQ")) or
                                   PGF.L("OP_GTE")
                    UIDropDownMenu_SetSelectedValue(reqData.operatorDropdown, req.operator)
                    UIDropDownMenu_SetText(reqData.operatorDropdown, opLabel)
                end
                if reqData.valueEditbox then
                    reqData.valueEditbox:SetText(tostring(req.value or 0))
                end
            else
                local defaults = PGF.defaults.filter.raidRoleRequirements
                if defaults and defaults[role] then
                    local def = defaults[role]
                    if reqData.enableCheckbox then
                        reqData.enableCheckbox:SetChecked(def.enabled == true)
                    end
                    if reqData.operatorDropdown then
                        local opLabel = (def.operator == ">=" and PGF.L("OP_GTE")) or
                                       (def.operator == "<=" and PGF.L("OP_LTE")) or
                                       (def.operator == "=" and PGF.L("OP_EQ")) or
                                       PGF.L("OP_GTE")
                        UIDropDownMenu_SetSelectedValue(reqData.operatorDropdown, def.operator)
                        UIDropDownMenu_SetText(reqData.operatorDropdown, opLabel)
                    end
                    if reqData.valueEditbox then
                        reqData.valueEditbox:SetText(tostring(def.value or 0))
                    end
                end
            end
        end
    end

    if raidPanel.bossFilterDropdown then
        local db = PintaGroupFinderDB
        local currentFilter = (db.filter and db.filter.raidBossFilter) or "any"
        UIDropDownMenu_SetSelectedValue(raidPanel.bossFilterDropdown, currentFilter)
        UIDropDownMenu_SetText(raidPanel.bossFilterDropdown, 
            currentFilter == "fresh" and PGF.L("BOSS_FILTER_FRESH") or
            currentFilter == "partial" and PGF.L("BOSS_FILTER_PARTIAL") or
            PGF.L("BOSS_FILTER_ANY"))
    end

    UpdateRaidList()

    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
    
    if raidPanel.quickApplyEnable then
        raidPanel.quickApplyEnable:SetChecked(quickApply.enabled == true)
    end
    
    if raidPanel.quickApplyRoleCheckboxes then
        local _, tank, healer, dps = GetLFGRoles()
        local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
        
        if raidPanel.quickApplyRoleCheckboxes.tank then
            raidPanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
            if availTank then raidPanel.quickApplyRoleCheckboxes.tank:SetChecked(tank) end
        end
        if raidPanel.quickApplyRoleCheckboxes.healer then
            raidPanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
            if availHealer then raidPanel.quickApplyRoleCheckboxes.healer:SetChecked(healer) end
        end
        if raidPanel.quickApplyRoleCheckboxes.damage then
            raidPanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
            if availDPS then raidPanel.quickApplyRoleCheckboxes.damage:SetChecked(dps) end
        end
    end
    
    if raidPanel.quickApplyNoteBox then
        raidPanel.quickApplyNoteBox:SetText(quickApply.note or "")
    end
    
    if raidPanel.quickApplyAutoAccept then
        raidPanel.quickApplyAutoAccept:SetChecked(quickApply.autoAcceptParty ~= false)
    end
    
    RecalculateLayout()
end

---Show or hide the raid panel.
---@param show boolean
function PGF.ShowRaidPanel(show)
    if show then
        if not raidPanel then
            CreateRaidFilterPanel()
        end
        if raidPanel then
            raidPanel:Show()
            PGF.UpdateRaidPanel()
        end
    else
        if raidPanel then
            raidPanel:Hide()
        end
    end
end

---Get the raid panel frame.
---@return Frame?
function PGF.GetRaidPanel()
    return raidPanel
end

---Initialize the raid filter panel.
function PGF.InitializeRaidPanel()
    CreateRaidFilterPanel()
end
