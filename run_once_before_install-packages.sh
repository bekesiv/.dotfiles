#!/bin/bash
set -e

chezmoi_dir="$HOME/.local/share/chezmoi"

# Function to check if a apt repository exists
repo_exists() {
  local repo="$1"
  grep -Fxq "$repo" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null
}

# Adding apt repositories
while IFS= read -r repo; do
  # Skip empty lines and comments
  [[ -z "$repo" || "$repo" =~ ^# ]] && continue

  # Check if repo already exists
  if repo_exists "$repo"; then
    echo "✅ Repository already exists: $repo"
  else
    echo "➕ Adding repository: $repo"
    sudo apt-add-repository "$repo"
  fi
done < "$chezmoi_dir/packages/apt-repositories.txt"

# Update package lists
echo "🔄 Updating APT sources..."
sudo apt update

# Remove not needed packages
sudo apt remove -y --autoremove --ignore-missing $(tr '\n' ' ' < "$chezmoi_dir/packages/remove_packages.list")

# # Install missing packages
# for pkg in $(cat package-list.txt); do
#     if ! dpkg -l | grep -q "^ii  $pkg "; then
#         echo "Installing $pkg..."
#         sudo apt-get install -y $pkg
#     else
#         echo "$pkg is already installed."
#     fi
# done

# Flatpaks
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y $(tr '\n' ' ' < "$chezmoi_dir/packages/flatpak.list")
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
dconf load / "$chezmoi_dir/dconf_settings_dump.dconf"
