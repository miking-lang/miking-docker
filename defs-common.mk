SHELL=bash

BASELINE_IMAGENAME=mikinglang/baseline
MIKING_IMAGENAME=mikinglang/miking

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile
LATEST_VERSION=latest-$(VERSION_SUFFIX)
MIKING_IMAGEVERSION=dev9-$(VERSION_SUFFIX)
BASELINE_IMAGEVERSION=v6-$(VERSION_SUFFIX)

# The suffix for the version to be tagged with the `latest` alias
LATEST_ALIAS=latest-alpine

BUILD_LOGDIR=../_logs

MIKING_GIT_REMOTE="https://github.com/miking-lang/miking.git"
MIKING_GIT_COMMIT="dfa6fac2561ee491ce4f4460f4ad4c6e0f34856a"

VALIDATE_IMAGE_SCRIPT=../scripts/validate_image.py
VALIDATE_ARCH_SCRIPT="../scripts/validate_architecture.py"
