root_path=$(cd `dirname $0` && cd .. && pwd)
cd "$root_path"

docker rm -f ipfs 2>/dev/null

# start kubo daemon
docker run \
  --detach \
  --network=host \
  --volume=$(pwd):/usr/src/ipfs \
  --workdir=/usr/src/ipfs \
  --name ipfs \
  --restart always \
  --log-opt max-size=10m \
  --log-opt max-file=5 \
  node:18 sh -c "./start.sh"

# wait for kubo daemon to start
docker logs --follow ipfs &
sleep 5


# not needed, the relays don't do any provide
# docker rm -f addresses-rewriter-proxy-server 2>/dev/null

# # start addresses-rewriter-proxy-server
# docker run \
#   --detach \
#   --network=host \
#   --volume=$(pwd):/usr/src/addresses-rewriter-proxy-server \
#   --workdir=/usr/src/addresses-rewriter-proxy-server \
#   --name addresses-rewriter-proxy-server \
#   --restart always \
#   --log-opt max-size=10m \
#   --log-opt max-file=5 \
#   node:18 addresses-rewriter-proxy-server.js

# docker logs --follow addresses-rewriter-proxy-server
