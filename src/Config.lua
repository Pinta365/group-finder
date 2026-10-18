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
        keepAppliedRole = true,
    },
}

---M+ score color tiers from Raider.IO API.
---Format: { minScore, r, g, b } - scores below first tier use gray.
---@type number[][]
PGF.SCORE_COLORS = {
    { 4075, 1.00, 0.50, 0.00 },
    { 4015, 1.00, 0.49, 0.09 },
    { 3990, 0.99, 0.48, 0.14 },
    { 3970, 0.98, 0.47, 0.18 },
    { 3945, 0.98, 0.47, 0.22 },
    { 3920, 0.98, 0.46, 0.25 },
    { 3895, 0.97, 0.45, 0.27 },
    { 3870, 0.96, 0.44, 0.30 },
    { 3850, 0.96, 0.43, 0.33 },
    { 3825, 0.95, 0.42, 0.35 },
    { 3800, 0.95, 0.41, 0.38 },
    { 3775, 0.94, 0.40, 0.40 },
    { 3750, 0.93, 0.39, 0.43 },
    { 3730, 0.92, 0.38, 0.45 },
    { 3705, 0.91, 0.38, 0.47 },
    { 3680, 0.91, 0.37, 0.50 },
    { 3655, 0.90, 0.36, 0.52 },
    { 3630, 0.89, 0.35, 0.55 },
    { 3610, 0.88, 0.34, 0.56 },
    { 3585, 0.87, 0.33, 0.59 },
    { 3560, 0.86, 0.32, 0.61 },
    { 3535, 0.85, 0.31, 0.64 },
    { 3510, 0.84, 0.31, 0.66 },
    { 3490, 0.82, 0.30, 0.68 },
    { 3465, 0.81, 0.29, 0.70 },
    { 3440, 0.80, 0.28, 0.73 },
    { 3415, 0.78, 0.27, 0.75 },
    { 3390, 0.77, 0.26, 0.77 },
    { 3370, 0.76, 0.25, 0.80 },
    { 3345, 0.74, 0.25, 0.82 },
    { 3320, 0.72, 0.24, 0.84 },
    { 3295, 0.70, 0.23, 0.86 },
    { 3270, 0.68, 0.22, 0.89 },
    { 3250, 0.66, 0.22, 0.91 },
    { 3225, 0.64, 0.21, 0.93 },
    { 3190, 0.60, 0.25, 0.93 },
    { 3165, 0.57, 0.28, 0.92 },
    { 3140, 0.53, 0.31, 0.91 },
    { 3120, 0.49, 0.33, 0.91 },
    { 3095, 0.44, 0.36, 0.90 },
    { 3070, 0.40, 0.38, 0.89 },
    { 3045, 0.34, 0.39, 0.89 },
    { 3020, 0.28, 0.41, 0.88 },
    { 3000, 0.19, 0.42, 0.87 },
    { 2975, 0.00, 0.44, 0.87 },
    { 2910, 0.11, 0.45, 0.85 },
    { 2885, 0.16, 0.47, 0.84 },
    { 2865, 0.19, 0.48, 0.82 },
    { 2840, 0.22, 0.49, 0.81 },
    { 2815, 0.25, 0.51, 0.80 },
    { 2790, 0.27, 0.52, 0.78 },
    { 2765, 0.28, 0.54, 0.76 },
    { 2745, 0.30, 0.55, 0.75 },
    { 2720, 0.31, 0.56, 0.73 },
    { 2695, 0.32, 0.58, 0.72 },
    { 2670, 0.33, 0.59, 0.71 },
    { 2645, 0.34, 0.60, 0.69 },
    { 2625, 0.35, 0.62, 0.67 },
    { 2600, 0.36, 0.64, 0.66 },
    { 2575, 0.36, 0.65, 0.64 },
    { 2550, 0.36, 0.66, 0.63 },
    { 2525, 0.37, 0.68, 0.61 },
    { 2505, 0.37, 0.69, 0.60 },
    { 2480, 0.37, 0.71, 0.58 },
    { 2455, 0.37, 0.72, 0.56 },
    { 2430, 0.37, 0.73, 0.55 },
    { 2405, 0.37, 0.75, 0.53 },
    { 2385, 0.37, 0.76, 0.51 },
    { 2360, 0.37, 0.78, 0.49 },
    { 2335, 0.36, 0.79, 0.48 },
    { 2310, 0.36, 0.81, 0.46 },
    { 2285, 0.35, 0.82, 0.44 },
    { 2265, 0.35, 0.84, 0.42 },
    { 2240, 0.34, 0.85, 0.40 },
    { 2215, 0.33, 0.87, 0.38 },
    { 2190, 0.32, 0.88, 0.35 },
    { 2165, 0.31, 0.89, 0.33 },
    { 2145, 0.29, 0.91, 0.31 },
    { 2120, 0.27, 0.93, 0.28 },
    { 2095, 0.25, 0.94, 0.25 },
    { 2070, 0.23, 0.96, 0.21 },
    { 2045, 0.20, 0.97, 0.17 },
    { 2025, 0.17, 0.98, 0.11 },
    { 2000, 0.12, 1.00, 0.00 },
    { 1975, 0.16, 1.00, 0.07 },
    { 1950, 0.20, 1.00, 0.11 },
    { 1925, 0.24, 1.00, 0.14 },
    { 1900, 0.26, 1.00, 0.16 },
    { 1875, 0.29, 1.00, 0.18 },
    { 1850, 0.31, 1.00, 0.21 },
    { 1825, 0.33, 1.00, 0.23 },
    { 1800, 0.35, 1.00, 0.24 },
    { 1775, 0.37, 1.00, 0.26 },
    { 1750, 0.38, 1.00, 0.28 },
    { 1725, 0.40, 1.00, 0.29 },
    { 1700, 0.42, 1.00, 0.31 },
    { 1675, 0.43, 1.00, 0.32 },
    { 1650, 0.45, 1.00, 0.34 },
    { 1625, 0.46, 1.00, 0.35 },
    { 1600, 0.47, 1.00, 0.36 },
    { 1575, 0.49, 1.00, 0.38 },
    { 1550, 0.50, 1.00, 0.39 },
    { 1525, 0.52, 1.00, 0.40 },
    { 1500, 0.53, 1.00, 0.42 },
    { 1475, 0.54, 1.00, 0.43 },
    { 1450, 0.55, 1.00, 0.44 },
    { 1425, 0.56, 1.00, 0.45 },
    { 1400, 0.58, 1.00, 0.47 },
    { 1375, 0.59, 1.00, 0.48 },
    { 1350, 0.60, 1.00, 0.49 },
    { 1325, 0.61, 1.00, 0.50 },
    { 1300, 0.62, 1.00, 0.51 },
    { 1275, 0.63, 1.00, 0.53 },
    { 1250, 0.64, 1.00, 0.54 },
    { 1225, 0.65, 1.00, 0.55 },
    { 1200, 0.66, 1.00, 0.56 },
    { 1175, 0.67, 1.00, 0.57 },
    { 1150, 0.68, 1.00, 0.58 },
    { 1125, 0.69, 1.00, 0.60 },
    { 1100, 0.70, 1.00, 0.61 },
    { 1075, 0.71, 1.00, 0.62 },
    { 1050, 0.72, 1.00, 0.63 },
    { 1025, 0.73, 1.00, 0.64 },
    { 1000, 0.74, 1.00, 0.65 },
    { 975, 0.75, 1.00, 0.66 },
    { 950, 0.76, 1.00, 0.67 },
    { 925, 0.76, 1.00, 0.68 },
    { 900, 0.78, 1.00, 0.69 },
    { 875, 0.78, 1.00, 0.71 },
    { 850, 0.79, 1.00, 0.72 },
    { 825, 0.80, 1.00, 0.73 },
    { 800, 0.81, 1.00, 0.74 },
    { 775, 0.82, 1.00, 0.75 },
    { 750, 0.83, 1.00, 0.76 },
    { 725, 0.84, 1.00, 0.77 },
    { 700, 0.84, 1.00, 0.78 },
    { 675, 0.85, 1.00, 0.79 },
    { 650, 0.86, 1.00, 0.80 },
    { 625, 0.87, 1.00, 0.82 },
    { 600, 0.88, 1.00, 0.83 },
    { 575, 0.89, 1.00, 0.84 },
    { 550, 0.89, 1.00, 0.85 },
    { 525, 0.90, 1.00, 0.86 },
    { 500, 0.91, 1.00, 0.87 },
    { 475, 0.92, 1.00, 0.88 },
    { 450, 0.93, 1.00, 0.89 },
    { 425, 0.93, 1.00, 0.90 },
    { 400, 0.94, 1.00, 0.91 },
    { 375, 0.95, 1.00, 0.93 },
    { 350, 0.96, 1.00, 0.93 },
    { 325, 0.96, 1.00, 0.95 },
    { 300, 0.97, 1.00, 0.96 },
    { 275, 0.98, 1.00, 0.97 },
    { 250, 0.98, 1.00, 0.98 },
    { 225, 0.99, 1.00, 0.99 },
    { 200, 1.00, 1.00, 1.00 },
}
