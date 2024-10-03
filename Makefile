.PHONY: print-variables \
        list-baselines \
        build-baseline \
        build-miking \
        build-miking-dppl

# This can be overriden to use podman by CONTAINER_RUNTIME=podman
CONTAINER_RUNTIME ?= docker

ifeq ($(CONTAINER_RUNTIME),docker)
CMD_BUILD    = docker build
CMD_RUN      = docker run
CMD_RUN_CUDA = docker run --gpus all
CMD_PUSH_f   = docker push $1
CMD_MANIFEST = docker manifest
else
CMD_BUILD    = podman build --format=docker
CMD_RUN      = podman run
CMD_RUN_CUDA = podman run --device nvidia.com/gpu=all
CMD_PUSH_f   = podman push $1 docker://docker.io/$1
CMD_MANIFEST = podman manifest
endif

SHELL = bash

VERSION_BASELINE    = v8
VERSION_MIKING      = dev12
VERSION_MIKING_DPPL = dev1

IMAGENAME_BASELINE    = mikinglang/baseline
IMAGENAME_MIKING      = mikinglang/miking
IMAGENAME_MIKING_DPPL = mikinglang/miking-dppl

BUILD_LOGDIR = _logs

MIKING_GIT_REMOTE = https://github.com/miking-lang/miking.git
MIKING_GIT_COMMIT = c36fcc7cf8bae3f2352cc6500a9940b6e8c97476

MIKING_DPPL_GIT_REMOTE = https://github.com/miking-lang/miking-dppl.git
MIKING_DPPL_GIT_COMMIT = 6bad5a74da2538a6d014ee47796dbf298f1a575c

VALIDATE_PLATFORM_SCRIPT = ./scripts/validate_platform.py
VALIDATE_IMAGE_SCRIPT    = ./scripts/validate_image.py

BASELINES_AMD64 = alpine3.20 debian12.6 cuda11.4
BASELINES_ARM64 = alpine3.20 debian12.6

BASELINES_ALL = $(shell echo $(BASELINES_AMD64) $(BASELINES_ARM64) | tr ' ' '\n' | sort | uniq)

BASELINE_IMPLICIT = debian12.6

print-variables:
	@echo -e "\033[4;36mMakefile variables:\033[0m"
	@echo -e " - \033[1;36mCONTAINER_RUNTIME        \033[0m= $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mCMD_BUILD                \033[0m= $(CMD_BUILD)"
	@echo -e " - \033[1;36mCMD_RUN                  \033[0m= $(CMD_RUN)"
	@echo -e " - \033[1;36mCMD_RUN_CUDA             \033[0m= $(CMD_RUN_CUDA)"
	@echo -e " - \033[1;36mCMD_PUSH_f               \033[0m= $(call CMD_PUSH_f,<IMAGE_TAG>)"
	@echo -e " - \033[1;36mCMD_MANIFEST             \033[0m= $(CMD_MANIFEST)"
	@echo -e " - \033[1;36mSHELL                    \033[0m= $(SHELL)"
	@echo -e " - \033[1;36mVERSION_BASELINE         \033[0m= $(VERSION_BASELINE)"
	@echo -e " - \033[1;36mVERSION_MIKING           \033[0m= $(VERSION_MIKING)"
	@echo -e " - \033[1;36mVERSION_MIKING_DPPL      \033[0m= $(VERSION_MIKING_DPPL)"
	@echo -e " - \033[1;36mBUILD_LOGDIR             \033[0m= $(BUILD_LOGDIR)"
	@echo -e " - \033[1;36mMIKING_GIT_REMOTE        \033[0m= $(MIKING_GIT_REMOTE)"
	@echo -e " - \033[1;36mMIKING_GIT_COMMIT        \033[0m= $(MIKING_GIT_COMMIT)"
	@echo -e " - \033[1;36mMIKING_DPPL_GIT_REMOTE   \033[0m= $(MIKING_DPPL_GIT_REMOTE)"
	@echo -e " - \033[1;36mMIKING_DPPL_GIT_COMMIT   \033[0m= $(MIKING_DPPL_GIT_COMMIT)"
	@echo -e " - \033[1;36mVALIDATE_PLATFORM_SCRIPT \033[0m= $(VALIDATE_PLATFORM_SCRIPT)"
	@echo -e " - \033[1;36mVALIDATE_IMAGE_SCRIPT    \033[0m= $(VALIDATE_IMAGE_SCRIPT)"
	@echo -e " - \033[1;36mBASELINES_ALL            \033[0m= $(BASELINES_ALL)"
	@echo -e " - \033[1;36mBASELINES_AMD64          \033[0m= $(BASELINES_AMD64)"
	@echo -e " - \033[1;36mBASELINES_ARM64          \033[0m= $(BASELINES_ARM64)"
	@echo -e " - \033[1;36mBASELINE_IMPLICIT        \033[0m= $(BASELINE_IMPLICIT)"

list-baselines:
	@echo $(foreach f, $(shell ls baselines/*.Dockerfile), $(shell basename "$f" .Dockerfile))

define FOREACH_NEWLINE


endef

# Example usages:
#  - `make build-baseline-all-linux/amd64`
#  - `make build-miking-dppl-all-linux/arm64`
%-all-linux/amd64:
	$(foreach be, $(BASELINES_AMD64), make $* BASELINE=$(be) PLATFORM=linux/amd64 ${FOREACH_NEWLINE})

%-all-linux/arm64:
	$(foreach be, $(BASELINES_ARM64), make $* BASELINE=$(be) PLATFORM=linux/arm64 ${FOREACH_NEWLINE})

# Sequential builds. If baseline is unchanged, it is only necessary to run the
# `seqbuild-from-miking` rule.
seqbuild-from-baseline:
	make build-baseline
	make seqbuild-from-miking
seqbuild-from-miking:
	make build-miking
	make build-miking-dppl

seqbuild-%-all:
	@echo "Starting concurrent builds of all images"; \
	 pids=(); \
	 for baseline in $(BASELINES_AMD64); do \
	   eval "make seqbuild-$* PLATFORM=linux/amd64 BASELINE=\"$$baseline\" > seqbuild-$*-amd64-$$baseline.out &"; \
	   pids+=("$$!"); \
	 done; \
	 for baseline in $(BASELINES_ARM64); do \
	   eval "make seqbuild-$* PLATFORM=linux/arm64 BASELINE=\"$$baseline\" > seqbuild-$*-arm64-$$baseline.out &"; \
	   pids+=("$$!"); \
	 done; \
	 echo "PIDS = $${pids[@]}"; \
	 trap 'kill $${pids[@]}' INT; \
	 wait


# Provide the image and target with
#    BASELINE=name
#    PLATFORM=platform
build-baseline:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+baseline_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := baselines/$(BASELINE).Dockerfile)
	$(eval IMAGE_TAG := $(IMAGENAME_BASELINE):$(VERSION_BASELINE)-$(BASELINE)-$(subst /,-,$(PLATFORM)))

	@if [[ -z "$(BASELINE)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; \
	     exit 1; \
	 fi
	@if [[ -z "$(PLATFORM)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Platform not provided (provide with PLATFORM=arch)"; \
	     exit 1; \
	 fi
	@if [[ ! -z "$$($(CONTAINER_RUNTIME) images -n -f 'reference=$(IMAGE_TAG)')" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image $(IMAGE_TAG) already exists. Remove it before rebuilding."; \
	     exit 1; \
	 fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:    \033[0m$(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:   \033[0m$(BASELINE)"
	@echo -e " - \033[1;36mplatform:   \033[0m$(PLATFORM)"
	@echo -e " - \033[1;36mimage tag:  \033[0m$(IMAGE_TAG)"
	@echo -e " - \033[1;36muid:        \033[0m$(UID)"
	@echo -e " - \033[1;36mgid:        \033[0m$(GID)"
	@echo -e " - \033[1;36mlogfile:    \033[0m$(LOGFILE)"
	@echo -e " - \033[1;36mdockerfile: \033[0m$(DOCKERFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(CMD_BUILD) \
	    --tag "$(IMAGE_TAG)" \
	    --force-rm \
	    --platform="$(PLATFORM)" \
	    $(shell ./baselines/conf.py build-args --platform=$(PLATFORM) --baseline=$(BASELINE)) \
	    --file "$(DOCKERFILE)" \
	    . 2>&1 | tee -a $(LOGFILE)

	$(VALIDATE_IMAGE_SCRIPT) "$(IMAGE_TAG)" --platform="$(PLATFORM)" --runtime="$(CONTAINER_RUNTIME)"


# Provide the image and target with
#    BASELINE=name
#    PLATFORM=platform
build-miking:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := Dockerfile-miking)
	$(eval IMAGE_TAG := $(IMAGENAME_MIKING):$(VERSION_MIKING)-$(BASELINE)-$(subst /,-,$(PLATFORM)))
	$(eval BASELINE_TAG := $(IMAGENAME_BASELINE):$(VERSION_BASELINE)-$(BASELINE)-$(subst /,-,$(PLATFORM)))

	@if [[ -z "$(BASELINE)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; \
	     exit 1; \
	 fi
	@if [[ -z "$(PLATFORM)" ]]; then \
	     echo -e "\033[1;31mERROR:\033[0m Platform not provided (provide with PLATFORM=platform)"; \
	     exit 1; \
	 fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:     \033[0m $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:    \033[0m $(BASELINE)"
	@echo -e " - \033[1;36mplatform:    \033[0m $(PLATFORM)"
	@echo -e " - \033[1;36mimage tag:   \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36mbaseline tag:\033[0m $(BASELINE_TAG)"
	@echo -e " - \033[1;36muid:         \033[0m $(UID)"
	@echo -e " - \033[1;36mgid:         \033[0m $(GID)"
	@echo -e " - \033[1;36mlogfile:     \033[0m $(LOGFILE)"
	@echo -e " - \033[1;36mdockerfile:  \033[0m $(DOCKERFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(CMD_BUILD) \
	    --tag "$(IMAGE_TAG)" \
	    --force-rm \
	    --platform="$(PLATFORM)" \
	    --build-arg="BASELINE_IMAGE=$(BASELINE_TAG)" \
	    --build-arg="MIKING_GIT_REMOTE=$(MIKING_GIT_REMOTE)" \
	    --build-arg="MIKING_GIT_COMMIT=$(MIKING_GIT_COMMIT)" \
	    --file "$(DOCKERFILE)" \
	    . 2>&1 | tee -a $(LOGFILE)

	$(VALIDATE_IMAGE_SCRIPT) "$(IMAGE_TAG)" --platform="$(PLATFORM)" --runtime="$(CONTAINER_RUNTIME)"


# Provide the image and target with
#    BASELINE=name
#    PLATFORM=platform
build-miking-dppl:
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+miking_%Y-%m-%d_%H.%M.%S.log"))
	$(eval DOCKERFILE := Dockerfile-miking-dppl)
	$(eval MIKING_TAG := $(IMAGENAME_MIKING):$(VERSION_MIKING)-$(BASELINE)-$(subst /,-,$(PLATFORM)))
	$(eval IMAGE_TAG := $(IMAGENAME_MIKING_DPPL):$(VERSION_MIKING_DPPL)-$(BASELINE)-$(subst /,-,$(PLATFORM)))

	@if [[ -z "$(BASELINE)" ]]; then echo -e "\033[1;31mERROR:\033[0m Image not provided (provide with BASELINE=name)"; 	     exit 1; fi
	@if [[ -z "$(PLATFORM)" ]]; then echo -e "\033[1;31mERROR:\033[0m Platform not provided (provide with PLATFORM=platform)"; 	     exit 1; fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:     \033[0m $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:    \033[0m $(BASELINE)"
	@echo -e " - \033[1;36mplatform:    \033[0m $(PLATFORM)"
	@echo -e " - \033[1;36mimage tag:   \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36mmiking tag:  \033[0m $(MIKING_TAG)"
	@echo -e " - \033[1;36muid:         \033[0m $(UID)"
	@echo -e " - \033[1;36mgid:         \033[0m $(GID)"
	@echo -e " - \033[1;36mlogfile:     \033[0m $(LOGFILE)"
	@echo -e " - \033[1;36mdockerfile:  \033[0m $(DOCKERFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(CMD_BUILD) \
	    --tag "$(IMAGE_TAG)" \
	    --force-rm \
	    --platform="$(PLATFORM)" \
	    --build-arg="MIKING_IMAGE=$(MIKING_TAG)" \
	    --build-arg="MIKING_DPPL_GIT_REMOTE=$(MIKING_DPPL_GIT_REMOTE)" \
	    --build-arg="MIKING_DPPL_GIT_COMMIT=$(MIKING_DPPL_GIT_COMMIT)" \
	    --file "$(DOCKERFILE)" \
	    . 2>&1 | tee -a $(LOGFILE)

	$(VALIDATE_IMAGE_SCRIPT) "$(IMAGE_TAG)" --platform="$(PLATFORM)" --runtime="$(CONTAINER_RUNTIME)"


# Provide the image and target with
#    IMAGENAME=name
#    IMAGEVERSION=name
#    BASELINE=name
#    PLATFORM=platform
#    TEST_CMD=command
test-image:
	$(eval TEST_RUN := $(CMD_RUN))
	$(eval UID := $(shell if [[ -z "$$SUDO_UID" ]]; then id -u; else echo "$$SUDO_UID"; fi))
	$(eval GID := $(shell if [[ -z "$$SUDO_GID" ]]; then id -g; else echo "$$SUDO_GID"; fi))
	$(eval IMAGE_TAG := $(IMAGENAME):$(IMAGEVERSION)-$(BASELINE)-$(subst /,-,$(PLATFORM)))
	$(eval LOGFILE := $(BUILD_LOGDIR)/$(shell date "+test_$(subst :,-,$(subst /,-,$(IMAGE_TAG)))_%Y-%m-%d_%H.%M.%S.log"))

	@if [[ -z "$(IMAGENAME)" ]]; then echo -e "\033[1;31mERROR:\033[0m Missing IMAGENAME variable"; exit 1; fi
	@if [[ -z "$(IMAGEVERSION)" ]]; then echo -e "\033[1;31mERROR:\033[0m Missing IMAGEVERSION variable"; exit 1; fi
	@if [[ -z "$(BASELINE)" ]]; then echo -e "\033[1;31mERROR:\033[0m Missing BASELINE variable"; exit 1; fi
	@if [[ -z "$(PLATFORM)" ]]; then echo -e "\033[1;31mERROR:\033[0m Missing PLATFORM variable"; exit 1; fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:     \033[0m $(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:    \033[0m $(BASELINE)"
	@echo -e " - \033[1;36mplatform:    \033[0m $(PLATFORM)"
	@echo -e " - \033[1;36mimage tag:   \033[0m $(IMAGE_TAG)"
	@echo -e " - \033[1;36mcommand:     \033[0m $(TEST_CMD)"
	@echo -e " - \033[1;36muid:         \033[0m $(UID)"
	@echo -e " - \033[1;36mgid:         \033[0m $(GID)"
	@echo -e " - \033[1;36mlogfile:     \033[0m $(LOGFILE)"

	mkdir -p $(BUILD_LOGDIR)
	touch $(LOGFILE)
	chown $(UID):$(GID) $(BUILD_LOGDIR) $(LOGFILE)

	$(TEST_RUN) --rm $(IMAGE_TAG) $(TEST_CMD) 2>&1 | tee -a $(LOGFILE)


# Test all AMD64 images
test-all-amd64:
	@# Run miking tests
	$(foreach be, $(BASELINES_AMD64), \
          make test-image IMAGENAME=$(IMAGENAME_MIKING) \
                          IMAGEVERSION=$(VERSION_MIKING) \
                          BASELINE=$(be) \
                          PLATFORM=linux/amd64 \
                          TEST_CMD="make -C /src/miking install test-all test-sundials" \
         ${FOREACH_NEWLINE})
	@# Run miking-dppl tests
	$(foreach be, $(BASELINES_AMD64), \
          make test-image IMAGENAME=$(IMAGENAME_MIKING_DPPL) \
                          IMAGEVERSION=$(VERSION_MIKING_DPPL) \
                          BASELINE=$(be) \
                          PLATFORM=linux/amd64 \
                          TEST_CMD="make -C /src/miking-dppl install test" \
         ${FOREACH_NEWLINE})


# Test all ARM64 images
test-all-arm64:
	@# Run miking tests
	$(foreach be, $(BASELINES_ARM64), \
          make test-image IMAGENAME=$(IMAGENAME_MIKING) \
                          IMAGEVERSION=$(VERSION_MIKING) \
                          BASELINE=$(be) \
                          PLATFORM=linux/arm64 \
                          TEST_CMD="make -C /src/miking install test-all test-sundials" \
         ${FOREACH_NEWLINE})
	@# Run miking-dppl tests
	$(foreach be, $(BASELINES_ARM64), \
          make test-image IMAGENAME=$(IMAGENAME_MIKING_DPPL) \
                          IMAGEVERSION=$(VERSION_MIKING_DPPL) \
                          BASELINE=$(be) \
                          PLATFORM=linux/arm64 \
                          TEST_CMD="make -C /src/miking-dppl install test" \
         ${FOREACH_NEWLINE})


# Test GPU functionality with Miking's CUDA image
test-cuda:
	make test-image IMAGENAME=$(IMAGENAME_MIKING) \
                        IMAGEVERSION=$(VERSION_MIKING) \
                        BASELINE=cuda11.4 \
                        PLATFORM=linux/amd64 \
                        TEST_RUN="$(CMD_RUN_CUDA)" \
                        TEST_CMD="make -C /src/miking install test-accelerate"


# Provide the image and target with
#    IMAGENAME=name
#    IMAGEVERSION=name
#    BASELINE=name
#    PLATFORM=platform
push:
	$(eval IMAGE_TAG := $(IMAGENAME):$(IMAGEVERSION)-$(BASELINE)-$(subst /,-,$(PLATFORM)))

	@if [[ -z "$(IMAGENAME)" ]];    then echo -e "\033[1;31mERROR:\033[0m Imagename not provided (provide with IMAGENAME=imagename)";  exit 1; fi
	@if [[ -z "$(IMAGEVERSION)" ]]; then echo -e "\033[1;31mERROR:\033[0m Image version not provided (provide with IMAGEVERSION=ver)"; exit 1; fi
	@if [[ -z "$(BASELINE)" ]];     then echo -e "\033[1;31mERROR:\033[0m Baseline not provided (provide with BASELINE=name)";         exit 1; fi
	@if [[ -z "$(PLATFORM)" ]];     then echo -e "\033[1;31mERROR:\033[0m Platform not provided (provide with PLATFORM=platform)";     exit 1; fi

	@echo -e "\033[4;36mBuild variables:\033[0m"
	@echo -e " - \033[1;36mruntime:    \033[0m$(CONTAINER_RUNTIME)"
	@echo -e " - \033[1;36mbaseline:   \033[0m$(BASELINE)"
	@echo -e " - \033[1;36mplatform:   \033[0m$(PLATFORM)"
	@echo -e " - \033[1;36mimage tag:  \033[0m$(IMAGE_TAG)"

	$(call CMD_PUSH_f,$(IMAGE_TAG))

push-baseline:
	make push IMAGENAME=$(IMAGENAME_BASELINE) IMAGEVERSION=$(VERSION_BASELINE)

push-miking:
	make push IMAGENAME=$(IMAGENAME_MIKING) IMAGEVERSION=$(VERSION_MIKING)

push-miking-dppl:
	make push IMAGENAME=$(IMAGENAME_MIKING_DPPL) IMAGEVERSION=$(VERSION_MIKING_DPPL)


# Provide the image and target with
#    IMAGENAME=name
#    IMAGEVERSION=name
#    BASELINE=name
push-manifest:
	$(eval IMAGE_TAG := $(IMAGENAME):$(IMAGEVERSION)-$(BASELINE))
	$(eval AMENDMENTS := $(shell \
	  if echo "$(BASELINES_AMD64)" | grep -w -q "$(BASELINE)"; then \
	    echo "--amend $(IMAGE_TAG)-linux-amd64"; \
	  fi; \
	  if echo "$(BASELINES_ARM64)" | grep -w -q "$(BASELINE)"; then \
	    echo "--amend $(IMAGE_TAG)-linux-arm64"; \
	  fi   \
	 ))

	@if [[ -z "$(IMAGENAME)" ]];    then echo -e "\033[1;31mERROR:\033[0m Missing IMAGENAME variable";    exit 1; fi
	@if [[ -z "$(IMAGEVERSION)" ]]; then echo -e "\033[1;31mERROR:\033[0m Missing IMAGEVERSION variable"; exit 1; fi
	@if [[ -z "$(BASELINE)" ]];     then echo -e "\033[1;31mERROR:\033[0m Missing BASELINE variable";     exit 1; fi

	@# Using the || true since there is no -f option to `manifest rm`
	$(CMD_MANIFEST) rm $(IMAGENAME):$(IMAGEVERSION)-$(BASELINE) || true
	$(CMD_MANIFEST) rm $(IMAGENAME):latest-$(BASELINE)          || true
	$(CMD_MANIFEST) create $(IMAGENAME):$(IMAGEVERSION)-$(BASELINE) $(AMENDMENTS)
	$(CMD_MANIFEST) create $(IMAGENAME):latest-$(BASELINE)          $(AMENDMENTS)
	$(CMD_MANIFEST) push --purge $(IMAGENAME):$(IMAGEVERSION)-$(BASELINE)
	$(CMD_MANIFEST) push --purge $(IMAGENAME):latest-$(BASELINE)
ifeq ($(BASELINE),$(BASELINE_IMPLICIT))
	$(CMD_MANIFEST) rm $(IMAGENAME):$(IMAGEVERSION) || true
	$(CMD_MANIFEST) rm $(IMAGENAME):latest          || true
	$(CMD_MANIFEST) create $(IMAGENAME):$(IMAGEVERSION) $(AMENDMENTS)
	$(CMD_MANIFEST) create $(IMAGENAME):latest          $(AMENDMENTS)
	$(CMD_MANIFEST) push --purge $(IMAGENAME):$(IMAGEVERSION)
	$(CMD_MANIFEST) push --purge $(IMAGENAME):latest
endif

push-manifests-miking:
	@# Push miking manifests
	$(foreach be, $(BASELINES_ALL), \
          make push-manifest IMAGENAME=$(IMAGENAME_MIKING) \
                             IMAGEVERSION=$(VERSION_MIKING) \
                             BASELINE=$(be) \
         ${FOREACH_NEWLINE})

push-manifests-miking-dppl:
	@# Push miking-dppl manifests
	$(foreach be, $(BASELINES_ALL), \
          make push-manifest IMAGENAME=$(IMAGENAME_MIKING_DPPL) \
                             IMAGEVERSION=$(VERSION_MIKING_DPPL) \
                             BASELINE=$(be) \
         ${FOREACH_NEWLINE})

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


