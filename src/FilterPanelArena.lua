--[[
    PintaGroupFinder - Arena Filter Panel Module

    Filter panel for arena category (categoryID=4) with accordion-style collapsible sections.
]]

local addonName, PGF = ...

local arenaPanel = nil
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local HEADER_HEIGHT = 24
local CONTENT_PADDING = 8

local sections = {}

---Check if a section is expanded.
---@param sectionID string
---@return boolean
local function IsSectionExpanded(sectionID)
    return PintaGroupFinderDB.filter.arenaAccordionState[sectionID]
end

---Set accordion state for a section.
---@param sectionID string
---@param expanded boolean
local function SetAccordionState(sectionID, expanded)
    PintaGroupFinderDB.filter.arenaAccordionState[sectionID] = expanded
end

---Recalculate content height and reposition all sections.
local function RecalculateLayout()
    if not arenaPanel or not arenaPanel.scrollContent then return end

    local yOffset = 0

    for _, section in ipairs(sections) do
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", arenaPanel.scrollContent, "TOPLEFT", 0, -yOffset)
        section.header:SetPoint("TOPRIGHT", arenaPanel.scrollContent, "TOPRIGHT", 0, -yOffset)

        yOffset = yOffset + HEADER_HEIGHT

        if IsSectionExpanded(section.id) then
            section.content:ClearAllPoints()
            section.content:SetPoint("TOPLEFT", arenaPanel.scrollContent, "TOPLEFT", 0, -yOffset)
            section.content:SetPoint("TOPRIGHT", arenaPanel.scrollContent, "TOPRIGHT", 0, -yOffset)
            section.content:Show()
            yOffset = yOffset + section.content:GetHeight()
            section.header.arrow:SetText("-")
        else
            section.content:Hide()
            section.header.arrow:SetText("+")
        end

        yOffset = yOffset + 2
    end

    arenaPanel.scrollContent:SetHeight(math.max(1, yOffset))

    if arenaPanel.scrollBar then
        local scrollFrame = arenaPanel.scrollFrame
        local visibleHeight = scrollFrame:GetHeight()
        local contentHeight = arenaPanel.scrollContent:GetHeight()

        if contentHeight > visibleHeight then
            arenaPanel.scrollBar:Show()
            arenaPanel.scrollBar:SetMinMaxValues(0, contentHeight - visibleHeight)
        else
            arenaPanel.scrollBar:Hide()
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
    titleText:SetTextColor(1, 0.82, 0)

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
-- Section 1: Activities
--------------------------------------------------------------------------------

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

---Update arena activity list.
local function UpdateArenaList()
    if not arenaPanel or not arenaPanel.activityContent then
        return
    end

    local categoryID = PGF.ARENA_CATEGORY_ID
    local content = arenaPanel.activityContent
    local checkboxes = arenaPanel.activityCheckboxes or {}

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
    arenaPanel.activityCheckboxes = checkboxes

    local db = PintaGroupFinderDB
    local allowAll = (db.filter and db.filter.arenaActivities) == nil
    local selectedKeys = (db.filter and db.filter.arenaActivities) or {}

    local buttonsHeight = arenaPanel.activityButtonsHeight or 0
    local yPos = CONTENT_PADDING + buttonsHeight
    local checkboxHeight = 20
    local spacing = 2

    -- Try to get activity groups (positive keys)
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
        -- List groups (positive keys)
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
                if not db.filter then db.filter = {} end

                local isChecked = self:GetChecked()
                if isChecked then
                    if not db.filter.arenaActivities then db.filter.arenaActivities = {} end
                    db.filter.arenaActivities[groupID] = true
                else
                    if db.filter.arenaActivities == nil then
                        db.filter.arenaActivities = {}
                        for _, cb in ipairs(arenaPanel.activityCheckboxes or {}) do
                            if cb.groupID then db.filter.arenaActivities[cb.groupID] = true end
                        end
                    end
                    db.filter.arenaActivities[groupID] = nil
                end
                PGF.RefilterResults()
            end)

            table.insert(checkboxes, { frame = checkbox, label = label, groupID = groupID })
            yPos = yPos + checkboxHeight + spacing
        end

        for _, groupID in ipairs(groupIDs) do
            AddGroupCheckbox(groupID)
        end

        if #groupIDs > 0 and #legacyGroupIDs > 0 then
            local separator = content:CreateTexture(nil, "ARTWORK")
            separator:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
            separator:SetSize(PANEL_WIDTH - 30, 8)
            separator:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
            separator:SetVertexColor(0.5, 0.5, 0.5, 0.5)
            table.insert(checkboxes, { separator = separator })
            yPos = yPos + 10
        end

        for _, groupID in ipairs(legacyGroupIDs) do
            AddGroupCheckbox(groupID)
        end
    else
        -- Fallback: list individual activities (negative keys)
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
                    if not db.filter then db.filter = {} end

                    local isChecked = self:GetChecked()
                    if isChecked then
                        if not db.filter.arenaActivities then db.filter.arenaActivities = {} end
                        db.filter.arenaActivities[negKey] = true
                    else
                        if db.filter.arenaActivities == nil then
                            db.filter.arenaActivities = {}
                            for _, cb in ipairs(arenaPanel.activityCheckboxes or {}) do
                                if cb.actID then db.filter.arenaActivities[-cb.actID] = true end
                            end
                        end
                        db.filter.arenaActivities[negKey] = nil
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

---Create Activities section.
local function CreateActivitiesSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "activities", PGF.L("SECTION_ACTIVITIES"))
    local content = CreateAccordionContent(scrollContent)

    content:SetHeight(150)

    local selectAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    selectAllBtn:SetText(PGF.L("SELECT_ALL"))
    selectAllBtn:GetFontString():SetFont(selectAllBtn:GetFontString():GetFont(), 10)
    local selectWidth = selectAllBtn:GetFontString():GetStringWidth() + 16
    selectAllBtn:SetSize(selectWidth, 18)
    selectAllBtn:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)

    local deselectAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    deselectAllBtn:SetText(PGF.L("DESELECT_ALL"))
    deselectAllBtn:GetFontString():SetFont(deselectAllBtn:GetFontString():GetFont(), 10)
    local deselectWidth = deselectAllBtn:GetFontString():GetStringWidth() + 16
    deselectAllBtn:SetSize(deselectWidth, 18)
    deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 4, 0)

    selectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.arenaActivities = {}

        local checkboxes = arenaPanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.groupID then
                db.filter.arenaActivities[cb.groupID] = true
                if cb.frame then cb.frame:SetChecked(true) end
            elseif cb.actID then
                db.filter.arenaActivities[-cb.actID] = true
                if cb.frame then cb.frame:SetChecked(true) end
            end
        end
        PGF.RefilterResults()
    end)

    deselectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.arenaActivities = {}

        local checkboxes = arenaPanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.frame then cb.frame:SetChecked(false) end
        end
        PGF.RefilterResults()
    end)

    arenaPanel.activityContent = content
    arenaPanel.activityCheckboxes = {}
    arenaPanel.activityButtonsHeight = 18 + CONTENT_PADDING

    table.insert(sections, {
        id = "activities",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 2: Rating
--------------------------------------------------------------------------------

---Create Rating section (min PvP rating filter).
local function CreateRatingSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "rating", PGF.L("SECTION_PVP_RATING"))
    local content = CreateAccordionContent(scrollContent)

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
        if not db.filter then db.filter = {} end
        local val = tonumber(ratingBox:GetText()) or 0
        val = math.max(0, val)
        db.filter.arenaMinPvpRating = val
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

    arenaPanel.ratingBox = ratingBox

    y = y + 28

    content:SetHeight(y + CONTENT_PADDING)

    table.insert(sections, {
        id = "rating",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 3: Playstyle
--------------------------------------------------------------------------------

---Create Playstyle section.
local function CreatePlaystyleSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "playstyle", PGF.L("SECTION_PLAYSTYLE"))
    local content = CreateAccordionContent(scrollContent)

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
            if not db.filter then db.filter = {} end
            if not db.filter.arenaPlaystyle then db.filter.arenaPlaystyle = {} end
            db.filter.arenaPlaystyle[playstyle.blizzKey] = self:GetChecked()
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

    arenaPanel.playstyleCheckboxes = playstyleCheckboxes
    content:SetHeight(y + CONTENT_PADDING)

    table.insert(sections, {
        id = "playstyle",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 4: Quick Apply
--------------------------------------------------------------------------------

---Create Quick Apply section.
local function CreateQuickApplySection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "quickApply", PGF.L("SECTION_QUICK_APPLY"))
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

    y = y + 28

    local rolesLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rolesLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    rolesLabel:SetText(PGF.L("ROLES"))

    local quickApplyRoleCheckboxes = {}
    local roleButtons = {
        { key = "tank",   label = "T" },
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
            local tank   = charDB.quickApply.roles.tank   == true
            local healer = charDB.quickApply.roles.healer == true
            local dps    = charDB.quickApply.roles.damage == true
            SetLFGRoles(leader, tank, healer, dps)
        end)

        quickApplyRoleCheckboxes[role.key] = checkbox
        roleX = roleX + 35
    end

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

    arenaPanel.quickApplyEnable = quickApplyEnable
    arenaPanel.quickApplyRoleCheckboxes = quickApplyRoleCheckboxes
    arenaPanel.quickApplyAutoAccept = autoAcceptCheckbox

    content:SetHeight(y + CONTENT_PADDING)

    table.insert(sections, {
        id = "quickApply",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 5: Settings (Sorting)
--------------------------------------------------------------------------------

local arenaSortOptions = {
    { value = "age",       label = PGF.L("SORT_AGE") },
    { value = "groupSize", label = PGF.L("SORT_GROUP_SIZE") },
    { value = "pvpRating", label = PGF.L("SORT_PVP_RATING") },
    { value = "name",      label = PGF.L("SORT_NAME") },
}

local function GetSortSettings()
    local db = PintaGroupFinderDB
    return db.filter and db.filter.arenaSortSettings or PGF.defaults.filter.arenaSortSettings
end

---Create Settings section.
local function CreateSettingsSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "settings", PGF.L("SECTION_SETTINGS"))
    local content = CreateAccordionContent(scrollContent)

    local y = CONTENT_PADDING

    local disableCustomSortingCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    disableCustomSortingCheckbox:SetSize(20, 20)
    disableCustomSortingCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

    local disableCustomSortingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    disableCustomSortingLabel:SetPoint("LEFT", disableCustomSortingCheckbox, "RIGHT", 5, 0)
    disableCustomSortingLabel:SetText(PGF.L("DISABLE_CUSTOM_SORTING"))

    local function UpdateDropdownStates()
        local settings = GetSortSettings()
        local disabled = settings.disableCustomSorting == true

        if arenaPanel.primarySortDropdown then
            if disabled then UIDropDownMenu_DisableDropDown(arenaPanel.primarySortDropdown)
            else UIDropDownMenu_EnableDropDown(arenaPanel.primarySortDropdown) end
        end
        if arenaPanel.primaryDirDropdown then
            if disabled then UIDropDownMenu_DisableDropDown(arenaPanel.primaryDirDropdown)
            else UIDropDownMenu_EnableDropDown(arenaPanel.primaryDirDropdown) end
        end
        if arenaPanel.secondarySortDropdown then
            if disabled then UIDropDownMenu_DisableDropDown(arenaPanel.secondarySortDropdown)
            else UIDropDownMenu_EnableDropDown(arenaPanel.secondarySortDropdown) end
        end
        if arenaPanel.secondaryDirDropdown then
            if disabled then UIDropDownMenu_DisableDropDown(arenaPanel.secondaryDirDropdown)
            else UIDropDownMenu_EnableDropDown(arenaPanel.secondaryDirDropdown) end
        end
    end

    arenaPanel.UpdateDropdownStates = UpdateDropdownStates

    disableCustomSortingCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.arenaSortSettings then
            db.filter.arenaSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.arenaSortSettings) do
                db.filter.arenaSortSettings[k] = v
            end
        end
        db.filter.arenaSortSettings.disableCustomSorting = self:GetChecked()
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
    arenaPanel.disableCustomSortingCheckbox = disableCustomSortingCheckbox

    y = y + 24

    -- Primary Sort
    local primarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    primarySortLabel:SetText(PGF.L("SORT_PRIMARY"))

    local primarySortDropdown = CreateFrame("Frame", "PGFArenaPrimarySortDropdown", content, "UIDropDownMenuTemplate")
    primarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    UIDropDownMenu_SetWidth(primarySortDropdown, 120)

    local function SetPrimarySort(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.arenaSortSettings then
            db.filter.arenaSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.arenaSortSettings) do db.filter.arenaSortSettings[k] = v end
        end
        db.filter.arenaSortSettings.primarySort = value
        PGF.RefilterResults()
    end

    local function PrimarySortOnClick(self, arg1)
        SetPrimarySort(arg1)
        UIDropDownMenu_SetSelectedValue(primarySortDropdown, arg1)
        for _, opt in ipairs(arenaSortOptions) do
            if opt.value == arg1 then
                UIDropDownMenu_SetText(primarySortDropdown, opt.label)
                break
            end
        end
    end

    UIDropDownMenu_Initialize(primarySortDropdown, function(self, level)
        local s = GetSortSettings()
        local currentSort = s.primarySort or "age"
        for _, opt in ipairs(arenaSortOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.value   = opt.value
            info.arg1    = opt.value
            info.func    = PrimarySortOnClick
            info.checked = currentSort == opt.value
            UIDropDownMenu_AddButton(info)
        end
    end)

    local currentPrimarySort = settings.primarySort or "age"
    UIDropDownMenu_SetSelectedValue(primarySortDropdown, currentPrimarySort)
    for _, opt in ipairs(arenaSortOptions) do
        if opt.value == currentPrimarySort then
            UIDropDownMenu_SetText(primarySortDropdown, opt.label)
            break
        end
    end
    arenaPanel.primarySortDropdown = primarySortDropdown

    -- Primary Sort Direction
    local primaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    primaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))

    local primaryDirDropdown = CreateFrame("Frame", "PGFArenaPrimaryDirDropdown", content, "UIDropDownMenuTemplate")
    primaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 135, -y - 14)
    UIDropDownMenu_SetWidth(primaryDirDropdown, 80)

    local function SetPrimaryDir(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.arenaSortSettings then
            db.filter.arenaSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.arenaSortSettings) do db.filter.arenaSortSettings[k] = v end
        end
        db.filter.arenaSortSettings.primarySortDirection = value
        PGF.RefilterResults()
    end

    local function PrimaryDirOnClick(self, arg1)
        SetPrimaryDir(arg1)
        UIDropDownMenu_SetSelectedValue(primaryDirDropdown, arg1)
        UIDropDownMenu_SetText(primaryDirDropdown, arg1 == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    UIDropDownMenu_Initialize(primaryDirDropdown, function(self, level)
        local s = GetSortSettings()
        local currentDir = s.primarySortDirection or "asc"
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_ASC"); info.value = "asc"; info.arg1 = "asc"; info.func = PrimaryDirOnClick; info.checked = currentDir == "asc"
        UIDropDownMenu_AddButton(info)
        info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_DESC"); info.value = "desc"; info.arg1 = "desc"; info.func = PrimaryDirOnClick; info.checked = currentDir == "desc"
        UIDropDownMenu_AddButton(info)
    end)

    local currentPrimaryDir = settings.primarySortDirection or "asc"
    UIDropDownMenu_SetSelectedValue(primaryDirDropdown, currentPrimaryDir)
    UIDropDownMenu_SetText(primaryDirDropdown, currentPrimaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    arenaPanel.primaryDirDropdown = primaryDirDropdown

    y = y + 50

    -- Secondary Sort
    local secondarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    secondarySortLabel:SetText(PGF.L("SORT_SECONDARY"))

    local secondarySortDropdown = CreateFrame("Frame", "PGFArenaSecondarySortDropdown", content, "UIDropDownMenuTemplate")
    secondarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    UIDropDownMenu_SetWidth(secondarySortDropdown, 120)

    local function SetSecondarySort(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.arenaSortSettings then
            db.filter.arenaSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.arenaSortSettings) do db.filter.arenaSortSettings[k] = v end
        end
        db.filter.arenaSortSettings.secondarySort = value ~= "none" and value or nil
        PGF.RefilterResults()
    end

    local function SecondarySortOnClick(self, arg1)
        SetSecondarySort(arg1)
        UIDropDownMenu_SetSelectedValue(secondarySortDropdown, arg1)
        if arg1 == "none" then
            UIDropDownMenu_SetText(secondarySortDropdown, PGF.L("SORT_NONE"))
        else
            for _, opt in ipairs(arenaSortOptions) do
                if opt.value == arg1 then UIDropDownMenu_SetText(secondarySortDropdown, opt.label); break end
            end
        end
    end

    UIDropDownMenu_Initialize(secondarySortDropdown, function(self, level)
        local s = GetSortSettings()
        local currentSort = s.secondarySort
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_NONE"); info.value = "none"; info.arg1 = "none"; info.func = SecondarySortOnClick; info.checked = not s.secondarySort
        UIDropDownMenu_AddButton(info)
        for _, opt in ipairs(arenaSortOptions) do
            info = UIDropDownMenu_CreateInfo()
            info.text = opt.label; info.value = opt.value; info.arg1 = opt.value; info.func = SecondarySortOnClick; info.checked = currentSort == opt.value
            UIDropDownMenu_AddButton(info)
        end
    end)

    local currentSecondarySort = settings.secondarySort
    UIDropDownMenu_SetSelectedValue(secondarySortDropdown, currentSecondarySort or "none")
    if currentSecondarySort then
        for _, opt in ipairs(arenaSortOptions) do
            if opt.value == currentSecondarySort then UIDropDownMenu_SetText(secondarySortDropdown, opt.label); break end
        end
    else
        UIDropDownMenu_SetText(secondarySortDropdown, PGF.L("SORT_NONE"))
    end
    arenaPanel.secondarySortDropdown = secondarySortDropdown

    -- Secondary Sort Direction
    local secondaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    secondaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))

    local secondaryDirDropdown = CreateFrame("Frame", "PGFArenaSecondaryDirDropdown", content, "UIDropDownMenuTemplate")
    secondaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 135, -y - 14)
    UIDropDownMenu_SetWidth(secondaryDirDropdown, 80)

    local function SetSecondaryDir(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.arenaSortSettings then
            db.filter.arenaSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.arenaSortSettings) do db.filter.arenaSortSettings[k] = v end
        end
        db.filter.arenaSortSettings.secondarySortDirection = value
        PGF.RefilterResults()
    end

    local function SecondaryDirOnClick(self, arg1)
        SetSecondaryDir(arg1)
        UIDropDownMenu_SetSelectedValue(secondaryDirDropdown, arg1)
        UIDropDownMenu_SetText(secondaryDirDropdown, arg1 == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    UIDropDownMenu_Initialize(secondaryDirDropdown, function(self, level)
        local s = GetSortSettings()
        local currentDir = s.secondarySortDirection or "asc"
        local info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_ASC"); info.value = "asc"; info.arg1 = "asc"; info.func = SecondaryDirOnClick; info.checked = currentDir == "asc"
        UIDropDownMenu_AddButton(info)
        info = UIDropDownMenu_CreateInfo()
        info.text = PGF.L("SORT_DESC"); info.value = "desc"; info.arg1 = "desc"; info.func = SecondaryDirOnClick; info.checked = currentDir == "desc"
        UIDropDownMenu_AddButton(info)
    end)

    local currentSecondaryDir = settings.secondarySortDirection or "asc"
    UIDropDownMenu_SetSelectedValue(secondaryDirDropdown, currentSecondaryDir)
    UIDropDownMenu_SetText(secondaryDirDropdown, currentSecondaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    arenaPanel.secondaryDirDropdown = secondaryDirDropdown

    y = y + 50
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

---Create the arena filter panel.
local function CreateArenaFilterPanel()
    if arenaPanel then
        return arenaPanel
    end

    local parent = PVEFrame
    if not parent then
        return nil
    end

    arenaPanel = CreateFrame("Frame", "PGFArenaFilterPanel", parent, "BackdropTemplate")
    arenaPanel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)

    if LFGListFrame then
        arenaPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
    else
        arenaPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -75)
    end

    arenaPanel:SetFrameStrata("HIGH")
    arenaPanel:SetFrameLevel(100)

    arenaPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    arenaPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    arenaPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local scrollFrameContainer = CreateFrame("Frame", nil, arenaPanel)
    scrollFrameContainer:SetPoint("TOPLEFT",     arenaPanel, "TOPLEFT",     8,  -8)
    scrollFrameContainer:SetPoint("BOTTOMRIGHT", arenaPanel, "BOTTOMRIGHT", -4,  8)
    scrollFrameContainer:SetClipsChildren(true)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer)
    scrollFrame:SetAllPoints()
    arenaPanel.scrollFrame = scrollFrame

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(PANEL_WIDTH - 20)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)
    arenaPanel.scrollContent = scrollContent

    local scrollBar = CreateMinimalScrollBar(scrollFrame)
    arenaPanel.scrollBar = scrollBar

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local newValue = math.max(min, math.min(max, current - (delta * 20)))
        scrollBar:SetValue(newValue)
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

    return arenaPanel
end

---Update panel UI from saved settings.
function PGF.UpdateArenaPanel()
    if not arenaPanel then return end

    if arenaPanel.playstyleCheckboxes then
        local db = PintaGroupFinderDB
        local arenaPlaystyle = db.filter and db.filter.arenaPlaystyle or {}
        for blizzKey, checkboxData in pairs(arenaPanel.playstyleCheckboxes) do
            if checkboxData and checkboxData.frame then
                checkboxData.frame:SetChecked(arenaPlaystyle[blizzKey] ~= false)
            end
        end
    end

    if arenaPanel.ratingBox then
        local db = PintaGroupFinderDB
        local filter = db.filter or {}
        arenaPanel.ratingBox:SetText(tostring(filter.arenaMinPvpRating or 0))
    end

    UpdateArenaList()

    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply

    if arenaPanel.quickApplyEnable then
        arenaPanel.quickApplyEnable:SetChecked(quickApply.enabled == true)
    end

    if arenaPanel.quickApplyRoleCheckboxes then
        local _, tank, healer, dps = GetLFGRoles()
        local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
        if arenaPanel.quickApplyRoleCheckboxes.tank then
            arenaPanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
            if availTank then arenaPanel.quickApplyRoleCheckboxes.tank:SetChecked(tank) end
        end
        if arenaPanel.quickApplyRoleCheckboxes.healer then
            arenaPanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
            if availHealer then arenaPanel.quickApplyRoleCheckboxes.healer:SetChecked(healer) end
        end
        if arenaPanel.quickApplyRoleCheckboxes.damage then
            arenaPanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
            if availDPS then arenaPanel.quickApplyRoleCheckboxes.damage:SetChecked(dps) end
        end
    end

    if arenaPanel.quickApplyAutoAccept then
        arenaPanel.quickApplyAutoAccept:SetChecked(quickApply.autoAcceptParty ~= false)
    end

    if arenaPanel.disableCustomSortingCheckbox then
        local settings = GetSortSettings()
        arenaPanel.disableCustomSortingCheckbox:SetChecked(settings.disableCustomSorting ~= false)
    end

    if arenaPanel.UpdateDropdownStates then
        arenaPanel.UpdateDropdownStates()
    end

    if arenaPanel.primarySortDropdown then
        local settings = GetSortSettings()
        local cur = settings.primarySort or "age"
        UIDropDownMenu_SetSelectedValue(arenaPanel.primarySortDropdown, cur)
        for _, opt in ipairs(arenaSortOptions) do
            if opt.value == cur then UIDropDownMenu_SetText(arenaPanel.primarySortDropdown, opt.label); break end
        end
    end

    if arenaPanel.primaryDirDropdown then
        local settings = GetSortSettings()
        local cur = settings.primarySortDirection or "asc"
        UIDropDownMenu_SetSelectedValue(arenaPanel.primaryDirDropdown, cur)
        UIDropDownMenu_SetText(arenaPanel.primaryDirDropdown, cur == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    if arenaPanel.secondarySortDropdown then
        local settings = GetSortSettings()
        local cur = settings.secondarySort
        UIDropDownMenu_SetSelectedValue(arenaPanel.secondarySortDropdown, cur or "none")
        if cur then
            for _, opt in ipairs(arenaSortOptions) do
                if opt.value == cur then UIDropDownMenu_SetText(arenaPanel.secondarySortDropdown, opt.label); break end
            end
        else
            UIDropDownMenu_SetText(arenaPanel.secondarySortDropdown, PGF.L("SORT_NONE"))
        end
    end

    if arenaPanel.secondaryDirDropdown then
        local settings = GetSortSettings()
        local cur = settings.secondarySortDirection or "asc"
        UIDropDownMenu_SetSelectedValue(arenaPanel.secondaryDirDropdown, cur)
        UIDropDownMenu_SetText(arenaPanel.secondaryDirDropdown, cur == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    RecalculateLayout()
end

---Show or hide the arena panel.
---@param show boolean
function PGF.ShowArenaPanel(show)
    if show then
        if not arenaPanel then
            CreateArenaFilterPanel()
        end
        if arenaPanel then
            arenaPanel:Show()
            PGF.UpdateArenaPanel()
        end
    else
        if arenaPanel then
            arenaPanel:Hide()
        end
    end
end

---Get the arena panel frame.
---@return Frame?
function PGF.GetArenaPanel()
    return arenaPanel
end

---Initialize the arena filter panel.
function PGF.InitializeArenaPanel()
    CreateArenaFilterPanel()
end
