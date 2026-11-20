# Il Portale del Giostraio — prototipo frontend

## Avvio
Apri `index.html` con un browser moderno. Per un ambiente locale puoi anche eseguire:
`python3 -m http.server 8000`
e visitare `http://localhost:8000`.

## Funzioni dimostrative
- Homepage responsive con ruota panoramica cartoon.
- Categorie, filtri e ricerca.
- Schede annuncio, preferiti e pulsante contatto.
- Form di pubblicazione con prezzo obbligatorio, foto e limite di 4 annunci per account demo.
- Bacheca CERCO.
- Schermata area personale e accesso dimostrativo.
- Navigazione inferiore in stile app iOS.

## Importante: non è ancora un servizio di produzione
I dati vivono solo nella memoria della pagina e si perdono al ricaricamento. Login, OTP SMS, chat, caricamento immagini persistente, ruoli amministrativi e moderazione reale non sono collegati a un backend. Prima della pubblicazione servono backend/API, database, autenticazione sicura con verifica SMS, storage immagini, chat realtime, protezione anti-abuso, privacy policy e conformità GDPR.
