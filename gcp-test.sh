#!/bin/bash
#
# Create/delete GCP infrastructure for a Kubernetes cluster with one master and
# two worker nodes.
#
# Intended for testing purposes only since The GCP firewall is unrestricted and
# the GCP instances are rather small (but cheap).
#
# USAGE:
# 
#   k8s-gcp.sh up|down [suffix]
#
# The optional suffix is appended to all GCP resource names. This allows, for
# example, to invoke this script in a loop for creating multiple clusters.
#
# The script creates a new VPC network with a single subnet in the current
# default region. The IP address range of the subnet is 10.0.0.0/16.

suffix=$2

up() {
  set -e

  # Create VPC network 
  gcloud compute networks create k8s"$suffix" --subnet-mode custom
  gcloud compute networks subnets create k8s"$suffix" --network k8s"$suffix" --range 10.0.0.0/16

  # Add firewall rule to allow all incoming traffic from everywhere (testing)
  gcloud compute firewall-rules create k8s"$suffix" \
    --network k8s"$suffix" \
    --allow tcp,udp,icmp

  # Compute instances for master node and worker nodes
  gcloud compute instances create {k8s-master,k8s-worker-1,k8s-worker-2}"$suffix" \
    --subnet k8s"$suffix" \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-medium

#  # Create compute instance for master node (K8s master node requires 2 CPUs)
#  gcloud compute instances create k8s-master"$suffix" \
#    --subnet k8s"$suffix" \
#    --can-ip-forward \
#    --image-family ubuntu-1804-lts \
#    --image-project ubuntu-os-cloud \
#    --machine-type n1-standard-2  # Try with e2-medium
#
#  # Create compute instances for worker nodes
#  gcloud compute instances create k8s-worker-1"$suffix" k8s-worker-2"$suffix" \
#    --subnet k8s"$suffix" \
#    --can-ip-forward \
#    --image-family ubuntu-1804-lts \
#    --image-project ubuntu-os-cloud  # Try with e2-medium
}

down() {
  gcloud compute instances delete k8s-master"$suffix" k8s-worker-1"$suffix" k8s-worker-2"$suffix"
  gcloud compute firewall-rules delete k8s"$suffix"
  gcloud compute networks subnets delete k8s"$suffix"
  gcloud compute networks delete k8s"$suffix"
}

usage() {
  echo "USAGE:"
  echo "  $(basename $0) up|down [suffix]"
}

case "$1" in
  up) up ;;
  down) down ;;
  *) usage && exit 1 ;;
esac
