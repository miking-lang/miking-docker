SHELL=bash

BASELINE_IMAGENAME=mikinglang/baseline
MIKING_IMAGENAME=mikinglang/miking

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile
LATEST_VERSION=latest-$(VERSION_SUFFIX)
MIKING_IMAGEVERSION=dev10-$(VERSION_SUFFIX)
BASELINE_IMAGEVERSION=v7-$(VERSION_SUFFIX)

# The suffix for the version to be tagged with the `latest` alias
LATEST_ALIAS=latest-alpine

BUILD_LOGDIR=../_logs

MIKING_GIT_REMOTE="https://github.com/miking-lang/miking.git"
MIKING_GIT_COMMIT="58c6cbf0517c76bd6ad55c7b68ff7a9ea4e1d373"

VALIDATE_IMAGE_SCRIPT=../scripts/validate_image.py
VALIDATE_ARCH_SCRIPT="../scripts/validate_architecture.py"
