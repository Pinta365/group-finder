--[[
    PintaGroupFinder - Delve Filter Panel Module

    Filter panel for delve category with accordion-style collapsible sections.
]]

local addonName, PGF = ...

local delvePanel = nil
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local HEADER_HEIGHT = 24
local CONTENT_PADDING = 8

local sections = {}

---Check if a section is expanded.
---@param sectionID string
---@return boolean
local function IsSectionExpanded(sectionID)
    return PintaGroupFinderDB.filter.delveAccordionState[sectionID]
end

---Set accordion state for a section.
---@param sectionID string
---@param expanded boolean
local function SetAccordionState(sectionID, expanded)
    PintaGroupFinderDB.filter.delveAccordionState[sectionID] = expanded
end

---Recalculate content height and reposition all sections.
local function RecalculateLayout()
    if not delvePanel or not delvePanel.scrollContent then return end

    local yOffset = 0

    for _, section in ipairs(sections) do
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", delvePanel.scrollContent, "TOPLEFT", 0, -yOffset)
        section.header:SetPoint("TOPRIGHT", delvePanel.scrollContent, "TOPRIGHT", 0, -yOffset)

        yOffset = yOffset + HEADER_HEIGHT

        if IsSectionExpanded(section.id) then
            section.content:ClearAllPoints()
            section.content:SetPoint("TOPLEFT", delvePanel.scrollContent, "TOPLEFT", 0, -yOffset)
            section.content:SetPoint("TOPRIGHT", delvePanel.scrollContent, "TOPRIGHT", 0, -yOffset)
            section.content:Show()
            yOffset = yOffset + section.content:GetHeight()
            section.header.arrow:SetText("-")
        else
            section.content:Hide()
            section.header.arrow:SetText("+")
        end

        yOffset = yOffset + 2
    end

    delvePanel.scrollContent:SetHeight(math.max(1, yOffset))

    if delvePanel.scrollBar then
        local scrollFrame = delvePanel.scrollFrame
        local visibleHeight = scrollFrame:GetHeight()
        local contentHeight = delvePanel.scrollContent:GetHeight()

        if contentHeight > visibleHeight then
            delvePanel.scrollBar:Show()
            delvePanel.scrollBar:SetMinMaxValues(0, contentHeight - visibleHeight)
        else
            delvePanel.scrollBar:Hide()
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

---Update delve list in activities section.
local function UpdateDelveList()
    if not delvePanel or not delvePanel.activityContent then
        return
    end

    local categoryID = PGF.DELVE_CATEGORY_ID
    local content = delvePanel.activityContent
    local checkboxes = delvePanel.activityCheckboxes or {}

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
    delvePanel.activityCheckboxes = checkboxes

    local db = PintaGroupFinderDB
    local allowAllDelves = (db.filter and db.filter.delveActivities) == nil
    local selectedGroupIDs = (db.filter and db.filter.delveActivities) or {}

    local buttonsHeight = delvePanel.activityButtonsHeight or 0
    local yPos = CONTENT_PADDING + buttonsHeight
    local checkboxHeight = 20
    local spacing = 2
    local separatorHeight = 10

    -- Current season delves
    local seasonFilter = Enum.LFGListFilter.Recommended
    if bit and bit.bor then
        seasonFilter = bit.bor(Enum.LFGListFilter.Recommended, Enum.LFGListFilter.PvE)
    end
    local seasonGroupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, seasonFilter) or {}

    -- Legacy/expansion delves
    local legacyFilter = Enum.LFGListFilter.NotRecommended
    if bit and bit.bor then
        legacyFilter = bit.bor(Enum.LFGListFilter.NotRecommended, Enum.LFGListFilter.PvE)
    end
    local legacyGroupIDs = C_LFGList.GetAvailableActivityGroups(categoryID, legacyFilter) or {}

    seasonGroupIDs = SortGroupsAlphabetically(seasonGroupIDs)
    legacyGroupIDs = SortGroupsAlphabetically(legacyGroupIDs)

    local seasonCount = 0
    for _, groupID in ipairs(seasonGroupIDs) do
        local name = C_LFGList.GetActivityGroupInfo(groupID)
        if name then
            local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            checkbox:SetSize(16, 16)
            checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)

            local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
            label:SetText(name)
            label:SetWidth(PANEL_WIDTH - 50)
            label:SetJustifyH("LEFT")

            checkbox:SetChecked(allowAllDelves or selectedGroupIDs[groupID] == true)

            checkbox:SetScript("OnClick", function(self)
                local db = PintaGroupFinderDB
                if not db.filter then db.filter = {} end

                local isChecked = self:GetChecked()

                if isChecked then
                    if not db.filter.delveActivities then db.filter.delveActivities = {} end
                    db.filter.delveActivities[groupID] = true
                else
                    if db.filter.delveActivities == nil then
                        db.filter.delveActivities = {}
                        for _, cb in ipairs(delvePanel.activityCheckboxes or {}) do
                            if cb.groupID then db.filter.delveActivities[cb.groupID] = true end
                        end
                    end
                    db.filter.delveActivities[groupID] = nil
                end

                PGF.RefilterResults()
            end)

            table.insert(checkboxes, { frame = checkbox, label = label, groupID = groupID })
            yPos = yPos + checkboxHeight + spacing
            seasonCount = seasonCount + 1
        end
    end

    if seasonCount > 0 and #legacyGroupIDs > 0 then
        local separator = content:CreateTexture(nil, "ARTWORK")
        separator:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
        separator:SetSize(PANEL_WIDTH - 30, 8)
        separator:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)
        separator:SetVertexColor(0.5, 0.5, 0.5, 0.5)

        table.insert(checkboxes, { separator = separator })
        yPos = yPos + separatorHeight
    end

    for _, groupID in ipairs(legacyGroupIDs) do
        local name = C_LFGList.GetActivityGroupInfo(groupID)
        if name then
            local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            checkbox:SetSize(16, 16)
            checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -yPos)

            local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
            label:SetText(name)
            label:SetWidth(PANEL_WIDTH - 50)
            label:SetJustifyH("LEFT")

            checkbox:SetChecked(allowAllDelves or selectedGroupIDs[groupID] == true)

            checkbox:SetScript("OnClick", function(self)
                local db = PintaGroupFinderDB
                if not db.filter then db.filter = {} end

                local isChecked = self:GetChecked()

                if isChecked then
                    if not db.filter.delveActivities then db.filter.delveActivities = {} end
                    db.filter.delveActivities[groupID] = true
                else
                    if db.filter.delveActivities == nil then
                        db.filter.delveActivities = {}
                        for _, cb in ipairs(delvePanel.activityCheckboxes or {}) do
                            if cb.groupID then db.filter.delveActivities[cb.groupID] = true end
                        end
                    end
                    db.filter.delveActivities[groupID] = nil
                end

                PGF.RefilterResults()
            end)

            table.insert(checkboxes, { frame = checkbox, label = label, groupID = groupID })
            yPos = yPos + checkboxHeight + spacing
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
        db.filter.delveActivities = {}

        local checkboxes = delvePanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.groupID then
                db.filter.delveActivities[cb.groupID] = true
                if cb.frame then cb.frame:SetChecked(true) end
            end
        end

        PGF.RefilterResults()
    end)

    deselectAllBtn:SetScript("OnClick", function()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.delveActivities = {}

        local checkboxes = delvePanel.activityCheckboxes or {}
        for _, cb in ipairs(checkboxes) do
            if cb.frame then cb.frame:SetChecked(false) end
        end

        PGF.RefilterResults()
    end)

    delvePanel.activityContent = content
    delvePanel.activityCheckboxes = {}
    delvePanel.activityButtonsHeight = 18 + CONTENT_PADDING

    table.insert(sections, {
        id = "activities",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 2: Tier Range
--------------------------------------------------------------------------------

---Create Tier Range section.
local function CreateTierSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "tier", PGF.L("SECTION_TIER") or "TIER RANGE")
    local content = CreateAccordionContent(scrollContent)

    local y = CONTENT_PADDING

    local descLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    descLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    descLabel:SetText(PGF.L("TIER_RANGE_DESC") or "Only show groups for the selected tier range.")
    descLabel:SetWidth(PANEL_WIDTH - CONTENT_PADDING * 2 - 20)
    descLabel:SetJustifyH("LEFT")
    y = y + descLabel:GetStringHeight() + 6

    -- Min Tier
    local minLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    minLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    minLabel:SetText(PGF.L("TIER_MIN") or "Min Tier:")

    local minBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    minBox:SetSize(40, 20)
    minBox:SetPoint("LEFT", minLabel, "RIGHT", 8, 0)
    minBox:SetAutoFocus(false)
    minBox:SetNumeric(true)
    minBox:SetMaxLetters(2)

    -- Max Tier
    local maxLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    maxLabel:SetPoint("LEFT", minBox, "RIGHT", 16, 0)
    maxLabel:SetText(PGF.L("TIER_MAX") or "Max Tier:")

    local maxBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    maxBox:SetSize(40, 20)
    maxBox:SetPoint("LEFT", maxLabel, "RIGHT", 8, 0)
    maxBox:SetAutoFocus(false)
    maxBox:SetNumeric(true)
    maxBox:SetMaxLetters(2)

    local function SaveTierRange()
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        local minVal = tonumber(minBox:GetText()) or 1
        local maxVal = tonumber(maxBox:GetText()) or 11
        minVal = math.max(1, math.min(11, minVal))
        maxVal = math.max(1, math.min(11, maxVal))
        if minVal > maxVal then minVal, maxVal = maxVal, minVal end
        db.filter.delveTierMin = minVal
        db.filter.delveTierMax = maxVal
        minBox:SetText(tostring(minVal))
        maxBox:SetText(tostring(maxVal))
        PGF.RefilterResults()
    end

    minBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); SaveTierRange() end)
    minBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    minBox:SetScript("OnEditFocusLost", function(self) SaveTierRange() end)

    maxBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); SaveTierRange() end)
    maxBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    maxBox:SetScript("OnEditFocusLost", function(self) SaveTierRange() end)

    delvePanel.tierMinBox = minBox
    delvePanel.tierMaxBox = maxBox

    y = y + 28

    local specialCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    specialCheckbox:SetSize(16, 16)
    specialCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

    local specialLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    specialLabel:SetPoint("LEFT", specialCheckbox, "RIGHT", 3, 0)
    specialLabel:SetText(PGF.L("TIER_INCLUDE_SPECIAL") or "Show ?/?? tier groups")

    specialCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        db.filter.delveIncludeSpecialTiers = self:GetChecked()
        PGF.RefilterResults()
    end)

    specialCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PGF.L("TIER_INCLUDE_SPECIAL"))
        GameTooltip:AddLine(PGF.L("TIER_INCLUDE_SPECIAL_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    specialCheckbox:SetScript("OnLeave", GameTooltip_Hide)

    delvePanel.specialTiersCheckbox = specialCheckbox

    y = y + 22

    content:SetHeight(y + CONTENT_PADDING)

    table.insert(sections, {
        id = "tier",
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
        checkbox:SetSize(16, 16)
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)

        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 3, 0)
        label:SetText(playstyle.label)

        checkbox:SetScript("OnClick", function(self)
            local db = PintaGroupFinderDB
            if not db.filter then db.filter = {} end
            if not db.filter.delvePlaystyle then db.filter.delvePlaystyle = {} end
            db.filter.delvePlaystyle[playstyle.blizzKey] = self:GetChecked()

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

    delvePanel.playstyleCheckboxes = playstyleCheckboxes
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

    y = y + 28

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

    delvePanel.quickApplyEnable = quickApplyEnable
    delvePanel.quickApplyRoleCheckboxes = quickApplyRoleCheckboxes
    delvePanel.quickApplyAutoAccept = autoAcceptCheckbox

    content:SetHeight(y + CONTENT_PADDING)

    table.insert(sections, {
        id = "quickApply",
        header = header,
        content = content,
    })
end

--------------------------------------------------------------------------------
-- Section 5: Settings
--------------------------------------------------------------------------------

local delveSortOptions = {
    { value = "age",       label = PGF.L("SORT_AGE") },
    { value = "groupSize", label = PGF.L("SORT_GROUP_SIZE") },
    { value = "ilvl",      label = PGF.L("SORT_ILVL") },
    { value = "name",      label = PGF.L("SORT_NAME") },
}

local function GetSortSettings()
    local db = PintaGroupFinderDB
    return db.filter and db.filter.delveSortSettings or PGF.defaults.filter.delveSortSettings
end

---Create Settings section.
local function CreateSettingsSection(scrollContent)
    local header = CreateAccordionHeader(scrollContent, "settings", PGF.L("SECTION_SETTINGS") or "SETTINGS")
    local content = CreateAccordionContent(scrollContent)

    local y = CONTENT_PADDING

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

        if delvePanel.primarySortDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(delvePanel.primarySortDropdown)
            else
                UIDropDownMenu_EnableDropDown(delvePanel.primarySortDropdown)
            end
        end

        if delvePanel.primaryDirDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(delvePanel.primaryDirDropdown)
            else
                UIDropDownMenu_EnableDropDown(delvePanel.primaryDirDropdown)
            end
        end

        if delvePanel.secondarySortDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(delvePanel.secondarySortDropdown)
            else
                UIDropDownMenu_EnableDropDown(delvePanel.secondarySortDropdown)
            end
        end

        if delvePanel.secondaryDirDropdown then
            if disabled then
                UIDropDownMenu_DisableDropDown(delvePanel.secondaryDirDropdown)
            else
                UIDropDownMenu_EnableDropDown(delvePanel.secondaryDirDropdown)
            end
        end
    end

    delvePanel.UpdateDropdownStates = UpdateDropdownStates

    disableCustomSortingCheckbox:SetScript("OnClick", function(self)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.delveSortSettings then
            db.filter.delveSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.delveSortSettings) do
                db.filter.delveSortSettings[k] = v
            end
        end
        db.filter.delveSortSettings.disableCustomSorting = self:GetChecked()
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

    delvePanel.disableCustomSortingCheckbox = disableCustomSortingCheckbox

    y = y + 24

    -- Primary Sort
    local primarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    primarySortLabel:SetText(PGF.L("SORT_PRIMARY"))

    local primarySortDropdown = CreateFrame("Frame", "PGFDelvePrimarySortDropdown", content, "UIDropDownMenuTemplate")
    primarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    UIDropDownMenu_SetWidth(primarySortDropdown, 120)

    local function SetPrimarySort(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.delveSortSettings then
            db.filter.delveSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.delveSortSettings) do
                db.filter.delveSortSettings[k] = v
            end
        end
        db.filter.delveSortSettings.primarySort = value
        PGF.RefilterResults()
    end

    local function PrimarySortOnClick(self, arg1)
        SetPrimarySort(arg1)
        UIDropDownMenu_SetSelectedValue(primarySortDropdown, arg1)
        for _, opt in ipairs(delveSortOptions) do
            if opt.value == arg1 then
                UIDropDownMenu_SetText(primarySortDropdown, opt.label)
                break
            end
        end
    end

    UIDropDownMenu_Initialize(primarySortDropdown, function(self, level)
        local settings = GetSortSettings()
        local currentSort = settings.primarySort or "age"

        for _, opt in ipairs(delveSortOptions) do
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
    for _, opt in ipairs(delveSortOptions) do
        if opt.value == currentPrimarySort then
            UIDropDownMenu_SetText(primarySortDropdown, opt.label)
            break
        end
    end

    delvePanel.primarySortDropdown = primarySortDropdown

    -- Primary Sort Direction
    local primaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    primaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    primaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))

    local primaryDirDropdown = CreateFrame("Frame", "PGFDelvePrimaryDirDropdown", content, "UIDropDownMenuTemplate")
    primaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 135, -y - 14)
    UIDropDownMenu_SetWidth(primaryDirDropdown, 80)

    local function SetPrimarySortDirection(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.delveSortSettings then
            db.filter.delveSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.delveSortSettings) do
                db.filter.delveSortSettings[k] = v
            end
        end
        db.filter.delveSortSettings.primarySortDirection = value
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

    delvePanel.primaryDirDropdown = primaryDirDropdown

    y = y + 50

    -- Secondary Sort
    local secondarySortLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondarySortLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING, -y)
    secondarySortLabel:SetText(PGF.L("SORT_SECONDARY"))

    local secondarySortDropdown = CreateFrame("Frame", "PGFDelveSecondarySortDropdown", content, "UIDropDownMenuTemplate")
    secondarySortDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING - 15, -y - 14)
    UIDropDownMenu_SetWidth(secondarySortDropdown, 120)

    local function SetSecondarySort(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.delveSortSettings then
            db.filter.delveSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.delveSortSettings) do
                db.filter.delveSortSettings[k] = v
            end
        end
        db.filter.delveSortSettings.secondarySort = value ~= "none" and value or nil
        PGF.RefilterResults()
    end

    local function SecondarySortOnClick(self, arg1)
        SetSecondarySort(arg1)
        UIDropDownMenu_SetSelectedValue(secondarySortDropdown, arg1)
        if arg1 == "none" then
            UIDropDownMenu_SetText(secondarySortDropdown, PGF.L("SORT_NONE"))
        else
            for _, opt in ipairs(delveSortOptions) do
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

        for _, opt in ipairs(delveSortOptions) do
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
        for _, opt in ipairs(delveSortOptions) do
            if opt.value == currentSecondarySort then
                UIDropDownMenu_SetText(secondarySortDropdown, opt.label)
                break
            end
        end
    else
        UIDropDownMenu_SetText(secondarySortDropdown, PGF.L("SORT_NONE"))
    end

    delvePanel.secondarySortDropdown = secondarySortDropdown

    -- Secondary Sort Direction
    local secondaryDirLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secondaryDirLabel:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 150, -y)
    secondaryDirLabel:SetText(PGF.L("SORT_DIRECTION"))

    local secondaryDirDropdown = CreateFrame("Frame", "PGFDelveSecondaryDirDropdown", content, "UIDropDownMenuTemplate")
    secondaryDirDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PADDING + 135, -y - 14)
    UIDropDownMenu_SetWidth(secondaryDirDropdown, 80)

    local function SetSecondarySortDirection(value)
        local db = PintaGroupFinderDB
        if not db.filter then db.filter = {} end
        if not db.filter.delveSortSettings then
            db.filter.delveSortSettings = {}
            for k, v in pairs(PGF.defaults.filter.delveSortSettings) do
                db.filter.delveSortSettings[k] = v
            end
        end
        db.filter.delveSortSettings.secondarySortDirection = value
        PGF.RefilterResults()
    end

    local function SecondaryDirOnClick(self, arg1)
        SetSecondarySortDirection(arg1)
        UIDropDownMenu_SetSelectedValue(secondaryDirDropdown, arg1)
        UIDropDownMenu_SetText(secondaryDirDropdown, arg1 == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    UIDropDownMenu_Initialize(secondaryDirDropdown, function(self, level)
        local settings = GetSortSettings()
        local currentDir = settings.secondarySortDirection or "asc"

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

    local currentSecondaryDir = settings.secondarySortDirection or "asc"
    UIDropDownMenu_SetSelectedValue(secondaryDirDropdown, currentSecondaryDir)
    UIDropDownMenu_SetText(secondaryDirDropdown, currentSecondaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))

    delvePanel.secondaryDirDropdown = secondaryDirDropdown

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

---Create the delve filter panel.
local function CreateDelveFilterPanel()
    if delvePanel then
        return delvePanel
    end

    local parent = PVEFrame
    if not parent then
        return nil
    end

    delvePanel = CreateFrame("Frame", "PGFDelveFilterPanel", parent, "BackdropTemplate")
    delvePanel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)

    if LFGListFrame then
        delvePanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
    else
        delvePanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -75)
    end

    delvePanel:SetFrameStrata("HIGH")
    delvePanel:SetFrameLevel(100)

    delvePanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    delvePanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    delvePanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local scrollFrameContainer = CreateFrame("Frame", nil, delvePanel)
    scrollFrameContainer:SetPoint("TOPLEFT", delvePanel, "TOPLEFT", 8, -8)
    scrollFrameContainer:SetPoint("BOTTOMRIGHT", delvePanel, "BOTTOMRIGHT", -4, 8)
    scrollFrameContainer:SetClipsChildren(true)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer)
    scrollFrame:SetAllPoints()
    delvePanel.scrollFrame = scrollFrame

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(PANEL_WIDTH - 20)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)
    delvePanel.scrollContent = scrollContent

    local scrollBar = CreateMinimalScrollBar(scrollFrame)
    delvePanel.scrollBar = scrollBar

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
    CreateTierSection(scrollContent)
    CreatePlaystyleSection(scrollContent)
    CreateQuickApplySection(scrollContent)
    CreateSettingsSection(scrollContent)

    RecalculateLayout()

    return delvePanel
end

---Update panel UI from saved settings.
function PGF.UpdateDelvePanel()
    if not delvePanel then
        return
    end

    if delvePanel.playstyleCheckboxes then
        local db = PintaGroupFinderDB
        local delvePlaystyle = db.filter and db.filter.delvePlaystyle or {}

        for blizzKey, checkboxData in pairs(delvePanel.playstyleCheckboxes) do
            if checkboxData and checkboxData.frame then
                checkboxData.frame:SetChecked(delvePlaystyle[blizzKey] ~= false)
            end
        end
    end

    if delvePanel.tierMinBox then
        local db = PintaGroupFinderDB
        local filter = db.filter or {}
        delvePanel.tierMinBox:SetText(tostring(filter.delveTierMin or 1))
    end

    if delvePanel.tierMaxBox then
        local db = PintaGroupFinderDB
        local filter = db.filter or {}
        delvePanel.tierMaxBox:SetText(tostring(filter.delveTierMax or 11))
    end

    if delvePanel.specialTiersCheckbox then
        local db = PintaGroupFinderDB
        local filter = db.filter or {}
        delvePanel.specialTiersCheckbox:SetChecked(filter.delveIncludeSpecialTiers ~= false)
    end

    UpdateDelveList()

    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply

    if delvePanel.quickApplyEnable then
        delvePanel.quickApplyEnable:SetChecked(quickApply.enabled == true)
    end

    if delvePanel.quickApplyRoleCheckboxes then
        local _, tank, healer, dps = GetLFGRoles()
        local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()

        if delvePanel.quickApplyRoleCheckboxes.tank then
            delvePanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
            if availTank then delvePanel.quickApplyRoleCheckboxes.tank:SetChecked(tank) end
        end
        if delvePanel.quickApplyRoleCheckboxes.healer then
            delvePanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
            if availHealer then delvePanel.quickApplyRoleCheckboxes.healer:SetChecked(healer) end
        end
        if delvePanel.quickApplyRoleCheckboxes.damage then
            delvePanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
            if availDPS then delvePanel.quickApplyRoleCheckboxes.damage:SetChecked(dps) end
        end
    end

    if delvePanel.quickApplyAutoAccept then
        delvePanel.quickApplyAutoAccept:SetChecked(quickApply.autoAcceptParty ~= false)
    end

    if delvePanel.disableCustomSortingCheckbox then
        local settings = GetSortSettings()
        delvePanel.disableCustomSortingCheckbox:SetChecked(settings.disableCustomSorting ~= false)
    end

    if delvePanel.UpdateDropdownStates then
        delvePanel.UpdateDropdownStates()
    end

    if delvePanel.primarySortDropdown then
        local settings = GetSortSettings()
        local currentPrimarySort = settings.primarySort or "age"
        UIDropDownMenu_SetSelectedValue(delvePanel.primarySortDropdown, currentPrimarySort)
        for _, opt in ipairs(delveSortOptions) do
            if opt.value == currentPrimarySort then
                UIDropDownMenu_SetText(delvePanel.primarySortDropdown, opt.label)
                break
            end
        end
    end

    if delvePanel.primaryDirDropdown then
        local settings = GetSortSettings()
        local currentPrimaryDir = settings.primarySortDirection or "asc"
        UIDropDownMenu_SetSelectedValue(delvePanel.primaryDirDropdown, currentPrimaryDir)
        UIDropDownMenu_SetText(delvePanel.primaryDirDropdown, currentPrimaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    if delvePanel.secondarySortDropdown then
        local settings = GetSortSettings()
        local currentSecondarySort = settings.secondarySort
        UIDropDownMenu_SetSelectedValue(delvePanel.secondarySortDropdown, currentSecondarySort or "none")
        if currentSecondarySort then
            for _, opt in ipairs(delveSortOptions) do
                if opt.value == currentSecondarySort then
                    UIDropDownMenu_SetText(delvePanel.secondarySortDropdown, opt.label)
                    break
                end
            end
        else
            UIDropDownMenu_SetText(delvePanel.secondarySortDropdown, PGF.L("SORT_NONE"))
        end
    end

    if delvePanel.secondaryDirDropdown then
        local settings = GetSortSettings()
        local currentSecondaryDir = settings.secondarySortDirection or "asc"
        UIDropDownMenu_SetSelectedValue(delvePanel.secondaryDirDropdown, currentSecondaryDir)
        UIDropDownMenu_SetText(delvePanel.secondaryDirDropdown, currentSecondaryDir == "asc" and PGF.L("SORT_ASC") or PGF.L("SORT_DESC"))
    end

    RecalculateLayout()
end

---Show or hide the delve panel.
---@param show boolean
function PGF.ShowDelvePanel(show)
    if show then
        if not delvePanel then
            CreateDelveFilterPanel()
        end
        if delvePanel then
            delvePanel:Show()
            PGF.UpdateDelvePanel()
        end
    else
        if delvePanel then
            delvePanel:Hide()
        end
    end
end

---Get the delve panel frame.
---@return Frame?
function PGF.GetDelvePanel()
    return delvePanel
end

---Initialize the delve filter panel.
function PGF.InitializeDelvePanel()
    CreateDelveFilterPanel()
end
