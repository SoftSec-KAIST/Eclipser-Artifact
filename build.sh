#!/bin/bash
echo "Please check README.md first if you haven't yet."
echo "Building an image takes a long time (consider running pull.sh instead)"
printf "Do you wish to continue? [y/n] "
read answer
if [ "$answer" == "y" ]; then
  docker build -t eclipser:v0.1 -f Dockerfile --build-arg HOST_UID=$(id -u) .
fi
