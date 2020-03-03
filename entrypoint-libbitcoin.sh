#!/bin/bash
#HTTP_ADDR=http://172.17.0.1
OUTPUT_FILE=/opt/libbitcoin/etc/bs.cfg
#OUTPUT_FILE=./bitprim-node.cfg
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git

configure_external_port()
{

[ "$NETWORK" == "testnet" ] && PORT=18333 || PORT=8333

for portmap in $(curl -s http://rancher-metadata/latest/self/container/ports)
do
    PORT_MAPPING=$(curl -s http://rancher-metadata/latest/self/container/ports/${portmap} | grep ":${PORT}")
    if [ -n "${PORT_MAPPING}" ]
    then
        MAPPED_PORT_LINE=$(echo ${PORT_MAPPING} | cut -d: -f1,2)
        EXTERNAL_IP=$(echo ${MAPPED_PORT_LINE} | cut -d: -f1)
        MAPPED_PORT=$(echo ${MAPPED_PORT_LINE} | cut -d: -f2)
        break
    fi
done

[ "${EXTERNAL_IP}" == "0.0.0.0" ] && EXTERNAL_IP=$(curl -s http://rancher-metadata/latest/self/host/agent_ip)
echo "Configuring network.self as: ${EXTERNAL_IP}:${MAPPED_PORT}"
sed -i "s/self =.*/self = ${EXTERNAL_IP}:${MAPPED_PORT}/g" $OUTPUT_FILE

}

copy_config()
{
echo "Cloning config repository $CONFIG_REPO"
cd /opt/libbitcoin ; rm -rf bitprim-config
git clone ${CONFIG_REPO}


if [ -n "$CONFIG_FILE" ] ; then
echo "Copying ${CONFIG_FILE} from repo (CONFIG_FILE variable found)"
cp bitprim-config/$CONFIG_FILE ${OUTPUT_FILE}

else
[ ! -n "$COIN" ] && COIN=btc
[ ! -n "$NETWORK" ] && NETWORK=mainnet
echo "Copying bitprim-node-${COIN}-${NETWORK}.cfg from repo"
cp bitprim-config/libbitcoin-server-${COIN}-${NETWORK}.cfg  ${OUTPUT_FILE}
fi

DB_DIR=$(sed -nr "/^\[database\]/ { :l /^directory[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $OUTPUT_FILE)
}

_term() {
  echo "Caught SIGTERM signal!"
  echo Waiting for $child
  kill -TERM "$child" ; wait $child 2>/dev/null
}



start_libbitcoin()
{
echo "Starting $(/opt/libbitcoin/bin/bs --version)"
if [ ! -d "${DB_DIR}" ] ; then echo "Initializing database directory"
/opt/libbitcoin/bin/bs -c $OUTPUT_FILE -i
fi
trap _term SIGTERM
/opt/libbitcoin/bin/bs -c $OUTPUT_FILE &
child=$!
wait $child


}


configure_secret_key()
{
sed -i "s#server_private_key =.*#server_private_key = ${SERVER_PRIVATE_KEY}#g" $OUTPUT_FILE
}


copy_config
configure_external_port
configure_secret_key
start_libbitcoin
