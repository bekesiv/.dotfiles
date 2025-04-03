#!/bin/bash
set -e

# Bookworm backport repos
echo "deb https://deb.debian.org/debian bookworm-backports main non-free-firmware" | sudo tee -a /etc/apt/sources.list
echo "deb-src https://deb.debian.org/debian bookworm-backports main non-free-firmware" | sudo tee -a /etc/apt/sources.list
echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/Debian_12/ /" | sudo tee -a /etc/apt/sources.list
echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" | sudo tee -a /etc/apt/sources.list
#echo "deb [signed-by=/usr/share/keyrings/teamviewer-keyring.gpg] https://linux.teamviewer.com/deb stable main" | sudo tee -a /etc/apt/sources.list

# Remove not needed packages
# sudo apt remove -y --autoremove --ignore-missing

# Install missing packages
for pkg in $(cat package-list.txt); do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Installing $pkg..."
        sudo apt-get install -y $pkg
    else
        echo "$pkg is already installed."
    fi
done

# Flatpaks
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak uninstall --unused


# Oh-My-Posh
curl -s https://ohmyposh.dev/install.sh | bash -s

# Brave Browser
curl -fsS https://dl.brave.com/install.sh | sh

# TeamViewer
wget -P ~/Downloads "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
sudo apt install ~/Downloads/teamviewer_amd64.deb

sudo apt autoremove

#Gnome settings
dconf load / ~/.local/share/chezmoi/dconf_settings_dump.dconf
