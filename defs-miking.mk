.PHONY: build run tag-latest rmi rmi-latest-version rmi-latest rmi-all

# Imports the following variables:
#  - LATEST_VERSION
#  - MIKING_COMMIT
#  - MIKING_IMAGENAME
#  - MIKING_IMAGEVERSION
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(MIKING_IMAGENAME)
VERSION=$(MIKING_IMAGEVERSION)

# The subfolder's makefile shall set the following variables:
#  - DOCKERFILE

build:
	@echo -e "\033[1;31mSpecify the platform you are building for with \033[1;37mmake build/<arch>\033[0m"

build/%:
	docker build --tag $(IMAGENAME):$(VERSION) \
	             --force-rm \
	             --build-arg "BASELINE_IMAGE=$(BASELINE_IMAGENAME):$(BASELINE_IMAGEVERSION)" \
	             --build-arg "MIKING_COMMIT=$(MIKING_COMMIT)" \
	             --file $(DOCKERFILE) \
	             ..
	docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):$(LATEST_VERSION)

push:
	docker push $(IMAGENAME):$(VERSION)
	docker push $(IMAGENAME):$(LATEST_VERSION)

run:
	docker run --rm -it \
	           --name miking \
	           --hostname miking \
	           $(IMAGENAME):$(VERSION) \
	           bash

tag-latest:
	docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):latest

push-latest:
	docker push $(IMAGENAME):latest

rmi:
	docker rmi $(IMAGENAME):$(VERSION)

rmi-latest-version:
	docker rmi $(IMAGENAME):$(LATEST_VERSION)

rmi-latest:
	docker rmi $(IMAGENAME):latest

rmi-all: rmi rmi-latest-version rmi-latest
