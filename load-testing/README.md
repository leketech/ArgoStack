# Load Testing Setup

This directory contains various load testing tools and configurations for testing the sample application.

## Tools Included

1. **k6** - Modern load testing tool with JavaScript scripting
2. **Artillery** - Load testing toolkit with YAML configuration
3. **Locust** - Python-based load testing framework

## k6 Tests

The k6 tests include several different types of load tests:

- `basic-load-test.js` - Standard load test with ramping up and down
- `stress-test.js` - Stress test to find breaking points
- `spike-test.js` - Spike test for sudden traffic bursts
- `soak-test.js` - Long duration test for endurance validation

### Running k6 Tests Locally

```bash
# Install k6
npm install -g k6

# Run basic load test
k6 run load-testing/k6/basic-load-test.js

# Run with environment variables
BASE_URL=http://localhost:8080 k6 run load-testing/k6/basic-load-test.js
```

### Running k6 Tests in Kubernetes

The tests can be run in Kubernetes using the provided Job configuration:

```bash
# Apply the job
kubectl apply -f load-testing/k8s/k6-job.yaml

# Check job status
kubectl get jobs -n testing

# View logs
kubectl logs -n testing -l app=k6
```

## Artillery Tests

Artillery tests are configured in YAML format and are easier to write for simple scenarios.

### Running Artillery Tests

```bash
# Install artillery
npm install -g artillery

# Run test
artillery run load-testing/artillery/basic-test.yml
```

## Locust Tests

Locust tests are written in Python and provide programmatic control over user behavior.

### Running Locust Tests

```bash
# Install locust
pip install locust

# Run test
locust -f load-testing/locust/locustfile.py
```

## GitHub Actions Integration

A GitHub Actions workflow is provided to run load tests as part of CI/CD:

- Manual trigger with test type selection
- Automatic deployment to Kubernetes
- Results collection and notification

## Kubernetes Integration

The load testing tools can be deployed and run directly in Kubernetes:

1. **K6 Job** - Standard Kubernetes Job for running k6 tests
2. **K6 Operator** - Custom resource for managing k6 tests
3. **Namespace Isolation** - Tests run in dedicated `testing` namespace

## Configuration

All tests can be configured with environment variables:

- `BASE_URL` - Target URL for tests
- `K6_VUS` - Number of virtual users for k6
- `K6_DURATION` - Test duration for k6