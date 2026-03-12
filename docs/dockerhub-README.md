# Miking Docker Image

This is the Miking Docker image supported by https://miking.org. The image
provides a prebuilt Miking toolchain `mi` along with dependencies to recompile
the Miking toolchain as well as to run the features present in the standard
library.

## Basic Usage
The Miking image is best run interractively as:

```
docker run --rm -it -v $(pwd):/mnt:ro -w /mnt mikinglang/miking bash
```

This launches a bash shell where `mi` can be run with read-only access to your
current directory. If you wish to extract results generated from running a
Miking program, then add another mounted directory with write permissions where
your program can place its output files.

### Architecture Support

The default Miking image with the `latest` tag is based on Debian 13.2. We also
provide additional baselines that can be specified with `latest-<baseline>` or
`<ver>-<baseline>`, e.g. `latest-debian13.2`. These baselines, and their
supported architectures, are:

 * [`debian13.2`](https://hub.docker.com/_/debian): linux/amd64, linux/arm64/v8

### Using tup

Miking has support for using `tup` to do more intelligent testing when modifying files. However, since tup depends on fuse, you need to provide the following arguments when using tup inside the docker container:

```
--cap-add SYS_ADMIN --device /dev/fuse
```
