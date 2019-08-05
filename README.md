# DM-Crypt-Helper-Scripts
Additional mount scripts for DM-Crypt containers

Script for comfortable create / mount DM-Crypt containers over sudo, make Crypted SWAP.

Use one command instead three command. Mount your containers under LiveCD with one easy step.


# Installation

1). download scripts to local system, for example to /opt (you can run script from any fs)

cd /opt
wget https://github.com/Aminuxer/DM-Crypt-Helper-Scripts/raw/master/_dmc.sh
chmod +x _dmc.sh

2). Optional step. Usage dm-crypt require high permissions.
Create sudo rules for start scripts under non-privileged users:

vi /etc/sudoers.d/myscripts-example
user1  ALL=(root)      NOPASSWD: /opt/_dmc.sh
user1  ALL=(root)      NOPASSWD: /opt/_swap.sh

Without this step (livecd) manage cryptocontainers will require root permissions.

3). Run script with sudo :
$ sudo /__dmc/_dmc.sh

Usage: /__dmc/_dmc.sh <Path to Dm-Crypt container> [start|stop|create|make_loops] [Mount point] [cipher]
    Example: /__dmc/_dmc.sh ~/mysecrets.bin start /mnt/MyDisk aes-cbc-essiv:sha256
    create - make new container. Existing files don't touch for prevent data loss
    make_loops - create new loop-devices in /dev


