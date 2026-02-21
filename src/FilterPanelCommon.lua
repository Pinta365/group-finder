--[[
    PintaGroupFinder - Common Filter Panel Utilities

    Shared UI helpers used by all filter panel modules.
    Loaded before any FilterPanel*.lua file.
]]

local addonName, PGF = ...

local HEADER_HEIGHT = 24
local CONTENT_PADDING = 8

---Create a minimal scrollbar attached to a scroll frame.
---@param parent Frame The scroll frame to attach to
---@return Slider scrollBar
function PGF.CreateMinimalScrollBar(parent)
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
---@param isExpanded fun(sectionID: string): boolean
---@param setExpanded fun(sectionID: string, expanded: boolean)
---@param recalculate fun()
---@return Frame header The header frame
function PGF.CreateAccordionHeader(parent, sectionID, title, isExpanded, setExpanded, recalculate)
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
    arrow:SetText(isExpanded(sectionID) and "-" or "+")
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
        local newState = not isExpanded(sectionID)
        setExpanded(sectionID, newState)
        recalculate()
    end)

    return header
end

---Create an accordion section content container.
---@param parent Frame Parent frame (scroll content)
---@return Frame content The content frame
function PGF.CreateAccordionContent(parent)
    local content = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    content:SetBackdropColor(0.15, 0.15, 0.15, 1)

    return content
end

---Recalculate section layout within a panel's scroll content.
---@param panel table Panel table with scrollContent, scrollBar, scrollFrame fields
---@param sections table Array of section tables with header, content, id fields
---@param isExpanded fun(sectionID: string): boolean
function PGF.RecalculateLayout(panel, sections, isExpanded)
    if not panel or not panel.scrollContent then return end

    local yOffset = 0

    for _, section in ipairs(sections) do
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", panel.scrollContent, "TOPLEFT", 0, -yOffset)
        section.header:SetPoint("TOPRIGHT", panel.scrollContent, "TOPRIGHT", 0, -yOffset)

        yOffset = yOffset + HEADER_HEIGHT

        if isExpanded(section.id) then
            section.content:ClearAllPoints()
            section.content:SetPoint("TOPLEFT", panel.scrollContent, "TOPLEFT", 0, -yOffset)
            section.content:SetPoint("TOPRIGHT", panel.scrollContent, "TOPRIGHT", 0, -yOffset)
            section.content:Show()
            yOffset = yOffset + section.content:GetHeight()
            section.header.arrow:SetText("-")
        else
            section.content:Hide()
            section.header.arrow:SetText("+")
        end

        yOffset = yOffset + 2
    end

    panel.scrollContent:SetHeight(math.max(1, yOffset))

    if panel.scrollBar then
        local scrollFrame = panel.scrollFrame
        local visibleHeight = scrollFrame:GetHeight()
        local contentHeight = panel.scrollContent:GetHeight()

        if contentHeight > visibleHeight then
            panel.scrollBar:Show()
            panel.scrollBar:SetMinMaxValues(0, contentHeight - visibleHeight)
        else
            panel.scrollBar:Hide()
            scrollFrame:SetVerticalScroll(0)
        end
    end
end

---Create the Quick Apply accordion section
---Stores widget references on the panel table; all settings go to charDB.quickApply.
---@param scrollContent Frame The scroll content frame
---@param panel table Panel table; receives quickApplyEnable, quickApplyRoleCheckboxes, quickApplyAutoAccept
---@param sections table The sections array to insert into
---@param makeHeader fun(parent, sectionID, title): Frame Panel-local accordion header builder
function PGF.CreateQuickApplySection(scrollContent, panel, sections, makeHeader)
    local header = makeHeader(scrollContent, "quickApply", PGF.L("SECTION_QUICK_APPLY") or "QUICK APPLY")
    local content = PGF.CreateAccordionContent(scrollContent)

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
            local t = charDB.quickApply.roles
            SetLFGRoles(false, t.tank == true, t.healer == true, t.damage == true)
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

    panel.quickApplyEnable = quickApplyEnable
    panel.quickApplyRoleCheckboxes = quickApplyRoleCheckboxes
    panel.quickApplyAutoAccept = autoAcceptCheckbox

    content:SetHeight(y + CONTENT_PADDING)

    table.insert(sections, {
        id = "quickApply",
        header = header,
        content = content,
    })
end
