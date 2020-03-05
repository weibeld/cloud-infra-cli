# Create Kubernetes infrastructure

This repository contains a script for creating and deleting the infrastructure for a simple Kubernetes cluster on GCP.

The cluster is intended for testing purposes only:

- 1 master node, 2 worker nodes
- Unrestricted GCP firewall
- Small instances

## Usage

### Basic

Creating infrastructure:

```bash
./gcp-test.sh up
```

Deleting infrastructure:

```bash
./gcp-test.sh down
```

### With suffix

The script can be invoked with an additional suffix argument. The suffix will be appended to the names of all created resources:

```bash
./gcp-test.sh up -foo
```

This appends `-foo` to all GCP resource names. For example, the VPC network will be named `k8s-foo`, the master node `k8s-master-foo`, and so on.

The same suffix must be supplied to the `down` command to delete the infrastructure:

```bash
./gcp-test.sh down -foo
```

### Multiple clusters

To create multiple clusters, the script can be invoked in a loop.

In this case, the suffix argument is mandatory to prevent name clashes:

```bash
for suffix in -foo -bar -baz; do
  ./gcp-test.sh up "$suffix"
done
```

This creates three sets of infrastrucutre for three different clusters.

To delete the entire infrastructure, use:

```bash
for suffix in -foo -bar -baz; do
  ./gcp-test.sh down "$suffix"
done
```

## GCP instance pricing

Hourly prices in the `europe-west6` region (one of the most expensive regions):

| Instance                                                                                | Price         | Capacity |
|-----------------------------------------------------------------------------------------|---------------|----------|
| [`e2-medium`](https://cloud.google.com/compute/all-pricing#e2_sharedcore_machine_types) | $0.046879 | 1 CPU (2 [shared CPUs](https://cloud.google.com/compute/docs/machine-types#e2_shared-core_machine_types)), 4 GB RAM |
| [`n1-standard-1`](https://cloud.google.com/compute/all-pricing#n1_machine_types) | $0.066500 | 1 CPU, 3.75 GB RAM |
| [`e2-standard-2`](https://cloud.google.com/compute/all-pricing#e2_machine-types) | $0.093758 | 2 CPUs, 8 GB RAM |
| [`n1-standard-2`](https://cloud.google.com/compute/all-pricing#n1_machine_types) | $0.132900 | 2 CPUs, 7.5 GB RAM |

### Example calculations

Cluster with 3 `e2-medium` instances:

- Per hour: $0.140637
- Per day: $3.38

Cluster with 1 `n1-standard-2` (master node) and 2 `n1-standard-1` instances (worker nodes):

- Per hour: $0.2659
- Per day: $6.38
