# Audio-Watchdog
Questo progetto fornisce un watchdog automatico per il sottosistema audio di SailfishOS su Sony Xperia 10 III, utile per mitigare il noto problema dell’audio muto durante le chiamate.

# Audio Watchdog per SailfishOS – Xperia 10 III

Questo progetto fornisce un sistema di controllo automatico (“watchdog”) per il sottosistema audio di SailfishOS su **Sony Xperia 10 III**, utile per mitigare il problema dell’audio muto durante le chiamate.

Il watchdog verifica periodicamente lo stato di PulseAudio e del routing audio, e in caso di problemi tenta un ripristino automatico senza riavviare il telefono.

Questa guida descrive **la procedura manuale** per creare il watchdog (punti 1–4).

---

## 1. Creare lo script `audio-watchdog`

Creare il file:

```bash
sudo nano /usr/local/bin/audio-watchdog
```
Inserire nel file appena creato:
```bash
#!/bin/bash

LOGFILE="$HOME/.local/share/audio-watchdog.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Controllo se pulseaudio risponde
if ! pactl info >/dev/null 2>&1; then
    echo "$DATE - PulseAudio non risponde, riavvio..." >> $LOGFILE
    systemctl --user restart pulseaudio
    sleep 2
    devel-su systemctl restart ohmd
    echo "$DATE - Riavvio completato." >> $LOGFILE
    exit 0
fi

# Controllo se il modulo call-mode è bloccato
if pactl list | grep -q "State: RUNNING" && pactl list | grep -q "Call Mode"; then
    echo "$DATE - Call mode bloccato, riavvio audio..." >> $LOGFILE
    systemctl --user restart pulseaudio
    sleep 2
    devel-su systemctl restart ohmd
    echo "$DATE - Audio ripristinato." >> $LOGFILE
    exit 0
fi

echo "$DATE - Audio OK." >> $LOGFILE
exit 0
```
Rendere eseguibile:
```bash
sudo chmod +x /usr/local/bin/audio-watchdog
```
## 2. Creare la directory dei servizi utente
```bash
mkdir -p ~/.config/systemd/user
```
## 3. Creare il servizio systemd utente
Creare:
```bash
sudo nano ~/.config/systemd/user/audio-watchdog.service
```
Inserire nel file appena creato:
```bash
[Unit]
Description=Audio watchdog per Xperia 10 III

[Service]
Type=oneshot
ExecStart=/usr/local/bin/audio-watchdog
```
## 4. Creare il timer systemd utente
Creare:
```bash
sudo nano ~/.config/systemd/user/audio-watchdog.timer
```
Inserire nel file appena creato:
```bash
[Unit]
Description=Timer per audio-watchdog

[Timer]
OnBootSec=20
OnUnitActiveSec=30

[Install]
WantedBy=default.target
```
Ricaricare e attivare i servizi systemd:
```bash
systemctl --user daemon-reload
systemctl --user enable --now audio-watchdog.timer
```
Log
Il watchdog scrive in:
```bash
~/.local/share/audio-watchdog.log
```
Con il comando:
```bash
sudo tail -f ~/.local/share/audio-watchdog.log
```
è possibile verificarne il corretto funzionamento.

## Compatibilità
SailfishOS 5.x
Sony Xperia 10 III (lena)

# Per una installazione rapida:
