#!/bin/bash

echo "Target :" $1
echo "Timelimit :" $2
echo "Number of slots to sort by timestamp : " $3
echo "Command-line argument : " $4
echo "Input file : " $5
echo "NSpawn : " $6
echo "NSolve : " $7

# Remove and create new box to use.
cd /home/artifact
sudo chmod -R 777 ./box
sudo rm -rf ./box
mkdir box
chmod 777 box
cd box

# Run Eclipser
cp /home/artifact/LAVA-data/llvm-bins/$1 ./$1
cp -r /home/artifact/LAVA-data/seeds/$1 ./seeds

start_time=`date "+%s"`
dotnet ../Eclipser/build/Eclipser.dll fuzz -p $1 -t $2 -v 0 -i seeds \
  --src file --maxfilelen 1048576 --initarg "$4" --fixfilepath $5 \
  --nspawn $6 --nsolve $7

/home/artifact/experiment-scripts/rename_by_timestamp.py \
  ./output-0/crash $start_time

# Copy to /tmp/output, for replay
rm -rf "/tmp/output-$1" # Just to be safe, although reboot will clear /tmp
mkdir "/tmp/output-$1"
mv ./output-0/crash.renamed "/tmp/output-$1"
