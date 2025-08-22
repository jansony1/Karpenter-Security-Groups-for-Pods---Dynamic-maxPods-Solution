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

This project provides **dynamic maxPods calculation** for Karpenter-managed nodes, automatically adjusting pod capacity based on:

1. **Instance Type**: Different EC2 instance types have different ENI limits
2. **Security Groups for Pods Status**: Automatically detects if SG for Pods is enabled
3. **Reserved ENI Calculation**: Intelligently reserves ENIs for trunk interfaces
4. **Real-time Adjustment**: Calculates optimal maxPods value during node bootstrap

## ✨ Features

- 🧮 **Smart maxPods Calculation**: Based on instance type ENI limits and reserved trunk ENIs
- 🔒 **Security Groups for Pods Detection**: Automatic detection and optimization
- 📊 **Multi-Instance Support**: Supports 30+ instance types (T3, M5, C5, R5, M6i series)
- 📝 **Comprehensive Logging**: Detailed calculation and detection logs
- 🔄 **Background Verification**: Post-deployment configuration validation
- 🎯 **Production Ready**: Tested and validated in real environments

## 📋 Supported Instance Types

| Series | Instance Types | maxPods Range | Use Case |
|--------|----------------|---------------|----------|
| **T3** | micro → 2xlarge | 2-40 pods | Cost-optimized workloads |
| **M5** | large → 24xlarge | 20-629 pods | General purpose workloads |
| **C5** | large → 24xlarge | 20-629 pods | Compute-optimized workloads |
| **R5** | large → 24xlarge | 20-629 pods | Memory-optimized workloads |
| **M6i** | large → 24xlarge | 20-629 pods | Latest generation instances |

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
                       │   Instance       │    │   Calculated    │
                       │   Metadata       │───▶│   maxPods       │
                       │   (IMDSv2)       │    │   Value         │
                       └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   kubelet        │    │   Node Joins    │
                       │   Starts with    │───▶│   Cluster       │
                       │   maxPods        │    │                 │
                       └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Security Groups │    │   Validation    │
                       │  for Pods        │───▶│   & Logging     │
                       │  Detection       │    │   (Background)  │
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
git clone https://github.com/your-username/karpenter-sg-pods-maxpods.git
cd karpenter-sg-pods-maxpods

# Deploy using the automated script
./deploy.sh
```

### 2. Verify Deployment

```bash
# Check resources
kubectl get ec2nodeclass m5-dynamic-nodeclass-v2
kubectl get nodepool m5-dynamic-nodepool-v2

# Deploy test workload
kubectl apply -f test-pod.yaml
```

### 3. Monitor Results

```bash
# Watch node creation
kubectl get nodeclaims -w

# Check node maxPods configuration
kubectl describe node <node-name> | grep -E "(instance-type|pods)"
```

## 📁 Project Structure

```
├── README.md                    # This file
├── LICENSE                      # MIT License
├── CONTRIBUTING.md              # Contributing guidelines
├── CHANGELOG.md                 # Version history
├── ec2nodeclass.yaml           # Dynamic maxPods EC2NodeClass
├── nodepool.yaml               # Multi-instance NodePool
├── test-pod.yaml               # Single test pod
├── test-multi-instances.yaml   # Multi-instance test
├── trigger-c5-large-small.yaml # Force c5.large creation
├── trigger-c5-large.yaml       # Force c5.large creation (larger)
├── trigger-m5-xlarge.yaml      # Force m5.xlarge creation
├── deploy.sh                   # Deployment script
├── cleanup.sh                  # Cleanup script
├── validation-script.sh        # Validation script
└── VERSION                     # Version information
```

## 🔧 How It Works

### 1. Dynamic Calculation Algorithm

```bash
# Core calculation formula
adjusted_max_pods = default_max_pods - reserved_enis

# Safety minimum
if adjusted_max_pods < 10; then
    adjusted_max_pods = 10
fi
```

### 2. Instance Type Detection

The solution uses IMDSv2 to detect the instance type and applies the appropriate maxPods calculation:

```bash
# Example for m5.xlarge
default_max_pods=58    # AWS default for m5.xlarge
reserved_enis=18       # Reserved for trunk interfaces
calculated_max_pods=40 # Final result: 58-18=40
```

### 3. Execution Flow

1. **Node Bootstrap**: Karpenter creates node with EC2NodeClass userData
2. **Instance Detection**: Script uses IMDSv2 to get instance type
3. **maxPods Calculation**: Applies formula based on instance type
4. **kubelet Start**: Launches kubelet with calculated maxPods value
5. **Cluster Join**: Node joins the cluster with correct pod capacity
6. **Background Validation**: Asynchronously detects and logs SG for Pods status

### 4. Security Groups for Pods Detection (Post-Join Validation)

After the node joins the cluster, a background script validates the configuration:
- Checks aws-node DaemonSet environment variables
- Verifies amazon-vpc-cni ConfigMap settings
- Logs the detected configuration for troubleshooting
- **Note**: This is for validation/logging only, not for calculation adjustment

## 📊 Validation Results

### Real-world Test Results

| Instance Type | Default maxPods | Reserved ENI | Calculated maxPods | Status |
|---------------|-----------------|--------------|-------------------|---------|
| c5.large | 29 | 9 | 20 | ✅ Verified |
| m5.xlarge | 58 | 18 | 40 | ✅ Verified |
| t3.2xlarge | 58 | 18 | 40 | ✅ Verified |

### Log Examples

```
Instance Type: m5.xlarge, Calculated Max Pods: 40
Security Groups for Pods is DISABLED - using standard Max Pods calculation
Final Max Pods configuration: 40
```

## 🎯 Use Cases

### 1. Enable Security Groups for Pods
Perfect for clusters that need pod-level security group isolation:
```bash
kubectl apply -f ec2nodeclass.yaml
kubectl apply -f nodepool.yaml
```

### 2. Multi-Instance Type Workloads
Supports diverse workload requirements:
```bash
kubectl apply -f test-multi-instances.yaml
```

### 3. Specific Instance Type Targeting
Force specific instance types for specialized workloads:
```bash
kubectl apply -f trigger-c5-large-small.yaml  # For compute-optimized
kubectl apply -f trigger-m5-xlarge.yaml       # For general purpose
```

## 🔍 Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   - Check node maxPods capacity: `kubectl describe node <node-name>`
   - Verify calculation logs: Check `/var/log/karpenter-maxpods.log` on the node

2. **Incorrect maxPods calculation**
   - Ensure instance type is supported
   - Check IMDSv2 access and metadata retrieval

3. **Security Groups for Pods detection issues**
   - Verify cluster configuration
   - Check detection logs: `/var/log/sg-pods-check.log`

### Debug Commands

```bash
# Check node capacity
kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE:.metadata.labels.node\\.kubernetes\\.io/instance-type,PODS:.status.capacity.pods

# Access node logs via SSM
aws ssm send-command \
  --instance-ids <instance-id> \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cat /var/log/karpenter-maxpods.log"]' \
  --region us-west-2
```

## 🧪 Testing

### Run Validation Script

```bash
# Comprehensive validation
./validation-script.sh
```

### Manual Testing

```bash
# Test different instance types
kubectl apply -f test-multi-instances.yaml

# Force specific instance creation
kubectl apply -f trigger-c5-large-small.yaml
kubectl apply -f trigger-m5-xlarge.yaml

# Monitor results
kubectl get nodeclaims -w
kubectl get nodes -o wide
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Karpenter](https://karpenter.sh/) team for the excellent node provisioning solution
- AWS EKS team for Security Groups for Pods feature
- Community contributors and testers

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/your-username/karpenter-sg-pods-maxpods/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/your-username/karpenter-sg-pods-maxpods/discussions)
- 📖 **Documentation**: Check the detailed sections below

---

## 📚 Detailed Documentation

### Supported Instance Types and Calculations

#### T3 Series
| Instance Type | Default maxPods | Reserved ENI | Calculated maxPods | CPU | Memory |
|---------------|-----------------|--------------|-------------------|-----|--------|
| t3.micro | 4 | 2 | 2 | 2 vCPU | 1GB |
| t3.small | 11 | 4 | 7 | 2 vCPU | 2GB |
| t3.medium | 17 | 6 | 11 | 2 vCPU | 4GB |
| t3.large | 35 | 12 | 23 | 2 vCPU | 8GB |
| t3.xlarge | 58 | 18 | 40 | 4 vCPU | 16GB |
| t3.2xlarge | 58 | 18 | 40 | 8 vCPU | 32GB |

#### M5 Series
| Instance Type | Default maxPods | Reserved ENI | Calculated maxPods | CPU | Memory |
|---------------|-----------------|--------------|-------------------|-----|--------|
| m5.large | 29 | 9 | 20 | 2 vCPU | 8GB |
| m5.xlarge | 58 | 18 | 40 | 4 vCPU | 16GB |
| m5.2xlarge | 58 | 18 | 40 | 8 vCPU | 32GB |
| m5.4xlarge | 234 | 54 | 180 | 16 vCPU | 64GB |
| m5.8xlarge | 234 | 54 | 180 | 32 vCPU | 128GB |
| m5.12xlarge | 234 | 54 | 180 | 48 vCPU | 192GB |
| m5.16xlarge | 737 | 108 | 629 | 64 vCPU | 256GB |
| m5.24xlarge | 737 | 108 | 629 | 96 vCPU | 384GB |

#### C5 Series (Compute Optimized)
| Instance Type | Default maxPods | Reserved ENI | Calculated maxPods | CPU | Memory |
|---------------|-----------------|--------------|-------------------|-----|--------|
| c5.large | 29 | 9 | 20 | 2 vCPU | 4GB |
| c5.xlarge | 58 | 18 | 40 | 4 vCPU | 8GB |
| c5.2xlarge | 58 | 18 | 40 | 8 vCPU | 16GB |
| c5.4xlarge | 234 | 54 | 180 | 16 vCPU | 32GB |
| c5.9xlarge | 234 | 54 | 180 | 36 vCPU | 72GB |
| c5.12xlarge | 234 | 54 | 180 | 48 vCPU | 96GB |
| c5.18xlarge | 737 | 108 | 629 | 72 vCPU | 144GB |
| c5.24xlarge | 737 | 108 | 629 | 96 vCPU | 192GB |

#### R5 Series (Memory Optimized)
| Instance Type | Default maxPods | Reserved ENI | Calculated maxPods | CPU | Memory |
|---------------|-----------------|--------------|-------------------|-----|--------|
| r5.large | 29 | 9 | 20 | 2 vCPU | 16GB |
| r5.xlarge | 58 | 18 | 40 | 4 vCPU | 32GB |
| r5.2xlarge | 58 | 18 | 40 | 8 vCPU | 64GB |
| r5.4xlarge | 234 | 54 | 180 | 16 vCPU | 128GB |
| r5.8xlarge | 234 | 54 | 180 | 32 vCPU | 256GB |
| r5.12xlarge | 234 | 54 | 180 | 48 vCPU | 384GB |
| r5.16xlarge | 737 | 108 | 629 | 64 vCPU | 512GB |
| r5.24xlarge | 737 | 108 | 629 | 96 vCPU | 768GB |

#### M6i Series (Latest Generation)
| Instance Type | Default maxPods | Reserved ENI | Calculated maxPods | CPU | Memory |
|---------------|-----------------|--------------|-------------------|-----|--------|
| m6i.large | 29 | 9 | 20 | 2 vCPU | 8GB |
| m6i.xlarge | 58 | 18 | 40 | 4 vCPU | 16GB |
| m6i.2xlarge | 58 | 18 | 40 | 8 vCPU | 32GB |
| m6i.4xlarge | 234 | 54 | 180 | 16 vCPU | 64GB |
| m6i.8xlarge | 234 | 54 | 180 | 32 vCPU | 128GB |
| m6i.12xlarge | 234 | 54 | 180 | 48 vCPU | 192GB |
| m6i.16xlarge | 737 | 108 | 629 | 64 vCPU | 256GB |
| m6i.24xlarge | 737 | 108 | 629 | 96 vCPU | 384GB |

### Configuration Details

#### Important Notes

1. **Cluster Name**: Update the cluster name in `ec2nodeclass.yaml` from `nlb-test-cluster` to your actual cluster name
2. **Region**: Ensure the region in scripts matches your cluster region
3. **Security Groups for Pods**: The solution automatically detects if SG for Pods is enabled
4. **Instance Availability**: Ensure the instance types are available in your target region

#### Customization

To add support for new instance types, update the `calculate_max_pods` function in `ec2nodeclass.yaml`:

```bash
# Add new instance type
"m7i.large")    default_max_pods=29;  reserved_enis=9 ;;
```

And add the instance type to the NodePool's instance type list in `nodepool.yaml`.

---

**⭐ If this project helps you, please give it a star!**
