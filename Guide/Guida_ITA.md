# FrostSeek — Guida per Principianti Totali

FrostSeek ti serve per **trovare gruppo** (LFG) e **trovare membri** per il tuo gruppo (LFM) su World of Warcraft.

Questa guida è scritta per chi non ha mai installato un addon in vita sua. Segui i passi in ordine, uno alla volta, e andrà tutto bene.

---

## Passo 1 — Scarica il file ZIP

1. Scarica FrostSeek: otterrai un file **ZIP** (una cartella "compressa").
2. Salvalo dove lo trovi facilmente, per esempio sul **Desktop**.

Non serve nessun programma particolare: Windows sa fare tutto da solo.

---

## Passo 2 — Estrai lo ZIP

1. Clic **destro** sul file ZIP → **Estrai tutto...** (Extract All).
2. Windows ti chiede dove estrarre: va bene il Desktop.
3. Alla fine avrai una **cartella** chiamata **FrostSeek**.

> ✓ **Controlla:** apri questa cartella. Dentro devi vedere dei file come `FrostSeek.toc`, `Core.lua`, `loader.xml` e altre cartelle (`Modules`, `Media`, `Guide`, `Locales`).

---

## Passo 3 — Trova la cartella AddOns del gioco

La cartella "AddOns" sta dentro la cartella dove è installato WoW:

```
<cartella del gioco>\Interface\AddOns\
```

Come trovarla se non sai dov'è:

1. Clic **destro** sull'icona che usi per aprire WoW → **Apri percorso file** (Open file location).
2. Dalla cartella che si apre, entra in **Interface** → **AddOns**.
3. Se la cartella **AddOns** non esiste: entra in `Interface` e creala tu (clic destro → Nuovo → Cartella → chiamala esattamente `AddOns`).

> 💡 Hai più giochi/client installati (per esempio Ascension E un client 3.3.5)? Ognuno ha la **propria** cartella AddOns. Metti FrostSeek in quello dove giochi davvero.

---

## Passo 4 — Metti la cartella FrostSeek dentro AddOns

1. Copia la cartella **FrostSeek** (quella estratta al Passo 2).
2. Incollala dentro `Interface\AddOns\`.

### ⚠️ REGOLA D'ORO — La cartella deve chiamarsi ESATTAMENTE `FrostSeek`

Nome GIUSTO:

```
Interface\AddOns\FrostSeek\
```

Nomi SBAGLIATI (con questi nomi l'addon NON apparirà nel gioco):

```
Interface\AddOns\FrostSeek-main\      ← con scritta finale "-main" o simili
Interface\AddOns\FrostSeek(1)\        ← doppione creato da Windows
Interface\AddOns\frostseek addon\     ← nome inventato
```

Se la cartella ha un nome sbagliato: clic destro su di essa → **Rinomina** → scrivi `FrostSeek`.

### ⚠️ ATTENZIONE alla "cartella doppia"

SBAGLIATO (cartella dentro cartella):

```
Interface\AddOns\FrostSeek\FrostSeek\FrostSeek.toc    ← NO!
```

GIUSTO (il file .toc deve stare DIRETTAMENTE dentro FrostSeek):

```
Interface\AddOns\FrostSeek\FrostSeek.toc              ← SÌ!
```

### ✓ Controlla prima di andare avanti

Apri `Interface\AddOns\FrostSeek\` e guarda che ci sia il file **FrostSeek.toc**.

- Se c'è → perfetto, vai al Passo 5.
- Se invece c'è solo un'altra cartella FrostSeek → sei nella cartella doppia: entra, **taglia** tutto il contenuto, **incollalo** nella FrostSeek esterna, poi elimina la cartella interna ormai vuota.

---

## Passo 5 — Se avevi già FrostSeek (aggiornamento)

Se avevi già una versione precedente di FrostSeek:

1. **Chiudi WoW.**
2. **Elimina** la vecchia cartella `Interface\AddOns\FrostSeek` (clic destro → Elimina).
3. Incolla la cartella nuova.
4. Riapri WoW.

> ⚠️ Non incollare sopra la vecchia: prima elimina, poi incolla. Così sei sicuro che non restino file vecchi a creare problemi.

Se è la prima volta che lo installi, salta questo passo.

---

## Passo 6 — Attiva l'addon in gioco

1. Avvia WoW e arriva alla schermata di **selezione del personaggio**.
2. In **basso a sinistra** trovi il pulsante **AddOns** → cliccalo.
3. Nella lista deve esserci **FrostSeek** → assicurati che sia **spuntato**.
4. Se in alto compare la scritta **"Carica AddOn non aggiornati"** (Load out of date AddOns) → **spuntala**. Sui server privati serve quasi sempre.
5. Chiudi la finestrella ed **entra nel mondo** con il tuo personaggio.

> ❓ **FrostSeek non è nella lista?** Il gioco non vede la cartella. Torna al Passo 4 e ricontrolla il nome della cartella e la posizione del file `FrostSeek.toc` (deve stare in `Interface\AddOns\FrostSeek\FrostSeek.toc`).

---

## Passo 7 — Prima apertura

Quando entri nel mondo:

- In chat (in basso a sinistra) appare la scritta **`FrostSeek loaded!`** → tutto ok.
- La **prima volta** che apri FrostSeek parte una **procedura guidata di 4 pagine**:
  1. **Lingua** → scegli *Italiano* (oppure *Auto* per seguire la lingua del gioco)
  2. **INFO**
  3. **Opzioni rapide** → popup, suoni, filtro chat (puoi lasciare tutto com'è e cambiare tutto dopo)
  4. **Fine** → clicca *Termina*

Fatto! 🎉

---

## Come si apre FrostSeek

Hai due modi, entrambi validi:

1. **Pulsante sulla minimappa** — l'icona colorata intorno alla minimappa, click **sinistro**.
2. **Comando in chat** — scrivi `/fs` e premi Invio.

---

## Cosa trovi dentro — le 6 schede

In alto alla finestra di FrostSeek ci sono 6 schede:

| Scheda | A cosa serve |
|--------|--------------|
| **Dashboard** | Panoramica: il tuo iLvl, quanti sono online su FrostNet, statistiche di sessione |
| **FrostNet** | La bacheca dei gruppi: sfoglia i gruppi aperti, crea il tuo, vedi chi si è candidato |
| **LFG** | "Cerco gruppo": ti avvisa con un popup quando qualcuno cerca membri |
| **LFM** | "Cerco membri": quando hai TU un gruppo e ti manca gente |
| **Community** | Gilde che reclutano e bacheca eventi |
| **Options** | Tutte le impostazioni: lingua, tema, suoni, filtri, popup... |

---

## Le 3 cose che farai più spesso

### 🔍 Voglio TROVARE un gruppo → scheda LFG

1. Apri la scheda **LFG**.
2. Scegli il tuo **ruolo** (Tank / Healer / DPS / Support).
3. Scegli cosa ti interessa (Dungeon, Raid, Keystone, PvP...).
4. Aspetta: quando qualcuno cerca membri ti appare un **popup** con nome, messaggio e bottone **Whisper**.
5. Clicca **Whisper** → il messaggio si scrive da solo, con il tuo ruolo, classe e iLvl.

### 📢 HO un gruppo e mi manca gente → scheda LFM

1. Apri la scheda **LFM**.
2. Scegli l'attività e i ruoli che ti servono (e quanti ne vuoi).
3. Lascia il messaggio automatico o scrivine uno tuo; scegli i canali.
4. Clicca **Start Spam**: il messaggio parte da solo ogni tot secondi. **Stop Spam** per fermarlo.

### 🌐 Voglio vedere TUTTI i gruppi → scheda FrostNet

1. Apri la scheda **FrostNet**.
2. Sfoglia i gruppi pubblicati dagli altri utenti di FrostSeek.
3. Clicca **Apply** per candidarti, oppure crea il tuo gruppo con **Create Group**.

> 💡 FrostNet si collega da solo: non devi fare niente. Se vuoi controllare che sia connesso, scrivi `/fsnet` in chat.

---

## Comandi utili (da scrivere in chat e premere Invio)

| Comando | Cosa fa |
|---------|---------|
| `/fs` | Apre/chiude FrostSeek |
| `/fslfg` | Apre direttamente la scheda LFG |
| `/fslfm` | Apre direttamente la scheda LFM |
| `/fsnet` | Ti dice se FrostNet è connesso |
| `/fsetup` | Ripete la procedura guidata iniziale |

---

## Se qualcosa non va

### "In chat non appare FrostSeek loaded!"
- L'addon non è caricato: o non è spuntato nella lista AddOns (Passo 6), o la cartella ha nome/posizione sbagliati (Passo 4).

### "FrostSeek non è nella lista degli AddOns"
- Il gioco non trova il file `.toc`: quasi sempre è la cartella doppia o il nome sbagliato. Ricontrolla che esista `Interface\AddOns\FrostSeek\FrostSeek.toc`.

### "Ho aggiornato ma è tutto strano"
- Rifai un'installazione pulita: chiudi WoW → elimina `Interface\AddOns\FrostSeek` → incolla la cartella nuova → riavvia WoW.

### "Non vedo il pulsante sulla minimappa"
- Scrivi `/fs` in chat: la finestra si apre uguale. (Da Options → General puoi riattivare il pulsante.)

### "FrostNet non si collega"
- Scrivi `/fsnet` per vedere lo stato. Prova `/reload` (ricarica l'interfaccia senza chiudere il gioco).

---

## Riepilogo in 4 righe

1. Scarica lo ZIP → estrai → trovi la cartella **FrostSeek**
2. Mettila in `Interface\AddOns\` → deve chiamarsi **esattamente FrostSeek** (niente doppie cartelle!)
3. Schermata personaggio → pulsante **AddOns** → spunta FrostSeek
4. Entra nel mondo → scrivi **`/fs`** → gioca!

---

FrostSeek — Copyright © 2026 Ayro. Tutti i diritti riservati.
Per supporto contatta l'autore tramite il repository ufficiale (CurseForge Project ID: 1460315).
