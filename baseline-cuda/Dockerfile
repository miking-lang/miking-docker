FROM nvidia/cuda:11.4.3-devel-ubuntu20.04

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# Add a nice PS1 for bash
RUN echo "export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc

# Where the built mi image will be placed
RUN echo "export PATH=/root/.local/bin:\$PATH" >> /root/.bashrc

# (ls with color is already enables on ubuntu)

# Install dependencies and opam (also need to add the Nvidia key)
RUN DEBIAN_FRONTEND=noninteractive echo "Installing dependencies" \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC \
 && apt-get update \
 && ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime \
 && apt-get install -y curl time cmake wget unzip git rsync m4 mercurial nodejs libopenblas-dev liblapacke-dev pkg-config zlib1g-dev python3 libpython3-dev \
 && curl -L -o /usr/local/bin/opam https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-x86_64-linux \
 && chmod +x /usr/local/bin/opam

# Install sundials manually
RUN mkdir -p /src/sundials \
 && cd /src/sundials \
 && wget https://github.com/LLNL/sundials/releases/download/v6.1.1/sundials-6.1.1.tar.gz \
 && tar -xzvf sundials-6.1.1.tar.gz \
 && cd sundials-6.1.1 \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make \
 && make install \
 && cd /src \
 && rm -rf sundials

ENV OWL_CFLAGS="-g -O3 -Ofast -mfpmath=sse -funroll-loops -ffast-math -DSFMT_MEXP=19937 -msse2 -fno-strict-aliasing -Wno-tautological-constant-out-of-range-compare"
ENV EIGENCPP_OPTFLAGS="-Ofast -funroll-loops -ffast-math"
ENV EIGEN_FLAGS="-O3 -Ofast -funroll-loops -ffast-math"

# NOTE: Running the opam setup as a single step to contain the downloading and
#       cleaning of unwanted files in the same layer.
# 1. Initialize opam
RUN opam init --disable-sandboxing --auto-setup \
# 2. Create the 4.12 environment
 && opam switch create 4.12.0+domains --packages=ocaml-variants.4.12.0+domains --repositories=multicore=git+https://github.com/ocaml-multicore/multicore-opam.git,default \
# 3. Install ocaml packages
 && opam install -y dune linenoise pyml toml lwt owl ocamlformat.0.20.1 \
# 4. Install sundialsml manually (to ensure correct version)
 && eval $(opam env) \
 && mkdir -p /src/sundialsml \
 && cd /src/sundialsml \
 && wget https://github.com/inria-parkas/sundialsml/archive/refs/tags/v6.1.1p1.zip \
 && unzip v6.1.1p1.zip \
 && cd sundialsml-6.1.1p1 \
 && ./configure \
 && make \
 && make install \
 && cd /src \
 && rm -rf sundialsml \
# 5. Clean up stuff we no longer need
 && opam clean -rca \
 && rm -rf /root/.opam/repo           \
           /root/.opam/download-cache \
           /root/.opam/default

# Add the opam environment as default
RUN echo "eval \$(opam env)" >> /root/.bashrc

WORKDIR /root

# Export the opam env contents to docker ENV
ENV PATH="/root/.opam/4.12.0+domains/bin:/root/.local/bin:$PATH"
ENV MANPATH="$MANPATH:/root/.opam/4.12.0+domains/man"
ENV OPAM_SWITCH_PREFIX="/root/.opam/4.12.0+domains"
ENV CAML_LD_LIBRARY_PATH="/root/.opam/4.12.0+domains/lib/stublibs:/root/.opam/4.12.0+domains/lib/ocaml/stublibs:/root/.opam/4.12.0+domains/lib/ocaml"
ENV OCAML_TOPLEVEL_PATH="/root/.opam/4.12.0+domains/lib/toplevel"
ENV PKG_CONFIG_PATH="/root/.opam/4.12.0+domains/lib/pkgconfig"

# For some reason this environment variable is wrongly configured in the source image...
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib:/usr/local/cuda/lib64:/usr/local/lib:$LD_LIBRARY_PATH"

# The ld linker also does not play nice with LD_LIBRARY_PATH, create some
# symbolic links for the libraries:
RUN mkdir -p /usr/local/lib64 \
 && ls /usr/local/cuda/lib64/*.so | xargs ln -s -t /usr/local/lib64

CMD ["bash"]
