#!/usr/bin/env python3

import argparse
import os

PLATFORMS = ["linux/amd64", "linux/arm64"]
BASELINES = [f[:-len(".Dockerfile")] for f in os.listdir(os.path.dirname(__file__)) if f.endswith(".Dockerfile")]


def main():
    MODES = {
        "build-args": build_args,
    }

    parser = argparse.ArgumentParser(description="Baseline configuration.")
    parser.add_argument("mode", choices=MODES.keys())
    parser.add_argument("--platform", dest="platform", choices=PLATFORMS, default=None)
    parser.add_argument("--baseline", dest="baseline", choices=BASELINES, default=None)
    args = parser.parse_args()

    MODES[args.mode](args)


def build_args(args):
    """
    Print out build args to be passed to container runtime for specified platform and baseline.
    """
    common_args = [f"TARGET_PLATFORM={args.platform}"]

    static_args = {
        "cuda11.4": {
            "linux/amd64": {
                "TARGET_LD_LIBRARY_PATH": "/usr/local/cuda/targets/x86_64-linux/lib:/usr/local/cuda-11/targets/x86_64-linux/lib:/usr/local/cuda-11.4/targets/x86_64-linux/lib:/usr/local/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu",
            },
        },
        "debian12.6": {
            "linux/amd64": {
                "TARGET_LD_LIBRARY_PATH": "/usr/lib/x86_64-linux-gnu/libfakeroot:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu",
            },
            "linux/arm64": {
                "TARGET_LD_LIBRARY_PATH": "/usr/local/lib/aarch64-linux-gnu:/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu/libfakeroot:/usr/local/lib",
            },
        },
    }

    args = common_args + [
        f"{arg}={value}"
        for arg, value in static_args.get(args.baseline, {}).get(args.platform, {}).items()
    ]
    print(" ".join([f"--build-arg=\"{a}\"" for a in args]))


if __name__ == "__main__":
    main()
