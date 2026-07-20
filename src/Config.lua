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
            augmentationEvoker = false
        },
        hideAugmentationEvokers = false,
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
    { 4350, 1.00, 0.50, 0.00 },
    { 4290, 1.00, 0.49, 0.08 },
    { 4265, 0.99, 0.49, 0.13 },
    { 4240, 0.99, 0.48, 0.17 },
    { 4215, 0.98, 0.47, 0.20 },
    { 4190, 0.98, 0.46, 0.24 },
    { 4170, 0.97, 0.45, 0.26 },
    { 4145, 0.97, 0.44, 0.29 },
    { 4120, 0.96, 0.44, 0.31 },
    { 4095, 0.96, 0.43, 0.33 },
    { 4070, 0.95, 0.42, 0.36 },
    { 4050, 0.95, 0.41, 0.38 },
    { 4025, 0.94, 0.40, 0.40 },
    { 4000, 0.93, 0.40, 0.43 },
    { 3975, 0.93, 0.38, 0.45 },
    { 3950, 0.92, 0.38, 0.47 },
    { 3930, 0.91, 0.37, 0.49 },
    { 3905, 0.90, 0.36, 0.51 },
    { 3880, 0.89, 0.35, 0.53 },
    { 3855, 0.89, 0.35, 0.55 },
    { 3830, 0.87, 0.34, 0.58 },
    { 3810, 0.87, 0.33, 0.60 },
    { 3785, 0.85, 0.32, 0.62 },
    { 3760, 0.85, 0.31, 0.64 },
    { 3735, 0.84, 0.31, 0.66 },
    { 3710, 0.82, 0.30, 0.68 },
    { 3690, 0.82, 0.29, 0.70 },
    { 3665, 0.80, 0.28, 0.72 },
    { 3640, 0.79, 0.27, 0.74 },
    { 3615, 0.78, 0.27, 0.76 },
    { 3590, 0.76, 0.26, 0.78 },
    { 3570, 0.75, 0.25, 0.80 },
    { 3545, 0.73, 0.24, 0.83 },
    { 3520, 0.71, 0.24, 0.85 },
    { 3495, 0.70, 0.23, 0.87 },
    { 3470, 0.68, 0.22, 0.89 },
    { 3450, 0.66, 0.22, 0.91 },
    { 3425, 0.64, 0.21, 0.93 },
    { 3385, 0.61, 0.24, 0.93 },
    { 3365, 0.58, 0.27, 0.92 },
    { 3340, 0.56, 0.29, 0.92 },
    { 3315, 0.53, 0.31, 0.91 },
    { 3290, 0.49, 0.33, 0.91 },
    { 3265, 0.46, 0.35, 0.90 },
    { 3245, 0.43, 0.36, 0.90 },
    { 3220, 0.39, 0.38, 0.89 },
    { 3195, 0.35, 0.39, 0.89 },
    { 3170, 0.30, 0.40, 0.88 },
    { 3145, 0.24, 0.42, 0.88 },
    { 3125, 0.16, 0.43, 0.87 },
    { 3100, 0.00, 0.44, 0.87 },
    { 3045, 0.13, 0.46, 0.85 },
    { 3025, 0.19, 0.48, 0.83 },
    { 3000, 0.23, 0.50, 0.81 },
    { 2975, 0.26, 0.51, 0.78 },
    { 2950, 0.28, 0.53, 0.76 },
    { 2925, 0.30, 0.55, 0.75 },
    { 2905, 0.32, 0.57, 0.73 },
    { 2880, 0.33, 0.59, 0.70 },
    { 2855, 0.35, 0.61, 0.68 },
    { 2830, 0.36, 0.63, 0.66 },
    { 2805, 0.36, 0.65, 0.64 },
    { 2785, 0.37, 0.67, 0.62 },
    { 2760, 0.37, 0.69, 0.60 },
    { 2735, 0.37, 0.71, 0.57 },
    { 2710, 0.37, 0.73, 0.55 },
    { 2685, 0.37, 0.75, 0.53 },
    { 2665, 0.37, 0.77, 0.50 },
    { 2640, 0.36, 0.79, 0.47 },
    { 2615, 0.36, 0.82, 0.45 },
    { 2590, 0.35, 0.84, 0.42 },
    { 2565, 0.34, 0.85, 0.39 },
    { 2545, 0.32, 0.87, 0.36 },
    { 2520, 0.31, 0.90, 0.33 },
    { 2495, 0.28, 0.92, 0.29 },
    { 2470, 0.26, 0.94, 0.25 },
    { 2445, 0.22, 0.96, 0.20 },
    { 2425, 0.18, 0.98, 0.14 },
    { 2400, 0.12, 1.00, 0.00 },
    { 2375, 0.16, 1.00, 0.05 },
    { 2350, 0.19, 1.00, 0.09 },
    { 2325, 0.22, 1.00, 0.12 },
    { 2300, 0.24, 1.00, 0.15 },
    { 2275, 0.26, 1.00, 0.16 },
    { 2250, 0.28, 1.00, 0.18 },
    { 2225, 0.30, 1.00, 0.20 },
    { 2200, 0.32, 1.00, 0.22 },
    { 2175, 0.34, 1.00, 0.23 },
    { 2150, 0.35, 1.00, 0.25 },
    { 2125, 0.37, 1.00, 0.26 },
    { 2100, 0.38, 1.00, 0.27 },
    { 2075, 0.40, 1.00, 0.29 },
    { 2050, 0.41, 1.00, 0.30 },
    { 2025, 0.42, 1.00, 0.31 },
    { 2000, 0.44, 1.00, 0.33 },
    { 1975, 0.45, 1.00, 0.34 },
    { 1950, 0.46, 1.00, 0.35 },
    { 1925, 0.47, 1.00, 0.36 },
    { 1900, 0.48, 1.00, 0.37 },
    { 1875, 0.49, 1.00, 0.38 },
    { 1850, 0.50, 1.00, 0.39 },
    { 1825, 0.51, 1.00, 0.40 },
    { 1800, 0.53, 1.00, 0.41 },
    { 1775, 0.53, 1.00, 0.42 },
    { 1750, 0.55, 1.00, 0.43 },
    { 1725, 0.55, 1.00, 0.44 },
    { 1700, 0.56, 1.00, 0.45 },
    { 1675, 0.57, 1.00, 0.46 },
    { 1650, 0.58, 1.00, 0.47 },
    { 1625, 0.59, 1.00, 0.48 },
    { 1600, 0.60, 1.00, 0.49 },
    { 1575, 0.61, 1.00, 0.50 },
    { 1550, 0.62, 1.00, 0.51 },
    { 1525, 0.63, 1.00, 0.52 },
    { 1500, 0.64, 1.00, 0.53 },
    { 1475, 0.64, 1.00, 0.54 },
    { 1450, 0.65, 1.00, 0.55 },
    { 1425, 0.66, 1.00, 0.56 },
    { 1400, 0.67, 1.00, 0.57 },
    { 1375, 0.68, 1.00, 0.58 },
    { 1350, 0.69, 1.00, 0.59 },
    { 1325, 0.69, 1.00, 0.60 },
    { 1300, 0.70, 1.00, 0.61 },
    { 1275, 0.71, 1.00, 0.62 },
    { 1250, 0.72, 1.00, 0.62 },
    { 1225, 0.73, 1.00, 0.64 },
    { 1200, 0.73, 1.00, 0.64 },
    { 1175, 0.74, 1.00, 0.65 },
    { 1150, 0.75, 1.00, 0.66 },
    { 1125, 0.76, 1.00, 0.67 },
    { 1100, 0.76, 1.00, 0.68 },
    { 1075, 0.77, 1.00, 0.69 },
    { 1050, 0.78, 1.00, 0.70 },
    { 1025, 0.78, 1.00, 0.71 },
    { 1000, 0.79, 1.00, 0.71 },
    { 975, 0.80, 1.00, 0.73 },
    { 950, 0.80, 1.00, 0.73 },
    { 925, 0.81, 1.00, 0.74 },
    { 900, 0.82, 1.00, 0.75 },
    { 875, 0.83, 1.00, 0.76 },
    { 850, 0.84, 1.00, 0.77 },
    { 825, 0.84, 1.00, 0.78 },
    { 800, 0.85, 1.00, 0.79 },
    { 775, 0.85, 1.00, 0.80 },
    { 750, 0.86, 1.00, 0.80 },
    { 725, 0.87, 1.00, 0.81 },
    { 700, 0.87, 1.00, 0.82 },
    { 675, 0.88, 1.00, 0.83 },
    { 650, 0.89, 1.00, 0.84 },
    { 625, 0.89, 1.00, 0.85 },
    { 600, 0.90, 1.00, 0.86 },
    { 575, 0.91, 1.00, 0.87 },
    { 550, 0.91, 1.00, 0.87 },
    { 525, 0.92, 1.00, 0.89 },
    { 500, 0.93, 1.00, 0.89 },
    { 475, 0.93, 1.00, 0.90 },
    { 450, 0.94, 1.00, 0.91 },
    { 425, 0.95, 1.00, 0.92 },
    { 400, 0.95, 1.00, 0.93 },
    { 375, 0.96, 1.00, 0.94 },
    { 350, 0.96, 1.00, 0.95 },
    { 325, 0.97, 1.00, 0.96 },
    { 300, 0.98, 1.00, 0.96 },
    { 275, 0.98, 1.00, 0.97 },
    { 250, 0.99, 1.00, 0.98 },
    { 225, 0.99, 1.00, 0.99 },
    { 200, 1.00, 1.00, 1.00 },
}
