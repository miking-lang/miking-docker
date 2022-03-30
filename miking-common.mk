.PHONY: build run rm tag-latest

# NOTE: VERSION_SUFFIX to be set in subfolders' Makefile

IMAGENAME=mikinglang/miking
VERSION=dev2-$(VERSION_SUFFIX)
LATEST_VERSION=latest-$(VERSION_SUFFIX)

build:
	sudo docker build --tag $(IMAGENAME):$(VERSION) \
	                  --force-rm \
	                  --file Dockerfile \
	                  ..
	sudo docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):$(LATEST_VERSION)

push:
	sudo docker push $(IMAGENAME):$(VERSION)
	sudo docker push $(IMAGENAME):$(LATEST_VERSION)

run:
	sudo docker run --rm -it \
	                --name $(IMAGENAME) \
	                --hostname $(IMAGENAME) \
	                $(IMAGENAME):$(VERSION)

rm:
	sudo docker rmi $(IMAGENAME):$(VERSION)

tag-latest:
	sudo docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):latest

push-latest:
	sudo docker push $(IMAGENAME):latest
