#!/bin/bash
# Version 1.6
# Copyright (c) 2023 tteck
# Author: skyguy2002
# License: MIT
# https://github.com/skyguy2002/Proxmox/raw/main/LICENSE

# Setze die Farben für die Ausgabe
GREEN='\e[32m'
BLUE='\e[34m'
CYAN='\e[36m'
YELLOW='\e[33m'
RESET='\e[0m'

# Funktion zur Anzeige der Hilfe
show_help() {
  GREEN='\e[32m'
  BLUE='\e[34m'
  CYAN='\e[36m'
  YELLOW='\e[33m'
  RESET='\e[0m'
  
  echo -e "${GREEN}Dieses Skript führt Aktualisierungen und Wartungsarbeiten auf einem Ubuntu-System durch.${RESET}"
  echo -e "${GREEN}Es aktualisiert die Paketquellen, führt ein Paketupgrade durch und bietet die Option, das System herunterzufahren.${RESET}"
  echo -e "${CYAN}Verwendung:${RESET}"
  echo -e "${CYAN}  ./scriptname              - Führt das Skript aus.${RESET}"
  echo -e "${CYAN}  ./scriptname help or ?    - Zeigt diese Hilfe an.${RESET}"
  exit 0
}

# Funktion zur Überprüfung, ob Fail2Ban installiert ist
check_fail2ban_installed() {
  if dpkg -l | grep -q "fail2ban"; then
    fail2ban_installed=true
  else
    fail2ban_installed=false
  fi
}

# Funktion zur Überprüfung, ob Docker installiert ist
check_docker_installed() {
  if dpkg -l | grep -q "docker"; then
    docker_installed=true
  else
    docker_installed=false
  fi
}

# Funktion zur Installation von Docker
install_docker() {
  echo -e "${BLUE}Schritt 13: Installiere Fail2Ban und richte eine Grundkonfiguration ein.${RESET}"
  sudo curl -sSL https://get.docker.com/ | CHANNEL=stable sh > /dev/null 2>&1
  echo -e "${BLUE}Schritt 13: Fail2Ban wurde installiert und konfiguriert.${RESET}"
}

# Funktion zur Installation von Fail2Ban und Konfiguration
install_fail2ban() {
  echo -e "${BLUE}Schritt 13: Installiere Fail2Ban und richte eine Grundkonfiguration ein.${RESET}"
  sudo apt-get install fail2ban -y > /dev/null 2>&1

  # Erstellen Sie eine einfache Konfigurationsdatei für Fail2Ban.
  cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 192.168.0.0/16
bantime = 600
findtime = 600
maxretry = 3

[sshd]
enabled = true
EOF

  # Aktiviere den Fail2Ban-Dienst und starte ihn.
  sudo systemctl enable fail2ban > /dev/null 2>&1
  sudo systemctl start fail2ban > /dev/null 2>&1
  sudo systemctl restart fail2ban > /dev/null 2>&1

  echo -e "${BLUE}Schritt 13: Fail2Ban wurde installiert und konfiguriert.${RESET}"
}


# Funktion für die Pausen
pause() {
  sleep 2 # 2 Sekunden Pause
}

# Überprüfung, ob ein Paket bereits installiert ist
is_package_installed() {
  local package_name="$1"
  if dpkg -l | grep -q "^ii  $package_name "; then
    return 0
  else
    return 1
  fi
}

# Funktion zur Überprüfung und Durchführung von 'apt-get autoremove'
autoremove() {
  echo -e "${BLUE}Schritt 3: Überprüfe, ob Pakete zum Entfernen verfügbar sind.${RESET}"
  autoremove_output=$(sudo apt-get autoremove -s > /dev/null 2>&1)

  if [[ "$autoremove_output" == *"Die folgenden Pakete werden entfernt"* ]]; then
    echo -e "${BLUE}Schritt 3: Bereinigung wird durchgeführt, um ungenutzte Pakete zu entfernen.${RESET}"
    sudo apt-get autoremove -y > /dev/null 2>&1
    echo -e "${BLUE}Schritt 3: Bereinigung abgeschlossen.${RESET}"
  else
    echo -e "${YELLOW}Keine Pakete zum Entfernen gefunden. Der Schritt 3 wird übersprungen.${RESET}"
  fi
}

#==============Ab hier startet das Skript==============

# Prüfe, ob der Parameter "?" oder "help" übergeben wurde
if [ "$1" = "?" ] || [ "$1" = "help" ]; then
  show_help
fi

# Fragt am Anfang nach dem Sudo-Passwort und aktiviert den Sudo-Cache
sudo echo "Sudo-Cache aktiviert."

echo -e "${GREEN}===== Grundinstallation einer Proxmox VM =====${RESET}"
# Führt ein Update der Paketquellen durch
echo -e "${BLUE}Schritt 1: Aktualisiere die Paketquellen...${RESET}"
sudo apt-get update > /dev/null 2>&1
echo -e "${BLUE}Schritt 1: Aktualisierung abgeschlossen.${RESET}"
pause

# Setze die Umgebungsvariable DEBIAN_FRONTEND auf noninteractive
export DEBIAN_FRONTEND=noninteractive

# Führt ein Upgrade der Paketquellen durch
echo -e "${BLUE}Schritt 2: Führe ein Upgrade der installierten Pakete durch, um die Systemstabilität und Sicherheit zu gewährleisten.${RESET}"
sudo apt-get upgrade -y > /dev/null 2>&1
echo -e "${BLUE}Schritt 2: Upgrade der installierten Pakete abgeschlossen.${RESET}"


# Lösche die DEBIAN_FRONTEND-Umgebungsvariable
unset DEBIAN_FRONTEND

# Aufruf der autoremove-Funktion
autoremove

# Installiert das Paket linux-virtual und alle empfohlenen Pakete
echo -e "${BLUE}Schritt 4: Linux Virtual Treiber werden installiert....${RESET}"
package_name="linux-virtual"
if is_package_installed "$package_name"; then
  echo -e "${YELLOW}Schritt 4: Paket $package_name ist bereits vorhanden.${RESET}"
else
  echo -e "${BLUE}Schritt 4: Installiere das Paket $package_name und empfohlene Pakete...${RESET}"
  sudo apt-get install --install-recommends -y "$package_name" > /dev/null 2>&1
  echo -e "${BLUE}Schritt 4: Installation abgeschlossen.${RESET}"
fi
pause

# Installiert die Pakete linux-tools-virtual und linux-cloud-tools-virtual
echo -e "${BLUE}Schritt 5: Weitere Pakete werden installiert....${RESET}"
package_names=("linux-tools-virtual" "linux-cloud-tools-virtual" "dialog")
for package_name in "${package_names[@]}"; do
  if is_package_installed "$package_name"; then
    echo -e "${YELLOW}Schritt 5: Paket $package_name ist bereits vorhanden.${RESET}"
  else
    echo -e "${BLUE}Schritt 5: Installiere das Paket $package_name...${RESET}"
    sudo apt-get install -y "$package_name"  > /dev/null 2>&1
    echo -e "${BLUE}Schritt 5: Installation abgeschlossen.${RESET}"
  fi
  pause
done

# Ersetzt die Zeile GRUB_CMDLINE_LINUX_DEFAULT in der Datei /etc/default/grub
echo -e "${BLUE}Schritt 6: Passe die GRUB-Konfiguration an...${RESET}"
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="elevator=noop"/' /etc/default/grub > /dev/null 2>&1
echo -e "${BLUE}Schritt 6: Anpassung abgeschlossen.${RESET}"
pause

# Aktualisiert GRUB
echo -e "${BLUE}Schritt 7: Aktualisiere GRUB...${RESET}"
sudo update-grub > /dev/null 2>&1
echo -e "${BLUE}Schritt 7: Aktualisierung abgeschlossen.${RESET}"
pause

# Ändert die After-Zeile in der Datei hv-kvp-daemon.service
echo -e "${BLUE}Schritt 8: Passe die Datei hv-kvp-daemon.service an...${RESET}"
sudo sed -i 's/^After=.*/After=systemd-remount-fs.service/' /etc/systemd/system/multi-user.target.wants/hv-kvp-daemon.service > /dev/null 2>&1
echo -e "${BLUE}Schritt 8: Anpassung abgeschlossen.${RESET}"
pause

# Aktualisiert die systemd-Dienstkonfiguration
echo -e "${BLUE}Schritt 9: Aktualisiere die systemd-Dienstkonfiguration...${RESET}"
sudo systemctl daemon-reload
echo -e "${BLUE}Schritt 9: Aktualisierung abgeschlossen.${RESET}"
pause

# Führt ein erneutes Update der Paketquellen durch
echo -e "${BLUE}Schritt 10: Erneuere die Paketquellen...${RESET}"
sudo apt-get update > /dev/null 2>&1
echo -e "${BLUE}Schritt 10: Aktualisierung abgeschlossen.${RESET}"
pause

# Überprüfen, ob das Paket qemu-guest-agent bereits installiert ist
echo -e "${BLUE}Schritt 11: Überprüfe auf Qemu Guest Agent....${RESET}"
package_name="qemu-guest-agent"
if is_package_installed "$package_name"; then
  echo -e "${YELLOW}Schritt 11: Paket $package_name ist bereits installiert.${RESET}"
else
  echo -e "${BLUE}Schritt 11: Installiere das Paket $package_name...${RESET}"
  sudo apt-get install -y "$package_name" > /dev/null 2>&1
  echo -e "${BLUE}Schritt 11: Installation von $package_name abgeschlossen.${RESET}"
fi
pause

# Setze die Zeitzone auf Berlin
echo -e "${BLUE}Schritt 12:Setze die Zeitzone auf Berlin...${RESET}"
sudo timedatectl set-timezone Europe/Berlin > /dev/null 2>&1

# Aktualisiere die NTP-Konfiguration, um deutsche Zeitserver zu verwenden
echo -e "${BLUE}Schritt 12:Aktualisiere die NTP-Konfiguration...${RESET}"
cat <<EOL | sudo tee /etc/systemd/timesyncd.conf > /dev/null
[Time]
NTP=de.pool.ntp.org
FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOL

# Aktiviere und starte den systemd-timesyncd-Dienst
sudo systemctl enable systemd-timesyncd > /dev/null 2>&1
sudo systemctl start systemd-timesyncd > /dev/null 2>&1

echo -e "${BLUE}Schritt 12:Zeitzone und NTP-Konfiguration aktualisiert.${RESET}"
pause

# Überprüfen, ob Fail2Ban installiert ist
check_fail2ban_installed

if $fail2ban_installed; then
  echo -e "${YELLOW}Fail2Ban ist bereits installiert. Die Installation wird übersprungen.${RESET}"
else
  # Benutzerabfrage, ob Fail2Ban installiert werden soll
  dialog --title "Fail2Ban Installation" --yesno "Möchten Sie Fail2Ban installieren und konfigurieren? Dies hilft bei der Sicherung Ihres Servers, indem fehlgeschlagene Anmeldeversuche überwacht werden." 0 0

  response=$?
  case $response in
    0)
      echo -e "${YELLOW}Fail2Ban wird installariert.${RESET}"
      clear
      install_fail2ban ;; # Benutzer hat "Ja" ausgewählt, Fail2Ban wird installiert und konfiguriert
    1)
      echo -e "${GREEN}Fail2Ban wird nicht installiert.${RESET}" ;; # Benutzer hat "Nein" ausgewählt, das Skript wird fortgesetzt
    255)
      echo -e "${YELLOW}Abbruch.${RESET}" ;; # Benutzer hat Abbruch ausgewählt
  esac
fi

# Überprüfen, ob Docker installiert ist
check_docker_installed
if $docker_installed; then
  echo -e "${YELLOW}Docker ist bereits installiert. Die Installation wird übersprungen.${RESET}"
else
  # Benutzerabfrage, ob Docker installiert werden soll
  dialog --title "Docker Installation" --yesno "Möchten Sie Docker installieren und konfigurieren?" 0 0
  response=$?
  case $response in
    0)
      echo -e "${YELLOW}Docker wird installariert.${RESET}"
      clear
      install_docker ;; # Benutzer hat "Ja" ausgewählt, Docker wird installiert und konfiguriert
    1)
      echo -e "${GREEN}Docker wird nicht installiert.${RESET}" ;; # Benutzer hat "Nein" ausgewählt, das Skript wird fortgesetzt
    255)
      echo -e "${YELLOW}Abbruch.${RESET}" ;; # Benutzer hat Abbruch ausgewählt
  esac
fi


echo -e "${GREEN}===== Skript abgeschlossen =====${RESET}"
pause

# Benutzerabfrage, ob Autoupdate aktiviert werden soll
dialog --title "Autoupdate aktivieren" --yesno "Möchten Sie Autoupdate aktivieren? Wenn ja, werden wöchentliche Updates automatisch Samstags um 00:00 Uhr durchgeführt." 0 0

response=$?
case $response in
  0)
    echo -e "${YELLOW}Autoupdate wird aktiviert.${RESET}"
    sudo mkdir -p /opt/update/
    sudo curl -o /opt/update/update-script.sh https://raw.githubusercontent.com/skyguy2002/Proxmox/main/scripts/update-script.sh
    sudo chmod +x /opt/update/update-script.sh
    (crontab -l ; echo "0 0 * * 6 /opt/update/update-script.sh") | crontab -
    echo -e "${BLUE}Autoupdate aktiviert.${RESET}"
    ;;
  1)
    echo -e "${GREEN}Autoupdate wird nicht aktiviert.${RESET}" ;;
  255)
    echo -e "${YELLOW}Abbruch.${RESET}" ;;
esac

# Informiere den Benutzer über die Aktivierung des QEMU-Agents
dialog --title "QEMU-Agent in Proxmox aktivieren" --msgbox "Bitte stellen Sie sicher,dass der QEMU-Agent in Proxmox aktiviert wird, um eine reibungslose Kommunikation mit dem Gastsystem zu ermöglichen." 0 0

# Benutzerabfrage, ob das System heruntergefahren werden soll
dialog --title "Skript abgeschlossen" --yesno "Das Skript wurde abgeschlossen. Möchten Sie das System herunterfahren?" 0 0

# Überprüft die Antwort auf die Benutzerabfrage
response=$?
case $response in
  0)
    echo -e "${YELLOW}Der Server wird heruntergefahren.${RESET}"
    clear
    sudo shutdown -h now ;; # Benutzer hat "Ja" ausgewählt, das System wird heruntergefahren
  1)
    echo -e "${GREEN}Das System bleibt eingeschaltet.${RESET}" ;; # Benutzer hat "Nein" ausgewählt, das Skript wird beendet
  255)
    echo -e "${YELLOW}Abbruch.${RESET}" ;; # Benutzer hat Abbruch ausgewählt
esac

# Lösche das Konsolenfenster nach dem Dialog
clear
