#!/bin/bash

cd /home/artifact/
sudo chmod -R 777 ./box
sudo rm -rf ./box
mkdir box
chmod 777 box
cd box

cp /home/artifact/LAVA-data/llvm-bins/$1 ./$1

echo "===== Running crashes ======"
if [ "$(ls -A /tmp/output-$1/crash.renamed/)" ]; then
  for crash in /tmp/output-$1/crash.renamed/*
  do
    echo $crash
    cp $crash ./$3
    timeout --kill-after=3 5 ./$1 $2
    echo "======================="
  done
fi
