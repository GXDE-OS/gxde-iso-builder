#!/usr/bin/env python3
import os
import sys
programPath = os.path.split(os.path.realpath(__file__))[0] 
os.system(f"bash '{programPath}/incremental-updating-packages.sh' '{programPath}'")
os.system("rm Packages.xz")
os.system(f"xz -k '{programPath}/Packages'")
os.system("apt-ftparchive release . > Release")
os.system("rm Release.gpg")
os.system("rm InRelease")
os.system("rm gpg.asc")
if(os.getenv("GPGPASSWD")):
    os.system(f"gpg --passphrase '{os.getenv('GPGPASSWD')}' --armor --detach-sign -o Release.gpg Release")
    os.system(f"gpg --passphrase '{os.getenv('GPGPASSWD')}' --clearsign -o InRelease Release")
else:
    os.system("gpg --armor --detach-sign -o Release.gpg Release")
    os.system("gpg --clearsign -o InRelease Release")
# 压缩 Packages
#os.system(f"rm '{programPath}/Packages.xz'")
#os.system(f"xz '{programPath}/Packages'")
#os.system(f"rm '{programPath}/Packages'")
