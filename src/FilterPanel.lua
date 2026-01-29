--[[
    PintaGroupFinder - Filter Panel Coordinator
    
    Coordinates showing/hiding the appropriate filter panel for each category.
]]

local addonName, PGF = ...

local PANEL_WIDTH = 280
local PVE_BASE_WIDTH = PVE_FRAME_BASE_WIDTH or 563
local WIDENED_WIDTH_OFFSET = PANEL_WIDTH + 5

---Initialize advanced filter with our defaults if not already set.
local function InitializeAdvancedFilterDefaults()
    local advancedFilter = C_LFGList.GetAdvancedFilter()
    
    local db = PintaGroupFinderDB
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

---Check if we're in a valid state to show a filter panel.
---@return boolean, number? Returns true if should show, and categoryID if valid
local function ShouldShowFilterPanel()
    if not PVEFrame or not PVEFrame:IsVisible() then
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
    
    local db = PintaGroupFinderDB
    local categoryMatches = (categoryID == PGF.DUNGEON_CATEGORY_ID) or (categoryID == PGF.RAID_CATEGORY_ID)
    local panelEnabled = db.ui and db.ui.filterPanelShown ~= false
    
    return categoryMatches and panelEnabled, categoryID
end

---Hide all filter panels.
local function HideAllPanels()
    PGF.ShowDungeonPanel(false)
    PGF.ShowRaidPanel(false)
end

---Show the appropriate panel for a category.
---@param categoryID number
local function ShowPanelForCategory(categoryID)
    HideAllPanels()
    
    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        PGF.ShowDungeonPanel(true)
    elseif categoryID == PGF.RAID_CATEGORY_ID then
        PGF.ShowRaidPanel(true)
    end
end

---Set PVEFrame width for tab 1: widened when panel shown, Blizzard default when hidden.
---Other tabs are left alone.
---@param panelShown boolean
local function applyFrameWidthForPanel(panelShown)
    if not PVEFrame then return end
    if (PVEFrame.selectedTab or 1) ~= 1 then return end

    if panelShown then
        PVEFrame:SetWidth(PVE_BASE_WIDTH + WIDENED_WIDTH_OFFSET)
    else
        PVEFrame:SetWidth(PVE_BASE_WIDTH)
    end
end

---Show or hide our panel and set frame width based on current view (dungeon/raid on tab 1 = show; else hide).
local function syncPanelAndFrameWidth()
    local shouldShow, categoryID = ShouldShowFilterPanel()
    if shouldShow and categoryID then
        ShowPanelForCategory(categoryID)
        applyFrameWidthForPanel(true)
    else
        HideAllPanels()
        applyFrameWidthForPanel(false)
    end
end

---Show or hide filter panels.
---@param show boolean? Show state
---@param save boolean? Whether to save state
function PGF.ShowFilterPanel(show, save)
    local db = PintaGroupFinderDB
    db.ui = db.ui or {}
    
    if show == nil then
        show = db.ui.filterPanelShown ~= false
    end
    
    if save ~= false and show == true then
        db.ui.filterPanelShown = true
    elseif save == true and show == false then
        db.ui.filterPanelShown = false
    end
    
    if show then
        syncPanelAndFrameWidth()
    else
        HideAllPanels()
        applyFrameWidthForPanel(false)
    end
end

function PGF.UpdateFilterPanel()
    local shouldShow, categoryID = ShouldShowFilterPanel()
    if shouldShow and categoryID then
        if categoryID == PGF.DUNGEON_CATEGORY_ID then
            PGF.UpdateDungeonPanel()
        elseif categoryID == PGF.RAID_CATEGORY_ID then
            PGF.UpdateRaidPanel()
        end
    end
end

---Update Quick Apply role checkboxes from Blizzard's persistent roles.
function PGF.UpdateQuickApplyRoles()
    local _, tank, healer, dps = GetLFGRoles()
    local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    if not charDB.quickApply then charDB.quickApply = {} end
    if not charDB.quickApply.roles then charDB.quickApply.roles = {} end
    charDB.quickApply.roles.tank = tank
    charDB.quickApply.roles.healer = healer
    charDB.quickApply.roles.damage = dps

    local dungeonPanel = PGF.GetDungeonPanel()
    if dungeonPanel and dungeonPanel.quickApplyRoleCheckboxes then
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
    
    local raidPanel = PGF.GetRaidPanel()
    if raidPanel and raidPanel.quickApplyRoleCheckboxes then
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
end

---Initialize filter panel coordinator and hook into WoW UI.
function PGF.InitializeFilterPanel()
    if not PVEFrame or not LFGListFrame then
        C_Timer.After(0.5, PGF.InitializeFilterPanel)
        return
    end
    
    InitializeAdvancedFilterDefaults()

    PGF.InitializeDungeonPanel()
    PGF.InitializeRaidPanel()

    HideAllPanels()

    PVEFrame:HookScript("OnShow", function()
        syncPanelAndFrameWidth()
    end)
    
    PVEFrame:HookScript("OnHide", function()
        HideAllPanels()
        applyFrameWidthForPanel(false)
    end)
    
    hooksecurefunc("PVEFrame_ShowFrame", function()
        syncPanelAndFrameWidth()
    end)

    if LFGListFrame.SearchPanel then
        LFGListFrame.SearchPanel:HookScript("OnShow", function()
            syncPanelAndFrameWidth()
        end)
    end
    
    hooksecurefunc("LFGListFrame_SetActivePanel", function(frame, panel)
        local isSearch = panel == LFGListFrame.SearchPanel
        if isSearch then
            syncPanelAndFrameWidth()
        else
            HideAllPanels()
            applyFrameWidthForPanel(false)
        end
    end)
    
    -- Runs when a category is selected (e.g. Dungeons, Raids, Arenas, Battlegrounds).
    hooksecurefunc("LFGListSearchPanel_SetCategory", function(self, categoryID, filters, baseFilters)
        if categoryID == PGF.DUNGEON_CATEGORY_ID or categoryID == PGF.RAID_CATEGORY_ID then
            InitializeAdvancedFilterDefaults()
            syncPanelAndFrameWidth()
        else
            HideAllPanels()
            applyFrameWidthForPanel(false)
        end
    end)
    
    if LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.BackButton then
        LFGListFrame.SearchPanel.BackButton:HookScript("OnClick", function()
            syncPanelAndFrameWidth()
        end)
    end
    
    if LFGListFrame.SearchPanel.FilterButton then
        LFGListFrame.SearchPanel.FilterButton:HookScript("OnClick", function()
            C_Timer.After(0.2, function()
                PGF.UpdateFilterPanel()
            end)
        end)
    end

    syncPanelAndFrameWidth()
end
