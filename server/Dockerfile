FROM ago1024/wurmbase

ENV WURMROOT=/wurmunlimited DATADIR=/data SERVERSDIR=/servers
ARG betabranch=
ARG betapassword=
ARG MODLOADER_VERSION=0.22
ARG CLUSTERCONFIG_VERSION=1.4
ARG RMITOOL_VERSION=1.0

#
# Load packages
#
RUN \
  apt-get -y update && \
  apt-get install -y \
    sqlite3 \
    unzip \
    && \
  rm -rf /var/lib/apt/lists/*

#
# Download WU Server
#
RUN \
  /opt/steamcmd/steamcmd.sh \
    +login anonymous \
    +force_install_dir $WURMROOT \
    +app_update 402370 ${betabranch:+-beta} ${betabranch} ${betapassword:+-betapassword} ${betapassword} validate \
    +exit && \
  mv $WURMROOT/linux64/steamclient.so $WURMROOT/nativelibs && \
  rm $WURMROOT/steamclient.so && \
  mkdir -p $SERVERSDIR && \
  rm -rf $WURMROOT/*_backup && \
  rm -rf $WURMROOT/runtime && \
  ln -sf /opt/runtime $WURMROOT

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
STOPSIGNAL SIGTERM
ENTRYPOINT ["./launcher.sh"]
