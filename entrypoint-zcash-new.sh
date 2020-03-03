#!/bin/bash
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
NODE_MEMORY_LIMIT=8192
NODE_NAME="bitcore-${COIN}-${NETWORK}"
IS_TESTNET=0
BITCORE_NETWORK=livenet


configure_zcash()
{
echo "Creating Zcash config file"
[ ! -d  /root/.zcash/blockchain ] && mkdir /root/.zcash/blockchain
cat <<EOF >/root/.zcash/zcash.conf
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://0.0.0.0:28332
zmqpubhashblock=tcp://0.0.0.0:28332
#rpcbind=127.0.0.1
rpcport=8332
rpcallowip=127.0.0.1
rpcallowip=10.42.0.0/16
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
showmetrics=0
metricsui=0
EOF
cat /root/.zcash/zcash.conf
}



_term() {
  echo "Caught SIGTERM signal!"
  echo Waiting for $child
  kill -TERM "$child" ; wait $child 2>/dev/null
}

start_zcash()
{
trap _term SIGTERM
echo "Starting Bitcore"
cd /root/.bitcoin/${NODE_NAME}
/usr/bin/zcashd -conf=/root/.zcash/zcash.conf  -datadir=/root/.zcash/blockchain -showmetrics=0 -printtoconsole -disabledeprecation=1.0.13 &
#bitcore start >/dev/console &
child=$!
wait $child
}

### WORK Starts Here

configure_zcash
start_zcash
