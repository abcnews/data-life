#!/usr/bin/env bash
set -e

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# Source and set some env variables
PROJECT_DIR=$(realpath "${BASH_SOURCE%/*}/..")
DATE=`date +%Y-%m-%d-%H-%M-%S`
DATA_DIR="$PROJECT_DIR/analysis/proxydata/$DATE"
"$PROJECT_DIR/server/.envrc"

mkdir DATA_DIR

# Connect and download the mobile data
echo "Downloading mobile data"
ssh root@$VPN_IP 'docker run --rm --volumes-from mitmproxy -v $(pwd)/backup:/backup ubuntu tar czvf /backup/flows.tar.gz /proxydata/dump.json'
ssh root@$VPN_IP 'docker logs -t mitmproxy > $(pwd)/backup/proxy-mobile.log'
rsync -rvP root@$VPN_IP:~/backup/* /tmp

echo "Unpacking mobile data"
tar -xzf /tmp/flows.tar.gz --directory /tmp
mv /tmp/proxydata/dump.json "$DATA_DIR/dump-mobile.json"
mv /tmp/proxy-mobile.log "$DATA_DIR/proxy-mobile.log"

echo 'Tidying up'
rm -rf /tmp/proxydata
rm /tmp/proxy-mobile.log

# Connect and download latest laptop data
echo "Downloading laptop data"
docker run --rm --volumes-from mitmproxy -v $DATA_DIR:/backup ubuntu cp /proxydata/dump.json /backup/dump-laptop.json
docker logs -t mitmproxy > $DATA_DIR/proxy-laptop.log

echo "Done"

# cat 2018-08-01-17-12-36-dump-laptop.json | jq -c "{id, request, response}" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' | jq -sr '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' > test.csv