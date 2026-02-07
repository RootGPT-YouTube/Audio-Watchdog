# [ITALIANO] == Audio-Watchdog ==
## Known Issue:
Quando si riavvia ohms i tasti volume smettono di funzionare.

## Audio-Watchdog per SailfishOS (testato su Sony Xperia 10 III)

Questo progetto fornisce un sistema di controllo automatico (“watchdog”) per il sottosistema audio di SailfishOS su **Sony Xperia 10 III**, utile per mitigare il problema dell’audio muto durante le chiamate.

Il watchdog verifica periodicamente lo stato di PulseAudio e del routing audio, e in caso di problemi tenta un ripristino automatico senza riavviare il telefono.

Questa guida descrive **la procedura manuale** per creare il watchdog.

### 1. Creare lo script `audio-watchdog`
Installare sudo:
```bash
devel-su pkcon install sudo -y
```
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
    echo "$DATE - PulseAudio is not responding, restarting..." >> $LOGFILE
    notificationtool -o add --summary="audio-watchdog" "Audio Watchdog" "PulseAudio was not responding and has been restarted."
    systemctl --user restart pulseaudio
    sleep 2
    sudo systemctl restart ohmd
    echo "$DATE - Restart completed." >> $LOGFILE
    exit 0
fi

# Controllo se il modulo call-mode è bloccato
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
```
Rendere eseguibile:
```bash
sudo chmod +x /usr/local/bin/audio-watchdog
```
### 2. Creare la directory dei servizi utente
```bash
sudo mkdir -p ~/.config/systemd/user
```
### 3. Creare il servizio systemd utente
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
### 4. Creare il timer systemd utente
Creare:
```bash
sudo nano ~/.config/systemd/user/audio-watchdog.timer
```
Inserire nel file appena creato:
```bash
[Unit]
Description=Timer per audio-watchdog

[Timer]
OnBootSec=300
OnUnitActiveSec=30

[Install]
WantedBy=default.target
```
Ricaricare e attivare i servizi systemd:
```bash
systemctl --user daemon-reload
systemctl --user enable --now audio-watchdog.timer
```
Log:  
Il watchdog scrive in:
```bash
~/.local/share/audio-watchdog.log
```
Con il comando:
```bash
sudo tail -f ~/.local/share/audio-watchdog.log
```
è possibile verificarne il corretto funzionamento.

### Compatibilità
SailfishOS 5.x
Sony Xperia 10 III (lena)

## Per una installazione rapida:
Prima di tutto, installa sudo:
```bash
devel-su pkcon install sudo -y
```
Poi lancia l'installer:
```bash
curl -sSL https://raw.githubusercontent.com/RootGPT-YouTube/Audio-Watchdog/refs/heads/main/install.sh | bash
```
## Per una sua disinstallazione facilitata:
```bash
curl -sSL https://raw.githubusercontent.com/RootGPT-YouTube/Audio-Watchdog/refs/heads/main/uninstall.sh | bash
```

### Chi vuole provare questo workaround è il benvenuto e sono graditi feedback.
## Grazie a tutti!

# [ENGLISH] == Audio-Watchdog ==
## Known Issue:
When ohmd is restarted, the volume keys stop working.

This project provides an automatic watchdog for the SailfishOS audio subsystem on the Sony Xperia 10 III, useful for mitigating the well‑known issue of muted audio during phone calls.

## Audio-Watchdog for SailfishOS (tested on Sony Xperia 10 III)
This project provides an automatic monitoring system (“watchdog”) for the SailfishOS audio subsystem on the Sony Xperia 10 III, useful for mitigating the issue of muted audio during calls.

The watchdog periodically checks the status of PulseAudio and the audio routing, and if a problem is detected, it attempts an automatic recovery without rebooting the device.

This guide describes the manual procedure to create the watchdog.

### 1. Create the audio-watchdog script
Install sudo:
```bash
devel-su pkcon install sudo -y
```
Create the file:
```bash
sudo nano /usr/local/bin/audio-watchdog
```
Insert into the newly created file:

```bash
#!/bin/bash

LOGFILE="$HOME/.local/share/audio-watchdog.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Check if PulseAudio is responding
if ! pactl info >/dev/null 2>&1; then
    echo "$DATE - PulseAudio not responding, restarting..." >> $LOGFILE
    notificationtool -o add --summary="audio-watchdog" "Audio Watchdog" "PulseAudio was not responding and has been restarted."
    systemctl --user restart pulseaudio
    sleep 2
    sudo systemctl restart ohmd
    echo "$DATE - Restart completed." >> $LOGFILE
    exit 0
fi

# Check if call-mode is stuck
if pactl list | grep -q "State: RUNNING" && pactl list | grep -q "Call Mode"; then
    echo "$DATE - Call mode stuck, restarting audio..." >> $LOGFILE
    notificationtool -o add --summary="audio-watchdog" "Audio Watchdog" "Call-mode was stuck and audio has been restored."
    systemctl --user restart pulseaudio
    sleep 2
    sudo systemctl restart ohmd
    echo "$DATE - Audio restored." >> $LOGFILE
    exit 0
fi

echo "$DATE - Audio OK." >> $LOGFILE
exit 0
```
Make it executable:
```bash
sudo chmod +x /usr/local/bin/audio-watchdog
```
### 2. Create the user service directory
```bash
sudo mkdir -p ~/.config/systemd/user
```
### 3. Create the systemd user service
Create:
```bash
sudo nano ~/.config/systemd/user/audio-watchdog.service
```
Insert into the newly created file:
```ini
[Unit]
Description=Audio watchdog for Xperia 10 III

[Service]
Type=oneshot
ExecStart=/usr/local/bin/audio-watchdog
```
### 4. Create the systemd user timer
Create:
```bash
sudo nano ~/.config/systemd/user/audio-watchdog.timer
```
Insert into the newly created file:
```ini
[Unit]
Description=Timer for audio-watchdog

[Timer]
OnBootSec=20
OnUnitActiveSec=30

[Install]
WantedBy=default.target
```
Reload and activate systemd services:
```bash
systemctl --user daemon-reload
systemctl --user enable --now audio-watchdog.timer
```
Log:  
The watchdog writes to:
```bash
~/.local/share/audio-watchdog.log
```
You can check its correct operation with:
```bash
sudo tail -f ~/.local/share/audio-watchdog.log
```
### Compatibility
SailfishOS 5.x
Sony Xperia 10 III (lena)

## For quick installation:
First of all, install sudo:
```
devel-su pkcon install sudo -y
```
Then, run the install.sh file:
```bash
curl -sSL https://raw.githubusercontent.com/RootGPT-YouTube/Audio-Watchdog/refs/heads/main/install.sh | bash
```
## For easy uninstallation:
```bash
curl -sSL https://raw.githubusercontent.com/RootGPT-YouTube/Audio-Watchdog/refs/heads/main/uninstall.sh | bash
```
### Anyone who wants to try this workaround is welcome, and feedback is appreciated.
## Thank you all!
