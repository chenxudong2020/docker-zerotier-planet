#!/bin/bash

USER=zerotier
REPO=ZeroTierOne
DOCKER_IMAGE="xubiaolin/zerotier-planet"


 
docker buildx build --platform linux/amd64 -t "$DOCKER_IMAGE":latest .
