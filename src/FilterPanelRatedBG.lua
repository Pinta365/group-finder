--[[
    PintaGroupFinder - Rated Battleground Filter Panel Module

    Filter panel for rated battleground category (categoryID=9) with accordion-style collapsible sections.
]]

local addonName, PGF = ...

local ratedBGPanel = nil
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local CONTENT_PADDING = 8

local sections = {}

local function IsSectionExpanded(sectionID)
    return PintaGroupFinderDB.filter.ratedBGAccordionState[sectionID]
end

local function SetAccordionState(sectionID, expanded)
    PintaGroupFinderDB.filter.ratedBGAccordionState[sectionID] = expanded
end

local function RecalculateLayout()
    PGF.RecalculateLayout(ratedBGPanel, sections, IsSectionExpanded)
end

local function MakeAccordionHeader(parent, sectionID, title)
    return PGF.CreateAccordionHeader(parent, sectionID, title,
        IsSectionExpanded, SetAccordionState, RecalculateLayout)
end

--------------------------------------------------------------------------------
-- Section 1: Activities
--------------------------------------------------------------------------------

local function SortGroupsAlphabetically(groupIDs)
    local sorted = {}
    for _, groupID in ipairs(groupIDs) do
        local name = C_LFGList.GetActivityGroupInfo(groupID) or ""
        table.insert(sorted, { groupID = groupID, name = name })
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)
    local result = {}
    for _, entry in ipairs(sorted) do table.insert(result, entry.groupID) end
    return result
end

local function UpdateRatedBGList()
    if not ratedBGPanel or not ratedBGPanel.activityContent then return end

    local categoryID = PGF.RATED_BG_CATEGORY_ID
    local content = ratedBGPanel.activityContent
    local checkboxes = ratedBGPanel.activityCheckboxes or {}

    for i = 1, #checkboxes do
        local cb = checkboxes[i]
        if cb then
            if cb.frame then cb.frame:Hide(); cb.frame:ClearAllPoints() end
            if cb.label then cb.label:Hide(); cb.label:ClearAllPoints() end
            if cb.separator then cb.separator:Hide(); cb.separator:ClearAllPoints() end
        end
    end
    wipe(checkboxes)
    ratedBGPanel.activityCheckboxes = checkboxes

    local db = PintaGroupFinderDB
    local allowAll = (db.filter and db.filter.ratedBGActivities) == nil
    local selectedKeys = (db.filter and db.filter.ratedBGActivities) or {}

    local buttonsHeight = ratedBGPanel.activityButtonsHeight or 0
    local yPos = CONTENT_PADDING + buttonsHeight
    local checkboxHeight = 20
    local spacing = 2

    local recFilter = Enum.LFGListFilter and Enum.LFGListFilter.Recommended or 1
    if bit and bit.bor and Enum and Enum.LFGListFilter then
        recFilter = bit.bor(Enum.LFGListFilter.Recommended, Enum.LFGListFilter.PvP)
    end
    local groupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, recFilter) or {}

    local nonRecFilter = Enum.LFGListFilter and Enum.LFGListFilter.NotRecommended or 2
    if bit and bit.bor and Enum and Enum.LFGListFilter then
        nonRecFilter = bit.bor(Enum.LFGListFilter.NotRecommended, Enum.LFGListFilter.PvP)
    end
    local legacyGroupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, nonRecFilter) or {}

    groupIDs = SortGroupsAlphabetically(groupIDs)
    legacyGroupIDs = SortGroupsAlphabetically(legacyGroupIDs)

    local hasGroups = (#groupIDs + #legacyGroupIDs) > 0

    if hasGroups then
        local function AddGroupCheckbox(groupID)
            local name = C_LFGList.GetActivityGroupInfo(groupID)
            if not name then return end

            local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            checkbox:SetSize(16, 16)
            checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)

            local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
            label:SetText(name)
            label:SetWidth(PANEL_WIDTH - 50)
            label:SetJustifyH("LEFT")

            checkbox:SetChecked(allowAll or selectedKeys[groupID] == true)

            checkbox:SetScript("OnClick", function(self)
                local db = PintaGroupFinderDB
                PGF.EnsureFilter(db)
                local isChecked = self:GetChecked()
                if isChecked then
                    if not db.filter.ratedBGActivities then db.filter.ratedBGActivities = {} end
                    db.filter.ratedBGActivities[groupID] = true
                else
                    if db.filter.ratedBGActivities == nil then
                        db.filter.ratedBGActivities = {}
                        for _, cb in ipairs(ratedBGPanel.activityCheckboxes or {}) do
                            if cb.groupID then db.filter.ratedBGActivities[cb.groupID] = true end
                        end
                    end
                    db.filter.ratedBGActivities[groupID] = nil
                end
                PGF.RefilterResults()
            end)

            table.insert(checkboxes, { frame = checkbox, label = label, groupID = groupID })
            yPos = yPos + checkboxHeight + spacing
        end

        for _, groupID in ipairs(groupIDs) do AddGroupCheckbox(groupID) end

        if #groupIDs > 0 and #legacyGroupIDs > 0 then
            local separator = content:CreateTexture(nil, "ARTWORK")
            separator:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
            separator:SetSize(PANEL_WIDTH - 30, 8)
            separator:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
            separator:SetVertexColor(0.5, 0.5, 0.5, 0.5)
            table.insert(checkboxes, { separator = separator })
            yPos = yPos + 10
        end

        for _, groupID in ipairs(legacyGroupIDs) do AddGroupCheckbox(groupID) end
    else
        local activities = C_LFGList.GetAvailableActivities(categoryID, nil) or {}
        for _, actID in ipairs(activities) do
            local actInfo = C_LFGList.GetActivityInfoTable(actID)
            if actInfo then
                local name = actInfo.fullName or actInfo.shortName or tostring(actID)
                local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                checkbox:SetSize(16, 16)
                checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)

                local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
                label:SetText(name)
                label:SetWidth(PANEL_WIDTH - 50)
                label:SetJustifyH("LEFT")

                local negKey = -actID
                checkbox:SetChecked(allowAll or selectedKeys[negKey] == true)

                checkbox:SetScript("OnClick", function(self)
                    local db = PintaGroupFinderDB
                    PGF.EnsureFilter(db)
                    local isChecked = self:GetChecked()
                    if isChecked then
                        if not db.filter.ratedBGActivities then db.filter.ratedBGActivities = {} end
                        db.filter.ratedBGActivities[negKey] = true
                    else
                        if db.filter.ratedBGActivities == nil then
                            db.filter.ratedBGActivities = {}
                            for _, cb in ipairs(ratedBGPanel.activityCheckboxes or {}) do
                                if cb.actID then db.filter.ratedBGActivities[-cb.actID] = true end
                            end
                        end
                        db.filter.ratedBGActivities[negKey] = nil
                    end
                    PGF.RefilterResults()
                end)

                table.insert(checkboxes, { frame = checkbox, label = label, actID = actID })
                yPos = yPos + checkboxHeight + spacing
            end
        end
    end

    content:SetHeight(math.max(1, yPos + CONTENT_PADDING))
    RecalculateLayout()
end

local function CreateActivitiesSection(scrollContent)
    local header = MakeAccordionHeader(scrollContent, "activities", PGF.L("SECTION_ACTIVITIES"))
    local content = PGF.CreateAccordionContent(scrollContent)
    content:SetHeight(150)

    local selectAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    selectAllBtn:SetText(PGF.L("SELECT_ALL"))
    selectAllBtn:GetFontString():SetFont(selectAllBtn:GetFontString():GetFont(), 10)
    selectAllBtn:SetSize(selectAllBtn:GetFontString():GetStringWidth() + 16, 18)
    selectAllBtn:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)

    local deselectAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    deselectAllBtn:SetText(PGF.L("DESELECT_ALL"))
    deselectAllBtn:GetFontString():SetFont(deselectAllBtn:GetFontString():GetFont(), 10)
    deselectAllBtn:SetSize(deselectAllBtn:GetFontString():GetStringWidth() + 16, 18)
    deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 4, 0)

    selectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        db.filter.ratedBGActivities = {}
        for _, cb in ipairs(ratedBGPanel.activityCheckboxes or {}) do
            if cb.groupID then db.filter.ratedBGActivities[cb.groupID] = true; if cb.frame then cb.frame:SetChecked(true) end
            elseif cb.actID then db.filter.ratedBGActivities[-cb.actID] = true; if cb.frame then cb.frame:SetChecked(true) end
            end
        end
        PGF.RefilterResults()
    end)

    deselectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        db.filter.ratedBGActivities = {}
        for _, cb in ipairs(ratedBGPanel.activityCheckboxes or {}) do
            if cb.frame then cb.frame:SetChecked(false) end
        end
        PGF.RefilterResults()
    end)

    ratedBGPanel.activityContent = content
    ratedBGPanel.activityCheckboxes = {}
    ratedBGPanel.activityButtonsHeight = 18 + CONTENT_PADDING

    table.insert(sections, { id = "activities", header = header, content = content })
end

--------------------------------------------------------------------------------
-- Section 2: Rating
--------------------------------------------------------------------------------

local function CreateRatingSection(scrollContent)
    local header = MakeAccordionHeader(scrollContent, "rating", PGF.L("SECTION_PVP_RATING"))
    local content = PGF.CreateAccordionContent(scrollContent)

    local y = CONTENT_PADDING

    local ratingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    ratingLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    ratingLabel:SetText(PGF.L("MIN_PVP_RATING"))

    local ratingBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    ratingBox:SetSize(60, 20)
    ratingBox:SetPoint("LEFT", ratingLabel, "RIGHT", 8, 0)
    ratingBox:SetAutoFocus(false)
    ratingBox:SetNumeric(true)
    ratingBox:SetMaxLetters(5)

    local function SaveRating()
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        local val = math.max(0, tonumber(ratingBox:GetText()) or 0)
        db.filter.ratedBGMinPvpRating = val
        ratingBox:SetText(tostring(val))
        PGF.RefilterResults()
    end

    ratingBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); SaveRating() end)
    ratingBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ratingBox:SetScript("OnEditFocusLost", function(self) SaveRating() end)

    ratingBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("MIN_PVP_RATING"))
        GameTooltip:AddLine(PGF.L("MIN_PVP_RATING_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ratingBox:SetScript("OnLeave", GameTooltip_Hide)

    ratedBGPanel.ratingBox = ratingBox

    y = y + 28
    content:SetHeight(y + CONTENT_PADDING)
    table.insert(sections, { id = "rating", header = header, content = content })
end

--------------------------------------------------------------------------------
-- Section 3: Playstyle
--------------------------------------------------------------------------------

local function CreatePlaystyleSection(scrollContent)
    local header = MakeAccordionHeader(scrollContent, "playstyle", PGF.L("SECTION_PLAYSTYLE"))
    local content = PGF.CreateAccordionContent(scrollContent)

    local y = CONTENT_PADDING
    local playstyleCheckboxes = {}

    local playstyles = {
        { blizzKey = "generalPlaystyle1", label = _G["GROUP_FINDER_GENERAL_PLAYSTYLE1"] or "Learning",    tooltip = PGF.L("PLAYSTYLE_LEARNING_DESC") },
        { blizzKey = "generalPlaystyle2", label = _G["GROUP_FINDER_GENERAL_PLAYSTYLE2"] or "Relaxed",     tooltip = PGF.L("PLAYSTYLE_RELAXED_DESC") },
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
            db.filter.ratedBGPlaystyle[playstyle.blizzKey] = self:GetChecked()
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

    ratedBGPanel.playstyleCheckboxes = playstyleCheckboxes
    content:SetHeight(y + CONTENT_PADDING)
    table.insert(sections, { id = "playstyle", header = header, content = content })
end

--------------------------------------------------------------------------------
-- Section 4: Quick Apply
--------------------------------------------------------------------------------

local function CreateQuickApplySection(scrollContent)
    PGF.CreateQuickApplySection(scrollContent, ratedBGPanel, sections, MakeAccordionHeader)
end

--------------------------------------------------------------------------------
-- Section 5: Settings (Sorting)
--------------------------------------------------------------------------------

local ratedBGSortOptions = {
    { value = "age",       label = PGF.L("SORT_AGE") },
    { value = "groupSize", label = PGF.L("SORT_GROUP_SIZE") },
    { value = "pvpRating", label = PGF.L("SORT_PVP_RATING") },
    { value = "name",      label = PGF.L("SORT_NAME") },
}

local function GetSortSettings()
    local db = PintaGroupFinderDB
    return db.filter and db.filter.ratedBGSortSettings or PGF.defaults.filter.ratedBGSortSettings
end

local function CreateSettingsSection(scrollContent)
    local header = MakeAccordionHeader(scrollContent, "settings", PGF.L("SECTION_SETTINGS"))
    local content = PGF.CreateAccordionContent(scrollContent)

    local y = CONTENT_PADDING

    local specIndCB = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    specIndCB:SetSize(20, 20)
    specIndCB:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    local specIndLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    specIndLabel:SetPoint("LEFT", specIndCB, "RIGHT", 5, 0)
    specIndLabel:SetText(PGF.L("SHOW_RATED_BG_SPEC_INDICATORS"))
    specIndCB:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.ui then db.ui = {} end
        db.ui.showRatedBGSpecIndicators = self:GetChecked()
        PGF.RefilterResults()
    end)
    specIndCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("SHOW_RATED_BG_SPEC_INDICATORS"))
        GameTooltip:AddLine(PGF.L("SHOW_RATED_BG_SPEC_INDICATORS_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    specIndCB:SetScript("OnLeave", GameTooltip_Hide)
    local ui = (PintaGroupFinderDB and PintaGroupFinderDB.ui) or PGF.defaults.ui
    specIndCB:SetChecked(ui.showRatedBGSpecIndicators ~= false)
    ratedBGPanel.showRatedBGSpecIndicatorsCheckbox = specIndCB

    y = y + 24

    local disableCB = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    disableCB:SetSize(20, 20)
    disableCB:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

    local disableLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    disableLabel:SetPoint("LEFT", disableCB, "RIGHT", 5, 0)
    disableLabel:SetText(PGF.L("DISABLE_CUSTOM_SORTING"))

    local function UpdateDropdownStates()
        local s = GetSortSettings()
        local disabled = s.disableCustomSorting == true
        local function toggle(dd)
            if not dd then return end
            dd:SetEnabled(not disabled)
        end
        toggle(ratedBGPanel.primarySortDropdown)
        toggle(ratedBGPanel.primaryDirDropdown)
        toggle(ratedBGPanel.secondarySortDropdown)
        toggle(ratedBGPanel.secondaryDirDropdown)
    end

    ratedBGPanel.UpdateDropdownStates = UpdateDropdownStates

    disableCB:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        db.filter.ratedBGSortSettings.disableCustomSorting = self:GetChecked()
        UpdateDropdownStates()
        PGF.RefilterResults()
    end)
    disableCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("DISABLE_CUSTOM_SORTING"))
        GameTooltip:AddLine(PGF.L("DISABLE_CUSTOM_SORTING_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    disableCB:SetScript("OnLeave", GameTooltip_Hide)

    local settings = GetSortSettings()
    disableCB:SetChecked(settings.disableCustomSorting ~= false)
    ratedBGPanel.disableCustomSortingCheckbox = disableCB

    local movePendingGroupsToTopCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    movePendingGroupsToTopCheckbox:SetSize(20, 20)
    movePendingGroupsToTopCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

    local movePendingGroupsToTopLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    movePendingGroupsToTopLabel:SetPoint("LEFT", movePendingGroupsToTopCheckbox, "RIGHT", 5, 0)
    movePendingGroupsToTopLabel:SetText(PGF.L("MOVE_PENDING_GROUPS_TO_TOP"))

    movePendingGroupsToTopCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        PGF.EnsureFilter(db)
        db.filter.ratedBGSortSettings.movePendingGroupsToTop = self:GetChecked()
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

    ratedBGPanel.movePendingGroupsToTopCheckbox = movePendingGroupsToTopCheckbox
    disableCB:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 24)

    y = y + 48

    -- Primary Sort label
    local primarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    primarySortLabel:SetText(PGF.L("SORT_PRIMARY"))

    local primarySortDropdown = PGF.CreateRadioDropdown(
        content, "PGFRatedBGPrimarySortDropdown", 120, ratedBGSortOptions,
        function() return GetSortSettings().primarySort or "age" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.ratedBGSortSettings.primarySort = value
            PGF.RefilterResults()
        end)
    primarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 14)
    ratedBGPanel.primarySortDropdown = primarySortDropdown

    -- Primary Dir
    local primaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    primaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))

    local dirOptions = {
        { value = "asc", label = PGF.L("SORT_ASC") },
        { value = "desc", label = PGF.L("SORT_DESC") },
    }
    local primaryDirDropdown = PGF.CreateRadioDropdown(
        content, "PGFRatedBGPrimaryDirDropdown", 80, dirOptions,
        function() return GetSortSettings().primarySortDirection or "asc" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.ratedBGSortSettings.primarySortDirection = value
            PGF.RefilterResults()
        end)
    primaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y - 14)
    ratedBGPanel.primaryDirDropdown = primaryDirDropdown

    y = y + 50

    -- Secondary Sort
    local secondarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    secondarySortLabel:SetText(PGF.L("SORT_SECONDARY"))

    local secondarySortOptions = { { value = "none", label = PGF.L("SORT_NONE") } }
    for _, opt in ipairs(ratedBGSortOptions) do
        secondarySortOptions[#secondarySortOptions + 1] = opt
    end
    local secondarySortDropdown = PGF.CreateRadioDropdown(
        content, "PGFRatedBGSecondarySortDropdown", 120, secondarySortOptions,
        function() return GetSortSettings().secondarySort or "none" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.ratedBGSortSettings.secondarySort = value ~= "none" and value or nil
            PGF.RefilterResults()
        end)
    secondarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y - 14)
    ratedBGPanel.secondarySortDropdown = secondarySortDropdown

    -- Secondary Dir
    local secondaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    secondaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))

    local secondaryDirDropdown = PGF.CreateRadioDropdown(
        content, "PGFRatedBGSecondaryDirDropdown", 80, dirOptions,
        function() return GetSortSettings().secondarySortDirection or "asc" end,
        function(value)
            local db = PintaGroupFinderDB
            PGF.EnsureFilter(db)
            db.filter.ratedBGSortSettings.secondarySortDirection = value
            PGF.RefilterResults()
        end)
    secondaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y - 14)
    ratedBGPanel.secondaryDirDropdown = secondaryDirDropdown

    y = y + 50
    UpdateDropdownStates()
    content:SetHeight(y + CONTENT_PADDING)
    table.insert(sections, { id = "settings", header = header, content = content })
end

--------------------------------------------------------------------------------
-- Main Panel Creation
--------------------------------------------------------------------------------

local function CreateRatedBGFilterPanel()
    if ratedBGPanel then return ratedBGPanel end

    local parent = PVEFrame
    if not parent then return nil end

    ratedBGPanel = CreateFrame("Frame", "PGFRatedBGFilterPanel", parent, "BackdropTemplate")
    ratedBGPanel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)

    if LFGListFrame then
        ratedBGPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
    else
        ratedBGPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -75)
    end

    ratedBGPanel:SetFrameStrata("HIGH")
    ratedBGPanel:SetFrameLevel(100)
    ratedBGPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ratedBGPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    ratedBGPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local scrollFrameContainer = CreateFrame("Frame", nil, ratedBGPanel)
    scrollFrameContainer:SetPoint("TOPLEFT",     ratedBGPanel, "TOPLEFT",     8,  -8)
    scrollFrameContainer:SetPoint("BOTTOMRIGHT", ratedBGPanel, "BOTTOMRIGHT", -4,  8)
    scrollFrameContainer:SetClipsChildren(true)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer)
    scrollFrame:SetAllPoints()
    ratedBGPanel.scrollFrame = scrollFrame

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(PANEL_WIDTH - 20)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)
    ratedBGPanel.scrollContent = scrollContent

    local scrollBar = PGF.CreateMinimalScrollBar(scrollFrame)
    ratedBGPanel.scrollBar = scrollBar

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        scrollBar:SetValue(math.max(min, math.min(max, current - (delta * 20))))
    end)
    scrollContent:EnableMouseWheel(true)
    scrollContent:SetScript("OnMouseWheel", function(self, delta)
        scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta)
    end)

    wipe(sections)
    CreateActivitiesSection(scrollContent)
    CreateRatingSection(scrollContent)
    CreatePlaystyleSection(scrollContent)
    CreateQuickApplySection(scrollContent)
    CreateSettingsSection(scrollContent)

    RecalculateLayout()
    return ratedBGPanel
end

function PGF.UpdateRatedBGPanel()
    if not ratedBGPanel then return end

    if ratedBGPanel.playstyleCheckboxes then
        local db = PintaGroupFinderDB
        local ps = db.filter and db.filter.ratedBGPlaystyle or {}
        for blizzKey, cd in pairs(ratedBGPanel.playstyleCheckboxes) do
            if cd and cd.frame then cd.frame:SetChecked(ps[blizzKey] ~= false) end
        end
    end

    if ratedBGPanel.ratingBox then
        local filter = (PintaGroupFinderDB.filter or {})
        ratedBGPanel.ratingBox:SetText(tostring(filter.ratedBGMinPvpRating or 0))
    end

    UpdateRatedBGList()

    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local qa = charDB.quickApply or PGF.charDefaults.quickApply

    if ratedBGPanel.quickApplyEnable then ratedBGPanel.quickApplyEnable:SetChecked(qa.enabled == true) end

    if ratedBGPanel.quickApplyRoleCheckboxes then
        local _, tank, healer, dps = GetLFGRoles()
        local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
        if ratedBGPanel.quickApplyRoleCheckboxes.tank then
            ratedBGPanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
            if availTank then ratedBGPanel.quickApplyRoleCheckboxes.tank:SetChecked(tank) end
        end
        if ratedBGPanel.quickApplyRoleCheckboxes.healer then
            ratedBGPanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
            if availHealer then ratedBGPanel.quickApplyRoleCheckboxes.healer:SetChecked(healer) end
        end
        if ratedBGPanel.quickApplyRoleCheckboxes.damage then
            ratedBGPanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
            if availDPS then ratedBGPanel.quickApplyRoleCheckboxes.damage:SetChecked(dps) end
        end
    end

    if ratedBGPanel.quickApplyAutoAccept then ratedBGPanel.quickApplyAutoAccept:SetChecked(qa.autoAcceptParty ~= false) end

    if ratedBGPanel.disableCustomSortingCheckbox then
        ratedBGPanel.disableCustomSortingCheckbox:SetChecked(GetSortSettings().disableCustomSorting ~= false)
    end

    if ratedBGPanel.movePendingGroupsToTopCheckbox then
        ratedBGPanel.movePendingGroupsToTopCheckbox:SetChecked(GetSortSettings().movePendingGroupsToTop ~= false)
    end

    if ratedBGPanel.showRatedBGSpecIndicatorsCheckbox then
        local ui = (PintaGroupFinderDB and PintaGroupFinderDB.ui) or PGF.defaults.ui
        ratedBGPanel.showRatedBGSpecIndicatorsCheckbox:SetChecked(ui.showRatedBGSpecIndicators ~= false)
    end

    if ratedBGPanel.UpdateDropdownStates then ratedBGPanel.UpdateDropdownStates() end

    if ratedBGPanel.primarySortDropdown then
        ratedBGPanel.primarySortDropdown:GenerateMenu()
    end
    if ratedBGPanel.primaryDirDropdown then
        ratedBGPanel.primaryDirDropdown:GenerateMenu()
    end
    if ratedBGPanel.secondarySortDropdown then
        ratedBGPanel.secondarySortDropdown:GenerateMenu()
    end
    if ratedBGPanel.secondaryDirDropdown then
        ratedBGPanel.secondaryDirDropdown:GenerateMenu()
    end

    RecalculateLayout()
end

function PGF.ShowRatedBGPanel(show)
    if show then
        if not ratedBGPanel then CreateRatedBGFilterPanel() end
        if ratedBGPanel then ratedBGPanel:Show(); PGF.UpdateRatedBGPanel() end
    else
        if ratedBGPanel then ratedBGPanel:Hide() end
    end
end

function PGF.GetRatedBGPanel()
    return ratedBGPanel
end

function PGF.InitializeRatedBGPanel()
    CreateRatedBGFilterPanel()
end
