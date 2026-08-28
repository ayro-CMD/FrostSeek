--[[
==============================================================================
 FrostSeek - Advanced LFG/LFM Manager
==============================================================================
 Copyright (c) 2026 Ayro. All rights reserved.

 License: FrostSeek Proprietary License - All Rights Reserved
 Author:  Ayro

 This source code is the proprietary intellectual property of Ayro.
 Unauthorized copying, modification, redistribution, or use of any part of
 this code, in whole or in part, via any medium, is strictly prohibited
 without the express written permission of the author.

 For licensing inquiries, contact the author via the official repository:
   CurseForge Project ID: 1460315

 Watermark: FSK-WM-36DA8EFBD010-FSK-AYRO-2026-7F3C-9A21-BD54-8E1F
==============================================================================
]]


local _th = {}

local THEMES = {
    Frost = {
        primary     = {0.2, 0.6, 0.9},
        secondary   = {0.3, 0.3, 0.3},
        accent      = {0.53, 0.8, 1.0},

        bgMain      = {0.1, 0.1, 0.1, 0.95},
        bgSection   = {0.06, 0.07, 0.10, 0.6},
        bgBlock     = {0.08, 0.09, 0.13, 0.5},
        bgButton    = {0.15, 0.15, 0.15, 0.9},
        bgInput     = {0.08, 0.08, 0.10, 0.85},
        bgInputFocus= {0.10, 0.14, 0.20, 0.95},
        bgRowOdd    = {0.08, 0.08, 0.11, 0.15},
        bgRowEven   = {0.12, 0.12, 0.15, 0.25},
        bgRowHover  = {0.18, 0.25, 0.35, 0.45},
        bgPopup     = {0.02, 0.02, 0.04, 0.85},
        bgToggleOn  = {0.2, 0.75, 0.15, 1},
        bgToggleOff = {0.7, 0.15, 0.1, 1},
        bgMenuBg    = {0.02, 0.02, 0.04, 0.98},
        bgCheckbox  = {0.1, 0.1, 0.1, 0.5},
        bgTabActive = {0.1, 0.2, 0.3, 1},
        bgTabInactive = {0.15, 0.15, 0.15, 0.9},

        border      = {0.4, 0.4, 0.4, 1},
        borderInput = {0.25, 0.28, 0.32, 0.9},
        borderFocus = {0.35, 0.60, 0.85, 1.0},
        borderHover = {0.6, 0.8, 1, 1},
        borderCheck = {0.4, 0.4, 0.4, 0.8},
        borderMenu  = {0.35, 0.38, 0.42, 1},

        accentBar   = {0.3, 0.55, 0.75, 0.6},
        accentFocus = {0.45, 0.70, 1.0, 0.9},
        accentHover = {0.45, 0.55, 0.70, 1.0},

        textPrimary = {1, 1, 1},
        textBright  = {0.95, 0.95, 0.95},
        textNorm    = {0.85, 0.85, 0.88},
        textDim     = {0.45, 0.48, 0.55},
        textLabel   = {0.38, 0.42, 0.5},
        textMuted   = {0.7, 0.7, 0.7},
        textAccent  = {0.6, 0.8, 1},

        success     = {0.2, 0.9, 0.4},
        warning     = {1.0, 0.75, 0.2},
        danger      = {0.95, 0.3, 0.3},
        gold        = {1.0, 0.85, 0.0},

        line        = {0.18, 0.22, 0.30, 0.5},
        lineAccent  = {0.2, 0.5, 0.8, 0.35},
        separator   = {0.2, 0.2, 0.25, 0.3},

        catDungeon  = {0.2, 0.75, 0.2},
        catRaid     = {0.85, 0.45, 0.15},
        catWorldBoss= {0.85, 0.2, 0.2},
        catPvP      = {0.85, 0.2, 0.2},
        catMana     = {0.6, 0.3, 0.85},
        catKeystone = {0.9, 0.4, 0.65},
        catCustom   = {1.0, 0.8, 0.0},
        catAll      = {0.4, 0.6, 0.8},
        catMisc     = {0.53, 0.80, 1.00},

        titleR = 0.8, titleG = 0.9, titleB = 1.0,
    },

    Blood = {
        primary     = {0.8, 0.15, 0.15},
        secondary   = {0.35, 0.15, 0.15},
        accent      = {1.0, 0.35, 0.35},
        bgMain      = {0.12, 0.05, 0.05, 0.95},
        bgSection   = {0.10, 0.04, 0.04, 0.6},
        bgBlock     = {0.09, 0.05, 0.06, 0.5},
        bgButton    = {0.18, 0.08, 0.08, 0.9},
        bgInput     = {0.10, 0.05, 0.05, 0.85},
        bgInputFocus= {0.18, 0.08, 0.10, 0.95},
        bgRowOdd    = {0.08, 0.04, 0.04, 0.15},
        bgRowEven   = {0.12, 0.06, 0.06, 0.25},
        bgRowHover  = {0.30, 0.12, 0.12, 0.45},
        bgPopup     = {0.06, 0.02, 0.02, 0.85},
        bgToggleOn  = {0.6, 0.15, 0.1, 1},
        bgToggleOff = {0.3, 0.1, 0.1, 1},
        bgMenuBg    = {0.06, 0.02, 0.02, 0.98},
        bgCheckbox  = {0.12, 0.06, 0.06, 0.5},
        bgTabActive = {0.25, 0.08, 0.08, 1},
        bgTabInactive = {0.14, 0.06, 0.06, 0.9},
        border      = {0.5, 0.15, 0.15, 1},
        borderInput = {0.35, 0.15, 0.15, 0.9},
        borderFocus = {0.7, 0.25, 0.25, 1.0},
        borderHover = {0.9, 0.3, 0.3, 1},
        borderCheck = {0.5, 0.2, 0.2, 0.8},
        borderMenu  = {0.45, 0.15, 0.15, 1},
        accentBar   = {0.7, 0.2, 0.2, 0.6},
        accentFocus = {0.9, 0.3, 0.3, 0.9},
        accentHover = {0.6, 0.2, 0.2, 1.0},
        textPrimary = {1, 0.95, 0.95},
        textBright  = {0.95, 0.9, 0.9},
        textNorm    = {0.88, 0.8, 0.8},
        textDim     = {0.5, 0.4, 0.4},
        textLabel   = {0.45, 0.35, 0.35},
        textMuted   = {0.7, 0.6, 0.6},
        textAccent  = {1.0, 0.6, 0.6},
        success     = {0.3, 0.8, 0.3},
        warning     = {1.0, 0.7, 0.2},
        danger      = {1.0, 0.2, 0.2},
        gold        = {1.0, 0.85, 0.0},
        line        = {0.30, 0.12, 0.12, 0.5},
        lineAccent  = {0.6, 0.2, 0.2, 0.35},
        separator   = {0.25, 0.12, 0.12, 0.3},
        catDungeon  = {0.3, 0.75, 0.3},
        catRaid     = {0.95, 0.4, 0.2},
        catWorldBoss= {0.9, 0.3, 0.3},
        catPvP      = {1.0, 0.3, 0.3},
        catMana     = {0.7, 0.3, 0.8},
        catKeystone = {0.95, 0.4, 0.6},
        catCustom   = {1.0, 0.75, 0.15},
        catAll      = {0.6, 0.3, 0.3},
        catMisc     = {0.5, 0.35, 0.35},
        titleR = 1.0, titleG = 0.5, titleB = 0.5,
    },

    Emerald = {
        primary     = {0.1, 0.7, 0.3},
        secondary   = {0.15, 0.3, 0.2},
        accent      = {0.3, 1.0, 0.5},
        bgMain      = {0.05, 0.10, 0.07, 0.95},
        bgSection   = {0.04, 0.08, 0.06, 0.6},
        bgBlock     = {0.05, 0.09, 0.07, 0.5},
        bgButton    = {0.08, 0.15, 0.10, 0.9},
        bgInput     = {0.05, 0.08, 0.06, 0.85},
        bgInputFocus= {0.08, 0.15, 0.10, 0.95},
        bgRowOdd    = {0.04, 0.07, 0.05, 0.15},
        bgRowEven   = {0.07, 0.12, 0.08, 0.25},
        bgRowHover  = {0.12, 0.25, 0.15, 0.45},
        bgPopup     = {0.02, 0.05, 0.03, 0.85},
        bgToggleOn  = {0.15, 0.65, 0.25, 1},
        bgToggleOff = {0.3, 0.15, 0.1, 1},
        bgMenuBg    = {0.02, 0.05, 0.03, 0.98},
        bgCheckbox  = {0.06, 0.10, 0.07, 0.5},
        bgTabActive = {0.10, 0.20, 0.12, 1},
        bgTabInactive = {0.08, 0.14, 0.09, 0.9},
        border      = {0.15, 0.4, 0.2, 1},
        borderInput = {0.15, 0.3, 0.2, 0.9},
        borderFocus = {0.2, 0.6, 0.35, 1.0},
        borderHover = {0.3, 0.8, 0.4, 1},
        borderCheck = {0.2, 0.4, 0.25, 0.8},
        borderMenu  = {0.15, 0.35, 0.2, 1},
        accentBar   = {0.2, 0.6, 0.3, 0.6},
        accentFocus = {0.3, 0.8, 0.4, 0.9},
        accentHover = {0.2, 0.5, 0.3, 1.0},
        textPrimary = {0.95, 1, 0.95},
        textBright  = {0.9, 0.95, 0.9},
        textNorm    = {0.8, 0.88, 0.82},
        textDim     = {0.4, 0.5, 0.45},
        textLabel   = {0.35, 0.45, 0.4},
        textMuted   = {0.6, 0.7, 0.65},
        textAccent  = {0.4, 1.0, 0.6},
        success     = {0.2, 0.9, 0.4},
        warning     = {1.0, 0.8, 0.2},
        danger      = {0.9, 0.3, 0.3},
        gold        = {1.0, 0.9, 0.3},
        line        = {0.12, 0.25, 0.15, 0.5},
        lineAccent  = {0.2, 0.5, 0.3, 0.35},
        separator   = {0.15, 0.22, 0.18, 0.3},
        catDungeon  = {0.2, 0.8, 0.3},
        catRaid     = {0.85, 0.55, 0.2},
        catWorldBoss= {0.8, 0.3, 0.25},
        catPvP      = {0.85, 0.25, 0.25},
        catMana     = {0.5, 0.35, 0.8},
        catKeystone = {0.85, 0.45, 0.65},
        catCustom   = {0.95, 0.7, 0.1},
        catAll      = {0.3, 0.6, 0.4},
        catMisc     = {0.45, 0.5, 0.47},
        titleR = 0.4, titleG = 1.0, titleB = 0.6,
    },

    Void = {
        primary     = {0.5, 0.2, 0.8},
        secondary   = {0.2, 0.15, 0.3},
        accent      = {0.7, 0.4, 1.0},
        bgMain      = {0.08, 0.05, 0.12, 0.95},
        bgSection   = {0.06, 0.04, 0.09, 0.6},
        bgBlock     = {0.07, 0.05, 0.10, 0.5},
        bgButton    = {0.12, 0.08, 0.18, 0.9},
        bgInput     = {0.08, 0.05, 0.12, 0.85},
        bgInputFocus= {0.12, 0.08, 0.18, 0.95},
        bgRowOdd    = {0.06, 0.04, 0.09, 0.15},
        bgRowEven   = {0.10, 0.06, 0.14, 0.25},
        bgRowHover  = {0.20, 0.12, 0.30, 0.45},
        bgPopup     = {0.04, 0.02, 0.06, 0.85},
        bgToggleOn  = {0.45, 0.2, 0.7, 1},
        bgToggleOff = {0.3, 0.1, 0.15, 1},
        bgMenuBg    = {0.04, 0.02, 0.06, 0.98},
        bgCheckbox  = {0.08, 0.05, 0.12, 0.5},
        bgTabActive = {0.18, 0.10, 0.28, 1},
        bgTabInactive = {0.10, 0.06, 0.15, 0.9},
        border      = {0.35, 0.2, 0.5, 1},
        borderInput = {0.3, 0.18, 0.4, 0.9},
        borderFocus = {0.5, 0.3, 0.7, 1.0},
        borderHover = {0.6, 0.4, 0.8, 1},
        borderCheck = {0.35, 0.2, 0.45, 0.8},
        borderMenu  = {0.3, 0.18, 0.42, 1},
        accentBar   = {0.5, 0.25, 0.7, 0.6},
        accentFocus = {0.6, 0.35, 0.85, 0.9},
        accentHover = {0.4, 0.25, 0.6, 1.0},
        textPrimary = {0.98, 0.95, 1},
        textBright  = {0.92, 0.88, 0.96},
        textNorm    = {0.85, 0.80, 0.90},
        textDim     = {0.5, 0.45, 0.58},
        textLabel   = {0.42, 0.38, 0.52},
        textMuted   = {0.65, 0.6, 0.72},
        textAccent  = {0.7, 0.5, 1.0},
        success     = {0.3, 0.8, 0.45},
        warning     = {1.0, 0.75, 0.3},
        danger      = {0.9, 0.3, 0.5},
        gold        = {1.0, 0.85, 0.4},
        line        = {0.20, 0.12, 0.30, 0.5},
        lineAccent  = {0.4, 0.2, 0.6, 0.35},
        separator   = {0.18, 0.12, 0.25, 0.3},
        catDungeon  = {0.3, 0.75, 0.45},
        catRaid     = {0.85, 0.5, 0.3},
        catWorldBoss= {0.85, 0.3, 0.4},
        catPvP      = {0.9, 0.3, 0.4},
        catMana     = {0.65, 0.35, 0.9},
        catKeystone = {0.9, 0.5, 0.7},
        catCustom   = {1.0, 0.78, 0.05},
        catAll      = {0.5, 0.4, 0.7},
        catMisc     = {0.5, 0.45, 0.55},
        titleR = 0.7, titleG = 0.5, titleB = 1.0,
    },

    Classic = {
        primary     = {0.8, 0.65, 0.35},
        secondary   = {0.4, 0.3, 0.2},
        accent      = {1.0, 0.85, 0.5},
        bgMain      = {0.15, 0.10, 0.05, 0.95},
        bgSection   = {0.12, 0.08, 0.04, 0.6},
        bgBlock     = {0.10, 0.08, 0.05, 0.5},
        bgButton    = {0.20, 0.15, 0.08, 0.9},
        bgInput     = {0.12, 0.08, 0.04, 0.85},
        bgInputFocus= {0.18, 0.12, 0.06, 0.95},
        bgRowOdd    = {0.10, 0.07, 0.04, 0.15},
        bgRowEven   = {0.14, 0.10, 0.06, 0.25},
        bgRowHover  = {0.25, 0.18, 0.10, 0.45},
        bgPopup     = {0.08, 0.05, 0.02, 0.85},
        bgToggleOn  = {0.6, 0.5, 0.2, 1},
        bgToggleOff = {0.4, 0.2, 0.1, 1},
        bgMenuBg    = {0.08, 0.05, 0.02, 0.98},
        bgCheckbox  = {0.12, 0.08, 0.04, 0.5},
        bgTabActive = {0.22, 0.16, 0.08, 1},
        bgTabInactive = {0.16, 0.12, 0.06, 0.9},
        border      = {0.5, 0.4, 0.25, 1},
        borderInput = {0.4, 0.3, 0.2, 0.9},
        borderFocus = {0.7, 0.55, 0.3, 1.0},
        borderHover = {0.8, 0.65, 0.4, 1},
        borderCheck = {0.5, 0.4, 0.25, 0.8},
        borderMenu  = {0.45, 0.35, 0.22, 1},
        accentBar   = {0.6, 0.45, 0.2, 0.6},
        accentFocus = {0.8, 0.6, 0.3, 0.9},
        accentHover = {0.5, 0.4, 0.25, 1.0},
        textPrimary = {1, 0.95, 0.85},
        textBright  = {0.95, 0.90, 0.78},
        textNorm    = {0.88, 0.82, 0.72},
        textDim     = {0.55, 0.48, 0.38},
        textLabel   = {0.48, 0.42, 0.35},
        textMuted   = {0.7, 0.65, 0.55},
        textAccent  = {1.0, 0.85, 0.5},
        success     = {0.4, 0.8, 0.3},
        warning     = {1.0, 0.8, 0.2},
        danger      = {0.85, 0.3, 0.2},
        gold        = {1.0, 0.9, 0.4},
        line        = {0.30, 0.22, 0.12, 0.5},
        lineAccent  = {0.5, 0.35, 0.15, 0.35},
        separator   = {0.25, 0.18, 0.10, 0.3},
        catDungeon  = {0.5, 0.75, 0.35},
        catRaid     = {0.9, 0.6, 0.3},
        catWorldBoss= {0.85, 0.35, 0.25},
        catPvP      = {0.8, 0.3, 0.25},
        catMana     = {0.6, 0.4, 0.7},
        catKeystone = {0.85, 0.55, 0.5},
        catCustom   = {0.9, 0.7, 0.2},
        catAll      = {0.6, 0.5, 0.35},
        catMisc     = {0.55, 0.5, 0.42},
        titleR = 1.0, titleG = 0.85, titleB = 0.5,
    },

    Neon = {
        primary     = {0.0, 0.9, 0.9},
        secondary   = {0.2, 0.2, 0.25},
        accent      = {0.0, 1.0, 0.6},
        bgMain      = {0.04, 0.04, 0.08, 0.95},
        bgSection   = {0.05, 0.05, 0.10, 0.6},
        bgBlock     = {0.06, 0.06, 0.10, 0.5},
        bgButton    = {0.08, 0.10, 0.15, 0.9},
        bgInput     = {0.05, 0.05, 0.10, 0.85},
        bgInputFocus= {0.08, 0.10, 0.18, 0.95},
        bgRowOdd    = {0.04, 0.04, 0.08, 0.15},
        bgRowEven   = {0.08, 0.08, 0.12, 0.25},
        bgRowHover  = {0.10, 0.20, 0.25, 0.45},
        bgPopup     = {0.03, 0.03, 0.06, 0.85},
        bgToggleOn  = {0.0, 0.7, 0.5, 1},
        bgToggleOff = {0.5, 0.1, 0.2, 1},
        bgMenuBg    = {0.03, 0.03, 0.06, 0.98},
        bgCheckbox  = {0.06, 0.06, 0.10, 0.5},
        bgTabActive = {0.10, 0.15, 0.20, 1},
        bgTabInactive = {0.08, 0.08, 0.12, 0.9},
        border      = {0.0, 0.6, 0.6, 1},
        borderInput = {0.0, 0.4, 0.5, 0.9},
        borderFocus = {0.0, 0.8, 0.7, 1.0},
        borderHover = {0.0, 1.0, 0.8, 1},
        borderCheck = {0.0, 0.5, 0.5, 0.8},
        borderMenu  = {0.0, 0.5, 0.5, 1},
        accentBar   = {0.0, 0.7, 0.6, 0.6},
        accentFocus = {0.0, 0.9, 0.7, 0.9},
        accentHover = {0.0, 0.5, 0.5, 1.0},
        textPrimary = {0.9, 1, 1},
        textBright  = {0.85, 0.95, 0.95},
        textNorm    = {0.78, 0.88, 0.88},
        textDim     = {0.4, 0.5, 0.52},
        textLabel   = {0.35, 0.45, 0.48},
        textMuted   = {0.6, 0.7, 0.72},
        textAccent  = {0.0, 1.0, 0.7},
        success     = {0.0, 1.0, 0.5},
        warning     = {1.0, 0.9, 0.0},
        danger      = {1.0, 0.15, 0.4},
        gold        = {1.0, 0.95, 0.3},
        line        = {0.0, 0.25, 0.30, 0.5},
        lineAccent  = {0.0, 0.5, 0.5, 0.35},
        separator   = {0.0, 0.18, 0.22, 0.3},
        catDungeon  = {0.0, 0.85, 0.5},
        catRaid     = {1.0, 0.6, 0.0},
        catWorldBoss= {1.0, 0.2, 0.4},
        catPvP      = {1.0, 0.15, 0.55},
        catMana     = {0.7, 0.3, 1.0},
        catKeystone = {1.0, 0.4, 0.7},
        catCustom   = {1.0, 0.8, 0.1},
        catAll      = {0.0, 0.7, 0.7},
        catMisc     = {0.45, 0.5, 0.52},
        titleR = 0.0, titleG = 1.0, titleB = 0.8,
    },

    Shadow = {
        primary     = {0.45, 0.45, 0.50},
        secondary   = {0.15, 0.15, 0.18},
        accent      = {0.60, 0.60, 0.68},
        bgMain      = {0.06, 0.06, 0.08, 0.97},
        bgSection   = {0.05, 0.05, 0.07, 0.65},
        bgBlock     = {0.06, 0.06, 0.08, 0.55},
        bgButton    = {0.10, 0.10, 0.13, 0.9},
        bgInput     = {0.05, 0.05, 0.07, 0.85},
        bgInputFocus= {0.09, 0.09, 0.12, 0.95},
        bgRowOdd    = {0.04, 0.04, 0.05, 0.15},
        bgRowEven   = {0.07, 0.07, 0.09, 0.25},
        bgRowHover  = {0.14, 0.14, 0.18, 0.45},
        bgPopup     = {0.03, 0.03, 0.04, 0.9},
        bgToggleOn  = {0.45, 0.45, 0.52, 1},
        bgToggleOff = {0.25, 0.18, 0.20, 1},
        bgMenuBg    = {0.03, 0.03, 0.04, 0.98},
        bgCheckbox  = {0.06, 0.06, 0.08, 0.5},
        bgTabActive = {0.12, 0.12, 0.15, 1},
        bgTabInactive = {0.08, 0.08, 0.10, 0.9},
        border      = {0.28, 0.28, 0.32, 1},
        borderInput = {0.22, 0.22, 0.26, 0.9},
        borderFocus = {0.38, 0.38, 0.45, 1.0},
        borderHover = {0.50, 0.50, 0.58, 1},
        borderCheck = {0.25, 0.25, 0.30, 0.8},
        borderMenu  = {0.22, 0.22, 0.28, 1},
        accentBar   = {0.35, 0.35, 0.42, 0.5},
        accentFocus = {0.48, 0.48, 0.55, 0.85},
        accentHover = {0.30, 0.30, 0.38, 1.0},
        textPrimary = {0.82, 0.82, 0.88},
        textBright  = {0.75, 0.75, 0.82},
        textNorm    = {0.65, 0.65, 0.72},
        textDim     = {0.35, 0.35, 0.40},
        textLabel   = {0.30, 0.30, 0.35},
        textMuted   = {0.52, 0.52, 0.58},
        textAccent  = {0.60, 0.60, 0.68},
        success     = {0.35, 0.78, 0.40},
        warning     = {0.90, 0.78, 0.25},
        danger      = {0.82, 0.28, 0.32},
        gold        = {0.92, 0.85, 0.42},
        line        = {0.14, 0.14, 0.18, 0.5},
        lineAccent  = {0.25, 0.25, 0.32, 0.35},
        separator   = {0.10, 0.10, 0.14, 0.3},
        catDungeon  = {0.35, 0.72, 0.40},
        catRaid     = {0.82, 0.50, 0.22},
        catWorldBoss= {0.78, 0.30, 0.28},
        catPvP      = {0.82, 0.28, 0.30},
        catMana     = {0.52, 0.35, 0.78},
        catKeystone = {0.82, 0.42, 0.60},
        catCustom   = {0.95, 0.72, 0.1},
        catAll      = {0.38, 0.58, 0.32},
        catMisc     = {0.45, 0.45, 0.48},
        titleR = 0.60, titleG = 0.60, titleB = 0.68,
    },

    Horde = {
        primary     = {0.85, 0.22, 0.18},
        secondary   = {0.25, 0.10, 0.08},
        accent      = {1.0, 0.82, 0.25},
        bgMain      = {0.10, 0.04, 0.03, 0.96},
        bgSection   = {0.08, 0.03, 0.02, 0.65},
        bgBlock     = {0.09, 0.04, 0.02, 0.55},
        bgButton    = {0.16, 0.08, 0.05, 0.9},
        bgInput     = {0.07, 0.03, 0.02, 0.85},
        bgInputFocus= {0.14, 0.06, 0.04, 0.95},
        bgRowOdd    = {0.05, 0.02, 0.01, 0.15},
        bgRowEven   = {0.09, 0.04, 0.02, 0.25},
        bgRowHover  = {0.22, 0.10, 0.06, 0.5},
        bgPopup     = {0.04, 0.02, 0.01, 0.9},
        bgToggleOn  = {0.85, 0.22, 0.18, 1},
        bgToggleOff = {0.30, 0.18, 0.12, 1},
        bgMenuBg    = {0.04, 0.02, 0.01, 0.98},
        bgCheckbox  = {0.08, 0.04, 0.02, 0.5},
        bgTabActive = {0.20, 0.08, 0.06, 1},
        bgTabInactive = {0.13, 0.06, 0.04, 0.9},
        border      = {0.55, 0.18, 0.14, 1},
        borderInput = {0.42, 0.14, 0.10, 0.9},
        borderFocus = {0.70, 0.25, 0.18, 1.0},
        borderHover = {0.85, 0.35, 0.22, 1},
        borderCheck = {0.45, 0.16, 0.12, 0.8},
        borderMenu  = {0.42, 0.14, 0.12, 1},
        accentBar   = {0.60, 0.20, 0.15, 0.5},
        accentFocus = {0.78, 0.30, 0.20, 0.85},
        accentHover = {0.50, 0.18, 0.12, 1.0},
        textPrimary = {0.98, 0.90, 0.82},
        textBright  = {0.95, 0.85, 0.72},
        textNorm    = {0.85, 0.75, 0.68},
        textDim     = {0.52, 0.38, 0.32},
        textLabel   = {0.45, 0.32, 0.28},
        textMuted   = {0.70, 0.58, 0.48},
        textAccent  = {1.0, 0.82, 0.25},
        success     = {0.40, 0.82, 0.30},
        warning     = {0.98, 0.80, 0.22},
        danger      = {0.90, 0.25, 0.18},
        gold        = {1.0, 0.92, 0.38},
        line        = {0.20, 0.08, 0.06, 0.5},
        lineAccent  = {0.40, 0.15, 0.10, 0.35},
        separator   = {0.15, 0.06, 0.04, 0.3},
        catDungeon  = {0.40, 0.78, 0.32},
        catRaid     = {0.90, 0.52, 0.18},
        catWorldBoss= {0.85, 0.35, 0.22},
        catPvP      = {0.88, 0.28, 0.22},
        catMana     = {0.58, 0.35, 0.82},
        catKeystone = {0.88, 0.45, 0.58},
        catCustom   = {0.92, 0.75, 0.05},
        catAll      = {0.48, 0.65, 0.30},
        catMisc     = {0.52, 0.45, 0.40},
        titleR = 0.85, titleG = 0.22, titleB = 0.18,
    },

    Alliance = {
        primary     = {0.18, 0.35, 0.85},
        secondary   = {0.08, 0.12, 0.25},
        accent      = {0.95, 0.85, 0.35},
        bgMain      = {0.03, 0.05, 0.12, 0.96},
        bgSection   = {0.02, 0.04, 0.10, 0.65},
        bgBlock     = {0.03, 0.05, 0.09, 0.55},
        bgButton    = {0.06, 0.10, 0.18, 0.9},
        bgInput     = {0.02, 0.04, 0.09, 0.85},
        bgInputFocus= {0.05, 0.09, 0.16, 0.95},
        bgRowOdd    = {0.02, 0.03, 0.06, 0.15},
        bgRowEven   = {0.04, 0.07, 0.12, 0.25},
        bgRowHover  = {0.08, 0.15, 0.28, 0.5},
        bgPopup     = {0.01, 0.02, 0.06, 0.9},
        bgToggleOn  = {0.18, 0.35, 0.85, 1},
        bgToggleOff = {0.18, 0.15, 0.22, 1},
        bgMenuBg    = {0.01, 0.02, 0.06, 0.98},
        bgCheckbox  = {0.03, 0.05, 0.09, 0.5},
        bgTabActive = {0.08, 0.14, 0.25, 1},
        bgTabInactive = {0.05, 0.09, 0.16, 0.9},
        border      = {0.18, 0.30, 0.62, 1},
        borderInput = {0.14, 0.22, 0.48, 0.9},
        borderFocus = {0.25, 0.42, 0.78, 1.0},
        borderHover = {0.35, 0.55, 0.92, 1},
        borderCheck = {0.16, 0.28, 0.52, 0.8},
        borderMenu  = {0.15, 0.25, 0.50, 1},
        accentBar   = {0.20, 0.35, 0.60, 0.5},
        accentFocus = {0.30, 0.50, 0.82, 0.85},
        accentHover = {0.18, 0.30, 0.52, 1.0},
        textPrimary = {0.85, 0.90, 0.98},
        textBright  = {0.78, 0.85, 0.95},
        textNorm    = {0.68, 0.75, 0.85},
        textDim     = {0.35, 0.42, 0.55},
        textLabel   = {0.30, 0.36, 0.48},
        textMuted   = {0.55, 0.62, 0.72},
        textAccent  = {0.95, 0.85, 0.35},
        success     = {0.32, 0.80, 0.38},
        warning     = {0.92, 0.82, 0.25},
        danger      = {0.85, 0.28, 0.28},
        gold        = {0.95, 0.88, 0.40},
        line        = {0.08, 0.14, 0.28, 0.5},
        lineAccent  = {0.15, 0.25, 0.45, 0.35},
        separator   = {0.06, 0.10, 0.20, 0.3},
        catDungeon  = {0.32, 0.78, 0.42},
        catRaid     = {0.85, 0.52, 0.22},
        catWorldBoss= {0.80, 0.32, 0.28},
        catPvP      = {0.82, 0.28, 0.28},
        catMana     = {0.55, 0.38, 0.82},
        catKeystone = {0.82, 0.45, 0.62},
        catCustom   = {0.95, 0.72, 0.08},
        catAll      = {0.35, 0.62, 0.35},
        catMisc     = {0.48, 0.50, 0.55},
        titleR = 0.18, titleG = 0.35, titleB = 0.85,
    },

    Plague = {
        primary     = {0.45, 0.72, 0.25},
        secondary   = {0.18, 0.25, 0.10},
        accent      = {0.65, 0.90, 0.30},
        bgMain      = {0.06, 0.08, 0.03, 0.96},
        bgSection   = {0.05, 0.07, 0.02, 0.65},
        bgBlock     = {0.06, 0.08, 0.03, 0.55},
        bgButton    = {0.10, 0.15, 0.05, 0.9},
        bgInput     = {0.05, 0.07, 0.02, 0.85},
        bgInputFocus= {0.09, 0.14, 0.04, 0.95},
        bgRowOdd    = {0.04, 0.06, 0.02, 0.15},
        bgRowEven   = {0.08, 0.10, 0.04, 0.25},
        bgRowHover  = {0.15, 0.25, 0.06, 0.5},
        bgPopup     = {0.03, 0.04, 0.01, 0.9},
        bgToggleOn  = {0.45, 0.72, 0.25, 1},
        bgToggleOff = {0.25, 0.15, 0.10, 1},
        bgMenuBg    = {0.03, 0.04, 0.01, 0.98},
        bgCheckbox  = {0.06, 0.08, 0.03, 0.5},
        bgTabActive = {0.14, 0.22, 0.06, 1},
        bgTabInactive = {0.09, 0.12, 0.04, 0.9},
        border      = {0.30, 0.45, 0.15, 1},
        borderInput = {0.22, 0.35, 0.10, 0.9},
        borderFocus = {0.40, 0.60, 0.18, 1.0},
        borderHover = {0.55, 0.80, 0.25, 1},
        borderCheck = {0.28, 0.42, 0.14, 0.8},
        borderMenu  = {0.26, 0.40, 0.12, 1},
        accentBar   = {0.35, 0.55, 0.15, 0.5},
        accentFocus = {0.50, 0.75, 0.22, 0.85},
        accentHover = {0.30, 0.48, 0.14, 1.0},
        textPrimary = {0.92, 0.95, 0.85},
        textBright  = {0.85, 0.92, 0.78},
        textNorm    = {0.78, 0.82, 0.72},
        textDim     = {0.42, 0.48, 0.35},
        textLabel   = {0.36, 0.42, 0.30},
        textMuted   = {0.60, 0.65, 0.52},
        textAccent  = {0.65, 0.90, 0.30},
        success     = {0.35, 0.85, 0.30},
        warning     = {0.95, 0.82, 0.22},
        danger      = {0.88, 0.35, 0.28},
        gold        = {0.95, 0.90, 0.35},
        line        = {0.15, 0.22, 0.08, 0.5},
        lineAccent  = {0.28, 0.42, 0.12, 0.35},
        separator   = {0.12, 0.18, 0.06, 0.3},
        catDungeon  = {0.35, 0.78, 0.30},
        catRaid     = {0.82, 0.52, 0.22},
        catWorldBoss= {0.78, 0.32, 0.28},
        catPvP      = {0.82, 0.30, 0.28},
        catMana     = {0.55, 0.35, 0.80},
        catKeystone = {0.82, 0.45, 0.62},
        catCustom   = {0.9, 0.75, 0.12},
        catAll      = {0.40, 0.60, 0.28},
        catMisc     = {0.48, 0.50, 0.42},
        titleR = 0.65, titleG = 0.90, titleB = 0.30,
    },

    Druid = {
        primary     = {0.76, 0.56, 0.22},
        secondary   = {0.22, 0.18, 0.10},
        accent      = {0.90, 0.78, 0.35},
        bgMain      = {0.10, 0.08, 0.04, 0.96},
        bgSection   = {0.08, 0.06, 0.03, 0.65},
        bgBlock     = {0.09, 0.07, 0.03, 0.55},
        bgButton    = {0.16, 0.12, 0.06, 0.9},
        bgInput     = {0.07, 0.05, 0.02, 0.85},
        bgInputFocus= {0.14, 0.10, 0.05, 0.95},
        bgRowOdd    = {0.05, 0.04, 0.02, 0.15},
        bgRowEven   = {0.09, 0.07, 0.03, 0.25},
        bgRowHover  = {0.22, 0.17, 0.08, 0.5},
        bgPopup     = {0.04, 0.03, 0.01, 0.9},
        bgToggleOn  = {0.76, 0.56, 0.22, 1},
        bgToggleOff = {0.30, 0.20, 0.10, 1},
        bgMenuBg    = {0.04, 0.03, 0.01, 0.98},
        bgCheckbox  = {0.08, 0.06, 0.03, 0.5},
        bgTabActive = {0.20, 0.15, 0.07, 1},
        bgTabInactive = {0.13, 0.10, 0.05, 0.9},
        border      = {0.50, 0.38, 0.18, 1},
        borderInput = {0.38, 0.28, 0.14, 0.9},
        borderFocus = {0.65, 0.50, 0.22, 1.0},
        borderHover = {0.80, 0.62, 0.28, 1},
        borderCheck = {0.42, 0.32, 0.16, 0.8},
        borderMenu  = {0.40, 0.30, 0.14, 1},
        accentBar   = {0.55, 0.42, 0.18, 0.5},
        accentFocus = {0.72, 0.55, 0.25, 0.85},
        accentHover = {0.48, 0.36, 0.16, 1.0},
        textPrimary = {0.95, 0.90, 0.80},
        textBright  = {0.92, 0.85, 0.72},
        textNorm    = {0.82, 0.75, 0.65},
        textDim     = {0.50, 0.42, 0.32},
        textLabel   = {0.42, 0.36, 0.28},
        textMuted   = {0.68, 0.60, 0.48},
        textAccent  = {0.90, 0.78, 0.35},
        success     = {0.42, 0.82, 0.30},
        warning     = {0.95, 0.80, 0.25},
        danger      = {0.88, 0.32, 0.22},
        gold        = {1.0, 0.92, 0.45},
        line        = {0.22, 0.17, 0.08, 0.5},
        lineAccent  = {0.42, 0.32, 0.14, 0.35},
        separator   = {0.18, 0.14, 0.06, 0.3},
        catDungeon  = {0.42, 0.78, 0.35},
        catRaid     = {0.88, 0.55, 0.18},
        catWorldBoss= {0.85, 0.35, 0.22},
        catPvP      = {0.85, 0.28, 0.22},
        catMana     = {0.58, 0.38, 0.82},
        catKeystone = {0.88, 0.50, 0.60},
        catCustom   = {0.92, 0.7, 0.1},
        catAll      = {0.55, 0.65, 0.30},
        catMisc     = {0.52, 0.48, 0.38},
        titleR = 0.90, titleG = 0.78, titleB = 0.35,
    },

    Warlock = {
        primary     = {0.18, 0.78, 0.28},
        secondary   = {0.20, 0.10, 0.25},
        accent      = {0.55, 0.22, 0.72},
        bgMain      = {0.06, 0.03, 0.08, 0.96},
        bgSection   = {0.05, 0.02, 0.06, 0.65},
        bgBlock     = {0.06, 0.03, 0.07, 0.55},
        bgButton    = {0.10, 0.06, 0.14, 0.9},
        bgInput     = {0.05, 0.02, 0.06, 0.85},
        bgInputFocus= {0.10, 0.06, 0.12, 0.95},
        bgRowOdd    = {0.04, 0.02, 0.05, 0.15},
        bgRowEven   = {0.07, 0.04, 0.09, 0.25},
        bgRowHover  = {0.15, 0.08, 0.20, 0.5},
        bgPopup     = {0.03, 0.01, 0.04, 0.9},
        bgToggleOn  = {0.18, 0.78, 0.28, 1},
        bgToggleOff = {0.30, 0.12, 0.18, 1},
        bgMenuBg    = {0.03, 0.01, 0.04, 0.98},
        bgCheckbox  = {0.06, 0.03, 0.07, 0.5},
        bgTabActive = {0.14, 0.08, 0.18, 1},
        bgTabInactive = {0.09, 0.05, 0.12, 0.9},
        border      = {0.35, 0.18, 0.48, 1},
        borderInput = {0.28, 0.14, 0.38, 0.9},
        borderFocus = {0.45, 0.22, 0.62, 1.0},
        borderHover = {0.62, 0.32, 0.82, 1},
        borderCheck = {0.32, 0.16, 0.42, 0.8},
        borderMenu  = {0.30, 0.15, 0.40, 1},
        accentBar   = {0.30, 0.55, 0.20, 0.5},
        accentFocus = {0.40, 0.72, 0.25, 0.85},
        accentHover = {0.28, 0.48, 0.18, 1.0},
        textPrimary = {0.88, 0.92, 0.82},
        textBright  = {0.82, 0.90, 0.75},
        textNorm    = {0.72, 0.78, 0.68},
        textDim     = {0.38, 0.42, 0.35},
        textLabel   = {0.32, 0.36, 0.28},
        textMuted   = {0.58, 0.62, 0.52},
        textAccent  = {0.55, 0.22, 0.72},
        success     = {0.30, 0.82, 0.35},
        warning     = {0.92, 0.82, 0.22},
        danger      = {0.88, 0.28, 0.35},
        gold        = {0.95, 0.88, 0.42},
        line        = {0.14, 0.08, 0.20, 0.5},
        lineAccent  = {0.28, 0.15, 0.38, 0.35},
        separator   = {0.10, 0.06, 0.15, 0.3},
        catDungeon  = {0.30, 0.80, 0.35},
        catRaid     = {0.85, 0.50, 0.25},
        catWorldBoss= {0.80, 0.30, 0.35},
        catPvP      = {0.85, 0.25, 0.30},
        catMana     = {0.52, 0.32, 0.82},
        catKeystone = {0.82, 0.42, 0.65},
        catCustom   = {0.95, 0.75, 0.08},
        catAll      = {0.35, 0.65, 0.32},
        catMisc     = {0.48, 0.45, 0.50},
        titleR = 0.18, titleG = 0.78, titleB = 0.28,
    },

    Northrend = {
        primary     = {0.55, 0.72, 0.88},
        secondary   = {0.18, 0.22, 0.30},
        accent      = {0.78, 0.88, 1.0},
        bgMain      = {0.04, 0.06, 0.10, 0.96},
        bgSection   = {0.03, 0.05, 0.08, 0.65},
        bgBlock     = {0.04, 0.06, 0.09, 0.55},
        bgButton    = {0.08, 0.12, 0.18, 0.9},
        bgInput     = {0.03, 0.05, 0.08, 0.85},
        bgInputFocus= {0.07, 0.10, 0.16, 0.95},
        bgRowOdd    = {0.03, 0.04, 0.06, 0.15},
        bgRowEven   = {0.05, 0.07, 0.10, 0.25},
        bgRowHover  = {0.12, 0.18, 0.28, 0.5},
        bgPopup     = {0.02, 0.03, 0.06, 0.9},
        bgToggleOn  = {0.55, 0.72, 0.88, 1},
        bgToggleOff = {0.18, 0.22, 0.30, 1},
        bgMenuBg    = {0.02, 0.03, 0.06, 0.98},
        bgCheckbox  = {0.04, 0.06, 0.09, 0.5},
        bgTabActive = {0.10, 0.16, 0.24, 1},
        bgTabInactive = {0.07, 0.10, 0.16, 0.9},
        border      = {0.30, 0.42, 0.58, 1},
        borderInput = {0.22, 0.32, 0.45, 0.9},
        borderFocus = {0.42, 0.58, 0.78, 1.0},
        borderHover = {0.58, 0.72, 0.92, 1},
        borderCheck = {0.28, 0.38, 0.52, 0.8},
        borderMenu  = {0.25, 0.35, 0.50, 1},
        accentBar   = {0.38, 0.52, 0.70, 0.5},
        accentFocus = {0.52, 0.68, 0.88, 0.85},
        accentHover = {0.32, 0.45, 0.62, 1.0},
        textPrimary = {0.88, 0.92, 0.98},
        textBright  = {0.82, 0.88, 0.95},
        textNorm    = {0.72, 0.78, 0.85},
        textDim     = {0.38, 0.45, 0.55},
        textLabel   = {0.32, 0.38, 0.48},
        textMuted   = {0.58, 0.65, 0.75},
        textAccent  = {0.78, 0.88, 1.0},
        success     = {0.35, 0.82, 0.42},
        warning     = {0.95, 0.82, 0.30},
        danger      = {0.85, 0.30, 0.28},
        gold        = {0.98, 0.92, 0.55},
        line        = {0.12, 0.18, 0.28, 0.5},
        lineAccent  = {0.25, 0.35, 0.50, 0.35},
        separator   = {0.08, 0.12, 0.20, 0.3},
        catDungeon  = {0.35, 0.78, 0.48},
        catRaid     = {0.82, 0.52, 0.22},
        catWorldBoss= {0.78, 0.32, 0.28},
        catPvP      = {0.82, 0.30, 0.28},
        catMana     = {0.55, 0.38, 0.82},
        catKeystone = {0.82, 0.48, 0.62},
        catCustom   = {0.92, 0.72, 0.1},
        catAll      = {0.42, 0.62, 0.35},
        catMisc     = {0.48, 0.52, 0.58},
        titleR = 0.55, titleG = 0.72, titleB = 0.88,
    },

    Dragon = {
        primary     = {0.88, 0.35, 0.18},
        secondary   = {0.25, 0.12, 0.08},
        accent      = {1.0, 0.82, 0.30},
        bgMain      = {0.10, 0.04, 0.03, 0.96},
        bgSection   = {0.08, 0.03, 0.02, 0.65},
        bgBlock     = {0.09, 0.04, 0.02, 0.55},
        bgButton    = {0.16, 0.08, 0.05, 0.9},
        bgInput     = {0.07, 0.03, 0.02, 0.85},
        bgInputFocus= {0.14, 0.07, 0.04, 0.95},
        bgRowOdd    = {0.05, 0.02, 0.01, 0.15},
        bgRowEven   = {0.09, 0.04, 0.02, 0.25},
        bgRowHover  = {0.24, 0.12, 0.06, 0.5},
        bgPopup     = {0.04, 0.02, 0.01, 0.9},
        bgToggleOn  = {0.88, 0.35, 0.18, 1},
        bgToggleOff = {0.32, 0.18, 0.12, 1},
        bgMenuBg    = {0.04, 0.02, 0.01, 0.98},
        bgCheckbox  = {0.08, 0.04, 0.02, 0.5},
        bgTabActive = {0.22, 0.10, 0.06, 1},
        bgTabInactive = {0.14, 0.07, 0.04, 0.9},
        border      = {0.58, 0.28, 0.15, 1},
        borderInput = {0.42, 0.20, 0.12, 0.9},
        borderFocus = {0.72, 0.38, 0.18, 1.0},
        borderHover = {0.88, 0.48, 0.22, 1},
        borderCheck = {0.48, 0.24, 0.14, 0.8},
        borderMenu  = {0.45, 0.22, 0.12, 1},
        accentBar   = {0.65, 0.32, 0.15, 0.5},
        accentFocus = {0.82, 0.45, 0.20, 0.85},
        accentHover = {0.55, 0.28, 0.12, 1.0},
        textPrimary = {0.98, 0.92, 0.85},
        textBright  = {0.95, 0.85, 0.75},
        textNorm    = {0.85, 0.75, 0.68},
        textDim     = {0.52, 0.40, 0.35},
        textLabel   = {0.45, 0.34, 0.30},
        textMuted   = {0.70, 0.58, 0.52},
        textAccent  = {1.0, 0.82, 0.30},
        success     = {0.42, 0.82, 0.30},
        warning     = {0.98, 0.80, 0.22},
        danger      = {0.90, 0.28, 0.20},
        gold        = {1.0, 0.92, 0.40},
        line        = {0.22, 0.10, 0.06, 0.5},
        lineAccent  = {0.42, 0.20, 0.10, 0.35},
        separator   = {0.16, 0.08, 0.04, 0.3},
        catDungeon  = {0.38, 0.78, 0.35},
        catRaid     = {0.90, 0.52, 0.18},
        catWorldBoss= {0.85, 0.35, 0.22},
        catPvP      = {0.88, 0.30, 0.22},
        catMana     = {0.58, 0.35, 0.82},
        catKeystone = {0.88, 0.45, 0.58},
        catCustom   = {0.95, 0.75, 0.08},
        catAll      = {0.50, 0.65, 0.30},
        catMisc     = {0.52, 0.45, 0.40},
        titleR = 0.88, titleG = 0.35, titleB = 0.18,
    },

    Titan = {
        primary     = {0.72, 0.62, 0.38},
        secondary   = {0.18, 0.15, 0.10},
        accent      = {0.88, 0.78, 0.48},
        bgMain      = {0.08, 0.06, 0.04, 0.96},
        bgSection   = {0.06, 0.05, 0.03, 0.65},
        bgBlock     = {0.07, 0.06, 0.03, 0.55},
        bgButton    = {0.14, 0.10, 0.06, 0.9},
        bgInput     = {0.06, 0.04, 0.02, 0.85},
        bgInputFocus= {0.12, 0.09, 0.05, 0.95},
        bgRowOdd    = {0.04, 0.03, 0.02, 0.15},
        bgRowEven   = {0.07, 0.05, 0.03, 0.25},
        bgRowHover  = {0.20, 0.15, 0.08, 0.5},
        bgPopup     = {0.03, 0.02, 0.01, 0.9},
        bgToggleOn  = {0.72, 0.62, 0.38, 1},
        bgToggleOff = {0.28, 0.22, 0.15, 1},
        bgMenuBg    = {0.03, 0.02, 0.01, 0.98},
        bgCheckbox  = {0.06, 0.05, 0.03, 0.5},
        bgTabActive = {0.18, 0.14, 0.08, 1},
        bgTabInactive = {0.12, 0.09, 0.05, 0.9},
        border      = {0.48, 0.40, 0.25, 1},
        borderInput = {0.35, 0.30, 0.18, 0.9},
        borderFocus = {0.60, 0.50, 0.32, 1.0},
        borderHover = {0.75, 0.62, 0.40, 1},
        borderCheck = {0.40, 0.34, 0.22, 0.8},
        borderMenu  = {0.38, 0.32, 0.20, 1},
        accentBar   = {0.52, 0.44, 0.28, 0.5},
        accentFocus = {0.68, 0.58, 0.38, 0.85},
        accentHover = {0.45, 0.38, 0.24, 1.0},
        textPrimary = {0.95, 0.90, 0.82},
        textBright  = {0.90, 0.85, 0.75},
        textNorm    = {0.80, 0.75, 0.68},
        textDim     = {0.48, 0.42, 0.35},
        textLabel   = {0.40, 0.35, 0.28},
        textMuted   = {0.65, 0.58, 0.48},
        textAccent  = {0.88, 0.78, 0.48},
        success     = {0.38, 0.82, 0.35},
        warning     = {0.92, 0.80, 0.25},
        danger      = {0.85, 0.32, 0.25},
        gold        = {0.95, 0.88, 0.40},
        line        = {0.18, 0.14, 0.08, 0.5},
        lineAccent  = {0.35, 0.28, 0.18, 0.35},
        separator   = {0.14, 0.10, 0.06, 0.3},
        catDungeon  = {0.38, 0.78, 0.40},
        catRaid     = {0.85, 0.55, 0.22},
        catWorldBoss= {0.82, 0.35, 0.25},
        catPvP      = {0.85, 0.28, 0.25},
        catMana     = {0.55, 0.38, 0.82},
        catKeystone = {0.85, 0.48, 0.62},
        catCustom   = {0.9, 0.72, 0.1},
        catAll      = {0.48, 0.65, 0.35},
        catMisc     = {0.50, 0.48, 0.42},
        titleR = 0.72, titleG = 0.62, titleB = 0.38,
    },
}

local _currentName = "Shadow"
local _currentTheme = THEMES.Shadow

local _crossDeps = {
    _dShift = 0,
    _dMul = 1.0,
}

local function _recalcCrossDeps()
    _crossDeps._dShift = 0
    _crossDeps._dMul = 1.0
end

local ThemeAPI = {}

function ThemeAPI.Get(token)
    if not token then return {1, 0, 1} end

    local val = _currentTheme[token]
    if val ~= nil then
        return val
    end

    local frostDefault = THEMES.Frost[token]
    if frostDefault then
        return frostDefault
    end

    return {1, 0, 1}
end

function ThemeAPI.GetName()
    return _currentName
end

function ThemeAPI.Set(name)
    if not name then return false end

    local theme = THEMES[name]
    if not theme then
        return false
    end

    _currentName = name
    _currentTheme = theme
    _recalcCrossDeps()

    if FrostSeekDB and FrostSeekDB.Settings then
        FrostSeekDB.Settings.theme = name
    end

    return true
end

function ThemeAPI.GetThemes()
    local list = {}
    for name, _ in pairs(THEMES) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

function ThemeAPI.Apply()
    local FS = _G.FrostSeek
    if not FS then return end
    local T = ThemeAPI

    if FS.MainFrame then
        FS.MainFrame:SetBackdropColor(unpack(T.Get("bgMain")))
        FS.MainFrame:SetBackdropBorderColor(unpack(T.Get("border")))

        for _, child in ipairs({FS.MainFrame:GetRegions()}) do
            if child:GetObjectType() == "FontString" then
                local txt = child:GetText() or ""
                if string.find(txt, "Frost") and string.find(txt, "Seek") then
                    local tc = T.Get("primary")
                    child:SetTextColor(tc[1], tc[2], tc[3])
                end
            end
        end
    end

    if FS.Tabs then
        for name, tabData in pairs(FS.Tabs) do
            if tabData.button then
                local btn = tabData.button
                if FS.ActiveTab == name then
                    btn.bg:SetColorTexture(unpack(T.Get("bgTabActive")))
                    local bc = T.Get("borderFocus")
                    btn.border:SetColorTexture(unpack(bc))
                    local pc = T.Get("primary")
                    btn.activeOverlay:SetColorTexture(pc[1], pc[2], pc[3], 0.2)
                    btn.activeOverlay:Show()
                    local tc = T.Get("textPrimary")
                    btn.text:SetTextColor(tc[1], tc[2], tc[3])
                else
                    btn.bg:SetColorTexture(unpack(T.Get("bgTabInactive")))
                    btn.border:SetColorTexture(unpack(T.Get("border")))
                    btn.activeOverlay:Hide()
                    local mc = T.Get("textMuted")
                    btn.text:SetTextColor(mc[1], mc[2], mc[3])
                end
            end
        end
    end

    if FS.Modules then
        for _, mod in pairs(FS.Modules) do
            if mod and mod.ApplyTheme then
                local ok, err = pcall(function() mod:ApplyTheme() end)
                if not ok and FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
                    print(_G.FrostSeek.L["theme_error_applying"] .. tostring(err))
                end
            end
        end
    end
end

function ThemeAPI.RegisterModule(modName)
end

if not FSK_FontSystem then
    FSK_FontSystem = { templates = {}, objects = {} }
    local EMERGENCY = {
        { obj = "FSKFontNormalSmall",  src = "GameFontNormalSmall",  size = 10 },
        { obj = "FSKFontNormal",       src = "GameFontNormal",       size = 12 },
        { obj = "FSKFontNormalLarge",  src = "GameFontNormalLarge",  size = 14 },
        { obj = "FSKFontNormalHuge",   src = "GameFontNormalHuge",   size = 20 },
        { obj = "FSKFontDisableSmall", src = "GameFontDisableSmall", size = 10 },
    }
    for _, t in ipairs(EMERGENCY) do
        local o = CreateFont(t.obj)
        _G[t.obj] = o
        local ok, file = pcall(function() return o:GetFont() end)
        if not ok or not file then
            local src = _G[t.src]
            if src then
                pcall(function()
                    local f2, s2, fl2 = src:GetFont()
                    if f2 then o:SetFont(f2, s2, fl2) end
                end)
            end
            local ok3, file3 = pcall(function() return o:GetFont() end)
            if not ok3 or not file3 then
                
                pcall(function()
                    o:SetFont("Interface\\AddOns\\FrostSeek\\Media\\Fonts\\Carlito-Regular.ttf", t.size, "")
                end)
            end
            local ok4, file4 = pcall(function() return o:GetFont() end)
            if not ok4 or not file4 then
                pcall(function() o:SetFont("Fonts\\FRIZQT__.TTF", t.size, "") end)
            end
        end
        t.object = o
        FSK_FontSystem.objects[t.obj] = o
    end
    FSK_FontSystem.templates = EMERGENCY
end

local FSK_FONT_TEMPLATES = FSK_FontSystem.templates
local _fontObjs = FSK_FontSystem.objects

ThemeAPI.FONTS = {
    { id = "default",  label = nil,                    file = nil },
    { id = "carlito",  label = "Carlito (bundled)",    file = "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\Carlito-Regular.ttf" },
    { id = "libsans",  label = "Liberation Sans (bundled)", file = "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\LiberationSans-Regular.ttf" },
    { id = "libserif", label = "Liberation Serif (bundled)", file = "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\LiberationSerif-Regular.ttf" },
    { id = "dejavu",   label = "DejaVu Sans (bundled)", file = "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\DejaVuSans.ttf" },
    { id = "frizqt",   label = "Friz Quadrata",        file = "Fonts\\FRIZQT__.TTF" },
    { id = "arialn",   label = "Arial",                file = "Fonts\\ARIALN.TTF" },
    { id = "skurri",   label = "Skurri",               file = "Fonts\\SKURRI.TTF" },
    { id = "morpheus", label = "Morpheus",             file = "Fonts\\MORPHEUS.TTF" },
}

function ThemeAPI.GetFonts()
    local labels = {}
    local L = (_G.FrostSeek and _G.FrostSeek.L) or {}
    for i, f in ipairs(ThemeAPI.FONTS) do
        if f.id == "default" then
            labels[i] = L["opt_font_default"] or "Default (Game)"
        else
            labels[i] = f.label
        end
    end
    return labels
end

function ThemeAPI.GetFont()
    return (FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.font) or "default"
end

function ThemeAPI.GetFontLabel()
    local id = ThemeAPI.GetFont()
    local L = (_G.FrostSeek and _G.FrostSeek.L) or {}
    for _, f in ipairs(ThemeAPI.FONTS) do
        if f.id == id then
            if f.id == "default" then
                return L["opt_font_default"] or "Default (Game)"
            end
            return f.label
        end
    end
    return L["opt_font_default"] or "Default (Game)"
end

function ThemeAPI.SetFont(fontId)
    local font = nil
    for _, f in ipairs(ThemeAPI.FONTS) do
        if f.id == fontId then font = f break end
    end
    if not font then
        fontId = "default"
        font = ThemeAPI.FONTS[1]
    end

    for _, t in ipairs(FSK_FONT_TEMPLATES) do
        local obj = _fontObjs[t.obj]
        if obj then
            if font.file then
                local _, size, flags = obj:GetFont()
                if not size then
                
                    for _, tt in ipairs(FSK_FONT_TEMPLATES) do
                        if _fontObjs[tt.obj] == obj then size = tt.size break end
                    end
                end
                pcall(function() obj:SetFont(font.file, size or t.size or 12, flags or "") end)
            
                if FSK_FontSystem.FontWorks and not FSK_FontSystem.FontWorks(obj) then
                    FSK_FontSystem.ApplyBestAvailable(obj, size or t.size or 12)
                end
            else
                if FSK_FontSystem.DeriveFromSource then
                    FSK_FontSystem.DeriveFromSource(obj, _G[t.src], t.size)
                end
            end
        end
    end

    if FrostSeekDB and FrostSeekDB.Settings then
        FrostSeekDB.Settings.font = fontId
    end
    return true
end

function ThemeAPI.SetFontByLabel(label)
    local L = (_G.FrostSeek and _G.FrostSeek.L) or {}
    if label == (L["opt_font_default"] or "Default (Game)") then
        return ThemeAPI.SetFont("default")
    end
    for _, f in ipairs(ThemeAPI.FONTS) do
        if f.label == label then
            return ThemeAPI.SetFont(f.id)
        end
    end
    return false
end

local _initDone = false

local function InitTheme()
    if _initDone then return end
    _initDone = true
    if FSK_FontSystem and FSK_FontSystem.EnsureValid then
        FSK_FontSystem.EnsureValid()
    end

    if FrostSeekDB and FrostSeekDB.Settings then
        if FrostSeekDB.Settings.theme == nil then
            FrostSeekDB.Settings.theme = "Shadow"
        end

        local saved = FrostSeekDB.Settings.theme
        if saved and THEMES[saved] then
            _currentName = saved
            _currentTheme = THEMES[saved]
        end

        if not THEMES[saved] then
            _currentName = "Shadow"
            _currentTheme = THEMES.Shadow
            FrostSeekDB.Settings.theme = "Shadow"
        end

        if FrostSeekDB.Settings.font and FrostSeekDB.Settings.font ~= "default" then
            ThemeAPI.SetFont(FrostSeekDB.Settings.font)
        end
    end

    ThemeAPI.RegisterModule("theme")

    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
        print(_G.FrostSeek.L["theme_initialized_active"] .. _currentName)
    end
end

FrostSeekTheme = ThemeAPI

local themeInitFrame = CreateFrame("Frame")
themeInitFrame:RegisterEvent("ADDON_LOADED")
themeInitFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == "FrostSeek" then
        self:UnregisterEvent("ADDON_LOADED")
        InitTheme()
    end
end)

C_Timer.After(3, function()
    if not _initDone then
        InitTheme()
    end
end)