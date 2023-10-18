#!/bin/bash
# Version 1.0
# Copyright (c) 2023 tteck
# Author: skyguy2002
# License: MIT
# https://github.com/skyguy2002/Proxmox/raw/main/LICENSE


# Automatisches Update-Skript

# Aktualisiere die Paketquellen
sudo apt-get update -y > /dev/null 2>&1

# Führe ein Upgrade der installierten Pakete durch
sudo apt-get upgrade -y > /dev/null 2>&1

# Führe autoremove durch
sudo apt-get autoremove -y > /dev/null 2>&1
