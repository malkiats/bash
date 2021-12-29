rd.break
mount -o remount,rw /sysroot
chroot /sysroot
passwd
touch ./autorelabel
