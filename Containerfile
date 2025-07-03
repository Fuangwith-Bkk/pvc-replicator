# Use a RHEL 8 base image (adjust version as needed for OpenShift compatibility)
FROM registry.redhat.io/ubi8/ubi-minimal:latest

# Set a working directory
WORKDIR /app

# Copy the replication script
COPY src/replicate.sh /app/replicate.sh

# Install rsync and any other necessary tools
# ubi-minimal uses microdnf, which is a lighter version of dnf
RUN microdnf update -y && \
    microdnf install -y rsync && \
    microdnf clean all

# Make the script executable
RUN chmod +x /app/replicate.sh

# Define default environment variables (can be overridden by ConfigMap)
ENV RSYNC_PARAMS="-avz --delete"
ENV INTERVAL_SECONDS="300"

# Command to run the replication script when the container starts
CMD ["/app/replicate.sh"]