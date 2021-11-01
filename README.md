# DM-Crypt-Helper-Scripts
Additional mount scripts for DM-Crypt containers

Script for comfortable create / mount DM-Crypt containers over sudo, make Crypted SWAP.

Use one command instead three command. Mount your containers under LiveCD with one easy step.
With many safety checks.


## Installation and requirements

0). Programs cryptsetup, sed, basename, realpath, losetup, dd, mkfs*, shred, touch and bash must be installed (usually default)
On some system cryptsetup must be installed manually (ex Ubuntu 18 minimal):
`apt-get install cryptsetup-bin`

Optionally you can install sudo and tools for support other filesystems (ex btrfs, xfs, ntfs, exfat, reiserfs).

1). download scripts to local system, for example to /opt (you can run script from any fs)

`cd /opt`

`wget https://github.com/Aminuxer/DM-Crypt-Helper-Scripts/raw/master/_dmc.sh`

`chmod +x _dmc.sh`
Tools curl or fetch can be used instead of wget.

2). Optional step. Usage dm-crypt require high permissions.
Create sudo rules for start scripts under non-privileged users:

`# vi /etc/sudoers.d/myscripts-example`

`user1  ALL=(root)      NOPASSWD: /opt/_dmc.sh`

Without this step (ex. livecd like knoppix) manage cryptocontainers will require root permissions.

3). Run script with sudo :
`$ sudo /opt/_dmc.sh`

Start without parameters will show mini-help:

```
Usage: ./_dmc.sh <Path to Dm-Crypt container> [start|stop|create|make_loops] [Mount point] [cipher]
    Example: ./_dmc.sh ~/mysecrets.bin create    - make new in file
             ./_dmc.sh /dev/md0 create           - on RAID
             ./_dmc.sh ~/mysecrets.bin           - swicth
             ./_dmc.sh ~/mysecrets.bin stop      - force stop
    create - make new container. Existing file don't touch for safety
    make_loops - create new loop-devices in /dev
```

## Create new crypto-container

You can create containers in new files or unused block devices (like raw drives, partitions, LVM-slices or RAIDs).
Script don't touch existing files or mounted/used devices when create method called.
Also many safety checks added - for block devices like /dev/(md*|sd*|mapper|lvm*) make many checks for mounted state or contain RAID / LVM / ZFS used structures.

In this case you see messages like "file /var/tmp/fs1.bin exist, usage existing files denied.", "Device mounted" or "Device in RAID / LVM /  ZFS".

Run script with full path to new containers and use cli dialogs for create new container:

In usual file :
`$ sudo /opt/_dmc.sh /var/tmp/fs1.bin create`

In partition #9 on physical drive sdg:
`$ sudo /opt/_dmc.sh /dev/sdg9 create`

in free LVM-LV (logical volume)
`$ sudo /opt/_dmc.sh /dev/mapper/free-LVM-LogicalVolume create`



```
----- CREATE NEW CryptoContainer ---------------------
You start to CREATE dm-crypt container. Continue (Yes/No)? Yes
OK, continue...
Enter internal volume label for new container: MyNewContainer1
Enter volume size (1048576, 1024K, 100M, 2G): 42M
Supported filesystems on your machine:
------------------------------------------
btrfs     ext2      ext3     ext4     fat
msdos     ntfs      vfat     xfs
------------------------------------------
Enter filesystem type (from list above): ext4
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

For physical devices don't need input size - autodetect present.
After this your container will already mounted and ready for usage.


## Start / mount cryptocontainer
Run script with full path to container and method start:

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
If any file from internal fs will be opened in external program, script stopped with umount error message.
Close all files opened from container and try again.

##  FAQ
* What happens if i run `$ sudo /opt/_dmc.sh /var/tmp/fs1.bin` - command with only path to existing file ?
  - Script will try detect current status and propose mount / umount action. Mounted containr will try umount, unmounted - mount with passphrase request.

* Can i use raw devices or partitions like /dev/sdh or /dev/sdg2 instead of file ?
  - Yes. But script allow this only for unmounted partitions, not included in active RAID / LVM / ZFS structures; Work with mounted partitions so destructive and denied by safety checks in script. At your own risk anyway; I tested this on Fedora and Ubuntu and this work normally.

* What is method make_loops ?
  - This method for some old or livecd systems, where loopback devices not created at boot.
Use mknod util. Can be useful , if you try mount too many containers.

* Can script damage my trivial file if i try mount this as container ? ex _dmc.sh dsc0001.jpg ?
  - No. You cannot create passphrase for convert jpeg-file to FS-image by AES =) It's fantastic.
  Script can't found internal FS and rollback all changes. File will not changed.
  But you must have backups in any case =].

* How to mount container in another mount point, for example, in path under /tmp, /home or other path ?
  - Use third parameter: `$ sudo /opt/_dmc.sh /var/tmp/fs1.bin start /tmp/mountpoint`

* What filesystems can be used ?
  - On external storage for place encrypted container - any type. Check maximal size and characters in filename (actually only for old MS products like FAT).
  - For FS inside container - all standard with labels support and present in your system - ext*, fat*, ntfs, btrfs, xfs, reiser
  - Another FS can be added in future, depends of many factors.

* I have container without volume label. How it important ?
  - Not important. Containers with unlabeled fs will mount to path like `/run/media/Disk_NoLABEL__fs1.bin` and only with parameter start. Mount container, see device name by `df` and change label for /dev/mapper/fs1.bin by `e2label` or similar tool.
Some FS must be unmount first. Use mount, change label, _dmc.sh ... stop   Label will applied at next _dmc.sh ... start

* Can i mount some different copies of same container ?
  - Bad idea; Script try detect this for prevent dangerous mistakes.
  If need, rename old copy of container and mount this to another mountpoint. Make backups BEFORE this work.
  Since 2021-10-26 script prevent multiple start-binding to loop-devices for same file.

* Can i make fsck or another service works for fs in container ?
  - Yes. Mount container with correct passphrase by script _dmc.sh. See device name by `df` command or command `mount`. umount this filesystem with `umount` system command (NOT by script !!). Start fsck for /dev/mapper/<virtual.device.name>
Force stop cryptodevice by call script with stop parameter.

* What is Cipher option - parameter 4 ?
  - If you have another or older dm-crypt container with other ciphers you can use this options for manual mount this. Syntax of this same as `-c` parameter for cryptsetup.

* Can i update file by new version ?
  - Yes. Make backup copy and simple download over. If you don't change default cipher-method - all must work. In other case, use fourth parametr for CIPHER specification.

* Why used aes-xts-essiv:sha256 --hash sha512 --key-size 512 ?
  - This methods suitable for full-disk encryption, prevent many attacks against crypted partitions and supported in almost all linux distribs. Also AES ciphers have hardware-acceleration on modern CPU - this important for big containers (ex virtual machines storages)
   More deep understand will require learn more about cryptography:
   https://wikipedia.org/wiki/Disk_encryption_theory
   Disk encryption is one of hardest cryptograhy task - too many crypto-issues must be solved.

* How to view list of supported ciphers ?
  - Use commands `cryptsetup benchmark` and `cryptsetup --help`
    More detailed info here: https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks

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
  - This script so old and don't have many safety checks. Be careful.

* Can i use multi-keys / multi-user scenario ?
   - No. This raw dm-crypt related code. Use LUKS for more compex tasks.

* Can i embed containers in containers ? Is it deniable encryption ?
  - Your can place container in another container (container is usual file), but this tested slightly;
    You must use different filenames and FS labels at least; This not deniable; Deniable encryption required more complex software like TrueCrypt or use steganograhy like `steghide` utility.

* Can i place scripts or containers on removable media ?
  - No problem. But your possible will need root permissions (sudo rules danger apply to removable), start script as `bash` parameter (fs without +x attr) or speed of removable media can be lower. This script work in Knoppix-Live environment when running from KNOPPIX-DATA storage.

* How to move my PGP-keys / Bitcoin wallet / SSH-keys / TOTP apps / private documents inside crypto-container ?
  - Be sure that you strongly remember your passphrase. Check this twice; Check that you have BACKUPS.
    If your forget passphrase, almost no way to recover it; Bruteforce of dm-crypt so difficult.
  - Create subdirs in container and copy sensitive data in container FS.
  - `shred` sensitive data on non-encrypted disks; Simple `rm` or delete by Del/F8 buttons
     vulnerable to forensics / data-recovery tools. For SSD drives, remove shreded files and run trim procedure by `fstrim` command.
  - make symlinks like this `ln -s /media/MyNewContainer1/SSH/id_rsa ~/.ssh/id_rsa`
    (~/.ssh/id_rsa -> /media/MyNewContainer1/SSH/id_rsa)
  - Move your highly-private apps like micro totp-generator (https://github.com/Aminuxer/Other-nix-Scripts/blob/master/totp.py) to subdir inside container-FS.

* How big/small size can have dm-crypt cryptocontainer ?
  - Almost any, but depends of filesystems. I create small containers with fat / ext2 system inside with 100 Kb size;
  Big 200-300 Gb containers i create too - if your hard disk work properly, no problem taking place;
  I recommend store only high-critical data inside containers with comfortable size for transfer / backups / restore / archiving;
  P.S. Archiving can be bad idea in terms of cryptography; But in most cases accessibility and integrity must be prefer.

* Can i use this script on Mac with MacOS ?
  - No. MacOS use another tools like `hdiutil` and older versions of coreutils. Theoretically it is possible, but i don't has interest do this. Your can make fork.
