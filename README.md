# G23-GetSysInfo

Sito per raccogliere e visualizzare le specifiche di sistema di più PC.

## Struttura
```
G23-GetSysInfo/
├── api/
│   ├── upload.js          ← riceve i dati dal PowerShell
│   ├── list.js            ← lista tutti i PC
│   └── pc/[pcName].js     ← report di un singolo PC
├── public/
│   └── index.html         ← sito web
├── vercel.json
└── G23-GetSysInfo.ps1    ← script da eseguire sui PC
```

## Deploy su Vercel

1. Crea repo GitHub, carica tutti i file
2. Vai su vercel.com → New Project → importa il repo
3. Aggiungi le variabili d'ambiente:
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`
4. Deploy → copia l'URL (es. `G23-GetSysInfo-xyz.vercel.app`)
5. Nello script `.ps1` sostituisci `TUO-PROGETTO` con l'URL reale

## Esecuzione script PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File G23-GetSysInfo.ps1
```

Non richiede privilegi admin. Non salva nulla sul disco.
