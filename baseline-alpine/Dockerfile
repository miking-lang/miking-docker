FROM alpine:3.16.2

RUN apk add bash

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# bashrc setting: PS1, ls format, and new PATH to include mi destination
RUN echo "export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc \
 && echo "alias ls='ls --color=auto'" >> /root/.bashrc \
 && echo "export PATH=/root/.local/bin:\$PATH" >> /root/.bashrc

# Install dependencies available through apk
RUN apk add opam make cmake m4 bubblewrap git rsync mercurial gcc g++ curl libexecinfo-dev linux-headers zlib-dev openblas-dev lapack-dev nodejs-current

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
# 2. Create the 5.0.0~rc1 environment
 && opam switch create miking-ocaml 5.0.0~rc1 \
# 3. Setup platform compiler specific flags
 && export OWL_CFLAGS="-g -O3 -Ofast -funroll-loops -ffast-math -DSFMT_MEXP=19937 -fno-strict-aliasing -Wno-tautological-constant-out-of-range-compare" \
 && export OWL_AEOS_CFLAGS="-g -O3 -Ofast -funroll-loops -ffast-math -DSFMT_MEXP=19937 -fno-strict-aliasing" \
 && export EIGENCPP_OPTFLAGS="-Ofast -funroll-loops -ffast-math" \
 && export EIGEN_FLAGS="-O3 -Ofast -funroll-loops -ffast-math" \
 && if [[ "$TARGETPLATFORM" == "linux/amd64" ]]; then \
        export OWL_CFLAGS="$OWL_CFLAGS -mfpmath=sse -msse2"; \
        echo "$OWL_CFLAGS" > /root/owlflags.txt; \
    fi \
# 4. Install ocaml packages
 && opam install -y --assume-depexts dune linenoise pyml toml lwt owl ocamlformat.0.24.1 \
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
ENV MANPATH=":/root/.opam/miking-ocaml/man"
ENV OPAM_SWITCH_PREFIX="/root/.opam/miking-ocaml"
ENV CAML_LD_LIBRARY_PATH="/root/.opam/miking-ocaml/lib/stublibs:/root/.opam/miking-ocaml/lib/ocaml/stublibs:/root/.opam/miking-ocaml/lib/ocaml"
ENV OCAML_TOPLEVEL_PATH="/root/.opam/miking-ocaml/lib/toplevel"

CMD ["bash"]
