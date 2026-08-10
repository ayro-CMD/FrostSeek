# ⚡ FrostSeek v2.2.5
**ONLY ENG/IT LANGUAGE IS FULL TRANSLATE ATM** (OTHER IS WIP)
**Advanced LFG/LFM Manager with FrostNet** — for WoW Ascension & all WoW Classic / Retail clients.

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](License)
[![Version](https://img.shields.io/badge/Version-2.2.5-blue.svg)](https://www.curseforge.com/wow/addons/frostseek)

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
4. Open WoW — you'll see `FrostSeek v2.2.5 loaded!` in chat

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

## 🆕 New Features in v2.2.5

### Chat Filter
- Hide LFG/LFM spam from Trade, General, Yell, Say, Guild
- Smart keyword matching with role detection
- Custom keywords support
- Addon channels always excluded
- Debug commands: `/fscf status`, `/fscf log`, `/fscf reregister`

### Keystone Level Filter
- Show only keystones at or above a minimum level
- Works in LFG popups and recruiters list
- Smart parser handles all keystone formats (CoA, standard, item links)
- Test command: `/fskeytest <message>`

### Setup Wizard
- 4-page guided setup for new users
- Language, role, popups, sounds, chat filter
- Saves to FrostSeekDB

### UI Improvements
- Removed FrostNet button from LFG (channel managed in background)
- Removed LFG toggle from top-right
- Profile button moved to bottom-right
- New Custom Wisp button (opens custom whisper settings)
- Bonus Coin checkbox renamed from "Keystone"
- Popup buttons themed to match addon UI
- Whisper button preview tooltip (shows message before sending)

### Localization
- Full Italian localization (1000+ strings)
- English base localization updated
- All option names, descriptions, tooltips, buttons, messages translated
- No more raw key names in UI

### Bug Fixes
- Fixed popup queue getting stuck after first item
- Fixed CreateLFGPopup missing isMythic parameter
- Fixed Dashboard nil dereference on netStats
- Fixed LFM UpdateMessagePreview clearing message on role toggle
- Fixed Network _FlushQueue not using AddonMessage API
- Fixed Community PostEvent silent drop
- Fixed Compat.lua typo CLASSIC_335 → wotlk335
- Fixed Core.lua /fsdebug nil deref on Network
- Fixed LFG.lua ClearAllSearches stale reference
- Fixed channel blacklist select() indices
- Fixed LFM string.find plain=true (malformed pattern crash)
- Fixed LFM StartAutoSpam multiple ticker creation
- Fixed SetItemRef not forwarding chatFrame argument
- Fixed keystone stale currentKeystone value
- Fixed nil checks in Presence, Profile, VoiceBridge, Community, Dashboard
- Fixed OnEnter nil check in Core.lua
- Fixed theme typo "ShadowS" → "Shadow"
- Fixed ConsoleExec("reloadui") fallback (doesn't work, use ReloadUI)
- Fixed Profile.lua SetColorTexture called with table instead of unpacked values
- Fixed Options.lua SetPoint 2-arg invalid form
- Fixed Theme.lua dead code
- Fixed Network.lua tostring() for sentId
- Fixed Community.lua gsub pattern escaping for language tags

### Network
- FSK and FSK-EVT channels now join 10 seconds after login (so they get higher channel numbers)

---

## ⌨️ Slash Commands

| Command | Description |
|---------|-------------|
| `/fs` | Open main window |
| `/fslfg` | Open LFG tab |
| `/fslfm` | Open LFM tab |
| `/fsnet` | FrostNet network status |
| `/fsoptions` | Open settings |
| `/fsetup` | Repeat setup wizard |
| `/fsdebug` | Debug info |
| `/fsdumplog` | Dump log |
| `/fsclass` | Class management (Ascension) |
| `/fsreset confirm` | Full reset |
| `/fscf` or `/fschatfilter` | Chat filter management |
| `/fscf status` | Show filter status |
| `/fscf log [n]` | Show last N filtered messages |
| `/fscf reregister` | Force re-register filter |
| `/fskeytest <msg>` | Test keystone parser |
| `/fschatsniff` | Chat event sniffer (debug) |

---

## 📖 Documentation

- **Italian guide:** `Guide/Guida ITA.md`
- **English guide:** `Guide/Guide ENG.md`

---

## 🔧 Technical Details

- **Saved Variables:** `FrostSeekDB`
- **Supported clients:** Vanilla Classic, TBC Classic, WotLK (3.3.5),WorLK Classic, Cata Classic, Mists Classic, Ascension Private Server
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

**FrostSeek v2.2.5** — Find groups faster. Find members smarter.
