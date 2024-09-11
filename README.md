# Miking Docker Images

Docker images for compiling and running Miking/MCore programs. Produces images
for a selected number of base images, located under the `baselines/` directory.
The images produced by this repository are:

 * `mikinglang/baseline`
 * `mikinglang/miking`
 * `mikinglang/miking-dppl`

The baseline images contains all dependencies of Miking, excluding Miking
itself. These are primarily used to avoid recompiling all dependencies on new
releases of Miking, but they can also serve as a development environment for
quickly getting started on tinkering with Miking.

This readme contains development and build instructions only. For usage
instructions, see the [Docker Hub README](docs/dockerhub-README.md) file in the
`docs/` directory.


### Build Dependencies

The following dependencies are needed to build the docker images:

* `docker` or `podman`
* `make`

**If using podman**, make sure that the environment variable `CONTAINER_RUNTIME` is
set to `podman`. Before running any of the commands below, the easiest approach
is simply to export this variable by running:

```sh
export CONTAINER_RUNTIME=podman
```

**If using docker**, you have to prefix the commands below with `sudo` if you
cannot execute docker as your regular user.


### CUDA Runtime Dependencies

See CUDA Runtime Dependencies section in the dockerhub README under `docs/`. It
is still possible to build the cuda images without CUDA installed on the host
system. Though the testing of the image has to be done on a system with CUDA.


## Table of Contents

 * [Build](#build)
   * [Individual Baseline Image](#baseline-image)
   * [Individual Miking Image](#miking-image)
   * [Individual Miking DPPL Image](#miking-image)
   * [All Images](#miking-image)
 * [Pushing to Docker Hub](#pushing-to-docker-hub)
   * [Pushing Images](#pushing-images)
   * [Pushing Manifests](#pushing-manifests)
 * [Running the Image](#running-the-image)
   * [Verify Compilation](#verify-compilation)
 * [Contributing](#contributing)
   * [Pull Requests](#pull-requests)


## Build

When building an image, you always provide the hardware architecture you want
to build for as well as the baseline it should be based on. The command to
build an image follow this format:

```sh
make build-<image> ARCH=<os/arch> BASELINE=<baseline>
```

Run `print-variables` to see which baselines that are available for any given
hardware architecture.


### Individual Baseline Image

Using the `debian12.6` baseline for x86_64 as an example, we build it by
running:

```sh
make build-baseline ARCH=linux/amd64 BASELINE=debian12.6
```

This will create the `mikinglang/baseline:<ver>-debian12.6-linux-amd64` image.


### Individual Miking Image

After the baseline image has been built, the `miking` image can now be built
by:

```sh
make build-miking ARCH=linux/amd64 BASELINE=debian12.6
```

This will create the versioned image
`mikinglang/miking:<miver>-debian12.6-linux-amd64`.


### Individual Miking DPPL Image

After the `miking` image has been built, the `miking-dppl` image can now be
built by:

```sh
make build-miking-dppl ARCH=linux/amd64 BASELINE=debian12.6
```

This will create the versioned image
`mikinglang/miking-dppl:<dpplver>-debian12.6-linux-amd64`.


### All Images

For convenience, a collection of make rules are provided to build images for
all baselines. These commands usually take a long time to run, so it is
recommended to spawn them with `nohup <cmd> &` and go do something else while
they are running.

To build all images for all baselines, run the corresponding command for each
kind of image:

* **baseline**: `make build-baseline-all-<os/arch>`
* **miking**: `make build-miking-all-<os/arch>`
* **miking-dppl**: `make build-miking-dppl-all-<os/arch>`

To build **ALL** images, run the command below. This requires that your podman
or docker installation supports cross-platform builds. **Warning: This will
likely take a very long time.**

```sh
make build-baseline-all-linux/amd64 \
     build-baseline-all-linux/arm64 \
     build-miking-all-linux/amd64 \
     build-miking-all-linux/arm64 \
     build-miking-dppl-all-linux/amd64 \
     build-miking-dppl-all-linux/arm64
```


## Pushing to Docker Hub

These instructions concerns the pushing of images to Docker Hub. If you are a
developer and need to have push access, contact the core Miking team.


### Pushing Images

Sticking with the example of `debian12.6` for `linux/amd64`, push the build
images to Docker Hub by running:

```sh
make push-baseline ARCH=linux/amd64 BASELINE=debian12.6
make push-miking   ARCH=linux/amd64 BASELINE=debian12.6
```

The primary reason for pushing baseline images is to avoid having to recreate
them on new releases of Miking. Hence we do not create any manifests for these
images.


### Pushing Manifests

Once all architectures have been built and pushed for an image, push the
manifests to Docker Hub by the following make rule:

```sh
make push-manifest-miking
```

This will create manifests for the following tags:

 * `mikinglang/miking:latest`
 * `mikinglang/miking:latest-<baseline>`
 * `mikinglang/miking:<miver>`
 * `mikinglang/miking:<miver>-<baseline>`

The baseline used for `latest` and `<miver>` tags is specified by the
`BASELINE_IMPLICIT` variable shown when running `make print-variables`.

## Running the Image

To verify that the build image can evaluate and compile MCore programs, the
_test_ directory contains a _sample.mc_ program to test with.


### Verify Evaluation

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

### Verify Compilation

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
