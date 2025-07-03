#!/bin/bash

IMAGE_NAME="pvc-replicator"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="your_registry_url/$IMAGE_NAME:$IMAGE_TAG" # Replace your_registry_url

echo "Building container image: $FULL_IMAGE_NAME"

# Use podman if available, otherwise docker
if command -v podman &> /dev/null; then
    BUILD_CMD="podman build"
else
    BUILD_CMD="docker build"
fi

$BUILD_CMD -f ../Containerfile -t "$FULL_IMAGE_NAME" ..

if [ $? -eq 0 ]; then
    echo "Image built successfully: $FULL_IMAGE_NAME"
    echo "You can push this image to your OpenShift internal registry or external registry:"
    echo "  podman push $FULL_IMAGE_NAME"
    echo "  docker push $FULL_IMAGE_NAME"
else
    echo "Image build failed."
    exit 1
fi