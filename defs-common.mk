BASELINE_IMAGENAME=mikinglang/baseline
MIKING_IMAGENAME=mikinglang/miking

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile
LATEST_VERSION=latest-$(VERSION_SUFFIX)
MIKING_IMAGEVERSION=dev6-$(VERSION_SUFFIX)
BASELINE_IMAGEVERSION=v4-$(VERSION_SUFFIX)

# The suffix for the version to be tagged with the `latest` alias
LATEST_ALIAS=latest-alpine

BUILD_LOGDIR=../_logs

#MIKING_GIT_REMOTE="https://github.com/miking-lang/miking.git"
#MIKING_GIT_COMMIT="f649b2a63572964340ba066bdbab5210259933e8"

# Temporarily use the OCaml 5 branch
MIKING_GIT_REMOTE="https://github.com/larshum/miking.git"
MIKING_GIT_COMMIT="9ea937474c4acbe1a5566e2c0af99ddd48281039"
