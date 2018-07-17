#!/usr/bin/env bash
set -e

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# Source and set some env variables
PROJECT_DIR=$(realpath "${BASH_SOURCE%/*}/..")
DATE=`date +%Y-%m-%d-%H-%M-%S`
source "$PROJECT_DIR/server/.envrc"

# Connect and download the mobile data
echo "Downloading mobile data"
ssh root@$VPN_IP 'docker run --rm --volumes-from mitmproxy -v $(pwd)/backup:/backup ubuntu tar czvf /backup/flows.tar.gz /proxydata/dump.json'
ssh root@$VPN_IP 'docker logs -t mitmproxy > $(pwd)/backup/proxy-mobile.log'
rsync -rvP root@$VPN_IP:~/backup/* "$PROJECT_DIR/analysis/proxydata/mobile"

echo "Unpacking mobile data"
tar -xzf "$PROJECT_DIR/analysis/proxydata/mobile/flows.tar.gz" --directory /tmp
mv /tmp/proxydata/dump.json "$PROJECT_DIR/analysis/proxydata/$DATE-dump-mobile.json"
mv "$PROJECT_DIR/analysis/proxydata/mobile/proxy-mobile.log" "$PROJECT_DIR/analysis/proxydata/$DATE-proxy-mobile.log"

# Connect and download latest laptop data
echo "Downloading laptop data"
docker run --rm --volumes-from mitmproxy -v $PROJECT_DIR/analysis/proxydata:/backup ubuntu cp /proxydata/dump.json /backup/$DATE-dump-laptop.json
docker logs -t mitmproxy > $PROJECT_DIR/analysis/proxydata/$DATE-proxy-laptop.log

echo "Removing payload"
cat $PROJECT_DIR/analysis/proxydata/$DATE-dump-mobile.json | jq -c "{id, request: .request|del(.content), response: .response|del(.content) }" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' > $PROJECT_DIR/analysis/proxydata/$DATE-requests-mobile.json
cat $PROJECT_DIR/analysis/proxydata/$DATE-dump-laptop.json | jq -c "{id, request: .request|del(.content), response: .response|del(.content) }" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' > $PROJECT_DIR/analysis/proxydata/$DATE-requests-laptop.json

echo 'Tidying up'
rm -rf /tmp/proxydata

echo "Setup symlinks"
rm $PROJECT_DIR/analysis/proxydata/requests-mobile.json
rm $PROJECT_DIR/analysis/proxydata/requests-laptop.json

ln -s "$PROJECT_DIR/analysis/proxydata/$DATE-requests-mobile.json" "$PROJECT_DIR/analysis/proxydata/requests-mobile.json"
ln -s "$PROJECT_DIR/analysis/proxydata/$DATE-requests-laptop.json" "$PROJECT_DIR/analysis/proxydata/requests-laptop.json"

echo "Done"