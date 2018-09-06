#!/bin/bash

## 
## WurmUnlimited docker server launcher script
##
## Link files from $DATADIR/config into $WURMROOT
## Copy files from $DATADIR/mods into $WURMROOT/mods
## Link server folder from $DATADIR/servers/$SERVERNAME into $WURMROOT/$SERVERNAME
## Link logging folder from $DATADIR/logs/$SERVERNAME into $WURMROOT/logging
##

set -e

function die() {
  echo "$*"
  exit -1
}

# Check WURMROOT
test -z "$WURMROOT" && die "WURMROOT environment variable is not set"
test -d "$WURMROOT" || die "WURMROOT ($WURMROOT) is not a directory"

# Check DATADIR
test -z "$DATADIR" && die "DATADIR environment variable is not set"
test -d "$DATADIR" || die "DATADIR ($DATADIR) is not a directory"

# Check SERVERSDIR
test -z "$SERVERSDIR" && die "SERVERSDIR environment variable is not set"
test -d "$SERVERSDIR" || die "SERVERSDIR ($SERVERSDIR) is not a directory"

# Check SERVERNAME
SERVERNAME="$1"
test -z "$SERVERNAME" && die "Usage: laucher.sh servername [additional WurmServerLauncher options]"
shift

SERVERDIR="$SERVERSDIR/$SERVERNAME"
LOGGINGDIR="$SERVERSDIR/$SERVERNAME/Logs"

# Overlay config files
find /data/config -mindepth 1 -maxdepth 1 -type f | while read configfile; do
  ln -sfv $configfile $WURMROOT/
done

# Overlay mod files
test -d $DATADIR/mods && cp -rv $DATADIR/mods $WURMROOT/

# Set wurm.ini option
function setoption() {
  option="$1"
  value="$2"

  sed -n -i -e "/^$option=/!p" -e "\$a$option=$value" "$WURMROOT/$SERVERNAME/wurm.ini"
}

# Link server directory
if test -d "$SERVERDIR"; then
  ln -sfv "$SERVERDIR" $WURMROOT/
  ln -sfvn "$SERVERDIR" $WURMROOT/currentserver

  # Enable RMI
  setoption USE_INCOMING_RMI true
  # Disable auto networking
  setoption AUTO_NETWORKING false
  setoption ENABLE_PNP_PORT_FORWARD false

  mkdir -p "$LOGGINGDIR"
  ln -sfvn "$LOGGINGDIR" $WURMROOT/logging
else
  die "Server directory '$SERVERDIR' is missing"
fi

if test ! -f "$WURMROOT/mods/httpserver.config" -a -n "$HTTPSERVER_HOSTNAME"; then
  cat >"$WURMROOT/mods/httpserver.config" <<EOF
serverPort=8787
publicServerAddress=$HTTPSERVER_HOSTNAME
publicServerPort=$HTTPSERVER_PORT
EOF
fi

# Setup server for cluster
if test -f servers.yml; then
  java -jar clusterconfig.jar servers.yml --verify $SERVERNAME || die "servers.yml is not valid"
  java -jar clusterconfig.jar servers.yml --ini $SERVERNAME | while read option value; do
    setoption "$option" "$value"
  done || die "failed to set server options"

  java -jar clusterconfig.jar servers.yml --sql $SERVERNAME | \
    sqlite3 $WURMROOT/currentserver/sqlite/wurmlogin.db || die "Failed to server server ports"
fi


# Set local IP and ports
ip=$(hostname -i)
echo "UPDATE SERVERS SET INTRASERVERADDRESS='$ip', INTRASERVERPORT='48010', EXTERNALIP='$ip', EXTERNALPORT='3724', RMIPORT='7220', REGISTRATIONPORT='7221' WHERE LOCAL=1;" | \
  sqlite3 $WURMROOT/currentserver/sqlite/wurmlogin.db || die "Failed to set local server ip"

function term_handler() {
  echo "term_handler $pid"
  if test "$pid" -ne 0; then
    echo "rmitool shutdown"
    $WURMROOT/rmitool shutdown docker 10 "Server shutdown" || kill -TERM "$pid"
    wait "$pid"
  fi
  exit 143
}
trap 'term_handler' SIGTERM SIGINT

cd $WURMROOT
$WURMROOT/WurmServerLauncher "Start=$SERVERNAME" "$@" &
pid="${!}"
wait
