#!/bin/bash

build_lava() {
  PROG=$1
  PROGOPT=$2
  INPUT_PATTERN="inputs/$3"
  INPUT_CLEAN="inputs/$4"
  INPUT_TOTAL=$5
  COMPILER=$6
  FLAG=$7

  echo "Building buggy ${PROG}..."
  cd $PROG/ || exit 1

  cd coreutils-8.24-lava-safe || exit 1
  CC=$COMPILER CFLAGS=$FLAG ./configure --prefix=`pwd`/lava-install LIBS="-lacl" || exit 1
  CC=$COMPILER make -j $(nproc) || exit 1
  make install || exit 1
  cd ..
  
  echo "Checking if buggy ${PROG} succeeds on non-trigger input..."
  ./coreutils-8.24-lava-safe/lava-install/bin/${PROG} ${PROGOPT} ${INPUT_CLEAN}
  rv=$?
  if [ $rv -lt 128 ]; then
      echo "Success: ${PROG} ${PROGOPT} ${INPUT_CLEAN} returned $rv"
  else
      echo "ERROR: ${PROG} ${PROGOPT} ${INPUT_CLEAN} returned $rv"
      exit 1
  fi
  
  #echo "Validating bugs..."
  #rm -f log.txt
  #for (( i=1; i<=$INPUT_TOTAL; i++ ))
  #do
  #  INPUT_FUZZ=$(printf "$INPUT_PATTERN" $i)
  #  { ./coreutils-8.24-lava-safe/lava-install/bin/${PROG} ${PROGOPT} ${INPUT_FUZZ} ; } >> log.txt
  #done

  cd ../
}

# Extract tarball.
wget http://panda.moyix.net/~moyix/lava_corpus.tar.xz || exit 1
tar -xf lava_corpus.tar.xz || exit 1
mv lava_corpus/LAVA-M ./LAVA-M || exit 1
rm -rf lava_corpus.tar.xz lava_corpus || exit 1
for PGM in "base64" "md5sum" "uniq" "who"
do
  make clean -C LAVA-M/${PGM}/coreutils-8.24-lava-safe || exit 1
done
cd LAVA-M && patch -p0 < ../setup-scripts/who.patch && cd ../ || exit 1
cp -r LAVA-M LAVA-M-lafintel || exit 1

# Build LAVA-M with clang-3.8
cd LAVA-M || exit 1
build_lava base64 -d utmp-fuzzed-%s.b64 utmp.b64 884 clang-3.8 " "
build_lava md5sum -c bin-ls-md5s-fuzzed-%s  bin-ls-md5s 592 clang-3.8 -Dlint
build_lava uniq " " man-clang3-sorted-fuzzed-%s man-clang3-sorted 497 clang-3.8 " "
build_lava who " " utmp-fuzzed-%s utmp 4562 clang-3.8 " "
cd ../

# Build LAVA-M with LAF-intel
cd LAVA-M-lafintel || exit 1
build_lava base64 -d utmp-fuzzed-%s.b64 utmp.b64 884 \
  /home/artifact/lafintel/afl-clang-fast " "
build_lava md5sum -c bin-ls-md5s-fuzzed-%s  bin-ls-md5s 592 \
  /home/artifact/lafintel/afl-clang-fast -Dlint
build_lava uniq " " man-clang3-sorted-fuzzed-%s man-clang3-sorted 497 \
  /home/artifact/lafintel/afl-clang-fast " "
build_lava who " " utmp-fuzzed-%s utmp 4562 \
  /home/artifact/lafintel/afl-clang-fast " "
cd ../

# Leave binaries and seeds only
mkdir LAVA-data/
mkdir LAVA-data/llvm-bins
mkdir LAVA-data/lafintel-bins
mkdir LAVA-data/seeds

for PGM in "base64" "md5sum" "uniq" "who"
do
  cp LAVA-M/$PGM/coreutils-8.24-lava-safe/lava-install/bin/$PGM \
    ./LAVA-data/llvm-bins/ || exit 1
  cp LAVA-M-lafintel/$PGM/coreutils-8.24-lava-safe/lava-install/bin/$PGM \
    ./LAVA-data/lafintel-bins/ || exit 1
  cp -r LAVA-M/$PGM/fuzzer_input/ ./LAVA-data/seeds/$PGM || exit 1
done

rm -rf LAVA-M LAVA-M-lafintel
