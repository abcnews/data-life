#!/usr/bin/env bash
set -e

echo "Combine data files"
cat dump-mobile.json | jq -c '{id, request, response, device: "mobile"}' > request-response-combined.json
cat dump-laptop.json | jq -c '{id, request, response, device: "laptop"}' >> request-response-combined.json

echo "Removing payload"
cat request-response-combined.json | jq -c "{id, device, request: .request|del(.content), response: .response|del(.content) }" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' > requests-response-combined-no-content.json

echo "Making CSVs"
# Wide
cat request-response-combined.json | jq -c "{id, device, request, response}" | jq -c '[leaf_paths as $path | {"key": $path | join(".") | ascii_downcase, "value": getpath($path)}] | from_entries' | jq -sr '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' > request-response-combined.csv

# Narrow
cat request-response-combined.json |  jq --compact-output --raw-output '{id, device, request, response} | [leaf_paths as $path | {id: .id, field: $path | join(".") | ascii_downcase, value: getpath($path)}] | del(.[0]) | .[] | [.id, .field, .value] | @csv' > all_narrow.csv