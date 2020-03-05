# Create Kubernetes infrastructure

This repository contains various scripts for creating the infrastructure for a Kubernetes cluster.

## [`gcp-test.sh`](gcp-test.sh)

Create infrastrucutre for a simple Kubernetes cluster for testing purposes on GCP:

- One master node and two worker nodes
- Unrestricted GCP firewall
- Small instances

### Usage

Creating a single cluster:

```bash
./gcp-test.sh
```

Creating multiple clusters:

```bash
for suffix in -foo -bar -baz; do
  ./gcp-test.sh "$suffix"
done
```

This creates three sets of infrastructure (for three clusters) with a different suffix for the resources of each set. For example, the above would create VPC networks `k8s-foo`, `k8s-bar`, `k8s-baz`, master nodes `k8s-master-foo`, `k8s-master-bar`, `k8s-master-baz`, and so on.



