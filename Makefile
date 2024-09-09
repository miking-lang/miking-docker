.PHONY: build-baseline \
        build-miking \
        build-miking-dppl \
        list-baselines

# This can be overriden to use podman by CONTAINER_RUNTIME=podman
CONTAINER_RUNTIME ?= docker

SHELL = bash

VERSION_BASELINE    = v8
VERSION_MIKING      = dev12
VERSION_MIKING_DPPL = dev1

IMAGENAME_BASELINE    = mikinglang/baseline
IMAGENAME_MIKING      = mikinglang/miking
IMAGENAME_MIKING_DPPL = mikinglang/miking-dppl

BUILD_LOGDIR = _logs

MIKING_GIT_REMOTE = https://github.com/miking-lang/miking.git
MIKING_GIT_COMMIT = fdce4618293c562bb56eb01028bb4db3358a5ddf

MIKING_DPPL_GIT_REMOTE = https://github.com/miking-lang/miking-dppl.git
MIKING_DPPL_GIT_COMMIT = 960519a6afd2f6edd50a5c5b6f404314c732d0a3

VALIDATE_ARCH_SCRIPT  = ./scripts/validate_architecture.py
VALIDATE_IMAGE_SCRIPT = ./scripts/validate_image.py

BASELINES_AMD64 = alpine3.20 debian12.6 cuda11.4
BASELINES_ARM64 = alpine3.20 debian12.6


list-baselines:
	@echo $(foreach f, $(shell ls baselines/*.Dockerfile), $(shell basename "$f" .Dockerfile))

define FOREACH_NEWLINE


endef

# Example usages:
#  - `make build-baseline-all-linux-amd64`
#  - `make build-miking-dppl-all-linux-arm64`
%-all-linux-amd64:
	$(foreach be, $(BASELINES_AMD64), make $* BASELINE=$(be) ARCH=linux/amd64 ${FOREACH_NEWLINE})

%-all-linux-arm64:
	$(foreach be, $(BASELINES_ARM64), make $* BASELINE=$(be) ARCH=linux/arm64 ${FOREACH_NEWLINE})



# Provide the image and target with
#    BASELINE=name
#    ARCH=arch
build-baseline:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+baseline_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := baselines/$(BASELINE).Dockerfile)
	$(eval IMAGE_TAG := $(IMAGENAME_BASELINE):$(VERSION_BASELINE)-$(BASELINE)-$(subst /,-,$(ARCH)))

	@if [[ -z "$(BASELINE)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; \
	     exit 1; \
	 fi
	@if [[ -z "$(ARCH)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Architecture not provided (provide with ARCH=arch)"; \
	     exit 1; \
	 fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:   \033[0m $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:  \033[0m $(BASELINE)"
	@echo -e " - \033[1;36march:      \033[0m $(ARCH)"
	@echo -e " - \033[1;36mimage tag: \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36muid:       \033[0m $(UID)"
	@echo -e " - \033[1;36mgid:       \033[0m $(GID)"
	@echo -e " - \033[1;36mlogfile:   \033[0m $(LOGFILE)"
	@echo -e " - \033[1;36mdockerfile:\033[0m $(DOCKERFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(CONTAINER_RUNTIME) build \
	    --tag "$(IMAGE_TAG)" \
	    --force-rm \
	    --progress=plain \
	    --platform="$(ARCH)" \
	    --build-arg "TARGETPLATFORM=$(ARCH)" \
	    --file "$(DOCKERFILE)" \
	    . 2>&1 | tee -a $(LOGFILE)

	$(VALIDATE_IMAGE_SCRIPT) "$(IMAGE_TAG)" --arch="$(ARCH)" --runtime="$(CONTAINER_RUNTIME)"


# Provide the image and target with
#    BASELINE=name
#    ARCH=arch
build-miking:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := Dockerfile-miking)
	$(eval IMAGE_TAG := $(IMAGENAME_MIKING):$(VERSION_MIKING)-$(BASELINE)-$(subst /,-,$(ARCH)))
	$(eval BASELINE_TAG := $(IMAGENAME_BASELINE):$(VERSION_BASELINE)-$(BASELINE)-$(subst /,-,$(ARCH)))

	@if [[ -z "$(BASELINE)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; \
	     exit 1; \
	 fi
	@if [[ -z "$(ARCH)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Architecture not provided (provide with ARCH=arch)"; \
	     exit 1; \
	 fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:     \033[0m $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:    \033[0m $(BASELINE)"
	@echo -e " - \033[1;36march:        \033[0m $(ARCH)"
	@echo -e " - \033[1;36mimage tag:   \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36mbaseline tag:\033[0m $(BASELINE_TAG)"
	@echo -e " - \033[1;36muid:         \033[0m $(UID)"
	@echo -e " - \033[1;36mgid:         \033[0m $(GID)"
	@echo -e " - \033[1;36mlogfile:     \033[0m $(LOGFILE)"
	@echo -e " - \033[1;36mdockerfile:  \033[0m $(DOCKERFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(CONTAINER_RUNTIME) build \
	    --tag "$(IMAGE_TAG)" \
	    --force-rm \
	    --progress=plain \
	    --platform="$(ARCH)" \
	    --build-arg "TARGETPLATFORM=$(ARCH)" \
	    --build-arg "BASELINE_IMAGE=$(BASELINE_TAG)" \
	    --build-arg "MIKING_GIT_REMOTE=$(MIKING_GIT_REMOTE)" \
	    --build-arg "MIKING_GIT_COMMIT=$(MIKING_GIT_COMMIT)" \
	    --file "$(DOCKERFILE)" \
	    . 2>&1 | tee -a $(LOGFILE)

	$(VALIDATE_IMAGE_SCRIPT) "$(IMAGE_TAG)" --arch="$(ARCH)" --runtime="$(CONTAINER_RUNTIME)"


# Provide the image and target with
#    BASELINE=name
#    ARCH=arch
build-miking-dppl:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := Dockerfile-miking-dppl)
	$(eval MIKING_TAG := $(IMAGENAME_MIKING):$(VERSION_MIKING)-$(BASELINE)-$(subst /,-,$(ARCH)))
	$(eval IMAGE_TAG := $(VERSION_MIKING_DPPL):$(IMAGENAME_MIKING_DPPL)-$(BASELINE)-$(subst /,-,$(ARCH)))

	@if [[ -z "$(BASELINE)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; \
	     exit 1; \
	 fi
	@if [[ -z "$(ARCH)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Architecture not provided (provide with ARCH=arch)"; \
	     exit 1; \
	 fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:     \033[0m $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:    \033[0m $(BASELINE)"
	@echo -e " - \033[1;36march:        \033[0m $(ARCH)"
	@echo -e " - \033[1;36mimage tag:   \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36mmiking tag:  \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36muid:         \033[0m $(UID)"
	@echo -e " - \033[1;36mgid:         \033[0m $(GID)"
	@echo -e " - \033[1;36mlogfile:     \033[0m $(LOGFILE)"
	@echo -e " - \033[1;36mdockerfile:  \033[0m $(DOCKERFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(CONTAINER_RUNTIME) build \
	    --tag "$(IMAGE_TAG)" \
	    --force-rm \
	    --progress=plain \
	    --platform="$(ARCH)" \
	    --build-arg "TARGETPLATFORM=$(ARCH)" \
	    --build-arg "MIKING_IMAGE=$(MIKING_TAG)" \
	    --build-arg "MIKING_DPPL_GIT_REMOTE=$(MIKING_DPPL_GIT_REMOTE)" \
	    --build-arg "MIKING_DPPL_GIT_COMMIT=$(MIKING_DPPL_GIT_COMMIT)" \
	    --file "$(DOCKERFILE)" \
	    . 2>&1 | tee -a $(LOGFILE)

	$(VALIDATE_IMAGE_SCRIPT) "$(IMAGE_TAG)" --arch="$(ARCH)" --runtime="$(CONTAINER_RUNTIME)"


# TODO: Test GPU functionality with Miking
#test-gpu:
#	docker run --rm -it --gpus all \
#	           --name miking-test-gpu \
#	           --hostname miking-test-gpu \
#	           $(IMAGENAME):$(VERSION)-$* \
#	           make -C /src/miking install test-accelerate

# Provide with
#    BASELINE=arch
manifests:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := Dockerfile-miking)
	$(eval MIKING_TAG_NOARCH := $(IMAGENAME_MIKING):$(VERSION_MIKING)-$(BASELINE))
	$(eval BASELINE_TAG := $(IMAGENAME_BASELINE):$(VERSION_BASELINE)-$(BASELINE)-$(subst /,-,$(ARCH)))
	$(eval AMENDMENTS := $(shell \
	  if echo "$(BASELINES_AMD64)" | grep -w -q "$(BASELINE)"; then \
	    echo "--amend $(MIKING_TAG_NOARCH)-linux-amd64"; \
	  fi; \
	  if echo "$(BASELINES_ARM64)" | grep -w -q "$(BASELINE)"; then \
	    echo "--amend $(MIKING_TAG_NOARCH)-linux-arm64"; \
	  fi   \
	 ))

	@if [[ -z "$(BASELINE)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; \
	     exit 1; \
	 fi

	@echo $(AMENDMENTS)

	echo "TODO"



# TODO: Convert these functions to work with the new setup
#push:
#	@echo -e "\033[1;31mSpecify the platform you are pushing for with \033[1;37mmake push/<arch>\033[0m"
#
#push/%:
#	$(VALIDATE_ARCH_SCRIPT) $*
#	docker push $(IMAGENAME):$(VERSION)-$*
#
#push-manifests:
#	$(eval AMENDMENTS := $(shell \
#	  if [[ "$(VERSION_SUFFIX)" == "alpine" ]]; then \
#	    echo "$(foreach a,amd64 arm64,--amend $(IMAGENAME):$(VERSION)-$a)"; \
#	  else \
#	    echo "--amend $(IMAGENAME):$(VERSION)-amd64"; \
#	  fi   \
#	 ))
#	echo $(AMENDMENTS)
#
#	# Using the || true since there is no -f option to `manifest rm`
#	docker manifest rm $(IMAGENAME):$(VERSION) || true
#	docker manifest rm $(IMAGENAME):$(LATEST_VERSION) || true
#	docker manifest create $(IMAGENAME):$(VERSION) $(AMENDMENTS)
#	docker manifest create $(IMAGENAME):$(LATEST_VERSION) $(AMENDMENTS)
#	docker manifest push --purge $(IMAGENAME):$(VERSION)
#	docker manifest push --purge $(IMAGENAME):$(LATEST_VERSION)
#	if [[ "$(LATEST_VERSION)" == "$(LATEST_ALIAS)" ]]; then \
#		docker manifest rm $(IMAGENAME):latest || true; \
#		docker manifest create $(IMAGENAME):latest $(AMENDMENTS); \
#		docker manifest push --purge $(IMAGENAME):latest; \
#	fi
#
#run:
#	@echo -e "\033[1;31mSpecify the platform you are running on with \033[1;37mmake run/<arch>\033[0m"
#
#run/%:
#	docker run --rm -it \
#	           --name miking \
#	           --hostname miking \
#	           $(IMAGENAME):$(VERSION)-$* \
#	           bash
#
#rmi:
#	docker rmi $(IMAGENAME):$(VERSION)-$* $(IMAGENAME):$(VERSION)
#
#rmi-latest-version:
#	docker rmi $(IMAGENAME):$(LATEST_VERSION)
#
#rmi-latest:
#	docker rmi $(IMAGENAME):latest
#
#rmi-all: rmi rmi-latest-version rmi-latest


