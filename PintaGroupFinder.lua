--[[
    PintaGroupFinder - Main Entry Point
    
    A group finder addon for World of Warcraft.
]]

local addonName, PGF = ...

local eventFrame = CreateFrame("Frame")

function eventFrame:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

eventFrame:SetScript("OnEvent", eventFrame.OnEvent)

---Recursively merge defaults into saved variables.
---@param saved table Saved variables table
---@param defaults table Default values table
local function MergeDefaults(saved, defaults)
    for key, defaultValue in pairs(defaults) do
        if saved[key] == nil then
            saved[key] = type(defaultValue) == "table" and CopyTable(defaultValue) or defaultValue
        elseif type(defaultValue) == "table" and type(saved[key]) == "table" then
            MergeDefaults(saved[key], defaultValue)
        end
    end
end

---@param loadedAddon string
function eventFrame:ADDON_LOADED(loadedAddon)
    if loadedAddon ~= addonName then return end
    
    if PGF.InitializeLocale then
        PGF.InitializeLocale()
    end
    
    if not PintaGroupFinderDB then
        PintaGroupFinderDB = CopyTable(PGF.defaults)
    else
        MergeDefaults(PintaGroupFinderDB, PGF.defaults)
    end
    
    if not PintaGroupFinderCharDB then
        PintaGroupFinderCharDB = CopyTable(PGF.charDefaults)
    else
        MergeDefaults(PintaGroupFinderCharDB, PGF.charDefaults)
    end
    local quickApply = PintaGroupFinderCharDB.quickApply or {}
    local roles = quickApply.roles or {}
    local hasRolesInDB = (roles.tank == true) or (roles.healer == true) or (roles.damage == true)
    
    if not hasRolesInDB then
        local _, tank, healer, dps = GetLFGRoles()
        local hasBlizzardRoles = tank or healer or dps
        if hasBlizzardRoles then
            if not PintaGroupFinderCharDB.quickApply then
                PintaGroupFinderCharDB.quickApply = {}
            end
            if not PintaGroupFinderCharDB.quickApply.roles then
                PintaGroupFinderCharDB.quickApply.roles = {}
            end
            PintaGroupFinderCharDB.quickApply.roles.tank = tank
            PintaGroupFinderCharDB.quickApply.roles.healer = healer
            PintaGroupFinderCharDB.quickApply.roles.damage = dps
        end
    end
    
    PGF.debug = PintaGroupFinderDB.debug
    
    PGF.Print("v" .. PGF.version, "loaded. Type /pgf for options.")
    self:UnregisterEvent("ADDON_LOADED")
end

function eventFrame:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        PGF.Debug("Player entered world - initializing modules")
        PGF.InitializeFilterCore()
        PGF.InitializeFilterPanel()
        PGF.InitializeEntryEnhancements()
        PGF.InitializeQuickApply()
        eventFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
    end
end

function eventFrame:LFG_LIST_SEARCH_RESULTS_RECEIVED()
    PGF.Debug("Search results received, re-rendering filtered results")
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    if panel and panel.results and LFGListSearchPanel_UpdateResults then
        LFGListSearchPanel_UpdateResults(panel)
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

---Handle slash command input.
---@param msg string Command message
local function SlashHandler(msg)
    local cmd = msg:lower():trim()
    
    if cmd == "debug" then
        PGF.debug = not PGF.debug
        PintaGroupFinderDB.debug = PGF.debug
        PGF.Print("Debug mode:", PGF.debug and "ON" or "OFF")
    elseif cmd == "filter" or cmd == "panel" then
        local db = PintaGroupFinderDB or PGF.defaults
        db.ui = db.ui or {}
        local currentState = db.ui.filterPanelShown ~= false
        local newState = not currentState
        db.ui.filterPanelShown = newState
        PGF.ShowFilterPanel(newState, true)
        PGF.Print("Filter panel:", newState and "shown" or "hidden")
    elseif cmd == "reset" then
        PintaGroupFinderDB = CopyTable(PGF.defaults)
        PintaGroupFinderCharDB = CopyTable(PGF.charDefaults)
        PGF.debug = PGF.defaults.debug
        
        local _, tank, healer, dps = GetLFGRoles()
        local hasBlizzardRoles = tank or healer or dps
        
        if hasBlizzardRoles then
            if not PintaGroupFinderCharDB.quickApply then
                PintaGroupFinderCharDB.quickApply = {}
            end
            if not PintaGroupFinderCharDB.quickApply.roles then
                PintaGroupFinderCharDB.quickApply.roles = {}
            end
            PintaGroupFinderCharDB.quickApply.roles.tank = tank
            PintaGroupFinderCharDB.quickApply.roles.healer = healer
            PintaGroupFinderCharDB.quickApply.roles.damage = dps
            PGF.Print("All settings reset to defaults")
            PGF.Print("Quick Apply roles synced from Blizzard's saved roles")
        else
            PGF.Print("All settings reset to defaults")
        end
        
        PGF.Print("Reloading UI to apply changes...")
        ReloadUI()
    else
        PGF.Print("Commands:")
        PGF.Print("  /pgf debug - Toggle debug mode")
        PGF.Print("  /pgf filter - Toggle filter panel")
        PGF.Print("  /pgf reset - Reset all settings to defaults")
    end
end

SLASH_PINTAGROUPFINDER1 = "/pgf"
SLASH_PINTAGROUPFINDER2 = "/pintagroupfinder"
SlashCmdList["PINTAGROUPFINDER"] = SlashHandler
