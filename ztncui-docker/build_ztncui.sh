#!/bin/bash
DOCKER_IMAGE="chengxudong2020/ztncui"
docker buildx build --platform linux/amd64 -t "$DOCKER_IMAGE":latest --push .
