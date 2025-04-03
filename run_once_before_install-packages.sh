#!/bin/bash
set -e

chezmoi_dir="$HOME/.local/share/chezmoi"
pkgmgmt="$chezmoi_dir/package_management"
sources_destdir="/etc/apt/sources.list.d/"

# Adding apt repositories
sudo mkdir -p "$sources_destdir"
for file in "$pkgmgmt/sources"/*.sources; do
    [ -f "$file" ] || continue  # Skip if no .sources files exist
    # Extract KeyUrl and KeyPath from the .sources file (if they exist)
    key_url=$(grep -E "^.?Key-Url:" "$file" | awk '{print $2}')
    key_path=$(grep -E "^Signed-By:" "$file" | awk '{print $2}')
    dearmor=$(grep -E "^.Dearmor:" "$file" | awk '{print $2}')
    # If both KeyUrl and KeyPath exist, download the key
    if [[ -n "$key_url" && -n "$key_path" ]]; then
        echo "Downloading GPG key from $key_url to $key_path..."

        sudo mkdir -p "$(dirname "$key_path")"  # Ensure the key directory exists

        if command -v curl >/dev/null 2>&1; then
            sudo curl -fsSL "$key_url" -o "$key_path"
        elif command -v wget >/dev/null 2>&1; then
            sudo wget -q "$key_url" -O "$key_path"
        else
            echo "Error: Neither curl nor wget found. Cannot download the key." >&2
            continue
        fi
        # Convert to binary format if required
        if [[ "$dearmor" == "Yes" ]]; then
            sudo gpg --dearmor "$key_path"
            sudo mv "${key_path}.gpg" "$key_path"
        fi
        # Set correct ownership and permissions
        sudo chown root:root "$key_path"
        sudo chmod 644 "$key_path"

        echo "Key downloaded and installed: $key_path"
    fi
    # Install the .sources file
    sudo install -v -o root -g root -m 644 "$file" "$sources_destdir"
    echo "Installed: $(basename "$file")"
done

# Update package lists
echo "🔄 Updating APT sources..."
sudo apt update

# Remove not needed packages
sudo apt remove -y --autoremove --ignore-missing $(tr '\n' ' ' < "$pkgmgmt/remove_packages.list")

# Install missing packages
sudo apt install -y --ignore-missing $(tr '\n' ' ' < "$pkgmgmt/install_packages.list")

# Flatpaks
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y $(tr '\n' ' ' < "$pkgmgmt/flatpak.list")
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
dconf load / < "$chezmoi_dir/dconf_settings_dump.dconf"
