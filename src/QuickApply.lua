--[[
    PintaGroupFinder - Quick Apply Module
    
    Handles auto-joining groups with pre-selected roles, bypassing the role selection dialog.
    Hold Shift when clicking to show the normal dialog.
]]

local addonName, PGF = ...

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

---Set checked state on LFD role-check popup role buttons.
---Blizzard uses `LFGRole_*` (lowercase `checkButton` on the template); LFGList dialog uses `CheckButton`.
---@param button Frame LFDRoleCheckPopupRoleButton*
---@param checked boolean
local function SetLFDRolePopupRoleChecked(button, checked)
    if not button then return end
    if LFGRole_SetChecked then
        LFGRole_SetChecked(button, checked)
    elseif button.checkButton then
        button.checkButton:SetChecked(checked)
    elseif button.CheckButton then
        button.CheckButton:SetChecked(checked)
    end
end

---Read checked state from LFD role-check popup role buttons.
---@param button Frame LFDRoleCheckPopupRoleButton*
---@return boolean
local function GetLFDRolePopupRoleChecked(button)
    if not button then return false end
    if LFGRole_GetChecked then
        return LFGRole_GetChecked(button)
    end
    if button.checkButton then
        return button.checkButton:GetChecked()
    end
    if button.CheckButton then
        return button.CheckButton:GetChecked()
    end
    return false
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

        if dialog.SignUpButton and dialog.SignUpButton:IsEnabled() then
            --LFGListApplicationDialogSignUpButton_OnClick(dialog.SignUpButton)
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
                PGF.Debug("Quick apply: signing up for", entry.resultID)
                LFGListSearchPanel_SignUp(searchPanel)
            end
        end
    end
    
    hooksecurefunc("LFGListSearchEntry_OnClick", clickHandler)
end

local partyRoleAutoAcceptHooked = false
local partyRoleAutoAcceptRetryScheduled = false

---Setup automatic acceptance for party member role confirmation.
local function SetupPartyRoleAutoAccept()
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
        
        SetLFDRolePopupRoleChecked(LFDRoleCheckPopupRoleButtonTank, roles.tank)
        SetLFDRolePopupRoleChecked(LFDRoleCheckPopupRoleButtonHealer, roles.healer)
        SetLFDRolePopupRoleChecked(LFDRoleCheckPopupRoleButtonDPS, roles.damage)
        
        if LFGRoleCheckPopup_UpdatePvPRoles then
            LFGRoleCheckPopup_UpdatePvPRoles()
        end
        if LFDRoleCheckPopup_UpdateAcceptButton then
            LFDRoleCheckPopup_UpdateAcceptButton()
        end
        
        local tankSelected = GetLFDRolePopupRoleChecked(LFDRoleCheckPopupRoleButtonTank)
        local healerSelected = GetLFDRolePopupRoleChecked(LFDRoleCheckPopupRoleButtonHealer)
        local dpsSelected = GetLFDRolePopupRoleChecked(LFDRoleCheckPopupRoleButtonDPS)
        
        if not (tankSelected or healerSelected or dpsSelected) then
            return
        end
        
        local acceptBtn = LFDRoleCheckPopupAcceptButton
        if acceptBtn and acceptBtn:IsEnabled() then
            PGF.Debug("Auto-accept: accepting role check")
            --LFDRoleCheckPopupAccept_OnClick()
            acceptBtn:Click()
        end
    end
    
    local function tryHook()
        if partyRoleAutoAcceptHooked then
            return true
        end
        local popup = LFDRoleCheckPopup
        if not popup then
            return false
        end
        popup:HookScript("OnShow", popupHandler)
        partyRoleAutoAcceptHooked = true
        PGF.Debug("Party role auto-accept: hooked LFDRoleCheckPopup")
        return true
    end
    
    if tryHook() then
        return
    end
    
    if partyRoleAutoAcceptRetryScheduled then
        return
    end
    partyRoleAutoAcceptRetryScheduled = true
    
    local attempts = 0
    local maxAttempts = 40
    local function retry()
        if partyRoleAutoAcceptHooked or tryHook() then
            return
        end
        attempts = attempts + 1
        if attempts < maxAttempts then
            C_Timer.After(0.25, retry)
        else
            partyRoleAutoAcceptRetryScheduled = false
            PGF.Debug("Party role auto-accept: LFDRoleCheckPopup not found after retries")
        end
    end
    C_Timer.After(0.25, retry)
end

local KEEP_ROLE_WATCH_SECONDS = 30
local VALID_ROLES = { TANK = true, HEALER = true, DAMAGER = true }

---Keep the role you applied with after joining a group.
---The game can reassign your group role to your current spec's role on join
---(e.g. applying as healer while in a DPS spec). For a short window after
---accepting an invite, restore the applied role once if it was changed.
---Stops watching as soon as another player (e.g. the leader) sets your role.
local function SetupKeepAppliedRole()
    local wantedRole
    local watchUntil = 0

    local function checkRole()
        if not wantedRole then return end
        if GetTime() > watchUntil or not IsInGroup() then
            wantedRole = nil
            return
        end

        if InCombatLockdown() then return end

        -- "NONE" means the join hasn't assigned a role yet; wait so the single restore isn't spent early
        local current = UnitGroupRolesAssigned("player")
        if current == wantedRole or current == "NONE" then
            return
        end

        PGF.Debug("Keep applied role: restoring", wantedRole, "was", current)
        UnitSetRole("player", wantedRole)
        -- Restore only once so later role changes are left alone
        wantedRole = nil
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    frame:RegisterEvent("ROLE_CHANGED_INFORM")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ROLE_CHANGED_INFORM" then
            -- Someone else (usually the leader) set our role: respect it and stop watching
            local changedName, fromName = ...
            if not wantedRole or not changedName or not fromName or fromName == "" then return end
            if issecretvalue and (issecretvalue(changedName) or issecretvalue(fromName)) then return end
            if UnitIsUnit(changedName, "player") and not UnitIsUnit(fromName, "player") then
                PGF.Debug("Keep applied role: role set by", fromName, "- no longer watching")
                wantedRole = nil
            end
            return
        end

        if event ~= "LFG_LIST_APPLICATION_STATUS_UPDATED" then
            checkRole()
            return
        end

        local resultID, newStatus = ...
        if newStatus ~= "inviteaccepted" then return end

        local charDB = PintaGroupFinderCharDB or PGF.charDefaults
        local quickApply = charDB.quickApply or PGF.charDefaults.quickApply
        if not quickApply.enabled or not quickApply.keepAppliedRole then return end

        local _, _, _, _, role = C_LFGList.GetApplicationInfo(resultID)
        if not role or (issecretvalue and issecretvalue(role)) or not VALID_ROLES[role] then
            return
        end

        wantedRole = role
        watchUntil = GetTime() + KEEP_ROLE_WATCH_SECONDS

        -- The server can assign roles a moment after the join completes
        C_Timer.After(1, checkRole)
        C_Timer.After(3, checkRole)
    end)
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
    SetupAutoSignup()
    SetupEntryClickHandler()
    SetupPartyRoleAutoAccept()
    SetupKeepAppliedRole()
    
    PGF.Debug("Quick Apply initialized")
end
