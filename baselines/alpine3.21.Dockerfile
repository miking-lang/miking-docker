FROM docker.io/library/alpine:3.21

RUN apk add bash

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# bashrc setting: PS1, ls format, and new PATH to include mi destination
RUN echo "export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc \
 && echo "alias ls='ls --color=auto'" >> /root/.bashrc \
 && echo "export PATH=/root/.local/bin:\$PATH" >> /root/.bashrc

# Install dependencies available through apk
RUN apk add opam make cmake m4 bubblewrap git rsync mercurial gcc g++ curl \
    linux-headers zlib-dev libc-dev openblas-dev lapack-dev nodejs-current openjdk17 \
    autoconf pkgconfig wget fuse3-dev

# Install tup manually (dependends on pkgconfig and fuse3-dev)
# NOTE: There was a 0.8 version available at the time of writing this
#       Dockerfile. But since debian install 0.7.11, we do that here too.
RUN mkdir -p /src/tup \
 && cd /src/tup \
 && wget https://gittup.org/tup/releases/tup-v0.7.11.tar.gz \
 && tar -xzvf tup-v0.7.11.tar.gz \
 && cd tup-v0.7.11 \
 && ./build.sh \
 && cp build/tup /usr/local/bin/tup \
 && cd /src \
 && rm -rf /src/tup

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

# Minizinc and all of its dependencies are missing from Alpine's packages. Need
# to build them manually.
# Note: This will install Gecode 6.3.1. Version 6.2.0 cannot compile due to a
#       type error.
RUN mkdir -p /src/gecode \
 && cd /src/gecode \
 && wget https://github.com/Gecode/gecode/archive/fec7e9fd99bca98f146416ba8ea8adc278f5a95a.tar.gz \
 && tar -xzvf fec7e9fd99bca98f146416ba8ea8adc278f5a95a.tar.gz \
 && cd gecode-fec7e9fd99bca98f146416ba8ea8adc278f5a95a \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make \
 && make install \
 && OLD BELOW \
 && cd gecode-release-6.2.0 \
 && ./configure \
 && make \
 && **************** TODO: INSTALL COINOR_CBC *************************** \
 && mkdir -p /src/coinor-coinutils && cd /src/coinor-coinutils \
 && wget https://github.com/coin-or/CoinUtils/archive/refs/tags/releases/2.11.12.tar.gz \
 && tar -xzvf 2.11.12.tar.gz && cd CoinUtils-releases-2.11.12 \
 && ./configure \
 && mkdir -p /src/coinor-cbc \
 && cd /src/coinor-cbc \
 && wget https://github.com/coin-or/Cbc/archive/refs/tags/releases/2.10.12.tar.gz \
 && tar -xzvf 2.10.12.tar.gz \
 && cd Cbc-releases-2.10.12 \
 && ./configure \
 && make ????????????????


# configure: error: One or more required packages CoinUtils, Osi, and Cgl are not available.

ARG TARGET_PLATFORM
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
 && if [[ "$TARGET_PLATFORM" == "linux/amd64" ]]; then \
        export OWL_CFLAGS="$OWL_CFLAGS -mfpmath=sse -msse2"; \
    fi \
 && echo "OWL_CFLAGS=\"$OWL_CFLAGS\"" >> /root/imgbuild_flags.txt \
 && echo "OWL_AEOS_CFLAGS=\"$OWL_AEOS_CFLAGS\"" >> /root/imgbuild_flags.txt \
 && echo "EIGENCPP_OPTFLAGS=\"$EIGENCPP_OPTFLAGS\"" >> /root/imgbuild_flags.txt \
 && echo "EIGEN_FLAGS=\"$EIGEN_FLAGS\"" >> /root/imgbuild_flags.txt \
# 4. Install ocaml packages (there is a bug with that conf-openblas cannot find alpine packages, so treat this package separately)
 && opam install -y --no-depexts conf-openblas.0.2.1 \
 && opam install -y --assume-depexts dune linenoise menhir pyml toml lwt owl.0.10.0 ocamlformat.0.24.1 \
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

WORKDIR /root

# Export the opam env contents to docker ENV
ENV PATH="/root/.opam/miking-ocaml/bin:/root/.local/bin:$PATH"
ENV MANPATH="$MANPATH:/root/.opam/miking-ocaml/man"
ENV OPAM_SWITCH_PREFIX="/root/.opam/miking-ocaml"
ENV CAML_LD_LIBRARY_PATH="/root/.opam/miking-ocaml/lib/stublibs:/root/.opam/miking-ocaml/lib/ocaml/stublibs:/root/.opam/miking-ocaml/lib/ocaml"
ENV OCAML_TOPLEVEL_PATH="/root/.opam/miking-ocaml/lib/toplevel"

CMD ["bash"]
