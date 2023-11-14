# Miking Docker Images
Docker Environment for compiling and running miking/mcore programs. Each kind
of image is placed under its own directory.

This readme contains development and build instructions only. For usage
instructions, see the [Docker Hub README](docs/dockerhub-README.md) file in the
`docs/` directory.

## Build Dependencies

The following dependencies are needed to build the docker images:

* `docker` (with a running Docker deamon in the background)
* `make`
* `sudo`

## CUDA Runtime Dependencies

See CUDA Runtime Dependencies section in the dockerhub README under `docs/`. It
is still possible to build the miking-cuda image without CUDA installed on the
host system.

# Table of Contents

 * [Build](#build)
 * [Running the Image](#running-the-image)
   * [Verify Compilation](#verify-compilation)
 * [Contributing](#contributing)
   * [Pull Requests](#pull-requests)

# Build

The images are configured to be built via makefiles. Build the image with its
Dockerfile in the directory `<DIR>` by running the following in at the
top-level of the repository (replacing `<arch>` by either amd64 or arm64):

```sh
make -C <DIR> build/<arch>
```

Each miking image is based on a baseline image. **Before building a miking
image, its corresponding baseline image has to be built.** If the correct
baseline image already exists on Docker Hub, that can be pulled directly
instead and you can skip the "Baseline Image" step below.

## Baseline Image

Taking the alpine image as an example, before building the `miking-alpine`
image, the matching `baseline-alpine` image has to be built first. Build it
for amd64/x86_64 by running make on its directory:

```sh
make -C baseline-alpine build/amd64
```

This will create baseline image `mikinglang/baseline:<basever>-alpine-amd64`
which contains all the necessary dependencies to build the miking compiler, but
not the compiler itself. The `<arch>` part is necessary to specify some
compiler options for certain dependencies.

## Miking Image

After the baseline image has been built, the `miking-alpine` image can now be
built by running make on its directory:

```sh
make -C miking-alpine build/amd64
```

This will create the versioned image `mikinglang/miking:<miver>-alpine-amd64`.
This image can then be used directly, or pushed up to Docker Hub. To push it up
to Docker Hub, make sure that you have push access to the mikinglang repository
and then run the make rule (replace `amd64` with the architecture of your
platform):

```sh
make -C miking-alpine push/amd64
```

Each image should be built for the following architectures:

 * miking-alpine: `amd64`, `arm64`
 * miking-cuda: `amd64`

Once all architectures have been built and pushed for an image, push the
manifests to Docker Hub by the following make rule:

```sh
make -C miking-alpine push-manifests
```

This will make the `mikinglang/miking:latest-alpine` tag available on Docker
Hub. In the case of `make -C miking-cuda push-manifests`, the
`mikinglang/miking:latest-cuda` tag would be available on Docker Hub. If image
marked as the `LATEST_ALIAS` has its manifest pushed, then the
`mikinglang/miking:latest` tag would also be available on Docker Hub.

# Running the Image

To verify that the build image can evaluate and compile MCore programs, the
_test_ directory contains a _sample.mc_ program to test with.

## Verify Evaluation

Run the following command:

```sh
sudo docker run --rm -it -v $(pwd)/test:/mnt:ro mikinglang/miking:<ver> mi eval /mnt/sample.mc
```

This should produce the following output:

```
Found msg: "foo"
Found msg: "bar"
Found nothing.
```

## Verify Compilation

**NOTE:** Compilation is highly specific to the target platform. If planning to
run the compiled program outside the docker container, verify that your binary
will work for your host environment by running `ldd <binary>`. Ideally,
choosing an image version similar to the host system should produce a
compatible binary.

Run the following command to compile and run it:

```sh
sudo docker run --rm -it -v $(pwd)/test:/mnt:ro mikinglang/miking:<ver> bash -c "mi compile /mnt/sample.mc --output /tmp/sample && /tmp/sample"
```

This should produce the same output as for the evaluation case above. To export
the compiled binary out from the container, either mount the /mnt folder
without the ":ro" part or mount another folder that is writable from the
container. Then change the `--output` flag to point to that directory instead
of the /tmp directory.

# Contributing

To contribute to this repository, fork it, add your changes to a branch on your
fork, submit your changes as a pull request from that branch.

## Pull Requests

Each pull request shall contain a record of all the targets that builds have
been validated for. Copy paste this checklist to your PR description:

```
**Validated builds:**

- [ ] miking-alpine (amd64 / x86_64)
- [ ] miking-alpine (arm64 / M1 Mac)
- [ ] miking-cuda (amd64 / x86_64)

**Validated GPU tests:**

- [ ] miking-cuda (amd64 / x86_64)
```

It should look like this when formatted by GitHub:

**Validated builds:**

- [ ] miking-alpine (amd64 / x86_64)
- [ ] miking-alpine (arm64 / M1 Mac)
- [ ] miking-cuda (amd64 / x86_64)

**Validated GPU tests:**

- [ ] miking-cuda (amd64 / x86_64)

Tick each box under "Validated builds" once the build is validated. A build is
validated when the miking image successfully builds with all tests passing. If
an image is also listed under "Validated GPU tests", the command
`make -C <DIR> test-gpu/<arch>` must also be run which runs additional tests
with a GPU. Tick the box if and only if this test has also succeeded.
