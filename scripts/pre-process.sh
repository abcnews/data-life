#!/usr/bin/env bash
set -e

# There's now something broken in the mobile dump because something crashed and corrupted the file at some point. 
# This excises the damage. Run it before the pre-processing.
# echo "Removing bad line from dump-mobile.json"
# sed -i.bak -e '78060d' dump-mobile.json

echo "Combine data files"
echo "Read dump-mobile.json"
cat dump-mobile.json | jq -c '{id, error, request, response, device: "mobile"}' > request-response-combined.json
echo "Read dump-laptop.json"
cat dump-laptop.json | jq -c '{id, error, request, response, device: "laptop"}' >> request-response-combined.json

echo "Making CSVs"
# Narrow
cat request-response-combined.json |  jq --compact-output --raw-output '{id, device, error, request: .request|del(.content), response:.response|del(.content)} | [leaf_paths as $path | {id: .id, field: $path | join(".") | ascii_downcase, value: getpath($path)}] | del(.[0]) | .[] | [.id, .field, .value] | @csv' > meta_narrow.csv
# cat request-response-combined.json |  jq --compact-output --raw-output '{id, request: {content: .request.content}, response:{content:.response.content}} | [leaf_paths as $path | {id: .id, field: $path | join(".") | ascii_downcase, value: getpath($path)}] | del(.[0]) | .[] | [.id, .field, .value] | @csv' > content_narrow.csv