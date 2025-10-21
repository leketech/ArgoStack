#!/bin/bash
# Complete cluster setup with all components

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setting Up Kubernetes Cluster${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if kubectl is configured
check_kubectl() {
    echo -e "${BLUE}Checking kubectl configuration...${NC}"
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}kubectl is not configured. Please configure it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}kubectl is configured${NC}"
}

# Install ArgoCD
install_argocd() {
    echo -e "${BLUE}Installing ArgoCD...${NC}"
    
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo -e "${YELLOW}Waiting for ArgoCD to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Get admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo -e "${GREEN}ArgoCD installed successfully${NC}"
    echo -e "${YELLOW}ArgoCD Admin Password: ${ARGOCD_PASSWORD}${NC}"
    echo -e "${YELLOW}Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
}

# Install Argo Rollouts
install_argo_rollouts() {
    echo -e "${BLUE}Installing Argo Rollouts...${NC}"
    
    kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    
    echo -e "${YELLOW}Waiting for Argo Rollouts to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=180s deployment/argo-rollouts -n argo-rollouts
    
    echo -e "${GREEN}Argo Rollouts installed successfully${NC}"
}

# Install Prometheus Stack
install_prometheus() {
    echo -e "${BLUE}Installing Prometheus Stack...${NC}"
    
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Prometheus Helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install kube-prometheus-stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.retention=30d \
        --set grafana.adminPassword=admin123 \
        --set grafana.persistence.enabled=true \
        --set grafana.persistence.size=10Gi \
        --wait
    
    echo -e "${GREEN}Prometheus Stack installed successfully${NC}"
    echo -e "${YELLOW}Grafana Admin Password: admin123${NC}"
    echo -e "${YELLOW}Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80${NC}"
}

# Install Ingress NGINX
install_ingress_nginx() {
    echo -e "${BLUE}Installing Ingress NGINX...${NC}"
    
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.metrics.enabled=true \
        --set controller.podAnnotations."prometheus\.io/scrape"=true \
        --set controller.podAnnotations."prometheus\.io/port"="10254" \
        --wait
    
    echo -e "${GREEN}Ingress NGINX installed successfully${NC}"
}

# Install Cert Manager
install_cert_manager() {
    echo -e "${BLUE}Installing Cert Manager...${NC}"
    
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    echo -e "${YELLOW}Waiting for Cert Manager to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=180s deployment/cert-manager -n cert-manager
    
    echo -e "${GREEN}Cert Manager installed successfully${NC}"
}

# Install Sealed Secrets
install_sealed_secrets() {
    echo -e "${BLUE}Installing Sealed Secrets...${NC}"
    
    helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
    helm repo update
    
    helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
        --namespace kube-system \
        --wait
    
    echo -e "${GREEN}Sealed Secrets installed successfully${NC}"
}

# Apply monitoring configurations
apply_monitoring_config() {
    echo -e "${BLUE}Applying monitoring configurations...${NC}"
    
    if [ -d "monitoring/prometheus" ]; then
        kubectl apply -f monitoring/prometheus/
    fi
    
    if [ -d "monitoring/grafana" ]; then
        kubectl apply -f monitoring/grafana/
    fi
    
    echo -e "${GREEN}Monitoring configurations applied${NC}"
}

# Apply ArgoCD applications
apply_argocd_apps() {
    echo -e "${BLUE}Applying ArgoCD applications...${NC}"
    
    if [ -d "argocd/applications" ]; then
        kubectl apply -f argocd/applications/
    fi
    
    if [ -d "argocd/projects" ]; then
        kubectl apply -f argocd/projects/
    fi
    
    echo -e "${GREEN}ArgoCD applications applied${NC}"
}

# Main setup
main() {
    check_kubectl
    
    echo -e "${BLUE}Creating namespaces...${NC}"
    kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
    
    install_argocd
    install_argo_rollouts
    install_prometheus
    install_ingress_nginx
    install_cert_manager
    install_sealed_secrets
    apply_monitoring_config
    apply_argocd_apps
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Cluster setup completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Access your tools:"
    echo "  ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
    echo "  Prometheus: kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090"
    echo ""
    echo "Next steps:"
    echo "  1. Login to ArgoCD UI (admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d))"
    echo "  2. Apply your applications via ArgoCD"
    echo "  3. Monitor your applications via Grafana/Prometheus"
}

main