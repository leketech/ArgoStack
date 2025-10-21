#!/bin/bash

# Install Linkerd service mesh

set -e

echo "Installing Linkerd service mesh..."

# Install Linkerd CLI
curl -sL https://run.linkerd.io/install | sh

# Add Linkerd to PATH
export PATH=$HOME/.linkerd2/bin:$PATH

# Check Kubernetes cluster
linkerd check --pre

# Install Linkerd
linkerd install | kubectl apply -f -

# Wait for Linkerd to be ready
linkerd check

# Enable Linkerd injection for production namespace
kubectl get namespace production -o yaml | linkerd inject - | kubectl apply -f -

echo "Linkerd installation completed!"
echo "To verify installation, run: linkerd check"