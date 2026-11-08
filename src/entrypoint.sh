#!/bin/sh
# ===========================================================================
# UniFi Network Controller entrypoint wrapper for TOS 7.
#
# The upstream image boots with the s6-overlay v3 init, whose service manager
# runs as root: it creates the config folders, links /usr/lib/unifi/{data,logs}
# into /config and then starts the bundled Java controller (which spawns its
# own MongoDB on 127.0.0.1). With user "1000:1000" that init cannot run, and
# the controller would fall back to the root-owned paths inside the image.
#
# TOS forbids root containers, so this wrapper does the same three steps itself
# and then runs the very same Java command the s6 service runs. /usr/lib/unifi/
# data and /usr/lib/unifi/logs are bind-mounted from the application data
# folder, which makes them writable for uid 1000 without touching the image.
# ===========================================================================
set -u

CONFIG_DIR=/config
DATA_DIR=/usr/lib/unifi/data
LOG_DIR=/usr/lib/unifi/logs
RUN_DIR=/usr/lib/unifi/run

mkdir -p "$CONFIG_DIR/data" "$CONFIG_DIR/logs" "$DATA_DIR" "$LOG_DIR" "$RUN_DIR"

# First-run defaults, exactly like the image's init script (never overwritten).
if [ ! -e "$DATA_DIR/system.properties" ] && [ -e /defaults/system.properties ]; then
  cp /defaults/system.properties "$DATA_DIR/system.properties" 2>/dev/null || true
fi

export TZ="${TZ:-Asia/Shanghai}"

MEM_STARTUP="${MEM_STARTUP:-128}"
MEM_LIMIT="${MEM_LIMIT:-1024}"

cd "$CONFIG_DIR" || exit 1
exec java \
  -Xms"${MEM_STARTUP}M" -Xmx"${MEM_LIMIT}M" \
  -Dlog4j2.formatMsgNoLookups=true \
  -Dfile.encoding=UTF-8 \
  -Djava.awt.headless=true \
  -Dapple.awt.UIElement=true \
  -XX:+UseParallelGC \
  -XX:+ExitOnOutOfMemoryError \
  -XX:+CrashOnOutOfMemoryError \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.time=ALL-UNNAMED \
  --add-opens java.base/sun.security.util=ALL-UNNAMED \
  --add-opens java.base/java.io=ALL-UNNAMED \
  --add-opens java.rmi/sun.rmi.transport=ALL-UNNAMED \
  -jar /usr/lib/unifi/lib/ace.jar start
