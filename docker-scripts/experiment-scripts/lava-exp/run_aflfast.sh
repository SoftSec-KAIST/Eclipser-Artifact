#!/bin/bash

echo "Target : " $1
echo "Timelimit : " $2
echo "Number of slots to sort by timestamp : " $3
echo "Command-line argument : " $4
echo "Input file : " $5

# Remove and create new box to use.
cd /home/artifact
sudo chmod -R 777 ./box
sudo rm -rf ./box
mkdir box
chmod 777 box
cd box

# Run AFLFast
cp /home/artifact/LAVA-data/llvm-bins/$1 ./$1
cp -r /home/artifact/LAVA-data/seeds/$1 ./seeds
mkdir output

export AFL_NO_AFFINITY=1
export AFL_INST_LIBS=1
start_time=`date "+%s"`
timeout $2 ../aflfast/afl-fuzz -m 4096 -t 500 -i ./seeds -o ./output -f $5 \
  -Q -- ./$1 $4

/home/artifact/experiment-scripts/rename_by_timestamp.py \
  ./output/crashes $start_time

# Check test case directory
echo "Test cases # : "
ls -l ./output/queue | wc -l

# Copy to /tmp/output, for replay
rm -rf "/tmp/output-$1" # Just to be safe, although reboot will clear /tmp
mkdir "/tmp/output-$1"
mv output/crashes.renamed "/tmp/output-$1/crash.renamed"

# Append fuzzer log to 'log-run'
echo "===== 'fuzzer_stats' content ====="
cat output/fuzzer_stats
