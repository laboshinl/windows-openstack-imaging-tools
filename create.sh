#! /bin/bash
IMAGE=windows-7-i386.qcow2
FLOPPY=Autounattend.vfd
VIRTIO_ISO=virtio-win-latest.iso
ISO="$1"

qemu-img create -f qcow2 -o preallocation=metadata $IMAGE 16G

qemu-kvm -m 2048 -smp 2 -cdrom $ISO -drive file=$VIRTIO_ISO,index=3,media=cdrom -fda $FLOPPY $IMAGE -boot d -vga std -k en-us -vnc :1
