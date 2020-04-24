#!/bin/bash
#
# This script creates (and deletes) the following resources:
#
#   1 VPC network
#   1 subnet
#   3 firewall rules
#   3 VM instances
#
#------------------------------------------------------------------------------#

set -e

# Name for the resources. There should be no existing resources with this name.
name=gcp-example-infra

up() {
  # Create VPC network 
  gcloud compute networks create "$name" --subnet-mode custom

  # Create subnet
  gcloud compute networks subnets create "$name" --network "$name" --range 10.0.0.0/16

  # Create instances
  gcloud compute instances create "$name"-1 "$name"-2 "$name"-3 \
    --subnet "$name" \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --tags "$name"

  # Create firewall rule 1 (allow all incoming traffic from other instances)
  gcloud compute firewall-rules create "$name"-internal \
    --network "$name" \
    --allow tcp,udp,icmp \
    --target-tags "$name" \
    --source-tags "$name"

  # Create firewall rule 2 (allow incoming HTTP traffic from everywhere)
  gcloud compute firewall-rules create "$name"-http\
    --network "$name" \
    --allow tcp:80 \
    --target-tags "$name"

  # Create firewall rule 3 (allow incoming SSH traffic from your local machine)
  gcloud compute firewall-rules create "$name"-ssh \
    --network "$name" \
    --allow tcp:22 \
    --target-tags "$name" \
    --source-ranges "$(curl -s checkip.amazonaws.com)"/32

  cat <<EOF

✅ Done!

You can list the created instances with:

  gcloud compute instances list --filter 'tags.items=$name'

You can log in to an instance through SSH with:

  gcloud compute ssh root@INSTANCE-NAME

EOF
}

down() {
  gcloud compute instances delete "$name"-1 "$name"-2 "$name"-3
  gcloud compute firewall-rules delete "$name"-internal "$name"-http "$name"-ssh
  gcloud compute networks subnets delete "$name"
  gcloud compute networks delete "$name"

  cat <<EOF

✅ Done!

All resources have been deleted.

EOF
}

usage() {
  echo "USAGE:"
  echo "  $(basename $0) up|down"
}

case "$1" in
  up) up ;;
  down) down ;;
  *) usage && exit 1 ;;
esac
