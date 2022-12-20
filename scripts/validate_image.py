#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys

def pprop(key, val, sep=": "): sys.stderr.write(f"\033[1;37m{key}{sep}\033[0;37m{val}\n\033[0m")
def pinfo(msg): sys.stderr.write(f"\033[0;37m{msg}\n\033[0m")
def pwarn(msg): sys.stderr.write(f"\033[1;33m{msg}\n\033[0m")
def perror(msg, code=1):
    sys.stderr.write(f"\033[1;31m{msg}\n\033[0m")
    if code is not None: sys.exit(code)


def print_tag(d):
    """Prints the image tag."""
    tags = d["RepoTags"]
    if len(tags) != 1:
        pwarn(f"Expected single tag, received {len(tags)}")

    pprop("tag", tags[0])


def print_arch(d):
    """Prints info about the architecture in the JSON blob `b` that was output
    from the `docker inspect [image]` command."""
    info = {
        "os":      {"v": None, "req": True,  "order": 0, "key": "Os"},
        "arch":    {"v": None, "req": True,  "order": 1, "key": "Architecture"},
        "variant": {"v": None, "req": False, "order": 2, "key": "Variant"},
    }

    for key, item in info.items():
        if item["key"] in d:
            item["v"] = d[item["key"]]
        elif item["req"]:
            pwarn(f"Missing {key} info")

    expairs = [(k, v["v"]) for k,v in info.items() if v["v"] is not None]
    pprop("/".join(k for k,_ in expairs), "/".join(v for _,v in expairs))


def print_env(d):
    """Prints the preconfigured environment of the image."""
    pinfo("Pre-configured Environment:")
    conf_env = d.get("Config", {}).get("Env", [])
    containerconf_env = d.get("ContainerConfig", {}).get("Env", [])
    if conf_env is None:
        conf_env = []
    if containerconf_env is None:
        containerconf_env = []

    env = conf_env + containerconf_env

    for e in env:
        idx = e.find("=")
        if idx < 0:
            pwarn(f" - Irregular environment def: {e}")
            continue
        name = e[:idx]
        value = e[idx+1:]
        pprop(f" - {name}", value, sep="=")


if __name__ == "__main__":
    parser = argparse.ArgumentParser("Validate the output from a docker inspect [image]")
    parser.add_argument("-A", "--arch", dest="arch", metavar="NAME", type=str, default=None,
                        help="Validate the architecture of the produced image.")
    parser.add_argument("image", type=str,
                        help="The image to inspect")
    args = parser.parse_args()

    try:
        jsonstr = subprocess.check_output(f"docker inspect {args.image}", shell=True)
    except subprocess.CalledProcessError as e:
        print(e)
        sys.exit(e.returncode)

    # Output from `docker inspect` should not be more than 10 MB... just a precaution
    blob = json.loads(jsonstr)
    if isinstance(blob, list):
        if len(blob) != 1:
            pwarn(f"Expected exactly one entry in blob, received {len(blob)}")
        blob = blob[0]

    if args.arch is not None and blob["Architecture"] != args.arch:
        perror(f"Architecture assertion failed. Expected \"{args.arch}\", got \"{blob['Architecture']}\"")

    # This is just for information, so relax the correctness a bit... (assertions should be done above)
    funcs = [print_tag, print_arch, print_env]
    for f in funcs:
        try:
            f(blob)
        except Exception as e:
            msg = f"{type(e).__name__} exception in {f.__name__}: {str(e)}"
            perror(msg, code=None)
    #for key, val in blob.items():
    #    pprop(key, val)
