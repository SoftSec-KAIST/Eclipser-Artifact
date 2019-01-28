#!/bin/bash
rm -rf output-test
mkdir output-test
docker run --rm -it --cap-add=SYS_PTRACE --name eclipser \
  --cpuset-cpus=0 \
  --memory=4096m \
  --volume $(pwd)/output-test:/home/artifact/output \
  eclipser:v0.1
