#!/bin/bash

cd /home/artifact/
sudo chmod -R 777 ./box
sudo rm -rf ./box
mkdir box
chmod 777 box
cd box

cp /home/artifact/package-bins/llvm/$1 ./$1
cp /home/artifact/Eclipser/build/qemu-trace-bbcount-x64 ./

rm -rf "/tmp/coverages"
mkdir "/tmp/coverages"

export CK_FORK_SERVER=0
export CK_MODE=1
export CK_COVERAGE_LOG=./coverage
export CK_NODE_LOG=./node
export CK_EDGE_LOG=./edge
export CK_PATH_LOG=./path

echo "===== Now replaying testcase ======"

echo "Visited nodes : 0 (+0)" >> ./coverage
echo "Visited edges : 0 (+0)" >> ./coverage
echo "Visited paths : 0 (+0)" >> ./coverage
echo "=========================" >> ./coverage

for (( i=1; i<=$2; i++ ))
do
  if [ "$(ls -A /tmp/output-$1/testcase.sorted/$i)" ]; then
    dotnet ../Eclipser/build/Eclipser.dll decode \
      -i "/tmp/output-$1/testcase.sorted/$i" \
      -o "/tmp/output-$1/testcase.sorted/$i"

    for tc_file in /tmp/output-$1/testcase.sorted/$i/decoded_files/*
    do
      echo $tc_file
      cp $tc_file ./$4
      timeout -k 3 10 ./qemu-trace-bbcount-x64 ./$1 $3 > /dev/null 2>&1
      echo "======================="
    done
  fi

  tail -n 5 ./coverage > /tmp/coverages/coverage-$i
done

tail -n 5 ./coverage > /tmp/coverage
rm -f ./coverage ./node ./edge

mkdir /tmp/output-$1/crash.reproduced/
echo "===== Now reproducing crash ======"

if [ "$(ls -A /tmp/output-$1/crash.renamed/)" ]; then
  ulimit -c unlimited
  echo -e "where 10\ninfo reg\nx/i \$rip\nquit" > gdb_command
  dotnet ../Eclipser/build/Eclipser.dll decode \
    -i "/tmp/output-$1/crash.renamed" -o "/tmp/output-$1/crash.renamed"

  gcc /home/artifact/experiment-scripts/exec.c -o ./exec.bin
  for crash_file in /tmp/output-$1/crash.renamed/decoded_files/*
  do
    echo $crash_file
    cp $crash_file ./$4
    rm -f ./core
    timeout -k 3 10 ./exec.bin ./$1 $3
    if [ -f ./core ]; then
      timeout -k 1 1 /usr/bin/gdb -q --command=gdb_command ./$1 ./core
      cp $crash_file /tmp/output-$1/crash.reproduced/
    fi
    echo "======================="
  done
fi

export ASAN_SYMBOLIZER_PATH=/usr/bin/llvm-symbolizer
export ASAN_OPTIONS=detect_leaks=0:allocator_may_return_null=1
echo "===== Now analyzing with sanitizer ======"
if [ "$(ls -A /tmp/output-$1/crash.reproduced/)" ]; then
  cp /home/artifact/package-bins/sanitize/$1 ./$1

  for crash_file in /tmp/output-$1/crash.reproduced/* # Caution, no 'decoded_..'
  do
    echo $crash_file
    cp $crash_file ./$4
    timeout -k 3 10 ./$1 $3
    echo "+++++++++++++++++++++++"
  done
fi
