#!/bin/bash

cd /root/coreutils-8.27/obj-gcov/
rm -rf ./*.gcov
cd src
rm -rf ./*.gcda

rm -rf ./box
mkdir box
chmod 777 box
cp "./$1" ./box
cd box

rm -rf "/tmp/coverages"
mkdir "/tmp/coverages"

for (( i=1; i<=$2; i++ ))
do
  if [ "$(ls -A /tmp/output-$1/testcase.sorted/$i)" ]; then
    dotnet /home/artifact/Eclipser/build/Eclipser.dll replay -p "./$1" \
      -i "/tmp/output-$1/testcase.sorted/$i" --usepty
  fi
  cd ../../ # Should move to .../obj-gcov/
  gcov -b ./src/$3 > "/tmp/coverages/coverage-$i" 2>&1
  cd ./src/box # Now move back into the box
done

cd ../../ # Should move to .../obj-gcov/
gcov -b ./src/$3 > "/tmp/coverage" 2>&1
chown artifact.artifact "/tmp/coverage"
chown -R artifact.artifact "/tmp/coverages"
