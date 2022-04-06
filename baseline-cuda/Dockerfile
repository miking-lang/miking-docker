FROM nvidia/cuda:11.6.0-devel-ubuntu20.04

RUN apt-get update \
 && apt-get install -y curl unzip git rsync m4 mercurial libopenblas-dev \
 && curl -L -o /usr/local/bin/opam https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-x86_64-linux \
 && chmod +x /usr/local/bin/opam

# NOTE: Running the opam setup as a single step to contain the downloading and
#       cleaning of unwanted files in the same layer.
# 1. Initialize opam
RUN opam init --disable-sandboxing --auto-setup \
# 2. Create the 4.12 environment
 && opam switch create 4.12.0+domains --packages=ocaml-variants.4.12.0+domains --repositories=multicore=git+https://github.com/ocaml-multicore/multicore-opam.git,default \
# 3. Install ocaml packages
 && opam install -y dune linenoise pyml toml lwt owl ocamlformat.0.20.1 \
# 4. Clean up stuff we no longer need
 && opam clean -rca \
 && rm -rf /root/.opam/repo           \
           /root/.opam/download-cache \
           /root/.opam/default


CMD ["bash"]
