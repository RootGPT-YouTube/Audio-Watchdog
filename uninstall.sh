#!/bin/bash

echo "=== Audio Watchdog Uninstaller per SailfishOS (Xperia 10 III) ==="
echo

# 1. Disattivazione timer e servizio utente
echo "[1/4] Disattivo timer e servizio utente..."
systemctl --user disable --now audio-watchdog.timer 2>/dev/null
systemctl --user disable --now audio-watchdog.service 2>/dev/null
echo "✔ Timer e servizio disattivati."
echo

# 2. Rimozione file systemd utente
echo "[2/4] Rimuovo file systemd utente..."
rm -f ~/.config/systemd/user/audio-watchdog.timer
rm -f ~/.config/systemd/user/audio-watchdog.service
echo "✔ File rimossi."
echo

# 3. Ricarica systemd utente
echo "[3/4] Ricarico systemd utente..."
systemctl --user daemon-reload
echo "✔ Ricaricato."
echo

# 4. Rimozione script watchdog
echo "[4/4] Rimuovo lo script /usr/local/bin/audio-watchdog..."
sudo rm -f /usr/local/bin/audio-watchdog
echo "✔ Script rimosso."
echo

echo "=== Disinstallazione completata! ==="
echo "Il watchdog audio è stato completamente rimosso."
echo
