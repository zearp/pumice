#!/bin/bash
#
set -euxo pipefail

# functions
#
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# make sure the crb repo is enabled
#
dnf -y config-manager --set-enabled crb

# selinux, needed for kde and maybe others
#
setsebool -P selinuxuser_execmod 1

# set a hostname
#
echo "pumice" > /etc/hostname

# clear machine id
#
truncate -s 0 /etc/machine-id

# grub
#
echo "GRUB_DEFAULT=saved" >> /etc/default/grub

# services
#
systemctl enable chronyd.service
systemctl enable systemd-oomd.service
systemctl enable systemd-resolved.service
systemctl mask kdump.service

# persistent logs
#
mkdir -p /var/log/journal

# clear root password
#
passwd -d root
passwd -l root

# we are live
#
echo 'livesys_session="gnome"' > /etc/sysconfig/livesys
sed -i "s/org.fedoraproject.AnacondaInstaller/anaconda/" /usr/share/applications/liveinst.desktop

# set default boot target (gui or cli)
#
systemctl set-default graphical.target
#systemctl set-default multi-user.target

# apply custom gnome stuff in /etc/dconf/db/local.d/99-pumice
#
dconf update

# setup flathub repo
#
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# dnf stuff
#
dnf -y config-manager --set-enabled crb elrepo elrepo-extras elrepo-kernel epel
dnf -y --refresh update && dnf clean all && dnf makecache

exit 0
