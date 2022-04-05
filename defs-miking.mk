.PHONY: build run tag-latest rm rm-latest-version rm-latest rm-all

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
	           --name $(IMAGENAME) \
	           --hostname $(IMAGENAME) \
	           $(IMAGENAME):$(VERSION)

tag-latest:
	docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):latest

push-latest:
	docker push $(IMAGENAME):latest

rm:
	docker rmi $(IMAGENAME):$(VERSION)

rm-latest-version:
	docker rmi $(IMAGENAME):$(LATEST_VERSION)

rm-latest:
	docker rmi $(IMAGENAME):latest

rm-all: rm rm-latest-version rm-latest
