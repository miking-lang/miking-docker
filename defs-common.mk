BASELINE_IMAGENAME=mikinglang/baseline
MIKING_IMAGENAME=mikinglang/miking

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile
LATEST_VERSION=latest-$(VERSION_SUFFIX)
MIKING_IMAGEVERSION=dev6-$(VERSION_SUFFIX)
BASELINE_IMAGEVERSION=v4-$(VERSION_SUFFIX)

# The suffix for the version to be tagged with the `latest` alias
LATEST_ALIAS=latest-alpine

BUILD_LOGDIR=../_logs

MIKING_GIT_REMOTE="https://github.com/miking-lang/miking.git"
MIKING_GIT_COMMIT="6628246936d9323b05175c2ab92f5026c232021c"
