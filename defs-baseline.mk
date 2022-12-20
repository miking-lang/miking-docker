.PHONY: build rmi

# Imports the following variables:
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
#  - BUILD_LOGDIR
#  - VALIDATE_ARCH_SCRIPT
#  - VALIDATE_IMAGE_SCRIPT
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(BASELINE_IMAGENAME)
VERSION=$(BASELINE_IMAGEVERSION)

build:
	@echo -e "\033[1;31mSpecify the platform you are building for with \033[1;37mmake build/<arch>\033[0m"

build/%:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+baseline_%Y-%m-%d_%H.%M.%S.log"))

	$(VALIDATE_ARCH_SCRIPT) $*

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	docker build --tag $(IMAGENAME):$(VERSION)-$* \
	             --force-rm \
	             --progress=plain \
	             --build-arg "TARGETPLATFORM=linux/$*" \
	             --file Dockerfile \
	             .. 2>&1 | tee -a $(LOGFILE)
	$(VALIDATE_IMAGE_SCRIPT) --arch=$* $(IMAGENAME):$(VERSION)-$*

rmi:
	docker rmi $(IMAGENAME):$(VERSION)
