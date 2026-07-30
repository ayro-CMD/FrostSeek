⚡ FrostSeek v2.2.0

Advanced LFG/LFM Manager with FrostNet — for WoW Ascension & all WoW Classic / Retail clients.

✨ Features

🔍 LFG — Looking For Group
Auto-detect recruitment messages with popup alerts, category filters (Dungeon, Raid, Keystone, PvP, World Boss, Manastorm, Event), keyword filters, cooldown system, and customizable whisper templates with role/class/ilvl/enchant/keystone support.

📢 LFM — Looking For Members
Full LFM interface with auto-spam, customizable timers, activity dropdown, real-time message preview, multi-channel support, and auto-invite by minimum ilvl.

🌐 FrostNet
Serverless P2P listing board. Browse, Create Group, Apply, Whisper leader, all from a single panel. New in v2.2.0: protocol v2 (`FSK2`) with backward compat, `C_ChatInfo.SendAddonMessage` on modern clients, heartbeat keepalives, per-sender rate limiter, voice bridge (Discord/TS).

📊 Dashboard
Real-time player stats, average ilvl, role info, FrostNet online count, and module status overview.

🔗 Voice Bridge (NEW in v2.2.0)
Set your Discord/TeamSpeak invite link once in the **Profile tab** ("Voice URL" field). The link is auto-attached to every FrostNet listing you publish. Other players see a "Join Voice" button on the Browse panel that opens the URL via a StaticPopup. Persisted in `FrostSeekDB.VoiceLinks`. Slash fallback: `/fsvoice set|get|remove|list`.

🌐 Multi-language (NEW in v2.2.0)
 Italian (`itIT`) and Spanish (`esES`) full translations of all user-facing strings. Framework auto-falls back to English for any future keys. Selectable in Options → General → Language. `auto` follows the WoW client language.

⚙️ Settings
9 categories: General, LFG, Popups, Word Filter, Custom Messages, UI, Theme, Advanced, plus the new Language and Log Level dropdowns. Minimap button, position saving, UI scale, debug mode, log level (DEBUG/INFO/WARN/ERROR).

🛠️ Developer / Power-user Tools (NEW in v2.2.0)
- `/fsdumplog` — dump the last 200 log entries (network traces, errors, migration events)
- `/fsreset confirm` — wipe all settings except your LFM templates
- `FrostSeek.Logger` — 4-level logger with circular buffer
- `FrostSeek.SafeHandler` — xpcall wrapper that prevents addon-wide crashes
- Schema migrations: forward-only, snapshot backup on first upgrade

🖱️ Minimap Button Shortcuts
- Left Click → Open FrostSeek on the LFG tab
- Ctrl + Click → Quick toggle to disable LFG + Popups (button turns red). Repeat to re-enable. FrostNet and LFM stay active.
- Drag → Move the button around the minimap
- Slash equivalents: `/fsdisable`, `/fsenable`, `/fstoggle`

📥 Installation

1. Download the latest Release (v2.2.0+)
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
4. Run `/fsreset confirm` as last resort — wipes settings (preserves LFM templates)

🐛 Reporting bugs

When reporting a bug, include:
- `/fsdebug` output
- `/fsdumplog` output (or the last ~20 lines)
- What you were doing when the bug happened
- WoW client version + server type (Ascension / Retail / etc.)
