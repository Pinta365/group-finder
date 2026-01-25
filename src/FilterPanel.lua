--[[
    PintaGroupFinder - Filter Panel Module
    
    Side panel UI for filter controls.
]]

local addonName, PGF = ...

local filterPanel = nil
local originalPVEFrameWidth = nil
local PANEL_WIDTH = 280

-- Store original widths per tab (tab 1 = Group Finder, tab 2 = PvP, etc.)
local originalTabWidths = {}

---Update activity list based on current category.
---@param categoryID number
local function UpdateActivityList(categoryID)
    if not filterPanel then
        return
    end
    
    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        PGF.UpdateDungeonFilterPanel(filterPanel, categoryID)
    end
end

---Create difficulty checkboxes for a category (delegates to category-specific modules).
---@param categoryID number
local function CreateDifficultyCheckboxes(categoryID)
    if not filterPanel then
        return
    end
    
    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        local difficulties = PGF.GetDungeonDifficulties()
        if not filterPanel.difficultyCheckboxes then
            return
        end
        
        for _, diff in ipairs(difficulties) do
            local checkbox = filterPanel.difficultyCheckboxes[diff.key]
            if checkbox then
                checkbox:Show()
            end
        end
    end
end

---Create category-specific filter UI section.
---@param categoryID number
local function CreateCategoryFilterSection(categoryID)
    if not filterPanel then
        return -10
    end
    
    -- Only create if not already created
    if filterPanel.categoryUICreated then
        return filterPanel.categoryUIYOffset or -10
    end
    
    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        local yOffset = PGF.CreateDungeonFilterSection(filterPanel, PANEL_WIDTH)
        filterPanel.categoryUICreated = true
        filterPanel.categoryUIYOffset = yOffset
        return yOffset
    end
    
    -- Future: Add other categories here (Raid, PvP, etc.)
    return -10
end

---Update UI labels and visibility based on category.
---@param categoryID number
local function UpdateCategoryUI(categoryID)
    if not filterPanel then
        return
    end

    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        if not filterPanel.categoryUICreated then
            CreateCategoryFilterSection(categoryID)
        end
        CreateDifficultyCheckboxes(categoryID)
    end
end

---Create the filter panel UI.
---@return Frame? Filter panel frame
local function CreateFilterPanel()
    if filterPanel then
        return filterPanel
    end
    
    local parent = PVEFrame
    if not parent then
        return nil
    end
    
    if PVEFrame then
        local selectedTab = PVEFrame.selectedTab or 1
        if not originalTabWidths[selectedTab] then
            originalTabWidths[selectedTab] = parent:GetWidth()
        end
    end
    
    filterPanel = CreateFrame("Frame", "PGFilterPanel", parent, "BackdropTemplate")
    filterPanel:SetSize(PANEL_WIDTH, 400)
    
    if LFGListFrame then
        filterPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
    else
        filterPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -75)
    end
    
    filterPanel:SetFrameStrata("HIGH")
    filterPanel:SetFrameLevel(100)
    
    filterPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    filterPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    filterPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local headerSpacing = 12
    
    local yOffset = -310
    
    local quickApplyLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    quickApplyLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    quickApplyLabel:SetText("Quick Apply:")
    
    yOffset = yOffset - headerSpacing
    
    local quickApplyEnable = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
    quickApplyEnable:SetSize(20, 20)
    quickApplyEnable:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    
    local enableLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    enableLabel:SetPoint("LEFT", quickApplyEnable, "RIGHT", 5, 0)
    enableLabel:SetText("Enable")
    
    quickApplyEnable:SetScript("OnClick", function(self)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        charDB.quickApply.enabled = self:GetChecked()
    end)
    
    quickApplyEnable:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Enable Quick Apply")
        GameTooltip:AddLine("Click a group to instantly sign up with selected roles.", 1, 1, 1, true)
        GameTooltip:AddLine("Hold Shift when clicking to show the dialog.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    quickApplyEnable:SetScript("OnLeave", GameTooltip_Hide)
    
    yOffset = yOffset - 20
    
    local quickApplyRolesLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    quickApplyRolesLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    quickApplyRolesLabel:SetText("Roles:")
    
    local quickApplyRoleCheckboxes = {}
    local roleButtons = {
        { key = "tank", label = "T" },
        { key = "healer", label = "H" },
        { key = "damage", label = "D" },
    }
    
    local roleX = 55
    for _, role in ipairs(roleButtons) do
        local checkbox = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
        checkbox:SetSize(16, 16)
        checkbox:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", roleX, yOffset)
        
        local label = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
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
    
    yOffset = yOffset - 20
    
    local noteLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    noteLabel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    noteLabel:SetText("Note:")
    
    local noteBox = CreateFrame("EditBox", nil, filterPanel, "InputBoxTemplate")
    noteBox:SetSize(PANEL_WIDTH - 55, 20)
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
        GameTooltip:SetText("Application Note")
        GameTooltip:AddLine("This note will be sent with your application.", 1, 1, 1, true)
        GameTooltip:AddLine("Note persists between sign-ups.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    noteBox:SetScript("OnLeave", GameTooltip_Hide)
    
    yOffset = yOffset - 15
    
    local autoAcceptCheckbox = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
    autoAcceptCheckbox:SetSize(20, 20)
    autoAcceptCheckbox:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, yOffset)
    
    local autoAcceptLabel = filterPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    autoAcceptLabel:SetPoint("LEFT", autoAcceptCheckbox, "RIGHT", 5, 0)
    autoAcceptLabel:SetText("Auto-accept party")
    autoAcceptLabel:SetWidth(PANEL_WIDTH - 40)
    autoAcceptLabel:SetJustifyH("LEFT")
    
    autoAcceptCheckbox:SetScript("OnClick", function(self)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        charDB.quickApply.autoAcceptParty = self:GetChecked()
    end)
    
    autoAcceptCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-Accept Party Sign Up")
        GameTooltip:AddLine("Automatically accept when your party leader signs up.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    autoAcceptCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    
    filterPanel.quickApplyEnable = quickApplyEnable
    filterPanel.quickApplyRoleCheckboxes = quickApplyRoleCheckboxes
    filterPanel.quickApplyNoteBox = noteBox
    filterPanel.quickApplyAutoAccept = autoAcceptCheckbox
    
    return filterPanel
end

---Update Quick Apply role checkboxes from Blizzard's persistent roles.
function PGF.UpdateQuickApplyRoles()
    if not filterPanel or not filterPanel.quickApplyRoleCheckboxes then
        return
    end
    
    local _, tank, healer, dps = GetLFGRoles()
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    if not charDB.quickApply then charDB.quickApply = {} end
    if not charDB.quickApply.roles then charDB.quickApply.roles = {} end
    charDB.quickApply.roles.tank = tank
    charDB.quickApply.roles.healer = healer
    charDB.quickApply.roles.damage = dps
    
    local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
    
    if filterPanel.quickApplyRoleCheckboxes.tank then
        filterPanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
        if availTank then
            filterPanel.quickApplyRoleCheckboxes.tank:SetChecked(tank)
        end
    end
    
    if filterPanel.quickApplyRoleCheckboxes.healer then
        filterPanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
        if availHealer then
            filterPanel.quickApplyRoleCheckboxes.healer:SetChecked(healer)
        end
    end
    
    if filterPanel.quickApplyRoleCheckboxes.damage then
        filterPanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
        if availDPS then
            filterPanel.quickApplyRoleCheckboxes.damage:SetChecked(dps)
        end
    end
end

---Initialize advanced filter with our defaults if not already set.
local function InitializeAdvancedFilterDefaults()
    local advancedFilter = C_LFGList.GetAdvancedFilter()
    if not advancedFilter then
        return
    end
    
    local db = PintaGroupFinderDB or PGF.defaults
    local filter = db.filter or {}
    local difficultyDefaults = filter.difficulty or PGF.defaults.filter.difficulty
    local playstyleDefaults = filter.playstyle or PGF.defaults.filter.playstyle
    
    local difficultyMapping = {
        difficultyNormal = "normal",
        difficultyHeroic = "heroic",
        difficultyMythic = "mythic",
        difficultyMythicPlus = "mythicplus",
    }
    
    local playstyleMapping = {
        generalPlaystyle1 = "learning",
        generalPlaystyle2 = "relaxed",
        generalPlaystyle3 = "competitive",
        generalPlaystyle4 = "carry",
    }
    
    local needsSave = false
    
    for blizzKey, ourKey in pairs(difficultyMapping) do
        if (advancedFilter[blizzKey] == nil or advancedFilter[blizzKey] == false) and difficultyDefaults[ourKey] == true then
            advancedFilter[blizzKey] = true
            needsSave = true
        end
    end
    
    for blizzKey, ourKey in pairs(playstyleMapping) do
        if (advancedFilter[blizzKey] == nil or advancedFilter[blizzKey] == false) and playstyleDefaults[ourKey] == true then
            advancedFilter[blizzKey] = true
            needsSave = true
        end
    end
    
    if needsSave then
        C_LFGList.SaveAdvancedFilter(advancedFilter)
    end
end

---Update filter panel UI from saved settings.
function PGF.UpdateFilterPanel()
    if not filterPanel then
        return
    end
    
    InitializeAdvancedFilterDefaults()
    
    local db = PintaGroupFinderDB or PGF.defaults
    local filter = db.filter or {}
    
    if filterPanel.ratingBox then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter and advancedFilter.minimumRating then
            filterPanel.ratingBox:SetText(advancedFilter.minimumRating > 0 and tostring(advancedFilter.minimumRating) or "")
            filter.minRating = advancedFilter.minimumRating
        else
            filterPanel.ratingBox:SetText(filter.minRating and filter.minRating > 0 and tostring(filter.minRating) or "")
        end
    end
    
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    local categoryID = panel and panel.categoryID
    
    if categoryID then
        UpdateCategoryUI(categoryID)
    end
    
    if filterPanel.difficultyCheckboxes then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            local blizzToOur = {
                difficultyNormal = "normal",
                difficultyHeroic = "heroic",
                difficultyMythic = "mythic",
                difficultyMythicPlus = "mythicplus",
            }
            
            for blizzKey, ourKey in pairs(blizzToOur) do
                local checkbox = filterPanel.difficultyCheckboxes[ourKey]
                if checkbox then
                    local isChecked = advancedFilter[blizzKey] ~= false
                    checkbox:SetChecked(isChecked)
                    
                    if not filter.difficulty then filter.difficulty = {} end
                    filter.difficulty[ourKey] = isChecked
                end
            end
        else
            local difficulty = filter.difficulty or PGF.defaults.filter.difficulty
            
            for key, checkbox in pairs(filterPanel.difficultyCheckboxes) do
                if checkbox and difficulty then
                    checkbox:SetChecked(difficulty[key] == true)
                end
            end
        end
    end
    
    if filterPanel.roleCheckboxes then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            local blizzToOur = {
                hasTank = "tank",
                hasHealer = "healer",
            }
            
            for blizzKey, ourKey in pairs(blizzToOur) do
                local checkboxData = filterPanel.roleCheckboxes[ourKey]
                local checkbox = checkboxData and checkboxData.frame
                if checkbox then
                    local isChecked = advancedFilter[blizzKey] == true
                    checkbox:SetChecked(isChecked)
                    
                    if not filter.hasRole then filter.hasRole = {} end
                    filter.hasRole[ourKey] = isChecked
                end
            end
        else
            local hasRole = filter.hasRole or {}
            for key, checkboxData in pairs(filterPanel.roleCheckboxes) do
                local checkbox = checkboxData and checkboxData.frame
                if checkbox then
                    checkbox:SetChecked(hasRole[key] == true)
                end
            end
        end
    end
    
    if filterPanel.playstyleCheckboxes then
        local advancedFilter = C_LFGList.GetAdvancedFilter()
        if advancedFilter then
            for blizzKey, checkboxData in pairs(filterPanel.playstyleCheckboxes) do
                local checkbox = checkboxData and checkboxData.frame
                if checkbox then
                    local isChecked = advancedFilter[blizzKey] == true
                    checkbox:SetChecked(isChecked)
                end
            end
        else
            local playstyle = filter.playstyle or {}
            local keyToBlizzKey = {
                learning = "generalPlaystyle1",
                relaxed = "generalPlaystyle2",
                competitive = "generalPlaystyle3",
                carry = "generalPlaystyle4",
            }
            for blizzKey, checkboxData in pairs(filterPanel.playstyleCheckboxes) do
                local checkbox = checkboxData and checkboxData.frame
                if checkbox then
                    local isChecked = false
                    for oldKey, mappedBlizzKey in pairs(keyToBlizzKey) do
                        if mappedBlizzKey == blizzKey and playstyle[oldKey] then
                            isChecked = playstyle[oldKey] == true
                            break
                        end
                    end
                    checkbox:SetChecked(isChecked)
                end
            end
        end
    end
    
    if categoryID then
        UpdateActivityList(categoryID)
    end
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
    
    if filterPanel.quickApplyEnable then
        filterPanel.quickApplyEnable:SetChecked(quickApply.enabled == true)
    end
    
    if filterPanel.quickApplyRoleCheckboxes then
        local _, tank, healer, dps = GetLFGRoles()
        local roles = {
            tank = tank,
            healer = healer,
            damage = dps,
        }
        
        if not quickApply.roles then quickApply.roles = {} end
        quickApply.roles.tank = tank
        quickApply.roles.healer = healer
        quickApply.roles.damage = dps
        
        local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
        
        if filterPanel.quickApplyRoleCheckboxes.tank then
            filterPanel.quickApplyRoleCheckboxes.tank:SetShown(availTank)
            if availTank then
                filterPanel.quickApplyRoleCheckboxes.tank:SetChecked(roles.tank)
            end
        end
        
        if filterPanel.quickApplyRoleCheckboxes.healer then
            filterPanel.quickApplyRoleCheckboxes.healer:SetShown(availHealer)
            if availHealer then
                filterPanel.quickApplyRoleCheckboxes.healer:SetChecked(roles.healer)
            end
        end
        
        if filterPanel.quickApplyRoleCheckboxes.damage then
            filterPanel.quickApplyRoleCheckboxes.damage:SetShown(availDPS)
            if availDPS then
                filterPanel.quickApplyRoleCheckboxes.damage:SetChecked(roles.damage)
            end
        end
    end
    
    if filterPanel.quickApplyNoteBox then
        filterPanel.quickApplyNoteBox:SetText(quickApply.note or "")
    end
    
    if filterPanel.quickApplyAutoAccept then
        filterPanel.quickApplyAutoAccept:SetChecked(quickApply.autoAcceptParty ~= false)
    end
end

---Show or hide the filter panel.
---@param show boolean? Show state (nil = toggle)
---@param save boolean? Whether to save state
function PGF.ShowFilterPanel(show, save)
    local db = PintaGroupFinderDB or PGF.defaults
    db.ui = db.ui or {}
    
    if show == nil then
        show = db.ui.filterPanelShown ~= false
    end
    
    if save ~= false and show == true then
        db.ui.filterPanelShown = true
    elseif save == true and show == false then
        db.ui.filterPanelShown = false
    end
    
    if not filterPanel then
        CreateFilterPanel()
    end
    
    if not filterPanel then
        return
    end
    
    if show then
        filterPanel:Show()
        if PVEFrame then
            local selectedTab = PVEFrame.selectedTab or 1
            if selectedTab == 1 then
                if not originalTabWidths[selectedTab] then
                    originalTabWidths[selectedTab] = PVEFrame:GetWidth()
                end
                PVEFrame:SetWidth(originalTabWidths[selectedTab] + PANEL_WIDTH + 5)
            end
        end
    else
        filterPanel:Hide()
        if PVEFrame then
            local selectedTab = PVEFrame.selectedTab or 1
            if originalTabWidths[selectedTab] then
                PVEFrame:SetWidth(originalTabWidths[selectedTab])
            elseif originalPVEFrameWidth then
                PVEFrame:SetWidth(originalPVEFrameWidth)
            end
        end
    end
end

---Initialize filter panel and hook into WoW UI.
function PGF.InitializeFilterPanel()
    if not PVEFrame or not LFGListFrame then
        C_Timer.After(0.5, PGF.InitializeFilterPanel)
        return
    end
    
    if PVEFrame then
        local selectedTab = PVEFrame.selectedTab or 1
        originalTabWidths[selectedTab] = originalTabWidths[selectedTab] or PVEFrame:GetWidth()
    end
    
    C_Timer.After(0.3, InitializeAdvancedFilterDefaults)
    
    CreateFilterPanel()
    
    if not filterPanel then
        return
    end
    
    ---Check if we're in a valid state to show the filter panel.
    ---@return boolean, number? categoryID Returns true if should show, and categoryID if valid
    local function ShouldShowFilterPanel()
        if not filterPanel or not PVEFrame or not PVEFrame:IsVisible() then
            return false
        end
        
        if PVEFrame.selectedTab ~= 1 then
            return false
        end
        
        if not LFGListFrame or not LFGListFrame:IsVisible() then
            return false
        end
        
        if LFGListFrame.activePanel ~= LFGListFrame.SearchPanel then
            return false
        end
        
        local panel = LFGListFrame.SearchPanel
        if not panel or not panel:IsVisible() then
            return false
        end
        
        local categoryID = panel.categoryID
        if not categoryID then
            return false
        end
        
        if not panel.SearchBox or not panel.SearchBox:IsVisible() then
            return false
        end
        
        local db = PintaGroupFinderDB or PGF.defaults
        local categoryMatches = (categoryID == PGF.DUNGEON_CATEGORY_ID)
        local panelEnabled = db.ui and db.ui.filterPanelShown ~= false
        
        return categoryMatches and panelEnabled, categoryID
    end
    
    local function UpdatePanelVisibility()
        local shouldShow, categoryID = ShouldShowFilterPanel()
        
        PGF.ShowFilterPanel(shouldShow, shouldShow)
        
        if shouldShow and categoryID then
            if LFGListFrame then
                filterPanel:ClearAllPoints()
                filterPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 5, -25)
            end
            UpdateCategoryUI(categoryID)
            PGF.UpdateFilterPanel()
        end
    end
    
    local function UpdatePVEFrameWidth()
        if not PVEFrame then return end
        
        local selectedTab = PVEFrame.selectedTab or 1
        
        if not originalTabWidths[selectedTab] then
            originalTabWidths[selectedTab] = PVEFrame:GetWidth()
        end
        
        if originalTabWidths[selectedTab] then
            PVEFrame:SetWidth(originalTabWidths[selectedTab])
        end
    end
    
    PVEFrame:HookScript("OnShow", function()
        UpdatePVEFrameWidth()
        C_Timer.After(0.2, UpdatePanelVisibility)
    end)
    
    PVEFrame:HookScript("OnHide", function()
        PGF.ShowFilterPanel(false, false)
    end)
    
    hooksecurefunc("PVEFrame_ShowFrame", function()
        UpdatePVEFrameWidth()
        C_Timer.After(0.2, UpdatePanelVisibility)
    end)
    
    if LFGListFrame.SearchPanel then
        LFGListFrame.SearchPanel:HookScript("OnShow", function()
            C_Timer.After(0.2, UpdatePanelVisibility)
        end)
    end
    
    hooksecurefunc("LFGListFrame_SetActivePanel", function(frame, panel)
        if panel == LFGListFrame.SearchPanel then
            C_Timer.After(0.2, UpdatePanelVisibility)
        end
    end)
    
    hooksecurefunc("LFGListSearchPanel_SetCategory", function(self, categoryID, filters, baseFilters)
        if categoryID == PGF.DUNGEON_CATEGORY_ID then
            C_Timer.After(0.1, InitializeAdvancedFilterDefaults)
        end
        C_Timer.After(0.2, UpdatePanelVisibility)
    end)
    
    if LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.BackButton then
        LFGListFrame.SearchPanel.BackButton:HookScript("OnClick", function()
            C_Timer.After(0.1, UpdatePanelVisibility)
        end)
    end
    
    if LFGListFrame.SearchPanel.FilterButton then
        LFGListFrame.SearchPanel.FilterButton:HookScript("OnClick", function()
            C_Timer.After(0.3, function()
                PGF.UpdateFilterPanel()
            end)
        end)
    end
    
    C_Timer.After(0.5, UpdatePanelVisibility)
end
