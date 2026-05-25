SERVICE K38 - CARTELLA PULITA PER GITHUB

Carica su GitHub solo i file presenti in questa cartella.

Inclusi:
- index.html
- config.js
- logo-k38.png
- icon-192.png
- icon-512.png
- manifest.webmanifest
- service-worker.js
- sound-click.wav
- sound-success.wav
- sound-error.wav

Non sono inclusi:
- setup_supabase.sql
- report JSON
- istruzioni interne

Prima del deploy:
1. Esegui setup_supabase.sql su Supabase SQL Editor dalla cartella completa originale.
2. Verifica che config.js punti al progetto Supabase corretto.
3. Dopo la pubblicazione, apri l'app e controlla la pagina Sistema.

Upgrade inclusi:
- ruoli utenti: admin, tecnico, collaboratore, sola visualizzazione
- avvisi automatici interni
- statistiche avanzate
- checklist tecnica per materiale evento
- storico manutenzioni materiale
- archivio documenti locale
- numerazioni PREV/EVT/CONTR
