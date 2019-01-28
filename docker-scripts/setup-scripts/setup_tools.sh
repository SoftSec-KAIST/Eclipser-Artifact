#!/bin/bash

# Install KLEE
git clone https://github.com/stp/minisat.git || exit 1
cd minisat && mkdir build && cd build || exit 1
cmake -DSTATIC_BINARIES=ON -DCMAKE_INSTALL_PREFIX=/usr/local/ ../ || exit 1
sudo make install || exit 1
cd /home/artifact || exit 1
rm -rf minisat || exit 1

git clone https://github.com/stp/stp.git || exit 1
cd stp && git checkout tags/2.1.2 && mkdir build && cd build || exit 1
cmake -DBUILD_SHARED_LIBS:BOOL=OFF -DENABLE_PYTHON_INTERFACE:BOOL=OFF .. || exit 1
make || exit 1
sudo make install || exit 1
cd /home/artifact || exit 1
rm -rf stp || exit 1

git clone https://github.com/klee/klee-uclibc.git || exit 1
cd klee-uclibc || exit 1
./configure --make-llvm-lib || exit 1
make -j2 || exit 1
cd /home/artifact || exit 1

sudo apt-get install -yy libtcmalloc-minimal4 libgoogle-perftools-dev || exit 1

wget https://github.com/klee/klee/archive/v1.4.0.tar.gz || exit 1
tar -xf v1.4.0.tar.gz || exit 1
rm -f v1.4.0.tar.gz || exit 1
mkdir klee_build && cd klee_build || exit 1
cmake \
  -DENABLE_SOLVER_STP=ON \
  -DENABLE_POSIX_RUNTIME=ON \
  -DENABLE_KLEE_UCLIBC=ON \
  -DENABLE_UNIT_TESTS=OFF and -DENABLE_SYSTEM_TESTS=OFF \
  -DKLEE_UCLIBC_PATH=/home/artifact/klee-uclibc \
  /home/artifact/klee-1.4.0/ || exit 1
make || exit 1
cd /home/artifact || exit 1

# Install AFLFast
git clone https://github.com/mboehme/aflfast.git || exit 1
cd aflfast && git checkout 15894a6b && make || exit 1
cd qemu_mode && ./build_qemu_support.sh || exit 1
rm -rf qemu_mode/qemu/qemu-2.3.0* || exit 1
cd /home/artifact || exit 1

# Install LAF-intel
wget http://lcamtuf.coredump.cx/afl/releases/afl-2.52b.tgz || exit 1
tar -xf afl-2.52b.tgz || exit 1
rm -f afl-2.52b.tgz || exit 1
mv afl-2.52b lafintel || exit 1
git clone https://gitlab.com/laf-intel/laf-llvm-pass.git || exit 1
cp laf-llvm-pass/src/*.so.cc ./lafintel/llvm_mode/ || exit 1
cp laf-llvm-pass/src/afl.patch ./lafintel/llvm_mode/ || exit 1
cd lafintel && make || exit 1
cd llvm_mode && patch < afl.patch || exit 1
CC=clang-3.8 CXX=clang++-3.8 LLVM_CONFIG=llvm-config-3.8 make || exit 1
cd /home/artifact || exit 1
rm -rf laf-llvm-pass || exit 1
