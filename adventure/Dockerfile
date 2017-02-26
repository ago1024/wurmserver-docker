FROM ago1024/wurmunlimited:beta

ENV SERVERNAME=Adventure

#
# Pull steamcmd
# Pull wurm unlimited
# Copy the server data to /data/server/$SERVERNAME
# Remove the downloaded files
#
ADD $SERVERNAME.tar.gz $SERVERSDIR

VOLUME $SERVERSDIR

CMD ["Adventure"]
