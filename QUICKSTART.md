# Quick Start Guide

Get up and running with dynamic maxPods calculation in 5 minutes!

## 🚀 Prerequisites

- ✅ Amazon EKS cluster (v1.30+)
- ✅ Karpenter installed and configured
- ✅ AWS CLI configured with appropriate permissions
- ✅ kubectl configured to access your cluster

## ⚡ 5-Minute Setup

### Step 1: Clone and Navigate
```bash
git clone https://github.com/your-username/karpenter-sg-pods-maxpods.git
cd karpenter-sg-pods-maxpods
```

### Step 2: Update Cluster Name
```bash
# Update cluster name in ec2nodeclass.yaml
sed -i 's/nlb-test-cluster/YOUR_CLUSTER_NAME/g' ec2nodeclass.yaml
```

### Step 3: Deploy
```bash
./deploy.sh
```

### Step 4: Verify
```bash
# Check resources
kubectl get ec2nodeclass m5-dynamic-nodeclass-v2
kubectl get nodepool m5-dynamic-nodepool-v2
```

### Step 5: Test
```bash
# Deploy test pod
kubectl apply -f test/test-pod.yaml

# Watch node creation
kubectl get nodeclaims -w
```

## 🎯 Expected Results

```bash
# Example output
NAME                                           INSTANCE    PODS
ip-192-168-53-39.us-west-2.compute.internal   c5.large    20
ip-192-168-101-199.us-west-2.compute.internal m5.xlarge   40
```

## 🔍 Validation

```bash
# Run validation script
./validation-script.sh

# Check logs
INSTANCE_ID=$(kubectl get node <node-name> -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cat /var/log/karpenter-maxpods.log"]' \
  --region us-west-2
```

## 🧪 Test Different Instance Types

```bash
# Force c5.large
kubectl apply -f trigger-c5-large-small.yaml

# Force m5.xlarge  
kubectl apply -f trigger-m5-xlarge.yaml

# Multiple instances
kubectl apply -f test-multi-instances.yaml
```

## 🧹 Cleanup

```bash
./cleanup.sh
```

## 🆘 Troubleshooting

**Pods stuck in Pending:**
```bash
kubectl describe node <node-name> | grep -E "(pods|Capacity)"
kubectl describe pod <pod-name>
```

**Incorrect maxPods:**
```bash
aws ssm send-command --instance-ids <id> --document-name "AWS-RunShellScript" --parameters 'commands=["cat /var/log/karpenter-maxpods.log"]' --region us-west-2
```

---

**⏱️ Total time: ~5 minutes**
