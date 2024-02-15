# Pumice
![pumice](https://github.com/zearp/pumice/assets/63272687/cff79de2-c50d-454f-ac3e-356605e24398)

My spin on Rocky Linux. Nothing fancy. Bare bones with only the things I need and want. The aim of this repo is to have my stuff easily available to myself and anyone interested. It is essentially a kickstart file that can be modified to suit your needs and build an iso with. Compared to a normal Rocky Linux dark mode is enabled by default, third party repo's been added and a different (minimal) selection of packages is used. Kickstarts are a great way to customise Rocky Linux. The iso can be installed without an active internet connection.
<details>
  <summary>Packages:</summary>
  
  - GUI Stuff:
    - Cockpit, manage stuff (remotely) from your browser
    - Eye of Gnome image viewer
    - Evince document viewer
    - Flatseal to manage Flatpak permissions
    - gedit, simple text editor
    - Gnome disk utility
    - Gnome font vieuwer
    - Gnome schreenshot tool
    - Gnome software centre
    - Gnome system monitor
    - Gnome terminal
    - Gnome tweaks
    - Nautilus file manager
    - Plymouth spinner boot theme
  - Shell utils:
    - bat 🦀
    - btop
    - eza 🦀
    - grubby
    - htop
    - nano
    - nvme-cli
    - pciutils
    - pfetch 🦀
    - usbutils
    - ripgrep 🦀
    - rsync
    - wget
    - zsh
    - and many others!
  - Extra repo's:
    - RPM Fusion
    - EPEL
    - El Repo
    - Flatpaks via the Gnome software centre

</details>

#### Contents:
* [Installation](#installation)
* [Post install](#post-install)
* [Updating](#updating)

### Installation
1. Disable SELinux:
   ```sh
   sudo setenforce 0
   ```
2. Install required packages:
   ```sh
   sudo dnf -y --refresh update && sudo dnf -y install epel-release
   sudo dnf -y install --nogpgcheck rpmfusion-free-release \
   https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
   sudo dnf -y install mock mock-rpmfusion-free mock-rpmfusion-nonfree
   ```
3. Add yourself to the mock group and logout:
   ```sh
   sudo usermod -a -G mock $USER && exit
   ```
4. Log back in and create ```/etc/mock/pumice.cfg``` and paste in the following:
   ```sh
   include('rocky+epel-9-x86_64.cfg')
   include('templates/rpmfusion_free-epel.tpl')
   include('templates/rpmfusion_nonfree-epel.tpl')
   config_opts['root'] = "pumice-9-{{ target_arch }}"
   config_opts['description'] = 'Pumice 9'
   ```
5. Initialise and enter the mock environment:
   ```sh
   mock -r pumice --init --nobest
   mock -r pumice --install lorax-lmc-novirt nano pykickstart git
   mock -r pumice --shell --isolation=simple --enable-network
   ```
   <sup>The --nobest option is not strickly needed, just sometimes its fails to initialise and this option prevents/fixes it.</sup>
   
6. From inside the mock enviroment download the kickstart file and edit, then flatten it:
   ```sh
   git clone https://github.com/zearp/pumice && cd pumice/kickstart
   nano pumice.ks
   ksflatten -c pumice.ks -o flat.ks
   ```
7. Generate the iso with the following command:
   ```sh
   livemedia-creator --ks flat.ks --no-virt --resultdir /var/lmc --project="Pumice" --make-iso \
   --volid Pumice-9 --iso-only --iso-name Pumice-9-x86_64.iso --releasever=9 --nomacboot && exit
   ```
8. When it's done we'll move the iso file to the current directory and clean up:
   ```sh
   sudo mv /var/lib/mock/pumice-9-x86_64/root/var/lmc/Pumice-9-x86_64.iso .
   sudo chown $USER:$USER Pumice-9-x86_64.iso
   mock -r pumice --scrub=all
   ```
9. Re-enable SELinux:
   ```sh
   sudo setenforce 1
   ```
That's all, you can now use the iso file to install.

# Post install
Some (hopefully) useful post install stuff.

### Remove left overs.
```
sudo dnf -y remove anaconda\*
sudo dnf clean all
```
Optionally if you just want to use ```dnf``` remove flatpak, flatseal and gnome-software.
```
sudo dnf -y remove flatpak\* flatseal gnome-software
```
On AMD iGPU/GPU systems the Intel driver can be removed too:
```
sudo dnf -y remove intel-media-driver
```

### Verify SELinux
Security is paramount so let's make sure SELinux is running in ```enforcement``` mode. run the following command to check the current enforcement status:
```
sudo getenforce
```
If it shows ```Enforcing``` we don't need to do anything. If it shows ```Permissive``` run the following command, reboot and check the enforcement status again:
```
sudo fixfiles onboot
```
For more information please refer to [this](https://docs.rockylinux.org/guides/security/learning_selinux) page.

### Check for and install firmware updates
Run these commands one by one and only update if you want to. If everything is workign fine it might not be needed to update anything. Refer to the release notes and change logs for each firmware update.
```
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
## make sure you need/want these updates!
sudo fwupdmgr update
```
### Cockpit
Cockpit is a nice web frontend to do basic monitoring and managements tasks. I suggest using it not only on servers but anywhere and also when you need to troubleshoot issues. It has some great utilities and access to log files and services and so on. The default location is ```https://localhost:9090```. For more information please read [this](https://www.redhat.com/sysadmin/intro-cockpit) page.

To get started run the following commands:
```
sudo dnf -y install cockpit && sudo systemctl enable --now cockpit.socket
```
You can now open ```https://localhost:9090``` in your browser. It is possible to use a Let's encrypt certiffcate using ```certbot```.

### El Repo kernel
Sometimes you need a more modern kernel, for example very recent hardware. We can use the El Repo repository for that. The only cost is that secure boot will no longer function. To enable and install El Repo's 6.x kernel run the following commands:
```
sudo dnf install kernel-lt kernel-lt-modules-extra
```
Now reboot and press the escape key to show the grub menu and select the new kernel from the list.

We can replace ```lt``` for ```ml``` if you want even newer mainline kernel as opposed to the long term support kernel. If everything works well run the following commands to set a new default kernel and remove the old default kernel:
```
sudo echo -e "DEFAULTKERNEL=kernel-lt-core\nUPDATEDEFAULT=yes" | sudo tee /etc/sysconfig/kernel
sudo dnf -y remove kernel kernel-core
```
You can also modify the kickstart to build your iso with a 6.x kernel instead. For more information see [this](https://elrepo.org/wiki/doku.php?id=kernel-lt) page. In order to compile modules it may be needed to install the ```kernel-lt-devel``` package.

### AMD Drivers
Only works with the stock 5.x kernels. This will give you OpenCL and some additonal video encoders/decoders. Download the latest installer rpm [here](https://repo.radeon.com/amdgpu-install/latest/rhel/9.4/) and install it:
```
sudo rpm -i amdgpu-install*.rpm
sudo amdgpu-install --usecase=graphics,multimedia,dkms,opencl
sudo reboot
```

### Firefox
For hardware encoding set ```media.ffmpeg.vaapi.enabled``` and ```gfx.webrender.all``` to true in ```about:config``` and restart Firefox. To test check cpu/gpu usage in ```nvtop``` or ```intel_gpu_top```. The latter may have to be compiled from source or if you dare manually install the Fedora package (```igt-gpu-tools```). If you use the Flatpak version it may also be needed to run Firefox in Wayland mode by adding an enviroment option using Flatseal. This shouldn't be needed anymore.

It is recommended to block unsupported codecs using [this](https://addons.mozilla.org/en-US/firefox/addon/enhanced-h264ify) add-on. For example, my NUC 8 does not support AV1 but does support VP8/9 and h264. Setting the add-on to only block AV1 tries to makes it so videos are being decoded by the gpu. To see which codecs are supported you can use the ```vainfo``` command.

You will see entries like ```VAProfileH264``` and so on. Disable any you don't have but are listed in the ```enhanced-h264ify``` add-on. This way Firefox won't be rendering videos ususing the cpu (as much). If you run into a video that doesn't play disabling the add-on and refreshing the page should fix it and let Firefox use the cpu to render the video.

While we're at it let's install [uBlock Origin](https://addons.mozilla.org/en-GB/firefox/addon/ublock-origin) to block some ads and trackers.

### Misc.
- Change shell to zsh:
  ```sh
  sudo usermod --shell /usr/bin/zsh $USER
  ```
- Less flickering when booting and old school network interface names:
  ```sh
  sudo grubby --update-kernel=ALL --args="loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 biosdevname=0 net.ifnames=0"
  ```
- Sort apps alphabetically, logout and in to apply, don't use sudo here:
  ```sh
  gsettings set org.gnome.shell app-picker-layout "[]"
  ```
- Flatpak dark mode fix, add an enviroment variable using Flatseal:
  ```sh
  GTK_THEME=Adwaita-dark
  ```
- Sync login screen settings (gdm):
  ```sh
  sudo cp ~/.config/monitors.xml /var/lib/gdm/.config/
  ```
- Remove brightness slider (when applicable):
  ```sh
  sudo grubby --update-kernel ALL --args acpi_backlight=none
  ```
- Enable 8bitdo xbox gamepad:
  ```sh
  sudo nano /etc/udev/rules.d/99-8bitdo-xinput.rules
  ```
  ```
  ACTION=="add", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="310a", RUN+="/sbin/modprobe xpad", RUN+="/bin/sh -c 'echo 2dc8 310a > /sys/bus/usb/drivers/xpad/new_id'"
  ```
  ```sh
  sudo udevadm control --reload-rules && sudo udevadm trigger
  ```
- Compiling kernel modules:
  ```sh
  sudo dnf -y install kernel-devel dkms
  ```
- Disable sleep/suspend completely, disable it in Gnome settings first or else you get false positive notifications about impending suspends. Re-run with ```unmask``` to re-enable:
  ```sh
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ```
- The firewall (```firewalld```) is enabled and allowing; cockpit and ssh. For some basics on opening ports/services and more information please refer to [this](https://docs.rockylinux.org/guides/security/firewalld-beginners) page.

# Updating
Easy mode!
```
sudo dnf --refresh update
```
