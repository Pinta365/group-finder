--[[
    PintaGroupFinder - Configuration Module
    
    Defines saved variable defaults and constants.
]]

local addonName, PGF = ...

PGF.DUNGEON_CATEGORY_ID  = 2
PGF.RAID_CATEGORY_ID     = 3
PGF.DELVE_CATEGORY_ID    = 121
PGF.ARENA_CATEGORY_ID    = 4
PGF.RATED_BG_CATEGORY_ID = 9

-- SpecializationID for Evoker: Augmentation
PGF.SPEC_ID_AUGMENTATION_EVOKER = 1473

-- Sentinel for "no upper limit" in the raid bosses-defeated range. A real maximum is a
-- boss count, so any negative value is unreachable and safe to overload.
PGF.BOSS_MAX_UNLIMITED = -1

-- Classes that can provide the Bloodlust/Heroism 30% haste effect. 
PGF.BLOODLUST_CLASSES = {
    SHAMAN = true,
    MAGE = true,
    EVOKER = true,
    HUNTER = true,
}

---@class SavedVariables
---@field debug boolean
---@field filter FilterSettings
---@field ui UISettings

---@class FilterSettings
---@field minRating number
---@field dungeons number[]
---@field hasRole HasRoleSettings
---@field raidBossMin number? Minimum bosses defeated (0 = no minimum)
---@field raidBossMax number? Maximum bosses defeated (PGF.BOSS_MAX_UNLIMITED = no maximum)
---@field hideIncompatibleGroups boolean?
---@field hideUnratedLeaders boolean?
---@field regions table<string, boolean>? Region tag -> false to hide that region
---@field difficulty DifficultySettings
---@field playstyle PlaystyleSettings
---@field dungeonSortSettings SortSettings
---@field raidSortSettings SortSettings

---@class HasRoleSettings
---@field tank boolean
---@field healer boolean
---@field tankOrHealer boolean

---@class DifficultySettings
---@field normal boolean
---@field heroic boolean
---@field mythic boolean
---@field mythicplus boolean

---@class PlaystyleSettings
---@field learning boolean
---@field relaxed boolean
---@field competitive boolean
---@field carry boolean

---@class SortSettings
---@field primarySort string "age"|"rating"|"bossProgress"|"groupSize"|"ilvl"|"name"
---@field primarySortDirection string "asc"|"desc"
---@field secondarySort string? "age"|"rating"|"bossProgress"|"groupSize"|"ilvl"|"name"|nil
---@field secondarySortDirection string? "asc"|"desc"|nil
---@field movePendingGroupsToTop boolean?

---@class UISettings
---@field showLeaderRating boolean
---@field showAge boolean
---@field showMissingRoles boolean
---@field showLeaderIcon boolean
---@field showDungeonSpecIcons boolean
---@field showBloodlustIcon boolean
---@field showRegionTag boolean
---@field showRaidBossProgress boolean
---@field showArenaLeaderIcon boolean
---@field showArenaSpecIcons boolean
---@field showRatedBGSpecIndicators boolean
---@field filterPanelShown boolean

---@type SavedVariables
PGF.defaults = {
    debug = false,
    
    filter = {
        minRating = 0,
        dungeons = {},
        hasRole = {
            tank = false,
            healer = false,
            tankOrHealer = false,
            augmentationEvoker = false,
            bloodlust = false
        },
        hideAugmentationEvokers = false,
        hideBloodlustGroups = false,
        hideIncompatibleGroups = false,
        hideSameSpec = false,
        hideUnratedLeaders = false,
        regions = {},
        difficulty = {
            normal = true,
            heroic = true,
            mythic = true,
            mythicplus = true,
        },
        playstyle = {
            learning = true,
            relaxed = true,
            competitive = true,
            carry = true,
        },
        raidBossMin = 0,
        raidBossMax = PGF.BOSS_MAX_UNLIMITED,
        raidRoleRequirements = {
            tank = { enabled = false, operator = ">=", value = 1 },
            healer = { enabled = false, operator = ">=", value = 2 },
            dps = { enabled = false, operator = ">=", value = 0 },
        },
        raidAccordionState = {
            activities = true,
            bossFilter = false,
            difficulty = false,
            playstyle = false,
            roleFiltering = false,
            quickApply = false,
            settings = false,
        },
        dungeonAccordionState = {
            activities = true,
            difficulty = false,
            playstyle = false,
            misc = false,
            quickApply = false,
            settings = false,
            regions = false,
        },
        dungeonSortSettings = {
            disableCustomSorting = true,
            movePendingGroupsToTop = true,
            primarySort = "rating",
            primarySortDirection = "desc",
            secondarySort = nil,
            secondarySortDirection = "desc",
        },
        raidSortSettings = {
            disableCustomSorting = true,
            movePendingGroupsToTop = true,
            primarySort = "groupSize",
            primarySortDirection = "desc",
            secondarySort = nil,
            secondarySortDirection = "desc",
        },
        delveTierMin = 1,
        delveTierMax = 11,
        delveIncludeSpecialTiers = true,
        delvePlaystyle = {
            generalPlaystyle1 = true,
            generalPlaystyle2 = true,
            generalPlaystyle3 = true,
            generalPlaystyle4 = true,
        },
        delveAccordionState = {
            activities = true,
            tier = false,
            playstyle = false,
            quickApply = false,
            settings = false,
        },
        delveSortSettings = {
            disableCustomSorting = true,
            movePendingGroupsToTop = true,
            primarySort = "age",
            primarySortDirection = "asc",
            secondarySort = nil,
            secondarySortDirection = "asc",
        },
        arenaMinPvpRating = 0,
        arenaPlaystyle = {
            generalPlaystyle1 = true,
            generalPlaystyle2 = true,
            generalPlaystyle3 = true,
            generalPlaystyle4 = true,
        },
        arenaAccordionState = {
            activities = true,
            rating = false,
            playstyle = false,
            quickApply = false,
            settings = false,
        },
        arenaSortSettings = {
            disableCustomSorting = true,
            movePendingGroupsToTop = true,
            primarySort = "age",
            primarySortDirection = "asc",
            secondarySort = nil,
            secondarySortDirection = "asc",
        },
        ratedBGMinPvpRating = 0,
        ratedBGPlaystyle = {
            generalPlaystyle1 = true,
            generalPlaystyle2 = true,
            generalPlaystyle3 = true,
            generalPlaystyle4 = true,
        },
        ratedBGAccordionState = {
            activities = true,
            rating = false,
            playstyle = false,
            quickApply = false,
            settings = false,
        },
        ratedBGSortSettings = {
            disableCustomSorting = true,
            movePendingGroupsToTop = true,
            primarySort = "age",
            primarySortDirection = "asc",
            secondarySort = nil,
            secondarySortDirection = "asc",
        },
    },
    
    ui = {
        showLeaderRating = true,
        showAge = true,
        showMissingRoles = true,
        showLeaderIcon = true,
        showDungeonSpecIcons = true,
        showBloodlustIcon = true,
        showRegionTag = true,
        showRaidSpecIndicators = true,
        showRaidBossProgress = true,
        showArenaLeaderIcon = true,
        showArenaSpecIcons = true,
        showRatedBGSpecIndicators = true,
        filterPanelShown = true,
    },
}

---@class CharacterSavedVariables
---@field quickApply QuickApplySettings

---@class QuickApplySettings
---@field enabled boolean
---@field roles RoleSettings
---@field autoAcceptParty boolean
---@field keepAppliedRole boolean

---@class RoleSettings
---@field tank boolean
---@field healer boolean
---@field damage boolean

---@type CharacterSavedVariables
PGF.charDefaults = {
    quickApply = {
        enabled = false,
        roles = {
            tank = false,
            healer = false,
            damage = false,
        },
        autoAcceptParty = false,
        keepAppliedRole = false,
    },
}

---M+ score color tiers from Raider.IO API.
---Format: { minScore, r, g, b } - scores below first tier use gray.
---@type number[][]
PGF.SCORE_COLORS = {
    { 4300, 1.00, 0.50, 0.00 },
    { 4240, 1.00, 0.49, 0.09 },
    { 4215, 0.99, 0.49, 0.14 },
    { 4190, 0.98, 0.47, 0.18 },
    { 4170, 0.98, 0.47, 0.21 },
    { 4145, 0.98, 0.46, 0.24 },
    { 4120, 0.97, 0.45, 0.27 },
    { 4095, 0.96, 0.44, 0.30 },
    { 4070, 0.96, 0.43, 0.32 },
    { 4050, 0.95, 0.42, 0.35 },
    { 4025, 0.95, 0.42, 0.37 },
    { 4000, 0.94, 0.40, 0.40 },
    { 3975, 0.93, 0.40, 0.42 },
    { 3950, 0.93, 0.39, 0.44 },
    { 3930, 0.92, 0.38, 0.46 },
    { 3905, 0.91, 0.37, 0.49 },
    { 3880, 0.90, 0.36, 0.51 },
    { 3855, 0.89, 0.35, 0.53 },
    { 3830, 0.88, 0.35, 0.55 },
    { 3810, 0.87, 0.34, 0.58 },
    { 3785, 0.87, 0.33, 0.60 },
    { 3760, 0.85, 0.32, 0.62 },
    { 3735, 0.84, 0.31, 0.64 },
    { 3710, 0.83, 0.30, 0.67 },
    { 3690, 0.82, 0.29, 0.69 },
    { 3665, 0.81, 0.29, 0.71 },
    { 3640, 0.80, 0.28, 0.73 },
    { 3615, 0.78, 0.27, 0.75 },
    { 3590, 0.77, 0.26, 0.78 },
    { 3570, 0.75, 0.25, 0.80 },
    { 3545, 0.74, 0.24, 0.82 },
    { 3520, 0.72, 0.24, 0.84 },
    { 3495, 0.70, 0.23, 0.87 },
    { 3470, 0.68, 0.22, 0.89 },
    { 3450, 0.66, 0.22, 0.91 },
    { 3425, 0.64, 0.21, 0.93 },
    { 3385, 0.62, 0.24, 0.93 },
    { 3360, 0.59, 0.26, 0.93 },
    { 3335, 0.57, 0.28, 0.92 },
    { 3315, 0.54, 0.30, 0.91 },
    { 3290, 0.51, 0.32, 0.91 },
    { 3265, 0.49, 0.33, 0.91 },
    { 3240, 0.46, 0.35, 0.90 },
    { 3215, 0.43, 0.36, 0.90 },
    { 3195, 0.40, 0.38, 0.89 },
    { 3170, 0.36, 0.39, 0.89 },
    { 3145, 0.32, 0.40, 0.89 },
    { 3120, 0.28, 0.41, 0.88 },
    { 3095, 0.22, 0.42, 0.87 },
    { 3075, 0.15, 0.43, 0.87 },
    { 3050, 0.00, 0.44, 0.87 },
    { 2990, 0.11, 0.45, 0.85 },
    { 2965, 0.17, 0.47, 0.84 },
    { 2940, 0.20, 0.49, 0.82 },
    { 2920, 0.24, 0.50, 0.80 },
    { 2895, 0.26, 0.51, 0.78 },
    { 2870, 0.28, 0.53, 0.77 },
    { 2845, 0.29, 0.55, 0.75 },
    { 2820, 0.31, 0.56, 0.74 },
    { 2800, 0.33, 0.58, 0.72 },
    { 2775, 0.33, 0.59, 0.70 },
    { 2750, 0.35, 0.61, 0.69 },
    { 2725, 0.35, 0.62, 0.67 },
    { 2700, 0.36, 0.64, 0.65 },
    { 2680, 0.36, 0.66, 0.64 },
    { 2655, 0.37, 0.67, 0.62 },
    { 2630, 0.37, 0.69, 0.60 },
    { 2605, 0.37, 0.71, 0.58 },
    { 2580, 0.37, 0.72, 0.56 },
    { 2560, 0.37, 0.74, 0.55 },
    { 2535, 0.37, 0.75, 0.53 },
    { 2510, 0.37, 0.77, 0.51 },
    { 2485, 0.36, 0.78, 0.49 },
    { 2460, 0.36, 0.80, 0.47 },
    { 2440, 0.36, 0.82, 0.44 },
    { 2415, 0.35, 0.84, 0.42 },
    { 2390, 0.34, 0.85, 0.40 },
    { 2365, 0.33, 0.87, 0.38 },
    { 2340, 0.31, 0.88, 0.35 },
    { 2320, 0.30, 0.90, 0.32 },
    { 2295, 0.28, 0.92, 0.29 },
    { 2270, 0.26, 0.93, 0.26 },
    { 2245, 0.24, 0.95, 0.22 },
    { 2220, 0.21, 0.96, 0.18 },
    { 2200, 0.17, 0.98, 0.12 },
    { 2175, 0.12, 1.00, 0.00 },
    { 2150, 0.16, 1.00, 0.06 },
    { 2125, 0.20, 1.00, 0.10 },
    { 2100, 0.23, 1.00, 0.13 },
    { 2075, 0.25, 1.00, 0.15 },
    { 2050, 0.27, 1.00, 0.18 },
    { 2025, 0.30, 1.00, 0.20 },
    { 2000, 0.32, 1.00, 0.22 },
    { 1975, 0.33, 1.00, 0.23 },
    { 1950, 0.35, 1.00, 0.25 },
    { 1925, 0.37, 1.00, 0.26 },
    { 1900, 0.38, 1.00, 0.28 },
    { 1875, 0.40, 1.00, 0.29 },
    { 1850, 0.42, 1.00, 0.31 },
    { 1825, 0.43, 1.00, 0.32 },
    { 1800, 0.44, 1.00, 0.33 },
    { 1775, 0.45, 1.00, 0.35 },
    { 1750, 0.47, 1.00, 0.36 },
    { 1725, 0.48, 1.00, 0.37 },
    { 1700, 0.49, 1.00, 0.38 },
    { 1675, 0.51, 1.00, 0.40 },
    { 1650, 0.52, 1.00, 0.41 },
    { 1625, 0.53, 1.00, 0.42 },
    { 1600, 0.54, 1.00, 0.43 },
    { 1575, 0.55, 1.00, 0.44 },
    { 1550, 0.56, 1.00, 0.45 },
    { 1525, 0.57, 1.00, 0.46 },
    { 1500, 0.58, 1.00, 0.47 },
    { 1475, 0.59, 1.00, 0.49 },
    { 1450, 0.60, 1.00, 0.49 },
    { 1425, 0.61, 1.00, 0.51 },
    { 1400, 0.62, 1.00, 0.52 },
    { 1375, 0.63, 1.00, 0.53 },
    { 1350, 0.64, 1.00, 0.54 },
    { 1325, 0.65, 1.00, 0.55 },
    { 1300, 0.66, 1.00, 0.56 },
    { 1275, 0.67, 1.00, 0.57 },
    { 1250, 0.68, 1.00, 0.58 },
    { 1225, 0.69, 1.00, 0.59 },
    { 1200, 0.70, 1.00, 0.60 },
    { 1175, 0.71, 1.00, 0.61 },
    { 1150, 0.71, 1.00, 0.62 },
    { 1125, 0.72, 1.00, 0.63 },
    { 1100, 0.73, 1.00, 0.64 },
    { 1075, 0.74, 1.00, 0.65 },
    { 1050, 0.75, 1.00, 0.66 },
    { 1025, 0.76, 1.00, 0.67 },
    { 1000, 0.76, 1.00, 0.68 },
    { 975, 0.77, 1.00, 0.69 },
    { 950, 0.78, 1.00, 0.70 },
    { 925, 0.79, 1.00, 0.71 },
    { 900, 0.80, 1.00, 0.72 },
    { 875, 0.80, 1.00, 0.73 },
    { 850, 0.81, 1.00, 0.74 },
    { 825, 0.82, 1.00, 0.75 },
    { 800, 0.83, 1.00, 0.76 },
    { 775, 0.84, 1.00, 0.77 },
    { 750, 0.84, 1.00, 0.78 },
    { 725, 0.85, 1.00, 0.79 },
    { 700, 0.86, 1.00, 0.80 },
    { 675, 0.87, 1.00, 0.81 },
    { 650, 0.87, 1.00, 0.82 },
    { 625, 0.88, 1.00, 0.83 },
    { 600, 0.89, 1.00, 0.84 },
    { 575, 0.89, 1.00, 0.85 },
    { 550, 0.90, 1.00, 0.86 },
    { 525, 0.91, 1.00, 0.87 },
    { 500, 0.92, 1.00, 0.88 },
    { 475, 0.93, 1.00, 0.89 },
    { 450, 0.93, 1.00, 0.90 },
    { 425, 0.94, 1.00, 0.91 },
    { 400, 0.95, 1.00, 0.92 },
    { 375, 0.95, 1.00, 0.93 },
    { 350, 0.96, 1.00, 0.94 },
    { 325, 0.96, 1.00, 0.95 },
    { 300, 0.97, 1.00, 0.96 },
    { 275, 0.98, 1.00, 0.97 },
    { 250, 0.99, 1.00, 0.98 },
    { 225, 0.99, 1.00, 0.99 },
    { 200, 1.00, 1.00, 1.00 },
}
