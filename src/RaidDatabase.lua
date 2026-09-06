--[[
    PintaGroupFinder - Raid Database Module

    Resolves a raid activity to its Encounter Journal boss roster.

    C_LFGList.GetSearchResultEncounterInfo only reports defeated bosses as localized names, with
    no IDs and no indication of how many bosses the raid has in total. The journal fills both
    gaps: it gives the full roster in kill order, and a journalEncounterID per boss that is
    stable across locales and therefore safe to persist in saved variables.
]]

local addonName, PGF = ...

---@class RaidEncounter
---@field id number journalEncounterID, locale-independent and safe to save
---@field name string Localized encounter name, matches GetSearchResultEncounterInfo

-- activityID -> journalInstanceID. Only successful lookups are cached, so a miss caused by the
-- journal not being loaded yet is retried rather than remembered.
local activityToJournalInstance = {}

-- journalInstanceID -> RaidEncounter[]
local instanceRosters = {}

-- No raid comes close to this; it only bounds the scan.
local MAX_ENCOUNTERS = 30

---@param journalInstanceID number
---@return RaidEncounter[] roster Empty when the journal has no data for this instance yet
local function BuildRoster(journalInstanceID)
    local roster = {}

    local function Scan()
        for index = 1, MAX_ENCOUNTERS do
            local name, _, journalEncounterID = EJ_GetEncounterInfoByIndex(index, journalInstanceID)
            if not name or name == "" then
                break
            end
            roster[#roster + 1] = { id = journalEncounterID, name = name }
        end
    end

    Scan()

    if #roster == 0 and EJ_SelectInstance then
        EJ_SelectInstance(journalInstanceID)
        Scan()
    end

    return roster
end

---@param activityID number?
---@return number? journalInstanceID
local function GetJournalInstanceID(activityID)
    if not activityID then
        return nil
    end

    local cached = activityToJournalInstance[activityID]
    if cached then
        return cached
    end

    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    local mapID = activityInfo and activityInfo.mapID
    if not mapID or mapID <= 0 then
        return nil
    end

    if not (C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap) then
        return nil
    end

    local journalInstanceID = C_EncounterJournal.GetInstanceForGameMap(mapID)
    if journalInstanceID then
        activityToJournalInstance[activityID] = journalInstanceID
    end

    return journalInstanceID
end

---Get the ordered boss roster for a raid activity.
---@param activityID number?
---@return RaidEncounter[]? encounters Ordered by kill order, nil when it cannot be resolved
function PGF.GetRaidEncounters(activityID)
    local journalInstanceID = GetJournalInstanceID(activityID)
    if not journalInstanceID then
        return nil
    end

    local roster = instanceRosters[journalInstanceID]
    if roster then
        return roster
    end

    roster = BuildRoster(journalInstanceID)
    if #roster == 0 then
        -- Journal data may simply not be loaded yet; leave it uncached so it retries.
        return nil
    end

    instanceRosters[journalInstanceID] = roster
    return roster
end

---Get the total number of bosses in a raid activity.
---@param activityID number?
---@return number count 0 when the roster cannot be resolved
function PGF.GetRaidEncounterCount(activityID)
    local roster = PGF.GetRaidEncounters(activityID)
    return roster and #roster or 0
end
