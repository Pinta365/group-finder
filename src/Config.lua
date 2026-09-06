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
---@field hideIncompatibleGroups boolean?
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
---@field primarySort string "age"|"rating"|"groupSize"|"ilvl"|"name"
---@field primarySortDirection string "asc"|"desc"
---@field secondarySort string? "age"|"rating"|"groupSize"|"ilvl"|"name"|nil
---@field secondarySortDirection string? "asc"|"desc"|nil
---@field movePendingGroupsToTop boolean?

---@class UISettings
---@field showLeaderRating boolean
---@field showAge boolean
---@field showMissingRoles boolean
---@field showLeaderIcon boolean
---@field showDungeonSpecIcons boolean
---@field showBloodlustIcon boolean
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
        showRaidSpecIndicators = true,
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
    },
}

---M+ score color tiers from Raider.IO API.
---Format: { minScore, r, g, b } - scores below first tier use gray.
---@type number[][]
PGF.SCORE_COLORS = {
    { 3600, 1.00, 0.50, 0.00 },
    { 3540, 1.00, 0.49, 0.09 },
    { 3515, 0.99, 0.49, 0.14 },
    { 3490, 0.99, 0.48, 0.17 },
    { 3465, 0.98, 0.47, 0.21 },
    { 3445, 0.98, 0.46, 0.24 },
    { 3420, 0.97, 0.45, 0.27 },
    { 3395, 0.96, 0.44, 0.29 },
    { 3370, 0.96, 0.44, 0.32 },
    { 3345, 0.95, 0.43, 0.34 },
    { 3325, 0.95, 0.42, 0.36 },
    { 3300, 0.94, 0.41, 0.39 },
    { 3275, 0.93, 0.40, 0.41 },
    { 3250, 0.93, 0.39, 0.44 },
    { 3225, 0.92, 0.38, 0.45 },
    { 3205, 0.91, 0.37, 0.48 },
    { 3180, 0.91, 0.36, 0.50 },
    { 3155, 0.90, 0.36, 0.52 },
    { 3130, 0.89, 0.35, 0.55 },
    { 3105, 0.88, 0.34, 0.56 },
    { 3085, 0.87, 0.33, 0.59 },
    { 3060, 0.86, 0.33, 0.61 },
    { 3035, 0.85, 0.31, 0.63 },
    { 3010, 0.84, 0.31, 0.65 },
    { 2985, 0.83, 0.30, 0.67 },
    { 2965, 0.82, 0.29, 0.69 },
    { 2940, 0.80, 0.28, 0.72 },
    { 2915, 0.79, 0.27, 0.74 },
    { 2890, 0.78, 0.27, 0.76 },
    { 2865, 0.76, 0.26, 0.78 },
    { 2845, 0.75, 0.25, 0.80 },
    { 2820, 0.73, 0.24, 0.82 },
    { 2795, 0.72, 0.24, 0.85 },
    { 2770, 0.70, 0.23, 0.87 },
    { 2745, 0.68, 0.22, 0.89 },
    { 2725, 0.66, 0.22, 0.91 },
    { 2700, 0.64, 0.21, 0.93 },
    { 2665, 0.61, 0.24, 0.93 },
    { 2640, 0.57, 0.27, 0.92 },
    { 2615, 0.54, 0.30, 0.91 },
    { 2590, 0.50, 0.33, 0.91 },
    { 2570, 0.46, 0.35, 0.90 },
    { 2545, 0.42, 0.36, 0.90 },
    { 2520, 0.38, 0.38, 0.89 },
    { 2495, 0.33, 0.40, 0.89 },
    { 2470, 0.26, 0.41, 0.88 },
    { 2450, 0.18, 0.43, 0.87 },
    { 2425, 0.00, 0.44, 0.87 },
    { 2350, 0.09, 0.45, 0.85 },
    { 2325, 0.14, 0.46, 0.84 },
    { 2300, 0.17, 0.47, 0.84 },
    { 2275, 0.20, 0.48, 0.82 },
    { 2255, 0.22, 0.49, 0.81 },
    { 2230, 0.24, 0.50, 0.80 },
    { 2205, 0.25, 0.51, 0.79 },
    { 2180, 0.27, 0.52, 0.78 },
    { 2155, 0.28, 0.53, 0.76 },
    { 2135, 0.29, 0.55, 0.76 },
    { 2110, 0.31, 0.56, 0.75 },
    { 2085, 0.31, 0.56, 0.73 },
    { 2060, 0.32, 0.58, 0.72 },
    { 2035, 0.33, 0.59, 0.71 },
    { 2015, 0.34, 0.60, 0.70 },
    { 1990, 0.35, 0.61, 0.69 },
    { 1965, 0.35, 0.62, 0.67 },
    { 1940, 0.35, 0.63, 0.66 },
    { 1915, 0.36, 0.64, 0.65 },
    { 1895, 0.36, 0.65, 0.64 },
    { 1870, 0.36, 0.66, 0.63 },
    { 1845, 0.37, 0.67, 0.62 },
    { 1820, 0.37, 0.69, 0.60 },
    { 1795, 0.37, 0.70, 0.59 },
    { 1775, 0.37, 0.71, 0.58 },
    { 1750, 0.37, 0.72, 0.56 },
    { 1725, 0.37, 0.73, 0.55 },
    { 1700, 0.37, 0.74, 0.54 },
    { 1675, 0.37, 0.75, 0.53 },
    { 1655, 0.37, 0.76, 0.51 },
    { 1630, 0.37, 0.77, 0.50 },
    { 1605, 0.36, 0.78, 0.49 },
    { 1580, 0.36, 0.80, 0.47 },
    { 1555, 0.36, 0.81, 0.46 },
    { 1535, 0.36, 0.82, 0.44 },
    { 1510, 0.35, 0.83, 0.43 },
    { 1485, 0.35, 0.84, 0.41 },
    { 1460, 0.34, 0.85, 0.40 },
    { 1435, 0.33, 0.86, 0.38 },
    { 1415, 0.32, 0.87, 0.36 },
    { 1390, 0.31, 0.89, 0.35 },
    { 1365, 0.30, 0.90, 0.33 },
    { 1340, 0.29, 0.91, 0.31 },
    { 1315, 0.28, 0.92, 0.29 },
    { 1295, 0.27, 0.93, 0.27 },
    { 1270, 0.25, 0.94, 0.24 },
    { 1245, 0.23, 0.95, 0.21 },
    { 1220, 0.21, 0.96, 0.18 },
    { 1195, 0.19, 0.98, 0.15 },
    { 1175, 0.16, 0.99, 0.09 },
    { 1150, 0.12, 1.00, 0.00 },
    { 1125, 0.20, 1.00, 0.10 },
    { 1100, 0.25, 1.00, 0.16 },
    { 1075, 0.30, 1.00, 0.20 },
    { 1050, 0.34, 1.00, 0.24 },
    { 1025, 0.38, 1.00, 0.27 },
    { 1000, 0.41, 1.00, 0.30 },
    { 975, 0.44, 1.00, 0.33 },
    { 950, 0.46, 1.00, 0.35 },
    { 925, 0.49, 1.00, 0.38 },
    { 900, 0.51, 1.00, 0.40 },
    { 875, 0.54, 1.00, 0.43 },
    { 850, 0.56, 1.00, 0.45 },
    { 825, 0.58, 1.00, 0.47 },
    { 800, 0.60, 1.00, 0.50 },
    { 775, 0.62, 1.00, 0.52 },
    { 750, 0.64, 1.00, 0.54 },
    { 725, 0.66, 1.00, 0.56 },
    { 700, 0.68, 1.00, 0.58 },
    { 675, 0.70, 1.00, 0.61 },
    { 650, 0.72, 1.00, 0.63 },
    { 625, 0.74, 1.00, 0.65 },
    { 600, 0.75, 1.00, 0.67 },
    { 575, 0.77, 1.00, 0.69 },
    { 550, 0.79, 1.00, 0.71 },
    { 525, 0.80, 1.00, 0.73 },
    { 500, 0.82, 1.00, 0.75 },
    { 475, 0.84, 1.00, 0.77 },
    { 450, 0.85, 1.00, 0.80 },
    { 425, 0.87, 1.00, 0.82 },
    { 400, 0.88, 1.00, 0.84 },
    { 375, 0.90, 1.00, 0.85 },
    { 350, 0.91, 1.00, 0.88 },
    { 325, 0.93, 1.00, 0.90 },
    { 300, 0.94, 1.00, 0.92 },
    { 275, 0.96, 1.00, 0.94 },
    { 250, 0.97, 1.00, 0.96 },
    { 225, 0.98, 1.00, 0.98 },
    { 200, 1.00, 1.00, 1.00 },
}
