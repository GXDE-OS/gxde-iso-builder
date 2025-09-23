#!/usr/bin/env python3
import os
import sys
import subprocess
programPath = os.path.split(os.path.realpath(__file__))[0]  # 返回 string
for p in sys.argv[1:]:
    deb = subprocess.getoutput(f"dpkg --info '{p}'")
    debPackage = ""
    for i in deb.splitlines():
        i = i.strip()
        if i[:8] == "Package:":
            debPackage = i[9:].strip()
            break
    if debPackage != "":
        os.system(f"mkdir -p '{programPath}/{debPackage[0].lower()}/{debPackage.lower()}'")
        os.system(f"cp -ruv '{p}' '{programPath}/{debPackage[0].lower()}/{debPackage.lower()}'")
        os.system(f"chmod 755 -R '{programPath}/{debPackage[0].lower()}/{debPackage.lower()}'")
