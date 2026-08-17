# FrostSeek — Idiot-Proof Guide (English)

Welcome to **FrostSeek**, the addon that helps you find a group (LFG) and find members (LFM) in World of Warcraft — Ascension, 3.3.5 and classic servers.

This guide is written for people who have never used an addon before. Read one section at a time and you'll be fine.

---

## 1) Installation (1 minute)

1. Close WoW
2. Extract the `FrostSeek` folder into:
   - WoW Ascension → `Interface\AddOns\`
   - WoW 3.3.5 / Private → `Interface\AddOns\`
3. The final structure must be:
   ```
   Interface\AddOns\FrostSeek\FrostSeek.toc
   Interface\AddOns\FrostSeek\Core.lua
   Interface\AddOns\FrostSeek\loader.xml
   Interface\AddOns\FrostSeek\Modules\...
   ```
4. Open WoW. On login you'll see in chat:
   `FrostSeek v2. loaded!`

Done. If you don't see the message, check that the addon is enabled on the Character screen → **AddOns** button (bottom left) → tick FrostSeek.

---

## 2) First launch — the Setup Wizard

The first time you open FrostSeek (or if you type `/fsetup`), a 4-page wizard appears. It configures the basics in 30 seconds:

### Page 1 — Language
Choose the addon language:
- **Auto** → follows the WoW client language
- **Italian** → force Italian
- **English, Deutsch, Español, Français, Português** → other languages

### Page 2 — INFO

### Page 3 — Quick options
Three ON/OFF toggles:
- **Enable LFG popups** → show popups when someone looks for members (recommended OFF at first, too many popups)
- **Enable sounds** → play sounds when a popup or application arrives
- **Enable LFG/LFM chat filter** → **hides LFG/LFM messages from normal chat channels** (Trade, General, Yell). Messages in the addon channel (FSK) remain visible. Useful if chat is full of LFG spam.

### Page 4 — Confirm
Click **Finish**. The addon reloads the UI and you're ready.

---

## 3) How to open it

You have 3 ways:

1. **Minimap button** (the colored icon top-left of the minimap) → Left-click
2. **Chat command** → type `/fs` and press Enter
3. **Dedicated slash commands:**
   - `/fslfg` → opens the LFG tab
   - `/fslfm` → opens the LFM tab
   - `/fsnet` → FrostNet network status
   - `/fsoptions` → opens settings
   - `/fsetup` → repeats the setup wizard
   - `/fsdebug` → debug info (useful if something is wrong)

---

## 4) The 6 tabs on top

When you open FrostSeek you see 6 buttons on top. Here's what they do:

| Tab | What it does |
|-----|--------------|
| **Dashboard** | General overview: your iLvl, FrostNet online count, session stats |
| **FrostNet** | The heart of the addon. Browse open groups, create your own group, see applicants |
| **LFG** | "Looking For Group" — alerts you with a popup when someone in chat is looking for members |
| **LFM** | "Looking For Members" — when YOU need members and want to spam your message |
| **Community** | Guilds and community: event board, recruitment |
| **Options** | All settings |

---

## 5) LFG Tab — Finding a group (lazy mode)

Here FrostSeek listens to chat and alerts you with a popup when someone is looking for members.

### How to use it

1. Open the **LFG** tab
2. Choose your **Role** (Tank / Healer / DPS / Support) from the top menu
3. Choose which categories you care about with the buttons on top:
   - **All** — everything
   - **Dungeon** — dungeons
   - **Raid** — raids
   - **World Boss** — world bosses
   - **PvP** — arena/battleground
   - **Manastorm** — Manastorm activities (Ascension only)
   - **Keystone** — mythic+ keystones

### Difficulty filters

Below the search bar you see difficulty buttons that change based on the category:
- **Dungeon** → Normal, Heroic, HC, Mythic
- **Raid** → Ascended, Trial, Farm
- **Manastorm** → Leveling, Bonzo, ALVA
- **Keystone** → (no difficulty, but you see the level filter — see below)

Click a difficulty to filter only those groups. Click again to remove it.

### Minimum Keystone Level Filter (NEW)

When you select the **Keystone** category, a **"Min Key:"** field appears after the difficulty filters.

- Type a number (e.g. `8`)
- FrostSeek will **only show keystones level 8 or higher** in popups and recruiters list
- `0` = filter disabled (show all)
- Keys below the minimum are hidden immediately (need /reload or clear button click)

### Bottom buttons

| Button | What it does |
|--------|--------------|
| **Refresh** | Refreshes the recruiters list |
| **Clear All** | Clears all active searches |
| **Custom Wisp** | Opens settings to customize the whisper message |
| **Profile** | Opens your FrostNet profile |

**Tip:** hover over the green **Whisper** button (in popups or in the list) to see a **preview of the message** that will be sent. Shows the base message or the custom one if enabled.

### The popups

When someone looks for members, a popup appears at the top with:
- Player name
- Message
- Category (with color)
- 3 buttons: **Whisper** (green), **Mute** (yellow), **Close** (gray)

Click **Whisper** to apply. The message is automatically generated with your role, class, iLvl.

---

## 6) LFM Tab — Finding members (spam mode)

When YOU have a group and need members.

### How to use it

1. Open the **LFM** tab
2. Choose the category (Raid, Dungeon, Keystone, etc.)
3. Select the roles you need (Tank, Healer, DPS, Support) and **how many** (left-click to increase, right-click to decrease)
4. Select the **difficulty** from the dropdown
5. If it's a keystone, tick **Bonus Coin** if your key has bonus coin
6. Write the message in the bottom box (or use the automatic template)
7. Choose the **channels** to spam on (tick the Ch# you want to use)
8. Click **Start Spam** to start auto-spam, or **Send All** for a single send

### Auto-Spam

- Set the **timer** (e.g. 30 seconds between messages)
- Click **Start Spam** → the message is sent automatically every X seconds
- Click **Stop Spam** to stop
- **Auto-Stop:** you can set it to stop automatically when the group reaches a certain member count

### Auto-Invite

If you enable **Auto-Invite on Whisper**:
- When someone whispers you with their iLvl
- If the iLvl is above the minimum you set
- FrostSeek auto-invites them to the group

---

## 7) FrostNet Tab — The addon network

FrostNet is the addon's private channel. Here you see groups published by other FrostSeek users.

### What you can do

- **Browse** → browse open groups
- **Create Group** → create your group and publish it on FrostNet
- **My Group** → manage your active group
- **Applications** → see who applied to your group

### Advantages over normal LFG

- Doesn't depend on server chat
- See full details immediately (leader, members, iLvl, voice link)
- Apply with one click
- The leader sees your application and can accept you

---

## 8) Community Tab — Guilds and events

- **Guild Browser** → browse recruiting guilds
- **Recruitment** → create your guild recruitment message
- **Event Board** → community event board (scheduled raids, PvP events, etc.)

---

## 9) Options Tab — All settings

### General
- **Language** → change language
- **Theme** → choose interface color (Frost, Shadow, Void, etc.)
- **UI Scale** → enlarge/shrink the interface
- **Server Profile** → auto-detect or forced (Ascension, WotLK, Cata, etc.)

### LFG
- **Disable LFG** → turns off the entire LFG system
- **Silent notifications** → no sounds
- **No alerts in group** → no popups if already in a group
- **No alerts in combat** → no popups in combat
- **Popup duration** → how long the popup stays visible (seconds)
- **Popup cooldown** → time between identical popups
- **Max popups** → how many popups at once
- **Popup LFG ON/OFF** → show/hide LFG popups (default: OFF)
- **Popup LFM ON/OFF** → show/hide LFM popups (default: ON)

### Keystone Filter (NEW)
- **Min keystone level** → slider 0 to 30. Only show keystones at this level or higher

### Chat Filter (NEW)
- **Hide LFG/LFM in Chat** → hide LFG/LFM messages from normal channels (Trade, General, Yell, Guild). Addon channels (FSK, FSK-EVT) are always excluded.
- **Filter keywords** → comma-separated keywords that trigger the filter. Defaults: `lfg, lfm, lf, lfg+, looking for group, looking for member, looking for raid, looking for, inv, invite, keystone, wts, wtb, boost, carry`

### Activity Filter
Choose which activity categories to show in popups (Dungeon, Raid, World Boss, PvP, Manastorm, Keystone)

### Popup Filter
Choose which categories trigger popups

### Sounds
- **Enable sounds** → master switch
- **New listing sound** → when a new LFG arrives
- **Applicant sound** → when you receive an application
- **Popup sound** → when a popup appears

### Advanced
- **Reset position** → restore window to center
- **Reset stats** → reset session counters
- **Clear favorites** → remove all favorite players
- **Clear all data** → full reset (careful!)

---

## 10) Chat Filter — How it works (NEW)

The chat filter hides LFG/LFM messages from normal channels to reduce spam.

### How to enable

1. Go to **Options → LFG → Chat Filter**
2. Tick **"Hide LFG/LFM in Chat"**
3. (Optional) Customize keywords in the **"Filter keywords"** field

### What gets hidden

The filter hides messages containing:
- `lfg`, `lfm`, `lfr`
- `lf1m`, `lf2m`, `lf3m`, `lf4m`, `lf5m` (numbered variants)
- `lf1`, `lf2`, `lf3` (short variants)
- `looking for group`, `looking for member`, `looking for raid`
- `keystone`
- `lf` + a role (`dps`, `tank`, `heal`, `healer`, `support`) — so "lf" alone doesn't hide "half", "self", "life"
- The custom keywords you set

### What does NOT get hidden

- Addon channels (**FSK, FSK-EVT**) are **always excluded** from the filter
- Whisper messages, guild (if you don't enable guild filter), say, yell (if you don't enable yell filter)

### Debug commands

- `/fscf status` → show filter status
- `/fscf log` → show last 10 filtered messages
- `/fscf log 20` → show last 20
- `/fscf reregister` → force re-register the filter
- `/fschatsniff` → chat event sniffer (advanced debug)

---

## 11) Complete slash commands

| Command | What it does |
|---------|--------------|
| `/fs` | Opens main window |
| `/fslfg` | Opens LFG tab |
| `/fslfm` | Opens LFM tab |
| `/fsnet` | FrostNet network status |
| `/fsoptions` | Opens settings |
| `/fsetup` | Repeats setup wizard |
| `/fsdebug` | Debug info |
| `/fsdumplog` | Dump log |
| `/fsclass` | Class management (Ascension) |
| `/fsreset confirm` | Full reset |
| `/fschatfilter` or `/fscf` | Chat filter management |
| `/fskeytest <msg>` | Test keystone parser |
| `/fschatsniff` | Chat event sniffer |

---

## 12) Practical tips

### If you have too many popups
- Go to Options → LFG → tick "No alerts in group" and "No alerts in combat"
- Increase "Popup cooldown" to 600 seconds
- Disable "Popup LFG" (leave only LFM)
- Use the Activity Filter to hide categories you don't care about

### If you don't see enough groups
- Make sure FrostNet is connected (Dashboard → green dot)
- Run `/fsnet` to see channel status
- Disable the chat filter if active

### If chat is too full of LFG spam
- Enable the chat filter: Options → LFG → Chat Filter → "Hide LFG/LFM in Chat"
- LFG/LFM messages will disappear from normal channels but remain in the FSK channel

### If you're looking for high keystones
- Go to LFG tab → Keystone category
- Set "Min Key: 10" (or whatever level you want)
- You'll only see keys level 10+

---

## 13) Common problems

### "I don't see the minimap button"
- Options → General → "Show minimap button" ON
- Or use `/fs` to open

### "Popups don't appear"
- Options → LFG → "Disable LFG" must be OFF
- Options → LFG → "Popup LFG" or "Popup LFM" must be ON
- Check you're in the right category

### "FrostNet doesn't connect"
- Run `/fsnet` to see status
- The FSK channel is joined automatically 10 seconds after login
- If it doesn't connect, try `/reload`

### "Chat filter doesn't work"
- Verify it's active: `/fscf status`
- Verify `chatFilterEnabled: true`
- Run `/fscf reregister` to re-register
- Run `/fscf log` to see if messages are being filtered

### "Keystone filter doesn't work"
- Verify the value: `/fskeytest LF TANK [Keystone: Maraudon (6)]`
- You should see `ksLevel: 6` and `keystoneMinLevel: <your value>`
- If `ksLevel: nil`, the parser can't extract the level — send the real message to the author

---

## 14) Version

FrostSeek v2.3.0 — Copyright © 2026 Ayro. All rights reserved.

For support, contact the author through the official CurseForge repository (Project ID: 1460315).
