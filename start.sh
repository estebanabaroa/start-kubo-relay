#!/usr/bin/env bash

IPFS_DOWNLOAD_URL="https://dist.ipfs.io/kubo/v0.32.1/kubo_v0.32.1_linux-amd64.tar.gz"
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

# config routers
IPFS_PATH=.ipfs ./ipfs config --json Routing '{
  "Methods": {
    "find-peers": {
      "RouterName": "HttpRouterNotSupported"
    },
    "find-providers": {
      "RouterName": "HttpRoutersParallel"
    },
    "get-ipns": {
      "RouterName": "HttpRouterNotSupported"
    },
    "provide": {
      "RouterName": "HttpRoutersParallel"
    },
    "put-ipns": {
      "RouterName": "HttpRouterNotSupported"
    }
  },
  "Routers": {
    "HttpRouter1": {
      "Parameters": {
        "Endpoint": "http://127.0.0.1:19575"
      },
      "Type": "http"
    },
    "HttpRouter2": {
      "Parameters": {
        "Endpoint": "http://127.0.0.1:19576"
      },
      "Type": "http"
    },
    "HttpRouter3": {
      "Parameters": {
        "Endpoint": "http://127.0.0.1:19577"
      },
      "Type": "http"
    },
    "HttpRouter4": {
      "Parameters": {
        "Endpoint": "http://127.0.0.1:19578"
      },
      "Type": "http"
    },
    "HttpRouterNotSupported": {
      "Parameters": {
        "Endpoint": "http://kubonotsupported"
      },
      "Type": "http"
    },
    "HttpRoutersParallel": {
      "Parameters": {
        "Routers": [
          {
            "IgnoreErrors": true,
            "RouterName": "HttpRouter1",
            "Timeout": "10s"
          },
          {
            "IgnoreErrors": true,
            "RouterName": "HttpRouter2",
            "Timeout": "10s"
          },
          {
            "IgnoreErrors": true,
            "RouterName": "HttpRouter3",
            "Timeout": "10s"
          },
          {
            "IgnoreErrors": true,
            "RouterName": "HttpRouter4",
            "Timeout": "10s"
          }
        ]
      },
      "Type": "parallel"
    }
  },
  "Type": "custom"
}'

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

# config autotls
IPFS_PATH=.ipfs ./ipfs config --json AutoTLS '{
  "Enabled": true
}'
IPFS_PATH=.ipfs ./ipfs config --json Addresses.Swarm '[
  "/ip4/0.0.0.0/tcp/4001",
  "/ip6/::/tcp/4001",
  "/ip4/0.0.0.0/udp/4001/webrtc-direct",
  "/ip4/0.0.0.0/udp/4001/quic-v1",
  "/ip4/0.0.0.0/udp/4001/quic-v1/webtransport",
  "/ip6/::/udp/4001/webrtc-direct",
  "/ip6/::/udp/4001/quic-v1",
  "/ip6/::/udp/4001/quic-v1/webtransport",
  "/ip4/0.0.0.0/tcp/4002/tls/sni/*.libp2p.direct/ws",
  "/ip6/::/tcp/4002/tls/sni/*.libp2p.direct/ws"
]'

IPFS_PATH=.ipfs ./ipfs daemon
