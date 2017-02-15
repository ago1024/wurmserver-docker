FROM ago1024/wurmunlimited:public

ENV SERVERNAME=Creative

#
# Pull steamcmd
# Pull wurm unlimited
# Copy the server data to /data/server/$SERVERNAME
# Remove the downloaded files
#
RUN \
  /opt/steamcmd/steamcmd.sh \
    +login anonymous \
    +force_install_dir /tmp/wurm \
    +app_update 402370 validate \
    +exit && \
  mkdir -pv $SERVERSDIR && \
  for server in $SERVERNAME; do \
    cp -rv /tmp/wurm/${server}_backup $SERVERSDIR/$server && \
    rm -rv $SERVERSDIR/$server/originaldir; \
  done && \
  rm -rf /tmp/wurm

VOLUME $SERVERSDIR

CMD ["Creative"]
