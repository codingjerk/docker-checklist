#!/usr/bin/env bash

docker run \
  -it \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  --log-opt compress=true \
  hello-world
