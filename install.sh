#!/bin/bash

echo "=== Audio Watchdog Installer per SailfishOS (Xperia 10 III) ==="
echo

# 1. Creazione script watchdog.
echo "[1/4] Creazione dello script /usr/local/bin/audio-watchdog..."
cat << 'EOF' | sudo tee /usr/local/bin/audio-watchdog >/dev/null
#!/bin/bash

LOGFILE="$HOME/.local/share/audio-watchdog.log"
LASTEVENT="$HOME/.local/share/audio-watchdog.last"

TITLE="Audio Watchdog"
MSG_PULSE="PulseAudio was not responding and has been restarted."
MSG_CALLMODE="Call-mode was stuck and audio has been restored."

# Minimum time between two interventions (seconds)
RATELIMIT=120

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

notify() {
    # $1 = message
    dbus-send --session --print-reply \
      --dest=org.nemo.notifications \
      /org/nemo/notifications \
      org.nemo.notifications.NotificationManager.Notify \
      string:"$TITLE" \
      string:"$1" \
      string:"icon-system-notification" \
      uint32:0 \
      boolean:true >/dev/null 2>&1
}

restart_audio() {
    log "Restarting PulseAudio and ohmd..."
    systemctl --user restart pulseaudio
    sleep 2
    sudo systemctl restart ohmd
    log "Audio restart completed."
}

#############################################
# Rate-limit: avoid too frequent restarts
#############################################

if [ -f "$LASTEVENT" ]; then
    LASTTIME=$(cat "$LASTEVENT")
    NOW=$(date +%s)
    DIFF=$((NOW - LASTTIME))

    if [ "$DIFF" -lt "$RATELIMIT" ]; then
        log "Rate-limit active: skipping restart."
        exit 0
    fi
fi

#############################################
# 1. Check if PulseAudio responds
#############################################

if ! LANG=C pactl info >/dev/null 2>&1; then
    log "PulseAudio not responding."
    notify "$MSG_PULSE"
    date +%s > "$LASTEVENT"
    restart_audio
    exit 0
fi

#############################################
# 2. Check if call-mode is stuck
#############################################

if LANG=C pactl list | grep -q "State: RUNNING" && \
   LANG=C pactl list | grep -q "Call Mode"; then
    log "Call-mode stuck."
    notify "$MSG_CALLMODE"
    date +%s > "$LASTEVENT"
    restart_audio
    exit 0
fi

#############################################
# 3. Everything OK
#############################################

log "Audio OK."
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
