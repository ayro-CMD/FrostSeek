# ⚡ FrostSeek 

**6 languages  localized: English, Italian, German, Spanish, French, Portuguese.**
**Advanced LFG/LFM Manager with FrostNet** — for WoW Ascension & all WoW Classic / Retail clients.

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](License)
[![Version](https://img.shields.io/badge/Version-2.3.3-blue.svg)](https://www.curseforge.com/wow/addons/frostseek)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Tabs](#tabs)
- [New Features in v2.2.5](#new-features-in-v225)
- [Slash Commands](#slash-commands)
- [Support](#support)

---

## 🎯 Overview

FrostSeek is a comprehensive LFG/LFM addon that helps you find groups and members in World of Warcraft. It works on Ascension, 3.3.5 private servers, and all WoW Classic/Retail clients.

**Key highlights:**
- 🌐 **FrostNet** — serverless P2P listing board (no dependency on server chat)
- 🔍 **LFG** — auto-detect recruitment messages with popup alerts
- 📢 **LFM** — full LFM interface with auto-spam and auto-invite
- 🚫 **Chat Filter** — hide LFG/LFM spam from normal chat channels
- 🎯 **Keystone Filter** — show only keystones at or above a minimum level
- 🌍 **Multi-language** — English, Italian, German, Spanish, French, Portuguese
- 🎨 **Themes** — customizable color schemes

---

## ✨ Features

### 🔍 LFG — Looking For Group

Auto-detect recruitment messages with popup alerts, category filters, keyword filters, cooldown system, and customizable whisper templates with role/class/ilvl/enchant/keystone support.

**Categories:** Dungeon, Raid, Keystone, PvP, World Boss, Manastorm, Event

**Difficulty filters per category:**
- Dungeon: Normal, Heroic, HC, Mythic
- Raid: Normal, Heroic, HC, Mythic, Ascended, Trial
- Manastorm: Leveling, Bonzo, ALVA
- Keystone: level filter (0-30+)

### 📢 LFM — Looking For Members

Full LFM interface with:
- Auto-spam with customizable timers
- Activity dropdown
- Real-time message preview
- Multi-channel support
- Auto-invite by minimum ilvl
- Auto-stop at member count threshold
- Bonus Coin support for keystones

### 🌐 FrostNet

Serverless P2P listing board:
- Browse, Create Group, Apply, Whisper leader
- Protocol v2 (`FSK2`) with backward compat
- `C_ChatInfo.SendAddonMessage` on modern clients
- Heartbeat keepalives
- Per-sender rate limiter
- Voice bridge (Discord/TS)

### 📊 Dashboard

Real-time player stats:
- Average ilvl
- Role info
- FrostNet online count
- Module status overview
- Session statistics

### 🚫 Chat Filter (NEW)

Hide LFG/LFM messages from normal chat channels:
- Filters: lfg, lfm, lfr, lf1m-lf5m, looking for group/member/raid, keystone
- Smart "lf + role" detection (avoids false positives like "half", "self")
- Custom keywords support
- Addon channels (FSK, FSK-EVT) always excluded
- Works on CHANNEL, YELL, SAY, GUILD

### 🎯 Keystone Level Filter (NEW)

Show only keystones at or above a minimum level:
- Set minimum level (0-30) in LFG → Keystone category
- Applied to popups and recruiters list
- Smart parser handles all keystone formats:
  - `[Keystone: Name (level)]` (CoA format)
  - `[Keystone: Name] (level)` (standard format)
  - `Keystone: Name (N)` (unbracketed)
  - Item links `|Hitem:...|h[Keystone: Name]|h`
- Strip WoW color codes before parsing

### 🎨 Themes

Multiple color themes: Frost, Shadow, Void, and more. All popup buttons are themed to match the addon UI.

### 🌍 Multi-language

Supported languages:
- English (enUS)
- Italian (itIT)
- German (deDE)
- Spanish (esES)
- French (frFR)
- Portuguese (ptBR)
- Auto-detect (follows WoW client language)

---

## 📦 Installation

1. Close WoW
2. Extract the `FrostSeek` folder into `Interface\AddOns\`
3. Final structure:
   ```
   Interface\AddOns\FrostSeek\
   ├── FrostSeek.toc
   ├── Core.lua
   ├── loader.xml
   ├── Guide\
   │   ├── Guida ITA.md
   │   └── Guide ENG.md
   ├── Locales\
   ├── Media\
   └── Modules\
   ```
4. Open WoW — you'll see `FrostSeek v2.3.3 loaded!` in chat

---

## 🚀 Quick Start

1. **First launch:** A 4-page setup wizard appears:
   - Page 1: Choose language
   - Page 2: Choose your role (Tank/Healer/DPS/Support)
   - Page 3: Enable popups, sounds, and chat filter
   - Page 4: Click Finish

2. **Open the addon:**
   - Click the minimap button, OR
   - Type `/fs` in chat

3. **Find a group (LFG):**
   - Open the LFG tab
   - Select your role
   - Choose a category (Dungeon, Raid, Keystone, etc.)
   - Wait for popups when someone looks for members

4. **Find members (LFM):**
   - Open the LFM tab
   - Select the activity
   - Choose roles needed
   - Click "Start Spam"

5. **Use FrostNet:**
   - Open the FrostNet tab
   - Browse open groups
   - Apply with one click

---

## 📑 Tabs

| Tab | Description |
|-----|-------------|
| **Dashboard** | Player stats, iLvl, FrostNet status, session counters |
| **FrostNet** | P2P listing board — browse, create, apply |
| **LFG** | Looking For Group — popup alerts when someone seeks members |
| **LFM** | Looking For Members — spam your LFM message |
| **Community** | Guild browser, recruitment, event board |
| **Options** | All settings |


---

## 📖 Documentation

- **Italian guide:** `Guide/Guida ITA.md`
- **English guide:** `Guide/Guide ENG.md`

---

## 🔧 Technical Details

- **Saved Variables:** `FrostSeekDB`
- **Supported clients:** Vanilla Classic, TBC Classic, WotLK (3.3.5),WotLK Classic, Cata Classic, Mists Classic, Ascension Private Server
- **Load order:** Compat → Theme → UIUtils → Shared → Core → Locales → Modules
- **Network protocol:** FSK2 (backward compatible with FSK1)
- **Channels:** FSK (main), FSK-EVT (events)
- **Watermark:** FSK-WM-36DA8EFBD010-FSK-AYRO-2026-7F3C-9A21-BD54-8E1F

---

## 📄 License

**FrostSeek Proprietary License — All Rights Reserved**

Copyright © 2026 Ayro. All rights reserved.

This source code is the proprietary intellectual property of Ayro. Unauthorized copying, modification, redistribution, or use of any part of this code, in whole or in part, via any medium, is strictly prohibited without the express written permission of the author.

For licensing inquiries, contact the author via the official repository:
- CurseForge Project ID: 1460315

---

## 👤 Author

**Ayro** — FrostSeek creator and maintainer

---

## 🙏 Acknowledgments

Thanks to all the testers and users who provided feedback on Ascension, and other private servers. Special thanks to Ernestodx for minimap icon

---

**FrostSeek** — Find groups faster. Find members smarter.
FrostSeek Plugin https://github.com/jak2772/FrostSeekAddon-Aura-Tracker
