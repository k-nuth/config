#!/bin/bash
#HTTP_ADDR=http://172.17.0.1
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
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
sed -i "s/self =.*/self = ${EXTERNAL_IP}:${MAPPED_PORT}/g" /bitprim/conf/bitprim-node.cfg

}

install_additional_packages()
{
if [ ! -e /tmp/already_installed ] ; then
    apt-get update
    apt-get -y install $ADDITIONAL_PACKAGES
    if [ $? -eq 0 ] ; then
	echo "$ADDITIONAL_PACKAGES installed" >/tmp/already_installed
    fi
fi
}

copy_config()
{
echo "Cloning config repository $CONFIG_REPO"
cd /bitprim ; rm -rf bitprim-config
git clone ${CONFIG_REPO}


if [ -n "$CONFIG_FILE" ] ; then
echo "Copying ${CONFIG_FILE} from repo (CONFIG_FILE variable found)"
cp bitprim-config/$CONFIG_FILE ${OUTPUT_FILE}

else
[ ! -n "$COIN" ] && COIN=btc
[ ! -n "$NETWORK" ] && NETWORK=mainnet
echo "Copying bitprim-node-${COIN}-${NETWORK}.cfg from repo"
cp bitprim-config/bitprim-node-${COIN}-${NETWORK}.cfg  ${OUTPUT_FILE}
fi

DB_DIR=$(sed -nr "/^\[database\]/ { :l /^directory[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $OUTPUT_FILE)
}

clean_db_directory()
{
if [ -d "${DB_DIR}" ] ; then
  if [ ! -e /tmp/cleaned_db_directory ] ; then
  echo "Cleaning up database directory"
  rm -rf $DB_DIR/* && rmdir $DB_DIR
  [ $? -eq 0 ] && touch /tmp/cleaned_db_directory
  fi
fi


}

_term() {
  echo "Caught SIGTERM signal!"
  echo Waiting for $child
  kill -TERM "$child" ; wait $child 2>/dev/null
}

start_bitprim()
{
if [ ! -d "${DB_DIR}" ] ; then echo "Initializing database directory"
/bitprim/bin/bn -c $OUTPUT_FILE -i
fi
trap _term SIGTERM
echo "Starting $(/bitprim/bin/bn --version)"
/bitprim/bin/bn -c $OUTPUT_FILE &
child=$!
wait $child
}

### WORK Starts Here

copy_config
[ -n "$CLEAN_DB_DIRECTORY" ] && clean_db_directory
configure_external_port
[ -n "$ADDITIONAL_PACKAGES" ] && install_additional_packages
start_bitprim
