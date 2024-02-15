# pumice.ks
# https://github.com/zearp
#
bootloader --location=none
clearpart --all
firewall --enabled --service=mdns
keyboard 'us'
lang en_US.UTF-8
network  --bootproto=dhcp --device=link --activate
part / --fstype="ext4" --size=8192
rootpw --iscrypted --lock locked
selinux --enforcing
services --disabled="ModemManager,sshd" --enabled="NetworkManager"
shutdown
timezone Europe/Amsterdam
url --url="http://dl.rockylinux.org/stg/rocky/9/BaseOS/$basearch/os/"
xconfig  --startxonboot
zerombr

# fix dns inside mock
#
%post --nochroot
cp --remove-destination /etc/resolv.conf /mnt/sysimage/etc/resolv.conf
%end

# setup repos
#
repo --name="BaseOS" --baseurl=http://dl.rockylinux.org/stg/rocky/9/BaseOS/$basearch/os/ --cost=200
repo --name="AppStream" --baseurl=http://dl.rockylinux.org/stg/rocky/9/AppStream/$basearch/os/ --cost=200
repo --name="CRB" --baseurl=http://dl.rockylinux.org/stg/rocky/9/CRB/$basearch/os/ --cost=200
repo --name="extras" --baseurl=http://dl.rockylinux.org/stg/rocky/9/extras/$basearch/os --cost=200
repo --name="epel" --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch
repo --name="rpmfusion-free-release" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-el-updates-released-$releasever&arch=$basearch
repo --name="rpmfusion-nonfree-release" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=nonfree-el-updates-released-$releasever&arch=$basearch
repo --name="elrepo" --baseurl=https://elrepo.org/linux/elrepo/el9/$basearch/
repo --name="elrepo-extras" --baseurl=https://elrepo.org/linux/extras/el9/$basearch/
repo --name="elrepo-kernel" --baseurl=https://elrepo.org/linux/kernel/el9/$basearch/

# enable repos
#
%post
dnf config-manager --enable crb elrepo elrepo-extras elrepo-kernel extras
%end

# include needed bits from the stock kickstart
#
%include include/rocky.ks

# intel tweaks, remove enable_guc for 5th gen and older and set to 2 for 6th to 8th gen
#
%post
echo "options i915 enable_guc=3 enable_fbc=1 fastboot=1" | tee /etc/modprobe.d/i915.conf
echo "dev.i915.perf_stream_paranoid = 0" | tee /etc/sysctl.d/98-i915.conf
%end

# setup darkmode and wallpaper
#
%post
mkdir -p /usr/share/backgrounds
wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/pumice/main/assets/wallpaper.jpg -O /usr/share/backgrounds/pumice.jpg
mkdir -p /etc/skel/.config/gtk-3.0
cat > /etc/skel/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name = Adwaita-dark
EOF
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/01-darkmode << EOF
[org/gnome/desktop/interface]
gtk-theme='Adwaita-dark'
color-scheme='prefer-dark'
EOF
cat > /etc/dconf/db/local.d/02-background << EOF
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/pumice.jpg'
picture-options='scaled'
EOF
cat > /etc/dconf/db/local.d/03-apptimeout << EOF
[org/gnome/mutter]
check-alive-timeout='10000'
EOF
cat > /etc/dconf/db/local.d/04-gnome-software << EOF
[org.gnome.software]
download-updates='false'
EOF
dconf update
%end

# enable persistent systemd logs
# creating the directory is enough to trigger the default "auto" configuration into keeping the logs between reboots
#
%post
mkdir /var/log/journal
%end

# setup flathub
#
%post
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
%end

# disable gnome software centre
#
# not working for gnome-software auto starting: systemctl mask packagekit.service
#
# nuclear option:
#rm /etc/xdg/autostart/org.gnome.Software.desktop
#touch /etc/xdg/autostart/org.gnome.Software.desktop
#chattr +i /etc/xdg/autostart/org.gnome.Software.desktop
#%end

# setup some misc stuff
#
%post
# sets the spinner theme, requires the plymouth-theme-spinner package
plymouth-set-default-theme spinner -R
# fixes flatseal not saving overrides properly
mkdir -p /etc/skel/.local/share/flatpak/overrides
# fix mpv not always using hardware encoding
mkdir -p /etc/skel/.config/mpv
echo "hwdec=auto" | tee /etc/skel/.config/mpv/mpv.conf
# fetch .zshrc
rm /etc/skel/.zshrc
wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/pumice/main/assets/dot_zshrc -O /etc/skel/.zshrc
# fetch pfetch
wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/pumice/main/assets/pfetch -O /usr/local/bin/pfetch
chmod 755 /usr/local/bin/pfetch
# monitor the waves
rpm -i https://kojipkgs.fedoraproject.org/packages/wavemon/0.9.4/4.fc38/x86_64/wavemon-0.9.4-4.fc38.x86_64.rpm
# bring back eza
rpm -i https://kojipkgs.fedoraproject.org/packages/rust-eza/0.19.3/1.el9/x86_64/eza-0.19.3-1.el9.x86_64.rpm
%end

# setup some services
#
%post
systemctl disable NetworkManager-wait-online
systemctl enable --now acpid
systemctl enable --now firewalld
systemctl enable --now fstrim.timer
systemctl enable --now sshd
systemctl enable --now thermald
systemctl enable --now tuned
tuned-adm profile desktop
%end

# el repo
#
#%post
#echo -e "DEFAULTKERNEL=kernel-lt-core\nUPDATEDEFAULT=yes" | tee /etc/sysconfig/kernel
#%end

# a little maintenance and cleaning
#
%post
dnf -y remove gnome-tour rocky-backgrounds gnome-shell-extension-background-logo
dnf clean all
dnf makecache
%end

# package selection
#
%packages
@^minimal-environment
@anaconda-tools
#@base-x
@core
@fonts
#@gnome-desktop
# uncomment if you plan to run in a virtual machine
#@guest-desktop-agents
@hardware-support
#@internet-browser
@multimedia
@networkmanager-submodules
aajohan-comfortaa-fonts
acpid
anaconda
anaconda-install-env-deps
anaconda-live
#baobab
bat
bc
#broadcom-wl
btop
chkconfig
chrome-gnome-shell
#cockpit
dracut-live
efi-filesystem
efibootmgr
efivar-libs
elrepo-release
eog
epel-release
evince
ffmpeg
file-roller-nautilus
flatseal
gdm
gedit
glibc-all-langpacks
#gnome-calculator
#gnome-characters
gnome-disk-utility
# uncomment if you don't intend to use the flatpak extension manager app
#gnome-extensions-app
#gnome-font-viewer
gnome-keyring
#gnome-logs
gnome-screenshot
gnome-session-wayland-session
gnome-software
gnome-system-monitor
gnome-terminal
gnome-tweaks
google-noto-emoji-color-fonts
#gparted
grub2-common
grub2-efi
grub2-efi-*64
grub2-efi-*64-cdboot
grub2-pc-modules
grub2-tools
grub2-tools-efi
grub2-tools-extra
grub2-tools-minimal
grubby
#htop
initscripts
# 5th gen and older should use libva-intel-driver or libva-intel-hybrid-driver
intel-media-driver
kernel
kernel-core
#kernel-devel
#kernel-headers
kernel-modules
kernel-modules-extra
kernel-tools
# el repo
#kernel-lt
#kernel-lt-core
#kernel-lt-modules
#kernel-lt-modules-extra
#kernel-lt-tools
libavcodec-freeworld
libva-utils
memtest86+
mlocate
mpv
nano
nautilus
ncdu
nvme-cli
#nvtop
pciutils
#piper
plymouth
plymouth-theme-spinner
ripgrep
rpmfusion-free-release
rpmfusion-nonfree-release
rsync
#seahorse
shim-*64
syslinux
tio
thermald
tuned
unzip
usbutils
wget
zsh
zsh-autosuggestions
zsh-syntax-highlighting
-@dial-up
-@input-methods
-@standard
-gfs2-utils
-kmod-kvdo
-reiserfs-utils
-shim-unsigned-*64
-vdo
%end

# fix for dns inside mock, the installed system doesn't need it
%post
rm /etc/resolv.conf
%end
