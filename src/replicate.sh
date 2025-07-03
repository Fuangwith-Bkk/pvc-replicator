#!/bin/bash

# Trap signals to ensure graceful exit
trap 'echo "Script interrupted by SIGINT/SIGTERM. Exiting gracefully."; exit 0' SIGINT SIGTERM

echo "Starting PVC replication process..."

# Source and Destination PVC mount paths (these will be mounted into the pod)
# These paths are fixed based on how PVCs are mounted in OpenShift/Kubernetes.
# The container runtime ensures these directories exist.
SOURCE_PVC_PATH="${SOURCE_PVC_PATH:-/mnt/source}" # Make path configurable via ENV, with default
DESTINATION_PVC_PATH="${DESTINATION_PVC_PATH:-/mnt/destination}" # Make path configurable via ENV, with default

# Rsync parameters from ConfigMap (passed as environment variables)
# Default to common parameters if not set
# -a: archive mode (recursive, preserves permissions, ownership, timestamps, symlinks)
# -v: verbose
# -z: compress file data during transfer
# --delete: deletes extraneous files from dest dir (if they don't exist in source)
RSYNC_PARAMS="${RSYNC_PARAMS:- -avz --delete}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-300}" # Default to 5 minutes (300 seconds)

echo "Source PVC Path: $SOURCE_PVC_PATH"
echo "Destination PVC Path: $DESTINATION_PVC_PATH"
echo "Rsync Parameters: $RSYNC_PARAMS"
echo "Replication Interval: $INTERVAL_SECONDS seconds"

# Basic validation of mount paths
if [ ! -d "$SOURCE_PVC_PATH" ]; then
    echo "Error: Source path '$SOURCE_PVC_PATH' does not exist or is not a directory. Ensure PVC is mounted correctly."
    exit 1
fi
if [ ! -d "$DESTINATION_PVC_PATH" ]; then
    echo "Error: Destination path '$DESTINATION_PVC_PATH' does not exist or is not a directory. Ensure PVC is mounted correctly."
    exit 1
fi
if [ -z "$(ls -A "$SOURCE_PVC_PATH" 2>/dev/null)" ]; then # Added 2>/dev/null to suppress 'ls' errors if directory is truly inaccessible for some reason
   echo "Warning: Source path '$SOURCE_PVC_PATH' appears to be empty."
fi

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP: Starting rsync from $SOURCE_PVC_PATH/ to $DESTINATION_PVC_PATH/"
    echo "$TIMESTAMP: Running command: rsync $RSYNC_PARAMS \"$SOURCE_PVC_PATH/\" \"$DESTINATION_PVC_PATH/\""

    # Perform the rsync operation
    # The trailing slash on SOURCE_PVC_PATH/ is crucial to copy contents *of* the source
    # into the destination. Without the trailing slash on DESTINATION_PVC_PATH/,
    # rsync will copy the contents directly into the root of the destination mount.
    rsync $RSYNC_PARAMS "$SOURCE_PVC_PATH/" "$DESTINATION_PVC_PATH/"

    RSYNC_EXIT_CODE=$? # Capture exit code immediately

    if [ $RSYNC_EXIT_CODE -eq 0 ]; then
        echo "$TIMESTAMP: Rsync completed successfully."
    elif [ $RSYNC_EXIT_CODE -eq 24 ]; then
        echo "$TIMESTAMP: Rsync completed with warnings (exit code 24 - some files disappeared during transfer). This may be acceptable."
    else
        echo "$TIMESTAMP: Rsync failed with exit code $RSYNC_EXIT_CODE."
        # This is where you might add more robust error handling for critical failures
    fi

    echo "$TIMESTAMP: Waiting for $INTERVAL_SECONDS seconds before next replication..."
    sleep "$INTERVAL_SECONDS"
done