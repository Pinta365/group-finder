--[[
    PintaGroupFinder - Configuration Module
    
    Defines saved variable defaults and constants.
]]

local addonName, PGF = ...

PGF.DUNGEON_CATEGORY_ID = 2
PGF.RAID_CATEGORY_ID = 3

---@class SavedVariables
---@field debug boolean
---@field filter FilterSettings
---@field ui UISettings

---@class FilterSettings
---@field minRating number
---@field dungeons number[]
---@field hasRole HasRoleSettings
---@field difficulty DifficultySettings
---@field playstyle PlaystyleSettings

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

---@class UISettings
---@field showClassColors boolean
---@field showLeaderRating boolean
---@field showMissingRoles boolean
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
        },
        dungeonAccordionState = {
            activities = true,
            difficulty = false,
            playstyle = false,
            misc = false,
            quickApply = false,
        },
    },
    
    ui = {
        showClassColors = true,
        showLeaderRating = true,
        showMissingRoles = true,
        filterPanelShown = true,
    },
}

---@class CharacterSavedVariables
---@field quickApply QuickApplySettings

---@class QuickApplySettings
---@field enabled boolean
---@field roles RoleSettings
---@field note string
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
        note = "",
        autoAcceptParty = false,
    },
}

---M+ score color tiers from Raider.IO API.
---Format: { minScore, r, g, b } - scores below first tier use gray.
---@type number[][]
PGF.SCORE_COLORS = {
    { 4075, 1.00, 0.50, 0.00 },
    { 4010, 1.00, 0.49, 0.08 },
    { 3990, 0.99, 0.49, 0.13 },
    { 3965, 0.99, 0.48, 0.17 },
    { 3940, 0.98, 0.47, 0.20 },
    { 3915, 0.98, 0.46, 0.23 },
    { 3890, 0.97, 0.45, 0.25 },
    { 3870, 0.97, 0.45, 0.28 },
    { 3845, 0.96, 0.44, 0.31 },
    { 3820, 0.96, 0.43, 0.33 },
    { 3795, 0.95, 0.42, 0.35 },
    { 3770, 0.95, 0.41, 0.38 },
    { 3750, 0.94, 0.40, 0.40 },
    { 3725, 0.93, 0.40, 0.42 },
    { 3700, 0.93, 0.39, 0.44 },
    { 3675, 0.92, 0.38, 0.46 },
    { 3650, 0.91, 0.37, 0.48 },
    { 3630, 0.91, 0.36, 0.50 },
    { 3605, 0.90, 0.36, 0.52 },
    { 3580, 0.89, 0.35, 0.55 },
    { 3555, 0.88, 0.34, 0.56 },
    { 3530, 0.87, 0.33, 0.58 },
    { 3510, 0.86, 0.33, 0.60 },
    { 3485, 0.85, 0.32, 0.62 },
    { 3460, 0.84, 0.31, 0.65 },
    { 3435, 0.83, 0.30, 0.67 },
    { 3410, 0.82, 0.29, 0.69 },
    { 3390, 0.81, 0.29, 0.71 },
    { 3365, 0.80, 0.28, 0.73 },
    { 3340, 0.78, 0.27, 0.75 },
    { 3315, 0.77, 0.26, 0.77 },
    { 3290, 0.76, 0.25, 0.79 },
    { 3270, 0.75, 0.25, 0.81 },
    { 3245, 0.73, 0.24, 0.83 },
    { 3220, 0.71, 0.24, 0.85 },
    { 3195, 0.70, 0.23, 0.87 },
    { 3170, 0.68, 0.22, 0.89 },
    { 3150, 0.66, 0.22, 0.91 },
    { 3125, 0.64, 0.21, 0.93 },
    { 3095, 0.58, 0.27, 0.92 },
    { 3070, 0.51, 0.32, 0.91 },
    { 3045, 0.44, 0.36, 0.90 },
    { 3020, 0.36, 0.39, 0.89 },
    { 3000, 0.25, 0.42, 0.88 },
    { 2975, 0.00, 0.44, 0.87 },
    { 2905, 0.09, 0.45, 0.85 },
    { 2880, 0.15, 0.46, 0.84 },
    { 2855, 0.18, 0.47, 0.83 },
    { 2830, 0.20, 0.49, 0.82 },
    { 2810, 0.23, 0.50, 0.80 },
    { 2785, 0.25, 0.51, 0.79 },
    { 2760, 0.27, 0.52, 0.78 },
    { 2735, 0.28, 0.53, 0.77 },
    { 2710, 0.29, 0.55, 0.76 },
    { 2690, 0.31, 0.56, 0.74 },
    { 2665, 0.31, 0.57, 0.73 },
    { 2640, 0.33, 0.58, 0.72 },
    { 2615, 0.33, 0.59, 0.71 },
    { 2590, 0.34, 0.60, 0.69 },
    { 2570, 0.35, 0.62, 0.68 },
    { 2545, 0.35, 0.63, 0.67 },
    { 2520, 0.36, 0.64, 0.65 },
    { 2495, 0.36, 0.65, 0.64 },
    { 2470, 0.36, 0.66, 0.63 },
    { 2450, 0.37, 0.67, 0.61 },
    { 2425, 0.37, 0.69, 0.60 },
    { 2400, 0.37, 0.70, 0.58 },
    { 2375, 0.37, 0.71, 0.57 },
    { 2350, 0.37, 0.73, 0.56 },
    { 2330, 0.37, 0.74, 0.55 },
    { 2305, 0.37, 0.75, 0.53 },
    { 2280, 0.37, 0.76, 0.51 },
    { 2255, 0.37, 0.77, 0.50 },
    { 2230, 0.36, 0.79, 0.49 },
    { 2210, 0.36, 0.80, 0.47 },
    { 2185, 0.36, 0.81, 0.45 },
    { 2160, 0.35, 0.82, 0.44 },
    { 2135, 0.35, 0.84, 0.42 },
    { 2110, 0.34, 0.85, 0.40 },
    { 2090, 0.33, 0.86, 0.38 },
    { 2065, 0.32, 0.87, 0.36 },
    { 2040, 0.31, 0.89, 0.35 },
    { 2015, 0.30, 0.90, 0.33 },
    { 1990, 0.29, 0.91, 0.30 },
    { 1970, 0.27, 0.93, 0.28 },
    { 1945, 0.26, 0.94, 0.25 },
    { 1920, 0.24, 0.95, 0.23 },
    { 1895, 0.22, 0.96, 0.19 },
    { 1870, 0.19, 0.98, 0.15 },
    { 1850, 0.16, 0.99, 0.10 },
    { 1825, 0.12, 1.00, 0.00 },
    { 1800, 0.17, 1.00, 0.07 },
    { 1775, 0.21, 1.00, 0.11 },
    { 1750, 0.24, 1.00, 0.15 },
    { 1725, 0.27, 1.00, 0.17 },
    { 1700, 0.30, 1.00, 0.20 },
    { 1675, 0.32, 1.00, 0.22 },
    { 1650, 0.35, 1.00, 0.24 },
    { 1625, 0.36, 1.00, 0.26 },
    { 1600, 0.38, 1.00, 0.28 },
    { 1575, 0.40, 1.00, 0.29 },
    { 1550, 0.42, 1.00, 0.31 },
    { 1525, 0.44, 1.00, 0.33 },
    { 1500, 0.45, 1.00, 0.34 },
    { 1475, 0.47, 1.00, 0.36 },
    { 1450, 0.49, 1.00, 0.37 },
    { 1425, 0.50, 1.00, 0.39 },
    { 1400, 0.51, 1.00, 0.40 },
    { 1375, 0.53, 1.00, 0.42 },
    { 1350, 0.54, 1.00, 0.43 },
    { 1325, 0.55, 1.00, 0.44 },
    { 1300, 0.57, 1.00, 0.46 },
    { 1275, 0.58, 1.00, 0.47 },
    { 1250, 0.59, 1.00, 0.48 },
    { 1225, 0.60, 1.00, 0.50 },
    { 1200, 0.62, 1.00, 0.51 },
    { 1175, 0.63, 1.00, 0.52 },
    { 1150, 0.64, 1.00, 0.54 },
    { 1125, 0.65, 1.00, 0.55 },
    { 1100, 0.66, 1.00, 0.56 },
    { 1075, 0.67, 1.00, 0.58 },
    { 1050, 0.69, 1.00, 0.59 },
    { 1025, 0.70, 1.00, 0.60 },
    { 1000, 0.71, 1.00, 0.61 },
    { 975, 0.72, 1.00, 0.62 },
    { 950, 0.73, 1.00, 0.64 },
    { 925, 0.74, 1.00, 0.65 },
    { 900, 0.75, 1.00, 0.66 },
    { 875, 0.76, 1.00, 0.67 },
    { 850, 0.77, 1.00, 0.69 },
    { 825, 0.78, 1.00, 0.70 },
    { 800, 0.79, 1.00, 0.71 },
    { 775, 0.80, 1.00, 0.72 },
    { 750, 0.81, 1.00, 0.73 },
    { 725, 0.82, 1.00, 0.75 },
    { 700, 0.83, 1.00, 0.76 },
    { 675, 0.84, 1.00, 0.77 },
    { 650, 0.84, 1.00, 0.78 },
    { 625, 0.85, 1.00, 0.80 },
    { 600, 0.86, 1.00, 0.81 },
    { 575, 0.87, 1.00, 0.82 },
    { 550, 0.88, 1.00, 0.83 },
    { 525, 0.89, 1.00, 0.84 },
    { 500, 0.90, 1.00, 0.85 },
    { 475, 0.91, 1.00, 0.87 },
    { 450, 0.92, 1.00, 0.88 },
    { 425, 0.93, 1.00, 0.89 },
    { 400, 0.93, 1.00, 0.90 },
    { 375, 0.94, 1.00, 0.92 },
    { 350, 0.95, 1.00, 0.93 },
    { 325, 0.96, 1.00, 0.94 },
    { 300, 0.97, 1.00, 0.95 },
    { 275, 0.98, 1.00, 0.96 },
    { 250, 0.98, 1.00, 0.98 },
    { 225, 0.99, 1.00, 0.99 },
    { 200, 1.00, 1.00, 1.00 },
}
