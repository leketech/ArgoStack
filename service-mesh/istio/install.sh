#!/bin/bash

# Install Istio service mesh

set -e

echo "Installing Istio service mesh..."

# Download Istio
curl -L https://istio.io/downloadIstio | sh -

# Navigate to Istio directory
cd istio-*

# Add Istio to PATH
export PATH=$PWD/bin:$PATH

# Install Istio
istioctl install --set profile=demo -y

# Enable Istio injection for production namespace
kubectl label namespace production istio-injection=enabled

echo "Istio installation completed!"
echo "To verify installation, run: kubectl get pods -n istio-system"