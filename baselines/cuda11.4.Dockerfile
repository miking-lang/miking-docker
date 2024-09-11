FROM docker.io/nvidia/cuda:11.4.3-devel-ubuntu20.04

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# bashrc setting: PS1, ls format, and new PATH to include mi destination
RUN echo "export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc \
 && echo "alias ls='ls --color=auto'" >> /root/.bashrc \
 && echo "export PATH=/root/.local/bin:\$PATH" >> /root/.bashrc

# Install dependencies and opam (also need to add the Nvidia key)
RUN DEBIAN_FRONTEND=noninteractive echo "Installing dependencies" \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC \
 && apt-get update \
 && ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime \
 && apt-get install -y curl time cmake wget unzip git rsync m4 mercurial nodejs \
    libopenblas-dev liblapacke-dev pkg-config zlib1g-dev python3 libpython3-dev \
    libtinfo-dev libgmp-dev build-essential curl libffi-dev libffi7 libgmp-dev \
    libgmp10 libncurses-dev libncurses5 libtinfo5 openjdk-17-jdk autoconf \
 && curl -L -o /usr/local/bin/opam https://github.com/ocaml/opam/releases/download/2.2.1/opam-2.2.1-x86_64-linux \
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

ARG TARGETPLATFORM
# NOTE: Running the opam setup as a single step to contain the downloading and
#       cleaning of unwanted files in the same layer.
# 1. Initialize opam
RUN opam init --disable-sandboxing --auto-setup \
# 2. Create the 5.0.0 environment
 && opam switch create miking-ocaml 5.0.0 \
 && eval $(opam env --switch=miking-ocaml) \
# 3. Setup platform compiler specific flags
 && export OWL_CFLAGS="-g -O3 -Ofast -funroll-loops -ffast-math -DSFMT_MEXP=19937 -fno-strict-aliasing -Wno-tautological-constant-out-of-range-compare" \
 && export OWL_AEOS_CFLAGS="-g -O3 -Ofast -funroll-loops -ffast-math -DSFMT_MEXP=19937 -fno-strict-aliasing" \
 && export EIGENCPP_OPTFLAGS="-Ofast -funroll-loops -ffast-math" \
 && export EIGEN_FLAGS="-O3 -Ofast -funroll-loops -ffast-math" \
 && if [[ "$TARGETPLATFORM" == "linux/amd64" ]]; then \
        export OWL_CFLAGS="$OWL_CFLAGS -mfpmath=sse -msse2"; \
    fi \
 && echo "OWL_CFLAGS=\"$OWL_CFLAGS\"" >> /root/imgbuild_flags.txt \
 && echo "OWL_AEOS_CFLAGS=\"$OWL_AEOS_CFLAGS\"" >> /root/imgbuild_flags.txt \
 && echo "EIGENCPP_OPTFLAGS=\"$EIGENCPP_OPTFLAGS\"" >> /root/imgbuild_flags.txt \
 && echo "EIGEN_FLAGS=\"$EIGEN_FLAGS\"" >> /root/imgbuild_flags.txt \
# 4. Install ocaml packages (there is a bug with that conf-openblas cannot find alpine packages, so treat this package separately)
 && opam install -y dune linenoise menhir pyml toml lwt conf-openblas.0.2.1 owl.0.10.0 ocamlformat.0.24.1 \
# 5. Install sundialsml manually (to ensure correct version)
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
# 6. Clean up stuff we no longer need
 && opam clean -rca \
 && rm -rf /root/.opam/repo           \
           /root/.opam/download-cache \
           /root/.opam/default

# Add the opam environment as default
RUN echo "eval \$(opam env)" >> /root/.bashrc

# Install Futhark
RUN export PATH="/root/.ghcup/bin:$PATH" \
 && curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.2.5 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=3.6.2 \
    BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
    BOOTSTRAP_HASKELL_ADJUST_BASHRC=P \
    sh \
 && cd /src \
 && wget https://github.com/diku-dk/futhark/archive/refs/tags/v0.22.4.zip \
 && unzip v0.22.4.zip \
 && cd futhark-0.22.4 \
 && make configure build install \
 && cd /src \
 && rm -rf /root/.cabal /root/.ghcup /src/futhark-0.22.4 /src/v0.22.4.zip

WORKDIR /root

# Indicate that this baseline image has support for accelerate
ENV MIKING_HAS_FEATURE_ACCELERATE="1"

# Export the opam env contents to docker ENV
ENV PATH="/root/.opam/miking-ocaml/bin:/root/.local/bin:$PATH"
ENV MANPATH="$MANPATH:/root/.opam/miking-ocaml/man"
ENV OPAM_SWITCH_PREFIX="/root/.opam/miking-ocaml"
ENV CAML_LD_LIBRARY_PATH="/root/.opam/miking-ocaml/lib/stublibs:/root/.opam/miking-ocaml/lib/ocaml/stublibs:/root/.opam/miking-ocaml/lib/ocaml"
ENV OCAML_TOPLEVEL_PATH="/root/.opam/miking-ocaml/lib/toplevel"
ENV PKG_CONFIG_PATH="/root/.opam/miking-ocaml/lib/pkgconfig"

# The config seems to exist under /etc/ld.so.conf.d, but OCaml does not seem
# to respect this when linking externals.
ARG TARGET_LIB_PATH
ENV LD_LIBRARY_PATH="$TARGET_LIB_PATH"

RUN test "$(cat /etc/ld.so.conf.d/*.conf | sed '/^#.*/d' | paste -sd ':' -)" = "$LD_LIBRARY_PATH"

# Add CPATH to allow GCC to access the CUDA includes
ENV CPATH="/usr/local/cuda/include"

CMD ["bash"]
