FROM ago1024/wurmunlimited:alpha

ENV SERVERNAME=Creative

#
# Pull steamcmd
# Pull wurm unlimited
# Copy the server data to /data/server/$SERVERNAME
# Remove the downloaded files
#
ADD $SERVERNAME.tar.gz $SERVERSDIR

VOLUME $SERVERSDIR

CMD ["Creative"]
