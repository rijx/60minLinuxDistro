60minLinuxDistro
=========

A brief walkthrough on how-to get into building minimal Linux setups.

  - Creating a bootable disk / partition setup
  - Building the Linux kernel
  - Fabricating your own hello world initrd (quick 'n' dirty)
  - Installing and configuring grub

Creating your own Linux distribution is often claimed to be a very hard task. It is however surprisingly easy if you have the programming skills to write your own package manager and other tools you desire in your own distribution.

##### Step 1: Creating a bootable disk / partition setup
We will need a partition to store our kernel, initrd and grub files. This can either be a directory on the main system's partition or a dedicated /boot partition.

I decided to dedicate a small (50MB) partition as I had challenged myself to make a small working distro running entirely from initrd, so I wouldn't even need a system partition.

You can use any partition utility you like to do this. I personally tend to go with fdisk but there are oh so many and even I don't know all the pros and cons of them, so just use what you're comfortable with if you want to know what I recommend.

**The partition should have the BE flag and be set to bootable**

You'll want to use ext2 if you are dedicating a partition for a multitude of reasons. You can format the newly created partition to ext2 using this command: (**remember to substiture /dev/sda1 or you might wipe import data!**)

```sh
mke2fs -m 0 -L /boot -j /dev/sda1
```

If you are not dedicating a partiton, I'd recommend just using ext4 without any fancy parameters:

```sh
mkfs -t ext4 /dev/sda1
```

##### Step 2: Building the Linux kernel (you can also use a tutorial online for this step)
*Note: the kernel source code and assets produced by the compiling process can become quite big, make sure to conduct this step somewhere with enough disk space.*

##### Step 2.1: Downloading the kernel source code
First off download the desired kernel's source code at kernel.org and extract it somewhere. Picking the latest stable releae is usually safe enough.

```sh
wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.15.1.tar.xz
tar xJvf linux-3.15.1.tar.xz
cd linux-3.15.1
```

Pretty generic method of downloading and extracting. You can of course use a regular webbrowser to download the kernel source and extract it using a graphical extracting tool. No harm in doing either way.

##### Step 2.2: Configuring the kernel (can in theory be skipped)
*Note: if you have no clue what the configuration options means and have no intend to even bother looking their meaning up, just skip this step*

Requirements for this step is that you have the ncurses library. On my Ubuntu live CD environment I would run the following command to install it:

```sh
sudo apt-get install libncurses-dev
```

You can easily find the instructions for other distributions using an internet search engine.

Using ncurses we can now configure the kernel in a text-based user interface. Run the following command: (while still being in the kernel-<version> folder)

```sh
make menuconfig
```

It should look more or less like this:  
![screenshot](http://i.imgur.com/FATUbpZ.png)

You can look up the individual purpose of every option online.

##### Step 2.3: Building the kernel image (you *could* copy a kernel (vmlinuz) from another distribution, but I'd personally discourage doing that)

You'll need build tools like gcc and make for this. Often distributions ship grouped packages containing all of these tools requiring only one group package to be installed.

**Substitute 8 with the amount of cores / threads you want to allocate to the compilation process**

```sh
make bzImage -j8
```

When it's done and it doesn't show any (fatal) errors (warnings are ok) you can copy the bzImage from arch/x86/boot/ to the partition we created earlier. Like so:

```sh
cp arch/x86/boot/bzImage /mnt/boot/vmlinuz # vmlinuz is the generic name for bzImage
```

##### Step 3: Fabricating your own hello world initrd (quick 'n' dirty)
When I was new to this entirely I had a look at Linux From Scratch, but what bothered me most was having to compile a million things just to get a hello world. I'll show you how to get any file into your initrd acting as init using ldd.

It'd make sense to create and enter into a directory for this procedure.

```sh
mkdir initrd
cd initrd
```

##### Step 3.1: Copy, download or compile the binary you want as init
In my case I decided to bluntly copy /bin/bash (dash in fact) from this Ubuntu Live CD.

```sh
cp /bin/bash ./init
```

##### Step 3.2: Determine what we need to make it work
This is fairly straightforward ldd usage. You can find tons of information on ldd online, but here's a nice bash spaghetti command to do all the hard work. Make sure to be inside the working directory for our initrd.

```sh
for x in $(ldd ./init | awk '{print $3}' | grep ^/); do mkdir .$(dirname $x); cp $x .$x; done
```

##### Step 3.3: Test it!
There's a very simple way to test our initrd filesystem: try chroot into it!

```sh
cd ..
chroot initrd /init
```

If you copied bash like I did and it looks like nothing happens when you run the chroot command it in fact did, but you can't notice the difference because you already were in bash.

If it didn't print any output at all and just returned to the shell prompt, you should be able to run `exit` and still be in bash (but outside the chroot). Alternatively you can just try `ls /` and it will likely fail, or if you copied `ls` it will print the contents of your chroot directory.

##### Step 3.4: Create the actual image
The initrd image is in fact a gzipped cpio (newc format) archive. While inside the initrd working directory you can run these commands to achieve this:

```sh
find | cpio -H newc -ov | gzip --best -c - > ../initrd.img
```

##### Step 3.4: Copying the image to the boot directory
You can now copy or move the initrd.img to the earlier determined boot directory. In my case:

```sh
mv ./initrd.img /mnt/boot/initrd.img
```

##### Step 4: Installing and configuring grub
*Note: you'll need grub-install, use your package manager or if you're as lazy as I am you just use a live CD with such tools (usually 'rescue' CDs)*

**substitute /mnt/boot by your mount path + boot directory and /dev/sda with your disk that should have the grub *bootloader***

```sh
grub-install --boot-directory /mnt/boot /dev/sda
```

This will install grub into your Master Boot Record and the loadable grub modules into the boot directory. If it shows any error, you better get yourself a can of coffee and start Googling! (read: grub is a bitch)

The last thing we'll have to do is create a grub configuration file. Doing this manually really isn't that much work. Setting up /etc/grub.d and all that is not exactly desirable considering our goal (minimal system).

**Make sure to omit /boot/ in the menuentry parameters when you use a dedicated /boot partition**

```sh
cat > /mnt/boot/grub/grub.cfg << "EOF"
set default=0
set timeout=5

menuentry "My supercool minimal distro" {
    linux /boot/vmlinuz ro
    initrd /boot/initrd.img
}
EOF
```

License
----

This instruction paper is licensed under the CC0 (1.0) meaning no rights are reserved. The license can be viewed at https://creativecommons.org/publicdomain/zero/1.0/ or the LICENSE file in the repository.

