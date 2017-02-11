FROM ubuntu:latest

ENV WURMROOT=/wurmunlimited DATADIR=/data

#
# Load packages
#
RUN apt-get -y update && apt-get install -y \
	curl \
	lib32gcc1 \
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
# Adjust server settings
#
RUN cp linux64/steamclient.so ./nativelibs
COPY LaunchConfig.ini logging.properties $WURMROOT/
COPY launcher.sh $WURMROOT/

#
# Initialize data volume
#
COPY LaunchConfig.ini logging.properties $DATADIR/config/
RUN chmod a+x launcher.sh
RUN mkdir -p $DATADIR/servers && \
	for server in Creative Adventure; do \
		cp -rp ${server}_backup $DATADIR/servers/$server; \
	done

EXPOSE 3724 48010 7221 7220 27016
VOLUME $DATADIR
ENTRYPOINT ["./launcher.sh"]
