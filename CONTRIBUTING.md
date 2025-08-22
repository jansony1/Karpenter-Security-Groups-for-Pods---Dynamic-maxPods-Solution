# Contributing to Karpenter Security Groups for Pods - Dynamic maxPods Solution

Thank you for your interest in contributing! We welcome contributions from the community.

## 🤝 How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use the issue template** when creating new issues
3. **Provide detailed information**:
   - EKS cluster version
   - Karpenter version
   - Instance types affected
   - Error messages and logs
   - Steps to reproduce

### Code Contributions

#### Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl configured to access an EKS cluster
- Basic understanding of Karpenter and Kubernetes
- Familiarity with AWS EC2 instance types and ENI limits

#### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes**
4. **Test thoroughly** using the validation script
5. **Commit and push**: `git commit -m "feat: description" && git push`
6. **Create a Pull Request**

## 🔧 Adding New Instance Types (Detailed Guide)

### Research Phase

#### 1. Check AWS VPC Resource Controller

**Primary Source**: https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/main/pkg/aws/vpc/limits.go

Look for your instance type entry:
```go
"m7i.large": {
    Interface:               3,           // Number of ENIs
    IPv4PerInterface:        10,          // IPs per ENI
    IsTrunkingCompatible:    true,        // Security Groups for Pods support
    BranchInterface:         9,           // Available branch interfaces
    DefaultNetworkCardIndex: 0,
    NetworkCards: []NetworkCard{
        {
            MaximumNetworkInterfaces: 3,
            MaximumPrivateIpv4AddressesPerInterface: 10,
        },
    },
    IsBareMetal: false,
},
```

#### 2. Cross-Reference with AWS Documentation

**Instance Types**: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
**ENI Limits**: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI

#### 3. Calculate Values

**Default maxPods Formula:**
```bash
# Standard AWS calculation
default_max_pods = (ENIs × IPv4PerInterface) - 1

# Examples:
# m7i.large: (3 × 10) - 1 = 29
# c6i.2xlarge: (4 × 15) - 1 = 59
```

**Reserved ENI Calculation:**
```bash
# Method 1: Use BranchInterface value from limits.go (preferred)
reserved_enis = BranchInterface

# Method 2: Conservative estimation (if BranchInterface not available)
reserved_enis = total_ips × 0.3  # Reserve ~30% for trunk interfaces

# Method 3: Pattern matching with similar instance types
# Look at existing instances with similar ENI/IP configuration
```

### Implementation Phase

#### 1. Update Trunk ENI Compatibility Check

In `ec2nodeclass.yaml`, update the `is_trunk_eni_compatible()` function:

```bash
# Add new instance family
case $instance_type in
    # M7i series - supports trunk ENI (example)
    "m7i.large"|"m7i.xlarge"|"m7i.2xlarge"|"m7i.4xlarge"|"m7i.8xlarge"|"m7i.12xlarge"|"m7i.16xlarge"|"m7i.24xlarge")
        echo "true" ;;
    # C7i series - supports trunk ENI (example)  
    "c7i.large"|"c7i.xlarge"|"c7i.2xlarge"|"c7i.4xlarge"|"c7i.8xlarge"|"c7i.12xlarge"|"c7i.16xlarge"|"c7i.24xlarge")
        echo "true" ;;
    # T4g series - does NOT support trunk ENI (example)
    "t4g.nano"|"t4g.micro"|"t4g.small"|"t4g.medium"|"t4g.large"|"t4g.xlarge"|"t4g.2xlarge")
        echo "false" ;;
    # ... existing cases
esac
```

#### 2. Add Default maxPods Values

In the `calculate_max_pods()` function:

```bash
case $instance_type in
    # M7i series (example - research actual values)
    "m7i.large")    default_max_pods=29 ;;
    "m7i.xlarge")   default_max_pods=58 ;;
    "m7i.2xlarge")  default_max_pods=58 ;;
    "m7i.4xlarge")  default_max_pods=234 ;;
    "m7i.8xlarge")  default_max_pods=234 ;;
    "m7i.12xlarge") default_max_pods=234 ;;
    "m7i.16xlarge") default_max_pods=737 ;;
    "m7i.24xlarge") default_max_pods=737 ;;
    # ... existing cases
esac
```

#### 3. Add Reserved ENI Values

For trunk ENI compatible instances:

```bash
case $instance_type in
    # M7i series reserved ENIs (example - research actual values)
    "m7i.large")    reserved_enis=9 ;;
    "m7i.xlarge")   reserved_enis=18 ;;
    "m7i.2xlarge")  reserved_enis=18 ;;
    "m7i.4xlarge")  reserved_enis=54 ;;
    "m7i.8xlarge")  reserved_enis=54 ;;
    "m7i.12xlarge") reserved_enis=54 ;;
    "m7i.16xlarge") reserved_enis=108 ;;
    "m7i.24xlarge") reserved_enis=108 ;;
    # ... existing cases
esac
```

#### 4. Update NodePool Configuration

In `nodepool.yaml`, add new instance types to the requirements:

```yaml
spec:
  requirements:
    - key: node.kubernetes.io/instance-type
      operator: In
      values:
        # Add new instance types
        - m7i.large
        - m7i.xlarge
        - m7i.2xlarge
        - m7i.4xlarge
        # ... existing types
```

### Testing Phase

#### 1. Validation Checklist

- [ ] **Syntax Check**: Validate YAML files with `kubectl --dry-run=client`
- [ ] **Deploy Test**: Deploy in non-production environment
- [ ] **Instance Creation**: Verify Karpenter creates the new instance type
- [ ] **maxPods Verification**: Check actual maxPods matches calculation
- [ ] **Log Verification**: Confirm logs show correct trunk ENI detection
- [ ] **Pod Scheduling**: Test pod scheduling works correctly

#### 2. Testing Commands

```bash
# Deploy test configuration
kubectl apply -f ec2nodeclass.yaml
kubectl apply -f nodepool.yaml

# Create test pod to trigger instance creation
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-new-instance-type
spec:
  nodeSelector:
    node-type: m5-dynamic-v2
  containers:
  - name: test
    image: nginx:alpine
    resources:
      requests:
        cpu: 2000m    # Adjust to target your new instance type
        memory: 4Gi
EOF

# Monitor instance creation
kubectl get nodeclaims -w

# Verify maxPods configuration
kubectl describe node <node-name> | grep -E "(instance-type|pods)"

# Check calculation logs
INSTANCE_ID=$(kubectl get node <node-name> -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cat /var/log/karpenter-maxpods.log"]' \
  --region us-west-2
```

### Documentation Phase

#### 1. Update README.md

Add your new instance types to the supported instance types table:

```markdown
### ✅ M7i Series (Trunk ENI Compatible - SG for Pods Supported)
| Instance Type | Default maxPods | ENI Reservation | Final maxPods | CPU | Memory |
|---------------|-----------------|-----------------|---------------|-----|--------|
| m7i.large | 29 | 9 | 20 | 2 vCPU | 8GB |
| m7i.xlarge | 58 | 18 | 40 | 4 vCPU | 16GB |
| ... | ... | ... | ... | ... | ... |
```

#### 2. Update Test Configurations

Create test configurations for new instance types:

```yaml
# trigger-m7i-large.yaml
apiVersion: v1
kind: Pod
metadata:
  name: trigger-m7i-large
spec:
  nodeSelector:
    node-type: m5-dynamic-v2
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: node.kubernetes.io/instance-type
            operator: In
            values: ["m7i.large"]
  containers:
  - name: workload
    image: nginx:alpine
    resources:
      requests:
        cpu: 1500m
        memory: 6Gi
```

### Common Instance Families to Research

#### Likely Trunk ENI Compatible
- **M7i/M7a**: Latest generation general purpose
- **C7i/C7a**: Latest generation compute optimized  
- **R7i/R7a**: Latest generation memory optimized
- **M6a/M6id**: Previous generation variants
- **C6a/C6id**: Previous generation variants
- **R6a/R6id**: Previous generation variants

#### Likely NOT Trunk ENI Compatible
- **T4g**: Graviton-based burstable (check limits.go)
- **A1**: ARM-based instances
- **Older generations**: m4, c4, r4, etc.

### Research Resources

#### Primary Sources
1. **AWS VPC Resource Controller**: https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/main/pkg/aws/vpc/limits.go
2. **AWS EC2 Documentation**: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
3. **EKS Security Groups for Pods**: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html

#### Secondary Sources
1. **Karpenter Documentation**: https://karpenter.sh/docs/
2. **AWS CNI Plugin**: https://github.com/aws/amazon-vpc-cni-k8s
3. **EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/

#### Community Resources
1. **AWS re:Post**: https://repost.aws/
2. **Kubernetes Slack**: #karpenter, #aws-eks channels
3. **AWS Community Forums**: https://forums.aws.amazon.com/

### Pull Request Guidelines

When submitting a PR for new instance types:

#### 1. PR Title Format
```
feat: add support for M7i instance series

- Add M7i.large through M7i.24xlarge support
- Include trunk ENI compatibility detection
- Update documentation and test configurations
```

#### 2. Required Information
- [ ] **Research source**: Link to limits.go commit or AWS documentation
- [ ] **Calculation details**: Show how maxPods and reserved ENI values were determined
- [ ] **Test results**: Include validation output from real deployment
- [ ] **Documentation updates**: README tables and examples updated

#### 3. Testing Evidence
Include in PR description:
```bash
# Test results for m7i.large
kubectl describe node ip-xxx | grep pods
# Capacity: pods: 20
# Allocatable: pods: 20

# Log verification
cat /var/log/karpenter-maxpods.log
# Instance Type: m7i.large, Calculated Max Pods: 20
# Trunk ENI Compatible: true
```

## 📋 Pull Request Process

1. **Ensure your PR**:
   - Has a clear title and description
   - References related issues
   - Includes tests for new features
   - Updates documentation as needed

2. **PR Requirements**:
   - All validation scripts pass
   - No merge conflicts
   - Documentation updated
   - YAML files are valid

## 🏷️ Commit Message Guidelines

Use conventional commit format:

- `feat:` New features (new instance types)
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or modifications

Examples:
```
feat: add support for M7i instance series
fix: correct maxPods calculation for c6i.large
docs: update README with C7i instance types
```

## 🔒 Security

If you discover a security vulnerability, please email the maintainers directly rather than creating a public issue.

## 🙏 Recognition

Contributors will be recognized in the README and release notes.

Thank you for helping make this project better! 🚀
