# Miking Docker Images
Docker Environment for compiling and running miking/mcore programs. Each kind
of image is placed under its own directory.

## Build Dependencies

The following dependencies are needed to build the docker images:

* `docker` (with a running deamon in the background)
* `make`
* `sudo`

## CUDA Runtime Dependencies

The miking-cuda image is based on CUDA 11.4. As such, **CUDA with version 11.4
or greater** is required on the host system in order to run the miking-cuda
image. See the docker documentation on
[Runtime options with Memory, CPUs, and GPUs](https://docs.docker.com/config/containers/resource_constraints/#gpu)
for information on how to set up docker on the host system to work with GPUs.

It is still possible to build the miking-cuda image without CUDA installed on
the host system.

# Build

The images are configured to be built via makefiles. Build the image with its
Dockerfile in the directory `<DIR>` by running the following in at the
top-level of the repository (replacing `<arch>` by either amd64 or arm64):

```sh
make -C <DIR> build/<arch>
```

Each miking image is based on a baseline image. **Before building a miking
image, its corresponding baseline image has to be built.**

For example, before building the `miking-alpine` image, the matching
`baseline-alpine` image has to be built first. Build it by running make on its
directory:

```sh
make -C baseline-alpine build/<arch>
```

This will create baseline image `mikinglang/baseline:<basever>-alpine` which
contains all the necessary dependencies to build the miking compiler, but not
the compiler itself. After the baseline image has been built, the
`miking-alpine` image can now be built by running make on its directory:

```sh
make -C miking-alpine build/<arch>
```

This will create the versioned image `mikinglang/miking:<miver>-alpine` as well
as the `mikinglang/miking:latest-alpine` tag for the created image. To tag an
image as _the_ latest miking image, use the `tag-latest` makefile rule. For
example:

```sh
make -C miking-alpine tag-latest
```

This will create the tagged image `mikinglang/miking:latest`. This allows the
instatiation of a container with the short-hand `mikinglang/miking` image name
instead of writing the specific version.

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
