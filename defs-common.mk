SHELL=bash

BASELINE_IMAGENAME=mikinglang/baseline
MIKING_IMAGENAME=mikinglang/miking

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile
LATEST_VERSION=latest-$(VERSION_SUFFIX)
MIKING_IMAGEVERSION=dev8-$(VERSION_SUFFIX)
BASELINE_IMAGEVERSION=v5-$(VERSION_SUFFIX)

# The suffix for the version to be tagged with the `latest` alias
LATEST_ALIAS=latest-alpine

BUILD_LOGDIR=../_logs

MIKING_GIT_REMOTE="https://github.com/miking-lang/miking.git"
MIKING_GIT_COMMIT="09c233080104f147a8fdd66fb63cfd6cfe8bf7b8"

VALIDATE_IMAGE_SCRIPT=../scripts/validate_image.py
VALIDATE_ARCH_SCRIPT="../scripts/validate_architecture.py"
