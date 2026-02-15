--[[
    PintaGroupFinder - Localization Module
    
    Provides localization support with English as the default built-in language.
    Falls back to English if a translation is missing.
    
    Locale files should set a global table: PGF_LOCALE_XX (e.g., PGF_LOCALE_frFR)
    This module will automatically load the appropriate locale based on GetLocale().
]]

local addonName, PGF = ...

-- Default English locale (built-in)
local defaultLocale = {
    -- Quick Apply
    ["QUICK_APPLY"] = "Quick Apply:",
    ["ENABLE"] = "Enable",
    ["ENABLE_QUICK_APPLY"] = "Enable Quick Apply",
    ["ENABLE_QUICK_APPLY_DESC"] = "Click a group to instantly sign up with selected roles.",
    ["ENABLE_QUICK_APPLY_SHIFT"] = "Hold Shift when clicking to show the dialog.",
    ["ROLES"] = "Roles:",
    ["NOTE"] = "Note:",
    ["APPLICATION_NOTE"] = "Application Note",
    ["APPLICATION_NOTE_DESC"] = "This note will be sent with your application.",
    ["APPLICATION_NOTE_PERSIST"] = "Note persists between sign-ups.",
    ["AUTO_ACCEPT_PARTY"] = "Auto-accept party",
    ["AUTO_ACCEPT_PARTY_TITLE"] = "Auto-Accept Party Sign Up",
    ["AUTO_ACCEPT_PARTY_DESC"] = "Automatically accept when your party leader signs up.",
    
    -- Rating
    ["MIN_RATING"] = "Min Rating:",
    ["MIN_RATING_TITLE"] = "Minimum Leader Rating",
    ["MIN_RATING_DESC"] = "Only show groups where the leader has at least this M+ rating.\nSet to 0 or leave empty to disable.",
    
    -- Difficulty
    ["DIFFICULTY"] = "Difficulty:",
    ["DIFFICULTY_NORMAL_DESC"] = "Show Normal difficulty dungeons.",
    ["DIFFICULTY_HEROIC_DESC"] = "Show Heroic difficulty dungeons.",
    ["DIFFICULTY_MYTHIC_DESC"] = "Show Mythic (non-keystone) dungeons.",
    ["DIFFICULTY_MYTHICPLUS_DESC"] = "Show Mythic+ keystone dungeons.",
    
    -- Playstyle
    ["PLAYSTYLE"] = "Playstyle:",
    ["PLAYSTYLE_LEARNING_DESC"] = "Show groups with Learning playstyle.",
    ["PLAYSTYLE_RELAXED_DESC"] = "Show groups with Relaxed playstyle.",
    ["PLAYSTYLE_COMPETITIVE_DESC"] = "Show groups with Competitive playstyle.",
    ["PLAYSTYLE_CARRY_DESC"] = "Show groups offering carries.",
    
    -- Roles
    ["HAS_ROLE"] = "Has Role:",
    ["HAS_TANK"] = "Has Tank",
    ["HAS_HEALER"] = "Has Healer",
    ["HAS_TANK_DESC"] = "Only show groups that already have a tank.",
    ["HAS_HEALER_DESC"] = "Only show groups that already have a healer.",
    ["HIDE_INCOMPATIBLE_GROUPS"] = "Hide incompatible groups",
    ["HIDE_INCOMPATIBLE_GROUPS_DESC"] = "Only show groups that have room for your party's roles (tank/healer/DPS). When solo, hides groups that need none of your selected roles.",
    
    -- Role Requirements
    ["ROLE_REQUIREMENTS"] = "Role Requirements",
    ["ROLE_REQ_DESC"] = "Filter groups by exact role counts (e.g., at least 2 healers).",
    ["OP_GTE"] = ">=",
    ["OP_LTE"] = "<=",
    ["OP_EQ"] = "=",
    
    ["BOSS_FILTER"] = "Boss Filter:",
    ["BOSS_FILTER_ANY"] = "Any",
    ["BOSS_FILTER_FRESH"] = "Fresh Run",
    ["BOSS_FILTER_PARTIAL"] = "Partial Progress",
    
    -- Accordion sections
    ["SECTION_ACTIVITIES"] = "ACTIVITIES",
    ["SECTION_BOSS_FILTER"] = "BOSS FILTER",
    ["SECTION_DIFFICULTY"] = "DIFFICULTY",
    ["SECTION_PLAYSTYLE"] = "PLAYSTYLE",
    ["SECTION_MISC"] = "MISC",
    ["SECTION_ROLE_FILTERING"] = "ROLE FILTERING",
    ["SECTION_QUICK_APPLY"] = "QUICK APPLY",
    ["SECTION_SETTINGS"] = "SETTINGS",
    
    -- Activity buttons
    ["SELECT_ALL"] = "Select All",
    ["DESELECT_ALL"] = "Deselect All",
    
    -- Sorting
    ["SORT_PRIMARY"] = "Primary Sort:",
    ["SORT_SECONDARY"] = "Secondary Sort:",
    ["SORT_DIRECTION"] = "Direction:",
    ["SORT_AGE"] = "Age",
    ["SORT_RATING"] = "Leader Rating",
    ["SORT_GROUP_SIZE"] = "Group Size",
    ["SORT_ILVL"] = "Item Level Req.",
    ["SORT_NAME"] = "Leader Name",
    ["SORT_ASC"] = "Ascending",
    ["SORT_DESC"] = "Descending",
    ["SORT_NONE"] = "None",
    ["DISABLE_CUSTOM_SORTING"] = "Disable custom sorting",
    ["DISABLE_CUSTOM_SORTING_DESC"] = "Use Blizzard's default result sorting",
    ["SHOW_LEADER_ICON"] = "Show leader icon",
    ["SHOW_LEADER_ICON_DESC"] = "Show a crown icon above the group leader in dungeon search results.",
    ["SHOW_DUNGEON_SPEC_ICONS"] = "Show class spec icons",
    ["SHOW_DUNGEON_SPEC_ICONS_DESC"] = "Show specialization icons below filled role slots in dungeon search results.",
    ["SHOW_LEADER_RATING"] = "Show leader rating",
    ["SHOW_LEADER_RATING_DESC"] = "Show the group leader's Mythic+ rating next to the group name.",
    ["SHOW_MISSING_ROLES"] = "Show missing role icons",
    ["SHOW_MISSING_ROLES_DESC"] = "Show desaturated role icons for unfilled slots in dungeon search results.",
    ["SHOW_RAID_SPEC_INDICATORS"] = "Show raid spec indicators",
    ["SHOW_RAID_SPEC_INDICATORS_DESC"] = "Show how many of your class and spec are already in the raid group.",
}

local currentLocale = {}
local currentLocaleCode = "enUS" -- Both GB and US return enUS
local localeInitialized = false

---Initialize locale system.
---Should be called during ADDON_LOADED event.
function PGF.InitializeLocale()
    if localeInitialized then
        return
    end
    
    local locale = GetLocale()
    currentLocaleCode = locale
    
    -- Get locale-specific translations if available
    local localeTable = nil
    if locale ~= "enUS" then
        local localeTableName = "PGF_LOCALE_" .. locale
        localeTable = _G[localeTableName]
        if localeTable and type(localeTable) == "table" then
            PGF.Debug("Loaded locale:", locale)
        else
            PGF.Debug("Locale not found:", locale, "- using English")
            localeTable = nil
        end
    end
    
    if localeTable then
        for key, _ in pairs(defaultLocale) do
            if localeTable[key] then
                currentLocale[key] = localeTable[key]
            end
        end
    end
    localeInitialized = true
end

---Get a localized string.
---@param key string Localization key
---@return string localizedString Returns the localized string or the key if not found
function PGF.L(key)
    if not localeInitialized then
        PGF.InitializeLocale()
    end
    return currentLocale[key] or defaultLocale[key] or key
end

---Get the current locale code.
---@return string localeCode
function PGF.GetLocale()
    return currentLocaleCode
end


