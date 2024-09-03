#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("arch", help="Name of the architecture")
parser.add_argument("--runtime", choices=["docker", "podman"], default="docker",
                    help="Which runtime that is being used. (Default: docker)")
args = parser.parse_args()

if args.runtime == "docker":
    ARCH_ALIASES = {
        "x86_64": "linux/amd64",
        "aarch64": "linux/arm64"
    }
    try:
        arch = subprocess.check_output(r"docker info -f '{{.Architecture}}'", shell=True)
    except subprocess.CalledProcessError as e:
        print(e)
        sys.exit(e.returncode)

    arch = arch.decode("utf-8").strip()
    arch = ARCH_ALIASES.get(arch, arch)

elif args.runtime == "podman":
    try:
        podman_output = subprocess.check_output(r"podman info -f json", shell=True)
    except subprocess.CalledProcessError as e:
        print(e)
        sys.exit(e.returncode)

    podman_info = json.loads(podman_output)
    arch = podman_info["version"]["OsArch"]


if arch != args.arch:
    print(f"\033[1;31mMismatch between provided architecture \"{args.arch}\"" +
          f" and actual architecture \"{arch}\"\033[0m")
    sys.exit(1)
else:
    print("\033[1;32marchitecture ok\033[0m")
    sys.exit(0)
