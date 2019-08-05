# DM-Crypt-Helper-Scripts
Additional mount scripts for DM-Crypt containers

Script for comfortable create / mount DM-Crypt containers over sudo, make Crypted SWAP.

Use one command instead three command. Mount your containers under LiveCD with one easy step.


## Installation and requirements

0). Programs cryptsetup, sed, basename, losetup, dd, mkfs, shred, touch and bash must be installed (usually default)

Install package with tool fsstat.
For Fedora - `dnf install sleuthkit`

Optionally you can install sudo and tools for support other filesystems (ex btrfs, xfs).

1). download scripts to local system, for example to /opt (you can run script from any fs)

`cd /opt`

`wget https://github.com/Aminuxer/DM-Crypt-Helper-Scripts/raw/master/_dmc.sh`

`chmod +x _dmc.sh`

2). Optional step. Usage dm-crypt require high permissions.
Create sudo rules for start scripts under non-privileged users:

`# vi /etc/sudoers.d/myscripts-example`

`user1  ALL=(root)      NOPASSWD: /opt/_dmc.sh`

Without this step (ex. livecd like knoppix) manage cryptocontainers will require root permissions.

3). Run script with sudo :
`$ sudo /opt/_dmc.sh`

Start without parameters will show mini-help:

```
Usage: /opt/_dmc.sh <Path to Dm-Crypt container> [start|stop|create|make_loops] [Mount point] [cipher]
    Example: /opt/_dmc.sh ~/mysecrets.bin start /mnt/MyDisk aes-cbc-essiv:sha256
    create - make new container. Existing files don't touch for prevent data loss
    make_loops - create new loop-devices in /dev
```

## Create new crypto-container

You can create containers only in new files.
Script don't touch existing files when create method called.
In this case you see message "file /var/tmp/fs1.bin exist, usage existing files denied."

Run script with full path to new containers and use cli dialogs for create new container:

`$ sudo /opt/_dmc.sh /var/tmp/fs1.bin create`

```
----- CREATE NEW CryptoContainer ---------------------
You start to CREATE dm-crypt container. Continue (Yes/No)? Yes
OK, continue...
Enter internal volume label for new container: MyNewContainer1
Enter volume size (1048576, 1024K, 100M, 2G): 42M
Supported filesystems on your machine:
----------------------------------------------------------------------------------------------
/sbin/mkfs.btrfs    /sbin/mkfs.ext2   /sbin/mkfs.ext3   /sbin/mkfs.ext4    /sbin/mkfs.fat
/sbin/mkfs.hfsplus  /sbin/mkfs.minix  /sbin/mkfs.msdos  /sbin/mkfs.ntfs  /sbin/mkfs.reiserfs
/sbin/mkfs.vfat    /sbin/mkfs.xfs
----------------------------------------------------------------------------------------------
Enter filesystem type (ext2 as default): ext4
Fast fill container
0+0 records in
0+0 records out
0 bytes copied, 7.7594e-05 s, 0.0 kB/s
Enter passphrase for /dev/loop2: EnterYouStrongUberMegaPaSsW0rD~PhRAZe+Here
Shreding [42M] space on [/var/tmp/fs1.bin] ...   (please wait)
Formatting cryptocontainer...
mke2fs 1.44.6 (5-Mar-2019)
Creating filesystem with 43008 1k blocks and 10752 inodes
Filesystem UUID: 340138b4-b630-47c2-852c-bf57d3d7ca99
Superblock backups stored on blocks:
        8193, 24577, 40961

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

Label :: [fs1.bin] ; /var/tmp/fs1.bin --> /run/media/MyNewContainer1 ; [on /dev/loop2], SIZE: [42M]
----- New CryptoContainer mounted succesfully ! ---------
```

After this your container will already mounted and ready for usage.


## Start / mount cryptocontainer
Run script with full path to container and method stop:

`$ sudo /opt/_dmc.sh /var/tmp/fs1.bin start`

Normal mount will show this output:

```
----- Mount CryptoContainer [/var/tmp/fs1.bin] ---------------------
Cipher options: aes-xts-essiv:sha256 --hash sha512 --key-size 512
Enter passphrase for /dev/loop3: EnterYouStrongUberMegaPaSsW0rD~PhRAZe+Here
Command successful.
FS in container: ext4
Label :: [fs1.bin] ; /var/tmp/fs1.bin --> /run/media/MyNewContainer1 ; [on /dev/loop3]
----- Mount CryptoContainer Complete ! ---------
```
You must input passphrase "as one string", without misprints, errors or try editing.
Inputed symbols don't displayed.
Any error in passphrase will cause mount errors.


## Stop and unmount cryptocontainer
Run script with full path to container and method stop:

`$ sudo /opt/_dmc.sh /var/tmp/fs1.bin stop`

Normal shutdown will show this output:

```
----- Unmount CryptoContainer [/var/tmp/fs1.bin] --------------------
losetup: /dev/loop1
Check mount-point [/run/media/MyNewContainer1] and try remove empty dir
!! Remove mount-point /run/media/MyNewContainer1 !!
removed directory '/run/media/MyNewContainer1'
----- Unmount CryptoContainer Complete ! ---------
```
If any file from internal fs will be opened in external program, script stopped with umount erro message.
Close all files opened from container and try again.

##  FAQ
* What happens if i run `$ sudo /opt/_dmc.sh /var/tmp/fs1.bin` - command with only path to existing file ?
  - Script will try detect current status and propose mount / umount action. Mounted containr will try umount, unmounted - mount with passphrase request.

* What is method make_loops ?
  - This method for some old or livecd systems, where loopback devices not created at boot.
Use mknod util. Can be useful , if you try mount too many containers.

* Can script damage my trivial file if i try mount this as container ? ex _dmc.sh dsc0001.jpg ?
  - No. You cannot create passphrase for convert jpeg-file to FS-image by AES =) It's fantastic.
But you must have backups in any case.

* How to mount container in another mount point, for example, in path under /tmp, /home or other path ?
  - Use third parameter: `$ sudo /opt/_dmc.sh /var/tmp/fs1.bin start /tmp/mountpoint`

* I have container without volume label. How it important ?
  - Not important. Containers with unlabeled fs will mount to path like `/run/media/Disk_NoLABEL__fs1.bin` and only with parameter start. Mount container, see device name by `df` and change label for /dev/mapper/fs1.bin by `e2label` or similar tool.

* Can i mount some different copies of same container ?
  - Bad idea. This script rely to unique names of containers and internal FS labels.
  Data will not loss, but this behavior not tested deep. Also, this scenario more danger for mistakes;
  If need, rename old copy of container and mount this to another mountpoint. Make backups BEFORE this work.

* Can i make fsck or another service works for fs in container ?
  - Yes. Mount container with correct passphrase by script _dmc.sh. See device name by `df` command or command `mount`. umount this filesystem with `umount` system command (NOT by script !!). Start fsck for /dev/mapper/<virtual.device.name>
Force stop cryptodevice by call script with stop parameter.

* What is Cipher option - parameter 4 ?
  - If you have another or older dm-crypt container with other ciphers you can use this options for manual mount this. Syntax of this same as -c parameter for cryptsetup.

* Why used aes-xts-essiv:sha256 --hash sha512 --key-size 512 ?
  - This methods suitable for full-disk encryption, prevent many attacks against crypted partitions and supported in almost all linux distribus. More deep understand will require learn more about cryptography: https://wikipedia.org/wiki/Disk_encryption_theory
Disk encryption is one of hardest cryptograhy task - too many crypto-issues must be solved.

* Can i resize container, change passphrase or encryption method ?
  - By this script - No. You can create new container and copy files by `cp` / `mc` / `rsync`.
  
For make this convert on existing container you must strong understand how work dm-crypt, loopback devices and linux block devices / filesystems.
This work required accuracy; Make backups BEFORE start work;
Read this:
- https://wiki.gentoo.org/wiki/Dm-crypt
- https://geekpeek.net/resize-filesystem-fdisk-resize2fs/
- https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption
Test result and make backups again;

* What about crypto swap ?
  - Same as containers, but use script _swap.sh, passphrase generated random at each start, mountpoint not need, first 512 bytes not used.
  


