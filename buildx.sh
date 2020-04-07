#!/usr/bin/env sh
#shellcheck shell=sh

REPO=mikenye
IMAGE=readsb
PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"

docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# Build & push latest
docker buildx build -t "${REPO}/${IMAGE}:protobuf-latest" --compress --push --platform "${PLATFORMS}" .

# Get piaware version from latest
docker pull "${REPO}/${IMAGE}:latest"
VERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:protobuf-latest" /VERSIONS | grep readsb | cut -d " " -f 2)

# Build & push version-specific
docker buildx build -t "${REPO}/${IMAGE}:protobuf-${VERSION}" --compress --push --platform "${PLATFORMS}" .
