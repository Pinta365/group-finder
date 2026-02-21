--[[
    PintaGroupFinder - Common Filter Panel Utilities

    Shared UI helpers used by all filter panel modules.
    Loaded before any FilterPanel*.lua file.
]]

local addonName, PGF = ...

local HEADER_HEIGHT = 24

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
