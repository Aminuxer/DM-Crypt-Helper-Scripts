#!/bin/bash

MNTBASE=/media;


if [ -f "$1" ] || [ "$2" = "create" ]
   then CCNTR=$1;
   else
        echo "Usage: $0 <Path to Dm-Crypt container> [start|stop|create|make_loops] [Mount point] [cipher]
    Example: $0 ~/mysecrets.bin start /mnt/MyDisk aes-cbc-essiv:sha256
    create - make new container. Existing files don't touch for prevent data loss
    make_loops - create new loop-devices in /dev";
        exit 1;
fi

if [ -n "$3" ]
   then MNTPT=$3;
fi

if [ -n "$4" ]
   then CIPHER=$4;
   else CIPHER="aes-xts-essiv:sha256 --hash sha512 --key-size 512";
fi

LABEL=`basename "$CCNTR"`;

start() {
echo ' ';
echo '----- Mount CryptoContainer ['$CCNTR'] ---------------------';
LOOPD=`/sbin/losetup -f`;
/sbin/losetup $LOOPD $CCNTR;
/sbin/cryptsetup -c $CIPHER create $LABEL $LOOPD;
if [ ! -n "$MNTPT" ]
   then
      CCNLABEL=`e2label /dev/mapper/$LABEL`;
      if [ ! -n "$CCNLABEL" ]
         then CCNLABEL="Disk_NoLABEL__$LABEL";
      fi;
      MNTPT="$MNTBASE/$CCNLABEL"
fi
mkdir $MNTPT;
mount /dev/mapper/$LABEL $MNTPT;
       MLINE=`mount | grep $MNTPT`;
       if [ -n "$MLINE" ]; then
         echo "Label :: [$LABEL] ; $CCNTR --> $MNTPT ; [on $LOOPD]";
         echo '----- Mount CryptoContainer Complete ! ---------';
       else echo '----- ERROR - Bad password  -----------------';
         stop ;
       fi
echo ' ';
}

stop() {
echo ' ';
echo '----- Unmount CryptoContainer ['$CCNTR'] --------------------';
sync;
LOOPD=`/sbin/losetup -a | grep $CCNTR | cut -d ':' -f 1`;
if [ ! -n "$MNTPT" ]
   then MNTPT=`mount | grep /dev/mapper/$LABEL | cut -d ' ' -f 3`
fi
umount $MNTPT;
/sbin/cryptsetup remove $LABEL;
/sbin/losetup -d $LOOPD;
DLINE=`ls -A $MNTPT`;
if [ -n "$DLINE" ];
   then echo '----- CryptoContainer cannot be unmouted !!! ------';
   else
        rm -rf --one-file-system $MNTPT;
        echo '----- Unmount CryptoContainer Complete ! ---------';
fi
echo ' ';
}

create() {
echo ' ';
echo '----- CREATE NEW CryptoContainer ---------------------';
echo -n "You start to CREATE dm-crypt container. Continue (Yes/No)? "
read CONFIRM
if [ ! -n "$CONFIRM" ] || [ ! $CONFIRM == 'Yes' ]
   then echo 'No confirmation!'; exit 60;
   else echo "OK, continue...";
fi

if [ -f "$CCNTR" ]
   then echo "file $CCNTR exist, usage existing files denied."; exit 61;
   else
     while [ "$NEWLABEL" = "" ]
     do
       echo -n "Enter internal volume label for new container: "
       read NEWLABEL
     done

     while [ "$NEWSIZE" = "" ]
     do
       echo -n "Enter volume size (1048576, 1024K, 100M, 2G): "
       read NEWSIZE
     done
     touch $CCNTR;
     LOOPD=`/sbin/losetup -f`;
     echo "Supported filesystems on your machine:";
     echo "----------------------------------------------------------------------------------------------";
     ls -l /sbin/mkfs.*
     echo "----------------------------------------------------------------------------------------------";
     echo -n "Enter filesystem type (ext2 as default): "
     read FSTYPE
     if [ ! -n "$FSTYPE" ]
        then FSTYPE="ext2";
     fi
     echo "Fast fill container"
     dd if=/dev/null of=$CCNTR bs=1 seek=$NEWSIZE
     /sbin/losetup $LOOPD $CCNTR;
     /sbin/cryptsetup -c $CIPHER create $LABEL $LOOPD;
     echo "Shreding [$NEWSIZE] space on [$CCNTR] ...   (please wait)";
     shred -n1 /dev/mapper/$LABEL;
     echo "Formatting cryptocontainer...";
     mkfs -t $FSTYPE -L $NEWLABEL /dev/mapper/$LABEL
     if [ ! -n "$MNTPT" ]
        then MNTPT="$MNTBASE/$NEWLABEL";
     fi
     mkdir $MNTPT;
     mount -t $FSTYPE /dev/mapper/$LABEL $MNTPT;
       MLINE=`mount | grep $MNTPT`;
       if [ -n "$MLINE" ]; then
         echo "Label :: [$LABEL] ; $CCNTR --> $MNTPT ; [on $LOOPD], SIZE: [$NEWSIZE]";
         echo '----- New CryptoContainer mounted succesfully ! ---------';
       fi
     echo ' ';
fi
exit 0;
}

make_loops() {
  for i in $(seq 100 220); do
    mknod -m0660 /dev/loop$i b 7 $i;
    chown root.disk /dev/loop$i;
  done;
}


case "$2" in
start)
  start ;;
stop)
  stop ;;
create)
  create ;;
make_loops)
  make_loops ;;
*)
  MLINE=`/sbin/losetup -a | grep $CCNTR`;
  if [ -n "$MLINE" ]; then
   stop;
   else
   stop;
   clear;
   start;
  fi
esac


exit 0;
