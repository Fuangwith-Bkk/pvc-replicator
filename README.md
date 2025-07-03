# PVC Replicator

## 📝 Project Overview

The `pvc-replicator` is a demo application designed to continuously replicate data from a source Persistent Volume Claim (PVC) to a destination PVC. This can be useful for scenarios like:
* Migrating data between different storage classes (e.g., from a vSAN RWX to an AWS gp3 RWO).
* Creating live backups or mirrors of data.
* Synchronizing content between single-writer (RWO) and multi-writer (RWX) volumes.

The application mounts two PVCs (one as source, one as destination) and uses standard file system commands to copy content at a configurable interval.

## 🚀 Getting Started

Follow these steps to deploy the `pvc-replicator` on your OpenShift or Kubernetes cluster.

### Prerequisites

* An OpenShift or Kubernetes cluster (tested with OpenShift).
* Configured StorageClasses, specifically:
    * `gp3-csi` (for `ReadWriteOnce` volumes, e.g., for `my-rwo`)
    * `ocs-storagecluster-cephfs` (for `ReadWriteMany` volumes, e.g., for `my-rwx` from OpenShift Data Foundation)
* `oc` (OpenShift CLI) or `kubectl` CLI tool configured to your cluster.

### 1. Build and Push the Container Image 

If you're building the image yourself and pushing to an external registry (like Quay.io, Docker Hub, GCR), follow these steps. If you are using OpenShift's internal registry and ImageStreams, you can adapt the `Dockerfile` and OpenShift `BuildConfig` logic.

```bash
# 1. Ensure you are in the root of the repository
cd pvc-replicator

# 2. Build the Docker image
docker build -t [your-registry.com/your-org/pvc-replicator:latest](https://your-registry.com/your-org/pvc-replicator:latest) .

# 3. Log in to your container registry (if private)
docker login your-registry.com

# 4. Push the image
docker push [your-registry.com/your-org/pvc-replicator:latest](https://your-registry.com/your-org/pvc-replicator:latest)

Remember to replace your-registry.com/your-org/pvc-replicator:latest with your actual image path.

### 2. Create Persistent Volume Claims (PVCs)

Navigate to the openshift/ directory and apply the pvc-replicator-pvc.yaml

cd openshift/
oc apply -f pvc-replicator-pvc.yaml -n test1 # Adjust namespace as needed


### 3. Deploy the PVC Replicator Application
cd openshift/
oc apply -f pvc-replicator-deployment.yaml -n test1 # Adjust namespace as needed