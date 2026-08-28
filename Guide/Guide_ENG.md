# FrostSeek — Total Beginner's Guide

FrostSeek helps you **find a group** (LFG) and **find members** for your own group (LFM) in World of Warcraft.

This guide is written for people who have never installed an addon in their life. Follow the steps in order, one at a time, and you'll be fine.

---

## Step 1 — Download the ZIP file

1. Download FrostSeek: you will get a **ZIP** file (a "compressed" folder).
2. Save it somewhere easy to find, for example your **Desktop**.

You don't need any special program: Windows can do everything by itself.

---

## Step 2 — Extract the ZIP

1. **Right-click** the ZIP file → **Extract All...**
2. Windows asks where to extract: Desktop is fine.
3. When it's done, you will have a **folder** called **FrostSeek**.

> ✓ **Check:** open this folder. Inside you must see files like `FrostSeek.toc`, `Core.lua`, `loader.xml` and other folders (`Modules`, `Media`, `Guide`, `Locales`).

---

## Step 3 — Find the game's AddOns folder

The "AddOns" folder is inside the folder where WoW is installed:

```
<game folder>\Interface\AddOns\
```

How to find it if you don't know where it is:

1. **Right-click** the icon you use to open WoW → **Open file location**.
2. From the folder that opens, go into **Interface** → **AddOns**.
3. If the **AddOns** folder doesn't exist: go into `Interface` and create it yourself (right-click → New → Folder → name it exactly `AddOns`).

> 💡 Do you have more than one game/client installed (for example Ascension AND a 3.3.5 client)? Each one has its **own** AddOns folder. Put FrostSeek in the one you actually play.

---

## Step 4 — Put the FrostSeek folder inside AddOns

1. Copy the **FrostSeek** folder (the one extracted in Step 2).
2. Paste it inside `Interface\AddOns\`.

### ⚠️ GOLDEN RULE — The folder must be named EXACTLY `FrostSeek`

Correct name:

```
Interface\AddOns\FrostSeek\
```

Wrong names (with these names the addon will NOT show up in the game):

```
Interface\AddOns\FrostSeek-main\      ← with "-main" or similar endings
Interface\AddOns\FrostSeek(1)\        ← duplicate created by Windows
Interface\AddOns\frostseek addon\     ← made-up name
```

If the folder has a wrong name: right-click it → **Rename** → type `FrostSeek`.

### ⚠️ Watch out for the "double folder"

WRONG (folder inside folder):

```
Interface\AddOns\FrostSeek\FrostSeek\FrostSeek.toc    ← NO!
```

CORRECT (the .toc file must sit DIRECTLY inside FrostSeek):

```
Interface\AddOns\FrostSeek\FrostSeek.toc              ← YES!
```

### ✓ Check before moving on

Open `Interface\AddOns\FrostSeek\` and make sure the **FrostSeek.toc** file is there.

- If it is → perfect, go to Step 5.
- If instead you only see another FrostSeek folder → you are in the double folder: go inside it, **cut** all of its content, **paste** it into the outer FrostSeek, then delete the now-empty inner folder.

---

## Step 5 — If you already had FrostSeek (updating)

If you already had a previous copy of FrostSeek:

1. **Close WoW.**
2. **Delete** the old `Interface\AddOns\FrostSeek` folder (right-click → Delete).
3. Paste the new folder in.
4. Open WoW again.

> ⚠️ Don't paste on top of the old one: delete first, then paste. That way you're sure no old files are left behind causing problems.

If this is your first install, skip this step.

---

## Step 6 — Enable the addon in game

1. Start WoW and get to the **character selection screen**.
2. **Bottom left** you'll find the **AddOns** button → click it.
3. **FrostSeek** must be in the list → make sure it is **ticked**.
4. If you see **"Load out of date AddOns"** at the top → **tick it**. On private servers it's almost always needed.
5. Close the popup and **enter the world** with your character.

> ❓ **FrostSeek is not in the list?** The game can't see the folder. Go back to Step 4 and double-check the folder name and the position of the `FrostSeek.toc` file (it must be at `Interface\AddOns\FrostSeek\FrostSeek.toc`).

---

## Step 7 — First open

When you enter the world:

- In chat (bottom left) you'll see **`FrostSeek loaded!`** → all good.
- The **first time** you open FrostSeek, a **4-page wizard** starts:
  1. **Language** → choose *English* (or *Auto* to follow the game's language)
  2. **INFO**
  3. **Quick options** → popups, sounds, chat filter (you can leave everything as-is and change it later)
  4. **Done** → click *Finish*

You're all set! 🎉

---

## How to open FrostSeek

You have two ways, both work:

1. **Minimap button** — the colored icon around the minimap, **left-click** it.
2. **Chat command** — type `/fs` and press Enter.

---

## What's inside — the 6 tabs

At the top of the FrostSeek window you'll see 6 tabs:

| Tab | What it's for |
|-----|---------------|
| **Dashboard** | Overview: your ilvl, how many users are online on FrostNet, session stats |
| **FrostNet** | The group board: browse open groups, create yours, see who applied |
| **LFG** | "Looking for group": pops up an alert when someone is looking for members |
| **LFM** | "Looking for members": when YOU have a group and need people |
| **Community** | Recruiting guilds and event board |
| **Options** | All the settings: language, theme, sounds, filters, popups... |

---

## The 3 things you'll do most often

### 🔍 I want to FIND a group → LFG tab

1. Open the **LFG** tab.
2. Choose your **role** (Tank / Healer / DPS / Support).
3. Choose what you care about (Dungeon, Raid, Keystone, PvP...).
4. Wait: when someone looks for members, a **popup** appears with name, message and a **Whisper** button.
5. Click **Whisper** → the message writes itself, with your role, class and ilvl.

### 📢 I HAVE a group and need people → LFM tab

1. Open the **LFM** tab.
2. Pick the activity and the roles you need (and how many of each).
3. Keep the automatic message or write your own; pick the channels.
4. Click **Start Spam**: the message goes out automatically every X seconds. **Stop Spam** to stop it.

### 🌐 I want to see ALL groups → FrostNet tab

1. Open the **FrostNet** tab.
2. Browse the groups published by other FrostSeek users.
3. Click **Apply** to apply, or create your own group with **Create Group**.

> 💡 FrostNet connects by itself: you don't have to do anything. If you want to check that it's connected, type `/fsnet` in chat.

---

## Useful commands (type them in chat and press Enter)

| Command | What it does |
|---------|--------------|
| `/fs` | Opens/closes FrostSeek |
| `/fslfg` | Opens the LFG tab directly |
| `/fslfm` | Opens the LFM tab directly |
| `/fsnet` | Tells you if FrostNet is connected |
| `/fsetup` | Repeats the initial setup wizard |

---

## If something goes wrong

### "FrostSeek loaded! doesn't appear in chat!"
- The addon isn't loaded: either it's not ticked in the AddOns list (Step 6), or the folder has the wrong name/position (Step 4).

### "FrostSeek is not in the AddOns list"
- The game can't find the `.toc` file: it's almost always the double folder or a wrong name. Check again that `Interface\AddOns\FrostSeek\FrostSeek.toc` exists.

### "I updated and now everything is weird"
- Do a clean install: close WoW → delete `Interface\AddOns\FrostSeek` → paste the new folder in → restart WoW.

### "I don't see the minimap button"
- Type `/fs` in chat: the window opens all the same. (You can re-enable the button in Options → General.)

### "FrostNet won't connect"
- Type `/fsnet` to see the status. Try `/reload` (reloads the interface without closing the game).

---

## Summary in 4 lines

1. Download the ZIP → extract → you get the **FrostSeek** folder
2. Put it in `Interface\AddOns\` → it must be named **exactly FrostSeek** (no double folders!)
3. Character screen → **AddOns** button → tick FrostSeek
4. Enter the world → type **`/fs`** → play!

---

FrostSeek — Copyright © 2026 Ayro. All rights reserved.
For support, contact the author through the official repository (CurseForge Project ID: 1460315).
