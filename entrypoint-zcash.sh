#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/kth/kth-config.git
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-zcash-new.sh

echo "Cloning Config Repository ${CONFIG_REPO}"
cd /root
rm -rf kth-config
git clone ${CONFIG_REPO} kth-config
echo "Running entrypoint script ${ENTRYPOINT_SCRIPT}"
. /root/kth-config/${ENTRYPOINT_SCRIPT}
sleep 20000