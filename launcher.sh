#!/bin/bash

## 
## WurmUnlimited docker server launcher script
##
## Link files from $DATADIR/config into $WURMROOT
## Link server folder from $DATADIR/servers/$SERVERNAME into $WURMROOT/$SERVERNAME
## Link logging folder from $DATADIR/logs/$SERVERNAME into $WURMROOT/logging
##

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

# Start server
cd $WURMROOT
$WURMROOT/WurmServerLauncher "Start=$SERVERNAME" "$@"
