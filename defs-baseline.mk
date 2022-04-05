.PHONY: build rm

# Imports the following variables:
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(BASELINE_IMAGENAME)
VERSION=$(BASELINE_IMAGEVERSION)

build:
	docker build --tag $(IMAGENAME):$(VERSION) \
	             --force-rm \
	             --file Dockerfile \
	             ..

rm:
	docker rmi $(IMAGENAME):$(VERSION)
