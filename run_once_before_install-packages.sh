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
done < "$chezmoi_dir/packages/apt-repositories.list"

# Adding apt repository keys
while IFS= read -r key; do
  # Skip empty lines and comments
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  echo "➕ Adding repository key: $key"
  curl -fsSL "$key" | sudo apt-key add -
done < "$chezmoi_dir/packages/apt-keys.list"

# Update package lists
echo "🔄 Updating APT sources..."
sudo apt update

# Remove not needed packages
sudo apt remove -y --autoremove --ignore-missing $(tr '\n' ' ' < "$chezmoi_dir/packages/remove_packages.list")

# Install missing packages
sudo apt install -y --ignore-missing $(tr '\n' ' ' < "$chezmoi_dir/packages/install_packages.list")

# Flatpaks
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y $(tr '\n' ' ' < "$chezmoi_dir/packages/flatpak.list")
flatpak uninstall --unused

# Install Jetbrains Mono Nerd Font
echo "Installing JetBrains Mono Nerd Font..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip -o JetBrainsMono.zip
rm JetBrainsMono.zip

# Refresh font cache
fc-cache -fv
echo "JetBrains Mono Nerd Font installed successfully!"

# Oh-My-Posh
curl -s https://ohmyposh.dev/install.sh | bash -s

# Brave Browser
curl -fsS https://dl.brave.com/install.sh | sh

# TeamViewer
# wget -P ~/Downloads "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
# sudo apt install ~/Downloads/teamviewer_amd64.deb

sudo apt autoremove

#Gnome settings
dconf load / "$chezmoi_dir/dconf_settings_dump.dconf"
