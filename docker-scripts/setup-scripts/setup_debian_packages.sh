#!/bin/bash

## Prepare source.
mv setup-scripts/packages-src ./ || exit 1
cd packages-src || exit 1
tar -xf xfig-full-3.2.6a.tar.xz || exit 1
tar -xf ufraw-0.22.tar.gz || exit 1
tar -xf icoutils-0.32.2.tar.bz2 || exit 1
unzip vorbis-tools-1.4.0.zip || exit 1
tar -xf gnuplot-5.2.2.tar.gz || exit 1
tar -xf optipng-0.7.6.tar.gz || exit 1
tar -xf dcraw.tar.gz || exit 1
tar -xf 5.1.0.tar.gz || exit 1
tar -xf gocr-0.50.tar.gz || exit 1
tar -xf advancecomp-2.0.tar.gz || exit 1
tar -xf x264-snapshot-20171225-2245-stable.tar.bz2 || exit 1
tar -xf jhead-3.00-5.tgz || exit 1
tar -xf sextractor-2.19.5.tar.gz || exit 1
tar -xf v1.90.tar.gz || exit 1
rm -rf ./*.tar.xz ./*.tar.gz ./*.tar.bz2 ./*.zip ./*.tgz && mkdir bins || exit 1
cd ../ || exit 1
cp -r packages-src packages-llvm || exit 1
cp -r packages-src packages-sanitize || exit 1
mv packages-src packages-lafintel || exit 1

## Build with clang-3.8.

cd /home/artifact/packages-llvm/ || exit 1

# Build fig2dev
cd fig2dev-3.2.6a || exit 1
aclocal || exit 1
autoconf || exit 1
automake || exit 1
CC=clang-3.8 ./configure || exit 1
make || exit 1
cp ./fig2dev/fig2dev /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

## Build ufraw
cd ufraw-0.22 || exit 1
./autogen.sh || exit 1
CC=clang-3.8 CXX=clang++-3.8 ./configure || exit 1
make || exit 1
cp ./ufraw-batch /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build icoutils
cd icoutils-0.32.2 || exit 1
CC=clang-3.8 ./configure || exit 1
make || exit 1
cp ./icotool/icotool /home/artifact/packages-llvm/bins/ || exit 1
cp ./wrestool/wrestool /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build vorbis-tools
cd vorbis-tools-1.4.0 || exit 1
CC=clang-3.8 ./configure || exit 1
make || exit 1
cp ./vorbiscomment/vorbiscomment /home/artifact/packages-llvm/bins/ || exit 1
cp ./oggenc/oggenc /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build gnuplot
cd gnuplot-5.2.2/ || exit 1
CC=clang-3.8 CXX=clang++-3.8 ./configure --with-x=no --with-qt=no || exit 1
make || exit 1
cp ./src/gnuplot /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build optipng
cd optipng-0.7.6 || exit 1
sed -i 's/LDFLAGS--s/LDFLAGS-/g' ./configure || exit 1
CC=clang-3.8 ./configure || exit 1
make || exit 1
cp ./src/optipng/optipng /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build dcraw
cd dcraw-9.27 || exit 1
autoreconf -i || exit 1
CC=clang-3.8 ./configure || exit 1
make || exit 1
cp dcraw dcparse /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build wavpack
cd WavPack-5.1.0 || exit 1
autoreconf -v --install || exit 1
CC=clang-3.8 CXX=clang++-3.8 ./configure --disable-shared || exit 1
make || exit 1
cp ./cli/wvunpack /home/artifact/packages-llvm/bins/ || exit 1
cp ./cli/wavpack /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build gocr
cd gocr-0.50 || exit 1
CC=clang-3.8 CFLAGS="-static" LDFLAGS="-static" ./configure || exit 1
make || exit 1
cp ./src/gocr /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build advancecomp
cd advancecomp-2.0/ || exit 1
aclocal || exit 1
autoconf || exit 1
automake || exit 1
CC=clang-3.8 CXX=clang++-3.8 ./configure || exit 1
make || exit 1
cp ./advmng ./advzip /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build x264
cd x264-snapshot-20171225-2245-stable || exit 1
CC=clang-3.8 ./configure --disable-asm || exit 1
make || exit 1
cp ./x264 /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build jhead
cd jhead-3.00-5 || exit 1
CC=clang-3.8 make || exit 1
cp ./jhead /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build sextractor
cd sextractor-2.19.5 || exit 1
CC=clang-3.8 CFLAGS="-I/usr/include/atlas" ./configure || exit 1
make || exit 1
cp ./src/ldactoasc /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

# Build gifsicle
cd gifsicle-1.90/ || exit 1
autoreconf -i || exit 1
CC=clang-3.8 CFLAGS="-static" LDFLAGS="-static" ./configure || exit 1
make || exit 1
cp ./src/gifdiff ./src/gifsicle /home/artifact/packages-llvm/bins/ || exit 1
cd ../ || exit 1

## Build with LAF-intel

cd /home/artifact/packages-lafintel/ || exit 1

# Build fig2dev
cd fig2dev-3.2.6a || exit 1
aclocal || exit 1
autoconf || exit 1
automake || exit 1
CC=/home/artifact/lafintel/afl-clang-fast ./configure || exit 1
make || exit 1
cp ./fig2dev/fig2dev /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build ufraw
cd ufraw-0.22 || exit 1
./autogen.sh || exit 1
CC=/home/artifact/lafintel/afl-clang-fast \
CXX=/home/artifact/lafintel/afl-clang-fast++ \
  ./configure || exit 1
make || exit 1
cp ./ufraw-batch /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build icoutils
cd icoutils-0.32.2 || exit 1
CC=/home/artifact/lafintel/afl-clang-fast ./configure || exit 1
make || exit 1
cp ./icotool/icotool /home/artifact/packages-lafintel/bins/ || exit 1
cp ./wrestool/wrestool /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build vorbis-tools
cd vorbis-tools-1.4.0 || exit 1
CC=/home/artifact/lafintel/afl-clang-fast ./configure || exit 1
make || exit 1
cp ./vorbiscomment/vorbiscomment /home/artifact/packages-lafintel/bins/ || exit 1
cp ./oggenc/oggenc /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build gnuplot
cd gnuplot-5.2.2/ || exit 1
CC=/home/artifact/lafintel/afl-clang-fast \
CXX=/home/artifact/lafintel/afl-clang-fast++ \
  ./configure --with-x=no --with-qt=no || exit 1
make || exit 1
cp ./src/gnuplot /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build optipng
cd optipng-0.7.6 || exit 1
sed -i 's/LDFLAGS--s/LDFLAGS-/g' ./configure || exit 1
CC=/home/artifact/lafintel/afl-clang-fast ./configure || exit 1
make || exit 1
cp ./src/optipng/optipng /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build dcraw
cd dcraw-9.27 || exit 1
autoreconf -i || exit 1
CC=/home/artifact/lafintel/afl-clang-fast ./configure || exit 1
make || exit 1
cp dcraw dcparse /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build wavpack
cd WavPack-5.1.0 || exit 1
autoreconf -v --install || exit 1
CC=/home/artifact/lafintel/afl-clang-fast \
CXX=/home/artifact/lafintel/afl-clang-fast++ \
  ./configure --disable-shared || exit 1
make || exit 1
cp ./cli/wvunpack /home/artifact/packages-lafintel/bins/ || exit 1
cp ./cli/wavpack /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build gocr
cd gocr-0.50 || exit 1
CC=/home/artifact/lafintel/afl-clang-fast \
CFLAGS="-static" LDFLAGS="-static" \
  ./configure || exit 1
make || exit 1
cp ./src/gocr /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build advancecomp
cd advancecomp-2.0/ || exit 1
aclocal || exit 1
autoconf || exit 1
automake || exit 1
CC=/home/artifact/lafintel/afl-clang-fast \
CXX=/home/artifact/lafintel/afl-clang-fast++ \
  ./configure || exit 1
make || exit 1
cp ./advmng ./advzip /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build x264
cd x264-snapshot-20171225-2245-stable || exit 1
CC=/home/artifact/lafintel/afl-clang-fast ./configure --disable-asm || exit 1
make || exit 1
cp ./x264 /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build jhead
cd jhead-3.00-5 || exit 1
CC=/home/artifact/lafintel/afl-clang-fast make || exit 1
cp ./jhead /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build sextractor
cd sextractor-2.19.5 || exit 1
CC=/home/artifact/lafintel/afl-clang-fast CFLAGS="-I/usr/include/atlas" \
  ./configure || exit 1
make || exit 1
cp ./src/ldactoasc /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

# Build gifsicle
cd gifsicle-1.90/ || exit 1
autoreconf -i || exit 1
CC=/home/artifact/lafintel/afl-clang-fast CFLAGS="-static" LDFLAGS="-static" \
  ./configure || exit 1
make || exit 1
cp ./src/gifdiff ./src/gifsicle /home/artifact/packages-lafintel/bins/ || exit 1
cd ../ || exit 1

## Build with address sanitizer.

cd /home/artifact/packages-sanitize/ || exit 1

# Build fig2dev
cd fig2dev-3.2.6a || exit 1
# Fix compile error when building with ASAN.
cp ../fig2dev-patch/realloc.c ./fig2dev/lib/realloc.c || exit 1
aclocal || exit 1
autoconf || exit 1
automake || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./fig2dev/fig2dev /home/artifact/packages-sanitize/bins/ &&\
cd ../ || exit 1

## Build ufraw
cd ufraw-0.22 || exit 1
./autogen.sh || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" \
CXX=clang++-3.8 CXXFLAGS="-fsanitize=address -g" \
LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./ufraw-batch /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build icoutils
cd icoutils-0.32.2 || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./icotool/icotool /home/artifact/packages-sanitize/bins/ || exit 1
cp ./wrestool/wrestool /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build vorbis-tools
cd vorbis-tools-1.4.0 || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./vorbiscomment/vorbiscomment /home/artifact/packages-sanitize/bins/ || exit 1
cp ./oggenc/oggenc /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build gnuplot
cd gnuplot-5.2.2/ || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" \
CXX=clang++-3.8 CXXFLAGS="-fsanitize=address -g" \
LDFLAGS="-fsanitize=address -g" \
  ./configure --with-x=no --with-qt=no || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./src/gnuplot /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build optipng
cd optipng-0.7.6 || exit 1
sed -i 's/LDFLAGS--s/LDFLAGS-/g' ./configure || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./src/optipng/optipng /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build dcraw
cd dcraw-9.27 || exit 1
autoreconf -i || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp dcraw dcparse /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build wavpack
cd WavPack-5.1.0 || exit 1
autoreconf -v --install || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" \
CXX=clang++-3.8 CXXFLAGS="-fsanitize=address -g" \
LDFLAGS="-fsanitize=address -g" \
  ./configure --disable-shared || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./cli/wvunpack /home/artifact/packages-sanitize/bins/ || exit 1
cp ./cli/wavpack /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build gocr
cd gocr-0.50 || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./src/gocr /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build advancecomp
cd advancecomp-2.0/ || exit 1
aclocal || exit 1
autoconf || exit 1
automake || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" \
CXX=clang++-3.8 CXXFLAGS="-fsanitize=address -g" \
LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./advmng ./advzip /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build x264
cd x264-snapshot-20171225-2245-stable || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure --disable-asm || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./x264 /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build jhead
cd jhead-3.00-5 || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./jhead /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build sextractor
cd sextractor-2.19.5 || exit 1
CC=clang-3.8 CFLAGS="-I/usr/include/atlas -fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./src/ldactoasc /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

# Build gifsicle
cd gifsicle-1.90/ || exit 1
autoreconf -i || exit 1
CC=clang-3.8 CFLAGS="-fsanitize=address -g" LDFLAGS="-fsanitize=address -g" \
  ./configure || exit 1
ASAN_OPTIONS=detect_leaks=0 make || exit 1
cp ./src/gifdiff ./src/gifsicle /home/artifact/packages-sanitize/bins/ || exit 1
cd ../ || exit 1

cd /home/artifact/
mkdir package-bins/ || exit 1
mv packages-llvm/bins ./package-bins/llvm || exit 1
mv packages-lafintel/bins ./package-bins/lafintel || exit 1
mv packages-sanitize/bins ./package-bins/sanitize || exit 1
rm -rf packages-llvm || exit 1
rm -rf packages-lafintel || exit 1
rm -rf packages-sanitize || exit 1
