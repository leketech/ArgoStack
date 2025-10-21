#!/bin/bash

# Backup ETCD script
# Note: This script should be run on the Kubernetes master node

set -e

echo "Backing up ETCD..."

# Create backup directory
BACKUP_DIR="/backup/etcd"
mkdir -p $BACKUP_DIR

# Get ETCD pod name
ETCD_POD=$(kubectl get pods -n kube-system | grep etcd | awk '{print $1}')

# Backup ETCD
kubectl exec -n kube-system $ETCD_POD -- \
  etcdctl snapshot save /tmp/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Copy backup to local directory
kubectl cp kube-system/$ETCD_POD:/tmp/etcd-snapshot.db $BACKUP_DIR/etcd-snapshot-$(date +%Y%m%d-%H%M%S).db

echo "ETCD backup completed successfully!"
echo "Backup location: $BACKUP_DIR"