# Supported Instance Types and Configuration

## Currently Supported Instance Types

Based on `ec2nodeclass-production.yaml` and `nodepool-production.yaml`, the following instance types are currently supported:

### Production-Ready Instance Types

| Instance Type | ENI IPs | System Pods | Recommended maxPods | Calculation |
|---------------|---------|-------------|-------------------|-------------|
| **m5.large** | 18 | 3 | 21 | 3 + 18 |
| **m5.xlarge** | 42 | 3 | 45 | 3 + 42 |
| **m5.2xlarge** | 42 | 3 | 45 | 3 + 42 |
| **c6i.large** | 18 | 3 | 21 | 3 + 18 |
| **c6i.xlarge** | 42 | 3 | 45 | 3 + 42 |
| **c6i.2xlarge** | 42 | 3 | 45 | 3 + 42 |

### Additional Configured Sizes

The configuration also includes patterns for larger instance types:

| Instance Pattern | ENI IPs | Recommended maxPods | Calculation |
|-----------------|---------|-------------------|-------------|
| ***.4xlarge** | 203 | 206 | 3 + 203 |

## ENI IP Calculation Method

To calculate ENI IPs for any instance type, use the following formula:

```
ENI_IPS = (Max_ENIs - 1) × (Secondary_IPs_per_ENI - 1)
```

### Explanation
- **Max_ENIs**: Maximum number of ENIs the instance type supports
- **Secondary_IPs_per_ENI**: Maximum secondary IP addresses per ENI
- **-1 for ENIs**: Primary ENI is reserved for system use
- **-1 for IPs**: Primary IP on each ENI is reserved

### Example Calculations

#### m5.large
- Max ENIs: 3
- Secondary IPs per ENI: 10
- ENI_IPS = (3-1) × (10-1) = 2 × 9 = **18**

#### m5.xlarge
- Max ENIs: 4  
- Secondary IPs per ENI: 15
- ENI_IPS = (4-1) × (15-1) = 3 × 14 = **42**

#### c5.4xlarge
- Max ENIs: 8
- Secondary IPs per ENI: 30
- ENI_IPS = (8-1) × (30-1) = 7 × 29 = **203**

## Adding New Instance Types

### Step 1: Update EC2NodeClass Configuration

Edit `ec2nodeclass-production.yaml` and add your instance type to the case statement:

```bash
case "$INSTANCE_TYPE" in
    # Existing configurations...
    
    # Add new instance type
    *.8xlarge)
        ENI_IPS=234  # Calculate using formula above
        MAX_PODS=$(( SYSTEM_PODS + ENI_IPS ))
        ;;
    
    # Specific instance type (if different from pattern)
    r5.metal)
        ENI_IPS=737  # Calculate using formula above
        MAX_PODS=$(( SYSTEM_PODS + ENI_IPS ))
        ;;
        
    # Keep the default error case
    *)
        echo "Error: Unsupported instance type $INSTANCE_TYPE"
        exit 1
    ;;
esac
```

### Step 2: Update NodePool Configuration

Edit `nodepool-production.yaml` to include the new instance types:

```yaml
- key: node.kubernetes.io/instance-type
  operator: In
  values: [
    "m5.large", "m5.xlarge", "m5.2xlarge", 
    "c6i.large", "c6i.xlarge", "c6i.2xlarge",
    "r5.8xlarge",  # Add new instance type
    "r5.metal"     # Add specific instance type
  ]
```

### Step 3: Verify ENI Information

Before adding any instance type, verify the ENI specifications from AWS documentation:

1. Check [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/) documentation
2. Look for "Network Performance" specifications
3. Confirm maximum ENIs and IPs per ENI
4. Calculate using the formula: `(Max_ENIs - 1) × (Secondary_IPs_per_ENI - 1)`

### Step 4: Test Configuration

1. Deploy the updated configuration to a test environment
2. Verify the calculated maxPods value in node logs:
   ```bash
   kubectl debug node/NODE_NAME -it --image=busybox -- cat /host/var/log/mixed-deployment-calc.log
   ```
3. Confirm the node shows correct allocatable pods:
   ```bash
   kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE:.metadata.labels.node\\.kubernetes\\.io/instance-type,MAXPODS:.status.allocatable.pods
   ```

## Instance Type Families

### Supported Families
- **M5 Series**: General purpose (m5.large, m5.xlarge, m5.2xlarge)
- **C6i Series**: Compute optimized (c6i.large, c6i.xlarge, c6i.2xlarge)

### Easily Extensible Families
- **M5 Series**: m5.4xlarge, m5.8xlarge, m5.12xlarge, etc.
- **C5/C6i Series**: c5.4xlarge, c6i.4xlarge, etc.
- **R5 Series**: r5.large, r5.xlarge, r5.2xlarge, etc.
- **I3 Series**: i3.large, i3.xlarge, i3.2xlarge, etc.

### Notes
- All instance types must support **Trunk ENI** for Security Groups for Pods
- Verify instance type availability in your target AWS regions
- Consider cost implications when adding larger instance types
- Test thoroughly before deploying to production environments
