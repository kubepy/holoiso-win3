#!/bin/zsh
# Prepares ISO for packaging

# Remove useless shortcuts for now
mkdir /etc/holoinstall/post_install_shortcuts
mv /etc/skel/Desktop/Return.desktop /etc/holoinstall/post_install_shortcuts

# Prepare thyself
chmod +x /etc/holoinstall/post_install/install_holoiso.sh
chmod +x /etc/holoinstall/post_install/chroot_holoiso.sh
chmod +x /etc/skel/Desktop/install.desktop
chmod 755 /etc/skel/Desktop/install.desktop

# Remove stupid stuff on build
rm /home/${LIVEOSUSER}/steam.desktop

# Add a liveOS user
ROOTPASS="holoconfig"
LIVEOSUSER="liveuser"

echo -e "${ROOTPASS}\n${ROOTPASS}" | passwd root
useradd --create-home ${LIVEOSUSER}
echo -e "${ROOTPASS}\n${ROOTPASS}" | passwd ${LIVEOSUSER}
echo "${LIVEOSUSER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${LIVEOSUSER}
chmod 0440 /etc/sudoers.d/${LIVEOSUSER}
usermod -a -G rfkill ${LIVEOSUSER}
usermod -a -G wheel ${LIVEOSUSER}
# Begin coreOS bootstrapping below:

# Init pacman keys
pacman-key --init
pacman -Sy

# Install desktop suite
pacman -Rcns --noconfirm pulseaudio xfce4-pulseaudio-plugin pulseaudio-alsa
pacman -Rdd --noconfirm sddm linux syslinux
pacman --overwrite="*" --noconfirm -S holoiso-main
mv /etc/pacman.conf /etc/pacold
cp /etc/holoinstall/post_install/pacman.conf /etc/pacman.conf
pacman --overwrite="*" --noconfirm -S holoiso-updateclient wireplumber flatpak packagekit-qt5 rsync unzip sddm-wayland dkms steam-im-modules systemd-swap ttf-twemoji-default ttf-hack ttf-dejavu pkgconf pavucontrol partitionmanager gamemode lib32-gamemode cpupower bluez-plugins bluez-utils
mv /etc/xdg/autostart/steam.desktop /etc/xdg/autostart/desktopshortcuts.desktop /etc/skel/Desktop/steamos-gamemode.desktop /etc/holoinstall/post_install_shortcuts
pacman --noconfirm -S base-devel

# Enable stuff
systemctl enable sddm NetworkManager systemd-timesyncd cups bluetooth sshd

# Download extra stuff
mkdir -p /etc/holoinstall/post_install/pkgs
wget $(pacman -Sp win600-xpad-dkms) -P /etc/holoinstall/post_install/pkgs_addon
wget $(pacman -Sp linux-firmware-neptune) -P /etc/holoinstall/post_install/pkgs_addon

# Download Kernels
wget $(pacman -Sp linux-neptune-61) -P /etc/holoinstall/post_install/pkgs
wget $(pacman -Sp linux-neptune-61-headers) -P /etc/holoinstall/post_install/pkgs

# Workaround mkinitcpio bullshit so that i don't KMS after rebuilding ISO each time and having users reinstalling their fucking OS bullshit every goddamn time.
rm /etc/mkinitcpio.conf
mv /etc/mkinitcpio.conf.pacnew /etc/mkinitcpio.conf 
rm /etc/mkinitcpio.d/* # This removes shitty unasked presets so that this thing can't overwrite it next time
mkdir -p /etc/mkinitcpio.d

# New HWSupport test packages
pacman -Syu --noconfirm mesa lib32-mesa lib32-vulkan-intel lib32-vulkan-radeon vulkan-intel vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver --config /etc/holoinstall/pre_install/testpacman.conf

# Remove this shit from post-build
rm -rf /etc/holoinstall/pre_install
rm /etc/pacman.conf
mv /etc/pacold /etc/pacman.conf
rm /home/.steamos/offload/var/cache/pacman/pkg/*
