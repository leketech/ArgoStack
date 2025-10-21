# Makefile for DevOps Project

# Variables
NAMESPACE ?= production
APP_NAME ?= sample-app

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Help
.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Installation
install: ## Install all required tools
	@echo "$(BLUE)Installing required tools...$(NC)"
	./scripts/install-tools.sh

##@ Cluster Setup
setup: ## Setup Kubernetes cluster with all components
	@echo "$(BLUE)Setting up Kubernetes cluster...$(NC)"
	./scripts/setup-cluster.sh

##@ Port Forwarding
port-forward-argocd: ## Port forward ArgoCD UI
	@echo "$(GREEN)Access ArgoCD at https://localhost:8080$(NC)"
	@echo "$(YELLOW)Username: admin$(NC)"
	@echo "$(YELLOW)Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)$(NC)"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

port-forward-prometheus: ## Port forward Prometheus
	@echo "$(GREEN)Access Prometheus at http://localhost:9090$(NC)"
	kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

port-forward-grafana: ## Port forward Grafana
	@echo "$(GREEN)Access Grafana at http://localhost:3000$(NC)"
	@echo "$(YELLOW)Username: admin$(NC)"
	@echo "$(YELLOW)Password: admin123$(NC)"
	kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

port-forward-alertmanager: ## Port forward Alertmanager
	@echo "$(GREEN)Access Alertmanager at http://localhost:9093$(NC)"
	kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

##@ Deployment
deploy-dev: ## Deploy application to development environment
	@echo "$(BLUE)Deploying to development environment...$(NC)"
	kubectl apply -f argocd/applications/sample-app-dev.yml

deploy-staging: ## Deploy application to staging environment
	@echo "$(BLUE)Deploying to staging environment...$(NC)"
	kubectl apply -f argocd/applications/sample-app-staging.yml

deploy-prod: ## Deploy application to production environment
	@echo "$(BLUE)Deploying to production environment...$(NC)"
	kubectl apply -f argocd/applications/sample-app-prod.yml

##@ Rollout Management
rollout-status: ## Check rollout status
	@echo "$(BLUE)Checking rollout status...$(NC)"
	kubectl argo rollouts get rollout $(APP_NAME) -n $(NAMESPACE)

rollout-promote: ## Promote canary rollout
	@echo "$(BLUE)Promoting rollout...$(NC)"
	kubectl argo rollouts promote $(APP_NAME) -n $(NAMESPACE)

rollout-abort: ## Abort rollout
	@echo "$(BLUE)Aborting rollout...$(NC)"
	kubectl argo rollouts abort $(APP_NAME) -n $(NAMESPACE)

##@ Monitoring
monitor: ## Access monitoring dashboards
	@echo "$(BLUE)Starting monitoring dashboards...$(NC)"
	@echo "$(GREEN)Access Grafana at http://localhost:3000$(NC)"
	@echo "$(GREEN)Access Prometheus at http://localhost:9090$(NC)"
	@echo "$(GREEN)Access Alertmanager at http://localhost:9093$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
	kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
	kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &
	wait

##@ Load Testing
load-test-basic: ## Run basic load test
	@echo "$(BLUE)Running basic load test...$(NC)"
	k6 run load-testing/k6/basic-load-test.js

load-test-stress: ## Run stress test
	@echo "$(BLUE)Running stress test...$(NC)"
	k6 run load-testing/k6/stress-test.js

load-test-spike: ## Run spike test
	@echo "$(BLUE)Running spike test...$(NC)"
	k6 run load-testing/k6/spike-test.js

load-test-soak: ## Run soak test
	@echo "$(BLUE)Running soak test...$(NC)"
	k6 run load-testing/k6/soak-test.js

##@ Security
scan-image: ## Scan Docker image for vulnerabilities
	@echo "$(BLUE)Scanning Docker image...$(NC)"
	trivy image ghcr.io/your-org/$(APP_NAME):latest

##@ Cleanup
clean: ## Clean up port-forward processes
	@echo "$(BLUE)Cleaning up...$(NC)"
	pkill -f "kubectl port-forward" || true

##@ Documentation
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	./scripts/generate-docs.sh

.PHONY: install setup port-forward-argocd port-forward-prometheus port-forward-grafana port-forward-alertmanager
.PHONY: deploy-dev deploy-staging deploy-prod
.PHONY: rollout-status rollout-promote rollout-abort
.PHONY: monitor load-test-basic load-test-stress load-test-spike load-test-soak
.PHONY: scan-image clean docs