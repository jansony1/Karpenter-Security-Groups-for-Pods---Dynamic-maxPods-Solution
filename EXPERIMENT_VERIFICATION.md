# Mixed Deployment Experiment & Verification Results

## Test Environmen
- **EKS Version**: 1.32
- **Karpenter Version**: 1.6.3
- **Region**: us-west-2

## Problem Statemen
Fix the mismatch between **ENI/IP resources** and **`maxPods` setting** when deploying mixed **Security Groups for Pods (SGP)** and **non-SG Pods** on Karpenter nodes.

## Resource Constraints
- **Non-SG Pods**: Limited by ENI IP capacity
- **SG Pods**: Limited by `pod-ENI` quota, consume maxPods slots but no ENI IPs
- **Both**: Constrained by single `maxPods` value

## Instance Type Parameters

| Instance Type | Default maxPods | pod-ENI Limit | Available ENI IPs | System Pods | Verification Status |
|---------------|-----------------|---------------|-----------------|-------------|-------------------|
| **m5.large** | 29 | 9 | 18 | 2 | ✅ Verified |
| **m5.xlarge** | 58 | 18 | 42 | 3 | ✅ Verified |
| **m5.2xlarge** | 58 | 38 | 42 | 3 | ✅ Verified |
| **c6i.large** | 29 | 9 | 18 | 3 | ✅ Verified |
| **c6i.xlarge** | 58 | 18 | 42 | 3 | ✅ Verified |
| **c6i.2xlarge** | 58 | 38 | 42 | 3 | ✅ Verified |

## Deployment Order Impac

### Non-SG Pods Firs
- **Issue**: ENI IPs exhausted before reaching maxPods
- **Result**: IP allocation failures
- **Example (m5.large)**: 2 system + 18 non-SG = 20 < maxPods(29) → scheduler continues → IP errors

### SG Pods Firs
- **Issue**: maxPods reached while ENI IPs remain unused
- **Result**: ENI IP waste
- **Example (m5.2xlarge)**: 38 SG + 3 system = 41, remaining 17 slots vs 42 available ENI IPs

## Production Solution

### Conservative Formula
```
maxPods = system_pods + available_ENI_IPs
```

### Recommended Values

| Instance Type | Default maxPods | Recommended maxPods | Calculation |
|---------------|-----------------|-------------------|-------------|
| **m5.large** | 29 | 20 | 2 system + 18 ENI IPs |
| **m5.xlarge** | 58 | 45 | 3 system + 42 ENI IPs |
| **m5.2xlarge** | 58 | 45 | 3 system + 42 ENI IPs |
| **c6i.large** | 29 | 21 | 3 system + 18 ENI IPs |
| **c6i.xlarge** | 58 | 45 | 3 system + 42 ENI IPs |
| **c6i.2xlarge** | 58 | 45 | 3 system + 42 ENI IPs |

## Deployment Scenarios Tested

| Scenario | Deployment Pattern | Result |
|----------|-------------------|--------|
| **SG First** | All SG pods → All non-SG pods | ✅ Works optimally |
| **Non-SG First** | All non-SG pods → All SG pods | ✅ Prevents IP exhaustion |
| **Alternating Mixed** | SG pod → non-SG pod → SG pod... | ✅ Scheduler handles limits |

## Resource Potential Waste Analysis

| Instance Type | Default maxPods | Recommended maxPods | pod-ENI Limit | Available ENI IPs | System Pods | MaxPods Potential Waste | ENI IP Potential Waste |
|---------------|-----------------|-------------------|---------------|-----------------|-------------|------------------------|----------------------|
| **m5.large** | 29 | 20 | 9 | 18 | 2 | 9 pods | 9 IPs |
| **m5.xlarge** | 58 | 45 | 18 | 42 | 3 | 13 pods | 24 IPs |
| **m5.2xlarge** | 58 | 45 | 38 | 42 | 3 | 13 pods | 38 IPs |
| **c6i.large** | 29 | 21 | 9 | 18 | 3 | 8 pods | 9 IPs |
| **c6i.xlarge** | 58 | 45 | 18 | 42 | 3 | 13 pods | 24 IPs |
| **c6i.2xlarge** | 58 | 45 | 38 | 42 | 3 | 13 pods | 38 IPs |

### Waste Calculation Logic

#### MaxPods Potential Waste
- **Formula**: `Default maxPods - Recommended maxPods`
- **Meaning**: Pod capacity reduction due to conservative strategy

#### ENI IP Potential Waste (SG-pods-first worst case)
- **Formula**: `Available ENI IPs - Usable ENI IPs`
- **Calculation**:
  1. SG pods consume maxPods slots but no ENI IPs
  2. Remaining slots: `Recommended maxPods - pod-ENI Limit - System Pods`
  3. ENI IP Potential Waste = `Available ENI IPs - Remaining slots`

#### Example: m5.2xlarge
- SG pods first: 38 pods (38 maxPods slots, 0 ENI IPs)
- System pods: 3 (hostNetwork)
- Remaining slots: 45 - 38 - 3 = **4 slots**
- Available ENI IPs: 42
- **ENI IP Potential Waste: 42 - 4 = 38 IPs**

## Derived Alternative Approach

Based on the experiment results showing ENI IP waste in SG-first scenarios, an alternative aggressive approach can be derived:

### Aggressive Formula (Alternative)
```
maxPods = default_maxPods + ENI_waste_observed
```

### Alternative Values

| Instance Type | Conservative (Recommended) | Aggressive (Alternative) | ENI Waste Eliminated |
|---------------|---------------------------|------------------------|-------------------|
| **m5.large** | 20 | 29 (keep default) | 0 (already optimal) |
| **m5.xlarge** | 45 | 63 (58 + 5) | 5 ENI IPs |
| **m5.2xlarge** | 45 | 83 (58 + 25) | 25 ENI IPs |
| **c6i.large** | 21 | 30 (29 + 1) | 1 ENI IP |
| **c6i.xlarge** | 45 | 63 (58 + 5) | 5 ENI IPs |
| **c6i.2xlarge** | 45 | 83 (58 + 25) | 25 ENI IPs |

### Approach Comparison

| Aspect | Conservative (Recommended) | Aggressive (Alternative) |
|--------|---------------------------|-------------------------|
| **Reliability** | ✅ Guaranteed success | ⚠️ Deployment order dependent |
| **Resource Efficiency** | ⚠️ Some waste acceptable | ✅ Maximum utilization |
| **Operational Complexity** | ✅ Simple | ⚠️ Complex scheduling required |
| **Production Readiness** | ✅ Production safe | ⚠️ Requires testing |

**Recommendation**: Conservative approach prevents deployment failures and provides predictable behavior, making it ideal for production environments.

## Derived Solutions from Experiment Results

Based on the deployment scenarios analysis, two approaches emerge:

### Conservative Approach (Recommended)
**Problem**: Non-SG pods first → IP exhaustion before reaching maxPods
**Solution**: Lower maxPods to prevent over-scheduling

**Formula**: `maxPods = system_pods + available_ENI_IPs`

| Instance Type | Issue Observed | Conservative maxPods | Benefit |
|---------------|----------------|-------------------|---------|
| **m5.large** | IP errors at 20 pods | 20 | Prevents IP exhaustion |
| **m5.xlarge** | IP errors at 45 pods | 45 | Prevents IP exhaustion |
| **m5.2xlarge** | IP errors at 45 pods | 45 | Prevents IP exhaustion |

### Aggressive Approach (Alternative)
**Problem**: SG pods first → ENI IPs wasted due to maxPods limi
**Solution**: Increase maxPods to utilize remaining ENI IPs

| Instance Type | Issue Observed | Aggressive maxPods | Benefit |
|---------------|----------------|------------------|---------|
| **m5.large** | No waste (optimal) | 29 (keep default) | Already optimal |
| **m5.xlarge** | 5 ENI IPs wasted | 63 (58 + 5) | Eliminates ENI waste |
| **m5.2xlarge** | 25 ENI IPs wasted | 83 (58 + 25) | Eliminates ENI waste |

### Approach Comparison

| Aspect | Conservative (Recommended) | Aggressive |
|--------|---------------------------|------------|
| **Target Problem** | Prevents IP allocation failures | Eliminates ENI IP waste |
| **Reliability** | ✅ Works regardless of deployment order | ⚠️ Depends on SG-first deployment |
| **Resource Efficiency** | ⚠️ Accepts some waste | ✅ Maximum utilization |
| **Risk** | ✅ No deployment failures | ⚠️ IP exhaustion if non-SG first |
| **Complexity** | ✅ Simple to implement | ⚠️ Requires deployment control |

### Recommendation
**Conservative approach is recommended** because:
- Guarantees deployment success regardless of pod deployment order
- Eliminates IP allocation failures completely
- Provides predictable and reliable behavior
- Simplifies operational managemen

The aggressive approach should only be considered when deployment order can be strictly controlled and maximum resource utilization is critical.
