#!/bin/bash

## 
## WurmUnlimited docker server launcher script
##
## Link files from $DATADIR/config into $WURMROOT
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

# Check SERVERNAME
SERVERNAME="$1"
test -z "$SERVERNAME" && die "Usage: laucher.sh servername [additional WurmServerLauncher options]"
shift

SERVERDIR="$DATADIR/servers/$SERVERNAME"
LOGGINGDIR="$DATADIR/logs/$SERVERNAME"

# Overlay config files
find /data/config -maxdepth 1 -type f | while read configfile; do
  ln -sfv $configfile $WURMROOT/
done

# Set wurm.ini option
function setoption() {
  option="$1"
  value="$2"

  sed -n -i -e "/^$option=/!p" -e "\$a$option=$value" "$WURMROOT/$SERVERNAME/wurm.ini"
}

# Link server directory
if test -d "$SERVERDIR"; then
  ln -sfv "$SERVERDIR" $WURMROOT/
  ln -sfv "$SERVERDIR" $WURMROOT/currentserver

  # Enable RMI
  setoption USE_INCOMING_RMI true

  mkdir -p "$LOGGINGDIR"
  ln -sfv "$LOGGINGDIR" $WURMROOT/logging
else
  die "Server directory '$SERVERDIR' is missing"
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
trap 'kill ${!}; term_handler' SIGTERM SIGINT

# Start server
cd $WURMROOT
$WURMROOT/WurmServerLauncher "Start=$SERVERNAME" "$@" &
pid="${!}"

while true
do
  tail -f /dev/null & wait ${!}
done
