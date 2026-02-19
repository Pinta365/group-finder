--[[
    PintaGroupFinder - Filter Panel Coordinator
    
    Coordinates showing/hiding the appropriate filter panel for each category.
]]

local addonName, PGF = ...

local PANEL_WIDTH = 280
local PVE_BASE_WIDTH = PVE_FRAME_BASE_WIDTH or 563
local WIDENED_WIDTH_OFFSET = PANEL_WIDTH + 5
local widthBeforeWiden = nil
local tabWhenWidened = nil

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
        PGF.Debug("ShouldShow: PVEFrame not visible/missing")
        return false
    end
    
    local selectedTab = PVEFrame.selectedTab
    local lfgVisible = LFGListFrame and LFGListFrame:IsVisible()
    local spCatID = LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID
    local gffSel = GroupFinderFrame and GroupFinderFrame.selection and GroupFinderFrame.selection:GetName() or "nil"
    local pvpSel = PVPQueueFrame and PVPQueueFrame.selection and PVPQueueFrame.selection:GetName() or "nil"
    PGF.Debug("ShouldShow: tab=", selectedTab,
        "| LFGListFrame visible=", lfgVisible,
        "| SearchPanel.categoryID=", spCatID,
        "| GroupFinderFrame.selection=", gffSel,
        "| PVPQueueFrame.selection=", pvpSel)

    if selectedTab ~= 1 and selectedTab ~= 2 then
        PGF.Debug("ShouldShow: wrong tab:", selectedTab)
        return false
    end
    
    if selectedTab == 1 then
        if GroupFinderFrame and LFGListPVEStub and GroupFinderFrame.selection ~= LFGListPVEStub then
            PGF.Debug("ShouldShow: tab1 but GFF.selection is not LFGListPVEStub:", gffSel)
            return false
        end
    elseif selectedTab == 2 then
        if PVPQueueFrame and LFGListPVPStub and PVPQueueFrame.selection ~= LFGListPVPStub then
            PGF.Debug("ShouldShow: tab2 but PVPQueueFrame.selection is not LFGListPVPStub:", pvpSel)
            return false
        end
    end
    
    if not LFGListFrame or not LFGListFrame:IsVisible() then
        PGF.Debug("ShouldShow: LFGListFrame not visible")
        return false
    end
    
    if LFGListFrame.activePanel ~= LFGListFrame.SearchPanel then
        local apName = LFGListFrame.activePanel and LFGListFrame.activePanel:GetName() or "nil"
        PGF.Debug("ShouldShow: activePanel is not SearchPanel:", apName)
        return false
    end
    
    local panel = LFGListFrame.SearchPanel
    if not panel or not panel:IsVisible() then
        PGF.Debug("ShouldShow: SearchPanel not visible")
        return false
    end
    
    local categoryID = panel.categoryID
    if not categoryID then
        PGF.Debug("ShouldShow: SearchPanel.categoryID is nil")
        return false
    end
    
    if not panel.SearchBox or not panel.SearchBox:IsVisible() then
        PGF.Debug("ShouldShow: SearchBox not visible")
        return false
    end
    
    local db = PintaGroupFinderDB
    local categoryMatches = (categoryID == PGF.DUNGEON_CATEGORY_ID)
        or (categoryID == PGF.RAID_CATEGORY_ID)
        or (categoryID == PGF.DELVE_CATEGORY_ID)
        or (categoryID == PGF.ARENA_CATEGORY_ID)
        or (categoryID == PGF.RATED_BG_CATEGORY_ID)
    local panelEnabled = db.ui and db.ui.filterPanelShown ~= false

    PGF.Debug("ShouldShow: categoryID=", categoryID, "| categoryMatches=", categoryMatches, "| panelEnabled=", panelEnabled)
    return categoryMatches and panelEnabled, categoryID
end

---Hide all filter panels.
local function HideAllPanels()
    PGF.ShowDungeonPanel(false)
    PGF.ShowRaidPanel(false)
    PGF.ShowDelvePanel(false)
    PGF.ShowArenaPanel(false)
    PGF.ShowRatedBGPanel(false)
end

---Show the appropriate panel for a category.
---@param categoryID number
local function ShowPanelForCategory(categoryID)
    HideAllPanels()
    
    if categoryID == PGF.DUNGEON_CATEGORY_ID then
        PGF.ShowDungeonPanel(true)
    elseif categoryID == PGF.RAID_CATEGORY_ID then
        PGF.ShowRaidPanel(true)
    elseif categoryID == PGF.DELVE_CATEGORY_ID then
        PGF.ShowDelvePanel(true)
    elseif categoryID == PGF.ARENA_CATEGORY_ID then
        PGF.ShowArenaPanel(true)
    elseif categoryID == PGF.RATED_BG_CATEGORY_ID then
        PGF.ShowRatedBGPanel(true)
    end
end

---Widen or restore PVEFrame for a filter panel.
---@param panelShown boolean
local function applyFrameWidthForPanel(panelShown)
    if not PVEFrame then return end
    local tab = PVEFrame.selectedTab or 1
    if tab ~= 1 and tab ~= 2 then return end

    if panelShown then
        if not widthBeforeWiden then
            widthBeforeWiden = PVEFrame:GetWidth()
            tabWhenWidened = tab
        end
        PVEFrame:SetWidth((widthBeforeWiden or PVE_BASE_WIDTH) + WIDENED_WIDTH_OFFSET)
    else
        if widthBeforeWiden then
            if tab == tabWhenWidened then
                PVEFrame:SetWidth(widthBeforeWiden)
            end
            widthBeforeWiden = nil
            tabWhenWidened = nil
        elseif tab == 1 then
            PVEFrame:SetWidth(PVE_BASE_WIDTH)
        end
        -- PvP tab with no saved width: Let Blizzard manage it.
    end
end

---Show or hide our panel and set frame width based on current view.
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
        elseif categoryID == PGF.DELVE_CATEGORY_ID then
            PGF.UpdateDelvePanel()
        elseif categoryID == PGF.ARENA_CATEGORY_ID then
            PGF.UpdateArenaPanel()
        elseif categoryID == PGF.RATED_BG_CATEGORY_ID then
            PGF.UpdateRatedBGPanel()
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

    local function updatePanel(p)
        if not p or not p.quickApplyRoleCheckboxes then return end
        local cb = p.quickApplyRoleCheckboxes

        if cb.tank then
            cb.tank:SetShown(availTank)
            if availTank then cb.tank:SetChecked(tank) end
        end

        if cb.healer then
            cb.healer:SetShown(availHealer)
            if availHealer then cb.healer:SetChecked(healer) end
        end

        if cb.damage then
            cb.damage:SetShown(availDPS)
            if availDPS then cb.damage:SetChecked(dps) end
        end
    end

    updatePanel(PGF.GetDungeonPanel())
    updatePanel(PGF.GetRaidPanel())
    updatePanel(PGF.GetDelvePanel())
    updatePanel(PGF.GetArenaPanel())
    updatePanel(PGF.GetRatedBGPanel())
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
    PGF.InitializeDelvePanel()
    PGF.InitializeArenaPanel()
    PGF.InitializeRatedBGPanel()

    HideAllPanels()

    PVEFrame:HookScript("OnShow", function()
        PGF.Debug("PVEFrame OnShow, tab=", PVEFrame.selectedTab)
        syncPanelAndFrameWidth()
    end)
    
    PVEFrame:HookScript("OnHide", function()
        HideAllPanels()
        applyFrameWidthForPanel(false)
    end)
    
    hooksecurefunc("PVEFrame_ShowFrame", function(frameName)
        PGF.Debug("PVEFrame_ShowFrame:", frameName, "| tab=", PVEFrame and PVEFrame.selectedTab)
        syncPanelAndFrameWidth()
    end)

    if LFGListFrame.SearchPanel then
        LFGListFrame.SearchPanel:HookScript("OnShow", function()
            PGF.Debug("LFGListFrame.SearchPanel OnShow")
            syncPanelAndFrameWidth()
        end)
    end
    
    hooksecurefunc("LFGListFrame_SetActivePanel", function(frame, panel)
        local pName = panel and panel:GetName() or "nil"
        PGF.Debug("LFGListFrame_SetActivePanel:", pName)
        local isSearch = panel == LFGListFrame.SearchPanel
        if isSearch then
            syncPanelAndFrameWidth()
        else
            HideAllPanels()
            applyFrameWidthForPanel(false)
        end
    end)

    if GroupFinderFrame_ShowGroupFrame then
        hooksecurefunc("GroupFinderFrame_ShowGroupFrame", function(frame)
            local fName = frame and frame:GetName() or "nil"
            PGF.Debug("GroupFinderFrame_ShowGroupFrame:", fName)
            syncPanelAndFrameWidth()
        end)
    end
    
    if PVPQueueFrame_ShowFrame then
        hooksecurefunc("PVPQueueFrame_ShowFrame", function(frame)
            local fName = frame and frame:GetName() or "nil"
            PGF.Debug("PVPQueueFrame_ShowFrame:", fName)
            syncPanelAndFrameWidth()
        end)
    end
    
    -- Runs when a category is selected (e.g. Dungeons, Raids, Arenas, Battlegrounds).
    hooksecurefunc("LFGListSearchPanel_SetCategory", function(self, categoryID, filters, baseFilters)
        PGF.Debug("LFGListSearchPanel_SetCategory: categoryID=", categoryID)
        if categoryID == PGF.DUNGEON_CATEGORY_ID
            or categoryID == PGF.RAID_CATEGORY_ID
            or categoryID == PGF.DELVE_CATEGORY_ID then
            InitializeAdvancedFilterDefaults()
            syncPanelAndFrameWidth()
        elseif categoryID == PGF.ARENA_CATEGORY_ID
            or categoryID == PGF.RATED_BG_CATEGORY_ID then
            syncPanelAndFrameWidth()
        else
            HideAllPanels()
            applyFrameWidthForPanel(false)
        end
    end)
    
    
    if LFGListFrame.SearchPanel.FilterButton then
        LFGListFrame.SearchPanel.FilterButton:HookScript("OnClick", function()
            C_Timer.After(0.2, function()
                PGF.UpdateFilterPanel()
            end)
        end)
    end

    syncPanelAndFrameWidth()
end
