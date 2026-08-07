⚡ FrostSeek v2.2.4

Advanced LFG/LFM Manager with FrostNet — for WoW Ascension & all WoW Classic / Retail clients.

✨ Features

🔍 LFG — Looking For Group
Auto-detect recruitment messages with popup alerts, category filters (Dungeon, Raid, Keystone, PvP, World Boss, Manastorm, Event), keyword filters, cooldown system, and customizable whisper templates with role/class/ilvl/enchant/keystone support.

New in v2.2.x:
- ⭐ **Raid target icons** — `{star}`, `{square}`, `{circle}`, `{diamond}`, `{triangle}`, `{moon}`, `{cross}`, `{skull}` (any case) render as actual icon textures in popups, recruiters list, and tooltips — exactly like the game chat.
- 🏷️ **Canonical dungeon names** — popups and recruiters list always show the full name ("Zul'Gurub", "Molten Core", "Kaldros Depthbreaker") instead of the matched keyword ("ZG", "MC", "KALDROS"). Typos and abbreviations are normalized too.
- 🎨 **Colored dungeon names** — recruiters list names are color-coded by category (green= Dungeon, orange= Raid, red= World Boss/PvP, purple= Manastorm, pink= Keystone) in a smaller, compact font.
- 🎯 **Smarter spam filter** — legitimate LFM messages containing a single spam word (e.g. "staff" in "Int Staff") no longer get dropped when strong LFM/LFG indicators are present.
- 🐻 **Mute Boss button** — on World Boss popups, instantly disables popups for that specific boss until you re-enable it in Options → Activity Filter. Perfect for weekly-lockout bosses.
- ⚔️ **PvP sub-categories** — Arena 2v2/3v3/5v5, generic Arena, Warsong Gulch, Arathi Basin, Alterac Valley, Eye of the Storm, Wintergrasp, generic Battleground. Ranked arenas show a red [Ranked] tag.
- 🔄 **RDF no longer flagged as Mythic** — "RDF" and "RDF hc" are correctly classified as Random Dungeon Finder with Normal/Heroic difficulty.
- 🔧 **Activity Filter fix** — keyword collision bug fixed (selecting only "Zul'Gurub" Classic now matches "zg" messages even when "Zul'Gurub (Cata)" also exists).
- 🔤 **Atal'zul typo handling** — "Atal azul" and "Atal'azul" now correctly recognized as the Atal'Zul world boss instead of falling through to Manastorm.

📢 LFM — Looking For Members
Full LFM interface with auto-spam, customizable timers, activity dropdown, real-time message preview, multi-channel support, and auto-invite by minimum ilvl.

🌐 FrostNet
Serverless P2P listing board. Browse, Create Group, Apply, Whisper leader, all from a single panel. Protocol v2 (`FSK2`) with backward compat, `C_ChatInfo.SendAddonMessage` on modern clients, heartbeat keepalives, per-sender rate limiter, voice bridge (Discord/TS).

📊 Dashboard
Real-time player stats, average ilvl, role info, FrostNet online count, and module status overview.

📍 Popup Anchor Position (NEW in v2.2.4)
Decide exactly where LFG and FrostNet popups appear on screen — **no chat commands needed**.
- Go to **Options → Popup Categories → Unlock Popup Anchor**
- A visual editor opens with two draggable demo boxes:
  - 🔵 Blue "LFG Popup Anchor" — positions LFG popups
  - 🟢 Green "FrostNet Applicant Popup Anchor" — positions FrostNet applicant popups
- Drag both boxes where you want, click the green **Save** button — both positions persist across sessions
- Click **Reset** to return to defaults
- Quick repositioning: hold **Shift** and drag any live popup to instantly move its anchor
- Optional slash: `/fspopup` (also: `/fspopup reset`, `/fspopup status`)

✅ Two separate LFG/LFM popup toggles (NEW in v2.2.2)
The old "Popup Mode Filter" dropdown (All / LFG / LFM) is replaced with two clean checkboxes:
- **Show LFG Popups** — popups for players looking for a group to join
- **Show LFM Popups** — popups for players forming a group and looking for members
- If you deselect both, one is automatically re-enabled. Your previous dropdown choice is migrated automatically.

🔗 Voice Bridge (since v2.2.0)
Set your Discord/TeamSpeak invite link once in the **Profile tab** ("Voice URL" field). The link is auto-attached to every FrostNet listing you publish. Other players see a "Join Voice" button on the Browse panel that opens the URL via a StaticPopup. Persisted in `FrostSeekDB.VoiceLinks`. Slash fallback: `/fsvoice set|get|remove|list`.

🌐 Multi-language (since v2.2.0)
Italian (`itIT`), Spanish (`esES`), German (`deDE`), French (`frFR`), Portuguese (`ptBR`) translations of all user-facing strings. Framework auto-falls back to English for any future keys. Selectable in Options → General → Language. `auto` follows the WoW client language.

⚙️ Settings
9 categories: General, LFG, Activity Filter, LFM, Popup Categories (with anchor editor), Custom Keywords, Custom Messages, Sound, Advanced. Plus Language and Log Level dropdowns. Minimap button, position saving, UI scale, debug mode, log level (DEBUG/INFO/WARN/ERROR).

🛠️ Developer / Power-user Tools
- `/fsdumplog` — dump the last 200 log entries (network traces, errors, migration events)
- `/fsreset confirm` — wipe all settings except your LFM templates
- `/fspopup` — open the visual popup anchor editor (also: `/fspopup reset`, `/fspopup status`)
- `FrostSeek.Logger` — 4-level logger with circular buffer
- `FrostSeek.SafeHandler` — xpcall wrapper that prevents addon-wide crashes
- Schema migrations: forward-only, snapshot backup on first upgrade

🖱️ Minimap Button Shortcuts
- Left Click → Open FrostSeek on the LFG tab
- Ctrl + Click → Quick toggle to disable LFG + Popups (button turns red). Repeat to re-enable. FrostNet and LFM stay active.
- Drag → Move the button around the minimap
- Slash equivalents: `/fsdisable`, `/fsenable`, `/fstoggle`

📥 Installation

1. Download the latest Release (v2.2.4+)
2. Extract the `.zip` file
3. Place the `FrostSeek` folder inside `Interface/AddOns/`
4. Restart the game and enjoy

🖥️ Compatibility

- ✅ WoW Ascension (Project Ascension) — 3.3.5a, uses legacy custom channel
- ✅ 3.3.5 Vanilla Servers — same as Ascension
- ✅ Vanilla Classic, TBC Classic, WotLK Classic — uses `C_ChatInfo.SendAddonMessage` when available
- ✅ Cata Classic, Cata PS, Mists Classic
- ✅ Retail

The addon automatically detects the client and adapts. No manual configuration needed.

📜 License

All Rights Reserved — See license file for more info.

🔧 Troubleshooting

If something doesn't work:
1. Run `/fsdebug` — prints version, schema version, language, log level, module status, network state
2. Run `/fsdumplog` — prints the last 200 log entries
3. Run `/fsnet` — prints FrostNet connection status, queue length, channel ID
4. Run `/fspopup status` — prints current LFG and FrostNet popup anchor positions
5. Run `/fsreset confirm` as last resort — wipes settings (preserves LFM templates)

🐛 Reporting bugs

When reporting a bug, include:
- `/fsdebug` output
- `/fsdumplog` output (or the last ~20 lines)
- What you were doing when the bug happened
- WoW client version + server type (Ascension / Retail / etc.)

📚 Full guides

- `Guide/Guide ENG.md` — complete English walkthrough (idiot-proof)
- `Guide/Guida ITA.md` — guida italiana completa
