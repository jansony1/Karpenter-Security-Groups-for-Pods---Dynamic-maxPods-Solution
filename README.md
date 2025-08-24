# Karpenter Security Groups for Pods - Dynamic maxPods Solution

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30+-blue.svg)](https://kubernetes.io/)
[![Karpenter](https://img.shields.io/badge/Karpenter-v1.x-green.svg)](https://karpenter.sh/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange.svg)](https://aws.amazon.com/eks/)

## 🎯 Problem Statement

When **Security Groups for Pods** is enabled in Amazon EKS, it introduces **trunk ENIs** (`vpc.amazonaws.com/pod-eni`) which significantly reduces the number of available IP addresses for regular pods. The default `maxPods` configuration on EC2 instances becomes insufficient, causing pod scheduling failures.

### The Challenge

- **Before SG for Pods**: Instance uses all ENIs for pod networking
- **After SG for Pods**: Some ENIs are reserved as trunk interfaces, reducing available pod capacity
- **Result**: Pods fail to schedule due to insufficient pod capacity, even when CPU/memory resources are available

## 🚀 Solution

This project provides **fully dynamic maxPods calculation** for Karpenter-managed nodes, automatically adapting to ANY EC2 instance type by:

1. **Real-time ENI Limit Detection**: Queries AWS VPC Resource Controller for actual instance limits
2. **Trunk ENI Compatibility Check**: Automatically detects if instance supports Security Groups for Pods
3. **Dynamic Calculation**: Applies appropriate maxPods formula based on instance capabilities
4. **Fallback Support**: Handles unknown instance types with conservative defaults

## ✨ Features

- 🌐 **Universal Instance Support**: Works with ANY EC2 instance type automatically
- 🔍 **Real-time Limit Detection**: Queries live AWS data for ENI limits
- 🧮 **Smart maxPods Calculation**: Dynamic formula based on actual instance capabilities
- 🔒 **Trunk ENI Auto-Detection**: Automatic Security Groups for Pods compatibility check
- 📝 **Comprehensive Logging**: Detailed calculation and detection logs
- 🎯 **Production Ready**: Tested and validated in real environments
- 🔄 **Self-Updating**: Automatically adapts to new instance types as AWS releases them

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Karpenter     │    │  EC2NodeClass    │    │   Node Bootstrap│
│   NodePool      │───▶│  with Dynamic    │───▶│   Script        │
│                 │    │  maxPods Calc    │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Instance       │    │   AWS VPC       │
                       │   Metadata       │───▶│   Resource      │
                       │   (IMDSv2)       │    │   Controller    │
                       └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Dynamic ENI     │    │  Trunk ENI      │
                       │  Limit Query     │───▶│  Compatibility  │
                       │                  │    │  Detection      │
                       └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Calculated     │    │   kubelet       │
                       │   maxPods        │───▶│   Starts with   │
                       │   Value          │    │   maxPods       │
                       └──────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Amazon EKS cluster with Karpenter installed
- AWS CLI configured with appropriate permissions
- kubectl configured to access your cluster

### 1. Deploy the Solution

```bash
# Clone the repository
git clone https://github.com/jansony1/Karpenter-Security-Groups-for-Pods---Dynamic-maxPods-Solution.git
cd Karpenter-Security-Groups-for-Pods---Dynamic-maxPods-Solution

# Update cluster name in ec2nodeclass.yaml
sed -i 's/nlb-test-cluster/YOUR_CLUSTER_NAME/g' ec2nodeclass.yaml

# Deploy using the automated script
./deploy.sh
```

### 2. Verify Deployment

```bash
# Check resources
kubectl get ec2nodeclass m5-dynamic-nodeclass-v2
kubectl get nodepool m5-dynamic-nodepool-v2

# Deploy test workload
kubectl apply -f test/test-pod.yaml
```

### 3. Monitor Results

```bash
# Watch node creation
kubectl get nodeclaims -w

# Check node maxPods configuration
kubectl describe node <node-name> | grep -E "(instance-type|pods)"
```

## 🔧 How It Works

### 1. Dynamic Detection Algorithm

```bash
# Real-time ENI limit detection
curl -s "https://raw.githubusercontent.com/aws/amazon-vpc-resource-controller-k8s/main/pkg/aws/vpc/limits.go"

# Extract instance-specific limits
interface_count=$(extract_from_limits "Interface:")
ipv4_per_interface=$(extract_from_limits "IPv4PerInterface:")
branch_interface=$(extract_from_limits "BranchInterface:")
is_trunk_compatible=$(extract_from_limits "IsTrunkingCompatible:")
```

### 2. Universal Calculation Logic

```bash
# Dynamic maxPods calculation
default_max_pods = (interface_count × ipv4_per_interface) - 1

if (is_trunk_compatible && branch_interface > 0); then
    adjusted_max_pods = default_max_pods - branch_interface
else
    adjusted_max_pods = default_max_pods  # No ENI reservation needed
fi

# Safety minimum
if adjusted_max_pods < 10; then
    adjusted_max_pods = 10
fi
```

### 3. Execution Flow

1. **Node Bootstrap**: Karpenter creates node with dynamic EC2NodeClass
2. **Instance Detection**: Script uses IMDSv2 to get instance type
3. **Live ENI Query**: Downloads latest AWS VPC Resource Controller limits
4. **Compatibility Check**: Determines trunk ENI support automatically
5. **Dynamic Calculation**: Applies appropriate maxPods formula
6. **kubelet Start**: Launches kubelet with calculated maxPods value
7. **Cluster Join**: Node joins cluster with optimal pod capacity

## 📊 Universal Instance Support

### ✅ Automatically Supported Instance Families

The solution **automatically supports ALL EC2 instance types** by querying live AWS data:

| Family | Examples | Auto-Detection | Trunk ENI Support |
|--------|----------|----------------|-------------------|
| **T-Series** | t3.micro, t4g.small | ✅ Auto | ❌ No (full maxPods) |
| **M-Series** | m5.large, m6i.xlarge, m7i.2xlarge | ✅ Auto | ✅ Yes (ENI reserved) |
| **C-Series** | c5.large, c6i.xlarge, c7i.4xlarge | ✅ Auto | ✅ Yes (ENI reserved) |
| **R-Series** | r5.large, r6i.xlarge, r7i.8xlarge | ✅ Auto | ✅ Yes (ENI reserved) |
| **I-Series** | i3.large, i4i.xlarge | ✅ Auto | ✅ Yes (ENI reserved) |
| **X-Series** | x2iezn.large, x2gd.medium | ✅ Auto | ✅ Yes (ENI reserved) |
| **Future Types** | Any new AWS instance type | ✅ Auto | ✅ Auto-detected |

### 🔄 Self-Updating Capability

- **No Manual Updates Required**: Automatically adapts to new instance types
- **Live AWS Data**: Queries official AWS VPC Resource Controller limits
- **Future-Proof**: Works with instance types that don't exist yet
- **Fallback Support**: Conservative defaults for unknown types

## 🧪 Testing

### Run Validation Script

```bash
# Comprehensive validation
./validation-script.sh
```

### Test Different Instance Types

```bash
# The solution automatically works with ANY instance type
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-any-instance
spec:
  nodeSelector:
    node-type: m5-dynamic-v2
  containers:
  - name: test
    image: nginx:alpine
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
