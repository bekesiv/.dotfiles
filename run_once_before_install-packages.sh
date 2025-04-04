#!/bin/bash
set -e

chezmoi_dir="$HOME/.local/share/chezmoi"
pkgmgmt="$chezmoi_dir/package_management"
files_dir="$chezmoi_dir/files"
sources_destdir="/etc/apt/sources.list.d/"

# Custom Locale
sudo install -v -o root -g root -m 644 "$files_dir/hu_HU_custom" "/usr/share/i18n/locales/hu_HU_custom"
sudo localedef -i hu_HU_custom -f UTF-8 hu_HU.UTF-8@custom

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
fonts_dir="$HOME/.local/share/fonts/JetBrains/TrueType"
if [ ! -d "$fonts_dir" ]; then
    echo "Installing JetBrains Mono Nerd Font..."
    mkdir -p "$fonts_dir"
    cd "$fonts_dir"
    wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -o JetBrainsMono.zip
    rm JetBrainsMono.zip
    # Refresh font cache
    fc-cache -fv
    echo "JetBrains Mono Nerd Font installed successfully!"
fi

# Oh-My-Posh
type oh-my-posh || curl -s https://ohmyposh.dev/install.sh | bash -s

# eCalc
github_dir="$HOME/work/github"
if [ ! -d "$github_dir" ]; then
    mkdir -p "$github_dir"
    cd "$github_dir"
    git clone git@github.com:bekesiv/ecalc.git
    cd ecalc/install
    ./make_installer.sh   
fi

# Brave Browser
type brave-browser || curl -fsS https://dl.brave.com/install.sh | sh

# TeamViewer
type teamviewer
if [ $? -ne 0 ]; then
    wget -P "$HOME/Downloads" "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
    sudo dpkg -i "$HOME/Downloads/teamviewer_amd64.deb"
fi

#Gnome settings
dconf load / < "$chezmoi_dir/dconf_settings_dump.dconf"

# Flatpak does not respect gtk cursors
flatpak --user override --filesystem=/home/$USER/.icons/:ro
flatpak --user override --filesystem=/usr/share/icons/:ro

#TODO: Gnome extensions and their configurations
#TODO: flatpak apps configuration
#TODO: VSCode extensions and configurations
#TODO: Printing
#TODO: Custom Color Profie
#TODO: Wine
