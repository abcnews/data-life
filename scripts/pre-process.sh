#!/usr/bin/env bash
set -e

echo "Combine data files"
cat dump-mobile.json | jq -c '{id, request, response, device: "mobile"}' > request-response-combined.json
cat dump-laptop.json | jq -c '{id, request, response, device: "laptop"}' >> request-response-combined.json

echo "Making CSVs"
# Narrow
cat request-response-combined.json |  jq --compact-output --raw-output '{id, device, request: .request|del(.content), response:.response|del(.content)} | [leaf_paths as $path | {id: .id, field: $path | join(".") | ascii_downcase, value: getpath($path)}] | del(.[0]) | .[] | [.id, .field, .value] | @csv' > meta_narrow.csv
cat request-response-combined.json |  jq --compact-output --raw-output '{id, request: {content: .request.content}, response:{content:.response.content}} | [leaf_paths as $path | {id: .id, field: $path | join(".") | ascii_downcase, value: getpath($path)}] | del(.[0]) | .[] | [.id, .field, .value] | @csv' > content_narrow.csv