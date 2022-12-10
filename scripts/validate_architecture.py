#!/usr/bin/env python3

import argparse
import subprocess
import sys

ARCH_ALIASES = {
    "x86_64": "amd64",
    "aarch64": "arm64"
}

parser = argparse.ArgumentParser()
parser.add_argument("arch", help="Name of the architecture")
args = parser.parse_args()

try:
    arch = subprocess.check_output(r"docker info -f '{{.Architecture}}'", shell=True)
except subprocess.CalledProcessError as e:
    print(e)
    sys.exit(e.returncode)

arch = arch.decode("utf-8").strip()
arch = ARCH_ALIASES.get(arch, arch)

if arch != args.arch:
    print(f"\033[1;31mMismatch between provided architecture \"{args.arch}\"" +
          f" and actual architecture \"{arch}\"\033[0m")
    sys.exit(1)
else:
    print("architecture ok")
    sys.exit(0)
