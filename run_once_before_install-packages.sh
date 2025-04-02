#!/bin/bash
set -e

# Install missing packages
for pkg in $(cat package-list.txt); do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Installing $pkg..."
        sudo apt-get install -y $pkg
    else
        echo "$pkg is already installed."
    fi
done
