FROM ubuntu:latest

ENV WURMROOT=/wurmunlimited DATADIR=/data

#
# Load packages
#
RUN apt-get -y update && apt-get install -y \
  curl \
  lib32gcc1 \
  sqlite3 \
  unzip \
&& rm -rf /var/lib/apt/lists/*

#
# Download and setup steamcmd
#
RUN mkdir /root/steamcmd && curl https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xvz -C /root/steamcmd

#
# Download WurmUnlimited server
#
ARG betabranch
ARG betapassword
RUN /root/steamcmd/steamcmd.sh +login anonymous +force_install_dir $WURMROOT +app_update 402370 ${betabranch:+-beta} ${betabranch} ${betapassword:+-betapassword} ${betapassword} validate +exit

#
# Setup modloader
#
WORKDIR $WURMROOT
RUN curl -L https://github.com/ago1024/WurmServerModLauncher/releases/download/v0.21.1/server-modlauncher-0.21.1.zip >/root/server-modlauncher.zip && unzip /root/server-modlauncher.zip && rm -rf /root/server-modlauncher.zip
RUN chmod a+x ./patcher.sh && ./patcher.sh

#
# Setup RMI Tool
#
RUN curl -L -O https://github.com/bdew-wurm/rmitool/releases/download/v1.0/rmitool.jar
COPY rmitool $WURMROOT/rmitool

#
# Setup clusterconfig
#
RUN curl -L -O https://github.com/ago1024/clusterconfig/releases/download/v1.4/clusterconfig.jar

#
# Adjust server settings
#
RUN cp linux64/steamclient.so ./nativelibs
COPY LaunchConfig.ini logging.properties $WURMROOT/
COPY launcher.sh $WURMROOT/

#
# Initialize data volume
#
COPY LaunchConfig.ini logging.properties $DATADIR/config/
RUN mkdir -p $DATADIR/servers && \
  for server in Creative Adventure; do \
    cp -r ${server}_backup $DATADIR/servers/$server && \
    rm $DATADIR/servers/$server/originaldir; \
  done

ENV PATH=$PATH:$WURMROOT:$WURMROOT/runtime/jre1.8.0_60/bin

HEALTHCHECK --interval=5m --timeout=10s \
  CMD rmitool isrunning || exit 1
EXPOSE 3724 48010 7221 7220 27016
VOLUME $DATADIR
STOPSIGNAL SIGTERM
ENTRYPOINT ["./launcher.sh"]
