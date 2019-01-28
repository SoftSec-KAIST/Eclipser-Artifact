#!/bin/bash

HOST_UID=$1
if [ $HOST_UID -eq 0 ]; then
  echo "Docker host UID=0 (rejected)"
  echo "It seems you are running docker as a root user, which we do not assume."
  echo "Please refer to 'https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user'"
  exit 1
elif [ $HOST_UID -eq 1000 ]; then
  echo "Docker host UID=1000, nothing to update."
else
  echo "Adjusting UID to $HOST_UID (takes a while)"
  usermod -u $HOST_UID artifact
  echo "Adjusting GID to $HOST_UID (takes a while)"
  groupmod -g $HOST_UID artifact
  echo "Updating file ownership"
  # UID of files within home directory are automatically updated by 'usermod'.
  find /home/artifact/ -group 1000 -exec chgrp -h artifact {} \;
fi
