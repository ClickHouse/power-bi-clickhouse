#!/bin/sh
# Build ClickHouse.mez (flat zip of the connector sources). Usage: ./build-mez.sh [outdir]
set -eu
cd "$(dirname "$0")"
out="${1:-.}"
tmp="$(mktemp -d)"
cp ClickHouseConnector.pq "$tmp/ClickHouseConnector.m"
cp ./*.pqm ./*.resx ./*.png "$tmp/"
(cd "$tmp" && zip -j -q ClickHouse.mez ./*)
mv "$tmp/ClickHouse.mez" "$out/ClickHouse.mez"
rm -rf "$tmp"
echo "built $out/ClickHouse.mez ($(wc -c < "$out/ClickHouse.mez") bytes)"
