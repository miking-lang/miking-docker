.PHONY: build run rm tag-latest

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile

IMAGENAME=miking
VERSION=0.0.0-dev1-$(VERSION_SUFFIX)
LATEST_VERSION=latest-$(VERSION_SUFFIX)

build:
	sudo docker build --tag $(IMAGENAME):$(VERSION) \
	                  --force-rm \
	                  --file Dockerfile \
	                  ..
	sudo docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):$(LATEST_VERSION)

run:
	sudo docker run --rm -it \
	                --name $(IMAGENAME) \
	                --hostname $(IMAGENAME) \
	                $(IMAGENAME):$(VERSION)

rm:
	sudo docker rmi $(IMAGENAME):$(VERSION)

tag-latest:
	sudo docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):latest
