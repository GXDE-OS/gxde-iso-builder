#!/usr/bin/env python3
import os
import sys
programPath = os.path.split(os.path.realpath(__file__))[0]  # 返回 string
for i in sys.argv[1:]:
    os.system(f"python3 '{programPath}/move-letter-path.py' '{i}'")
if(os.getenv("GPGPASSWD")):
    os.system(f"GPGPASSWD={os.getenv('GPGPASSWD')} python3 '{programPath}/loaddeb.py'")
else:
    os.system(f"python3 '{programPath}/loaddeb.py'")
os.system(f"python3 '{programPath}/build.py'")