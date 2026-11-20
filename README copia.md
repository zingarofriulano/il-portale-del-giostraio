# Il Portale del Giostraio — base tecnica di produzione

Questa cartella contiene la prima base tecnica: schema PostgreSQL/Supabase, policy RLS e configurazione ambientale di esempio. Non contiene ancora un'applicazione Next.js completa né credenziali attive.

## Stack proposto
- Next.js su Vercel per sito e API server-side
- Supabase Auth + PostgreSQL + Storage + Realtime
- Twilio Verify per OTP SMS
- Dominio `ilportaledelgiostraio.it` da acquistare tramite registrar accreditato

## Passi tecnici
1. Creare un progetto Supabase intestato al proprietario del portale.
2. Eseguire `supabase/migrations/202611200001_initial_schema.sql` nel SQL Editor o tramite Supabase CLI.
3. Abilitare Phone Auth con password e verifica del numero; configurare Twilio Verify come provider SMS.
4. Configurare rate limits, CAPTCHA, OTP expiry e template in italiano.
5. Creare il bucket Storage `listing-photos`; aggiungere policy di upload e cancellazione per utente autenticato, con directory iniziale uguale all'UID.
6. Implementare le API/RPC server-side per creare conversazioni in modo atomico, aggiungere i due partecipanti (venditore e interessato) e impedire auto-contatti.
7. Implementare UI Next.js e validazioni server-side; non fidarsi dei controlli solo nel browser.
8. Pubblicare su Vercel e collegare il dominio dopo l'acquisto, impostando i DNS indicati da Vercel.
9. Configurare variabili d'ambiente nel pannello Vercel. La service role key e le credenziali Twilio devono restare solo lato server, mai nel browser.
10. Eseguire test di sicurezza, privacy, chat, upload, limite annunci e recupero account prima del lancio.

## Requisiti funzionali già fissati
- Tutti possono consultare annunci e post CERCO.
- Solo utenti autenticati possono contattare e pubblicare.
- Ogni annuncio ha prezzo obbligatorio maggiore di zero.
- Massimo 4 annunci attivi per utente, enforced da trigger database.
- Pubblicazione immediata, con segnalazione e moderazione amministrativa successiva.
- Chat privata con accesso limitato ai membri.

## Attenzione: attività ancora necessarie prima del go-live
- Completare l'applicazione Next.js, le API e la UI collegata al database.
- Completare RPC per apertura conversazioni e policy Storage/admin; testare tutte le policy con utenti distinti.
- Configurare ruoli amministrativi separati e audit log.
- Definire termini di servizio, privacy/cookie policy, tempi di conservazione e procedura per richieste GDPR.
- Verificare titolarità del dominio e configurare email di sistema.
- Effettuare test di carico, backup/restore e test di sicurezza.

## Dominio
La disponibilità di `ilportaledelgiostraio.it` non è stata verificata né il dominio acquistato. Il Registro .it spiega che la registrazione avviene tramite Registrar accreditato: https://www.nic.it/it/trova-il-tuo-it/come-registrare

## SMS
Twilio Verify è la scelta iniziale proposta. Costi, copertura, mittente, requisiti di verifica dell'account e consegna in Italia vanno confermati nel pannello del provider prima del lancio. Non inserire segreti nel repository.
