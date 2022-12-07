.PHONY: build rmi

# Imports the following variables:
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(BASELINE_IMAGENAME)
VERSION=$(BASELINE_IMAGEVERSION)

build:
	@echo -e "\033[1;31mSpecify the platform you are building for with \033[1;37mmake build/<arch>\033[0m"

build/%:
	@if [[ ! ("$*" == "arm64" || "$*" == "amd64") ]]; then   \
	     echo -e "\033[1;31mInvalid platform \"$*\"\033[0m"; \
	     exit 1;                                             \
	 fi
	$(eval PLATFORM_OWL_CFLAGS := $(shell \
	  if [[ "$*" == "amd64" ]]; then      \
	    echo "-mfpmath=sse -msse2";       \
	  else                                \
	    echo "";                          \
	  fi                                  \
	 ))
	docker build --tag $(IMAGENAME):$(VERSION) \
	             --force-rm \
	             --build-arg "PLATFORM_OWL_CFLAGS=$(PLATFORM_OWL_CFLAGS)" \
	             --file Dockerfile \
	             ..

rmi:
	docker rmi $(IMAGENAME):$(VERSION)
