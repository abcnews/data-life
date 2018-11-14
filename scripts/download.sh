#!/usr/bin/env bash
set -e

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# Source and set some env variables
PROJECT_DIR=$(realpath "${BASH_SOURCE%/*}/..")
DATE=`date +%Y-%m-%d-%H-%M-%S`
DATA_DIR="$PROJECT_DIR/analysis/data/proxy"
source "$PROJECT_DIR/server/.envrc"

mkdir -p $DATA_DIR

# Connect and download latest laptop data
echo "Downloading laptop data"
docker run --rm --volumes-from mitmproxy -v $DATA_DIR:/backup rsync:alpine rsync -rvP --no-R /proxydata/dump.json /backup/dump-laptop.json
docker logs -t mitmproxy > $DATA_DIR/proxy-laptop.log

# Connect and download the mobile data
echo "Downloading mobile data from $VPN_IP"
ssh root@$VPN_IP 'docker run --rm --volumes-from mitmproxy -v $(pwd)/backup:/backup ubuntu cp /proxydata/dump.json /backup/dump-mobile.json'
ssh root@$VPN_IP 'docker logs -t mitmproxy > $(pwd)/backup/proxy-mobile.log'
rsync -rvPz root@$VPN_IP:~/backup/* $DATA_DIR

echo "Done"
