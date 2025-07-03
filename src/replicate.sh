#!/bin/bash

# Ensure necessary tools are installed (rsync)
if ! command -v rsync &> /dev/null
then
    echo "rsync could not be found, installing..."
    yum update -y && yum install -y rsync
fi

# Trap signals to ensure graceful exit
trap 'echo "Script interrupted. Exiting."; exit 1' SIGINT SIGTERM

echo "Starting PVC replication process..."

# Source and Destination PVC mount paths (these will be mounted into the pod)
# These paths are fixed based on how PVCs are mounted in OpenShift.
SOURCE_PVC_PATH="/mnt/source"
DESTINATION_PVC_PATH="/mnt/destination"

# Rsync parameters from ConfigMap (passed as environment variables)
# Default to common parameters if not set
RSYNC_PARAMS="${RSYNC_PARAMS:- -avz --delete}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-300}" # Default to 5 minutes

echo "Source PVC Path: $SOURCE_PVC_PATH"
echo "Destination PVC Path: $DESTINATION_PVC_PATH"
echo "Rsync Parameters: $RSYNC_PARAMS"
echo "Replication Interval: $INTERVAL_SECONDS seconds"

# Ensure source and destination directories exist
mkdir -p "$SOURCE_PVC_PATH"
mkdir -p "$DESTINATION_PVC_PATH"

while true; do
    echo "$(date): Starting rsync from $SOURCE_PVC_PATH to $DESTINATION_PVC_PATH"
    echo "Running command: rsync $RSYNC_PARAMS $SOURCE_PVC_PATH/ $DESTINATION_PVC_PATH/"

    # Perform the rsync operation
    # The trailing slash on SOURCE_PVC_PATH/ is crucial to copy contents, not the directory itself
    rsync $RSYNC_PARAMS "$SOURCE_PVC_PATH/" "$DESTINATION_PVC_PATH/"

    if [ $? -eq 0 ]; then
        echo "$(date): Rsync completed successfully."
    else
        echo "$(date): Rsync failed with exit code $?."
    fi

    echo "$(date): Waiting for $INTERVAL_SECONDS seconds before next replication..."
    sleep "$INTERVAL_SECONDS"
done