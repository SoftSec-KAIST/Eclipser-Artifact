FROM jchoi2022/eclipser-artifact:v0.1

USER root
ARG HOST_UID
# Adjust the UID of 'artifact' user within the container. This enables the user
# to write files in bind mounts directory without root privilege.
RUN ./setup-scripts/adjust_uid.sh $HOST_UID

USER artifact
