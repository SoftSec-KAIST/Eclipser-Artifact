#!/bin/bash

echo "Target : " $1
echo "Timelimit : " $2
echo "Number of slots to sort by timestamp : " $3
echo "Eclipser option : " $4
echo "NSpawn : " $5
echo "NSolve : " $6

# Remove and create new box to play with
cd /home/artifact/
sudo chmod -R 777 ./box
sudo rm -rf ./box
mkdir box
chmod 777 box
cd box

# Run Eclipser
sudo cp "/root/coreutils-8.27/obj-gcc/src/$1" ./

start_time=`date "+%s"`
sudo dotnet ../Eclipser/build/Eclipser.dll fuzz -p ./$1 -t $2 -v 0 \
  $4 --usepty --nspawn $5 --nsolve $6 \

# Caution : timestamp is modified if 'chown' command below is executed first
interval=$(($2 / $3))
sudo /home/artifact/experiment-scripts/sort_by_timestamp.py \
  ./output-0/testcase $start_time $interval $3
sudo /home/artifact/experiment-scripts/rename_by_timestamp.py \
  ./output-0/crash $start_time

# Note that current directory can be chowned to root in 'ginstall'
sudo chown -R artifact.artifact ./

sudo rm -rf "/tmp/output-$1" # Just to be safe, although reboot will clear /tmp
mkdir "/tmp/output-$1"
mv ./output-0/testcase.sorted "/tmp/output-$1"
mv ./output-0/crash.renamed "/tmp/output-$1"
# Clean-up internal files to save space.
sudo rm -rf ./output-0/.internal
