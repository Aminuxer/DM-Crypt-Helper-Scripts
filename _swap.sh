#!/bin/bash

#   Amin 's Crypted SWAP helper script.   v. 2021-11-04
#   This script is old legacy;               Consider native https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption

if [ -e "$1" ] || [ "$2" == "create" ]
   then SWPFILE=$1;
   else
     echo "Usage: $0 <Path to Dm-Crypt Swap> [start|stop|list|create|make_loops] [cipher]
                  Example: $0 ~/myswap.bin create
                           $0 /dev/sda13   start
                  create - make new swap. Existing files don't touch for prevent data loss
                  make_loops - create new loop-devices in /dev";
     exit 1;
fi

if [ -n "$3" ]
   then CIPHER=$3;
   else CIPHER="aes-xts-essiv:sha256";
fi

SWPDEV=`basename "$SWPFILE"`;     # filename
RLPATH=`realpath "$SWPFILE"`;     # full-path

## Start safety checks - mounted paritions, RAID, LVM, ZFS
##  ACHTUNG CHECKS !!!
   if [ -e "$SWPFILE" ] && [ `mount -f | cut -d ' ' -f 1 | grep '/dev/' | grep "$RLPATH" | wc -l` -gt 0 ] && [ "$2" != "stop" ]
         then echo "Device $SWPFILE mounted. Unmount first. BE CARE!"; exit 69;
   elif [ -e "$SWPFILE" ] && [ `swapon -s | grep '/dev/' | cut -d ' ' -f 1 | grep "$RLPATH" | wc -l` -gt 0 ]
      then echo "Device $SWPFILE is active non-crypted SWAP. Unmount first. Stop."; exit 71;

   elif [ -e "$SWPFILE" ] && [ `mdadm -D /dev/md* 2>/dev/null | grep 'active' | grep "$RLPATH" | wc -l` -gt 0 ]
      then echo "Device $SWPFILE in RAID-array. Stop. BE CARE!"; exit 72;

   elif [ -e "$SWPFILE" ] && [ `pvscan -s 2>/dev/null | grep '/dev/' | grep "$RLPATH" | wc -l` -gt 0 ]
      then echo "Device $SWPFILE in LVM. Stop. BE CARE!"; exit 73;

   elif [ -e "$SWPFILE" ] && [ `blkid --match-token TYPE="zfs_member" -s LABEL | cut -d ':' -f 1 | grep "$RLPATH" | wc -l` -gt 0 ]
      then echo "Device $SWPFILE contain ZFS. Stop. BE CARE!"; exit 74;

   elif [ ! -e "$SWPFILE" ] && [ `echo "$RLPATH" | grep -E "^/(dev|sys|proc)/"` ]
      then echo "Path $RLPATH in system area. Stop. Use new regular file or free block-device."; exit 75;

   elif [ `lsblk $RLPATH -n -o MOUNTPOINT 2> /dev/null | grep -v '^$' | wc -l` -gt 0 ]
      then echo "Block device $RLPATH has active MOUNTPOINT."; exit 75;
   fi
## End safety checks - mounted paritions, RAID, LVM, ZFS


start() {
if [ `losetup -a | grep "$RLPATH" | wc -l` -gt 0 ]
   then echo "This device already loop-mapped ! Stop it first."; exit 62;
fi

FILEHEADER=`dd if=$SWPFILE bs=8 count=1` 2>/dev/null;
if [ $FILEHEADER == 'DMC-SWAP' ]
then
   LOOPD=`/sbin/losetup -f`;
   /sbin/losetup -o 512 $LOOPD $SWPFILE;
   /sbin/cryptsetup --key-file=/dev/urandom --key-size 512 -c $CIPHER create $SWPDEV $LOOPD;
   /sbin/mkswap -L $SWPDEV -f /dev/mapper/$SWPDEV >/dev/null 2>&1;
   /sbin/swapon /dev/mapper/$SWPDEV;
   echo '===== CryptoSWAP Start for ['$SWPFILE'] --> ['$LOOPD'] --> ['$SWPDEV']  =====';
else
   echo "Sorry, this storage NOT LABELED as 'DMC-SWAP' ";
fi
}


stop() {
LOOPD=`/sbin/losetup -a | grep $RLPATH | cut -d ':' -f 1`;
/sbin/swapoff /dev/mapper/$SWPDEV;
/sbin/cryptsetup remove $SWPDEV;
/sbin/losetup -d $LOOPD;
echo '===== CryptoSWAP Stop for ['$SWPFILE'] --> ['$LOOPD'] --> ['$SWPDEV']  =====';
}

create() {
echo '----- CREATE NEW Crypto-SWAP File ---------------------';

if [ -f "$SWPFILE" ]
   then echo "file $SWPFILE exist, usage existing files denied."; exit 61;
   elif [ `losetup -a | grep "$RLPATH" | wc -l` -gt 0 ]
          then echo "This device already loop-mapped ! Stop it first."; exit 62;
   else
     if [ `echo "$RLPATH" | grep -E "^/dev/"` ]
        then echo "!! ATTENTION !! Your Crypto-SWAP on PHYSICAL block device !
!! Current content of $RLPATH will be ERASED!  Be carefully!";
     fi

     OLDFS=`blkid "$RLPATH"`
     if [ ! "$OLDFS" == '' ]
        then echo "!! Device $SWPFILE contain filesystem:
          $OLDFS"
     fi

     echo -n "You start to CREATE dm-crypt SWAP. Continue (Yes/No)? "
     read CONFIRM
     if [ ! -n "$CONFIRM" ] || [ ! $CONFIRM == 'Yes' ]
       then echo 'No confirmation!'; exit 60;
       else echo "OK, continue...";
     fi

     if [ ! `echo "$RLPATH" | grep -E "^/dev/"` ]
     then
       while [ "$NEWSIZE" = "" ]
       do
         echo -n "Enter file size (1048576, 1024K, 100M, 2G): "
         read NEWSIZE
         NEWSIZE=`echo "$NEWSIZE" | grep -Ex '[0-9KMGTPEZY]+'`
       done
     else
       NEWSIZE=`lsblk -bdno SIZE "$RLPATH" | tr -d ' '`;
       echo "Block device :: Full detected size [$NEWSIZE] used"
     fi

     echo "Fast fill crypted swap"
     dd if=/dev/null of="$SWPFILE" bs=1 seek="$NEWSIZE"
     if [ $? -ne 0 ]
     then
        echo "DD error; Size too big, read-only storage, etc ?"
        exit 7;
     fi

    touch $SWPFILE;
    LOOPD=`/sbin/losetup -f`;
    dd if=/dev/null of=$SWPFILE bs=1 seek=$NEWSIZE
    losetup -o 0 --sizelimit 512 $LOOPD $SWPFILE
echo "DMC-SWAP : Edit only 5 comment strings ! [ Header: 512b ] */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* 1.                                                        */
/* 2.                                                        */
/* 3.                                                        */
/* 4.                                                        */
/* 5.                                                        */
/*___________________________________________________________*/
"> $LOOPD
    sync
    losetup -d $LOOPD
    LOOPD=`/sbin/losetup -f`;
    losetup -o 512 $LOOPD $SWPFILE
    dd if=/dev/urandom of=$LOOPD
    sync
    losetup -d $LOOPD
fi
}


make_loops() {
  for i in $(seq 100 220); do
      mknod -m0660 /dev/loop$i b 7 $i;
      chown root.disk /dev/loop$i;
  done;
}


list() { /sbin/swapon -s; }


case "$2" in
start)
   start;;
stop)
   stop;;
create)
   create;;
make_loops)
  make_loops ;;
list)
   list;;
*)
   SWPLINE=`/sbin/losetup -a | grep $SWPFILE`;
   if [ -n "$SWPLINE" ]; then stop; else start; fi
esac


exit 0

