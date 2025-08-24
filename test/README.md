# Test Files

This directory contains test files for validating the Karpenter dynamic maxPods solution.

## Test Files Overview

### Basic Tests
- `test-pod.yaml` - Basic test pod that triggers m5.xlarge or larger instances
- `test-multi-instances.yaml` - Multi-instance type test for various scenarios

### Instance-Specific Triggers
- `trigger-c5-large.yaml` - Triggers c5.large instance creation
- `trigger-c5-large-small.yaml` - Triggers c5.large with smaller resource requirements
- `trigger-m5-xlarge.yaml` - Triggers m5.xlarge instance creation

### Validation Tests
- `test-m5-validation.yaml` - M5 series instance validation
- `test-t3-validation.yaml` - T3 series instance validation

## Usage

Deploy any test file to validate the dynamic maxPods calculation:

```bash
# Basic test
kubectl apply -f test/test-pod.yaml

# Multi-instance test
kubectl apply -f test/test-multi-instances.yaml

# Specific instance type test
kubectl apply -f test/trigger-m5-xlarge.yaml
```

## Monitoring

After deploying tests, monitor the results:

```bash
# Watch node creation
kubectl get nodeclaims -w

# Check node maxPods configuration
kubectl describe node <node-name> | grep -E "(instance-type|pods)"

# View calculation logs
kubectl logs -n karpenter deployment/karpenter
```

## Cleanup

Remove test pods when done:

```bash
kubectl delete -f test/
```
