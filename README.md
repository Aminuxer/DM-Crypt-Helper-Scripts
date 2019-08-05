# DM-Crypt-Helper-Scripts
Additional mount scripts for DM-Crypt containers

Script for comfortable create / mount DM-Crypt containers over sudo, make Crypted SWAP.

Use one command instead three command. Mount your containers under LiveCD with one easy step.


## Installation

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

```bash
Usage: /opt/_dmc.sh <Path to Dm-Crypt container> [start|stop|create|make_loops] [Mount point] [cipher]
    Example: /opt/_dmc.sh ~/mysecrets.bin start /mnt/MyDisk aes-cbc-essiv:sha256
    create - make new container. Existing files don't touch for prevent data loss
    make_loops - create new loop-devices in /dev```

## Create new crypto-container

You can create containers only in new files.
Script don't touch existing files when create method called.
In this case you see message "file /var/tmp/fs1.bin exist, usage existing files denied."

Run script with full path to new containers and use cli dialogs for create new container:

`$ sudo /opt/_dmc.sh /var/tmp/fs1.bin create`
 

```bash
----- CREATE NEW CryptoContainer ---------------------
You start to CREATE dm-crypt container. Continue (Yes/No)? _Yes_
OK, continue...
Enter internal volume label for new container: _MyNewContainer1_
Enter volume size (1048576, 1024K, 100M, 2G): _42M_
Supported filesystems on your machine:
----------------------------------------------------------------------------------------------
/sbin/mkfs.btrfs    /sbin/mkfs.cramfs  /sbin/mkfs.ext2   /sbin/mkfs.ext3   /sbin/mkfs.ext4    /sbin/mkfs.f2fs  /sbin/mkfs.fat
/sbin/mkfs.hfsplus  /sbin/mkfs.jfs     /sbin/mkfs.minix  /sbin/mkfs.msdos  /sbin/mkfs.nilfs2  /sbin/mkfs.ntfs  /sbin/mkfs.reiserfs
/sbin/mkfs.udf      /sbin/mkfs.vfat    /sbin/mkfs.xfs
----------------------------------------------------------------------------------------------
Enter filesystem type (ext2 as default): _ext4_
Fast fill container
0+0 records in
0+0 records out
0 bytes copied, 7.7594e-05 s, 0.0 kB/s
Enter passphrase for /dev/loop2:_EnterYouStrongUberMegaPaSsW0rD~PhRAZe+Here_
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
----- New CryptoContainer mounted succesfully ! ---------```

After this your container will already mounted and ready for usage.

## Stop and unmount cryptocontainer
