#!/bin/bash

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


# Prüfe, ob der Parameter "?" oder "help" übergeben wurde
if [ "$1" = "?" ] || [ "$1" = "help" ]; then
  show_help
fi

# Setze die Farben für die Ausgabe
GREEN='\e[32m'
BLUE='\e[34m'
CYAN='\e[36m'
YELLOW='\e[33m'
RESET='\e[0m'

# Fragt am Anfang nach dem Sudo-Passwort und aktiviert den Sudo-Cache
sudo echo "Sudo-Cache aktiviert."

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
echo -e "${GREEN}===== Grundinstallation einer Proxmox VM =====${RESET}"
# Führt ein Update der Paketquellen durch
echo -e "${BLUE}Schritt 1: Aktualisiere die Paketquellen...${RESET}"
sudo apt update > /dev/null 2>&1
echo -e "${BLUE}Schritt 1: Aktualisierung abgeschlossen.${RESET}"
pause

# Setze die Umgebungsvariable DEBIAN_FRONTEND auf noninteractive
export DEBIAN_FRONTEND=noninteractive

# Zeigt die Anzahl der zu aktualisierenden Pakete an (ohne das Upgrade durchzuführen)
update_count=$(sudo apt -s upgrade | grep "aktualisiert,")
echo -e "${BLUE}Schritt 2: Anzahl der zu aktualisierenden Pakete: $update_count ${RESET}"
pause

# Führt ein Upgrade der installierten Pakete durch und zeigt dabei die Pakete an, die aktualisiert werden
echo -e "${BLUE}Schritt 2: Aktualisiert die Pakete...${RESET}"
sudo apt upgrade -y > /dev/null 2>&1
echo -e "${BLUE}Schritt 2: Upgrade abgeschlossen.${RESET}"
pause

# Lösche die DEBIAN_FRONTEND-Umgebungsvariable
unset DEBIAN_FRONTEND

# Entfernt nicht mehr benötigte Pakete
echo -e "${BLUE}Schritt 3: Entferne nicht mehr benötigte Pakete...${RESET}"
sudo apt autoremove > /dev/null 2>&1
echo -e "${BLUE}Schritt 3: Bereinigung abgeschlossen.${RESET}"
pause

# Installiert das Paket linux-virtual und alle empfohlenen Pakete
package_name="linux-virtual"
if is_package_installed "$package_name"; then
  echo -e "${BLUE}Schritt 2: Paket $package_name ist bereits vorhanden.${RESET}"
else
  echo -e "${BLUE}Schritt 2: Installiere das Paket $package_name und empfohlene Pakete...${RESET}"
  sudo apt install --install-recommends -y "$package_name" > /dev/null 2>&1
  echo -e "${BLUE}Schritt 2: Installation abgeschlossen.${RESET}"
fi
pause

# Installiert die Pakete linux-tools-virtual und linux-cloud-tools-virtual
package_names=("linux-tools-virtual" "linux-cloud-tools-virtual" "dialog")
for package_name in "${package_names[@]}"; do
  if is_package_installed "$package_name"; then
    echo -e "${BLUE}Schritt 3: Paket $package_name ist bereits vorhanden.${RESET}"
  else
    echo -e "${BLUE}Schritt 3: Installiere das Paket $package_name...${RESET}"
    sudo apt install -y "$package_name"  > /dev/null 2>&1
    echo -e "${BLUE}Schritt 3: Installation abgeschlossen.${RESET}"
  fi
  pause
done

# Ersetzt die Zeile GRUB_CMDLINE_LINUX_DEFAULT in der Datei /etc/default/grub
echo -e "${BLUE}Schritt 6: Passe die GRUB-Konfiguration an...${RESET}"
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="elevator=noop"/' /etc/default/grub
echo -e "${BLUE}Schritt 6: Anpassung abgeschlossen.${RESET}"
pause

# Aktualisiert GRUB
echo -e "${BLUE}Schritt 7: Aktualisiere GRUB...${RESET}"
sudo update-grub
echo -e "${BLUE}Schritt 7: Aktualisierung abgeschlossen.${RESET}"
pause

# Ändert die After-Zeile in der Datei hv-kvp-daemon.service
echo -e "${BLUE}Schritt 8: Passe die Datei hv-kvp-daemon.service an...${RESET}"
sudo sed -i 's/^After=.*/After=systemd-remount-fs.service/' /etc/systemd/system/multi-user.target.wants/hv-kvp-daemon.service
echo -e "${BLUE}Schritt 8: Anpassung abgeschlossen.${RESET}"
pause

# Aktualisiert die systemd-Dienstkonfiguration
echo -e "${BLUE}Schritt 9: Aktualisiere die systemd-Dienstkonfiguration...${RESET}"
sudo systemctl daemon-reload
echo -e "${BLUE}Schritt 9: Aktualisierung abgeschlossen.${RESET}"
pause

# Führt ein erneutes Update der Paketquellen durch
echo -e "${BLUE}Schritt 10: Erneuere die Paketquellen...${RESET}"
sudo apt update > /dev/null 2>&1
echo -e "${BLUE}Schritt 10: Aktualisierung abgeschlossen.${RESET}"
pause

# Überprüfen, ob das Paket qemu-guest-agent bereits installiert ist
package_name="qemu-guest-agent"
if is_package_installed "$package_name"; then
  echo -e "${BLUE}Schritt 11: Paket $package_name ist bereits installiert.${RESET}"
else
  echo -e "${BLUE}Schritt 11: Installiere das Paket $package_name...${RESET}"
  sudo apt install -y "$package_name" > /dev/null 2>&1
  echo -e "${BLUE}Schritt 11: Installation von $package_name abgeschlossen.${RESET}"
fi
pause

# Informiere den Benutzer über die Aktivierung des QEMU-Agents
dialog --title "QEMU-Agent in Proxmox aktivieren" --msgbox "Bitte stellen Sie sicher,dass der QEMU-Agent in Proxmox aktiviert wird, um eine reibungslose Kommunikation mit dem Gastsystem zu ermöglichen." 0 0

# Benutzerabfrage, ob das System heruntergefahren werden soll
echo -e "${GREEN}===== Skript abgeschlossen =====${RESET}"
dialog --title "Skript abgeschlossen" --yesno "Das Skript wurde abgeschlossen. Möchten Sie das System herunterfahren?" 0 0

# Überprüft die Antwort auf die Benutzerabfrage
response=$?
case $response in
   0)
     echo -e "${YELLOW}Der Server wird heruntergefahren.${RESET}"
     pause
     pause
     sudo shutdown -h now ;; # Benutzer hat "Ja" ausgewählt, das System wird heruntergefahren
   1) 
     echo -e "${GREEN}Das System bleibt eingeschaltet.${RESET}" ;; # Benutzer hat "Nein" ausgewählt, das Skript wird beendet
     pause
   255) echo -e "${YELLOW}Abbruch.${RESET}" ;; # Benutzer hat Abbruch ausgewählt
esac

# Lösche das Konsolenfenster nach dem Dialog
clear
