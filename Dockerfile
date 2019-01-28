FROM ubuntu:16.04

WORKDIR /root/

### Install dependencies
RUN sed -i 's/archive.ubuntu.com/ftp.daumkakao.com/g' /etc/apt/sources.list && \
    sed -i 's/# deb-src http:\/\/ftp.daum/deb-src http:\/\/ftp.daum/g' \
      /etc/apt/sources.list && \
    apt-get update && \
    apt-get -yy install \
# Basic utilities
      wget apt-transport-https \
      sudo vim git unzip xz-utils ntp \
      build-essential time libtool libtool-bin gdb \
      automake autoconf bison flex \
# Dependencies for KLEE
      libcap-dev cmake libncurses5-dev python-minimal python-pip \
# Dependencies for LAVA
      libacl1-dev gperf && \
# Dependencies for QEMU used in Eclipser
    apt-get -yy build-dep qemu && \
# Dependencies for Debian packages
    apt-get -yy install lua5.1 autogen && \
    apt-get -yy build-dep ufraw-batch icoutils vorbis-tools gnuplot-nox \
      optipng dcraw wavpack gocr advancecomp x264 jhead sextractor gifsicle && \
# Install .NET Core for Eclipser
    wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get -yy install dotnet-sdk-2.1 && \
    rm -f packages-microsoft-prod.deb
# pip installation raises an error when combined together
RUN pip install --upgrade pip
RUN pip install --upgrade wllvm

### Install clang/LLVM.

# For KLEE, install 3.4 as requested in KLEE's official website. In Ubuntu 16,
# clang-3.4 is not available in apt repository.
RUN wget http://releases.llvm.org/3.4.2/llvm-3.4.2.src.tar.gz && \
    wget http://releases.llvm.org/3.4.2/cfe-3.4.2.src.tar.gz && \
    tar -xf llvm-3.4.2.src.tar.gz && \
    tar -xf cfe-3.4.2.src.tar.gz && \
    rm -f llvm-3.4.2.src.tar.gz && \
    rm -f cfe-3.4.2.src.tar.gz && \
    mkdir llvm-3.4.2 && \
    mv llvm-3.4.2.src ./llvm-3.4.2/llvm && \
    mv cfe-3.4.2.src ./llvm-3.4.2/llvm/tools/clang && \
    mkdir llvm-3.4.2/llvm-build/ && \
    cd llvm-3.4.2/llvm-build && \
    ../llvm/configure --enable-optimized && \
    make && \
    make install && \
    cd /root/ && \
# For other compile purpose, use 3.8 which is more widely used in distros.
    wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-3.8 main" \
      >> /etc/apt/sources.list && \
    apt-get update && apt-get -yy install clang-3.8 && \
# ASAN rejects program name with version suffix, so create a symbolic link.
    ln -s /usr/bin/llvm-symbolizer-3.8 /usr/bin/llvm-symbolizer

# Create a user and switch.
RUN useradd -ms /bin/bash artifact && \
    adduser artifact sudo && \
    echo "artifact ALL = NOPASSWD : ALL" >> /etc/sudoers

USER artifact
WORKDIR /home/artifact

# Copy script files
COPY --chown=artifact:artifact docker-scripts/ ./

# Install test case generation tools.
RUN ./setup-scripts/setup_tools.sh
ENV LAF_SPLIT_SWITCHES=1 \
    LAF_TRANSFORM_COMPARES=1 \
    LAF_SPLIT_COMPARES=1 \
    AFL_CC=clang-3.8 \
    AFL_CXX=clang++-3.8

# Setup coreutils.
USER root
WORKDIR /root/
ENV LLVM_COMPILER=clang FORCE_UNSAFE_CONFIGURE=1
RUN wget https://ftp.gnu.org/gnu/coreutils/coreutils-8.27.tar.xz \
      -O /root/coreutils-8.27.tar.xz && \
    tar -xf coreutils-8.27.tar.xz && \
    cd /root/coreutils-8.27/ && \
    mkdir obj-llvm && \
    cd obj-llvm && \
    CC=wllvm ../configure --disable-nls CFLAGS="-g" && \
    CC=wllvm make && \
    cd /root/coreutils-8.27/ && \
    mkdir obj-gcc && \
    cd obj-gcc && \
    ../configure --disable-nls CFLAGS="-g" && \
    make && \
    cd /root/coreutils-8.27/ && \
    mkdir obj-gcov && \
    cd obj-gcov && \
    ../configure --disable-nls CFLAGS="-g -fprofile-arcs -ftest-coverage" && \
    make

USER artifact
WORKDIR /home/artifact

# Setup LAVA.
RUN ./setup-scripts/setup_lava.sh

# Setup Debian packages.
RUN ./setup-scripts/setup_debian_packages.sh

# Install Eclipser
RUN git clone https://github.com/SoftSec-KAIST/Eclipser.git && \
    cd Eclipser && \
    git checkout tags/v0.1 && \
    make && \
    rm -rf ./Instrumentor/qemu/qemu-2.3.0*

USER root
ARG HOST_UID
RUN ./setup-scripts/adjust_uid.sh $HOST_UID

USER artifact
