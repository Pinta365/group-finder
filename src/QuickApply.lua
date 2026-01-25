--[[
    PintaGroupFinder - Quick Apply Module
    
    Handles auto-joining groups with pre-selected roles, bypassing the role selection dialog.
    Hold Shift when clicking to show the normal dialog.
]]

local addonName, PGF = ...

local notePersistenceEnabled = false

---Update Blizzard's role storage with our saved preferences.
local function UpdateBlizzardRoles()
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
    local roles = quickApply.roles or {}
    
    local leader = false
    SetLFGRoles(leader, roles.tank == true, roles.healer == true, roles.damage == true)
end

---Load roles from Blizzard's storage into our database.
local function LoadRolesFromBlizzard()
    local _, tank, healer, dps = GetLFGRoles()
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    if not charDB.quickApply then charDB.quickApply = {} end
    if not charDB.quickApply.roles then charDB.quickApply.roles = {} end
    
    charDB.quickApply.roles.tank = tank
    charDB.quickApply.roles.healer = healer
    charDB.quickApply.roles.damage = dps
end

---Get roles from Blizzard's system
---@return RoleSettings
local function GetRolesFromBlizzard()
    local _, tank, healer, dps = GetLFGRoles()
    return {
        tank = tank,
        healer = healer,
        damage = dps,
    }
end

---Custom dialog show handler that preserves note text.
---@param dialog Frame Dialog frame
---@param resultID number? Search result ID
local function CustomDialogShow(dialog, resultID)
    if resultID then
        local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
        dialog.resultID = resultID
        dialog.activityID = searchResultInfo and searchResultInfo.activityIDs and searchResultInfo.activityIDs[1] or 0
    end
    LFGListApplicationDialog_UpdateRoles(dialog)
    StaticPopupSpecial_Show(dialog)
end

---Enable note persistence by replacing the default show function.
local function EnableNotePersistence()
    if not notePersistenceEnabled then
        LFGListApplicationDialog_Show = CustomDialogShow
        notePersistenceEnabled = true
    end
end

---Set role button checked state.
---@param button Frame Role button frame
---@param checked boolean
local function SetRoleButtonChecked(button, checked)
    if not button or not button.CheckButton then return end
    button.CheckButton:SetChecked(checked)
end

---Get role button checked state.
---@param button Frame Role button frame
---@return boolean
local function GetRoleButtonChecked(button)
    if not button or not button.CheckButton then return false end
    return button.CheckButton:GetChecked()
end

---Configure dialog with saved role preferences.
---@param dialog Frame Application dialog frame
---@return boolean True if any role is configured
local function ConfigureDialogRoles(dialog)
    if not dialog then return false end
    
    UpdateBlizzardRoles()
    
    if LFGListApplicationDialog_UpdateRoles then
        LFGListApplicationDialog_UpdateRoles(dialog)
    end
    
    local tankChecked = GetRoleButtonChecked(dialog.TankButton)
    local healerChecked = GetRoleButtonChecked(dialog.HealerButton)
    local dpsChecked = GetRoleButtonChecked(dialog.DamagerButton)
    
    return tankChecked or healerChecked or dpsChecked
end

---Try to set note on dialog.
---@param dialog Frame Application dialog frame
local function SetNoteOnDialog(dialog)
    if not dialog then return end
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
    local note = quickApply.note or ""
    
    if note == "" then return end
    
    if dialog.Description and dialog.Description.EditBox then
        pcall(function()
            dialog.Description.EditBox:SetText(note)
        end)
    end
end

---Setup automatic signup when dialog appears.
local function SetupAutoSignup()
    if not LFGListApplicationDialog then return end
    
    local dialogHandler = function(dialog)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
        
        if not quickApply.enabled or IsShiftKeyDown() then
            return
        end
        
        local roles = GetRolesFromBlizzard()
        local hasAnyRole = roles.tank or roles.healer or roles.damage
        
        if not hasAnyRole then
            return
        end
        
        ConfigureDialogRoles(dialog)
        
        if PGF.UpdateQuickApplyRoles then
            PGF.UpdateQuickApplyRoles()
        end
        
        SetNoteOnDialog(dialog)
        
        if dialog.SignUpButton and dialog.SignUpButton:IsEnabled() then
            dialog.SignUpButton:Click()
        end
    end
    
    LFGListApplicationDialog:HookScript("OnShow", dialogHandler)
end

---Handle entry clicks to initiate quick signup.
local function SetupEntryClickHandler()
    local clickHandler = function(entry, button)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
        
        if not quickApply.enabled or button == "RightButton" or IsShiftKeyDown() then
            return
        end
        
        local roles = GetRolesFromBlizzard()
        local hasAnyRole = roles.tank or roles.healer or roles.damage
        
        if not hasAnyRole then
            return
        end
        
        local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
        if not searchPanel then return end
        
        local canSelect = LFGListSearchPanelUtil_CanSelectResult and 
                         LFGListSearchPanelUtil_CanSelectResult(entry.resultID)
        local buttonEnabled = searchPanel.SignUpButton and searchPanel.SignUpButton:IsEnabled()
        
        if canSelect and buttonEnabled then
            if searchPanel.selectedResult ~= entry.resultID then
                if LFGListSearchPanel_SelectResult then
                    LFGListSearchPanel_SelectResult(searchPanel, entry.resultID)
                end
            end
            
            if LFGListSearchPanel_SignUp then
                LFGListSearchPanel_SignUp(searchPanel)
            end
        end
    end
    
    hooksecurefunc("LFGListSearchEntry_OnClick", clickHandler)
end

---Setup automatic acceptance for party member role confirmation.
local function SetupPartyRoleAutoAccept()
    if not LFDRoleCheckPopup then
        return
    end
    
    local popupHandler = function(popup)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
        
        if not quickApply.enabled or not quickApply.autoAcceptParty or IsShiftKeyDown() then
            return
        end
        
        local inGroup = IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
        local isLeader = UnitIsGroupLeader("player")
        
        if not inGroup or isLeader then
            return
        end
        
        local roles = GetRolesFromBlizzard()
        
        SetRoleButtonChecked(LFDRoleCheckPopupRoleButtonTank, roles.tank)
        SetRoleButtonChecked(LFDRoleCheckPopupRoleButtonHealer, roles.healer)
        SetRoleButtonChecked(LFDRoleCheckPopupRoleButtonDPS, roles.damage)
        
        local tankSelected = GetRoleButtonChecked(LFDRoleCheckPopupRoleButtonTank)
        local healerSelected = GetRoleButtonChecked(LFDRoleCheckPopupRoleButtonHealer)
        local dpsSelected = GetRoleButtonChecked(LFDRoleCheckPopupRoleButtonDPS)
        
        if not (tankSelected or healerSelected or dpsSelected) then
            return
        end
        
        if LFDRoleCheckPopupAcceptButton then
            LFDRoleCheckPopupAcceptButton:Enable()
            LFDRoleCheckPopupAcceptButton:Click()
        end
    end
    
    LFDRoleCheckPopup:HookScript("OnShow", popupHandler)
end

---Monitor and sync role changes from Blizzard's UI.
local function SetupRoleChangeMonitoring()
    local roleChangeHandler = function(leader, tank, healer, dps)
        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        if not charDB.quickApply then charDB.quickApply = {} end
        if not charDB.quickApply.roles then charDB.quickApply.roles = {} end
        
        charDB.quickApply.roles.tank = tank
        charDB.quickApply.roles.healer = healer
        charDB.quickApply.roles.damage = dps
        
        if PGF.UpdateQuickApplyRoles then
            PGF.UpdateQuickApplyRoles()
        end
    end
    
    hooksecurefunc("SetLFGRoles", roleChangeHandler)
    
    local roleButtonHandler = _G["LFGListRoleButtonCheckButton_OnClick"]
    if roleButtonHandler then
        local buttonClickHandler = function(button)
            if PGF.UpdateQuickApplyRoles then
                PGF.UpdateQuickApplyRoles()
            end
        end
        hooksecurefunc("LFGListRoleButtonCheckButton_OnClick", buttonClickHandler)
    end
end

---Initialize Quick Apply system.
function PGF.InitializeQuickApply()
    if not LFGListFrame then
        C_Timer.After(0.5, PGF.InitializeQuickApply)
        return
    end
    
    local charDB = PintaGroupFinderCharDB or PGF.charDefaults
    local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
    local roles = quickApply.roles or {}
    local hasRolesInDB = (roles.tank ~= nil) or (roles.healer ~= nil) or (roles.damage ~= nil)
    
    if not hasRolesInDB then
        LoadRolesFromBlizzard()
    else
        UpdateBlizzardRoles()
    end
    
    SetupRoleChangeMonitoring()
    EnableNotePersistence()
    SetupAutoSignup()
    SetupEntryClickHandler()
    SetupPartyRoleAutoAccept()
    
    PGF.Debug("Quick Apply initialized")
end
