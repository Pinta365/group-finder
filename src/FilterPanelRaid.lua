--[[
    PintaGroupFinder - Raid Filter Panel Module
    
    Filter panel for raid category with accordion-style collapsible sections.
]]

local addonName, PGF = ...

local raidPanel = nil
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local CONTENT_PADDING = 8

local sections = {}

local function IsSectionExpanded(sectionID)
    return PintaGroupFinderDB.filter.raidAccordionState[sectionID]
end

local function SetAccordionState(sectionID, expanded)
    PintaGroupFinderDB.filter.raidAccordionState[sectionID] = expanded
end

local function RecalculateLayout()
    PGF.RecalculateLayout(raidPanel, sections, IsSectionExpanded)
end

local function MakeAccordionHeader(parent, sectionID, title)
    return PGF.CreateAccordionHeader(parent, sectionID, title,
        IsSectionExpanded, SetAccordionState, RecalculateLayout)
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
local function CreateRaidGroupCheckbox(content, groupID, yPos, selectedGroupIDs, allowAllRaids, checkboxHeight, spacing)
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
    
    checkbox:SetChecked(allowAllRaids or selectedGroupIDs[groupID] == true)
    
    checkbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        
        local isChecked = self:GetChecked()
        
        if isChecked then
            if not db.filter.raidActivities then db.filter.raidActivities = {} end
            db.filter.raidActivities[groupID] = true
        else
            if db.filter.raidActivities == nil then
                db.filter.raidActivities = {}
                for _, cb in ipairs(raidPanel.activityCheckboxes or {}) do
                    local k = cb.groupID or cb.storageKey
                    if k then db.filter.raidActivities[k] = true end
                end
            end
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
local function CreateRaidActivityCheckbox(content, activityID, yPos, selectedActivities, allowAllRaids, checkboxHeight, spacing)
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
    checkbox:SetChecked(allowAllRaids or selectedActivities[storageKey] == true)
    
    checkbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        
        local isChecked = self:GetChecked()
        
        if isChecked then
            if not db.filter.raidActivities then db.filter.raidActivities = {} end
            db.filter.raidActivities[storageKey] = true
        else
            if db.filter.raidActivities == nil then
                db.filter.raidActivities = {}
                for _, cb in ipairs(raidPanel.activityCheckboxes or {}) do
                    local k = cb.groupID or cb.storageKey
                    if k then db.filter.raidActivities[k] = true end
                end
            end
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
    
    local allowAllRaids = (db.filter and db.filter.raidActivities) == nil
    local selectedGroupIDs = (db.filter and db.filter.raidActivities) or {}
    
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
            yPos = CreateRaidGroupCheckbox(content, groupID, yPos, selectedGroupIDs, allowAllRaids, checkboxHeight, spacing)
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
            yPos = CreateRaidActivityCheckbox(content, activityID, yPos, selectedGroupIDs, allowAllRaids, checkboxHeight, spacing)
        end
    end
    
    content:SetHeight(math.max(CONTENT_PADDING * 2, yPos + CONTENT_PADDING))
    RecalculateLayout()
end

---Create Activities section.
local function CreateActivitiesSection(scrollContent)
    local header = MakeAccordionHeader(scrollContent, "activities", PGF.L("SECTION_ACTIVITIES") or "ACTIVITIES")
    local content = PGF.CreateAccordionContent(scrollContent)
    
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
        PGF.EnsureFilter(db)
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
        PGF.EnsureFilter(db)
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
    local header = MakeAccordionHeader(scrollContent, "bossFilter", PGF.L("SECTION_BOSS_FILTER") or "BOSS FILTER")
    local content = PGF.CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    
    -- Filter type dropdown
    local filterLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    filterLabel:SetText(PGF.L("BOSS_FILTER") or "Filter:")
    
    local bossFilterOptions = {
        { value = "any", label = PGF.L("BOSS_FILTER_ANY") },
        { value = "fresh", label = PGF.L("BOSS_FILTER_FRESH") },
        { value = "partial", label = PGF.L("BOSS_FILTER_PARTIAL") },
    }
    local dropdown = PGF.CreateRadioDropdown(
        content, "PGFRaidBossFilterDropdown", 150, bossFilterOptions,
        function()
            local db = PintaGroupFinderDB
            return (db.filter and db.filter.raidBossFilter) or "any"
        end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidBossFilter = value
            PGF.RefilterResults()
        end)
    dropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 14)
    
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
    local header = MakeAccordionHeader(scrollContent, "difficulty", PGF.L("SECTION_DIFFICULTY") or "DIFFICULTY")
    local content = PGF.CreateAccordionContent(scrollContent)
    
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
            PGF.EnsureFilter(db)
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
    local header = MakeAccordionHeader(scrollContent, "playstyle", PGF.L("SECTION_PLAYSTYLE") or "PLAYSTYLE")
    local content = PGF.CreateAccordionContent(scrollContent)
    
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
            PGF.EnsureFilter(db)
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
    local header = MakeAccordionHeader(scrollContent, "roleFiltering", PGF.L("SECTION_ROLE_FILTERING") or "ROLE FILTERING")
    local content = PGF.CreateAccordionContent(scrollContent)
    
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
        
        local operatorOptions = {
            { value = ">=", label = PGF.L("OP_GTE") },
            { value = "<=", label = PGF.L("OP_LTE") },
            { value = "=", label = PGF.L("OP_EQ") },
        }
        local operatorDropdown = PGF.CreateRadioDropdown(
            content, nil, 50, operatorOptions,
            function()
                local db = PintaGroupFinderDB
                local req = db.filter and db.filter.raidRoleRequirements and db.filter.raidRoleRequirements[role.key]
                return (req and req.operator) or ">="
            end,
            function(value)
                local db = PintaGroupFinderDB
                PGF.EnsureFilter(db)
                db.filter.raidRoleRequirements[role.key].operator = value
                PGF.RefilterResults()
            end)
        local contentWidth = PANEL_WIDTH - 20 -- scrollContent width
        local centerX = contentWidth / 2 + 20
        operatorDropdown:SetPoint("TOP", content, "TOPLEFT", centerX, -y + 2)
        valueEditbox:SetAutoFocus(false)
        valueEditbox:SetNumeric(true)
        valueEditbox:SetMaxLetters(2)
        local efFile, _, efFlags = valueEditbox:GetFont()
        if efFile then valueEditbox:SetFont(efFile, 9, efFlags) end
        valueEditbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        valueEditbox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            local value = tonumber(self:GetText()) or 0
            value = math.max(0, math.min(30, value))
            self:SetText(tostring(value))
            
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidRoleRequirements[role.key].value = value
            PGF.RefilterResults()
        end)
        valueEditbox:SetScript("OnEditFocusLost", function(self)
            local value = tonumber(self:GetText()) or 0
            value = math.max(0, math.min(30, value))
            self:SetText(tostring(value))
            
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidRoleRequirements[role.key].value = value
            PGF.RefilterResults()
        end)
        
        enableCheckbox:SetScript("OnClick", function(self)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
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
    PGF.CreateQuickApplySection(scrollContent, raidPanel, sections, MakeAccordionHeader)
end

--------------------------------------------------------------------------------
-- Section 7: Settings
--------------------------------------------------------------------------------

local raidSortOptions = {
    { value = "age", label = PGF.L("SORT_AGE") },
    { value = "groupSize", label = PGF.L("SORT_GROUP_SIZE") },
    { value = "ilvl", label = PGF.L("SORT_ILVL") },
    { value = "name", label = PGF.L("SORT_NAME") },
}

local function GetSortSettingsRaid()
    local db = PintaGroupFinderDB
    return db.filter and db.filter.raidSortSettings or PGF.defaults.filter.raidSortSettings
end

---Create Settings section.
local function CreateSettingsSection(scrollContent)
    local header = MakeAccordionHeader(scrollContent, "settings", PGF.L("SECTION_SETTINGS") or "SETTINGS")
    local content = PGF.CreateAccordionContent(scrollContent)
    
    local y = CONTENT_PADDING
    local ui = PintaGroupFinderDB.ui or PGF.defaults.ui

    -- Show Raid Spec Indicators Checkbox
    local showRaidSpecCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    showRaidSpecCheckbox:SetSize(20, 20)
    showRaidSpecCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    local showRaidSpecLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    showRaidSpecLabel:SetPoint("LEFT", showRaidSpecCheckbox, "RIGHT", 5, 0)
    showRaidSpecLabel:SetText(PGF.L("SHOW_RAID_SPEC_INDICATORS"))
    showRaidSpecCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.ui then db.ui = {} end
        for k, v in pairs(PGF.defaults.ui) do
            if db.ui[k] == nil then db.ui[k] = v end
        end
        db.ui.showRaidSpecIndicators = self:GetChecked()
        PGF.RefilterResults()
    end)
    showRaidSpecCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("SHOW_RAID_SPEC_INDICATORS"))
        GameTooltip:AddLine(PGF.L("SHOW_RAID_SPEC_INDICATORS_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showRaidSpecCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    showRaidSpecCheckbox:SetChecked(ui.showRaidSpecIndicators ~= false)
    raidPanel.showRaidSpecCheckbox = showRaidSpecCheckbox
    y = y + 24

    -- Disable Custom Sorting Checkbox
    local disableCustomSortingCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    disableCustomSortingCheckbox:SetSize(20, 20)
    disableCustomSortingCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    
    local disableCustomSortingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    disableCustomSortingLabel:SetPoint("LEFT", disableCustomSortingCheckbox, "RIGHT", 5, 0)
    disableCustomSortingLabel:SetText(PGF.L("DISABLE_CUSTOM_SORTING"))
    
    local function UpdateDropdownStates()
        local settings = GetSortSettingsRaid()
        local disabled = settings.disableCustomSorting == true
        
        if raidPanel.primarySortDropdown then
            raidPanel.primarySortDropdown:SetEnabled(not disabled)
        end

        if raidPanel.primaryDirDropdown then
            raidPanel.primaryDirDropdown:SetEnabled(not disabled)
        end

        if raidPanel.secondarySortDropdown then
            raidPanel.secondarySortDropdown:SetEnabled(not disabled)
        end

        if raidPanel.secondaryDirDropdown then
            raidPanel.secondaryDirDropdown:SetEnabled(not disabled)
        end
    end
    
    disableCustomSortingCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        db.filter.raidSortSettings.disableCustomSorting = self:GetChecked()
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
    
    -- Initialize checkbox state
    local settings = GetSortSettingsRaid()
    disableCustomSortingCheckbox:SetChecked(settings.disableCustomSorting ~= false)
    
    raidPanel.disableCustomSortingCheckbox = disableCustomSortingCheckbox

    local movePendingGroupsToTopCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    movePendingGroupsToTopCheckbox:SetSize(20, 20)
    movePendingGroupsToTopCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

    local movePendingGroupsToTopLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    movePendingGroupsToTopLabel:SetPoint("LEFT", movePendingGroupsToTopCheckbox, "RIGHT", 5, 0)
    movePendingGroupsToTopLabel:SetText(PGF.L("MOVE_PENDING_GROUPS_TO_TOP"))

    movePendingGroupsToTopCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        db.filter.raidSortSettings.movePendingGroupsToTop = self:GetChecked()
        PGF.RefilterResults()
    end)

    movePendingGroupsToTopCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("MOVE_PENDING_GROUPS_TO_TOP"))
        GameTooltip:AddLine(PGF.L("MOVE_PENDING_GROUPS_TO_TOP_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    movePendingGroupsToTopCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    movePendingGroupsToTopCheckbox:SetChecked(settings.movePendingGroupsToTop ~= false)

    raidPanel.movePendingGroupsToTopCheckbox = movePendingGroupsToTopCheckbox
    disableCustomSortingCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 24)
    raidPanel.UpdateDropdownStates = UpdateDropdownStates
    
    y = y + 48
    
    -- Primary Sort
    local primarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    primarySortLabel:SetText(PGF.L("SORT_PRIMARY"))
    
    local primarySortDropdown = PGF.CreateRadioDropdown(
        content, "PGFRaidPrimarySortDropdown", 120, raidSortOptions,
        function() return GetSortSettingsRaid().primarySort or "age" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidSortSettings.primarySort = value
            PGF.RefilterResults()
        end)
    primarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 14)
    
    raidPanel.primarySortDropdown = primarySortDropdown
    
    -- Primary Sort Direction
    local primaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    primaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))
    
    local dirOptions = {
        { value = "asc", label = PGF.L("SORT_ASC") },
        { value = "desc", label = PGF.L("SORT_DESC") },
    }
    local primaryDirDropdown = PGF.CreateRadioDropdown(
        content, "PGFRaidPrimaryDirDropdown", 80, dirOptions,
        function() return GetSortSettingsRaid().primarySortDirection or "asc" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidSortSettings.primarySortDirection = value
            PGF.RefilterResults()
        end)
    primaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y - 14)
    
    raidPanel.primaryDirDropdown = primaryDirDropdown
    
    y = y + 50
    
    -- Secondary Sort
    local secondarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    secondarySortLabel:SetText(PGF.L("SORT_SECONDARY"))
    
    local secondarySortOptions = { { value = "none", label = PGF.L("SORT_NONE") } }
    for _, opt in ipairs(raidSortOptions) do
        secondarySortOptions[#secondarySortOptions + 1] = opt
    end
    local secondarySortDropdown = PGF.CreateRadioDropdown(
        content, "PGFRaidSecondarySortDropdown", 120, secondarySortOptions,
        function() return GetSortSettingsRaid().secondarySort or "none" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidSortSettings.secondarySort = value ~= "none" and value or nil
            PGF.RefilterResults()
        end)
    secondarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 14)
    
    raidPanel.secondarySortDropdown = secondarySortDropdown
    
    -- Secondary Sort Direction
    local secondaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    secondaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))
    
    local secondaryDirDropdown = PGF.CreateRadioDropdown(
        content, "PGFRaidSecondaryDirDropdown", 80, dirOptions,
        function() return GetSortSettingsRaid().secondarySortDirection or "desc" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.raidSortSettings.secondarySortDirection = value
            PGF.RefilterResults()
        end)
    secondaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y - 14)
    
    raidPanel.secondaryDirDropdown = secondaryDirDropdown
    
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
    
    local scrollBar = PGF.CreateMinimalScrollBar(scrollFrame)
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
    CreateSettingsSection(scrollContent)
    
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
                if reqData.operatorDropdown then
                    reqData.operatorDropdown:GenerateMenu()
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
                        reqData.operatorDropdown:GenerateMenu()
                    end
                    if reqData.valueEditbox then
                        reqData.valueEditbox:SetText(tostring(def.value or 0))
                    end
                end
            end
        end
    end

    if raidPanel.bossFilterDropdown then
        raidPanel.bossFilterDropdown:GenerateMenu()
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
    
    if raidPanel.quickApplyAutoAccept then
        raidPanel.quickApplyAutoAccept:SetChecked(quickApply.autoAcceptParty ~= false)
    end
    
    if raidPanel.disableCustomSortingCheckbox then
        local settings = GetSortSettingsRaid()
        raidPanel.disableCustomSortingCheckbox:SetChecked(settings.disableCustomSorting ~= false)
    end

    if raidPanel.movePendingGroupsToTopCheckbox then
        local settings = GetSortSettingsRaid()
        raidPanel.movePendingGroupsToTopCheckbox:SetChecked(settings.movePendingGroupsToTop ~= false)
    end
    
    if raidPanel.UpdateDropdownStates then
        raidPanel.UpdateDropdownStates()
    end

    if raidPanel.primarySortDropdown then
        raidPanel.primarySortDropdown:GenerateMenu()
    end

    if raidPanel.primaryDirDropdown then
        raidPanel.primaryDirDropdown:GenerateMenu()
    end

    if raidPanel.secondarySortDropdown then
        raidPanel.secondarySortDropdown:GenerateMenu()
    end

    if raidPanel.secondaryDirDropdown then
        raidPanel.secondaryDirDropdown:GenerateMenu()
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
