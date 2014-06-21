#!/bin/sh
cd bin
find | cpio -H newc -ov | gzip --best -c - > ../initrd.img
