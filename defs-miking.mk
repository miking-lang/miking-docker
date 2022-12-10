.PHONY: build push run rmi rmi-latest-version rmi-latest rmi-all

# Imports the following variables:
#  - LATEST_VERSION
#  - LATEST_ALIAS
#  - MIKING_GIT_REMOTE
#  - MIKING_GIT_COMMIT
#  - MIKING_IMAGENAME
#  - MIKING_IMAGEVERSION
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
#  - BUILD_LOGDIR
#  - VALIDATE_ARCH_SCRIPT
#  - VALIDATE_IMAGE_SCRIPT
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(MIKING_IMAGENAME)
VERSION=$(MIKING_IMAGEVERSION)

# The subfolder's makefile shall set the following variables:
#  - DOCKERFILE

build:
	@echo -e "\033[1;31mSpecify the platform you are building for with \033[1;37mmake build/<arch>\033[0m"

build/%:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))

	$(VALIDATE_ARCH_SCRIPT) $*

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	docker build --tag $(IMAGENAME):$(VERSION)-$* \
	             --force-rm \
	             --progress=plain \
	             --build-arg "TARGETPLATFORM=linux/$*" \
	             --build-arg "BASELINE_IMAGE=$(BASELINE_IMAGENAME):$(BASELINE_IMAGEVERSION)-$*" \
	             --build-arg "MIKING_GIT_REMOTE=$(MIKING_GIT_REMOTE)" \
	             --build-arg "MIKING_GIT_COMMIT=$(MIKING_GIT_COMMIT)" \
	             --file $(DOCKERFILE) \
	             .. 2>&1 | tee -a $(LOGFILE)
	$(VALIDATE_IMAGE_SCRIPT) --arch=$* $(IMAGENAME):$(VERSION)-$*

push:
	@echo -e "\033[1;31mSpecify the platform you are pushing for with \033[1;37mmake push/<arch>\033[0m"

push/%:
	$(VALIDATE_ARCH_SCRIPT) $*
	docker push $(IMAGENAME):$(VERSION)-$*

push-manifests:
	$(eval AMENDMENTS := $(shell \
	  if [[ "$(VERSION_SUFFIX)" == "alpine" ]]; then \
	    echo "$(foreach a,amd64 arm64,--amend $(IMAGENAME):$(VERSION)-$a)"; \
	  else \
	    echo "--amend $(IMAGENAME):$(VERSION)-amd64"; \
	  fi   \
	 ))
	echo $(AMENDMENTS)

	docker manifest create $(IMAGENAME):$(VERSION) $(AMENDMENTS)
	docker manifest create $(IMAGENAME):$(LATEST_VERSION) $(AMENDMENTS)
	docker manifest push $(IMAGENAME):$(VERSION)
	docker manifest push $(IMAGENAME):$(LATEST_VERSION)
	if [[ "$(LATEST_VERSION)" == "$(LATEST_ALIAS)" ]]; then \
		docker manifest create $(IMAGENAME):latest $(AMENDMENTS)
		docker manifest push $(IMAGENAME):latest
	fi

run:
	docker run --rm -it \
	           --name miking \
	           --hostname miking \
	           $(IMAGENAME):$(VERSION) \
	           bash

rmi:
	docker rmi $(IMAGENAME):$(VERSION)-$* $(IMAGENAME):$(VERSION)

rmi-latest-version:
	docker rmi $(IMAGENAME):$(LATEST_VERSION)

rmi-latest:
	docker rmi $(IMAGENAME):latest

rmi-all: rmi rmi-latest-version rmi-latest
