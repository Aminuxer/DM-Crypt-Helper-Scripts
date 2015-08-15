#!/bin/bash

if [ -f "$1" ] || [ "$2" = "create" ]
   then SWPFILE=$1;
   else
     echo "Usage: $0 <Path to Dm-Crypt Swap> [start|stop|list|create|make_loops] [cipher]
                  Example: $0 ~/myswap.bin start aes-xts-essiv:sha256
                  create - make new swap. Existing files don't touch for prevent data loss
                  make_loops - create new loop-devices in /dev";
     exit 1;
fi

if [ -n "$3" ]
   then CIPHER=$3;
   else CIPHER="--key-file=/dev/urandom --key-size 512 --hash sha512 --cipher aes-xts-essiv:sha256";
fi

SWPDEV=`basename "$SWPFILE"`;

start() {
FILEHEADER=`dd if=$SWPFILE bs=8 count=1` 2>&1;
if [ $FILEHEADER == 'DMC-SWAP' ]
then
   LOOPD=`/sbin/losetup -f`;
   /sbin/losetup -o 512 $LOOPD $SWPFILE;
   /sbin/cryptsetup $CIPHER create $SWPDEV $LOOPD;
   /sbin/mkswap -L $SWPDEV -f /dev/mapper/$SWPDEV >/dev/null 2>&1;
   /sbin/swapon /dev/mapper/$SWPDEV;
   echo '===== CryptoSWAP Start for ['$SWPFILE'] --> ['$LOOPD'] --> ['$SWPDEV']  =====';
else
   echo "Sorry, this file NOT LABELED as 'DMC-SWAP' ";
fi
}

stop() {
LOOPD=`/sbin/losetup -a | grep $SWPFILE | cut -d ':' -f 1`;
/sbin/swapoff /dev/mapper/$SWPDEV;
/sbin/cryptsetup remove $SWPDEV;
/sbin/losetup -d $LOOPD;
echo '===== CryptoSWAP Stop for ['$SWPFILE'] --> ['$LOOPD'] --> ['$SWPDEV']  =====';
}

create() {
echo '----- CREATE NEW Crypto-SWAP File ---------------------';
echo -n "You start to CREATE dm-crypt SWAP. Continue (Yes/No)? "
read CONFIRM
if [ ! -n "$CONFIRM" ] || [ ! $CONFIRM == 'Yes' ]
   then echo 'No confirmation!'; exit 60;
   else echo "OK, continue...";
fi

if [ -f "$SWPFILE" ]
 then echo "file $SWPFILE exist, usage existing files denied."; exit 61;
 else
    while [ "$NEWSIZE" = "" ]
    do
      echo -n "Enter swap size (1048576, 1024K, 100M, 2G): "
      read NEWSIZE
    done

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
