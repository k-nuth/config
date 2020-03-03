#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=git@github.com:kth-Infra/blockdozer.git
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-blockdozer-new.sh

echo "Cloning Config Repository ${CONFIG_REPO}"
cd /root
mkdir -p /root/.ssh
echo "${SSH_KEY}" >.ssh/id_rsa
chmod 600 .ssh/id_rsa
rm -rf kth-config
cat <<EOF >/root/.ssh/config 
Host *
StrictHostKeyChecking no 
EOF
cat /root/.ssh/id_rsa
cat /root/.ssh/config
git clone ${CONFIG_REPO} kth-config
echo "Running entrypoint script ${ENTRYPOINT_SCRIPT}"
. /root/kth-config/${ENTRYPOINT_SCRIPT}
sleep 20000