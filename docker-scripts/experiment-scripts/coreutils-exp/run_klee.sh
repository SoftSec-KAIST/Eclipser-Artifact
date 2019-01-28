#!/bin/bash

echo "Target : " $1
echo "Timelimit : " $2
echo "Number of slots to sort by timestamp : " $3
echo "KLEE option : " $4

cd /home/artifact

rm -rf /tmp/test.env
env -i /bin/bash -c '(source experiment-scripts/testing-env.sh; env > /tmp/test.env)'
rm -rf /tmp/sandbox
cp experiment-scripts/sandbox.tgz /tmp/
tar xzvf /tmp/sandbox.tgz -C /tmp

cd /home/artifact/
sudo chmod -R 777 ./box
sudo rm -rf ./box
mkdir box
chmod 777 box
cd box

sudo extract-bc /root/coreutils-8.27/obj-llvm/src/"$1" 
sudo mv /root/coreutils-8.27/obj-llvm/src/"$1".bc ./

# Options used below are retrieved from http://klee.github.io/docs/coreutils-experiments/
start_time=`date "+%s"`
klee_cmd="ulimit -s unlimited && ulimit -n 49000 && /home/artifact/klee_build/bin/klee --simplify-sym-indices --write-cvcs --write-cov --output-module --max-memory=1000 --disable-inlining --optimize --use-forked-solver --use-cex-cache --libc=uclibc --posix-runtime --allow-external-sym-calls --only-output-states-covering-new --environ=/tmp/test.env --run-in=/tmp/sandbox --max-sym-array-size=4096 --max-instruction-time=30. --max-time=$2. --watchdog --max-memory-inhibit=false --max-static-fork-pct=1 --max-static-solve-pct=1 --max-static-cpfork-pct=1 --switch-type=internal --search=random-path --search=nurs:covnew --use-batching-search --batch-instructions=10000 './${1}.bc' $4"
sudo /bin/bash -c "$klee_cmd"

# Caution : timestamp is modified if 'chown' command below is executed first
interval=$(($2 / $3))
sudo /home/artifact/experiment-scripts/sort_by_timestamp.py \
  ./klee-out-0 $start_time $interval $3
sudo /home/artifact/experiment-scripts/rename_by_timestamp.py \
  ./klee-out-0 $start_time

# Note that current directory can be chowned to root in 'ginstall'
sudo chown -R artifact.artifact ./

sudo rm -rf "/tmp/output-$1" # Just to be safe, although reboot will clear /tmp
mkdir "/tmp/output-$1"
mv ./klee-out-0.sorted "/tmp/output-$1"
mv ./klee-out-0.renamed "/tmp/output-$1"
