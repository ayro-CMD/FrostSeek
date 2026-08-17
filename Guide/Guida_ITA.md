# FrostSeek — Guida per Stupidi (Italiano)

Benvenuto in **FrostSeek**, l'addon che ti fa trovare gruppo (LFG) e trovare membri (LFM) su World of Warcraft — Ascension, 3.3.5 e server classici.

Questa guida è scritta per chi non ha mai usato un addon in vita sua. Leggi una sezione alla volta e andrà tutto bene.

---

## 1) Installazione (1 minuto)

1. Chiudi WoW
2. Estrai la cartella `FrostSeek` dentro:
   - WoW Ascension → `Interface\AddOns\`
   - WoW 3.3.5 / Private → `Interface\AddOns\`
3. La struttura finale deve essere:
   ```
   Interface\AddOns\FrostSeek\FrostSeek.toc
   Interface\AddOns\FrostSeek\Core.lua
   Interface\AddOns\FrostSeek\loader.xml
   Interface\AddOns\FrostSeek\Modules\...
   ```
4. Apri WoW. Al login vedrai in chat:
   `FrostSeek v2.3 loaded!`

Fatto. Se non vedi il messaggio, controlla che l'addon sia attivo nella schermata dei Personaggi → pulsante **AddOns** (in basso a sinistra) → spunta FrostSeek.

---

## 2) Prima apertura — il Setup Wizard

La prima volta che apri FrostSeek (o se digiti `/fsetup`), appare una procedura guidata di 4 pagine. Serve a configurare le cose base in 30 secondi:

### Pagina 1 — Lingua
Scegli la lingua dell'addon:
- **Auto** → segue la lingua del client WoW
- **Italiano** → forza italiano
- **English, Deutsch, Español, Français, Português** → altre lingue

### Pagina 2 — INFO

### Pagina 3 — Opzioni rapide
Tre interruttori ON/OFF:
- **Abilita popup LFG** → mostra popup quando qualcuno cerca membri (consigliato OFF all'inizio, troppi popup)
- **Abilita suoni** → riproduce suoni quando arriva un popup o una candidatura
- **Abilita filtro chat LFG/LFM** → **nasconde i messaggi LFG/LFM dai canali normali** (Trade, General, Yell). I messaggi nel canale dell'addon (FSK) restano visibili. Utile se la chat è piena di spam LFG.

### Pagina 4 — Conferma
Clicca **Termina**. L'addon ricarica la UI e sei pronto.

---

## 3) Come si apre

Hai 3 modi:

1. **Pulsante sulla minimap** (l'icona colorata in alto a sinistra della minimap) → Click sinistro
2. **Comando chat** → scrivi `/fs` e premi Invio
3. **Slash dedicati:**
   - `/fslfg` → apre il tab LFG
   - `/fslfm` → apre il tab LFM
   - `/fsnet` → stato della rete FrostNet
   - `/fsoptions` → apre le impostazioni
   - `/fsetup` → ripete il setup wizard
   - `/fsdebug` → info di debug (utile se qualcosa non va)

---

## 4) Le 6 schede in alto (i "Tab")

Quando apri FrostSeek vedi 6 pulsanti in alto. Ecco a cosa servono:

| Tab | Cosa fa |
|-----|---------|
| **Dashboard** | Panoramica generale: il tuo iLvl, online su FrostNet, statistiche di sessione |
| **FrostNet** | Il cuore dell'addon. Sfogli i gruppi aperti, crei il tuo gruppo, vedi chi si è candidato |
| **LFG** | "Looking For Group" — ti avvisa con popup quando qualcuno cerca membri in chat |
| **LFM** | "Looking For Members" — quando SEI TU che cerchi membri e vuoi spammare il tuo annuncio |
| **Community** | Gilde e community: bacheca eventi, reclutamento |
| **Options** | Tutte le impostazioni |

---

## 5) Tab LFG — Trovare un gruppo (modalità pascolatore)

Qui FrostSeek ascolta la chat e ti avvisa con un popup quando qualcuno cerca membri.

### Come usarlo

1. Apri il tab **LFG**
2. Scegli il tuo **Ruolo** (Tank / Healer / DPS / Support) dal menu in alto
3. Scegli quali categorie ti interessano con i pulsanti in alto:
   - **All** — tutto
   - **Dungeon** — spedizioni
   - **Raid** — incursioni
   - **World Boss** — boss del mondo
   - **PvP** — arena/battleground
   - **Manastorm** — attività Manastorm (solo Ascension)
   - **Keystone** — keystone mythic+

### Filtri difficoltà

Sotto la barra di ricerca vedi dei pulsanti di difficoltà che cambiano in base alla categoria:
- **Dungeon** → Normal, Heroic, HC, Mythic
- **Raid** → Ascended, Trial, Farm
- **Manastorm** → Leveling, Bonzo, ALVA
- **Keystone** → (nessuna difficoltà, ma vedi il filtro livello — vedi sotto)

Clicca una difficoltà per filtrare solo quei gruppi. Clicca di nuovo per toglierla.

### Filtro livello minimo Keystone (NOVITÀ)

Quando selezioni la categoria **Keystone**, appare un campo **"Min Key:"** dopo i filtri difficoltà.

- Scrivi un numero (es. `8`)
- FrostSeek mostrerà **solo le keystone di livello 8 o superiore** nei popup e nella lista reclutatori
- `0` = filtro disattivato (mostra tutte)
- Le key sotto il livello minimo vengono nascoste immediatamente dopo un (/reload) oppure pulisci (il bottone in basso a sinistra)

### Bottoni in basso

| Bottone | Cosa fa |
|---------|---------|
| **Refresh** | Aggiorna la lista reclutatori |
| **Clear All** | Pulisce tutte le ricerche attive |
| **Custom Wisp** | Apre le impostazioni per personalizzare il messaggio whisper |
| **Profile** | Apre il tuo profilo FrostNet |

**Suggerimento:** passa il mouse sul bottone verde **Whisper** (nei popup o nella lista) per vedere un **preview del messaggio** che verrà inviato. Mostra il messaggio base o quello custom se l'hai attivato.

### I popup

Quando qualcuno cerca membri, appare un popup in alto con:
- Nome del player
- Messaggio
- Categoria (con colore)
- 3 bottoni: **Whisper** (verde), **Mute** (giallo), **Close** (grigio)

Clicca **Whisper** per candidarti. Il messaggio viene generato automaticamente con il tuo ruolo, classe, iLvl.

---

## 6) Tab LFM — Cercare membri (modalità spam)

Quando HAI TU un gruppo e cerchi membri.

### Come usarlo

1. Apri il tab **LFM**
2. Scegli la categoria (Raid, Dungeon, Keystone, ecc.)
3. Seleziona i ruoli che ti servono (Tank, Healer, DPS, Support) e **quanti** ne vuoi (click sinistro per aumentare, destro per diminuire)
4. Seleziona la **difficoltà** dal menu a tendina
5. Se è una keystone, flagga **Bonus Coin** se la tua key ha bonus coin
6. Scrivi il messaggio nella casella in basso (o usa il template automatico)
7. Scegli i **canali** dove spammare (flagga i Ch# che vuoi usare)
8. Clicca **Start Spam** per iniziare lo spam automatico, oppure **Send All** per un singolo invio

### Auto-Spam

- Imposta il **timer** (es. 30 secondi tra un messaggio e l'altro)
- Clicca **Start Spam** → il messaggio viene inviato automaticamente ogni X secondi
- Clicca **Stop Spam** per fermare
- **Auto-Stop:** puoi impostare di fermare automaticamente quando il gruppo raggiunge un certo numero di membri

### Auto-Invite

Se attivi **Auto-Invite on Whisper**:
- Quando qualcuno ti sussurra con il suo iLvl
- Se l'iLvl è sopra il minimo che hai impostato
- FrostSeek lo invita automaticamente nel gruppo

---

## 7) Tab FrostNet — Il network dell'addon

FrostNet è il canale privato dell'addon. Qui vedi i gruppi pubblicati da altri utenti di FrostSeek.

### Cosa puoi fare

- **Browse** → sfoglia i gruppi aperti
- **Create Group** → crea il tuo gruppo e pubblicalo su FrostNet
- **My Group** → gestisci il tuo gruppo attivo
- **Applications** → vedi chi si è candidato al tuo gruppo

### Vantaggi rispetto al LFG normale

- Non dipende dalla chat del server
- Vedi subito i dettagli completi (leader, membri, iLvl, voice link)
- Puoi candidarti con un click
- Il leader vede la tua candidatura e può accettarti

---

## 8) Tab Community — Gilde ed eventi

- **Guild Browser** → sfoglia le gilde che reclutano
- **Recruitment** → crea il tuo messaggio di reclutamento gilda
- **Event Board** → bacheca eventi community (raid programmati, eventi PvP, ecc.)

---

## 9) Tab Options — Tutte le impostazioni

### General
- **Lingua** → cambia lingua
- **Tema** → scegli il colore dell'interfaccia (Frost, Shadow, Void, ecc.)
- **Scala UI** → ingrandisci/riduci l'interfaccia
- **Profilo server** → auto-rileva o forzato (Ascension, WotLK, Cata, ecc.)

### LFG
- **Disabilita LFG** → spegne tutto il sistema LFG
- **Notifiche silenziose** → niente suoni
- **Nessun avviso in gruppo** → niente popup se sei già in gruppo
- **Nessun avviso in combattimento** → niente popup in combat
- **Durata popup** → quanto resta visibile il popup (secondi)
- **Cooldown popup** → tempo tra popup identici
- **Popup massimi** → quanti popup contemporanei
- **Popup LFG ON/OFF** → mostra/nascondi popup LFG (default: OFF)
- **Popup LFM ON/OFF** → mostra/nascondi popup LFM (default: ON)

### Filtro Keystone (NOVITÀ)
- **Livello minimo keystone** → slider da 0 a 30. Mostra solo keystone di questo livello o superiore

### Filtro Chat (NOVITÀ)
- **Nascondi LFG/LFM in Chat** → nascondi messaggi LFG/LFM dai canali normali (Trade, General, Yell, Guild). I canali dell'addon (FSK, FSK-EVT) sono sempre esclusi.
- **Keyword filtro** → lista di parole chiave separate da virgola che attivano il filtro. Predefinite: `lfg, lfm, lf, lfg+, looking for group, looking for member, looking for raid, looking for, inv, invite, keystone, wts, wtb, boost, carry`

### Activity Filter
Scegli quali categorie di attività mostrare nei popup (Dungeon, Raid, World Boss, PvP, Manastorm, Keystone)

### Filtro Popup
Scegli quali categorie attivano i popup

### Sounds
- **Abilita suoni** → master switch
- **Suono nuovo annuncio** → quando arriva un nuovo LFG
- **Suono candidatura** → quando ricevi una candidatura
- **Suono popup** → quando appare un popup

### Advanced
- **Resetta posizione** → ripristina la finestra al centro
- **Resetta statistiche** → azzera i contatori di sessione
- **Pulisci preferiti** → rimuove tutti i giocatori preferiti
- **Pulisci tutti i dati** → reset completo (attenzione!)

---

## 10) Filtro Chat — Come funziona (NOVITÀ)

Il filtro chat nasconde i messaggi LFG/LFM dai canali normali per ridurre lo spam.

### Come attivarlo

1. Vai in **Options → LFG → Filtro Chat**
2. Spunta **"Nascondi LFG/LFM in Chat"**
3. (Opzionale) Personalizza le keyword nel campo **"Keyword filtro"**

### Cosa viene nascosto

Il filtro nasconde i messaggi che contengono:
- `lfg`, `lfm`, `lfr`
- `lf1m`, `lf2m`, `lf3m`, `lf4m`, `lf5m` (varianti con numeri)
- `lf1`, `lf2`, `lf3` (varianti brevi)
- `looking for group`, `looking for member`, `looking for raid`
- `keystone`
- `lf` + una role (`dps`, `tank`, `heal`, `healer`, `support`) — così "lf" da solo non nasconde "half", "self", "life"
- Le keyword personalizzate che hai impostato

### Cosa NON viene nascosto

- I canali dell'addon (**FSK, FSK-EVT**) sono **sempre esclusi** dal filtro
- I messaggi whisper, guild (se non attivi il filtro guild), say, yell (se non attivi il filtro yell)

### Comandi di debug

- `/fscf status` → mostra lo stato del filtro
- `/fscf log` → mostra gli ultimi 10 messaggi filtrati
- `/fscf log 20` → mostra gli ultimi 20
- `/fscf reregister` → forza re-registrazione del filtro
- `/fschatsniff` → sniffer eventi chat (per debug avanzato)

---

## 11) Comandi slash completi

| Comando | Cosa fa |
|---------|---------|
| `/fs` | Apre la finestra principale |
| `/fslfg` | Apre il tab LFG |
| `/fslfm` | Apre il tab LFM |
| `/fsnet` | Stato rete FrostNet |
| `/fsoptions` | Apre le impostazioni |
| `/fsetup` | Ripete il setup wizard |
| `/fsdebug` | Info debug |
| `/fsdumplog` | Dump log |
| `/fsclass` | Gestione classe (Ascension) |
| `/fsreset confirm` | Reset completo |
| `/fschatfilter` o `/fscf` | Gestione filtro chat |
| `/fskeytest <msg>` | Test parser keystone |
| `/fschatsniff` | Sniffer eventi chat |

---

## 12) Consigli pratici

### Se hai troppi popup
- Vai in Options → LFG → spunta "Nessun avviso in gruppo" e "Nessun avviso in combattimento"
- Aumenta il "Cooldown popup" a 600 secondi
- Disattiva "Popup LFG" (lascia solo LFM)
- Usa l'Activity Filter per nascondere categorie che non ti interessano

### Se non vedi abbastanza gruppi
- Assicurati che FrostNet sia connesso (Dashboard → pallino verde)
- Esegui `/fsnet` per vedere lo stato del canale
- Disattiva il filtro chat se attivo

### Se la chat è troppo piena di spam LFG
- Attiva il filtro chat: Options → LFG → Filtro Chat → "Nascondi LFG/LFM in Chat"
- I messaggi LFG/LFM spariranno dai canali normali ma restano nel canale FSK

### Se cerchi keystone alte
- Vai nel tab LFG → categoria Keystone
- Imposta "Min Key: 10" (o il livello che vuoi)
- Vedrai solo le key di livello 10+

---

## 13) Problemi comuni

### "Non vedo il pulsante sulla minimap"
- Options → General → "Mostra pulsante minimap" ON
- Oppure usa `/fs` per aprire

### "I popup non appaiono"
- Options → LFG → "Disabilita LFG" deve essere OFF
- Options → LFG → "Popup LFG" o "Popup LFM" devono essere ON
- Verifica di essere nella categoria giusta

### "FrostNet non si connette"
- Esegui `/fsnet` per vedere lo stato
- Il canale FSK viene joinato automaticamente 10 secondi dopo il login
- Se non si connette, prova `/reload`

### "Il filtro chat non funziona"
- Verifica che sia attivo: `/fscf status`
- Verifica che `chatFilterEnabled: true`
- Esegui `/fscf reregister` per re-registrare
- Esegui `/fscf log` per vedere se i messaggi vengono filtrati

### "Il filtro keystone non funziona"
- Verifica il valore: `/fskeytest LF TANK [Keystone: Maraudon (6)]`
- Dovresti vedere `ksLevel: 6` e `keystoneMinLevel: <il tuo valore>`
- Se `ksLevel: nil`, il parser non estrae il livello — manda il messaggio reale all'autore

---

## 14) Versione

FrostSeek v2.3 — Copyright © 2026 Ayro. Tutti i diritti riservati.

Per supporto, contatta l'autore tramite il repository ufficiale CurseForge (Project ID: 1460315).
