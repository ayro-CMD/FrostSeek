FrostSeek — Guida per Stupidi (Italiano)
Benvenuto in FrostSeek, l'addon che ti fa trovare gruppo (LFG) e trovare membri (LFM) su World of Warcraft — Ascension, 3.3.5 e server classici.
Questa guida è scritta per chi non ha mai usato un addon in vita sua. Leggi una sezione alla volta e andrà tutto bene.
---
1) Installazione (1 minuto)
Chiudi WoW
Estrai la cartella `FrostSeek` dentro:
WoW Ascension → `Interface\AddOns\`
WoW 3.3.5 / Private → `Interface\AddOns\`
La struttura finale deve essere:
```
   Interface\AddOns\FrostSeek\FrostSeek.toc
   Interface\AddOns\FrostSeek\Core.lua
   Interface\AddOns\FrostSeek\loader.xml
   Interface\AddOns\FrostSeek\Modules\...
   ```
Apri WoW. Al login vedrai in chat:
`FrostSeek v2.1.6 loaded!`
Fatto. Se non vedi il messaggio, controlla che l'addon sia attivo nella schermata dei Personaggi → pulsante AddOns (in basso a sinistra) → spunta FrostSeek.
---
2) Come si apre
Hai 3 modi:
Pulsante sulla minimap (l'icona colorata in alto a sinistra della minimap) → Click sinistro
Comando chat → scrivi `/fs` e premi Invio
Slash dedicati:
`/fslfg` → apre il tab LFG
`/fslfm` → apre il tab LFM
`/fsnet` → stato della rete FrostNet
`/fsoptions` → apre le impostazioni
`/fsdebug` → info di debug (utile se qualcosa non va)
---
3) Le 6 schede in alto (i "Tab")
Quando apri FrostSeek vedi 6 pulsanti in alto. Ecco a cosa servono:
Tab	Cosa fa
Dashboard	Panoramica generale: il tuo iLvl, GS, online su FrostNet, statistiche di sessione
FrostNet	Il cuore dell'addon. Sfogli i gruppi aperti, crei il tuo gruppo, vedi chi si è candidato
LFG	"Looking For Group" — ti avvisa con popup quando qualcuno cerca membri in chat
LFM	"Looking For Members" — quando SEI TU che cerchi membri e vuoi spammare il tuo annuncio
Community	Gilde e community: bacheca eventi, reclutamento
Options	Tutte le impostazioni
---
4) Tab LFG — Trovare un gruppo (modalità pascolatore)
Qui FrostSeek ascolta la chat e ti avvisa con un popup quando qualcuno cerca membri.
Come usarlo
Apri il tab LFG
Scegli il tuo Ruolo (Tank / Healer / DPS / Support) dal menu in alto
Scegli quali categorie ti interessano con i pulsanti in alto:
All — tutto
Dungeon — spedizioni
Raid — incursioni
WBoss — World Boss
PvP — arena/BG
Mana — Manastorm
Key — Mythic+ / Keystone
Quando qualcuno scrive "lfm tank icc" in chat, ti appare un popup in alto
Sul popup clicca:
Whisper → mandi un sussurro al tizio per farti invitare
Invite → lo inviti tu (se sei leader)
Mute → silenzia quel player per 30 minuti
Filtri utili (in Options → LFG)
Filter Words — parole bannate (es. "wts", "boost", "gold") — i messaggi con queste parole non ti danno popup
Popup Duration — quanto resta visibile il popup (in secondi)
Popup Cooldown — secondi tra due popup identici
Max Popups — quanti popup contemporanei (max 4)
No Alerts in Combat — non ti disturbano in combattimento
No Alerts in Group — non ti disturbano se sei già in gruppo
---
5) Tab LFM — Spammare il tuo annuncio
Qui sei tu che hai un gruppo e cerchi membri.
Come usarlo passo passo
Apri il tab LFM
Scegli la categoria (Raid / Dungeon / Key / Manastorm / PvP)
Scegli l'attività specifica (es. "Icecrown Citadel")
Scegli la difficoltà (Normal / Heroic / Mythic / Ascended / Trial 1-10 per i raid)
Scrivi il messaggio nel box in basso. Puoi usare variabili tipo:
`{role}` — chi ti serve
`{class}` — la tua classe
`{ilvl}` — il tuo item level
`{gs}` — il tuo gear score
Esempio: `LFM ICC 10 hc need {role} {class} {ilvl} ilvl`
Sotto trovi i canali spam: sono 10 pulsanti (1-10). Ognuno corrisponde a uno slot canale di WoW.
Per vedere quali canali hai attivi: chat → `/chatlist` oppure guarda la lista in alto a destra della chat
I canali standard sono: 1 = General, 2 = Trade, 3 = LocalDefense, 4 = LookingForGroup, 5 = GuildRecruitment
Clicca i pulsanti per attivarli (diventano verdi)
Imposta il timer (es. 30 secondi) e premi Start Spam
FrostSeek manderà il tuo messaggio sui canali scelti ogni 30 secondi. Per fermare: Stop Spam
Auto-Invite (facoltativo)
Attiva ON/OFF
Imposta Min iLvl (es. 200)
Quando qualcuno ti sussurra un numero ≥ 200, viene invitato in automatico
> **Attenzione**: lo spam automatico è comodo ma non abusarne. I GM possono bannarti per spam eccessivo. 30 secondi è un buon compromesso.
---
6) Tab FrostNet — Il cuore dell'addon
FrostNet è una rete tra tutti i player che hanno FrostSeek. Qui vedi i gruppi reali, non i messaggi in chat.
Sotto-tab
Browse — sfogli i gruppi aperti creati da altri player FrostSeek
Create Group — crei il tuo gruppo e lo pubblichi su FrostNet
My Group — gestisci il gruppo che hai creato
Applications — vedi chi ha fatto richiesta di entrare nel tuo gruppo
Filtri in alto (Browse)
All — Dungeons — Raids — Keys — Events — Manastorm — Quests
Creare un gruppo
Vai su Create Group
Scegli:
Type (Dungeon, Raid, World Boss, Key, Event, PvP, Manastorm, Quest)
Expansion (Classic, TBC, WotLK, Cata, MoP, Custom)
Activity (es. "Icecrown Citadel")
Difficulty (Normal, Heroic, Mythic, ecc.)
Se è una Key: imposta anche il Key Level
Roles Needed (spunta Tank / Healer / DPS / Support)
Min iLvl, Max Members, Voice, Loot
Note (es. "link achievement")
Premi Publish Group
Il gruppo appare nella lista Browse di tutti i player FrostNet connessi
Ricevere candidature
Quando qualcuno si candida al tuo gruppo, ti appare un popup in alto a sinistra
Clicca Accept per accettare (auto-invito) o Decline per rifiutare
Vedi tutte le candidature nel tab Applications
Candidarsi a un gruppo
Scegli un gruppo da Browse
Scegli il tuo ruolo
Premi Apply
Aspetta che il leader ti accetti (puoi vedere lo stato in My Applications)
---
7) Tab Community
Bacheca eventi della community
Reclutamento gilda
Puoi creare/modelli template per annunci gilda
Comandi utili
`/fsloadtemplate <nome>` — carica un template salvato
`/fsdeltemplate <nome>` — cancella un template
---
8) Tab Options — Tutte le impostazioni
Le opzioni sono divise in categorie:
Categoria	Cosa fare qui
General	Tema, scala UI, posizione finestra, minimap button, auto-open al login
LFG System	Tutte le impostazioni LFG (popup, filtri, ruoli)
LFM System	Timer spam, auto-invite, canali spam, reset canali
Popup Categories	Scegli quali categorie fanno apparire i popup
Custom Keywords	Aggiungi parole chiave personalizzate per ogni categoria
Custom Messages	Personalizza il messaggio sussurrato quando accetti qualcuno
Sound	Suoni per popup, listing, applicant
Advanced	Reset posizione, reset stats, pulisci favoriti, debug mode
Temi disponibili
Cambia tema da Options → General → Select Theme. Dopo aver cambiato tema serve `/reload` (te lo chiede lui).
---
9) Minimap Button — L'icona sulla minimap
Click sinistro → apre/chiude FrostSeek sul tab LFG
Ctrl + Click sinistro → disabilita in un colpo solo LFG + Popups (pulsante rosso). Ripeti per riattivare. FrostNet e LFM restano attivi.
Trascina → sposta il pulsante attorno alla minimap
L'icona cambia colore in base all'attività rilevata:
🟢 Verde → Dungeon
🟠 Arancione → Raid
🟡 Giallo → World Boss
🔴 Rosso → PvP
🟣 Viola → Manastorm
🌸 Rosa → Keystone
🔵 Azzurro → Quest
Se c'è attività lampeggia. Se è tutto calmo resta neutra.
---
10) Problemi comuni — Risoluzione
"Non vedo nessun gruppo su FrostNet"
Scrivi `/fsnet` in chat — controlla che Connected = true
Se Connected = false, esci ed entra da un canale chat (qualunque) per forzare la sincronizzazione
Verifica che `Options → General → Enable FrostNet` sia spuntato
`/reload` e riprova
"I popup LFG non mi appaiono"
Verifica che Options → LFG → Disable Popups sia OFF
Verifica che Popup Categories abbia almeno una categoria attiva
Se sei in gruppo o in combattimento, i popup sono soppressi (vedi opzioni)
`/reload`
"Lo spam non parte"
Verifica di aver scritto un messaggio nel box
Verifica che almeno un canale sia attivo (verde) tra i 10 pulsanti
Verifica che il timer sia ≥ 5 secondi
Verifica di essere in un canale valido (prova `/1` in chat — se non risponde "General", non sei in nessun canale)
"L'addon non carica"
Controlla nella schermata personaggio → AddOns → FrostSeek sia spuntato
Se dice "Out of date", spunta Load out of date AddOns in alto a destra
`/fsdebug` per vedere lo stato dei moduli
"Voglio resettare tutto"
Options → Advanced → Clear All Data → conferma → `/reload`
---
11) Comandi rapidi — Tabella riassuntiva
Comando	Cosa fa
`/fs`	Apre/chiude FrostSeek
`/fsdisable`	Disabilita LFG + Popups (stesso del Ctrl+Click minimap)
`/fsenable`	Riattiva LFG + Popups
`/fstoggle`	Altera LFG + Popups acceso/spento
`/fslfg`	Apre sul tab LFG
`/fslfm`	Apre sul tab LFM
`/fscommunity`	Apre sul tab Community
`/fsoptions`	Apre sul tab Options
`/fsnet`	Stato rete FrostNet
`/fsopen`	Apre sul tab Dashboard
`/fsdebug`	Info di debug
`/fsdebugtoggle`	Toggle debug mode
`/fsclass set <classe>`	Forza classe (per Ascension)
`/fsclass reset`	Reset classe
`/fsloadtemplate <nome>`	Carica template gilda
`/fsdeltemplate <nome>`	Cancella template gilda
---
12) Consigli pratici
Per Ascension: usa `/fsclass set <NomeClasse>` se l'addon non rileva correttamente la tua classe custom
Per 3.3.5: Gear Score funziona solo se hai un addon GS installato (FrostSeek lo legge automaticamente)
Per fare gruppo raid: crea il gruppo in FrostNet (più visibile) E fai partire lo spam LFM in chat (per chi non ha l'addon). Le due cose non si escludono
Per non essere bannato per spam: imposta il timer LFM a 30+ secondi e usa massimo 2-3 canali alla volta
---
13) Cose da NON fare
❌ NON impostare il timer LFM a 5 secondi su 10 canali — rischi ban per spam
❌ NON attivare "Mute" su tutti i player — non vedrai più nessun popup
❌ NON dimenticare il gruppo pubblicato su FrostNet — se il gruppo è pieno, rimuovilo dal tab My Group
---
14) FAQ veloci
D: FrostSeek è bannabile?
R: No, è un addon come gli altri. Bannabile è lo spam eccessivo, ma quello dipende da te.
D: Devo avere FrostNet attivo per usare LFG/LFM?
R: No. LFG ascolta la chat, LFM scrive in chat. FrostNet è solo la rete tra chi ha l'addon. Sono 3 cose separate.
D: I miei amici senza addon vedono i miei gruppi FrostNet?
R: No. Devono installare FrostSeek. Per quelli senza addon, usa lo spam LFM.
D: Perdita dati dopo reload?
R: Tutto è salvato in `FrostSeekDB`. Le impostazioni e i template gilda persistono. I gruppi FrostNet spariscono al logout.
D: Come disinstallo?
R: Cancella la cartella `Interface\AddOns\FrostSeek`. Per pulire anche i salvataggi: Options → Advanced → Clear All Data → reload → poi cancella la cartella.
---
Buon divertimento. Se qualcosa non funziona come dovrebbe, prima `/fsdebug` poi `/fsnet`, poi chiedi sul Discord ufficiale.
— Ayro
---
15) Novità v2.2.0 (LEGGI SE HAI GIA' USATO FROSTSEEK)
Questa versione aggiunge diverse funzioni nuove. Niente paura: tutto quello che già usavi continua a funzionare uguale.

🔗 Voice Bridge — link Discord nel profilo
NUOVO: il link Discord/TeamSpeak si imposta UNA VOLTA nel tab Profilo.
- Apri il tab Profile dal main frame
- Trova il campo "Voice URL (Discord/TS)"
- Incolla il tuo invito Discord (deve iniziare con https://discord.gg/ o https://discord.com/invite/)
- Clicca "Salva Link Voice"
- Da quel momento in poi, ogni gruppo che pubblichi su FrostNet avrà automaticamente il tuo link allegato
- Clicca "Test Voice" per verificare che il link funzioni (apre un popup con il link selezionabile + bottone Copy)
- Gli altri utenti vedranno un pulsante "Entra in Voice" quando selezionano il tuo gruppo nel tab FrostNet → Browse
- Su 3.3.5 il popup non apre il browser in automatico (limiti del client): stampa il link in chat e lo puoi copiare a mano
- Da chat puoi comunque gestire i link (per te o per altri leader):
  - `/fsvoice set <leaderName> <URL>`
  - `/fsvoice get <leaderName>`
  - `/fsvoice remove <leaderName>`
  - `/fsvoice list`

🌐 Lingua
In Options → General ci sono due dropdown nuovi:
- Language: auto / enUS / itIT / esES (auto segue la lingua del client WoW)
- Log Level: DEBUG / INFO / WARN / ERROR (controlla quanto stampa in chat)
Le traduzioni italiana e spagnola sono complete al 100%.
Quando cambi lingua, appare un popup "Ricarica Ora / Più tardi" — clicca "Ricarica Ora" per applicare la nuova lingua.

🛠️ Comandi nuovi per power-user
- `/fsdumplog` — stampa gli ultimi 200 eventi del log interno (utile quando reporti un bug)
- `/fsreset confirm` — cancella TUTTO tranne i tuoi template LFM preferiti (da usare come ultima spiaggia)

📦 Retrocompatibilità
- Il protocollo di rete è passato da FSK1 a FSK2. I client vecchi (2.1.x) continuano a vedere i tuoi messaggi e tu vedi i loro. Non serve fare nulla.
- Al primo login dopo l'upgrade, FrostSeek crea un backup del vecchio DB in `FrostSeekDB._backup_v1`. Se qualcosa va storto, puoi tornare indietro a mano.
