#!/bin/bash
set -e

# Bookworm backport repos
echo "deb https://deb.debian.org/debian bookworm-backports main non-free-firmware" | sudo tee /etc/apt/sources.list
echo "deb-src https://deb.debian.org/debian bookworm-backports main non-free-firmware" | sudo tee /etc/apt/sources.list
echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/Debian_12/ /" | sudo tee /etc/apt/sources.list
echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list
#echo "deb [signed-by=/usr/share/keyrings/teamviewer-keyring.gpg] https://linux.teamviewer.com/deb stable main" | sudo tee /etc/apt/sources.list

# Install missing packages
for pkg in $(cat package-list.txt); do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Installing $pkg..."
        sudo apt-get install -y $pkg
    else
        echo "$pkg is already installed."
    fi
done

# Brave Browser
curl -fsS https://dl.brave.com/install.sh | sh

# TeamViewer
wget -P ~/Downloads "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
sudo apt install ~/Downloads/teamviewer_amd64.deb

