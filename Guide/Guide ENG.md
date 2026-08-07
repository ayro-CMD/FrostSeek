FrostSeek — Idiot-Proof Guide (English)
Welcome to FrostSeek, the addon that helps you find a group (LFG) and find members (LFM) in World of Warcraft.
This guide is written for people who have never used an addon before. Read one section at a time and you'll be fine.
---
1) Installation (1 minute)
Close WoW
Extract the `FrostSeek` folder into:
WoW Ascension → `Interface\AddOns\`
WoW 3.3.5 / Private → `Interface\AddOns\`
The final structure must be:
```
   Interface\AddOns\FrostSeek\FrostSeek.toc
   Interface\AddOns\FrostSeek\Core.lua
   Interface\AddOns\FrostSeek\loader.xml
   Interface\AddOns\FrostSeek\Modules\...
   ```
Open WoW. On login you'll see in chat:
`FrostSeek v2.2.4 loaded!`
Done. If you don't see the message, check that the addon is enabled on the Character screen → AddOns button (bottom left) → tick FrostSeek.
---
2) How to open it
You have 3 ways:
Minimap button (the colored icon top-left of the minimap) → Left-click
Chat command → type `/fs` and press Enter
Dedicated slash commands:
`/fslfg` → opens the LFG tab
`/fslfm` → opens the LFM tab
`/fsnet` → FrostNet network status
`/fsoptions` → opens settings
`/fsdebug` → debug info (useful if something is wrong)
---
3) The 6 tabs on top
When you open FrostSeek you see 6 buttons on top. Here's what they do:
Tab     What it does
Dashboard       General overview: your iLvl, FrostNet online count, session stats
FrostNet        The heart of the addon. Browse open groups, create your own group, see applicants
LFG     "Looking For Group" — alerts you with a popup when someone in chat is looking for members
LFM     "Looking For Members" — when YOU need members and want to spam your message
Community       Guilds and community: event board, recruitment
Options All settings
---
4) LFG Tab — Finding a group (lazy mode)
Here FrostSeek listens to chat and alerts you with a popup when someone is looking for members.
How to use it
Open the LFG tab
Choose your Role (Tank / Healer / DPS / Support) from the top menu
Choose which categories you care about with the buttons on top:
All — everything
Dungeon — dungeons
Raid — raids
WBoss — World Bosses
PvP — arena/BG
Mana — Manastorm
Key — Mythic+ / Keystone
Wait. When someone writes "lfm tank icc" in chat, a popup appears at your configured anchor position
On the popup click:
Whisper → whisper the person to get invited
Invite → invite them (if you're the leader)
Mute → silence that player for 30 minutes
Mute Boss → (only on World Boss popups) silences that specific boss until you re-enable it in Options → Activity Filter. Perfect for weekly-lockout bosses you've already cleared.
Raid target icons in messages
If a player writes `{star}`, `{square}`, `{circle}`, `{diamond}`, `{triangle}`, `{moon}`, `{cross}`, `{skull}` in their message (or any case variant like `{STAR}`), FrostSeek now renders the actual raid target icon texture in the popup, recruiters list, and tooltip — exactly like the game chat does.
Colored dungeon names
In the recruiters list, dungeon/raid/boss names are now color-coded by category and rendered in a smaller, more compact font:
🟢 Green = Dungeon
🟠 Orange = Raid
🔴 Red = World Boss / PvP
🟣 Purple = Manastorm
🌸 Pink = Keystone
Canonical names (no more abbreviations)
Even if a player writes only an abbreviation like "zg", "mc", "bwl", "kara", "naxx", "kaldros", "atal azul" (typo), the popup and recruiters list always display the full canonical name: "Zul'Gurub", "Molten Core", "Blackwing Lair", "Karazhan", "Naxxramas", "Kaldros Depthbreaker", "Atal'Zul".
Smarter spam filter
The spam filter no longer kills legitimate LFM messages that happen to contain a single spam word (e.g. "staff" inside "Int Staff"). Strong LFM/LFG indicators (lfm, lfg, need tank/heal/dps, 24/25, etc.) make the filter more permissive, while real boost/carry/guild-recruitment spam is still blocked.
PvP sub-categories
PvP messages are now sub-categorized:
- Arena 2v2 / 3v3 / 5v5 (detected from "2s", "3s", "5v5", etc.)
- Generic Arena
- Warsong Gulch, Arathi Basin, Alterac Valley, Eye of the Storm, Wintergrasp
- Generic Battleground
Ranked arena messages (containing "ranked", "yolo", "rating", "cr") display a red [Ranked] tag in the popup.
RDF no longer flagged as Mythic
"RDF" and "RDF hc" are now correctly classified as Random Dungeon Finder with Normal/Heroic difficulty — no longer mislabeled as Mythic.
Useful filters (in Options → LFG)
Filter Words — banned words (e.g. "wts", "boost", "gold") — messages with these words won't trigger popups
Popup Duration — how long the popup stays visible (in seconds)
Popup Cooldown — seconds between two identical popups
Max Popups — how many popups at the same time (max 4)
No Alerts in Combat — no popups while in combat
No Alerts in Group — no popups if you're already in a group
Activity Filter (Options → Activity Filter) — granular per-dungeon and per-boss checkboxes. Uncheck bosses/dungeons you don't care about. Weekly-lockout world bosses you've already cleared can be unchecked individually.
---
5) LFM Tab — Spamming your announcement
Here YOU have a group and need members.
Step by step
Open the LFM tab
Choose the category (Raid / Dungeon / Key / Manastorm / PvP)
Choose the specific activity (e.g. "Icecrown Citadel")
Choose the difficulty (Normal / Heroic / Mythic / Ascended / Trial 1-10 for raids)
Write your message in the box below. You can use variables like:
`{role}` — what you need
`{class}` — your class
`{ilvl}` — your item level
Example: `LFM ICC 10 hc need {role} {class} {ilvl} ilvl`
Below you'll find the spam channels: 10 buttons (1-10). Each one corresponds to a WoW channel slot.
To see which channels you have active: chat → `/chatlist` or look at the list top-right of chat
Standard channels are: 1 = General, 2 = Trade, 3 = LocalDefense, 4 = LookingForGroup, 5 = GuildRecruitment
Click the buttons to activate them (they turn green)
Set the timer (e.g. 30 seconds) and press Start Spam
FrostSeek will send your message on the selected channels every 30 seconds. To stop: Stop Spam
Auto-Invite (optional)
Toggle ON/OFF
Set Min iLvl (e.g. 200)
When someone whispers you a number ≥ 200, they get auto-invited
> **Warning**: auto-spam is convenient but don't abuse it. GMs can ban you for excessive spam. 30 seconds is a good compromise.
---
6) FrostNet Tab — The heart of the addon
FrostNet is a network between all players who have FrostSeek. Here you see real groups, not chat messages.
Sub-tabs
Browse — browse open groups created by other FrostSeek players
Create Group — create your own group and publish it on FrostNet
My Group — manage the group you created
Applications — see who applied to join your group
Top filters (Browse)
All — Dungeons — Raids — Keys — Events — Manastorm — Quests
> **New**: the **Quests** category has been added for those looking for group quest, daily, weekly, chain quest companions, etc.
Creating a group
Go to Create Group
Choose:
Type (Dungeon, Raid, World Boss, Key, Event, PvP, Manastorm, Quest)
Expansion (Classic, TBC, WotLK, Cata, MoP, Custom)
Activity (e.g. "Icecrown Citadel")
Difficulty (Normal, Heroic, Mythic, etc.)
If it's a Key: also set the Key Level
Roles Needed (tick Tank / Healer / DPS / Support)
Min iLvl, Max Members, Voice, Loot
Note (e.g. "link achievement")
Press Publish Group
The group appears in the Browse list of all connected FrostSeek players
Receiving applications
When someone applies to your group, a popup appears at your configured FrostNet popup anchor position
Click Accept to accept (auto-invite) or Decline to reject
See all applications in the Applications tab
Applying to a group
Pick a group from Browse
Choose your role
Press Apply
---
7) Community Tab
Community event board
Guild recruitment
You can create/edit templates for guild announcements
Useful commands
`/fsloadtemplate <name>` — load a saved template
`/fsdeltemplate <name>` — delete a template
---
8) Options Tab — All settings
Settings are divided into categories:
Category        What to do here
General Theme, UI scale, window position, minimap button, auto-open on login, language, log level
LFG System      All LFG settings (popups, filters, roles, LFG/LFM popup toggles)
Activity Filter Granular per-dungeon and per-boss checkboxes — uncheck what you don't care about
LFM System      Spam timer, auto-invite, spam channels, reset channels
Popup Categories        Choose which categories trigger popups + Show LFG Popups / Show LFM Popups checkboxes + Popup Anchor Position editor (Unlock / Reset buttons)
Custom Keywords Add custom keywords for each category
Custom Messages Customize the whispered message when you accept someone
Sound   Sounds for popup, listing, applicant
Advanced        Reset position, reset stats, clear favorites, debug mode
Popup Anchor Position (NEW)
You can decide exactly where LFG and FrostNet popups appear on screen — no chat commands needed.
How to position popups:
Go to Options → Popup Categories
Click "Unlock Popup Anchor" — a visual editor opens with two draggable demo boxes:
🔵 Blue box "LFG Popup Anchor" — positions LFG popups (chat-detected groups)
🟢 Green box "FrostNet Applicant Popup Anchor" — positions FrostNet applicant popups (when someone applies to your group)
Drag both boxes to where you want popups to appear
Click the green "Save" button at the bottom — both positions are saved and persist across sessions
Click "Reset" if you want to return to defaults (LFG top-center, FrostNet top-left)
Quick repositioning: hold Shift and drag any live popup (LFG or FrostNet) to instantly move its anchor without opening the editor.
Available themes
Change theme from Options → General → Select Theme. After changing theme you need `/reload` (it'll ask you).
---
9) Minimap Button — The icon on the minimap
Left-click → opens/closes FrostSeek on the LFG tab
Ctrl + Left-click → quick disable of LFG + Popups (button turns red). Repeat to re-enable. FrostNet and LFM stay active.
Drag → move the button around the minimap
The icon changes color based on detected activity:
🟢 Green → Dungeon
🟠 Orange → Raid
🟡 Yellow → World Boss
🔴 Red → PvP
🟣 Purple → Manastorm
🌸 Pink → Keystone
🔵 Azure → Quest
If there's activity, it blinks. If all is calm, it stays neutral.
---
10) Common problems — Troubleshooting
"I don't see any groups on FrostNet"
Type `/fsnet` in chat — check that Connected = true
If Connected = false, leave and rejoin any chat channel to force sync
Verify that `Options → General → Enable FrostNet` is ticked
`/reload` and try again
"LFG popups aren't appearing"
Verify that Options → LFG → Disable Popups is OFF
Verify that Popup Categories has at least one category active
If you're in a group or in combat, popups are suppressed (see options)
`/reload`
"Spam won't start"
Verify you wrote a message in the box
Verify that at least one channel is active (green) among the 10 buttons
Verify that the timer is ≥ 5 seconds
Verify you're in a valid channel (try `/1` in chat — if it doesn't answer "General", you're in no channel)
"The addon won't load"
Check on the character screen → AddOns → FrostSeek is ticked
If it says "Out of date", tick Load out of date AddOns top-right
`/fsdebug` to see module status
"I want to reset everything"
Options → Advanced → Clear All Data → confirm → `/reload`
---
11) Quick commands — Summary table
Command What it does
`/fs`   Opens/closes FrostSeek
`/fsdisable`    Quick disable LFG + Popups (same as Ctrl+Click minimap)
`/fsenable`     Re-enable LFG + Popups
`/fstoggle`     Toggle LFG + Popups on/off
`/fslfg`        Opens on LFG tab
`/fslfm`        Opens on LFM tab
`/fscommunity`  Opens on Community tab
`/fsoptions`    Opens on Options tab
`/fsnet`        FrostNet network status
`/fsopen`       Opens on Dashboard tab
`/fsdebug`      Debug info
`/fsdebugtoggle`        Toggle debug mode
`/fsclass set <class>`  Force class (for Ascension)
`/fsclass reset`        Reset class
`/fsloadtemplate <name>`        Load guild template
`/fsdeltemplate <name>` Delete guild template
`/fspopup`      Opens the visual popup anchor editor (same as Options → Popup Categories → Unlock Popup Anchor). Optional sub-commands: `/fspopup reset`, `/fspopup status`.
---
12) Practical tips
To form a raid group: create the group in FrostNet (more visible) AND start LFM spam in chat (for those without the addon). The two things don't exclude each other
To avoid being banned for spam: set LFM timer to 30+ seconds and use maximum 2-3 channels at a time
---
13) Things NOT to do
❌ DO NOT activate "Mute" on every player — you won't see any popups anymore
❌ DO NOT forget your published FrostNet group — if the group is full, remove it from the My Group tab
---
14) Quick FAQ
Q: Is FrostSeek bannable?
A: No, it's an addon like any other. What's bannable is excessive spam, but that's on you.
Q: Do I need FrostNet active to use LFG/LFM?
A: No. LFG listens to chat, LFM writes to chat. FrostNet is only the network between addon users. They are 3 separate things.
Q: Will my friends without the addon see my FrostNet groups?
A: No. They need to install FrostSeek. For those without the addon, use LFM spam.
Q: Data loss after reload?
A: Everything is saved in `FrostSeekDB`. Settings and guild templates persist. FrostNet groups disappear on logout.
Q: How do I uninstall?
A: Delete the `Interface\AddOns\FrostSeek` folder. To also clean saved data: Options → Advanced → Clear All Data → reload → then delete the folder.
---
Have fun. If something doesn't work as it should, first `/fsdebug` then `/fsnet`, then ask on the official Discord.
— Ayro
---
15) What's new in v2.2.0 (READ IF YOU'VE USED FROSTSEEK BEFORE)
This version adds several new features. Don't worry: everything you already used still works the same.

🔗 Voice Bridge — Discord link in your Profile
NEW: the Discord/TeamSpeak link is now set ONCE in the Profile tab.
- Open the Profile tab in the main frame
- Find the "Voice URL (Discord/TS)" field
- Paste your Discord invite (must start with https://discord.gg/ or https://discord.com/invite/)
- Click "Save Voice Link"
- From now on, every group you publish on FrostNet will automatically have your link attached
- Click "Test Voice" to verify the link works (opens a popup with selectable URL + Copy button)
- Other users will see a "Join Voice" button when they select your group in the FrostNet → Browse tab
- On 3.3.5 the popup doesn't auto-open the browser (client limitation): it prints the link in chat for manual copy-paste
- You can still manage links from chat (for yourself or other leaders):
  - `/fsvoice set <leaderName> <URL>`
  - `/fsvoice get <leaderName>`
  - `/fsvoice remove <leaderName>`
  - `/fsvoice list`

🌐 Language
In Options → General there are two new dropdowns:
- Language: auto / enUS / itIT / esES (auto follows the WoW client language)
- Log Level: DEBUG / INFO / WARN / ERROR (controls chat verbosity)
Italian and Spanish translations are 100% complete.
When you change language, a popup "Reload Now / Later" appears — click "Reload Now" to apply the new language.

🛠️ New commands for power-users
- `/fsdumplog` — prints the last 200 internal log entries (useful when reporting a bug)
- `/fsreset confirm` — wipes EVERYTHING except your favourite LFM templates (use as last resort)

📦 Backward compatibility
- The network protocol moved from FSK1 to FSK2. Old clients (2.1.x) still see your messages and you see theirs. Nothing to do.
- On first login after upgrade, FrostSeek creates a backup of the old DB in `FrostSeekDB._backup_v1`. If something goes wrong, you can roll back manually.
---
16) What's new in v2.2.3 → v2.2.4 (READ IF YOU'VE USED FROSTSEEK BEFORE)
This version adds several new features and fixes. Don't worry: everything you already used still works the same.

🎯 Smarter LFG detection (v2.2.4)
- Fixed: legitimate LFM World Boss messages like `{square} LFM Kaldros wb instanced need dps 24/25 (1 Int Staff HR) MS>OS /w me class/spec/ilvl {square}` were being dropped by the spam filter because "staff" appeared in "Int Staff". The spam filter is now permissive when strong LFM/LFG indicators are present.
- Added: `wb`, `worldboss`, `world boss` as generic World Boss keywords so messages that just say "wb" (without naming the boss) are still categorized correctly.
- Added: a "Mute Boss" button on World Boss popups — instantly disables popups for that specific boss until you re-enable it in Options → Activity Filter. Perfect for weekly-lockout bosses.
- Fixed: the Activity Filter had a keyword collision bug — selecting only "Zul'Gurub" (Classic) didn't match messages saying "zg" because the lookup also pointed to "Zul'Gurub (Cata)". Now selecting either variant works.
- Fixed: "Atal azul" (typo for "Atal'zul") is now correctly recognized as the Atal'Zul world boss instead of falling through to Manastorm.

🏷️ Canonical dungeon names (v2.2.3)
- Popups and recruiters list now always display the full canonical name ("Zul'Gurub", "Molten Core", "Kaldros Depthbreaker", "Atal'Zul") instead of the matched keyword ("ZG", "MC", "KALDROS", "ATAL AZUL").
- Even typos and abbreviations get normalized to the correct name.
- The search box in the recruiters list now matches against both the keyword and the canonical name.

⭐ Raid target icons (v2.2.4)
- `{star}`, `{square}`, `{circle}`, `{diamond}`, `{triangle}`, `{moon}`, `{cross}`, `{skull}` (and any case variant) are now rendered as actual icon textures in popups, recruiters list, and tooltips — exactly like the game chat.
- Unknown `{placeholders}` have their braces stripped but the inner text is preserved.

🎨 Colored dungeon names (v2.2.4)
- In the recruiters list, dungeon/raid/boss names are now color-coded by category (green= Dungeon, orange= Raid, red= World Boss/PvP, purple= Manastorm, pink= Keystone) and rendered in a smaller, more compact font.

⚔️ PvP sub-categories (v2.2.4)
- PvP messages are now sub-categorized: Arena 2v2 / 3v3 / 5v5, generic Arena, Warsong Gulch, Arathi Basin, Alterac Valley, Eye of the Storm, Wintergrasp, generic Battleground.
- Ranked arena messages (containing "ranked", "yolo", "rating", "cr") display a red [Ranked] tag.

🔄 RDF no longer flagged as Mythic (v2.2.4)
- "RDF" and "RDF hc" are now correctly classified as Random Dungeon Finder with Normal/Heroic difficulty. They were previously mislabeled as Mythic when the word "mythic" appeared in the message.

📍 Popup anchor position (v2.2.3 → v2.2.4)
- You can now decide exactly where LFG and FrostNet popups appear on screen — no chat commands needed.
- Go to Options → Popup Categories → click "Unlock Popup Anchor".
- A visual editor opens with two draggable demo boxes:
  - 🔵 Blue "LFG Popup Anchor" — positions LFG popups
  - 🟢 Green "FrostNet Applicant Popup Anchor" — positions FrostNet applicant popups
- Drag both boxes where you want, then click the green "Save" button. Both positions persist across sessions.
- Click "Reset" to return to defaults.
- Quick repositioning: hold Shift and drag any live popup (LFG or FrostNet) to instantly move its anchor.
- The `/fspopup` slash command also opens the visual editor (optional — the buttons in Options are the primary way).

✅ Two separate LFG/LFM popup toggles (v2.2.2)
- The old "Popup Mode Filter" dropdown (All / LFG / LFM) has been replaced with two clean checkboxes:
  - "Show LFG Popups" — show popups for players looking for a group to join
  - "Show LFM Popups" — show popups for players forming a group and looking for members
- If you deselect both, one is automatically re-enabled (you always see at least one type).
- Your previous dropdown choice is migrated automatically.

🌐 Locale updates
- All new features are translated in en, it, de, es, fr, pt.
