#!/usr/bin/env bash

# deploy to a server

# go to current folder
cd "$(dirname "$0")"
cd ..

# add env vars
if [ -f .deploy-env ]; then
  export $(echo $(cat .deploy-env | sed 's/#.*//g'| xargs) | envsubst)
fi

# check creds
if [ -z "${DEPLOY_HOST+xxx}" ]; then echo "DEPLOY_HOST not set" && exit; fi
if [ -z "${DEPLOY_USER+xxx}" ]; then echo "DEPLOY_USER not set" && exit; fi
if [ -z "${DEPLOY_PASSWORD+xxx}" ]; then echo "DEPLOY_PASSWORD not set" && exit; fi

SCRIPT="
docker exec ipfs sh -c 'IPFS_PATH=.ipfs ./ipfs id'
docker logs -n 100 ipfs
#docker logs --follow -n 100 addresses-rewriter-proxy-server
#docker exec ipfs sh -c 'IPFS_PATH=.ipfs ./ipfs dag get bafkreiczsscdsbs7ffqz55asqdf3smv6klcw3gofszvwlyarci47bgf354'
"

# execute script over ssh
echo "$SCRIPT" | sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$DEPLOY_HOST"
