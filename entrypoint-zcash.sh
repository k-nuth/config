#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-zcash-new.sh

echo "Cloning Config Repository ${CONFIG_REPO}"
cd /root
rm -rf bitprim-config
git clone ${CONFIG_REPO} bitprim-config
echo "Running entrypoint script ${ENTRYPOINT_SCRIPT}"
. /root/bitprim-config/${ENTRYPOINT_SCRIPT}
sleep 20000