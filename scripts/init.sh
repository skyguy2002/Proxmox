#!/bin/bash

# Führt ein Update der Paketquellen durch
echo "Schritt 1: Aktualisiere die Paketquellen..."
sudo apt update > /dev/null 2>&1
echo "Schritt 1: Aktualisierung abgeschlossen."

# Führt ein Upgrade der installierten Pakete durch und zeigt dabei die Pakete an, die aktualisiert werden
echo "Schritt 2: Führe ein Upgrade der installierten Pakete durch..."
sudo apt upgrade -Y > /dev/null 2>&1
echo "Schritt 2: Upgrade abgeschlossen."

# Entfernt nicht mehr benötigte Pakete
echo "Schritt 3: Entferne nicht mehr benötigte Pakete..."
sudo apt autoremove > /dev/null 2>&1
echo "Schritt 3: Bereinigung abgeschlossen."

# Installiert das Paket linux-virtual und alle empfohlenen Pakete
echo "Schritt 4: Installiere das Paket linux-virtual und empfohlene Pakete..."
sudo apt install --install-recommends -y linux-virtual
echo "Schritt 4: Installation abgeschlossen."

# Installiert die Pakete linux-tools-virtual und linux-cloud-tools-virtual
echo "Schritt 5: Installiere die Pakete linux-tools-virtual und linux-cloud-tools-virtual..."
sudo apt install -y linux-tools-virtual linux-cloud-tools-virtual
echo "Schritt 5: Installation abgeschlossen."

# Ersetzt die Zeile GRUB_CMDLINE_LINUX_DEFAULT in der Datei /etc/default/grub
echo "Schritt 6: Passe die GRUB-Konfiguration an..."
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="elevator=noop"/' /etc/default/grub
echo "Schritt 6: Anpassung abgeschlossen."

# Aktualisiert GRUB
echo "Schritt 7: Aktualisiere GRUB..."
sudo update-grub
echo "Schritt 7: Aktualisierung abgeschlossen."

# Ändert die After-Zeile in der Datei hv-kvp-daemon.service
echo "Schritt 8: Passe die Datei hv-kvp-daemon.service an..."
sudo sed -i 's/^After=.*/After=systemd-remount-fs.service/' /etc/systemd/system/multi-user.target.wants/hv-kvp-daemon.service
echo "Schritt 8: Anpassung abgeschlossen."

# Aktualisiert die systemd-Dienstkonfiguration
echo "Schritt 9: Aktualisiere die systemd-Dienstkonfiguration..."
sudo systemctl daemon-reload
echo "Schritt 9: Aktualisierung abgeschlossen."

# Führt ein erneutes Update der Paketquellen durch
echo "Schritt 10: Erneuere die Paketquellen..."
sudo apt update > /dev/null 2>&1
echo "Schritt 10: Aktualisierung abgeschlossen."

# Installiert das Paket qemu-guest-agent
echo "Schritt 11: Installiere das Paket qemu-guest-agent..."
sudo apt install -y qemu-guest-agent
echo "Schritt 11: Installation abgeschlossen."

# Benutzerabfrage, ob das System heruntergefahren werden soll
echo "Schritt 12: Skript abgeschlossen."
dialog --title "Skript abgeschlossen" --yesno "Das Skript wurde abgeschlossen. Möchten Sie das System herunterfahren?" 10 50

# Überprüft die Antwort auf die Benutzerabfrage
response=$?
case $response in
   0) sudo shutdown -h now ;; # Benutzer hat "Ja" ausgewählt, das System wird heruntergefahren
   1) echo "Das System bleibt eingeschaltet." ;; # Benutzer hat "Nein" ausgewählt, das Skript wird beendet
   255) echo "Abbruch." ;; # Benutzer hat Abbruch ausgewählt
esac

