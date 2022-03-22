FROM alpine:3.15.0

RUN apk add bash

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# Add a nice PS1 for bash
RUN echo "export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc

# Automatically show colors with ls
RUN echo "alias ls='ls --color=auto'" >> /root/.bashrc

# Where the built mi image will be placed
RUN echo "export PATH=/root/.local/bin:\$PATH" >> /root/.bashrc

# Install dependencies available through apk
RUN apk add opam make m4 bubblewrap git rsync mercurial gcc g++ curl libexecinfo-dev linux-headers zlib-dev openblas-dev

# Initialize opam
RUN opam init --disable-sandboxing --auto-setup

# Create the 4.12 environment
RUN opam switch create 4.12.0+domains --packages=ocaml-variants.4.12.0+domains --repositories=multicore=git+https://github.com/ocaml-multicore/multicore-opam.git,default

# Install ocaml packages
RUN opam install -y dune               \
                    linenoise          \
                    ocamlformat=0.20.1 \
                    owl \
                    lwt

# Add the opam environment as default
RUN echo "eval \$(opam env)" >> /root/.bashrc

# Download the latest version of the miking repository
RUN mkdir /src && cd /src && git clone https://github.com/miking-lang/miking

WORKDIR /src/miking

# Use the following commit as baseline
RUN git checkout 707a8a6dab95abca5a5f73c22960e1cdac39742a

RUN eval $(opam env) && make install

WORKDIR /root

# Export the opam env contents to docker ENV
ENV PATH="/root/.opam/4.12.0+domains/bin:/root/.local/bin:$PATH"
ENV MANPATH=":/root/.opam/4.12.0+domains/man"
ENV OPAM_SWITCH_PREFIX="/root/.opam/4.12.0+domains"
ENV CAML_LD_LIBRARY_PATH="/root/.opam/4.12.0+domains/lib/stublibs:/root/.opam/4.12.0+domains/lib/ocaml/stublibs:/root/.opam/4.12.0+domains/lib/ocaml"
ENV OCAML_TOPLEVEL_PATH="/root/.opam/4.12.0+domains/lib/toplevel"

CMD ["mi"]
