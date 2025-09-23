#!/bin/bash
#xorriso -as mkisofs -R -r -J -joliet-long -l -cache-inodes -iso-level 3 -A "GXDE OS Live" -V "GXDE-OS" -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus -o gxde.iso loong64
xorriso -as mkisofs -R -r -J -joliet-long -l -cache-inodes -iso-level 3 -A "GXDE OS Live" -p "https://www.gxde.top" -V "GXDE-OS" -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus -o gxde.iso riscv64
