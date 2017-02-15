FROM ubuntu:latest

ENV WURMROOT=/wurmunlimited DATADIR=/data
ARG betabranch
ARG betapassword
ARG MODLOADER_VERSION=0.21.1
ARG CLUSTERCONFIG_VERSION=1.4
ARG RMITOOL_VERSION=1.0

#
# Load packages
#
RUN \
  apt-get -y update && \
  apt-get install -y \
    curl \
    lib32gcc1 \
    sqlite3 \
    unzip \
    && \
  rm -rf /var/lib/apt/lists/*

#
# Download and setup steamcmd, Download WU Server
#
RUN \
  mkdir /root/steamcmd && \
  curl https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xvz -C /root/steamcmd && \
  /root/steamcmd/steamcmd.sh \
    +login anonymous \
    +force_install_dir $WURMROOT \
    +app_update 402370 ${betabranch:+-beta} ${betabranch} ${betapassword:+-betapassword} ${betapassword} validate \
    +exit && \
  cp $WURMROOT/linux64/steamclient.so $WURMROOT/nativelibs && \
  rm -rf /root/steamcmd && \
  mkdir -p $DATADIR/servers && \
  for server in Creative Adventure; do \
    cp -rv $WURMROOT/${server}_backup $DATADIR/servers/$server && \
    rm -rv $DATADIR/servers/$server/originaldir; \
  done && \
  rm -rf $WURMROOT/*_backup

#
# Setup modloader
#
WORKDIR $WURMROOT
RUN \
  curl -L -O https://github.com/ago1024/WurmServerModLauncher/releases/download/v${MODLOADER_VERSION}/server-modlauncher-${MODLOADER_VERSION}.zip && \
  unzip $WURMROOT/server-modlauncher-${MODLOADER_VERSION} && \
  rm $WURMROOT/server-modlauncher-${MODLOADER_VERSION}.zip && \
  rm -rf $WURMROOT/mods/* && \
  /bin/bash $WURMROOT/patcher.sh && \
  mv -v $WURMROOT/WurmServerLauncher-patched $WURMROOT/WurmServerLauncher

#
# Setup RMI Tool
#
RUN curl -L -O https://github.com/bdew-wurm/rmitool/releases/download/v${RMITOOL_VERSION}/rmitool.jar
COPY rmitool $WURMROOT/rmitool

#
# Setup clusterconfig
#
RUN curl -L -O https://github.com/ago1024/clusterconfig/releases/download/v${CLUSTERCONFIG_VERSION}/clusterconfig.jar

#
# Adjust server settings
#
COPY LaunchConfig.ini logging.properties $WURMROOT/
COPY launcher.sh $WURMROOT/

#
# Initialize data volume
#
COPY LaunchConfig.ini logging.properties $DATADIR/config/

ENV PATH=$PATH:$WURMROOT:$WURMROOT/runtime/jre1.8.0_60/bin

HEALTHCHECK --interval=5m --timeout=10s \
  CMD $WURMROOT/rmitool isrunning || exit 1
EXPOSE 3724 48010 7221 7220 27016
VOLUME $DATADIR
STOPSIGNAL SIGTERM
ENTRYPOINT ["./launcher.sh"]
