# Miking Docker Image

This is the Miking Docker image supported by https://miking.org. The image
provides a prebuilt Miking toolchain `mi` along with dependencies to recompile
the Miking toolchain as well as to run the features present in the standard
library.

The default Miking image with the `latest-alpine` tag is based on the
[Alpine Linux image](https://hub.docker.com/_/alpine). This has support for the
features that does not require GPU acceleration. If GPU acceleration is
required, then use the `latest-cuda` tag instead.

### Architecture Support

 * `latest-alpine`: linux/amd64, linux/arm64/v8
 * `latest-cuda`: linux/amd64

The `latest` tag is an alias for `latest-alpine`.

## Basic Usage
The Miking image is best run interractively as:

```
docker run --rm -it -v $(pwd):/mnt:ro mikinglang/miking bash
```

This launches a bash shell where `mi` can be run with read-only access to your
current directory. If you wish to extract results generated from running a
Miking program, then add another mounted directory with write permissions where
your program can place its output files.

### CUDA Runtime Dependencies

If you wish to use any GPU features from Miking then you need to use the
`latest-cuda` tag, for example like:

```
docker run --rm -it \
           --gpus all \
           -v $(pwd):/mnt:ro \
           mikinglang/miking:latest-cuda bash
```

The `latest-cuda` tag is based on Ubuntu with CUDA 11.4. As such, **CUDA with
version 11.4 or greater** is required on the host system in order to run the
miking-cuda image. See the docker documentation on
[Runtime options with Memory, CPUs, and GPUs](https://docs.docker.com/config/containers/resource_constraints/#gpu)
for information on how to set up docker on the host system to work with GPUs.
