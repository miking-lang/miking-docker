.PHONY: build rmi

# Imports the following variables:
#  - BASELINE_IMAGENAME
#  - BASELINE_IMAGEVERSION
#  - BUILD_LOGDIR
include ../defs-common.mk
# NOTE: The ../ is because this file is imported from a child directory

IMAGENAME=$(BASELINE_IMAGENAME)
VERSION=$(BASELINE_IMAGEVERSION)

VALIDATE_IMAGE_SCRIPT=docker inspect "$(IMAGENAME):$(VERSION)" | ../scripts/validate_image.py
VALIDATE_ARCH_SCRIPT="../scripts/validate_architecture.sh"

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

	$(eval PLATFORM_OWL_CFLAGS := $(shell \
	  if [[ "$*" == "amd64" ]]; then      \
	    echo "-mfpmath=sse -msse2";       \
	  else                                \
	    echo "";                          \
	  fi                                  \
	 ))
	docker build --tag $(IMAGENAME):$(VERSION) \
	             --force-rm \
	             --progress=plain \
	             --build-arg "PLATFORM_OWL_CFLAGS=$(PLATFORM_OWL_CFLAGS)" \
	             --file Dockerfile \
	             .. 2>&1 | tee -a $(LOGFILE)
	$(VALIDATE_IMAGE_SCRIPT) --arch=$*

inspect:
	$(VALIDATE_IMAGE_SCRIPT)

rmi:
	docker rmi $(IMAGENAME):$(VERSION)
