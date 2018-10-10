#!/usr/bin/env bash
set -e

if [[ -z "${DATA_DIR}" ]]; then
	echo "Set DATA_DIR environment variable."
	exit 1
fi

echo "Combine data files"
cat $DATA_DIR/dump-mobile.json | jq -c '{id, request, response, device: "mobile"}' > $DATA_DIR/request-response-combined.json
cat $DATA_DIR/dump-laptop.json | jq -c '{id, request, response, device: "laptop"}' >> $DATA_DIR/request-response-combined.json

echo "Removing payload"
cat $DATA_DIR/request-response-combined.json | jq -c "{id, device, request: .request|del(.content), response: .response|del(.content) }" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' > $DATA_DIR/requests-response-combined-no-content.json

echo "Making CSVs"
cat request-response-combined.json | jq -c "{id, device, request, response}" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' | jq -sr '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' > request-response-combined.csv

echo "Setup symlinks"
rm $PROJECT_DIR/analysis/proxydata/requests-response-combined-no-content.json
ln -s "$DATA_DIR/requests-response-combined-no-content.json" "$PROJECT_DIR/analysis/proxydata/requests-response-combined-no-content.json"