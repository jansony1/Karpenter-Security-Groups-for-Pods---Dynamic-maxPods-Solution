# Project Structure

## Production Files

### Core Configuration
- `ec2nodeclass-production.yaml` - Production EC2NodeClass with conservative maxPods formula
- `nodepool-production.yaml` - NodePool configuration for mixed deployment scenarios

### Documentation
- `README.md` - Main project documentation and overview
- `EXPERIMENT_VERIFICATION.md` - Experiment results, verification data, and derived solutions
- `PRODUCTION_DEPLOYMENT.md` - Step-by-step deployment guide

### Reference Documentation
- `SUPPORTED_INSTANCES.md` - Instance type compatibility matrix (800+ instance types)
- `CHANGELOG.md` - Version history and changes
- `CONTRIBUTING.md` - Contribution guidelines
- `LICENSE` - MIT license
- `VERSION` - Current version information

### Project Managemen
- `.github/` - GitHub workflows and templates
- `.gitignore` - Git ignore rules
- `PROJECT_STRUCTURE.md` - This file

## Key Features

### Production Formula (Conservative)
```
maxPods = system_pods + available_ENI_IPs
```

### Supported Instance Types
- **m5 family**: m5.large (20), m5.xlarge (45), m5.2xlarge (45)
- **c6i family**: c6i.large (21), c6i.xlarge (45), c6i.2xlarge (45)
- **800+ total**: Comprehensive instance type suppor

### Mixed Deployment Suppor
- SG pods first deploymen
- Non-SG pods first deploymen
- Alternating mixed deploymen

All deployment patterns are supported with the conservative formula to prevent resource allocation failures.

### Alternative Approach Available
- Aggressive formula for maximum resource utilization
- Trade-off between reliability and efficiency
- Conservative approach recommended for production
