#!/bin/bash

echo "=== Audio Watchdog Installer per SailfishOS (Xperia 10 III) ==="
echo

# 1. Creazione script watchdog.
echo "[1/4] Creazione dello script /usr/local/bin/audio-watchdog..."
cat << 'EOF' | sudo tee /usr/local/bin/audio-watchdog >/dev/null
#!/bin/bash

LOGFILE="$HOME/.local/share/audio-watchdog.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Controllo se pulseaudio risponde.
if ! pactl info >/dev/null 2>&1; then
    echo "$DATE - PulseAudio not responding, restart..." >> $LOGFILE
    notificationtool -o add --summary="audio-watchdog" "Audio Watchdog" "PulseAudio was not responding and has been restarted."
    systemctl --user restart pulseaudio
    sleep 2
    sudo systemctl restart ohmd
    echo "$DATE - Restart completed." >> $LOGFILE
    exit 0
fi

# Controllo se il modulo call-mode è bloccato.
if pactl list | grep -q "State: RUNNING" && pactl list | grep -q "Call Mode"; then
    echo "$DATE - Call mode blocked, restart audio..." >> $LOGFILE
    notificationtool -o add --summary="audio-watchdog" "Audio Watchdog" "Call-mode was stuck and audio has been restored."
    systemctl --user restart pulseaudio
    sleep 2
    sudo systemctl restart ohmd
    echo "$DATE - Audio restored." >> $LOGFILE
    exit 0
fi

echo "$DATE - Audio OK." >> $LOGFILE
exit 0
EOF

sudo chmod +x /usr/local/bin/audio-watchdog
echo "✔ Script creato."
echo

# 2. Creazione directory systemd utente.
echo "[2/4] Creazione directory ~/.config/systemd/user..."
sudo mkdir -p ~/.config/systemd/user
echo "✔ Directory pronta."
echo

# 3. Creazione servizio utente.
echo "[3/4] Creazione audio-watchdog.service..."
cat << 'EOF' > ~/.config/systemd/user/audio-watchdog.service
[Unit]
Description=Audio watchdog per Xperia 10 III

[Service]
Type=oneshot
ExecStart=/usr/local/bin/audio-watchdog
EOF
echo "✔ Servizio creato."
echo

# 4. Creazione timer utente.
echo "[4/4] Creazione audio-watchdog.timer..."
cat << 'EOF' > ~/.config/systemd/user/audio-watchdog.timer
[Unit]
Description=Timer per audio-watchdog

[Timer]
OnBootSec=300
OnUnitActiveSec=30

[Install]
WantedBy=default.target
EOF
echo "✔ Timer creato."
echo

# Attivazione.
echo "Ricarico systemd utente..."
systemctl --user daemon-reload

echo "Abilito e avvio il timer..."
systemctl --user enable --now audio-watchdog.timer

echo
echo "=== Installazione completata! ==="
echo "Il watchdog è ora attivo e controllerà l'audio ogni 30 secondi."
echo "Log disponibile in: ~/.local/share/audio-watchdog.log"
echo
