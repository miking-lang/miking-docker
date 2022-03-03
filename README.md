# Miking Docker Images
Docker Environment for compiling and running miking/mcore programs. Each kind
of image is placed under its own directory.

## Dependencies

The following dependencies are needed to build the docker images:

* `docker` (with a running deamon in the background)
* `make`
* `sudo`

# Build

The images are configured to be built via makefiles. Build the image with its
Dockerfile in the directory `<DIR>` by running the following in at the
top-level of the repository (the _build_ rule is optional and can be omitted):

```sh
make -C <DIR> build
```

For example, to build the `miking:<ver>-alpine` image, run make on its
directory:

```sh
make -C miking-alpine build
```

This will also create the `miking:latest-alpine` tag for the created image. To
tag an image as the latest miking image, use the `tag-latest` makefile rule.
For example:

```sh
make -C miking-alpine tag-latest
```

This will create the tagged image `miking:latest`. This allows the instatiation
of a container with the short-hand `miking` image name instead of writing the
specific version.

# Running the Image

To verify that the build image can evaluate and compile MCore programs, the
_test_ directory contains a _sample.mc_ program to test with.

## Verify Evaluation

Run the following command:

```sh
sudo docker run --rm -it -v $(pwd)/test:/mnt:ro miking:<ver> mi eval /mnt/sample.mc
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
sudo docker run --rm -it -v $(pwd)/test:/mnt:ro miking:<ver> bash -c "mi compile /mnt/sample.mc --output /tmp/sample && /tmp/sample"
```

This should produce the same output as for the evaluation case above. To export
the compiled binary out from the container, either mount the /mnt folder
without the ":ro" part or mount another folder that is writable from the
container. Then change the `--output` flag to point to that directory instead
of the /tmp directory.
