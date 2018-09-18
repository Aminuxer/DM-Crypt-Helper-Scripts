#!/bin/bash

# Amin 's DM-Crypt mount helper script   v. 2018-09-18

MNTBASE=/run/media;


if [ -f "$1" ] || [ "$2" = "create" ]
   then CCNTR="$1";
   else
        echo "Usage: $0 <Path to Dm-Crypt container> [start|stop|create|make_loops] [Mount point] [cipher]
    Example: $0 ~/mysecrets.bin start /mnt/MyDisk aes-cbc-essiv:sha256
    create - make new container. Existing files don't touch for prevent data loss
    make_loops - create new loop-devices in /dev";
        exit 1;
fi

if [ -n "$3" ]
   then MNTPT="$3";
fi

if [ -n "$4" ]
   then CIPHER=`echo "$4" | sed 's/[#&;%$|\n[\t]//g'`;
   else CIPHER='aes-xts-essiv:sha256 --hash sha512 --key-size 512';
fi

LABEL=`basename "$CCNTR"`;

start() {
echo ' ';
echo "----- Mount CryptoContainer [$CCNTR] ---------------------";
LOOPD=`/sbin/losetup -f`;
/sbin/losetup "$LOOPD" "$CCNTR";

echo "Cipher options: $CIPHER"
/sbin/cryptsetup -v create "$LABEL" "$LOOPD" -c $CIPHER

if [ ! -n "$MNTPT" ]
   then
      if [ `which fsstat 2> /dev/null` ]
         then FSDETECT=`fsstat -t /dev/mapper/$LABEL`;
         else
            FSDETECT='';
            echo "Tool fsstat NOT FOUND ! Container-Labels NOT applied"
      fi

      BTRFSTEST=`e2label /dev/mapper/$LABEL 2> /dev/null | grep btrfs`;

      if [ "$FSDETECT" == 'ext2' ] || [ "$FSDETECT" == 'ext3' ] || [ "$FSDETECT" == 'ext4' ]
         then CCNLABEL=`e2label "/dev/mapper/$LABEL"`;
      elif [ "$FSDETECT" == 'fat16' ] || [ "$FSDETECT" == 'msdos' ] || [ "$FSDETECT" == 'fat32' ] || [ "$FSDETECT" == 'vfat' ]
         then CCNLABEL=`dosfslabel "/dev/mapper/$LABEL"`;
      elif [ "$FSDETECT" == 'exfat' ]
         then CCNLABEL=`exfatlabel "/dev/mapper/$LABEL"`;
      elif [ "$FSDETECT" == 'ntfs' ]
         then CCNLABEL=`ntfslabel "/dev/mapper/$LABEL"`;
      elif [ "$FSDETECT" == 'btrfs' ] || [ -n "$BTRFSTEST" ]
         then CCNLABEL=`btrfs filesystem label "/dev/mapper/$LABEL"`;
              FSDETECT='btrfs';
      fi

      echo "FS in container: $FSDETECT"

      if [ $? -ne 0 ] || [ ! -n "$CCNLABEL" ]
         then CCNLABEL="Disk_NoLABEL__$LABEL";
      fi;
      MNTPT="$MNTBASE/$CCNLABEL"
fi
mkdir -p "$MNTPT";
mount "/dev/mapper/$LABEL" "$MNTPT";
       MLINE=`mount | grep "$MNTPT"`;
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
echo "----- Unmount CryptoContainer [$CCNTR] --------------------";
sync;
LOOPD=`/sbin/losetup -a | grep "$CCNTR" | cut -d ':' -f 1`;
if [ ! -n "$MNTPT" ]
   then MNTPT=`df /dev/mapper/$LABEL --output=target 2> /dev/null | tail -n 1`
fi

if [ -n "$MNTPT" ]
   then umount "$MNTPT";
fi

if [ -n "$LABEL" ]
   then /sbin/cryptsetup remove "$LABEL";
fi

if [ -n "$LOOPD" ]
   then /sbin/losetup -d "$LOOPD";
fi

if [ -n "$MNTPT" ]
   then DLINE=`ls -A "$MNTPT"`;
fi

if [ -n "$DLINE" ];
   then echo "WARNING: Not empty mount point. Check $MNTPT";
   else
           echo "Check mount-point [$MNTPT] and try remove empty dir";
           if [ ! "$MNTPT" == '' ]
              then
                echo "!! Remove mount-point $MNTPT !!";
                rm -f --one-file-system -d -v "$MNTPT";
                echo '----- Unmount CryptoContainer Complete ! ---------';
              else echo "Empty mount-point string -)";
           fi
fi
echo ' ';
}

create() {
echo ' ';
echo '----- CREATE NEW CryptoContainer ---------------------';
echo -n "You start to CREATE dm-crypt container. Continue (Yes/No)? "
read CONFIRM
if [ ! -n "$CONFIRM" ] || [ ! "$CONFIRM" == 'Yes' ]
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
     touch "$CCNTR";
     LOOPD=`/sbin/losetup -f`;
     echo "Supported filesystems on your machine:";
     echo "----------------------------------------------------------------------------------------------";
     ls -l /sbin/mkfs.* -x
     echo "----------------------------------------------------------------------------------------------";
     echo -n "Enter filesystem type (ext2 as default): "
     read FSTYPE
     if [ ! -n "$FSTYPE" ]
        then FSTYPE="ext2";
     fi
     echo "Fast fill container"
     dd if=/dev/null of="$CCNTR" bs=1 seek="$NEWSIZE"
     /sbin/losetup "$LOOPD" "$CCNTR";
     /sbin/cryptsetup create "$LABEL" "$LOOPD" -c $CIPHER;
     echo "Shreding [$NEWSIZE] space on [$CCNTR] ...   (please wait)";
     shred -n1 "/dev/mapper/$LABEL";
     echo "Formatting cryptocontainer...";
     mkfs -t "$FSTYPE" "/dev/mapper/$LABEL"

     if [ "$FSTYPE" == 'ext2' ] || [ "$FSTYPE" == 'ext3' ] || [ "$FSTYPE" == 'ext4' ]
        then e2label "/dev/mapper/$LABEL" "$NEWLABEL"
     fi

     if [ "$FSTYPE" == 'vfat' ] || [ "$FSTYPE" == 'msdos' ] || [ "$FSTYPE" == 'fat16' ] || [ "$FSTYPE" == 'fat32' ]
        then dosfslabel "/dev/mapper/$LABEL" "$NEWLABEL"
     fi

     if [ "$FSTYPE" == 'btrfs' ]
        then btrfs filesystem label "/dev/mapper/$LABEL" "$NEWLABEL"
     fi

     if [ "$FSTYPE" == 'exfat' ]
        then exfatlabel "/dev/mapper/$LABEL" "$NEWLABEL"
     fi

     if [ "$FSTYPE" == 'ntfs' ]
        then ntfslabel "/dev/mapper/$LABEL" "$NEWLABEL"
     fi

     if [ ! -n "$MNTPT" ]
        then MNTPT="$MNTBASE/$NEWLABEL";
     fi
     mkdir -p "$MNTPT";
     mount -t "$FSTYPE" "/dev/mapper/$LABEL" "$MNTPT";
       MLINE=`mount | grep "$MNTPT"`;
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
  MLINE=`/sbin/losetup -a | grep "$CCNTR"`;
  if [ -n "$MLINE" ]; then
   stop;
   else
   stop;
   ## clear;
   start;
  fi
esac


exit 0;
