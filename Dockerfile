#
# Base system
#
FROM openjdk:8-jre-stretch AS base
ENV WURMROOT=/wurmunlimited DATADIR=/data SERVERSDIR=/servers
WORKDIR $WURMROOT

# Packages
RUN \
  apt-get -y update && \
  apt-get install -y \
    sqlite3 \
    unzip \
    curl \
    openjfx \
    && \
  rm -rf /var/lib/apt/lists/*

#
# Steamcmd
#
FROM base AS steamcmd

RUN apt-get -y update
RUN apt-get install -y lib32gcc1

WORKDIR /opt/steamcmd
ADD https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz /opt/steamcmd
RUN tar xvzf steamcmd_linux.tar.gz -C /opt/steamcmd
RUN /opt/steamcmd/steamcmd.sh +exit

#
# Build
#
FROM steamcmd AS build
WORKDIR $WURMROOT

RUN apt-get -y update
RUN apt-get install -y lib32gcc1

# Versions
ARG betabranch=
ARG betapassword=
ARG WURMVER=3127452

# Download wurmunlimited
RUN /opt/steamcmd/steamcmd.sh \
    +login anonymous \
    +force_install_dir $WURMROOT \
    +app_update 402370 ${betabranch:+-beta} ${betabranch} ${betapassword:+-betapassword} ${betapassword} validate \
    +exit
# stream shared libs
RUN mv $WURMROOT/linux64/steamclient.so $WURMROOT/nativelibs
RUN rm $WURMROOT/steamclient.so

# move bundled servers out of wurmunlimited dir
RUN mkdir /dist
RUN for SERVER in Creative Adventure; do \
  mv $WURMROOT/dist/$SERVER /dist && \
  rm /dist/$SERVER/originaldir && \
  touch /dist/$SERVER/gamedir && \
  mkdir $WURMROOT/dist/$SERVER && \
  touch $WURMROOT/dist/$SERVER/originaldir ; \
  done

# move runtime out of wurmunlimited dir
RUN mv $WURMROOT/runtime /runtime

#
# Runtime
#
FROM base AS runtime
# not needed. We have openjdk + openjfx in the base image
#COPY --from=build /runtime /runtime
#RUN ln -sf /runtime $WURMROOT/runtime

#
# Server
#
FROM runtime AS server

# Copy server from build image
COPY --from=build $WURMROOT $WURMROOT

# Setup modloader
ARG MODLOADER_VERSION=0.40
WORKDIR $WURMROOT
RUN \
  curl -L -O https://github.com/ago1024/WurmServerModLauncher/releases/download/v${MODLOADER_VERSION}/server-modlauncher-${MODLOADER_VERSION}.zip && \
  unzip $WURMROOT/server-modlauncher-${MODLOADER_VERSION} && \
  rm $WURMROOT/server-modlauncher-${MODLOADER_VERSION}.zip && \
  /bin/bash $WURMROOT/patcher.sh && \
  mv -v $WURMROOT/WurmServerLauncher-patched $WURMROOT/WurmServerLauncher


# Setup RMI Tool
ARG RMITOOL_VERSION=1.0
RUN curl -L -O https://github.com/bdew-wurm/rmitool/releases/download/v${RMITOOL_VERSION}/rmitool.jar
COPY rmitool $WURMROOT/rmitool

# Setup clusterconfig
ARG CLUSTERCONFIG_VERSION=1.4
RUN curl -L -O https://github.com/ago1024/clusterconfig/releases/download/v${CLUSTERCONFIG_VERSION}/clusterconfig.jar

# Adjust server settings
COPY LaunchConfig.ini logging.properties $WURMROOT/
# Launcher
COPY launcher.sh $WURMROOT/

# Initialize data volume
COPY LaunchConfig.ini logging.properties $DATADIR/config/

ENV PATH=$PATH:$WURMROOT
#ENV PATH=$PATH:$WURMROOT/runtime/jre1.8.0_121/bin

ENV HTTPSERVER_PORT 8787
ENV HTTPSERVER_HOSTNAME ""

HEALTHCHECK --interval=5m --timeout=10s \
  CMD $WURMROOT/rmitool isrunning || exit 1
EXPOSE 3724 48010 7221 7220 8787 27016
STOPSIGNAL SIGTERM
ENTRYPOINT ["./launcher.sh"]

VOLUME $SERVERSDIR
VOLUME $DATADIR

#
# Creative
#
FROM server AS creative
COPY --from=build /dist/Creative $SERVERSDIR/Creative

#
# Adventure
#
FROM server AS adventure
COPY --from=build /dist/Adventure $SERVERSDIR/Adventure

#
# Final stage (default result)
#
FROM server
