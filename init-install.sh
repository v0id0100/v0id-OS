#!/bin/bash

# Welcome:
echo "Hello and welcome to the vArch Linux setup script! This script will help you customize your desktop environment and install some useful applications. Let's get started!"
echo "--------------------------------------------------"

# 1. Set up user:
read -p "Do you want to set up a new user and delete the default 'vArch' user? (y/n): " answer

if [[ "$answer" == "y" ]]; then
    echo "Proceeding with user setup..."
    read -p "Enter the new username: " new_username
    sudo useradd -m -G wheel -s /bin/bash "$new_username"
    echo "User $new_username created and added to the wheel group."

    # Set password for the new user
    sudo passwd "$new_username"

    # Delete the default user
    sudo userdel -r vArch
    echo "Default user 'vArch' deleted."
else
    echo "Skipping user setup."
fi

echo "--------------------------------------------------"

# 2. Set up hostname:
read -p "Do you want to set up a new hostname? (y/n): " answer

if [[ "$answer" == "y" ]]; then
    echo "Proceeding with hostname setup..."
    read -p "Enter the new hostname: " new_hostname
    echo "$new_hostname" | sudo tee /etc/hostname && sudo hostnamectl set-hostname "$new_hostname"
    echo "Hostname updated to $new_hostname."
else
    echo "Skipping hostname setup."
fi

echo "--------------------------------------------------"

# 3. Terminal Customizations:
read -p "Do you want to install terminal customizations (zsh, Oh My Zsh, and plugins)? (y/n): " answer

if [[ "$answer" == "y" ]]; then
    echo "Changin distro name..."
    sed -i 's/GRUB_DISTRIBUTOR="vArch"/GRUB_DISTRIBUTOR="vArch"/' /etc/default/grub

    echo "Proceeding with terminal customizations..."
    echo "Installing zsh..."
    sudo pacman -S --noconfirm zsh

    echo "Installing Oh My Zsh..."
    # Running the installer unattended so it doesn't interrupt the script
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    echo "Installing plugins for Oh My Zsh..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

    # Set up the .zshrc file with the plugins
    echo "Configuring .zshrc..."
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)/' ~/.zshrc
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' ~/.zshrc
else
    echo "Skipping terminal customizations."
fi

echo "--------------------------------------------------"

# 4. Custom Apps:
read -p "Do you want to install custom apps (Firefox, Thunderbird, WebAppHub, ProtonVPN, VirtualBox, VS Code)? (y/n): " answer

if [[ "$answer" == "y" ]]; then
    echo "Proceeding with custom apps installation..."

    echo "Installing Firefox..."
    sudo pacman -S --noconfirm firefox

    echo "Installing Thunderbird..."
    sudo pacman -S --noconfirm thunderbird

    echo "Installing WebAppHub..."
    flatpak install flathub org.pvermeer.WebAppHub -y

    echo "Installing ProtonVPN..."
    sudo pacman -S --noconfirm proton-vpn-gtk-app

    echo "Installing VirtualBox..."
    sudo pacman -S virtualbox virtualbox-host-modules-arch --noconfirm

    echo "Installing Visual Studio Code..."
    sudo pacman -S --noconfirm code
else
    echo "Skipping custom apps installation."
fi

echo "--------------------------------------------------"

# 5. Desktop Customization:
read -p "Do you want to install the desktop customization (WhiteSur Theme & Icons)? (y/n): " answer

if [[ "$answer" == "y" ]]; then
    echo "Installing desktop environment customizations..."
    
    # Set a fallback global theme first
    plasma-apply-lookandfeel -a org.kde.breezedark.desktop

    # --- 1. Install WhiteSur Icons (Fixes the "Icon theme not found" error) ---
    echo "Downloading WhiteSur Icon Theme..."
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme
    cd /tmp/WhiteSur-icon-theme
    echo "Installing WhiteSur icons..."
    ./install.sh
    
    # --- 2. Install WhiteSur KDE Desktop Theme ---
    echo "Downloading WhiteSur Apple Theme..."
    git clone https://github.com/vinceliuice/WhiteSur-kde.git /tmp/WhiteSur-kde
    cd /tmp/WhiteSur-kde

    echo "Installing WhiteSur dependencies..."
    sudo pacman -S --needed sassc kvantum-qt5 kvantum --noconfirm
    
    echo "Installing WhiteSur theme..."
    ./install.sh

    echo "Applying WhiteSur Dark Global Theme..."
    plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur-dark --resetLayout
    plasma-apply-colorscheme WhiteSurDark
    
    # --- 3. Headless Kvantum Configuration (No GUI popups!) ---
    echo "Configuring Kvantum application style cleanly..."
    mkdir -p ~/.config/Kvantum
    
    # Directly write to the config file so no GUI opens
    cat <<EOF > ~/.config/Kvantum/kvantum.kvconfig
[General]
theme=WhiteSur-dark
EOF

    # Force KDE to use Kvantum for Application Style via CLI
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file kdeglobals --group General --key widgetStyle kvantum
    else
        kwriteconfig5 --file kdeglobals --group General --key widgetStyle kvantum
    fi

    # Set the icon theme explicitly
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme WhiteSur-dark
    else
        kwriteconfig5 --file kdeglobals --group Icons --key Theme WhiteSur-dark
    fi

    echo "Resetting desktop layout to apply changes..."
    plasmashell --replace & disown

    echo "Changing Application Style to 'Oxygen'..."
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "oxygen"
    busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure

    echo "Changing Splash Screen to 'Breeze'..."
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme "org.kde.breeze.desktop"
    kwriteconfig6 --file ksplashrc --group KSplash --key Engine "KSplashQML"

    echo "Changing Application Launcher Icon to 'Breeze'..."
    sed -i 's|^icon=.*|icon=/usr/share/icons/breeze/places/16/start-here-kde-plasma.svg|g' ~/.config/plasma-org.kde.plasma.desktop-appletsrc

    echo "Cleaning up icon and plasma caches to ensure the new theme is applied correctly..."
    rm -rf ~/.cache/ico*
    rm -rf ~/.cache/plasma*
    systemctl --user restart plasma-plasmashell.service

    echo "Pinning essential apps to the panel..."
    bash add-apps-to-panel.sh
    
    echo "Cleaning up desktop configuration files to ensure a fresh start..."
    # Clean up installation files
    rm -rf /tmp/WhiteSur-kde
    rm -rf /tmp/WhiteSur-icon-theme
    echo "Desktop customization complete!"
else
    echo "Skipping desktop customization."
fi

echo "--------------------------------------------------"
echo "vArch Linux setup script finished! Please restart your system to ensure all changes take effect."

read -p "Prepare to reboot now? (y/n): " answer

if [[ "$answer" == "y" ]]; then
    echo "Rebooting now..."
    sudo reboot
else
    echo "Please remember to reboot your system as soon as possible to apply all changes."
fi