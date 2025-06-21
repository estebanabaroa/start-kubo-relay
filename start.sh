#!/usr/bin/env bash

IPFS_DOWNLOAD_URL="https://dist.ipfs.io/kubo/v0.35.0/kubo_v0.35.0_linux-amd64.tar.gz"
IPFS_PATH="./ipfs"

# download ipfs
if [ ! -f "$IPFS_PATH" ]; then
  echo "downloading ipfs..."
  TEMP_DIR=$(mktemp -d)
  TAR_FILE="$TEMP_DIR/kubo.tar.gz"
  curl -L "$IPFS_DOWNLOAD_URL" -o "$TAR_FILE"
  tar -xzf "$TAR_FILE" -C "$TEMP_DIR" --strip-components=1
  mv "$TEMP_DIR/ipfs" "$IPFS_PATH"
  rm -rf "$TEMP_DIR"
else
  echo "$IPFS_PATH already exists, skipping download"
fi

IPFS_PATH=.ipfs ./ipfs init

# config relay
IPFS_PATH=.ipfs ./ipfs config --json Swarm.RelayService '{
  "Enabled": true,
  "Limit": {
    "Duration": "60m",
    "Data": 10000000000,
    "ConnectionDurationLimit": "60m",
    "ConnectionDataLimit": 10000000000,
    "ReservationTTL": "6h",
    "MaxReservations": 100000,
    "MaxCircuits": 1000,
    "MaxReservationsPerIP": 100,
    "MaxReservationsPerASN": 500
  },
  "ConnectionDurationLimit": "60m",
  "ConnectionDataLimit": 10000000000,
  "ReservationTTL": "6h",
  "MaxReservations": 100000,
  "MaxCircuits": 1000,
  "MaxReservationsPerIP": 100,
  "MaxReservationsPerASN": 500
}'

IPFS_PATH=.ipfs ./ipfs daemon
