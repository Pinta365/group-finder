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
        },
        hideIncompatibleGroups = false,
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
    { 3600, 1.00, 0.50, 0.00 },
    { 3540, 1.00, 0.49, 0.08 },
    { 3515, 0.99, 0.49, 0.13 },
    { 3490, 0.99, 0.48, 0.17 },
    { 3465, 0.98, 0.47, 0.20 },
    { 3440, 0.98, 0.46, 0.24 },
    { 3420, 0.97, 0.45, 0.26 },
    { 3395, 0.97, 0.44, 0.29 },
    { 3370, 0.96, 0.44, 0.31 },
    { 3345, 0.96, 0.43, 0.33 },
    { 3320, 0.95, 0.42, 0.36 },
    { 3300, 0.95, 0.41, 0.38 },
    { 3275, 0.94, 0.40, 0.40 },
    { 3250, 0.93, 0.40, 0.43 },
    { 3225, 0.93, 0.38, 0.45 },
    { 3200, 0.92, 0.38, 0.47 },
    { 3180, 0.91, 0.37, 0.49 },
    { 3155, 0.90, 0.36, 0.51 },
    { 3130, 0.89, 0.35, 0.53 },
    { 3105, 0.89, 0.35, 0.55 },
    { 3080, 0.87, 0.34, 0.58 },
    { 3060, 0.87, 0.33, 0.60 },
    { 3035, 0.85, 0.32, 0.62 },
    { 3010, 0.85, 0.31, 0.64 },
    { 2985, 0.84, 0.31, 0.66 },
    { 2960, 0.82, 0.30, 0.68 },
    { 2940, 0.82, 0.29, 0.70 },
    { 2915, 0.80, 0.28, 0.72 },
    { 2890, 0.79, 0.27, 0.74 },
    { 2865, 0.78, 0.27, 0.76 },
    { 2840, 0.76, 0.26, 0.78 },
    { 2820, 0.75, 0.25, 0.80 },
    { 2795, 0.73, 0.24, 0.83 },
    { 2770, 0.71, 0.24, 0.85 },
    { 2745, 0.70, 0.23, 0.87 },
    { 2720, 0.68, 0.22, 0.89 },
    { 2700, 0.66, 0.22, 0.91 },
    { 2675, 0.64, 0.21, 0.93 },
    { 2640, 0.60, 0.25, 0.93 },
    { 2615, 0.56, 0.29, 0.92 },
    { 2595, 0.51, 0.32, 0.91 },
    { 2570, 0.47, 0.35, 0.90 },
    { 2545, 0.42, 0.37, 0.90 },
    { 2520, 0.36, 0.39, 0.89 },
    { 2495, 0.29, 0.41, 0.88 },
    { 2475, 0.20, 0.42, 0.87 },
    { 2450, 0.00, 0.44, 0.87 },
    { 2380, 0.09, 0.45, 0.85 },
    { 2355, 0.15, 0.46, 0.84 },
    { 2330, 0.18, 0.47, 0.83 },
    { 2305, 0.20, 0.49, 0.82 },
    { 2285, 0.23, 0.50, 0.80 },
    { 2260, 0.25, 0.51, 0.79 },
    { 2235, 0.27, 0.52, 0.78 },
    { 2210, 0.28, 0.53, 0.77 },
    { 2185, 0.29, 0.55, 0.76 },
    { 2165, 0.31, 0.56, 0.74 },
    { 2140, 0.31, 0.57, 0.73 },
    { 2115, 0.33, 0.58, 0.72 },
    { 2090, 0.33, 0.59, 0.71 },
    { 2065, 0.34, 0.60, 0.69 },
    { 2045, 0.35, 0.62, 0.68 },
    { 2020, 0.35, 0.63, 0.67 },
    { 1995, 0.36, 0.64, 0.65 },
    { 1970, 0.36, 0.65, 0.64 },
    { 1945, 0.36, 0.66, 0.63 },
    { 1925, 0.37, 0.67, 0.61 },
    { 1900, 0.37, 0.69, 0.60 },
    { 1875, 0.37, 0.70, 0.58 },
    { 1850, 0.37, 0.71, 0.57 },
    { 1825, 0.37, 0.73, 0.56 },
    { 1805, 0.37, 0.74, 0.55 },
    { 1780, 0.37, 0.75, 0.53 },
    { 1755, 0.37, 0.76, 0.51 },
    { 1730, 0.37, 0.77, 0.50 },
    { 1705, 0.36, 0.79, 0.49 },
    { 1685, 0.36, 0.80, 0.47 },
    { 1660, 0.36, 0.81, 0.45 },
    { 1635, 0.35, 0.82, 0.44 },
    { 1610, 0.35, 0.84, 0.42 },
    { 1585, 0.34, 0.85, 0.40 },
    { 1565, 0.33, 0.86, 0.38 },
    { 1540, 0.32, 0.87, 0.36 },
    { 1515, 0.31, 0.89, 0.35 },
    { 1490, 0.30, 0.90, 0.33 },
    { 1465, 0.29, 0.91, 0.30 },
    { 1445, 0.27, 0.93, 0.28 },
    { 1420, 0.26, 0.94, 0.25 },
    { 1395, 0.24, 0.95, 0.23 },
    { 1370, 0.22, 0.96, 0.19 },
    { 1345, 0.19, 0.98, 0.15 },
    { 1325, 0.16, 0.99, 0.10 },
    { 1300, 0.12, 1.00, 0.00 },
    { 1275, 0.19, 1.00, 0.09 },
    { 1250, 0.24, 1.00, 0.15 },
    { 1225, 0.28, 1.00, 0.18 },
    { 1200, 0.32, 1.00, 0.22 },
    { 1175, 0.35, 1.00, 0.25 },
    { 1150, 0.38, 1.00, 0.27 },
    { 1125, 0.41, 1.00, 0.30 },
    { 1100, 0.44, 1.00, 0.33 },
    { 1075, 0.46, 1.00, 0.35 },
    { 1050, 0.48, 1.00, 0.37 },
    { 1025, 0.50, 1.00, 0.39 },
    { 1000, 0.53, 1.00, 0.41 },
    { 975, 0.55, 1.00, 0.43 },
    { 950, 0.56, 1.00, 0.45 },
    { 925, 0.58, 1.00, 0.47 },
    { 900, 0.60, 1.00, 0.49 },
    { 875, 0.62, 1.00, 0.51 },
    { 850, 0.64, 1.00, 0.53 },
    { 825, 0.65, 1.00, 0.55 },
    { 800, 0.67, 1.00, 0.57 },
    { 775, 0.69, 1.00, 0.59 },
    { 750, 0.70, 1.00, 0.61 },
    { 725, 0.72, 1.00, 0.62 },
    { 700, 0.73, 1.00, 0.64 },
    { 675, 0.75, 1.00, 0.66 },
    { 650, 0.76, 1.00, 0.68 },
    { 625, 0.78, 1.00, 0.70 },
    { 600, 0.79, 1.00, 0.71 },
    { 575, 0.80, 1.00, 0.73 },
    { 550, 0.82, 1.00, 0.75 },
    { 525, 0.84, 1.00, 0.77 },
    { 500, 0.85, 1.00, 0.79 },
    { 475, 0.86, 1.00, 0.80 },
    { 450, 0.87, 1.00, 0.82 },
    { 425, 0.89, 1.00, 0.84 },
    { 400, 0.90, 1.00, 0.86 },
    { 375, 0.91, 1.00, 0.87 },
    { 350, 0.93, 1.00, 0.89 },
    { 325, 0.94, 1.00, 0.91 },
    { 300, 0.95, 1.00, 0.93 },
    { 275, 0.96, 1.00, 0.95 },
    { 250, 0.98, 1.00, 0.96 },
    { 225, 0.99, 1.00, 0.98 },
    { 200, 1.00, 1.00, 1.00 },
}
