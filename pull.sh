#!/bin/bash

echo "Pulling Eclipser artifact image from Docker Hub..."
docker pull jchoi2022/eclipser-artifact:v0.1
echo "Building a local image from the pull image..."
docker build -t eclipser:v0.1 -f Pull.Dockerfile --build-arg HOST_UID=$(id -u) .
