.PHONY: build run tag-latest rmi rmi-latest-version rmi-latest rmi-all

# Imports the following variables:
#  - LATEST_VERSION
#  - MIKING_GIT_REMOTE
#  - MIKING_GIT_COMMIT
#  - MIKING_IMAGENAME
#  - MIKING_IMAGEVERSION
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
#  - BUILD_LOGDIR
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(MIKING_IMAGENAME)
VERSION=$(MIKING_IMAGEVERSION)

VALIDATE_SCRIPT=docker inspect "$(IMAGENAME):$(VERSION)" | ../scripts/validate_image.py

# The subfolder's makefile shall set the following variables:
#  - DOCKERFILE

build:
	@echo -e "\033[1;31mSpecify the platform you are building for with \033[1;37mmake build/<arch>\033[0m"

build/%:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))
	mkdir -p $(BUILD_LOGDIR)
	chown $(UID):$(GID) $(BUILD_LOGDIR)

	docker build --tag $(IMAGENAME):$(VERSION) \
	             --force-rm \
	             --progress=plain \
	             --build-arg "BASELINE_IMAGE=$(BASELINE_IMAGENAME):$(BASELINE_IMAGEVERSION)" \
	             --build-arg "MIKING_GIT_REMOTE=$(MIKING_GIT_REMOTE)" \
	             --build-arg "MIKING_GIT_COMMIT=$(MIKING_GIT_COMMIT)" \
	             --file $(DOCKERFILE) \
	             .. 2>&1 | tee $(LOGFILE)
	chown $(UID):$(GID) $(LOGFILE)
	$(VALIDATE_SCRIPT) --arch=$*

	docker tag $(IMAGENAME):$(VERSION) $(IMAGENAME):$(LATEST_VERSION)

inspect:
	$(VALIDATE_SCRIPT)

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
