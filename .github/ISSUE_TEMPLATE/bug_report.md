---
name: Bug repor
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**Environment**
- EKS Version: [e.g. 1.30]
- Karpenter Version: [e.g. v1.0.0]
- Instance Type: [e.g. m5.xlarge]
- Security Groups for Pods: [Enabled/Disabled]
- AWS Region: [e.g. us-west-2]

**Steps to Reproduce**
1. Deploy configuration '...'
2. Apply workload '...'
3. Observe error '...'

**Expected Behavior**
A clear description of what you expected to happen.

**Actual Behavior**
A clear description of what actually happened.

**Logs**
Please include relevant logs:

```
# Karpenter maxPods calculation logs
/var/log/karpenter-maxpods.log

# Security Groups for Pods detection logs
/var/log/sg-pods-check.log

# Karpenter controller logs
kubectl logs -n karpenter deployment/karpenter
```

**Node Information**
```bash
# Output of kubectl describe node <node-name>
kubectl describe node <node-name> | grep -E "(instance-type|pods|Capacity|Allocatable)"
```

**Additional context**
Add any other context about the problem here.
