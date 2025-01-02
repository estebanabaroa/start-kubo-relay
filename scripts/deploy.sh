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
cd /home
git clone https://github.com/estebanabaroa/start-kubo-relay.git
cd start-kubo-relay
git reset HEAD --hard
git pull
"

# execute script over ssh
echo "$SCRIPT" | sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$DEPLOY_HOST"

# copy files
FILE_NAMES=(
  # .env
)

# copy files
for FILE_NAME in ${FILE_NAMES[@]}; do
  sshpass -p "$DEPLOY_PASSWORD" scp $FILE_NAME "$DEPLOY_USER"@"$DEPLOY_HOST":/home/start-kubo-relay
done

SCRIPT="
cd /home/start-kubo-relay
scripts/start-docker.sh
"

echo "$SCRIPT" | sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$DEPLOY_HOST"
