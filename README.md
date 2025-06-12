# Pumice
![pumice-penguin](https://github.com/user-attachments/assets/711c80a3-d09b-48d8-ae1e-c868921a3238)

Pumice based on Rocky Linux 10, based on: [this great resource](https://git.resf.org/sig_core/rocky-kiwi-descriptions/src/branch/r10). A customised Rocky Linux install to my liking and for you to use, modify and make into your own.

By default you'll get a very basic Gnome install. I use this as a daily driver on a bunch of systems.

It should work out of the box on most hardware. I've included a lot of firmware packages --which could be removed to save space-- and the kernel should have drivers for most hardware. 

Dark mode is enabled by default and Cockpit is installed as well. Open ```https://localhost:9090``` in a browser post-install to easily manage the system or virtual machines and such.

I use Flatpak a lot so there are not many default apps installed. Just use the store to install what you need. Both ```epel``` and ```el repo``` repositories have been enabled.

For Gnome extensions I suggest using the Gnome extension manager app found on Flathub to manage them.

Building will be very straight forward on any ```dnf``` system and on most other distro's as well, all you need is ```podman```.

On other platforms like macOS and Windows it is possible too but out of the scope for me. I've tested this on RHEL 9/10-beta, CentOS Stream 10, Alma 9/10-beta and Rocky 9 without issues. I'm very impressed with ```kiwi``` and how easy it is to build an almost spin worthy customised iso in minutes. 

## Initial setup:
```
sudo dnf install -y podman git
git clone https://github.com/zearp/pumice-rocky && cd pumice-rocky
```
## Disable SELinux:
```
sudo setenforce permissive
```

## Customise packages and file system:
```
sudo nano config.xml && ls -lha root/
```
## Pull the Rocky Linux image and enter it:
```
sudo podman pull quay.io/rockylinux/rockylinux:10
sudo podman run --privileged --rm -it -v /dev:/dev -v $PWD:/code:z -w /code quay.io/rockylinux/rockylinux:10 /bin/bash
```

## Building:
Run these commands inside the downloaded image:
```
rpm -i https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
dnf -y install epel-release && dnf -y install kiwi policycoreutils && dnf -y --refresh update
kiwi-ng --type=iso --profile="Pumice" --color-output system build --description="." --target-dir ./outdir
```

> You can track progress by tailing the log file in another terminal: ```tail -f outdir/build/image-root.log```

## Finishing up:
Exit with ```exit``` and copy the generated image from ```outdir```.

Podman leaves things behind, to clean up the mess run:
```
sudo podman system prune --all --volumes --force
```

# Tip and tricks:
- You can build multiple images without exiting if you change the output folder in the ```kiwi-ng``` command
- /etc/rc.d/rc.local is used to run some firstboot commands and removes itself
- You can customise the file system by adding, removing or eding files in the ```root``` folder
- Read the ```kiwi``` docs: https://osinside.github.io/kiwi/image_description/elements.html
