# Production Deployment Guide

## Quick Setup

### 1. Update Configuration
Edit the following files and replace `YOUR_CLUSTER_NAME` with your actual EKS cluster name:
- `ec2nodeclass-production.yaml`
- `nodepool-production.yaml`

### 2. Deploy to Cluster
```bash
# Set your cluster name
export CLUSTER_NAME="your-cluster-name"

# Update configuration files
sed -i "s/YOUR_CLUSTER_NAME/$CLUSTER_NAME/g" ec2nodeclass-production.yaml

# Deploy the production configuration
kubectl apply -f ec2nodeclass-production.yaml
kubectl apply -f nodepool-production.yaml
```

### 3. Verification
```bash
# Check nodes are created with correct maxPods
kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE:.metadata.labels.node\\.kubernetes\\.io/instance-type,MAXPODS:.status.allocatable.pods

# Check calculation logs (replace NODE_NAME)
kubectl debug node/NODE_NAME -it --image=busybox -- cat /host/var/log/mixed-deployment-calc.log
```

## Production Formula

The solution uses a conservative formula to prevent deployment failures:
```
maxPods = system_pods + available_ENI_IPs
```

### Supported Instance Types
| Instance Type | System Pods | ENI IPs | maxPods | vs Default | Potential Waste |
|---------------|-------------|---------|---------|------------|-----------------|
| m5.large | 2 | 18 | 20 | 29 | 9 pods (31%) |
| m5.xlarge | 3 | 42 | 45 | 58 | 13 pods (22%) |
| m5.2xlarge | 3 | 42 | 45 | 58 | 13 pods (22%) |
| c6i.large | 3 | 18 | 21 | 29 | 8 pods (28%) |
| c6i.xlarge | 3 | 42 | 45 | 58 | 13 pods (22%) |
| c6i.2xlarge | 3 | 42 | 45 | 58 | 13 pods (22%) |

## Adding New Instance Types

To add support for additional instance types, update the case statement in `ec2nodeclass-production.yaml`:

```bash
your-instance-type)
    SYSTEM_PODS=X  # Number of system pods (typically 2-3)
    ENI_IPS=Y      # Available ENI IPs for the instance type
    MAX_PODS=$(( SYSTEM_PODS + ENI_IPS ))
    ;;
```

## Monitoring

Check calculation logs:
```bash
# Example log outpu
Mon Sep 22 15:30:00 UTC 2025: m5.large SystemPods:2 ENI_IPs:18 Final:20 Formula:conservative
```

## Troubleshooting

If pods fail to schedule due to resource constraints, verify:
1. Node has sufficient ENI IPs available
2. maxPods calculation is correct for the instance type
3. No other resource constraints (CPU, memory, etc.)
