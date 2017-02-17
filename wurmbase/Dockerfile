FROM ubuntu:latest

#
# Load packages
#
RUN \
  apt-get -y update && \
  apt-get install -y \
    curl \
    lib32gcc1 \
    && \
  rm -rf /var/lib/apt/lists/*

#
# Add java
#
ADD runtime.tar.gz /opt/

#
# Download steamcmd
#
RUN \
  mkdir /opt/steamcmd && \
  curl https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xvz -C /opt/steamcmd && \
  /opt/steamcmd/steamcmd.sh +exit
